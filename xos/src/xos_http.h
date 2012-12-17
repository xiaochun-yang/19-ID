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
                                xos_http.h

    This is the include file associated with xos_socket.c.
    Together, these two files define an abstract data type,
    xos_socket, which is used to encapsulate the data and
    functions required for TCP sockets under all operating
    systems supported by XOS.


    Author:             Timothy M. McPhillips, SSRL.
    Last Revision:      January 16, 1997, by TMM.

****************************************************************/


#ifndef XOS_HTTP_H
#define XOS_HTTP_H

/**
 * @file xos_http.h
 * Header file for the C implementation of HTTP.
 * Used by the impClient of impersonation server (C version). 
 * It's a thin wrapper of the xos_socket for 
 * a client side HTTP connection.  
 *
 * Example:
 * @code
 
   int main(int argc, char *argv[]) 
   {

	char request[512] = "/";
	char body[102400] =	"This is a test body.\n"
				"Here is the next line.\n"
				"Here is the last line.\n";
	
	xos_http_t http;


	// initialize the http structure
	xos_http_init( &http, 512, 20480 );

	// start the http get request 
	xos_http_start_get( &http, "smblx7.slac.stanford.edu", 61000, request );
	
	//write the http request header
	xos_http_write_header( &http, "impCommand", "writeFile" );
	xos_http_finish_header( &http );

	// write the http request body
	xos_http_write_body(&http, body, strlen(body) );

	// finish the http request and read the response
	xos_http_finish_get( &http );

	//printf("Response size = %d\n", http.responseSize );

	puts( http.responseBuffer );
	
	return 0;
  }

 
 * @endcode

 */


#include "xos_socket.h"

#ifdef __cplusplus
extern "C" {
#endif


/**
 * @struct xos_http_struct
 * @brief xos_http data type.
 *
 */
struct xos_http_struct 
{

    /** Maximum number of bytes for the request line.
        that can be held by this structure. */
    xos_size_t      maxRequestSize;
    
    /** Maximum number of bytes for the entire response
        that can be held by this structure inclyding 
	response line, headers and body */
    xos_size_t      maxResponseSize;
    
    /** Actual response size */
    xos_size_t      responseSize;
    
    /** Buffer holding the request line. */
    char *          requestBuffer;
    
    /** Buffer holding the entire response including response line, headers and body. */
    char *          responseBuffer;
    
    /** The underlying socket for the HTTP connection. */
    xos_socket_t    socket;

};

/**
 * @typedef struct xos_http_struct xos_http_t
 * @brief Data type of the xos_http structure used by xos_http_* functions.
 */
typedef struct xos_http_struct xos_http_t;

/**
 * @fn xos_result_t xos_http_init(xos_http_t* http, xos_size_t maxRequestSize, xos_size_t maxResponseSize)
 * @brief Initializes the xos_http_t structure. Allocates the buffers for the request and response.
 *
 * This is the same as C++ constructor.
 * @param http The xos_http_t data structure to be initialized.
 * @param maxRequestSize Size of the request buffer used to hold the request line.
 * @param maxResponseSize Size of the response buffer used to hold the entire response including response line, headers and body.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_init (
        xos_http_t *    http,
        xos_size_t      maxRequestSize,
        xos_size_t      maxResponseSize
        );

/**
 * @fn xos_result_t xos_http_destroy(xos_http_t* http)
 * @brief Clean up the resources held by this data structure. 
 *
 * This is the same as C++ destructor. The xos_http_t object should not be used thereafter.
 * @param http The xos_http_t data structure to be destroyed.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_destroy (
        xos_http_t *    http
        );

/**
 * @fn xos_result_t xos_http_start_get(xos_http_t* http, const char* host, int port, const char* request)
 * @brief Writes out the request line to the output socket stream using HTTP GET method.
 *
 * HTTP request line has the following format:
 *
 * GET URI HTTP/1.1
 *
 * For example:
 * 
 * GET http://localhost:8084/store/info.html HTTP/1.1
 *
 * @param http The xos_http_t data structure for this connection.
 * @param host Name of the server.
 * @param port Port number of the server.
 * @param request The URI to be written in the request line.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_start_get (
        xos_http_t *    http,
        const char *    host,
        int             port,
        const char *    request
        );

/**
 * @fn xos_result_t xos_http_finish_get(xos_http_t* http)
 * @brief Closes the output socket stream and waits for the response.
 *
 * This method should be called after xos_http_start_get(), xos_http_write_header()
 * xos_http_finish_header(). xos_http_write_body() should not be called
 * since GET method does not allow request body.
 *
 * @param http The xos_http_t data structure for this connection.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_finish_get (
        xos_http_t *    http
        );

/**
 * @fn xos_result_t xos_http_start_post(xos_http_t* http, const char* host, int port, const char* request)
 * @brief Writes out the request line to the output socket stream using HTTP POST method.
 *
 * HTTP request line has the following format:
 *
 * POST URI HTTP/1.1
 *
 * For example:
 * 
 * POST http://localhost:8084/store/buy.cgi?item=boots1?price=52.0 HTTP/1.1
 *
 * @param http The xos_http_t data structure for this connection.
 * @param host Name of the server.
 * @param port Port number of the server.
 * @param request The URI to be written in the request line.
 */
xos_result_t xos_http_start_post (
        xos_http_t *    http,
        const char *    host,
        int             port,
        const char *    request
        );

/**
 * @fn xos_result_t xos_http_finish_post(xos_http_t* http)
 * @brief Closes the output socket stream and waits for the response.
 *
 * This method should be called after xos_http_start_post(), xos_http_write_header()
 * xos_http_finish_header(), and, optionally, xos_http_write_body().
 *
 * @param http The xos_http_t data structure for this connection.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_finish_post(
        xos_http_t *    http
        );

/**
 * @fn xos_result_t xos_http_write_body(xos_http_t* http, const char* buffer, int bufferSize)
 * @brief Write the body of the message.
 *
 * This method should be called (if it is called at all) 
 * after xos_http_start_post(), xos_http_write_header()
 * xos_http_finish_header(). It should not be called for the GET method.
 *
 * @param http The xos_http_t data structure for this connection.
 * @param buffer Buffer to be written as request body.
 * @param bufferSize of the buffer.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_write_body (
    xos_http_t * http,
    const char * buffer,
    int bufferSize
    );


/**
 * @fn xos_result_t xos_http_finish_header(xos_http_t* http)
 * @brief Writes an empty to indicate the end of headers.
 *
 * This method should be called after xos_http_write_header() and 
 * before xos_http_write_body(). It adds an empty line
 * after the header lines to signify that it is the end of the headers.
 *
 * @param http The xos_http_t data structure for this connection.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_finish_header (
    xos_http_t *    http
    );

/**
 * @fn xos_result_t xos_http_write_header(xos_http_t* http, const char* name, const char* value)
 * @brief Writes a header line.
 *
 * This method should be called before xos_http_start_get() or
 * xos_http_start_post() and before xos_http_finish_header().
 *
 * @param http The xos_http_t data structure for this connection.
 * @param name Header name.
 * @param value Header value.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_write_header (
    xos_http_t *    http,
    const char * name,
    const char * value
    );

/**
 * @fn xos_result_t xos_http_parse_uri(const char* uri, char* host, char* port, char* resource)
 * @brief Utility function to parse the request URI. 
 *
 * Extracts the host name, port number and the URI resource.
 *
 * @param uri The request URI to be parsed.
 * @param host Returned host name
 * @param port Returned port number
 * @param resource Returned URI resource
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_parse_uri
    (
    const char * uri,
    char * host,
    char * port,
    char * resource
    );


/**
 * @fn xos_result_t xos_http_decode(const char* string, char* decodedString)
 * @brief Utility function to decode the URI.
 *
 * @param string The encoded URI.
 * @param decodedString Returned decoded URI.
 * @return XOS_SUCCESS or XOS_FAILURE.
 */
xos_result_t xos_http_decode
    (
    const char * string,
    char * decodedString
    );


/**
 * @fn char* xos_get_http_status(int status)
 * @brief Translates an http code to a string. The returned string must be deallocated by the caller.
 *
 * @param status HTTP standard response code.
 * @return String representing the http status. "Unknown http status" is returned
 *          if the status is unrecofnized. The caller is responsible for deallocating
 *          the return string. Can also return NULL if the memory allocation fails.
 */
char* xos_get_http_status(int status);

xos_boolean_t isHexDigit( char c );

#ifdef __cplusplus
}
#endif


#endif
