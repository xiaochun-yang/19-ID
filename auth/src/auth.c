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

/* auth.c */
#include "auth.h"


xos_boolean_t auth_user_in_group( gid_t gid,
											 auth_key * key )
	{
	/* define group relationships */
	gid_t	auth_groups[10][10] = {
		{ 27, 28, -1 },
		{ 28, -1 },
		{ 15, -1 },
		{ 26, 27, 28, 15, -1 },
		{ 29, 28, -1 },
		{ -1 }
	};

	/* local variables */
	int 	primaryGroupIndex;
	int 	secondaryGroupIndex;

	/* return true if user's primary group matches */
	if ( key->user.pw_gid == gid )
		  {
		  return TRUE;
		  }

	/* find primary group in secondary group table */
	primaryGroupIndex = 0;
	while ( auth_groups[ primaryGroupIndex ][0] != key->user.pw_gid )
		{
		/* handle case of primary group not in table */
		if ( auth_groups[ primaryGroupIndex ][0] == -1 )
			{
			xos_error("Primary group %d not found in secondary group table", key->user.pw_gid );
			return FALSE;
			}
		
		primaryGroupIndex ++;
		}

	/* check for matches between secondary group ids and the gid of the file */
	secondaryGroupIndex = 1;
	while ( auth_groups[ primaryGroupIndex ][secondaryGroupIndex] != -1 )
		{
		/* return TRUE if secondary */
		if ( auth_groups[ primaryGroupIndex ][ secondaryGroupIndex ] == gid )
			{
			return TRUE;
			}
		
		secondaryGroupIndex ++;
		}

	/* return FALSE if gid not a secondary group of the user */
	return FALSE;
	}


xos_boolean_t auth_file_readable( const char * filepath,
											 auth_key * key )
	{
	/* local variables */
	struct stat status;

	//puts("@@@@@@@@@@@@@@@@@@@ Calling auth_file_readable @@@@@@@@@@@@@@@@@@@");
	//printf("@@@ filepath = %s, uid = %d, gid = %d\n", filepath, key->user.pw_uid,  key->user.pw_gid );
	
	/* get status of file */
	if ( stat( filepath, & status ) != 0 )
		{
		xos_error_sys("Unable to stat %s", filepath );
		return FALSE;
		}

	/* make sure filepath points to a regular file */
	if ( ! S_ISREG( status.st_mode) )
		{
		xos_error("%s is not a regular file", filepath );
		return FALSE;
		}

	/* check if user is in staff group */
	if ( key->user.pw_gid == 26 )
		{
		return TRUE;
		}

	/* check if file owned by user and readable by user */
	if ( key->user.pw_uid == status.st_uid )
		  {
		  return (status.st_mode & S_IRUSR);
		  }

	/* return true is file is group readable and user in group */
	if ( auth_user_in_group( status.st_gid, key ) )
		 {
		 return (status.st_mode & S_IRGRP);
		 }

	/* check if file is world readable */
	return ( status.st_mode & S_IROTH );
	}




xos_boolean_t auth_file_writable( const char * filepath,
											 auth_key * key )
	{
	/* local variables */
	struct stat status;

	/* get status of file */
	if ( stat( filepath, & status ) != 0 )
		{
		xos_error_sys("Unable to stat %s", filepath );
		return FALSE;
		}

	/* make sure filepath points to a regular file */
	if ( ! S_ISREG( status.st_mode) )
		{
		xos_error("%s is not a regular file", filepath );
		return FALSE;
		}

	/* check if file owned by user and writable by user */
	if ( key->user.pw_uid == status.st_uid )
		  {
		  return (status.st_mode & S_IWUSR);
		  }

	/* return true is file is group writable and user in group */
	if ( auth_user_in_group( status.st_gid, key ) )
		 {
		 return (status.st_mode & S_IWGRP);
		 }

	/* check if file is world readable */
	return ( status.st_mode & S_IWOTH );
	}


xos_boolean_t auth_directory_readable( const char * dirpath,
											 		auth_key * key )
	{
	/* local variables */
	struct stat status;

	/* get status of file */
	if ( stat( dirpath, & status ) != 0 )
		{
		xos_error_sys("Unable to stat %s", dirpath );
		return FALSE;
		}

	/* make sure filepath points to a directory */
	if ( ! S_ISDIR( status.st_mode) )
		{
		xos_error("%s is not a directory", dirpath );
		return FALSE;
		}

	/* check if user is in staff group */
	if ( key->user.pw_gid == 26 )
		{
		return TRUE;
		}

	/* check if file owned by user and readable/executable by user */
	if ( key->user.pw_uid == status.st_uid )
		  {
		  return (status.st_mode & S_IRUSR) && ( status.st_mode & S_IXUSR );
		  }

	/* return true is file is group readable/executable and user in group */
	if ( auth_user_in_group( status.st_gid, key ) )
		 {
		 return (status.st_mode & S_IRGRP) && ( status.st_mode & S_IXGRP );
		 }

	/* check if directory is world readable/executable */
	return ( status.st_mode & S_IROTH ) && ( status.st_mode & S_IXOTH );
	}



xos_boolean_t auth_directory_writable( const char * dirpath,
											 		auth_key * key )
	{
	/* local variables */
	struct stat status;

	/* get status of file */
	if ( stat( dirpath, & status ) != 0 )
		{
		xos_error_sys("Unable to stat %s", dirpath );
		return FALSE;
		}

	/* make sure filepath points to a directory */
	if ( ! S_ISDIR( status.st_mode) )
		{
		xos_error("%s is not a directory", dirpath );
		return FALSE;
		}

	/* check if file owned by user and writable by user */
	if ( key->user.pw_uid == status.st_uid )
		  {
		  return (status.st_mode & S_IWUSR);
		  }

	/* return true is file is group writable and user in group */
	if ( auth_user_in_group( status.st_gid, key ) )
		 {
		 return (status.st_mode & S_IWGRP);
		 }

	/* check if directory is world writable */
	return ( status.st_mode & S_IWOTH );
	}


void auth_crypt_buffer( char 		* buffer, 
								int 		bufferSize,
								char 		* key )
	{
	/* local variables */
	char	* sourcePointer;
	char 	outputBlock[8];
	int 	sourceCount;
	int c;
	/* loop over input buffer in blocks of 8 bytes */
	for ( sourceCount = 0, sourcePointer = buffer; 
			sourceCount < bufferSize; 
			sourceCount += 8, sourcePointer += 8  )
		{
		/* encrypt next block of 8 bytes */
		for (  c = 0;
				 c < 8;
				 c++
				 )
			{
			sourcePointer[c] = sourcePointer[c] ^ key[c];
			}
		/* copy encrypted block back into input buffer */
		/* memcpy( sourcePointer, outputBlock, 8 ); */
		}
	}


void auth_swap_bytes( char * buffer, 
							 int bufferSize )
	{
	/* local variables */
	char 	* ptr;
	int   count;
	char	newByteOne;

	//puts("Swapping bytes...");

	//puts( buffer );

	for ( ptr = buffer, count = 0;
			count < bufferSize;
			ptr += 2, count += 2 )
		{
		newByteOne = *(ptr+1);
		*(ptr+1) = *ptr;
		*ptr = newByteOne;
		}

	//puts( buffer );
	}


void auth_encrypt_buffer( char 		* buffer, 
								  int 		bufferSize,
								  auth_key	* key )
	{
#ifdef LITTLE_ENDIANa
	auth_swap_bytes( buffer, bufferSize );
#endif

	auth_crypt_buffer( buffer, bufferSize, key->encryptionKey );
	}


void auth_decrypt_buffer( char 		* buffer, 
								  int 		bufferSize,
								  auth_key 	* key )
	{
	auth_crypt_buffer( buffer, bufferSize, key->encryptionKey );

#ifdef LITTLE_ENDIANa
	auth_swap_bytes( buffer, bufferSize );
#endif
	}


char * auth_get_id( auth_key * key )
	{
	return key->id;
	}

xos_result_t auth_check_id( char * id, 
									 auth_key * key )
	{
	if ( strncmp( id, key->id, 128 ) == 0 )
		{
		//puts("Match");
		return XOS_SUCCESS;
		}
	else
		{
		//puts("Mismatch");
		return XOS_FAILURE;
		}
	} 


xos_result_t auth_load_key( char 		* userName,
									 auth_key	* key )
	{
	/* local variables */
	FILE * file;
	char buffer[200];
	char filename[255];
	struct passwd * passwordEntryPtr;

	int rc;

	/* look up password entry for the user */
	rc = getpwnam_r( userName,
						  &key->user,
						  key->passwdBuffer,
						  BUFSIZ,
						  &passwordEntryPtr
						  );
	if ( passwordEntryPtr == NULL )
		{
		xos_error("auth_get_key -- no user %s", userName );
		return XOS_FAILURE;
		}


	/* save the contents of the password structure */
	key->user = *passwordEntryPtr;
	
	/* generate filename of private key file */
	sprintf( filename, "/home/adm/keys/%s", userName );

	/* open the private key file */
	if ( ( file = fopen( filename, "r" ) ) == NULL ) 
		{
		xos_error("auth_get_key -- unable to open %s", filename );
		return XOS_FAILURE;
		}

	/* read first 200 bytes of private key file */
	if ( fread( buffer, 200, 1, file ) == EOF )
		{
		xos_error("auth_get_key -- error reading %s", filename );
		return XOS_FAILURE;
		}

	/* copy bytes 100-115 of private key file to encryption key buffer */
	memcpy( key->encryptionKey, buffer + 100, 16 );

#ifdef LITTLE_ENDIANa
	auth_swap_bytes( key->encryptionKey, 16 );
#endif

	/* close the private key file */
	fclose( file );

	/* generate filename of private key file */
	sprintf( filename, "/home/adm/keys/%s.pub", userName );

	/* open the private key file */
	if ( ( file = fopen( filename, "r" ) ) == NULL ) 
		{
		xos_error("auth_get_key -- unable to open %s", filename );
		return XOS_FAILURE;
		}

	/* read first 200 bytes of public key file */
	if ( fread( buffer, 200, 1, file ) == EOF )
		{
		fclose(file);
		xos_error("auth_get_key -- error reading %s", filename );
		return XOS_FAILURE;
		}

	/* copy bytes 20-147 of private key file to id buffer */
	memcpy( key->id, buffer + 20, 127 );
	key->id[127] = NULL;

	/* close the private key file */
	fclose( file );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t auth_get_challenge_string( char * challengeString, 
													 auth_key * key )
	{
	/* local variables */
	int x;
	int y;

	/* seed the randoma number generator */
	srand( time(0) % 10000 );
	
	/* calculate two random integers */
	x = rand() % 16384;
	y = rand() % 16384;
	
	/* create the challenge and expected response strings */
	sprintf( challengeString, "%d %d                ", x, y );
	sprintf( key->responseString, "%d                ", x + y );

	/* encrypt the challenge string */
	auth_encrypt_buffer( challengeString, 16, key );

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t auth_get_response_string( char * responseString,
													char * challengeString,
													auth_key * key )
	{
	/* local variables */
	int x;
	int y;

	//printf("challenge = %s\n", challengeString );

	/* decrypt the challenge string */
	auth_decrypt_buffer( challengeString, 16, key );

	//printf("challenge = %s\n", challengeString );

   /* parse the challenge string */
	if ( sscanf( challengeString, "%ld %ld", &x, &y ) != 2 )
		{
		xos_error("Error parsing challenge string.");
		return XOS_FAILURE;
		}

	/* create the response string */
	sprintf( responseString, "%d                ", x + y );

	/* encrypt the response string */
	auth_encrypt_buffer( responseString, 16, key );

	/* report success */
	return XOS_SUCCESS;
	}


xos_boolean_t auth_response_string_ok( char * responseString,
													auth_key * key )
	{
	/* decrypt the response string */
	auth_decrypt_buffer( responseString, 16, key );

	/* compare response to expected response */
	if ( strncmp( responseString, key->responseString ,16) == 0 ) 
		{
		return TRUE;
		}
	else
		{
		return FALSE;
		}
	}





void testPassword ( char * userName,
						  char * password )
	{
	FILE * passwordFile;
	char filebuffer[20000];
	size_t filesize;
	char searchString[255];
	char * storedPassword;

	passwordFile = fopen( "/var/yp/src/passwd", "r" );
	
	if ( passwordFile == NULL ) return;

	filesize = fread( filebuffer, 20000, 1, passwordFile ); 

	sprintf( searchString, "\n%s:", userName );
	storedPassword = strstr( filebuffer, searchString ) + strlen(userName) + 2;


	storedPassword[13] = 0; 

	//puts(storedPassword);

	fclose( passwordFile );
	}
