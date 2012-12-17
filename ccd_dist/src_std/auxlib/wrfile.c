/****************************************************************
 *   int wrfile (filename, head, array, naxis, axis, type )
 *   write a file to disk.
 *
 *   filename    *filename (input)
 *   head        *image header (input)
 *   array       *image (input)
 *   naxis       array dimension
 *   axis        *dimensions
 *   type        array type
 *
 *   istat       competion status (output) (0:normal)
 *
 *   22-Apr-1992    Marty Stanton     Brandeis University
 ****************************************************************/
#include <string.h>
#include <stdio.h>
#include "filec.h"

int wrfile (char* filename, char* head, char* array, 
	    int naxis, int* axis, int type )
{
  int size, lun;
  int lflag;

  int istat;
  char s[80], s1[80];
  int t;
  int headl, j, i;
  int as;

  int filec_debug = filec_getdebug();

  if (filec_debug)
    {
      printf("Filename      : %s\n", filename);
      printf("Header        : \n%s<END\n", head);
      printf("Array address : %d\n", array);
      printf("Array dim     : %d\n", naxis);
      for (i=0; i<naxis; i++)
	printf("              : %d\n", axis[i]);
      printf("Type          : %d", type);
      if ( type == SMV_SIGNED_BYTE ) 
	printf (" (signed_byte)\n");
      else if ( type == SMV_UNSIGNED_BYTE ) 
	printf (" (unsigned_byte)\n");
      else if ( type == SMV_SIGNED_SHORT ) 
	printf (" (signed_short)\n");
      else if ( type == SMV_UNSIGNED_SHORT ) 
	printf (" (unsigned_short)\n");
      else if ( type == SMV_SIGNED_LONG ) 
	printf (" (signed_long)\n");
      else if ( type == SMV_UNSIGNED_LONG ) 
	printf (" (unsigned_long)\n");
      else if ( type == SMV_FLOAT ) 
	printf (" (float)\n");
      else if ( type == SMV_DOUBLE ) 
	printf (" (double)\n");
    }

  as = 1;
  for (i=0; i<naxis; i++)
    {
      as *= axis[i];
      sprintf (s1, "SIZE%d", i+1);
      gethd (s1, s, head );
      if ( *s=0 || sscanf(s,"%d",&t)!=1 || t!=axis[i] )
	{
	  sprintf(s,"%4d", axis[i]);
	  puthd (s1, s, head );
	}
    }

  gethd ("DIM", s, head );
  if ( sscanf(s,"%d",&t)!=1 || t!=naxis )
    {
      sprintf (s, "%d", naxis);
      puthd ("DIM", s, head );
    }

  gethd ("TYPE", s, head );
  if ( type == SMV_SIGNED_BYTE && strcmp(s,"signed_byte") ) 
    puthd("TYPE", "signed_byte", head);
  else if ( type == SMV_UNSIGNED_BYTE && strcmp(s,"unsigned_byte") ) 
    puthd("TYPE", "unsigned_byte", head);
  else if ( type == SMV_SIGNED_SHORT && strcmp(s, "signed_short") )
    puthd("TYPE", "signed_short", head);
  else if ( type == SMV_UNSIGNED_SHORT && strcmp(s, "unsigned_short") )
    puthd("TYPE", "unsigned_short", head);
  else if ( type == SMV_SIGNED_LONG && strcmp(s, "signed_long") )
    puthd("TYPE", "signed_long", head);
  else if ( type == SMV_UNSIGNED_LONG && strcmp(s, "unsigned_long") )
    puthd("TYPE", "unsigned_long", head);
  else if ( type == SMV_FLOAT && strcmp(s, "float") )
    puthd("TYPE", "float", head);
  else if ( type == SMV_DOUBLE && strcmp(s, "double") )
    puthd("TYPE", "double", head);
  else if ( type == SMV_COMPLEX && strcmp(s, "complex") )
    puthd("TYPE", "float", head);
  else if ( type == SMV_DCOMPLEX && strcmp(s, "double_complex") )
    puthd("TYPE", "double", head);

  gethd ("BYTE_ORDER", s, head );
  if ( getbo () == 0 &&  strcmp(s, "little_endian" ) != 0 )
    puthd ("BYTE_ORDER", "little_endian", head );
  else if ( getbo () == 1 &&  strcmp(s, "big_endian" ) != 0 )
    puthd ("BYTE_ORDER", "big_endian", head );
  istat = 0;

  /* So UNIX "more" can be used to look at header
   */
  /*puthd ("END_OF_HEADER", "", head ); /* ASA 7/2/96 */

  if ( type == SMV_SIGNED_BYTE )
    as *= sizeof (char);
  else if ( type == SMV_UNSIGNED_BYTE )
    as *= sizeof (unsigned char);
  else if ( type == SMV_SIGNED_SHORT )
    as *= sizeof (short);
  else if ( type == SMV_UNSIGNED_SHORT )
    as *= sizeof (unsigned short);
  else if ( type == SMV_SIGNED_LONG )
    as *= sizeof (int);
  else if ( type == SMV_UNSIGNED_LONG )
    as *= sizeof (unsigned int);
  else if ( type == SMV_FLOAT )
    as *= sizeof (float);
  else if ( type == SMV_DOUBLE )
    as *= sizeof (double);
  else if ( type == SMV_COMPLEX )
    as *= 2*sizeof (float);
  else if ( type == SMV_DCOMPLEX )
    as *= 2*sizeof (double);

  /*
   *     When opening file on VMS, need filesize (in bytes)
   */
  padhd ( head, 512 );
  gethdl (&headl, head );
  size = headl + as;
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
   * Write out the image
   */
  dskbw_ (&lun, (char*) array, &as, &istat);
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






