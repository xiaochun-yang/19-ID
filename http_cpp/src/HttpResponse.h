#ifndef __HttpResponse_h__
#define __HttpResponse_h__

/**
 * @file HttpResponse.h
 * Header file for HttpResponse class.
 */

#include "HttpMessage.h"
#include "XosException.h"

/**
 * @class HttpResponse
 * Subclass of HttpMessage represents an HTTP response message.
 *
 * Following RFC2616, a request message has the following format:
 *
 * version code phrase
 * general headers
 * response headers
 * entity headers
 * extension headers
 * CRLF
 * body
 *
 * where
 * version is HTTP/major.minor. It is defaulted to HTTP/1.1
 * code is the status code. 2xx range indicates that the resposne is OK.
 * phrase is the human readable explanation of the code.
 * general headers are the headers which can be included in both request and response messages, e.g. Date.
 * response headers are found in the response only, e.g. Server.
 * entity headers gives information about the message body. Can be found in both request and response.
 * extension headers are those understood by the server. Can be anything.
 *
 * See HttpConst.h for a list of header names.
 *
 * An HTTP client application constructs this object
 * by parsing the socket input stream.
 * This class does not know anything about how the response
 * is transported. It only deals with the contents of the response message.
 *
 * A server application constructs a response object after it receives
 * a request message.
 *
 * Example:
 *
 * @code

    HttpResponse response;

    response.setServer("smb.slac.stanford.edu");

    if (x > 0) {

       response.setStatusCode(200);
       response.setStatusPhrase("OK");

    } else {

       response.setStatusCode(522);
       response.setStatusPhrase("Invalid x value");

    }



 * @endcode
 *
 */

class HttpResponse : public HttpMessage
{
public:

    /**
     * @brief Default constructor.
     *
     * Status code is defaulted to 200 and status phrase is "OK".
     */
    HttpResponse();

    /**
     * @brief Constructor. Cretaes a response with a status code and phrase.
     * @param code Status code
     * @param phrase Status phrase
     */
    HttpResponse(int code, const std::string& phrase);

    /**
     * @brief Destructor
     */
    virtual ~HttpResponse();

    /**
     * @brief Set the HTTP version string
     * @param v Version string such as HTTP/1.1
     * @see HttoConst.h for the default version string
     */
    void setVersion(const std::string& v)
    {
        version = v;
    }

    /**
     * @brief Returns the version string.
     * @return Version string such as HTTP/1.1
     */
    std::string getVersion() const
    {
        return version;
    }

    /**
     * @brief Sets the status code and phrase for this response.
     * @param code Status code
     * @param phrase Status phrase.
     */
    void setStatus(int code, const std::string& phrase)
    {
        statusCode = code;
        statusPhrase = phrase;
    }

    /**
     * @brief Sets the status code of this response.
     * @param code Status code.
     */
    void setStatusCode(int code)
    {
        statusCode = code;
    }

    /**
     * @brief Returns the status code of this response.
     * @return Status code.
     */
    int getStatusCode() const
    {
        return statusCode;
    }

    /**
     * @brief Sets the status phease of this response.
     * @param phrase Status phrase.
     */
    void setStatusPhrase(const std::string& phrase)
    {
        statusPhrase = phrase;
    }

    /**
     * @brief Returns the status phrase of this response.
     * @return Status phrase.
     */
    std::string getStatusPhrase() const
    {
        return statusPhrase;
    }

    /**
     * @brief Sets the Server header for this response.
     *
     * The Server header is a response header (see RFC2616 for definition of headers).
     * @see HttpConst.h for a complete list of header names.
     */
    void setServer(const std::string& server)
    {
        setHeader(RES_SERVER, server);
    }

    /**
     * @brief Returns the Server header.
     * @return Server header value.
     */
    std::string getServer() const
    {
        std::string server;
        if (getHeader(RES_SERVER, server)) {
            return server;
        }

        return "";
    }

    /**
     * @brief Parses the response line which consists and save the version string,
     * status code and phrase in this object.
     * @param str Response line.
     * @exception XosException Thrown if the string is an invalid response line.
     */
    void parseResponseLine(const std::string& str)
        throw (XosException);



private:

    int             statusCode;
    std::string     statusPhrase;
    std::string     version;


};

#endif // __HttpResponse_h__

