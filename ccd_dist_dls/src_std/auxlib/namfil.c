#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "filec.h"

#define MIN(a,b) (( (a) < (b) ) ? (a) : (b) )
#define ABS(a)   (( (a) <  0  ) ? (-a) : (a) )

void namfil (char* tmpfil, int num, char* filnam);

/* #define TEST_NUMFIL */
#ifdef TEST_NUMFIL
main ()
{
  char tmpfil[132], filnam[132];
  int  num;

  printf("Template, number : ");
  scanf("%s %d", tmpfil, &num);
  namfil (tmpfil, num, filnam );

  printf("Filename >%s<\n", filnam);
}
#endif
/*
 *
 *  NAMFIL   NAMe a FILe based on a template file name and an integer.
 *  ======
 *  Feb 1995         Marty Stanton
 *                   C rewrite
 *
 *  14-Jan-1988      J. W. Pflugrath         Cold Spring Harbor Laboratory
 *
 *  Read Only:
 *     TMPFIL    Character    A template file name.  The string contains
 *                            the character # to designate a part of the
 *                            field which will contain the number specified
 *                            in NUM.  Example:  FILE###.###
 *     NUM       Integer      An integer number to be formatted and placed
 *                            in the # fields of TMPFIL.
 *
 *  Write Only:
 *     FILNAM    Character    The output file name (without #s) generated
 *                            by this routine.  The # field will be zeroed
 *                            filled on the left and a minus sign will be
 *                            changed to _ (underscore).
 */

void namfil (char* tmpfil, int num, char* filnam)
{
  char cnum[15], string[131];
  int  len, lstrng, fsthsh, lcnum, i, istat;

  istat = 0;
  len = strlen(tmpfil);
  strcpy (filnam, tmpfil);

  /*
   *  Put integer NUM into string CNUM.
   */
  sprintf (cnum, "%15d", ABS(num));
  lcnum = 14;

  /*
   *  Find first hash in FILNAM, it will hold sign if NUM is negative and
   *  there is room for it.
   */
  fsthsh = (int) strchr(filnam, '#')- (int) filnam;
  if (fsthsh > 0) 
    {
      for (i = len-1; i>=fsthsh; i--)
	{
	  if (filnam[i] == '#')
	    {
	      /*
	       *  replace with digit from CNUM as long as it available 
	       *  and is non-blank.  If it is blank, replace with a 0.
	       *
	       *  If no more characters available in CNUM, 
	       *  use underscore to replace hash
	       */
	      if (lcnum >= 0)
		{
		  if ( cnum[lcnum] == ' ' )
		    filnam[i]='0';
		  else
		    filnam[i] = cnum[lcnum];
		  lcnum--;
		}
              else
                filnam[i] = '_';
            }
        }
      
      /*
       *  If positive digits still left in cnum, write error message
       */
      if (lcnum >= 0 & cnum[lcnum] != ' ') 
	/*
	fprintf(stderr, 
		"WARNING in NAMFIL, template overflow with file number %s\n",
		filnam) */;

      /*
       *  Deal with minus sign if necessary
       */
      if (num < 0)
	{
	  if (filnam[fsthsh] == '0') 
	    filnam[fsthsh] = '_';
	  else
	    /*fprintf(stderr, 
		    "WARNING in NAMFIL, no room for minus sign in %s\n",
		    filnam)*/;
	}
    }
}
