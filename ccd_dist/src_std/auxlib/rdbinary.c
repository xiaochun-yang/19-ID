/* ***************************************************************
 *
 * Read a binary file and try to make some guesses about
 * it's content assuming a 2-d array
 *
 * ****************************************************************/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>
#include <ieeefp.h>
#include <sys/types.h>
#include <sys/stat.h>

#include "filec.h"

extern int global_debug;

#define WORDSIZE_GUESS_LENGTH 1024          /* bytes */
#define TYPE_GUESS_LENGTH     1024          /* words */
#define MIN_LINE_LENGTH         20          /* bytes */
#define MAX_LINE_LENGTH       8192          /* bytes */
    

int rdbinary (char *filename, char **array,  int *filesize, 
	      int *filetype, int *byteorder, int *headl, int *size )
{
  int wordsize;
  struct stat file_status;
  char *a;
  int rows, linelength;
  int offset;

  *array = 0;
  *filesize = 0;
  *filetype = SMV_UNKNOWN;
  *byteorder = getbo();
  size[0] = 0;
  size[1] = 0;

  /*
   * Get the filesize
   */
  if ( stat (filename, &file_status) ) return -1;
  *filesize = (int) file_status.st_size;
  
  /*
   * Allocate memory for the file and
   * Read the file
   */
  {
    int lun=1;
    int j, i, istat;
    int readl = *filesize;
    a = (char*) malloc ( (size_t) *filesize);
    *array = a;
    offset = (*filesize/8)*4;

    if ( global_debug ) printf ("Allocated %d bytes at location %d\n",
				*filesize, a);

    j = strlen(filename);
    dskbor_ ( &lun, filename, &j, &istat);
    if ( istat != 0 ) return ERROR_OPENING_FILE;

    dskbr_ (&lun, a, &readl, &istat);
    if ( istat != 0 ) return ERROR_READING_FILE;
    if (global_debug ) printf ("Read %d bytes \n", readl);

    dskbcr_ (&lun, &i);
    if ( global_debug ) printf ("File successfully read\n");
  }


  /*
   * Look for a non-ASCII character - if none, return ASCII
   */
  {
    int i;
    char *ap=a;
    for (i=0; i<*filesize; i++, ap++)
      if ( !isascii(*ap) ) goto have_binary;
    *filetype = SMV_ASCII;
    *byteorder = getbo();
    return SUCCESS;
  have_binary:
    if ( global_debug ) printf ("Determined not ASCII at byte %d\n", i);
  }

  /*
   * Make a guess about the word size
   */
  if ( *filesize < 2*WORDSIZE_GUESS_LENGTH )
    {
      *headl = *filesize;
      return SUCCESS;
    }
  else
    {
      char *ap = a + offset;
      int diff1=0, diff2=0, diff4=0, diff8=0;
      int i;
      
      for (i=0; i<WORDSIZE_GUESS_LENGTH-8; i+=4, ap++)
	{
	  diff1 += abs ( (int) (*ap - *(ap+1)) );
	  diff2 += abs ( (int) (*ap - *(ap+2)) );
	  diff4 += abs ( (int) (*ap - *(ap+4)) );
	  diff8 += abs ( (int) (*ap - *(ap+8)) );
	}
      if ( global_debug ) 
	{
	  printf ("Word length differences: \n");
	  printf ("                 Byte        : %d\n", diff1);
	  printf ("                 Word        : %d\n", diff2);
	  printf ("                 Longword    : %d\n", diff4);
	  printf ("                 8 Byte Long : %d\n", diff8);
	}

      if ( diff1 < diff2 && diff1 < diff4 && diff1 < diff8 )
	{
	  wordsize = 1;
	  *filetype = SMV_UNSIGNED_BYTE;
	}
      else if ( diff2 < diff4*1.2 && diff2 < diff8*1.2 )
	{
	  wordsize = 2;
	  *filetype = SMV_UNSIGNED_SHORT;
	}
      else if ( diff4 < diff8*1.2 )
	{
	  wordsize = 4;
	  *filetype = SMV_SIGNED_LONG;
	}
      else
	{
	  wordsize = 8;
	  *filetype = SMV_COMPLEX;
	}
      if (global_debug)
	printf ("Wordsize = %d\n", wordsize);
    }
	  

  /*
   * Make a guess about the data type and byteorder
   */
  if ( wordsize == 1 ) 
    {
      *filetype = SMV_UNSIGNED_BYTE;
      *byteorder = getbo();
    }
  else if ( wordsize == 2 ) 
    {
      char *ap = a + offset;
      int diff1=0, diff2=0;
      int i;
      
      *filetype = SMV_UNSIGNED_SHORT;
      for (i=0; i<WORDSIZE_GUESS_LENGTH-2*wordsize; i++, ap+=wordsize)
	{
	  diff1 += abs ( (int) (*ap     - *(ap+2)) );
	  diff2 += abs ( (int) (*(ap+1) - *(ap+3)) );
	}
      if ( diff1 < diff2 )
	*byteorder = 1;    /* Big Endian */
      else
	*byteorder = 0;    /* Little Endian */
      if (global_debug)
	printf ("Byte order = %d\n", *byteorder);
    }
  else if ( wordsize == 4 ) 
    {
      char *ap = a + offset;
      int diff1=0, diff2=0, diff3=0, diff4=0, diff5=0;
      int i;
      
      for (i=0; i<WORDSIZE_GUESS_LENGTH-2*wordsize; i++, ap+=wordsize)
	{
	  diff1 += abs ( (int) (*ap              - *(ap+wordsize  )) );
	  diff2 += abs ( (int) (*(ap+1)          - *(ap+wordsize+1)) );
	  diff3 += abs ( (int) (*(ap+2)          - *(ap+wordsize+2)) );
	  diff4 += abs ( (int) (*(ap+3)          - *(ap+wordsize+3)) );
	}

      if ( diff1 < diff4 )
	{
	  *byteorder = 1;    /* Big Endian */
	  if ( diff1 < diff2 && diff3 < diff2 && diff3 < diff4 )
	    {
	      wordsize = 2;
	      *filetype == SMV_UNSIGNED_SHORT;
	    }
	}
      else
	{
	  *byteorder = 0;    /* Little Endian */
	  if ( diff4 < diff3 && diff2 < diff1 && diff2 < diff3 )
	    {
	      wordsize = 2;
	      *filetype == SMV_UNSIGNED_SHORT;
	    }
	}

      if ( wordsize == 4 )
	{
	  if ( diff1 <= diff3 && diff1 <= diff4 && diff2 <= diff4 )
	    *filetype = SMV_SIGNED_LONG;
	  else if ( diff1 >= diff3 && diff1 >= diff4 && diff2 >= diff4 )
	    *filetype = SMV_SIGNED_LONG;
	  else
	    {
	      int i4 = 0;
	      float *af = (float*) ( a + offset);
	      float *aflimit = (*filesize/4)*2 < 2048 ?  
		(float*) ( a + *filesize - 4) : af + 2048;
	      
	      for (;af<aflimit && !i4; af++)
		if ( isnanf (*af) ) i4 = 1;
	      
	      if ( i4 ) 
		*filetype = SMV_SIGNED_LONG;
	      else
		{
		  *filetype = SMV_FLOAT;
		  *byteorder = getbo();
		}
	    }
	}

      if (global_debug)
	{
	  printf ("Byte differences: \n");
	  printf ("                 1 Byte      : %d\n", diff1);
	  printf ("                 2 Byte      : %d\n", diff2);
	  printf ("                 3 Byte      : %d\n", diff3);
	  printf ("                 4 Byte      : %d\n", diff4);

	  printf ("Byte differences : %d %d %d %d %d\n", 
		  diff1, diff2, diff3, diff4, diff5);
	  if ( *byteorder == 1 ) 
	    printf ("Byte order = BIG ENDIAN\n");
	  else
	    printf ("Byte order = LITTLE ENDIAN\n");

	  if ( *filetype == SMV_SIGNED_LONG )
	    printf ("Most likely type is SIGNED LONG \n");
	  else
	    printf ("Most likely type is FLOAT \n");
	}
    }
  else if ( wordsize == 8 ) 
    {
      *filetype = SMV_COMPLEX;
      *byteorder = getbo();
    }
  
  /****************************************************************/
  /*
   * Make a guess about the Line Length
   */
  if (*filetype == SMV_UNSIGNED_BYTE ||
      *filetype == SMV_UNSIGNED_SHORT ||
      *filetype == SMV_SIGNED_LONG )
    {
      int score;
      int best_score;
      int len, best_len, test_len;
      int len1, len2;
      int i,j;
      
      int *t, *t1;
      int *lut, *lutp;
      
      int *tp, *tp1;
      unsigned char *ap, *ap1;
      
      int maxlen = *filesize/4;
      if ( maxlen > MAX_LINE_LENGTH ) maxlen = MAX_LINE_LENGTH;
      if ( global_debug ) printf ("Maximum line length %d\n", maxlen);
      /*
       * To determine the linelength, compare bytes within
       * the array.  Instead of using a call to abs, 
       * make a lookup table with the absolute difference
       * between two bytes, then use the bytes as the index.
       */
      lut=malloc(256*256*sizeof(*lut));
      lutp = lut;
      for (i=0; i<256; i++)
	for (j=0; j<256; j++)
#define USE_ABS
#ifdef USE_ABS
	  *lutp++ = abs(i-j);
#else
      *lutp++ = (i-j)*(i-j);
#endif
      
      /* 
       * For faster lookup into the lut, form two arrays,
       * the first with the bytes converted into integers, and 
       * the second with the bytes converted into integers and shifted
       * by one byte
       */
      t =malloc(2*maxlen*sizeof(int));
      t1=malloc(2*maxlen*sizeof(int));
      ap = (unsigned char*) (a + offset);
      tp = t; tp1 = t1;
      for (i=0; i<2*maxlen; i++)
	{
	  *tp  = (int) *ap;
	  *tp1 = ( (int) *ap ) << 8;
	  tp++; tp1++; ap++;
	}
      
      /* 
       * To calculate an initial best score, assume square array
       */
      len = (int) sqrt ( (int) ( *filesize / wordsize ) );
      len *= wordsize;
      best_score=0;
      best_len = len;
      tp = t;
      tp1 = t1 + len;
      for (i=0; i<maxlen; i++, tp++, tp1++)
	best_score += *(lut + *tp + *tp1);
      if (global_debug)
	printf ("Test Score : %d at length %d\n", best_score, len);
      
      /*
       * Search to find a better score
       * Assume that the repeat length will be a multiple
       * of the wordsize
       */
      for (len1=best_len-1, len2=best_len+1;
	   len1>=MIN_LINE_LENGTH || len2<maxlen; len1--, len2++ )
	{
	  if ( len1 >= MIN_LINE_LENGTH )
	    {
	      score=0;
	      tp = t;
	      tp1 = t1 + len1;
	      for (i=0; i<maxlen && score<best_score; i++, tp++, tp1++)
		score += *(lut + *tp + *tp1);
	      
	      if ( score < best_score ) 
		{
		  best_score = score;
		  best_len = len1;
		  if (global_debug)
		    printf ("New Best Score : %d at length %d\n", score, len1);
		}
	    }
	  if ( len2 < maxlen )
	    {
	      score=0;
	      tp = t;
	      tp1 = t1 + len2;
	      for (i=0; i<maxlen && score<best_score; i++, tp++, tp1++)
		score += *(lut + *tp + *tp1);
	      
	      if ( score < best_score ) 
		{
		  best_score = score;
		  best_len = len2;
		  if (global_debug)
		    printf ("New Best Score : %d at length %d\n", score, len2);
		}
	    }
	}
      
      /* 
       * Line length in WORDS
       */
      linelength = best_len / wordsize;
      
      /* 
       * Free up lut and indices
       */
      free (lut);
      free (t);
      free (t1);
      
    }

  /****************************************************************/
  /*
   * I found that just comparing bytes (as is done above for ints)
   * doesn't work very well for floating numbers.
   * Use the read values
   */

  else if ( *filetype == SMV_FLOAT || *filetype == SMV_COMPLEX )
    {
      float score;
      float best_score;
      int len, best_len, test_len;
      int len1, len2;
      int i,j;
      int *al;
      float *ap, *ap1, *ap2;
      
      int maxlen = *filesize/4/4;
      ap = (float*) (a + offset );
      al = (int*) (a + offset );

      if ( maxlen > MAX_LINE_LENGTH/4 ) maxlen = MAX_LINE_LENGTH/4;
      if ( global_debug ) printf ("Maximum line length %d\n", maxlen);

      /* 
       * To calculate an initial best score, assume square array
       */
      len = (int) sqrt ( (int) ( *filesize / wordsize ) );

      best_score=0;
      best_len = len;
      ap1 = ap;
      ap2 = ap + len;

      for (i=0; i<maxlen; i++, ap1++, ap2++)
	{
	  if ( (*ap1) > (*ap2) )
	    best_score += (*ap1 - *ap2);
	  else
	    best_score += (*ap2 - *ap1);
	}
      if (global_debug)
	printf ("Test Score : %f at length %d\n", best_score, len);
      
      /*
       * Search to find a better score
       * Assume that the repeat length will be a multiple
       * of the wordsize
       */
      for (len1=best_len-1, len2=best_len+1;
	   len1>=MIN_LINE_LENGTH || len2<maxlen; len1--, len2++ )
	{
	  if ( len1 >= MIN_LINE_LENGTH )
	    {
	      score=0;

	      ap1 = ap;
	      ap2 = ap + len1;
	      for (i=0; i<maxlen; i++, ap1++, ap2++)
		score += *ap1 > *ap2 ? *ap1 - *ap2 : *ap2 - *ap1;
	      
	      if ( score < best_score ) 
		{
		  best_score = score;
		  best_len = len1;
		  if (global_debug)
		    printf ("New Best Score : %f at length %d\n", score, len1);
		}
	    }
	  if ( len2 < maxlen )
	    {
	      score=0;
	      ap1 = ap;
	      ap2 = ap + len2;
	      for (i=0; i<maxlen; i++, ap1++, ap2++)
		score += *ap1 > *ap2 ? *ap1 - *ap2 : *ap2 - *ap1;
	      
	      if ( score < best_score ) 
		{
		  best_score = score;
		  best_len = len2;
		  if (global_debug)
		    printf ("New Best Score : %f at length %d\n", score, len2);
		}
	    }
	}
      
      if ( *filetype == SMV_FLOAT )
	linelength = best_len;
      else if ( *filetype == SMV_COMPLEX )
	linelength = best_len / 2;

      if ( global_debug ) printf ("Linelength %d\n", linelength);
    }


/****************************************************************/
  /*
   * If the array is one row larger than square, it is probably
   * square with a linelength header
   */
  rows = (*filesize/wordsize) / linelength;
  if ( rows == (linelength+1) ) rows--;
  *headl = *filesize - (rows*linelength*wordsize);
  size[0] = linelength;
  size[1] = rows;

  return SUCCESS;

}

