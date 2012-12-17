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
                                xos_socket.c

    This is the source code file associated with xos_socket.h.
    Together, these two files define an abstract data type,
    xos_socket, which is used to encapsulate the data and
    functions required for TCP sockets under UNIX and
    VMS/Multinet.


    Author:             Timothy M. McPhillips, SSRL.
    Last Revision:      March 4, 1998, by TMM.

****************************************************************/


/* xos_socket_t include file */
#include "xos_http.h"
#include <ctype.h>


#ifndef SHUT_WR
  #ifndef SD_RECEIVE
    #define SD_RECEIVE      0x00
    #define SD_SEND         0x01
    #define SD_BOTH         0x02
  #endif
  #define SHUT_WR SD_SEND
#endif

#ifndef MSG_WAITALL
#define MSG_WAITALL 0
#endif


/***************************************************************
 *
 * xos_http_init
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 * @param maxRequestSize
 * @param maxResponseSize
 ***************************************************************/
xos_result_t xos_http_init (
    xos_http_t * http,
    xos_size_t maxRequestSize,
    xos_size_t maxResponseSize
    ) {

    /* allocate memory for the http request buffer */
    http->maxRequestSize = maxRequestSize;
    http->requestBuffer = malloc( maxRequestSize );

    /* allocate memory for http response buffer */
    http->maxResponseSize = maxResponseSize;
    http->responseBuffer = malloc( maxResponseSize );

    /* initialize other data members */
    http->responseSize = 0;

    return XOS_SUCCESS;
}


/***************************************************************
 * xos_http_destroy
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_destroy (
    xos_http_t * http
    ) {

    /* free the memory for the http request buffer */
    free( http->requestBuffer );

    /* free the memory for hte http response buffer */
    free( http->responseBuffer );

    return XOS_SUCCESS;
}


/***************************************************************
 * xos_http_start_get
 * Open a socket connection and write out
 * the GET and host headers.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_start_get (
    xos_http_t *    http,
    const char *    host,
    int     port,
    const char *    request
    )

    {
    /* local variables */
    xos_socket_address_t    address;

    /*xos_http_parse_uri( "smb.slac.stanford.edu:80/index.html?hello.cgi",
            NULL, NULL, NULL );*/

    /* create an address structure pointing at the authentication server */
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host );
    xos_socket_address_set_port( &address, (xos_socket_port_t)port );

    /* create the socket to connect to authentication server */
    xos_socket_create_client( &http->socket );

    /* connect to the authentication server */
    xos_socket_make_connection( &http->socket, &address );

    /* create the request packet */
    sprintf( http->requestBuffer,
            "GET %s HTTP/1.1\n"
            "Host: %s:%d\n",
            request, host, port );

    /* send the HTTP request */
    xos_socket_write( &http->socket, http->requestBuffer, strlen(http->requestBuffer) );

    return XOS_SUCCESS;
}

/***************************************************************
 * xos_http_finish_get
 * Shuts down the outgoing socket and start waiting for the response.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_finish_get (
    xos_http_t * http
    )

    {
    int num = 0;

    /* shutdown the writing side of the socket */
    if ( SOCKET_SHUTDOWN(http->socket.clientDescriptor, SHUT_WR) != 0 ) {
        xos_error_sys("Error shutting down socket.");
        return XOS_FAILURE;
    }

    /* read the HTTP result */
#ifndef WIN32
    if ( (num = recv( http->socket.clientDescriptor, http->responseBuffer,
                http->maxResponseSize, MSG_WAITALL)) == -1 ) {
#else
    if ( (num = recv( http->socket.clientDescriptor, http->responseBuffer,
                http->maxResponseSize, 0)) == -1 ) {
#endif
            xos_error_sys("Error reading HTTP result.");
            return XOS_FAILURE;
        }

    http->responseSize = num;
    return XOS_SUCCESS;
    }



/***************************************************************
 * xos_http_start_get
 * Open a socket connection and write out
 * the GET and host headers.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_start_post (
    xos_http_t *    http,
    const char *    host,
    int     port,
    const char *    request
    )

    {
    /* local variables */
    xos_socket_address_t    address;

    /*xos_http_parse_uri( "smb.slac.stanford.edu:80/index.html?hello.cgi",
            NULL, NULL, NULL );*/

    /* create an address structure pointing at the authentication server */
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host );
    xos_socket_address_set_port( &address, (xos_socket_port_t)port );

    /* create the socket to connect to authentication server */
    xos_socket_create_client( &http->socket );

    /* connect to the authentication server */
    xos_socket_make_connection( &http->socket, &address );

    /* create the request packet */
    sprintf( http->requestBuffer,
            "POST %s HTTP/1.1\n"
            "Host: %s:%d\n",
            request, host, port );

    /* send the HTTP request */
    xos_socket_write( &http->socket, http->requestBuffer, strlen(http->requestBuffer) );

    return XOS_SUCCESS;
}


/***************************************************************
 * xos_http_finish_get
 * Shuts down the outgoing socket and start waiting for the response.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_finish_post (
    xos_http_t * http
    )

    {
    int num = 0;

    /* shutdown the writing side of the socket */
    if ( SOCKET_SHUTDOWN(http->socket.clientDescriptor, SHUT_WR) != 0 ) {
        xos_error_sys("Error shutting down socket.");
        return XOS_FAILURE;
    }

    /* read the HTTP result */
    if ( (num = recv( http->socket.clientDescriptor, http->responseBuffer,
                http->maxResponseSize, MSG_WAITALL)) == -1 ) {
            xos_error_sys("Error reading HTTP result.");
            return XOS_FAILURE;
        }

    http->responseSize = num;
    return XOS_SUCCESS;
    }


/***************************************************************
 * xos_http_write_header
 * Append a header line from a name/value pair.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 * @param name Name of the header
 * @param value Value of the header
 ***************************************************************/
xos_result_t xos_http_write_header (
    xos_http_t * http,
    const char * name,
    const char * value
    )

    {
    xos_socket_write( &http->socket, name, strlen(name) );
    xos_socket_write( &http->socket, ": ", 2 );
    xos_socket_write( &http->socket, value, strlen(value) );
    xos_socket_write( &http->socket, "\n", 1 );

    return XOS_SUCCESS;

    }

/***************************************************************
 * xos_http_finish_header
 * Ends the header section of the http message by appending an empty line
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 ***************************************************************/
xos_result_t xos_http_finish_header (
    xos_http_t *    http
    )

{
    xos_socket_write( &http->socket, "\n", 1 );
    return XOS_SUCCESS;

}



/***************************************************************
 * xos_http_write_body
 * Send the string buffer
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param http
 * @param buffer Array of chars
 * @param size of the buffer to send
 ***************************************************************/
xos_result_t xos_http_write_body (
    xos_http_t * http,
    const char * buffer,
    int bufferSize
    )

    {
    /* write the buffer to the http body */
    if ( xos_socket_write( &http->socket, buffer, bufferSize ) != XOS_SUCCESS ) {
        xos_error("Error writing http body.");
        return XOS_FAILURE;
    }

    return XOS_SUCCESS;
    }



/***************************************************************
 * xos_http_parse_uri
 * Extracts host, port and resource from the given URI
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param uri
 * @param host
 * @param port
 * @param resource
 ***************************************************************/
xos_result_t xos_http_parse_uri
    (
    const char * uri,
    char * host,
    char * port,
    char * resource
    )

    {
    char hostX[1024];
    char portX[1024];
    char resourceX[1024];

    sscanf( uri, "%s:%s/%s", hostX, portX, resourceX );

    puts(hostX);
    puts(portX);
    puts(resourceX);

    return XOS_SUCCESS;
    }

/***************************************************************
 * xos_http_decode
 * Converts the URI encoded string back to its original string.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param string
 * @param decodedString
 ***************************************************************/
xos_result_t xos_http_decode
    (
    const char * string,
    char * decodedString
    )

    {
    /* local variables */
    char *startPtr;
    char *endPtr;
    const char *srcPtr;
    char *destPtr;
    char localParameter[1024];
    char convertBuffer[3];
    unsigned int code;

    /* make a local copy of the parameter, replacing escaped
    * characters along the way */
    srcPtr = string;
    destPtr = localParameter;
    while ( *srcPtr != 0 ) {

        /* replace plus signs with spaces */
        if ( *srcPtr == '+' ) {

            *destPtr++ = ' ';
            srcPtr++;
            continue;

        /* replace hex-encoded characters */
        } else if ( *srcPtr == '%' ) {

            /* copy presumed characters to convert to a separate string */
            srcPtr++;
            convertBuffer[0] = *srcPtr++;
            convertBuffer[1] = *srcPtr++;
            convertBuffer[2] = 0;

            /* make sure next two characters are valid */
            if ( ! isHexDigit(convertBuffer[0]) || ! isHexDigit(convertBuffer[1]) ) {
                xos_error("Error decoding parameter value %%%s", convertBuffer);
                return XOS_FAILURE;
            }

            /* convert string to a character */
            if ( sscanf( convertBuffer, "%2x", &code ) == 1 ) {
                *destPtr++ = code;
            } else {
                xos_error("Error decoding parameter value %%%s.", convertBuffer);
                return XOS_FAILURE;
            }

        } else {
            /* just copy all other characters */
            *destPtr++ = *srcPtr++;
        }
    }

    /* terminate the local copy of the parameter */
    *destPtr = 0;

    /* remove leading spaces from the local copy of the parameter */
    startPtr = localParameter;
    while ( isspace(*startPtr) ) {
        startPtr ++;
    }

    /* remove trailing spaces from the local copy of the parameter */
    endPtr=localParameter + strlen(localParameter) - 1;
    while ( isspace(*endPtr) ) {
        *(endPtr --)= 0;
    }

    /* copy local parameter value back to decoded string */
    strcpy( decodedString, startPtr);

    return XOS_SUCCESS;
}


/***************************************************************
 * isHexDigit
 * Finds out if the given char is one of the valid chars representing a hex
 * Valid chars are 0-9, A-F and a-F.
 *
 * @return XOS_SUCCESS or XOS_FAILURE
 * @param c
 ***************************************************************/
xos_boolean_t isHexDigit( char c ) {

    return ( c >= '0' && c <= '9' ) ||
            ( c >= 'A' && c <= 'F' ) ||
            ( c >= 'a' && c <= 'f' );
}

/***************************************************************
 * Translates an http code to a string. The returned string must be
 * deallocated by the caller.
 * @return  String representing the http status. "Unknown http status" is returned
 *          if the status is unrecofnized. The caller is responsible for deallocating
 *          the return string. Can also return NULL if the memory allocation fails.
 * @param http status
 ***************************************************************/
char* xos_get_http_status(int status)
{
    int len = 50;
    char* str = (char*)malloc(sizeof(char)*len);

    /* Invaid char array */
    if (str == NULL )
        return str;

    /* initialize the array */
    memset(str, 0, sizeof(char)*len);


    switch (status) {
    case 202:
        strcpy(str, "Accepted");
        break;
    case 502:
        strcpy(str, "Bad Gateway");
        break;
    case 405:
        strcpy(str, "Method Not Allowed");
        break;
    case 400:
        strcpy(str, " Request");
        break;
    case 408:
        strcpy(str, "Time-Out");
        break;
    case 409:
        strcpy(str, "Conflict");
        break;
    case 201:
        strcpy(str, "Created");
        break;
    case 413:
        strcpy(str, "Request Entity Too Large");
        break;
    case 403:
        strcpy(str, "Forbidden");
        break;
    case 504:
        strcpy(str, "Gateway Timeout");
        break;
    case 410:
        strcpy(str, "Gone");
        break;
    case 500:
        strcpy(str, "Internal Server Error");
        break;
    case 411:
        strcpy(str, "Length Required");
        break;
    case 301:
        strcpy(str, "Moved Permanently");
        break;
    case 302:
        strcpy(str, "Temporary Redirect");
        break;
    case 300:
        strcpy(str, "Multiple Choices");
        break;
    case 204:
        strcpy(str, "No Content");
        break;
    case 406:
        strcpy(str, "Not Acceptable");
        break;
    case 203:
        strcpy(str, "Non-Authoritative Information");
        break;
    case 404:
        strcpy(str, "Not Found");
        break;
    case 501:
        strcpy(str, "Not Implemented");
        break;
    case 304:
        strcpy(str, "Not Modified");
        break;
    case 200:
        strcpy(str, "OK");
        break;
    case 206:
        strcpy(str, "Partial Content");
        break;
    case 402:
        strcpy(str, "Payment Required");
        break;
    case 412:
        strcpy(str, "Precondition Failed");
        break;
    case 407:
        strcpy(str, "Proxy Authentication Required");
        break;
    case 414:
        strcpy(str, "Request-URI Too Large");
        break;
    case 205:
        strcpy(str, "Reset Content");
        break;
    case 303:
        strcpy(str, "See Other");
        break;
    case 401:
        strcpy(str, "Unauthorized");
        break;
    case 503:
        strcpy(str, "Service Unavailable");
        break;
    case 415:
        strcpy(str, "Unsupported Media Type");
        break;
    case 305:
        strcpy(str, "Use Proxy");
        break;
    case 505:
        strcpy(str, "HTTP Version Not Supported");
        break;
    default:
        sprintf(str, "%s%d", "Unkown HTTP status code: ", status);
        break;

    }

    return str;
}

