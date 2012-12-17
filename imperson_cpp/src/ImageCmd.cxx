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

/*************************************************
 *
 * printUsageAndExit
 *
 *************************************************/
static void printUsageAndExit()
{
	std::string cmd = "getImage";
	cmd += " <headerOnly:0/1>"; 	// 1
	cmd += " <filePath>"; 		// 2
	cmd += " <sizeX>"; 		// 3
	cmd += " <sizeY>"; 		// 4
	cmd += " <zoom>"; 		// 5
	cmd += " <gray>"; 		// 6
	cmd += " <percentx>"; 		// 7
	cmd += " <percenty>"; 		// 8
	printf("Usage: %s\n", cmd.c_str()); fflush(stdout);
	exit(0);
}

/*************************************************
 *
 * getHeader
 *
 *************************************************/
static xos_result_t getHeader(img_handle image, const char* filepath, char* buf, int maxSize)
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

/*************************************************
 *
 * main
 *
 *************************************************/
int main(int argc, char** argv)
{
		
	if (argc < 9)
		printUsageAndExit();
	
	// Disable xos_error output to stderr
	xos_error_set_stream(NULL);
		
	try {

	int i = 1;
	int headerOnly = atoi(argv[i]); ++i;			// 1
	std::string impFilePath = argv[i]; ++i;			// 2
	int sizex = XosStringUtil::toInt(argv[i], 0); ++i;	// 3
	int sizey = XosStringUtil::toInt(argv[i], 0); ++i;	// 4
	double zoom = XosStringUtil::toDouble(argv[i], 0); ++i;	// 
	int gray = XosStringUtil::toInt(argv[i], 0); ++i;	// 6
	double percentx = XosStringUtil::toDouble(argv[i], 0.0);++i;// 7
	double percenty = XosStringUtil::toDouble(argv[i], 0.0);++i;// 8
	std::string outFile = "";
	if (argc == 10) {
		outFile = argv[i]; ++i; // 9
	}

	// create a new diffraction image object
	Diffimage* pImage = new Diffimage(255, 100, 100, 125, 125);
	if (pImage == NULL)
		throw XosException("Failed to create Diffimage");
	
	if (headerOnly) {
		if (pImage->load_header(impFilePath.c_str()) != XOS_SUCCESS)
			throw XosException("Failed to load header");
	} else {
		if (pImage->load(impFilePath.c_str()) != XOS_SUCCESS)
			throw XosException("Failed to load image");
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
	pImage->set_mode (DIFFIMAGE_MODE_FULL);

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
	
	// Send output to stdout
	FILE* stream = stdout;
		
	if (headerOnly) {
	
		// Create buffer to hold header string
		char* header = NULL;
		if ((header=new char[IMAGE_HEADER_MAX_LEN]) == NULL)
			throw XosException("Failed to allocate buffer for header");

		// Copy header to buffer
		if (pImage->get_header(header, IMAGE_HEADER_MAX_LEN) != XOS_SUCCESS)
			throw XosException("Failed in get_header");

		if (!outFile.empty())
			stream = fopen(outFile.c_str(), "w");
		
		if (stream == NULL)
			throw XosException("Failed to open file " + outFile);
		
		// Send HTTP response
    		fprintf(stream, "%s", header); fflush(stream);
	
		// Free header buffer
		delete[] header;
	
		if (stream != stdout)
			fclose(stream);

	} else {
		
		// create the uncompressed image 
		unsigned char *uncompressedBuffer;
		JINFO jinfo;
		if (pImage->create_uncompressed_buffer( & uncompressedBuffer, & jinfo ) != XOS_SUCCESS) {
			throw XosException("Failed in create_uncompressed_buffer");
		}
		
		if (!outFile.empty())
			stream = fopen(outFile.c_str(), "wb");

		if (stream == NULL)
			throw XosException("Failed to open file " + outFile);

		// send a jpeg compressed image
		if (send_jpeg_buffer_to_stream(stream, JPEG_FILE_STREAM, 
			&uncompressedBuffer, & jinfo, 
			JPEG_HTTP_PROTOCOL) != XOS_SUCCESS) {

			free(uncompressedBuffer);
			if (stream != stdout)
				fclose(stream);
			throw XosException("Failed in send_jpeg_buffer_to_stream");
		}

 		free(uncompressedBuffer);
		if (stream != stdout)
			fclose(stream);
	
	}
	
	delete pImage;
	
	} catch (XosException& e) {
		fprintf(stderr, "%s\n", e.getMessage().c_str()); fflush(stderr);
	} 
}






