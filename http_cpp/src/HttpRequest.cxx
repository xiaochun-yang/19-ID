extern "C" {
#include "xos.h"
#include "xos_log.h"
}

#include <string>
#include <vector>
#include "HttpStatusCodes.h"
#include "XosStringUtil.h"
#include "HttpMessage.h"
#include "HttpRequest.h"
#include "HttpUtil.h"


/****************************************************
 *
 * Constructor
 *
 ****************************************************/
HttpRequest::HttpRequest()
: m_isSSL(false)
{
    method = HTTP_GET;
    version = HTTP_VERSION;

}


/****************************************************
 *
 * Destructor
 *
 ****************************************************/
HttpRequest::~HttpRequest()
{
}


/****************************************************
 *
 * Only POST and PUT are allowed to have a body
 *
 ****************************************************/
bool HttpRequest::isBodyAllowed()
{
    if (method.empty())
        return false;

    if (method == HTTP_POST)
        return true;
    else if (method == HTTP_PUT)
        return true;

    return false;
}



/****************************************************
 *
 * Extract host, resource and query from the request URI
 * The query will be further parsed and added to the
 * header
 *
 ****************************************************/
void HttpRequest::parseRequestLine(const std::string& str)
    throw (XosException)
{

    size_t pos = 0;
    size_t pos1 = 0;

    pos1 = str.find(' ', pos);

    if (pos1 == std::string::npos)
        throw XosException(422, SC_422);

    setMethod(str.substr(pos, pos1-pos));

    pos = pos1+1;
    pos1 = str.find(' ', pos);
    if (pos1 == std::string::npos)
        throw XosException(422, SC_422);

    if (!HttpUtil::decodeURI(str.substr(pos, pos1-pos), uri))
        throw XosException(424, SC_424);


    pos = pos1+1;
    setVersion(XosStringUtil::trim(str.substr(pos)));


    parseURI();
}

/****************************************************
 * The request-URI to be included in the request line
 * of the http message in the following format:
 * [http://hostname:port]/resource[?query]
 * Note that the string in the square brackets are
 * optional. For example,
 * http://blctlxx:61000/listDirectory?impUser=joe&impSessionID=LSLJFKJSDF7862KJ
 * /listDirectory?impUser=joe&impSessionID=LSLJFKJSDF7862KJ
 *
 ****************************************************/
void HttpRequest::setURI(const std::string& uri)
    throw (XosException)
{
    this->uri = uri;

    parseURI();
}


/****************************************************
 *
 * Extract host, resource and query from the request URI
 * The query will be further parsed and added to the
 * header
 *
 ****************************************************/
void HttpRequest::parseURI()
    throw (XosException)
{

    size_t pos = 0;
    size_t pos1 = 0;
    size_t pos2 = 0;

    int default_port = 80;
    m_isSSL = false;
    if (uri.find( "https" ) == 0) {
        default_port = 432;
        m_isSSL = true;
    }

    pos = uri.find("://");
    if (pos == std::string::npos) {
        pos = 0;
    } else {
        pos1 = uri.find("/", pos+3);
        if (pos1 == std::string::npos)
            pos1 = 0;
    }

    if ((pos != std::string::npos) && (pos1 > pos)) {
        std::string hostandport = uri.substr(pos+3, pos1-pos-3);
        setHeader(RQH_HOST, hostandport);
        size_t tmp = hostandport.find(":");
        if (tmp != std::string::npos) {
            host = hostandport.substr(0, tmp);
            port = XosStringUtil::toInt(hostandport.substr(tmp+1), default_port);
        } else {
            host = hostandport;
            port = default_port;
        }

    }

    pos2 = uri.find("?", pos1);
    if (pos2 != std::string::npos) {
        parseFormData(uri.substr(pos2+1));
    } else {
        pos2 = uri.size();
    }


    // resource is the string between port and ?
    if (!HttpUtil::decodeURI(uri.substr(pos1, pos2-pos1), resource))
        throw XosException(424, SC_424);


//    xos_log("method = %s\n", method.c_str());
//    xos_log("version = %s\n", version.c_str());
//    xos_log("uri = %s\n", uri.c_str());
//    xos_log("resource = %s\n", resource.c_str());


}

/****************************************************
 *
 * Extract the parameter-name/value pairs from the query
 * part of the request-URI.
 * Save them in the header hash table.
 *
 ****************************************************/
void HttpRequest::parseFormData(const std::string& str)
        throw(XosException)
{

    size_t pos1 = 0;
    size_t pos2 = 0;
    size_t pos3 = 0;
    bool done = false;
    std::string value;
    while (!done) {
        pos2 = str.find("=", pos1);
        if (pos2 == std::string::npos)
            throw XosException(423, SC_423);
        pos3 = str.find("&", pos2+1);
        if (pos3 == std::string::npos)
            done = true;

        if (!HttpUtil::decodeURI(str.substr(pos2+1, pos3-pos2-1), value))
            throw XosException(424, SC_424);

//        xos_log("parseFormData %s: %s\n",
//            str.substr(pos1, pos2-pos1).c_str(), value.c_str());
        setParam(str.substr(pos1, pos2-pos1), value);

        pos1 = pos3+1;

    }

}

/****************************************************
 *
 * Returns request attribute
 *
 ****************************************************/
bool HttpRequest::getAttribute(const std::string& n, std::string& ret)
		throw(XosException)
{
	StrMap::const_iterator i;
	if ((i = attributes.find(n)) != attributes.end()) {
		ret = i->second;
		return true;
	}

	return false;
}

/****************************************************
 *
 * Sets request attribute
 *
 ****************************************************/
void HttpRequest::setAttribute(const std::string& n, const std::string& v)
		throw(XosException)
{
    // Look in the param list only
    StrMap::iterator i;
    if ((i = attributes.find(n)) != attributes.end()) {
        attributes.erase(i);
    }

    attributes.insert(StrMap::value_type(n, v));
}

