/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

/* analyzePeak.c
 * Zachary Anderson
 * ERULF at SLAC Summer '02
 *
 * A cubic smoothing spline is fit to data. The extrema of the spline are
 * found, and the second derivative is analyzed to find inflection points
 * about the maximum. If inflection points about the maximum exist, they
 * are found exactly along with some usefull ratios.  Scans wich do not 
 * have a well defined maximum and peak are identified as bad, and an error
 * message is returned.
 * In a later version The FWHM points are also located 
 *
 * Scans are rejected as bad if they fail any one criteria. 
 * 1. The data must contain at least n/3 non-zero points. Later changed to 
 *    n/4 to accommodate scans with small beams
 * 2. The maximum may not be on the boundry of the domain.
 * 3. Intervals containing inflection points must be found
 *    about the maximum. There must be at least one interval
 *    between the inflection points where the second derivative
 *    is negative over the entire interval (ie. '+--+').
 * 4. Inflection points and FWHM points about the maximum may not be at the
 *    boundry of the domain.
 * 5. The actual distance between inflection points must be 
 *    larger than the input parameter wmin.
 * 6. The actual distance between inflection points must be
 *    smaller than the input parameter wmax.
 * 7. The ratio of the max to the min scaled by the flux must 
 *    be larger than the input parameter rho.
 * 8. The ratios of the gradients at the left and right inflection 
 *    points to the maximum must be smaller and larger than the
 *    input parameters glc and grc respectively.
 *
 *    The suggested value of wmax is large because the parameter
 *    was not used during testing. It has been included to accomodate
 *    changes to beam lines and other uses.
 * 
 * Description of parameters:
 *   
 *   n                 The number of data points
 *   xstring           A list of x values seperated by spaces delimited by
 *                     quotes where x is the independant variable.
 *   fstring           Like xstring but f values where f is the dependant
 *                     variable.
 *   flux              The flux of the beamline in Gp/s
 *   width_min         The minimum width between inflection points
 *   width_max         The maximum width between inflection points
 *   rho               The minimum value of (max/min)/flux
 *   glc               The maximum value of the gradient at the left
 *                     inflection point over the max.
 *   grc               The minimum value of the gradient at the right
 *                     inflection point over the max.
 *   verbosity         0: output just the result <x,y>
 *                     1: output everything 
 *        
 *   optimize <n> <xstring> <fstring> <flux> <width_min> <width_max> 
 *   <rho> <glc> <grc> <verbosity>
 *
 *   suggested parameters 
 *   BL      11-1          9-1           9-2       5-1 
 *  flux      120          50            70         3  
 *   wmin      .1          .15           .15       .15 
 *   wmax     1.0         1.0           1.0       1.0  
 *   rho       .15         .15           .15       .15 
 *   glc       11          11            11        11  
 *   grc      -12         -12           -12       -12  
 */

#include "xos.h"
#include <tcl.h>
#include <tk.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "cubgcv.h"
#include "analyzePeak.h"

#define max(a,b) ((a > b) ? (a) : (b))

/*  Counts number of non-zero elements of f. */
int nonzero(double *f,int n);

/*
 * 
 * Finds extrema of the spline defined by x,y,cc.
 * returns results in max_ and min_.
 *
 */
int find_extrema(int n, double *x,double *y, double **c,
		 double *maxf, double *maxx, int *maxi,
		 double *minf, double *minx, int *mini);

//Locates FWHM 

int hmps(int n,int maxi,double maxf, double minf, double **c, double *x,double *y, double *hmax, double *fwhmr, double *fwhml);

/*
 * 
 * Locates inflection points around the maximum in interval maxi of the spline
 * defined by x,y,cc. 
 * Returned Values:
 * j is the interval containing the left inflection point
 * k-1 "" right ""
 * infl is the x value of the left inflection point
 * infr "" right ""
 * ivl is the value of the left inflection point
 * ivr "" right ""
 * ilp is the gradient at the left infleciton point
 * irp "" right ""
 * 
 */

int ips(int n,int maxi, double **c, double *x, double *y,
	int *j,int *k,double *infl,
	double *infr,double *ivl,double *ivr,
	double *ilp,double *irp); 

/* use gathered information to make a decision. */
int decide(int j,int k,int n,double maxf,double minf,double infl,
	   double infr,double ilp,double irp,double flux,
	   double rho,double wmin,double wmax,double glc, double grc);

/* free malloced memory */
void cleanup(double *x,double *y,double *f,double *df,
	     double **wk1,double **wk2,double *wk3,double *wk4,
	     double **c,double *se);

DECLARE_TCL_COMMAND(analyzePeak)
	{
	int ic,job,ier,maxi,j,k,result;
	int verbose,mini,nzero,i;

	double *x,*f,*y,*df,**c,**wk1,**wk2,*wk3,*wk4,*se;
	double var,wmin,wmax,flux,maxf,maxx;
	double minf,minx,infl,infr,ivl,ivr,hmax,fwhmr,fwhml;
	double ilp,irp;
	double rho,glc,grc;

	char buf[250];	

	int num, numF;
	char **pointPtrX, **pointPtrY;
  
	/* make sure there are the right number of args */  
	if ( argc != 10 )
		{
		Tcl_SetResult(interp,"Wrong number of arguments: should be xpoints fpoints flux wmin wmax rho glc grc verbose",TCL_STATIC);
		return TCL_ERROR;
		}

	/* get command line args */
	flux = atof(argv[3]);
	wmin = atof(argv[4]);
	wmax = atof(argv[5]);  
	rho = atof(argv[6]);
	glc = atof(argv[7]);
	grc = atof(argv[8]);
	verbose = atoi(argv[9]);  

	/* initialize */
	job = 1;
	var = -1.0;

	/* parse X and F input strings*/
	Tcl_SplitList(interp, argv[1], &num, &pointPtrX);
	Tcl_SplitList(interp, argv[2], &numF, &pointPtrY);

	if ( num == numF ) 
		{
		//allocate enough space for the floating point numbers
		x = (double*)malloc((num+1) * sizeof(double));
		f = (double*)malloc((num+1) * sizeof(double));
		
		for ( i=0; i < num; i++)
			{
			f[i+1] = atof( pointPtrY[i] );
			x[i+1] = atof( pointPtrX[i] );
			if (verbose)
				{
				printf ("%d] %lf %lf\n",i+1, x[i+1], f[i+1]);
				};
			}

		Tcl_Free((char*) pointPtrX );
		Tcl_Free((char*) pointPtrY );
		}
	else
		{
		//The number of X and F points are not the same in the passed strings.
		Tcl_Free((char*) pointPtrX );
		Tcl_Free((char*) pointPtrY );
		
		Tcl_SetResult(interp,"UnmatchedPoints",TCL_STATIC);
		return TCL_ERROR;
		}


	if (verbose)
		{
		printf("%d\n%f %f %f %d %f %f %f\n %f %d\n",
				 num,flux,wmin,wmax,verbose,rho,glc,grc,var,job);
		}
	
	/* count nonzero datapoints */
	//They should be less than 1/4 of the total (set arbitrarily)
	nzero = nonzero(f, num);

	if (nzero <= num/4)
		{
		free(x);
		free(f);

		Tcl_SetResult(interp,"TooFewPoints",TCL_STATIC);
		return TCL_ERROR;
		}

	ic = num-1;

	//allocate memory for calculations
	y = (double*)malloc((num+1) * sizeof(double));
	df = (double*)malloc((num+1) * sizeof(double));
	c = (double**)malloc(3 * sizeof(double *));
	for(i=0;i<3;i++) c[i] = (double*)malloc((ic+1)*sizeof(double));
	wk1 = (double**)malloc(3 * sizeof(double *));
	for(i=0;i<3;i++) wk1[i] = (double*)malloc((num+3)*sizeof(double));
	wk2 = (double**)malloc(2 * sizeof(double *));
	for(i=0;i<2;i++) wk2[i] = (double*)malloc((num+3)*sizeof(double));
	wk3 = (double*)malloc((num+3) * sizeof(double));
	wk4 = (double*)malloc((num+3) * sizeof(double));
	se = (double*)malloc((num+1) * sizeof(double));
	for(i=0;i<=num;i++) df[i] = 1.0;
	
	/* fit cubic spline */
	if (!cubgcv(x,f,df,num,y,c,ic,&var,job,se,wk1,wk2,wk3,wk4,&ier))
		{
		/* raise exception */
		cleanup(x,y,f,df,wk1,wk2,wk3,wk4,c,se);
		Tcl_SetResult(interp,"CUBGCVFailed",TCL_STATIC);
		return TCL_ERROR;
		}

	/* output if verbose == 1 */
	if (verbose == 1)
		{
		printf(" cubgcv test driver results\n");
		printf("ier=%d\n var=%e\n gcv=%e\n msr=%f\n rdf=%f\n",
				 ier,var,wk1[0][2],wk1[0][3],wk1[0][1]);
		printf("input                          output\n");
		printf("I     x(i)     f(i)    y(i)");
		printf("    se(i)       c[0][i]       c[1][i]");
		printf("      c[2][i]\n");
		for(i=1;i<num;i++)
			printf("%4d %f %f %f %e %e %e %e\n",
					 i,x[i],f[i],y[i],se[i],c[0][i],c[1][i],c[2][i]);
		printf("%4d %f %f %f %e\n",num,x[num],f[num],y[num],se[num]);
		}

	/* find extrema */
	if (!find_extrema( num,x,y,c,&maxf,&maxx,&maxi,&minf,&minx,&mini))
		{
		/* raise exception */	
		cleanup(x,y,f,df,wk1,wk2,wk3,wk4,c,se);
		Tcl_SetResult(interp,"FindExtremaFailed",TCL_STATIC);
		return TCL_ERROR;
		}

	if (verbose == 1)
		{
		printf("max i       max x       max\n");
		printf("%d    %f    %f\n",maxi,maxx,maxf);
		printf("min i       min x       min\n");
		printf("%d    %f    %f\n",mini,minx,minf);
		}

	if (maxi > 1 && maxi < num )
	  {

	    //verify and print fwhm  
	    switch (hmps(num,maxi,maxf,minf,c,x,y,&hmax,&fwhmr,&fwhml)) {
		 case 1:	    
			if ( verbose )
				{
				printf("HMf       FWHML          FWHMR          HMwidth\n");
				printf("%f    %f    %f    %f\n",hmax,fwhml,fwhmr,fwhmr-fwhml);
				}

	    case -1:
	      Tcl_SetResult(interp,"NoInfAfterPeak",TCL_STATIC);
	      result = TCL_ERROR;
	      break;
	    case -2:
	      Tcl_SetResult(interp,"NoInfBeforePeak",TCL_STATIC);
	      result = TCL_ERROR;
	      break;
	    default:
	      /* The result was bad, raise exception */
	      Tcl_SetResult(interp,"NoInfPoints",TCL_STATIC);
	      result = TCL_ERROR;
	    }

	    /* verify second derivative, find ips */
	    switch (ips(num,maxi,c,x,y,&j,&k,&infl,&infr,&ivl,&ivr,&ilp,&irp)) {
	    case 1:
	      /* The result was good and found ips*/
	      if ( verbose )
		{
		  printf("infl          infr          width\n");
		  printf("%f    %f    %f\n",infl,infr,infr-infl);
		  printf("ivl          ivr\n");
		  printf("%f    %f\n",ivl,ivr);
		  printf("max/min          (max/min)/flux\n");
		  printf("%f    %f\n",maxf/max(minf,1.0),(maxf/max(minf,1.0))/flux);
		  printf("ilp          irp\n");
		  printf("%f    %f\n",ilp/maxf,irp/maxf);
		}
	      
	      /* decide what to do */
	      switch ( decide(j,k,num,maxf,minf,infl,infr,ilp,irp,flux,rho,wmin,wmax,glc,grc))
		{
		case -1:
		  Tcl_SetResult(interp,"NoSigMax",TCL_STATIC);
		  result = TCL_ERROR;
		  break;
		case -2:
		  Tcl_SetResult(interp,"TooNarrow",TCL_STATIC);
		  result = TCL_ERROR;
		  break;
		case -3:
		  Tcl_SetResult(interp,"TooWide",TCL_STATIC);
		  result = TCL_ERROR;
		  break;
		case -4:
		  Tcl_SetResult(interp,"TooSteep",TCL_STATIC);
		  result = TCL_ERROR;
		  break;
		case -5:
		  Tcl_SetResult(interp,"NoGoodMax",TCL_STATIC);
		  result = TCL_ERROR;
		  break;
		case 1:
		  sprintf(buf,"%f %f %f %f",maxx,maxf,fwhml,fwhmr);
		  Tcl_SetResult(interp,buf,TCL_STATIC);    
		  result = TCL_OK;
		  break;
		default:
		  Tcl_SetResult(interp,"UnknownResult",TCL_STATIC);
		  result = TCL_ERROR;
		}
	      break;

	    case -1:
	      Tcl_SetResult(interp,"NoInfAfterPeak",TCL_STATIC);
	      result = TCL_ERROR;
	      break;
	    case -2:
	      Tcl_SetResult(interp,"NoInfBeforePeak",TCL_STATIC);
	      result = TCL_ERROR;
	      break;
	    default:
	      /* The result was bad, raise exception */
	      Tcl_SetResult(interp,"NoInfPoints",TCL_STATIC);
	      result = TCL_ERROR;
	    }
	  }
	else
		{
		/* raise exception */
		Tcl_SetResult(interp,"MaxOnEdge",TCL_STATIC);
		result = TCL_ERROR;
		}
	
	cleanup:
	/* free the intermediate results */
	cleanup(x,y,f,df,wk1,wk2,wk3,wk4,c,se);
	
	return result;
	}

int nonzero(double *f,int n)
	{
	int i, nzero = 0;

	for(i=1;i<=n;i++)
		{
		if(f[i]>0.0) nzero++;
		}

	return nzero;
	}

int find_extrema(int n, double *x,double *y, double **c,
		 double *maxf, double *maxx, int *maxi,
		 double *minf, double *minx, int *mini)
	{
	int inrange1,inrange2,i;
	double d,root1,root2,ex1,ex2;
  
	*maxf = y[1];
	*maxx = x[1];
	*maxi = 1;
	*minf = y[1];
	*minx = x[1];
	*mini = 1;

	//Initialiting root1,root2,ex1,ex2, just in case...
	root1 = 0.0;
	root2 = 0.0;
	ex1 = 0.0;
	ex2 = 0.0;


	for(i=1;i<n;i++)
		{
		d = 4.*c[1][i]*c[1][i]-12.*c[2][i]*c[0][i];
		if(d > 0. && c[2][i] != 0.)
			{
			root1 = (-2.*c[1][i]+sqrt(d))/(6.*c[2][i]);
			root2 = (-2.*c[1][i]-sqrt(d))/(6.*c[2][i]);
			if(root1 >= 0. && root1 <= x[i+1]-x[i])
				{
				inrange1 = 1;
				ex1 = ((c[2][i]*root1+c[1][i])*root1+c[0][i])*root1 + y[i];
				}
			else
				{
				inrange1 = 0;
				}
			if (root2 >= 0. && root2 <= x[i+1]-x[i])
				{
				inrange2 = 1;
				ex2 = ((c[2][i]*root2+c[1][i])*root2+c[0][i])*root2 + y[i];
				}
			else
				{
				inrange2 = 0;
				}
			if (inrange1)
				{
				if (ex1 > *maxf)
					{
					*maxf = ex1;
					*maxx = root1 + x[i];
					*maxi = i;
					}
				if (ex1 < *minf)
					{
					*minf = ex1;
					*minx = root1 + x[i];
					*mini = i;
					}
				}
			if (inrange2)
				{
				if (ex2 > *maxf)
					{
					*maxf = ex2;
					*maxx = root2 + x[i];
					*maxi = i;
					}
				if (ex2 < *minf)
					{
					*minf = ex2;
					*minx = root2 + x[i];
					*mini = i;
					}
				}
			}
		else if (c[2][i] == 0.)
			{
			if (c[1][i] != 0.)
				{
				root1 = -c[0][i]/(2.*c[1][i]);
				if (root1 >= 0. && root1 <= x[i+1]-x[i])
					{
					inrange1 = 1;
					ex1 = (c[1][i]*root1 + c[0][i])*root1 + y[i];
					}
				else
					{
					inrange1 = 0;
					}
				if (inrange1)
					{
					if (ex1 > *maxf)
						{
						*maxf = ex1;
						*maxx = root1 + x[i];
						*maxi = i;
						}
					if (ex1 < *minf)
						{
						*minf = ex1;
						*minx = root1 + x[i];
						*mini = i;
						}
					}
				}
			else if (c[1][i] == 0. && c[0][i] == 0.)
				{
				ex1 = y[i];
				if(ex1 > *maxf) {
				*maxf = ex1;
				*maxx = root1 + x[i]; //Is root1 defined for sure?
				*maxi = i;
				}
				if (ex1 < *minf)
					{
					*minf = ex1;
					*minx = root1 + x[i];
					*mini = i;
					}
				}
			}
		}

	if (y[n] > *maxf)
		{
		*maxf = y[n];
		*maxx = x[n];
		*maxi = n;
		}

	if (y[n] < *minf)
		{
		*minf = y[n];
		*minx = x[n];
		*mini = n;
		}
	
	return 1;
	}

int hmps(int n,int maxi,double maxf, double minf, double **c, double *x,double *y, double *hmax, double *fwhmr, double *fwhml)
{
  int finished, fj,fk, j,k,good;
  double roota,rootb;

  //Find half maximum
  good = 0;
  finished = 0;
  j = maxi;
  k = maxi;
  fj = 0;
  fk = 0;
  roota = 0.0;
  rootb = 0.0;

  *hmax = (maxf + minf)/2;
  *fwhmr = 0.0;
  *fwhml = 0.0;

  while((j > 0 || k < n) && !finished)
    {
      if(j > 0 && j < n)
	{
	  if( *hmax < y[j]) 
	    {
	      printf("%f %f \n",y[j],*hmax);

	      (j)--;
	    }
	  else
	    {
	      fj=1;
	    }
	}
      if(k > 0 && k < n)
	{

	  if( *hmax < y[k] )
	    {
	      printf("%f %f \n",y[k], *hmax);

	      (k)++;
	    }
	  else
	    {
	      fk = 1;
	    }
	}
      
      if (fj == 1 && fk == 1) finished = 1;
      else if(j <= 1 && k >= n) finished = 1;
      else if(j <= 1 && fk == 1) finished = 1;
      else if(k >= n && fj == 1) finished = 1;
  

    }

  //  if (*fwhml != 0.0 && *fwhmr != 0.0)  
     if (fj == 1 && fk == 1)    {
           good = 1;
	   //           roota = (-2.*c[1][j])/(6.*c[2][j]);
	   //           rootb = (-2.*c[1][k])/(6.*c[2][k]);
	   //           *fwhml = roota + x[j];
	   //           *fwhmr = rootb + x[k];
	   *fwhml = x[j];
	   *fwhmr = x[k];
    }
  else
    if (fj) {
      good = -1;
    } else if (fk) {
      good = -2;
    }
 
  return good;
}



int ips(int n,int maxi,double **c,double *x,double *y,
		  int *j,int *k,double *infl,
		  double *infr,double *ivl,double *ivr,
		  double *ilp,double *irp)
	{
	int finished,fj,fk,ns,good;
	double root1,root2;
       
	*j = maxi;
	*k = maxi + 1;
	good = 0;
	finished = 0;
	fj = 0;
	fk = 0;
	ns = 0;
	
	

	while((*j > 0 || *k < n) && !finished)
		{
		if(*j > 0 && *j < n)
			{
			if(c[1][*j] <= 0.) 
				{
				(*j)--;
				ns++;
				}
			else
				{
				fj=1;
				}
			}
		if(*k > 0 && *k < n)
			{
			if(c[1][*k] <= 0.)
				{
				(*k)++;
				ns++;
				}
			else
				{
				fk = 1;
				}
			}

		if (fj == 1 && fk == 1) finished = 1;
		else if(*j <= 1 && *k >= n) finished = 1;
		else if(*j <= 1 && fk == 1) finished = 1;
		else if(*k >= n && fj == 1) finished = 1;
		}


	/* Accept ns =1 - some scans are weird-shaped! */ 
	good = (ns >= 1) && (fj == 1) && (fk == 1);
  
	if (good)
		{
		root1 = (-2.*c[1][*j])/(6.*c[2][*j]);
		root2 = (-2.*c[1][*k-1])/(6.*c[2][*k-1]);
		*ivl = ((c[2][*j]*root1+c[1][*j])*root1+c[0][*j])*root1 + y[*j];
		*ivr = ((c[2][*k-1]*root2+c[1][*k-1])*root2+c[0][*k-1])*root2 + y[*k-1];
		*infl = root1 + x[*j];
		*infr = root2 + x[*k-1];
		*ilp = 3.*c[2][*j]*root1*root1+2.*c[1][*j]*root1+c[0][*j];
		*irp = 3.*c[2][*k-1]*root2*root2+2.*c[1][*k-1]*root2+c[0][*k-1];
		}
    else {
        /* no possible that ns == 0 but (fd == 1 and fk == 1) */
        if (fj) {
            good = -1;
        } else if (fk) {
            good = -2;
        }
    }
	return good;
	}


int decide(int j, int k,int n,double maxf,double minf,double infl,
			  double infr,double ilp,double irp,double flux,
			  double rho,double wmin,double wmax, double glc, double grc)
	{
	if((maxf/max(minf,1.))/flux < rho) return -1;
	if(infr - infl < wmin) return -2;
	if(infr - infl > wmax) return -3;
	if(ilp/maxf > glc || irp/maxf < grc) return -4; 
	if(j == 1 || k == n) return -5;
	return 1;
	}

void cleanup(double *x,double *y,double *f,double *df,
				 double **wk1,double **wk2,double *wk3,double *wk4,
				 double **c,double *se)
	{
	int i;
  
	free(x);
	free(y);
	free(f);
	free(df);
	free(wk3);
	free(wk4);
	free(se);
	for(i=0;i<3;i++) free(c[i]);
	free(c);
	for(i=0;i<3;i++) free(wk1[i]);
	free(wk1);
	for(i=0;i<2;i++) free(wk2[i]);
	free(wk2);
	}
