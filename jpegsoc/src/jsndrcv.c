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

/*
 * jsndrec.c
 *
 */

#include <stdio.h>
#include "jpeglib.h"
#include <setjmp.h>
#include <xos.h>
#include <xos_socket.h>
#include "jpegsoc.h"
#define xos_socket_error strcmp(cinfo.err->msg_parm.s,"xos_failure")==0

xos_result_t send_jpeg_buffer ( xos_socket_t *socket,
				unsigned char **uncompressedBuffer,
				JINFO *jinfo,
				int protocol)
{
	return send_jpeg_buffer_to_stream(socket, JPEG_SOCKET_STREAM, uncompressedBuffer, jinfo, protocol);
}

xos_result_t send_jpeg_buffer_to_stream(void* stream, int stream_type,
				unsigned char **uncompressedBuffer,
				JINFO *jinfo,
				int protocol)
{
	xos_result_t result = XOS_SUCCESS;
	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;
	JSAMPROW row_pointer;	/* pointer to JSAMPLE row[s] */
	int row_stride;		/* physical row width in image buffer */
	JSAMPLE * image_buffer;
		
	bzero(&jerr, sizeof(struct jpeg_error_mgr));
	
	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cinfo);
	
	jpeg_stream_dest(&cinfo, stream, stream_type, protocol);
	cinfo.image_width = jinfo->width; 	/* image width and height, in pixels */
	cinfo.image_height = jinfo->height;
	cinfo.input_components = jinfo->components;		/* # of color components per pixel */
	cinfo.in_color_space = jinfo->j_color_space; 	/* colorspace of input image */

	jpeg_set_defaults(&cinfo);
	jpeg_set_quality(&cinfo, jinfo->quality, TRUE);

	jpeg_start_compress(&cinfo, TRUE);
	row_stride = cinfo.image_width * cinfo.input_components;	/* JSAMPLEs per row in image_buffer */
	image_buffer = (JSAMPLE *) (*uncompressedBuffer);
  
	row_pointer = image_buffer;
	while (cinfo.next_scanline < cinfo.image_height )
		{
		(void) jpeg_write_scanlines(&cinfo, &row_pointer, 1);
		if (xos_socket_error)
			{
			xos_error ("send_jpeg_buffer: xos_socket unable to send scanline\n");
			jpeg_destroy_compress(&cinfo);
			return XOS_FAILURE;
			}
		row_pointer += row_stride;
		}

	jpeg_finish_compress(&cinfo);
	if (xos_socket_error) 
		{
		xos_error ("send_jpeg_buffer: xos_socket unable to finish compression\n");
		jpeg_destroy_compress(&cinfo);
		return XOS_FAILURE;
		}
		 
	jpeg_destroy_compress(&cinfo);

	/* report result */	
	return result;	
	}

struct my_error_mgr
	{
	struct jpeg_error_mgr pub;	/* "public" fields */
	jmp_buf setjmp_buffer;	/* for return to caller */
	};

typedef struct my_error_mgr * my_error_ptr;

/*
 * Here's the routine that will replace the standard error_exit method:
 */

METHODDEF(void)
my_error_exit (j_common_ptr cinfo)
{
  /* cinfo->err really points to a my_error_mgr struct, so coerce pointer */
  my_error_ptr myerr = (my_error_ptr) cinfo->err;

  puts("Error decompressing jpeg image");

  /* Always display the message. */
  /* We could postpone this until after returning, if we chose. */
  (*cinfo->err->output_message) (cinfo);

  /* Return control to the setjmp point */
  longjmp(myerr->setjmp_buffer, 1);
}


xos_result_t receive_jpeg_buffer( xos_socket_t *socket,
											 unsigned char **uncompressedBuffer,
											 JINFO *jinfo )
	{
	struct jpeg_decompress_struct cinfo;
	struct my_error_mgr jerr;
	int row_stride;		/* physical row width in output buffer */
	int total_size;
	unsigned char * pointer;

	cinfo.err = jpeg_std_error(&jerr.pub);
	jerr.pub.error_exit = my_error_exit;
	if (setjmp(jerr.setjmp_buffer))
		{
		jpeg_destroy_decompress(&cinfo);
		return XOS_FAILURE;
		}

	jpeg_create_decompress(&cinfo);

	jpeg_sock_src(&cinfo, socket); 

	(void) jpeg_read_header(&cinfo, TRUE);
	if (xos_socket_error) 
		{
		xos_error ("receive_jpeg_buffer: xos_socket unable to read header\n");
		return XOS_FAILURE;
		}

	(void) jpeg_start_decompress(&cinfo);
	if (xos_socket_error) 
		{
		jpeg_destroy_decompress(&cinfo);
		xos_error ("receive_jpeg_buffer: xos_socket unable to start decompression\n");
		return XOS_FAILURE;
		}
	
	/*printf("output_components %d\n",cinfo.output_components);*/
	row_stride = cinfo.output_width * cinfo.output_components;
	total_size = row_stride * cinfo.output_height;
  
	if ((*uncompressedBuffer = (unsigned char *) malloc(total_size))==NULL)
  		{
		jpeg_destroy_decompress(&cinfo);
  		xos_error ("receive_jpeg_buffer. Couldn't allocate total memory for image.\n");
  		return XOS_FAILURE;
  		}
  
	/*printf ("receive_jpeg_buffer: allocated the uncompressed buffer\n");*/
	pointer = *uncompressedBuffer;
  
	jinfo->height = cinfo.output_height;
	jinfo->width = cinfo.output_width;
	jinfo->components = cinfo.output_components;

	/*printf ("receive_jpeg_buffer: assigned to jinfo\n");*/
  
	while (cinfo.output_scanline < cinfo.output_height) 
		{
		/*printf ("receive_jpeg_buffer: output_scanline %d; output_height %d\n",cinfo.output_scanline,cinfo.output_height);*/
		(void) jpeg_read_scanlines(&cinfo, &pointer, 1);
		/*printf ("receive_jpeg_buffer: after jpeg_read_scanlines, new output_scanline %d;",cinfo.output_scanline);*/
		if (xos_socket_error) 
			{
			jpeg_destroy_decompress(&cinfo);
			xos_error ("receive_jpeg_buffer: xos_socket unable to read a scanline\n");
			return XOS_FAILURE;
			}
		pointer+=row_stride;
		}

	/*printf ("receive_jpeg_buffer: done with read scanlines\n");*/
	
	(void) jpeg_finish_decompress(&cinfo);
	/*printf ("receive_jpeg_buffer: done with finish decompress\n");*/
	
	jpeg_destroy_decompress(&cinfo);
	
	return XOS_SUCCESS;
	}
