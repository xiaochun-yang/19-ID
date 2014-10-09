#include <string.h>
#include <deque>
#include <tcl.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include "bilinearMap.h"

extern "C" {
int BilinearMappingCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
void DeleteBilinearMappingCmd( ClientData cdata );
int NewBilinearMappingCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv );
};

static char normal_result[] = "normal OK";

static deque<BilinearMapping*> myObjPool;

int BilinearMappingCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    //char puts_buffer[256] = {0};

    BilinearMapping* pMapping = (BilinearMapping*)cdata;

    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "command" );
        return TCL_ERROR;
    }

    char* argv1 = Tcl_GetString( objv[1] );

    if (!strcmp( argv1, "setup" )) {
        if (objc < 18) {
            Tcl_WrongNumArgs( interp, 2, objv, "u v x y ..." );
            return TCL_ERROR;
        }

        double uvQuad[4][2] = {0};
        double xyQuad[4][2] = {0};

        int i,j;
        for (i = 0; i < 4; ++i) {
            for (j = 0; j < 2; ++j) {
                if (Tcl_GetDoubleFromObj( interp, objv[2 * i + j + 2],
                &uvQuad[i][j] ) != TCL_OK) {
                    Tcl_SetResult( interp, "uv is wrong", TCL_STATIC );
                    return TCL_ERROR;
                }
                if (Tcl_GetDoubleFromObj( interp, objv[2 * i + j + 10],
                &xyQuad[i][j] ) != TCL_OK) {
                    Tcl_SetResult( interp, "xy is wrong", TCL_STATIC );
                    return TCL_ERROR;
                }
            }
        }

        if (!pMapping->setupAnchorSource( uvQuad )) {
            Tcl_SetResult( interp, "setupAnchorSource failed", TCL_STATIC );
            return TCL_ERROR;
        }
        pMapping->setupAnchorDestination( xyQuad );
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }
    if (!strcmp( argv1, "map" )) {
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "uvList" );
            return TCL_ERROR;
        }
        char* argv2 = Tcl_GetString( objv[2] );
        const char *pResult = pMapping->map( argv2 );
        //passing result back by variable "m_mapResults"
        if (Tcl_SetVar( interp, "m_mapResult", (char*)pResult, TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }


    Tcl_SetResult( interp, "unsupported commande", TCL_STATIC );
    return TCL_ERROR;
}
void DeleteBilinearMappingCmd( ClientData cdata )
{
    fprintf( stderr, "bilinearMapping at %p deleted\n", cdata );
    BilinearMapping* pObj = (BilinearMapping *)cdata;

    myObjPool.push_front( pObj );
    fprintf( stderr, "pool size=%d\n", myObjPool.size( ) );
}

int NewBilinearMappingCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv )
{
    static unsigned int id(0);

    BilinearMapping* newObjPtr = NULL;

    if (myObjPool.size( ) > 0) {
        newObjPtr = myObjPool.front( );
        myObjPool.pop_front( );
        newObjPtr->reset( );
        fprintf( stderr, "bilinear reusing from pool\n" );
    } else {
        fprintf( stderr, "bilinear empty pool create new\n" );
        newObjPtr = new BilinearMapping( );
    }

    //create unique name
    sprintf( interp->result, "BilinearMapping%u", id++ );
    Tcl_CreateObjCommand( interp,
                    interp->result,
                    BilinearMappingCmd,
                    newObjPtr,
                    DeleteBilinearMappingCmd );
    return TCL_OK;
}
