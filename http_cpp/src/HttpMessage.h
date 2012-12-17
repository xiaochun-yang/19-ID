#ifndef __HttpMessage_h__
#define __HttpMessage_h__

/**
 * @file HttpMessage.h
 * Header file for HttpMessage class.
 */

#include <map>
#include <set>
#include <vector>
#include "XosStringUtil.h"
#include "HttpCookie.h"

class Helper
{

public:
 	Helper();
 	
};

/**
 * @typedef std::map<std::string, std::string> StrMap
 * @brief Hash table of string pairs. Both keys and values are strings.
 *
 * Keys are case-sensitive.
 */
typedef std::map<std::string, std::string> StrMap;

/**
 * @typedef std::map<std::string, std::string, LessNoCase> CaseInsensitiveStrMap
 * @brief Hash table of string pairs. Both keys and values are strings.
 *
 * Keys are case-insensitive.
 * @see LessNoCase
 */
typedef std::map<std::string, std::string, LessNoCase> CaseInsensitiveStrMap;

/**
 * @typedef std::set<std::string, LessNoCase> CaseInsensitiveStrSet
 * @brief A list of case-insensitive unique strings.
 *
 * @see LessNoCase
 */
typedef std::set<std::string, LessNoCase> CaseInsensitiveStrSet;

/**
 * @class HttpMessage
 *
 * Base class of HttpRequest and HttpResponse.
 * This class implements common functionalities shared by the request and response.
 * A message can contain headers, cookies, parameters and body. Extra components
 * of a message specific to request or response are implemented
 * in those subclasses.
 * There are 4 types of headers: general, request/response,
 * entity and extension headers.
 * Headers are sent in that order. Some servers such as Tomcat are very picky
 * about the order of the headers and will not accept a request with
 * the wrong header-order.
 *
 * Parameters are different from headers in that they come from the query part
 * of the request URL or the request body. They are encoded in the URL format
 * (name1=param1&name2=param2...).
 * Parameter names are case-sensitive whereas header names are case-insensitive.
 * Parameters are saved in this class as a separate list.
 *
 * Cookies are also saved in a separete list even though they come from the header.
 * This is because a cookie is more structured than a regular header.
 *
 * The purpose of the HttpMessage and its subclass is to hold the information about
 * an HTTP message. It does not deal with how the message is constructed or the
 * the message transportation.
 *
 * Follows RFC2616 for HTTP specification.
 *
 **/
class HttpMessage
{
public:

    /**
     * @brief Default constructor
     **/
    HttpMessage();

    /**
     * @brief destructor
     **/
    virtual ~HttpMessage();

    /**
     * @brief Returns the general headers in a hash table.
     *
     * The keys are header names and values are header values.
     * Header names are case-insensitive.
     * @return Hash table of the general headers
     **/
    const CaseInsensitiveStrMap& getGeneralHeaders() const
    {
        return generalHeaders;
    }

    /**
     * @brief Returns either request/response headers in a hash table.
     *
     * Usually an Http message is created as either a request or response
     * message and so this method returns either one of them.
     * The keys are header names and values are header values.
     * Header names are case-insensitive.
     * @return Hash table of the general headers
     **/
    const CaseInsensitiveStrMap& getMsgHeaders() const
    {
        return extensionHeaders;
    }

    /**
     * @brief Returns the entity and extension headers in a hash table.
     *
     * The keys are header names and values are header values.
     * Header names are case-insensitive.
     * @return Hash table of the general headers
     **/
    const CaseInsensitiveStrMap& getEntityHeaders() const
    {
        return entityHeaders;
    }


    /**
     * @brief Concatenates the headers into a string and returns it.
     *
     * The headers are in the correct order: general + request or response + entity/extension.
     * Header name and value of each header are separated by  ": ".
     * Each header is separated by CRLF (\\r\\n).
     * @return Headers concatenated into a string.
     **/
    std::string getHeaderString() const;


    /**
     * @brief Searches for the header and returns the value in the second argument.
     *
     * Note that the header name is case insensitive.
     * @param name Name of the header to search
     * @param value Value of the header to be returned.
     * @return True if the header exist. Otherwise returns false, in
     *         which case the returned value should be ignored.
     **/
    bool getHeader(const std::string& name, std::string& value) const;

    /**
     * @brief Check if the header exists.
     *
     * The header name is case insensitive.
     * @param name Header name
     * @return True if the header exists. Otherwise returns false.
     **/
    bool hasHeader(const std::string& name) const;

    /**
     * @brief Check if the header exists and check if its value
     * equals the expected value.
     *
     * The third argument indicates whether the
     * value is case-sensitive or not. The header name itself is always case-insensitive.
     * @param name Header name
     * @param value Expected header value
     * @param caseSensitive True if the value is case-sensitive. Otherwise false.
     * @return True if the header name is found (case-insensitive) and its value
     *         equals the expected value in the second argument. Use string
     *         comparison to compare the header value and the expected value,
     *         using case-sensitive or case-insensitive depending on the third argument.
     **/
    bool hasHeader(const std::string& name,
                   const std::string& value,
                   bool caseSensitive=false) const;

    /**
     * @brief Sets the header. If the header does not exist, add it first and set the value.
     *
     * Header name is case-insensitive.
     * @param name Header name
     * @param value Header value
     **/
    void setHeader(const std::string& name, const std::string& value);

    /**
     * @brief Removes the header from the list.
     *
     * Header name is case-insensitive.
     * @param name Header name
     **/
    void removeHeader(const std::string& name);

    /**
     * @brief Extracts header name and value from a string and save them in a
     * hash table, depending on the type of the header (general, request, response,
     * or entiry/extension header).
     *
     * @param str String containing header name and value separated by a colon and spaces.
     * @return True if the string is parsed successfully.
     **/
    bool parseHeader(const std::string& str);

    /**
     * @brief Extracts cookies from a cookie header and save them in the cookie list.
     *
     * @param str String containing a cookie header.
     * @return True if the string is parsed successfully. Else returns false.
     **/
    bool parseCookieHeader(const std::string& str);

    /**
     * @brief Extracts a cookie from a Set-Cookie header and save it in the cookie list.
     * @param str String contain a Set-Cookie header
     * @param host_ Host name of the where the Set-Cookie comes from. Used to validated
     *              the cookie's domain field.
     * @param path_ Path of the request that initiates the response containing
     *              the Set-Cookie header. Used to validate the cookie's path field.
     * @return True if the string is a valid Set-Cookie header for the given host_ and path_.
     **/
    bool parseSetCookieHeader(const std::string& str,
                              const std::string& host_,
                              const std::string& path_);



    /**
     * @brief Returns the message body.
     *
     * The body may be an empty string if the application reads the body directly, for example, using
     * HttpClient->readResponseBody().
     * Note that the body may be modified by the caller of this method.
     * @return Body string
     **/
    std::string& getBody()
    {
        return body;
    }

    /**
     * @brief Returns the message body.
     *
     * The body may be an empty string if the application reads the body directly, for example, using
     * HttpClient->readResponseBody().
     * Note that the body can not be modified by the caller of this method.
     * @return Body string
     **/
    const std::string& getBody() const
    {
        return body;
    }

    /**
     * @brief Copies the buffer into the message body.
     *
     * If buf is null, the body will be set to an empty string.
     * @param buf String buffer.
     * @param size Buffer size
     **/
    void setBody(const char* buf, size_t size)
    {
        if (buf == NULL) {
            body = "";
        } else {
            body.append(buf, size);
        }

    }

    /**
     * @brief Copies the buffer into the message body.
     *
     * If buf is null, the body will be set to an empty string.
     * @param buf String buffer.
     **/
    void setBody(const std::string& buf)
    {
        body = buf;
    }


    /**
     * @brief Sets Content-Length header
     * @param length Content length in bytes.
     **/
    void setContentLength(long int length);

    /**
     * @brief Returns the value of Content-Length header.
     * @return Content length in bytes
     **/
    long int getContentLength() const;

    /**
     * @brief Sets Content-Type header.
     * @param type Content type
     * @see HttpConst.h
     **/
    void setContentType(const std::string& type);

    /**
     * @brief Returns the value of Content-Type header.
     * @return Content type
     **/
    std::string getContentType() const;

    /**
     * @brief Sets Content-Encoding header, such as compress, gzip and deflate.
     * @param str Content encoding
     * @see HttpConst.h
     **/
    void setContentEncoding(const std::string& str);

    /**
     * @brief Returns the value of Content-Encoding header, such as compress, gzip and deflate.
     * @return Content encoding
     **/
    std::string getContentEncoding() const;


    /**
     * @brief Sets Date header
     * @param d Date string
     **/
    void setDate(const std::string& d);

    /**
     * @brief Return the value of Date header
     * @return Date string from Date header
     **/
    std::string getDate() const;



    /**
     * @brief Returns true if the message body is chunked encoded
     * @return True if Transfer-Encoding is chunked.
     * @todo To be moved to HttpStream or something like that
     **/
    bool isChunkedEncoding() const;

    /**
     * @brief Indicates that the message body is in chunk encoding.
     * @param b True if Transfer-Encoding is chunked.
     * @todo To be moved to HttpStream or something like that
     **/
    void setChunkedEncoding(bool b);

    /**
     * To be moved to xos_cpp
     **/

    /**
     * @brief Utility function that returns current date and time in the HTTP Date header format.
     * @return Date and time string
     * @todo Move it to xos_cpp or to HttpUtil.
     **/
    static std::string getCurrentDateTime();


    /**
     * @brief Adds or replaces a parameter.
     *
     * A parameter is a name and value pair listed in the URL (request line)
     * or in the FORM data (in the request body). Parameters are differentiated from
     * the headers, eventhough they both consist of a name and value. Header names
     * are case-insensitive but parameter names are case-sensitive.
     *
     * @param name Parameter name (case-sensitive)
     * @param value Parameter value
     **/
    void setParam(const std::string& name, const std::string& value);

    /**
     * @brief Searches for the parameter of a given name. Returns the
     * value in the second argument.
     *
     * Parameter names are case-sensitive.
     *
     * @param name Parameter name
     * @param value Returned parameter value
     * @return True if the parameter is found.
     * @see setParam(const std::string& name, const std::string& value)
     **/
    bool getParam(const std::string& name, std::string& value) const;

    /**
     * @brief Searches for the name in the parameters and the header hash tables and returns
     * the value in the second argument.
     *
     * Use case-sensitive search in the parameter table. If not found,
     * use case-insensitive search in the header table.
     * @param name Parameter name
     * @param value Returned value
     * @return True if name is found in one of the hash tables.
     **/
    bool getParamOrHeader(const std::string& name, std::string& value) const;

    /**
     * @brief Returns the parameter hash table. The keys are case-sensitive and are
     * the parameter names.
     *
     * @return Parameter hash table. The table can not be modified by the caller.
     **/
    const StrMap& getParameters() const
    {
        return params;
    }

    /**
     * @brief Adds a cookie to the list.
     * @param cookie The cookie to add to the cookie list.
     **/
    void addCookie(const HttpCookie& cookie);


    /**
     * @brief Returns the cookie list.
     *
     * @return Cookie list
     **/
    const std::vector<HttpCookie>& getCookies() const
    {
        return cookies;
    }


private:

    /**
     * General headers
     **/
    CaseInsensitiveStrMap generalHeaders;

    /**
     * Request and response headers
     **/
    CaseInsensitiveStrMap msgHeaders;

    /**
     * Extension headers
     **/
    CaseInsensitiveStrMap extensionHeaders;
    /**
     * entity headers
     **/
    CaseInsensitiveStrMap entityHeaders;

    /**
     * Cookie list
     **/
    std::vector<HttpCookie> cookies;

    /**
     * List of parameter names and values
     * Unlike headers, param names are case sensitive.
     * param are extracted from the query part of the URI
     * and from the form (in the message body).
     **/
    StrMap params;

    /**
     * Extensible-sized buffer for holding the message body
     **/
    std::string     body;

    /**
     * To be moved to HttpStream type of class
     **/
    bool chunkedEncoding;
    long int contentLength;


    /**
     * Returns true if the given map contains the name
     **/
    bool hasHeader(const CaseInsensitiveStrMap& hash,
                    const std::string& name) const;

    /**
     * Returns true if the given map contains the name
     * The name and value will be erased from the map
     **/
    bool removeHeader(CaseInsensitiveStrMap& hash,
                    const std::string& name);

    /**
     * Returns true if the given map contains the name
     * The value is returned in the third arg
     **/
    bool getHeader(const CaseInsensitiveStrMap& hash,
                    const std::string& name,
                    std::string& value) const;

    /**
     * Inserts the name and value to the map
     * If the name already exist, its name and value will be replaced by the new one.
     * Note that the name is case insensitive. If the old name/value is, for example,
     * appName/myapp and the new name/value is APPNAME/xxxx,
     * the new name and value will be changed to APPNAME/xxxx.
     **/
    void setHeader(CaseInsensitiveStrMap& hash,
                    const std::string& name,
                    const std::string& value);

    static CaseInsensitiveStrSet generalHeaderNames;
    static CaseInsensitiveStrSet msgHeaderNames;
    static CaseInsensitiveStrSet entityHeaderNames;

    static char generalHeaderNamesArray[9][40];
    static char msgHeaderNamesArray[30][40];
    static char entityHeaderNamesArray[9][40];

    friend class Helper;


};



#endif // __HttpMessage_h__

