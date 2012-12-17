#include <tcl.h>
#include <log_quick.h>

#include "dcss_broadcast.h"

extern "C" int log_puts( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    const char dummy[2] = {0};
    const char* pMsg = dummy;
    const char* pFile = dummy;
    int line = 0;

    if (objc < 2)
    {
        return TCL_OK;
    }
    pMsg = Tcl_GetString( objv[1] );
    if (objc >=3)
    {
        pFile = Tcl_GetString( objv[2] );
    }
    if (objc >=4)
    {
        if (Tcl_GetIntFromObj( interp, objv[3], &line ) != TCL_OK)
        {
            line = 0;
        }
    }

    //LOG_INFO( pMsg );
    info_details( pFile, line, dummy, dummy, gpDefaultLogger, pMsg );

    return TCL_OK;
}
extern "C" int check_device_permit( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    long client_id = 0;
    const char* deviceName = NULL;

    /* check input */
    if (objc < 3)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "client_id, device_name" );
        return TCL_ERROR;
    }
    if (Tcl_GetLongFromObj( interp, objv[1], &client_id ) != TCL_OK)
    {
        Tcl_SetResult( interp, "client_id must by long integer", TCL_STATIC );
        return TCL_ERROR;
    }
    deviceName = Tcl_GetString( objv[2] );

    /* call function */
    switch (checkDevicePermit( client_id, deviceName ))
    {
    case GRANTED:
        Tcl_SetResult( interp, "GRANTED", TCL_STATIC );
        break;

    case NOT_ACTIVE_CLIENT:
        Tcl_SetResult( interp, "NOT_ACTIVE_CLIENT", TCL_STATIC );
        break;

    case HUTCH_OPEN_REMOTE:
        Tcl_SetResult( interp, "HUTCH_OPEN_REMOTE", TCL_STATIC );
        break;

    case HUTCH_OPEN_LOCAL:
        Tcl_SetResult( interp, "HUTCH_OPEN_LOCAL", TCL_STATIC );
        break;

    case IN_HUTCH_RESTRICTED:
        Tcl_SetResult( interp, "IN_HUTCH_RESTRICTED", TCL_STATIC );
        break;

    case IN_HUTCH_AND_DOOR_CLOSED:
        Tcl_SetResult( interp, "IN_HUTCH_AND_DOOR_CLOSED", TCL_STATIC );
        break;

    case HUTCH_DOOR_CLOSED:
        Tcl_SetResult( interp, "HUTCH_DOOR_CLOSED", TCL_STATIC );
        break;

    case NO_PERMISSIONS:
    default:
        Tcl_SetResult( interp, "NO_PERMISSIONS", TCL_STATIC );
        break;
    }
    return TCL_OK;
}
extern "C" int get_user_session_id( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    long client_id = 0;

    /* check input */
    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "client_id" );
        return TCL_ERROR;
    }
    if (Tcl_GetLongFromObj( interp, objv[1], &client_id ) != TCL_OK)
    {
        Tcl_SetResult( interp, "client_id must by long integer", TCL_STATIC );
        return TCL_ERROR;
    }
    char SID[1024] = {0};
    if (!getUserSID( SID, sizeof(SID), client_id )) {
        Tcl_SetResult( interp, "client_id not found", TCL_STATIC );
        return TCL_ERROR;
    }
    Tcl_SetStringObj( Tcl_GetObjResult( interp ), SID, strlen( SID ) );
    return TCL_OK;
}
extern "C" int brief_dump_database( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    char* buffer = NULL;
    const int BUFFER_SIZE = 102400;

    buffer = Tcl_Alloc( BUFFER_SIZE + 1 );

    if (buffer == NULL) {
        Tcl_SetResult( interp, "failed allocate buffer", TCL_STATIC );
        return TCL_ERROR;
    }

    if (brief_safe_dump_database( buffer, BUFFER_SIZE )) {
        Tcl_SetResult( interp, buffer, TCL_DYNAMIC );
        return TCL_OK;
    } else {
        Tcl_Free( buffer );
        Tcl_SetResult( interp, "failed to save", TCL_STATIC );
        return TCL_ERROR;
    }
}
