#include <string>
#include <ctype.h>
//#include <map>
#include "XosException.h"
#include "XosStringUtil.h"
#include "XosFileUtil.h"
#include "log_quick.h"
#include "SSLCommon.h"
#include "HttpConst.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"


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

#define MAX_CIPHER_LENGTH 5000

/**********************************************************
 *
 * Static method
 *
 **********************************************************/
void HttpClientSSLImp::setDefaultCiphers(const char* ciphers)
	throw(XosException)
{
	int len = strlen(ciphers);
	if (len == 0)
		throw XosException("Zero length ciphers");
	if (len > MAX_CIPHER_LENGTH)
		throw XosException("Ciphers to long");
	if (g_defaultCiphers != null)
			delete g_defaultCiphers;
	g_defaultCiphers = new char[len+1];
	strcpy(g_defaultCiphers, ciphers);

}

/**********************************************************
 *
 * Static method
 *
 **********************************************************/
const char* HttpClientSSLImp::getDefaultCiphers()
{
	return g_defaultCiphers;
}

/**********************************************************
 *
 * Constructor
 *
 **********************************************************/
bool HttpClientSSLImp::sslInited = false;
char* HttpClientSSLImp::g_defaultCiphers = NULL;
const char HttpClientSSLImp::hex[16] = {
'0', '1', '2', '3', '4', '5', '6', '7',
'8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void HttpClientSSLImp::bioSelect( ) {
    BIO_wait( bio, &timeout );
}

HttpClientSSLImp::HttpClientSSLImp( const char* ca_file,
const char* ca_directory )
    : HttpClient()
    , trusted_ca_file(ca_file)
    , trusted_ca_directory(ca_directory)
    , m_debugLevel(0)
    , ctx(NULL)
    , bio(NULL)
    , ssl(NULL)
    , m_local_buffered_data_length(0)
	, m_ciphers(NULL)
    , m_httpDone(false)
{
    request = new HttpRequest();
    response = new HttpResponse(0, "nothing done yet");

    writeState = WRITE_REQUEST_LINE;
    readState = READ_RESPONSE_LINE;

    autoReadResponseBody = false;
    numResponseBodyRead = 0;
    remainingBytesInChunk =0;
    
    numWritten = 0;
    
    timeout.tv_sec = 5;
    timeout.tv_usec = 0;

    //init ssl if not done yet
    ::SSL_init( );

}



/**********************************************************
 *
 * Destructor
 *
 **********************************************************/
HttpClientSSLImp::~HttpClientSSLImp()
{
	 if (m_ciphers)
        delete m_ciphers;

    if (request)
        delete request;

    if (response)
        delete response;

    request = NULL;
    response = NULL;
    
    if (ctx) SSL_CTX_free( ctx );
    if (bio) BIO_free_all( bio );
    // no need to free ssl???
}

/**********************************************************
 *
 * Set supported ciphers to be sent to server. Comma separated cipher names.
 *
 **********************************************************/
void HttpClientSSLImp::setCiphers(const char* ciphers)
	throw (XosException)
{
	if (writeState > WRITE_REQUEST_LINE)
		throw XosException("Too late to set ciphers");
	if (ciphers == null)
		throw XosException("Null cipher");
	int len = strlen(ciphers);
	if (len == 0)
		throw XosException("Zero length ciphers");
	if (len > MAX_CIPHER_LENGTH)
		throw XosException("Ciphers to long");
	if (m_ciphers != null)
			delete m_ciphers;
	m_ciphers = new char[len+1];
	strcpy(m_ciphers, ciphers);

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
bool HttpClientSSLImp::writeRequestBody(const char* buf, int numChars)
    throw (XosException)
{
    response->setStatus(1, "direct sending request line");
    m_strDebugMsg = "direct sending requeust line";
    sendRequestLine();

    response->setStatus(2, "direct sending request header");
    m_strDebugMsg = "direct sending requeust header";
    sendRequestHeader();

    m_strDebugMsg = "direct sending end of header";
    response->setStatus(3, "direct sending end of header");
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
    	char tt[1024] = {0};
    	if (numWritten > 0) {
    		sprintf(tt, "%s%x%s", CRLF, numChars, CRLF);
    	} else {
    		sprintf(tt, "%x%s", numChars, CRLF);
    	}
		writeString( tt);
    }

    myWrite( buf, numChars);
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
HttpResponse* HttpClientSSLImp::finishWriteRequest()
    throw (XosException)
{

    if (writeState == WRITE_REQUEST_LINE) {
        m_strDebugMsg = "sending request line";
        response->setStatus(1, "sending request line");
        sendRequestLine();
    }

    if (writeState == WRITE_REQUEST_HEADER) {
        m_strDebugMsg = "sending request header";
        response->setStatus(2, "sending request header");
        sendRequestHeader();
    }

    if (writeState == WRITE_END_REQUEST_HEADER) {
        m_strDebugMsg = "sending end of header";
        response->setStatus(3, "sending end of header");
        finishRequestHeader();
    }
        
    if (writeState == WRITE_REQUEST_BODY_MANUAL) {
    
		if (request->isChunkedEncoding()) {
			char tt[25];
			if (numWritten > 0) {
				sprintf(tt, "%s%x%s", CRLF, 0, CRLF);
			} else {
				sprintf(tt, "%x%s", 0, CRLF);
			}
            m_strDebugMsg = "sending chunked header";
            response->setStatus(4, "sending chunked header");
			writeString( tt );
		}
		
    }


    if (writeState == WRITE_REQUEST_BODY) {
        m_strDebugMsg = "sending request body";
        response->setStatus(5, "sending request body");
        sendRequestBody();
    }

    writeState = FINISH_REQUEST;

    finishRequestBody();
    
    m_strDebugMsg = "http all Done";
    m_httpDone = true;
    
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
int HttpClientSSLImp::readResponseBody(char* buf, int buffer_size)
        throw (XosException)
{

    if ((readState != READ_RESPONSE_BODY_MANUAL) && (readState != READ_RESPONSE_BODY))
        return 0;


    readState = READ_RESPONSE_BODY_MANUAL;


    size_t numRead = 0;


    if (response->isChunkedEncoding()) { // chunked encoding


        char tmp[100];
        if (remainingBytesInChunk <= 0) {
            if (readOneLine( tmp, sizeof(tmp) ) <= 0) {
                return 0;
            }

            sscanf(tmp, "%x\n", &remainingBytesInChunk);
        }

        // Got the last line in the request body indicating that
        // there is no more data
        if (remainingBytesInChunk == 0) {
            return 0;
        }

        // Find out how much to read
        numRead = (remainingBytesInChunk > (unsigned int)buffer_size)
                ? buffer_size : remainingBytesInChunk;


        // Read the chunk (or part of it)
        numRead = myRead( buf, numRead);
        if (numRead <= 0)
            return 0;

        remainingBytesInChunk -= numRead;

        // Read the end of line
        if (remainingBytesInChunk == 0) {
            if (readOneLine( tmp, sizeof(tmp) ) <= 0)
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
        if (numRead > buffer_size)
            numRead = buffer_size;

        numRead = myRead( buf, numRead);

        if (numRead <= 0)
            return 0;


    } else { // Content-Length header NOT included. Read until socket is closed by server

        numRead = myRead( buf, buffer_size);

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
void HttpClientSSLImp::close()
{
}

/**********************************************************
 *
 *
 *
 **********************************************************/

void HttpClientSSLImp::connect( ) {
//    m_debugLevel = 100;
    if (request->isSSL( )) {
        if (m_debugLevel > 0) {
            LOG_FINEST("+connect SSL");
        }
        ctx = SSL_CTX_new( SSLv23_client_method( ) );
        if (ctx == NULL) {
            SSL_LogSSLError( );
            if (m_debugLevel > 0) {
                LOG_FINEST("-connect: SSL_CTX_new failed");
            }
            throw XosException( "SSL_CTX_new failed" );
        }
        if (trusted_ca_file != NULL || trusted_ca_directory != NULL) {
            if (m_debugLevel > 0) {
                if (trusted_ca_file != NULL) {
                    LOG_FINEST1( "trusted_ca file {%s}",
                    trusted_ca_file );
                }
                if (trusted_ca_directory != NULL) {
                    LOG_FINEST1( "trusted_ca dir {%s}",
                    trusted_ca_directory );
                }
            }

            if (!SSL_CTX_load_verify_locations( ctx, trusted_ca_file,
            trusted_ca_directory )) {
                SSL_LogSSLError( );
                if (m_debugLevel > 0) {
                    LOG_FINEST("-connect: load CA failed");
                }
                throw XosException( "Failed to load trusted certificates" );
            }
        }

        //bio = BIO_new_buffer_ssl_connect( ctx );
        bio = BIO_new_ssl_connect( ctx );
        if (bio == NULL) {
            SSL_LogSSLError( );
            if (m_debugLevel > 0) {
                LOG_FINEST("-connect: BIO_new_ssl_connect failed");
            }
            throw XosException( "Failed to create BIO" );
        }
        BIO_get_ssl( bio, &ssl );
		  // Use the specified cipher suite
	 	  // If not specified then use the global 
		  // default cipher suite set by the application
		  // If nothing is set then use the default cipher
        // suite for this system.
		  if (m_ciphers != null) {
				SSL_set_cipher_list(ssl, m_ciphers);
		  } else if (g_defaultCiphers != NULL) {
				SSL_set_cipher_list(ssl, g_defaultCiphers);
		  }

        SSL_set_mode( ssl, SSL_MODE_AUTO_RETRY );

        int port = request->getPort( );
        BIO_set_conn_hostname( bio, request->getHost( ).c_str( ) );
        BIO_set_conn_int_port( bio, &port );
        //we use nonblocking mode
        BIO_set_nbio( bio, 1 );
    
        while (BIO_do_connect( bio ) != 1) {
            bioSelect( );
        }

        //check certificates
        if (trusted_ca_file != NULL || trusted_ca_directory != NULL) {
            long vResult = SSL_get_verify_result( ssl );
            if (vResult != X509_V_OK) {
                LOG_WARNING1(
                "certificate verify failed: %ld (man verity to look it up",
                vResult );

                if (m_debugLevel > 0) {
                    LOG_FINEST("-connect: certificate verify failed");
                }
                throw XosException( "Failed to verify certificate" );
            }
        }
    } else {
        if (m_debugLevel > 0) {
            LOG_FINEST("+connect: nonSSL");
        }
        m_strDebugMsg = "connecting";

        //BIO* ss = BIO_new_connect( (char*)request->getHost( ).c_str( ) );
        //BIO* bs = BIO_new( BIO_f_buffer( ));
        //bio = BIO_push( bs, ss );
        bio = BIO_new_connect( (char*)request->getHost( ).c_str( ) );
        int port = request->getPort( );
        BIO_set_conn_int_port( bio, &port );
        while (BIO_do_connect( bio ) != 1) {
            bioSelect( );
        }
        m_strDebugMsg = "connected";
    }
    if (m_debugLevel > 0) {
        LOG_FINEST("-connect: OK");
    }
}

time_t HttpClientSSLImp::getTimeToCertExpiration() {
    if (!request->isSSL( )) {
        //let's just return 10 years
        return 10l*365*24*3600;
    }

	if(ssl == NULL) {
		throw XosException("Could not retrieve ssl object.");
	}
    X509* peerCert = SSL_get_peer_certificate(ssl);
    if(peerCert == NULL) {
        throw XosException("Could not retrieve peer certificate.");
    }
	ASN1_TIME* asnTime = X509_get_notAfter(peerCert);
	if(asnTime == NULL) {
		throw XosException("Could not retrieve expiration time.");
	}
//	printf("%s\n", asnTime->data);
	std::string asnTimeData((const char*)(asnTime->data));

	struct tm expireTime;
	time_t utcExpireTime;
	if(asnTimeData[asnTimeData.size()-1]!='Z') {
		expireTime.tm_sec = atoi(asnTimeData.substr(12, 2).c_str());
		expireTime.tm_min = atoi(asnTimeData.substr(10, 2).c_str()); 
		expireTime.tm_hour = atoi(asnTimeData.substr(8, 2).c_str());
		expireTime.tm_year = atoi(asnTimeData.substr(0, 3).c_str()) -1900;
		expireTime.tm_mday = atoi(asnTimeData.substr(6, 2).c_str());
		expireTime.tm_mon = atoi(asnTimeData.substr(4, 2) .c_str()) - 1;
		utcExpireTime = mktime(&expireTime);
	} else {
		expireTime.tm_sec = atoi(asnTimeData.substr(10, 2).c_str());
		expireTime.tm_min = atoi(asnTimeData.substr(8, 2).c_str()); 
		expireTime.tm_hour = atoi(asnTimeData.substr(6, 2).c_str());
		// Only works for dates after 2000
		expireTime.tm_year = atoi(asnTimeData.substr(0, 2).c_str()) + 100;
		expireTime.tm_mday = atoi(asnTimeData.substr(4, 2).c_str());
		expireTime.tm_mon = atoi(asnTimeData.substr(2, 2) .c_str()) - 1;
		expireTime.tm_isdst = -1;
	}
    #ifdef __GLIBC__
    utcExpireTime = timegm(&expireTime);
    #else
	if(expireTime.tm_isdst != 0) {	
	 	utcExpireTime = mktime(&expireTime) - timezone + 3600;
		if(expireTime.tm_isdst < 0) {
			LOG_WARNING("Daylight savings status unknown, assuming that it is in effect.");
		}
	} else {
		utcExpireTime =  mktime(&expireTime) - timezone;
	}
    #endif
	
    //printf("Contents of expireTime: %4d-%2d-%2d %2d:%2d:%2d\n", expireTime.tm_year+1900, expireTime.tm_mon, expireTime.tm_mday, expireTime.tm_hour, expireTime.tm_min, expireTime.tm_sec);

    X509_free(peerCert);
	return (utcExpireTime - time(NULL));
}

void HttpClientSSLImp::myWrite( const void *buf, int len ) {
    const char *ptr = (const char*)buf;
    int left = len;
    int oneTime;

    if (m_debugLevel > 0) {
        LOG_FINEST1("+myWrite %d", len);
    }

    if (buf == NULL) {
        if (m_debugLevel > 0) {
            LOG_FINEST("-myWrite NULL buffer" );
        }
        return;
    }

    while (left > 0) {
        oneTime = BIO_write( bio, ptr, left );
        if (m_debugLevel > 10) {
            LOG_FINEST1("oneTime: %d", oneTime);
        }
        if (oneTime > 0) {
            left -= oneTime;
            ptr += oneTime;
            continue;
        }
        bioSelect( );
    }
    if (m_debugLevel > 0) {
        LOG_FINEST("-myWrite OK");
    }
}
void HttpClientSSLImp::writeString( const char *buf ) {
    myWrite( buf, strlen( buf ) );
}
void HttpClientSSLImp::flush( ) {
    while (BIO_flush( bio ) <= 0) {
        bioSelect( );
    }
}
int HttpClientSSLImp::readOneLine( char *buf, int len ) {
    if (m_debugLevel > 0) {
        LOG_FINEST1("+readOneLine len=%d", len);
    }
    if (len <= 0) {
        if (m_debugLevel > 0) {
            LOG_FINEST("-readOneLine len<=0");
        }
        return 0;
    }

    int result = 0;
    while (1)  {
        if (m_local_buffered_data_length > 0) {
            char* ptr = (char*)memchr( m_local_buffer, '\n',
                m_local_buffered_data_length
            );
            if (ptr != NULL) {
                int nCopy = ptr - m_local_buffer + 1;
                if (result + nCopy > len - 1) {
                    LOG_WARNING( "HttpClientSSL::readOneLine failed, found newline but line too long" );
                    if (m_debugLevel > 0) {
                        LOG_FINEST("-readOneLine line too long");
                    }
                    throw XosException( "line too long found newline" );
                }
                memcpy( buf + result, m_local_buffer, nCopy );
                result += nCopy;
                buf[result] = '\0';
                m_local_buffered_data_length -= nCopy;
                if (m_local_buffered_data_length > 0) {
                    memmove( m_local_buffer, m_local_buffer + nCopy,
                        m_local_buffered_data_length
                    );
                }
                break;
            } else {
                //no newline fouond in local buffer
                int nLeft = len - result - 1;
                if (m_local_buffered_data_length > nLeft) {
                    LOG_WARNING( "HttpClientSSL::readOneLine failed, line too long" );
                    if (m_debugLevel > 0) {
                        LOG_FINEST("-readOneLine line too long");
                    }
                    throw XosException( "line too long still no newline" );
                }
                memcpy( buf + result, m_local_buffer,
                    m_local_buffered_data_length
                );
                result += m_local_buffered_data_length;
                m_local_buffered_data_length = 0;
            }
        }
        m_local_buffered_data_length = myRead(
            m_local_buffer, sizeof(m_local_buffer)
        );
    }

    if (m_debugLevel > 10 && result > 0) {
        dumpHex( buf, result );
    }
    if (m_debugLevel > 0) {
        LOG_FINEST1("-readOneLine OK len=%d", result);
    }
    return result;
}
void HttpClientSSLImp::dumpHex( const void *buf, int len ) {
    LOG_FINEST2("+dumpHex at %p len=%d", buf, len);
    const unsigned char* ptr = (const unsigned char*)buf;

    char line[1024] = {0};

    int index = 0;
    int offset = 0;
    while (index < len) {
        memset( line, 0, sizeof(line) );
        memset( line, ' ', 80 );
        for (offset = 0; offset < 16; ++offset) {
            unsigned char value = ptr[index];
            line[offset*3] = hex[value >> 4];
            line[offset*3 + 1] = hex[value &0xf];
            if (isprint( value )) {
                line[offset + 50] = value;
            } else {
                line[offset + 50] = '.';
            }
            ++index;
            if (index >= len) break;
        }
        LOG_FINEST( line );
    }
    LOG_FINEST("-dumpHex end");
}
int HttpClientSSLImp::myRead( void *buf, int buffer_size ) {
    char *ptr = (char*)buf;
    int oneTime;
    int result  = 0;
    if (m_debugLevel > 0) {
        LOG_FINEST1("+myRead buffer_size=%d", buffer_size);
    }
    if (buf == NULL || buffer_size <= 0) {
        if (m_debugLevel > 0) {
            LOG_FINEST("-myRead no input buffer");
        }
        return 0;
    }

    //local buffer
    if (m_local_buffered_data_length > 0) {
        result = m_local_buffered_data_length;
        if (result > buffer_size) {
            result = buffer_size;
        }
        memcpy( buf, m_local_buffer, result );
        m_local_buffered_data_length -= result;
        if (m_local_buffered_data_length > 0) {
            memmove( m_local_buffer, m_local_buffer + result,
                m_local_buffered_data_length
            );
        }
        if (m_debugLevel > 10) {
            LOG_FINEST1("myRead got from local buffer: %d", result);
        }
        //in fact, you can return now
    }

    while (result == 0) {
        if (m_debugLevel > 0) {
            fprintf( stderr, "call BIO_read\n" );
        }
        oneTime = BIO_read( bio, ptr + result, buffer_size - result );
        if (m_debugLevel > 10) {
            LOG_FINEST1("myRead: onetime= %d",oneTime );
        }
        if (oneTime > 0) {
            result += oneTime;
            break;
        }
        if (BIO_eof( bio )) {
            break;
        }
        bioSelect( );
    }
    if (m_debugLevel > 20 && result > 0) {
        dumpHex( buf, result );
    }
    if (m_debugLevel > 0) {
        LOG_FINEST1("-myRead result len=%d", result );
    }
    return result;
}
bool HttpClientSSLImp::sendRequestLine()
    throw(XosException)
{

    if (writeState != WRITE_REQUEST_LINE)
        return false;

    connect( );

    // send the request line here
    std::string space(" ");

    // create the request packet
    std::string line = request->getMethod()
                        + space
                        + request->getURI()
                        + space
                        + request->getVersion()
                        + CRLF;

    writeString( line.c_str( ));
    writeState = WRITE_REQUEST_HEADER;

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::sendRequestHeader()
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
    writeString( str.c_str( ));
    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::finishRequestHeader()
    throw(XosException)
{
    if (writeState != WRITE_END_REQUEST_HEADER)
        return false;


    writeState = WRITE_REQUEST_BODY;

    // send the request header end line here
    myWrite( CRLF, 2);
    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::sendRequestBody()
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

    writeString( body.c_str( ) );
    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::finishRequestBody()
    throw(XosException)
{
    if (writeState != FINISH_REQUEST)
        return false;

    m_strDebugMsg = "flushing";
    response->setStatus(6, "flushing");
    flush( );

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
bool HttpClientSSLImp::receiveResponseLine()
    throw(XosException)
{
    if (readState != READ_RESPONSE_LINE)
        return false;


    readState = READ_RESPONSE_HEADER;

    // read the HTTP result
    response->setStatus(7, "reading line");
    m_strDebugMsg = "reading line";
    char buf[1024] = {0};
    readOneLine( buf, sizeof(buf) );
    m_strDebugMsg = "parse line:";
    m_strDebugMsg += buf;

    response->parseResponseLine(buf);
    m_strDebugMsg = "parse line OK";

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::receiveResponseHeader()
    throw(XosException)
{

    if (readState != READ_RESPONSE_HEADER)
        return false;


    readState = READ_RESPONSE_BODY;

    char inputLine[1024];

    // iteratively read lines from the header
    m_strDebugMsg = "receiving header";
    bool forever = true;
    while (forever) {
        inputLine[0] = '\0';

        // read and store the next line from standard input
        int ll = readOneLine( inputLine, sizeof(inputLine) );
        inputLine[ll] = '\0';
        if (ll == 0) {
            m_strDebugMsg = "receiving header OK end";
            return true;
        }

        // If it is a Set-Cookie header, don't save it as a normal header
        // Save only the valid cookie. Do not quit if encounter a bad cookie.
        if (isSetCookieHeader(inputLine))
            response->parseSetCookieHeader(inputLine, request->getHost(), request->getURI());
        else if (!response->parseHeader(inputLine)) {
            m_strDebugMsg = "receiving header failed end";
            return false;
        }
    }

    return true;
}

/**********************************************************
 *
 *
 *
 **********************************************************/
bool HttpClientSSLImp::isSetCookieHeader(const std::string& str)
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
bool HttpClientSSLImp::receiveResponseBody()
    throw(XosException)
{
    if (readState != READ_RESPONSE_BODY)
        return false;



    char buf[5000];

    std::string& body = response->getBody();

    int numRead;
    while ((numRead = readResponseBody(buf, sizeof(buf) )) > 0) {
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
void HttpClientSSLImp::setReadTimeout(int msec)
{
	if (msec > 0) {
        timeout.tv_sec = msec / 1000;
        timeout.tv_usec = (msec % 1000) * 1000;
    }
}

void HttpClientSSLImp::logDebugMsg( ) {
    LOG_WARNING1( "HttpClientSSLImp:debugMsg: %s", m_strDebugMsg.c_str( ) );

    switch (writeState) {
    case WRITE_REQUEST_LINE:
        LOG_WARNING( "HttpClientSSLImp: write: WRITE_REQUEST_LINE" );
        break;
    case WRITE_REQUEST_HEADER:
        LOG_WARNING( "HttpClientSSLImp: write: WRITE_REQUEST_HEADER" );
        break;
    case WRITE_END_REQUEST_HEADER:
        LOG_WARNING( "HttpClientSSLImp: write: END_REQUEST_HEADER" );
        break;
    case WRITE_REQUEST_BODY:
        LOG_WARNING( "HttpClientSSLImp: write: WRITE_REQUEST_BODY" );
        break;
    case WRITE_REQUEST_BODY_MANUAL:
        LOG_WARNING( "HttpClientSSLImp: write: WRITE_REQUEST_BODY_MANUAL" );
        break;
    case FINISH_REQUEST:
        LOG_WARNING( "HttpClientSSLImp: write: FINISH_REQUEST" );
        break;

    default:
        LOG_WARNING1( "HttpClientSSLImp: write: UNKNOWN %d", (int)writeState);
        break;
    }
    switch (readState) {
    case READ_RESPONSE_LINE:
        LOG_WARNING( "HttpClientSSLImp: read READ_RESPONSE_LINE" );
        break;
    case READ_RESPONSE_HEADER:
        LOG_WARNING( "HttpClientSSLImp: read READ_RESPONSE_HEADER" );
        break;
    case READ_RESPONSE_BODY:
        LOG_WARNING( "HttpClientSSLImp: read READ_RESPONSE_BODY" );
        break;
    case READ_RESPONSE_BODY_MANUAL:
        LOG_WARNING( "HttpClientSSLImp: read READ_RESPONSE_BODY_MANUAL" );
        break;
    case FINISH_RESPONSE:
        LOG_WARNING( "HttpClientSSLImp: read FINISH_RESPONSE" );
        break;
    default:
        LOG_WARNING1( "HttpClientSSLImp: read: UNKNOWN %d", (int)readState);
        break;
    }
}
