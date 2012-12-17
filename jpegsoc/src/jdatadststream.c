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

#define OUTPUT_BUF_SIZE  8192

/*
 * jdatadstsock.c
 *
 * Extension to JPEG library to allow compressed data to be
 * output to an output stream or xos_socket.
 *
 */

/* this is not a core library module, so it doesn't define JPEG_INTERNALS */

#include "xos.h"
#include "xos_socket.h"
#include "jconfig.h"
#include "jpeglib.h"
#include "jerror.h"
#include "jpegsoc.h"

//#define DEBUG_JPEGWRITE

#ifdef DEBUG_JPEGWRITE
static FILE* debugFile = NULL;
#endif


/* Expanded data destination object for stdio output */

typedef struct {
	struct jpeg_destination_mgr pub; /* public fields */
	void* stream;			/* target stream */
	int stream_type;
	JOCTET * buffer;		/* start of buffer */
} my_destination_mgr;

typedef my_destination_mgr * my_dest_ptr;

#define OUTPUT_BUF_SIZE  8192	/* choose an efficiently fwrite'able size */


/*
 * Initialize destination --- called by jpeg_start_compress
 * before any data is actually written.
 */

METHODDEF(void) init_destination (j_compress_ptr cinfo)
{
	my_dest_ptr dest = (my_dest_ptr) cinfo->dest;

	/* Allocate the output buffer --- it will be released when done with image */
	dest->buffer = (JOCTET *)
		 (*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_IMAGE,
						OUTPUT_BUF_SIZE * sizeof(JOCTET));

	dest->pub.next_output_byte = dest->buffer;
	dest->pub.free_in_buffer = OUTPUT_BUF_SIZE;


}


/*
 * Empty the output buffer --- called whenever buffer fills up.
 *
 * In typical applications, this should write the entire output buffer
 * (ignoring the current state of next_output_byte & free_in_buffer),
 * reset the pointer & count to the start of the buffer, and return TRUE
 * indicating that the buffer has been dumped.
 *
 * In applications that need to be able to suspend compression due to output
 * overrun, a FALSE return indicates that the buffer cannot be emptied now.
 * In this situation, the compressor will return to its caller (possibly with
 * an indication that it has not accepted all the supplied scanlines).  The
 * application should resume compression after it has made more room in the
 * output buffer.  Note that there are substantial restrictions on the use of
 * suspension --- see the documentation.
 *
 * When suspending, the compressor will back up to a convenient restart point
 * (typically the start of the current MCU). next_output_byte & free_in_buffer
 * indicate where the restart point will be if the current call returns FALSE.
 * Data beyond this point will be regenerated after resumption, so do not
 * write it out when emptying the buffer externally.
 */

METHODDEF(boolean) empty_output_buffer (j_compress_ptr cinfo)
{
	my_dest_ptr dest = (my_dest_ptr) cinfo->dest;
	
	if (dest->stream_type == JPEG_SOCKET_STREAM) {
	   if (xos_socket_write((xos_socket_t*)dest->stream, (char*)dest->buffer,OUTPUT_BUF_SIZE) != XOS_SUCCESS) {
		printf ("unable to write to the socket\n");
		sprintf(cinfo->err->msg_parm.s,"xos_failure");
		return FALSE;
	   }
	} else if (dest->stream_type == JPEG_FILE_STREAM) {
		if ( fwrite((char*)dest->buffer, sizeof(char), OUTPUT_BUF_SIZE, (FILE*)dest->stream) <= 0) {
			sprintf(cinfo->err->msg_parm.s,"xos_failure");
			return FALSE;
		}

	}


	dest->pub.next_output_byte = dest->buffer;
	dest->pub.free_in_buffer = OUTPUT_BUF_SIZE;

	return TRUE;
}


/*
 * Terminate destination --- called by jpeg_finish_compress
 * after all data has been written.  Usually needs to flush buffer.
 *
 * NB: *not* called by jpeg_abort or jpeg_destroy; surrounding
 * application must deal with any cleanup that should happen even
 * for error exit.
 */

METHODDEF(void)
term_destination_for_http (j_compress_ptr cinfo)
{
	my_dest_ptr dest = (my_dest_ptr) cinfo->dest;
	size_t datacount = OUTPUT_BUF_SIZE - dest->pub.free_in_buffer;


	/* Write any data remaining in the buffer */
	if (datacount <= 0)
		return;
	
	if (dest->stream_type == JPEG_SOCKET_STREAM) {
	  	if (xos_socket_write((xos_socket_t*)dest->stream, (char*)dest->buffer, datacount) != XOS_SUCCESS)
			sprintf(cinfo->err->msg_parm.s,"xos_failure");
	} else if (dest->stream_type == JPEG_FILE_STREAM) {
		if (fwrite((char*)dest->buffer, sizeof(char), datacount, (FILE*)dest->stream) <= 0)
			sprintf(cinfo->err->msg_parm.s,"xos_failure");
	}
	
}

METHODDEF(void)
term_destination (j_compress_ptr cinfo)
{
	my_dest_ptr dest = (my_dest_ptr) cinfo->dest;
	size_t datacount = OUTPUT_BUF_SIZE - dest->pub.free_in_buffer;
	char warning[OUTPUT_BUF_SIZE];

	/* Warn the client that the next buffer is the last */
	sprintf (warning,"stoc_END_JPEG_NEXT_BUFFER %d\0",datacount);

	if (dest->stream_type == JPEG_SOCKET_STREAM) {
		
		if (xos_socket_write((xos_socket_t*)dest->stream, warning, OUTPUT_BUF_SIZE) != XOS_SUCCESS)
			sprintf(cinfo->err->msg_parm.s,"xos_failure");
  
		/* Write any data remaining in the buffer */
		if (datacount > 0) {
			if (xos_socket_write((xos_socket_t*)dest->stream, (char*)dest->buffer, datacount) != XOS_SUCCESS)
				sprintf(cinfo->err->msg_parm.s,"xos_failure");
		}

	} else if (dest->stream_type == JPEG_FILE_STREAM) {

		if (fwrite(warning, sizeof(char), OUTPUT_BUF_SIZE, (FILE*)dest->stream) <= 0)
			sprintf(cinfo->err->msg_parm.s,"xos_failure");

		if (datacount > 0) {
			if (fwrite((char*)dest->buffer, sizeof(char), datacount, (FILE*)dest->stream) <= 0)
				sprintf(cinfo->err->msg_parm.s,"xos_failure");
		}
	}
}


/*
 * Prepare for output to a stdio stream.
 * The caller must have already opened the stream, and is responsible
 * for closing it after finishing compression.
 */

GLOBAL(void)
jpeg_stream_dest (j_compress_ptr cinfo, void* stream, int stream_type, int protocol)
{
	my_dest_ptr dest;

	/* The destination object is made permanent so that multiple JPEG images
	 * can be written to the same file without re-executing jpeg_stdio_dest.
	 * This makes it dangerous to use this manager and a different destination
	 * manager serially with the same JPEG object, because their private object
	 * sizes may be different.  Caveat programmer.
	 */
	if (cinfo->dest == NULL) {	/* first time for this JPEG object? */
		cinfo->dest = (struct jpeg_destination_mgr *)
				(*cinfo->mem->alloc_small) ((j_common_ptr) cinfo, JPOOL_PERMANENT,
				sizeof(my_destination_mgr));
	}

	dest = (my_dest_ptr) cinfo->dest;
	dest->pub.init_destination = init_destination;
	dest->pub.empty_output_buffer = empty_output_buffer;
	if (protocol == JPEG_HTTP_PROTOCOL) {
		dest->pub.term_destination = term_destination_for_http;
	} else {
		dest->pub.term_destination = term_destination;
	}
	dest->stream = stream;
	dest->stream_type = stream_type;

}

GLOBAL(void)
jpeg_sock_dest (j_compress_ptr cinfo, xos_socket_t* socket, int protocol)
{
	jpeg_stream_dest(cinfo, socket, JPEG_SOCKET_STREAM, protocol);
	
}
