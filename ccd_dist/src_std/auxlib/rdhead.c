/*****************************************************************
 *   =================================================
 *   void rdhead (filename, head, istat)
 *   =================================================
 *   read a file header
 *
 *   filename    filename (input)
 *   head        image header (output)
 *   istat       completion status
 *
 ****************************************************************/
#include <string.h>
#include "filec.h"

int rdhead ( char* filename, char* head )
{
  int readl, remain;
  int i, j, k;
  int lhead, bo, dim;
  char s[80], byteo[80];
  int lun;
  int lflag;
  int istat;

  lun = 1;
  j = strlen(filename);
  dskbor_ ( &lun, filename, &j, &istat);
  if ( istat != 0 ) return istat;

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
  dskbr_ ( &lun, head, &readl, &istat);
  head[512]=0;
  if ( istat != 0 ) goto close;
  
  /*
   * Read remainder of the header (Should be multiple of 512,
   * but doesn't really matter)
   */
  gethdl (&lhead, head );
  if ( lhead <= 0 ) 
    {
      istat = -1;
      goto close;
    }

  readl = lhead - 512;
  if ( readl > 0 ) 
    {
      dskbr_ (&lun, head+512, &readl, &istat);
      if ( istat != 0 ) goto close;
    }
  
  /*
   * Close the file
   */
  
 close:
  if ( istat == 0 )
    dskbcr_ (&lun, &istat);
  else
    dskbcr_ (&lun, &j);
  
  return istat;
}
