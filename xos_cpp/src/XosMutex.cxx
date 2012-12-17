#include "XosMutex.h"

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
XosMutex::XosMutex()
	throw (XosException)
{
	// initialize the entry mutex
	if ( xos_mutex_create(&m_mutex) != XOS_SUCCESS ) {
		throw XosException( "Failed to initialize mutex");	
	}
}

/****************************************************************
 *
 * Destructor
 *
 ****************************************************************/
XosMutex::~XosMutex()
{
	destroy();
}

/***************************************************************
 *
 * @brief Tries to lock the specified mutex. If the mutex is already locked, 
 * an error is returned. Otherwise, this operation returns with the mutex 
 * in the locked state with the calling thread as its owner. 
 * 
 * @return On success, returns 0. On error, one of the following values is returned: 
 * 	EBUSY The mutex is already locked. 
 * 	EINVAL mutex is not an initialized mutex. 
 * 	EFAULT mutex is an invalid pointer. 
 *
 ***************************************************************/
bool XosMutex::trylock()
	throw (XosException)
{

	if (xos_mutex_trylock(&m_mutex) == XOS_SUCCESS)
		return true;
		
	return false;
	
}



/***************************************************************
 *
 * @brief Locks the mutex
 * 
 * @exception XosException Thrown if the func fails to 
 *  lock the mutex
 *
 ***************************************************************/
void XosMutex::lock()
	throw (XosException)
{
	// Lock the cache entry mutex
	if ( xos_mutex_lock(&m_mutex) != XOS_SUCCESS ) {
		throw XosException("Failed to lock mutex");
	}
}

/***************************************************************
 *
 * @brief Destroy mutex
 * 
 * @exception XosException Thrown if the func fails to 
 *  destroy the mutex
 *
 ***************************************************************/
void XosMutex::destroy()
{
	xos_mutex_close(&m_mutex);
}

/***************************************************************
 *
 * @brief Unlocks the cache entry
 * 
 * @exception XosException Thrown if the func fails to 
 *  unlock the mutex of this cache entry.
 *
 ***************************************************************/
void XosMutex::unlock()
	throw (XosException)
{
	// release the cache entry mutex
	if ( xos_mutex_unlock(&m_mutex) != XOS_SUCCESS ) {
		throw XosException("Failed to unlock mutex");
	}
}

