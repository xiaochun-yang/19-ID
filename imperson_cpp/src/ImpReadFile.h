#ifndef __ImpReadFile_h__
#define __ImpReadFile_h__

/**
 * @file ImpReadFile.h
 * Header file for ImpReadFile class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"


class HttpServer;

/**
 * @class ImpReadFile
 * Subclass of ImpCommand for retrieving a remote file or check if the file is readable.
 *
 * ImpServer creates an instance of this class if the value of the
 * request header, "impCommand", is readFile or isFileReadable.
 *
 * readFile allows the client to read a file readable by the user.
 * The contents of the file are returned in the body of the http response.
 * Starting and ending positions within the file may be specified in the request.
 * If the command is constructed in the request URI, The requested file can be
 * specified in the impFilePath parameter or the resource of the URI (in
 * which case, impCommand parameter must be included).
 *
 * isFileReadable command is used to test if the file can be read by the user,
 * without actually reading the file.
 *
 * For example,
 * @code

   http://smblx7:61000/home/penjitk/test.txt?impCommand=readFile&impUser=penjitk&impSessionID=IUREIOUROU

   and

   http://smblx7:61000/readFile?impFilePath=/home/penjitk/test.txt&impUser=penjitk&impSessionID=IUREIOUROU

 * @endcode
 *
 * will give the same result. However, the browser will be able to figure out how to display
 * the file properly if the file path is specified as URI resource.
 */

class ImpReadFile : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpReadFile();

    /**
     * @brief Constructor. Creates an instance of ImpReadFile with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpReadFile(HttpServer* s);

    /**
     * @brief Constructor. Creates an instance of ImpReadFile with defautlt name.
     * @param n Command name which is either readFile or isFileReadable.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpReadFile(const std::string& n, HttpServer* s);

    /**
     * @brief Destructor.
     */
    virtual ~ImpReadFile();

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

#endif // __ImpReadFile_h__
