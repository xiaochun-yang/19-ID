#ifndef __ImpWriteFile_h__
#define __ImpWriteFile_h__

/**
 * @file ImpWriteFile.h
 * Header file for ImpWriteFile class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"


class HttpServer;

/**
 * @class ImpWriteFile
 * Subclass of ImpCommand for writing remote files to local disk.
 *
 * ImpServer creates an instance of this class if the value of the
 * request header, "impCommand", is writeFile.
 *
 * writeFile allows the user to upload a file onto the server.
 * The message body of the request contains the file content.
 * The file name and file permissions are specified by impFilePath
 * and impFileMode. The request header must include either
 * "Transfer-Encoding: chunked" or Content-Length, which is set the
 * length of the message body (in bytes). Note that only POST method
 * with the parameters in the request-URI or headers can be used with
 * the writeFile command. HTML-FORM with POST method is not applicable
 * since the message body already contains the parameters in the
 * application/x-www-form-urlencoded format.
 */

/*
 * if impBackupExist set to true, the existing file will be moved to
 * OVERWRITTEN_FILES sub-directory.  If cannot move, the program will
 * try to remove it.
 * This way, the command will success if the file is writable or the
 * directory is writable.
 */


class ImpWriteFile : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set properly with this constructor.
     */
    ImpWriteFile();

    /**
     * @brief Constructor.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpWriteFile(HttpServer* s);

    ImpWriteFile(const std::string& n, HttpServer* s);

    /**
     * @brief Destructor.
     */
    virtual ~ImpWriteFile();

    /**
     * @brief Entry point for the command execution.
     * @exception XosException Thrown if there is an error in writing file.
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

#endif // __ImpWriteFile_h__
