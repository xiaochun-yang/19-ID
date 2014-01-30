#include <cmath>
#include <vector>
#include <string>
#include <tcl.h>
#include <cstdlib>
#include "findMax.h"

using namespace std;

/*
 * String Name: errorstring
 * ------------------------
 * 
 * Unique Specifications: None
 *
 * Usage: In the event that an error occurs, the particular error will be 
 * saved. Then, this string will be uploaded to Tcl_SetResult.
 */

string errorstring = "";

/*
 * Variable Name: TAYLOR_ACCURACY
 * ------------------------------
 *
 * Unique Specifications: This MUST be positive. 
 *
 * Usage: This is used only if the number of coefficients is greater than or 
 * equal to 4. It determines the number of points checked by the taylor series 
 * approximation to find the maximum value. The program typically runs 
 * linearly with this value, so I do not suggest increasing it. It does 
 * significantly change accuracy, so do not decrease it.
 */

static const int TAYLOR_ACCURACY = 10000;

/*
 * Variable Name: MaxValue
 * -----------------------
 *
 * Unique Specifications: Returns 1 if successful.
 *
 * Usage: This scans through a vector and saves the coordinate associated
 * with the maximum y-value contained in the vector. If the maximum point
 * is outside the appropriate bouonds, it returns 2. If the total number
 * of possible maximas is less than one, then it returns 1.
 */


int MaxValue(const vector<pair<double, double> > &possibleMax, const double &xmin, const double &xmax, double & xret, double & yret){
  pair<double, double> max;
  if (possibleMax.size() < 1) return 1;
  max = possibleMax[0];
  for(short i = 1; i < possibleMax.size(); i++)
    if(possibleMax[i].second > max.second)
      max = possibleMax[i];
  if(max.first >= xmax || max.first <= xmin)
    return 2;
  xret = max.first;
  yret = max.second;
  return 0;
}

/*
 * Function Name: getVal
 * ---------------------
 *
 * Unique Specifications: None
 *
 * Usage: This function takes in an x coordinate and a function and computes 
 * the value of that function. The values are returned as a pair.
 */

static pair<double, double> getVal(double valX, const vector<double> &function){
  double valY = 0;
  for(short i = 0; i<function.size(); i++)
    valY += (pow(valX, i) * function[i]);
  pair<double, double> returned = make_pair(valX, valY);
  return returned;
}

/*
 * Function Name: derive
 * ---------------------
 *
 * Unique Specifications: None
 *
 * Usage: This takes the derivative of a passed in function and returns the
 * derivative in vector form. 
 */

static vector<double> derive (const vector<double> &function){
  vector<double> returned;
  for(short i = 1; i < function.size(); i++)
    returned.push_back(function[i] * i);
  return returned;
}

/*
 * Function Name: quadFormula
 * --------------------------
 *
 * Unique Specifications: None
 *
 * Usage: This is the quadratic formula for a vector (assuming that values are 
 * entered in the order c b a). The formula returns values in vector format 
 * since the number of returned values varies.
 */

static vector<double> quadFormula(const vector<double> &function){
  vector<double> returned;
  if(function[2] == 0){
    errorstring = "Cannot divide by zero.";
    return returned;
  }
  double sqrted;
  sqrted = pow(function[1], 2) - (function[2] * (function[0] * 4));
  if(sqrted > 0){
    sqrted = sqrt(sqrted);
    returned.push_back(((function[1] * -1) + (sqrted)) / (function[2] * 2));
    returned.push_back(((function[1] * -1) - (sqrted)) / (function[2] * 2));
    return returned;
  }
  if(sqrted == 0){
    returned.push_back((function[1] * -1) / (function[2] * 2));
    return returned;
  }
  return returned;
}

/*
 * Variable Name: SolveMax
 * -----------------------
 *
 * Unique Specifications: If the number of coefficients > 3, a taylor series 
 * approximation is required to find the maximum point that the trendline 
 * takes over range of the data. It returns 0 if successful.
 *
 * Usage: This computes the value of the function at the two endpoints. It 
 * then computes the value at any critical point assuming that the critical 
 * point is in bounds. If MaxValue did not return 0, then this returns the 
 * same number. If errorstring is not empty, then this returns 3. Otherwise, 
 * the point is a vaild point within the given boundaries. The coordinates are 
 * then saved as xret and yret and 0 is returned.
 */

int SolveMax(vector<double> & coef, double & xmin, double & xmax, double & xret, double & yret){
  vector<pair<double, double> > posMax;
  posMax.push_back(getVal(xmin, coef));
  posMax.push_back(getVal(xmax, coef));
  double critpoint;
  vector<double> derivative = derive(coef);
  vector<double> critpnts;
  switch(coef.size() - 1){//ex: If coef.size() = 3 -> quadratic fit (case 2).
  case 2: 
    critpoint = (derivative[0] / derivative[1]) * -1;
    if(critpoint > xmin && critpoint < xmax)
      posMax.push_back(getVal(critpoint, coef));
    break;
  case 3:
    critpnts = quadFormula(derivative);
    for(int i=0; i< critpnts.size(); i++)
      if(critpnts[i] > xmin && critpnts[i] < xmax)
	posMax.push_back(getVal(critpnts[i], coef));
    break;
  default: //brute force local Max check using Taylor approximation
    bool positive = (getVal(xmin, derivative).second >= 0);
    double xcoord = xmin;
    vector<double> TaylorAppx;
    vector<double> secondDeriv = derivative;
    secondDeriv = derive(secondDeriv);
    vector<double> thirdDeriv = secondDeriv;
    thirdDeriv = derive(thirdDeriv);
    double Bigdelta = (xmax - xmin) / TAYLOR_ACCURACY;
    for(int s = 1; s < TAYLOR_ACCURACY; s ++){
      xcoord += Bigdelta;
      bool pointIsPositive = (getVal(xcoord, derivative).second >= 0);
      if(!positive && pointIsPositive)
	positive = true;
      else if(positive && !pointIsPositive){
	positive = false;
	xcoord -= Bigdelta;
	double delta = Bigdelta / TAYLOR_ACCURACY;
	for(int i = 0; i < TAYLOR_ACCURACY; i++){
	  TaylorAppx.clear();
	  TaylorAppx.push_back(getVal(xcoord, derivative).second - xcoord * getVal(xcoord, secondDeriv).second + (pow(xcoord, 2) * (getVal(xcoord, thirdDeriv).second) * .5));
	  TaylorAppx.push_back(getVal(xcoord, secondDeriv).second - xcoord * getVal(xcoord, thirdDeriv).second);
	  TaylorAppx.push_back(getVal(xcoord, thirdDeriv).second * .5);
	  critpnts = quadFormula(TaylorAppx);
	  for(short k = 0; k < critpnts.size(); k++)
	    if((critpnts[k] >= (xcoord - delta)) && (critpnts[k] <= (xcoord + delta)))
	      posMax.push_back(getVal(critpnts[k], coef));
	  xcoord += delta;
	}
      }
    }
    break;
  }
  int ret = MaxValue(posMax, xmin, xmax, xret, yret);
  if(ret == 0 && errorstring != "") ret = 3;
  return ret;	
}

/*
 * Function Name: findMax
 * ----------------------
 *
 * Unique Specifications: The user must specify a list containing coefficients
 * (if y = a + bx +cx^2, then list should be "a b c") and two doubles that are 
 * the boundaries of the maxima search (these x coordinates cannot correspond 
 * to the maximum value that the function takes in that interval).
 *
 * Usage: If not given four arguments (TCL interp and three user specified
 * arguments), then an error is raised. If there are four arguments, then the
 * second and third user-specified arguments are converted to doubles and an 
 * error is returned if the second argument is not less than the third. It then
 * splits the first argument such that each value is a double, each of which
 * is appended to the back of a vector storing the coefficients. While the last
 * value in the vector is zero, it is discarded since it does not influence the
 * outcome. If the size of the vector is less than three, the function is 
 * linear. As there is a specification that neither endpoints can be the 
 * maximum, an error is returned. Otherwise, SolveMax is called. If it raises 
 * an error, then this function returns an error. Otherwise, the results are
 * printed to TCL interp, and the function returns.
 * 
 */



DECLARE_TCL_COMMAND(findMax){
  if(argc != 4){
    sprintf(interp->result, "Wrong number of arguments. Should be coefficients[], minimum x, and maximum x (neither of which are acceptable max values).");
    return TCL_ERROR;
  }
  double xret, yret;
  double xmin = atof(argv[2]);
  double xmax = atof(argv[3]);
  if(xmin >= xmax){
    sprintf(interp->result, "The minimum x value must be less than the maximum x value.");
    return TCL_ERROR;
  }
  char ** coefPointer;
  int numCoef;
  Tcl_SplitList(interp, argv[1], &numCoef, &coefPointer);
  vector<double> coef;
  for(short s = 0; s < numCoef; s ++)
    coef.push_back(atof(coefPointer[s]));
  while(coef.back() == 0)
    coef.pop_back();
  Tcl_Free((char *) coefPointer);
  if(coef.size() <= 2){
    sprintf(interp->result, "Cannot find the max value of a linear or point source. The maximum value cannot be at the endpoints.");
    return TCL_ERROR;
  }
  int ret = SolveMax(coef, xmin, xmax, xret, yret);
  if(ret == 0){
    sprintf(interp->result, "%.16e %.16e", xret, yret);
    return TCL_OK;
  }
  switch(ret){
  case 1:
    sprintf(interp->result, "Could not find any possible maximum points");
    break;
  case 2:
    sprintf(interp->result, "The maximum point cannot be at or beyond the endpoints of the specified range.");
    break;
  case 3:
    sprintf(interp->result, "Unexpected error while taking the Taylor Series of the data.");
    break;
  }
  return TCL_ERROR;
}





