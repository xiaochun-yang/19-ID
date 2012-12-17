#include <stdio.h>
#include "param_gui.h"

/* read, write and modify parameter files. The parameter file
 * consists of two strings per line. The first string is the "tag"
 * and the second string is the "value". A line in which the
 * first non-white space character is a "#" is a comment.
 * A comment may also begin after the "value" string but again
 * must start with the "#" character. A blank line is also treated
 * as a comment line. 
 *
 * For Example:
 *
 * # This is a comment line
 *
 *  Alpha  90.000  # More comments
 *   Beta  90.000  
 *  Gamma  120.000 
 * Beam_X  150.12  
 * Beam_Y  152.34  
 * .
 * .
 * .
 */

read_parameter_file(filename,param)
char *filename;
PARAMETER *param;
{
	FILE *fp;
	char tag[MAX_TAG_LENGTH+1], val[MAX_VAL_LENGTH+1];
	char str[MAX_COM_LENGTH+1], comment[MAX_COM_LENGTH+1],format[64];
	int nline=0, ncomment=0, nparam=0, nblank=0;

	if (!strcmp(filename,"stdin")) {
		fp=stdin;
	}
	else 
	if ((fp = fopen(filename,"r")) == NULL) {
		sprintf(str,"can not read parameter file: \"%s\"\n", filename);
		eprint(str);
		return -1;
	}

	strcpy(param[0].tag,"END OF PARAMETER FILE");

	sprintf(format,"%%%ds%%%ds%%[^\n]", MAX_TAG_LENGTH,MAX_VAL_LENGTH);
	while(fgets(str,MAX_COM_LENGTH,fp) != NULL) {
		if (iswhite(str)) {	/* blank line */
			nblank++;
			modify_parameter_file(param,"","","");
		}
		else
		if (iscomment(str)) {	/* comment line */
			ncomment++;
			sscanf(str,"%[^\n]",comment);
			modify_parameter_file(param,"","",comment);
		}
		else {			/* tag - value pair */
			strcpy(tag,"");
			strcpy(val,"");
			strcpy(comment,"");
			sscanf(str,format,tag,val,comment);
			/*printf("tag: %s val: %s\n", tag,val);*/
			/* DISABLED BY CN
			if (iswhite(val)) {
				sprintf(str,"tag without a value: %s\n",tag);
				eprint(str);
			}
			 */
			if (modify_parameter_file(param,tag,val,comment)==0) {
				fprintf(stderr,"warning: duplicate tag in paramater file: \"%s\" \n",tag);
			}
		}
		nline++;
	}
	nparam=nline-ncomment-nblank;
	/*
	printf("\nRead: %d lines (%d comments, %d blank, %d paramters)\n\n",
		nline,ncomment,nblank,nparam);
	*/
	if (strcmp(filename,"stdin"))
		fclose(fp);
	strcpy(param[nline].tag,"END OF PARAMETER FILE");
	return(0);
}

write_parameter_file(filename,param)
char *filename;
PARAMETER *param;
{
	char format[64], str[256];
	FILE *fp;
	int nline=0, max_tag_length=0, max_val_length=0;

	if (!strcmp(filename,"stdout")) {
		fp=stdout;
	}
	else 
	if ((fp = fopen(filename,"w")) == NULL) {
		sprintf(str,"can not write parameter file: \"%s\"\n", filename);
		eprint(str);
		return -1;
	}

	while (strcmp(param[nline].tag,"END OF PARAMETER FILE")) {
		unblank(param[nline].comment);
		if (strlen(param[nline].tag) > max_tag_length)
			max_tag_length = strlen(param[nline].tag);
		if (strlen(param[nline].val) > max_val_length)
			max_val_length = strlen(param[nline].val);
		nline++;
	}
	sprintf(format,"%%%ds  %%-%ds %%-s\n",max_tag_length,max_val_length);
	nline=0;
	while (strcmp(param[nline].tag,"END OF PARAMETER FILE")) {
		if (!strcmp(param[nline].tag,"")) { /* comment */
			fprintf(fp,"%s\n",param[nline].comment);
		}
		else
			fprintf(fp,format,param[nline].tag,
				param[nline].val,param[nline].comment);
		nline++;
	}

	if (strcmp(filename,"stdout"))
		fclose(fp);
	return(0);
}

modify_parameter_file(param,tag,val,comment)
PARAMETER *param;
char *tag, *val, *comment;
{
	int nline=0;

	/* Check to see if the comment field contains something other than
	 * a comment or white space.
	 */
	if (!iscomment(comment) && !iswhite(comment)) {
		fprintf(stderr,"\nwarning: non-white space following value:\n");
		fprintf(stderr,"%s %s %s\n\n",tag,val,comment);
		/*strcpy(comment,"");*/
	}

	/* If there is no tag then only append a comment to the
	 * end of the parameter file
	 */
	if (iswhite(tag)) {
		nline = find_tag(param,"END OF PARAMETER FILE");
		if (nline > MAX_PARAMETERS) {
			eprint("could not find end of parameter file.");
			return(-1);
		}
	 	strcpy(param[nline].tag,"");
	 	strcpy(param[nline].val,"");
	 	strcpy(param[nline].comment,comment);
	 	strcpy(param[nline+1].tag,"END OF PARAMETER FILE");
	 	return(1);
	}

	if ((nline = find_tag(param,tag)) <= MAX_PARAMETERS) {
		strcpy(param[nline].val,val);
		if (!iswhite(comment))
			strcpy(param[nline].comment,comment);
		return(0);
	}

	/* Since nline greater than MAX_PARAMETERS we have reached the end of the 
	 * parameter list and have not found the tag. Therefore
	 * we add it to to the end of the parameter list.
	 */
	 nline -= (MAX_PARAMETERS+1);

	 strcpy(param[nline].tag,tag);
	 strcpy(param[nline].val,val);
	 strcpy(param[nline].comment,comment);
	 strcpy(param[nline+1].tag,"END OF PARAMETER FILE");
	 return(1);
}

/* Return the index of the given tag into the parameter array.
 * If the tag is not found then return -1 * index of the last
 * parameter.
 */

find_tag(param,tag)
PARAMETER *param;
char *tag;
{
	int nline=0;
	char str[256];

	while (strcmp(param[nline].tag,tag)) {
		if (!strcmp(param[nline].tag,"END OF PARAMETER FILE")) {
				return(MAX_PARAMETERS+1+nline);
		}
		if (++nline >= MAX_PARAMETERS) {
			sprintf(str,"too many parameters. MAX_PARAMETERS=%d\n",
				MAX_PARAMETERS);
			eprint(str);
			return (MAX_PARAMETERS-1);
		}
	}
	return(nline);
}

/* Return 1 if s1 is a comment (starts with #).
 */

iscomment(s1)
char *s1;
{
	while (*s1) {
		if (!isspace(*s1++)) {
			if (*--s1 == '#') 
				return(1);
			else
				return(0);
		}
	} 
	return(0);
}

/* Return 1 if s1 consists only of white-space characters.
 */

unblank(s1)
char *s1;
{
	char *s2=s1--;

	while (*++s1) {
		if (!isspace(*s1))  {
			while (*s1)
				*s2++ = *s1++;
			break;
		}
	}
	*s2 = 0;
}

/* Print an error message */

static int	param_file_quiet = 0;	/* 1 for no error message printing */

eprint(str)
char *str;
{
	if(param_file_quiet != 0)
		return;

	fprintf(stderr,"error: %s\n",str);
	fflush(stderr);
}

#ifdef NOT_USED
set_parameter_message(val)
int	val;
  {
	param_file_quiet = val;
  }
#endif /* NOT_USED */
