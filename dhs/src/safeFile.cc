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


// *************************************************************************
// safeFiles.c
// These function allows a root process to create directories at a non-root 
// user's request.  Privileges are checked before a directory is created. 
// If the user does not have privilege, an error is returned.
//
// Note: designed to run as root, but does not crash with limited privileges
// *************************************************************************

// local include files
#include "xos.h"
  //#include "auth.h"
#include "string.h"
#include "auth.h"
#include "safeFile.h"
#include "errno.h"
#include "log_quick.h"
#include "DcsConfig.h"

extern DcsConfig gConfig;

//std::string mDirectoryRestriction = "/data";

xos_result_t setDirectoryRestriction( )
   {
//	mDirectoryRestriction = gConfig.getStr("dhs.directoryRestriction");
//   if (mDirectoryRestriction == "")
//      {
//      mDirectoryRestriction = "/data";
//      }
   }


// ************************************************************************
// 1) If the directory exists:
//       Returns XOS_SUCCESS if user can write to it.
//       Returns XOS_FAILURE if user cannot write to it.
// 2) If directory doesn't exist
//       Creates the directory if requesting user has permission to do so 
//       -- then returns XOS_SUCCESS.
//    If directory doesn't exist and requesting user does not have permission
//    to create the directory, returns XOS_FAILURE.
//
// SUMMARY:
// Returns XOS_SUCCESS if the requested directory is now available to write to.
// Returns XOS_FAILURE if the requested directory is not available to write to.
//
// 1) WARNING: THIS CODE CURRENTLY SUPPORTS A USER'S READ/WRITE
// SETTINGS FOR A DIRECTORY AND WILL NOT ATTEMPT TO CHANGE
// THE SETTINGS IF THE DIRECTORY ALREADY EXISTS.
// 2) WARNING: unix dependent
// ********************************************************
xos_result_t createWritableDirectory( const char * userName,
												  const char * directory )
	{
	// file permission variables (unix specific)
	struct stat status; // unix status of file
	struct passwd * passwordEntry; //Structure for holding user info
	auth_key key;

	int subDirectoryLength;
	char *nextSlash;
	char *directoryCopy;
	const char * searchDirectory;
	xos_boolean_t complete;

	xos_boolean_t lastDirectoryWritable;

	// look up password entry for the user
	if ( ( passwordEntry = getpwnam( userName ) ) == NULL )
		{
		LOG_WARNING1("No user %s", userName );
		return XOS_FAILURE;
		}
	
	key.user = *passwordEntry;

	//Check first character indicates absolute path name 
	if ( strncmp (directory,"/",1) != 0 )
		{
		LOG_WARNING("Must use absolute path name");
		return XOS_FAILURE;
		}

    //chech will be done in dcss level
	//Check first characters indicates correct root directory structure.
	//if ( strncmp (directory, mDirectoryRestriction.c_str() ,mDirectoryRestriction.length() ) != 0 )
	//	{
    //  LOG_WARNING1("dhs.directoryRestriction configured to write only to %s\n", mDirectoryRestriction.c_str() );
	//	return XOS_FAILURE;
	//	}

	//Save time and memory by checking first for
	// the existence of the directory.
	// If it exists then return now.
	if ( stat( directory, & status ) == 0 )
		{
		//directory already exists
		if ( auth_directory_writable( (const char *)directory, &key) )
			{
			return XOS_SUCCESS;
			}
		else
			{
			return XOS_FAILURE;
			}
		}

	// The directory doesn't exist. 
	// allocate memory for holding a copy of the directory string
	if ( ( directoryCopy = (char *)malloc( strlen( directory ) + 1 )) == NULL )
		xos_error_exit("createWritableDirectory: Error allocating memory");

	//Create a pointer to handle sub directories one at a time.
	searchDirectory = directory;
	lastDirectoryWritable = FALSE;
	complete = FALSE;
	while ( !complete )
		{
		nextSlash = (char *) strstr( searchDirectory,"/");
		if (nextSlash != NULL)
			{
			//found a directory slash
			while ( *nextSlash == '/')
				{
				//skip directory slashes that are side by side
				nextSlash += 1;
				}
			//check for end of string
			if (*nextSlash == 0x00)
				{
				//this was the final trailing slash
				complete = TRUE;
				}
			
			subDirectoryLength = (int)(nextSlash - directory);
			strncpy( directoryCopy, directory, subDirectoryLength );
			*(directoryCopy + subDirectoryLength )= 0x00; //terminate the string
			}
		else
			{
			//There were no more slashes
			complete = TRUE;
			strcpy( directoryCopy, directory);
			}


 		LOG_INFO(directoryCopy);
		
		searchDirectory = nextSlash;

		// check if user has permission to write to the requested directory & file
		if ( stat( directoryCopy, & status ) != 0 )
			{
			LOG_INFO("-- doesn't exist\n");
			
			if ( lastDirectoryWritable == TRUE )
				{
				LOG_INFO("creating directory\n");

				// directory doesn't exist create with user name
				if ( mkdir( directoryCopy , S_IRUSR | S_IWUSR | S_IXUSR ) != 0)
					{
					LOG_WARNING("createWritableDirectory: error writing directory\n");
					//perror(sys_errlist[errno]);
					free(directoryCopy);
					return XOS_FAILURE;
					}
				chown( directoryCopy , key.user.pw_uid, key.user.pw_gid);
				//chmod( directoryCopy , S_IRUSR | S_IWUSR | S_IXUSR );
				}
			else
				{
				LOG_WARNING("insufficient privilege to create directory\n");
				free (directoryCopy);				
				return XOS_FAILURE;
				}
			}
		else
			{
			LOG_INFO("-- exists");
			
			if (auth_directory_writable((const char *) directoryCopy, &key) )
				{
				LOG_INFO("-- writable\n");
				lastDirectoryWritable = TRUE;
				}
			else 
				{
				LOG_INFO("-- not writable\n");
				lastDirectoryWritable = FALSE;
				}
			}
		}
	
	free(directoryCopy);
	return XOS_SUCCESS;
	}

// ***************************************************************************
// prepareSafeFileWrite: This function can be called by a process that is 
//    expecting to write a particular file to a particular directory.  If the
//    file by the same name already exists in the directory, the file is moved
//    to a subdirectory ./OVERWRITTEN_FILES.  This function can be called by a 
//    root process acting on behalf of a user that is not root.  No file privileges
//    will be violated by the root process on behalf of a less privileged user.
// 
//    Returns --
//    1) a. XOS_SUCCESS if it is safe and possible to write a file to the requested
//          directory.
//       b. XOS_FAILURE if it is not safe or not possible to write a file
//          in the requested location.
//    2) backupFullPath
//       -- will contain the full pathname for the backup directory that a file was
//       moved to.
//       -- will be a null string if no backup was necessary.
//
// ***************************************************************************
xos_result_t prepareSafeFileWrite( const char * userName,
											  const char * directory,
											  const char * fileName,
											  char * backupFullPath )
	{
	struct stat status; // unix status of file
	char fullPath[MAX_PATHNAME];
	char backupDirectory[MAX_PATHNAME];
	const char *backupDirectoryName = "OVERWRITTEN_FILES";
	
	//initialize full path to a null string 
	*backupFullPath = 0x00; 

	// check directory writable, create directory if possible
	if ( createWritableDirectory( userName, directory ) == XOS_FAILURE )
		{
		//user cannot write to the target directory
		LOG_WARNING("prepareSafeFileWrite:  can not write to directory");
		return XOS_FAILURE;
		}

	// create a string that hold the directory and the pathname
	if ( strlen(directory) + strlen(fileName) < MAX_PATHNAME )
		{
		sprintf(fullPath,"%s/%s", directory, fileName);
		}
	else
		{
		//
		LOG_WARNING("prepareSafeFileWrite: file and pathname too long.");
		return XOS_FAILURE;
		}
	
	LOG_INFO(fullPath);
	//check to see if the file exists, we already checked the directory
	if ( stat( fullPath, & status ) != 0 )
		{
		// could not get status of file.
		if ( errno == ENOENT ) 
			{
			//make sure that the error is due to the non existence of the file.
			LOG_INFO("prepareSafeFileWrite: file not found in directory.\n");
			//*********************************************************
			//The file doesn't exist. safe to write to target directory.
			return XOS_SUCCESS;
			//*********************************************************
			}
		else 
			{
			//don't know why the status could not be obtained. Something is 
			//wrong and we can't recommend writing here.
			LOG_WARNING("prepareSafeFileWrite: error checking status of file.");
			return XOS_FAILURE;
			}
		}
	
	// The file was found in the directory
	LOG_INFO("prepareSafeFileWrite: file exists in directory\n");
	if ( S_ISREG( status.st_mode ) )
		{
		// There is a regular file sitting exactly where we want to put another.
		if ( strlen( directory ) + strlen(backupDirectory) < MAX_PATHNAME )
			{
			sprintf( backupDirectory,"%s/%s", directory, backupDirectoryName);
			}
		else
			{
			LOG_WARNING("prepareSafeFileWrite: backup pathname too long.");
			return XOS_FAILURE;
			}

		// create backup directory if possible
		if ( createWritableDirectory( userName, backupDirectory ) == XOS_FAILURE )
			{
			//Failed to create the backup directory.
			LOG_WARNING("prepareSafeFileWrite: could not create a backup directory");
			return XOS_FAILURE;
			}

		// Fill in the backup directory into the string so that the calling program
		// knows where the file was move to.
		if ( strlen( backupDirectory ) + strlen(fileName) < MAX_PATHNAME )
			{
			sprintf( backupFullPath,"%s/%s", backupDirectory, fileName);
			}
		else
			{
			LOG_WARNING("prepareSafeFileWrite: backup pathname too long.");
			return XOS_FAILURE;
			}
		
		//attempt to move the file to the backup directory.
		if ( rename( fullPath, backupFullPath) !=0 )
			{
			LOG_WARNING("prepareSafeFileWrite: could not move existing file.");
			return XOS_FAILURE;
			}
		// successfully backed up an existing file
		return XOS_SUCCESS;
		}
	else
		{
		LOG_WARNING("prepareSafeFileWrite: something exists in directory and its not a regular file.");
		return XOS_FAILURE;
		}
	}


xos_result_t safeChangeOwner( const char * userName,
											  const char * fullPath )
	{
	// file permission variables (unix specific)
	struct stat status; // unix status of file
	struct passwd * passwordEntry; //Structure for holding user info
	auth_key key;

	// look up password entry for the user
	if ( ( passwordEntry = getpwnam( userName ) ) == NULL )
		{
		LOG_WARNING1("No user %s", userName );
		return XOS_FAILURE;
		}
	
	key.user = *passwordEntry;

	LOG_INFO1("Changing ownership of %s", fullPath);
	//check to see if the file exists, we already checked the directory
	if ( stat( fullPath, & status ) != 0 )
		{
		// could not get status of file.
		if ( errno == ENOENT ) 
			{
			//see if the error is due to the non existence of the file.
			LOG_WARNING("file not found in directory.\n");
			//*********************************************************
			//The file doesn't exist.
			return XOS_FAILURE;
			//*********************************************************
			}
		else 
			{
			//don't know why the status could not be obtained.
			LOG_WARNING("error checking status of file.");
			return XOS_FAILURE;
			}
		}
	
	// The file was found in the directory
	LOG_INFO("file exists in directory\n");
	if ( S_ISREG( status.st_mode ) )
		{
		// There is a regular file sitting exactly where we expect it.
		chown( fullPath , key.user.pw_uid, key.user.pw_gid);
		// successfully changed ownership of existing file
		return XOS_SUCCESS;
		}
	else
		{
		LOG_WARNING("something exists in directory and its not a regular file.");
		return XOS_FAILURE;
		}
	}

xos_result_t createFileSystemFifo( const char * fifoName )
	{
   int status;

   //delete any possible file sitting where the fifo should be.
   unlink( fifoName);

   if ( mkfifo( fifoName, S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH) != 0) {
      return XOS_FAILURE;
   }

   return XOS_SUCCESS;
   }


