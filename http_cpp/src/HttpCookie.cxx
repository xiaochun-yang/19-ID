#include "XosStringUtil.h"
#include "HttpCookie.h"
#include "log_quick.h"



/****************************************************
 *
 * Defaultl constructor
 *
 ****************************************************/
HttpCookie::HttpCookie()
{
    init();
}


/****************************************************
 *
 * CSonstructor
 *
 ****************************************************/
HttpCookie::HttpCookie(const std::string& name,
           const std::string& value,
           const std::string& comment,
           const std::string& domain,
           unsigned int maxAge,
           const std::string& path,
           bool secure,
           const std::string& version)
{
    this->paramName = name;
    this->paramValue = value;
    this->comment = comment;
    this->domain = domain;
    this->maxAge = maxAge;
    this->path = path;
    this->secure = secure;
}


/****************************************************
 *
 * init
 *
 * Applies these defaults for optional attributes that are missing:
 *
 * VersionDefaults to "old cookie" behavior as originally specified by
 *        Netscape.  See the HISTORICAL section.
 *
 * Domain Defaults to the request-host.  (Note that there is no dot at
 *        the beginning of request-host.)
 *
 * Max-AgeThe default behavior is to discard the cookie when the user
 *        agent exits.
 *
 * Path   Defaults to the path of the request URL that generated the
 *        Set-Cookie response, up to, but not including, the
 *        right-most /.
 *
 * Secure If absent, the user agent may send the cookie over an
 *        insecure channel.
 *
 ****************************************************/
void HttpCookie::init()
{
	semicolon = ";";
	space = " ";
	quote = "\"";
	equals = "=";

    comment = "";
    domain = "";
    maxAge = 0;
    path = "/";
    secure = false;
    version = "1";
}




/****************************************************
 *
 * Destructor
 *
 ****************************************************/
HttpCookie::~HttpCookie()
{
}


/****************************************************
 *
 * Cookie header: Parse the cookie string and save the parameters in the cookie object.
 * Returns false if fails to parse the string.
 *
 ****************************************************/
bool HttpCookie::parseCookie(HttpCookie& cookie, const std::string& str)
{
    return false;
}

/****************************************************
 *
 * Set-Cookie header: Parse the cookie string and save the parameters in the cookie object.
 * Returns false if fails to parse the string.
 *
 * The user agent keeps separate track of state information that arrives
 * via Set-Cookie response headers from each origin server (as
 * distinguished by name or IP address and port).  The user agent
 * applies these defaults for optional attributes that are missing:
 *
 * VersionDefaults to "old cookie" behavior as originally specified by
 *        Netscape.  See the HISTORICAL section.
 *
 * Domain Defaults to the request-host.  (Note that there is no dot at
 *        the beginning of request-host.)
 *
 * Max-AgeThe default behavior is to discard the cookie when the user
 *        agent exits.
 *
 * Path   Defaults to the path of the request URL that generated the
 *        Set-Cookie response, up to, but not including, the
 *        right-most /.
 *
 * Secure If absent, the user agent may send the cookie over an
 *        insecure channel.
 *
 ****************************************************/
bool HttpCookie::parseSetCookie(HttpCookie& cookie,
                        const std::string& str,
                        const std::string& host,
                        const std::string& uri)
{
    cookie.init();

    std::vector<std::string> items;

    // sotkenize the whole string with semicolon
    if (!XosStringUtil::tokenize(str, ";", items)) {
        LOG_WARNING( "parseSetCookie failed: tokenize;" );
        return false;
    }

    // For each item, split the string again with =
    std::vector<std::string>::iterator i = items.begin();
    std::string item;
    std::string str1;
    std::string str2;
    std::string equals("=");
    std::string delim("\" \n\r\t");
    for (; i != items.end(); ++i) {
        item = XosStringUtil::trim(*i);
        if (item == COOKIE_SECURE) {
            cookie.setSecure(true);
            continue;
        }
        if (!XosStringUtil::split(item, equals, str1, str2)) {
            LOG_WARNING1( "parseSetCookie failed: split %s by =", item.c_str( ) );
            return false;
        }

        str1 = XosStringUtil::trim(str1, delim);
        str2 = XosStringUtil::trim(str2, delim);
        if (str1 == COOKIE_COMMENT)
            cookie.setComment(str2);
        else if (str1 == COOKIE_DOMAIN)
            cookie.setDomain(str2);
        else if (str1 == COOKIE_MAXAGE)
            cookie.setMaxAge(XosStringUtil::toInt(str2, 0));
        else if (str1 == COOKIE_PATH)
            cookie.setPath(str2);
        else if (str1 == COOKIE_VERSION)
            cookie.setVersion(str2);
        else {
            if (!cookie.getName().empty()) {
                LOG_WARNING1( "parseSetCookie failed: name not empty %s", cookie.getName( ).c_str( ) );
                return false;
            }
            cookie.setName(str1);
            cookie.setValue(str2);
        }
    }

    // Set default domain
    if (cookie.domain.empty())
        cookie.domain = host;


    return validateSetCookie(cookie, host, uri);


}

/****************************************************
 *
 * To prevent possible security or privacy violations, a user agent
 * rejects a cookie (shall not store its information) if any of the
 * following is true:
 *
 * * The value for the Path attribute is not a prefix of the request-
 *   URI.
 *
 * * The value for the Domain attribute contains no embedded dots or
 *   does not start with a dot.
 *
 * * The value for the request-host does not domain-match the Domain
 *   attribute.
 *
 * * The request-host is a FQDN (not IP address) and has the form HD,
 *   where D is the value of the Domain attribute, and H is a string
 *   that contains one or more dots.
 *
 * Examples:
 *
 * * A Set-Cookie from request-host y.x.foo.com for Domain=.foo.com
 *   would be rejected, because H is y.x and contains a dot.
 *
 * * A Set-Cookie from request-host x.foo.com for Domain=.foo.com would
 *   be accepted.
 *
 * * A Set-Cookie with Domain=.com or Domain=.com., will always be
 *   rejected, because there is no embedded dot.
 *
 * * A Set-Cookie with Domain=ajax.com will be rejected because the
 *   value for Domain does not begin with a dot.
 *
 ****************************************************/
bool HttpCookie::validateSetCookie(const HttpCookie& cookie,
                                const std::string& host,
                                const std::string& uri)
{
    // The value for the Path attribute is not a prefix of the request-URI.
    if (uri.find(cookie.path) == std::string::npos) {
        LOG_WARNING2( "validateSetCookie failed: not found path (%s) in uri: %s", cookie.path.c_str(), uri.c_str( ) );
        return false;
    }

    if (cookie.domain.size() < 1) {
        LOG_WARNING( "validateSetCookie no domain" );
        return false;
    }


    if (cookie.domain.size() > host.size()) {
        LOG_WARNING2( "domain {%s} size not match host {%s} size",
        cookie.domain.c_str( ), host.c_str( ) );
        return false;
    }

    // The value for the Domain attribute does not start with a dot.
    // The only time the domain does not have start with a dot is
    // when it is the same as the host.
    if (XosStringUtil::equalsNoCase(cookie.domain, host))
        return true;


    if (cookie.domain[0] != '.') {
        LOG_WARNING( "validateSetCookie domain not start with ." );
        return false;
    }


    // The value for the Domain attribute contains no embedded dots
    std::string tmp = XosStringUtil::trim(cookie.domain, ".");
    if (tmp.find('.') == std::string::npos) {
        LOG_WARNING( "validateSetCookie domain no middle ." );
        return false;
    }

    // The value for the request-host does not domain-match the Domain attribute.
    size_t pos = host.find(cookie.domain);
    if (pos == std::string::npos) {
        LOG_WARNING1( "validateSetCookie host {%s} not contains domain", host.c_str( ) );
        return false;
    }

    if (pos + cookie.domain.size() != host.size()) {
        LOG_WARNING( "validateSetCookie pos +size not match" );
        return false;
    }

    // The request-host is a FQDN (not IP address) and has the form HD,
    // where D is the value of the Domain attribute, and H is a string
    // that contains one or more dots.
    std::string front = cookie.domain.substr(0, pos);
    if (front.find('.')) {
        LOG_WARNING1( "validateSetCookie front {%s} not contains .", front.c_str( ) );
        return false;
    }


    return true;
}

void HttpCookie::setName(const std::string& name)
{
    paramName = name;
}


std::string HttpCookie::getName() const
{
    return paramName;
}

void HttpCookie::setValue(const std::string& value)
{
    paramValue = value;
}


std::string HttpCookie::getValue() const
{
    return paramValue;
}


/**
 * Returns the comment
 **/
std::string HttpCookie::getComment() const
{
    return comment;
}

void HttpCookie::setComment(const std::string& comment)
{
    this->comment = comment;
}

std::string HttpCookie::getDomain() const
{
    return domain;
}

void HttpCookie::setDomain(const std::string& domain)
{
    this->domain = domain;
}

unsigned int HttpCookie::getMaxAge() const
{
    return maxAge;
}

void HttpCookie::setMaxAge(unsigned int maxAge)
{
    this->maxAge = maxAge;
}

std::string HttpCookie::getPath() const
{
    return path;
}

void HttpCookie::setPath(const std::string& path)
{
    this->path = path;
}

bool HttpCookie::getSecure() const
{
    return secure;
}

void HttpCookie::setSecure(bool secure)
{
    this->secure = secure;
}

std::string HttpCookie::getVersion() const
{
    return version;
}

void HttpCookie::setVersion(const std::string& version)
{
    this->version = version;
}


/****************************************************
 *
 *
 *
 ****************************************************/
void HttpCookie::dump() const
{
    dump(stdout);
}

/****************************************************
 *
 *
 *
 ****************************************************/
void HttpCookie::dump(FILE* fd) const
{
    printf("%s=%s", paramName.c_str(), paramValue.c_str());

    if (!comment.empty()) {
        printf("; %s=%s", COOKIE_COMMENT, comment.c_str());
    }

    if (!domain.empty()) {
        printf("; %s=%s", COOKIE_DOMAIN, domain.c_str());
    }

    if (maxAge != 0) {
        printf("; %s=%u", COOKIE_MAXAGE, maxAge);
    }

    if (!path.empty()) {
        printf("; %s=%s", COOKIE_PATH, path.c_str());
    }

    if (!version.empty()) {
        printf("; %s=%s", COOKIE_VERSION, version.c_str());
    }
    if (secure) {
        printf("; secure");
    }

    printf("\n");

}






