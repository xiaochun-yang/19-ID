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
#include "newmat.h"
#include "newmatap.h"
#include "calibrate.h"

#include <math.h>
#include <stdio.h>
#include <string.h>

const double GOLDEN_R = 1.618033988749895;
const double GOLDEN_A = 0.381966011250105;
//const double GOLDEN_B = 0.618033988749895;


  // Check that a vector is monotonic

int cal_ismonotonic (const ColumnVector& v)
{
  int sense, c;
  
  if (v.Nrows () < 2)
  
    return 0;

  if (v (1) == v (v.Nrows ()))
  
    return 0;
    
  sense = (v (1) < v (v.Nrows ()));
  
  for (c = 2; c <= v.Nrows (); c++)
  
    if (sense)
    {
      if (v (c) < v (c - 1))
      
        return 0;
    }
    else
    
      if (v (c) > v (c - 1))
      
        return 0;
        
  return sense * 2 - 1;
}


  // Interpolate from (x0, y0) to (x1, y1) both monotonic increasing in x
  
int cal_interpolate (const ColumnVector& x0, 
                     const ColumnVector& y0,
                     const ColumnVector& x1, 
                           ColumnVector& y1)
{
  int rows0, rows1, c0, c1;


    // Check the arguments
    
  if (cal_ismonotonic (x0) <= 0 ||
      cal_ismonotonic (x1) <= 0)
      
    return CAL_BAD_ARGUMENT;
    
  rows0 = x0.Nrows ();
  rows1 = x1.Nrows ();
  
  if (x0.Nrows () != y0.Nrows ())
  
    return CAL_BAD_ARGUMENT;


    // Check the final scale

  if (rows1 < 1)

    return CAL_BAD_ARGUMENT;


    // Set the final y vector to the correct length

  y1.ReSize (rows1);


    // All unknown points are set to 0

  y1 = 0.0;


    // Check the initial scale

  if (rows0 < 2)

    return CAL_BAD_ARGUMENT;


    // Check that the two scales overlap

  if (x0 (1) <= x1 (rows1) && x1 (1) <= x0 (rows0))
  {
      // Simple linear interpolation

    for (c1 = 1; c1 <= rows1 && x1 (c1) < x0 (1); c1++);

    for (c0 = 2; c0 <= rows0 && c1 <= rows1; c0++)
    {
      if (x0 (c0) <= x0 (c0 - 1))

        continue;

      if (x0 (c0)     >= x1 (c1) && 
          x0 (c0 - 1) <= x1 (c1) && 
          x0 (c0)     >= x0 (c0 - 1))
      {
        y1 (c1) = ((x1 (c1) - x0 (c0 - 1)) * y0 (c0) +
                   (x0 (c0) - x1 (c1))     * y0 (c0 - 1)) /
                   (x0 (c0) - x0 (c0 - 1));

        c1++;
        c0--;
      }
    }
  }


    // Success
    
  return 0;
}


  // Convolute a curve monotonic increasing in x with a Gaussian of HWHH width

int cal_convolutegaussian (ColumnVector& x, 
                           ColumnVector& y, double width)
{
  int rows, grid_points, last, c, FTrows;

  double step, Gauss_FTRe;

  ColumnVector grid_x, grid_y, FTRe, FTIm;


    // Check the arguments

  if (cal_ismonotonic (x) <= 0)
  
    return CAL_BAD_ARGUMENT;
    
  if (x.Nrows () != y.Nrows ())
  
    return CAL_BAD_ARGUMENT;
      

  rows = x.Nrows ();
  

    // Interpolate the curve onto a regular grid from xmin to xmax
    
  grid_points = 512;
    
  while (grid_points < 2 * rows)
  
    grid_points *= 2;

  step = (x (rows) - x (1) + 8 * width) / grid_points;

  grid_x.ReSize (grid_points);

  for (c = 1; c <= grid_points; c++)

    grid_x (c) = (c - 1) * step + x (1);
    
  cal_interpolate (x, y, grid_x, grid_y);


    // Extend the curve at each end with the first and last values

  last = (x (rows) - x (1)) / step + 1;

  for (c = last + 1; c < (grid_points + last) / 2; c++)
  
    grid_y (c) = y (rows);

  for (; c <= grid_points; c++)

    grid_y (c) = y (1);


    // Do a Fourier transform
    
  RealFFT (grid_y, FTRe, FTIm);


    // Multiply the FT by the FT of the Gaussian
    //
    // (1) The steps in the FT are 2PI / xmax
    //
    // (2) The FT of a Gaussian is a Gaussian with 
    //     HWHH = 2 ln 2 / original HWHH

  FTrows = FTRe.Nrows ();

  step = M_PI * width / (M_LN2 * step * grid_points);

  for (c = 1; c <= FTrows; c++)
  {
    Gauss_FTRe = exp (-step * step * (c - 1) * (c - 1) * M_LN2);

    FTRe (c) *= Gauss_FTRe;
    FTIm (c) *= Gauss_FTRe;
  }


    // Get the inverse FT

  RealFFTI (FTRe, FTIm, grid_y);


    // Interpolate the final curve back to the original scale

  cal_interpolate (grid_x, grid_y, x, y);


    // Success

  return 0;
}


  // Calculate the correlation between two curves (monotonic increasing in x)

int cal_correlation (const ColumnVector& x0,
                     const ColumnVector& y0,
                     const ColumnVector& x1,
                     const ColumnVector& y1,
                           double        offset,
                           double&       correlation)
{
    // Correlation = (av(xy) - av(x) av(y)) / 
    //          sqrt((av(xx) - av(x) av(x)) * (av(yy) - av(y) av (y)))

  int rows0, rows1, c0, c1, count;
  
  double av_x, av_y, av_xx, av_yy, av_xy, x, y;
  
  correlation = 0;


    // Check the arguments
    
  if (cal_ismonotonic (x0) <= 0 ||
      cal_ismonotonic (x1) <= 0)
      
    return CAL_BAD_ARGUMENT;
    
  rows0 = x0.Nrows ();
  rows1 = x1.Nrows ();
  
  if (x0.Nrows () != y0.Nrows ())
  
    return CAL_BAD_ARGUMENT;


    // Check the scales

  if (rows0 < 2 || rows1 < 1)

    return CAL_BAD_ARGUMENT;


    // Calculate the correlation
    
  av_x = av_y = av_xx = av_yy = av_xy = 0;
  
  count = 0;
    
  if (x0 (1) <= x1 (rows1) + offset && x1 (1) + offset <= x0 (rows0))
  {
      // Simple linear interpolation

    for (c1 = 1; c1 <= rows1 && x1 (c1) + offset < x0 (1); c1++);

    for (c0 = 2; c0 <= rows0 && c1 <= rows1; c0++)
    {
      if (x0 (c0) <= x0 (c0 - 1))

        continue;

      if (x0 (c0)     >= x1 (c1) + offset && 
          x0 (c0 - 1) <= x1 (c1) + offset && 
          x0 (c0)     >= x0 (c0 - 1))
      {
        x =   y1 (c1);
        y = ((x1 (c1) - x0 (c0 - 1) + offset) * y0 (c0) +
             (x0 (c0) - x1 (c1)     - offset) * y0 (c0 - 1)) /
             (x0 (c0) - x0 (c0 - 1));
             
        av_x  += x;
        av_y  += y;
        av_xx += x * x;
        av_yy += y * y;
        av_xy += x * y;
        
        count++;

        c1++;
        c0--;
      }
    }
  }


    // Calculate the correlation
    
  if (count < 4)
  
    correlation = 0;
    
  else
  {
    av_x  /= count;
    av_y  /= count;
    av_xx /= count;
    av_yy /= count;
    av_xy /= count;
  
    if (av_xx == av_x * av_x || av_yy == av_y * av_y)
  
      correlation = 0;
      
    else      

      correlation = (av_xy - av_x * av_y) * (av_xy - av_x * av_y) / 
                   ((av_xx - av_x * av_x) * (av_yy - av_y * av_y));
  }
        

    // Success
    
  return 0;
}


  // Given initial points (a b) find (a b c) bracketing the maximum

int cal_bracket (const ColumnVector& x0,
                 const ColumnVector& y0,
                 const ColumnVector& x1,
                 const ColumnVector& y1,
                       double&       a,
                       double&       b,
                       double&       c,
                       double&       fa,
                       double&       fb,
                       double&       fc,
                       int&          evaluations,
                       int           limit)
{
  int code;  
  
  double d;


    // Get the starting function values
    
  code = cal_correlation (x0, y0, x1, y1, a, fa) |
         cal_correlation (x0, y0, x1, y1, b, fb);

  evaluations += 2;
  
  if (code & CAL_BAD_ARGUMENT)
  
    return code;


    // Make sure that the function increases from a to b

  if (fa > fb)
  {
    d = a;
    a = b;
    b = d;
    
    d  = fa;
    fa = fb;
    fb = d;
  }

  while (evaluations < limit)
  {
      // Extend the section

    c = b + (b - a) * GOLDEN_R;

    code |= cal_correlation (x0, y0, x1, y1, c, fc);

    evaluations++;
    
    if (fc < fb)
    
      return code;
    
    if (fa == fb && fb == fc)
    
      return CAL_BAD_ARGUMENT;
      
    a = b;
    b = c;
      
    fa = fb;
    fb = fc;
  }


    // Reached limit of evaluations
  
  return CAL_EVALUATIONS_LIMIT | code;
}


  // Given the bracket (a b c) isolate the maximum

int cal_isolate (const ColumnVector& x0,
                 const ColumnVector& y0,
                 const ColumnVector& x1,
                 const ColumnVector& y1,
                       double&       a,
                       double&       b,
                       double&       c,
                       double&       fa,
                       double&       fb,
                       double&       fc,
                       int&          evaluations,
                       int           limit,
                       double        accuracy)
{
  int code;  
  
  double up, down, fx, x, d, mean /*, la, lb, lc */, step;
  

    // The brackets are such that f(a) < f(b), f(c) < f(b)

    // Get the region bounding the minimum

  if (a > c)
  {
    up   = a;
    down = c;
  }
  else
  {
    up   = c;
    down = a;
  }


    // up and down bracket the minimum
    // a is the point with highest f(x)        fa
    // b is the point with second highest f(x) fb
    // c is the point with lowset f(x)         fc

  d = a;
  a = b;
  b = d;
  
  d  = fa;
  fa = fb;
  fb = d;

  if (fb < fc)
  {
    d = b;
    b = c;
    c = d;
  
    d  = fb;
    fb = fc;
    fc = d;
  }


    // Optimisation loop

  step = up - down;
  
  code = 0;

  while (evaluations < limit && (up - a > accuracy || a - down > accuracy))
  {
    mean = (up + down) / 2;


      // Do a Golden section

    if (a > mean)

      x = a + (down - a) * GOLDEN_A;

    else

      x = a + (up - a) * GOLDEN_A;


      // Check that x differs from the best point

    if (fabs (x - a) <= accuracy / 2)

      if (a > mean)

        x = a - accuracy / 2;

      else

        x = a + accuracy / 2;

        
      // At this point we have a new trial x value

    step = x - a;

    code |= cal_correlation (x0, y0, x1, y1, x, fx);

    evaluations++;
    
    if (code)
    
      return code;
    

      // Change up or down if necessary

    if (fx < fa)
      
      if (step > 0)

        up = x;

      else

        down = x;


      // Change the three best estimates if necessary

    if (fx > fa)
    {
      d  = fa;
      fa = fx;
      fx = d;

      d  = a;
      a  = x;
      x  = d;
    }
    
    if (fx > fb)
    {
      d  = fb;
      fb = fx;
      fx = d;

      d  = b;
      b  = x;
      x  = d;
    }
    
    if (fx > fc)
    {
      fc = fx;

      c  = x;
    }
  }


    // Success?
    
  if (up - a <= accuracy && a - down <= accuracy)
  
    return code;

  return code | CAL_EVALUATIONS_LIMIT;
}


  // Calculate the x offset of two curves (monotonic in x)

int cal_overlap (ColumnVector& x0,
                 ColumnVector& y0,
                 ColumnVector& x1,
                 ColumnVector& y1,
                 double&       offset,
                 double&       correlation,
                 int&          evaluations,
                 int           limit,
                 double        width,
                 double        step,
                 double        accuracy)
{
  int sense0, sense1, code;
  
  double a, b, c, fa, fb, fc;
  
  ColumnVector curve0, curve1;
  

    // Check the arguments

  sense0 = cal_ismonotonic (x0);
  sense1 = cal_ismonotonic (x1);
  
  if (sense0 == 0 || sense1 == 0)
      
    return CAL_BAD_ARGUMENT;
    
  if (x0.Nrows () != y0.Nrows () || x1.Nrows () != y1.Nrows ())
  
    return CAL_BAD_ARGUMENT;
    
  if (limit <= 0 || accuracy <= 0 || width <= 0)
  
    return CAL_BAD_ARGUMENT;
      

    // Ensure that the curves are increasing in x

  if (sense0 < 0)
  {
    x0 = x0.Reverse ();
    y0 = y0.Reverse ();
  }

  if (sense1 < 0)
  {
    x1 = x1.Reverse ();
    y1 = y1.Reverse ();
  }


    // Subtract the background
    
  curve0 = y0;
  curve1 = y1;
  
  code = cal_convolutegaussian (x0, curve0, width);
  
  if (code)
  
    return code;
    
  code = cal_convolutegaussian (x1, curve1, width);
  
  if (code)
  
    return code;
    
  curve0 -= y0;
  curve1 -= y1;

 
    // Find (a b c) bracketing the maximum
    
  evaluations = 0;
  
  a = offset;
  b = offset + step;

  code = cal_bracket (x0, curve0, x1, curve1, a, b, c, fa, fb, fc,
                      evaluations, limit);


    // Isolate the maximum
        
  if (code == 0)
  
    code |= cal_isolate (x0, curve0, x1, curve1, a, b, c, fa, fb, fc,
                         evaluations, limit, accuracy);
   

    // Restore the order if necessary

  if (sense0 < 0)
  {
    x0 = x0.Reverse ();
    y0 = y0.Reverse ();
  }

  if (sense1 < 0)
  {
    x1 = x1.Reverse ();
    y1 = y1.Reverse ();
  }


    // Success?
    
  if (code == 0)
  {
    offset = a;
    
    correlation = fa;
  }
  else
  
    correlation = 0;
  
  return code;
}


  // Parse a whitespace-separated list of numbers

int cal_parsevector (ColumnVector& v, const char *c)
{
  int count;
  
  const char *c0, *end;
  
  
    // Count the numbers
    
  c0 = end = c;

  count = -1;
  
  for (c = NULL; c != end; count++)
  {
    c = end;
    
    strtod (c, (char **) &end);
  }

  if (count < 1)
  
    return CAL_BAD_ARGUMENT;
    

    // Parse the string
    
  v.ReSize (count);
  
  c = c0;
  
  for (count = 1; count <= v.Nrows (); count++)

    v (count) = strtod (c, (char **) &c);


    // Success
    
  return 0;
}


  // Calculate a polynomial
  
double cal_polynomial (double x, ColumnVector& P)
{
  int n;
  
  double sum;
  
  sum = 0;
  
  for (n = P.Nrows (); n > 0; n--)
  
    sum = sum * x + P (n);
    
  return sum;
}


  // Get the peak of a curve

extern "C" int cal_peak (const char *scan_x,
                         const char *scan_y,
                         const char *polynomial_order,
                         const char *fit_points,
                               char *scan_peak)
{
  ColumnVector x, y, D, P;
  
  SymmetricMatrix A;
  
  int cc, cs, ce, c, row, col, order, points, start, sense;
  
  double y_max, y_min, xs, x_max, ys;
  

    // Parse the scan
  
  cal_parsevector (x, scan_x);
  cal_parsevector (y, scan_y);

  sense = cal_ismonotonic (x);
  
  if (!sense)
  
    return CAL_BAD_ARGUMENT;

  order  = atoi (polynomial_order);
  points = atoi (fit_points);
  
  if (x.Nrows () != y.Nrows () || 
      x.Nrows () <  points     || 
      points     <  1          || 
      order      >= points)
      
    return CAL_BAD_ARGUMENT;


    // Find the "points" highest contiguous points
    
  strcpy (scan_peak, "");

  start = 0;
  
  y_max = 0;
  
  for (cc = 1; cc <= x.Nrows (); cc++)
  {
    cs = cc - points / 2;

    if (cs < 1)
    
      cs = 1;
      
    ce = cs + points - 1;
    
    if (ce > x.Nrows ())
    {
      ce = x.Nrows ();
      
      cs = ce - points + 1;
    }

    y_min = y (cs);
    
    for (c = cs + 1; c <= ce; c++)
    
      if (y (c) < y_min)

        y_min = y (c);
        
    if (y_min > y_max || start == 0)
    {
      y_max = y_min;
      
      start = cs;
    }
  }

  if (start == 0)
  
    return CAL_BAD_ARGUMENT;

  cs = start;
  
  ce = cs + points - 1;
  

    // Fit the polynomial
    
  A.ReSize (order + 1);
  D.ReSize (order + 1);

      
    // A (i, j) = Sum (x**(i + j - 2))
    // D (i)    = Sum (x**(i - 1) * y)
       
  A = 0.0;
  D = 0.0;
  
  for (c = cs; c <= ce; c++)
      
    for (row = 1; row <= order + 1; row++)
    {
      D (row) += pow (x (c) - x (cs), row - 1) 
                   * (y (c) - y (cs));
        
      for (col = 1; col <= row; col++)
        
        A (row, col) += pow (x (c) - x (cs), row + col - 2);
    }

  P = A.i () * D;

   
    // Scan through the curve to find the highest point
  
  x_max = x (cs);
  
  y_max = cal_polynomial (0, P);
  
  for (c = cs; c < ce; c++)
  
    for (xs = x (c); sense * (x (c + 1) - xs) > 0;
                       xs += (x (c + 1) - x (c)) / 100)
    {
      ys = cal_polynomial (xs - x (cs), P);
      
      if (ys > y_max)
      {
        x_max = xs;
        y_max = ys;
      }
    }
  
  sprintf (scan_peak, "%.6e %.6e", x_max, y_max + y (cs));

  return 0;
}


  // Get the first derivative of a curve

extern "C" int cal_derivative (const char *scan_x,
                               const char *scan_y,
                               const char *polynomial_order,
                               const char *fit_points,
                                     char *scan_derivative)
{
  ColumnVector x, y, D, P;
  
  SymmetricMatrix A;
  
  int cc, cs, ce, c, row, col, order, points;
  

    // Parse the scan
  
  cal_parsevector (x, scan_x);
  cal_parsevector (y, scan_y);
  
  if (!cal_ismonotonic (x))
  
    return CAL_BAD_ARGUMENT;

  order  = atoi (polynomial_order);
  points = atoi (fit_points);
  
  if (x.Nrows () != y.Nrows () || 
      x.Nrows () <  points     || 
      points     <  1          || 
      order      >= points)
      
    return CAL_BAD_ARGUMENT;


    // Start differentiation cycle
    
  strcpy (scan_derivative, "");

  A.ReSize (order + 1);
  D.ReSize (order + 1);

  for (cc = 1; cc <= x.Nrows (); cc++)
  {
    cs = cc - points / 2;
    
    if (cs < 1)
    
      cs = 1;
      
    ce = cs + points - 1;
    
    if (ce > x.Nrows ())
    {
      ce = x.Nrows ();
      
      cs = ce - points + 1;
    }


      // Calculate the best-fit polynomial
      
      // A (i, j) = Sum (x**(i + j - 2))
      // D (i)    = Sum (x**(i - 1) * y)
       
    A = 0.0;
    D = 0.0;
    
    for (c = cs; c <= ce; c++)
      
      for (row = 1; row <= order + 1; row++)
      {
        D (row) += pow (x (c) - x (cc), row - 1) 
                     * (y (c) - y (cc));
        
        for (col = 1; col <= row; col++)
        
          A (row, col) += pow (x (c) - x (cc), row + col - 2);
      }
      
    P = A.i () * D;
    
    
      // The derivative is P (2)
    
    sprintf (scan_derivative, " %.6e", P (2));
    
    scan_derivative += strlen (scan_derivative);
  }

  return 0;
}


  // Calibrate the monochromator given a scan

extern "C" int cal_calibrate (const char *edge,
                              const char *reference,
                              const char *monochromator,
                              const char *scan_ev,
                              const char *scan_absorbance,
                                    char *result)
{
  ColumnVector reference_angle, reference_absorbance, 
               angle, absorbance,
               point;
  
  double monochromator_d, sin_theta, step, offset, correlation;
  
  int evaluations, code, count;

  FILE *file;
  
  char line [256];
  
  long int pos;
  
  strcpy (result, "0 0");
    
  
    // Parse the scan
  
  cal_parsevector (angle,      scan_ev);
  cal_parsevector (absorbance, scan_absorbance);
  
  monochromator_d = strtod (monochromator, NULL);
  
  if (angle.Nrows () == 0 ||
      angle.Nrows () != absorbance.Nrows () ||
      monochromator_d < 0.01 ||
      monochromator_d > 100.0)
      
    return CAL_BAD_ARGUMENT;


    // Read the reference curve
    
  if (edge == NULL || reference == NULL)
  
    return CAL_BAD_ARGUMENT;
    
  if (strlen (edge) < 1 || strlen (reference) < 1)
  
    return CAL_BAD_ARGUMENT;

  file = fopen (reference, "r");
  
  if (file == NULL)
  
    return CAL_BAD_OPEN;
  
  count = 0;
  
  while (fgets (line, 256, file))
  {
    if (strncasecmp (line, edge, strlen (edge)) == 0)
    {
        // Save the current position
        
      pos = ftell (file);
      
      
        // Count the number of points
        
      while (fgets (line, 256, file))
      {
        code = cal_parsevector (point, line);
        
        if (code != 0 || point.Nrows () != 2)
        
          break;
        
        count++;
      }
      
      if (count < 4)
      
        return CAL_BAD_FORMAT;
      
      
        // Read the points
        
      reference_angle.ReSize (count);
      reference_absorbance.ReSize (count);

      fseek (file, pos, SEEK_SET);

      for (count = 1; count <= reference_angle.Nrows (); count++)
      
        if (fgets (line, 256, file))
        {
          code = cal_parsevector (point, line);
        
          if (code != 0 || point.Nrows () != 2)
        
            return CAL_BAD_FORMAT;

          reference_angle (count) = point (1);
          reference_absorbance (count) = point (2);
        }
        else
        
          return CAL_BAD_READ;

      break;
    }
  }
        
  
    // Convert the scan and reference from energy into angle

  for (count = 1; count <= angle.Nrows (); count++)
  {
    sin_theta = 12398.5471 / (angle (count) * 2 * monochromator_d);
    
    if (sin_theta < 0 || sin_theta > 1)
    
      return CAL_BAD_ARGUMENT;
    
    angle (count) = asin (sin_theta);
  }

  for (count = 1; count <= reference_angle.Nrows (); count++)
  {
    sin_theta = 12398.5471 / (reference_angle (count) * 2 * monochromator_d);
    
    if (sin_theta < 0 || sin_theta > 1)
    
      return CAL_BAD_ARGUMENT;
    
    reference_angle (count) = asin (sin_theta);
  }


    // Superpose the curves

  step = fabs (angle (1) - angle (angle.Nrows ()));
  
  offset = 0;

  code = cal_overlap (reference_angle, reference_absorbance, 
                      angle, absorbance, offset, correlation,
                      evaluations, 100, step / 4, step / 40, 1e-6);

  if (code == 0)
  {
    sprintf (result, "%10.6f %12.5e", correlation, offset);
    
    return 0;
  }
  
  return code;
}

