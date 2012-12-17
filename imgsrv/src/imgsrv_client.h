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

#ifndef IMGSRV_CLIENT_H
#define IMGSRV_CLIENT_H

/**
 * @file imgsrv_client.h
 * Header file for image server client thread routine 
 * used by imgsrv_main.
 */

/**
 *
 * @func XOS_THREAD_ROUTINE incoming_client_handler( void* arg )
 *
 * @brief Thread routine to listen on a port for incoming socket connection.
 * This thread simply hands over each client connection
 * a new thread to perform tasks and goes back to listen on
 * the port again.
 *
 * This function is meant to be run as its own thread.  It opens 
 * a server socket on a predefined port and iteratively accepts 
 * new web client connections and starts new threads to handle 
 * the connections. It opens a new server socket for each connection 
 * and passes the socket to the new thread.  Only one thread
 * should execute this function.  It should never return.  Errors
 * result in the function exiting the entire program.
 * @param arg Thread argument, which, in this case, is a port number.
 * @return Thread return value.
 *
 */
XOS_THREAD_ROUTINE incoming_client_handler
	( 
	void* arg 
	);

/**
 * @def WEB_INTERFACE 0
 * Index for web interface thread
 */
#define WEB_INTERFACE 0

/**
 * @def GUI_INTERFACE 1
 * Index for Blu-Ice gui interface thread
 */
#define GUI_INTERFACE 1

/**
 * @def HTTP_INTERFACE 2
 * Index for HTTP interface thread
 */
#define HTTP_INTERFACE 2
	
#endif
