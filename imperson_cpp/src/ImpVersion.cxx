#include "xos.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "ImpVersion.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy = new ImpRegister(IMP_GETVERSION, &ImpVersion::createCommand, true);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpVersion::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpVersion(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpVersion::ImpVersion()
    : ImpCommand(IMP_GETVERSION, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpVersion::ImpVersion(HttpServer* s)
    : ImpCommand(IMP_GETVERSION, s)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpVersion::ImpVersion(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpVersion::~ImpVersion()
{
}

/*************************************************
 *
 * run
 *
 *************************************************/
void ImpVersion::execute()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

	int len = strlen(IMPERSON_VERSION);
    response->setContentLength(len);
 	response->setContentType("text/plain; charset=ISO-8859-1");
 	stream->writeResponseBody(IMPERSON_VERSION, len);
    stream->finishWriteResponse();
    
}

