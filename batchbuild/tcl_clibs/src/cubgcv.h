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

int cubgcv(double *x, double *f, double *df, int n, 
	   double *y, double **c, int ic, double *var, 
	   int job, double *se, double **wk1,double **wk2,
	   double *wk3, double *wk4, int *ier);


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
	   int ic, double **r, double **t, int *ier);


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
	   double *v);

/* CALCULATES BAYESIAN ESTIMATES OF THE STANDARD ERRORS OF THE FITTED */
/* VALUES OF A CUBIC SMOOTHING SPLINE BY CALCULATING THE DIAGONAL ELEMENTS */
/* OF THE INFLUENCE MATRIX. */

int sperr1(double *x, double *avh, double *dy, int n, 
	   double **r, double *p, double *var, double *se);

/* CALCULATES COEFFICIENTS OF A CUBIC SMOOTHING SPLINE FROM */
/* PARAMETERS CALCULATED BY SUBROUTINE SPFIT1. */

int spcof1(double *x, double *avh, double *y, double *dy, 
	   int n, double *p, double *q, double *a, 
	   double **c, int ic, double *u, double *v);











