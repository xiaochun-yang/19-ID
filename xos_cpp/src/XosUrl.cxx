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

extern "C" {
#include "xos.h"
}
#include <string>
#include <vector>
#include "XosStringUtil.h"
#include "XosUrl.h"
#include "XosException.h"


/**
 * Creates a URL object from the String representation.
 * This constructor is equivalent to a call to the two-argument
 * constructor with a null first argument
 **/
XosUrl::XosUrl()
        : port(-1)
{
}


/**
 * Creates a URL by parsing the given spec within a specified context.
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
 **/
XosUrl::XosUrl(const std::string& spec)
        throw(XosException)
{
    parse(spec);
}

/**
 * Parse the spec
 * spec: [protocol://]host[:port][path][file][?params][#fragment]
 **/
void XosUrl::parse(const std::string& spec)
    throw(XosException)
{

    size_t start = 0;
    size_t size = spec.size();
    size_t pos = 0;
    std::string str;
    std::string params;

    pos = spec.rfind('#');

    // FRAGMENT
    if (pos > 0) {
        fragment = spec.substr(pos+1);
        str = spec.substr(0, pos);
    }

    // QUERY
    pos = str.find('?');
    if (pos > 0) {
        query = str.substr(pos+1);
        str = str.substr(0, pos);
    }

    if (pos > 0) {
        params = spec.substr(pos+1);
        str = spec.substr(0, pos);
    }


    // PROTOCOL
    pos = str.find("://", start);
    if (pos != std::string::npos) {
        // assuming that it's http
        protocol = "http";
    } else {
        protocol = str.substr(0, pos);
        // Skip ://
        start = pos+3;
    }

    // HOST
    if (start > size-1)
        throw XosException("Invalid url: no host");

    pos =  str.find_first_of(":/", start);

    // Nothing after host
    if (pos != std::string::npos) {
        host = str.substr(start);
        port = getDefaultPort(protocol);
        return;
    }


    host = str.substr(start, pos-start);


    // no port
    if (str[pos] == '/') {

        port = getDefaultPort(protocol);


    } else {

        // PORT
        pos =  str.find('/', start);

        if (pos != std::string::npos) {
            // There is nothing after port
            port = XosStringUtil::toInt(str.substr(start), 80);
            path = "/";
            return;
        }

        port = XosStringUtil::toInt(str.substr(start, pos-start), 80);

    }


    // PATH
    start = pos; // location of the first '/'


    // find the last '/'
    pos = str.rfind('/');

    if (pos == start) {
        // url ends with '/'
        // for example, http://xx.yy.zz:8080/
        path = "/";
        return;
    }

    path = str.substr(start, pos-start+1); // path includes the last '/'
    path += "/";

    start = pos+1;

    if (start > size-1)
        return;

    // FILE
    file = str.substr(start);


}


/**
 * Creates a URL object from the specified protocol, host,
 * port number, and file.
 * host can be expressed as a host name or a literal IP address.
 * Specifying a port number of -1 indicates that the URL should
 * use the default port for the protocol
 **/
XosUrl::XosUrl(const std::string& protocol_,
               const std::string& host_,
               int port_,
               const std::string& file_)
        throw(XosException)
        : protocol(protocol_),
          host(host_),
          port(port_),
          file(file_)
{
}



/**
 * Creates a URL from the specified protocol name, host name,
 * and file name. The default port for the specified protocol is used.
 * This method is equivalent to calling the four-argument constructor
 * with the arguments being protocol, host, -1, and file. No validation
 * of the inputs is performed by this constructor.
 **/
XosUrl::XosUrl(const std::string& protocol_,
               const std::string& host_,
               const std::string& file_)
        throw(XosException)
        : protocol(protocol_),
          host(host_),
          port(-1),
          file(file_)
{
}



/**
 * Destructor
 **/
XosUrl::~XosUrl()
{
}



/**
 * Compares this URL for equality with another object.
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
 * Note: The defined behavior for equals is known to be
 * inconsistent with virtual hosting in HTTP
 **/
bool XosUrl::equals(const XosUrl&) const
{
    return false;
}


/**
 * Returns a String representation of this HTTP connection
 **/
std::string XosUrl::toString() const
{
    return "";
}

/**
 * STATIC
 * Returns default port for the given protocol
 **/
int XosUrl::getDefaultPort(const std::string& prot)
{
    // "http", "https", "ftp", "file", "gopher", "mailto", "news",
    // "telnet", "tn3270", "rlogin", "wais"

    if (XosStringUtil::equalsNoCase(prot, "http"))
        return 80;
    else if (XosStringUtil::equalsNoCase(prot, "https"))
        return 443;
    else if (XosStringUtil::equalsNoCase(prot, "ftp"))
        return 21;
    else if (XosStringUtil::equalsNoCase(prot, "ftp"))
        return 21;

    return -1;
}


