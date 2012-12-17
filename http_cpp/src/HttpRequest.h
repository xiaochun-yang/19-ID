#ifndef __HttpRequest_h__
#define __HttpRequest_h__

/**
 * @file HttpRequest.h
 * Header file for the HttpRequest class.
 */

#include "XosException.h"
#include "HttpMessage.h"

/**
 * @class HttpRequest
 * Subclass of HttpMessage represents an HTTP Request message.
 *
 * Following RFC2616, a request message has the following format:
 *
 * method URI version
 * general headers
 * request headers
 * entity headers
 * extension headers
 * CRLF
 * body
 *
 * where
 * method is GET, POST, PUT and etc.
 * URI follows the RFC2396 specification. Generally it's in this format: [http://hostname:port]/resource[?query]
 * version is HTTP/major.minor. It is defaulted to HTTP/1.1
 * general headers are the headers which can be included in both request and response messages, e.g. Date.
 * request headers are found in the request only, e.g. Host, Accept.
 * entity headers gives information about the message body. Can be found in both request and response.
 * extension headers are those understood by the server. Can be anything.
 *
 * See HttpConst.h for a list of header names.
 *
 * A client application uses this class to
 * construct an http request message to send to the server.
 *
 * Example:
 *
 * @code

    HttpRequest request;
    request.setMethod(HTTP_GET);
    request.setVersion(HTTP_VERSION);
    request.setURI("/readFile?impFilePath=/data/img/image1.tif&impUser=penjitk&impSessionID=IUWRJSLDJSKHUW");
    request.setHost("smblx7.slac.stanford.edu");
    request.setPort(61000);

 * @endcode
 *
 * A server application constructs
 * an HttpRequest object from a raw http
 * message recevied via an input stream.
 *
 * This class does not know anything about
 * how to transport the message to the server.
 * @see HttpClient and HttpClientImp classes for examples of how to create an HtttpRequest.
 *
 **/

class HttpRequest : public HttpMessage
{
public:

    /**
     * @brief Constructor
     * Set the method to GET and HTTP version to HTTP/1.1
     **/
    HttpRequest();

    /**
     * @brief Destructor
     **/
    virtual ~HttpRequest();

    bool isSSL( ) const {
        return m_isSSL;
    }

    void setIsSSL( bool ssl ) {
        m_isSSL = ssl;
    }

    /**
     * @brief Only POST and PUT are allowed to have a message body.
     * @return True if the HTTP method allows the message to have body or not.
     **/
    bool isBodyAllowed();

    /**
     * @brief Called by the application to set the HTTP method for this request.
     *
     * Method: GET, POST, HEAD, PUT, TRACE, DELETE and OPTIONS.
     * The method is written in the request line
     * which is the first line of the message.
     * @param method HTTP method for this request
     **/
    void setMethod(const std::string& method)
    {
        this->method = method;
    }

    /**
     * @brief Returns the HTTP method for this request.
     * @return HTTP method
     * @see setMethod(const std::string& method)
     **/
    std::string getMethod() const
    {
        return method;
    }

    /**
     * @brief returns the host name where the message is to be sent.
     *
     * This host name appears in the Host header tohether with the port number.
     * @return Host name
     **/
    std::string getHost() const
    {
        return host;
    }

    /**
     * @brief Sets the host
     * @param h Host name
     * @see getHost()
     **/
    void setHost(const std::string& h)
    {
        this->host = h;
    }

    /**
     * @brief Returns the port number where the request is to be sent.
     *
     * This port number appears in the Host header tohether with the host name.
     * @return Port number
     **/
    int getPort() const
    {
        return port;
    }

    /**
     * @brief Sets port number
     * @param p Port number
     * @see getPort()
     **/
    void setPort(int p)
    {
        this->port = p;
    }

    /**
     * @brief Sets HTTP version, for example, HTTP/1.1.
     *
     * The function does not check if the text is correct.
     * @param version HTTP version.
     **/
    void setVersion(const std::string& version)
    {
        this->version = version;
    }

    /**
     * @brief Returns HTTP version for this request.
     * @return HTTP version
     **/
    std::string getVersion() const
    {
        return version;
    }

    /**
     * @brief The request-URI to be included in the request line.
     *
     * URI has the following format:
     * [http://hostname:port]/resource[?query]
     * Note that the string in the square brackets are
     * optional. For example,
     * http://blctlxx:61000/listDirectory?impUser=joe&impSessionID=LSLJFKJSDF7862KJ
     * /listDirectory?impUser=joe&impSessionID=LSLJFKJSDF7862KJ
     *
     * See RFC2396 for URI specification
     **/
    void setURI(const std::string& uri)
        throw (XosException);

    /**
     * Returns the URI of the message
     **/
    std::string getURI() const
    {
        return uri;
    }

    /**
     * @brief Returns the resource of the URI.
     *
     * The URI is in the following format
     * [http://hostname:port]/resource[?query]
     * @return The resource part of the URI.
     * @see RFC2396 for definition of URI.
     **/
    std::string getResource() const
    {
        return resource;
    }

    /**
     * @brief Sets the resource of the URI Note that there is no validation.
     * @param resource The resource part of the URI.
     * @see RFC2396 for definition of URI.
     **/
    void setResource(const std::string& resource)
    {
        this->resource = resource;
    }


    /**
     * @brief Parses the request line of the request message and extracts the host, resource
     * and query from the uri.
     * @param str First line of the request message
     * @exception XosException Thrown if the func fails to parse the line
     **/
    void parseRequestLine(const std::string& str)
            throw(XosException);

    /**
     * @brief Parses a FORM data. The FORM data is encoded in the URL format.
     *
     * Note that a FORM data can be found in the query part of the URI or
     * in the message body. The Content-Type header = application/x-www-form-urlencoded
     * indicates that the message body contains a FORM data.
     * @param str FORM string
     * @exception XosException Thrown if the func fails to parse the FORM data.
     **/
    void parseFormData(const std::string& str)
            throw(XosException);

	/**
	 * Returns request attribute
	 */
	 bool getAttribute(const std::string& n, std::string& ret)
				throw(XosException);

	/**
	 * Sets request attribute
	 */
	 void setAttribute(const std::string& n, const std::string& v)
				throw(XosException);



private:

    std::string     uri;
    std::string     method;
    std::string     version;
    std::string     resource;

    std::string     host;
    int             port;

    bool            m_isSSL;

	StrMap			  attributes;

//    CaseInsensitiveStrMap acceptEncoding;

    /**
     * Extract the host, resource and query from the uri
     **/
    void parseURI()
            throw(XosException);

};

#endif // __HttpRequest_h__

