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
#ifndef CALIBRATE
#define CALIBRATE

#define CAL_BAD_ARGUMENT          0x00001
#define CAL_BAD_OPEN              0x00002
#define CAL_BAD_READ              0x00004
#define CAL_BAD_FORMAT            0x00008
#define CAL_EVALUATIONS_LIMIT     0x00010

#ifdef __cplusplus

extern "C" {

#endif


  /* Find the peak of a curve */

int cal_peak (const char *scan_x,                 /* x points (monotonic)    */
              const char *scan_y,                 /* y points                */
              const char *polynomial_order,       /* polynomial order        */
              const char *fit_points,             /* number of points to fit */
                    char *scan_peak);             /* result = (x, y)         */


  /* Calculate the first derivative of a curve */

int cal_derivative (const char *scan_x,           /* x points (monotonic)    */
                    const char *scan_y,           /* y points                */
                    const char *polynomial_order, /* polynomial order        */
                    const char *fit_points,       /* number of points to fit */
                          char *scan_derivative); /* derivative points       */


  /* Calculate the angular error in the monochromator */

int cal_calibrate (const char *edge,              /* edge type (eg. "Cu K")  */
                   const char *reference,         /* file with reference
                                                     curves                  */
                   const char *monochromator,     /* monochromator d-spacing
                                                     in angstroms            */
                   const char *scan_ev,           /* energy points in eV     */
                   const char *scan_absorbance,   /* absorbance points       */
                         char *result);           /* result = (correlation,
                                                     mono error in radians)  */

#ifdef __cplusplus

}

#endif

#endif
