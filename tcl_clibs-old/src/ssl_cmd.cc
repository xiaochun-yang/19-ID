#include <string.h>
#include <tcl.h>

#include "XosException.h"
#include "SSLCommon.h"

extern "C" {
int DcsSslUtil( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
}

static char normal_result[] = "normal OK";

int DcsSslUtil( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 3)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "cmd args" );
        return TCL_ERROR;
    }

    char* cmd = Tcl_GetString( objv[1] );
    char* param = Tcl_GetString( objv[2] );

    if (!strcmp( cmd, "loadCertificate" )) {
        try {
            loadDCSSCertificate( param );
            Tcl_SetResult( interp, "loaded", TCL_STATIC );
        } catch ( XosException& e) {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            const char* result = e.getMessage( ).c_str( );
            Tcl_SetStringObj( pResultObj, (char*)result, strlen( result ) );
            return TCL_ERROR;
        }
    } else if (!strcmp( cmd, "loadPrivateKey" )) {
        try {
            char* pass_phase = NULL;
            if (objc > 3) {
                pass_phase = Tcl_GetString( objv[3] );
            }
            loadDCSSPrivateKey( param, pass_phase );
            Tcl_SetResult( interp, "loaded", TCL_STATIC );
        } catch ( XosException& e) {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            const char* result = e.getMessage( ).c_str( );
            Tcl_SetStringObj( pResultObj, (char*)result, strlen( result ) );
            return TCL_ERROR;
        }
    } else if (!strcmp( cmd, "encryptSID" )) {
        char result[1024] = {0};
        if (!encryptSID( result, sizeof(result), param )) {
            Tcl_SetResult( interp, "encryptSID failed", TCL_STATIC );
            return TCL_ERROR;
        } else {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            Tcl_SetStringObj( pResultObj, result, strlen( result ) );
        }
    } else if (!strcmp( cmd, "decryptSID" )) {
        char result[1024] = {0};
        if (!decryptSID( result, sizeof(result), param )) {
            Tcl_SetResult( interp, "decryptSID failed", TCL_STATIC );
            return TCL_ERROR;
        } else {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            Tcl_SetStringObj( pResultObj, result, strlen( result ) );
        }
    } else {
        Tcl_SetResult( interp, "bad command", TCL_STATIC );
        return TCL_ERROR;
    }
    return TCL_OK;
}
