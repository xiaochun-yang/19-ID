
/*
 *	Handles some details of byte swapping, etc. due to moving
 *	files to/from vaxen
 */

short_swap(p,n)
unsigned short	*p;
int	n;
  {
	register int		i,j;
	register unsigned short	*q;

	for(i = 0, q = p; i < n;i++,q++)
	  {
	    j = *q;
	    *q = ((j << 8 ) | (j >> 8)) & 0x0000ffff;
	  }
  }

long_swap(oin, on)
	register long	*oin;	/* ptr to list of DEC long integer values */
	int	on;		/* no. of values to convert */
	{
	int i;
	register unsigned long n;
	register unsigned long nn;
	
	for	(i = 0; i < on; i++,oin++)
		{
		nn = *oin;
		n = nn << 16 | nn >> 16;
		nn = ((n&0x00ff00ff)<<8) | ((n&0xff00ff00)>>8);
		*oin = nn;
		}
	}
