/****************************************************************
 *   wrswap (filename, head, array, as1, as2, is1, is2  )
 *   write a mad file to disk.
 *
 *   filename    filename (input)
 *   head        image header (input)
 *   array       image (input)
 *   as1, as2    array size (input)
 *   is1, is2    image size (input)
 *
 *   istat       competion status (output) (0:normal)
 *
 *   22-Apr-1992    Marty Stanton     Brandeis University
 ****************************************************************/

#include <string.h>
#include <stdio.h>
#include "filec.h"

int wrrlmsb (char* filename, char* head, char* array, 
	     int naxis, int* axis, int type )
{
  int as1, as2, is1, is2;
  int status;

  if ( type != SMV_UNSIGNED_SHORT )
    return -2;
  else if ( naxis != 2 ) 
    return -2;
  
  as1 = axis[0];
  as2 = axis[1];
  is1 = axis[0];
  is2 = axis[1];

  status = wrswap(filename, head, (short*) array, 
		  as1, as2, is1, is2 );
  
  return status;
}

int wrswap(char* filename, char* head, short* array, 
	   int as1, int as2, int is1, int is2 )
{
  int size, i, j, headl, n;
  int t, lflag;
  unsigned char *lp, *mp, *alp, *amp;
  unsigned char *a;
  char s[80];
  unsigned char lsb[10240], msb[10240];
  int val, lun, bo;
  int istat = 0;

  a = (unsigned char*) array;
  gethd ("SIZE1", s, head );
  if ( *s=0 || sscanf(s,"%d",&t)!=1 || t!=is1 )
    {
      sprintf(s,"%4d", is1);
      puthd ("SIZE1", s, head );
    }
  
  gethd ("SIZE2", s, head );
  if ( sscanf(s,"%d",&t)!=1 || t!=is2 )
    {
      sprintf(s,"%4d", is2);
      puthd ("SIZE2", s, head );
    }
  
  gethd ("DIM", s, head );
  if ( sscanf(s,"%d",&t)!=1 || t!=2 )
    puthd ("DIM", "2", head );
  
  gethd ("TYPE", s, head );
  if ( strcmp(s,"swap_rlmsb") != 0 )
    puthd ("TYPE", "swap_rlmsb", head );

  puthd("INFO", " ______ This a compressed file ______ ", head );
  puthd("INFO", "Each line contains (2) bytes with the line length", head);
  puthd("INFO", "Followed by the LSBs for the line, and finally the", head);
  puthd("INFO", "run-length encoded MSBs.  Each pair of bytes in the", head);
  puthd("INFO", "MSB contains (byte 1) run-length and (byte 2) value", head);
  
  
  /*     When opening file on VMS, need filesize (in bytes)
   *     Unfortunately, before compressing I have no idea how
   *     large it is going to be!  I really don't know what to do about
   *     this.  Good thing that I don't use VMS! 
   */
  
  padhd (head, 512);
  gethdl (&headl, head);
  size = headl + (2*is1 * is2 );
  
  /*     
   * Open file 
   */
  lun = 1;
  j = strlen (filename);
  dskbow_ (&lun, filename, &j, &size, &istat );
  if (istat != 0) return (istat);

  /*
   *  Should never have to wait for completion 
   */
  lflag = (1==0);
  dskbww_ (&lun, &lflag);

  /*
   *     Write out the header
   */
  dskbw_ (&lun, head, &headl, &istat);
  if (istat != 0) goto Error;

  bo = getbo ();
  
  /*
   * Swap and Write out the image one line at a time 
   */
  
  for (j = 0; j < is2; j++) 
    {

      /*
       * Gather all the LSBs into the array lsb
       * and the MSBs into the array msn
       */
      
      if (bo == 0) 
	{
	  alp = a + (2*j*as1);
	  amp = a + (2*j*as1) + 1;
	}
      else if (bo == 1) 
	{
	  alp = a + (2*j*as1) + 1;
	  amp = a + (2*j*as1);
	}

      lp=lsb+2; mp=msb;
      for (i=0; i < is1; i++, alp+=2, amp+=2)
        {
          *lp++ = *alp;
          *mp++ = *amp;
        }

    /*    
     * Now do a cheap run length encoding on the MSBs, extending 
     * the LSB array
     */
    
    n = 1;
    val = *msb;
    for (mp=msb+1; mp < msb+is1; ++mp)
      {
	if (*mp == val && n < 255) 
	  ++n;
	else 
	  {
	    *lp++ = n;
	    *lp++ = val;
	    n = 1;
	    val = *mp;
	  }
      }
      *lp++ = n;
      *lp++ = val;
      size = (int) (lp - lsb);

      /*  
       * Write the full length of the line at the start of the line 
       */
      *lsb = size / 256;
      *(lsb+1) = size % 256;
      
      /*
       * Write out line
       */
/*
 *      printf ("Writing line %d \n", j);
 */
      dskbw_ (&lun, (char*) lsb, &size, &istat);
      if (istat != 0) goto Error;
      
    }
  
  /*
   * Wait for writing to complete 
   */
  lflag = (1==1);
  dskbww_ (&lun, &lflag);
  
  /*
   *Close the file 
   */
  
 Error:
  dskbcw_(&lun, &istat);
  return (istat) ;
}

/*
void wrswap_c_ (char* filename, char* head, short* array, 
		int* as1, int* as2, int* is1, int* is2, int* istat )
{
  * strchr(filename,' ') = 0;
  
  *istat = wrswap (filename, head, array, *as1, *as2, *is1, *is2);
  return;
}
*/
