/*     ALGORITHM 642 COLLECTED ALGORITHMS FROM ACM. */
/*     ALGORITHM APPEARED IN ACM-TRANS. MATH. SOFTWARE, VOL.12, NO. 2, */
/*     JUN., 1986, P. 150. */
/*   SUBROUTINE NAME     - CUBGCV */

/* -------------------------------------------------------------------------- */

/*   COMPUTER            - VAX/DOUBLE */

/*   AUTHOR              - M.F.HUTCHINSON */
/*                         CSIRO DIVISION OF MATHEMATICS AND STATISTICS */
/*                         P.O. BOX 1965 */
/*                         CANBERRA, ACT 2601 */
/*                         AUSTRALIA */

/*   LATEST REVISION     - 15 AUGUST 1985 */

/*   PURPOSE             - CUBIC SPLINE DATA SMOOTHER */

/*   USAGE               - CALL CUBGCV (X,F,DF,N,Y,C,IC,VAR,JOB,SE,WK,IER) */

/*   ARGUMENTS    X      - VECTOR OF LENGTH N CONTAINING THE */
/*                           ABSCISSAE OF THE N DATA POINTS */
/*                           (X(I),F(I)) I=1..N. (INPUT) X */
/*                           MUST BE ORDERED SO THAT */
/*                           X(I) .LT. X(I+1). */
/*                F      - VECTOR OF LENGTH N CONTAINING THE */
/*                           ORDINATES (OR FUNCTION VALUES) */
/*                           OF THE N DATA POINTS (INPUT). */
/*                DF     - VECTOR OF LENGTH N. (INPUT/OUTPUT) */
/*                           DF(I) IS THE RELATIVE STANDARD DEVIATION */
/*                           OF THE ERROR ASSOCIATED WITH DATA POINT I. */
/*                           EACH DF(I) MUST BE POSITIVE.  THE VALUES IN */
/*                           DF ARE SCALED BY THE SUBROUTINE SO THAT */
/*                           THEIR MEAN SQUARE VALUE IS 1, AND UNSCALED */
/*                           AGAIN ON NORMAL EXIT. */
/*                           THE MEAN SQUARE VALUE OF THE DF(I) IS RETURNED */
/*                           IN WK(7) ON NORMAL EXIT. */
/*                           IF THE ABSOLUTE STANDARD DEVIATIONS ARE KNOWN, */
/*                           THESE SHOULD BE PROVIDED IN DF AND THE ERROR */
/*                           VARIANCE PARAMETER VAR (SEE BELOW) SHOULD THEN */
/*                           BE SET TO 1. */
/*                           IF THE RELATIVE STANDARD DEVIATIONS ARE UNKNOWN, */
/*                           SET EACH DF(I)=1. */
/*                N      - NUMBER OF DATA POINTS (INPUT). */
/*                           N MUST BE .GE. 3. */
/*                Y,C    - SPLINE COEFFICIENTS. (OUTPUT) Y */
/*                           IS A VECTOR OF LENGTH N. C IS */
/*                           AN N-1 BY 3 MATRIX. THE VALUE */
/*                           OF THE SPLINE APPROXIMATION AT T IS */
/*                           S(T)=((C(I,3)*D+C(I,2))*D+C(I,1))*D+Y(I) */
/*                           WHERE X(I).LE.T.LT.X(I+1) AND */
/*                           D = T-X(I). */
/*                IC     - ROW DIMENSION OF MATRIX C EXACTLY */
/*                           AS SPECIFIED IN THE DIMENSION */
/*                           STATEMENT IN THE CALLING PROGRAM. (INPUT) */
/*                VAR    - ERROR VARIANCE. (INPUT/OUTPUT) */
/*                           IF VAR IS NEGATIVE (I.E. UNKNOWN) THEN */
/*                           THE SMOOTHING PARAMETER IS DETERMINED */
/*                           BY MINIMIZING THE GENERALIZED CROSS VALIDATION */
/*                           AND AN ESTIMATE OF THE ERROR VARIANCE IS */
/*                           RETURNED IN VAR. */
/*                           IF VAR IS NON-NEGATIVE (I.E. KNOWN) THEN THE */
/*                           SMOOTHING PARAMETER IS DETERMINED TO MINIMIZE */
/*                           AN ESTIMATE, WHICH DEPENDS ON VAR, OF THE TRUE */
/*                           MEAN SQUARE ERROR, AND VAR IS UNCHANGED. */
/*                           IN PARTICULAR, IF VAR IS ZERO, THEN AN */
/*                           INTERPOLATING NATURAL CUBIC SPLINE IS CALCULATED. */
/*                           VAR SHOULD BE SET TO 1 IF ABSOLUTE STANDARD */
/*                           DEVIATIONS HAVE BEEN PROVIDED IN DF (SEE ABOVE). */
/*                JOB    - JOB SELECTION PARAMETER. (INPUT) */
/*                         JOB = 0 SHOULD BE SELECTED IF POINT STANDARD ERROR */
/*                           ESTIMATES ARE NOT REQUIRED IN SE. */
/*                         JOB = 1 SHOULD BE SELECTED IF POINT STANDARD ERROR */
/*                           ESTIMATES ARE REQUIRED IN SE. */
/*                SE     - VECTOR OF LENGTH N CONTAINING BAYESIAN STANDARD */
/*                           ERROR ESTIMATES OF THE FITTED SPLINE VALUES IN Y. */
/*                           SE IS NOT REFERENCED IF JOB=0. (OUTPUT) */
/*                WK     - WORK VECTOR OF LENGTH 7*(N + 2). ON NORMAL EXIT THE */
/*                           FIRST 7 VALUES OF WK ARE ASSIGNED AS FOLLOWS:- */

/*                           WK(1) = SMOOTHING PARAMETER (= RHO/(RHO + 1)) */
/*                           WK(2) = ESTIMATE OF THE NUMBER OF DEGREES OF */
/*                                   FREEDOM OF THE RESIDUAL SUM OF SQUARES */
/*                           WK(3) = GENERALIZED CROSS VALIDATION */
/*                           WK(4) = MEAN SQUARE RESIDUAL */
/*                           WK(5) = ESTIMATE OF THE TRUE MEAN SQUARE ERROR */
/*                                   AT THE DATA POINTS */
/*                           WK(6) = ESTIMATE OF THE ERROR VARIANCE */
/*                           WK(7) = MEAN SQUARE VALUE OF THE DF(I) */

/*                           IF WK(1)=0 (RHO=0) AN INTERPOLATING NATURAL CUBIC */
/*                           SPLINE HAS BEEN CALCULATED. */
/*                           IF WK(1)=1 (RHO=INFINITE) A LEAST SQUARES */
/*                           REGRESSION LINE HAS BEEN CALCULATED. */
/*                           WK(2) IS AN ESTIMATE OF THE NUMBER OF DEGREES OF */
/*                           FREEDOM OF THE RESIDUAL WHICH REDUCES TO THE */
/*                           USUAL VALUE OF N-2 WHEN A LEAST SQUARES REGRESSION */
/*                           LINE IS CALCULATED. */
/*                           WK(3),WK(4),WK(5) ARE CALCULATED WITH THE DF(I) */
/*                           SCALED TO HAVE MEAN SQUARE VALUE 1.  THE */
/*                           UNSCALED VALUES OF WK(3),WK(4),WK(5) MAY BE */
/*                           CALCULATED BY DIVIDING BY WK(7). */
/*                           WK(6) COINCIDES WITH THE OUTPUT VALUE OF VAR IF */
/*                           VAR IS NEGATIVE ON INPUT.  IT IS CALCULATED WITH */
/*                           THE UNSCALED VALUES OF THE DF(I) TO FACILITATE */
/*                           COMPARISONS WITH A PRIORI VARIANCE ESTIMATES. */

/*                IER    - ERROR PARAMETER. (OUTPUT) */
/*                         TERMINAL ERROR */
/*                           IER = 129, IC IS LESS THAN N-1. */
/*                           IER = 130, N IS LESS THAN 3. */
/*                           IER = 131, INPUT ABSCISSAE ARE NOT */
/*                             ORDERED SO THAT X(I).LT.X(I+1). */
/*                           IER = 132, DF(I) IS NOT POSITIVE FOR SOME I. */
/*                           IER = 133, JOB IS NOT 0 OR 1. */

/*   PRECISION/HARDWARE  - DOUBLE */

/*   REQUIRED ROUTINES   - SPINT1,SPFIT1,SPCOF1,SPERR1 */

/*   REMARKS      THE NUMBER OF ARITHMETIC OPERATIONS REQUIRED BY THE */
/*                SUBROUTINE IS PROPORTIONAL TO N.  THE SUBROUTINE */
/*                USES AN ALGORITHM DEVELOPED BY M.F. HUTCHINSON AND */
/*                F.R. DE HOOG, 'SMOOTHING NOISY DATA WITH SPLINE */
/*                FUNCTIONS', NUMER. MATH. (IN PRESS) */

/* ----------------------------------------------------------------------- */

#include "cubgcv.h"
#include <math.h>
#include <stdlib.h>

#define max(a,b) ((a > b) ? (a) : (b))

int cubgcv(double *x, double *f, double *df, int n, 
	   double *y, double **c, int ic, double *var, 
	   int job, double *se, double **wk1,double **wk2,
	   double *wk3, double *wk4, int *ier)
{
  double ratio = 2.0;
  double tau = 1.618033989;
  double zero = 0.0;
  double one = 1.0;
  double delta,err,gf1,gf2,gf3,gf4,r1,r2,r3,r4;
  double avh,avdf,avar,*stat,p,q;

  int i;

  /* initialize */
  *ier = 133;
  if(job < 0 || job > 1) return 0;
  spint1(x,&avh,f,df,&avdf,n,y,c,ic,wk1,wk2,ier);
  if(*ier != 0) return 0;
  avar = *var;
  if(*var > zero) avar = (*var) * avdf * avdf;
  stat = (double *) malloc( 7 * sizeof(double) ); /* MALLOC stat */

  /* check for zero variance */
  if(*var != zero) goto L10; 
  r1 = zero;
  goto L90;

  /* find local minimum of gcv or the expected mean square error */
 L10:
  r1 = one;
  r2 = ratio * r1;
  spfit1(x,&avh,df,n,&r2,&p,&q,&gf2,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
 L20:
  spfit1(x,&avh,df,n,&r1,&p,&q,&gf1,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
  if(gf1 > gf2) goto L30;
  
  /* exit if p zero */
  if(p <= zero) goto L100;
  r2 = r1;
  gf2 = gf1;
  r1 = r1/ratio;
  goto L20;

 L30:
  r3 = ratio*r2;
 L40:
  spfit1(x,&avh,df,n,&r3,&p,&q,&gf3,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
  if(gf3 > gf2) goto L50;

  /* exit if q zero */
  if(q <= zero) goto L100;
  r2 = r3;
  gf2 = gf3;
  r3 = ratio*r3;
  goto L40;

 L50:
  r2 = r3;
  gf2 = gf3;
  delta = (r2 - r1) / tau;
  r4 = r1 + delta;
  r3 = r2 - delta;
  spfit1(x,&avh,df,n,&r3,&p,&q,&gf3,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
  spfit1(x,&avh,df,n,&r4,&p,&q,&gf4,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);

  /* golden section search for local minimum */
 L60:
  if(gf3 > gf4) goto L70;
  r2 = r4;
  gf2 = gf4;
  r4 = r3;
  gf4 = gf3;
  delta = delta / tau;
  r3 = r2 - delta;
  spfit1(x,&avh,df,n,&r3,&p,&q,&gf3,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
  goto L80;

 L70:
  r1 = r3;
  gf1 = gf3;
  r3 = r4;
  gf3 = gf4;
  delta = delta / tau;
  r4 = r1 + delta;
  spfit1(x,&avh,df,n,&r4,&p,&q,&gf4,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
 L80:
  err = (r2 - r1) / (r2 + r1);
  if(err*err + one > one && err > 1e-6) goto L60;
  r1 = (r1 + r2) * .5;
  
  /* calculate spline coefficients */
 L90:
  spfit1(x,&avh,df,n,&r1,&p,&q,&gf1,&avar,stat,y,c,ic,wk1,wk2,wk3,wk4);
 L100:
  spcof1(x,&avh,f,df,n,&p,&q,y,c,ic,wk3,wk4);
  
  /* optionally calculate standard error estimates */
  if(*var >= zero) goto L110;
  avar = stat[6];
  *var = avar / (avdf * avdf);
 L110:
  if( job == 1 ) sperr1(x,&avh,df,n,wk1,&p,&avar,se);

  /* unscale df */
  for(i=1;i<=n;i++) {
    df[i] = df[i] * avdf;
  }

  /* put statistics in wk */
  for(i=0;i<6;i++) { 
    wk1[0][i] = stat[i+1];
  }
  wk1[0][5] = stat[6] / (avdf * avdf);
  wk1[0][6] = avdf * avdf;

  /* check for error conditions */
 L140:
  if(*ier != 0) {
    free(stat);
    return 0;
  }
 L150:
  free(stat);
  return 1;
  
}


/* INITIALIZES THE ARRAYS C, R AND T FOR ONE DIMENSIONAL CUBIC */
/* SMOOTHING SPLINE FITTING BY SUBROUTINE SPFIT1.  THE VALUES */
/* DF(I) ARE SCALED SO THAT THE SUM OF THEIR SQUARES IS N */
/* AND THE AVERAGE OF THE DIFFERENCES X(I+1) - X(I) IS CALCULATED */
/* IN AVH IN ORDER TO AVOID UNDERFLOW AND OVERFLOW PROBLEMS IN */
/* SPFIT1. */

/* SUBROUTINE SETS IER IF ELEMENTS OF X ARE NON-INCREASING, */
/* IF N IS LESS THAN 3, IF IC IS LESS THAN N-1 OR IF DY(I) IS */
/* NOT POSITIVE FOR SOME I. */

int spint1(double *x, double *avh, double *y, double *dy, 
	    double *avdy, int n, double *a, double **c, 
	    int ic, double **r, double **t, int *ier)
{
  int i;
  double e,f,g,h,zero=0.0;

  /* initialization and input checking */
  *ier = 0;
  if( n < 3 ) {
    *ier = 130;
    return 0;
  }
  if(ic < n - 1) { 
    *ier = 129;
    return 0;
  }
  
  /* get average x spacing in avh */
  g = zero;
  for(i=1;i<n;i++) { 
    h = x[i+1] - x[i];
    if(h <= zero) {
      *ier = 131;
      return 0;
    }
    g = g + h; 
  }
  *avh = g / (n - 1);

  /* scale relative weights */
  g = zero;
  for(i=1;i<=n;i++) {
    if(dy[i] <= zero) {
      *ier = 132;
      return 0;
    }
    g = g + dy[i] * dy[i];
  }
  *avdy = sqrt(g / n);
  
  for(i=1;i<=n;i++) {
    dy[i] = dy[i] / *avdy;
  }

  /* initialize h,f */
  h = (x[2] - x[1]) / (*avh);
  f = (y[2] - y[1]) / h;

  /* calculate a,t,r */
  for(i=2;i<=n-1;i++) {
    g = h;
    h = (x[i+1]-x[i]) / (*avh);
    e = f;
    f = (y[i+1] - y[i]) / h;
    a[i] = f - e;
    t[0][i] = 2.0 * (g + h)/3.0;
    t[1][i] = h / 3.0;
    r[2][i] = dy[i-1] / g;
    r[0][i] = dy[i+1] / h;
    r[1][i] = -dy[i]/g - dy[i]/h;
  }

  /* calculate c = r'*r */
  r[1][n] = zero;
  r[2][n] = zero;
  r[2][n+1] = zero;
  for(i=2;i<=n-1;i++) {
    c[0][i] = r[0][i]*r[0][i]   + r[1][i]*r[1][i] + r[2][i]*r[2][i];
    c[1][i] = r[0][i]*r[1][i+1] + r[1][i]*r[2][i+1];
    c[2][i] = r[0][i]*r[2][i+2];
  }

  return 1;
}


/* FITS A CUBIC SMOOTHING SPLINE TO DATA WITH RELATIVE */
/* WEIGHTING DY FOR A GIVEN VALUE OF THE SMOOTHING PARAMETER */
/* RHO USING AN ALGORITHM BASED ON THAT OF C.H. REINSCH (1967), */
/* NUMER. MATH. 10, 177-183. */

/* THE TRACE OF THE INFLUENCE MATRIX IS CALCULATED USING AN */
/* ALGORITHM DEVELOPED BY M.F.HUTCHINSON AND F.R.DE HOOG (NUMER. */
/* MATH., IN PRESS), ENABLING THE GENERALIZED CROSS VALIDATION */
/* AND RELATED STATISTICS TO BE CALCULATED IN ORDER N OPERATIONS. */

/* THE ARRAYS A, C, R AND T ARE ASSUMED TO HAVE BEEN INITIALIZED */
/* BY THE SUBROUTINE SPINT1.  OVERFLOW AND UNDERFLOW PROBLEMS ARE */
/* AVOIDED BY USING P=RHO/(1 + RHO) AND Q=1/(1 + RHO) INSTEAD OF */
/* RHO AND BY SCALING THE DIFFERENCES X(I+1) - X(I) BY AVH. */

/* THE VALUES IN DF ARE ASSUMED TO HAVE BEEN SCALED SO THAT THE */
/* SUM OF THEIR SQUARED VALUES IS N.  THE VALUE IN VAR, WHEN IT IS */
/* NON-NEGATIVE, IS ASSUMED TO HAVE BEEN SCALED TO COMPENSATE FOR */
/* THE SCALING OF THE VALUES IN DF. */

/* THE VALUE RETURNED IN FUN IS AN ESTIMATE OF THE TRUE MEAN SQUARE */
/* WHEN VAR IS NON-NEGATIVE, AND IS THE GENERALIZED CROSS VALIDATION */
/* WHEN VAR IS NEGATIVE. */

int spfit1(double *x, double *avh, double *dy, int n, 
	   double *rho, double *p, double *q, double *fun, 
	   double *var, double *stats, double *a, double **c,
	   int ic, double **r, double **t, double *u, 
	   double *v)
{
  int i;
  double e,f,g,h,zero=0.0,one=1.0,two=2.0,rho1;
  
  /* use p and q instead of rho to prevent underflow and overflow */
  rho1 = one + *rho;
  *p = *rho / rho1;
  *q = one / rho1;
  if(rho1 == one) *p = zero;
  if(rho1 == *rho) *q = zero;

  /* rational cholesky decomposition of p*c + q*t */
  f = zero;
  g = zero;
  h = zero;
  r[0][0] = zero;
  r[0][1] = zero;
  for(i=2;i<=n-1;i++) {
    r[2][i-2] = g*r[0][i-2];
    r[1][i-1] = f*r[0][i-1];
    r[0][i] = one / ((*p)*c[0][i] + (*q)*t[0][i] - f*r[1][i-1] - g*r[2][i-2]);
    f = (*p)*c[1][i] + (*q)*t[1][i] - h*r[1][i-1];
    g = h;
    h = (*p)*c[2][i];
  }

  /* solve for u */
  u[0] = zero;
  u[1] = zero;
  for(i=2;i<=n-1;i++) {
    u[i] = a[i] - r[1][i-1]*u[i-1] - r[2][i-2]*u[i-2];
  }
  u[n] = zero;
  u[n + 1] = zero;
  for(i=n-1;i>=2;i--) {
    u[i] = r[0][i]*u[i] - r[1][i]*u[i+1] - r[2][i]*u[i+2];
  }
  
  /* calculate residual vector v */
  e = zero;
  h = zero;
  for(i=1;i<=n-1;i++) {
    g = h;
    h = (u[i+1]-u[i])/((x[i+1]-x[i])/ (*avh));
    v[i] = dy[i] * (h - g);
    e = e + v[i]*v[i];
  }
  v[n] = dy[n]*(-h);
  e = e+v[n]*v[n];

  /* calculate upper three bands of inverse matrix */
  r[0][n] = zero;
  r[1][n] = zero;
  r[0][n+1] = zero;
  for(i=n-1;i>=2;i--) {
    g = r[1][i];
    h = r[2][i];
    r[1][i] = -g*r[0][i+1]-h*r[1][i+1];
    r[2][i] = -g*r[1][i+1]-h*r[0][i+2];
    r[0][i] = r[0][i] - g*r[1][i] - h*r[2][i];
  }

  /* calculate trace */
  f = zero;
  g = zero;
  h = zero;
  for(i=2;i<= n-1;i++) {
    f = f + r[0][i]*c[0][i];
    g = g + r[1][i]*c[1][i];
    h = h + r[2][i]*c[2][i];
  }
  f = f + two*(g+h);
  
  /* calculate statistics */
  stats[1] = *p;
  stats[2] = f * (*p);
  stats[3] = n * e / (f*f);
  stats[4] = e*(*p)*(*p)/n;
  stats[6] = e * (*p) / f;  
  if(*var >= zero) {
    stats[5] = max(stats[4]-two*(*var)*stats[2]/(n)+(*var),zero);
    *fun = stats[5];
  }
  else {
 stats[5] = stats[6] - stats[4];
    *fun = stats[3];
  }

  return 1;
}


/* CALCULATES BAYESIAN ESTIMATES OF THE STANDARD ERRORS OF THE FITTED */
/* VALUES OF A CUBIC SMOOTHING SPLINE BY CALCULATING THE DIAGONAL ELEMENTS */
/* OF THE INFLUENCE MATRIX. */

int sperr1(double *x, double *avh, double *dy, int n, 
	   double **r, double *p, double *var, double *se)
{
  int i;
  double f,g,h,f1,g1,h1,zero=0.0,one=1.0;

  /* initialize */
  h = *avh / (x[2]-x[1]);
  se[1] = one - (*p)*dy[1]*dy[1]*h*h*r[0][2];
  r[0][1] = zero;
  r[1][1] = zero;
  r[2][1] = zero;

  /* calculate diagonal elements */
  for(i=2;i<=n-1;i++) {
    f = h;
    h = *avh / (x[i+1]-x[i]);
    g = -f - h;
    f1 = f*r[0][i-1] + g*r[1][i-1] + h*r[2][i-1];
    g1 = f*r[1][i-1] + g*r[0][i] + h*r[1][i];
    h1 = f*r[2][i-1] + g*r[1][i] + h*r[0][i+1];
    se[i] = one - (*p)*dy[i]*dy[i]*(f*f1+g*g1+h*h1);
  }
  se[n] = one - (*p)*dy[n]*dy[n]*h*h*r[0][n-1];

  /* calculate standard error estimates */
  for(i=1;i<=n;i++) {
    se[i] = sqrt(max(se[i]*(*var),zero))*dy[i];
  }
  return 1;
}


/* CALCULATES COEFFICIENTS OF A CUBIC SMOOTHING SPLINE FROM */
/* PARAMETERS CALCULATED BY SUBROUTINE SPFIT1. */


int spcof1(double *x, double *avh, double *y, double *dy, 
	    int n, double *p, double *q, double *a, 
	    double **c, int ic, double *u, double *v)
{
  int i;
  double h,qh;

  /* calculate a */
  qh = *q / ((*avh)*(*avh));
  for(i=1;i<=n;i++) {
    a[i] = y[i] - (*p)*dy[i]*v[i];
    u[i] = qh*u[i];
  }

  /* calculate c */
  for(i=1;i<=n-1;i++) {
    h = x[i+1]-x[i];
    c[2][i] = (u[i+1]-u[i])/(3.0*h);
    c[0][i] = (a[i+1]-a[i])/h - (h*c[2][i]+u[i])*h;
    c[1][i] = u[i];
  }

  return 1;
}
