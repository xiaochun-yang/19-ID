#include	<stdio.h>

/*
 *	Copy string from s2 to s1, stripping off blanks
 *	from the beginning and the end.
 */

util_copy_strip(s1,s2)
char	*s1,*s2;
  {
	/*
	 *	Strip leading whitespace.
	 */
	
	for(; *s2 != '\0'; s2++)
	  if(*s2 != ' ' && *s2 != '\t')
		break;
	
	/*
	 *	s2 either points to \0 or a non-blank.
	 */

	for(; *s2 != '\0'; s2++)
	  if(*s2 == ' ' || *s2 == '\t')
		break;
	    else
		*s1++ = *s2;
	
	/*
	 *	s2 points to whitespace or \0; put \0 in s1.
	 */
	
	*s1++ = '\0';
  }

/*
 *	Turn an integer into xxx.  Used in image numbers.
 */

util_3digit(s1,val)
char	*s1;
int	val;
  {
	int	i,j;

	i = val;
	j = i / 100;
	*s1++ = (char ) ('0' + j);
	i = i - 100 * j;
	j = i / 10;
	*s1++ = (char ) ('0' + j);
	i = i - 10 * j;
	*s1++ = (char ) ('0' + i);
	*s1++ = '\0';
  }

