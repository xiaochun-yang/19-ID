#ifndef __ImpVersion_h__
#define __ImpVersion_h__

/**
 * @file ImpVersion.h
 * Header file for ImpVersion class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"

#define IMPERSON_VERSION "4.5"


class HttpServer;

/**
 * @class ImpVersion
 * Subclass of ImpCommand for returning version number of the impersionation server.
 */

class ImpVersion : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpVersion();

    ImpVersion(const std::string& n, HttpServer* s);

        /**
     * @brief Constructor. Creates an instance of ImpVersion with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpVersion(HttpServer* s);

    /**
     * @brief Destructor.
     */
    virtual ~ImpVersion();

    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error reading file.
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

#endif // __ImpVersion_h__
