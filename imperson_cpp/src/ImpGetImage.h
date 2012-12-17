#ifndef __ImpGetImage_h__
#define __ImpGetImage_h__

/**
 * @file ImpGetImage.h
 * Header file for ImpGetImage class.
 */

#include "ImpCommand.h"
#include "ImpRegister.h"
#include "libimage.h"

class HttpServer;

/**
 * @class ImpGetImage
 * Subclass of ImpCommand for retrieving a remote file or check if the file is readable.
 *
 * ImpServer creates an instance of this class if the value of the
 * request header, "impCommand", is readFile or isFileReadable.
 *
 * getImage allows the client to load a diffraction image as jpeg. The image
 * must be readable by the user.
 * Raw diffraction image (and header) is loaded from file and converted into jpeg
 * before it is sent in the response.
 *
 * getImageHeader loads only the image header.
 *
 * For example,
 * @code

   http://smblx7:61000/getImage?impFilePath=/home/penjitk/test.img&impUser=penjitk&impSessionID=IUREIOUROU
   http://smblx7:61000/getImageHeader?impFilePath=/home/penjitk/test.img&impUser=penjitk&impSessionID=IUREIOUROU

 *
 */

class ImpGetImage : public ImpCommand
{
public:

    /**
     * @brief Constructor
     * @todo Should be removed since HttpServer will not be set
     * properly with this constructor.
     */
    ImpGetImage();

    /**
     * @brief Constructor. Creates an instance of ImpGetImage with defautlt name.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpGetImage(HttpServer* s);

    /**
     * @brief Constructor. Creates an instance of ImpGetImage with defautlt name.
     * @param n Command name which is either readFile or isFileReadable.
     * @param s HttpServer which provides access to HttpRequest, HttpResponse and HTTP streams.
     */
    ImpGetImage(const std::string& n, HttpServer* s);

    /**
     * @brief Destructor.
     */
    virtual ~ImpGetImage();

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

private:
		
    xos_result_t getHeader(img_handle image, const char* filepath, char* buf, int maxSize)
	throw(XosException);

};

#endif // __ImpGetImage_h__
