#include "XosStringUtil.h"
#include "HttpUtil.h"
#include "HttpResponse.h"

/****************************************************
 *
 * Defaultl constructor
 *
 ****************************************************/
HttpResponse::HttpResponse()
    : statusCode(200), statusPhrase("OK"), version(HTTP_VERSION)
{
}

/****************************************************
 *
 * Constructor
 *
 ****************************************************/
HttpResponse::HttpResponse(int code, const std::string& phrase)
    : statusCode(code), statusPhrase(phrase), version(HTTP_VERSION)
{
}

/****************************************************
 *
 * Destructor
 *
 ****************************************************/
HttpResponse::~HttpResponse()
{
}



/****************************************************
 *
 * Extract http version, status code, status phrase
 * from the first line.
 *
 ****************************************************/
void HttpResponse::parseResponseLine(const std::string& str)
    throw (XosException)
{  
    std::string reason;
    if (!HttpUtil::parseResponseLine(str, version, statusCode, statusPhrase, reason))
    	throw XosException(reason);


}



