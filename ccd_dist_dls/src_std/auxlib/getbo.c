#ifdef TEST_GETBO
main ()
{
  int s, istat;

  s = getbo();
  if ( s == 0 ) 
    printf ("Little Endian\n");
  else if ( s == 1 ) 
    printf ("Big Endian\n");
  else
    printf ("Unrecognized byte pattern\n");
}
#endif

#include "filec.h"

/*
 *     GETBO  -  Return the byte-order of the computer.
 *
 *        0 if little-endian
 *        1 if big-endian
 *        2 if unknown-endian
 *
 *  14-Sep-1994      Marty Stanton       Brandeis University
 *
 */
int getbo()
{
  long i4;
  short *i2;

  i4=1;
  i2 = (short *) &i4;

  if ( *i2 == 1 && *(i2+1) == 0 )
    return (0);
  else if ( *i2 == 0 && *(i2+1) == 1 )
    return (1);
  else
    return(2);
}
