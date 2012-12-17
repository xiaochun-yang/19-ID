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

#include "itcl.h"
#include "tcl_macros.h"
#include "dcss_scripting.h"
#include "DcsConfig.h"
#include "log_quick.h"

extern char gSessionID[4096];
extern std::string gDefaultUserName;

extern DcsConfig gDcssConfig;
extern "C" int log_puts( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
extern "C" int check_device_permit( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
extern "C" int get_user_session_id( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
extern "C" int brief_dump_database( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );

/****************************************************************
	combination_motor_handler:
****************************************************************/

XOS_THREAD_ROUTINE scripting_thread
	( 
	void *arg 
	)
	
	{ 
	/* local variables */
	static Tcl_Interp *interp;
	int forever = 1;
	

	/* create the Tcl interpreter */
	if ( (interp = Tcl_CreateInterp()) == NULL ) {
		LOG_SEVERE("scripting_thread -- error creating Tcl interpreter\n");
		exit(1);
	}


    /* init tcl library */
    if (Tcl_Init( interp ) == TCL_ERROR) {
        LOG_SEVERE1("scripting_thread -- error Tcl_Init: %s", Tcl_GetStringResult( interp ));
        //exit(1);
    }
    
	/* initialize [Incr Tcl] */
	if (Itcl_Init(interp) == TCL_ERROR) {
        LOG_SEVERE1("scripting_thread -- error Itcl_Init: %s", Tcl_GetStringResult( interp ));
        //exit(1);
    }
		

    REGISTER_TCL_OBJECT_COMMAND( log_puts );
    REGISTER_TCL_OBJECT_COMMAND( check_device_permit );
    REGISTER_TCL_OBJECT_COMMAND( get_user_session_id );
    REGISTER_TCL_OBJECT_COMMAND( brief_dump_database );

	// Set global variable
	char buf[256];
	sprintf(buf, "set scriptPort %d", gDcssConfig.getDcssScriptPort());
	if (Tcl_Eval( interp, buf) != TCL_OK) {
		LOG_WARNING1("error: failed to set $scriptPort %s\n", Tcl_GetStringResult(interp));
	}
	
	// Set global variable
	sprintf(buf, "set hardwarePort %d", gDcssConfig.getDcssHardwarePort());
	if (Tcl_Eval( interp, buf) != TCL_OK) {
		LOG_WARNING1("error: failed to set $hardwarePort %s\n", Tcl_GetStringResult(interp));
	}
	
	// Set global variable
	sprintf(buf, "set gBeamlineId %s", gDcssConfig.getConfigRootName( ).c_str( ));
	if (Tcl_Eval( interp, buf) != TCL_OK) {
		LOG_WARNING1("error: failed to set gBeamLineId %s\n", Tcl_GetStringResult(interp));
	}

    // set default sessionID
    LOG_INFO1( "set TCL gUserName to %s", gDefaultUserName.c_str() );
	sprintf(buf, "set gUserName %s", gDefaultUserName.c_str());
	if (Tcl_Eval( interp, buf) != TCL_OK) {
		LOG_WARNING1("error: failed to set gUserName %s\n", Tcl_GetStringResult(interp));
    }
	
    LOG_INFO1( "set TCL gSessionID to %.7s", gSessionID );
	sprintf(buf, "set gSessionID %s", gSessionID);
	if (Tcl_Eval( interp, buf) != TCL_OK) {
		LOG_WARNING1("error: failed to set gSessionID %s\n", Tcl_GetStringResult(interp));
    }
	
	/* read the scripts */
	if ( Tcl_EvalFile( interp, INITIALIZATION_SCRIPT ) != TCL_OK )
		{
		puts("********* Error reading Tcl script ********* ");
		Tcl_Eval(interp,"puts $errorInfo" );
		puts("******************************************** ");
		}
	      
	/* start event loop */
	while ( forever )
		{
		Tcl_DoOneEvent(0);
		}
	
	/* code should never reach here */
	XOS_THREAD_ROUTINE_RETURN;
	}
