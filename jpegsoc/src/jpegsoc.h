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

#ifndef JPEGSOC_H
#define JPEGSOC_H

#ifdef __cplusplus
extern "C" {
#endif
/*
 * jpegsoc.h
 *
 */
#include "xos_socket.h"
#include "jpeglib.h"

#define JPEG_HTTP_PROTOCOL 1
#define JPEG_DCS_PROTOCOL  2

#define JPEG_SOCKET_STREAM 1
#define JPEG_FILE_STREAM 2

typedef struct {
	int height;
	int width;
	int components;
	int quality;
	J_COLOR_SPACE j_color_space;
} JINFO;

void jpeg_sock_dest (j_compress_ptr cinfo, xos_socket_t* socket, int protocol);
void jpeg_stream_dest (j_compress_ptr cinfo, void* stream, int streamType, int protocol);

void jpeg_sock_src (j_decompress_ptr cinfo, xos_socket_t * socket);

xos_result_t receive_jpeg_buffer (
	xos_socket_t *socket, 
	unsigned char **uncompressedBuffer, 
	JINFO *jinfo
	);

xos_result_t send_jpeg_buffer (
	xos_socket_t* socket,
	unsigned char **uncompressedBuffer, 
	JINFO *jinfo,
	int protocol
	);
	
xos_result_t send_jpeg_buffer_to_stream (
	void* stream,
	int stream_type,
	unsigned char **uncompressedBuffer, 
	JINFO *jinfo,
	int protocol
	);

#ifdef __cplusplus
}
#endif

#endif
