#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "filec.h"

/* #define TEST_DSKHD */
#ifdef TEST_DSKHD
main()
{
char header[4096];
char value[80], field[80];
int  headl;
int  i;

clrhd(header);
printf("HEADER: \n%s<END\n", header);

puthd("FIELD", "100", header);
printf("HEADER: \n%s<END\n", header);

puthd("FIELD", "100", header);
printf("HEADER: \n%s<END\n", header);

gethdl(&headl, header);
printf("HEADER LENGTH: %d\n", headl);

gethd("FIELD", value, header);
printf("VALUE: %s\n", value);

puthd("COMMENT0", "Hi Mom", header);
printf("HEADER: \n%s<END\n", header);

puthd("COMMENT1", "Hi Dad", header);
printf("HEADER: \n%s<END\n", header);

gethd("COMMENT0", value, header);
printf("VALUE: %s\n", value);

gethd("???NOFIELD", value, header);
printf("??? VALUE: %s\n", value);

gethdl(&headl, header);
printf("HEADER LENGTH: %d\n", headl);

gethd("COMMENT1", value, header);
printf("VALUE: %s\n", value);

for (i=0; gethdn(i, field, value, header); i++)
  printf ("%d >%s< >%s<\n", i, field, value);
padhd(header, 512);
gethdl(&headl, header);
printf ("Header length (including padding) : %d\n", headl);
gethddl(&headl, header);
printf ("Header length (no padding)        : %d\n", headl);
printf ("Last character in header          : %c\n", header[headl-1]);
}
#endif
/****************************************************************
 *   =======
 *   dskhd.f
 *   =======
 *   Collection of fortran routines for disk files
 *
 *   22-Apr-1992    Marty Stanton     Brandeis University
 *
 *   ======
 *   HEADER
 *   ======
 *   
 *   The header always starts with a '{', ^J, 'HEADER_BYTES=nnnnn;'
 *   (where nnnnn is a number) and ends with a '}'.  It can be
 *   padded with space characters up to a multiple of 512 bytes.
 *   
 *   Information after the '}' is ignored by parsing routines.  The 
 *   header_length is used to to know how much to read and write to a file.
 *   A space will usually be the last character, unless the '}' happens to fall
 *   on a multiple of 512.
 *   
 *   The header contains description information of the form: 
 *   
 *   KEYWORD=VALUE;
 *   
 *   both the KEYWORD and VALUE are ASCII strings of any length.  
 *   The equals '=' and semicolon ';' are required.  
 *   Keywords are case sensitive.
 *   There may be whitespace between the 4 elements.  
 *
 *   Modified Sept 1995 - the keyword must be bracketed by char(10) and '="
 *
 *   
 *   The only required keyword is HEADER_BYTES.  The HEADER_BYTES keyword
 *   begins at the 3rd character of the header which is also the 3rd character 
 *   in the file.  The position of other keywords in the header is arbitrary.
 *   
 *   For image files there are additional required keywords. These
 *   required keywords are used by the read/write routines:
 *         DIM  - number of dimensions in the image
 *         TYPE - file type (miff or mad)
 *         BYTE_ORDER - byte order (little_endian or big_endian)
 *         SIZE1 - first dimension of the image
 *         SIZE2 - second dimension of the image
 *   
 *   
 *   ===============
 *   HEADER ROUTINES
 *   ===============
 *   To use the headers, I have the following routines:
 *   
 *   clrhd (header)
 *         Effectively clears the header by resetting the header_bytes
 *         field.  This always has to be called before a header is filled
 *         the first time.
 *   
 *   gethd (field, value, header)
 *         Get the field and value from the header
 *   
 *   gethdl (headl, header)
 *         Get the length (headl) of the header (including padding)
 *   
 *   gethddl (headl, header)
 *         Get the length of the data in the header (not including padding)
 *   
 *   gethdn (n, field, value, header)
 *         Get the nth field and value from the header
 *   
 *   puthd (field, value, header)
 *         Add the field and value to the header
 *   
 *   padhd (header, size)
 *         Pad the header to the lowest multiple of SIZE.  This is usually
 *         used to pad the header up to a multiple of 512 after filling it.
 *   
 *****************************************************************/
void clrhd_ ( char* header, int lheader )
{
   clrhd ( header );
}

void clrhd ( char* header )
{
static char temp[] = "{ HEADER_BYTES";

header[0] = '}';
temp[1]= 10;

puthd (temp, "    0", header);

}

/****************************************************************/

void gethd ( char* field, char* value, char* header )
{
  char *hp, *lhp, *fp, *vp;
  int l, j, n;
  char *newfield;

  /*
   * Find the last occurance of "field" in "header"
   */
  l = strlen (field);
  newfield = (char*) malloc ( l + 3 );
  *newfield = 10;
  strncpy (newfield+1, field, l);
  *(newfield+l+1) = '=';
  *(newfield+l+2) = (char) 0;
  l += 2;

  lhp = 0;
  for (hp=header; *hp != '}'; hp++)
    {
      for (fp=newfield, j=0; j<l && *(hp+j) == *fp; fp++, j++);
      if ( j == l ) lhp=hp;
    }

  if ( lhp == 0 )
    value[0] = 0;
  else
    {
      /*
       * Find the '='.  hp will now point to the '='
       */
      for (hp=lhp; *hp!='='; hp++);
      
      /*
       * Copy into the returned value until the ';'
       */
      for (lhp=hp+1, vp=value; *lhp!=';' && *lhp!=0; lhp++, vp++) *vp = *lhp;
      *(vp++)=0;
    }
  free (newfield);
}


/****************************************************************/

int gethdn ( int n, char* field, char* value, char* header )
{
  char *hp, *sp;
  int i;

  /*
   * Find the nth occurance of a ";"
   */
  sp = header;
  for (hp=header, i = -1; *hp != '}' && i<n; hp++)
    if ( *hp == ';' ) 
      {
	i++;
	if ( i==(n-1) ) sp=hp;
      }
  /*
   * Return if couldn't find nth field
   */
  if ( i<n ) 
    {
      field[0]=value[0]=0;
      return 0;
    }

  /*
   * Copy the field string 
   */
  for (hp=sp+2; *hp!='='; field++, hp++) *field = *hp;
  *field = 0;
  /*
   * Copy the value string 
   */
  for (hp++; *hp!=';'; value++, hp++) *value = *hp;
  *value = 0;

  return 1;
}


/****************************************************************/

int gethdl ( int* headl, char* head )
{
  char temp[6], *hp, *tp;
  int  i;

/*
 * at the start of the file it should include:
 *  {\nHEADER_BYTES=xxxxx;
 *  1 23456789012345678901
 */
  
  if ( strncmp("HEADER_BYTES=", head+2, 12) ) return -2;

  for (i=15,hp=head+15, tp=temp; i<20; i++ ) *tp++ = *hp++;
  *tp=0;
  if ( sscanf(temp,"%d", headl) != 1 ) *headl= 0;
  return 0;

}
/****************************************************************/

int gethddl ( int* headl, char* head )
{
  char *hp;

/*
 * find the } marking the end of the information in the header
 */
  for ( hp=head; *hp != '}'; hp++);
  *headl = hp-head +1;
  return 0;
}

/****************************************************************/

void puthd (char* field, char* value, char* header)
{
  char   temp[5];
  int    i, diff;
  char   *hp, *lp, *vp, *tp, *fp;

/*
 * find the } marking the end of the information in the header
 */
  for ( hp=header; *hp != '}'; hp++);

/*
 * Write the field name starting at the position of the }
 */
  for ( fp=field; *fp!=0; hp++, fp++) *hp = *fp;

/*
 * The field and the values are seperated by an = sign
 */
  *hp++ = '=';

/*
 * Write the field name starting at the position of the }
 */
  for ( vp=value; *vp!=0; hp++, vp++) *hp = *vp;

/*
 * End this field with a ; and new line
 * and mark the end of the header with a }
 */
  *hp++ = ';';
  *hp++ = 10;
  *hp++ = '}';

/*
 * Make the header a multiple of 4 by padding with spaces
 */
  i = (int) (hp-header);
  diff = 4 - i%4;
  if ( diff < 4 ) 
    for (i=0; i<diff; i++) *hp++=' ';

/*
 * Write the header length field
 */
  sprintf (temp, "%5d", (int) (hp-header));
  for (i=0,hp=header+15,tp=temp; i<5; i++) *hp++ = *tp++;

}

/****************************************************************/

void padhd (char* header, int size)
{
  int i, diff;
  char temp[5], *hp, *tp;

/*
 * find the } marking the end of the header
 */
  for ( hp=header; *hp != '}'; hp++); hp++;

/*
 * End this field with a ; and new line
 * and mark the end of the header with a }
 */
  *hp++ = ''; /* ASA 7/2/96 */
  *hp++ = 10;

/*
 * Make the header a multiple of "size" by padding with spaces
 */
  i = (int) (hp-header);
  diff = size - i%size;
  if ( diff < size ) 
    for (i=0; i<diff; i++) *hp++=' ';

/*
 * Write the header length field
 */
  sprintf (temp, "%5d", (int) (hp-header));
  for (i=0,hp=header+15,tp=temp; i<5; i++) *hp++ = *tp++;


}

