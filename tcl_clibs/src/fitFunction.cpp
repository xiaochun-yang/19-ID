/*Creator: John Rabedeau
 */

#include <vector>
#include <string>
#include <cstring>
#include <tcl.h>
#include "fitFunction.h"
#include "decimalnum.h"
#include "linearRegression.h"

/*
 * Variable Name: FIT_POWER
 * ------------------------
 *
 * Unique Specifications: This is either 3 or 5.
 *
 * Usage: This is the power of the trendline fit. The program runs linearly 
 * with this value, consequently, it is restricted to values of 3 and 5.
 */

short FIT_POWER;

static LinearRegression myEngine;

/*
 * Function Name: rref
 * -------------------
 *
 * Unique Specifications: This function runs in cubic time with respect to the 
 * power, another reason to not have a large power.
 *
 * Usage: This row-reduces the passed in grid. As a refresher on row reducing 
 * matrices, here's how the function works: For each variable, it checks if
 * there exists a non-zero value in the diagonal cell. If not, then the rows of
 * the matrix are switched such that there is a non-zero diagonal value 
 * (unless no valid switch exits). Fortunately, for this solution to find the 
 * minimum Sum Squared Error, there should always be a valid switch. After 
 * verifying an entry in the diagonal, it scales the row such that the 
 * diagonal has a value of 1. Then, it subtracts itself from all other rows 
 * until it is the only row with a non-zero value in the diagonal's column. It 
 * repeats for all variables until it is a diagonal, row reduced matrix. I 
 * chose to use vector<vector<num> > format instead of num[][] for the matrix 
 * because of the built in swap function.
 */

static void rref(vector<vector<DecimalNum> > &equation){
  for(short i=0; i<= FIT_POWER; i++){
    if(equation[i][i] == 0){
      for(int k=i; k<= FIT_POWER; k++){
	if(equation[k][i] != 0){
	  equation[i].swap(equation[k]);
	  break;
	}
      }
    }
    if(equation[i][i] != 0){
      DecimalNum Icoef = equation[i][i];
      for(short j=0; j <= FIT_POWER+1; j++)
	equation[i][j] /= Icoef;
      for(short k = 0; k <= FIT_POWER; k++)
	if(k!= i)
	  for(short j = FIT_POWER+1; j>= i; j--)
	    equation[k][j] -= (equation[k][i] * equation[i][j]);
    }
  }
}

/*
 * Function Name: findTrendline
 * ----------------------------
 *
 * Unique Specifications: None
 *
 * Usage: From linear algebra, it is known that the trendline of a data series
 * can be acquired through the row reduced form of the (N+1) X (N+2) matrix 
 * (where N is the power of the trendline). Each column represents the values 
 * of A, B, C, ... Y. Each row is the partial derivative of the Sum-Squared 
 * Error equation with respect to the ith variable (ex. the first row is the 
 * partial derivative of the SSE equation with respect to A). The actual 
 * formual for the matrix can be found online. Apart from the matrix, the range
 * of the data must be stored in memory. Once the matrix is acquired, the 
 * row-reduced form (rref) is computed. The rref of the matrix contains the 
 * equation for the trendline as the entries in the last cell, each of which 
 * are stored and returned in vector format.
 *
 * One possible location to find this equation (and the theory behind it) is:
 *
 * http://mathworld.wolfram.com/LeastSquaresFitting.html
 *
 * Article Citation:
 *
 * Weisstein, Eric W. "Least Squares Fitting." From MathWorld--A Wolfram Web
 * Resource. <http://mathworld.wolfram.com/LeastSquaresFitting.html>
 */

static vector<DecimalNum> findTrendline(vector<pair<DecimalNum, DecimalNum> > &data, string & errorstring){
  vector<vector<DecimalNum> > equation;
  for(short i= 0; i<= FIT_POWER; i++){
    vector<DecimalNum> temp;
    for(short j=0; j<= FIT_POWER+1; j++){
      DecimalNum num;
      temp.push_back(num);
    }
    equation.push_back(temp);
  }
  equation[0][0] = data.size();
  DecimalNum xmin = data[0].first;
  DecimalNum xmax = data[data.size() - 1].first;
  for(unsigned short s = 0; s < data.size(); s++){
    for(short i = 0; i <= FIT_POWER; i++){
      for(short j= 0; j<= FIT_POWER; j++)
	if(i != 0 || j != 0)
	  equation[i][j] += pow(data[s].first, i+j);
      equation[i][FIT_POWER+1] += (pow(data[s].first, i) * data[s].second);
    }
  }
  rref(equation);
  for(short s = 0; s <= FIT_POWER; s++)
    for(short t = 0; t <= FIT_POWER; t++)
      if((s != t) && (equation[s][t] != DecimalNum()))
	errorstring = "Unexpected error occurred during row reduction.";
  vector<DecimalNum> coef;
  for(short i=0; i <= FIT_POWER; i++)
    coef.push_back(equation[i][FIT_POWER+1]);
  return coef;
}

/*
 * Function Name: getVal
 * ---------------------
 *
 * Unique Specifications: None
 *
 * Usage: This function takes in an x coordinate and a function and computes 
 * the value of that function. The values are returned as a coordinate.
 */

pair <DecimalNum, DecimalNum> getVal(DecimalNum valX, vector<DecimalNum> &function){
  DecimalNum valY;
  for(unsigned short s = 0; s < function.size(); s ++)
    valY += (pow(valX, s) * function[s]);
  pair<DecimalNum, DecimalNum> returned = make_pair(valX, valY);
  return returned;
}

/*
 * Variable Name: maximum
 * ----------------------
 * 
 * Unique Specifications: None
 *
 * Usage: This returns the maximum value of two elements.
 */

#define maximum(one, two) ((one > two) ? (one) : (two))

/*
 * Variable Name: minimum
 * ----------------------
 * 
 * Unique Specifications: None
 *
 * Usage: This returns the minimum value of two elements.
 */

#define minimum(one, two) ((one < two) ? (one) : (two))

/*
 * Variable Name: fit
 * ------------------
 *
 * Unique Specifications: This function is called by poly3rdFit and poly5thFit.
 * It returns 0 if the fit was good, and 1 if there was an error in 
 * row-reducing the Sum Squared Error equation.
 *
 * Usage: This finds the coefficients of the trendline for the given data
 * points. If the subroutine does not encounter an error, then this will 
 * return 0 signifying success. If an error occurs, this returns a positive 
 * value to indicate some type of failure. If there was no error, the 
 * trendline coefficients are stored in the passed in doubles (a, b,..., f) 
 * as is the absolute value of the maximum error (in maxAbsError).
 */

int fit(double & a, double & b, double & c, double & d, double & e, double & f, string x[], string y[], int numPoints, short power, double & maxAbsError){
  FIT_POWER = power;
  vector<pair<DecimalNum, DecimalNum> > data;
  for(short s = 0; s < numPoints; s ++){
    DecimalNum xval = StringToNum(x[s]);
    DecimalNum yval = StringToNum(y[s]);
    pair<DecimalNum, DecimalNum> coord = make_pair(xval, yval);
    data.push_back(coord);
  }
  string errorstring = "";
  vector<DecimalNum> coefficients = findTrendline(data, errorstring);
  for(unsigned short s = 0; s < data.size(); s ++){
    DecimalNum delta = absoluteValue(getVal(data[s].first, coefficients).second - StringToNum(y[s]));
    maxAbsError = maximum(maxAbsError, delta);
  }
  if(errorstring != "") return 1;
  a = coefficients[0];
  b = coefficients[1];
  c = coefficients[2];
  d = coefficients[3];
  if(power == 5){
    e = coefficients[4];
    f = coefficients[5];
  }
  return 0;
}

/*
 * Variable Name: poly3rdFit
 * -------------------------
 *
 * Unique Specifications: None
 *
 * Usage: When the user calls this a 3rd order trendline is computed using the 
 * variable fit and the trendline coefficients are returned in interp->result.
 */

DECLARE_TCL_COMMAND(poly3rdFit){
  if(argc != 3){
    sprintf(interp->result, "Wrong number of arguments. Should be: x[] y[]");
    return TCL_ERROR;
  }
  double a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, maxAbsError = 0;
  int numx, numy;
  char ** xPointer;
  char ** yPointer;
  Tcl_SplitList(interp, argv[1], &numx, &xPointer);
  Tcl_SplitList(interp, argv[2], &numy, &yPointer);
  int numPoints = minimum(numx, numy);
  string x[numPoints];
  string y[numPoints];
  for(short s = 0; s < numPoints; s ++){
    x[s] = xPointer[s];
    y[s] = yPointer[s];
  }
  Tcl_Free((char *) xPointer);
  Tcl_Free((char *) yPointer);
  int ret = fit(a, b, c, d, e, f, x, y, numPoints, 3, maxAbsError);
  switch(ret){
  case 1:
    sprintf(interp->result, "Unexpected error occurred during row reduction.");
    return TCL_ERROR;
  default:
    char buffer[180];
    sprintf(buffer, "%.16e %.16e %.16e %.16e %.16e", a, b, c, d, maxAbsError); 
    sprintf(interp->result, "%s", buffer);
    return TCL_OK;
  }
}

/*
 * Variable Name: poly5thFit
 * -------------------------
 *
 * Unique Specifications: None
 *
 * Usage: When the user calls this a 5th order trendline is computed using the 
 * variable fit and the trendline coefficients are returned in interp->result.
 */

DECLARE_TCL_COMMAND(poly5thFit){
  if(argc != 3){
    sprintf(interp->result, "Wrong number of arguments. Should be x[] y[].");
    return TCL_ERROR;
  }
  double a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, maxAbsError = 0;
  int numx, numy;
  char ** xPointer;
  char ** yPointer;
  Tcl_SplitList(interp, argv[1], &numx, &xPointer);
  Tcl_SplitList(interp, argv[2], &numy, &yPointer);
  int numPoints = minimum(numx, numy);
  string x[numPoints];
  string y[numPoints];
  for(short s = 0; s < numPoints; s ++){
    x[s] = xPointer[s];
    y[s] = yPointer[s];
  }
  Tcl_Free((char *) xPointer);
  Tcl_Free((char *) yPointer);
  int ret = fit(a, b, c, d, e, f, x, y, numPoints, 5, maxAbsError);
  switch(ret){
  case 1:
    sprintf(interp->result, "Unexpected error occurred during row reduction");
    return TCL_ERROR;
  default:
    char buffer[180];
    sprintf(buffer, "%.16e %.16e %.16e %.16e %.16e %.16e %.16e", a, b, c, d, e, f, maxAbsError); 
    sprintf(interp->result, "%s", buffer);
    return TCL_OK;
  }
}

//linear fit

DECLARE_TCL_COMMAND(poly1stFit){
  if(argc != 3){
    sprintf(interp->result, "Wrong number of arguments. Should be: x[] y[]");
    return TCL_ERROR;
  }
  double a = 0, b = 0, c = 0, d = 0, e = 0, f = 0, maxAbsError = 0;
  int numx, numy;
  char ** xPointer;
  char ** yPointer;
  Tcl_SplitList(interp, argv[1], &numx, &xPointer);
  Tcl_SplitList(interp, argv[2], &numy, &yPointer);
  int numPoints = minimum(numx, numy);
  string x[numPoints];
  string y[numPoints];
  for(short s = 0; s < numPoints; s ++){
    x[s] = xPointer[s];
    y[s] = yPointer[s];
  }
  Tcl_Free((char *) xPointer);
  Tcl_Free((char *) yPointer);
  int ret = fit(a, b, c, d, e, f, x, y, numPoints, 1, maxAbsError);
  switch(ret){
  case 1:
    sprintf(interp->result, "Unexpected error occurred during row reduction.");
    return TCL_ERROR;
  default:
    char buffer[180];
    sprintf(buffer, "%.16e %.16e %.16e", a, b, maxAbsError); 
    sprintf(interp->result, "%s", buffer);
    return TCL_OK;
  }
}

DECLARE_TCL_OBJECT_COMMAND(linearRegression) {
  Tcl_Obj * pResult = Tcl_GetObjResult( interp );
  if(objc != 5){
    static char msg[] = "Wrong arguments. Should be: x[] y[] w[] order";
    Tcl_SetStringObj( pResult, msg, strlen(msg) );
    return TCL_ERROR;
  }
  int order = 1;
  double maxAbsError = 0;
  int numx;
  int numy;
  int numw;
  Tcl_Obj ** xPointer = NULL;
  Tcl_Obj ** yPointer = NULL;
  Tcl_Obj ** wPointer = NULL;
  if (Tcl_ListObjGetElements(interp, objv[1], &numx, &xPointer) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tcl_ListObjGetElements(interp, objv[2], &numy, &yPointer) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tcl_ListObjGetElements(interp, objv[3], &numw, &wPointer) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tcl_GetIntFromObj( interp, objv[4], &order ) != TCL_OK) {
    return TCL_ERROR;
  }

  int numPoints = minimum( minimum(numx, numy), numw );

  vector<double> x(numPoints, 0);
  vector<double> y(numPoints, 0);
  vector<double> w(numPoints, 0);
  for (int i = 0; i < numPoints; ++i) {
    if (Tcl_GetDoubleFromObj( interp, xPointer[i], &x[i] ) != TCL_OK) {
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, yPointer[i], &y[i] ) != TCL_OK) {
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, wPointer[i], &w[i] ) != TCL_OK) {
        return TCL_ERROR;
    }
  }    

  if (!myEngine.Regress( x, y, w, order )) {
    static char msg[] = "regress failed";
    Tcl_SetStringObj( pResult, msg, strlen(msg) );
    return TCL_ERROR;
  }

  vector<double> coe = myEngine.getCoefficients( );
  Tcl_SetListObj ( pResult, 0, NULL );
  for (int i = 0; i < coe.size( ); ++i) {
    Tcl_ListObjAppendElement( interp, pResult, Tcl_NewDoubleObj(coe[i]) );
  }
  Tcl_ListObjAppendElement( interp, pResult, Tcl_NewDoubleObj(myEngine.getMaxError( )) );
  return TCL_OK;
}

