/*                   *******************
                     *    marpack      *
                     *******************

	
     File structure

     1.) Image-file
         Record             1: Header information= 10 integer*4 
                                                   15 real*4
                                                   1  character string with
                                                      24 letters
                               1200-62 or 2000-62  integer*2 (dummy)
         Record     2 -> NX+1: NX records with image data
         Record  NX+3 -> MOV : Overflow records with <= NX/4 values 
                               for address and pixel value
                               MOV = NX+3+INT(OVFL*4/NX)

     2.) PCK-file
         Record             1: Header information= 10 integer*4 
                                                   15 real*4
                                                   1  character string with
                                                      24 letters
                               1200-62 or 2000-62  integer*2 (dummy)
         Record     2 -> MOV : Overflow records with <= NX/4 values 
                               for address and pixel value
                               MOV = NX+3+INT(OVFL*4/NX)
         Record MOV+1 -> NX+1+MOV: NX records with compressed image data

      
=======================================================================

     VERSION:      1.1
     DATE:         07.02.1994

     Claudio Klein 
     MAR Research
     X-ray Research G.m.b.H.
     Luruper Hauptstr. 50
     D-22547 Hamburg, GERMANY
     Tel.: (+49) 40  831 5868
     FAX:  (+49) 40  831 5916

=======================================================================

*/
#include <stdio.h>
#include <stddef.h>
#include <math.h>
#include <ctype.h>
#include <string.h>
#define MAX_NON_OVERFLOW 65535

#define BYTE char
#define WORD short int
#define LONG long int

#ifndef FORTRAN_TYPES
#define FORTRAN_TYPES 1
typedef int integer;
typedef float real;
#endif /* FORTRAN_TYPES */

LONG *diff_words(WORD *img, int x, int y, LONG *diffs, LONG done);

#define PACKIDENTIFIER "\nCCP4 packed image, X: %04d, Y: %04d\n"
#define PACKBUFSIZ BUFSIZ
#define DIFFBUFSIZ 16384L
#define max(x, y) (((x) > (y)) ? (x) : (y)) 
#define min(x, y) (((x) < (y)) ? (x) : (y)) 
#define abs(x) (((x) < 0) ? (-(x)) : (x))
const LONG setbits[33] = {0x00000000L, 0x00000001L, 0x00000003L, 0x00000007L,
			  0x0000000FL, 0x0000001FL, 0x0000003FL, 0x0000007FL,
			  0x000000FFL, 0x000001FFL, 0x000003FFL, 0x000007FFL,
			  0x00000FFFL, 0x00001FFFL, 0x00003FFFL, 0x00007FFFL,
			  0x0000FFFFL, 0x0001FFFFL, 0x0003FFFFL, 0x0007FFFFL,
			  0x000FFFFFL, 0x001FFFFFL, 0x003FFFFFL, 0x007FFFFFL,
			  0x00FFFFFFL, 0x01FFFFFFL, 0x03FFFFFFL, 0x07FFFFFFL,
			  0x0FFFFFFFL, 0x1FFFFFFFL, 0x3FFFFFFFL, 0x7FFFFFFFL,
                          0xFFFFFFFFL};
#define shift_left(x, n)  (((x) & setbits[32 - (n)]) << (n))
#define shift_right(x, n) (((x) >> (n)) & setbits[32 - (n)])


#ifndef VMS
/* macros to convert from VAX to IEEE: */
#define icvt(name) swab(&v->name, &n->name, 4), swaw(&n->name) /* int*4 */
#define rcvt(name) swab(&v->name, &n->name, 4), n->name/=4 /* real*4 */


/***************************************************************************/

/* swap the two 16-bit halves of a 32-bit word */
swaw(w)
int * w;
{
	int t;
	t = (( (*w)&0xFFFF) << 16 ) | (( (*w)&0xFFFF0000) >> 16);
	*w = t;
	return t;
}


/***************************************************************************/

/* swap the two 8-bit halves of a 16-bit word */
swapbytes(data, n)
register unsigned short *data;
int n;
{
	register int i;
	register unsigned short t;

	for(i=(n>>1)+1;--i;) {
		/*t = (( (*data)&0xFF) << 8 ) | (( (*data)&0xFF00) >> 8);*/
		t = (((*data) << 8) | ((*data) >> 8));
		*data++ = t;
	}
}


/***************************************************************************/

/* swap bytes and words */

swapbw(data, nbytes)
register char *data;
int nbytes;
{
	register int i, t1, t2, t3, t4;

	for(i=nbytes/4;i--;) {
		t1 = data[i*4+3];
		t2 = data[i*4+2];
		t3 = data[i*4+1];
		t4 = data[i*4+0];
		data[i*4+0] = t1;
		data[i*4+1] = t2;
		data[i*4+2] = t3;
		data[i*4+3] = t4;
	}
}

#endif

#ifdef NOT_USED /* defined in pack_c.c */

/*
 *	pack_wordimage_c_custom is a duplicate of the standard
 *	pack_wordimage_c with different file I/O.
 */


/* 
 *	Pack image 'img', containing 'x * y' WORD-sized pixels into 'filename'.
 */
pack_wordimage_c(WORD *img, int x, int y, int fdesc)
  { 
	int chunksiz, packsiz, nbits, next_nbits, tot_nbits;
	LONG buffer[DIFFBUFSIZ];
	LONG *diffs = buffer;
	LONG *end = diffs - 1;
	LONG done = 0;

	while(done < (x * y))
	  {
	    end = diff_words(img, x, y, buffer, done);
	    done += (end - buffer) + 1;
	    diffs = buffer;
	    while(diffs <= end)
	      {
	        packsiz = 0;
	        chunksiz = 1;
	        nbits = bits(diffs, 1);
	        while(packsiz == 0)
		  {
		    if(end <= (diffs + chunksiz * 2))
			packsiz = chunksiz;
		      else
			{
			  next_nbits = bits(diffs + chunksiz, chunksiz); 
			  tot_nbits = 2 * max(nbits, next_nbits);
			  if(tot_nbits >= (nbits + next_nbits + 6))
			      packsiz = chunksiz;
			    else
			      {
				nbits = tot_nbits;
				if(chunksiz == 64)
				    packsiz = 128;
				  else
				    chunksiz *= 2;
			      }
			}
		  }
		pack_chunk(diffs, packsiz, nbits / packsiz, fdesc);
		diffs += packsiz;
	      }
	  }
	pack_chunk(NULL, 0, 0, fdesc);
}

/* 
 *  Returns the number of bits neccesary to encode the longword-array 'chunk'
 *  of size 'n' The size in bits of one encoded element can be 0, 4, 5, 6, 7,
 *  8, 16 or 32.
 */

int bits(LONG *chunk, int n)
{ 
  int size, maxsize, i;

  for (i = 1, maxsize = abs(chunk[0]); i < n; ++i)
    maxsize = max(maxsize, abs(chunk[i]));
  if (maxsize == 0)
    size = 0;
  else if (maxsize < 8)
    size = 4 * n;
  else if (maxsize < 16)
    size = 5 * n;
  else if (maxsize < 32)
    size = 6 * n;
  else if (maxsize < 64)
    size = 7 * n;
  else if (maxsize < 128)
    size = 8 * n;
  else if (maxsize < 65536)
    size = 16 * n;
  else
    size = 32 * n;
  return(size);
}


/* 
 *  Packs 'nmbr' LONGs starting at 'lng[0]' into a packed array of 'bitsize'
 *  sized elements. If the internal buffer in which the array is packed is full,
 *  it is flushed to 'file', making room for more of the packed array. If 
 *  ('lng == NULL'), the buffer is flushed aswell. 
 */

pack_chunk(LONG *lng, int nmbr, int bitsize, int fdesc)
  { 
	static LONG bitsize_encode[33] = {0, 0, 0, 0, 1, 2, 3, 4, 5, 0, 0,
                                    	  0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0,
                                    	  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7};
	LONG descriptor[2], i, j;
	static BYTE *buffer = NULL;
	static BYTE *buffree = NULL;
	static int bitmark;

	if(buffer == NULL)
	  { 
	    buffree = buffer = (BYTE *) malloc(PACKBUFSIZ);
	    bitmark = 0;
	  }
	if(lng != NULL)
	  { 
	    for (i = nmbr, j = 0; i > 1; i /= 2, ++j);
	    descriptor[0] = j;
	    descriptor[1] = bitsize_encode[bitsize];
	    if((buffree - buffer) > (PACKBUFSIZ - (130 * 4)))
	      { 
		if(-1 == ff_write(fdesc, buffer,buffree - buffer))
			return;
		buffer[0] = buffree[0];
		buffree = buffer;
	      }
	    pack_longs(descriptor, 2, &buffree, &bitmark, 3);
	    pack_longs(lng, nmbr, &buffree, &bitmark, bitsize);
	  }
	 else
	  {
	    if(-1 == ff_write(fdesc,buffer,(buffree - buffer) + 1))
		return;
	    free((void *) buffer);
	    buffer = NULL;
	  }
  }


/* 
 *   Calculates the difference of WORD-sized pixels of an image with the
 *   truncated mean value of four of its neighbours. 'x' is the number of fast
 *   coordinates of the image 'img', 'y' is the number of slow coordinates,
 *   'diffs' will contain the differences, 'done' defines the index of the pixel
 *   where calculating the differences should start. A pointer to the last
 *   difference is returned. Maximally DIFFBUFSIZ differences are returned in
 *   'diffs'.
 */

LONG *diff_words(WORD *word, int x, int y, LONG *diffs, LONG done)
  { 
	LONG i = 0;
	LONG tot = x * y;

	if(done == 0)
	  { 
	    *diffs = word[0];
	    ++diffs;
	    ++done;
	    ++i;
	  }
	while((done <= x) && (i < DIFFBUFSIZ))
	  {
	    *diffs = word[done] - word[done - 1];
	    ++diffs;
	    ++done;
	    ++i;
	  }
	while ((done < tot) && (i < DIFFBUFSIZ))
	  {
	    *diffs = word[done] - (word[done - 1] + word[done - x + 1] +
                     word[done - x] + word[done - x - 1] + 2) / 4;
	    ++diffs;
	    ++done;
	    ++i;
	  }
	return(--diffs);
  }

/* 
 *  Pack 'n' WORDS, starting with 'lng[0]' into the packed array 'target'. The 
 *  elements of such a packed array do not obey BYTE-boundaries, but are put one 
 *  behind the other without any spacing. Only the 'bitsiz' number of least 
 *  significant bits are used. The starting bit of 'target' is 'bit' (bits range
 *  from 0 to 7). After completion of 'pack_words()', both '**target' and '*bit'
 *  are updated and define the next position in 'target' from which packing
 *  could continue. 
 */

pack_longs(LONG *lng, int n, BYTE **target, int *bit, int size)
  { 
	LONG mask, window;
	int valids, i, temp;
	int temp_bit = *bit;
	BYTE *temp_target = *target;

	if (size > 0)
	  {
	    mask = setbits[size];
	    for(i = 0; i < n; ++i)
	      {
		window = lng[i] & mask;
		valids = size;
		if(temp_bit == 0)
			*temp_target = (BYTE) window;
		  else
		    {
		      temp = shift_left(window, temp_bit);
        	      *temp_target |= temp;
		    }
		 window = shift_right(window, 8 - temp_bit);
		valids = valids - (8 - temp_bit);
		if(valids < 0)
		    temp_bit += size;
		  else
		    {
		      while (valids > 0)
			{ 
			  *++temp_target = (BYTE) window;
          		  window = shift_right(window, 8);
          		  valids -= 8;
			}
        	      temp_bit = 8 + valids;
		    }
      		if(valids == 0)
      		  { 
		    temp_bit = 0;
        	    ++temp_target;
		  }
	      }
  	    *target = temp_target;
  	    *bit = (*bit + (size * n)) % 8;
	  }
  }

#endif /* NOT_USED */
