//
// Copyright 1997 Molecular Structure Corporation
//                9009 New Trails Drive
//                The Woodlands, TX, USA  77381
//
// The contents are unpublished proprietary source
// code of Molecular Structure Corporation
//
// All rights reserved
//
// DevErrCode.h     Initial author: Bob Daly
//
// The original version of this file was developed for the CDevxxx d*TREK
// classes which involve communication with an EPICS IOC.
// This file has been expanded to contain additional error codes and also
// a routine returning an string representation of an error code.
//
/*
 * RCS stuff:
 *   $Author: jwp $
 *   $Date: 2000/03/06 02:21:36 $
 *   $Header: /user4/jwp/DTREKREPOSITORY/DTREK/DTREK/src/DTTREK/DevErrCode.h,v 1.4 2000/03/06 02:21:36 jwp Exp $
 *   $Log: DevErrCode.h,v $
 * Revision 1.4  2000/03/06  02:21:36  jwp
 * Update street address to 9009 New Trails Drive.
 *
 * Revision 1.3  1998/12/10  17:08:42  tlh
 * Added a new err code, DEV_INVALIDSYNTAX
 *
 * Revision 1.2  1998/07/23  18:56:06  jwp
 * Add DEV_EVENT definition.
 *
 * Revision 1.1  1998/03/30  14:33:56  tlh
 * Initial commit of device error codes and routines
 *
 *   $Revision: 1.4 $
 */

#ifndef DEV_ERROR_CODE_H
#define DEV_ERROR_CODE_H

// success
#define DEV_SUCCESS         0  /* dev success  				*/
// errors
#define DEV_NOTCONNECTED    1  /* communications error to IOC		*/
#define DEV_INVALIDARG      2  /* invalid argument passed to dev calls	*/
#define DEV_INVALIDMODE     3  /* in wrong mode after dev call		*/
#define DEV_INVALIDSTATE    4  /* in wrong mode after dev call		*/
#define DEV_INVALIDSETPOINT 5  /* in wrong mode after dev call		*/
#define DEV_TIMEOUT         6  /* time out 				*/
#define DEV_IOCFAILED       7  /* IOC hardware failed			*/
#define DEV_INVALIDAXIS     8  /* invalid axis specified */
#define DEV_FAILED          9  /* general failure */
#define DEV_WRONGCOMMAND   10  /* wrong command received */
#define DEV_UNKNOWNERROR   11  /* unknown or unexpected error */
#define DEV_INVALIDTYPE    12  /* invalid hardware type specified */
#define DEV_COLLISION      13  /* in/through gonio collision area */
#define DEV_WARNING        14  /* non-fatal error/warning */
#define DEV_ABORTED        15
#define DEV_EVENT          16  /* event callback signaled return */
#define DEV_INVALIDSYNTAX  17  /* invalid command syntax */

#endif  /* DEV_ERROR_CODE_H */
