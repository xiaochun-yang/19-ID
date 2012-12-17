#ifndef __Include_HttpClientStream_h__
#define __Include_HttpClientStream_h__

/**
 * @file HttpClient.h
 * Header file for HTTP client base class.
 */

class HttpRequest;
class HttpResponse;

#include "XosException.h"

/**
 * @class HttpClient
 * An http client is used by an application to construct/send
 * an HTTP request and get a response back from the server.
 * This is a base class of all HTTP client.
 *
 * It defines an interface for sending a request body
 * and receiving a response body.
 * Client application creates an HttpClient object and get
 * a request object from this class.
 *
 * The client application can then construct a request by
 * setting the request headers via the HttpRequest class.
 * If the request body is small, the client application
 * can set the request body using HttpRequest::setBody method.
 * The body will saved in the internal buffer of the HttpRequest
 * and sent automatically.
 * If the request body is large, the client application can
 * choose to send the body directly calling writeRequestBody()
 * repeatedly until all of the buffer is sent and then call
 * finishWriteRequest() to finish sending the request.
 *
 * For the response, the client application can choose
 * whether to read the response body directly by calling
 * readResponseBody() repeatedly until the func
 * return 0, or to let the HttpClient read the body automatically
 * (the body can be retrieved by calling HttpResponse::getBody()).
 *
 * Example:
 * @code

   try {

       // Should we read the response body ourselves?
       bool beBrave = false;

       // Get an HttpClient from a factory
       HttpClient* client = HttpClientFactory::createClient();

       // Get the request object
       HttpRequest* request = client->getRequest();

       // Set the request
       request->setHost("www.google.com");
       request->setPort(80);
       request->setMethod(HTTP_GET);
       request->setURI("/search?hl=en&ie=UTF-8&oe=UTF-8&q=shoes");


       // Should we read the response ourselves?
       client->setAutoReadResponseBody(beBrave);


       // Send the request and wait for a response
       HttpResponse* response = client->finishWriteRequest();

       if (client->getAutoReadResponseBody()) {

           // We need to read the response body ourselves
           char buf[1000];
           int bufSize = 1000;
           while ((numRead = client->readResponseBody(buf, bufSize)) > 0) {

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

       delete client;

    } catch (XosException& e) {
        printf("Caught XosException %d %s\n", e.getCode(), e.getMessage().c_str());
    }

 * @endcode
 *
 **/
class HttpClient
{
public:

    /**
     * @brief Constructor
     *
     **/
    HttpClient()
    {
    }


    /**
     * @brief Destructor
     **/
    virtual ~HttpClient() {}


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
     * @param b If true, the response body will be read automatically.
     *          If false, the client application must call
     *          readResponseBody() to read the response body.
     * @see getAutoReadResponseBody()
     **/
    virtual void setAutoReadResponseBody(bool b) = 0;

    /**
     * @brief Returns true if the response body is be to read
     * automatically and saved in response->body.
     * @see setAutoReadResponseBody()
     * @return True if the response body is to be read automatically by the HttpClient.
     *         Otherwise returns false.
     **/
    virtual bool getAutoReadResponseBody() const = 0;

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
     * @param buf Character array to be sent
     * @param numChars Number of characters in the buffer to be sent.
     * @return True if the buffer is written to the stream successfully.
     *         Otherwise returns false.
     * @exception XosException Thrown if the function fails to send the buffer.
     * @see finishWriteRequest()
     **/
    virtual bool writeRequestBody(const char* buf, int numChars)
        throw(XosException) = 0;

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
     * @return A pointer to an HttpResponse.
     * @exception XosException Thrown if the function fails to
     *            read the stream or the content of the
     *            response is an invalid HTTP response.
     **/
    virtual HttpResponse* finishWriteRequest()
        throw(XosException) = 0;

    /**
     * @brief Reads the response body.
     *
     * Called by the client application that wishes to read the response
     * body directly instead of letting the HttpClient read and save the
     * body in HttpResponse::body.
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
        throw(XosException) = 0;

    /**
     * @brief Returns pointer to the request object.
     *
     * Application must not delete this pointer. It will be deleted
     * when the HttpClient is deleted.
     * Note that subclass must make sure that the request and response
     * objects are deleted properly in the destructor.
     * @return A pointer to the HTTP request.
     **/
    virtual HttpRequest* getRequest() = 0;

	 /**
 	  * @brief Sets the maximum time to wait for the response.
	  * 
	  * An exception will be thrown from receiveResponseLine
 	  * if the response is not returned within the readTimeout.
	  * @param msec read timeout in msec. 
	  */
	 virtual void setReadTimeout(int msec) = 0;


};

#endif // __Include_HttpClientStream_h__
