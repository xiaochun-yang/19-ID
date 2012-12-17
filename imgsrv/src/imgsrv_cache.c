/************************************************************************
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
#include "xos_hash.h"
#include "log_quick.h"

#include <diffimage.h>
#include "imgsrv_cache.h"
#include "imgsrv_validation.h"

#include "SessionInfo.h"
#include "ImgSrvCacheEntry.h"

/* module data */
static int mCacheEntryCount = 0;
static xos_mutex_t mCacheHashTableMutex;
static xos_hash_t mCacheHashTable;
static xos_semaphore_t mEntryCountSemaphore;
static int mNullEntryCounter = 0;
extern int gImageCacheSize;

#define MAX_IDLE_TIME 60 // in seconds


/***************************************************************
 *
 * @func xos_result_t cache_initialize( void )
 *
 * @brief Initializes image cache.
 *
 * @return XOS_SUCCESS if the cache entry is created and added successfully.
 *  Else the exit() will be called, which will cause the application
 *  to exit.
 *
 ***************************************************************/
xos_result_t cache_initialize( void )
	{
	/* initialize the cache hash table */
	if ( xos_hash_initialize( & mCacheHashTable, gImageCacheSize + 10,
									  NULL ) == XOS_FAILURE )
		{
		LOG_SEVERE("ERROR in cache_initialize: xos_hash_initialize failed");
		xos_error("initialize_cache -- error initializing cache hash table");
		return XOS_FAILURE;
		}

	/* initialize mutex for cache hash table */
	if ( xos_mutex_create( & mCacheHashTableMutex ) != XOS_SUCCESS )
		{
		LOG_SEVERE("ERROR in cache_initialize: xos_mutex_create failed");
		xos_error( "initialize_cache -- error initializing hash table mutex");
		return XOS_FAILURE;
		}

	/* initialize the entry count semaphore */
	if ( xos_semaphore_create( & mEntryCountSemaphore, 0 ) == XOS_FAILURE ) {
		LOG_SEVERE("ERROR in cache_initialize: xos_semaphore_create failed");
		xos_error_exit("cache_initialize -- entry count semaphore initialization failed" );
	}

	/* report success */
	return XOS_SUCCESS;
	}

/***************************************************************
 *
 * @func static void mark_entry_for_deletion(const std::string& filename)
 *
 * @brief Mark the hash entry for deletion by the garbage collector
 * when the cache is full. The entry marked for deletion can not be
 * searched.
 *
 * Assumes that the entry is locked by the caller of this func.
 *
 * @param filename Filename which is used as keys in the cache.
 *
 ***************************************************************/
static void mark_entry_for_deletion(const std::string& filename, ImgSrvCacheEntry* pEntry)
{
	char nullfilename[255];
	sprintf( nullfilename, "NULL%d%s", mNullEntryCounter++, filename.c_str() );


	// Set entry key to null*** so that it can not be found by the cache search func.
	// The cache entry itself will be removed by the garbage collector, which
	// goes through each entries and removes the one whose lastUse is old.
	if ( xos_hash_entry_kill( & mCacheHashTable, filename.c_str(), nullfilename ) != XOS_SUCCESS ) {
		LOG_SEVERE1("ERROR in mark_entry_for_deletion: xos_hash_entry_kill failed for %s",
					filename.c_str());
		xos_error_exit("Failed to remove cache entry");
	}

	// zero access time to make it top candidate for garbage collector
	pEntry->lastUse = 0;
	pEntry->isValid = FALSE;
}

/***************************************************************
 *
 * @func XOS_THREAD_ROUTINE garbage_collector_thread (void* junk)
 *
 * @brief Thread routine for garbage collection. Removes old and invalid entries from cache.
 *
 * @param junk Unused
 * @return XOS_THREAD_ROUTINE 0 if successful.
 *
 ***************************************************************/
XOS_THREAD_ROUTINE garbage_collector_thread ( void * /*arg*/ )
	{

	int 						entryCount;
	time_t 						oldestTime;
	xos_iterator_t 				entryIterator;
	char	 					filename[255];
	char						oldestEntryFilename[255];
	ImgSrvCacheEntry 		   *pEntry;
	ImgSrvCacheEntry 	       *pOldestEntry;
	int 						oldestSlot = 0;
	char						nullfilename[255];

	/* loop forever */
	for (;;)
		{
		/* wait for a new cache entry */
		if ( xos_semaphore_wait( &mEntryCountSemaphore, 0 ) != XOS_SUCCESS ) {
			LOG_SEVERE("ERROR in garbage_collector_thread: xos_semaphore_wait failed");
			xos_error_exit("garbage_collector_thread -- error waiting on entry count semaphore");
		}

		/* get the hash table mutex */
		if ( xos_mutex_lock( & mCacheHashTableMutex ) != XOS_SUCCESS )
			{
			LOG_SEVERE("ERROR in garbage_collector_thread: xos_mutex_lock failed for cache table mutex");
			xos_error_exit("garbage_collector_thread -- error locking hash table mutex");
			}
			LOG_FINEST("Locked cache table");


		/* get the current entry count */
		entryCount = mCacheEntryCount;

		LOG_FINEST2("\n **** entry count = %d **** (limit = %d)\n",
				entryCount, gImageCacheSize );

		/* do a cycle of garbage collection if cache is full */
		if ( entryCount > gImageCacheSize )
			{
			LOG_INFO("**** Starting garbage collection cycle ****\n");

			/* initialize oldest time to current time */
			oldestTime = time(0) + 1000;
			pOldestEntry = NULL;

			/* get an iterator for the hash table */
			if ( xos_hash_get_iterator( & mCacheHashTable, & entryIterator ) != XOS_SUCCESS ) {
				LOG_SEVERE("ERROR in garbage_collector_thread: xos_hash_get_iterator failed");
				xos_error_exit("garbage_collector_thread -- error getting hash table iterator");
			}

			/* loop over all hash table entries to find oldest entry */
			while ( xos_hash_get_next( & mCacheHashTable, filename,
						(xos_hash_data_t *) &pEntry, & entryIterator ) == XOS_SUCCESS )
			{
			//	pEntry->lock();
				LOG_INFO3("**** iterator = %d filename = %s entry use-time = %d\n",
						entryIterator, filename, (int)pEntry->lastUse );

				/* update oldest time if this entry is on older entry */
				if ( pEntry->lastUse < oldestTime ) {
					strcpy( oldestEntryFilename, filename );
					pOldestEntry = pEntry;
					oldestTime = pOldestEntry->lastUse;
					oldestSlot = entryIterator;
				}
			//	pEntry->unlock();
			}

			sprintf( nullfilename, "NULL%d%s", mNullEntryCounter++, oldestEntryFilename );
			LOG_INFO1("mark cache entry %s for deletion\n", oldestEntryFilename);


			/* wait for any threads just starting to use the entry to finish up */
			/* xos_thread_sleep(1000); */

			/* lock the mutex to wait for any threads legitimately using the entry */
			LOG_FINEST1("Garbage collector locking entry: %#x\n", pOldestEntry);
			pOldestEntry->lock();

			// If the entry has not been marked for deletion by another thread
			// then mark it now.
			if (pOldestEntry->isValid) {

				/* indicate that the entry is invalid */
				pOldestEntry->isValid = FALSE;

				/* delete the diffimage object */
				/* nullify entry in hash table */
				if ( xos_hash_entry_kill( & mCacheHashTable, oldestEntryFilename, nullfilename ) != XOS_SUCCESS ) {
					LOG_SEVERE1("ERROR in garbage_collector_thread: xos_hash_entry_kill failed for %s",
								oldestEntryFilename);
					// xos_hash_entry_kill returns failure because it can not find
					// the entry name in the hash, possibly because
					// another thread has already nullified the entry name it
					// So here we should just ignore the error???.
					xos_error_exit("Error nullifying entry.");
				}
			}


			LOG_FINEST1("Garbage collector unlocking entry: %#x\n", pOldestEntry);

			// unlock the entry mutex
			pOldestEntry->unlock();


			// delete the cache entry object
			// Delete its own memebers in the destructor.
			delete pOldestEntry ;

			if( xos_hash_delete_slot( & mCacheHashTable, oldestSlot ) != XOS_SUCCESS )
				{
				LOG_SEVERE("ERROR in garbage_collector_thread: xos_hash_delete_slot failed");
				xos_error_exit("garbage_collector_thread -- error deleting slot");
				}

			LOG_INFO1("Deleted %s\n", oldestEntryFilename );

			/* update count of entries in the cache */
			mCacheEntryCount --;
			}

		/* release the hash table mutex */
		if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS )
			{
			LOG_SEVERE("ERROR in garbage_collector_thread: xos_mutex_unlock failed for cache table mutex");
			xos_error_exit("create_cache_entry -- error unlocking hash table mutex");
			}
			LOG_FINEST("Unlocked cache table");
		}

	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
	}


/***************************************************************
 *
 * @func xos_result_t create_cache_entry(const std::string& filename,
 *										ImgSrvCacheEntry **ppEntry )
 *
 * Create a cache entry and puts it in the image cache.
 *
 * @param filename Name of the file
 * @param ppEntry Returned pointer to the newly created cache entry.
 *  This pointer must be deleted when it is no longer needed.
 * @return XOS_SUCCESS if the cache entry is created and added successfully.
 *  Else the exit() will be called, which will cause the application
 *  to exit.
 *
 ***************************************************************/
static xos_result_t create_cache_entry(const std::string& filename,
										ImgSrvCacheEntry **ppEntry )
	{

	// Create a new entry and lock it the entry
	ImgSrvCacheEntry* entry = new ImgSrvCacheEntry(filename);

	if ( entry == NULL) {
		LOG_SEVERE1("ERROR in create_cache_entry: failed to create ImgSrvCacheEntry for %s", filename.c_str());
		xos_error_exit("create_cache_entry -- error allocating memory for a new cache entry");
	}


	// insert entry into the cache
	if ( xos_hash_add_entry( & mCacheHashTable, filename.c_str(),
									 (xos_hash_data_t) entry ) != XOS_SUCCESS )
		{
		LOG_SEVERE1("ERROR in create_cache_entry: xos_hash_add_entry failed for %s", filename.c_str());
		xos_error_exit("create_cache_entry -- error adding entry to hash table");
		}

	/* count the entries put into the cache */
	mCacheEntryCount++;

	LOG_INFO1("new entry count = %d\n", mCacheEntryCount );

	/* notify garbage collection thread of a new cache entry */
	if ( xos_semaphore_post( & mEntryCountSemaphore ) != XOS_SUCCESS ) {
		LOG_SEVERE1("ERROR in create_cache_entry: xos_semaphore_post failed for %s", filename.c_str());
		xos_error_exit("create_cache_entry -- error posting entry count semaphore");
	}

	*ppEntry = entry;

	LOG_FINEST1("returned entry address = %x\n", *ppEntry );

	/* report success */
	return XOS_SUCCESS;
	}




/***************************************************************
 *
 * @func xos_result_t cache_get_image( const std::string& 	filename,
 *							const std::string& 		userName,
 *							const std::string&		sessionId,
 *							ImgSrvCacheEntry	  **ppEntry,
 *							std::string& 			reason)
 *
 * @brief Returns a cache entry that holds the image of the given filename.
 *
 * If the file has not been loaded into the cache, load it and save it in the cache
 * first before returning the new cache entry to the caller.
 *
 * @param filename Image filename
 * @param userName Name of the user who is retrieving the file
 * @param sessionId Session if of this user
 * @param ppEntry The returned cache entry
 * @param reason The returned string explaining the error.
 * @return XOS_SUCCESS if a cache entry is returned successfully. Else returns XOS_FAILURE
 * and ppEntry should not be used.
 *
 ***************************************************************/
xos_result_t cache_get_image( const std::string& 	filename,
							const std::string& 		userName,
							const std::string&		sessionId,
							ImgSrvCacheEntry	  **ppEntry,
							std::string& 			reason)
{


	ImgSrvCacheEntry *pEntry;
	struct stat 	  img_stat;
	int 			  statResult;

	// look up filename in hash table
	while( TRUE ) {

		// Lock the whole table since we are going to do some lookup
		// and we don't want the table to change.
		if ( xos_mutex_lock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
			LOG_SEVERE("ERROR in cache_get_image: xos_mutex_lock failed for cache table mutex");
			xos_error_exit("Failed to lock image cache");
		}
		LOG_FINEST("Locked cache table");

		// Look for the file in the cache.
		// Break out of the loop if the file is not in the cache.
		if ( xos_hash_lookup( & mCacheHashTable, filename.c_str(), (xos_hash_data_t *) & pEntry ) != XOS_SUCCESS ) {
			LOG_INFO1("CACHE: Entry not in cache %s\n", filename.c_str());
			break;
		}


		LOG_FINEST1("CACHE: Found %s in cache...\n", filename.c_str());


		// Try lockin this entry since we may want to modify it
		// also we don't want other thread to delete it while we are here.
		if (pEntry->tryLock() == 0) {

			// Now that we have locked the entry that we want to modify,
			// we can unlock the table so that other threads can use other entries.
			if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
				LOG_SEVERE("ERROR in cache_get_image: xos_mutex_unlock failed for cache table mutex");
				xos_error_exit("Failed to unlock image cache");
			}
			LOG_FINEST("Unlocked cache table");

			// Found the name in cache and the flag indicates that the file is valid
			// So here we will try to make sure that the file is still up to date
			// and the user is allowed to see the file.
			if (pEntry->isValid ) {

				// Now we will check if the file has not been modified since
				// we have loaded it into the cache.

				// get current state of file on disk
				statResult = stat( filename.c_str(), & img_stat );


				// The file is not there anymore.
				// We will remove this cache entry and return XOS_FAILURE.
				if ( statResult != 0 ) {

					LOG_INFO1("CACHE: Killing entry of non-existent file %s\n", filename.c_str());

					mark_entry_for_deletion(filename, pEntry);

					// release the cache entry mutex
					pEntry->unlock();

					LOG_INFO1("CACHE: Image in cache no longer on disk %s\n", filename.c_str());
					reason = "Image in cache no longer on disk " + filename;
					return XOS_FAILURE;
				}


				// The image file is still on disk.
				// We still have to make sure image it is still the same file
				// by checking the time stamp.

				// If the image file has changed, we have to remove this
				// cache entry first. And then reload the file and add it
				// to the cache as if it were a new file.
//				if ( img_stat.st_mtime > pEntry->lastUse ) {
				if (difftime(img_stat.st_mtime, pEntry->lastUse) > 0.0) {

					LOG_INFO1("CACHE: Image file is newer than entry in cache %s\n", filename.c_str());
					LOG_INFO2("CACHE: mtime = %ld, lastUse = %ld\n", img_stat.st_mtime, pEntry->lastUse);
					LOG_INFO1("CACHE: Killing entry of changed file %s\n", filename.c_str());

					mark_entry_for_deletion(filename, pEntry);

					// release the cache entry mutex
					pEntry->unlock();

					LOG_INFO("CACHE: Waiting 100 milliseconds...\n");

					xos_thread_sleep(100);

					// try again; the next time round, we won't find an entry for this file
					// which means that the file will be loaded from disk and added to the cache.
				   	continue;
				}

				// If we get to this point, it means that the file on disk
				// has not changed. We can return the image from this cache
				// entry to the client.
				// We will have to validate the user's session before returning
				// the image from cache.

				LOG_FINEST("CACHE: Image in cache is up to date\n");

				// update the access time
				pEntry->lastUse = time(0);

				LOG_FINEST("CACHE: checking session id\n");


				// Now check if the user has viewed the file before

				// Check if the user session has been associated with this filename
				SessionInfoMap::iterator i;
				pEntry->sessions.size();
				i = pEntry->sessions.find(sessionId);

				// This session has not retrived this file before.
				// We will have to validate the session first.
				if (i == pEntry->sessions.end()) {


					LOG_INFO1("CACHE: Session is new for this cache entry %s\n", filename.c_str());
					LOG_INFO("CACHE: Revalidating session via impersonation server\n");

					// Create a new user
					SessionInfo newSession(userName, sessionId, 0);

					// Ask the imp server if this user can read the file.
					std::string validationFailedReason;
					if (isFileReadable(newSession, filename, validationFailedReason)) {

						LOG_FINEST("CACHE: validate session OK\n");

						// If yes, add this user and sesion id to the list of sessions
						// that have retrieved this file.
#ifdef CACHE_SESSION
//						LOG_INFO("CACHE: adding session to this cache entry\n");
//						pEntry->addSession(newSession);
#endif
						// OK user can read the file.
						// We will return the image from this cache entry.
						goto success;

					} else {

						// If no, return here.
						LOG_INFO4("CACHE: file not readable by user %s session id %.7s file %s: %s\n",
								newSession.name.c_str(), newSession.sessionId.c_str(),
								filename.c_str(), reason.c_str());
						reason = "Authentication failed: " + validationFailedReason;
						pEntry->unlock();
						return XOS_FAILURE;

					}

				} else {	// Found this session id associated with the file.

					LOG_FINEST1("CACHE: Session exists for this cache entry %s\n", filename.c_str());

					// The user has accessedthis file before.
					// Check if the time between last validation time
					// and now is less than 1 minutes.
					SessionInfo& session = i->second;
					time_t now = time(NULL);

					// If last validation time is > 1 minutes
					// then check with the imp server again
					// to make sure that the session id is still valid
					// and that the user still has access
					// to this file.
					if ((now - session.lastValidation) > MAX_IDLE_TIME) {
						LOG_INFO2("CACHE: Session too old file = %s lastValidation time = %s\n",
								filename.c_str(), asctime(localtime(&(session.lastValidation))));
						LOG_INFO("CACHE: Revalidating session via impersonation server\n");

						// Revalidae the user
						// Ask the imp server if this user can read the file.
						std::string validationFailedReason;
						if (!isFileReadable(session, filename, validationFailedReason)) {

							// If no, return here.
							LOG_INFO4("CACHE: file not readable by user %s session id %.7s file %s: %s\n",
									session.name.c_str(), session.sessionId.c_str(),
									filename.c_str(), validationFailedReason.c_str());
							// Remove this user from the list
							LOG_INFO("CACHE: Removing invalid session from this cache entry\n");
							pEntry->removeSession(session.sessionId);
							reason = "Authentication failed: " + validationFailedReason;
							pEntry->unlock();
							return XOS_FAILURE;

						}

						LOG_INFO2("CACHE: validate session OK file = %s, lastValidation = %s\n",
								filename.c_str(), asctime(localtime(&(session.lastValidation))));


					} else {

						LOG_FINEST1("CACHE: Session is still valid for this cache entry for file %s\n",
								filename.c_str());
					}

				}

success:
				LOG_INFO1("CACHE: Returning the image from cache for %s\n", filename.c_str() );
				// and pass back pointer to Diffimage object
				*ppEntry = pEntry;


				return XOS_SUCCESS;

			} else {	// pEntry->isValid == FALSE

				LOG_INFO("CACHE: Found image in cache but entry was invalid\n");

				pEntry->unlock();

			}

		} else {	// pthread_mutex_trylock: Failed to lock the cache entry

			LOG_FINEST("CACHE: Found image in cache but entry was locked\n");

			// release the hash table mutex
			if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
				LOG_SEVERE("ERROR in cache_get_image: xos_mutex_unlock failed for cache table mutex");
				xos_error_exit("get_cache_entry -- error unlocking hash table mutex");
			}
			LOG_FINEST("Unlocked cache table");
		}


		LOG_FINEST("CACHE: Waiting 100 ms before search for image in cache again...\n");

		xos_thread_sleep(100);

		// Go back to look for the image again in cache.
		continue;

	} // while (TRUE)


	LOG_INFO1("CACHE: Image not found in cache %s\n", filename.c_str());


	// Image not found in cache.

	SessionInfo newSession(userName, sessionId, 0);

	LOG_FINEST("CACHE: Validate the session via impersonation server\n");


	// Check if the session id is valid and the user has read permission
	// for this file
	std::string validationFailedReason;
	if (!isFileReadable(newSession, filename, validationFailedReason)) {

		// If no, return here.
		LOG_INFO4("CACHE: file not readable by user %s session id %.7s file %s: %s\n",
				newSession.name.c_str(), newSession.sessionId.c_str(),
				filename.c_str(), validationFailedReason.c_str());
		reason = "Authentication failed: " + validationFailedReason;
		// release the hash table mutex
		if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
			LOG_SEVERE("ERROR in cache_get_image: xos_mutex_unlock failed for cache table mutex");
			xos_error_exit("cache_get_image -- error unlocking hash table mutex");
		}
		LOG_FINEST("Unlocked cache table");
		return XOS_FAILURE;
	}



	// create a cache entry
	create_cache_entry( filename, &pEntry );

#ifdef CACHE_SESSION
//	LOG_INFO1("CACHE: Adding session to this entry %s\n", filename.c_str());
//	pEntry->addSession(newSession);
#endif

	// create_cache_entry() has locked the entry
	// and so we can release the hash table mutex so that
	// other threads can access other entries in this hash table.
	if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
		LOG_SEVERE("ERROR in cache_get_image: xos_mutex_unlock failed for cache table mutex");
		xos_error_exit("cache_get_image -- error unlocking hash table mutex");
	}
	LOG_FINEST("Unlocked cache table");



	LOG_INFO1("CACHE: Loading image %s from disk\n", filename.c_str());

	// load the image and header from file
	if (!pEntry->load()) {

		// Failed to load the file
		// We have to delete the entry in the hash table.

		LOG_WARNING1("ERROR in cache_get_image: failed to load image from file %s", filename.c_str());

		// lock the hash table mutex
		if ( xos_mutex_lock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
			LOG_SEVERE("ERROR in cache_get_image: xos_mutex_lock failed for cache table mutex");
			xos_error_exit("cache_get_image -- error unlocking hash table mutex");
		}
		LOG_FINEST("Locked cache table");


		LOG_INFO1("CACHE: Removing entry from cache %s\n", filename.c_str());

		mark_entry_for_deletion(filename, pEntry);

		// release the cache entry mutex
		pEntry->unlock();

		// release the hash table mutex
		if ( xos_mutex_unlock( & mCacheHashTableMutex ) != XOS_SUCCESS ) {
			LOG_SEVERE("ERROR in cache_get_image: xos_mutex_lock failed for cache table mutex");
			xos_error_exit("create_cache_entry -- error unlocking hash table mutex");
		}
		LOG_FINEST("Unlocked cache table");

		reason = "Failed to load image file " + filename;
		return XOS_FAILURE;

	} else {

  		pEntry->isValid = TRUE;

	}

	LOG_INFO1("CACHE: Returning newly loaded image %s\n", filename.c_str());

	*ppEntry = pEntry;

	// report success
	return XOS_SUCCESS;

}



