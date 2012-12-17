#ifndef __HTTPCLIENTSSLIMPLEMENT__
#define __HTTPCLIENTSSLIMPLEMENT__

// THIS IS MODIFIED FROM HttpClientImp

/**
 * @file HttpClientSSLImp.h
 * Header file for the HttpClient implementation class.
 */

#include <string.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#include "HttpClient.h"

class HttpRequest;
class HttpResponse;

/**
 * @class HttpClientSSLImp
 * A subclass of HttpClient. Uses xos_socket for sending and receiving
 * HTTP Request and response.
 * This class is a state engine. It keeps track of the
 * states of the input and output streams.
 * For example, when writeRequestBody() is called,
 * it makes sure to send the request line, request headers
 * if they have not already been sent.
 * Example
 * @code

   try {

       // Should we read the response body ourselves?
       bool beBrave = false;

       // Get an HttpClient from a factory
       HttpClient client;

       // Get the request object
       HttpRequest* request = client.getRequest();

       // Set the request
       request->setHost("www.google.com");
       request->setPort(80);
       request->setMethod(HTTP_GET);
       request->setURI("/search?hl=en&ie=UTF-8&oe=UTF-8&q=shoes");


       // Should we read the response ourselves?
       client.setAutoReadResponseBody(beBrave);


       // Send the request and wait for a response
       HttpResponse* response = client.finishWriteRequest();

       if (client.getAutoReadResponseBody()) {

           // We need to read the response body ourselves
           char buf[1000];
           int bufSize = 1000;
           while ((numRead = client.readResponseBody(buf, bufSize)) > 0) {

               // Print out what we have read.
               fwrite(buf, sizeof(char), numRead, stdout);
           }

       } else {

           // Response body has been read by the HttpClient
           // and saved in the response->body.
           // So here we just print it out.
           fwrite(response->getBody().c_str(),
                  sizeof(char),
                  response->getBody().size(),
                  stdout);

       }

    } catch (XosException& e) {
        printf("Caught XosException %d %s\n", e.getCode(), e.getMessage().c_str());
    }

 * @endcode
 * @see HttpClient for more examples.
 **/
class HttpClientSSLImp : public HttpClient
{
public:
    /**
     * @brief Default constructor.
     *
     * HttpRequest and HttpResponse are created and initialized.
     *
     **/
    HttpClientSSLImp( const char* trusted_ca_file = NULL,
    const char* trusted_ca_directory = NULL );

    //one of them must not be NULL
    //LIMITATION: only one file or/and dir can be loaded
    //            openSSL supports many
    void setTrustedCa( const char* file, const char* dir ) {
        trusted_ca_file = file;
        trusted_ca_directory = dir;
    }

	void setTrustedCaFile(const char* file) {
		trusted_ca_file = file;
	}

	void setTrustedCaDir(const char* dir) {
		trusted_ca_directory = dir;
	}

    void setDebugFlag( int debug ) {
        m_debugLevel = debug;
    }

    void logDebugMsg( );

    bool httpDone( ) const {
        return m_httpDone;
    }

	/**
  	 * Set supported ciphers to be sent to server. Comma separated name.
	 */
	void setCiphers(const char* ciphers)
		throw(XosException);

	/**
  	 * Set supported ciphers to be sent to server. Comma separated name.
	 */
	const char* getCiphers() {
		return m_ciphers;
	}	

    const std::string& getDebugMsg( ) const {
        return m_strDebugMsg;
    }

    /**
     * @brief Destructor
     **/
    virtual ~HttpClientSSLImp();

    /**
     * @brief Tell the HttpClient whether or not it should
     * automatically read the response body and save it
     * in the HttpResponse.
     *
     * If true the response body will be read and saved
     * in response->body. Client application can get
     * the body by calling response->getBody().
     * If false, response body will not be read.
     * Note that the response line and response headers
     * are always read automatically.
     *
     * Client application can get the body by
     * calling readResponseBody() repeatedly until the func
     * returns 0.
     *
     * @param b If true, the response body will be read automatically.
     *          If false, the client application must call
     *          readResponseBody() to read the response body.
     * @see getAutoReadResponseBody()
     **/
    virtual void setAutoReadResponseBody(bool b)
    {
        autoReadResponseBody = b;
    }

    /**
     * @brief Returns true if the response body is be to read
     * automatically and saved in response->body.
     * @see setAutoReadResponseBody()
     * @return True if the response body is to be read automatically by the HttpClient.
     *         Otherwise returns false.
     **/
    virtual bool getAutoReadResponseBody() const
    {
        return autoReadResponseBody;
    }


    /**
     * @brief This method allows the clientn application
     * to write the message body directly
     * into the output stream.
     *
     * The client application can call this method
     * repeatedly until all of the buffer is sent.
     * Subclass of HttpClient that provides an implementation
     * of this method must make sure that the
     * response status line and the headers
     * are sent before the body. It also adds
     * the appropriate headers if they are not
     * set by the application.
     *
     * @param buf Character array to be sent
     * @param numChars Number of characters in the buffer to be sent.
     * @return True if the buffer is written to the stream successfully.
     *         Otherwise returns false.
     * @exception XosException Thrown if the function fails to send the buffer.
     * @see finishWriteRequest()
     **/
    virtual bool writeRequestBody(const char* buf, int numChars)
        throw(XosException);

    /**
     * @brief Called by the application to indicate that it
     * has finished writing the response.
     *
     * It can be called without prior calls to writeRequestBody().
     * Subclass must make sure that the request line,
     * request header and, if applicable, request body
     * are sent in the correct order before closing
     * the output stream.
     *
     * Client application can not call writeRequestBody()
     * to send more request body after this method is called.
     *
     * After sending the request, this method waits for the
     * response to come back. The func may not return until
     * the response line, response headers and, if applicable,
     * response body are read from the stream.
     *
     * @return A pointer to an HttpResponse.
     * @exception XosException Thrown if the function fails to
     *            read the stream or the content of the
     *            response is an invalid HTTP response.
     **/
    virtual HttpResponse* finishWriteRequest()
        throw(XosException);

    /**
     * @brief Reads the response body.
     *
     * Called by the client application that wishes to read the response
     * body directly instead of letting the HttpClient read and save the
     * body in response->body.
     *
     * The func can be called repeatedly until it returns 0, indicating that
     * there is no more buffer in the stream. For each call, this func reads
     * from the stream until it fills the buffer (the return value will be equal
     * to the buffer size) or when it reach the end of the stream or when
     * the total number of characters read so far is equal to the Content-Length
     * header (if set).
     *
     * @param buf A valid buffer.
     * @param count Size of the buffer.
     * @return Number of characters read from the stream.
     * @exception XosException Thrown if the func fails to read from the streams
     * @see setAutoReadResponseBody()
     **/
    virtual int readResponseBody(char* buf, int count)
        throw(XosException);

    /**
     * @brief Returns pointer to the request object.
     *
     * Application must not delete this pointer. It will be deleted
     * when the HttpClient is deleted.
     * objects are deleted properly in the destructor.
     * @return A pointer to the HTTP request.
     **/
    virtual HttpRequest* getRequest()
    {
        return request;
    }

	 /**
 	  * @brief Sets the maximum time to wait for the response.
	  * 
	  * An exception will be thrown from receiveResponseLine
 	  * if the response is not returned within the readTimeout.
	  * @param msec read timeout in msec. 
	  */
	 virtual void setReadTimeout(int msec);

	 /**
	  * @brief Returns the number of seconds until the certificate expires
	  *
	  * Note that currently the returned value may be off by as
	  * much as an hour due to DST issues.
	  */
	 time_t getTimeToCertExpiration();

    /**
     * Set and get default ciphers
     *
     */
	 static void setDefaultCiphers(const char* c)
			throw(XosException);
    static const char* getDefaultCiphers();

protected:


    /**
     * To be overridden by a subclass to implement
     * the streaming of the input/output.
     **/
    virtual void close();

    virtual bool sendRequestLine()
        throw(XosException);

    virtual bool sendRequestHeader()
        throw(XosException);

    virtual bool finishRequestHeader()
        throw(XosException);

    virtual bool sendRequestBody()
        throw(XosException);

    virtual bool finishRequestBody()
        throw(XosException);

    virtual bool receiveResponseLine()
        throw(XosException);

    virtual bool receiveResponseHeader()
        throw(XosException);

    virtual bool receiveResponseBody()
        throw(XosException);

private:

    //return success or timeout
    void bioSelect( );
    void connect( );
    void myWrite( const void *buf, int len );
    void writeString( const char *buf );
    void flush( );

    //time out or at least 1 BYTE
    int  myRead( void *buf, int len );

    //time out or read one line
    //the line is ended with \n
    //it will throw exception if the line is too long
    //this is needed for http protocol
    int  readOneLine( char *buf, int buffer_size );

    void dumpHex( const void * buf, int len );

    enum WriteState {
        WRITE_REQUEST_LINE,
        WRITE_REQUEST_HEADER,
        WRITE_END_REQUEST_HEADER,
        WRITE_REQUEST_BODY,
        WRITE_REQUEST_BODY_MANUAL,
        FINISH_REQUEST
    };

    enum ReadState {
        READ_RESPONSE_LINE,
        READ_RESPONSE_HEADER,
        READ_RESPONSE_BODY,
        READ_RESPONSE_BODY_MANUAL,
        FINISH_RESPONSE
    };

    /**
     * Request object
     **/
    HttpRequest* request;

    /**
     * Response object
     * Will not contain body, if autoReadResponseBody is false.
     **/
    HttpResponse* response;

    /**
     * State of the output stream
     **/
    WriteState writeState;

    /**
     * State of the input stream
     **/
    ReadState  readState;

    bool m_httpDone;

    /**
     * Socket that connects to the server
     **/
    SSL_CTX* ctx;
    BIO*     bio;
    SSL*     ssl;
    
    /**
     * Whether or not to automatically read the response
     * body after reading the response header.
     * If true, the response body will be read
     * and saved in response->body.
     * If false, the client application
     * can read the response body directly
     * by calling readResponseBody() over and over
     * until it the func returns 0.
     **/
    bool            autoReadResponseBody;


    /**
     * How many bytes of the request body we have read
     **/
    long int        numResponseBodyRead;

    /**
     * The remaining bytes to read in the current chunk
     **/
    unsigned int    remainingBytesInChunk;

    /**
     * Number of bytes written to socket
     **/
    unsigned int    numWritten;

	 /**
	  * Time in msec to wait in socket read for the response line.
     */
	struct timeval timeout;

    const char*   trusted_ca_file;
    const char*   trusted_ca_directory;

    int           m_debugLevel;

    bool isSetCookieHeader(const std::string& str);

    char m_local_buffer[4096];
    int  m_local_buffered_data_length;

    static bool sslInited;

	 static char* g_defaultCiphers;

    static const char hex[16];

	 char* m_ciphers;

    //debug information
    std::string m_strDebugMsg;
 };

#endif // __HTTPCLIENTSSLIMPLEMENT__
