extern "C" {
#include "xos.h"
}
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "log_quick.h"
#include "ImpListDirectory.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "XosFileUtil.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpWriteFiles.h"
#include "ImpFileAccess.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy = new ImpRegister(IMP_WRITEFILES, &ImpWriteFiles::createCommand, false);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpWriteFiles::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpWriteFiles(n, s);
}


/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFiles::ImpWriteFiles()
    : ImpCommand(IMP_WRITEFILE, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFiles::ImpWriteFiles(HttpServer* s)
    : ImpCommand(IMP_WRITEFILE, s)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFiles::ImpWriteFiles(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpWriteFiles::~ImpWriteFiles()
{
}


/*************************************************
 *
 * execute
 *
 * #define S_IRWXU 00700         // read, write, execute: owner
 * #define S_IRUSR 00400         // read permission: owner
 * #define S_IWUSR 00200         // write permission: owner
 * #define S_IXUSR 00100         // execute permission: owner 
 * #define S_IRWXG 00070         // read, write, execute: group 
 * #define S_IRGRP 00040         // read permission: group
 * #define S_IWGRP 00020         // write permission: group
 * #define S_IXGRP 00010         // execute permission: group
 * #define S_IRWXO 00007         // read, write, execute: other
 * #define S_IROTH 00004         // read permission: other
 * #define S_IWOTH 00002         // write permission: other 
 * #define S_IXOTH 00001         // execute permission: other

 *************************************************/
void ImpWriteFiles::execute()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();

    mode_t fileMode;
    bool impAppend = false;
    bool impWriteBinary = false;
    
    HttpResponse* response = stream->getResponse();
    response->setContentType(WWW_PLAINTEXT);

	std::string tmp = "";	
    if (request->getParamOrHeader(IMP_WRITEBINARY, tmp)) {
		if ((tmp == "true") || (tmp == "true"))
			impWriteBinary = true;
		else
			impWriteBinary = false;
	}
    	
	std::string writeMode = "w";
	
	// Loop until we have no more files to read from request body
	bool hasMore = true;
	while (hasMore) {
		hasMore = stream->nextFile();
		if (!hasMore)
			break;

	std::string impFilePath = stream->getCurFilePath();
	// Read next file size
	 long fileSize = stream->getCurFileSize();
//	 LOG_INFO2("cur filepath = %s size = %d", impFilePath.c_str(), fileSize);

    // try to open the file
    FILE* file;

    //ImpFileAccess::prepareDestinationFile(
    //    impFilePath,
    //    fileMode,
    //    impAppend,
    //    fileNeedBackup,
    //    fileBackuped,
    //    request
    //);  
    std::string tmpPath = impFilePath;
    ImpFileAccess::prepareDestinationTmpFile(
        tmpPath,
        fileMode,
        impAppend,
        request
    );  
	if (impAppend) {
		writeMode = "a+";
    } else {
		writeMode = "w";
    }
	if (impWriteBinary)
		writeMode += "b";
	else
		writeMode += "t"; 
		

    if ((file = fopen(tmpPath.c_str(), writeMode.c_str())) == NULL) {
		  int errCode = errno;
		  std::string errStr = XosFileUtil::getFopenErrorString(errCode);
        LOG_WARNING2("writeFile fopen failed for %s because %s", tmpPath.c_str(), errStr.c_str());
        throw XosException(561, std::string(SC_561) + " " + XosFileUtil::getErrorCode(errCode));
    }

    // Read content of the request
    char buf[1024];
    int numRead = 0;
    int numWritten = 0;

    long totRead = 0;
    long totWritten = 0;
    
//    LOG_INFO1("Started reading file %s", impFilePath.c_str());

    // Read until we have all of the bytes
    while ((numRead = stream->readCurFileContent(buf, 1024)) > 0) {
    
        // Write the buffer into the file
        if ((numWritten = fwrite(buf, 1, numRead, file)) != numRead) {
				int errCode = errno;
				std::string errStr = XosFileUtil::getErrorString(errCode);
            // close file for writing
            fclose(file);
            // delete the file
            remove(tmpPath.c_str());
	    LOG_WARNING2("writeFile fwrite failed for %s because %s", tmpPath.c_str(), errStr.c_str());
            throw XosException(562, std::string(SC_562) + " " + XosFileUtil::getErrorCode(errCode));
        }

        totRead += numRead;
        totWritten += numWritten;
	
    }

//    LOG_INFO1("Finished reading file %s", impFilePath.c_str());

		fclose(file);

	if (totRead != fileSize) {
            sprintf(buf, "%s: expected file size %ld but got %ld",
                    SC_578, fileSize, totRead);
            // remove file
            remove(tmpPath.c_str());
            throw XosException(578, buf);
        }

    // File incomplete
    if (totWritten < totRead) {
        sprintf(buf, "%s: got (%ld) but written (%ld)", SC_577, totRead, totWritten);
        // remove file
        remove(tmpPath.c_str());
        throw XosException(577, buf);
    }

    // set the file permissions
    if (chmod( tmpPath.c_str(), fileMode ) != 0 ) {
		  int errCode = errno;
		  std::string errStr = XosFileUtil::getChmodErrorString(errCode);
        LOG_WARNING2("writeFile Error chmod failed for %s because %s", tmpPath.c_str(), errStr.c_str());
        throw XosException(563, std::string(SC_563) + " " + XosFileUtil::getErrorCode(errCode));
    }


    //rename the tmp file to destnation file
    bool fileNeedBackup = false;
    bool fileBackuped = false;
    ImpFileAccess::backupDestinationFileAtTheEnd( impFilePath, fileMode, fileNeedBackup, fileBackuped, request );
    if (rename( tmpPath.c_str( ), impFilePath.c_str( ) )) {
        int errCode = errno;
        LOG_WARNING3( "rename file from %s to %s failed: %d",
        tmpPath.c_str( ), impFilePath.c_str( ), errCode );
        throw XosException(581, std::string(SC_581) + " " + XosFileUtil::getErrorCode(errCode));
    }

	 std::string body;
	 std::string warning;
    if (fileNeedBackup) {
        ImpFileAccess::writeBackupWarning(response, warning, impFilePath, fileBackuped);
		  body = XosStringUtil::trim(warning) + "\n";
    }
    body += "OK " + impFilePath + "\n";
   
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

//	LOG_INFO1("Finished writing file %s", impFilePath.c_str());
    
	} // end while stream->nextFile()

//	LOG_INFO("Finished writing all files");

    stream->finishWriteResponse();

}

