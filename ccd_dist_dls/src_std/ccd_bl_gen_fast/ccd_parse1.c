#include	<stdio.h>

/*
 *	Routine to parse a set of input lines to one of
 *	several clients of ccd_dc.  This currently includes
 *
 *		ccd_bl
 *		ccd_det
 *		ccd_xform
 *
 *	The input to each program looks like:
 *
 *		directive
 *		command
 *		   .
 *		   .
 *		   .
 *		command
 *		end_marker
 *
 *	Where "directive" is something meaningful to the particular
 *	process.  It always stands alone on the first line.
 *
 *	"command" is a '\n' terminated substring.
 *
 *	"end_marker" is an end marker specific to the process.
 *
 *	When finished with the parsing, the program sets the global
 *		int	ccdparse_linec
 *	to the number of lines found and the global
 *		char	*ccdparse_linev[]
 *	to the breaks in the lines.  The '\n's are replaced with \'0'
 *	for the convienece of string handline routines.
 *
 *	Additionally, each line is broken up into strings (separated by
 *	spaces or '\0' is the delimeter).  The global
 *		int	ccdparse_subc[MAXLINES];
 *	contains the number of substrings in each line.
 *	The global
 *		char	*ccdparse_subf[MAXLINES][MAXSUB]
 *	the pointers to each.
 */

#define	MAXLINES	100
#define	MAXSUB		10

int	ccdparse_linec;
char	*ccdparse_linev[MAXLINES];
int	ccdparse_subc[MAXLINES];
char	*ccdparse_subv[MAXLINES][MAXSUB];

ccd_parse1(buf)
char	*buf;
  {
	int	i,j,k,n;
	char	*p,*q;
	ccdparse_linec = 0;

	for(p = buf, i = 0; buf[i] != '\0'; i++)
	  if(buf[i] == '\n')
	    {
		ccdparse_linev[ccdparse_linec] = p;
		ccdparse_linec++;
		buf[i] = '\0';
		p = &buf[i+1];
	    }
	if(p != &buf[i])
	  {
		ccdparse_linev[ccdparse_linec] = p;
		ccdparse_linec++;
	  }

	for(n = 0; n < ccdparse_linec; n++)
	  {
	    ccdparse_subc[n] = 0;
	    for(p = q = ccdparse_linev[n]; *q != '\0'; q++)
	      if(*q == ' ')
		{
		  ccdparse_subv[n][ccdparse_subc[n]] = p;
		  ccdparse_subc[n]++;
		  *q = '\0';
		  p = q + 1;
		}
	    if(p != q)
	      {
		  ccdparse_subv[n][ccdparse_subc[n]] = p;
		  ccdparse_subc[n]++;
	      }
	  }
  }
