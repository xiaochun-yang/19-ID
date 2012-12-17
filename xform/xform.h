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

#ifdef __cplusplus
extern "C" {
#endif

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


  /* Calculate the pedestal level as the average of the dark pixels */

double average_dark
       (unsigned int *dark,
        unsigned int  dark_size,
        unsigned int  dz_flag);


  /* Does this pixel lie at least DARK_DISTANCE from pixels in the taper? */

int is_dark
       (unsigned int *nonunf,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int  x,
        unsigned int  y);


  /* Get the pedestal levels for each of the quadrants */

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


  /* Subtract the pedestal levels from each of the quadrants */

int fix_pedestals 
       (unsigned int *raw, 
        unsigned int  xsize, 
        unsigned int  ysize, 
        int           dA,
        int           dB,
        int           dC,
        int           dD,
        unsigned int  saturation);


  /* Subtract the dark image */
  
int subtract_dark 
    (unsigned int *im, 
     unsigned int *dkc, 
     unsigned int *out, 
     unsigned int  slow_max, 
     unsigned int  fast_max,
     unsigned int  saturation);


  /* Dezinger an image and subtract the dark assuming a 1:1 ratio */

int dezinger_simple
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *dkc,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int *nonunf,
        unsigned int  saturation);


  /* Dezinger a dark image */

int dezinger_dark
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int  saturation);


  /* Image transform
  
     Note that the dark current is subtracted before this routine */

int do_transform
       (unsigned int   *ccd_idata, 
        unsigned int   *ccd_odata,  
        unsigned int    bits,             /* Bits in the input data          */
        unsigned int    xsize,            /* x size                          */
        unsigned int    ysize,            /* y size                          */
        unsigned int    pedestal,         /* Pedestal level (CCD_PEDESTAL)   */
        unsigned int    saturation,       /* Saturation level                */
        unsigned int    saturation_mark,  /* Saturation level in output      */
        unsigned int    border,           /* Border width   (CCD_(NO)BORDER) */
        unsigned int   *nonunf,           /* Non-uniformity correction       */
        unsigned int   *calfil,           /* Calibration correction          */
        unsigned int   *postnuf);         /* Post non-uniformity correction  */

#ifdef __cplusplus
}
#endif

#endif /* XFORM_H */
