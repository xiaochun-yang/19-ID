/**********************************************************************
 Copyright 2001
 by
 The Board of Trustees of the
 Leland Stanford Junior University
 All rights reserved.

 Disclaimer Notice

 The items furnished herewith were developed under the sponsorship
 of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 Leland Stanford Junior University, nor their employees, makes any war-
 ranty, express or implied, or assumes any liability or responsibility
 for accuracy, completeness or usefulness of any information, apparatus,
 product or process disclosed, or represents that its use will not in-
 fringe privately-owned rights.  Mention of any product, its manufactur-
 er, or suppliers shall not, nor is it intended to, imply approval, dis-
 approval, or fitness for any particular use.  The U.S. and the Univer-
 sity at all times retain the right to use and disseminate the furnished
 items for any purpose whatsoever.                       Notice 91 02 01

 Work supported by the U.S. Department of Energy under contract
 DE-AC03-76SF00515; and the National Institutes of Health, National
 Center for Research Resources, grant 2P41RR01209.

 ************************************************************************/

/* imgsrv_cache.c */

/* local include files */
#include "xos.h"
#include "log_quick.h"

#include <diffimage.h>
#include "imgsrv_cache.h"
#include "imgsrv_validation.h"

#include "SessionInfo.h"
#include "ImgSrvCacheEntry.h"
#include "SessionCache.h"

#include <utility>
#include <map>
#include <string>
#include <list>
#include <sstream>
#include "imgsrvExceptions.h"


using std::map;
using std::string;
using std::list;
using std::pair;

/* module data */

SessionCache gSessionCache;

extern int gImageCacheSize;

#define MAX_IDLE_TIME 60 // in seconds


xos_result_t allocateEntryInCache(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntrySafePtr &ppEntry, std::string& reason);


typedef ImgSrvCacheEntry * imageCachePtr;
typedef imageCachePtr * imageCachePtrPtr;

class ImageCacheBase {
public:
	ImageCacheBase();
	~ImageCacheBase();
    ImageCacheBase(const ImageCacheBase& src);
    ImageCacheBase& operator=(const ImageCacheBase& rhs);
	void lock();
	void unlock();
	xos_result_t addImage(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntry *pEntry );

protected:
    map<string, ImgSrvCacheEntry * > mImages;
    map<string, ImgSrvCacheEntry * > mDefunctImages;
private:
    // Prevent assignment and pass-by-value.

	xos_mutex_t mutex;
};


void ImageCacheBase::lock()  {
	LOG_FINEST("Locking cache table");
	// Lock the cache entry mutex
	if (xos_mutex_lock(&this->mutex) != XOS_SUCCESS) {
		LOG_SEVERE("xos_mutex_lock failed for cache table mutex");
		throw XosException("ImageCache::lock: error locking cache table");
	}
	//LOG_FINEST("locked cache table");
}

void ImageCacheBase::unlock()  {
	LOG_FINEST("unlocking cache table");
	if (xos_mutex_unlock(&this->mutex) != XOS_SUCCESS) {
		LOG_SEVERE("xos_mutex_unlock failed for cache table mutex");
		throw XosException("ImageCache::unlock: error unlocking cache table");
	}
	//LOG_FINEST("unlocked cache table");
}

ImageCacheBase::ImageCacheBase()  {

	// initialize the entry mutex
	if (xos_mutex_create(&this->mutex) != XOS_SUCCESS) {
		LOG_SEVERE("xos_mutex_create failed for cache table mutex");
		throw XosException("Failed to initialize image cache mutex");
	}

}

ImageCacheBase::~ImageCacheBase() {
	try {
		LOG_SEVERE("image cache destructor");

		if (xos_mutex_close(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("ImageCache destructor: error deleting entry mutex");
		}

	} catch (XosException& e) {
		std::string tmp("Caught XosException in ImageCache destructor: ");
		tmp += e.getMessage();
		LOG_SEVERE(tmp.c_str());
		
	}

}

xos_result_t ImageCacheBase::addImage(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntry *pEntry ) {

	pair<map<string, ImgSrvCacheEntry *>::iterator, bool> result;

	LOG_FINEST1("add image %s", filename.c_str());

	if (!lockedByCaller) lock();
	// insert, use the filename as the key.
	result = mImages.insert(make_pair(filename, pEntry));
	if (!lockedByCaller) unlock();

	if (result.second == false) {
		LOG_SEVERE1("failed to add image %s", filename.c_str());
		return XOS_FAILURE;
	}

	LOG_FINEST1("add image complete %s", filename.c_str());
	
	return XOS_SUCCESS;
}




class ImageCache: public ImageCacheBase
{

public:
	ImageCache(): defunctCnt(0) {};
    xos_result_t deleteOldestImage (bool lockedByCaller );
    void waitForEntryLock(const std::string& filename,  time_t mtime, ImgSrvCacheEntrySafePtr &pEntry);
    xos_result_t removeDefunctImages(bool lockedByCaller);
    xos_result_t addDefunctImage(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntry *pEntry );
protected:
    xos_result_t makeEntryDefunct(bool lockedByCaller, const std::string& filename );
    int defunctCnt;
    	
};



xos_result_t ImageCache::addDefunctImage(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntry *pEntry ) {

	pair<map<string, ImgSrvCacheEntry *>::iterator, bool> result;

	LOG_FINEST1("add defunct image %s", filename.c_str());

	if (!lockedByCaller) lock();
	// insert, use the filename as the key.
	result = mDefunctImages.insert(make_pair(filename, pEntry));
	if (!lockedByCaller) unlock();

	if (result.second == false) {
		LOG_SEVERE1("failed to add image %s", filename.c_str());
		return XOS_FAILURE;
	}

	LOG_FINEST1("add defunct image complete %s", filename.c_str());
	
	return XOS_SUCCESS;
}

xos_result_t ImageCache::removeDefunctImages(bool lockedByCaller ) {
	
	map<string, ImgSrvCacheEntry *>::iterator it, end, oldest;

	if ( !lockedByCaller ) lock();

	for (it = mDefunctImages.begin(); it != mDefunctImages.end(); ) {
		ImgSrvCacheEntry * pEntry = it->second;
		
		if ( pEntry->inUse() ) {
			LOG_FINEST("ignoring entry in use");
			++it;
		} else {
			LOG_FINEST1("removing defunct image: %s\n", it->first.c_str() );

			delete pEntry;
			mDefunctImages.erase(it++);
		}
	}
	
	if (mDefunctImages.size() != 0) {
		LOG_WARNING1("%d defunct images", mDefunctImages.size() );
	}

	if ( !lockedByCaller ) unlock();

	return XOS_SUCCESS;
}


xos_result_t ImageCache::deleteOldestImage(bool lockedByCaller ) {

	removeDefunctImages(lockedByCaller);
	
	ImgSrvCacheEntry *pOldestEntry;
	
	map<string, ImgSrvCacheEntry *>::iterator it, end, oldest;

	if ( !lockedByCaller ) lock();

	LOG_FINEST2("entry count = %d **** (limit = %d)", mImages.size(),
			gImageCacheSize);
	
	if (mImages.size() < gImageCacheSize) {
		LOG_FINEST("image cache not full");
		if ( !lockedByCaller ) unlock();
		return XOS_SUCCESS;
	}
	
	pOldestEntry = NULL;

	oldest = mImages.end();
	for (it = mImages.begin(); it != mImages.end(); it++) {
		ImgSrvCacheEntry * pEntry = it->second;

		LOG_FINEST1("checking: %s\n", it->first.c_str() );
		
		if ( pEntry->inUse() ) {
			LOG_FINEST("ignoring entry in use");
			continue; //only consider entries that can be locked.
		}
		
		if (pOldestEntry == NULL) {
			LOG_FINEST("first lockable entry becomes the oldest entry");
			oldest = it;
			pOldestEntry = pEntry;
			continue;
		}

		/* update oldest time if this entry is an older entry */
		if (pEntry->lastUse < pOldestEntry->lastUse) {
			oldest=it;
			pOldestEntry = pEntry;

		}
		
	}

	if ( oldest == mImages.end() ) {
		LOG_WARNING("failed to find an entry for deletion");

		if ( !lockedByCaller ) unlock();
		return XOS_FAILURE;
	}

	LOG_FINEST1("delete the oldest entry %s", oldest->first.c_str());

	delete oldest->second;
	mImages.erase(oldest);
	
	if ( !lockedByCaller ) unlock();

	return XOS_SUCCESS;
}


xos_result_t ImageCache::makeEntryDefunct(bool lockedByCaller, const std::string& filename ) {
	LOG_INFO("hiding cache image");
	
	//find an entry with the filename
	map<string, imageCachePtr >::iterator it = mImages.find(filename);
	if (it == mImages.end()) {
		return XOS_SUCCESS;
	}
	
	imageCachePtr entry = it->second;
	mImages.erase(it);
	
	std::stringstream defunctFilename;
	defunctFilename << "#" << defunctCnt++ << "#" << filename;
	
	return addDefunctImage(true,  defunctFilename.str(), entry);
	
}


ImageCache gImageCache;



void allocateEntryInCache(bool lockedByCaller, const std::string& filename, ImgSrvCacheEntrySafePtr &ppEntry) {
	
	LOG_FINEST1("make room for %s", filename.c_str());
	if ( gImageCache.deleteOldestImage(lockedByCaller) == XOS_FAILURE) {
		LOG_SEVERE1("failed to delete oldest image to make room for %s", filename.c_str());
		throw cacheAllocationException();
	}
	
	// Create a new locked entry
	ImgSrvCacheEntry * entry;
	try {
		entry = new ImgSrvCacheEntry(filename);
	} catch (std::bad_alloc & e) {
		LOG_SEVERE1("could not allocate entry for %s", filename.c_str());
		throw e;
	}
	
	if ( gImageCache.addImage(lockedByCaller, filename, entry) != XOS_SUCCESS) {
		LOG_SEVERE1("addImage failed for %s", filename.c_str());
		delete entry;
		LOG_SEVERE("Cache is full.");
		throw cacheAllocationException();
	}
	
	LOG_FINEST1("unloaded image entry now in image cache: %s", filename.c_str());
	
	ppEntry.addEntry(entry);
}


void waitForFileOnDisk(const std::string& filename, struct stat * p_img_stat ) {

	int cnt = 0;
	while (stat(filename.c_str(), p_img_stat) != 0) {
		if ( ++cnt > 4 ) {
			throw fileNotFoundException();
		}
		LOG_INFO1("%s not on disk. Sleep.", filename.c_str() );
		xos_thread_sleep(1000);
	}
	
}
	

void cache_get_image(const std::string& filename,
		const std::string& userName, const std::string& sessionId,
		ImgSrvCacheEntrySafePtr &ppEntry ) {

	struct stat img_stat;

	waitForFileOnDisk( filename, &img_stat );

	gSessionCache.removeOldSessions(false);
	
	if ( gSessionCache.checkFilePermissions(false, filename,userName,sessionId) == XOS_FAILURE ) {
		LOG_FINEST1("Invalid file permissions %s\n", filename.c_str());
		throw invalidFilePermissionException();
	}

	gImageCache.waitForEntryLock( filename, img_stat.st_mtime, ppEntry);
	
	ppEntry.loadImage();

}


void ImageCache::waitForEntryLock(const std::string& filename, time_t mtime,
		ImgSrvCacheEntrySafePtr &ppEntry) {

	lock();

	//find an entry with the filename
	map<string, imageCachePtr >::iterator it = mImages.find(filename);
	if (it == mImages.end()) {
		LOG_FINEST1("CACHE: Entry not in cache %s\n", filename.c_str());
		try {
			allocateEntryInCache(true,filename,ppEntry);
		} catch ( cacheAllocationException & e ) {
			LOG_WARNING("Could not allocate entry");
			unlock();
			throw e;
		}
		unlock();
		return;
	}
	
	//entry in the cache
	imageCachePtr entry = it->second;
	if (entry->lastUse < mtime ) {
		makeEntryDefunct(true, filename);
		
		try {
			allocateEntryInCache(true,filename,ppEntry);
		}  catch ( cacheAllocationException & e ) {
			LOG_WARNING("Could not allocate entry");
			unlock();
			throw e;
		}
		unlock();
		return;
	}

	ppEntry.addEntry(entry);
	unlock();
	return;
}


xos_result_t readImageHeaderNoCache(const std::string& filename,
		const std::string& userName, const std::string& sessionId, std::string & header, std::string& reason) {

	struct stat img_stat;
	char tmpHeader[IMAGE_HEADER_MAX_LEN + 1];

	try { 
		waitForFileOnDisk( filename, &img_stat );
	} catch ( fileNotFoundException e ) {
		reason = "Image not on disk " + filename;
		return XOS_FAILURE;
	}

	gSessionCache.removeOldSessions(false);
	
	if ( gSessionCache.checkFilePermissions(false, filename,userName,sessionId ) == XOS_FAILURE ) {
		reason = "Invalid file permissions " + filename;

		LOG_FINEST1("Invalid file permissions %s\n", filename.c_str());
		return XOS_FAILURE;
	}

	Diffimage dImage;
	if ( dImage.load_header(filename.c_str()) == XOS_FAILURE) {
		LOG_WARNING1("failed to load image header %s\n", filename.c_str());
		return XOS_FAILURE;
	}

	if (dImage.get_header(tmpHeader, IMAGE_HEADER_MAX_LEN) != XOS_SUCCESS) {
		LOG_WARNING1("failed to load image header %s\n", filename.c_str());
		return XOS_FAILURE;
	}
	
	header = tmpHeader;
	
	return XOS_SUCCESS;
}




