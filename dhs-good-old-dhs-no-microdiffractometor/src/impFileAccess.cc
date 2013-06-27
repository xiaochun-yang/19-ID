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
#include "string.h"
#include "string"
#include "impFileAccess.h"
#include "errno.h"
#include "log_quick.h"
#include "xos_http.h"
#include "XosTimeCheck.h"
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"



void initLogging();


ImpFileAccess::ImpFileAccess(std::string impHost,std::string userName, std::string sessionId) {
         mImpPort= 61001;
         mImpHost = impHost;
         mUserName = userName;
         mSessionId = sessionId;
};

xos_result_t ImpFileAccess::createWritableDirectory(std::string directory) {
	//Check first character indicates absolute path name 
    if (directory.find("/") != 0)
		{
		LOG_WARNING("Must use absolute path name");
		return XOS_FAILURE;
		}

    if (fileWritable( directory ) && queryFileType( directory) == "directory" ) 
        {
        return XOS_SUCCESS;
        }

    return createDirectory( directory);
}
   
std::string ImpFileAccess::getUserName() {
   return std::string(mUserName);
}

xos_result_t ImpFileAccess::backupExistingFile( std::string directory, std::string filename,	std::string backupDir, bool & movedTheFile )
	{
    movedTheFile = false;
    std::string fullPath = directory +"/" + filename;
    std::string fileType = queryFileType( fullPath );
    
    if ( fileType == "regular" ) 
        {
        if ( createWritableDirectory( backupDir ) == XOS_FAILURE) 
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




bool ImpFileAccess::fileWritable ( std::string directory) {
   std::string impErrno;
   int impStatusCode;
    
   try {
      HttpClientImp client1;
      // Should we read the response ourselves?
      client1.setAutoReadResponseBody(false);

      HttpRequest* request1 = client1.getRequest();

      std::string uri("");
	   //uri += std::string("/getFileStatus?impUser=") + userName
		//  + "&impSessionID=" + sessionId
		//   + "&impFilePath=" + directory
      //   + "&impShowSymlinkStatus=false";

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
      LOG_INFO2("http: %d: %s",impStatusCode, impErrno.c_str());

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



std::string ImpFileAccess::queryFileType ( std::string directory)
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
        LOG_INFO2("http: %d: %s",impStatusCode, impErrno.c_str());

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
                
                LOG_INFO1("FileType: %s", impFileType.c_str());
                return impFileType;
        }
        
     } catch (XosException& e) {
      LOG_SEVERE1("getFileStatus failed. Root cause: %s", e.getMessage().c_str());
      LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
    } catch (...)
        {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
        }
        
    return impFileType;
    }






xos_result_t ImpFileAccess::createDirectory( std::string directory)
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

	    if (response1 == NULL)
            {
			 LOG_SEVERE("Invalid HTTP Response from imp server.");
		    throw XosException("invalid HTTP Response from imp server\n");
            }
            
        impErrno = response1->getStatusPhrase();
		impStatusCode = response1->getStatusCode(); 
        LOG_INFO2("http: %d: %s",impStatusCode, impErrno.c_str());

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
    } catch (...)
        {
        LOG_SEVERE("Impersonation server may not be available.");
        LOG_SEVERE2("Check host '%s' and port %d ",mImpHost.c_str(), mImpPort );
        return XOS_FAILURE;
        }
        
    return XOS_SUCCESS;
	}




xos_result_t ImpFileAccess::renameFile ( std::string oldPath, std::string newPath )
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
        LOG_INFO2("http: %d: %s",impStatusCode, impErrno.c_str());

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



xos_result_t ImpFileAccess::deleteFile ( std::string fullPath )
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
        LOG_INFO2("http: %d: %s",impStatusCode, impErrno.c_str());

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

