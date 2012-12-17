#include "xos.h"
#include "loglib_quick.h"
#include <string>
#include "XosStringUtil.h"
#include "HttpUtil.h"
#include "HttpMessage.h"


/********************************************************************
 *
 * Static variables
 *
 ********************************************************************/
char HttpMessage::generalHeaderNamesArray[9][40] = {
	GH_CACHECONTROL,
	GH_CONNECT,
	GH_DATE,
	GH_PRAGMA,
	GH_TRAILER,
	GH_TRANSFERENCODING,
	GH_UPGRADE,
	GH_VIA,
	GH_WARNING
};


char HttpMessage::msgHeaderNamesArray[30][40] = {
	RQH_ACCEPTENCODING,
	GH_CONNECT,
	RQH_ACCEPT,
	RQH_ACCEPT_CHARSET,
	RQH_ACCEPT_ENCODING,
	GH_TRANSFERENCODING,
	RQH_ACCEPT_ENCODING,
	RQH_ACCEPT_LANGUAGE,
	RQH_AUTHORIZATION,
	RQH_EXPECT,
	RQH_FROM,
	RQH_HOST,
	RQH_IF_MATCH,
	RQH_IF_MODIFIED_SINCE,
	RQH_IF_NONE_MATCH,
	RQH_IF_RANGE,
	RQH_REFERER,
	RQH_TE,
	RQH_USER_AGENT,
	RQH_COOKIE,
	RES_ACCEPT_RANGE,
	RES_AGE,
	RES_ETAG,
	RES_LOCATION,
	RES_PROXY_AUTHENTICATION,
	RES_RETRY_AFTER,
	RES_SERVER,
	RES_VARY,
	RES_WWW_AUTHENTICATE,
	RES_SETCOOKIE

};

char HttpMessage::entityHeaderNamesArray[9][40] = {
	EH_ALLOW,
	EH_CONTENT_ENCODING,
	EH_CONTENT_LANGUAGE,
	EH_CONTENT_LENGTH,
	EH_CONTENT_LOCATION,
	EH_CONTENT_MD5,
	EH_CONTENT_RANGE,
	EH_CONTENT_TYPE,
	EH_LAST_MODIFIED
};

#ifdef WIN32

Helper::Helper()
{

	HttpMessage::generalHeaderNames.insert(GH_CACHECONTROL);
	HttpMessage::generalHeaderNames.insert(GH_CONNECT);
	HttpMessage::generalHeaderNames.insert(GH_DATE);
	HttpMessage::generalHeaderNames.insert(GH_PRAGMA);
	HttpMessage::generalHeaderNames.insert(GH_TRAILER);
	HttpMessage::generalHeaderNames.insert(GH_TRANSFERENCODING);
	HttpMessage::generalHeaderNames.insert(GH_UPGRADE);
	HttpMessage::generalHeaderNames.insert(GH_VIA);
	HttpMessage::generalHeaderNames.insert(GH_WARNING);

	// Request
	HttpMessage::msgHeaderNames.insert(RQH_ACCEPTENCODING);
	HttpMessage::msgHeaderNames.insert(RQH_ACCEPT);
	HttpMessage::msgHeaderNames.insert(RQH_ACCEPT_CHARSET);
	HttpMessage::msgHeaderNames.insert(RQH_ACCEPT_ENCODING);
	HttpMessage::msgHeaderNames.insert(RQH_ACCEPT_LANGUAGE);
	HttpMessage::msgHeaderNames.insert(RQH_AUTHORIZATION);
	HttpMessage::msgHeaderNames.insert(RQH_EXPECT);
	HttpMessage::msgHeaderNames.insert(RQH_FROM);
	HttpMessage::msgHeaderNames.insert(RQH_HOST);
	HttpMessage::msgHeaderNames.insert(RQH_IF_MATCH);
	HttpMessage::msgHeaderNames.insert(RQH_IF_MODIFIED_SINCE);
	HttpMessage::msgHeaderNames.insert(RQH_IF_NONE_MATCH);
	HttpMessage::msgHeaderNames.insert(RQH_IF_RANGE);
	HttpMessage::msgHeaderNames.insert(RQH_IF_UNMODIFIED_SINCE);
	HttpMessage::msgHeaderNames.insert(RQH_MAX_FORWARDS);
	HttpMessage::msgHeaderNames.insert(RQH_PROXY_AUTHENTICATION);
	HttpMessage::msgHeaderNames.insert(RQH_RANGE);
	HttpMessage::msgHeaderNames.insert(RQH_REFERER);
	HttpMessage::msgHeaderNames.insert(RQH_TE);
	HttpMessage::msgHeaderNames.insert(RQH_USER_AGENT);
	HttpMessage::msgHeaderNames.insert(RQH_COOKIE);

	// Response
	HttpMessage::msgHeaderNames.insert(RES_ACCEPT_RANGE);
	HttpMessage::msgHeaderNames.insert(RES_AGE);
	HttpMessage::msgHeaderNames.insert(RES_ETAG);
	HttpMessage::msgHeaderNames.insert(RES_LOCATION);
	HttpMessage::msgHeaderNames.insert(RES_PROXY_AUTHENTICATION);
	HttpMessage::msgHeaderNames.insert(RES_RETRY_AFTER);
	HttpMessage::msgHeaderNames.insert(RES_SERVER);
	HttpMessage::msgHeaderNames.insert(RES_VARY);
	HttpMessage::msgHeaderNames.insert(RES_WWW_AUTHENTICATE);
	HttpMessage::msgHeaderNames.insert(RES_SETCOOKIE);

	HttpMessage::msgHeaderNames.insert(EH_ALLOW);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_ENCODING);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_LANGUAGE);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_LENGTH);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_LOCATION);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_MD5);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_RANGE);
	HttpMessage::msgHeaderNames.insert(EH_CONTENT_TYPE);
	HttpMessage::msgHeaderNames.insert(EH_EXPIRES);
	HttpMessage::msgHeaderNames.insert(EH_LAST_MODIFIED);


}


CaseInsensitiveStrSet HttpMessage::generalHeaderNames;
CaseInsensitiveStrSet HttpMessage::msgHeaderNames;
CaseInsensitiveStrSet HttpMessage::entityHeaderNames;

static Helper helper;


#else

Helper::Helper()
{
}

CaseInsensitiveStrSet HttpMessage::generalHeaderNames(generalHeaderNamesArray, generalHeaderNamesArray + 9);
CaseInsensitiveStrSet HttpMessage::msgHeaderNames(msgHeaderNamesArray, msgHeaderNamesArray+30);
CaseInsensitiveStrSet HttpMessage::entityHeaderNames(entityHeaderNamesArray, entityHeaderNamesArray+9);

#endif // ifdef NT


/********************************************************************
 *
 * Default constructor
 *
 ********************************************************************/
HttpMessage::HttpMessage()
	: generalHeaders(),
	  msgHeaders(),
	  extensionHeaders(),
	  entityHeaders(),
	  cookies(),
	  params(),
	  body()
{
    chunkedEncoding = false;
    contentLength = 0;

}

/********************************************************************
 *
 * Virtual destructor
 *
 ********************************************************************/
HttpMessage::~HttpMessage()
{
}


/********************************************************************
 *
 * Add or replace the parameter
 * Case sensitive
 *
 ********************************************************************/
void HttpMessage::setParam(const std::string& name, const std::string& value)
{
    // Look in the param list only
    StrMap::iterator i;
    if ((i = params.find(name)) != params.end()) {
        params.erase(i);
    }

    params.insert(StrMap::value_type(name, value));
}

/********************************************************************
 *
 * Returns true if the parameter table contains the name.
 * Return the value in the second arg
 *
 ********************************************************************/
bool HttpMessage::getParam(const std::string& name, std::string& value) const
{
    // Look in the param list only
    StrMap::const_iterator i;
    if ((i = params.find(name)) != params.end()) {
        value = i->second;
        return true;
    }

    return false;
}

/********************************************************************
 *
 * Look for name in param list first. If not found, look in
 * the headers.
 * Return true if name is found in either lists.
 * Return the value in the second arg
 *
 ********************************************************************/
bool HttpMessage::getParamOrHeader(const std::string& name, std::string& value) const
{
    // Look in the param list first
    StrMap::const_iterator i;
    if ((i = params.find(name)) != params.end()) {
        value = i->second;
        return true;
    }

    // Then look in the headers
    return getHeader(name, value);
}


/********************************************************************
 *
 * Concatenated all of the headers in the correct order (general + other + entity)
 * Each header name and value are separated by  ": ".
 * Each header is separated by CRLF (\r\n).
 *
 ********************************************************************/
std::string HttpMessage::getHeaderString() const
{
    std::string ret("");

    // Start with general headers
    CaseInsensitiveStrMap::const_iterator i = generalHeaders.begin();

    for (; i != generalHeaders.end(); ++i) {
        ret += i->first + ": " + i->second + CRLF;
    }

    // Followed by other headers including request or response
    i = msgHeaders.begin();

    for (; i != msgHeaders.end(); ++i) {
        ret += i->first + ": " + i->second + CRLF;
    }


    // Followed by entity headers
    i = entityHeaders.begin();

    for (; i != entityHeaders.end(); ++i) {
        ret += i->first + ": " + i->second + CRLF;
    }

    return ret;

}


/********************************************************************
 *
 * Returns the header value in the second argument
 * Returns false if the header name is empty or if the header does not exist.
 * The argument value should not be used if the func does not return true.
 * Header name is case insensitive.
 *
 ********************************************************************/
bool HttpMessage::getHeader(const std::string& name, std::string& value) const
{
    if (name.empty())
        return false;

    // First, look in the general header
    if (getHeader(generalHeaders, name, value))
        return true;

    // Then look in the other header
    if (getHeader(msgHeaders, name, value))
        return true;

    // Then look in the entity header
    return getHeader(entityHeaders, name, value);


}

/********************************************************************
 *
 * Utility method: get the param value from the given table.
 *
 ********************************************************************/
bool HttpMessage::hasHeader(const CaseInsensitiveStrMap& hash,
                            const std::string& name) const
{
    // Look in the general header first
    CaseInsensitiveStrMap::const_iterator i = hash.find(name);

    return (i != hash.end());
}

/********************************************************************
 *
 * Utility method: get the param value from the given table.
 *
 ********************************************************************/
bool HttpMessage::getHeader(const CaseInsensitiveStrMap& hash,
                            const std::string& name,
                            std::string& value) const
{
    // Look in the general header first
    CaseInsensitiveStrMap::const_iterator i = hash.find(name);

    if (i != hash.end()) {
        value = i->second;
        return true;
    }

    return false;
}

/********************************************************************
 *
 * Utility method: get the param value from the given table.
 *
 ********************************************************************/
void HttpMessage::setHeader(CaseInsensitiveStrMap& hash,
                            const std::string& name,
                            const std::string& value)
{
    // Look in the general header first
    CaseInsensitiveStrMap::iterator i = hash.find(name);

    if (i != hash.end())
        hash.erase(i);

    hash.insert(CaseInsensitiveStrMap::value_type(name, value));
}

/********************************************************************
 *
 * Utility method: get the param value from the given table.
 *
 ********************************************************************/
bool HttpMessage::removeHeader(CaseInsensitiveStrMap& hash,
                                const std::string& name)
{
    // Look in the general header first
    CaseInsensitiveStrMap::iterator i = hash.find(name);

    if (i != hash.end()) {
        hash.erase(i);
        return true;
    }

    return false;
}

/********************************************************************
 *
 * Sets the header.
 * Header name is case insensitive.
 * TODO: Move chunkEncoding var to the stream class
 *
 ********************************************************************/
void HttpMessage::setHeader(const std::string& name, const std::string& value)
{
    if (name.empty())
        return;

    setHeader(entityHeaders, name, value);

	if ((name == GH_TRANSFERENCODING) &&
		(value.find(WWW_CODING_CHUNKED) != std::string::npos)) {
//		LOG_HTTP_CPP(LOG_FINEST, "in setHeader found chunked transfer-encoding\n");
		chunkedEncoding = true;
	}

	if (name == EH_CONTENT_LENGTH) {
		contentLength = XosStringUtil::toLongInt(value, 0);
	}

//    LOG_HTTP_CPP2(LOG_FINEST,
//    		"in HttpMessage::setHeader: entity header name = %s, value = %s\n",
//            name.c_str(), value.c_str());

}

/********************************************************************
 *
 * Returns false if the name is empty or the header does not exist.
 * Header name is case insensitive.
 *
 ********************************************************************/
bool HttpMessage::hasHeader(const std::string& name) const
{
    if (name.empty())
        return false;

    if (hasHeader(generalHeaders, name))
        return true;

    if (hasHeader(msgHeaders, name))
        return true;


    return hasHeader(entityHeaders, name);

}

/********************************************************************
 *
 * Returns false if the name is empty or the header does not exist
 * Or if the value is not equal to the header value, using case sensitived comparison.
 * Header name is case insensitive.
 *
 ********************************************************************/
bool HttpMessage::hasHeader(const std::string& name,
                            const std::string& value,
                            bool caseSensitive) const
{
    if (name.empty())
        return false;

    std::string ret;
    if (!getHeader(generalHeaders, name, ret)) {
        if (!getHeader(msgHeaders, name, ret)) {
            if (!getHeader(entityHeaders, name, ret))
                return false;
        }
     }


    if (!caseSensitive)
        return XosStringUtil::equalsNoCase(ret, value);

    return (ret == value);

}

/********************************************************************
 *
 * Removes the header. Header name is case insensitive.
 *
 ********************************************************************/
void HttpMessage::removeHeader(const std::string& name)
{
    if (removeHeader(generalHeaders, name)) {
        if (name == GH_TRANSFERENCODING)
            chunkedEncoding = false;
        return;
    }

    if (removeHeader(msgHeaders, name))
        return;

    removeHeader(entityHeaders, name);

}

/********************************************************************
 *
 * Extracts header name and value from the buffer.
 * Returns true if successful.
 *
 ********************************************************************/
bool HttpMessage::parseHeader(const std::string& buf)
{
    std::string name;
    std::string value;

    if (!XosStringUtil::split(buf, ":", name, value))
        return false;


    setHeader(XosStringUtil::trim(name), XosStringUtil::trim(value));

    return true;

}


/********************************************************************
 *
 * Extracts a cookie from Cookie header (only in request message)
 * Returns true if successful.
 *
 ********************************************************************/
bool HttpMessage::parseCookieHeader(const std::string& buf)
{
    std::string name;
    std::string value;

    if (!XosStringUtil::split(buf, ":", name, value))
        return false;


    // Cookie header in the request
    if (name == RQH_COOKIE) {

        HttpCookie cookie;
        if (!HttpCookie::parseCookie(cookie, value))
            return false;

        addCookie(cookie);

        return true;

    }

    return false;


}



/********************************************************************
 *
 * Extracts a cookie from Set-Cookie header (in response header)
 * Returns true if successful.
 *
 ********************************************************************/
bool HttpMessage::parseSetCookieHeader(const std::string& buf,
                            const std::string& host_,
                            const std::string& uri_)
{
    std::string name;
    std::string value;

    if (!XosStringUtil::split(buf, ":", name, value))
        return false;


    // Set-Cookie header in the response
    if (XosStringUtil::equalsNoCase(name, RES_SETCOOKIE)) {

        HttpCookie cookie;
        // Reject bad cookies right away
        if (HttpCookie::parseSetCookie(cookie, value, host_, uri_)) {
            // No validation at this point
            addCookie(cookie);
            return true;
        }
    }


    return false;

}

/********************************************************************
 *
 *
 *
 ********************************************************************/
void HttpMessage::addCookie(const HttpCookie& cookie)
{
    cookies.push_back(cookie);
}



/********************************************************************
 *
 * TODO: Move it to the stream class
 *
 ********************************************************************/
bool HttpMessage::isChunkedEncoding() const
{
    return chunkedEncoding;
}

/********************************************************************
 *
 * TODO: Move it to the stream class
 *
 ********************************************************************/
void HttpMessage::setChunkedEncoding(bool b)
{
    if (b) {
        setHeader(GH_TRANSFERENCODING, WWW_CODING_CHUNKED);
    } else {
        removeHeader(GH_TRANSFERENCODING);
    }
}

/********************************************************************
 *
 * Set Content-Length header
 *
 ********************************************************************/
void HttpMessage::setContentLength(long int length)
{
    char tmp[20];
    sprintf(tmp, "%ld", length);

    setHeader(EH_CONTENT_LENGTH, tmp);
}

/********************************************************************
 *
 * TODO: remove contentLength variable
 *
 ********************************************************************/
long int HttpMessage::getContentLength() const
{
    return contentLength;
}

/********************************************************************
 *
 * Sets Content-Type header
 *
 ********************************************************************/
void HttpMessage::setContentType(const std::string& type)
{
    setHeader(EH_CONTENT_TYPE, type);
}


/********************************************************************
 *
 * Returns Content-Type header
 *
 ********************************************************************/
std::string HttpMessage::getContentType() const
{
    std::string tmp;
    if (getHeader(EH_CONTENT_TYPE, tmp)) {
        return tmp;
    }

    return "";
}


/********************************************************************
 *
 * Sets Content-Encoding header
 *
 ********************************************************************/
void HttpMessage::setContentEncoding(const std::string& str)
{
    setHeader(EH_CONTENT_ENCODING, str);
}


/********************************************************************
 *
 * Returns Content-Encoding header
 *
 ********************************************************************/
std::string HttpMessage::getContentEncoding() const
{
    std::string ret;
    if (getHeader(EH_CONTENT_ENCODING, ret)) {
        return ret;
    }

    return std::string("identity");
}



/********************************************************************
 *
 * Sets Date header
 *
 ********************************************************************/
void HttpMessage::setDate(const std::string& d)
{
    setHeader(GH_DATE, d);
}

/********************************************************************
 *
 * Returns Date header
 *
 ********************************************************************/
std::string HttpMessage::getDate() const
{
    std::string d;
    if (getHeader(GH_DATE, d))
        return d;

    return "";
}

/********************************************************************
 *
 * Returns the current GMT date and time in the Date header format
 *
 ********************************************************************/
std::string HttpMessage::getCurrentDateTime()
{
    time_t ltime;
    struct tm *gmt;

    time( &ltime );
    gmt = gmtime( &ltime );

    char wday[4];
    switch (gmt->tm_wday) {
        case 0:
            strcpy(wday, "Sun");
            break;
        case 1:
            strcpy(wday, "Mon");
            break;
        case 2:
            strcpy(wday, "Tue");
            break;
        case 3:
            strcpy(wday, "Wed");
            break;
        case 4:
            strcpy(wday, "Thu");
            break;
        case 5:
            strcpy(wday, "Fri");
            break;
        case 6:
            strcpy(wday, "Sat");
            break;

    }

    char mon[4];
    switch (gmt->tm_mon) {
        case 0:
            strcpy(mon, "Jan");
            break;
        case 1:
            strcpy(mon, "Feb");
            break;
        case 2:
            strcpy(mon, "Mar");
            break;
        case 3:
            strcpy(mon, "Apr");
            break;
        case 4:
            strcpy(mon, "May");
            break;
        case 5:
            strcpy(mon, "Jun");
            break;
        case 6:
            strcpy(mon, "Jul");
            break;
        case 7:
            strcpy(mon, "Aug");
            break;
        case 8:
            strcpy(mon, "Sep");
            break;
        case 9:
            strcpy(mon, "Oct");
            break;
        case 10:
            strcpy(mon, "Nov");
            break;
        case 11:
            strcpy(mon, "Dec");
            break;
    }

    char ret[100];
    sprintf(ret, "%s, %02d %s %d %02d:%02d:%02d GMT",
            wday, gmt->tm_mday, mon, gmt->tm_year+1900,
            gmt->tm_hour, gmt->tm_min, gmt->tm_sec);


    return std::string(ret);
}

