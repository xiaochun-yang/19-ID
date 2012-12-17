#include <string.h>
#include <tcl.h>
#include <stdlib.h>
#include <errno.h>
#include <math.h>
#include "matrix.h"

extern "C" {
int DcsScan2DDataCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
void DeleteDcsScan2DDataCmd( ClientData cdata );
int NewDcsScan2DDataCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv );
int DcsAxisTicks( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] );
};

static char normal_result[] = "normal OK";

static double* buffer_x(NULL);
static double* buffer_y(NULL);
static size_t currentBufferSize(0);

static int resizeArray( double*& x, double*& y, size_t newsize )
{
        if (x)
    {
        delete [] x;
        x = NULL;
    }
    if (y)
    {
        delete [] y;
        y = NULL;
    }
    x = new double[newsize];
    y = new double[newsize];
    if (x == NULL || y == NULL)
    {
        if (x)
        {
            delete [] x;
            x = NULL;
        }
        if (y)
        {
            delete [] y;
            y = NULL;
        }
        return 0;
    }
    return 1;
}


#define MAX_SEGMENT 100
int DcsScan2DDataCmd( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    //char puts_buffer[256] = {0};
        
    DcsScan2DData* pScan2DData = (DcsScan2DData*)cdata;
    DcsMatrix* pBase = pScan2DData;

    if (objc < 2)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "command" );
        return TCL_ERROR;
    }

    char* argv1 = Tcl_GetString( objv[1] );

    if (!strcmp( argv1, "setup" ))
    {
        int numRow = 0;
        double y0(0);
        double dy(1);
        int numColumn = 0; 
        double x0(0);
        double dx(1);

        if (objc < 8)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "numRow y0 dy numColumn x0 dx" );
            return TCL_ERROR;
        }
        if (Tcl_GetIntFromObj( interp, objv[2], &numRow ) != TCL_OK)
        {
            Tcl_SetResult( interp, "numRow is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &y0 ) != TCL_OK)
        {
            Tcl_SetResult( interp, "y0 is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[4], &dy ) != TCL_OK)
        {
            Tcl_SetResult( interp, "dy is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetIntFromObj( interp, objv[5], &numColumn ) != TCL_OK)
        {
            Tcl_SetResult( interp, "numColumn is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[6], &x0 ) != TCL_OK)
        {
            Tcl_SetResult( interp, "x0 is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[7], &dx ) != TCL_OK)
        {
            Tcl_SetResult( interp, "dx is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
        if (!pScan2DData->setup( numRow, y0, dy, numColumn, x0, dx ))
        {
            Tcl_SetResult( interp, "setup failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }

    if (!strcmp( argv1, "addData" ))
    {
        double x = 0;
        double y = 0;
        double value = 0;
        if (objc < 5)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "y x value" );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[2], &y ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad y", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &x ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad x", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[4], &value ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad value", TCL_STATIC );
            return TCL_ERROR;
        }

        int result = pScan2DData->addData( x, y, value );
        if (result == 0)
        {
            Tcl_SetResult( interp, "addData failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, result );
        return TCL_OK;
    }
    if (!strcmp( argv1, "addDataByIndex" ))
    {
        int index = -1;
        double y = 0;
        double value = 0;
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "index value" );
            return TCL_ERROR;
        }
        if (Tcl_GetIntFromObj( interp, objv[2], &index ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad index", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &value ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad value", TCL_STATIC );
            return TCL_ERROR;
        }

        int result = pScan2DData->addData( index, value );
        if (result == 0)
        {
            Tcl_SetResult( interp, "putDataByIndex failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, result );
        return TCL_OK;
    }
    if (!strcmp( argv1, "setNodeSize" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "width height" );
            return TCL_ERROR;
        }
        double w(1);
        double h(1);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &w ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad width", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &h ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad height", TCL_STATIC );
            return TCL_ERROR;
        }
        pScan2DData->setNodeSize( w, h );
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }
    if (!strcmp( argv1, "set1DPlotSize" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "rowPlotHeight columnPlotWidth" );
            return TCL_ERROR;
        }
        double w(1);
        double h(1);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &h ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad rowPlotHeight", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &w ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad columnPlotWidth", TCL_STATIC );
            return TCL_ERROR;
        }
        pScan2DData->setRowColumnPlotSize( h, w );
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }
    if (!strcmp( argv1, "allDataDefined" ))
    {
        int result = pScan2DData->allDataDefined( );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, result );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getColor" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "row col" );
            return TCL_ERROR;
        }
        int row(0);
        int col(0);
        int color(-1);
        if (Tcl_GetIntFromObj( interp, objv[2], &row ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad row", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetIntFromObj( interp, objv[3], &col ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad col", TCL_STATIC );
            return TCL_ERROR;
        }
        color = pScan2DData->getColor( row, col );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, color );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getValue" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "x y" );
            return TCL_ERROR;
        }
        double x(0);
        double y(0);
        double value(0);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &x ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad x", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &y ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad y", TCL_STATIC );
            return TCL_ERROR;
        }
        if (!pScan2DData->getValue( x, y, value ))
        {
            Tcl_SetResult( interp, "getValue failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetDoubleObj( pResultObj, value );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getValueRC" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "row column" );
            return TCL_ERROR;
        }
        int r(0);
        int c(0);
        double value(0);
        if (Tcl_GetIntFromObj( interp, objv[2], &r ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad row", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetIntFromObj( interp, objv[3], &c ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad column", TCL_STATIC );
            return TCL_ERROR;
        }
        if (!pBase->getValue( r, c, value ))
        {
            Tcl_SetResult( interp, "getValue failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetDoubleObj( pResultObj, value );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getMinMax" ))
    {
        double myMin(0);
        double myMax(0);
        char result[64] = {0};

        if (!pScan2DData->getMinMax( myMin, myMax ))
        {
            Tcl_SetResult( interp, "getMinMax failed", TCL_STATIC );
            return TCL_ERROR;
        }
        sprintf( result, "%.5lg %.5lg", myMin, myMax );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetStringObj( pResultObj, result, strlen( result ) );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getContour" ))
    {
        //puts( "+CMD getContour\n" );
        double level(0);

        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "level" );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[2], &level ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad level", TCL_STATIC );
            return TCL_ERROR;
        }
            
        DcsContourSegment segments[MAX_SEGMENT];
        int num_segment(0);

        //get size
        size_t desiredSize = 2 * pScan2DData->getNumRow( ) * pScan2DData->getNumColumn( );
        //sprintf( puts_buffer, "desiredSize=%lu, currentSize=%lu\n", desiredSize, currentBufferSize );
        //puts( puts_buffer );
        if (desiredSize > currentBufferSize)
        {
            if (!resizeArray( buffer_x, buffer_y, desiredSize ))
            {
                currentBufferSize = 0;
                Tcl_SetResult( interp, "failed, out of memory", TCL_STATIC );
                return TCL_ERROR;
            }
            currentBufferSize = desiredSize;
        }
        //sprintf( puts_buffer, "new currentSize %lu\n", currentBufferSize );
        //puts( puts_buffer );
        memset( buffer_x, 0, sizeof(*buffer_x) * currentBufferSize );
        memset( buffer_y, 0, sizeof(*buffer_y) * currentBufferSize );

        //call function
        int length(0);
        //puts( "calling the C++ function" );
        num_segment = pScan2DData->getContour( level, currentBufferSize, buffer_x, buffer_y, length,
                        MAX_SEGMENT, segments );
        //sprintf( puts_buffer, "function returned %d\n", num_segment );
        //puts( puts_buffer );

        //put results into TCL
        //clear the variable first
        Tcl_UnsetVar( interp, "m_contour", TCL_NAMESPACE_ONLY );
        int seg_no(0);
        for (seg_no = 0; seg_no < num_segment; ++seg_no)
        {
            char sub[32] = {0};
            sprintf( sub, "%d", seg_no );

            //sprintf( puts_buffer, "put into TCL: seg_no: %s\n", sub );
            //puts( puts_buffer );

            int num_point = segments[seg_no].m_length;
            //sprintf( puts_buffer, "num points: %d\n", num_point );
            //puts( puts_buffer );
            if (num_point <= 1)
            {
                continue;
            }

            int index(0);
            for (index = 0; index < num_point; ++index)
            {
                char buffer[64] = {0};
                int offset = segments[seg_no].m_offset + index;
                sprintf( buffer, "%.1f", buffer_x[offset] );
                if (Tcl_SetVar2( interp, "m_contour", sub, buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
                {
                    Tcl_SetResult( interp, "failed to put result into varialbe m_contour", TCL_STATIC );
                    puts( "set var failed for contour" );
                    return TCL_ERROR;
                }
                sprintf( buffer, "%.1f", buffer_y[offset] );
                if (Tcl_SetVar2( interp, "m_contour", sub, buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
                {
                    Tcl_SetResult( interp, "failed to put result into varialbe m_contour", TCL_STATIC );
                    return TCL_ERROR;
                }
            }
        }
        //puts( "getContour done\n" );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, num_segment );
        return TCL_OK;
    }
    if (!strcmp( argv1, "setAllData" )) {
        pScan2DData->setAllUndefinedNodeToMin( );
        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }

    if (!strcmp( argv1, "getRowPlot" ))
    {
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "y" );
            return TCL_ERROR;
        }
        double y(0);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &y ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad y", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_UnsetVar( interp, "m_rowPlot", TCL_NAMESPACE_ONLY );
        //get size
        size_t desiredSize = pScan2DData->getNumColumn( );
        if (desiredSize > currentBufferSize)
        {
            if (!resizeArray( buffer_x, buffer_y, desiredSize ))
            {
                currentBufferSize = 0;
                Tcl_SetResult( interp, "failed, out of memory", TCL_STATIC );
                return TCL_ERROR;
            }
            currentBufferSize = desiredSize;
        }
        memset( buffer_x, 0, sizeof(*buffer_x) * currentBufferSize );
        memset( buffer_y, 0, sizeof(*buffer_y) * currentBufferSize );

        //call function
        int length(0);
        pScan2DData->getRowPlot( y, currentBufferSize, buffer_x, buffer_y, length );
        if (length <= 0)
        {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            Tcl_SetIntObj( pResultObj, length );
            return TCL_OK;
        }

        //fill TCL result
        for (int i = 0; i < length; ++i)
        {
            char buffer[64] = {0};
            sprintf( buffer, "%.1f", buffer_x[i] );
            if (Tcl_SetVar( interp, "m_rowPlot", buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
            {
                return TCL_ERROR;
            }
            sprintf( buffer, "%.1f", buffer_y[i] );
            if (Tcl_SetVar( interp, "m_rowPlot", buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
            {
                return TCL_ERROR;
            }
        }
        return TCL_OK;
    }

    if (!strcmp( argv1, "getColumnPlot" ))
    {
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "x" );
            return TCL_ERROR;
        }
        double x(0);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &x ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad x", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_UnsetVar( interp, "m_columnPlot", TCL_NAMESPACE_ONLY );
        //get size
        size_t desiredSize = pScan2DData->getNumRow( );
        if (desiredSize > currentBufferSize)
        {
            if (!resizeArray( buffer_x, buffer_y, desiredSize ))
            {
                currentBufferSize = 0;
                Tcl_SetResult( interp, "failed, out of memory", TCL_STATIC );
                return TCL_ERROR;
            }
            currentBufferSize = desiredSize;
        }
        memset( buffer_x, 0, sizeof(*buffer_x) * currentBufferSize );
        memset( buffer_y, 0, sizeof(*buffer_y) * currentBufferSize );

        //call function
        int length(0);
        pScan2DData->getColumnPlot( x, currentBufferSize, buffer_x, buffer_y, length );
        if (length <= 0)
        {
            Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
            Tcl_SetIntObj( pResultObj, length );
            return TCL_OK;
        }

        //fill TCL result
        for (int i = 0; i < length; ++i)
        {
            char buffer[64] = {0};
            sprintf( buffer, "%.1f", buffer_x[i] );
            if (Tcl_SetVar( interp, "m_columnPlot", buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
            {
                return TCL_ERROR;
            }
            sprintf( buffer, "%.1f", buffer_y[i] );
            if (Tcl_SetVar( interp, "m_columnPlot", buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
            {
                return TCL_ERROR;
            }
        }
        return TCL_OK;
    }
    if (!strcmp( argv1, "toColumnRow" ))
    {
        if (objc < 4)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "x y" );
            return TCL_ERROR;
        }
        double x(0);
        double y(0);
        if (Tcl_GetDoubleFromObj( interp, objv[2], &x ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad x", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &y ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad y", TCL_STATIC );
            return TCL_ERROR;
        }
        int column(0);
        int row(0);
        if (!pScan2DData->toColumnRow( x, y, column, row ))
        {
            Tcl_SetResult( interp, "toColumnRow failed", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        char result[128] = {0};
        sprintf( result, "%d %d", column, row );
        Tcl_SetStringObj( pResultObj, result, strlen( result ) );
        return TCL_OK;
    }
        
    if (!strcmp( argv1, "setValues" ))
    {
        if (objc < 3)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "valueList" );
            return TCL_ERROR;
        }
        int len = 0;
        char **strValues;
        char* argv2 = Tcl_GetString( objv[2] );
        if (Tcl_SplitList(interp, argv2, &len, &strValues) != TCL_OK) {
            Tcl_SetResult( interp, "bad values", TCL_STATIC );
            return TCL_ERROR;
        }
        double values[len];
        int i;
        for (i = 0; i < len; ++i) {
            char *pEnd = NULL;
            values[i] = strtod(strValues[i], &pEnd);
            if (pEnd == strValues[i]) {
                //printf("got strange: {%s} at %d\n", strValues[i], i );
                values[i] = INFINITY;
            }
        }
        Tcl_Free( (char *) strValues);

        int result = pScan2DData->setValues( len, values );
        if (result == 0)
        {
            Tcl_SetResult( interp, "setValues failed: wrong length of values", TCL_STATIC );
            return TCL_ERROR;
        }
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, result );
        return TCL_OK;
    }
    if (!strcmp( argv1, "getRidge" ))
    {
        puts( "+CMD getRidge\n" );
        double level(0);
        double beamWidth(0);
        double beamSpace(0);

        if (objc < 5)
        {
            Tcl_WrongNumArgs( interp, 2, objv, "level beam_width beam_space" );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[2], &level ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad level", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[3], &beamWidth ) != TCL_OK) {
            Tcl_SetResult( interp, "bad beamWidth", TCL_STATIC );
            return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj( interp, objv[4], &beamSpace ) != TCL_OK)
        {
            Tcl_SetResult( interp, "bad beamSpace", TCL_STATIC );
            return TCL_ERROR;
        }

        vector<vector<RidgeNode> > ridges;
        int numRidges = pScan2DData->getRidge(
            level, beamWidth, beamSpace, ridges
        );
        printf("total ridges found: %d\n", numRidges );
        if (numRidges > 0) {
            vector<vector<RidgeNode> >::iterator iRidge;
            vector<RidgeNode>::iterator iNode;
            printf( "ridge==================\n");
            for (iRidge = ridges.begin( ); iRidge != ridges.end( ); ++iRidge) {
                for (iNode = iRidge->begin( ); iNode != iRidge->end( ); ++iNode) {
                    printf( "%f %f %f\n", iNode->x, iNode->y, iNode->w );
                }
            }
            printf( "==================\n");
        }
        //put results into TCL
        //clear the variable first
        Tcl_UnsetVar( interp, "m_ridge", TCL_NAMESPACE_ONLY );
        int ridge_no(0);
        for (ridge_no = 0; ridge_no < ridges.size( ); ++ridge_no) {
            char sub[32] = {0};
            sprintf( sub, "%d", ridge_no );

            printf( "put into TCL:ridge_no: %s\n", sub );

            int num_point = ridges[ridge_no].size( );
            printf( "num points: %d\n", num_point );

            int index(0);
            for (index = 0; index < num_point; ++index)
            {
                char buffer[64] = {0};
                sprintf( buffer, "%.1f", ridges[ridge_no][index].x );
                if (Tcl_SetVar2( interp, "m_ridge", sub, buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
                {
                    Tcl_SetResult( interp, "failed to put result into varialbe m_ridge", TCL_STATIC );
                    puts( "set var failed for contour" );
                    return TCL_ERROR;
                }
                printf( "added %s to m_ridge %s\n", buffer, sub );
                sprintf( buffer, "%.1f", ridges[ridge_no][index].y );
                if (Tcl_SetVar2( interp, "m_ridge", sub, buffer, TCL_LIST_ELEMENT | TCL_APPEND_VALUE | TCL_NAMESPACE_ONLY | TCL_LEAVE_ERR_MSG ) == NULL)
                {
                    Tcl_SetResult( interp, "failed to put result into varialbe m_ridge", TCL_STATIC );
                    return TCL_ERROR;
                }
                printf( "added %s to m_ridge %s\n", buffer, sub );
            }
        }
        puts( "getRidget done\n" );
        Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
        Tcl_SetIntObj( pResultObj, ridges.size( ) );
        return TCL_OK;
    }

    Tcl_SetResult( interp, "unsupported commande", TCL_STATIC );
    return TCL_ERROR;
}
void DeleteDcsScan2DDataCmd( ClientData cdata )
{
    //printf( "matrx at %p deleted \n", cdata );
    delete (DcsScan2DData *)cdata;
}

int NewDcsScan2DDataCmd( ClientData cdata, Tcl_Interp* interp, int argc, char** argv )
{
    static unsigned int id(0);

    DcsScan2DData* newMatrixPtr = new DcsScan2DData( );

    //create unique name
    sprintf( interp->result, "DcsScan2DData%u", id++ );
    Tcl_CreateObjCommand( interp,
                    interp->result,
                    DcsScan2DDataCmd,
                    newMatrixPtr,
                    DeleteDcsScan2DDataCmd );
    return TCL_OK;
}

int DcsAxisTicks( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 3)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "start end" );
        return TCL_ERROR;
    }
    double start(0);
    double end(0);

    if (Tcl_GetDoubleFromObj( interp, objv[1], &start ) != TCL_OK)
    {
        Tcl_SetResult( interp, "bad start", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, objv[2], &end ) != TCL_OK)
    {
        Tcl_SetResult( interp, "bad end", TCL_STATIC );
        return TCL_ERROR;
    }
    double stepSize(1);
    int nStart(0);
    int numTicks(0);
    DcsScan2DData::AxisStepStyle style(DcsScan2DData::STEP_1);
    if (!DcsScan2DData::generateAxis( start, end,
                     stepSize, nStart, numTicks, style ))
    {
        Tcl_SetResult( interp, "generateAxis failed", TCL_STATIC );
        return TCL_ERROR;
    }
    char result[256] = {0};
    sprintf( result, "%.5lg %d %d %d", stepSize, nStart, numTicks, style);
    Tcl_Obj* pResultObj = Tcl_GetObjResult( interp );
    Tcl_SetStringObj( pResultObj, result, strlen( result ) );
    return TCL_OK;
}
