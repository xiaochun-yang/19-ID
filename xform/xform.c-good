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
#ifndef WIN32
#include <values.h>
#endif
#include <string.h>
#include "xform.h"
#include <limits.h>

  /* Calculate the pedestal level as the average of the dark pixels */

double average_dark
       (unsigned int *dark,
        unsigned int  dark_size,
        unsigned int  dz_flag)
{
  int count, pass, min, max;
  
  double avg, variance, sigma;
  

    /* Get the average */
    
  avg = 0;

  for (count = 0; count < dark_size; count++)

    avg += dark [count];
    
  avg /= dark_size;

  if (dz_flag == 0 || dark_size == 1)

    return avg;


    /* Get the variance and standard deviation */
    
  variance = 0;

  for (count = 0; count < dark_size; count++)
  
    variance += (dark [count] - avg) * (dark [count] - avg);
  
  variance /= (dark_size - 1);
  
  sigma = sqrt (variance);


    /* Reject outliers and recalculate the average */

  if (avg > 2 * sigma)
  
    min = avg - 2 * sigma + 0.5;
    
  else
  
    min = 0;
    
  max = avg + 2 * sigma + 0.5;
  
  avg = 0;
  
  pass = 0;

  for (count = 0; count < dark_size; count++)
  
    if (dark [count] >= min && dark [count] <= max)
    {
      avg += dark [count];
      
      pass++;
    }
    else
    
      dark [count] = 0;

  avg = avg / pass;

  return avg;
}


  /* Does this pixel lie at least DARK_DISTANCE from pixels in the taper? */

int is_dark
       (unsigned int *nonunf,
        unsigned int  xsize,
        unsigned int  ysize,
        unsigned int  x,
        unsigned int  y)
{
  unsigned int xo, yo;

  for (xo = x - DARK_DISTANCE; xo <= x + DARK_DISTANCE; xo += DARK_DISTANCE)
  
    for (yo = y - DARK_DISTANCE; yo <= y + DARK_DISTANCE; yo += DARK_DISTANCE)

      if (xo >= 0    && 
          yo >= 0    && 
          xo < xsize &&
          yo < ysize && nonunf [yo * xsize + xo] > 4)

        return 0;

  return 1;
}


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
        unsigned int  dz_flag)
{
  unsigned int dark [1024], dark_pixels, x, y, x_start, y_start, x_end, y_end;
 
  
    /* Get the pedestal for from pixels not covered by the taper */

  for (x_start = 0; x_start < xsize; x_start += xsize / 2)

    for (y_start = 0; y_start < ysize; y_start += xsize / 2)
    {
      x_end = x_start + xsize / 2;
      y_end = y_start + ysize / 2;
      
      dark_pixels = 0;
      
      for (x = x_start; x < x_end; x++)

        for (y = y_start; y < y_end; y++)
        {
          if (is_dark (nonunf, xsize, ysize, x, y))
          {
            dark [dark_pixels] = raw [y * xsize + x];
            
            dark_pixels++;
            
            if (dark_pixels >= 1024)
            {
              x = x_end;
              y = y_end;
            }
          }
        }
          
      if (x_start == 0 && y_start == 0)
      
        *pedestal_A = average_dark (dark, dark_pixels, dz_flag);
          
      if (x_start != 0 && y_start == 0)
      
        *pedestal_B = average_dark (dark, dark_pixels, dz_flag);
          
      if (x_start == 0 && y_start != 0)

        *pedestal_C = average_dark (dark, dark_pixels, dz_flag);
          
      if (x_start != 0 && y_start != 0)

        *pedestal_D = average_dark (dark, dark_pixels, dz_flag);
    }

  return 0;  
}


  /* Subtract the pedestal levels from each of the quadrants */

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
  int d, *pixel, *stop_pixel, val, x_start, y_start, x_end, y_end, y;

  for (x_start = 0; x_start < xsize; x_start += xsize / 2)

    for (y_start = 0; y_start < ysize; y_start += xsize / 2)
    {
      if (x_start == 0 && y_start == 0)
      
        d = dA;
          
      if (x_start != 0 && y_start == 0)
      
        d = dB;
          
      if (x_start == 0 && y_start != 0)

        d = dC;
          
      if (x_start != 0 && y_start != 0)

        d = dD;
          
      if (d)
      {
        y_end = y_start + ysize / 2;
      
        for (y = y_start; y < y_end; y++)
        {
          pixel = (int *) raw + xsize * y + x_start;
          
          stop_pixel = pixel + xsize / 2;
          
          while (pixel != stop_pixel)
          {
            if ((val = *pixel) < (int) saturation)
            {
              if ((val -= d) < 0)
              
                val = 0;
                
              else
              
                if (val > (int) saturation)
                
                  val = saturation;
                  
              *pixel = val;
            }
            
            pixel++;
          }
        }
      }
    }

  return 0;
}


  /* Subtract the dark image */
  
int subtract_dark 
    (unsigned int *im, 
     unsigned int *dkc, 
     unsigned int *out, 
     unsigned int  slow_max, 
     unsigned int  fast_max,
     unsigned int  saturation)
{
  unsigned int *stop;
  
  stop = im + slow_max * fast_max;
    
  while (im != stop)
  {
    if (*im >= saturation)
      
      *out = OVERFLOW_BASE;
   
    else
    
      if (*im > *dkc)
      
        *out = *im - *dkc;
        
      else
      
        *out = 0;
        
    im++;
    dkc++;
    out++;
  }

  return 0;
}


  /* Dezinger an image and subtract the dark assuming a 1:1 ratio */

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
  double dkcA, dkcB, dkcC, dkcD;
  double im0A, im0B, im0C, im0D;
  double im1A, im1B, im1C, im1D;
  
  int dA, dB, dC, dD;
  
  unsigned int count, *pixel0, *pixel1, *stop_pixel;
  
  int difference, limit;
  
  long sum;
  
  double average_difference;


    /* Get the dark image pedestal levels */


  get_pedestals (dkc, fast_max, slow_max, nonunf, 
                                     &dkcA, &dkcB, &dkcC, &dkcD, 0);


    /* If there is only one image just subtract the pedestals and dark */


  if ((im0 == NULL) != (im1 == NULL))
  {
    if (im0 == NULL)
    
      im0 = im1;
      
    get_pedestals (im0, fast_max, slow_max, nonunf,
                                       &im0A, &im0B, &im0C, &im0D, 1);

    dA = floor (im0A - dkcA + 0.5);
    dB = floor (im0B - dkcB + 0.5);
    dC = floor (im0C - dkcC + 0.5);
    dD = floor (im0D - dkcD + 0.5);
    
    fix_pedestals (im0, fast_max, slow_max, dA, dB, dC, dD, saturation);

    subtract_dark (im0, dkc, out, slow_max, fast_max, saturation);

    return 0;
  }

    /* (1) Subtract the pedestals */
    
  get_pedestals (im0, fast_max, slow_max, nonunf,
                                     &im0A, &im0B, &im0C, &im0D, 1);
  get_pedestals (im1, fast_max, slow_max, nonunf,
                                     &im1A, &im1B, &im1C, &im1D, 1);

  dA = floor (im0A - dkcA + 0.5);
  dB = floor (im0B - dkcB + 0.5);
  dC = floor (im0C - dkcC + 0.5);
  dD = floor (im0D - dkcD + 0.5);
  
  fix_pedestals (im0, fast_max, slow_max, dA, dB, dC, dD, saturation);

  dA = floor (im1A - dkcA + 0.5);
  dB = floor (im1B - dkcB + 0.5);
  dC = floor (im1C - dkcC + 0.5);
  dD = floor (im1D - dkcD + 0.5);

  fix_pedestals (im1, fast_max, slow_max, dA, dB, dC, dD, saturation);


    /* (2) Get the average difference between the images */
  
  sum = 0;
  
  count = 0;

  stop_pixel = im0 + slow_max * fast_max;

  for (pixel0 = im0, pixel1 = im1; pixel0 != stop_pixel; pixel0++, pixel1++)
  
    if (*pixel0 < saturation && *pixel1 < saturation)
    {
      sum += abs ((int) *pixel0 - (int) *pixel1);

      count++;
    }

  average_difference = sum / (2.0 * count);

  sum = 0;
  
  count = 0;

  limit = DEZINGER_SIGMA * (average_difference + 1);

  for (pixel0 = im0, pixel1 = im1; pixel0 != stop_pixel; pixel0++, pixel1++)

    if (*pixel0 < saturation && *pixel1 < saturation)

      if ((difference = abs ((int) *pixel0 - (int) *pixel1)) < limit)
      {
        sum += difference;

        count++;
      }

  average_difference = sum / (2.0 * count);
  

    /* (3) Dezinger and subtract the dark image */

  limit = DEZINGER_SIGMA * (average_difference + 1);


  while (im0 != stop_pixel)
  {
    if (*im0 < saturation && abs ((int) *im0 - (int) *im1) < limit)

      if (*im0 + *im1 > 2 * *dkc)
      
        *out = *im0 + *im1 - 2 * *dkc;
        
      else
      
        *out = 0;

    else
    
      if (*im1 < saturation)

        if (*im0 < *im1)
        
          if (*im0 > *dkc)
        
            *out = (*im0 - *dkc) * 2;
            
          else
          
            *out = 0;

        else
        
          if (*im1 > *dkc)

            *out = (*im1 - *dkc) * 2;
            
          else
          
            *out = 0;

      else
      
        if (*im0 < saturation)
        
          if (*im0 > *dkc)
        
            *out = (*im0 - *dkc) * 2;
            
          else
        
            *out = 0;

        else
          
          *out = saturation;
          
    im0++;
    im1++;
    dkc++;
    out++;
  }

  return 0;
}


  /* Dezinger a dark image */

int dezinger_dark
       (unsigned int *im0,
        unsigned int *im1,
        unsigned int *out,
        unsigned int  slow_max,
        unsigned int  fast_max,
        unsigned int  saturation)
{
  unsigned int count, *pixel0, *pixel1, *stop_pixel;
  
  int difference, limit;
  
  long sum;
  
  double average_difference;


    /* (1) Get the average difference between the images */
  
  sum = 0;
  count = 0;

  stop_pixel = im0 + slow_max * fast_max;

  for (pixel0 = im0, pixel1 = im1; pixel0 != stop_pixel; pixel0++, pixel1++)
  
    sum += abs ((int) *pixel0 - (int) *pixel1);

  average_difference = sum / (2.0 * slow_max * fast_max);

  sum = 0;
  
  limit = DEZINGER_SIGMA * (average_difference + 1);

  for (pixel0 = im0, pixel1 = im1; pixel0 != stop_pixel; pixel0++, pixel1++)

    if (*pixel0 < saturation && *pixel1 < saturation)

      if ((difference = abs ((int) *pixel0 - (int) *pixel1)) < limit)
      {
        sum += difference;

        count++;
      }

  average_difference = sum / (2.0 * count);


    /* (2) Dezinger */

  limit = DEZINGER_SIGMA * (average_difference + 1);

  while (im0 != stop_pixel)
  {
    if (*im0 < saturation && abs ((int) *im0 - (int) *im1) < limit)

      *out = (*im0 + *im1) / 2;

    else
    
      if (*im1 < saturation)

        if (*im0 < *im1)
        
          *out = *im0;

        else

          *out = *im1;

      else
      
        if (*im0 < saturation)
        
          *out = *im0;

        else
          
          *out = saturation;
          
    im0++;
    im1++;
    out++;
  }

  return 0;
}


  /* Image transform
  
     Note that the dark current is subtracted before this routine */

int do_transform
       (unsigned int   *ccd_idata, 
        unsigned int   *ccd_odata,  
        unsigned int    bits,             /* Bits in the input data          */
        unsigned int    xsize,            /* x size                          */
        unsigned int    ysize,            /* y size                          */
        unsigned int    pedestal,         /* Pedestal level                  */
        unsigned int    saturation,       /* Saturation level                */
        unsigned int    saturation_mark,  /* Saturation level in output      */
        unsigned int    border,           /* Border width                    */
        unsigned int   *nonunf,           /* Non-uniformity correction       */
        unsigned int   *calfil,           /* Calibration correction          */
        unsigned int   *postnuf)          /* Post non-uniformity correction  */
{
  double       scale;
  
  unsigned int count, *pixel, *out, *outo, *stop_pixel, code, nonuniformity;
  
  unsigned int in, k, l, m, n, o, p, q, r, s, t, u, x, y;
  
  int          repeat;


    /* Transformation */

  scale = pow (0.5, CALFIL_FRACTION);
  
  memset (ccd_odata, 0, xsize * ysize * sizeof (unsigned int));
    
  stop_pixel = ccd_idata + xsize * ysize;
  
  for (pixel = ccd_idata; pixel < stop_pixel;)
  {
    code = *calfil++;
    
    repeat = ((int) code >> 8) & 0x00ff;

    code = code & 0x00ff;

    if (!code)
    {
      pixel += (unsigned int) repeat + 1;
      
      nonunf += (unsigned int) repeat + 1;
    }
    else
    {
      static int count = 0;
        
      out = ccd_odata + calfil [0] + calfil [1] * xsize;
      
      calfil += 2;
      
      in = *pixel++;

      nonuniformity = *nonunf++;
      
            
        /* Distribute unsaturated and saturated pixels */

      switch (code)
      {
          /* in -> (x, y) */
          
        case 0x0011:
        
          if (in < saturation)
          
            *out += (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

          else

            *out = saturation_mark;
            
          break;
          
          
          /* in ->     m  (x, y) + 
                  (1 - m) (x, y + 1) */
          
        case 0x0012:
    
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            o = (in * *calfil + CALFIL_ROUND) / CALFIL_SCALE;
            
            calfil++;
  
            out [0]     += o;
            out [xsize] += in - o;
          }
          else
          {
            calfil++;
  
            out [0]     =
            out [xsize] = saturation_mark;
          }
  
          break;
            
            
          /* in ->     m  (x,     y) + 
                  (1 - m) (x + 1, y) */
  
        case 0x0021:
  
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            o = (in * *calfil + CALFIL_ROUND) / CALFIL_SCALE;
            
            calfil++;
  
            out [0] += o;
            out [1] += in - o;
          }
          else
          {
            calfil++;
  
            out [0] =
            out [1] = saturation_mark;
          }
  
          break;
          
  
          /* in -> m / (1 + m + n) (x, y)     + 
                   1 / (1 + m + n) (x, y + 1) + 
                   n / (1 + m + n) (x, y + 2) */
          
        case 0x0013: 
            
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            m = calfil [0];
            n = calfil [1];
  
            calfil += 2;
            
            l = CALFIL_SCALE + m + n;
            
            o = ( in * m                 + (l >> 1)) / l;
            p = ((in << CALFIL_FRACTION) + (l >> 1)) / l;
  
            out [0]         += o;
            out [xsize]     += p;
            out [xsize * 2] += in - o - p;
          }
          else
          {
            calfil += 2;
  
            out [0]         =
            out [xsize]     =
            out [xsize * 2] = saturation_mark;
          }
            
          break;
          
  
          /* in -> m / (1 + m + n) (x    , y) + 
                   1 / (1 + m + n) (x + 1, y) + 
                   n / (1 + m + n) (x + 2, y) */
  
        case 0x0031:
  
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            m = calfil [0];
            n = calfil [1];
            
            calfil += 2;
            
            l = CALFIL_SCALE + m + n;
            
            o = ( in * m                 + (l >> 1)) / l;
            p = ((in << CALFIL_FRACTION) + (l >> 1)) / l;
  
            out [0] += o;
            out [1] += p;
            out [2] += in - o - p;
          }
          else
          {
            calfil += 2;
            
            out [0] =
            out [1] =
            out [2] = saturation_mark;
          }
  
          break;
          
  
          /* in ->      m  *      n  (x,     y)     + 
                        m  * (1 - n) (x,     y + 1) + 
                   (1 - m) *      n  (x + 1, y)     +
                   (1 - m) * (1 - n) (x + 1, y + 1)
                     
                   Repeat along +x */
  
        case 0x0022:
        
          outo = out + xsize;
  
          while (repeat >= 0)
          {
            if (in < saturation)
            {
              in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

              m = calfil [0];
              n = calfil [1];
            
              o = (in * m + CALFIL_ROUND) / CALFIL_SCALE;  /* in * m  */
              p = (in * n + CALFIL_ROUND) / CALFIL_SCALE;  /* in * n  */
              q = (o  * n + CALFIL_ROUND) / CALFIL_SCALE;  /* in * mn */
  
              out  [0] += q;
              out  [1] += p - q;
              outo [0] += o - q;
              outo [1] += in - o - p + q;
            }
            else
            {
              out  [0] =
              out  [1] =
              outo [0] =
              outo [1] = saturation_mark;
            }
              
            calfil += 2;
              
            in = *pixel++;
            
            nonuniformity = *nonunf++;

            out++;
            outo++;
              
            repeat--;
          }
            
          pixel--;
          
          nonunf--;
  
          break;
  
          
          /* in ->      m  *  n / (1 + n + o) (x,     y)     + 
                        m       / (1 + n + o) (x,     y + 1) + 
                        m  *  o / (1 + n + o) (x,     y + 2) + 
                   (1 - m) *  n / (1 + n + o) (x + 1, y)     +
                   (1 - m)      / (1 + n + o) (x + 1, y + 1) +
                   (1 - m) *  o / (1 + n + o) (x + 1, y + 2) */
  
        case 0x0023:
  
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            m = calfil [0];
            n = calfil [1];
            o = calfil [2];
            
            calfil += 3;
  
            l = CALFIL_SCALE + n + o;
  
            p = (in * m + CALFIL_ROUND) / CALFIL_SCALE;
            q =  in - p;
            r = ((p << CALFIL_FRACTION) + (l >> 1)) / l;
            s = ((q << CALFIL_FRACTION) + (l >> 1)) / l;
            t = (r * n + CALFIL_ROUND) / CALFIL_SCALE;
            u = (s * n + CALFIL_ROUND) / CALFIL_SCALE;
  
            out [0]             += t;
            out [1]             += u;
            out [xsize]         += r;
            out [xsize + 1]     += s;
            out [2 * xsize]     += p - t - r;
            out [2 * xsize + 1] += q - u - s;
          }
          else
          {
            calfil += 3;
  
            out [0]             =
            out [1]             =
            out [xsize]         =
            out [xsize + 1]     =
            out [2 * xsize]     =
            out [2 * xsize + 1] = saturation_mark;
          }
  
          break;
            
          
          /* in ->      o  * m / (1 + m + n) (x    , y)     + 
                        o      / (1 + m + n) (x + 1, y)     + 
                        o  * n / (1 + m + n) (x + 2, y)     + 
                   (1 - o) * m / (1 + m + n) (x    , y + 1) +
                   (1 - o)     / (1 + m + n) (x + 1, y + 1) +
                   (1 - o) * n / (1 + m + n) (x + 2, y + 1) */
  
        case 0x0032:
        
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            m = calfil [0];
            n = calfil [1];
            o = calfil [2];
            
            calfil += 3;
  
            l = CALFIL_SCALE + m + n;
  
            p = (in * o + CALFIL_ROUND) / CALFIL_SCALE;
            q =  in - p;
            r = ((p << CALFIL_FRACTION) + (l >> 1)) / l;
            s = ((q << CALFIL_FRACTION) + (l >> 1)) / l;
            t = (r * m + CALFIL_ROUND) / CALFIL_SCALE;
            u = (s * m + CALFIL_ROUND) / CALFIL_SCALE;
  
            out [0]         += t;
            out [1]         += r;
            out [2]         += p - t - r;
            out [xsize]     += u;
            out [xsize + 1] += s;
            out [xsize + 2] += q - u - s;
          }
          else
          {
            calfil += 3;
  
            out [0]         =
            out [1]         =
            out [2]         =
            out [xsize]     =
            out [xsize + 1] =
            out [xsize + 2] = saturation_mark;
          }
  
          break;
          
  
          /* in -> m / (1 + m + n) * o / (1 + o + p) (x    , y)     + 
                   m / (1 + m + n)     / (1 + o + p) (x    , y + 1) + 
                   m / (1 + m + n) * p / (1 + o + p) (x    , y + 2) + 
                   1 / (1 + m + n) * o / (1 + o + p) (x + 1, y)     + 
                   1 / (1 + m + n)     / (1 + o + p) (x + 1, y + 1) + 
                   1 / (1 + m + n) * p / (1 + o + p) (x + 1, y + 2) + 
                   n / (1 + m + n) * o / (1 + o + p) (x + 2, y)     + 
                   n / (1 + m + n)     / (1 + o + p) (x + 2, y + 1) + 
                   n / (1 + m + n) * p / (1 + o + p) (x + 2, y + 2) */
                     
        case 0x0033:
          
          if (in < saturation)
          {
            in = (in * nonuniformity + NONUNF_ROUND) / NONUNF_SCALE;

            m = calfil [0];
            n = calfil [1];
            o = calfil [2];
            p = calfil [3];
          
            calfil += 4;
            
            k = CALFIL_SCALE + m + n;
            l = CALFIL_SCALE + o + p;
  
            q = ((in * o)               + (l >> 1)) / l;
            r = ( q  * m                + (k >> 1)) / k;
            s = ((q << CALFIL_FRACTION) + (k >> 1)) / k;
  
            out [0] += r;
            out [1] += s;
            out [2] += q - r - s;
            
            out += xsize;
            
            q = ((in << CALFIL_FRACTION) + (l >> 1)) / l;
            r = (  q  * m                + (k >> 1)) / k;
            s = (( q << CALFIL_FRACTION) + (k >> 1)) / k;
  
            out [0] += r;
            out [1] += s;
            out [2] += q - r - s;
            
            out += xsize;
            
            q = ((in * p)               + (l >> 1)) / l;
            r = ( q  * m                + (k >> 1)) / k;
            s = ((q << CALFIL_FRACTION) + (k >> 1)) / k;
  
            out [0] += r;
            out [1] += s;
            out [2] += q - r - s;
          }
          else
          {
            calfil += 4;
            
            out [0] =
            out [1] =
            out [2] = saturation_mark;
            
            out += xsize;

            out [0] =
            out [1] =
            out [2] = saturation_mark;
            
            out += xsize;
            
            out [0] =
            out [1] =
            out [2] = saturation_mark;
          }
            
          break;
            
        default:
          
          return 1;
      }
    }
  }
  

    /* Post-transform non-uniformity correction */

  if (sizeof (unsigned int) * CHAR_BIT >= bits + POSTNUF_BITS)
    
    while (*postnuf != POSTNUF_END)
    {
      if (postnuf [0] < xsize && postnuf [1] < ysize)
      {
        pixel = ccd_odata + postnuf [1] * xsize + postnuf [0];
        
        *pixel = (*pixel * postnuf [2] + POSTNUF_ROUND) / POSTNUF_SCALE;
      }
        
      postnuf += 3;
    }
  else
  {
    scale = 1.0 / POSTNUF_SCALE;

    while (*postnuf != POSTNUF_END)
    {
      if (postnuf [0] < xsize && postnuf [1] < ysize)
      {
        pixel = &ccd_odata [postnuf [1] * xsize + postnuf [0]];

        *pixel = *pixel * (postnuf [2] * scale) + 0.5;
      }
      
      postnuf += 3;
    }
  }
  

    /* Mark saturated pixels */

  stop_pixel = ccd_odata + xsize * ysize;

  for (pixel = ccd_odata; pixel != stop_pixel; pixel++)
  {
    *pixel += pedestal;
    
    if (*pixel >= saturation_mark)
    
      *pixel = saturation_mark;
  }


    /* Set the border between modules to 0 */

  if (border > 0)
  {
    for (y = 0; y < ysize; y++) 
  
      for (x = xsize / 2 - border / 2; x <= xsize / 2 + border / 2; x++)
    
        ccd_odata [y * xsize + x] = 0;

    for (y = ysize / 2 - border / 2; y <= ysize / 2 + border / 2; y++)
  
      for (x = 0; x < xsize; x++)
    
        ccd_odata [y * xsize + x] = 0;
  }

  return 0;
}
