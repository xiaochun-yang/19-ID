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

/* local include files */
#include <tcl.h>
#include <tk.h>
#include "calibrate.h"
#include "ice_cal.h"
#include "string.h"


DECLARE_TCL_COMMAND(cal_correct_energy)
	{
	/* local variables */
	char * edgeType = argv[1];
	char * scanX = argv[2];
	char * scanY = argv[3];
	char * calibrationFile = argv[4];
	char resultString[255];
	int result;

	puts( edgeType );
	puts( scanX );
	puts( scanY );

	result = cal_calibrate( edgeType, calibrationFile, "3.13555", scanX, scanY, resultString  );

	/*printf("result = %d\n", result );*/
	/*puts( resultString );*/

	if ( result == 0 ) 
		{
		strcpy( interp->result, resultString );
		}
	else
		{
		strcpy( interp->result, "error" );
		}

	/* return success */
	return TCL_OK;
	}


DECLARE_TCL_COMMAND(cal_find_peak)
	{
	/* local variables */
	char * scan_x = argv[2];
	char * scan_y = argv[3];
	char * polynomial_order = "2";
	char * fit_points = "3";
	char scan_peak[255];

	int result;

	result = cal_peak( scan_x, scan_y, polynomial_order, fit_points, scan_peak );

	if ( result == 0 ) 
		{
		strcpy( interp->result, scan_peak );
		}
	else
		{
		strcpy( interp->result, "error" );
		}

	/* return success */
	return TCL_OK;
	}


