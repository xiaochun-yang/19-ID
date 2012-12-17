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

#include "ImpListDirectory.h"
#include "ImpStatusCodes.h"
#include "XosException.h"
#include "XosFileUtil.h"
#include "XosStringUtil.h"
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpRunScript.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy = new ImpRegister(IMP_RUNSCRIPT, &ImpRunScript::createCommand, true);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpRunScript::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpRunScript(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunScript::ImpRunScript()
    : ImpRunExecutable(IMP_RUNSCRIPT, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunScript::ImpRunScript(HttpServer* s)
    : ImpRunExecutable(IMP_RUNSCRIPT, s)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunScript::ImpRunScript(const std::string& n, HttpServer* s)
    : ImpRunExecutable(n, s)
{
}


/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpRunScript::~ImpRunScript()
{
}


/*************************************************
 *
 * run
 *
 *************************************************/
void ImpRunScript::execute()
    throw(XosException)
{
    HttpRequest* request = stream->getRequest();

    std::string dirPath;
    if (!request->getParamOrHeader(IMP_DIRECTORY, dirPath)) {
        request->getParamOrHeader(IMP_HOMEDIR, dirPath);
    }

	std::string impUser;
	if (!request->getParamOrHeader(IMP_USER, impUser))
		throw XosException(432, SC_432);
		
    dirPath = ImpListDirectory::resolveDir(dirPath, impUser);


    // chdir
    if (!changeDirectory(dirPath))
        throw XosException(564, SC_564);

    // Executable
    int argIndex = 0;
    std::string impShell = "";

    if (!request->getParamOrHeader(IMP_SHELL, impShell)) {
        // otherwise get default directory from passwd structure if not
        request->getParamOrHeader(IMP_DEFSHELL, impShell);

        // force shell to tcsh if interactive login to machine not allowed
//        if (impShell.empty() || (strncmp( impShell.c_str(), "/bin/false", 10) == 0)) {
//            impShell = "/bin/tcsh";
//        }
    }

    if (impShell.size() < 2)
        throw XosException(452, SC_452);


    impShell = ImpListDirectory::resolveDir(impShell, impUser);


    std::string impCommandLine;
    if (!request->getParamOrHeader(IMP_COMMANDLINE, impCommandLine)) {
        throw XosException(451, SC_451);
    }

    std::string tmp;
    bool norc = true;
    if (request->getParamOrHeader(IMP_NORC, tmp)) {
        if (tmp == IMP_FALSE)
		norc = false;
    }

    // Construct argv
    argList[argIndex] = new char[impShell.size()+1];
    strncpy(argList[argIndex], impShell.c_str(), impShell.size()+1);
    ++argIndex;

    // -f or --norc means do not source cshrc file
    if (norc) {
	if ((impShell.find("/csh") != std::string::npos) || (impShell.find("/tcsh") != std::string::npos)) {
        	argList[argIndex] = new char[3];
        	strncpy(argList[argIndex], "-f", 3);
        	++argIndex;
	} else if ((impShell.find("/bash") != std::string::npos) || (impShell.find("/sh") != std::string::npos)) {
        	argList[argIndex] = new char[7];
        	strncpy(argList[argIndex], "--norc", 7);
        	++argIndex;
	}
    }

    // -c means execute commandline that follows it.
    argList[argIndex] = new char[3];
    strncpy(argList[argIndex], "-c", 3);
    ++argIndex;

    argList[argIndex] = new char[impCommandLine.size() + 1];
    strncpy(argList[argIndex], impCommandLine.c_str(), impCommandLine.size() + 1);
    ++argIndex;

    argList[argIndex] = 0;


    // Construct env
    int envIndex = 0;
    envList[envIndex] = new char[impShell.size()+1];
    strncpy(envList[envIndex], impShell.c_str(), impShell.size()+1);
    ++envIndex;

    std::string paramName;
    std::string paramValue;
    bool hasUser = false;
    bool hasHome = false;
    bool hasPath = false;
    for (; envIndex < 1024; ++envIndex) {
        paramName = std::string("impEnv") + XosStringUtil::fromInt(envIndex);
        if (!request->getParamOrHeader(paramName, paramValue)) {
            break;
        }
	if (paramValue.find("USER=") == 0)
		hasUser = true;
	if (paramValue.find("HOME=") == 0)
		hasHome = true;
	if (paramValue.find("PATH=") == 0)
		hasPath = true;
        envList[envIndex] = new char[paramValue.size()+1];
        strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);

    }
    
    // Set default USER env
    if (!hasUser) {
	paramValue = std::string("USER=") + impUser;
        envList[envIndex] = new char[paramValue.size()+1];
        strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);
	++envIndex;
    }
    
    // set default HOME env
    if (!hasHome) {
	paramValue = std::string("HOME=/home/") + impUser;
        envList[envIndex] = new char[paramValue.size()+1];
        strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);
	++envIndex;
    }

    // set default PATH env
    if (!hasPath) {
	paramValue = std::string("PATH=/usr/local/bin:/bin:/usr/bin");
        envList[envIndex] = new char[paramValue.size()+1];
        strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);
 	++envIndex;
   }

    // set default SHELL env
    paramValue = std::string("SHELL=") + impShell;
    envList[envIndex] = new char[paramValue.size()+1];
    strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);
    ++envIndex;

    envList[envIndex] = NULL;


    // use fork() or not
    std::string impUseFork;
	std::string impStdoutFile;
	std::string impStderrFile;
    bool isUseFork = false;
    if (request->getParamOrHeader(IMP_USEFORK, impUseFork)) {
        if (XosStringUtil::toLower(impUseFork) == IMP_TRUE) {
            isUseFork = true;
			if (!request->getParamOrHeader(IMP_STDOUTFILE, impStdoutFile)) {
				impStdoutFile = "";
			}
			if (!request->getParamOrHeader(IMP_STDERRFILE, impStderrFile)) {
				impStderrFile = "";
			}
        }
    }

    std::string impKeepStdin;
    m_keepStdin = false;
    if (request->getParamOrHeader(IMP_KEEP_STDIN, impKeepStdin) &&
    XosStringUtil::toLower(impKeepStdin) == IMP_TRUE) {
        m_keepStdin = true;
    }

    if (isUseFork) {
        // Run the exectuable in a separate process
        // save the stdout/stderr of the child proc in
        // a tmp file. when the child proc exits,
        // this proc will send out the content of
        // the file to the client.
        doExec3(argIndex, argList, envList, impStdoutFile, impStderrFile);
    } else {
        // Never returns, if execvp call is successful
        // stdout/stderr of the child is streamed out directly
        // to the client.
        doExec2(argIndex, argList, envList);
    }


    // delete the argList
    for (int i = 0; i < argIndex; ++i) {
        if (argList[i])
            delete argList[i];
        argList[i] = NULL;
    }

    // delete the argList
    for (int i = 0; i < envIndex; ++i) {
        if (envList[i])
            delete envList[i];
        envList[i] = NULL;
    }

}


