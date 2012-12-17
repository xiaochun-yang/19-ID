/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/

/**
 * Class URL represents a Uniform Resource Locator, a pointer to a "resource"
 * on the World Wide Web. A resource can be something as simple as a file or
 * a directory, or it can be a reference to a more complicated object, such
 * as a query to a database or to a search engine. More information on the
 * types of URLs and their formats can be found at:
 *
 * http://archive.ncsa.uiuc.edu/SDG/Software/Mosaic/Demo/url-primer.html
 * In general, a URL can be broken into several parts. The previous example
 * of a URL indicates that the protocol to use is http (HyperText Transfer
 * Protocol) and that the information resides on a host machine named
 * www.ncsa.uiuc.edu. The information on that host machine is named /
 * SDG/Software/Mosaic/Demo/url-primer.html. The exact meaning of this
 * name on the host machine is both protocol dependent and host dependent.
 * The information normally resides in a file, but it could be generated on
 * the fly. This component of the URL is called the path component.
 *
 * A URL can optionally specify a "port", which is the port number to which
 * the TCP connection is made on the remote host machine. If the port is not
 * specified, the default port for the protocol is used instead. For example,
 * the default port for http is 80. An alternative port could be specified as:
 *
 *      http://archive.ncsa.uiuc.edu:80/SDG/Software/Mosaic/Demo/url-primer.html
 *  The syntax of URL is defined by RFC 2396: Uniform Resource Identifiers (URI):
 *  Generic Syntax, amended by RFC 2732: Format for Literal IPv6 Addresses in URLs.
 *
 * A URL may have appended to it a "fragment", also known as a "ref" or a
 * "reference". The fragment is indicated by the sharp sign character "#"
 * followed by more characters. For example,
 *
 *      http://java.sun.com/index.html#chapter1
 *  This fragment is not technically part of the URL. Rather, it indicates
 *  that after the specified resource is retrieved, the application is
 *  specifically interested in that part of the document that has the tag
 *  chapter1 attached to it. The meaning of a tag is resource specific.
 *
 * An application can also specify a "relative URL", which contains only
 * enough information to reach the resource relative to another URL.
 * Relative URLs are frequently used within HTML pages. For example,
 * if the contents of the URL:
 *
 *      http://java.sun.com/index.html
 *  contained within it the relative URL:
 *      FAQ.html
 *  it would be a shorthand for:
 *      http://java.sun.com/FAQ.html
 *  The relative URL need not specify all the components of a URL. If the
 *  protocol, host name, or port number is missing, the value is inherited
 *  from the fully specified URL. The file component must be specified.
 *  The optional fragment is not inherited
 *
 **/

#ifndef __Include_XosUrl_h__
#define __Include_XosUrl_h__

/**
 * @file XosUrl.h
 * Header file for constructing a URL object.
 */

extern "C" {
#include "xos.h"
}

#include <string>

#include "XosException.h"


/**
 * @class XosUrl
 * A class representing a URL. A URL can be constructed from a string or from
 * a list of URL parts such as protocol name, host, port and etc.
 * Example
 *
 * @code

   try {

       // Create a url from a string
       XosUrl url1("http://www.google.com/search?hl=en&ie=UTF-8&oe=UTF-8&q=shoes");

       // Creates a url from protocol, host, port and file
       XosUrl url2("http", "www.google.com", 80, "/search?hl=en&ie=UTF-8&oe=UTF-8&q=shoes");

       // Creates a url from protocol, host, and file
       // Assuming port 80 since protocol is http and default port for http is 80.
       XosUrl url3("http", "www.google.com", /search?hl=en&ie=UTF-8&oe=UTF-8&q=shoes");


       // These two urls are the same.
       XosUrl url4("http://www.google.com:80/index.html");
       XosUrl url5("http://www.google.com/index.html");

       if (url4.equals(url5))
          printf("ur4 is the same as url5\n");

   } catch (XosException& e) {
       printf("Caught XosException: %s\n", e.getMessage().c_str());
   }



 * @endcode
 */

class XosUrl
{
public:

    /**
     * @brief Default constructor.
     *
     * Only useful for putting XosUrl objects
     * in an STD collection such as std::list, std::vector std::map and etc.
     * These templates require objects with default constructor.
     **/
    XosUrl();

    /**
     * @brief Creates a URL by parsing the given spec within a specified context.
     *
     * The new URL is created from the given context URL and the spec
     * argument as described in RFC2396 "Uniform Resource Identifiers :
     * Generic * Syntax" :
     *     <scheme>://<authority><path>?<query>#<fragment>
     * The reference is parsed into the scheme, authority, path, query
     * and fragment parts. If the path component is empty and the scheme,
     * authority, and query components are undefined, then the new URL
     * is a reference to the current document. Otherwise, the fragment
     * and query parts present in the spec are used in the new URL.
     * If the scheme component is defined in the given spec and does not
     * match the scheme of the context, then the new URL is created as an
     * absolute URL based on the spec alone. Otherwise the scheme component
     * is inherited from the context URL.
     * If the authority component is present in the spec then the spec
     * is treated as absolute and the spec authority and path will
     * replace the context authority and path.
     * If the spec's path component begins with a slash character "/"
     * then the path is treated as absolute and the spec path replaces
     * the context path.
     * Otherwise, the path is treated as a relative path and is appended
     * to the context path, as described in RFC2396. Also, in this case,
     * the path is canonicalized through the removal of directory
     * changes made by occurences of ".." and ".".
     * For a more detailed description of URL parsing, refer to RFC2396.
     * @param spec URL String
     * @exception XosException thrown if the spec is invalid.
     * @todo Implement this
     **/
    XosUrl(const std::string& spec)
        throw(XosException);

    /**
     * @brief Creates a URL object from the specified protocol, host,
     * port number, and file.
     *
     * host can be expressed as a host name or a literal IP address.
     * Specifying a port number of -1 indicates that the URL should
     * use the default port for the protocol.
     * @param protocol Protocol of the URI such as http, ftp and etc.
     * @param hot Host name
     * @param port Port number
     * @param Path to a file on the server relative to webroot.
     * @exception XosException Thrown if The input parameters are invalid.
     * @todo Validate input parameters. Provide default port number
     *       if -1 is given.
     * @todo Implement this
     **/
    XosUrl(const std::string& protocol,
           const std::string& host,
           int port,
           const std::string& file)
        throw(XosException);

    /**
     * @brief Creates a URL from the specified protocol name, host name,
     * and file name.
     *
     * The default port for the specified protocol is used.
     * This method is equivalent to calling the four-argument constructor
     * with the arguments being protocol, host, -1, and file. No validation
     * of the inputs is performed by this constructor.
     * @param protocol Protocol of the URI such as http, ftp and etc.
     * @param hot Host name
     * @param Path to a file on the server relative to webroot.
     * @exception XosException Thrown if The input parameters are invalid.
     * @todo Validate input parameters.
     **/
    XosUrl(const std::string& protocol,
           const std::string& host,
           const std::string& file)
           throw(XosException);

    /**
     * @brief Destructor
     **/
    virtual ~XosUrl();

    /**
     * @brief Compares this URL for equality with another object.
     *
     * If the given object is not a URL then this method immediately
     * returns false.
     * Two URL objects are equal if they have the same protocol, reference
     * equivalent hosts, have the same port number on the host, and the same
     * file and fragment of the file.
     * Two hosts are considered equivalent if both host names can be
     * resolved into the same IP addresses; else if either host name
     * can't be resolved, the host names must be equal without regard
     * to case; or both host names equal to null.
     * Since hosts comparison requires name resolution, this operation
     * is a blocking operation.
     * @param other The other URL to compare with
     * @return True if the two URLs are equals. Otherwise returns false.
     * @todo Implement this
     **/
    bool equals(const XosUrl& other) const;


    /**
     * @brief Returns port number of this URL.
     * @return Port number
     **/
    int getPort() const
    {
        return port;
    }


    /**
     * @brief Returns the file name of this URL.
     *
     * The returned file portion
     * will be the same as getPath(), plus the concatenation of the
     * value of getQuery(), if any. If there is no query portion,
     * this method and getPath() will return identical results.
     * @return Path and query of the URI
     **/
    const std::string& getFile() const
    {
        return file;
    }

    /**
     * @brief Returns the protocol name of this URL.
     * @return protocol name.
     **/
    const std::string& getProtocol() const
    {
        return protocol;
    }

    /**
     * @brief return the host name of this URL, if applicable.
     *
     * The format of the host conforms to RFC 2732, i.e. for a literal IPv6
     * address, this method will return the IPv6 address enclosed
     * in square brackets ('[' and ']').
     * @return Host name.
     **/
    const std::string& getHost() const
    {
        return host;
    }

    /**
     * @brief Returns the path part of this URL.
     * @return Path of the URI (does not include the query)
     **/
    const std::string& getPath() const
    {
        return path;
    }

    /**
     * @brief Returns the query part of this URL
     * @return Query of the URI
     **/
    const std::string& getQuery() const
    {
        return query;
    }


    /**
     * @brief Returns a String representation of this HTTP connection.
     * @return String Representing this URL.
     * @todo Implement this.
     **/
    std::string toString() const;


protected:

    /**
     * @brief Protocol such as http, ftp and etc
     */
    std::string     protocol;

    /**
     * @brief Host name
     */
    std::string     host;

    /**
     * @brief Port number. If not sepecified, defaulted to default port number
     * of the given protocol.
     */
    int             port;

    /**
     * @brief Path portion of the URI. It's the text starting from the first / character
     * and ending before ?.
     */
    std::string     path;

    /**
     * @brief Same as path text after ? character (query)
     */
    std::string     file;

    /**
     * @brief Text that follows ? character in the URI
     */
    std::string     query;

    /**
     * @brief Text that follows # character.
     */
    std::string     fragment;

private:

    /**
     * @brief Returns default port for the given protocol
     **/
    static int getDefaultPort(const std::string& prot);

    /**
     * @brief Utility func to parse the URI string. Called by the constructors.
     * @param spec Input URI string
     * @exception Thrown if the spec is not a valid URI
     */
    void parse(const std::string& spec)
        throw(XosException);


};

#endif // __Include_XosUrl_h__
