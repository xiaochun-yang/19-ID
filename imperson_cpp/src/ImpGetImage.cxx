#include "xos.h"
#include "log_quick.h"
extern "C" {
#include "jpeglib.h"
#include "jpegsoc.h"
}
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
#include "HttpServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "ImpGetImage.h"
#include "ImpCommandFactory.h"

#include "libimage.h"
#include "diffimage.h"
#include "marheader.h"

#define IMAGE_HEADER_MAX_LEN 3000

static ImpRegister* dummy1 = new ImpRegister(IMP_GETIMAGE, &ImpGetImage::createCommand, true);
static ImpRegister* dummy2 = new ImpRegister(IMP_GETIMAGEHEADER, &ImpGetImage::createCommand, true);
static ImpRegister* dummy3 = new ImpRegister(IMP_GETHEADER, &ImpGetImage::createCommand, true);
static ImpRegister* dummy4 = new ImpRegister(IMP_GETTHUMBNAIL, &ImpGetImage::createCommand, true);

/*************************************************
 *
 * static method
 *
 *************************************************/
ImpCommand* ImpGetImage::createCommand(const std::string& n, HttpServer* s)
{
	return new ImpGetImage(n, s);
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpGetImage::ImpGetImage()
    : ImpCommand(IMP_GETIMAGE, NULL)
{
}

/*************************************************
 *
 * Constructor
 *
 *************************************************/
ImpGetImage::ImpGetImage(const std::string& c, HttpServer* s)
    : ImpCommand(c, s)
{
}

/*************************************************
 *
 * Destructor
 *
 *************************************************/
ImpGetImage::~ImpGetImage()
{
}

/*************************************************
 *
 * run
 *
 *************************************************/
void ImpGetImage::execute()
    throw(XosException)
{
	bool headerOnly = FALSE;
	if ((name == IMP_GETIMAGE) || (name == IMP_GETTHUMBNAIL)) {
		headerOnly = FALSE;
	} else if ((name == IMP_GETIMAGEHEADER) || ((name == IMP_GETHEADER))) {
		headerOnly = TRUE;
	} else {
		throw XosException(554, SC_554);
	}

	HttpRequest* request = stream->getRequest();
	HttpResponse* response = stream->getResponse();

	std::string impFilePath;
	if (!request->getParamOrHeader(IMP_FILEPATH, impFilePath)) {
		if (!request->getParamOrHeader("fileName", impFilePath))
	       	throw XosException(437, SC_437);
	}

	std::string impUser;
	if (!request->getParamOrHeader(IMP_USER, impUser)) {
		if (!request->getParam("userName", impUser))
			throw XosException(432, SC_432);
	}
	
	// Get image parameters
	int sizex = 400;
	int sizey = 400;
	double zoom = 1.0;
	int gray = 400;
	double percentx = 0.5;
	double percenty = 0.5;
	if (!headerOnly) {

	std::string str;
	
	if (!request->getParam("impSizeX", str)) {
		if (!request->getParam("sizeX", str))
			throw XosException(457, SC_457);
	}
		
	sizex = XosStringUtil::toInt(str, 0);
		
	if (!request->getParam("impSizeY", str)) {
		if (!request->getParam("sizeY", str))
			throw XosException(459, SC_459);
	}
		
	sizey = XosStringUtil::toInt(str, 0);

	if (!request->getParam("impZoom", str)) {
		if (!request->getParam("zoom", str))
			throw XosException(460, SC_460);
	}

	zoom = XosStringUtil::toDouble(str, 0);

	if (!request->getParam("impGray", str)) {
		if (!request->getParam("gray", str))
			throw XosException(461, SC_461);
	}

	gray = XosStringUtil::toInt(str, 0);

	if (!request->getParam("impPercentX", str)) {
		if (!request->getParam("percentX", str))
		throw XosException(462, SC_462);
	}

	percentx = XosStringUtil::toDouble(str, 0.0);
	
	if (!request->getParam("impPercentY", str)) {
		if (!request->getParam("percentY", str))
		throw XosException(463, SC_463);
	}

	percenty = XosStringUtil::toDouble(str, 0.0);
	
	}

	// create a new diffraction image object
	Diffimage* pImage = new Diffimage(255, 100, 100, 125, 125);
	if (pImage == NULL)
		throw XosException(589, SC_589);
	
	if (headerOnly) {
		if (pImage->load_header(impFilePath.c_str()) != XOS_SUCCESS)
			throw XosException(592, SC_592);
	} else {
		if (pImage->load(impFilePath.c_str()) != XOS_SUCCESS)
			throw XosException(592, SC_592);
	}


	// Calculate center of image
	int im_centerx = (int)(percentx * (double) pImage->get_image_size_x());
	int im_centery = (int)(percenty * (double) pImage->get_image_size_y());

	/* set parameters for creating the zoomed image */
	pImage->set_display_size( sizex, sizey ); 
	pImage->set_image_center( im_centerx, im_centery );
	pImage->set_zoom (zoom);
	pImage->set_contrast_min (0);
	pImage->set_contrast_max (gray);
	pImage->set_jpeg_quality (90);
	pImage->set_sampling_quality (3);
	
	if (name == IMP_GETIMAGE) {
		pImage->set_mode(DIFFIMAGE_MODE_FULL);
	} else if (name == IMP_GETTHUMBNAIL) {
		pImage->set_mode(DIFFIMAGE_MODE_THUMB);
	}

	char detectorTypeC64[64];
	//characteristics of image
	float  wavelength;
	float  originX;
	float  originY;
	float  time;
	float  pixelSize;
	float  distance;
	pImage->get_image_parameters(wavelength,
					distance,
					originX,
					originY,
					pixelSize,
					time,
					detectorTypeC64);	
	

	//image was loaded successfully or found in cache
	response->setHeader("wavelength", XosStringUtil::fromDouble(wavelength));
	response->setHeader("distance", XosStringUtil::fromDouble(distance));
	response->setHeader("originX", XosStringUtil::fromDouble(originX));
	response->setHeader("originY", XosStringUtil::fromDouble(originY));
	response->setHeader("pixelSize", XosStringUtil::fromDouble(pixelSize));
	response->setHeader("time", XosStringUtil::fromDouble(time));
	response->setHeader("detectorTypeC64", detectorTypeC64);
	
	
	if (headerOnly) {
	
		response->setHeader(EH_CONTENT_TYPE, "text/plain");
		stream->finishWriteResponseHeader();

			// Create buffer to hold header string
		char* header = NULL;
		if ((header=new char[IMAGE_HEADER_MAX_LEN]) == NULL)
			throw XosException(593, SC_593);

		// Copy header to buffer
		if (pImage->get_header(header, IMAGE_HEADER_MAX_LEN) != XOS_SUCCESS)
			throw XosException(588, SC_588);

		// Send HTTP response
    		stream->writeResponseBody(header, strlen(header));
		stream->finishWriteResponse();
	
		// Free header buffer
		delete[] header;
	
	} else {

		response->setHeader(EH_CONTENT_TYPE, WWW_JPEG);
		stream->finishWriteResponseHeader();

			// create the uncompressed image 
		unsigned char *uncompressedBuffer;
		JINFO jinfo;
		if (pImage->create_uncompressed_buffer( & uncompressedBuffer, & jinfo ) != XOS_SUCCESS)
			throw XosException(590, SC_590);
		// send a jpeg compressed image
		FILE* out = (FILE*)stream->getUserData();
		if (send_jpeg_buffer_to_stream(out, JPEG_FILE_STREAM, 
			&uncompressedBuffer, & jinfo, 
			JPEG_HTTP_PROTOCOL) != XOS_SUCCESS) {
			free(uncompressedBuffer);
			throw XosException(591, SC_591);
		}

		stream->finishWriteResponse();
 		free(uncompressedBuffer);
	
	}
	
	delete pImage;
}



/*************************************************
 *
 * getHeader
 *
 *************************************************/
xos_result_t ImpGetImage::getHeader(img_handle image, const char* filepath, char* buf, int maxSize)
	throw(XosException)
{
	int tagIndex;
	int tagCount = image->tags;
	img_tag *tag = image->tag;
	char spacer[200];
	long len;
	const char *imgField;
			
	char* ptr = buf;
		
	// print each tag and data item to the file
	for ( tagIndex = 0; tagIndex < tagCount; tagIndex++ ) {
	
		if ( tag[tagIndex].tag == NULL )
			break;
		len = strlen( tag[tagIndex].tag );
		strcpy( spacer, "                        " );
		spacer[20-len] = 0;
		sprintf(ptr, "%s %s %s\n", tag[tagIndex].tag, spacer,
			tag[tagIndex].data );
		
		// move the pointer 
		ptr = buf+strlen(buf);
		
	}
		
	imgField = img_get_field(image, "DETECTOR");
	if (imgField != NULL && strcmp(imgField, "MAR 345") == 0) {
		append_mar345_header_to_buf( filepath, ptr, maxSize-strlen(buf));		
	}
		
  
	return XOS_SUCCESS;
	
}



