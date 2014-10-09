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

extern "C" {
/* local include files */
#include <tcl.h>
#include "auth.h"
#include "ice_auth.h"

DECLARE_TCL_OBJECT_COMMAND(generate_auth_response)
	{
	/* local variables */
	char						*userName;
	unsigned char			*challengeString;
	auth_key					key;
	int cnt;
	char responseString[201];
	Tcl_Obj *resultPtr;

	userName = Tcl_GetString( objv[1] );
	challengeString = Tcl_GetByteArrayFromObj( objv[2] , &cnt );				

	/* load security key for user */
	if ( auth_load_key( userName, & key ) != XOS_SUCCESS )
		{
		xos_error( "Error loading security key for user %s", userName );
		return TCL_ERROR;
		}
	
	// printf("key name:%s, uid:%d, gid:%d\n", key.user.pw_name, key.user.pw_uid, key.user.pw_gid); 
	
	/* generate the response string */

	//	for ( cnt = 0; cnt < 16; cnt++)
	//	{
	//	printf("%02x ", challengeString[cnt]);
	//	}
	//puts(".end challenge");

	// call the auth function to generate the response
	auth_get_response_string( responseString,
									  (char *)challengeString,
									  & key );
	
	// get a pointer to the result object
	resultPtr = Tcl_GetObjResult( interp );

	Tcl_SetByteArrayObj ( resultPtr, (unsigned char *)responseString, 200);
	
	//for ( cnt = 0; cnt < 16; cnt++)
	//	{
	//	printf("%02d ", interp->result[cnt]);
	//	}
	//puts(".end response");

	/* disconnect from image server */
	return TCL_OK;
	}

}
