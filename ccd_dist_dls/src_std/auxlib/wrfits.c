#ifndef vms
#include <malloc.h>
#endif
#include "filec.h"

#ifdef HAVE_FITSIO
#include "cfitsio.h"
#endif


int wrfits ( char* filename, char* head, char* array, 
	    int naxis, int* axis, int type)
     
#ifdef HAVE_FITSIO
{
  int naxx;
  int group,fpixel,nelm,i,j,jvals[3];
  
  int unit, status, anyflg;
  int rwstat, bksize;
  int simple, bitpix;
  int pcount, gcount, extend;
  int nkeys;
  int nspace;
  char errtxt[FITS_CLEN_ERRMSG];
  
  char comment[73];
  char keyword[80], value[80];
  char s[80], s1[80];
  
  int filec_debug = filec_getdebug();
  /*****************************************
   * open the new FITS file
   *****************************************/
  status = 0;
  unit = 15;
  FCINIT(unit, filename, 2880, &status);
  
  /*
   * set the values for the primary array
   */
  for (nelm=1, i = 0; i < naxis; i++)
    nelm *= axis[i];
  
  simple = 1;                 /* This file conforms to all FITS standards */
  extend = 0;                 /* No extensions past first HDU */
  fpixel = 1;                 /* Start write at first pixel in the array */
  gcount = 1;                 /* Number of random groups */
  pcount = 0;                 /* Number of group parameters */
  group  = 0;                 /* Random groups present */
  
/*
 * FITS supports 5 data types in primary or IMAGE data arrays: 8-bit
 * unsigned binary integers, 16-bit twos-complement signed binary
 * integers, 32-bit twos-complement signed binary integers, 32-bit
 * IEEE-754 standard floating point numbers, and 64-bit IEEE-754 floating
 * point numbers. For signed integers, the byte that includes the sign
 * bit is first and the byte that has the 1-bit as its least significant
 * bit is last.
 *  
 * FITS does not support the 16-bit unsigned integer data type generated
 * by many analog/digital converters. Conforming FITS files can be
 * produced from such data by subtracting 32768 (decimal) from the
 * converter output before writing to the file, while setting the BZERO
 * keyword in the FITS header equal to 32768 and the BSCALE keyword equal
 * to 1. A FITS reader will then add 32768 to the value in the file,
 * restoring the original value, before interpreting it. Whether a 16-bit
 * unsigned data type should be added, and if so, how, is controversial
 * and under discussion, especially in sci.astro.fits.
 *
 * The bitpix parameter specifies the type of array in the file :
 *    8, 16, 32 = 1, 2 or 4 byte integers
 *    -32, -64 float or double
 */

  if ( type == SMV_UNSIGNED_SHORT )
    bitpix = 16;
  else if ( type == SMV_SIGNED_LONG )
    bitpix = 32;
  else if ( type == SMV_FLOAT )
    bitpix = -32;
  
  /*
   * write the required primary array keywords 
   */
  FCPHPR (unit, simple, bitpix, naxis, axis, pcount, 
	  gcount, extend, &status);
  /*
   * define the primary array structure 
   */
  FCPDEF (unit, bitpix, naxis, axis, pcount, gcount, &status);
  
  for (i=0; gethdn(i, keyword, value, head) != 0; i++)
    FCPKYS (unit, keyword, value, "From SMV image", &status);
  
  if ( type == SMV_UNSIGNED_SHORT )
    {
      short int *a;
      unsigned short int *b;
      a = (short int*) array;
      b = (unsigned short int*) array;
      for ( i=0; i<nelm; i++ ) a[i] = (int) b[i] - 32768;
      if ( filec_debug )
	{
	  printf ("Writing unsigned short image\n");
	  printf ("Number of elements : %d\n", nelm);
	}
      FCPPRI (unit, group, fpixel, nelm, (int*) array, &status);
      for ( i=0; i<nelm; i++ ) *b = (int) *a + 32768;
      FCPKYJ (unit, "BZERO", 32768, "Image originally unsigned short", 
              &status);
      FCPKYJ (unit, "BSCALE", 1, "Image originally unsigned short", 
              &status);
    }
  else if ( type == SMV_SIGNED_LONG )
    {
      FCPPRJ (unit, group, fpixel, nelm, (int*) array, &status);
    }
  
  else if ( type == SMV_FLOAT )
    {
      FCPPRE (unit, group, fpixel, nelm, (float*) array, &status);
    }
  
  /*
   * close the file
   */
  FCCLOS (unit, &status);
  
  if ( filec_debug )
    {
      if (status <= 0)
	puts ("*** Program completed successfully ***");
      else
	{
	  FCGERR(status,errtxt);
	  puts ("*** ERROR - program did not run successfully ***");
	  printf ("status = %d : %s\n", status, errtxt);
	}
    }
}
#else
{
return 1;
}
#endif
  
