#include "xos.h"
#include "log_quick.h"
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include "ImpListDirectory.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "XosFileUtil.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "ImpReadFile.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy1 = new ImpRegister(IMP_READFILE, &ImpReadFile::createCommand, true);
static ImpRegister* dummy2 = new ImpRegister(IMP_ISFILEREADABLE, &ImpReadFile::createCommand, true);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpReadFile::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpReadFile(n, s);
}


/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpReadFile::ImpReadFile()
    : ImpCommand(IMP_READFILE, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpReadFile::ImpReadFile(HttpServer* s)
    : ImpCommand(IMP_READFILE, s)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpReadFile::ImpReadFile(const std::string& c, HttpServer* s)
    : ImpCommand(c, s)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpReadFile::~ImpReadFile()
{
}

/*************************************************
 *
 * run
 *
 *************************************************/
void ImpReadFile::execute()
    throw(XosException)
{

    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

    std::string impFilePath;
    std::string impFileStartOffset;
    std::string impFileEndOffset;

    long int fileStartOffset = 0;
    long int fileEndOffset = 0;
    long int fileOffset = 0;

    // valud url
    // http://host:port/filepath?impCommand=readFile
    // http://host:port/readFile?impFilePath=/filepath
    // http://host:port/readFile?impCommand=readFile&impFilePath=/filepath


    // If impFilePath param is not present, impCommand must be present
    // and equal to readFile. impFilePath is in the uri resource
    if (!request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {

        std::string impCommand;
        // If we get to this point while impCommand is not present,
        // it means that the uri resource is readFile.
        // So what's actually missing is not impCommand
        // but impFilePath!!!
        if (!request->getParamOrHeader(IMP_COMMAND, impCommand))
            throw XosException(437, SC_437);

        impFilePath = request->getResource();
    }

    if (impFilePath.empty())
        throw XosException(437, SC_437);

	std::string impUser;
	if (!request->getParamOrHeader(IMP_USER, impUser))
		throw XosException(432, SC_432);
		
    impFilePath = ImpListDirectory::resolveDir(impFilePath, impUser);

    // read the requested offset from start of file
    if (request->getParamOrHeader(IMP_FILESTARTOFFSET, impFileStartOffset)) {

        // convert offset to a long int
        if ( sscanf(impFileStartOffset.c_str(), "%ld", &fileStartOffset ) != 1 ) {
            LOG_INFO1("Error converting impFileStartOffset value %s to a long integer.",
                    impFileStartOffset.c_str());
            throw XosException(438, std::string(SC_438) + " " + impFileStartOffset);
        }

        if (fileStartOffset < 0)
            throw XosException(438, std::string(SC_438) + " " + impFileStartOffset);

    }

    // read the requested offset from start of file
    if (request->getParamOrHeader(IMP_FILEENDOFFSET, impFileEndOffset)) {

        // convert offset to a long int
        if ( sscanf(impFileEndOffset.c_str(), "%ld", &fileEndOffset ) != 1 ) {
            LOG_INFO1("Error converting impFileEndOffset value %s to a long integer.",
                impFileEndOffset.c_str());
            throw XosException(439, SC_439);
        }
    }

	// Find out if this user is staff.
	// The request attribute is set by ImpServer.
	bool isStaff = false;
	std::string tmp;
	if (request->getAttribute("UserStaff", tmp) && ((tmp == "true") || (tmp == "TRUE") || (tmp == "True"))) {
		isStaff = true;
	}

    // try to open the file
    int fileDescriptor;
    if ( (fileDescriptor = open( impFilePath.c_str(), O_RDONLY )) == -1 ) {
		int errCode = errno;
    
		// For isFileReadable, we only want to check if the file 
		// can be open for read by this user.
		if (name == IMP_ISFILEREADABLE) {		
			close(fileDescriptor);
			response->setHeader(IMP_FILEREADABLE, IMP_FALSE);
			if (isStaff)
				response->setHeader(IMP_USERSTAFF, IMP_TRUE);
			char* tmp = "File is not readable";
    		stream->writeResponseBody(tmp, strlen(tmp));
			stream->finishWriteResponse();
			return;
		}
		
        throw XosException(555, std::string(SC_555) + " open failed for " + impFilePath 
				+ " because " + XosFileUtil::getErrorString(errCode));
        
    }
    
    // For isFileReadable, we only want to check if the file 
    // can be open for read by this user.
    if (name == IMP_ISFILEREADABLE) {
    	close(fileDescriptor);
    	response->setHeader(IMP_FILEREADABLE, IMP_TRUE);
		char* tmp = "File is readable";
		stream->writeResponseBody(tmp, strlen(tmp));
		stream->finishWriteResponse(); 
		return;
	}


    // convert the file descriptor to a stream
    FILE* fileStream;
    if ( (fileStream=fdopen(fileDescriptor, "r" )) == NULL ) {
        throw XosException(556, std::string(SC_556) + " fdopen failed for " + impFilePath 
						+ " because " + XosFileUtil::getErrorString(errno));
    }

    // offset into file
    if ( fseek(fileStream, fileStartOffset, SEEK_SET ) != 0 ) {
        throw XosException(557, std::string(SC_557) + " fseek failed for " + impFilePath 
										+ " because " + XosFileUtil::getErrorString(errno));
    }

    // initialize byteCount to offset position
    fileOffset = fileStartOffset;

    int readCount;
    char readBuffer[1024];

    struct stat fileStat;
    int ret = fstat(fileDescriptor, &fileStat);

    if (ret != 0)
        throw XosException(558, std::string(SC_558) + " fstat failed for " + impFilePath
									+ " because " + XosFileUtil::getErrorString(errno));
    
    if (fileStat.st_size == 0)
		throw XosException(586, SC_586);

    if (fileStat.st_size < 0)
	throw XosException(587, SC_587);

    // There is not enough to read
    if (fileEndOffset <= 0) {
        fileEndOffset = fileStat.st_size-1;

        if (fileEndOffset < fileStartOffset)
            throw XosException(438, SC_438);

    }


    if (fileEndOffset < fileStartOffset)
        throw XosException(439, SC_439);


    // Do this
    response->setContentLength(fileEndOffset-fileStartOffset+1);
    // Or
//    response->setTransferEncoding("chunked");



    // read the file in 1K blocks
    readCount = 1024;
    bool first = true;
    while ( readCount == 1024 ) {

        // adjust number of bytes to read if with 1K of desired file end
        if ( fileEndOffset > 0 && fileOffset + readCount > fileEndOffset ) {
            readCount = fileEndOffset - fileOffset + 1;
        }

        // read next block
        if ( (readCount = read( fileDescriptor, readBuffer, readCount )) == -1 ) {
            LOG_INFO2("Error reading from file %s because %s", impFilePath.c_str(), XosFileUtil::getErrorString(errno).c_str( ));
            break;
        }

        if (first) {

            first = false;

            // Try to guess the format of the content
            // and set the content-type accordingly.
            std::string contentType;
            std::string contentTransferEncoding;
            std::string contentEncoding;
            HttpUtil::guessFromContent(readBuffer, readCount,
                        contentEncoding,
                        contentTransferEncoding,
                        contentType);

//            LOG_FINE3("1) Content-Type = %s\nContent-Encoding = %s\nContent-Transfer-Encoding=%s\n",
//                    contentType.c_str(), contentEncoding.c_str(),
//                    contentTransferEncoding.c_str());

            if (!contentEncoding.empty())
                response->setContentEncoding(contentEncoding);

            std::string bestGuessFromContent = contentType;
            if (contentType.empty() ||
                (contentType == WWW_BINARY)) {

                // try to guess the content type from the file extension
                // Find the last dot
                size_t pos = impFilePath.rfind(".");

                if (pos != std::string::npos) {
                     HttpUtil::guessFromFileExtension(impFilePath, contentType);
 //                   LOG_FINE2("Content-Type = %s\nContent-Encoding = %s\nContent-Transfer-Encoding=%s\n",
 //                           contentType.c_str(), contentEncoding.c_str(),
//                            contentTransferEncoding.c_str());
                }
            }

            if (contentType.empty())
                contentType = bestGuessFromContent;


            if (!contentType.empty())
                response->setContentType(contentType);



        } // if (first)

        // writeBody makes sure that the response header has been
        // written. If the header does not contain Content-Type and
        // Content-Length, writeBody will return false
        // and the body will not be sent.
        if (!stream->writeResponseBody( readBuffer, readCount)) {
            LOG_SEVERE1("Error writing file %s to client\n", impFilePath.c_str());
            break;
        }

        // keep track offset into file
        fileOffset += readCount;
    }

    stream->finishWriteResponse();

}

