extern "C" {
#include "xos.h"
#include "xos_log.h"
}
#include "XosException.h"
#include "HttpConst.h"
#include "HttpStatusCodes.h"
#include "HttpMessage.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "InetdServer.h"
#include "HttpServerHandler.h"
#include "HttpUtil.h"
#include "XosStringUtil.h"
#include "log_quick.h"


FILE* log_response = NULL;

/****************************************************
 *
 * Utility func for debugging
 *
 ****************************************************/
static size_t l_fwrite(const void* buf, size_t bytesPerItem, size_t numItems, FILE* out)
{
    size_t ret = fwrite(buf, bytesPerItem, numItems, out);
    fflush(out);

    return ret;
}

/****************************************************
 *
 * Constructor
 *
 ****************************************************/
InetdServer::InetdServer()
		: in(0), out(0), handler(0),
		request(0), response(0),
		finishResponseBody(false),
		sentResponseHeader(false),
		numBytesWritten(0),
		numRequestBodyRead(0)
{
    init();
}

/****************************************************
 *
 * Constructor
 *
 ****************************************************/
InetdServer::InetdServer(HttpServerHandler* h)
{
    init();

    setHandler(h);
}


/****************************************************
 *
 * Destructor
 *
 ****************************************************/
InetdServer::~InetdServer()
{

    if (response)
        delete response;

    if (request)
        delete request;

}
/****************************************************
 *
 * init
 *
 ****************************************************/
void InetdServer::init()
{
    this->handler = 0;

    request = new HttpRequest();
    response = new HttpResponse();

    response->setDate(HttpMessage::getCurrentDateTime());

    response->setServer("Default");
    response->setHeader(GH_CONNECT, "close");

    in = stdin;
    out = stdout;


    finishResponseBody = false;
    sentResponseHeader = false;
    numBytesWritten = 0;
    numRequestBodyRead = 0;
    remainingBytesInChunk = 0;

}

/****************************************************
 *
 * setHandler
 *
 ****************************************************/
void InetdServer::setHandler(HttpServerHandler* h)
{
    if (h != 0) {
        handler = h;
        response->setServer(handler->getName());
    }
}




/****************************************************
 *
 * For HTTP server to read a request and send a response.
 *
 ****************************************************/
void InetdServer::start()
{
    try {

    receiveRequestLine();

    receiveRequestHeader();

    // GET can't have a body
    // POST can
    if (request->isBodyAllowed()) {
        // Even if this method can have a body
        // We still need to make sure that
        // there is Content-Length before
        // we can read it.
        receiveRequestBody();
    }

    if (response->getStatusCode() == 200) {

        if (handler) {

            std::string method = request->getMethod();
            if (method == HTTP_GET) {
                handler->doGet(this);
            } else if (method == HTTP_POST) {
                handler->doPost(this);
            }


        } else {    // no handler
            throw XosException(512, SC_512);
        }
    }


    // If we catch an exception here, we will
    // set the response code and message
    // and let the destructor send the message.
    } catch (XosException& e) {
        xos_log("in start: caught XosException\n");
        if (e.getCode() < 400)
        	response->setStatusCode(500);
        else
        	response->setStatusCode(e.getCode());
        response->setStatusPhrase(e.getMessage());
        std::string tmp = XosStringUtil::fromInt(e.getCode());
        tmp += std::string(" ") + e.getMessage();
        response->setBody(tmp.c_str());
    } catch (std::exception& e) {
        response->setStatusCode(500);
        response->setStatusPhrase(e.what());
        std::string tmp("500 ");
        tmp += e.what();
        response->setBody(tmp.c_str());
    } catch (...) {
        response->setStatusCode(500);
        response->setStatusPhrase("Unknown error");
        response->setBody("500 Unknown error");
    }

    // Send the response.
    // An exception can be thrown here but we will have to quit if it happens.
    xos_log("in start(): calling sendResponseBody\n");
    sendResponseBody();

    xos_log("Exiting start()\n");

}

/****************************************************
 *
 * Called by an application to send out the response header
 *
 ****************************************************/
bool InetdServer::finishWriteResponseHeader()
        throw (XosException)
{
    // Do nothing if the status line and the header have been sent
    return sendResponseHeader();
}

/****************************************************
 *
 * Called by the application to write the buffer
 * as http response body to the stream
 *
 ****************************************************/
bool InetdServer::writeResponseBody(const char* buff, size_t numChars)
    throw(XosException)
{
    // Check if finishResponseBody == true
    // then throw an exception
    if (finishResponseBody == true)
        throw XosException(511, SC_511);

    if (!sentResponseHeader) {

        // The client wants to get chunked encoded response body
        // indicated by TE header in the request
//        if (response->getContentLength() <= 0) {
            std::string teHeader;
            if (request->getHeader(RQH_TE, teHeader)) {
                if (teHeader.find(WWW_CODING_CHUNKED) != std::string::npos) {
                    response->setChunkedEncoding(true);

                }
            }
//        }
    }

    // Do nothing if the status line and the header have been sent
    sendResponseHeader();

    if (!buff || (numChars == 0))
        return false;


    // If we are doing chunk encoding then
    // put the chunk size in the first line
    if (response->isChunkedEncoding()) {

        char line[50];
        sprintf(line, "%#x%s", numChars, CRLF);
        l_fwrite(line, 1, strlen(line), out);
        xos_log("chunked encoding: writing chunk size line = %s\n", line);
    }


    int num = l_fwrite(buff, 1, numChars, out);

    if (num == 0) {
        xos_log("in writeResponseBody l_fwrite returns 0\n");
        return false;
    }

    numBytesWritten += num;

    // If we are doing chunk encoding then
    // put end of line after the chunk
    if (response->isChunkedEncoding()) {
        l_fwrite(CRLF, 1, strlen(CRLF), out);
    }


    return true;

}


/****************************************************
 *
 * Called by an application to indicate that it's
 * finished writing response
 *
 ****************************************************/
bool InetdServer::finishWriteResponse()
        throw (XosException)
{
    if (finishResponseBody)
        return true;


    // Do nothing if the status line and the header have been sent
    sendResponseHeader();


    // last chunk
    if (response->isChunkedEncoding()) {
        char* tt = "0" CRLF;
        l_fwrite(tt, 1, strlen(tt), out);
    }

    // If the header contains Connection: close
    // then close the connection
    std::string connection;
    if (response->getHeader(GH_CONNECT, connection)) {
        if (connection.find("close") != std::string::npos) {
//            fclose(out);
			closeOutputStream();
		}
    }

    finishResponseBody = true;

    return true;

}


/****************************************************
 *
 *
 ****************************************************/
std::string InetdServer::getCurFilePath()
{
	return curFilePath;
}

/****************************************************
 *
 *
 ****************************************************/
long InetdServer::getCurFileSize()
{
	return curFileSize;
}

static std::string fgets_errno(int error_no) {
	if (error_no == EAGAIN)
		return "EAGAIN";
	else if (error_no == EBADF)
		return "EBADF";
	else if (error_no == EINTR)
		return "EINTR";
	else if (error_no == EIO)
		return "EIO";
	else if (error_no == EOVERFLOW)
		return "EOVERFLOW";
	else if (error_no == ENOMEM)
		return "ENOMEM";
	else if (error_no == ENXIO)
		return "ENXIO";
	else if (error_no == EIO)
		return "EIO";
	else if (error_no == EISDIR)
		return "EISDIR";
	else if (error_no == EFAULT)
		return "EFAULT";
	else if (error_no == EINVAL)
		return "EINVAL";

	return XosStringUtil::fromInt(error_no);	
}

/****************************************************
 *
 *
 ****************************************************/
bool InetdServer::nextFile() throw (XosException) {

	curFilePath = "";
	curFileSize = 0;

	if (remainingBytesForFile > 0)
		throw XosException("Illegal state");
				
	// The first line is the file path
	char tmp1[1000];
	curFilePath = "";
	if (my_fgets(tmp1, 1000, fileno(in)) == NULL) {
		return false;
	}
			
	char tmp2[20];
	if (my_fgets(tmp2, 20, fileno(in)) == NULL) {
		return false;
	}

	curFilePath = XosStringUtil::trim(tmp1);
	// The line that is supposed to be the filename
	// is empty. Something is wrong. Stop reading further.
	if (curFilePath.size() == 0)
		return false;
	std::string str = XosStringUtil::trim(tmp2);
	// The line that is supposed to be the file size
	// is an empty line. Something is wrong. 
	// Stop reading further.
	if (str.size() == 0)
		return false;
	sscanf(tmp2, "%d\n", &curFileSize);
	remainingBytesForFile = curFileSize;
	
	return true;
	
}

/****************************************************
 *
 *
 ****************************************************/
int InetdServer::readCurFileContent(char* buf, size_t count) throw (XosException)
{
       	xos_log("in InetdServer::readFileContent: remainingBytesForFile = %d\n",
       			remainingBytesForFile);

        // Done reading this file
	// Next file need to be called before reading the next file
        if (remainingBytesForFile <= 0) {
        	return 0;
        }
        
        // Find out how much to read. Do not read for than buf size
        size_t numRead = (remainingBytesForFile > (unsigned int)count)
                ? count : remainingBytesForFile;
                
         
        xos_log("expecting to read size = %d\n", numRead);


        // Read the remaining of the file
        numRead = read(fileno(in), buf, numRead);
        if (numRead <= 0)
            return 0;

        xos_log("have read size = %d\n", numRead);
        
        remainingBytesForFile -= numRead;

        // Read the end of line
        if (remainingBytesForFile == 0) {
	    char tmp[100];
            if (my_fgets(tmp, 100, fileno(in)) == NULL) {
	    	throw XosException("Cannot read end-of-line after file content");
	    }
        }
	
	return numRead;
}

/****************************************************
 *
 * Read the request body
 * Return 0 when the total number of bytes read equals
 * contentLength or when the last chunk has been read (for chunked
 * encoding).
 *
 ****************************************************/
int InetdServer::readRequestBody(char* buf, size_t count)
        throw (XosException)
{
    size_t numRead = 0;

    // The body may be in "chunked" encoding or no encoding.
    if (!request->isChunkedEncoding()) {

        // NON chunked encoding
        long int requestContentLength = request->getContentLength();
        
//        xos_log("in InetdServer::readRequestBody: content length = %d, has read = %d\n",
//        	requestContentLength, numRequestBodyRead);

        // If we have read the body then simply returns 0
        if (numRequestBodyRead >= requestContentLength)
            return 0;

        // Read as much as we can but not more that the contentLength
        numRead = requestContentLength - numRequestBodyRead;


        // And not more than what the buffer can take
        if (numRead > count)
            numRead = count;

        //numRead = fread(buf, 1, numRead, in);
        numRead = read(fileno(in), buf, numRead);

//        xos_log("in InetdServer::readRequestBody: after fread numRead = %d\n",
//        			numRead);
        	
        
        if (numRead <= 0)
            return 0;


    } else {

       	xos_log("in InetdServer::readRequestBody: use chunk encoding: remainingBytesInChunk = %u\n",
       			remainingBytesInChunk);

        // chunked encoding
        char tmp[100];
        if (remainingBytesInChunk == 0) {
        
        	xos_log("reading chunk size\n");


            // The first line tells us how many bytes to read in this chunk
            if (my_fgets(tmp, 100, fileno(in)) == NULL)
                return 0;
                

            sscanf(tmp, "%x\n", &remainingBytesInChunk);
        }

        xos_log("chunk size = %d\n", remainingBytesInChunk);
        
        // Got the last line in the request body indicating that
        // there is no more data
        if (remainingBytesInChunk == 0)
            return 0;

        // Find out how much to read
        numRead = (remainingBytesInChunk > (unsigned int)count)
                ? count : remainingBytesInChunk;
                
         
        xos_log("expecting to read size = %d\n", numRead);


        // Read the chunk (or part of it)
        //numRead = fread(buf, 1, numRead, in);
        numRead = read(fileno(in), buf, numRead);
        if (numRead <= 0)
            return 0;

        xos_log("have read size = %d\n", numRead);
        
        remainingBytesInChunk -= numRead;

        // Read the end of line
        if (remainingBytesInChunk == 0) {
            if (my_fgets(tmp, 100, fileno(in)) == NULL)
                return 0;
        }



    } // isChunkedEncoding()?


    // Count how many bytes we have read so far
    numRequestBodyRead += numRead;

    return numRead;
}

char* InetdServer::fgetsRequestBody(char* buf, size_t count)
        throw (XosException)
{
    size_t numToRead = 0;
    size_t numAvailable = 0;

    if (buf == NULL || count == 0) {
        return NULL;
    }

    char* result = NULL;

    // The body may be in "chunked" encoding or no encoding.
    if (!request->isChunkedEncoding()) {

        long int requestContentLength = request->getContentLength();
        LOG_FINEST1( "contentLength=%ld", requestContentLength );
        
        // If we have read the body then simply returns 0
        if (numRequestBodyRead >= requestContentLength)
            return NULL;

        // Read as much as we can but not more that the contentLength
        numAvailable = requestContentLength - numRequestBodyRead;

        if (numAvailable > count - 1) {
            numToRead = count - 1;
        } else {
            numToRead = numAvailable;
        }

        result = my_fgets( buf, numToRead + 1, fileno(in) );
        if (result) {
            numRequestBodyRead += strlen(buf);
        }
        return result;
    } else {
       	xos_log("in InetdServer::fgetsRequestBody: use chunk encoding: remainingBytesInChunk = %u\n",
       			remainingBytesInChunk);
        bool doneRead = false;
        size_t startOffset = 0;
        size_t spaceLeft = count - 1;
        while (!doneRead) {
            if (remainingBytesInChunk >= spaceLeft) {
                numToRead = spaceLeft;
                result = my_fgets(
                    buf + startOffset,
                    numToRead + 1,
                    fileno(in)
                );
                if (result) {
                    size_t numRead = strlen(buf + startOffset);
                    numRequestBodyRead += numRead;
                    remainingBytesInChunk -= numRead;
                }
                return result;
            }

            //now the complicated case, we may need to read across the chunk.
            if (remainingBytesInChunk > 0) {
                numToRead = remainingBytesInChunk;
                result = my_fgets(
                    buf + startOffset,
                    numToRead + 1,
                    fileno(in)
                );
                if (result == NULL) {
                    return result;
                }
                size_t numRead = strlen(buf + startOffset);
                if (numRead > 0 && buf[numRead-1] == '\n') {
                    numRequestBodyRead += numRead;
                    remainingBytesInChunk -= numRead;
                    return result;
                }

                startOffset += numRead;
                spaceLeft -= numRead;
                //DEBUG
                if (remainingBytesInChunk > 0) {
                    LOG_SEVERE3( "numToRead=%lu, got %lu, remainInChunk=%u",
                    numToRead, numRead, remainingBytesInChunk);
                    return NULL;
                }
            }
            //now remainingBytesInChunk should be zero.

            // chunked encoding
            char tmp[100];
      	    xos_log("reading chunk size\n");
            if (my_fgets(tmp, 100, fileno(in)) == NULL) {
                return 0;
            }

            sscanf(tmp, "%x\n", &remainingBytesInChunk);

            xos_log("chunk size = %u\n", remainingBytesInChunk);
        
            // Got the last line in the request body indicating that
            // there is no more data
            if (remainingBytesInChunk == 0) {
                return NULL;
            }
        } //!done
    } // isChunkedEncoding()?
    //should neve be here.
    return NULL;
}

/****************************************************
 *
 * Sends the status line and headers
 *
 ****************************************************/
bool InetdServer::sendResponseHeader()
    throw(XosException)
{
    if (sentResponseHeader)
        return true;


    char tmp[1024];
    int code = response->getStatusCode();

    // Write status line
    sprintf(tmp, "HTTP/1.1 %d %s%s",
            code,
            response->getStatusPhrase().c_str(),
            CRLF);
    l_fwrite(tmp, 1, strlen(tmp), out);

    // Write headers
    std::string str = response->getHeaderString();
    l_fwrite(str.c_str(), 1, str.size(), out);

    l_fwrite(CRLF, 1, strlen(CRLF), out);

    sentResponseHeader = true;

    if ((code >= 200) && (code < 300))
        return true;

    return false;
}


/****************************************************
 *
 * Throws an exception if this method is called when
 * the header does not already contain Content-Type,
 * Content-Length, Content-Transfer-Encoding header fields.
 *
 ****************************************************/
void InetdServer::sendResponseBody()
    throw(XosException)
{
	if (finishResponseBody == true)
		return;
		
    if (numBytesWritten > 0)
        return;

    sendResponseHeader();

    std::string& body = response->getBody();
    writeResponseBody(body.c_str(), body.size());

    finishWriteResponse();


}


/****************************************************
 *
 * Read request body from input stream
 *
 ****************************************************/
void InetdServer::receiveRequestBody()
    throw(XosException)
{

    // TODO: add multipart mime support
    // Can only read content of POST at the moment
    if (request->getMethod() != HTTP_POST)
        return;

    // parse the parameters
    std::string contentType = request->getContentType();

    if (contentType.empty())
        throw XosException(427, SC_427);


    // We can only read the body in the supported MIME type
    // Otherwise, let the application read the body using
    // readRequestBody() method
    if (contentType != WWW_FORM)
        return;

    int contentLength = request->getContentLength();

    if (contentLength < 0)
        throw XosException(411, SC_411);


    // Read form data

    std::string form;

    char buf[1025];
    int totRead = 0;
    int numRead = 0;

    // Only read as much as contentLength bytes
    while (totRead < contentLength) {

        numRead = contentLength - numRead;
        if (numRead > 1024)
            numRead = 1024;
        if ((numRead = read(fileno(in), buf, numRead)) <= 0)
            break;

        buf[numRead] = '\0';

        totRead += numRead;

        // parse the parameters
        form.append(buf);
    }

    if (totRead < contentLength) {
        xos_log("Error reading message body\n");
        throw XosException(510, SC_510);
    }


    request->parseFormData(form);

}


/****************************************************
 *
 * Parse the Reuquest line
 * method SP request-URI SP http-version CRLF
 * For example,
 * GET /listDirectory?impDirectory=/data/img HTTP/1.1
 * Method, version and uri-resource are saved as member variables
 * parameters extracted from the query part of the uri
 * are parsed into parm-name/value pairs and saved
 * in the header hashtale.
 * Note that the duplicate entries of the headers
 * will simply be replaced. Hence any parameters
 * extracted from the URI will be replaced
 * by the ones in the headers, if found.
 *
 ****************************************************/
void InetdServer::receiveRequestLine()
    throw(XosException)
{
    char line_cstr[1024];

    // read and store the first line from standard input
    if ( my_fgets( line_cstr, 1024, fileno(in) ) == NULL ) {
        throw XosException(421, SC_421);
    }

    request->parseRequestLine(line_cstr);

    if (!handler)
        throw XosException(512, SC_512);

    if (!handler->isMethodAllowed(request->getMethod())) {
        xos_log("method not allowed: %s\n", request->getMethod().c_str());
        throw XosException(405, SC_405);
    }
}


/****************************************************
 *
 * Reads/parses HTTP headers from in.
 * stop reading when we see CRLF CRLF; what comes next
 * is the message body.
 * Saved the headers in the hashtable. Any params
 * found here as an entity-header will replace the
 * param extracted from the query part of the request-URI.
 *
 ****************************************************/
void InetdServer::receiveRequestHeader()
        throw(XosException)
{

//    char parameterName[1024];
    char inputLine[1024];
//    const char* parameterValuePtr;

    // iteratively read lines from the header
    bool forever = true;
    while (forever) {


        inputLine[0] = '\0';

        // read and store the next line from standard input
        if ( my_fgets( inputLine, 1024, fileno(in) ) == NULL ) {
            // No header
            return;
        }

		xos_log("calling parseHeader\n");
        if (!request->parseHeader(inputLine))
            return;


    }


}


