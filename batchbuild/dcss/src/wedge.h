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
#ifndef TK_WEDGE_H
#define TK_WEDGE_H

/* standard include files */
#include <xos_hash.h>


/* function prototypes */

xos_result_t wedge_set_mad_definition( int 				runIndex, 

													double				delta,
													double				wedgeSize,
													double				runStartAngle,
													double				runEndAngle,
													int					runStartFrame,
													xos_boolean_t 	inverseOn,

													int				numEnergies,
													double				*energy );


xos_result_t wedge_get_next_frame( int runIndex );



xos_result_t wedge_get_frame_data( int					runIndex,
											  int					absoluteFrameIndex,
											  double				*startAngle,
											  int					*frameLabel,
											  int 				*energy );

int wedge_get_max_index ( int runIndex);

#endif
