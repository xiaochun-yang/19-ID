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
#include "ImpWriteFile.h"
#include "ImpFileAccess.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy = new ImpRegister(IMP_WRITEFILE, &ImpWriteFile::createCommand, false);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpWriteFile::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpWriteFile(n, s);
}


/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFile::ImpWriteFile()
    : ImpCommand(IMP_WRITEFILE, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFile::ImpWriteFile(HttpServer* s)
    : ImpCommand(IMP_WRITEFILE, s)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpWriteFile::ImpWriteFile(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpWriteFile::~ImpWriteFile()
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
void ImpWriteFile::execute()
    throw(XosException)
{
    time_t totStart;
    time_t start,end;
    double diff;
    HttpRequest* request = stream->getRequest();
    bool isChunked = request->isChunkedEncoding();
    long len = request->getContentLength();

    if (!isChunked && (len <= 0))
        throw XosException(411, SC_411);

    std::string impFilePath;
    mode_t fileMode;
    bool fileNeedBackup = false;
    bool fileBackuped = false;
    bool impAppend = false;
    bool impWriteBinary = false;

    if (!request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {
          LOG_WARNING1("missing %s parameter", IMP_FILEPATH);
        throw XosException(446, SC_446);
    }
	time(&totStart);
	time(&start);
    std::string tmpPath = impFilePath;
    ImpFileAccess::prepareDestinationTmpFile(
        tmpPath,
        fileMode,
        impAppend,
        request
    );  

	time (&end);
	if ((diff = difftime(end, start)) > 8.0) {
		LOG_WARNING2("writeFile took %f seconds to prepare tmp file %s", diff, tmpPath.c_str());
	}
	std::string tmp = "";		
    if (request->getParamOrHeader(IMP_WRITEBINARY, tmp)) {
		if ((tmp == "true") || (tmp == "true"))
			impWriteBinary = true;
		else
			impWriteBinary = false;
	}
    	
	std::string writeMode = "w";
	if (impAppend)
		writeMode = "a+";
	
	if (impWriteBinary)
		writeMode += "b";
	else
		writeMode += "t";     	     
 
	time(&start);
    // try to open the file
    FILE* file;
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

    // TODO check content-length

    while ((numRead = stream->readRequestBody(buf, 1024)) > 0) {

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

    fclose(file);
	time (&end);
	if ((diff = difftime(end, start)) > 8.0) {
		LOG_WARNING3("writeFile took %f seconds to write %lu bytes to tmp file %s", diff, totWritten, tmpPath.c_str());
	}

    if (!isChunked && (len > 0)) {
        if (len != totRead) {
            sprintf(buf, "%s: content-lenth (%ld) body length (%ld)",
                    SC_578, len, totRead);
            // remove file
            remove(tmpPath.c_str());
            throw XosException(578, buf);
        }
    }

    // File incomplete
    if (totWritten < totRead) {
        sprintf(buf, "%s: got (%ld) but written (%ld)", SC_577, totRead, totWritten);
        // remove file
        remove(tmpPath.c_str());
        throw XosException(577, buf);
    }
	time(&start);
    // set the file permissions
    if (chmod( tmpPath.c_str(), fileMode ) != 0 ) {
		  int errCode = errno;
		  std::string errStr = XosFileUtil::getChmodErrorString(errCode);
        LOG_WARNING2("writeFile Error chmod failed for %s because %s", tmpPath.c_str(), errStr.c_str());
        throw XosException(563, std::string(SC_563) + " " + XosFileUtil::getErrorCode(errCode));
    }

	time (&end);
	if ((diff = difftime(end, start)) > 8.0) {
		LOG_WARNING2("writeFile took %f seconds to chmod tmp file %s", diff, tmpPath.c_str());
	}
	time(&start);
    //rename the tmp file to destnation file
    ImpFileAccess::backupDestinationFileAtTheEnd( impFilePath, fileMode, fileNeedBackup, fileBackuped, request );
    if (rename( tmpPath.c_str( ), impFilePath.c_str( ) )) {
        int errCode = errno;
        LOG_WARNING3( "rename file from %s to %s failed: %d",
        tmpPath.c_str( ), impFilePath.c_str( ), errCode );
        throw XosException(581, std::string(SC_581) + " " + XosFileUtil::getErrorCode(errCode));
    }
	time (&end);
	if ((diff = difftime(end, start)) > 8.0) {
		LOG_WARNING3("writeFile took %f seconds to rename tmp file %s to %s", diff, tmpPath.c_str(), impFilePath.c_str());
	}
    HttpResponse* response = stream->getResponse();
    std::string body("OK");

    if (fileNeedBackup) {
	time(&start);
        ImpFileAccess::writeBackupWarning(
            response,
            body,
            impFilePath,
            fileBackuped
        );
	time (&end);
	if ((diff = difftime(end, start)) > 8.0) {
		LOG_WARNING2("writeFile took %f seconds to backup file %s", diff, impFilePath.c_str());
	}
    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());

    stream->finishWriteResponse();
	time (&end);
	if ((diff = difftime(end, totStart)) > 8.0) {
		LOG_WARNING1("writeFile took %f seconds in total", diff);
	}
}

