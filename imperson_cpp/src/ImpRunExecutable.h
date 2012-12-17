#ifndef __ImpRunExecutable_h__
#define __ImpRunExecutable_h__

/**
 * @file ImpRunExecutable.h
 * Header file for ImpRunExecutable class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"

#define MAX_ARGLIST 1024


class HttpServer;

/**
 * @class ImpRunExecutable
 * Subclass of ImpCommand for running an executable on behalf of users.
 *
 * An instance of this class is created by ImpServer if the value of the
 * request header, "impCommand", is runExecutable.
 *
 * The impersonation server can run an arbitrary executable on behalf of the user.
 * If required, the client can supply the command line arguments and environment
 * variables as request parameters. The output of the executable from stdout is
 * sent back to the client in the message body. If the executable requires data
 * from stdin, impUseFork must be set to true and the data can be placed in
 * the request body (accompanied by Content-Length or chunked Transfer-Encoding header).
 *
 * By default the server replaces its process image with the executable process image
 * through execve function.  The executable inherits stdin/stdout/stderr file descriptors
 * from the server, which means that data written to stdout and stderr will be sent to
 * the client directly.  The server sends the status line and the headers to the
 * client before calling execve so that the data written by the new process will
 * be in the message body. A few drawbacks with this methods are, firstly, the
 * new process will hang if it requires stdin; and the status code and phrase
 * will always be 200 OK (if all parameters are correct) even if execve fails.
 * However, when execve fails, the message body will contain 567 status code and
 * a status phrase that explains the cause of the failure.
 *
 * Maximum number of arguments for the executable is 1024.
 */
class ImpRunExecutable : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpRunExecutable();

    /**
     * @brief Constructor. Creates an instance of ImpRunExecutable with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpRunExecutable(HttpServer* s);

    /**
     * @brief Constructor. Creates an instance of ImpRunExecutable with a new name.
     * @param n Name of the command.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     * @todo Do we need this constructor?
     */
    ImpRunExecutable(const std::string& n, HttpServer* s);


    /**
     * @brief Destructor.
     */
    virtual ~ImpRunExecutable();


    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error running an executable.
     */
    virtual void execute() throw(XosException);


    /**
     * @brief static method for creating an instance of this class.
     * Used by ImpCommandFactory.
     * @param n Command name to register with ImpCommandFactory
     * @param s Pointer to HttpServer
     */
    static ImpCommand* createCommand(const std::string& n, HttpServer* s);

    protected:

    bool m_keepStdin;

    char* argList[MAX_ARGLIST];
    char* envList[MAX_ARGLIST];

    /**
     * Must be called by all constructors to
     * initialize member variables.
     **/
    void init();


    /**
     *
     * Change dir to the given dirPath
     * If dirPath is an empty string, chdir to
     * default dir of this user.
     *
     **/
    bool changeDirectory(const std::string& dirPath);



    /**
     * Create a unique file name
     **/
    std::string makeTmpFileName(const std::string& tmpDir);

    /**
     * Fork a new process and run the executable in the child process.
     * Wait for the child to die before returning.
     **/
    void doExec2(int argc, char* argv[], char* envList[]);
    void doExec3(int argc, char* argv[], char* envList[]);
    void doExec3(int argc, char* argv[], char* envList[],
    				const std::string& stdoutFile,
    				const std::string& stderrFile);

private:

	/**
	 */
	std::string getDefaultFileName(int pid, const std::string& suffix);


};

#endif // __ImpRunExecutable_h__
