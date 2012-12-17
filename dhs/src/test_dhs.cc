#include "xos.h"
#include "xos_http.h"
#include "log_quick.h"

#ifdef IRIX
#include "sys/types.h"
#include "signal.h"
#endif
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"

#define MAX_PATHNAME 500

typedef struct
{
    char filename[MAX_PATHNAME];
    char sessionId[500];
    char userName[500];

    char message[500];

    xos_semaphore_t writeCompleteSemaphorePointer;
    xos_semaphore_t threadReadySemaphorePointer;
    xos_index_t bufferIndex;
    xos_thread_t thread;
} 	marccd_image_descriptor_t;


std::string mImpHost = "";
int mImpPort = 0;
std::string mUserName = "";
std::string mSessionId = "";
std::string mFifoName[2];

marccd_image_descriptor_t marCcdImageDescriptor[2];
xos_mutex_t mImageBufferMutex;
xos_index_t mFifoBufferIndex = 0;


/**
 *
 */
bool fileWritable(std::string directory) 
{
   std::string impErrno;
   int impStatusCode;
    
   try {
      HttpClientImp client1;
      // Should we read the response ourselves?
      client1.setAutoReadResponseBody(false);

      HttpRequest* request1 = client1.getRequest();

      std::string uri("");
	   uri += std::string("/getFilePermissions?impUser=") + mUserName
		   + "&impSessionID=" + mSessionId
		   + "&impFilePath=" + directory;

      request1->setURI(uri);
      request1->setHost( mImpHost );
      request1->setPort( mImpPort );
      request1->setMethod(HTTP_GET);

      // Send the request and wait for a response
      HttpResponse* response1 = client1.finishWriteRequest();

      if (response1 == NULL) {
			LOG_SEVERE("Invalid HTTP Response from imp server.");
         throw XosException("invalid HTTP Response from imp server\n");
      }
            
      impErrno = response1->getStatusPhrase();
      impStatusCode = response1->getStatusCode(); 
      LOG_INFO3("getFilePermissions http: %d: %s for %s",impStatusCode, impErrno.c_str(), directory.c_str());

      switch ( impStatusCode) {
         case 551:
            LOG_SEVERE("Session may have expired");
            return false;
          default:
            std::string impHeader = response1->getHeaderString();
            //LOG_INFO1("%s",impHeader.c_str());
            size_t pos = impHeader.find("impWritePermission: ") + strlen("impWritePermission: ");
            size_t pos1 = impHeader.find("\n", pos);
			   std::string impFileMode = impHeader.substr(pos, pos1 - pos -1) ;
                
            LOG_INFO1("FileMode: '%s'", impFileMode.c_str());
                
            if ( impFileMode == "true" ) {
               LOG_INFO("May write here");
               return true;
            } else {
               LOG_WARNING("Cannot write here");
               return false;
            }
      }
        
    } catch (XosException& e) {
      LOG_SEVERE1("getFilePermissions failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
		return false;
    } catch (...) {
      LOG_SEVERE("Impersonation server may not be available.");
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
      return false;
   }
   
   return true;
}

/**
 *
 */
std::string queryFileType(std::string directory)
	{
    std::string impErrno;
    int impStatusCode;
    std::string impFileType = "unknown";
    
    try {
	    HttpClientImp client1;
	    // Should we read the response ourselves?
	    client1.setAutoReadResponseBody(false);

	    HttpRequest* request1 = client1.getRequest();

	    std::string uri("");
	    uri += std::string("/getFileStatus?impUser=") + mUserName
		  + "&impSessionID=" + mSessionId
		   + "&impFilePath=" + directory
           + "&impShowSymlinkStatus=false";

	    request1->setURI(uri);
	    request1->setHost( mImpHost );
	    request1->setPort( mImpPort );
	    request1->setMethod(HTTP_GET);

	    // Send the request and wait for a response
        HttpResponse* response1 = client1.finishWriteRequest();

	    if (response1 == NULL)
            {
			 LOG_SEVERE("Invalid HTTP Response from imp server.");
		    throw XosException("invalid HTTP Response from imp server\n");
            }
            
        impErrno = response1->getStatusPhrase();
		  impStatusCode = response1->getStatusCode(); 
        LOG_INFO3("getFileStatus http: %d: %s for %s",
					impStatusCode, impErrno.c_str(),
					directory.c_str());

        switch ( impStatusCode) {
            case 551:
                LOG_SEVERE("Session may have expired");
                return impFileType;
    
            case 558:
                LOG_INFO("no file");
                impFileType = "ENOENT";
                return impFileType;
                
            default:
                std::string impHeader = response1->getHeaderString();
                //LOG_INFO1("%s",impHeader.c_str());
                size_t pos = impHeader.find("impFileType: ") + strlen("impFileType: ");
                size_t pos1 = impHeader.find("\n", pos);
			    impFileType = impHeader.substr(pos, pos1-pos -1);
                
                LOG_INFO2("FileType: %s for %s", impFileType.c_str(), directory.c_str());
                return impFileType;
        }
        
	 } catch (XosException& e) {
      LOG_SEVERE1("getFileStatus failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
    } catch (...) {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
	 }
        
    return impFileType;

}


/**
 *
 */
xos_result_t createDirectory(std::string directory)
{
    std::string impErrno;
    int impStatusCode;

    try {
	    HttpClientImp client1;
	    // Should we read the response ourselves?
	    client1.setAutoReadResponseBody(false);

	    HttpRequest* request1 = client1.getRequest();

	    std::string uri("");
	    uri += std::string("/createDirectory?impUser=") + mUserName
		   + "&impSessionID=" + mSessionId
		   + "&impDirectory=" + directory
           + "&impCreateParents=true"
           + "&impFileMode=drwx------";

	    request1->setURI(uri);
	    request1->setHost( mImpHost );
	    request1->setPort( mImpPort );
	    request1->setMethod(HTTP_GET);

	    // Send the request and wait for a response
        HttpResponse* response1 = client1.finishWriteRequest();

	    if (response1 == NULL){
			 LOG_SEVERE("Invalid HTTP Response from imp server.");
		    throw XosException("invalid HTTP Response from imp server\n");
		 }
            
        impErrno = response1->getStatusPhrase();
		  impStatusCode = response1->getStatusCode(); 
        LOG_INFO3("createDirectory http: %d: %s for %s",
					impStatusCode, impErrno.c_str(), directory.c_str());

        switch ( impStatusCode) {
            case 551:
                LOG_SEVERE("Session may have expired");
                return XOS_FAILURE;
        
            case 573:
                LOG_SEVERE("File already exists");
                return XOS_FAILURE;
                
            default:
                std::string impHeader = response1->getHeaderString();
                LOG_INFO1("%s",impHeader.c_str());
        }
        
    } catch (XosException& e) {
      LOG_SEVERE1("createDirectory failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
		return XOS_FAILURE;
    } catch (...) {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
        return XOS_FAILURE;
	 }
        
    return XOS_SUCCESS;
}

/**
 */
xos_result_t renameFile ( std::string oldPath, std::string newPath )
	{
    std::string impErrno;
    int impStatusCode;
    try {
	    HttpClientImp client1;
	    // Should we read the response ourselves?
	    client1.setAutoReadResponseBody(false);

	    HttpRequest* request1 = client1.getRequest();

	    std::string uri("");
	    uri += std::string("/renameFile?impUser=") + mUserName
		   + "&impSessionID=" + mSessionId
		   + "&impOldFilePath=" + oldPath
		   + "&impNewFilePath=" + newPath;

	    request1->setURI(uri);
	    request1->setHost( mImpHost );
	    request1->setPort( mImpPort );
	    request1->setMethod(HTTP_GET);

	    // Send the request and wait for a response
        HttpResponse* response1 = client1.finishWriteRequest();

	    if (response1 == NULL) {
			LOG_SEVERE("Invalid HTTP Response from imp server.");
			throw XosException("invalid HTTP Response from imp server\n");
		 }
     
        impErrno = response1->getStatusPhrase();
		impStatusCode = response1->getStatusCode(); 
        LOG_INFO4("renameFile http: %d: %s from %s to %s",
						impStatusCode, impErrno.c_str(), 
						oldPath.c_str(), newPath.c_str());

        switch ( impStatusCode) {
            case 445:
                LOG_SEVERE("Session may have expired");
                return XOS_FAILURE;
            case 446:
                LOG_SEVERE("Session may have expired");
                return XOS_FAILURE;
            case 581:
                LOG_SEVERE("Session may have expired");
                return XOS_FAILURE;
        
            default:
                return XOS_SUCCESS;
        }
        
    } catch (XosException& e) {
      LOG_SEVERE1("renameFile failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
		return XOS_FAILURE;
    } catch (...)
        {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
        return XOS_FAILURE;
        }

    return XOS_SUCCESS;
}


/**
 */
xos_result_t deleteFile (std::string fullPath )
	{
    std::string impErrno;
    int impStatusCode;
    try {
	    HttpClientImp client1;
	    // Should we read the response ourselves?
	    client1.setAutoReadResponseBody(false);

	    HttpRequest* request1 = client1.getRequest();

	    std::string uri("");
	    uri += std::string("/deleteFile?impUser=") + mUserName
		   + "&impSessionID=" + mSessionId
		   + "&impFilePath=" + fullPath;

	    request1->setURI(uri);
	    request1->setHost( mImpHost );
	    request1->setPort( mImpPort );
	    request1->setMethod(HTTP_GET);

	    // Send the request and wait for a response
        HttpResponse* response1 = client1.finishWriteRequest();

	    if (response1 == NULL) {
				LOG_SEVERE("Invalid HTTP Response from imp server.");
				throw XosException("invalid HTTP Response from imp server\n");
     	  }

        impErrno = response1->getStatusPhrase();
		impStatusCode = response1->getStatusCode(); 
        LOG_INFO3("deleteFile http: %d: %s for %s",impStatusCode, impErrno.c_str(), fullPath.c_str());

        switch ( impStatusCode) {
            case 581:
                LOG_SEVERE("Session may have expired");
                return XOS_FAILURE;
        
            default:
                return XOS_SUCCESS;
        }
        
    } catch (XosException& e) {
      LOG_SEVERE1("deleteFile failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
		return XOS_FAILURE;
    } catch (...)
        {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
        return XOS_FAILURE;
        }

    return XOS_SUCCESS;
}

/**
 */
xos_result_t createWritableDirectory(std::string directory)
{
	//Check first character indicates absolute path name 
	if (directory.find("/") != 0) {
		LOG_WARNING("Must use absolute path name");
		return XOS_FAILURE;
	}

	if (fileWritable(directory) && queryFileType(directory) == "directory") {
		return XOS_SUCCESS;
	}

	return createDirectory(directory);
}
   
/**
 *
 */
xos_result_t backupExistingFile(std::string directory, 
								std::string filename,
								std::string backupDir,
								bool& movedTheFile)
	{
    movedTheFile = false;
    std::string fullPath = directory +"/" + filename;
    std::string fileType = queryFileType( fullPath );
    
    if ( fileType == "regular" ) 
        {
        if (createWritableDirectory( backupDir ) == XOS_FAILURE) 
            {
            LOG_SEVERE1("Could not create backup directory: %s", backupDir.c_str() );
            return XOS_FAILURE;
            }
        //remove the old file from the backup directory
        deleteFile( backupDir + filename);
        
        if ( renameFile( fullPath, backupDir + filename) == XOS_SUCCESS )
            {
            movedTheFile = true;
            }
            else
            {
            LOG_SEVERE2(" Could not move %s to directory: %s", fullPath.c_str(), backupDir.c_str() );
            return XOS_FAILURE;
            }
        
        } else if (fileType == "directory" ) {
            LOG_SEVERE1("Directory exists with same name as data file to be written. %s", fileType.c_str() );
            return XOS_FAILURE;
        } else if (fileType == "ENOENT" ) {
            LOG_INFO1("No file here to backup: %s", fullPath.c_str() );
        } else {
            LOG_WARNING1("Can't recognize this filetype: %s", fileType.c_str() );
            LOG_SEVERE1("Can't recommend writing here %s", fullPath.c_str() );
        }
                
    
    return XOS_SUCCESS;
}

/**
 *
 */
xos_result_t impBackupFile(std::string directory, std::string filename) 
{

    if (createWritableDirectory(directory) == XOS_SUCCESS) {
        std::string fullPath = directory + "/" + filename;
        std::string backupDir = directory + "/OVERWRITTEN_FILES/";
        std::string backupPath = backupDir + filename;

        bool movedFile;
        if (backupExistingFile( directory, filename, backupDir, movedFile ) == XOS_FAILURE) {
            LOG_WARNING2("htos_note failedToBackupExistingFile %s %s", filename.c_str(), backupPath.c_str());
            LOG_WARNING("MarCcdControlThread: could not backup file");
            //but we allow the user to write their file anyway
        } else {
            if ( movedFile ) {
                // inform DCSS and GUI's that a file was backed up
                LOG_INFO2("htos_note movedExistingFile %s %s", fullPath.c_str(), backupPath.c_str());
            }
        }

    } else {
        LOG_INFO2("%s does *not* have permission to write to %s", mUserName.c_str(), directory.c_str());
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
}

/** 
 */
xos_result_t sendFifoOutputToImperson( int bufferIndex,
                                       std::string userName,
                                       std::string sessionId,
                                       std::string fileName) 
{

    try {

        HttpClientImp client2;
        // Should we read the response ourselves?
        client2.setAutoReadResponseBody(true);

        HttpRequest* request2 = client2.getRequest();

        std::string uri = "";
        uri += std::string("/writeFile?impUser=") + userName
               + "&impSessionID=" + sessionId
               + "&impFilePath=" + fileName
               + "&impFileMode=0740";

        request2->setURI(uri);
        request2->setHost(mImpHost);
        request2->setPort(mImpPort);
        request2->setMethod(HTTP_POST);

        request2->setContentType("text/plain");
        // Don't know the size of the entire content
        // so set transfer encoding to chunk so that
        // we don't have to set the Content-Length header.
        request2->setChunkedEncoding(true);

        LOG_INFO1("Open File %s",mFifoName[bufferIndex].c_str());
        FILE* input = fopen( mFifoName[bufferIndex].c_str(), "r");

        LOG_INFO1("Opened File %s",mFifoName[bufferIndex].c_str());
        if (input == NULL) {
            LOG_SEVERE1("Error Opening File %s",mFifoName[bufferIndex].c_str());
            throw XosException("Cannot open fifo file " + mFifoName[bufferIndex] );
        }

        // We need to read the response body ourselves
        char buf[1000000];
        int bufSize = 1000000;
        size_t numRead = 0;
        size_t sentTotal = 0;
        bool impConnectionGood = TRUE;

        LOG_INFO1("Read fifo File: %s",mFifoName[bufferIndex].c_str());
        while ((numRead = fread(buf, sizeof(char), bufSize, input)) > 0) {
            // Send what we have read
            if ( impConnectionGood ) {
                int tries = 0;
                do {
                try {
                    client2.writeRequestBody(buf, numRead);
                    impConnectionGood = true;
                } catch (XosException &e) {
                    LOG_SEVERE2("XosException while writing image: %d %s\n", e.getCode(), e.getMessage().c_str());
                    impConnectionGood = FALSE;
                    xos_thread_sleep(1000);
                } catch (...) {
                    LOG_SEVERE2("failed to write %d bytes after sending %d bytes \n", numRead, sentTotal);
                    //drain the image from the detector, but stop sending to impersonation server.
                    impConnectionGood = FALSE;
                    xos_thread_sleep(1000);
                }
                } while (impConnectionGood == FALSE && tries < 5);
            }
            sentTotal += numRead;
        }

        LOG_INFO1("close File %s",mFifoName[bufferIndex].c_str());
        //close the fifo
        fclose(input);

        if ( impConnectionGood ) {
            LOG_INFO2("Sent %d bytes for file %s \n", sentTotal, fileName.c_str());
            // Send the request and wait for a response
            HttpResponse* response2 = client2.finishWriteRequest();

            if (response2->getStatusCode() != 200) {
                LOG_SEVERE2("Error Writing file http error %d %s\n",
                            response2->getStatusCode(), response2->getStatusPhrase().c_str());
                impConnectionGood = FALSE;
            }
        }

        if (! impConnectionGood ) {
            LOG_WARNING1("htos_failed_to_store_image %s", fileName.c_str());
            return XOS_FAILURE;
        }

        return XOS_SUCCESS;

    } catch (XosException& e) {
        LOG_SEVERE1("Caught XosException: %s\n", e.getMessage().c_str());
    } catch (std::exception& e) {
        LOG_SEVERE1("Caught std::exception: %s\n", e.what());
    } catch (...) {
        LOG_SEVERE("Caught unknown exception\n");
    }

    return XOS_FAILURE;
}

/**
 */
XOS_THREAD_ROUTINE marccdImageWriterThreadRoutine( void *args ) 
{
    char fullImageName[1000];
    LOG_INFO("new thread");

    marccd_image_descriptor_t * thisImage = (marccd_image_descriptor_t *)args;
    //copy filename into local stack before posting semaphore
    strcpy(fullImageName,thisImage->filename);

    std::string sessionId = std::string(thisImage->sessionId);
    std::string userName = std::string(thisImage->userName);
    int bufferIndex = thisImage->bufferIndex;
	
	 // Pretending to wait for file to be ready for reading.
	 xos_thread_sleep(5000);
    
    xos_semaphore_post( &thisImage->threadReadySemaphorePointer );


    timespec time_stamp_1;
    clock_gettime( CLOCK_REALTIME, &time_stamp_1 );
    LOG_INFO2("expecting %s in buffer: %d \n", fullImageName, bufferIndex );

    strcpy(thisImage->message,"SUCCESS");

    if ( sendFifoOutputToImperson( bufferIndex, userName, sessionId, fullImageName ) != XOS_SUCCESS ) {
        LOG_SEVERE("error writing data file");
        strcpy(thisImage->message,"FAILURE");
//        writeImageWriteFailureResponseToDcss(fullImageName);
        LOG_INFO1("POST SEMAPHORE: %d",thisImage->bufferIndex);
        xos_semaphore_post( &thisImage->writeCompleteSemaphorePointer);
        XOS_THREAD_ROUTINE_RETURN;
    }

    //post the semaphore
    LOG_INFO1("POST SEMAPHORE: %d",thisImage->bufferIndex);
    xos_semaphore_post( &thisImage->writeCompleteSemaphorePointer);

    //wait for the file to become available on disk
    xos_thread_sleep(1000);
    //inform dcss
//    writeImageReadyResponseToDcss(fullImageName);
    LOG_INFO("end thread");

    XOS_THREAD_ROUTINE_RETURN;
}

/**
 */
int spinNextImageWriterThread(std::string userName, std::string sessionId, std::string fullPathName) 
{

    //go to next buffer
    LOG_INFO1("last mFifoBufferIndex: %d",mFifoBufferIndex);

    if (mFifoBufferIndex == 1)
		mFifoBufferIndex = 0;
	else 
		mFifoBufferIndex=1;

    LOG_INFO1("new mFifoBufferIndex: %d",mFifoBufferIndex);

    int bufferIndex=mFifoBufferIndex;

    xos_semaphore_wait( &marCcdImageDescriptor[bufferIndex].writeCompleteSemaphorePointer, 0 );

    marCcdImageDescriptor[bufferIndex].bufferIndex = bufferIndex;

    if ( xos_semaphore_create( &marCcdImageDescriptor[bufferIndex].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS ) {
        LOG_SEVERE("cannot create semaphore." );
        xos_error_exit("Exit.");
    }

    if ( xos_semaphore_create( &marCcdImageDescriptor[bufferIndex].threadReadySemaphorePointer, 0 ) != XOS_SUCCESS ) {
        LOG_SEVERE("Quantum315Thread: cannot create semaphore." );
        xos_error_exit("Exit.");
    }

    strcpy( marCcdImageDescriptor[bufferIndex].filename, (const char *)fullPathName.c_str() );
    strcpy( marCcdImageDescriptor[bufferIndex].sessionId, (const char *)sessionId.c_str() );
    strcpy( marCcdImageDescriptor[bufferIndex].userName, (const char *)userName.c_str() );

    if ( xos_thread_create(&marCcdImageDescriptor[bufferIndex].thread,& marccdImageWriterThreadRoutine, 
				&marCcdImageDescriptor[bufferIndex] ) != XOS_SUCCESS) {
        LOG_SEVERE("imageAssemblerRoutine: could not start new thread.");
        xos_error_exit("Exit.");
    }

    xos_semaphore_wait( &marCcdImageDescriptor[bufferIndex].threadReadySemaphorePointer, 0 );

    return bufferIndex;
}



/**
 */
int main(int argc, char** argv) 
{
	try {

		if (argc != 7) {
			printf("Usage: test <host> <port> <userName> <sessionId> <directory> <prefix>\n");
			exit(0);
		}

		LOG_QUICK_OPEN_STDOUT;
		set_save_logger_error(false);
		
		printf("IMPERSON TEST START\n"); fflush(stdout);

		mFifoName[0] = "./test1.mccd";
		mFifoName[1] = "./test2.mccd";

		// Create a new user
		int i = 1;

		// Create a new user
		mImpHost = argv[i]; ++i;
		mImpPort = atoi(argv[i]); ++i;
		mUserName = argv[i]; ++i;
		mSessionId = argv[i]; ++i;
		std::string directory = argv[i]; ++i;
		std::string prefix = argv[i]; ++i;


		bool done = false;
		int count = 1;	
		std::string rootName = "";
		std::string fileName = "";	
		std::string fullPath = "";
		int bufferIndex = 0;

		if ( xos_mutex_create( &mImageBufferMutex  ) == XOS_FAILURE ) {
			xos_error_exit("couldn't create mutex");
		}

		if ( xos_semaphore_create( &marCcdImageDescriptor[0].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS ) {
        xos_error_exit("cannot create semaphore." );
		}

		if ( xos_semaphore_create( &marCcdImageDescriptor[1].writeCompleteSemaphorePointer, 0 ) != XOS_SUCCESS ) {
			xos_error_exit("cannot create semaphore." );
		}

		xos_semaphore_post(&marCcdImageDescriptor[0].writeCompleteSemaphorePointer);
		xos_semaphore_post(&marCcdImageDescriptor[1].writeCompleteSemaphorePointer);

		while (!done) {

			if (count > 100) {
				rootName = prefix + "_" + XosStringUtil::fromInt(count);
			} else if (count > 10) {
				rootName = prefix + "_0" + XosStringUtil::fromInt(count);
			} else {
				rootName = prefix + "_00" + XosStringUtil::fromInt(count);
			}

			fileName = rootName + ".mccd";
			fullPath = directory + "/" + fileName;
			LOG_INFO1("Collecting image %s", fullPath.c_str());			

			// Back up old mccd file
			if (impBackupFile(directory, fileName) != XOS_SUCCESS)
				throw XosException("impBackFile failed for " + fullPath);

			// Write image
			LOG_INFO("LOCKING MUTEX");
			xos_mutex_lock( & mImageBufferMutex );
			LOG_INFO("Start thread");
			bufferIndex = spinNextImageWriterThread(mUserName, mSessionId, fullPath);
			LOG_INFO("UNLOCKING MUTEX");
			xos_mutex_unlock( &mImageBufferMutex );


			xos_thread_sleep(1000);

			++count;
		
		} // while !done
		
		printf("IMPERSON TEST DONE\n"); fflush(stdout);
		
		LOG_QUICK_CLOSE;

	} catch (XosException& e) {
		printf("IMPERSON TEST FAILED Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("IMPERSON TEST FAILED Caught unknown exception in main\n");
	}
	
	return 0;
}




