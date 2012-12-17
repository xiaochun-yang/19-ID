/*
	Procedure trnlog.
	Translate logical name from a logical name table.
	
	Character string "table" is name of logical name table to search.
	Character string "logical_name" is logical to be translated.
	Character string "name" is null terminated equivalence string.

	Maximum of 128 characters in strings.
	Case is ignored.
	On error print message and return.
*/

#include	<stdio.h>
#include	<ssdef.h>
#include	<lnmdef.h>
#include	<descrip.h>


int trnlog(table,logical_name,name)

char logical_name[];
char table[];
char name[];

{

	struct dsc$descriptor_s	logname;
	struct dsc$descriptor_s	tabname;

	struct {
	unsigned short buflen  ;
	unsigned short code ;
	int bufadr ;
	int retadr ;
	int end ;
	} equiv;

	char buf[128];
	unsigned short retbuf[1];
	int attr;

	int c;
	int len,i;

	equiv.buflen = 128;
	equiv.code = LNM$_STRING;
	equiv.bufadr = buf;
	equiv.retadr = retbuf;
	equiv.end = NULL;

	attr = LNM$M_CASE_BLIND;

	logname.dsc$w_length = strlen(logical_name);
	logname.dsc$b_dtype = DSC$K_DTYPE_T;
	logname.dsc$b_class = DSC$K_CLASS_S;
	logname.dsc$a_pointer = logical_name;

	tabname.dsc$w_length = strlen(table);
	tabname.dsc$b_dtype = DSC$K_DTYPE_T;
	tabname.dsc$b_class = DSC$K_CLASS_S;
	tabname.dsc$a_pointer = table;

	c=sys$trnlnm(&attr,&tabname,&logname,NULL,&equiv);
	if (c != SS$_NORMAL) {
	   lib$signal(c);
	   return(c);
	}

	i=retbuf[0];
	buf[i]= '\0';
	sprintf(name,"%s",buf);
	return(0);

}
