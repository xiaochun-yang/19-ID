#ifndef __Include_InetdServer_h__
#define __Include_InetdServer_h__

class HttpRequest;
class HttpResponse;
class HttpServerHandler;

/**
 * @file InetdServer.h
 * Header file for InetdServer class.
 */


#include "HttpServer.h"

/**
 * @class InetdServer
 * Subclass of HttServer that reads an HTTP request from stdin
 * and writes HTTP response to raw stdout.
 * This is a server side state engine for an HTTP transaction.
 * A server application creates an intance of this class
 * either directly or via a factory class, and interact with this
 * class through the HttServer interface.
 * The HttpServer calls virtual func of this class at various
 * stages in the transaction to let the application perform
 * specific tasks.
 *
 * An application using InetdServer runs as a daemon and is invoked
 * when a socket connection is established. The input/output socket
 * file descriptors are mapped to the standard input and output.
 * In this sense, the application runs almost like a CGI program,
 * except that the input contains a raw HTTP message.
 * @see HttpServer for an example.
 * @todo Use STATES like in HttpClientImp.
 **/
class InetdServer : public HttpServer
{
public:

    /**
     * @brief Constructor.
     *
     * Creates an InetdServer. The handler is defaulted to null.
     * Later in the process, if the handler remains null, default response
     * will be sent to the client.
     *
     **/
    InetdServer();

    /**
     * @brief Constructor
     *
     * Creates an InetdServer and registers the HttpServerHandler with the server.
     * @param h HttServerHandler
     */
    InetdServer(HttpServerHandler* h);


    /**
     * @brief Destructor
     *
     * Frees up the resources.
     **/
    virtual ~InetdServer();


    /**
     * @brief Returns the request pointer.
     *
     * The application must not delete this pointer.
     * It will be deleted by the destructor.
     * @return Pointer to HttpRequest object.
     **/
    virtual HttpRequest* getRequest()
    {
        return request;
    }

    /**
     * @brief Returns the response pointer.
     *
     * The application must not delete this pointer.
     * It will be deleted by the destructor.
     * @return Pointer to HttpResponse object.
     **/
    virtual HttpResponse* getResponse()
    {
        return response;
    }

    /**
     * @brief Registers the handler with this server.
     *
     * Methods in the handler will be called by this server
     * to allow the application to perform specific tasks.
     * @param h Pointer to HttpServerHandler
     */
    virtual void setHandler(HttpServerHandler* h);

    /**
     * @brief Starts reading the request from standard input stream.
     *
     * Called by the application to start reading the
     * the input stream and construct a request and response message.
     * This method calls doGet/doPost methods of the HttpServerHandler
     * before it sends the response.
     **/
    virtual void start();

    /**
     * @brief Reads the request body from standard input stream.
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
        throw (XosException);
    virtual char* fgetsRequestBody(char* buf, size_t size)
        throw (XosException);

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
        throw (XosException);

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
        throw (XosException);

    /**
     * @brief Called by the application to indicate that it
     * has finished writing the response.
     *
     * Response headers and the body,
     * if they have not been sent, are sent in the correct order.
     * @exception XosException Thrown if it fails to send the response.
     **/
    virtual bool finishWriteResponse()
        throw (XosException);
	
    virtual void* getUserData()
    {
	    return out;
    }

	virtual bool nextFile() throw (XosException);
	virtual std::string getCurFilePath();
	virtual long getCurFileSize();
	virtual int readCurFileContent(char* buf, size_t count) throw (XosException);


protected:

    /**
     * The physical input and output stream
     **/
    FILE* in;
    FILE* out;

	virtual void closeOutputStream()
		throw (XosException)
	{
		fclose(out);
	}

private:

    void receiveRequestLine()
        throw(XosException);

    void receiveRequestHeader()
        throw(XosException);

    void receiveRequestBody()
        throw(XosException);

    bool sendResponseHeader()
        throw(XosException);

    void sendResponseBody()
        throw(XosException);




    /**
     * The HttpServer's doGet and doPost will be
     * called to process the request and filling out
     * the response body.
     **/
    HttpServerHandler* handler;

    /**
     * The http request and response pair for this
     * connection.
     **/
    HttpRequest* request;
    HttpResponse* response;


    bool finishResponseBody;


    /**
     * Internal flag to indicate that the response
     * status line and headers have been sent.
     **/
    bool    sentResponseHeader;

    /**
     * Internal variable that keeps track of how many
     * bytes of the response body has been sent.
     **/
    int     numBytesWritten;

    /**
     * How many bytes of the request body we have read
     **/
    long int numRequestBodyRead;

    /**
     *
     **/
    unsigned int remainingBytesInChunk;

    void init();

	std::string curFilePath;
	long curFileSize;
	long remainingBytesForFile;

};

#endif // __Include_InetdServer_h__
