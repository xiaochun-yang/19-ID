#ifndef __Include_ImgSrvCacheEntry_h__
#define __Include_ImgSrvCacheEntry_h__

/**
 * @file ImgSrvCacheEntry.h
 *
 * Header file for ImgSrvCacheEntry class.
 */
#define IMAGE_HEADER_MAX_LEN 3000

extern "C" {
#include "xos.h"
}

#include <time.h>
#include <string>
#include <map>
#include "log_quick.h"
#include "XosException.h"
#include "SessionInfo.h"
#include "image_wrapper_polymorphic.h"
#include "imgsrvExceptions.h"
#include "diffimage.h"

class ImgSrvCacheEntry {
public:

	ImgSrvCacheEntry(const std::string& filename_):
		mIsValid(false), lastUse(time(0)), mImagePtr(NULL),
		mNumReferences(0), mRequestDelete(false) {
		LOG_FINEST1("image cache entry constructor:  %s\n", filename_.c_str());

		// initialize the entry mutex
		if (xos_mutex_create( &this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("error creating mutex");
			throw XosException( "Failed to initialize cache entry mutex");
		}

		try {
			mImagePtr = diffimage::libimage_factory(filename_);
		} catch (...) {
			LOG_SEVERE("Could not create image");
			throw;
		}
			
		LOG_INFO("allocated image");
	}
	
	~ImgSrvCacheEntry() {
		
		if ( inUse() ) {
			LOG_SEVERE("deleting entry in use");
		}
		
		if (mNumReferences != 0) {
			LOG_SEVERE("deleting image with outstanding pointers");
		}
		
		if ( mImagePtr != NULL) {
			//LOG_FINEST1("deleting image in cache entry:  %s\n", mFileName.c_str());
			delete mImagePtr;
		}

		if ( xos_mutex_close( & this->mutex ) != XOS_SUCCESS ) {
			LOG_SEVERE("ImgSrvCacheEntry destructor: error deleting entry mutex");
		}

	}
	
	//xos_result_t loadImage(time_t mtime);
	xos_result_t loadImage() {
		lock();
		
		LOG_INFO("load image");

		if ( !mImagePtr->isEmpty() ) {
			printf("image in entry. %d \n", mImagePtr->isEmpty());
			//image already loaded by a different thread
			unlock();
			return XOS_SUCCESS;
		}

		try {
			LOG_FINEST("image read start");
			mImagePtr->read_data();
			LOG_FINEST("image read complete");
			mImagePtr->findMinMax();
			LOG_FINEST("find min/maxcomplete");
		} catch (int ret) {
			LOG_SEVERE2("***** Diffimage::load -- Error loading image (error code %d) %s *****\n", ret, mImagePtr->getFilename().c_str());
			mIsValid = false;
			unlock();
			throw loadingImageException();
		}

		mIsValid = true;
		unlock();
		return XOS_SUCCESS;
	}
	
	time_t lastUse;


	bool inUse() {

		LOG_INFO("checking inUse");
      
		if ( pthread_mutex_trylock( & this->mutex.handle ) == XOS_FAILURE ) {
         LOG_INFO("could not lock");
			//someone is locking the entry
			return true;
		}
		
		int tempNumPointers = mNumReferences;
		
		unlock();
		
	    LOG_INFO1("refCount %d",tempNumPointers);
		
		return ( tempNumPointers == 0 ) ? false : true;
	}
	
	void removeWatch() {
		LOG_FINEST("report done");
		lock();
		mNumReferences--;
		unlock();
	    LOG_INFO1("refCount %d",mNumReferences);
	
	}
	
	void addWatch() {
		lock();
		mNumReferences++;
		unlock();
	}
	
	imagePtr_t getImage() {
		return mImagePtr;
	}
	
	void requestDelete() { mRequestDelete = true;};
	
	//bool isReadyToDelete() {
	//	return (inUse() && mRequestDelete ) ? true : false;
	//}
	
	bool isValid() {return mIsValid;};

private:
	bool mIsValid;
	int mNumReferences;
	bool mRequestDelete;
	imagePtr_t mImagePtr;
	//std::string mFileName;
	
	void unlock() {
		// release the cache entry mutex
		LOG_FINEST1("unlocking entry %#x\n", this);
		if (xos_mutex_unlock( &this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("error unlocking mutex");
			throw XosException("ImgSrvCacheEntry::unlock: error unlocking cache entry");
		}
		//LOG_FINEST1("unlocked entry %#x\n", this);

	}
	
	void lock() {

		LOG_FINEST1("locking entry %#x\n", this);
		// Lock the cache entry mutex
		if (xos_mutex_lock( &this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("error locking mutex");
			throw XosException("ImgSrvCacheEntry::lock: error locking cache entry");
		}
		//LOG_FINEST1("locked entry %#x\n", this);

	}
	xos_mutex_t mutex;
};



class ImgSrvCacheEntrySafePtr {
public:
	ImgSrvCacheEntrySafePtr():mEntry(NULL) {}
	~ImgSrvCacheEntrySafePtr() {
		if ( mEntry !=NULL) {
			mEntry->removeWatch();
		}
	}
	
	void addEntry(ImgSrvCacheEntry * entry) {
		mEntry = entry;
		mEntry->addWatch();
	}
	
	imagePtr_t getImage() {
		return mEntry->getImage();
	}
	
	xos_result_t loadImage() {
		return mEntry->loadImage();
	}
	
private:
	ImgSrvCacheEntry *mEntry;
	
};

#endif // __Include_ImgSrvCacheEntry_h__
