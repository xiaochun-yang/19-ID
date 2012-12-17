#ifndef __Include_ImgServerHandler_h__
#define __Include_ImgServerHandler_h__

extern "C" {
#include "xos.h"
#include "xos_socket.h"
}

#include "XosException.h"
#include "HttpServerHandler.h"


class HttpServer;

class ImgServerHandler : public HttpServerHandler
{
public:

    /**
     * @brief Constructor.
     *
     * The server name is sent to client in the "Server" response header
     **/
    ImgServerHandler(const std::string& n)
    	: name(n)
    {
    }

    /**
     * @brief destructor
     **/
    virtual ~ImgServerHandler()
    {
    }

    /**
     * @brief HttpServerHandler method
     * Called by the HttpServer to
     * set the "Server" response header.
     * @return Name of this server.
     **/
    virtual std::string getName() const
    {
        return name;
    }

    /**
     * @brief Returns true if this server allows
     * the given method in the request.
     *
     * Called when the stream reads the request
     * line. If this method returns false, the HttpServer
     * will stop parsing the rest of the request
     * and will return a response with an error code 405,
     * Method Not Allowed.
     *
     * @param m Method name such as GET, POST or PUT.
     * @return True if this server wishes to handle this method.
     **/
    virtual bool isMethodAllowed(const std::string& m) const
    {
    	if (m != "GET")
    		return false;
    		
    	return true;
    }

    /**
     * @brief Called by the HttpServer if the request method is GET.
     *
     * The method is called when after the request has been parsed
     * and the request headers are saved in the HttpRequest object
     * which can be accessed via the HttpServer object.
     *
     * @param s The HttpServer.
     * @exception XosException Can be thrown by this method if there is an error.
     **/
    virtual void doGet(HttpServer* s)
        throw (XosException);
	
    /**
     * @brief Called by the HttpServer if the request method is POST.
     *
     * The method is called when after the request has been parsed
     * and the request headers are saved in the HttpRequest object
     * which can be accessed via the HttpServer object.
     *
     * @param s The HttpServer.
     * @exception XosException Can be thrown by this method if there is an error.
     **/
    virtual void doPost(HttpServer* s)
        throw (XosException)
    {
    	doGet(s);
    }
    
    /**
	 * @brief Processes the http request and sends an HTTP response.
	 *
	 * @param socket Socket stream
     **/
    static void handleRequest(xos_socket_t* socket);


private:

    /**
     * Name of this server
     * Appears in "Server" response header field
     **/
    std::string name;




	/**
	 * @brief Utility func to read an HTTP request from the socket and parse it.
	 *  Expect the reuqest to contain the request line and headers only.
	 *
	 * @param socket Socket stream for receiving the request
	 * @param uri Input URI to parse
	 * @param method Returned request method such as POST or GET
	 * @param version Returned HTTP version info
	 * @param host Returned host name
	 * @param port Returned port number
	 * @param resource Returned resource part of the URI
	 * @param params Returned list of parameter names and 
	 *        values from the query part of the URI.
	 * @param reason Returned error string if the func returns false.
	 * @return True if the func parses the URI successfully. 
	 *         If the func returns false, the error string is also returned. 
	 */
	static bool readRequest(xos_socket_t* socket,
							std::string& uri,
							std::string& method,
							std::string& version,
							std::string& host,
							std::string& port,
							std::map<std::string, std::string>& params,
							std::string& reason);

public:  //changed to public by NKS. These functions don't even access class data; why not
         // move them to a namespace instead???
	/**
	 * @brief Sends an HTTP error response to the socket. The status code
	 * should be in the 400 or 500 ranges to indicate an error.
	 * The status phrase should explain what the error is.
	 * Code should not be 200 since it's reserved as an OK response code.
	 * If the body parameter can be en empty string.
	 *
	 * @param socket Socket stream for sending the response
	 * @param code Response status code
	 * @param phrase Response status phrase
	 * @param body Response body
	 */
	static void sendErrorResponse(xos_socket_t* socket, 
						const std::string& code,
						const std::string& phrase,
						const std::string& body);

	/**
	 * @brief Sends an HTTP error response to the socket. The status code
	 * should be in the 400 or 500 ranges to indicate an error.
	 * The status phrase should explain what the error is.
	 * Code should not be 200 since it's reserved as an OK response code.
	 * The response body is the status code followed by status phrase in one line.
	 *
	 * @param socket Socket stream for sending the response
	 * @param code Response status code
	 * @param phrase Response status phrase
	 * @param body Response body
	 */
	static void sendErrorResponse(xos_socket_t* socket, 
						const std::string& code,
						const std::string& phrase);


	/**
	 * @brief Sends an HTTP OK response to the socket. The response code
	 * is 200 and response phrase is OK.
	 *
	 * If the headerStr is NULL or headerSize is 0, only default headers,
	 * such as Server, will be included. If the bodyStr is NULL or 
	 * bodySize is 0, the response will not have a body.
	 *
	 * @param socket Socket stream for sending the response
	 * @param header String containing containing header lines.
	 * @param body Buffer contain the response body
	 * @param bodySize Size of the response body
	 */
	static void sendOkResponse(xos_socket_t* socket, 
						const std::string& header,
						const char* body,
						int bodySize);

	/**
	 * @brief Processeses the http request and sends an HTTP response.
	 *
	 * @param socket Socket stream
	 * @param params A list of input parameter names and values 
	 *  extracted from the request URI.
	 */
	static void sendResponse(xos_socket_t* socket, 
						std::map<std::string, std::string>& params);
};

#endif // __Include_ImgServerHandler_h__


