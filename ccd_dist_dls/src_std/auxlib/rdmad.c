#include <stdio.h>
#include <string.h>
#include "filec.h"


/*****************************************************************
 *   =================================================
 *   int rdmad (filename, head,
 *           array, as1, as2, is1, is2 )
 *   =================================================
 *   read a file from disk.  Can be either MAD or MIFF
 *
 *   filename    filename (input)
 *   head        image header (output)
 *   array       image (output)
 *   as1, as2    array size (input)
 *   is1, is2    image size (output)
 *
 *   22-Apr-1992    Marty Stanton     Brandeis University
 *
 ****************************************************************/
int rdmad ( char* filename, char* head, short* array, 
	   int as1, int as2, int *is1, int *is2 )
{
  int readl, remain;
  int i, j, k;
  int istat, lhead, bo, dim;
  char s[80], byteo[80];
  int lun=1;
  int lflag;

  unsigned char lsb[10*1024], msb[10*1024];
  unsigned char *lp, *mp, *alp, *amp;
  int  lstart, mstart;
  int  llen, n, val; 
  int filec_debug = filec_getdebug();

  j = strlen(filename);
  if (filec_debug)
    printf("Opening file: %s\n", filename);
  dskbor_ ( &lun, filename, &j, &istat);
  if ( istat != 0 ) return(istat);

  /*
   * While reading the header, have to wait before proceding
   */
  lflag = (1==1);
  if (filec_debug)
    printf("Reading header\n");
  dskbwr_ ( &lun, &lflag );
  
  /*
   * The header should be at least 512 bytes (and a multiple of 512)
   * Get the first 512 bytes to get the header length
   */
  readl = 512;
  dskbr_ ( &lun, head, &readl, &istat);
  if (filec_debug)
    printf("Read Completion status : %d\n", istat);
  if ( istat != 0 ) goto close;
  
  /*
   * Read remainder of the header (Should be multiple of 512,
   * but doesn't really matter)
   */
  gethdl (&lhead, head );
  if (filec_debug)
    printf("Header length : %d\n", lhead);
  readl = lhead - 512;
  if ( readl > 0 ) 
    {
      dskbr_ (&lun, head+512, &readl, &istat);
      if ( istat != 0 ) goto close;
    }
  
  /*
   * shouldn't have to wait to read the rest of the file
   */
  lflag = (1==0);
  dskbwr_ ( &lun, &lflag );

    /*
     * Extract headrmation out of header
     */
  gethd ("TYPE", s, head);
  if (filec_debug)
    printf ("Type >%s<\n", s);
  if ( strcmp(s, "mad") == 0 || strcmp(s, "unsigned_short") == 0 )
    {
      gethd ("BYTE_ORDER", byteo, head );
      
      gethd ("SIZE1", s, head );
      if ( *s==0 || sscanf(s, "%d", is1)!=1 ) goto close;
      
      gethd ("SIZE2", s, head );
      if ( *s==0 || sscanf(s, "%d", is2)!=1 ) goto close;
      
      gethd ("DIM", s, head );
      if ( *s==0 || sscanf(s, "%d", &dim)!=1 ) goto close;

      if (filec_debug)
	printf("Image size %d %d %d\n", *is1, *is2, dim);
      
      /*
       * If the image size is the same as the array size, read
       * it in one chunk
       */
      if ( *is1 == as1 )
	{
	  if (filec_debug)
	    printf("Reading in single chunk\n");
	  readl = (*is1) * (*is2) * 2;
	  dskbr_ ( &lun, (char*) array, &readl, &istat);
	  if (filec_debug)
	    printf("Read Completion status : %d\n", istat);

	  if ( istat != 0 ) goto close;
	}
      
      else
	/*
	 * Read the whole image one line at a time.  For now
	 * worry about the byte order later.  It might not
	 * take any extra time to start swapping bytes on each line 
	 * while the other is presumbly being read into cache by 
	 * the computer
	 */ 
	{
	  if (filec_debug)
	    printf("Reading one line at a time\n");
	  readl = *is1 * 2;
	  for (j=0; j<*is2; j++)
	    {
	      dskbr_ ( &lun, (char*) (array+j * as1), &readl, &istat);
	      if ( istat != 0 ) goto close;
	    }
	}
      
      /*
       * Should probably wait before swapping bytes
       */
      lflag = (1==1);
      dskbwr_ ( &lun, &lflag );
      
      /*
       * Fix up the byte order if necessary
       */
      if ( *byteo )
	{
	  if ( strcmp (byteo,"little_endian")==0 )
	    bo = 0;
	  else if ( strcmp(byteo,"big_endian")==0 )
	    bo = 1;
	  else
	    {
	      istat = -2;
	      goto close;
	    }
	}
      
      if ( bo != getbo() )
	{
	  if (filec_debug)
	    printf("Swapping bytes\n");
	  for (j=0; j<*is2; j++)
	    swpbyt ( 0, 2 * *is1, (char*) (array+j*as1) );
	}
    }
  else if ( strcmp(s, "swap_rlmsb") == 0 )
    {
      gethd ("SIZE1", s, head );
      if ( *s==0 || sscanf(s, "%d", is1)!=1 ) goto close;
      
      gethd ("SIZE2", s, head );
      if ( *s==0 || sscanf(s, "%d", is2)!=1 ) goto close;
      
      gethd ("DIM", s, head );
      if ( *s==0 || sscanf(s, "%d", &dim)!=1 ) goto close;
      
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
      if ( istat != 0 ) goto close;
      llen = (int) lsb[llen-2] * 256 + lsb[llen-1];
      
      for ( j = 0; j<(*is2-1); j++)
        {
          /*     
           *     Read the line and the first two bytes of the next line
           *     (which contain the length of the next line)
           */
	  if (filec_debug)
	    printf("Reading %d bytes\n", llen);
          dskbr_ ( &lun, (char*) lsb, &llen, &istat);
          if ( istat != 0 ) goto close;

          /*
           * Uncompress the MSBs
           */
	  if (filec_debug)
	    printf("Uncompressing %d bytes\n", llen-(*is1)-2);

          for ( lp = lsb+(*is1), mp=msb; lp<lsb+llen-2; )
            {
              n = *lp++;
              val = *lp++;
              for (i=0; i<n; i++) *mp++=val;
            }
	  if (filec_debug)
	    printf("Restored %d bytes in MSB\n", mp-msb);

          /*
           * Rebuild array
           */
          alp = (unsigned char*) array + 2*j*as1+lstart;
          amp = (unsigned char*) array + 2*j*as1+mstart;
          for ( lp=lsb, mp=msb; lp<lsb+(*is1); alp+=2, amp+=2)
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
      if ( istat != 0 ) goto close;

      for ( lp = lsb+(*is1), mp=msb; lp<lsb+llen; )
        {
          n = *lp++;
          val = *lp++;
          for (i=0; i<n; i++) *mp++=val;
        }
      if (filec_debug)
	printf("Restored %d bytes in MSB\n", mp-msb);
      
      
      /*
       * Rebuild array
       */
      alp = (unsigned char*) array + 2*j*as1+lstart;
      amp = (unsigned char*) array + 2*j*as1+mstart;
      for ( lp=lsb, mp=msb; lp<lsb+(*is1); alp+=2, amp+=2)
        {
          *alp = *lp++;
          *amp = *mp++;
        }
      
      if (filec_debug)
	printf("===================================\n");
      /*
       *
       * After rebuilding, this is now a "unsigned_short" file
       */
      puthd ("TYPE", "unsigned_short", head);
    }
  else
    {
      if (filec_debug)
	printf("Unsupported Filetype (%s)\n");
      istat = -2;
      goto close;
    }
  
  /*
   * Close the file
   */
  
 close:
  if (filec_debug)
    printf("Done reading Image size %d %d (%d)\n", *is1, *is2, istat);
  if ( istat != 0 ) 
    dskbcr_ (&lun, &i);
  else
    dskbcr_ (&lun, &istat);
  
  if (filec_debug)
    printf("RDFILE completion status %d\n", istat);
  return(istat);
}

