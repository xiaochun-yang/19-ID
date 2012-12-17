
/*
 *	Handles some details of byte swapping, etc. due to moving
 *	files to/from vaxen
 */

short_vms2mips(p,n)
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

short_mips2vms(p,n)
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

float_vms2mips(ofn,on)
register float	*ofn;	/* ptr to array of DEC floats */
int	on;		/* no. of values to convert */
  {
	register unsigned long n;
	unsigned long nn;
	int i;

	for(i = 0; i < on; i++,ofn++)
	  {
		nn = *(unsigned long *)ofn;
		n = ((nn>>16) | (nn<<16));
		n = ((n&0x00ff00ff)<<8) | ((n&0xff00ff00)>>8);
		if	( (n & (0xff << 7)) <= (0x2 << 7) )   
			*ofn = 0.0;
		else
			{
			n -= 0x2 << 7;
			nn = ((n>>16) | (n<<16));
			*ofn =  *(float *)&nn;
			}
	  }
  }

float_mips2vms(ofn,on)
register float	*ofn;
int		on;
  {
	register unsigned long n;
	unsigned long nn;
	int i;
	unsigned char	*cptr;
	unsigned char 	c1;
	float		val;

	for(i = 0; i < on; i++,ofn++)
	  {
		cptr = (unsigned char *)ofn;
		c1 = *cptr;
		*cptr = *(cptr+1);
		*(cptr+1) = c1;
		c1 = *(cptr+2);
		*(cptr+2) = *(cptr+3);
		*(cptr+3) = c1;
		val = *((float *) cptr);
		val *= 4;
		*ofn = val;
	  }
  }

long_vms2mips(oin, on)
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

long_mips2vms(oin, on)
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
