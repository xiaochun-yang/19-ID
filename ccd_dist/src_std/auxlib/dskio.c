/*
 *
 *=======================================================================
 *
 * dskio.c   C routines for UNIX disk io.
 *           Mimics similiar VMS routines written in FORTRAN
 *           These routines will work on VMS, but are VERY slow
 *
 *=======================================================================
 *
 *  8-Apr-1992   J. W. Pflugrath             Cold Spring Harbor Laboratory
 *    Modified to match VMS routines
 *
 *  ?-???-1992   J. Marty Stanton            Brandeis University
 *    Created original routines.
 *
 *  CHARACTER*(*)       filename          Filename
 *  INTEGER             namlen            length of filename
 *  INTEGER             lun               Fortran logical unit number
 *                                              currently can be 1,2,3, or 4
 *  INTEGER             size              Size in bytes of file to be opened
 *                                         for writing.  Things work if this
 *                                         is set to 0, they go faster
 *                                         if this is accurately specified, and
 *                                         they don't work if it is too small.
 *  INTEGER             length            Number of bytes to read/write
 *                                              currently can be 1 to infinity
 *                                          (or characters in filename)
 *  INTEGER             istat             Return status, 0 = successful
 *  integer,real,byte   buffer            Buffer to read/write
 *  LOGICAL             iwait             Flag for asynchronous/synchronous
 *                                              .true. (default) means synch.
 *
 *  DSKBOR(lun, filename, namlen, istat)  Open an old file for reading.
 *  DSKBOW(lun, filename, namlen, size, istat)  Open a  new file for writing.
 *  DSKBR(lun, buffer, length, istat)     Read length bytes into buffer
 *  DSKBW(lun, buffer, length, istat)     Write length bytes to disk
 *  DSKBCR(lun, istat)                    Close the file open for read
 *  DSKBCW(lun, istat)                    Close the file open for write
 *  DSKBWR(lun, iwait)                    Set/Unset Wait for Read  to complete
 *  DSKBWW(lun, iwait)                    Set/Unset Wait for Write to complete
 *                                           to complete
 *
 *  Note:  The C routines have the identical syntax and effect.  They should
 *         be used on Unix systems, with the exception that there is no
 *         async routines.  Calls that deal with waits are ignored
 *
 */
#include <stdio.h>
#include <string.h>
#include "filec.h"

#ifdef VAX11C
struct descr {
    unsigned short length;
    char           type;
    char           class;
    char           *data;
   };
#endif

static FILE *fp[4];


/*
 * ***********************************
 * dskbor - Byte file Open for Reading
 * ***********************************
 */
#ifdef VAX11C
void dskbor (int* lun, struct descr* filename, int* lfilename, int* istat)
#else
void dskbor_ (int* lun, char* filename, int* lfilename, int* istat)
#endif
{
  char *temp;
  int  fx;
  int filec_debug = filec_getdebug();

#ifdef VAX11C
   temp = filename->data;
#else
   temp = filename;
#endif
  fx = *lun - 1;

  temp[*lfilename] = '\0';
  if ( strncmp( temp, "stdin", 5 ) == 0 )
    fp[fx] = stdin;
  else
    {
      if ( (fp[fx] = fopen(temp, "r")) != NULL)
	*istat = 0;
      else 
	{
/*
 *	  fprintf(stderr, 
 *		  "!***ERROR in DSKBOR, could not open file %s\n", temp);
 */
	  *istat = -2;
	}
    }
  return;
}


/*
 * *******************************
 * dskbcr - CLOSE file for reading
 * ******************************
 */
#ifdef VAX11C
void dskbcr(int* lun, int* istat)
#else
void dskbcr_(int* lun, int* istat)
#endif
{
  int fx;
  fx = *lun - 1;
  if (fp[fx] == NULL) 
    {
/*
 *      fprintf(stderr, 
 *	      "!***ERROR in DSKBCR, file not open, cannot close!\n");
 */
      *istat = -1;
    }
  else if ( fp[fx] != stdin )
    {
      fclose(fp[fx]);
      fp[fx] = NULL;
      *istat = 0;
    }
  return;
}


/*
 * ****************************************
 * dskbr - read from previously opened file
 * ****************************************
 */
#ifdef VAX11C
void dskbr(int* lun, char* data, int* ldata, int* istat)
#else
void dskbr_(int* lun, char* data, int* ldata, int* istat)
#endif
{
  int fx;
  int filec_debug = filec_getdebug();
  fx = *lun - 1;
  if (fp[fx] != NULL) 
    {
      if ( (*istat = fread(data, sizeof(*data), *ldata, fp[fx])) == 0) 
	{
	  if (filec_debug)
	    fprintf(stderr, "!***ERROR in DSKBR, reading error.\n");
	  *istat = -1;
	}
      else if (*istat == *ldata)
	{
	  if ( filec_debug)
	    fprintf(stderr, "!***Successful read in DSKBR  (%d out of %d)\n",
		    *istat, *ldata);
	  *istat = 0;
	}
      else if (filec_debug)
	fprintf(stderr, "!***ERROR in DSKBR, file short! (%d out of %d)\n",
		*istat, *ldata);
    }
  else
    {
      if (filec_debug)
	fprintf(stderr, "!***ERROR in DSKBR, no file open!\n");
      *istat = -1;
    }

  return;
}

/*
 * ****************************************
 * dskbwr - wait for read to complete (dummy routine)
 * ****************************************
 */
#ifdef VAX11C
void dskbwr(int* lun, int* lflag)
#else
void dskbwr_(int* lun, int* lflag)
#endif
{
  return;
}

/*
 * ***********************************
 * dskbow - Byte file Open for Writing
 * ***********************************
 */
#ifdef VAX11C
void dskbow(int* lun, struct descr * filename, int* lfilename, 
	    int* size, int* istat)
#else
void dskbow_(int* lun, char * filename, int* lfilename, 
	     int* size, int* istat)
#endif
{
  char *temp;
  int   fx;

  fx = *lun - 1;  
#ifdef VAX11C
  temp = filename->data;
#else
  temp = filename;
#endif
 
  temp[*lfilename] = '\0';
  if ( strncmp( temp, "stdout", 6 ) == 0 )
    fp[fx] = stdout;
  else
    {
      if ( (fp[fx] = fopen(temp, "w")) != NULL)
	*istat = 0;
      else 
	{
/*
 *	  fprintf(stderr, 
 *		  "!***ERROR in DSKBOW, could not open file %s\n", temp);
 */
	  *istat = -2;
	}
    }
  return;
}


/*
 * ************************************
 * dskbcw - Byte Close file for Writing
 * ************************************
 */
#ifdef VAX11C
void dskbcw( int* lun, int* istat)
#else
void dskbcw_( int* lun, int* istat)
#endif
{
  int fx;
  fx = *lun - 1;
  if (fp[fx] == NULL)
    {
/* 
 *     fprintf(stderr, 
 *	      "!***ERROR in DSKBCW, file not open, cannot close!\n");
 */
      *istat = -1;
    }
  else
    {
      fclose(fp[fx]);
      *istat = 0;
    }
  return;
}


/*
 * ********************************************
 * dskbw - Byte Write to previously opened file
 * ********************************************
 */
#ifdef VAX11C
void dskbw(int* lun, char* data, int* ldata, int* istat)
#else
void dskbw_(int* lun, char* data, int* ldata, int* istat)
#endif
{
  int  fx, ip, size;
  fx = *lun - 1;

  if (fp[fx] != NULL) 
    {
/*
 *      for ( ip=0; ip<*ldata; ip+=2*1024 )
 *	{
 *	  size = *ldata-ip;
 *	  if ( size > 2*1024 ) size = 2*1024;
 *	  *istat = fwrite(data+ip, sizeof(char), size, fp[fx]);
 *
 *	  if (*istat  == 0) 
 *	    {
 *	      fprintf(stderr, 
 *		      "!***ERROR in DSKBW, writing error\n");
 *	      *istat = -1;
 *	    }
 *	  else if (*istat == size)
 *	    *istat = 0;
 *	  else
 *	    fprintf(stderr, "!***ERROR in DSKBW, file short!\n");
 *	}
 */
      
      *istat = fwrite(data, sizeof(char), *ldata, fp[fx]);
      if (*istat  == 0) 
	{
/*
 *	  fprintf(stderr, 
 *		  "!***ERROR in DSKBW, writing error\n");
 */
	  *istat = -1;
	}
      else if (*istat == *ldata)
	*istat = 0;
/*
 *       else
 *	fprintf(stderr, "!***ERROR in DSKBW, file short!\n");
 */    
    }
  else
    {
/*
 *      fprintf(stderr, "!***ERROR in DSKBW, no file open!\n");
 */
      *istat = -1;
    }
  return;
}


/*
 * ****************************************
 * dskbww - wait for write to complete (dummy routine)
 * ****************************************
 */
#ifdef VAX11C
void dskbww(int* lun, int* lflag)
#else
void dskbww_(int* lun, int* lflag)
#endif
{
  return;
}
