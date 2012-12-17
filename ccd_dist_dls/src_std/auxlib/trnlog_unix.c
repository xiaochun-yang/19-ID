/*
	Procedure trnlog.
	Translate logical name from the process environment.
	
	Character string "table" is name of logical name table to search.
	Character string "logical_name" is logical to be translated.
	Character string "name" is null terminated equivalence string.

	This procedure is designed to provide compatability between
	the unix and VMS versions.

	"table" above is ignored; the name must be in the environment.

	Maximum of 128 characters in strings.
	Case is ignored.
	On error print message and return.
*/

#include	<stdio.h>


int trnlog(table,logical_name,name)
char logical_name[];
char table[];
char name[];
  {
	char	*tr;
	
	if(NULL == (tr = (char *) getenv(logical_name)))
	  {
	    fprintf(stderr,"trnlog_unix:  no environment string for %s\n",
			logical_name);
	    name[0] = '\0';
	    return 0;
	  }
	 else
	   {
	     strcpy(name,tr);
	     return 1;
	   }
  }
