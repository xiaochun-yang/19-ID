/*****************************************************************
 *   =================================================
 *   int rdctbl (filename, red, green, blue, ncolor, istat)
 *   =================================================
 *   read a file from disk.  Can be either MAD or MIFF
 *
 *     filename             filename (input)
 *     red, green blue      array for each color  (output)
 *     ncolor               number of elements in color table (input/output)
 *     istat                competion status (0:normal)
 *
 *   Dec 12, 1994    Marty Stanton     Brandeis University
 *
 *
 ****************************************************************/
#include <stdio.h>
#include <string.h>

#include "filec.h"


#define BLINELEN 256
#define MAX_HEAD 4*1024
int rdctbl ( char* filename, char* red, char* green, char* blue, int* ncolor,
	    int* control, int* ncontrol, int* cmode )

{
  char bline[3*BLINELEN];
  char head[64*1024];


  int readl, remain;
  int i, j, k;
  int lhead, bo, dim;
  char s1[80], s[80];
  int lun;
  int lflag;
  int nreads;
  int istat;
  int filec_debug = filec_getdebug();

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
  if ( istat != 0 ) goto close;
  
  /*
   * Read remainder of the header (Should be multiple of 512,
   * but doesn't really matter)
   */
  gethdl (&lhead, head );
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
   * See if there are any control points for colortable
   */
  gethd ("NUM_CONTROL_POINTS", s, head);
  if ( sscanf (s, "%d", ncontrol) > 0 && *ncontrol > 0 )
    {
      if (filec_debug)
	printf ("Number of control points %d\n", *ncontrol);
      for ( i=0; i < *ncontrol; i++)
	{
	  sprintf (s, "CONTROL_POINT_%d", i);
	  if (filec_debug)
	    printf ("Looking for %s\n", s);
	  gethd (s, s1, head);
	  if (filec_debug)
	    printf ("Found %s\n", s1);
	  sscanf (s1, "%d %d %d", control+3*i, control+3*i+1, control+3*i+2);
	  if (filec_debug)
	    printf ("Control points %d = %d %d %d\n", i, 
		    *(control+3*i), *(control+3*i+1), *(control+3*i+2) );
	}
    }
  else
    {
      *ncontrol = 0;
      if (filec_debug)
	printf ("Number of control points %d\n", *ncontrol);
    }


  gethd ("MODE", s, head);
  if ( sscanf (s, "%d %d %d", cmode, cmode+1, cmode+2 ) < 1 ) 
    { *cmode = 0; *(cmode+1) = 0; *(cmode+1) = 0; }

  if (filec_debug)
    printf ("Mode %d %d %d\n", *cmode, *(cmode+1), *(cmode+2));

  /*
   * Extract headrmation out of header
   */
  gethd ("TYPE", s, head);
  /*
   * Binary Colortable
   *
   * Read in the colortable in chunks of BLINELEN values
   *
   */
  if ( strcmp(s, "colortable") == 0 )
    {
      if (filec_debug)
	printf ("Reading binary colortable\n");
      gethd ("SIZE1", s, head );
      sscanf (s, "%d", ncolor);
      nreads = *ncolor/BLINELEN;
      k = 0;
      for (i = 0; i<nreads; i++)
	{
	  readl = 3*BLINELEN;
	  dskbr_ (&lun, bline, &readl, &istat);
	  if ( istat != 0 ) goto close;
	  for (j=0; j<BLINELEN; j++, k++)
	    {
	      red[k]   = bline[3*j];
	      green[k]= bline[3*j+1];
	      blue[k] = bline[3*j+2];
	      if (filec_debug)
		printf ("Color %d = %d,%d,%d\n", k, red[k], green[k], blue[k]);
	    }
	}
      /*     
       * Read in any remaining values
       */    
      readl = (*ncolor%256)*3;
      dskbr_ (&lun, bline, &readl, &istat);
      if ( istat != 0 ) goto close;
      for (j=0; j<readl; j++, k++)
	{
	  red[k]   = bline[3*j];
	  green[k]= bline[3*j+1];
	  blue[k] = bline[3*j+2];
	}
    }

  /*
   * Read ASCII Colortable
   */
  else if ( strcmp(s, "ascii_colortable") == 0 )
    {
      if (filec_debug)
	printf ("Reading ascii colortable\n");
      gethd ("SIZE1", s, head );
      sscanf (s, "%d", ncolor);
      for (i=0; i < *ncolor; i++)
	{
	  sprintf (s1, "COLOR_%.4d", i);
	  gethd (s1, s, head);
	  sscanf (s, "%d %d %d", red+i, green+i, blue+i);
	}
    }
  
  /*
   * Close the file
   */
 close:
  dskbcr_ (&lun, &istat);
  
  return istat;
}
