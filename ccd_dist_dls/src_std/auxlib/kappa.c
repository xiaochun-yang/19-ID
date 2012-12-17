#include	<stdio.h>
#include	<math.h>

/*
 *	Routines to convert between kappa and eulerian angles.
 *
 *	ktoe(kang,eang)		convert 
 *					kang (omega, phi, kappa) in degrees, floating.
 *				  to:
 *				        eang (omega, phi, chi) in degrees, floating.
 *
 *	etok(kang,eang)		convert 
 *				        eang (omega, phi, chi) in degrees, floating.
 *				  to:
 *					kang (omega, phi, kappa) in degrees, floating.
 */

/*
 *	Return a - n * 2 * r, where -1 <= betw/r < 1
 */

double	betw(a,r)
double	a;
double	r;
  {
	int	sign1,ipart;
	double	c1,c2,c3;

	if(a < 0)
		c1 = -r;
	  else
		c1 = r;
	c2 = (a + c1) / (2 * r);
	if(c2 < 0)
		sign1 = -1;
	  else
		sign1 = 1;
	ipart = (int)(fabs(c2));
	c3 = a - 2 * r * sign1 * ipart;
	if(c3 / r >= 1.0)
		c3 = -r;
	return(c3);
  }

/*
 *	Cannonical constants.
 *
 *	k_con1:		1 - cos**2(kappa_offset)
 *	k_con2:		cos(kappa_offset) (~ 50 degrees).
 *	k_con3:		cos(89.98)
 */

float	k_con1;
float	k_con2;
float	k_con3;

#define	PI	3.1415926535
#define	RADC	(PI / 180.)

ktoe(kang,eang)
float	kang[3],eang[3];
  {
	double	om_e,phi_e,chi_e;
	double	om_k,phi_k,kap_k;
	double	si,co;

	om_k = kang[0];
	phi_k = kang[1];
	kap_k = kang[2];

	kap_k = betw(kap_k, 180.);
	si = k_con2 * sin(.5 * kap_k * RADC);
	co = cos(.5 * kap_k * RADC);
	si = 180 * atan2(si,co) / PI;

#ifdef  NONIUS_SENSE
	om_e = om_k + si;
#else
	om_e = om_k - si;
#endif	/* NONIUS_SENSE */
	
	phi_e = phi_k + si;
	om_e = betw(om_e, 180.);
	phi_e = betw(phi_e, 180.);

	si = sqrt(k_con1) * sin(.5 * kap_k * RADC);
	co = sqrt(fabs(1.0 - si * si));
	chi_e = 360. * atan2(si, co) / PI;

	eang[2] = chi_e;
	eang[1] = phi_e;
	eang[0] = om_e;
  }

etok(eang,kang)
float	eang[3],kang[3];
  {
	double	om_e,phi_e,chi_e;
	double	om_k,phi_k,kap_k;
	double	si,co;

	chi_e = eang[2];
	phi_e = eang[1];
	om_e = eang[0];

	chi_e = betw(chi_e,180.);
	si = sin(.5 * chi_e * RADC);
	co = k_con1 - si * si;

	if(k_con3 > co)
	  {
	    kap_k = 180.;
	    om_k = 90.;
	  }
	 else
	  {
	    co = sqrt(co);
	    kap_k = 360 * atan2(si,co) / PI;
	    si = si * k_con2;
	    om_k = 180 * atan2(si,co) / PI;
	  }
	phi_k = phi_e - om_k;

#ifdef  NONIUS_SENSE
	om_k = -om_k + om_e;
#else
	om_k =  om_k + om_e;
#endif  /* NONIUS_SENSE */

	phi_k = betw(phi_k, 180.);
	om_k = betw(om_k, 180.);

	kang[0] = om_k;
	kang[1] = phi_k;
	kang[2] = kap_k;
  }

kappa_init(deg)
double	deg;
  {

	k_con2 = cos(deg * RADC);
	k_con1 = 1 - k_con2 * k_con2;

	k_con3 = cos(89.98 * RADC);
  }

#ifdef MAIN
main(argc,argv)
int	argc;
char	*argv[];
  {
	char	line[132],opt;
	float	a[3],b[3];

	if(argc != 2)
	  {
	    fprintf(stderr,"Usage: test_kappa kappa_offset\n");
	    exit(0);
	  }

	kappa_init(atof(argv[1]));

	while(NULL != fgets(line,sizeof line,stdin))
	  {
	    sscanf(line,"%c %f%f%f",&opt,&a[0],&a[1],&a[2]);
	    if(opt == 'e')
	      {
		etok(a,b);
		fprintf(stdout,"convert eulerian (om, phi, chi  ) : (%10.3f, %10.3f, %10.3f)\n",a[0],a[1],a[2]);
		fprintf(stdout,"     to kappa    (om, phi, kappa) : (%10.3f, %10.3f, %10.3f)\n",b[0],b[1],b[2]);
	      }
	     else if(opt == 'k')
	      {
		ktoe(a,b);
		fprintf(stdout,"convert kappa    (om, phi, kappa) : (%10.3f, %10.3f, %10.3f)\n",a[0],a[1],a[2]);
		fprintf(stdout,"     to eularian (om, phi, chi  ) : (%10.3f, %10.3f, %10.3f)\n",b[0],b[1],b[2]);
	      }
	     else if(opt == 'i')
	      {
		ktoe(a,b);
                fprintf(stdout,"convert kappa    (om, phi, kappa) : (%10.3f, %10.3f, %10.3f)\n",a[0],a[1],a[2]);
                fprintf(stdout,"     to eularian (om, phi, chi  ) : (%10.3f, %10.3f, %10.3f)\n",b[0],b[1],b[2]);
		b[1] = b[1] + 180;
		b[2] = - b[2];
		if(b[1] > 360)
			b[1] -= 360;
		if(b[1] < -360)
			b[1] += 360;
                fprintf(stdout,"invb to eularian (om, phi, chi  ) : (%10.3f, %10.3f, %10.3f)\n",b[0],b[1],b[2]);
		etok(b,a);
                fprintf(stdout,"invb    kappa    (om, phi, kappa) : (%10.3f, %10.3f, %10.3f)\n",a[0],a[1],a[2]);
	      }
	  }
	exit(0);
  }
#endif /* MAIN */
