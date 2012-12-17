#ifndef MSCVERBOSE_H
#define MSCVERBOSE_H

//
// Copyright 1998 Molecular Structure Corporation
//                3200 Research Forest Drive
//                The Woodlands, TX, USA  77381
//
// The contents are unpublished proprietary source
// code of Molecular Structure Corporation
//
// All rights reserved 
//
// MSCVerbose.h      Initial author: T.L.Hendrixson           Jan 1998
//  This file contains the definitions for verbose levels used with the 
//  RAXIS and communication classes.
//
/*
 * RCS stuff:
 *   $Author: tlh $
 *   $Date: 1998/04/28 15:27:16 $
 *   $Header: /user4/jwp/DTREKREPOSITORY/DTREK/DTREK/src/IO/MSCVerbose.h,v 1.2 1998/04/28 15:27:16 tlh Exp $
 *   $Log: MSCVerbose.h,v $
 * Revision 1.2  1998/04/28  15:27:16  tlh
 * Added documetation comments to file.
 *
 * Revision 1.1.1.1  1998/02/18  14:27:49  tlh
 * Initial commit of I/O classes.
 *
 *   $Revision: 1.2 $
 */ 
//+Description
//
// Included in this file are definitions of verbosity level that are used
// in the communication (serial, SCSI) classes and in others (R-AXIS).  
// It is assumed that the verbose level variable is a long int.  Levels are
// defined so that multiple levels may be specified by bitwise ORing (|) 
// the values together.
//
//+ToDo
//
//
/****************************************************************************
 *                               Include Files                              *
 ****************************************************************************/

/****************************************************************************
 *                                Constants                                 *
 ****************************************************************************/

   // No diagnostic output will be generated.
const long MSCVerboseNone       = 0;
   // A list of all routines involved in the call will be placed in the
   // status message member variable when an error condition occurs.
const long MSCVerboseTraceback  = 1;
   // Information concerning opening and closing connections to a port will
   // be printed to either standard output or standard error.
const long MSCVerboseConnection = 2;
   // Information concerning reads from a port will be printed to either
   // standard output or standard error.
const long MSCVerboseRead       = 4;
   // Information concerning writes to a port will be printed to either
   // standard output or standard error.
const long MSCVerboseWrite      = 8;
   // Warning messages will be written to standard error.
const long MSCVerboseWarning    = 16;
   // All types of diagnostic output will be generated.
const long MSCVerboseAll        = 0x7fffffff;

#endif  /* MSCVERBOSE_H */

