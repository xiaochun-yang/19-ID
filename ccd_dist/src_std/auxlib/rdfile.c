#include <stdio.h>
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

int rdfile (char* filename, char** head, int *lhead,
	    char** array, int* naxis, int* axis, int* type)
{
  int status;
  int filec_debug = filec_getdebug();

  status = rdsmv (filename, head, lhead, array, naxis, axis, type);

  if (filec_debug)
    {
      if ( status == SUCCESS ) 
	printf ("SMV file\n");
      else if ( status == ERROR_READING_FILE ) 
	printf ("Error reading file\n");
      else if ( status == FILE_NOT_FOUND) 
	printf ("File not found\n");
      else if ( status = UNKNOWN_FILETYPE )
	printf ("Not a SMV file\n");
      else
	printf ("Unknown file error\n");
    }
  if ( status != UNKNOWN_FILETYPE ) return status;
  
  status = rdlum (filename, head, lhead, array, naxis, axis, type);
  if (filec_debug)
    {
      if (status==SUCCESS) 
	printf ("Lumiscan file\n");
      else
	printf ("Not a Lumiscan file\n");
    }
  if ( status == SUCCESS ) return status;

#ifdef HAVE_FITSIO
  status = rdfits (filename, head, lhead, array, naxis, axis, type);
  if (filec_debug)
    {  
      if (status==SUCCESS) 
	printf ("FITS file\n");
      else
	printf ("Not a FITS file\n");
    }
  if ( status == SUCCESS ) return status;
#endif

  status = rdmar (filename, head, lhead, array, naxis, axis, type);
  if (filec_debug)
    {
      if (status==SUCCESS) 
	printf ("MAR file\n");
      else
	printf ("Not a MAR file\n");
    }

  if ( status != SUCCESS ) status = UNKNOWN_FILETYPE;
  return status;
}
     
