#ifndef __ImpRunScript_h__
#define __ImpRunScript_h__

/**
 * @file ImpRunScript.h
 * Header file for ImpRunScript class.
 */

#include "ImpRunExecutable.h"
#include "ImpRegister.h"


class HttpServer;

/**
 * @class ImpRunScript
 * Subclass of ImpCommand for running a shell script on behalf of users.
 *
 * ImpServer creates an instance of this class if the value of the request header,
 * "impCommand" is runScript.
 *
 * This command allows clients to run any shell (default is default
 * shell of the user) and pass one command line for the shell to execute.
 * Output is returned in the body of the http response.
 *
 */
class ImpRunScript : public ImpRunExecutable
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpRunScript();

    /**
     * @brief Constructor. Creates an instance of ImpRunScript with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpRunScript(HttpServer* s);

    /**
     * @brief Constructor. Creates an instance of ImpRunScript with a new name.
     * @param n Name of the command.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     * @todo Do we need this constructor?
     */
    ImpRunScript(const std::string& n, HttpServer* s);


    /**
     * @brief Destructor.
     */
    virtual ~ImpRunScript();


    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error running a script.
     */
    virtual void execute() throw (XosException);


    /**
     * @brief static method for creating an instance of this class.
     * Used by ImpCommandFactory.
     * @param n Command name to register with ImpCommandFactory
     * @param s Pointer to HttpServer
     */
    static ImpCommand* createCommand(const std::string& n, HttpServer* s);

};

#endif // __ImpRunScript_h__
