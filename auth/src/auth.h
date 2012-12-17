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

/* auth.h */

#ifndef AUTH_H
#define AUTH_H

#include <pwd.h>
#include <grp.h>
#include "xos.h"

#ifdef __cplusplus
extern "C" {
#endif

/* define the auth_key structure */
typedef struct {
	 char encryptionKey[128];
	 char decryptionKey[128];
	 char responseString[128];
	 char id[128];
	 struct passwd user;
    char passwdBuffer[ BUFSIZ ];  // Password entry buffer.
	} auth_key;

xos_boolean_t auth_user_in_group( gid_t gid,
											 auth_key * key );

xos_boolean_t auth_file_readable( const char * filepath,
											 auth_key * key );

xos_boolean_t auth_file_writable( const char * filepath,
											 auth_key * key );

xos_boolean_t auth_directory_readable( const char * dirpath,
											 		auth_key * key );

xos_boolean_t auth_directory_writable( const char * dirpath,
											 		auth_key * key );

void auth_crypt_buffer( char 		* buffer, 
								int 		bufferSize,
								char 		* key );

void auth_encrypt_buffer( char 		* buffer, 
								  int 		bufferSize,
								  auth_key	* key );

void auth_decrypt_buffer( char 		* buffer, 
								  int 		bufferSize,
								  auth_key 	* key );

xos_result_t auth_load_key( char 		* userName,
									 auth_key	* key );

xos_result_t auth_get_challenge_string( char * challengeString, 
													 auth_key * key );

xos_result_t auth_get_response_string( char * responseString,
													char * challengeString,
													auth_key * key );

xos_boolean_t auth_response_string_ok( char * responseString,
													auth_key * key );

#ifdef __cplusplus
}
#endif


#endif
