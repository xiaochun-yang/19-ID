#include <stdio.h>
#include <string.h>
#include "filec.h"

#define BLINELEN  256
#define MAX_HEAD  4*1024

int wrctbl (char* filename, char* red, char* green, char* blue, int ncolor,
	    int* control, int ncontrol, int* mode )
{
  char bline[3*BLINELEN];
  char head[MAX_HEAD];

  int writel;
  int nwrites;
  int i, j, k;
  int lhead, size;
  char s[80], s1[80];
  int lun;
  int lflag;
  int istat;
  int headl;

  int filec_debug = filec_getdebug();

  clrhd (head);
  puthd ("TYPE", "colortable", head);
  sprintf (s, "%d", ncolor);
  puthd ("SIZE1", s, head );
  if ( ncontrol > 0 ) 
    {
      sprintf (s, "%d", ncontrol);
      puthd ("NUM_CONTROL_POINTS", s, head);
      if (filec_debug)
	printf ("Number of control points %d\n", ncontrol);
      for (i=0; i<ncontrol; i++)
	{
	  sprintf (s, "CONTROL_POINT_%d", i);
	  sprintf (s1, "%d %d %d", *(control+3*i), *(control+3*i+1), *(control+3*i+2));
	  puthd (s, s1, head);
	  if (filec_debug)
	    printf ("%s %s\n", s, s1);
	}
      sprintf (s, "%d %d %d", *mode, *(mode+1), *(mode+2) );
      puthd ("MODE", s, head);
      if (filec_debug)
	printf ("MODE %s\n", s);
    }
  puthd ("COMMENT","This colortable has 3 bytes for each element", head);
  padhd ( head, 512 );
  gethdl (&headl, head);

  size = headl + 3*ncolor;
  lun = 1;
  j = strlen(filename);
  if (filec_debug)
    printf ("Opening %s\n", filename);
  dskbow_ (&lun, filename, &j, &size, &istat);
  if ( istat != 0 ) 
    {
      if (filec_debug)
	printf ("Error opening %s\n", filename);
      return istat;
    }
  lflag = 0;
  dskbww_ ( &lun, &lflag );

  if (filec_debug)
    printf ("Writing header %d\n", headl);
  dskbw_ (&lun, head, &headl, &istat);
  if ( istat != 0 ) goto error;

  if (filec_debug)
    printf ("Writing colortable\n");
  nwrites = ncolor/BLINELEN;
  k = 0;
  for (i=0; i<nwrites; i++)
    {
      for (j=0; j<BLINELEN; j++)
	{
	  bline[3*j] = red[k];
	  bline[3*j+1] = green[k];
	  bline[3*j+2] = blue[k];
	  k = k + 1;
	}
      writel = 3*BLINELEN;
      if (filec_debug)
	printf ("Writing colortable %d\n", writel);
      dskbw_ (&lun, bline, &writel, &istat);
      if ( istat != 0 ) goto error;
    }

  writel = ncolor%(BLINELEN*nwrites);
  if ( writel > 0 ) 
    {
      for (j = 0; j<writel; j++)
	{
	  k = k + 1;
	  bline[3*j+1] = red[k];
	  bline[3*j+2] = green[k];
	  bline[3*j+3] = blue[k];
	}
      writel *= 3;
      if (filec_debug)
	  printf ("Writing colortable %d\n", writel);
      dskbw_ (&lun, bline, &writel, &istat);
    }

 error:
  if ( istat != 0 ) 
    {
      if (filec_debug)
	printf ("Error writing to file\n");
      dskbcw_ (&lun, &j);
    }
  else
    if (filec_debug)
      printf ("Closing file\n");
    dskbcw_ (&lun, &istat);
  return 0;
}
