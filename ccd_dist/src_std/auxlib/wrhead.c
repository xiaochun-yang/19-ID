/****************************************************************
 *   int wrhead (filename, head)
 *   write a header to disk.
 *
 *   filename    *filename (input)
 *   head        *image header (input)
 *
 *   istat       competion status (output) (0:normal)
 *
 *   22-Apr-1996    Marty Stanton     Brandeis University
 ****************************************************************/
#include <string.h>
#include <stdio.h>
#include "filec.h"

int wrhead (char* filename, char* head )
{
  int size, lun;
  int lflag;

  int istat;
  int headl, j, i;

  int filec_debug = filec_getdebug();

  /*
   *     When opening file on VMS, need filesize (in bytes)
   */
  padhd ( head, 512 );
  gethdl (&headl, head );
  size = headl;
  if (filec_debug)
    printf("Updated Header        : \n%s<END\n", head);

  /*
   * Open file
   */
  lun = 1;
  if (filec_debug)
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






