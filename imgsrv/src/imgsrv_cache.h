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

#ifndef IMGSRV_CACHE_H
#define IMGSRV_CACHE_H

/**
 * @file imgsrv_cache.h
 *
 * Header file for accessing cache for the image server.
 * Used by imgsrv_client.
 */

#include <string>
#include <map>
#include <ImgSrvCacheEntry.h>

class ImgSrvCacheEntry;

/**
 * @func xos_result_t cache_initialize( void )
 * @brief Initializes the cache.
 * @return XOS_SUCCESS if cache is initialized OK. Else returns XOS_FAIURE.
 */
xos_result_t cache_initialize( void );

/**
 * @func XOS_THREAD_ROUTINE garbage_collector_thread (void* arg)
 * @brief Remove the oldest entries from cache when it is full.
 * The entry object is also deleted.
 *
 * @param junk Not used.
 * @return Platform specific return value for thread.
 */
XOS_THREAD_ROUTINE garbage_collector_thread
	(
	void *arg
	);


void cache_get_image( const std::string& 		filename,
							const std::string& 			userName,
							const std::string&			sessionId,
							ImgSrvCacheEntrySafePtr	      &ppEntry);

void cache_delete_image( ImgSrvCacheEntry *pEntry);


xos_result_t readImageHeaderNoCache(const std::string& filename,
		const std::string& userName, const std::string& sessionId, std::string& header, std::string& reason);



#endif
