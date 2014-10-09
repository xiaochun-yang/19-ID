#ifndef _fitFunction_h
#define _fitFunction_h

#include "tcl_macros.h"

/*
 * Function Name: poly3rdFit
 * -------------------------
 *
 * Specifications: This returns 0 if it successfully computes a 3rd order
 * trendline and a positive number if otherwise.
 *
 * Usage: This will be called by a TCL Program. Pass in the same number of x 
 * and y coordinates and make sure that number is equal to numPoints since this
 * function will not perform bounds-checking on the data.
 */

DECLARE_TCL_COMMAND(poly3rdFit);


/*
 * Function Name: poly5thFit
 * -------------------------
 *
 * Specifications: This returns 0 if it successfully computes a 5th order
 * trendline and a positive number if otherwise.
 *
 * Usage: This will be called by a TCL Program. Pass in the same number of x 
 * and y coordinates and make sure that number is equal to numPoints since this
 * function will not perform bounds-checking on the data.
 */

DECLARE_TCL_COMMAND(poly5thFit);


/* linear fit */
DECLARE_TCL_COMMAND(poly1stFit);
DECLARE_TCL_OBJECT_COMMAND(linearRegression);
#endif

