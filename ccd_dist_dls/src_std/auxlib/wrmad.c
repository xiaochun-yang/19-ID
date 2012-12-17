/****************************************************************
 *   int wrmad (filename, head, array, as1, as2, is1, is2 )
 *   write a mad file to disk.
 *
 *   filename    *filename (input)
 *   head        *image header (input)
 *   array       *image (input)
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

void wrmad_ (char* filename, char* head, short *array,
    	     int* as1, int* as2, int* is1, int* is2, int *istat, int lfilename)
{
   char *fp;
   for (fp=filename+lfilename-1; *fp<=' '; fp--);
   *(fp+1) = 0;
   
   *istat = wrmad (filename, head, array, *as1, *as2, *is1, *is2);
}

int wrmad (char* filename, char* head, short* array, 
	   int as1, int as2, int is1, int is2 )
{
  int size, lun;
  int lflag;

  int istat;
  char s[80];
  int t;
  int headl, j;
  int filec_debug = filec_getdebug();

  if (filec_debug)
    {
      printf("Filename      : %s\n", filename);
      printf("Header        : \n%s<END\n", head);
      printf("Array address : %d\n", array);
      printf("Array size    : %d %d\n", as1, as2);
      printf("Image size    : %d %d\n", is1, is2);
    }

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
  if ( strcmp(s,"mad") != 0 )
    puthd ("TYPE", "mad", head );
  
  gethd ("BYTE_ORDER", s, head );
  if ( getbo () == 0 &&  strcmp(s, "little_endian" ) != 0 )
    puthd ("BYTE_ORDER", "little_endian", head );
  else if ( getbo () == 1 &&  strcmp(s, "big_endian" ) != 0 )
    puthd ("BYTE_ORDER", "big_endian", head );
  istat = 0;

  /*
   *     When opening file on VMS, need filesize (in bytes)
   */
  padhd ( head, 512 );
  gethdl (&headl, head );
  size = headl + is1*is2*2;
  if ( filec_debug )
    printf("Updated Header        : \n%s<END\n", head);

  /*
   * Open file
   */
  lun = 1;
  if ( filec_debug )
    printf( "Opening file : %s\n",filename);

  j=strlen(filename);
  dskbow_ (&lun, filename, &j, &size, &istat);
  if ( istat != 0 ) return (istat);

  /*
   * Should never have to wait for completion
   */
  lflag = (1==0);
  dskbww_ ( &lun, &lflag );

  /*
   * Write out the header
   */
  dskbw_ (&lun, head, &headl, &istat);
  if ( istat != 0 ) goto close;

  /*
   * Write out the image
   */
  if ( is1 == as1 )
    /*
     * Write out as a single array if possible
     */
    {
      size = 2*is1*is2;
      dskbw_ (&lun, (char*) array, &size, &istat);
      if ( istat != 0 ) goto close;
    }
  else
    /*
     * Write out the image one line at a time
     */
    {
      size = 2*is1;
      for (j=0;j<is2;j++)
	{
	  dskbw_ (&lun, (char*) (array+(j*as1)), &size, &istat);
	  if ( istat != 0 ) goto close;
	}
    }
  
  /*
   * Wait for writing to complete
   */
  lflag = (1==1);
  dskbww_ (&lun, &lflag );
  
  /*
   *    Close the file
   */

 close:
  dskbcw_ (&lun, &istat);
  return (istat);
}






