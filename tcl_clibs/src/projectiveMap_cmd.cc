#include <string.h>
#include <deque>
#include <tcl.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include "projectiveMap.h"

extern "C" {
int ProjectiveMappingCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
void DeleteProjectiveMappingCmd( ClientData cdata );
int NewProjectiveMappingCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv );


int DcsCoordsTranslateCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
void DeleteDcsCoordsTranslateCmd( ClientData cdata );
int NewDcsCoordsTranslateCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv );

};

static char normal_result[] = "normal OK";

static deque<ProjectiveMapping*> myObjPool;
static deque<DcsCoordsTranslate*> myTransObjPool;

int ProjectiveMappingCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    //char puts_buffer[256] = {0};

    ProjectiveMapping* pMapping = (ProjectiveMapping*)cdata;

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
void DeleteProjectiveMappingCmd( ClientData cdata )
{
    fprintf( stderr, "projectiveMapping at %p deleted\n", cdata );
    ProjectiveMapping* pObj = (ProjectiveMapping *)cdata;

    myObjPool.push_front( pObj );
    fprintf( stderr, "pool size=%d\n", myObjPool.size( ) );
}

int NewProjectiveMappingCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv )
{
    static unsigned int id(0);

    ProjectiveMapping* newObjPtr = NULL;

    if (myObjPool.size( ) > 0) {
        newObjPtr = myObjPool.front( );
        myObjPool.pop_front( );
        newObjPtr->reset( );
        fprintf( stderr, "reusing from pool\n" );
    } else {
        fprintf( stderr, "empty pool create new\n" );
        newObjPtr = new ProjectiveMapping( );
    }

    //create unique name
    sprintf( interp->result, "ProjectiveMapping%u", id++ );
    Tcl_CreateObjCommand( interp,
                    interp->result,
                    ProjectiveMappingCmd,
                    newObjPtr,
                    DeleteProjectiveMappingCmd );
    return TCL_OK;
}
int DcsCoordsTranslateCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    //char puts_buffer[256] = {0};

    DcsCoordsTranslate* pTrans = (DcsCoordsTranslate*)cdata;

    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "command" );
        return TCL_ERROR;
    }

    char* argv1 = Tcl_GetString( objv[1] );

    if (!strcmp( argv1, "setup" )) {
        if (objc < 10) {
            Tcl_WrongNumArgs( interp, 2, objv, "oOrig dOrig size angle ucx ucy ocx ocy" );
            return TCL_ERROR;
        }
        double angle;
        double uCenterX;
        double uCenterY;
        double oCenterX;
        double oCenterY;
        if (Tcl_GetDoubleFromObj( interp, objv[5], &angle ) != TCL_OK) {
            Tcl_SetResult( interp, "angle wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[6], &uCenterX ) != TCL_OK) {
            Tcl_SetResult( interp, "uCenterX wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[7], &uCenterY ) != TCL_OK) {
            Tcl_SetResult( interp, "uCenterY wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[8], &oCenterX ) != TCL_OK) {
            Tcl_SetResult( interp, "oCenterX wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[9], &oCenterY ) != TCL_OK) {
            Tcl_SetResult( interp, "oCenterY wrong", TCL_STATIC );
            return TCL_ERROR;
        }

        if (!pTrans->setup( 
            Tcl_GetString( objv[2] ),
            Tcl_GetString( objv[3] ),
            Tcl_GetString( objv[4] ),
            angle,
            uCenterX,
            uCenterY,
            oCenterX,
            oCenterY
        )) {
            Tcl_SetResult( interp, "setup failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }
    if (!strcmp( argv1, "saveLocalCoords" )) {
        //fprintf( stderr, "saveLocalCoords\n" );
        const char* pLocalCoords = Tcl_GetVar( interp, "m_localCoords",
            TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG );
        if (pLocalCoords == NULL) {
            return TCL_ERROR;
        }

        size_t numPoint = 0;
        double *userX;
        double *userY;
        double *originX;
        double *originY;
        if (!pTrans->mapToOrigin( pLocalCoords, numPoint, userX, userY,
            originX, originY )
        ) {
            Tcl_SetResult( interp, "saveLocalCoords failed", TCL_STATIC );
            return TCL_ERROR;
        }

        // output results
        std::string userResult;
        std::string originResult;
        size_t i;
        for (i = 0; i < numPoint; ++i) {
            char buffer1[1024] = {0};
            char buffer2[1024] = {0};
            sprintf( buffer1, " %.3lf %.3lf", userX[i], userY[i] );
            sprintf( buffer2, " %.3lf %.3lf", originX[i], originY[i] );
            userResult   += buffer1;
            originResult += buffer2;
            //if (i % 100 == 0) {
            //    fprintf( stderr, "user[%ld]=%s orig=%s\n", i, buffer1, buffer2 );
            //}
        }

        if (Tcl_SetVar( interp, "m_uLocalCoords", (char*)userResult.c_str( ), TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
        if (Tcl_SetVar( interp, "m_oLocalCoords", (char*)originResult.c_str( ), TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }
    if (!strcmp( argv1, "updateLocalCoords" )) {
        if (objc < 3) {
            Tcl_WrongNumArgs( interp, 2, objv, "onlyZoom" );
            return TCL_ERROR;
        }
        int onlyZoom = 0;
        if (Tcl_GetIntFromObj( interp, objv[2], &onlyZoom ) != TCL_OK) {
            Tcl_SetResult( interp, "get onlyZoom failed", TCL_STATIC );
            return TCL_ERROR;
        }
        //fprintf( stderr, "onlyZoom=%d\n", onlyZoom );

        const char* pInputCoords;
        if (onlyZoom) {
            pInputCoords = Tcl_GetVar( interp, "m_uLocalCoords",
            TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG );
        } else {
            pInputCoords = Tcl_GetVar( interp, "m_oLocalCoords",
            TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG );
        }
        if (pInputCoords == NULL) {
            return TCL_ERROR;
        }

        size_t numPoint = 0;
        double *userX;
        double *userY;
        double *pixelX;
        double *pixelY;
        if (!pTrans->mapToDisplay( pInputCoords, numPoint, userX, userY,
            pixelX, pixelY, onlyZoom != 0 )
        ) {
            Tcl_SetResult( interp, "updateLocalCoords failed", TCL_STATIC );
            return TCL_ERROR;
        }

        // output results
        std::string userResult;
        std::string pixelResult;
        size_t i;
        for (i = 0; i < numPoint; ++i) {
            char buffer1[1024] = {0};
            char buffer2[1024] = {0};
            sprintf( buffer1, " %.3lf %.3lf", userX[i], userY[i] );
            sprintf( buffer2, " %.3lf %.3lf", pixelX[i], pixelY[i] );
            userResult   += buffer1;
            pixelResult += buffer2;
            //if (i % 100 == 0) {
            //    fprintf( stderr, "user[%ld]=%s pixel=%s\n", i, buffer1, buffer2 );
            //}
        }
        //fprintf( stderr, "ready to output %ld points\n", numPoint );

        if (!onlyZoom) {
            if (Tcl_SetVar( interp, "m_uLocalCoords", (char*)userResult.c_str( ), TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
            {
                return TCL_ERROR;
            }
        }
        if (Tcl_SetVar( interp, "m_localCoords", (char*)pixelResult.c_str( ), TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
        {
            return TCL_ERROR;
        }
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }


    Tcl_SetResult( interp, "unsupported commande", TCL_STATIC );
    return TCL_ERROR;
}
void DeleteDcsCoordsTranslateCmd( ClientData cdata )
{
    fprintf( stderr, "DcsCoordsTranslate at %p deleted\n", cdata );
    DcsCoordsTranslate* pObj = (DcsCoordsTranslate *)cdata;

    myTransObjPool.push_front( pObj );
    fprintf( stderr, "pool size=%d\n", myTransObjPool.size( ) );
}

int NewDcsCoordsTranslateCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv )
{
    static unsigned int id(0);

    DcsCoordsTranslate* newObjPtr = NULL;

    if (myTransObjPool.size( ) > 0) {
        newObjPtr = myTransObjPool.front( );
        myTransObjPool.pop_front( );
        newObjPtr->reset( );
        fprintf( stderr, "reusing from pool\n" );
    } else {
        fprintf( stderr, "empty pool create new\n" );
        newObjPtr = new DcsCoordsTranslate( );
    }

    //create unique name
    sprintf( interp->result, "DcsCoordsTranslate%u", id++ );
    Tcl_CreateObjCommand( interp,
                    interp->result,
                    DcsCoordsTranslateCmd,
                    newObjPtr,
                    DeleteDcsCoordsTranslateCmd );
    return TCL_OK;
}
