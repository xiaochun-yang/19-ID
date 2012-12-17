#include <stdio.h>
#include <string.h>

#ifndef vms
#include <malloc.h>
#endif
#include "filec.h"

/*****************************************************************
 *   =================================================
 *   int rdsmv (char* filename, char** head, char** array, 
 *	   int* naxis, int* axis, int *type)
 *   =================================================
 *   read a file from disk. 
 *
 *   filename - name of file to open
 *   head - ascii header (returned)
 *   array - image (returned)
 *   naxis - image dimensions (returned)
 *   axis - image size (returned)
 *   type - image type (returned)
 ****************************************************************/
int rdsmv (char* filename, char** head, int* lhead,
	   char** array, int* naxis, int* axis, int *type)
{
  int readl, remain;
  int i, j, k;
  int istat, bo, dim;
  char s[80], s1[80];
  int lun=1;
  int lflag;
  int nelm;
  char *thead;

  int filec_debug = filec_getdebug();
  
  *head = 0;
  *array = 0;

  j = strlen(filename);
  if (filec_debug)
    printf("Opening file: %s\n", filename);
  dskbor_ ( &lun, filename, &j, &istat);
  if ( istat != 0 ) 
    {
      if (filec_debug)
	printf("Error opening file %s, istat=%d\n", filename, istat);
      return(ERROR_OPENING_FILE);
    }
  /*
   * While reading the header, have to wait before proceding
   */
  lflag = (1==1);
  dskbwr_ ( &lun, &lflag );
  
  /*
   * The header should be at least 512 bytes (and a multiple of 512)
   * Get the first 512 bytes to get the header length
   */
  readl = 512;
  thead = malloc (512);
  memset (thead, 0, 512);
  if (filec_debug)
    printf("Reading header\n");
  dskbr_ ( &lun, thead, &readl, &istat);
  if (filec_debug)
    printf("Read Completion status : %d\n", istat);
  if ( istat != 0 ) 
    { istat = ERROR_READING_FILE; goto close; }

  /*
   * Read remainder of the header (Should be multiple of 512,
   * but doesn't really matter)
   */
  if ( (istat = gethdl (&k, thead )) < 0 ) 
    {
      istat = UNKNOWN_FILETYPE;
      goto close;
    }
  if (filec_debug)
    printf("Header length : %d\n", k);


  
  *lhead = ((k/1024)+1) * 1024;
  *head = malloc (*lhead);
  memset (*head, 0, *lhead);
  memcpy (*head, thead, 512);
  free (thead);

  readl = k - 512;
  if ( readl > 0 ) 
    {
      dskbr_ (&lun, *head+512, &readl, &istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }
    }
  
  /*
   * shouldn't have to wait to read the rest of the file
   */
  lflag = (1==0);
  dskbwr_ ( &lun, &lflag );

  /* ****************************************************************
   * Extract information out of header
   * ****************************************************************/

  /*
   * Number of dimensions
   */
  *naxis = 0;
  gethd ("DIM", s, *head );
  if ( *s==0 || sscanf(s, "%d", &dim)!=1 ) 
    {
      if (filec_debug)
	printf ("Error reading dimensions\n");
      goto close;
    }
  if (filec_debug)
    printf ("Number of dimensions : %d\n", dim);

  /*
   * Size of each dimension
   */
  *naxis = dim;
  for (i=0, nelm=1; i<dim; i++)
    {
      sprintf (s1, "SIZE%d", i+1);
      gethd (s1, s, *head );
      if ( *s==0 || sscanf(s, "%d", &axis[i])!=1 ) 
	{
	  if (filec_debug)
	    printf ("Error reading %s\n", s1);
	  goto close;
	}
      nelm *= axis[i];
    }
  
  
  /*
   * Byte order
   * (not necessary if byte or bit image)
   */
  gethd ("BYTE_ORDER", s, *head );
  if ( *s )
    {
      if ( strcmp (s,"little_endian")==0 )
	bo = 0;
      else if ( strcmp(s,"big_endian")==0 )
	bo = 1;
      else
	{
	  istat = UNKNOWN_FILETYPE;
	  goto close;
	}
    }
  else
    bo = -1;

  /*
   * File type
   */
  gethd ("TYPE", s, *head);

  if (filec_debug)
    {
      printf ("Type >%s<\n", s);
      printf ("Image size (%d)", dim);
      for (i=0; i<dim; i++)
	printf (" %d ", axis[i]);
      printf ("\n");
      printf ("Number of elements : %d\n", nelm);
      if ( bo ) 
	printf ("Byte order : big_endian\n") ;
      else
	printf ("Byte order : little_endian\n");
    }

/****************************************************************/
  if (strcmp (s, "unsigned_byte")==0 || strcmp (s, "byte")==0 ||
      strcmp (s, "unsigned_char")==0 || strcmp (s, "char")==0 )
    {
      int i;
      unsigned char *char_array, *cp;
      unsigned short *ap;

      if ( filec_debug ) printf ("Reading byte image\n");
      /*
       * Read the char array
       */
      readl = nelm * sizeof (char);
      char_array = malloc (readl);
      if (filec_debug)
	{
	  printf("Allocating %d bytes for byte image\n", readl);
	  printf("Reading unsigned byte image\n");
	}
      dskbr_ ( &lun, (char*) char_array, &readl, &istat);
      if (filec_debug)
	printf("Read Byte Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }

      /*
       * Wait for file read to complete
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
            
      /*
       * Because SMV doesn't know about char arrays,
       * Convert to unsigned short
       */
      if ( filec_debug )
	{
	  readl = nelm * sizeof (unsigned short);
	  printf("Allocating %d bytes for short image\n", readl);
	}
      *array = malloc (nelm * sizeof (unsigned short));
      *type = SMV_UNSIGNED_SHORT;
      ap = (unsigned short *) *array;
      cp = char_array;
      if ( filec_debug )
	  printf("Converting %d bytes to short image\n", nelm);
	
      for ( i=0; i<nelm; i++ ) *ap++ = *cp++;

      /* 
       * Free the char array
       */
      free (char_array);
    }

/****************************************************************/
  else if (strcmp (s, "bit")==0)
    {
      int i;
      unsigned char *bit_array, *bp;
      unsigned short *ap;

      if ( filec_debug ) printf ("Reading bit image\n");
      /*
       * Read the bit array
       */
      readl = nelm * sizeof (char) / 8;
      bit_array = malloc (readl);
      if (filec_debug)
	printf("Reading bit image\n");
      dskbr_ ( &lun, (char*) bit_array, &readl, &istat);
      if (filec_debug)
	printf("Read Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }
      
      /*
       * Wait for file read to complete
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
            
      /*
       * Because SMV doesn't know about bit arrays,
       * Convert to unsigned short
       */
      *array = malloc (nelm * sizeof (unsigned short));
      *type = SMV_UNSIGNED_SHORT;
      ap = (unsigned short *) *array;
      bp = bit_array;
      for ( i=0; i<nelm; i+=8 )
	{
	  for ( j=0; j<8; j++)
	    *ap++ = *bp & 2<<j;
	  bp++;
	}

      /* 
       * Free the bit array
       */
      free (bit_array);
    }



/****************************************************************/
  else if ( strcmp(s, "mad") == 0 || strcmp (s, "unsigned_short")==0 )
    {
      if ( filec_debug ) printf ("Reading unsigned short image\n");
      readl = nelm * sizeof (unsigned short);
      if (filec_debug)
	{
	  printf("Reading unsigned short image\n");
	  printf("Allocating %d bytes\n", readl);
	}
      *array = malloc (readl);
      *type = SMV_UNSIGNED_SHORT;
      dskbr_ ( &lun, *array, &readl, &istat);
      if (filec_debug)
	printf("Read Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }

      /*
       * Wait before swapping bytes
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
            
      if ( bo != getbo() )
	{
	  if (filec_debug)
	    printf("Swapping bytes\n");
	  swpbyt ( 0, readl, *array );
	}
    }

/****************************************************************/
  else if (strcmp(s, "long") == 0 || 
      strcmp(s, "long_integer") == 0 || 
      strcmp (s, "signed_long")==0 )
    {
      if ( filec_debug ) printf ("Reading long image\n");
      readl = nelm * sizeof (int);
      if (filec_debug)
	{
	  printf("Reading signed long image\n");
	  printf("Allocating %d bytes\n", readl);
	}
      *array = malloc (readl);
      *type = SMV_SIGNED_LONG;
      dskbr_ ( &lun, *array, &readl, &istat);
      if (filec_debug)
	printf("Read Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }

      /*
       * Wait before swapping bytes
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
            
      if ( bo != getbo() )
	{
	  if (filec_debug)
	    printf("Swapping bytes\n");
	  swpbyt ( 1, readl, *array );
	}
    }

/****************************************************************/
  else if ( strcmp(s, "float") == 0 || strcmp (s, "ieee_float")==0 )
    {
      if ( filec_debug ) printf ("Reading float image\n");
      readl = nelm * sizeof (float);
      if (filec_debug)
	{
	  printf("Reading float image\n");
	  printf("Allocating %d bytes\n", readl);
	}
      *array = malloc (readl);
      *type = SMV_FLOAT;
      dskbr_ ( &lun, *array, &readl, &istat);
      if (filec_debug)
	printf("Read Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }
      
      /*
       * Wait before swapping bytes
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
            
      if ( bo != getbo() )
	{
	  if (filec_debug)
	    printf("Swapping bytes\n");
	  swpbyt ( 1, readl, *array );
	}
    }


/****************************************************************/
  else if ( strcmp(s, "complex") == 0 || strcmp (s, "ieee_complex")==0 )
    {
      if ( filec_debug ) printf ("Reading complex image\n");
      readl = nelm * 2 * sizeof (float);
      if (filec_debug)
	{
	  printf("Reading complex image\n");
	  printf("Allocating %d bytes\n", readl);
	}
      *array = malloc (readl);
      *type = SMV_COMPLEX;
      dskbr_ ( &lun, *array, &readl, &istat);
      if (filec_debug)
	printf("Read Completion status : %d\n", istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }
      
      /*
       * Wait before swapping bytes
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
      
      if ( bo != getbo() )
	{
	  if (filec_debug)
	    printf("Swapping bytes\n");
	  swpbyt ( 1, readl, *array );
	}
    }

/****************************************************************/
  else if ( strcmp(s, "swap_rlmsb") == 0 )
    {
      unsigned char lsb[10*1024], msb[10*1024];
      unsigned char *lp, *mp, *alp, *amp;
      int  lstart, mstart;
      int  llen, n, val; 
      int  is1=axis[0], is2=axis[1];

      if ( filec_debug ) printf ("Reading compressed image\n");

      if ( dim != 2 ) goto close;

      readl = nelm * sizeof (unsigned short);
      *array = malloc (readl);

      bo = getbo();
      if ( bo == 0 ) 
        {
          lstart = 0;
          mstart = 1;
        }
      else if ( bo == 1 )
        {
          lstart = 1;
          mstart = 0;
        }
      
      /*
       * Get the length of the first line
       * | LEN | LSBs       | MSBs       |
       * |  |  |  |  | ...  |  |  |  ... |          
       */
      llen = 2;
      dskbr_ ( &lun, (char*) lsb, &llen, &istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }
      llen = (int) lsb[llen-2] * 256 + lsb[llen-1];
      
      for ( j = 0; j<(is2-1); j++)
        {
          /*     
           *     Read the line and the first two bytes of the next line
           *     (which contain the length of the next line)
           */
	  if (filec_debug)
	    printf("Reading %d bytes\n", llen);
          dskbr_ ( &lun, (char*) lsb, &llen, &istat);
	  if ( istat != 0 ) 
	    { istat = ERROR_READING_FILE; goto close; }

          /*
           * Uncompress the MSBs
           */
	  if (filec_debug)
	    printf("Uncompressing %d bytes\n", llen-(is1)-2);

          for ( lp = lsb+(is1), mp=msb; lp<lsb+llen-2; )
            {
              n = *lp++;
              val = *lp++;
	      if (filec_debug && 0)
		printf("Line %d, n %d, val %d\n", j, n, val);
              for (i=0; i<n; i++) *mp++=val;
            }
	  if (filec_debug)
	    printf("Restored %d bytes in MSB\n", mp-msb);

          /*
           * Rebuild array
           */
          alp = (unsigned char*) *array + 2*j*is1+lstart;
          amp = (unsigned char*) *array + 2*j*is1+mstart;
          for ( lp=lsb, mp=msb; lp<lsb+(is1); alp+=2, amp+=2)
            {
              *alp = *lp++;
              *amp = *mp++;
            }

	  if (filec_debug)
	    {
	      printf("Done line %d\n", j);
	      printf("=================================\n");
	    }
          /*
           * Calculate length of the next line
           */
          llen = (int) lsb[llen-2] * 256 + lsb[llen-1];
        }
      /*
       * Read the last line (without trying to read the size of 
       * the next line
       */
      llen -= 2;
      dskbr_ ( &lun, (char*) lsb, &llen, &istat);
      if ( istat != 0 ) 
	{ istat = ERROR_READING_FILE; goto close; }

      for ( lp = lsb+(is1), mp=msb; lp<lsb+llen; )
        {
          n = *lp++;
          val = *lp++;
	  if (filec_debug && 0)
	    printf("Line %d, n %d, val %d\n", j, n, val);
          for (i=0; i<n; i++) *mp++=val;
        }
      if (filec_debug)
	printf("Restored %d bytes in MSB\n", mp-msb);
      
      
      /*
       * Rebuild array
       */
      alp = (unsigned char*) *array + 2*j*is1+lstart;
      amp = (unsigned char*) *array + 2*j*is1+mstart;
      for ( lp=lsb, mp=msb; lp<lsb+(is1); alp+=2, amp+=2)
        {
          *alp = *lp++;
          *amp = *mp++;
        }
      
      if (filec_debug)
	{
	  printf("Done line %d\n", j);
	  printf("===================================\n");
	}

      /*
       *
       * After rebuilding, this is now a "unsigned_short" file
       */
      puthd ("TYPE", "unsigned_short", *head);
      *type = SMV_UNSIGNED_SHORT;
    }
  else
    {
      if (filec_debug)
	printf("Unsupported Filetype (%s)\n");
      istat = UNKNOWN_FILETYPE;
      goto close;
    }
  
  /*
   * Close the file
   */
  
 close:
  if (filec_debug)
    printf("Done reading file\n");
  if ( istat ) 
    {
      dskbcr_ (&lun, &i);
      if (*head != 0 ) free (*head);
      if (*array != 0 ) free (*array);
    }
  else
    dskbcr_ (&lun, &istat);
  
  if (filec_debug)
    printf("RDSMV completion status %d\n", istat);
  return istat;
}
