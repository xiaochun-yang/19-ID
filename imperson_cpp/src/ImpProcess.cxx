#include "xos.h"
#include "log_quick.h"
#include <dirent.h>
#include <sys/stat.h>
#include <grp.h>
#include <pwd.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <signal.h>

#include "ImpListDirectory.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "XosFileUtil.h"
#include "XosStringUtil.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpProcess.h"
#include "ImpCommandFactory.h"

#define MAXLINE 500

static ImpRegister* dummy1 = new ImpRegister(IMP_GETPROCESSSTATUS, &ImpProcess::createCommand, true);
static ImpRegister* dummy2 = new ImpRegister(IMP_KILLPROCESS, &ImpProcess::createCommand, false);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpProcess::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpProcess(n, s);
}


/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpProcess::ImpProcess()
    : ImpCommand()
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpProcess::ImpProcess(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
}


/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpProcess::~ImpProcess()
{
}


/*************************************************
 *
 * run
 *
 *************************************************/
void ImpProcess::execute()
    throw(XosException)
{
    if (name == IMP_GETPROCESSSTATUS) {
        doGetProcessStatus();
    } else if (name == IMP_KILLPROCESS) {
        doKillProcess();
    } else {
        throw XosException(554, SC_554);
    }
}

/*************************************************
 *
 * doGetProcessStatus
 *
 *************************************************/
void ImpProcess::doGetProcessStatus()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

	std::string impUser;
	if (!request->getParamOrHeader(IMP_USER, impUser))
		throw XosException(432, SC_432);
		
	std::string impProcessId;
	request->getParamOrHeader(IMP_PROCESSID, impProcessId);

	std::string impShowUserProcessOnly;
	bool showUserProcessOnly = false;
    if (request->getParamOrHeader(IMP_SHOWUSERPROCESSONLY, impShowUserProcessOnly)) {
        if (XosStringUtil::toLower(impShowUserProcessOnly) == IMP_TRUE) {
            showUserProcessOnly = true;
		}
	}
	
    std::string endofline("\r\n");
    std::string body("");
   
    std::string command = "ps";
    
    if (showUserProcessOnly) {
    	command += " -u " + impUser; // display user's processes
    } else if (!impProcessId.empty()) {
    	command += " -p " + impProcessId;
    } else {
    	command += " -e"; // display all processes
    }
    
    command += " -o \"pid,ppid,pgid,ruser,user,rgroup,group,sz,rss,vsz,time,etime,stime,state,uid,args\"";
    command += " 2>&1";
    

    // Run ps -ef command and get its output
    // through read-only file stream.
    FILE* in = popen(command.c_str(), "r");
    
    if (in == NULL)
    	throw XosException(584, XosFileUtil::getErrorString(errno, SC_584));
    	
    	
    // Read output from "ps -ef" command
    char line[MAXLINE];
    while (fgets(line, MAXLINE, in) != NULL) {
    	body += line + endofline;
    }

    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    stream->finishWriteResponse();
}

/*************************************************
 *
 * doKillProcess
 *
 *************************************************/
void ImpProcess::doKillProcess()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

	std::string impUser;
	if (!request->getParamOrHeader(IMP_USER, impUser))
		throw XosException(432, SC_432);
		
	std::string impProcessId;
	if (!request->getParamOrHeader(IMP_PROCESSID, impProcessId))
		throw XosException(455, SC_455);
		
	int pid = XosStringUtil::toInt(impProcessId, 0);
	
	if (pid < 1)
		throw XosException(456, SC_456);

    std::string endofline("\r\n");
    std::string body("");
    
    // Kill the process
    if (kill(pid, SIGKILL) < 0) {
    	// Failed to kill the process
    	throw XosException(585, XosFileUtil::getErrorString(errno, SC_585));
    }
    
    body = std::string("Process ID ") + impProcessId + " killed successfully";
    
    response->setContentLength(body.size());
    response->setContentType(WWW_PLAINTEXT);
    stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    stream->finishWriteResponse();
    
}

