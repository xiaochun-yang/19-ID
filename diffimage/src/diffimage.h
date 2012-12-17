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

#ifndef DIFFIMAGE_H
#define DIFFIMAGE_H

/****************************************************************
                        diffimage.h

   This header file is included by diffimage.c and any source files
   that use Diffimage objects.

   A Diffimage object encapsulates the data and functions required
   to read an arbitray diffraction image from a file and create
   new images appropriate for display in various contexts.  For
   example, the image may be written to disk as a JPG file, or a
   Tk_PhotoImage may be written to memory for display on a Tcl/Tk
   canvas.

   The object does not provide direct access to the original
   diffraction image.  However, certain characteristics of the
   image may be queried, such as its dimensions, its original
   format, and any information in the header.

	The data stored within the object include a handle to a lower
	level object containing the original image and parameters that
	specify how the image will be manipulated as it is written,
	e.g., zoom and contrast information.

   Author:           Timothy M. McPhillips, SSRL.
   Date:					April 2, 1999 by TMM.

 * The following notice applies to code excerpted from gnuplot:
 * Copyright 1986 - 1993, 1998   Thomas Williams, Colin Kelley
 *
 * Permission to use, copy, and distribute this software and its
 * documentation for any purpose with or without fee is hereby granted,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.
****************************************************************/

#include <utility>
/* local include files */
#include <libimage.h>
#include <image_wrapper_polymorphic.h>


extern "C" {

#if defined TCL_PHOTO_SUPPORT
#include <tcl.h>
#include <tk.h>
#endif

#include <xos.h>
#include <xos_socket.h>
#include <jpegsoc.h>
}

#define JPEG_QUALITY 75

inline int min(int i, int j) { if ( i > j ) { return j;} else {return i;} }

/* type definitions */

typedef enum {
	DIFFIMAGE_FORMAT_NONE = 0,
   DIFFIMAGE_FORMAT_MAR = 1,
   DIFFIMAGE_FORMAT_CCD = 2
   } diffimage_format_t;

typedef enum {
   DIFFIMAGE_MODE_FULL,
   DIFFIMAGE_MODE_THUMB
   } diffimage_mode_t;


typedef int diffimage_value_t;

/* from gnuplot */

/* allow up to 16 bit width for character array */
typedef unsigned int char_row;
typedef char_row  * char_box;

#define FNT_CHARS   96      /* Number of characters in the font set */

#define FNT5X9 0
#define FNT5X9_VCHAR 11 /* vertical spacing between characters */
#define FNT5X9_VBITS 9 /* actual number of rows of bits per char */
#define FNT5X9_HCHAR 6 /* horizontal spacing between characters */
#define FNT5X9_HBITS 5 /* actual number of bits per row per char */
/* extern char_row GPFAR fnt5x9[FNT_CHARS][FNT5X9_VBITS]; */

#define FNT9X17 1
#define FNT9X17_VCHAR 21 /* vertical spacing between characters */
#define FNT9X17_VBITS 17 /* actual number of rows of bits per char */
#define FNT9X17_HCHAR 13 /* horizontal spacing between characters */
#define FNT9X17_HBITS 9 /* actual number of bits per row per char */
/* extern char_row GPFAR fnt9x17[FNT_CHARS][FNT9X17_VBITS]; */

#define FNT13X25 2
#define FNT13X25_VCHAR 31 /* vertical spacing between characters */
#define FNT13X25_VBITS 25 /* actual number of rows of bits per char */
#define FNT13X25_HCHAR 19 /* horizontal spacing between characters */
#define FNT13X25_HBITS 13 /* actual number of bits per row per char */
/* extern char_row GPFAR fnt13x25[FNT_CHARS][FNT13X25_VBITS]; */

/* class declaration for Diffimage */

typedef diffimage::libimage_base_wrapper * imagePtr_t;

class Diffimage
{
	public:
        // granularity of alignment between image & display pixels
        // needs to be compiled as double in tiling applications. (NKS 5/2008)
        typedef double snap_align_t;

	private:
	bool mSharedImage;

	/* properties of original image */
	imagePtr_t image;
	diffimage_format_t format;
	int imageSizeX;
	int imageSizeY;
	long int overloadCutoff;
	diffimage_value_t minImageValue;
	diffimage_value_t maxImageValue;

	/* properties of display image */
//	char filepath[400];
	int displaySizeX;
	int displaySizeY;
	int thumbSizeX;
	int thumbSizeY;
	snap_align_t offsetX;
	snap_align_t offsetY;
	diffimage_value_t	maxDisplayValue;
	diffimage_value_t contrastMin;
	diffimage_value_t contrastMax;
	diffimage_value_t contrastRange;
	double sampling;
	double zoom;
	double zoomRatio;
	double thumbRatio;
	double ratio;
	int samplingQuality;
	double jpegQuality;
	diffimage_mode_t mode;

	double incr25double;
	int incr25;
	int incr50;
	int incr75;
	xos_boolean_t overloadFlag;

	/* working buffer */
	unsigned char * workingBuffer;
	xos_size_t workingBufferSize;

	/* stuff from gnuplot */
	char_box b_font[FNT_CHARS]; 	/* the current font */
	unsigned int b_hchar;			/* width of characters */
	unsigned int b_hbits;			/* actual bits in char horizontally */
	unsigned int b_vchar;			/* height of characters */
	unsigned int b_vbits;			/* actual bits in char vertically */
	char_row fnt5x9[FNT_CHARS][FNT5X9_VBITS];
	/*char_row fnt9x17[FNT_CHARS][FNT9X17_VBITS];*/
	/*char_row fnt13x25[FNT_CHARS][FNT13X25_VBITS];*/

	void draw_markup(int sizeX, int sizeY, const void* buffer);

	public:

	/* constructors and destructors */
	Diffimage( diffimage_value_t maxValue=255, int dSizeX=400, int dSizeY=400,
		int tSizeX=100, int tSizeY=100 );

	Diffimage( diffimage::libimage_base_wrapper * image_,
			diffimage_value_t maxValue,
			int dSizeX,
			int dSizeY,
			int tSizeX,
			int tSizeY );

	~Diffimage( void );

	/* public member functions */
	// Caller of Diffimage class are reponsible for creating/loading image object.
	xos_result_t load( const char * filename );
	xos_result_t load_header( const char * filename );

	/* accessors for original image */

	const char* getFilePath() const { return image->getFilename().c_str(); }

	int get_image_size_x() const { return imageSizeX; }
	int get_image_size_y() const { return imageSizeY; }
	int get_min_image_value() const { return minImageValue; }
	int get_max_image_value() const { return maxImageValue; }
	diffimage_format_t get_image_format() const { return format; }

	/* accessors for display image */
	diffimage_value_t get_contrast_min() const { return contrastMin; }
	diffimage_value_t get_contrast_max() const { return contrastMax; }
	std::pair<int,int> get_display_size() const;

	/* mutators */
	void set_display_size( int dSizeX, int dSizeY );
	void set_zoom( double z );
	void set_mode( diffimage_mode_t m);
	void set_contrast_min( diffimage_value_t min )
		{ contrastMin = min; contrastRange = contrastMax - contrastMin; }
	void set_contrast_max( diffimage_value_t max )
		{ contrastMax = max; contrastRange = contrastMax - contrastMin; }
	void set_sampling_quality( int q ) { samplingQuality = q; }
	void set_jpeg_quality( double q ) { jpegQuality = q; }

	/* methods for manipulating image */
	void reset_view( void );
	unsigned char * get_working_buffer( xos_size_t size );

	diffimage_value_t get_display_value( int displayX,
													 int displayY,
													 int quality );
	diffimage_value_t get_pixel_value ( int imageX, int  imageY );

	void set_display_center( const snap_align_t& displayX, const snap_align_t& displayY );
	void set_image_center( const snap_align_t& imageX, const snap_align_t& imageY );

	/* methods to map pixel coordinates between the image and the display */
	template <typename map_t>
        map_t map_display_x_to_image( double displayX )
		{ return (int)(displayX * ratio + offsetX); }
	template <typename map_t>
        map_t map_display_y_to_image( double displayY )
		{ return (int)(displayY * ratio + offsetY); }
	double double_display_x_to_image( double displayX )
		{ return double(displayX) * ratio + double(offsetX); }
	double double_display_y_to_image( double displayY )
		{ return double(displayY) * ratio + double(offsetY); }

	/* methods for outputting image */
	unsigned char * get_display_buffer( void );
	xos_result_t create_uncompressed_buffer( unsigned char **uncompressedBuffer, JINFO *jinfo );
	static void free_uncompressed_buffer ( unsigned char *);

#if defined TCL_PHOTO_SUPPORT
 	xos_result_t create_Tk_photo( Tcl_Interp * interp,
											const char * photo );
#endif
 	// Only used by imgsrv WEB protocol, which is no longer used.
//	xos_result_t create_header_file( const char * filename );
 	// Moved to image_wrapper_polymorphic class.
	xos_result_t get_header(char* buf, int maxSize) { return image->get_header(buf, maxSize); }

	void draw_line( unsigned char * buffer, int start, int end,
		int step, unsigned char red, unsigned char blue, unsigned char green );

	void draw_horz_line ( unsigned char * buffer,int x0,int x1,int x, unsigned char red, unsigned char blue, unsigned char green);
	void draw_vert_line ( unsigned char * buffer,int y0,int y1,int x, unsigned char red, unsigned char blue, unsigned char green);
	void draw_zoom_box( unsigned char * buffer );

	/* functions for adding text to the image */
	void b_setpixel(unsigned int x, unsigned int y, int value,unsigned char * displaypointer);
	void b_charsize (unsigned int size);
	void b_putc (unsigned int x, unsigned int y, int c, unsigned int c_angle, int b_value,unsigned char *);
	void b_put_text(unsigned int x, unsigned int y, char *str,unsigned int b_angle, int b_value,unsigned char *);
	void get_image_parameters ( float & wavelength,
										 float & distance,
										 float & displayOriginX,
										 float & displayOriginY,
										 float & jpegPixelSize,
										 float & time,
										 char * detectorTypeC64 );
	xos_result_t send_jpeg_to_stream(FILE* stream, unsigned char* uncompressedBuffer, JINFO* info);
};

#endif
