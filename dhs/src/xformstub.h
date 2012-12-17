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

#ifndef XFORM_H
#define XFORM_H

#define NONUNF_BITS      (16)
#define NONUNF_FRACTION  (12)
#define NONUNF_SCALE     (1 << NONUNF_FRACTION)
#define NONUNF_ROUND     (1 << (NONUNF_FRACTION - 1))
#define CALFIL_FRACTION  (15)
#define CALFIL_SCALE     (1 << CALFIL_FRACTION)
#define CALFIL_ROUND     (1 << (CALFIL_FRACTION - 1))
#define POSTNUF_BITS     (16)
#define POSTNUF_FRACTION (12)
#define POSTNUF_SCALE    (1 << POSTNUF_FRACTION)
#define POSTNUF_ROUND    (1 << (POSTNUF_FRACTION - 1))
#define POSTNUF_END      (65535)
#define DARK_DISTANCE    (20)
#define  OVERFLOW_BASE   (0x01ffff)
#define DEZINGER_SIGMA   (8)


double average_dark
       (unsigned int *dark,
        unsigned int  dark_size,
        unsigned int  dz_flag);

int is_dark
       (unsigned int *nonunf,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int  x,
        unsigned int  y);

int get_pedestals
       (unsigned int *raw,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int *nonunf,
        double       *pedestal_A,
        double       *pedestal_B,
        double       *pedestal_C,
        double       *pedestal_D, 
        unsigned int  dz_flag);


int fix_pedestals 
       (unsigned int *raw, 
        unsigned int  xsize, 
        unsigned int  ysize, 
        int           dA,
        int           dB,
        int           dC,
        int           dD,
        unsigned int  saturation);

  
int subtract_dark 
    (unsigned int *im, 
     unsigned int *dkc, 
     unsigned int *out, 
     unsigned int  slow_max, 
     unsigned int  fast_max,
     unsigned int  saturation);


int dezinger_simple
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *dkc,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int *nonunf,
        unsigned int  saturation);



int dezinger_dark
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int  saturation);


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
        unsigned int   *postnuf);


#endif /* XFORM_H */
