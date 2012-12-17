#include "xos.h"
#include "log_quick.h"
#include "diffimage.h"
#include "SessionInfo.h"
#include "SessionCache.h"
#include "XosStringUtil.h"
#include "imgsrv_validation.h"

#include <map>
#include <string>
#include <list>

using std::multimap;
using std::string;
using std::list;


void SessionCache::addFileAccessForSession(bool lockedByCaller, const string& session, fileAccessInfoPtr fileAccessInfo) {

    if (!lockedByCaller) lock();

	try {
		mPermittedFilenames.insert(make_pair(session, fileAccessInfo));
	} catch (std::exception& e) {
		LOG_SEVERE( e.what());
	}

	LOG_FINEST1("size of session cache: %d", mPermittedFilenames.size());
	
    if (!lockedByCaller) unlock();	

}

fileAccessInfoPtr SessionCache::lookupFileAccessInfoForSession(bool lockedByCaller, const string& session,
		const string& filename) {

	multimap<string, FileAccessInfo *>::const_iterator start, end;
    if (!lockedByCaller) lock();

	try {
		end = mPermittedFilenames.upper_bound(session);

		for (start = mPermittedFilenames.lower_bound(session); start != end; ++start) {
			fileAccessInfoPtr fileAccessInfo = start->second;
			if (fileAccessInfo->filename == filename) {
			    if (!lockedByCaller) unlock();			    
		        fileAccessInfo->incrNumThreadPointers(1);
				return fileAccessInfo;
			}
		}

	} catch (std::exception& e) {
		LOG_SEVERE( e.what());
	}

    if (!lockedByCaller) unlock();

    //return null pointer
    return (FileAccessInfo*) 0;
}


/***************************************************************
 *
 * @brief Constructor
 *
 * Create a cache entry to be put in the image cache.
 *
 * @param filename Name of the file
 * @param dImage Pointer to a diffraction image object
 * @exception XosException Thrown if the func fails to
 *  create or lock the mutex of this cache entry.
 *
 ***************************************************************/
SessionCache::SessionCache() throw (XosException) {
	mLastCleanup=time(0);
	// initialize the entry mutex
	if (xos_mutex_create(&this->mutex) != XOS_SUCCESS) {
		throw XosException("Failed to initialize cache entry mutex");
	}

}

/***************************************************************
 *
 * @brief Destructor
 *
 * Create a cache entry to be put in the image cache.
 *
 * @param filename Name of the file
 * @param dImage Pointer to a diffraction image object
 * @exception XosException Thrown if the func fails to
 *  create or lock the mutex of this cache entry.
 *
 ***************************************************************/
SessionCache::~SessionCache() {
	try {

		if (xos_mutex_close(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE("SessionCache destructor: error deleting entry mutex");
		}

	} catch (XosException& e) {
		std::string tmp("Caught XosException in SessionCache destructor: ");
		tmp += e.getMessage();
		LOG_SEVERE(tmp.c_str());
	}
}

/***************************************************************
 *
 * @brief Locks the cache entry
 *
 * @exception XosException Thrown if the func fails to
 *  lock the mutex of this cache entry.
 *
 ***************************************************************/
void SessionCache::lock() throw (XosException) {

	LOG_FINEST1("locking session cache %#x\n", this);
	// Lock the cache entry mutex
	if (xos_mutex_lock(&this->mutex) != XOS_SUCCESS) {
		throw XosException("SessionCache::lock: error locking cache entry");
	}
	LOG_FINEST1("locked session cache %#x\n", this);

}

/***************************************************************
 *
 * @brief Unlocks the cache entry
 *
 * @exception XosException Thrown if the func fails to
 *  unlock the mutex of this cache entry.
 *
 ***************************************************************/
void SessionCache::unlock() throw (XosException) {
	// release the cache entry mutex
	LOG_FINEST1("unlocking session cache %#x\n", this);
	if (xos_mutex_unlock(&this->mutex) != XOS_SUCCESS) {
		throw XosException(
				"SessionCache::unlocked: error unlocking session cache");
	}
	LOG_FINEST1("unlocked session cache %#x\n", this);

}

/***************************************************************
 *
 * @brief Remove a session to the list of sessions.
 *
 * Assumes that the entry is locked.
 *
 * @param sessionId Id of the session to be removed
 *
 ***************************************************************/
void SessionCache::removeOldSessions(bool lockedByCaller) {
	multimap<string, FileAccessInfo *>::iterator it;
    
	if ( mLastCleanup + 60  > time(0) ) return; 
	mLastCleanup = time(0);
    
	if (!lockedByCaller) lock();
 
	LOG_INFO1("cleanup %d old sessions from cache", mPermittedFilenames.size());    
	for (it = mPermittedFilenames.begin() ; it != mPermittedFilenames.end();) {
		fileAccessInfoPtr fileAccessInfo = it->second;
		LOG_FINEST2("validation time: %d, %d", fileAccessInfo->validationTime, time(0) );

		if ( fileAccessInfo->validationTime < time(0) - 60 ) {
			LOG_FINEST1("removing File Access Info: %.7s", it->first.c_str() );
			// We found a match! Remove it from the map.
			delete fileAccessInfo;
			mPermittedFilenames.erase(it++);
		} else {
			++it;
		}
	}
 
	if (!lockedByCaller) unlock();

	LOG_INFO("leaving cleanup of sessions from cache" );    

}

/***************************************************************
 *
 * @brief Add a session to the list of sessions.
 *
 ***************************************************************/

xos_result_t SessionCache::checkFilePermissions(bool lockedByCaller, const std::string& filename,
			const std::string& userName, const std::string& sessionId ) {

	fileAccessInfoPtr fileAccessInfo;
	bool permitted = false;

	LOG_FINEST("CACHE: checking session id\n");

	if (!lockedByCaller)
		lock();

	fileAccessInfo = lookupFileAccessInfoForSession(true, sessionId, filename);

	if (fileAccessInfo != (fileAccessInfoPtr) 0) {
		LOG_FINEST("File found in session cache.  Skip revalidation.");

		fileAccessInfo->lock();
		permitted = fileAccessInfo->permitted;
		fileAccessInfo->unlock();

		//if ( !permitted)
		//	reason="session cache indicates permission denied";

		if (!lockedByCaller)
			unlock();

		return permitted ? XOS_SUCCESS : XOS_FAILURE;
	}
    
    	
   	//not in session cache
   	fileAccessInfo = new FileAccessInfo(filename);
   	fileAccessInfo->lock();
	addFileAccessForSession(true, sessionId, fileAccessInfo );
	if (!lockedByCaller) unlock();
    	
    // Ask the imp server if this user can read the file.
    SessionInfo newSession(userName, sessionId, 0);
    std::string reason;
    permitted = isFileReadable(newSession, filename, reason);
    if (!permitted)
	LOG_INFO1("file not readable %s", reason.c_str());
    else
	LOG_INFO("file is readable");
    
    fileAccessInfo->permitted = permitted;
	fileAccessInfo->unlock();
    
    return permitted ? XOS_SUCCESS : XOS_FAILURE;    		
	
}


