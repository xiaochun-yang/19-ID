#ifndef __ImpProcess_h__
#define __ImpProcess_h__

/**
 * @file ImpRunScript.h
 * Header file for ImpProcess class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"

class HttpServer;

/**
 * @class ImpProcess
 * Subclass of ImpCommand for getting process status and killing a process.
 *
 */
class ImpProcess : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpProcess();

    /**
     * @brief Constructor. Creates an instance of ImpProcess with a new name.
     * @param n Name of the command.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     * @todo Do we need this constructor?
     */
    ImpProcess(const std::string& n, HttpServer* s);


    /**
     * @brief Destructor.
     */
    virtual ~ImpProcess();


    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error.
     */
    virtual void execute() throw (XosException);


    /**
     * @brief static method for creating an instance of this class.
     * Used by ImpCommandFactory.
     * @param n Command name to register with ImpCommandFactory
     * @param s Pointer to HttpServer
     */
    static ImpCommand* createCommand(const std::string& n, HttpServer* s);

private:

	/**
	 * Handle getProcessInfo command.
	 */
	void doGetProcessStatus() throw (XosException);
	
	/**
	 * Handle killprocess command
	 */
	void doKillProcess() throw (XosException);

};

#endif // __ImpProcess_h__
