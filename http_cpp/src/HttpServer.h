#ifndef __Include_HttpServer_h__
#define __Include_HttpServer_h__

/**
 * @file HttpServer.h
 * Header file for HttpServer class.
 */

class HttpRequest;
class HttpResponse;
class HttpServerHandler;


#include "XosException.h"

/**
 * @class HttpServer
 *
 * This is an interface that represents the server side of
 * an HTTP transaction.
 *
 * It defines an interface for receiving an HTTP request and
 * returning a response. Server application creates
 * an instance of a subclass via a factory method and
 * uses the interface of this class to access the request
 * and response. Server application can also call
 * methods in this class to read the request body and
 * write the response body from/to the stream directly,
 * which is particulary useful if the body is large,.
 *
 * Subclass should create an HttpRequest object from the
 * input stream, and create an HttpResponse object.
 *
 * @see HttpServerHandler
 *
 * Example:
 *
 * @code

    // Main program
    void main(int argc, char** argv)
    {
        try {

        // Create  an HttpServer that represents an HTTP transaction.
        HttpServer* conn = HttpServerFactory::createServer(INETD);

        // Create a server handler. MyServerHandler is a subclass
        // if the HttpServerHandler implemented by the application.
        HttpServerHandler* handler = new MyServerHandler();

        // Register the handler with this HttpServer.
        // so that doGet and doPost will get called.
        conn->setHandler(handler);

        // Start reading the request.
        conn->start();

        } catch (...) {
            // should catch specific exception
        }

    }

    // HttpServerHandler doGet method define by the application
    MyServerHandler::doGet(HttpServer* conn)
        throw (XosException)
    {
        HttpRequest* request = conn->getRequest();
        HttpResponse* response = conn->getResponse();

        // Read the request body directly.
        char buf[1000];
        int num;
        while ((num = conn->readRequestBody(buf, 1000)) > 0) {
            fwrite(buf, sizeof(char), num, stdout);
        }


        // Set the response. Note that the response body can be
        // sent either directly via writeResponseBody() or
        // automatically.

        if (x > 1000) {

            // Set the headers only. We will write the response body ourselves.
            response->setStatusCode(200);
            response->setStatusPhrase("OK");

            // Write the response body directly
            conn->writeResponseBody("Thank you for shopping with ShoeBuy.com\n");
            conn->writeResponseBody("Please come again\n");

            // Finish with the response.
            conn->finishWriteResponse();

        } else {

            // Set both headers and body.
            response->setStatusCode(523);
            response->setStatusPhrase("Something is wrong");
            response->setBody("Put this message in the response body");

            // The response headers and body will be sent automatically.
            conn->finishWriteResponse();

        }

    }

 * @endcode
 **/
class HttpServer
{
public:

    /**
     * @brief Constructor
     *
     **/
    HttpServer() {}


    /**
     * @brief Destructor
     **/
    virtual ~HttpServer() {}

    /**
     * @brief Returns the request
     * @return The HttpRequest of this transaction
     **/
    virtual HttpRequest* getRequest() = 0;

    /**
     * @brief Returns the response
     * @return The HttpResponse of this transaction
     **/
    virtual HttpResponse* getResponse() = 0;

    /**
     * @brief Registers a server handler which will perform
     * application specific tasks.
     *
     * @param h Server handler
     */
    virtual void setHandler(HttpServerHandler* h) = 0;

    /**
     * @brief This is the server's starting point for a transaction.
     * The server application has been invoked when a request
     * arrives. This method is called by the server application
     * to read the the input stream and construct a request object.
     * It calls doGet()/doPost() methods of the HttpServerHandler
     * to let the application perform specific tasks before
     * sending the response.
     * @see HttpServerHandler
     **/
    virtual void start() = 0;

    /**
     * @brief Read the request body directly from the input stream.
     *
     * It's typically called from doGet/doPost of the HttpServerHandler.
     * The application calls this method directly in doGet() or doPost()
     * to read the request body. This method can be called repeatedly
     * until it returns 0 indicating the end of the stream.
     *
     * The function reads until one of the following conditions is reached:
     * - The output buffer is full.
     * - It reaches the end of the stream.
     * - Tt has read the last chunk (for chunked encoding) even though
     *   the input stream is not closed,
     * - It has read up to the number of bytes specified in the Content-Length
     *   header (if set, and Transfer-Encoding is not chunked).
     *
     * @param buf Output buffer
     * @param size Size of the buffer
     * @return Number of bytes read. 0 when the total number of bytes read equals
     * contentLength or when the last chunk has been read (for chunked
     * encoding).
     **/
    virtual int readRequestBody(char* buf, size_t size)
        throw (XosException) = 0;

    /**
     * @brief Called by the application flush out the response
     * headers.
     *
     * The application sets the response headers prior to this call.
     * The response headers set after this call or after the body (or part of it) has been set
     * by calling writeResponseBody() or finishWriteResponse() will not
     * be sent.
     * @exception XosException Thrown if there is an error.
     **/
    virtual bool finishWriteResponseHeader()
        throw (XosException) = 0;

    /**
     * @brief This method allows the application to write the message body
     * into the output stream directly.
     *
     * It's typically called from doGet/doPost of the HttpServerHandler.
     * Subclass must make sure that the
     * response status line and the headers
     * are sent before the body. It should also add
     * the appropriate headers for the response if they are not
     * set by the application.
     *
     * This function can be called repeatedly. To finish writing to the
     * output stream, the application should call finishWriteResponse().
     *
     * @param buf Input buffer
     * @param num Number of characters to write
     * @exception XosExcetion Thrown if there is an error
     **/
    virtual bool writeResponseBody(const char* buf, size_t num)
        throw (XosException) = 0;


    /**
     * @brief Called by the application to indicate that it
     * has finished writing the response.
     *
     * Subclass must make sure that the response headers and the body,
     * if they have not been sent, are sent in the correct order.
     * @exception XosException Thrown if it fails to send the response.
     **/
    virtual bool finishWriteResponse()
        throw (XosException) = 0;


    /**
     * @brief Returns an arbitrary pointer, specific to the subclass. 
     *
     * Subclass can use this method to return an arbitrary pointer
     * to the application. Default behaviour is to return NULL.
     * @return A pointer to data specific to the subclass.
     **/
    virtual void* getUserData()
    {
    	return NULL;
    }
    
	virtual bool nextFile() throw (XosException) { throw XosException("Not implemented"); }
	virtual std::string getCurFilePath() { return "";}
	virtual long getCurFileSize() { return 0;}
	virtual int readCurFileContent(char* buf, size_t count) throw (XosException) { throw XosException("Not implemented");}

protected:

	virtual void closeOutputStream() throw (XosException) = 0;

};

#endif // __Include_HttpServer_h__
