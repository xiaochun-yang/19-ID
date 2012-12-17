#ifndef __Include_HttpCookie_h__
#define __Include_HttpCookie_h__

/**
 * @file HttpCookie.h
 * Header file for HTTPCookie class.
 */

#include <string>
#include "HttpConst.h"

/**
 * @class HttpCookie
 * Represents a cookie object.
 *
 * The origin server initiates a session, if it so desires. (Note that "session"
 * here does not refer to a persistent network connection but to a logical
 * session created from HTTP requests and responses. The presence or absence
 * of a persistent connection should have no effect on the use of cookie-derived
 * sessions). To initiate a session, the origin server returns an extra response
 * header to the client, Set- Cookie. (The details follow later.)
 *
 * A user agent returns a Cookie request header to the origin
 * server if it chooses to continue a session. The origin server may ignore
 * it or use it to determine the current state of the
 * session. It may send back to the client a Set-Cookie response header with
 * the same or different information, or it may send no Set-Cookie header
 * at all. The origin server effectively ends a session by sending the
 * client a Set-Cookie header with Max-Age=0.
 *
 * Servers may return a Set-Cookie response headers with any response.
 * User agents should send Cookie request headers, subject to other rules
 * detailed below, with every request.
 *
 * An origin server may include multiple Set-Cookie headers in a response.
 * Note that an intervening gateway could fold multiple such headers
 * into a single header.
 *
 * Example:
 * @code

   std::string str1("Set-Cookie: Customer=\"WILE_E_COYOTE\"; Version=\"1\"; Path=\"/store\"; domain=\".amazon.com\"");

   HttpCookie setCookie1;

   // This one will fail since the cookie domain is ".amazon.com" but the expected domain
   // is .cnn.com
   if (!parseSetCookie(setCookie1, str1, "www.cnn.com", "/store"))
       printf("Bad cookie\n");

   // This one will fail since the cookie path is /store but the path
   // we expect is /.
   if (!parseSetCookie(setCookie1, str1, "www.amazon.com", "/"))
       printf("Bad cookie\n");

   // This one will be OK
   if (!parseSetCookie(setCookie1, str1, "www.amazon.com", "/store/shoes"))
       printf("Bad cookie\n");


   std::list<HttpCookie> cookies;

   std::string str2("Cookie: $Version=\"1\"; $domain=\".amazon.com\"; Customer=\"WILE_E_COYOTE\"; $Path=\"/store\"; item=\"shoes_0001\"; $Path=\"/store/shores\"; Shipping=\"FedEx\"; $Path=\"/store/customerService\"");

   // We should get 3 cookies
   // Customer=WILE_E_COYOTE; Path=/store; domain=.amazon.com; version=1
   // item=shoes_0001; Path=/store/shoes; domain=.amazon.com; version=1
   // Shipping=FedEx; Path=/store/customerService; domain=.amazon.com; version=1
   if ((!parseCookie(cookies, str2))
      printf("bad cookie\n");



 * @endcode
 */

class HttpCookie
{
public:

    /**
     * @brief Parses a Set-Cookie header in the second argument passed into this
     * function and returns a cookie object.
     *
     *
     * @param cookie Returned cookie object
     * @param str Set-Cookie header string
     * @param host Host name of the server than sends the response containing the Set-Cookie.
     *             If the domain field of
     *             the cookie is invalid for this host (defined by RFC2109)
     *             this method will return false and the returned cookie object
     *             should not be used.
     * @param uri  URI of the request. If the path field of the cookie
     *             is not a parent of the URI path, the method returns false.
     * @return True if the func parses the Set-Cookie header successfully and the
     *         cookie fields are returned in the first argument. Returns false
     *         if the Set-Cookie header is invalid.
     * @todo Do not validate the cookie. Remove host and uri from the arg list.
     **/
    static bool parseSetCookie(HttpCookie& cookie,
                        const std::string& str,
                        const std::string& host,
                        const std::string& uri);

    /**
     * @brief Parses a Cookie header and return the cookie fields in the first argument.
     *
     * @param cookie Returned cookie object
     * @param str Cookie header
     * @return True if the func successfully parses the the string and sets the cookie fields
     *         Otherwise returns false.
     * @todo This method should take std::list<HttpCooke>& as the first argument.
     **/
    static bool parseCookie(HttpCookie& cookie,
                            const std::string& str);



    /**
     * @brief Default constructor
     **/
    HttpCookie();


    /**
     * @brief Constructor. Create a cookie from cookie parameters.
     *
     * @param name Parameter name of the cookie
     * @param value Parameter value of the cookie
     * @param comment Comment field
     * @param domain Domain field
     * @param maxAge Max-Age field
     * @param path Path Field
     * @param secure Secure field
     * @param version Version field
     **/
    HttpCookie(const std::string& name,
               const std::string& value,
               const std::string& comment,
               const std::string& domain,
               unsigned int maxAge,
               const std::string& path,
               bool secure,
               const std::string& version);

    /**
     * @brief Destructor
     **/
    ~HttpCookie();


    /**
     * @brief Initialize cookie fields.
     * Applies default values to optional fields:
     *
     * Version is defaulted to 1. Max-Age defaulted to 0. Secure defaulted to false.
     *
     **/
    void init();

    /**
     * @brief Returns the comment field
     * @return Comment field
     **/
    std::string getComment() const;

    /**
     * @brief Sets the comment field
     * @param comment New String for the comment field
     **/
    void setComment(const std::string& comment);

    /**
     * @brief Returns the domain field
     * @return Domain field
     **/
    std::string getDomain() const;

    /**
     * @brief Sets the domain field
     * @param domain New String for the domain field
     **/
    void setDomain(const std::string& domain);

    /**
     * @brief Returns the Max-Age field
     * @return Max-Age field
     **/
    unsigned int getMaxAge() const;

    /**
     * @brief Sets the Max-Age field
     * @param maxAge Number of seconds the cookie should be saved.
     **/
    void setMaxAge(unsigned int maxAge);

    /**
     * @brief Returns the path field
     * @return path field
     **/
    std::string getPath() const;

    /**
     * @brief Sets the path field
     * @param path New path
     **/
    void setPath(const std::string& path);

    /**
     * @brief Returns the secure field
     * @return secure field
     **/
    bool getSecure() const;

    /**
     * @brief Sets the secure field
     * @param secure True or false
     **/
    void setSecure(bool secure);

    /**
     * @brief Returns the version field
     * @return version field
     **/
    std::string getVersion() const;

    /**
     * @brief Sets the version field
     * @param version Version string
     **/
    void setVersion(const std::string& version);

    /**
     * @brief Returns the parameter name
     * @return parameter name
     **/
    std::string getName() const;

    /**
     * @brief Sets the parameter name
     * @param name Parameter name
     **/
    void setName(const std::string& name);

    /**
     * @brief Returns the parameter value
     * @return parameter value
     **/
    std::string getValue() const;

    /**
     * @brief Sets the parameter value
     * @param value Parameter value
     **/
    void setValue(const std::string& value);

    /**
     * @brief Utility method for printing out cookie fields to stdout
     **/
    void dump() const;

    /**
     * @brief Utility method for printing out cookie fields to the output stream
     **/
    void dump(FILE* fd) const;

private:

    /**
     * Required.  The name of the state information ("cookie") is NAME,
     * and its value is VALUE.  NAMEs that begin with $ are reserved for
     * other uses and must not be used by applications.
     **/
    std::string paramName;

    /**
     * The VALUE is opaque to the user agent and may be anything the
     * origin server chooses to send, possibly in a server-selected
     * printable ASCII encoding.  "Opaque" implies that the content is of
     * interest and relevance only to the origin server.  The content
     * may, in fact, be readable by anyone that examines the Set-Cookie
     * header.
     **/
    std::string paramValue;

    /**
     * Optional.  Because cookies can contain private information about a
     * user, the Cookie attribute allows an origin server to document its
     * intended use of a cookie.  The user can inspect the information to
     * decide whether to initiate or continue a session with this cookie.
     **/
    std::string comment;

    /**
     * Optional. The Domain attribute specifies the domain for which the
     * cookie is valid.  An explicitly specified domain must always start
     * with a dot.
     **/
    std::string domain;

    /**
     * Optional.  The Max-Age attribute defines the lifetime of the
     * cookie, in seconds.  The delta-seconds value is a decimal non-
     * negative integer.  After delta-seconds seconds elapse, the client
     * should discard the cookie.  A value of zero means the cookie
     * should be discarded immediately.
     **/
    unsigned int maxAge;

    /**
     * Optional.  The Path attribute specifies the subset of URLs to
     * which this cookie applies.
     **/
    std::string path;

    /**
     * Optional.  The Secure attribute (with no value) directs the user
     * agent to use only (unspecified) secure means to contact the origin
     * server whenever it sends back this cookie.
     *
     * The user agent (possibly under the user's control) may determine
     * what level of security it considers appropriate for "secure"
     * cookies.  The Secure attribute should be considered security
     * advice from the server to the user agent, indicating that it is in
     * the session's interest to protect the cookie contents.
     **/
    bool secure;

    /**
     * Required.  The Version attribute, a decimal integer, identifies to
     * which version of the state management specification the cookie
     * conforms.  For this specification, Version=1 applies.
     **/
    std::string version;



    /**
     * Convenient variable
     **/
    std::string semicolon;
    std::string space;
    std::string quote;
    std::string equals;

    /**
     **/
    static bool validateSetCookie(const HttpCookie& cookie,
                        const std::string& host,
                        const std::string& uri);

};


#endif // __Include_HttpCookie_h__

