/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/
/****************************************************************
                        diffimage.c

   This C++ source file defines the member functions for the=
   Diffimage class declared in diffimage.h.

   Author:           Timothy M. McPhillips, SSRL.
   Date:					April 3, 1999 by TMM.

****************************************************************/

/*
 *The following notice applies to code excerpted from gnuplot:
 *Copyright 1986 - 1993, 1998   Thomas Williams, Colin Kelley
 *
 * Permission to use, copy, and distribute this software and its
 * documentation for any purpose with or without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.
 */

/* local include files */
#include <string>
#include "libimage.h"

#include "xos.h"
#include "xos_log.h"

#include "jpeglib.h"
#include "jpegsoc.h"

#include "diffimage.h"
#include "marheader.h"

#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
typedef struct cbfTagMap_t {
    char TAG[1024];
    char format[1024];
} cbfTagMap;
#endif

Diffimage::Diffimage( diffimage_value_t maxValue,
							 int dSizeX,
							 int dSizeY,
							 int tSizeX,
							 int tSizeY ) : image(NULL),
												 format(DIFFIMAGE_FORMAT_NONE),
												 displaySizeX(dSizeX),
												 displaySizeY(dSizeY),
												 thumbSizeX(tSizeX),
												 thumbSizeY(tSizeY),
												 maxDisplayValue(maxValue),
												 offsetX(0),
												 offsetY(0),
												 zoom(1.0),
												 workingBuffer(NULL),
												 workingBufferSize(0),
												 jpegQuality(100),
												 samplingQuality(3),
												 mode(DIFFIMAGE_MODE_FULL),mSharedImage(false) {
}

Diffimage::Diffimage( imagePtr_t image_, diffimage_value_t maxValue,
		int dSizeX,
		int dSizeY,
		int tSizeX,
		int tSizeY ) : image(image_), format(DIFFIMAGE_FORMAT_NONE),
displaySizeX(dSizeX),
displaySizeY(dSizeY),
thumbSizeX(tSizeX),
thumbSizeY(tSizeY),
maxDisplayValue(maxValue),
offsetX(0),
offsetY(0),
zoom(1.0),
workingBuffer(NULL),
workingBufferSize(0),
jpegQuality(100),
samplingQuality(3),
mode(DIFFIMAGE_MODE_FULL),mSharedImage(true) {

	/* store image dimensions */
	imageSizeX = image->columns();
	imageSizeY = image->rows();

	overloadCutoff = (long int)image->get_number ("OVERLOAD_CUTOFF");

	/* calculate sampling at zoom level of 1 */
	sampling = (double) imageSizeX / (double) displaySizeX;

	/* calculate ratio of sampling to current zoom level */
	zoomRatio = sampling / zoom;
	thumbRatio = (double) imageSizeX / (double) thumbSizeX;
	ratio = zoomRatio;

	image->getMinMax(maxImageValue,minImageValue);

	reset_view();
}


Diffimage::~Diffimage( void ) {
	/* close handle to libimage object if open and not shared*/
	if ( image != NULL &  !mSharedImage )
		{
		delete image;
		}

	/* delete working buffer if allocated */
	if ( workingBuffer != NULL )
		{
		xos_log("\nFreeing working buffer in Diffimage destructor.\n");
		free( workingBuffer );
		}
	}


/****************************************************************
	Diffimage::get_display_size -- access the size of the
          display image; different for full view vs. thumbnail
****************************************************************/
std::pair<int,int> Diffimage::get_display_size() const {
        if (mode==DIFFIMAGE_MODE_FULL){
          return std::pair<int,int>(displaySizeX,displaySizeY);
        } else {
          return std::pair<int,int>(thumbSizeX,thumbSizeY);
        }
}


/****************************************************************
	Diffimage::set_display_size -- sets the size of the display
	image
****************************************************************/

void Diffimage::set_display_size
	(
	int dSizeX,
	int dSizeY
	)

	{
	displaySizeX = dSizeX;
	displaySizeY = dSizeY;

	/* reset display parameters if an image is currently loaded */
	if ( image != NULL )
		{
		/* calculate sampling at zoom level of 1 */
		sampling = (double) imageSizeX / (double) displaySizeX;

		/* calculate ratio of sampling to current zoom level */
		zoomRatio = sampling / zoom;
		thumbRatio = (double) imageSizeX / (double) thumbSizeX;
		ratio = zoomRatio;

		/* set the image center */
		set_display_center( displaySizeX / 2, displaySizeY / 2 );
		}
	}




/****************************************************************
	Diffimage::load -- uses the libimage library to read in the
	image file specified as the single argument.
****************************************************************/

xos_result_t Diffimage::load
	(
	const char * filename
	)

	{
	/* local variables */
	xos_boolean_t		firstImage;

	/* close handle to libimage object if open */
	if ( image != NULL )
		{
		delete image;
		firstImage = FALSE;
		}
	else
		{
		firstImage = TRUE;
		}

	/* open a handle to libimage object */
	xos_log("Diffimage.load: reading image\n");
	/* load the image from disk */
	try {
		std::string source_image(filename);
		image = diffimage::libimage_factory(source_image);
		image->read_data();
	} catch (int ret) {
		xos_error("***** Diffimage::load -- Error loading image (error code %d) %s *****\n", ret, filename);
		return XOS_FAILURE;
	}

	xos_log("Diffimage.load: image read\n");


	/* store image dimensions */
	imageSizeX			= image->columns();
	imageSizeY			= image->rows();

	overloadCutoff = (long int)image->get_number ("OVERLOAD_CUTOFF");

	xos_log("overload cutoff %d \n",overloadCutoff);

	/* calculate sampling at zoom level of 1 */
	sampling = (double) imageSizeX / (double) displaySizeX;

	/* calculate ratio of sampling to current zoom level */
	zoomRatio = sampling / zoom;
	thumbRatio = (double) imageSizeX / (double) thumbSizeX;
	ratio = zoomRatio;

	/* query minimum and maximum pixel values in image */
	image->getMinMax(maxImageValue,minImageValue);

	xos_log("Diffimage.load: found maxValue image\n");

	/* set default values for display image if needed */
	if (
		firstImage == TRUE
		)
		{
		reset_view();
		}

	/* report success */
	return XOS_SUCCESS;
	}



xos_result_t Diffimage::load_header
	(
	const char * filename
	)

	{
	/* local variables */
	xos_boolean_t		firstImage;

	/* close handle to libimage object if open */
	if ( image != NULL )
		{
		delete image;
		firstImage = FALSE;
		}
	else
		{
		firstImage = TRUE;
		}

	/* open a handle to libimage object */

	xos_log("Diffimage.load: reading image\n");
	/* load the image from disk */
        try {
	      image = diffimage::libimage_factory(std::string(filename));
          image->read_header();
        } catch (int ret) {
		xos_error("***** Diffimage::load -- Error loading image (error code %d) %s *****\n", ret, filename);
		return XOS_FAILURE;
        }
	xos_log("Diffimage.load: image read\n");

	/* store image dimensions */
	imageSizeX			= image->columns();
	imageSizeY			= image->rows();

	overloadCutoff = (long int)image->get_number ("OVERLOAD_CUTOFF");

	xos_log("overload cutoff %d \n",overloadCutoff);

	/* calculate sampling at zoom level of 1 */
	sampling = (double) imageSizeX / (double) displaySizeX;

	/* calculate ratio of sampling to current zoom level */
	zoomRatio = sampling / zoom;
	thumbRatio = (double) imageSizeX / (double) thumbSizeX;
	ratio = zoomRatio;

	/* set default values for display image if needed */
	if (
		firstImage == TRUE
		)
		{
		reset_view();
		}

	/* report success */
	return XOS_SUCCESS;
	}

void Diffimage::reset_view()
	{
	zoom 				= 1.0;
	set_display_center( displaySizeX / 2, displaySizeY / 2 );
	contrastMin 	= minImageValue;
	contrastMax 	= maxImageValue;
	}

#if defined TCL_PHOTO_SUPPORT
//Some applications may want to display the jpegs themselves.
//If not, don't compile this in.
xos_result_t Diffimage::create_Tk_photo( Tcl_Interp * interp,
													  const char * photo )
 	{
 	/* local variables */
 	Tk_PhotoHandle handle;
 	Tk_PhotoImageBlock photoImageBlock;
 	unsigned char * buffer;

 	/* get handle to the photo object */
 	handle = Tk_FindPhoto( interp, (char *) photo );

 	/* set basic photo parameters */
 	photoImageBlock.width 		= displaySizeX;
 	photoImageBlock.height 		= displaySizeY;
 	photoImageBlock.pitch 		= displaySizeX;
 	photoImageBlock.offset[0] 	= 0;
 	photoImageBlock.offset[1] 	= 0;
 	photoImageBlock.offset[2] 	= 0;
 	photoImageBlock.pixelSize 	= 1;

 	/* refresh the display buffer */
 	buffer = get_display_buffer();

 	/* report error bad memory allocation */
 	if ( buffer == NULL )
 		{
 		xos_error( "Error allocating memory.");
 		return XOS_FAILURE;
 		}

 	/* point photo image block to prepared buffer */
 	photoImageBlock.pixelPtr = buffer;

 	/* write out the photo object */
 	Tk_PhotoPutBlock( handle, &(photoImageBlock), 0, 0,
 		photoImageBlock.width, photoImageBlock.height );

 	/* report success */
 	return XOS_SUCCESS;
 	}
#endif

/*
xos_result_t Diffimage::get_header(char* buf, int maxSize)
{
	if ((buf == NULL) || (maxSize <= 0))
		return XOS_FAILURE;

    memset(buf, 0, maxSize);

#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
    static cbfTagMap tagFormat[] = {
    {"SIZE1",               "size_slow:          %7.0f\n"},
    {"SIZE2",               "size_fast:          %7.0f\n"},
    {"OVERLOAD_CUTOFF",     "overload cutoff:  %9.0f\n"},
    {"WAVELENGTH",          "wavelength (Angstr):%7.4f\n"},
    {"DISTANCE",            "distance (mm):      %7.2f\n"},
    {"PIXEL_SIZE",          "pixel size (mm):    %7.2f\n"},
    {"BEAM_CENTER_X",       "beam_slow (mm):     %7.2f\n"},
    {"BEAM_CENTER_Y",       "beam_fast (mm):     %7.2f\n"},
    {"OSC_START",           "osc_start (deg):    %7.2f\n"},
    {"OSC_RANGE",           "osc_range (deg):    %7.2f\n"}
    };

    static size_t nTag = sizeof(tagFormat) / sizeof(cbfTagMap);

    if (image->wrapper_type()=="cbflib_adaptbx") {
        char oneLine[1024] = {0};

        sprintf(oneLine, "imfCIF-formatted file\n");

        if (strlen(oneLine) + strlen(buf) < maxSize) {
            strcat( buf, oneLine);
        } else {
		    return XOS_FAILURE;
        }
        size_t i;

        for (i = 0; i < nTag; ++i) {
            sprintf(oneLine, tagFormat[i].format,
            image->get_number(tagFormat[i].TAG));

            if (strlen(oneLine) + strlen(buf) < maxSize) {
                strcat( buf, oneLine);
            } else {
                return XOS_FAILURE;
            }
        }

  	    return XOS_SUCCESS;
    } else {
#endif
	int tagIndex;
	int tagCount = image->tags();
	img_tag *tag = image->tag();
	const char *imgField;
    char oneLine[1024] = {0};

	// print each tag and data item to the file
	for ( tagIndex = 0; tagIndex < tagCount; tagIndex++ ) {

		if ( tag[tagIndex].tag == NULL )
			break;
		sprintf(oneLine, "%-21s %s\n", tag[tagIndex].tag,
			tag[tagIndex].data );

        if (strlen(oneLine) + strlen(buf) < maxSize) {
            strcat( buf, oneLine);
        } else {
            return XOS_FAILURE;
        }
	}

	imgField = image->get_field("DETECTOR");
	if (imgField != NULL && strcmp(imgField, "MAR 345") == 0) {
		append_mar345_header_to_buf( filepath, buf+strlen(buf), maxSize-strlen(buf));
	}

	return XOS_SUCCESS;
#ifdef DIFFIMAGE_HAVE_CBFLIB_ADAPTBX
  }
#endif
}
*/
//called by imgsrv gui client handler
// Can throw std::exception
xos_result_t Diffimage::create_uncompressed_buffer ( unsigned char **uncompressedBuffer, JINFO *jinfo )
{
	/* report error bad memory allocation */
	unsigned char* buffer = get_display_buffer();

	/* report error bad memory allocation */
	if ( buffer == NULL )
		{
		xos_error( "Error allocating memory.");
		return XOS_FAILURE;
		}

	/* get a returnable memory buffer for the image */
	*uncompressedBuffer = (unsigned char *) malloc( workingBufferSize );

	if ( *uncompressedBuffer == NULL) {
		xos_log("Failed to allocate uncompressed buffer\n");
		return XOS_FAILURE;
	}

	/* copy image into buffer */
	memcpy( *uncompressedBuffer, buffer, workingBufferSize );

	jinfo->quality = (int) jpegQuality;

	if ( mode == DIFFIMAGE_MODE_FULL )
		{
		jinfo->width = displaySizeX;
		jinfo->height = displaySizeY;
		}
	else
		{
		draw_zoom_box( *uncompressedBuffer );
		jinfo->width = thumbSizeX;
		jinfo->height = thumbSizeY;
		}
	jinfo->components = 3;
	jinfo->j_color_space = JCS_RGB;

	return XOS_SUCCESS;

}

void Diffimage::free_uncompressed_buffer ( unsigned char * uncompressedBuffer ) {

	if (uncompressedBuffer != NULL)
		free (uncompressedBuffer);

}

void Diffimage::draw_zoom_box
	(
	unsigned char * buffer
	)

	{
	/* no box to draw if not zoomed */
	if ( zoom == 1 && offsetX == 0 && offsetY == 0 ) return;

	double imageToThumb 		= (double) thumbSizeX / imageSizeX;
	int thumbOffsetX 			= (int)(offsetX * imageToThumb);
	int thumbOffsetY 			= (int)(offsetY * imageToThumb);
	int thumbDisplaySizeX 	= (int)((double) thumbSizeX / zoom);
	int thumbDisplaySizeY 	= (int)((double) thumbSizeY / zoom);

	if ( thumbDisplaySizeX >= 5 )
		{
		int point1x = thumbOffsetX;
		int point1y = thumbOffsetY;
		int point2x = point1x + thumbDisplaySizeX;
		int point3y = point1y + thumbDisplaySizeY;

		draw_horz_line( buffer, point1x, point2x, point1y, 255, 0, 0 );
		draw_vert_line( buffer, point1y, point3y, point1x, 255, 0, 0 );
		draw_horz_line( buffer, point1x, point2x, point3y, 255, 0, 0 );
		draw_vert_line( buffer, point1y, point3y, point2x, 255, 0, 0 );
		}
	else
		{
		int centerX = thumbOffsetX + thumbDisplaySizeX / 2;
		int centerY = thumbOffsetY + thumbDisplaySizeY / 2;

		draw_horz_line( buffer, centerX - 10, centerX + 10, centerY, 255, 0, 0 );
		draw_vert_line( buffer, centerY - 10, centerY + 10, centerX, 255, 0, 0 );
		}

}


void Diffimage::draw_horz_line
	(
	unsigned char * buffer,
	int x0,
	int x1,
	int y,
	unsigned char red,
	unsigned char blue,
	unsigned char green
	)

	{
	/* local variables */
	int x;
	unsigned char * bufferPtr;

	/* return if line completely out of range in x */
	if ( x1 < x0 || x1 < 0 || x0 >= thumbSizeX ) return;

	/* return if line completely out of range in y */
	if ( y < 0 || y >= thumbSizeY ) return;

	/* clip line at left edge */
	if ( x0 < 0 ) x0 = 0;

	/* clip line at right edge */
	if ( x1 >= thumbSizeX ) x1 = thumbSizeX - 1;

	/* calculate address of start of line */
	bufferPtr = buffer + 3 * (y * thumbSizeX + x0);

	for ( x = x0; x <= x1; x++ )
		{
		*(bufferPtr++) = red;
		*(bufferPtr++) = blue;
		*(bufferPtr++) = green;
		}
	}


void Diffimage::draw_vert_line
	(
	unsigned char * buffer,
	int y0,
	int y1,
	int x,
	unsigned char red,
	unsigned char blue,
	unsigned char green
	)

	{
	/* local variables */
	int y;
	unsigned char * bufferPtr;

	/* return if line completely out of range in y */
	if ( y1 < y0 || y1 < 0 || y0 >= thumbSizeY ) return;

	/* return if line completely out of range in x */
	if ( x < 0 || x >= thumbSizeX ) return;

	/* clip line at left edge */
	if ( y0 < 0 ) y0 = 0;

	/* clip line at right edge */
	if ( y1 >= thumbSizeY ) y1 = thumbSizeY - 1;

	/* calculate address of start of line */
	bufferPtr = buffer + 3 * (y0 * thumbSizeX + x);

	for ( y = y0; y <= y1; y++ )
		{
		bufferPtr[0] = red;
		bufferPtr[1] = blue;
		bufferPtr[2] = green;
		bufferPtr += 3 * thumbSizeX;
		}
	}




unsigned char *  Diffimage::get_display_buffer( void ) {

	/* local variables */
	unsigned char * buffer;
	unsigned char * bufferPtr;
	int displayX;
	int displayY;
	int quality;
	int value;
	int size;
	char text[20];
	int imageX;
	int imageY;
	int j;
	int sizeY;
	int sizeX;

	/* calculate size of buffer */
	if ( mode == DIFFIMAGE_MODE_FULL )
		{
		size = displaySizeX * displaySizeY * 3;
		sizeY = displaySizeY;
		sizeX = displaySizeX;
		}
	else
		{
		size = thumbSizeX * thumbSizeY * 3;
		sizeY = thumbSizeY;
		sizeX = thumbSizeX;
		}

	/* get buffer to write photo into */
	buffer = get_working_buffer( size );

	/* return NULL if memory allocation error */
	if( buffer == NULL )
		{
		return NULL;
		}

	/* determine optimal sampling quality for current zoom level */
	if ( zoomRatio <= 1 )
		{
		quality = 0;
		}
	else
		{
		if ( zoomRatio <= 2 )
			{
			quality = min( samplingQuality, 1 );
			}
		else
			{
			quality = min( samplingQuality, 3 );
			}
		}

	/* precalculate diffraction image increments */
	incr25double = 0.25 * ratio;
	incr25 = (int)(incr25double);
	incr50 = (int)(incr25double * 2);
	incr75 = (int)(incr25double * 3);


	for( displayY = 0, bufferPtr = buffer; displayY < sizeY; displayY++ )
		{
		for( displayX = 0; displayX < sizeX; displayX++ )
			{
			value =  get_display_value( displayX, displayY, quality );

			if ( !overloadFlag )
				{
				*(bufferPtr++) = (unsigned char)value;
				*(bufferPtr++) = (unsigned char)value;
				*(bufferPtr++) = (unsigned char)value;
				}
			else
				{
				*(bufferPtr++) = (unsigned char)255;
				*(bufferPtr++) = (unsigned char)255;
				*(bufferPtr++) = (unsigned char)0;
				}
			}
		}
		// Draw markup of full image or thumbnail.
		if (mode == DIFFIMAGE_MODE_FULL)
			image->MK->draw_markup(sizeX, sizeY, offsetX, offsetY, ratio, (const void*)buffer);
		else
			image->MK->draw_markup(sizeX, sizeY, 0, 0, ratio, (const void*)buffer);

	/* provide text overlay for pixel values if image mode is FULL
	   and if display is sufficiently zoomed in */

	if ( mode == DIFFIMAGE_MODE_FULL && ratio < (1.0/25.0))
		{
		/* 5x9 font, bottom row first, left pixel in lsb */
		char_row fnt5x9[FNT_CHARS][FNT5X9_VBITS] = {
		/* */  {000000,000000,000000,000000,000000,000000,000000,000000,000000},
		/*!*/  {000000,000000,0x0004,000000,0x0004,0x0004,0x0004,0x0004,0x0004},
		/*"*/  {000000,000000,000000,000000,000000,000000,0x000a,0x000a,0x000a},
		/*#*/  {000000,000000,0x000a,0x000a,0x001f,0x000a,0x001f,0x000a,0x000a},
		/*$*/  {000000,000000,0x0004,0x000f,0x0014,0x000e,0x0005,0x001e,0x0004},
		/*%*/  {000000,000000,0x0018,0x0019,0x0002,0x0004,0x0008,0x0013,0x0003},
		/*&*/  {000000,000000,0x0016,0x0009,0x0015,0x0002,0x0005,0x0005,0x0002},
		/*'*/  {000000,000000,000000,000000,000000,0x0002,0x0004,0x0006,0x0006},
		/*(*/  {000000,000000,0x0008,0x0004,0x0002,0x0002,0x0002,0x0004,0x0008},
		/*)*/  {000000,000000,0x0002,0x0004,0x0008,0x0008,0x0008,0x0004,0x0002},
		/***/  {000000,000000,0x0004,0x0015,0x000e,0x001f,0x000e,0x0015,0x0004},
		/*+*/  {000000,000000,000000,0x0004,0x0004,0x001f,0x0004,0x0004,000000},
		/*,*/  {000000,0x0002,0x0004,0x0006,0x0006,000000,000000,000000,000000},
		/*-*/  {000000,000000,000000,000000,000000,0x001f,000000,000000,000000},
		/*.*/  {000000,000000,0x0006,0x0006,000000,000000,000000,000000,000000},
		/*-/-*/{000000,000000,000000,0x0001,0x0002,0x0004,0x0008,0x0010,000000},
		/*0*/  {000000,000000,0x000e,0x0011,0x0013,0x0015,0x0019,0x0011,0x000e},
		/*1*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0006,0x0004},
		/*2*/  {000000,000000,0x001f,0x0001,0x0001,0x000e,0x0010,0x0011,0x000e},
		/*3*/  {000000,000000,0x000e,0x0011,0x0010,0x000c,0x0010,0x0011,0x000e},
		/*4*/  {000000,000000,0x0008,0x0008,0x001f,0x0009,0x000a,0x000c,0x0008},
		/*5*/  {000000,000000,0x000e,0x0011,0x0010,0x0010,0x000f,0x0001,0x001f},
		/*6*/  {000000,000000,0x000e,0x0011,0x0011,0x000f,0x0001,0x0002,0x000c},
		/*7*/  {000000,000000,0x0001,0x0001,0x0002,0x0004,0x0008,0x0010,0x001f},
		/*8*/  {000000,000000,0x000e,0x0011,0x0011,0x000e,0x0011,0x0011,0x000e},
		/*9*/  {000000,000000,0x0006,0x0008,0x0010,0x001e,0x0011,0x0011,0x000e},
		/*:*/  {000000,000000,000000,0x0006,0x0006,000000,0x0006,0x0006,000000},
		/*;*/  {000000,0x0001,0x0002,0x0006,0x0006,000000,0x0006,0x0006,000000},
		/*<*/  {000000,000000,0x0008,0x0004,0x0002,0x0001,0x0002,0x0004,0x0008},
		/*=*/  {000000,000000,000000,000000,0x001f,000000,0x001f,000000,000000},
		/*>*/  {000000,000000,0x0002,0x0004,0x0008,0x0010,0x0008,0x0004,0x0002},
		/*?*/  {000000,000000,0x0004,000000,0x0004,0x0008,0x0010,0x0011,0x000e},
		/*@*/  {000000,000000,0x000e,0x0015,0x0015,0x0016,0x0010,0x0011,0x000e},
		/*A*/  {000000,000000,0x0011,0x0011,0x001f,0x0011,0x0011,0x000a,0x0004},
		/*B*/  {000000,000000,0x000f,0x0012,0x0012,0x000e,0x0012,0x0012,0x000f},
		/*C*/  {000000,000000,0x000e,0x0011,0x0001,0x0001,0x0001,0x0011,0x000e},
		/*D*/  {000000,000000,0x000f,0x0012,0x0012,0x0012,0x0012,0x0012,0x000f},
		/*E*/  {000000,000000,0x001f,0x0001,0x0001,0x0007,0x0001,0x0001,0x001f},
		/*F*/  {000000,000000,0x0001,0x0001,0x0001,0x0007,0x0001,0x0001,0x001f},
		/*G*/  {000000,000000,0x001e,0x0011,0x0011,0x0019,0x0001,0x0001,0x001e},
		/*H*/  {000000,000000,0x0011,0x0011,0x0011,0x001f,0x0011,0x0011,0x0011},
		/*I*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0004,0x000e},
		/*J*/  {000000,000000,0x000e,0x0011,0x0010,0x0010,0x0010,0x0010,0x0010},
		/*K*/  {000000,000000,0x0011,0x0009,0x0005,0x0003,0x0005,0x0009,0x0011},
		/*L*/  {000000,000000,0x001f,0x0001,0x0001,0x0001,0x0001,0x0001,0x0001},
		/*M*/  {000000,000000,0x0011,0x0011,0x0011,0x0015,0x0015,0x001b,0x0011},
		/*N*/  {000000,000000,0x0011,0x0011,0x0011,0x0019,0x0015,0x0013,0x0011},
		/*O*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x0011,0x0011,0x000e},
		/*P*/  {000000,000000,0x0001,0x0001,0x0001,0x000f,0x0011,0x0011,0x000f},
		/*Q*/  {000000,0x0018,0x000e,0x0015,0x0011,0x0011,0x0011,0x0011,0x000e},
		/*R*/  {000000,000000,0x0011,0x0009,0x0005,0x000f,0x0011,0x0011,0x000f},
		/*S*/  {000000,000000,0x000e,0x0011,0x0010,0x000e,0x0001,0x0011,0x000e},
		/*T*/  {000000,000000,0x0004,0x0004,0x0004,0x0004,0x0004,0x0004,0x001f},
		/*U*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x0011,0x0011,0x0011},
		/*V*/  {000000,000000,0x0004,0x0004,0x000a,0x000a,0x0011,0x0011,0x0011},
		/*W*/  {000000,000000,0x0011,0x001b,0x0015,0x0011,0x0011,0x0011,0x0011},
		/*X*/  {000000,000000,0x0011,0x0011,0x000a,0x0004,0x000a,0x0011,0x0011},
		/*Y*/  {000000,000000,0x0004,0x0004,0x0004,0x0004,0x000a,0x0011,0x0011},
		/*Z*/  {000000,000000,0x001f,0x0001,0x0002,0x0004,0x0008,0x0010,0x001f},
		/*[*/  {000000,000000,0x000e,0x0002,0x0002,0x0002,0x0002,0x0002,0x000e},
		/*\*/  {000000,000000,000000,0x0010,0x0008,0x0004,0x0002,0x0001,000000},
		/*]*/  {000000,000000,0x000e,0x0008,0x0008,0x0008,0x0008,0x0008,0x000e},
		/*^*/  {000000,000000,000000,000000,000000,000000,0x0011,0x000a,0x0004},
		/*_*/  {000000,000000,0x001f,000000,000000,000000,000000,000000,000000},
		/*`*/  {000000,000000,000000,000000,000000,0x0008,0x0004,0x000c,0x000c},
		/*a*/  {000000,000000,0x001e,0x0011,0x001e,0x0010,0x000e,000000,000000},
		/*b*/  {000000,000000,0x000d,0x0013,0x0011,0x0013,0x000d,0x0001,0x0001},
		/*c*/  {000000,000000,0x000e,0x0011,0x0001,0x0011,0x000e,000000,000000},
		/*d*/  {000000,000000,0x0016,0x0019,0x0011,0x0019,0x0016,0x0010,0x0010},
		/*e*/  {000000,000000,0x000e,0x0001,0x001f,0x0011,0x000e,000000,000000},
		/*f*/  {000000,000000,0x0004,0x0004,0x0004,0x000e,0x0004,0x0014,0x0008},
		/*g*/  {0x000e,0x0011,0x0016,0x0019,0x0011,0x0019,0x0016,000000,000000},
		/*h*/  {000000,000000,0x0011,0x0011,0x0011,0x0013,0x000d,0x0001,0x0001},
		/*i*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0006,000000,0x0004},
		/*j*/  {0x0006,0x0009,0x0008,0x0008,0x0008,0x0008,0x000c,000000,0x0008},
		/*k*/  {000000,000000,0x0009,0x0005,0x0003,0x0005,0x0009,0x0001,0x0001},
		/*l*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0004,0x0006},
		/*m*/  {000000,000000,0x0015,0x0015,0x0015,0x0015,0x000b,000000,000000},
		/*n*/  {000000,000000,0x0011,0x0011,0x0011,0x0013,0x000d,000000,000000},
		/*o*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x000e,000000,000000},
		/*p*/  {0x0001,0x0001,0x000d,0x0013,0x0011,0x0013,0x000d,000000,000000},
		/*q*/  {0x0010,0x0010,0x0016,0x0019,0x0011,0x0019,0x0016,000000,000000},
		/*r*/  {000000,000000,0x0001,0x0001,0x0001,0x0013,0x000d,000000,000000},
		/*s*/  {000000,000000,0x000f,0x0010,0x000e,0x0001,0x001e,000000,000000},
		/*t*/  {000000,000000,0x0008,0x0014,0x0004,0x0004,0x001f,0x0004,0x0004},
		/*u*/  {000000,000000,0x0016,0x0019,0x0011,0x0011,0x0011,000000,000000},
		/*v*/  {000000,000000,0x0004,0x000a,0x0011,0x0011,0x0011,000000,000000},
		/*w*/  {000000,000000,0x000a,0x0015,0x0015,0x0011,0x0011,000000,000000},
		/*x*/  {000000,000000,0x0011,0x000a,0x0004,0x000a,0x0011,000000,000000},
		/*y*/  {0x000e,0x0010,0x001e,0x0011,0x0011,0x0011,0x0011,000000,000000},
		/*z*/  {000000,000000,0x001f,0x0002,0x0004,0x0008,0x001f,000000,000000},
		/*{*/  {000000,000000,0x0008,0x0004,0x0004,0x0002,0x0004,0x0004,0x0008},
		/*|*/  {000000,000000,0x0004,0x0004,0x0004,000000,0x0004,0x0004,0x0004},
		/*}*/  {000000,000000,0x0002,0x0004,0x0004,0x0008,0x0004,0x0004,0x0002},
		/*~*/  {000000,000000,000000,000000,000000,000000,0x0008,0x0015,0x0002},
		/*DEL*/{000000,000000,0x001f,0x001f,0x001f,0x001f,0x001f,0x001f,0x001f},
		};
		b_hchar = FNT5X9_HCHAR;
		b_hbits = FNT5X9_HBITS;
		b_vchar = FNT5X9_VCHAR;
		b_vbits = FNT5X9_VBITS;
		for (j = 0; j < FNT_CHARS; j++)
			b_font[j] = &fnt5x9[j][0];
		/* b_charsize(FNT5X9); */

		bufferPtr = buffer;
		/* Loop through all the Image pixels shown on the display */
		/* Also make sure the Image pixels are within the boundaries of the image */

		for( imageY  = (map_display_y_to_image<int>(0) < 0) ? 0 : map_display_y_to_image<int>(0);
			  imageY <= map_display_y_to_image<int>(displaySizeY - 1) && imageY < imageSizeY;
			  imageY++ )
			{
			for( imageX =(map_display_x_to_image<int>(0) < 0) ? 0 : map_display_x_to_image<int>(0);
				  imageX<= map_display_x_to_image<int>(displaySizeX - 1) && imageX < imageSizeX;
				  imageX++ )
				{
				/* re-calculate display coordinates for the upper-left corner of image pixel */
				displayX = (int)(double(imageX-offsetX)/ratio);
				displayY = (int)(double(imageY-offsetY)/ratio);
				sprintf(text,"%d",image->pixel( imageX, imageY ));

				value = get_display_value( (int)(displayX+(0.5/ratio)), (int)(displayY+(0.5/ratio)), quality );

				/* now typeset the pixel value so it centers on the image pixel.
					The image pixel is (1/ratio) display pixels square.  */

				displayX +=  int(1.0/ratio-double(strlen(text))*double(b_hchar))/2;
				displayY +=  int(1.0/ratio)/2;

				/* set the text color & overlay it on display */
				if (value < (maxDisplayValue/2) && !overloadFlag )
					{
					b_put_text(displayX,displayY,text,0,maxDisplayValue,bufferPtr);
					}
				else
					{
					b_put_text(displayX,displayY,text,0,0,bufferPtr);
					}
				}
			}
		}

	/* return the buffer */
	return buffer;
	}


unsigned char * Diffimage::get_working_buffer( xos_size_t size )

	{

	/* check if currently allocated buffer is big enough */
	if ( workingBufferSize < size )
		{
		/* if not, free up memory currently allocated... */
		if ( workingBuffer != NULL )
			{
			free( workingBuffer );
			}

		/* ...and allocate the needed memory */
		workingBuffer = (unsigned char *) malloc ( size );
		if (workingBuffer == NULL) {
			xos_log("Failed to allocate working buffer\n");
			workingBufferSize = 0;
			return workingBuffer;
		}

		/* update buffer size */
		workingBufferSize = size;
		}

	/* return the buffer's address */
	return workingBuffer;
	}

diffimage_value_t Diffimage::get_display_value ( int displayX,
																 int displayY,
																 int quality )
	{
	/* local variables */
	diffimage_value_t imageValue = 0;
	diffimage_value_t value;
	double x;
	double y;
	int imageY;
	int imageX;

	//clear the overload flag
	overloadFlag = 0;

	/* get the sampled image value */
	if ( mode == DIFFIMAGE_MODE_FULL )
		{
		/* get image coordinates of pixel to read */
		imageX = map_display_x_to_image<int>( displayX );
		imageY = map_display_y_to_image<int>( displayY );

		/* return 0 if pixel out of bounds */
		if ( imageX < 0 || imageY < 0 ||
			  imageX >= imageSizeX | imageY >= imageSizeY )
			{
			imageValue = 0;
			}
		else
			{
			switch ( quality )
				{
				case 0:
					//	printf("0");
					imageValue =	get_pixel_value( imageX, imageY );
					break;

				case 1:
					//	printf("1");

					imageValue =
						 get_pixel_value( imageX, imageY  ) +
						 get_pixel_value( imageX + incr50, imageY + incr50 );
					imageValue /= 2;
					break;
				case 2:
					//	printf("2");
					imageValue =
						 get_pixel_value( imageX         ,   imageY           ) +
						 get_pixel_value( imageX + incr50,   imageY + incr50  ) +
						 get_pixel_value( imageX + incr50,   imageY           ) +
						 get_pixel_value( imageX         , 	 imageY + incr50  ) ;
					imageValue /= 4;
					break;
				case 3:
					//	printf("3");
					/* return 0 if any pixel out of bounds */
					if ( (imageX + incr75) >= imageSizeX | (imageY + incr75) >= imageSizeY )
						{
						imageValue = 0;
						break;
						}

					/* return the image value */
					imageValue =
						 get_pixel_value( imageX         , imageY          ) +
						 get_pixel_value( imageX + incr50, imageY + incr50 ) +
						 get_pixel_value( imageX + incr50, imageY          ) +
						 get_pixel_value( imageX         , imageY + incr50	) +
						 get_pixel_value( imageX + incr25, imageY + incr25 ) +
						 get_pixel_value( imageX + incr75, imageY + incr25 ) +
						 get_pixel_value( imageX + incr25, imageY + incr75 ) +
						 get_pixel_value( imageX + incr75, imageY + incr75 );
					imageValue /= 8;

					break;
				}
			}
		}
	else
		{
		//thumb jpeg
		for ( x = displayX; x < displayX + 1; x += 0.25 )
			{
			for ( y = displayY; y < displayY + 1; y += 0.25 )
				{
				imageX = (int)(x * thumbRatio);
				imageY = (int)(y * thumbRatio);

				/* return 0 if pixel out of bounds */
				if ( imageX < 0 || imageY < 0 ||
					  imageX >= imageSizeX | imageY >= imageSizeY )
					{
					continue;
					}

				value = get_pixel_value( imageX, imageY );
				if ( value > imageValue ) imageValue = value;
				}
			}
		}

	/* if image value above contrast range return the max display value */
	if ( imageValue >= contrastMax )
		{
		return 0;
		}

	/* if image value below contrast range return zero */
	if ( imageValue <= contrastMin )
		{
		return maxDisplayValue;
		}

	/* otherwise scale the image value to the contrast range and return it */
	return maxDisplayValue - (diffimage_value_t) ( (double) maxDisplayValue *
			(double)( imageValue - contrastMin ) / (double) contrastRange );
	}


diffimage_value_t Diffimage::get_pixel_value ( int imageX, int  imageY )
	{
	int value = image->pixel( imageX,   imageY);

	if ( value >= overloadCutoff )
		{
		//overload is private data
		overloadFlag = 1;
		}
	return value;
	}

void Diffimage::set_display_center
	(
	const snap_align_t& displayX,
	const snap_align_t& displayY
	)

	{
	/* local variables */
	snap_align_t imageX;
	snap_align_t imageY;

	/* get image coordinates of new center */
	imageX = map_display_x_to_image<snap_align_t>( displayX );
	imageY = map_display_y_to_image<snap_align_t>( displayY );

	/* calculate image coordinates of new offset */
	offsetX = (imageX - displaySizeX * zoomRatio / 2);
	offsetY = (imageY - displaySizeY * zoomRatio / 2);
	}


void Diffimage::set_image_center
	(
	const snap_align_t& imageX,
	const snap_align_t& imageY
	)

	{
	/* calculate image coordinates of new offset */
	offsetX = (imageX - displaySizeX * zoomRatio / 2);
	offsetY = (imageY - displaySizeY * zoomRatio / 2);
	}



void Diffimage::set_zoom( double z )
	{
	/* local variables */
	snap_align_t imageCenterX;
	snap_align_t imageCenterY;

	/* save current display center */
	imageCenterX = map_display_x_to_image<snap_align_t>( displaySizeX / 2 );
	imageCenterY = map_display_y_to_image<snap_align_t>( displaySizeY / 2 );

	/* set zoom parameters */
	zoom = z;
	zoomRatio = sampling / zoom;

	/* update current ratio if needed */
	if ( mode == DIFFIMAGE_MODE_FULL )
		ratio = zoomRatio;

	/* restore display center */
	offsetX = (imageCenterX - displaySizeX * zoomRatio / 2);
	offsetY = (imageCenterY - displaySizeY * zoomRatio / 2);
	}



void Diffimage::set_mode
	(
	diffimage_mode_t m
	)

	{
	mode = m;

	if ( mode == DIFFIMAGE_MODE_FULL )
		ratio = zoomRatio;
	else
		ratio = thumbRatio;
	}



/*
 * set pixel (x, y, value) to value value (this can be 1/0 or a color number).
 */
void Diffimage::b_setpixel ( unsigned int x,
									  unsigned int y,
									  int value,
									  unsigned char * displaypointer )
	{
	unsigned char * coordinates;

	coordinates = displaypointer + ( y * displaySizeX + x) * 3;

	if ( x < displaySizeX &&
		  coordinates >= displaypointer &&
		  coordinates < displaypointer + displaySizeY * displaySizeX *3 )
		{
		*(coordinates) = (unsigned char)value;
		*(coordinates + 1) = (unsigned char)value;
		*(coordinates + 2) = (unsigned char)value;
		}
	}



/*
 * set character size
 */
void Diffimage::b_charsize	(unsigned int size)
	{
	int j;

	/* 5x9 font, bottom row first, left pixel in lsb */
	char_row fnt5x9[FNT_CHARS][FNT5X9_VBITS] = {
	/* */  {000000,000000,000000,000000,000000,000000,000000,000000,000000},
	/*!*/  {000000,000000,0x0004,000000,0x0004,0x0004,0x0004,0x0004,0x0004},
	/*"*/  {000000,000000,000000,000000,000000,000000,0x000a,0x000a,0x000a},
	/*#*/  {000000,000000,0x000a,0x000a,0x001f,0x000a,0x001f,0x000a,0x000a},
	/*$*/  {000000,000000,0x0004,0x000f,0x0014,0x000e,0x0005,0x001e,0x0004},
	/*%*/  {000000,000000,0x0018,0x0019,0x0002,0x0004,0x0008,0x0013,0x0003},
	/*&*/  {000000,000000,0x0016,0x0009,0x0015,0x0002,0x0005,0x0005,0x0002},
	/*'*/  {000000,000000,000000,000000,000000,0x0002,0x0004,0x0006,0x0006},
	/*(*/  {000000,000000,0x0008,0x0004,0x0002,0x0002,0x0002,0x0004,0x0008},
	/*)*/  {000000,000000,0x0002,0x0004,0x0008,0x0008,0x0008,0x0004,0x0002},
	/***/  {000000,000000,0x0004,0x0015,0x000e,0x001f,0x000e,0x0015,0x0004},
	/*+*/  {000000,000000,000000,0x0004,0x0004,0x001f,0x0004,0x0004,000000},
	/*,*/  {000000,0x0002,0x0004,0x0006,0x0006,000000,000000,000000,000000},
	/*-*/  {000000,000000,000000,000000,000000,0x001f,000000,000000,000000},
	/*.*/  {000000,000000,0x0006,0x0006,000000,000000,000000,000000,000000},
	/*-/-*/{000000,000000,000000,0x0001,0x0002,0x0004,0x0008,0x0010,000000},
	/*0*/  {000000,000000,0x000e,0x0011,0x0013,0x0015,0x0019,0x0011,0x000e},
	/*1*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0006,0x0004},
	/*2*/  {000000,000000,0x001f,0x0001,0x0001,0x000e,0x0010,0x0011,0x000e},
	/*3*/  {000000,000000,0x000e,0x0011,0x0010,0x000c,0x0010,0x0011,0x000e},
	/*4*/  {000000,000000,0x0008,0x0008,0x001f,0x0009,0x000a,0x000c,0x0008},
	/*5*/  {000000,000000,0x000e,0x0011,0x0010,0x0010,0x000f,0x0001,0x001f},
	/*6*/  {000000,000000,0x000e,0x0011,0x0011,0x000f,0x0001,0x0002,0x000c},
	/*7*/  {000000,000000,0x0001,0x0001,0x0002,0x0004,0x0008,0x0010,0x001f},
	/*8*/  {000000,000000,0x000e,0x0011,0x0011,0x000e,0x0011,0x0011,0x000e},
	/*9*/  {000000,000000,0x0006,0x0008,0x0010,0x001e,0x0011,0x0011,0x000e},
	/*:*/  {000000,000000,000000,0x0006,0x0006,000000,0x0006,0x0006,000000},
	/*;*/  {000000,0x0001,0x0002,0x0006,0x0006,000000,0x0006,0x0006,000000},
	/*<*/  {000000,000000,0x0008,0x0004,0x0002,0x0001,0x0002,0x0004,0x0008},
	/*=*/  {000000,000000,000000,000000,0x001f,000000,0x001f,000000,000000},
	/*>*/  {000000,000000,0x0002,0x0004,0x0008,0x0010,0x0008,0x0004,0x0002},
	/*?*/  {000000,000000,0x0004,000000,0x0004,0x0008,0x0010,0x0011,0x000e},
	/*@*/  {000000,000000,0x000e,0x0015,0x0015,0x0016,0x0010,0x0011,0x000e},
  /*A*/  {000000,000000,0x0011,0x0011,0x001f,0x0011,0x0011,0x000a,0x0004},
  /*B*/  {000000,000000,0x000f,0x0012,0x0012,0x000e,0x0012,0x0012,0x000f},
  /*C*/  {000000,000000,0x000e,0x0011,0x0001,0x0001,0x0001,0x0011,0x000e},
  /*D*/  {000000,000000,0x000f,0x0012,0x0012,0x0012,0x0012,0x0012,0x000f},
  /*E*/  {000000,000000,0x001f,0x0001,0x0001,0x0007,0x0001,0x0001,0x001f},
  /*F*/  {000000,000000,0x0001,0x0001,0x0001,0x0007,0x0001,0x0001,0x001f},
  /*G*/  {000000,000000,0x001e,0x0011,0x0011,0x0019,0x0001,0x0001,0x001e},
  /*H*/  {000000,000000,0x0011,0x0011,0x0011,0x001f,0x0011,0x0011,0x0011},
  /*I*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0004,0x000e},
  /*J*/  {000000,000000,0x000e,0x0011,0x0010,0x0010,0x0010,0x0010,0x0010},
  /*K*/  {000000,000000,0x0011,0x0009,0x0005,0x0003,0x0005,0x0009,0x0011},
  /*L*/  {000000,000000,0x001f,0x0001,0x0001,0x0001,0x0001,0x0001,0x0001},
  /*M*/  {000000,000000,0x0011,0x0011,0x0011,0x0015,0x0015,0x001b,0x0011},
  /*N*/  {000000,000000,0x0011,0x0011,0x0011,0x0019,0x0015,0x0013,0x0011},
  /*O*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x0011,0x0011,0x000e},
  /*P*/  {000000,000000,0x0001,0x0001,0x0001,0x000f,0x0011,0x0011,0x000f},
  /*Q*/  {000000,0x0018,0x000e,0x0015,0x0011,0x0011,0x0011,0x0011,0x000e},
  /*R*/  {000000,000000,0x0011,0x0009,0x0005,0x000f,0x0011,0x0011,0x000f},
  /*S*/  {000000,000000,0x000e,0x0011,0x0010,0x000e,0x0001,0x0011,0x000e},
  /*T*/  {000000,000000,0x0004,0x0004,0x0004,0x0004,0x0004,0x0004,0x001f},
  /*U*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x0011,0x0011,0x0011},
  /*V*/  {000000,000000,0x0004,0x0004,0x000a,0x000a,0x0011,0x0011,0x0011},
  /*W*/  {000000,000000,0x0011,0x001b,0x0015,0x0011,0x0011,0x0011,0x0011},
  /*X*/  {000000,000000,0x0011,0x0011,0x000a,0x0004,0x000a,0x0011,0x0011},
  /*Y*/  {000000,000000,0x0004,0x0004,0x0004,0x0004,0x000a,0x0011,0x0011},
  /*Z*/  {000000,000000,0x001f,0x0001,0x0002,0x0004,0x0008,0x0010,0x001f},
  /*[*/  {000000,000000,0x000e,0x0002,0x0002,0x0002,0x0002,0x0002,0x000e},
  /*\*/  {000000,000000,000000,0x0010,0x0008,0x0004,0x0002,0x0001,000000},
  /*]*/  {000000,000000,0x000e,0x0008,0x0008,0x0008,0x0008,0x0008,0x000e},
  /*^*/  {000000,000000,000000,000000,000000,000000,0x0011,0x000a,0x0004},
  /*_*/  {000000,000000,0x001f,000000,000000,000000,000000,000000,000000},
  /*`*/  {000000,000000,000000,000000,000000,0x0008,0x0004,0x000c,0x000c},
  /*a*/  {000000,000000,0x001e,0x0011,0x001e,0x0010,0x000e,000000,000000},
  /*b*/  {000000,000000,0x000d,0x0013,0x0011,0x0013,0x000d,0x0001,0x0001},
  /*c*/  {000000,000000,0x000e,0x0011,0x0001,0x0011,0x000e,000000,000000},
  /*d*/  {000000,000000,0x0016,0x0019,0x0011,0x0019,0x0016,0x0010,0x0010},
  /*e*/  {000000,000000,0x000e,0x0001,0x001f,0x0011,0x000e,000000,000000},
  /*f*/  {000000,000000,0x0004,0x0004,0x0004,0x000e,0x0004,0x0014,0x0008},
  /*g*/  {0x000e,0x0011,0x0016,0x0019,0x0011,0x0019,0x0016,000000,000000},
  /*h*/  {000000,000000,0x0011,0x0011,0x0011,0x0013,0x000d,0x0001,0x0001},
  /*i*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0006,000000,0x0004},
  /*j*/  {0x0006,0x0009,0x0008,0x0008,0x0008,0x0008,0x000c,000000,0x0008},
  /*k*/  {000000,000000,0x0009,0x0005,0x0003,0x0005,0x0009,0x0001,0x0001},
  /*l*/  {000000,000000,0x000e,0x0004,0x0004,0x0004,0x0004,0x0004,0x0006},
  /*m*/  {000000,000000,0x0015,0x0015,0x0015,0x0015,0x000b,000000,000000},
  /*n*/  {000000,000000,0x0011,0x0011,0x0011,0x0013,0x000d,000000,000000},
  /*o*/  {000000,000000,0x000e,0x0011,0x0011,0x0011,0x000e,000000,000000},
  /*p*/  {0x0001,0x0001,0x000d,0x0013,0x0011,0x0013,0x000d,000000,000000},
  /*q*/  {0x0010,0x0010,0x0016,0x0019,0x0011,0x0019,0x0016,000000,000000},
  /*r*/  {000000,000000,0x0001,0x0001,0x0001,0x0013,0x000d,000000,000000},
  /*s*/  {000000,000000,0x000f,0x0010,0x000e,0x0001,0x001e,000000,000000},
  /*t*/  {000000,000000,0x0008,0x0014,0x0004,0x0004,0x001f,0x0004,0x0004},
  /*u*/  {000000,000000,0x0016,0x0019,0x0011,0x0011,0x0011,000000,000000},
  /*v*/  {000000,000000,0x0004,0x000a,0x0011,0x0011,0x0011,000000,000000},
  /*w*/  {000000,000000,0x000a,0x0015,0x0015,0x0011,0x0011,000000,000000},
  /*x*/  {000000,000000,0x0011,0x000a,0x0004,0x000a,0x0011,000000,000000},
  /*y*/  {0x000e,0x0010,0x001e,0x0011,0x0011,0x0011,0x0011,000000,000000},
  /*z*/  {000000,000000,0x001f,0x0002,0x0004,0x0008,0x001f,000000,000000},
  /*{*/  {000000,000000,0x0008,0x0004,0x0004,0x0002,0x0004,0x0004,0x0008},
  /*|*/  {000000,000000,0x0004,0x0004,0x0004,000000,0x0004,0x0004,0x0004},
  /*}*/  {000000,000000,0x0002,0x0004,0x0004,0x0008,0x0004,0x0004,0x0002},
  /*~*/  {000000,000000,000000,000000,000000,000000,0x0008,0x0015,0x0002},
  /*DEL*/{000000,000000,0x001f,0x001f,0x001f,0x001f,0x001f,0x001f,0x001f},
};

/* 9x17 font, bottom row first, left pixel in lsb */

/* 13x25 font, bottom row first, left pixel in lsb */

    switch (size) {
    case FNT5X9:
	b_hchar = FNT5X9_HCHAR;
	b_hbits = FNT5X9_HBITS;
	b_vchar = FNT5X9_VCHAR;
	b_vbits = FNT5X9_VBITS;
	for (j = 0; j < FNT_CHARS; j++)
	    b_font[j] = &fnt5x9[j][0];
	break;
/*
    case FNT9X17:
	b_hchar = FNT9X17_HCHAR;
	b_hbits = FNT9X17_HBITS;
	b_vchar = FNT9X17_VCHAR;
	b_vbits = FNT9X17_VBITS;
	for (j = 0; j < FNT_CHARS; j++)
	    b_font[j] = &fnt9x17[j][0];
	break;
    case FNT13X25:
	b_hchar = FNT13X25_HCHAR;
	b_hbits = FNT13X25_HBITS;
	b_vchar = FNT13X25_VCHAR;
	b_vbits = FNT13X25_VBITS;
	for (j = 0; j < FNT_CHARS; j++)
	    b_font[j] = &fnt13x25[j][0];
	break;
*/
    default:
	xos_error("Unknown character size\n");
    }
	}



/*
 * put characater c at (x,y) rotated by angle with color b_value.
 */
void Diffimage::b_putc( unsigned int x,
								unsigned int y,
								int c,
								unsigned int c_angle,
								int b_value,
								unsigned char * displaypointer )
	{
	unsigned int i, j, k;
	char_row fc;

	j = c - ' ';

	if (j >= FNT_CHARS)
		return;			/* unknown (top-bit-set ?) character */

	for (i = 0; i < b_vbits; i++)
		{
		fc = *(b_font[j] + i);
		if (c == '_')
			{		/* treat underline specially */
			if (fc)
				{		/* this this the underline row ? */
				/* draw the under line for the full h_char width */
				for (k = (b_hbits - b_hchar) / 2; k < (b_hbits + b_hchar) / 2; k++)
					{
					switch (c_angle)
						{
						case 0:
							b_setpixel(x + k + 1, y + b_vbits - i, b_value,displaypointer);
							break;
						case 1:
							b_setpixel(x - i, y + k + 1, b_value,displaypointer);
							break;
						}
					}
				}
			}
		else
			{
			/* draw character */
			for (k = 0; k < b_hbits; k++)
				{
				if ((fc >> k) & 1)
					{
					switch (c_angle)
						{
						case 0:
							b_setpixel(x + k + 1, y + b_vbits - i, b_value,displaypointer);
							break;
						case 1:
							b_setpixel(x - i, y + k + 1, b_value,displaypointer);
							break;
						}
					}
				}
			}
		}
	}


/*
 * put text str at (x,y) with color b_value and rotation b_angle
 */
void Diffimage::b_put_text ( unsigned int x,
									  unsigned int y,
									  char *str,
									  unsigned int b_angle,
									  int b_value,
									  unsigned char * displaypointer )
	{
	if (b_angle == 1)
		x += b_vchar / 2;
	else
		y -= b_vchar / 2;
	switch (b_angle)
		{
		case 0:
			for (; *str; ++str, x += b_hchar)
				{
				b_putc(x, y, *str, b_angle, b_value, displaypointer);
				}
			break;
		case 1:
			for (; *str; ++str, y += b_hchar)
				{
				b_putc(x, y, *str, b_angle, b_value, displaypointer);
				}
			break;
		}
	}


void Diffimage::get_image_parameters ( float & wavelength,
													float & distance,
													float & displayOriginX,
													float & displayOriginY,
													float & jpegPixelSize,
													float & time,
													char * detectorTypeC64 )
	{
	float fullImagePixelSize;
	float beamCenterX;
	float beamCenterY;
	int size1;
	float fullsizeY;

	if (image->get_field ("DETECTOR"))
		{
		strncpy (detectorTypeC64, image->get_field ( "DETECTOR"), 63);
		detectorTypeC64[63] = 0;
		}
	else
		{
		strcpy(detectorTypeC64,"UNKNOWN");
		}

	wavelength     =       image->get_number ("WAVELENGTH");
	size1          = (int) image->get_number ("SIZE1");
	//size2        = (int) image->get_number ("SIZE2");
	distance       =       image->get_number ("DISTANCE");
	beamCenterX    =       image->get_number ("BEAM_CENTER_X");
	beamCenterY    =       image->get_number ("BEAM_CENTER_Y");
	time           =       image->get_number ("TIME");


	fullImagePixelSize =   image->get_number ("PIXEL_SIZE");

	jpegPixelSize = fullImagePixelSize * ratio;


	fullsizeY = size1 * fullImagePixelSize;

	displayOriginX = ( beamCenterY - fullsizeY ) + offsetX * fullImagePixelSize;
	displayOriginY = - beamCenterX + offsetY * fullImagePixelSize;
	}

xos_result_t Diffimage::send_jpeg_to_stream(FILE* stream, unsigned char* uncompressedBuffer, JINFO* jinfo)
{
	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;
	FILE * outfile;
	JSAMPROW row_pointer[1];
	int row_stride;

	// report error bad memory allocation
	if ( uncompressedBuffer == NULL )
	{
		xos_error( "Error allocating memory.");
		return XOS_FAILURE;
	}

	cinfo.err = jpeg_std_error( &jerr );
	jpeg_create_compress( &cinfo );

	jpeg_stdio_dest(&cinfo, stream);
	cinfo.image_width = jinfo->width; 	/* image width and height, in pixels */
	cinfo.image_height = jinfo->height;
	cinfo.input_components = jinfo->components;		/* # of color components per pixel */
	cinfo.in_color_space = jinfo->j_color_space; 	/* colorspace of input image */

	jpeg_set_defaults(&cinfo);
	jpeg_set_quality(&cinfo, jinfo->quality, TRUE);

	jpeg_start_compress(&cinfo, TRUE);
	row_stride = cinfo.image_width * cinfo.input_components;	/* JSAMPLEs per row in image_buffer */

	while ( cinfo.next_scanline < cinfo.image_height)
	{
		row_pointer[0] = &uncompressedBuffer[ cinfo.next_scanline * row_stride ];
		jpeg_write_scanlines(&cinfo, row_pointer, 1);
	}

	jpeg_finish_compress(&cinfo);
	jpeg_destroy_compress(&cinfo);

	return XOS_SUCCESS;

}
