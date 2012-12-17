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
/**
This file is modified from cbf_example.c and read_cbf.c written by Paul Ellis.

cbf_example.c: a simple program to write out parameters of CBF files
read_cbf.c 
read_cbf.h: program and header files for a simple function to read CBF files

For many applications, read_cbf.c and read_cbf.h may be used as-is and may also
be freely modified.

To compile the sample program:

(1) first make the CBF library files

cd cbf
make all
cd ..

(2)

cc -Icbf/include/ cbf_example.c read_cbf.c -lm -Lcbf/lib -lcbf -o cbf_example

There are 2 sample CBF data sets at:

  http://smb.slac.stanford.edu/~ellis/CBF_examples
  
NOTE IF INTEGRATING: the Q4 data set from 1-5 has a much larger 
                     anomalous signal than the mar345 data set from 9-1.

For more details about the library, refer to the documentation in cbf/doc.

 **/

#ifndef READ_CBF_H
#define READ_CBF_H

#ifdef __cplusplus

extern "C" {

#endif

#include "cbf_simple.h"

int img_read_cbf(img_handle img, const char* name);
int img_read_cbf_header(img_handle img, const char* name);


#ifdef __cplusplus

}

#endif

#endif /* READ_CBF_H */

