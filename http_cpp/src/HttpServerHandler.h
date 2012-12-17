#ifndef __HttpServerHandler_h__
#define __HttpServerHandler_h__

/**
 * @file HttpServerHandler.h
 * Header file for HttpServerHandler class.
 */

#include "XosException.h"

class HttpServer;

/**
 * @class HttpServerHandler
 * Interface class for CGI or servet style server applications.
 * This is a place for hooking the application specific modules
 * to the HttpServer state engine. It allows the application
 * to perform application-specific tasks and and set the response
 * before the HttpServer sends the response back to the client.
 * The HttpServer class is a state engine that handles the flow
 * of the request and response messages.
 *
 * The server application implements an HttpServerHandler class and
 * registers it to the HttpServer
 * so that when a request arrives, doGet() or doPost()
 * will be called.
 *
 * The application does not have to deal with how to receive the request
 * and how to send the response. Or the order in which to send each
 * component of the response.
 *
 * Example:
 *
 * @code

    class MyServerHandler : public HttpServerHandler
    {
        // Name of our application
        virtual std::string getName() const
        {
            return "My Server";
        }

        // Only support GET method
        virtual bool isMethodAllowed(const std::string& m) const
        {
            if ((m == HTTP_GET) || (m == HTTP_POST))
                return true;

            return false;
        }

        // Simply set the status code and phrase and then return
        virtual void doGet(HttpServer* conn)
            throw (XosException)
        {
            HttpResponse* response = conn->getResponse();


            if (x > 2000) {

              response->setStatusCode(200);
              response->setStatusPhrase("OK");
              respomse-setHeader("MySpecialHeader", "X is greater than 2000");
              response->setBody("This is good.");

            } else {

              response->setStatusCode(511);
              response->setStatusPhrase("Something is wrong");

            }

        }

        // Same as GET
        virtual void doPost(HttpServer* connection)
            throw (XosException)
        {
            doGet(connection);
        }

    };

    void main(int argc, char** argv)
    {
        try {

            MyServerHandler handler;

            HttpServer* server = HttpServerFactory::createHttpServer("inetd");

            server->setHandler(handler);

            server->start();

            delete server;


        } catch (XosException& e) {
            printf("Caught XosException: %d %s\n", e.getCode(), e.getmessage().c_str());
        } catch (std::exception& e) {
            printf("Caught std::exception: %s\n", e.what());
        } catch (XosException& e) {
            printf("Caught unknown exception\n");
        }
    }

 * @endcode
 */


class HttpServerHandler
{
public:

    /**
     * @brief Constructor
     **/
    HttpServerHandler() {}

    /**
     * @brief Destructor
     **/
    virtual ~HttpServerHandler() {}

    /**
     * @brief Returns the name of this server.
     *
     * The HttpServer send this name in the http response header "Server"
     * @return Server name
     **/
    virtual std::string getName() const = 0;

    /**
     * @brief Returns true if this server allows
     * the given method in the request.
     *
     * Called when the HttpServer reads the request
     * line. If this method returns false, the stream
     * will abandon the rest of the request
     * and will return an error response.
     *
     * @param m Method name such as GET and POST.
     * @return True if the server application accepts the method.
     **/
    virtual bool isMethodAllowed(const std::string& m) const = 0;

    /**
     * @brief Entry point function for the application to
     * handle the request and response for this connection, if the request method is GET.
     *
     * Called by the stream when the request
     * has been read and is ready to use and
     * if the request method is GET.
     * @param conn Pointer to HttpServer which represents the connection.
     *             The application has access to the request and response
     *             through the HttServer object.
     * @exception XosException The application can throw an XosException
     *            from within this function. The HttpServer will catch the
     *            exception and sends a response with the status code and
     *            phrase set to the ones in the exception.
     * @todo Set the status code to 500 if the code is defaulted to < 0.
     **/
    virtual void doGet(HttpServer* conn)
        throw (XosException) = 0;

    /**
     * @brief Entry point function for the application to
     * handle the request and response for this connection, if the request method is POST.
     *
     * Called by the stream when the request
     * has been read and is ready to use and

     * @param conn Pointer to HttpServer which represents the connection.
     *             The application has access to the request and response
     *             through the HttServer object.
     * @exception XosException The application can throw an XosException
     *            from within this function. The HttpServer will catch the
     *            exception and sends a response with the status code and
     *            phrase set to the ones in the exception.
     * @todo Set the status code to 500 if the code is defaulted to < 0.
     **/
    virtual void doPost(HttpServer* conn)
        throw (XosException) = 0;
};

#endif // __HttpServerHandler_h__
