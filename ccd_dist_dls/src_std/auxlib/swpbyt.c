/*     subroutine swpbyt(mode, length, array)
 *
 *     swaps characters in array of length length according to mode:
 *     mode =
 *            0   pairwise;  1,2,3,4, ... --> 2,1,4,3, ...
 *            1   quadwise;  1,2,3,4, ... --> 4,3,2,1, ...
 *
 *     length = length in BYTES of the array
 */
#include "filec.h"
int swpbyt(int mode, int length, char* array)
{
  char temp, *ap;
  int  i;
  
  ap=array;
  if (mode == 0) 
    {
      if ( length%2 != 0) 
	return (-1);
      else
	{
	  for (i=0; i<length; i+=2)
	    {
	      temp = *ap;
	      *ap = *(ap+1);
	      *(ap+1) = temp;
	      ap+=2;
	    }
         }
    }
  else if (mode == 1)
    {
      if ( length%4 != 0 )
	return (-1);
      else
	{
	  for (i=0; i<length; i+=4)
	    {
	      temp = *ap;
	      *ap = *(ap+3);
	      *(ap+3) = temp;
	      ap++;
	      temp = *ap;
	      *ap = *(ap+1);
	      *(ap+1) = temp;
	      ap+=3;
	    }
	}
    }
  else
    return(-1);

  return(1);
}
