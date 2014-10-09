#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <tcl.h>
extern "C" int get_file_mtime( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] ) {
    const char* pFilename = NULL;
    double timestamp = 0;
    struct stat statBuffer;
    /* check input */
    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "filename" );
        return TCL_ERROR;
    }
    pFilename = Tcl_GetString( objv[1] );
    if (stat( pFilename, &statBuffer)) {
        Tcl_SetResult( interp, "stat failed", TCL_STATIC );
        return TCL_ERROR;
    }
    timestamp = statBuffer.st_mtim.tv_sec + double(statBuffer.st_mtim.tv_nsec) / 1.0e9;

    Tcl_SetDoubleObj( Tcl_GetObjResult( interp ), timestamp );
    return TCL_OK;
}
extern "C" int get_timeofday( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] ) {
    double timestamp = 0;
    struct timeval value;

    if (gettimeofday( &value, NULL )) {
        Tcl_SetResult( interp, "gettimeofday failed", TCL_STATIC );
        return TCL_ERROR;
    }

    timestamp = value.tv_sec + double(value.tv_usec) / 1.0e6;

    Tcl_SetDoubleObj( Tcl_GetObjResult( interp ), timestamp );
    return TCL_OK;
}
