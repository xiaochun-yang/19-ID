#ifndef vms
#include <malloc.h>
#endif
#include "filec.h"

#ifdef HAVE_FITSIO
#include "cfitsio.h"
#endif


int rdfits (char* filename, char** head, int *lhead,
	    char** array, int* naxis, int* axis, int *type)

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
  
  *head = 0;
  *array = 0;
  
  /*****************************************
   * open the existing FITS file with readonly access  
   *****************************************/
  status = 0;
  rwstat=0;
  unit=15;
  FCOPEN(unit, filename, rwstat, &bksize, &status);
  if ( filec_debug && status ) 
    {
      FCGERR(status,errtxt);
      printf ("fcghpr status = %d : %s\n", status, errtxt);
    }
  if (status) goto close;
  
  /*****************************************
   * read the required primary array keywords  
   *****************************************/
  FCGHPR(unit, 99, &simple, &bitpix, naxis, axis, &pcount,
	 &gcount, &extend, &status);
  if (filec_debug)
    {
      if ( status ) 
	{
	  FCGERR(status,errtxt);
	  printf ("fcghpr status = %d : %s\n", status, errtxt);
	}
      if ( *naxis == 1 ) 
	{
	  printf ("One Dimensional Array (size: %d)\n\n", axis[0]);
	}
      else if ( *naxis == 2 ) 
	{
	  printf ("Two Dimensional Array (size: %d x %d)\n\n", 
		  axis[0], axis[1]);
	}
      else if ( *naxis == 3 ) 
	{
	  printf ("Three Dimensional Array (size: %d x %d x %d)\n\n", 
		  axis[0], axis[1], axis[2]);
	}
      printf ("Required Primary Array Keywords : \n");
      printf ("   block size : %5d   simple     : %5d\n", bksize, simple);
      printf ("   pcount     : %5d   gcount     : %5d\n", pcount, gcount);
      printf ("   bit / pix  : %5d   extend     : %5d\n\n", bitpix, extend);
    }
  if (status) goto close;
  
  
  /*****************************************
   * Get the keywords from fits header and put into smv header
   *****************************************/
  *head = malloc (4096);
  *lhead = 4096;
  memset (*head, 0, 4096);
  clrhd (*head);
  puthd ("COMMENT", "This file translated from FITS file", *head);
  puthd ("COMMENT", "The following fields come from the FITS file", *head);
  
  FCGHSP(unit, &nkeys, &nspace, &status);
  printf ("Number of keys in primary header: %d\n", nkeys);
  for (i=0; i<nkeys; i++)
    {
      FCGKYN(unit, i+1, keyword, value, comment, &status);
      printf ("%s/%s/%s\n", keyword, value, comment);
      puthd (keyword, value, *head);
    }
  puthd ("COMMENT", "End of fields from the FITS file", *head);
  printf ("\n");
  
  sprintf (s, "%d", *naxis);
  puthd ("DIM", s, *head);
  for (i=0, nelm=1; i<*naxis; i++) 
    {
      sprintf (s, "SIZE%d", i+1);
      sprintf (s1, "%d", axis[i]);
      puthd (s, s1, *head);
      nelm *= axis[i];
    }
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
  
  if ( bitpix == 8 )
    {
      unsigned short int *data;
      int fpixel = 1;
      int group = 0;
      int nullval = 0;
      
      if (filec_debug)
	printf ("Reading SHORT image %d values (%dx%d)\n", 
		nelm, axis[0], axis[1] );
      data = (unsigned short int*)
	malloc ( nelm * sizeof (unsigned short int) );
      *array = (char*) data;
      FCGPVI (unit, group, fpixel, nelm, nullval,
	      (int*) (data), &anyflg, &status);
      if ( status > 0 ) 
	{
	  if ( filec_debug)
	    {
	      FCGERR(status,errtxt);
	      printf ("status = %d : %s\n", status, errtxt);
	    }
	  goto close;
	}
      *type = SMV_UNSIGNED_SHORT;
      puthd ("TYPE", "unsigned_short", *head);
    }
  
  else if ( bitpix == 16 || bitpix == 32 ) 
    {
      unsigned int *data;
      int fpixel = 1;
      int group = 0;
      int nullval = 0;
      printf ("Reading INT image %d values (%dx%d)\n", nelm, 
	      axis[0], axis[1] );
      data = (unsigned int*) malloc ( nelm * sizeof (unsigned int) );
      *array = (char*) data;
      
      FCGPVJ (unit, group, fpixel, nelm, nullval,
	      (int*) data, &anyflg, &status);
      
      if ( status > 0 ) 
	{
	  if ( filec_debug )
	    {
	      FCGERR(status,errtxt);
	      printf ("status = %d : %s\n", status, errtxt);
	    }
	  goto close;
	}
      *type = SMV_SIGNED_LONG;
      puthd ("TYPE", "signed_long", *head);
    }
  
  else if ( bitpix == -32 ) 
    {
      float *data;
      int fpixel = 1;
      int group = 0;
      float nullval = 0.;
      
      data = (float*) malloc ( nelm * sizeof (unsigned int) );
      *array = (char*) data;
      FCGPVE (unit, group, fpixel, nelm,
	      nullval, (float*) data, &anyflg, &status);
      
      if ( status > 0 ) 
	{
	  if ( filec_debug )
	    {
	      FCGERR(status,errtxt);
	      printf ("status = %d : %s\n", status, errtxt);
	    }
	  goto close;
	}
      *type = SMV_FLOAT;
      puthd ("TYPE", "float", *head);
    }
  
 close:
  FCCLOS (unit, &status);
  
  if ( filec_debug && status > 0)
    {
      FCGERR(status,errtxt);
      puts ("*** ERROR - routine did not run successfully ***");
      printf ("status = %d : %s\n", status, errtxt);
      if ( *head != 0 ) free (*head);
      if ( *array != 0 ) free ( *array );
    }
}
#else
{
  return 1;
}
#endif
