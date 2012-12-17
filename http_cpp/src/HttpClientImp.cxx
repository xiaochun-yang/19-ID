extern "C" {
#include "xos.h"
#include "xos_socket.h"
}

#include <string>
#include <map>
#include "XosException.h"
#include "XosStringUtil.h"
#include "XosFileUtil.h"
#include "HttpConst.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"


#ifndef SHUT_WR
  #ifndef SD_RECEIVE
    #define SD_RECEIVE      0x00
    #define SD_SEND         0x01
    #define SD_BOTH         0x02
  #endif
  #define SHUT_WR SD_SEND
#endif

#ifndef MSG_WAITALL
#define MSG_WAITALL 0
#endif

/**********************************************************
 *
 * Constructor
 *
 **********************************************************/
HttpClientImp::HttpClientImp()
    : HttpClient()
{


    request = new HttpRequest();
    response = new HttpResponse();

    writeState = WRITE_REQUEST_LINE;
    readState = READ_RESPONSE_LINE;

    autoReadResponseBody = false;
    numResponseBodyRead = 0;
    remainingBytesInChunk =0;
    
    numWritten = 0;
    
    in = 0;

	 readTimeout = 5000;

}



/**********************************************************
 *
 * Destructor
 *
 **********************************************************/
HttpClientImp::~HttpClientImp()
{
    if (request)
        delete request;

    if (response)
        delete response;

    request = NULL;
    response = NULL;
    
    if (writeState > WRITE_REQUEST_LINE)
    	xos_socket_destroy(&socket);
    
    if (in)
    	fclose(in);
}


/**********************************************************
 *
 * to write the message body directory
 * into the output stream. It's typically
 * from doGet/doPost.
 * This stream class makes sure that the
 * response status line and the headers
 * are sent before the body. It also adds
 * the appropriate headers if they are not
 * set by the application.
 *
 **********************************************************/
bool HttpClientImp::writeRequestBody(const char* buf, int numChars)
    throw (XosException)
{
    sendRequestLine();

    sendRequestHeader();

    finishRequestHeader();

    if ((writeState != WRITE_REQUEST_BODY) && (writeState != WRITE_REQUEST_BODY_MANUAL))
        return false;

    if (!request->isBodyAllowed())
        return false;


    // This will prevent sendRequestBody() from trying to send the request->body
    // since we have already sent the body (or part of the body) manually here.
    writeState = WRITE_REQUEST_BODY_MANUAL;

    if (buf == NULL)
        throw XosException("Null pointer passed to writeRequestBody\n");
        
    // Write the chunk size first
    if (request->isChunkedEncoding()) {
    	char tt[25];
    	if (numWritten > 0) {
    		sprintf(tt, "%s%x%s", CRLF, numChars, CRLF);
    	} else {
    		sprintf(tt, "%x%s", numChars, CRLF);
    	}
		if (xos_socket_write( &this->socket, tt, strlen(tt)) != XOS_SUCCESS)
			throw XosException( errno, "Failed in writeRequestBody: failed to write chunk size" + XosFileUtil::getErrorString(errno));
    }

    if (xos_socket_write( &this->socket, buf, numChars) != XOS_SUCCESS)
        throw XosException("Failed in writeRequestBody: failed to write http body" + XosFileUtil::getErrorString(errno));
        
    numWritten += numChars;

    return true;
}

/**********************************************************
 *
 * Called by the application to indicate that it
 * has finished writing the response.
 * Sent the response header if it has not been sent.
 *
 **********************************************************/
HttpResponse* HttpClientImp::finishWriteRequest()
    throw (XosException)
{

    if (writeState == WRITE_REQUEST_LINE)
        sendRequestLine();

    if (writeState == WRITE_REQUEST_HEADER)
        sendRequestHeader();


    if (writeState == WRITE_END_REQUEST_HEADER)
        finishRequestHeader();
        
    if (writeState == WRITE_REQUEST_BODY_MANUAL) {
    
		if (request->isChunkedEncoding()) {
			char tt[25];
			if (numWritten > 0) {
				sprintf(tt, "%s%x%s", CRLF, 0, CRLF);
			} else {
				sprintf(tt, "%x%s", 0, CRLF);
			}
			if (xos_socket_write( &this->socket, tt, strlen(tt)) != XOS_SUCCESS)
				throw XosException("Failed in finishWriteRequest: failed to write chunk size" + XosFileUtil::getErrorString(errno));
		}
		
    }


    if (writeState == WRITE_REQUEST_BODY)
        sendRequestBody();


    writeState = FINISH_REQUEST;


    finishRequestBody();
    
    
    return response;
    
}

/**********************************************************
 *
 * Read the request body
 * Return 0 when the total number of bytes read equals
 * contentLength or when the last chunk has been read (for chunked
 * encoding).
 *
 **********************************************************/
int HttpClientImp::readResponseBody(char* buf, int count)
        throw (XosException)
{

    if ((readState != READ_RESPONSE_BODY_MANUAL) && (readState != READ_RESPONSE_BODY))
        return 0;


    readState = READ_RESPONSE_BODY_MANUAL;


    size_t numRead = 0;


    if (response->isChunkedEncoding()) { // chunked encoding


        char tmp[100];
        if (remainingBytesInChunk <= 0) {


            // The first line tells us how many bytes to read in this chunk
            if (fgets(tmp, 100, in) == NULL)
                return 0;

            sscanf(tmp, "%x\n", &remainingBytesInChunk);
        }

        // Got the last line in the request body indicating that
        // there is no more data
        if (remainingBytesInChunk == 0)
            return 0;

        // Find out how much to read
        numRead = (remainingBytesInChunk > (unsigned int)count)
                ? count : remainingBytesInChunk;


        // Read the chunk (or part of it)
        numRead = fread(buf, 1, numRead, in);
        if (numRead <= 0)
            return 0;

        remainingBytesInChunk -= numRead;

        // Read the end of line
        if (remainingBytesInChunk == 0) {
            if (fgets(tmp, 100, in) == NULL)
                return 0;
        }



    }  else if (response->getContentLength() > 0) { // Content-Length header included

        // NON chunked encoding
        long int responseContentLength = response->getContentLength();

        // If we have read the body then simply returns 0
        if (numResponseBodyRead >= responseContentLength)
            return 0;

        // Read as much as we can but not more that the contentLength
        numRead = responseContentLength - numResponseBodyRead;


        // And not more than what the buffer can take
        if (numRead > count)
            numRead = count;

        numRead = fread(buf, sizeof(char), numRead, in);

        if (numRead <= 0)
            return 0;


    } else { // Content-Length header NOT included. Read until socket is closed by server

        numRead = fread(buf, sizeof(char), count, in);

        if (numRead <= 0)
            return 0;

    }


    // Count how many bytes we have read so far
    numResponseBodyRead += numRead;

    return numRead;
}





/**********************************************************
 *
 * To be overridden by a subclass to implement
 * the streaming of the input/output.
 *
 **********************************************************/
void HttpClientImp::close()
{
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::sendRequestLine()
    throw(XosException)
{

    if (writeState != WRITE_REQUEST_LINE)
        return false;


    // send the request line here

    xos_socket_address_t    address;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, request->getHost().c_str() );
    xos_socket_address_set_port( &address, request->getPort() );

    // create the socket to connect to server
    if (xos_socket_create_client( &this->socket ) != XOS_SUCCESS) {
        throw XosException("Failed in sendRequestLine: xos_socket_create_client");
    }

    // connect to the server
    if (xos_socket_make_connection( &this->socket, &address ) != XOS_SUCCESS) {
        throw XosException("Failed in sendRequestLine: xos_socket_make_connection");
    }

    std::string space(" ");

    // create the request packet
    std::string line = request->getMethod()
                        + space
                        + request->getURI()
                        + space
                        + request->getVersion()
                        + CRLF;


    // write the first line
    if (xos_socket_write( &this->socket, line.c_str(), line.size()) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestLine: xos_socket_write" + XosFileUtil::getErrorString(errno));

    writeState = WRITE_REQUEST_HEADER;

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::sendRequestHeader()
    throw(XosException)
{
    if (writeState != WRITE_REQUEST_HEADER)
        return false;


    writeState = WRITE_END_REQUEST_HEADER;

    request->setHeader(RQH_HOST,
            request->getHost() + ":"
            + XosStringUtil::fromInt(request->getPort()));

    std::string str = request->getHeaderString();

    // send the request header here
    // write the first line
    if (xos_socket_write( &this->socket, str.c_str(), str.size()) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestHeader: xos_socket_write" + XosFileUtil::getErrorString(errno));


     return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::finishRequestHeader()
    throw(XosException)
{
    if (writeState != WRITE_END_REQUEST_HEADER)
        return false;


    writeState = WRITE_REQUEST_BODY;

    // send the request header end line here
    if (xos_socket_write( &this->socket, CRLF, 2) != XOS_SUCCESS)
        throw XosException("Failed in finishRequestHeader: xos_socket_write" + XosFileUtil::getErrorString(errno));

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::sendRequestBody()
    throw(XosException)
{
    if (writeState != WRITE_REQUEST_BODY)
        return false;

    writeState = FINISH_REQUEST;

    if (!request->isBodyAllowed())
        return false;


    // Send the request body here
    // send the request header end line here
    const std::string& body = request->getBody();
    if (body.empty())
        return false;

    if (xos_socket_write( &this->socket, body.c_str(), body.size()) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestBody: xos_socket_write" + XosFileUtil::getErrorString(errno));

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::finishRequestBody()
    throw(XosException)
{
    if (writeState != FINISH_REQUEST)
        return false;


    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(this->socket.clientDescriptor, SHUT_WR) != 0 ) {
        throw XosException("Failed in finishRequestBody: SOCKET_SHUTDOWN " + XosFileUtil::getErrorString(errno));
	 }

    receiveResponseLine();

    receiveResponseHeader();

    if (autoReadResponseBody)
        receiveResponseBody();

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::receiveResponseLine()
    throw(XosException)
{
    if (readState != READ_RESPONSE_LINE)
        return false;


    readState = READ_RESPONSE_HEADER;

	// All xos_socket_read will only block for maximum
	// 5 seconds before returning an error 
	// if there is no response.
	if (xos_socket_set_read_timeout(&this->socket, readTimeout) != XOS_SUCCESS)
		throw XosException("Failed in receiveResponseLine: cannot set socket read timeout\n");

	// Only wait maximum 5 seconds for the response to arrive.
   xos_wait_result_t ret = xos_socket_wait_until_readable(&this->socket, readTimeout);

   if (ret == XOS_WAIT_FAILURE)
		throw XosException("receiveResponseLine failed because xos_socket_wait_until_readable connection not good or select failed\n");
   else if (ret == XOS_WAIT_TIMEOUT)
		throw XosException("receiveResponseLine failed because xos_socket_wait_until_readable timeout after " + XosStringUtil::fromInt(readTimeout/1000) + " sec");
   else if (ret != XOS_WAIT_SUCCESS)
		throw XosException("receiveResponseLine failed because xos_socket_wait_until_readable failed\n");

    // read the HTTP result
    char buf[1000];
    int bufSize = 1000;

    // convert the file descriptor to a stream
    if ( (in=fdopen(this->socket.clientDescriptor, "r" )) == NULL ) {
        throw XosException("Failed in receiveResponseLine: fdopen " + XosFileUtil::getErrorString(errno));
    }

    // read and store the first line from socket
    if ( fgets( buf, bufSize, in ) == NULL ) {
        throw XosException("Failed in receiveResponseLine: fgets " + XosFileUtil::getErrorString(errno));
    }


    response->parseResponseLine(buf);


    return true;
}




/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::receiveResponseHeader()
    throw(XosException)
{

    if (readState != READ_RESPONSE_HEADER)
        return false;


    readState = READ_RESPONSE_BODY;

    char inputLine[1024];

    // iteratively read lines from the header
    bool forever = true;
    while (forever) {


        inputLine[0] = '\0';

        // read and store the next line from standard input
        if ( fgets( inputLine, 1024, in ) == NULL ) {
            // No header
            return true;
        }

        // If it is a Set-Cookie header, don't save it as a normal header
        // Save only the valid cookie. Do not quit if encounter a bad cookie.
        if (isSetCookieHeader(inputLine))
            response->parseSetCookieHeader(inputLine, request->getHost(), request->getURI());
        else if (!response->parseHeader(inputLine))
            return false;


    }

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::isSetCookieHeader(const std::string& str)
{
    std::string name;
    std::string value;

    if (!XosStringUtil::split(str, ":", name, value))
        return false;

    if (!XosStringUtil::equalsNoCase(name, RES_SETCOOKIE))
        return false;

    return true;
}


/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientImp::receiveResponseBody()
    throw(XosException)
{
    if (readState != READ_RESPONSE_BODY)
        return false;



    char buf[5000];
    size_t bufSize = 5000;

    std::string& body = response->getBody();

    int numRead;
    while ((numRead = readResponseBody(buf, bufSize)) > 0) {
        body.append(buf, numRead);
    }


    readState = FINISH_RESPONSE;

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
void HttpClientImp::setReadTimeout(int msec)
{
	if (msec > 0)
		readTimeout = msec;
}
