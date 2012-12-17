#ifndef __Include_SessionCache_h__
#define __Include_SessionCache_h__

/**
 * @file SessionCache.h
 *
 * Header file for SessionCache class.
 */
#define IMAGE_HEADER_MAX_LEN 3000

extern "C" {
#include "xos.h"
}


#include <map>
#include <string>
#include <list>

using std::multimap;
using std::string;
using std::list;

#include "XosException.h"
#include "SessionInfo.h"



class FileAccessInfo {
public:
	string filename;

	bool permitted;
	time_t 	validationTime;
	
	FileAccessInfo(const string & filename_) {
		filename= filename_;
		permitted = true;
		validationTime = time(0);
		numThreadPointers=0;
		
		// initialize the entry mutex
		if (xos_mutex_create(&this->mutex) != XOS_SUCCESS) {
			throw XosException("Failed to initialize FileAccessInfo mutex");
		}

		// initialize the entry mutex
		if (xos_mutex_create(&this->numThreadPointerMutex) != XOS_SUCCESS) {
			throw XosException("Failed to initialize FileAccessInfo threadPointer mutex");
		}

		
	}

	~FileAccessInfo() {
		try {

			if (xos_mutex_close(&this->mutex) != XOS_SUCCESS) {
				LOG_SEVERE("FileAccessInfo destructor: error deleting entry mutex");
			}
			if (xos_mutex_close(&this->numThreadPointerMutex) != XOS_SUCCESS) {
				LOG_SEVERE("FileAccessInfo destructor: error deleting threadPointer mutex");
			}

		} catch (XosException& e) {
			std::string tmp("Caught XosException in FileAccessInfo destructor: ");
			tmp += e.getMessage();
			LOG_SEVERE(tmp.c_str());
		}
	}


	
	void lock() throw (XosException) {

		LOG_FINEST1("locking File Access Info %#x\n", this);
		// Lock the cache entry mutex
		if (xos_mutex_lock(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE1("error locking File Access Info %#x\n", this);
			throw XosException("error locking File Access Info");
		}
		LOG_FINEST1("locked File Access Info %#x\n", this);

	}

	void unlock() throw (XosException) {
		// release the cache entry mutex
		LOG_FINEST1("unlocking File Access Info %#x\n", this);
		if (xos_mutex_unlock(&this->mutex) != XOS_SUCCESS) {
			LOG_SEVERE1("error unlocking File Access Info %#x\n", this);
			throw XosException(
					"error unlocking File access Info");
		}
		LOG_FINEST1("unlocked File Access Info %#x\n", this);
	}
	
	void incrNumThreadPointers(int dir) {
		if (xos_mutex_lock(&this->numThreadPointerMutex) != XOS_SUCCESS) {
					LOG_SEVERE1("error locking ThreadPointer Mutex %#x", this);
					throw XosException("error locking thread pointer mutex in File Access Info");
		}
		
		numThreadPointers+=dir;

		if (xos_mutex_unlock(&this->numThreadPointerMutex) != XOS_SUCCESS) {
			LOG_SEVERE1("error unlocking Thread pointer mutex %#x\n", this);
			throw XosException(
					"error unlocking thread pointer mutex in File Access Info");
		}

	}

	int getNumThreadPointers() {
		return numThreadPointers;
	}
	
private:
	xos_mutex_t mutex;
	xos_mutex_t numThreadPointerMutex;
	int numThreadPointers;
	
};

typedef FileAccessInfo * fileAccessInfoPtr;

class SessionCache
{
    public:
    	SessionCache() throw (XosException);
    	~SessionCache();
    	void addFileAccessForSession(bool lockedByCaller, const string& session, fileAccessInfoPtr fileAccessInfo);

    	FileAccessInfo * lookupFileAccessInfoForSession(bool lockedByCaller, const string& session,
    			const string& filename);
    	
        bool isFileAccessibleForSession(bool lockedByCaller, const string& session, const string& filename);

    	xos_result_t checkFilePermissions(bool lockedByCaller, const std::string& filename,
    				const std::string& userName, const std::string& sessionId );

    	void removeOldSessions(bool lockedByCaller );

    protected:
        multimap<string, fileAccessInfoPtr> mPermittedFilenames;
    private:
        // Prevent assignment and pass-by-value.
        SessionCache(const SessionCache& src);
        SessionCache& operator=(const SessionCache& rhs);
    	void lock() throw (XosException);
    	void unlock() throw (XosException);

    	xos_mutex_t mutex;
    	int mLastCleanup;
};


#endif // __Include_SessionCache_h__


