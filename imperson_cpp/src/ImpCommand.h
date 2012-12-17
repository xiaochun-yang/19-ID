#ifndef __ImpCommand_h__
#define __ImpCommand_h__

/**
 * @file ImpCommand.h
 * Header file for ImpCommand class.
 */

#include <string>
#include "XosException.h"

class HttpServer;

/**
 * @class ImpCommand
 * Base class for all impersonation commands. Used by ImpServer to
 * execute a command on behalf of a client. A client connects to the
 * ImpServer via an HTTP connection. The request message contains
 * a command name and the necessary parameters for the command.
 * ImpServer creates an instance of an appropriate ImpCommand class
 * and calls the execute() method to execute the command.
 * @see ImpServer
 */


class ImpCommand
{
public:

    /**
     * @brief Destructor
     **/
    virtual ~ImpCommand() {}

    /**
     * @brief Returns name of this command.
     * @return Name of this command.
     **/
    std::string getName() const
    {
        return name;
    }

    /**
     * @brief Entry point for the command execution.
     * Called by ImpServer after it has received an HTTP request
     * that wishes to execute this command.
     * To be implemented by subclass.
     * @exception XosException Thrown if there is an error.
     *                         The framework will catch the exception
     *                         and deal with it appropriately.
     **/
    virtual void execute() throw (XosException) = 0;


protected:

    /**
     * @brief Constructor. Hide it so that only subclass can call this
     * constructor
     **/
    ImpCommand()
        : name(""), stream(NULL)
    {
    }


    /**
     * @brief Constructor. Creates an ImpCommand with the given name and an HttpServer.
     * Hide it so that only subclass can call this constructor.
     * @param n Name of this command.
     * @param s An HttpServer, which provide access to HttpRequest and HttpResponse
     *                         and the input/output streams.
     **/
    ImpCommand(const std::string& n, HttpServer* s)
        : name(n), stream(s)
    {
    }

    /**
     * @brief Name of this command.
     **/
    std::string name;

    /**
     * @brief The HTTP server associated with this command.
     **/
    HttpServer* stream;

};

#endif // __ImpCommand_h__
