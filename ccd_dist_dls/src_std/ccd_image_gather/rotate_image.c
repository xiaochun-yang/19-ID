#include	<stdio.h>

/* rotate short (16 bit) data 
 *
 *  if direction == -90 then:
 *
 *  0 1 2       2 5 8
 *  3 4 5  -->  1 4 7
 *  6 7 8       0 3 6
 *
 *  x,y -> y,(width-1-x)
 *
 *
 *  if direction == +90 then:
 * 
 *  0 1 2       6 3 0
 *  3 4 5  -->  7 4 1
 *  6 7 8       8 5 2
 *
 *  x,y -> (width-1-y),x
 * 
 *
 * If width == height then the rotation is done "in place"
 * so as to use less memory. Otherwise a temporary array
 * of size width*height is allocated.
 *
 * Direction can only be +90 or -90 (degrees).
 *
 * This is needed since the data as written on disk in the
 * .image files is rotated 90 degrees from how one would
 * see it when viewing the image plate.
 */

rotate2(data, width, height, direction)
unsigned short *data;
register int width;
int height, direction;
{
	register unsigned short *ptr1, *ptr2, *ptr3, *ptr4, temp;
	register int i, j;

	if (width != height) {

	if ((ptr1 = (unsigned short *)malloc(sizeof(unsigned short)*width*height)) == NULL) {
		fprintf(stderr,"not enough memory (tried to allocate %d bytes).\n",
			sizeof(unsigned short)*width*height);
		exit(-1);
	}

	if (direction == -90) {
		for(i=width;i--;) {
			ptr2 = data + i;
			for(j=height;j--;) {
				/* ptr1[i*height + j] = data[j*width + width-1-i]; */
				*ptr1++ = *ptr2;
				ptr2 += width;
			}
		}
	}
	else {
		for(i=width;i--;) {
			ptr2 = data + height*width - i - 1;
			for(j=height;j--;) {
		 		/*ptr1[i*height + j] = data[(height-j)*width - width + i]; */
		 		*ptr1++ = *ptr2;
				ptr2 -= width;
			}
		}
	}

	ptr1 -= width*height;
	memcpy(data,ptr1,width*height*sizeof(unsigned short));
	free(ptr1);

	}
	else {

	if (direction == -90) {
		for(i=width/2;i--;) {
			j = (width+1)/2 - 1;
			ptr1 = data + i*width + j;
			ptr2 = data + j*width + width-1-i;
			ptr3 = data + (width-1-i)*width + width-1-j;
			ptr4 = data + (width-1-j)*width + i;
			for(j=((width+1)/2)+1;--j;) {
				temp = *ptr1;
				*ptr1-- = *ptr2;
				*ptr2 = *ptr3;
				ptr2 -= width;
				*ptr3++ = *ptr4;
				*ptr4 = temp;
				ptr4 += width;
			}
		}
	}
	else {
		for(i=width/2;i--;) {
			j = (width+1)/2 - 1;
			ptr1 = data + i*width + j;
			ptr2 = data + j*width + width-1-i;
			ptr3 = data + (width-1-i)*width + width-1-j;
			ptr4 = data + (width-1-j)*width + i;
			for(j=((width+1)/2)+1;--j;) {
				temp = *ptr4;
				*ptr4 = *ptr3;
				ptr4 += width;
				*ptr3++ = *ptr2;
				*ptr2 = *ptr1;
				ptr2 -= width;
				*ptr1-- = temp;
			}
		}
	}
	}
}

/* Cut a cwidth x cheight pice of data from data
 * where the upper left hand corner is x,y.
 */

crop(data, width, height, cdata, cwidth, cheight, x, y) 
unsigned short *data;
int width, height;
register unsigned short *cdata;
register int cwidth, cheight;
int x, y;
{
	register int j, i;
	unsigned short *ptr;

	if ((x<0) || ((x+cwidth)> width) || 
	    (y<0) || ((y+cheight) > height)) {

		for(i=cheight;i--;y++) {
			if ((y>=height) || (y<0)) {
				for(j=cwidth;j--;) 
					*cdata++ = 0;
				continue;
			}
			ptr = data + y*width + x;
			for(j=cwidth;j--;x++) {
				if ((x<width) && (x>=0))
					*cdata++ = *ptr;
				else
					*cdata++ = 0;
				ptr++;
			}
			x -= cwidth;
		}
	}
	else {
		ptr = data + width*y + x;
		for(i=0;i<cheight;i++) {
#define USE_MEMCPY
#ifdef USE_MEMCPY
			memcpy(cdata+i*cwidth,ptr+i*width,cwidth*sizeof(unsigned short));
#else
			for(j=0;j<cwidth;j++)
				*cdata++ = *ptr++;
			ptr += (width-cwidth);
#endif /*USE_MEMCPY*/
		}
	}
}
