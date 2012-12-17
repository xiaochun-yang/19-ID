#ifndef __Include_HttpServerFactory_h__
#define __Include_HttpServerFactory_h__

/**
 * @file HttpServerFactory.h
 * Header file for HttpServerFactory class.
 */

/**
 * @def INETD_STREAM "inetd"
 * Type of HttpServer that reads the request from the standard input stream.
 */
#define INETD_STREAM "inetd"

#include <string>

class HttpServer;

/**
 * @class HttpServerFactory
 * Factory class for creating an HttpServer from a concrete class.
 */

class HttpServerFactory
{
public:

    /**
     * @brief Destructor
     */
    ~HttpServerFactory() {}

    /**
     * @brief Creates a new HttpServer from a subclass.
     *
     * The caller of this function is responsible for deleting the returned pointer.
     * @param type Type of the HttpServer. Currently, only "inetd" is supported.
     * @return A Pointer to the newly created HttpServer. Must be deleted by the application.
     */
    static HttpServer* createServer(const std::string& type);

private:
    /**
     * @brief Constructor
     */
    HttpServerFactory() {}

};

#endif // __Include_HttpServerFactory_h__
