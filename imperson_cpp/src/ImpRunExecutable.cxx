#include "xos.h"
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
#include "ImpRunExecutable.h"
#include "ImpCommandFactory.h"

static ImpRegister* dummy = new ImpRegister(IMP_RUNEXECUTABLE, &ImpRunExecutable::createCommand, false);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpRunExecutable::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpRunExecutable(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunExecutable::ImpRunExecutable()
    : ImpCommand(IMP_RUNEXECUTABLE, NULL)
{
    init();
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunExecutable::ImpRunExecutable(HttpServer* s)
    : ImpCommand(IMP_RUNEXECUTABLE, s)
{
    init();
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpRunExecutable::ImpRunExecutable(const std::string& n, HttpServer* s)
    : ImpCommand(n, s)
{
    init();
}

/*************************************************
 *
 * init: called by all constructor
 *
 *************************************************/
void ImpRunExecutable::init()
{
    // init the argList
    for (int i = 0; i < MAX_ARGLIST; ++i) {
        argList[i] = NULL;
    }

    // init envList
    for (int i = 0; i < MAX_ARGLIST; ++i) {
        envList[i] = NULL;
    }
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpRunExecutable::~ImpRunExecutable()
{
    // delete the argList
    for (int i = 0; i < MAX_ARGLIST; ++i) {
        if (!argList[i])
            break;
        delete argList[i];
        argList[i] = NULL;
    }

    // delete the envList
    for (int i = 0; i < MAX_ARGLIST; ++i) {
        if (!envList[i])
            break;
        delete envList[i];
        envList[i] = NULL;
    }
}


/*************************************************
 *
 * run
 *
 *************************************************/
void ImpRunExecutable::execute()
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
    std::string impExecutable;

    if (!request->getParamOrHeader(IMP_EXECUTABLE, impExecutable)) {
        impExecutable = request->getResource();
    }

    if (impExecutable.size() < 2)
        throw XosException(441, SC_441);

    impExecutable = ImpListDirectory::resolveDir(impExecutable, impUser);

    // Construct argv
    argList[argIndex] = new char[impExecutable.size()+1];
    strncpy(argList[argIndex], impExecutable.c_str(), impExecutable.size()+1);
    ++argIndex;

    char paramName[1024];
    for (; argIndex < 1024; ++argIndex) {
        std::string paramValue;
        sprintf(paramName, "impArg%d", argIndex);
        if (!request->getParamOrHeader(paramName, paramValue)) {
            break;
        }
        argList[argIndex] = new char[paramValue.size()+1];
        strncpy(argList[argIndex], paramValue.c_str(), paramValue.size()+1);
    }

    argList[argIndex] = NULL;

    // Construct env
    int envIndex = 0;
    envList[envIndex] = new char[impExecutable.size()+1];
    strncpy(envList[envIndex], impExecutable.c_str(), impExecutable.size()+1);
    ++envIndex;

    for (; envIndex < 1024; ++envIndex) {
        std::string paramValue;
        sprintf(paramName, "impEnv%d", envIndex);
        if (!request->getParamOrHeader(paramName, paramValue)) {
            break;
        }
        envList[envIndex] = new char[paramValue.size()+1];
        strncpy(envList[envIndex], paramValue.c_str(), paramValue.size()+1);

    }

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


/*************************************************
 *
 * Run an executable in this process.
 *
 *************************************************/
void ImpRunExecutable::doExec2(int argc, char* argv[], char* envList[])
{


/*    for (int i = 0; i < MAX_ARGLIST; ++i) {
       if (envList[i] == NULL)
            break;

       LOG_FINE2("env[%d] = %s\n", i, envList[i]);
    }*/

    // Force the header to be written
    HttpResponse* response = stream->getResponse();
    response->setHeader(EH_CONTENT_TYPE, "text/plain");
    stream->finishWriteResponseHeader();

    // close stdin
    if (!m_keepStdin) {
        fclose(stdin);
    }


    // The image of this process will be replaced by
    // the new executable i execvp succeeds. Otherwise,
    // send out an error to the client.

    if (envList != NULL)
        execve(argv[0], argv, envList);
    else
        execvp(argv[0], argv);

    // If we are still here, it means that exec* fails.
    std::string tmp = std::string("567: ")
                        + XosFileUtil::getErrorString(567,
                        SC_567 + std::string(" ") + argv[0]);
    stream->writeResponseBody(tmp.c_str(), tmp.size());
    stream->finishWriteResponse();


}


/*************************************************
 *
 * Fork a new process and run the executable
 * in the child process.
 *
 *************************************************/
void ImpRunExecutable::doExec3(int argc, 
							char* argv[], 
							char* envList[])
{
	doExec3(argc, argv, envList, "", "");
}

/*************************************************
 *
 * Fork a new process and run the executable
 * in the child process.
 *
 *************************************************/
void ImpRunExecutable::doExec3(int /*argc*/, 
							char* argv[], 
							char* envList[],
							const std::string& out,
							const std::string& err)
{

    HttpRequest* request = stream->getRequest();
    HttpResponse* response = stream->getResponse();

    pid_t childProcessID;
    std::string stdoutFile = out;
    std::string stderrFile = err;


    // flush the standard output stream
    fflush( stdout );

    std::string tmpDir;
    if (!request->getParamOrHeader(IMP_TMPDIR, tmpDir)) {
        tmpDir = "/tmp";
    }


    std::string stdoutTmpFile = makeTmpFileName(tmpDir);
    std::string stdinTmpFile = makeTmpFileName(tmpDir);
    
    // Do not let the child process inherite the 
    // stdin, stdout and stderr.
    if (!m_keepStdin) {
        fcntl(fileno(stdin), F_SETFD, FD_CLOEXEC);
    }
    fcntl(fileno(stdout), F_SETFD, FD_CLOEXEC);
    fcntl(fileno(stderr), F_SETFD, FD_CLOEXEC);


    // fork the process
    if ( (childProcessID = fork()) == -1 ) {
        response->setStatus(565, SC_565);
        stream->finishWriteResponse();
        return;
    }

    // the parent process executes this code
    if (childProcessID != 0 ) {
    
    	// Wait on the child process without blocking
    	// (func returns immediately). 
    	// Needs to be called in order for the child 
    	// not to become a zombie if it dies before
    	// the parent.
    	waitpid(childProcessID, NULL, WNOHANG);
    
		if (stdoutFile.empty())
			stdoutFile = getDefaultFileName(childProcessID, "_stdout.txt");

		if (stderrFile.empty())
			stderrFile = getDefaultFileName(childProcessID, "_stderr.txt");

		std::string childProcessIDStr = XosStringUtil::fromInt(childProcessID);

        // We are parent
        // Return child process id in header and body
        // And return immediately
        response->setHeader(IMP_PROCESSID, childProcessIDStr.c_str());
        response->setHeader(IMP_STDOUTFILE, stdoutFile);
        response->setHeader(IMP_STDERRFILE, stderrFile);
        response->setHeader(EH_CONTENT_TYPE, "text/plain");
        
        // Repeat the info in the body
		std::string endofline("\r\n");
		std::string equals("=");
		std::string body(IMP_PROCESSID);
		body += equals + childProcessIDStr + endofline;
		body += IMP_STDOUTFILE + equals + stdoutFile + endofline;
		body += IMP_STDERRFILE + equals + stderrFile + endofline;
		stream->writeResponseBody(body.c_str(), body.size());
		
		stream->finishWriteResponse();
	
        return;

    } else {
        
		if (stdoutFile.empty())
			stdoutFile = getDefaultFileName(getpid(), "_stdout.txt");

		if (stderrFile.empty())
			stderrFile = getDefaultFileName(getpid(), "_stderr.txt");

        FILE* stdoutFd = fopen(stdoutFile.c_str(), "w+");
        FILE* stderrFd = fopen(stderrFile.c_str(), "w+");

        if (stdoutFd == NULL) {
            exit(errno);
        }
        if (stderrFd == NULL) {
            exit(errno);
        }
        
        // Redirect stdout and stderr of child to the opened files       
        dup2(fileno(stdoutFd), fileno(stdout));
        dup2(fileno(stderrFd), fileno(stderr));


        if (envList != NULL)
            execve(argv[0], argv, envList);
        else
            execvp(argv[0], argv);

		// if we are still here then execve or execvp must have failed.
        fclose(stdoutFd);
        fclose(stderrFd);

        exit(0);
    }


}

/*************************************************
 *
 * Change dir to the given dirPath
 * If dirPath is an empty string, chdir to
 * default dir of this user.
 *
 *************************************************/
std::string ImpRunExecutable::getDefaultFileName(
							int pid,
							const std::string& suffix)
{		
    return "/tmp/" + XosStringUtil::fromInt(pid) + suffix;
}

/*************************************************
 *
 * Change dir to the given dirPath
 * If dirPath is an empty string, chdir to
 * default dir of this user.
 *
 *************************************************/
bool ImpRunExecutable::changeDirectory(const std::string& dirPath)
{

    // change to the imp directory
    return ( chdir(dirPath.c_str()) == 0 );
}

/*************************************************
 *
 * Creates a unique file name. Prefix name created
 * by tempnam with  pid and timestamp to really
 * reduce a chance of it being duplicated.
 * TODO: move it to XosFileUtil
 *
 *************************************************/
std::string ImpRunExecutable::makeTmpFileName(const std::string& tmpDir)
{

    char* tmp = tempnam(tmpDir.c_str(), "imp_");

    // Create a unique file name

    return tmp;
}

