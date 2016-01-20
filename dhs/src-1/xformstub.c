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

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <values.h>
#include "xform.h"
#include <limits.h>

double average_dark
       (unsigned int *dark,
        unsigned int  dark_size,
        unsigned int  dz_flag)
{ 

  return 1;
}



int is_dark
       (unsigned int *nonunf,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int  x,
        unsigned int  y)
{

  return 1;
}


int get_pedestals
       (unsigned int *raw,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int *nonunf,
        double       *pedestal_A,
        double       *pedestal_B,
        double       *pedestal_C,
        double       *pedestal_D, 
        unsigned int  dz_flag)
{

  return 0;  
}


int fix_pedestals 
       (unsigned int *raw, 
        unsigned int  xsize, 
        unsigned int  ysize, 
        int           dA,
        int           dB,
        int           dC,
        int           dD,
        unsigned int  saturation)
{


  return 0;
}

 
int subtract_dark 
    (unsigned int *im, 
     unsigned int *dkc, 
     unsigned int *out, 
     unsigned int  slow_max, 
     unsigned int  fast_max,
     unsigned int  saturation)
{

  return 0;
}

int dezinger_simple
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *dkc,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int *nonunf,
        unsigned int  saturation)
{
  return 0;
}


int dezinger_dark
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int  saturation)
{
  
  return 0;
}


int do_transform
       (unsigned int   *ccd_idata, 
        unsigned int   *ccd_odata,  
        unsigned int    bits,
        unsigned int    xsize,    
        unsigned int    ysize,        
        unsigned int    pedestal,       
        unsigned int    saturation,      
        unsigned int    saturation_mark,  
        unsigned int    border,         
        unsigned int   *nonunf,         
        unsigned int   *calfil,        
        unsigned int   *postnuf)        
{
  return 0;
}
