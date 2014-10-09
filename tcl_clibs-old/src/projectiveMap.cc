#include "projectiveMap.h"


ProjectiveMapping::ProjectiveMapping( ):
m_ready(false)
{
}
void ProjectiveMapping::setupAnchorDestination( const double xyList[4][2] ) {
    double x0 = xyList[0][0];
    double y0 = xyList[0][1];
    double x1 = xyList[1][0];
    double y1 = xyList[1][1];
    double x2 = xyList[2][0];
    double y2 = xyList[2][1];
    double x3 = xyList[3][0];
    double y3 = xyList[3][1];

    double m[3][3] = {0};

    if (m_v0 != m_v1 || m_u1 != m_u2 || m_v2 != m_v3 || m_u3 != m_u0) {
        //fprintf( stderr, "not a orth rectanble\n" );
        if (!matrixQuadToQuad( m_uvList, xyList, m )) {
            return;
        }
        m_a = m[0][0] / m[2][2];
        m_b = m[1][0] / m[2][2];
        m_c = m[2][0] / m[2][2];
        m_d = m[0][1] / m[2][2];
        m_e = m[1][1] / m[2][2];
        m_f = m[2][1] / m[2][2];
        m_g = m[0][2] / m[2][2];
        m_h = m[1][2] / m[2][2];
        m_ready = true;
        //printInfo( );
    } else {
        //fprintf( stderr, "orth rectanble\n" );
        if (!matrixRectangleToQuad( xyList, m_u0, m_v0, m_u2, m_v2, m )) {
            return;
        }
        m_a = m[0][0] / m[2][2];
        m_b = m[1][0] / m[2][2];
        m_c = m[2][0] / m[2][2];
        m_d = m[0][1] / m[2][2];
        m_e = m[1][1] / m[2][2];
        m_f = m[2][1] / m[2][2];
        m_g = m[0][2] / m[2][2];
        m_h = m[1][2] / m[2][2];
        m_ready = true;
        //printInfo( );
    }

}
void ProjectiveMapping::map( int numPoint,
const double uList[], const double vList[],
double xList[], double yList[] ) const {
    int i;
    for (i = 0; i < numPoint; ++i) {
        double mm = m_g * uList[i] + m_h * vList[i] + 1.0;
        double mx = m_a * uList[i] + m_b * vList[i] + m_c;
        double my = m_d * uList[i] + m_e * vList[i] + m_f;

        xList[i] = mx / mm;
        yList[i] = my / mm;
    }
}
const char *ProjectiveMapping::map( const char uvList[] ) {
    const char *pCurrent;
    char *pEnd;

    m_mapResult.clear( );
    pCurrent = uvList;
    int numGot = 0;
    double mapU;
    double mapV;
    while (pCurrent[0] != '\0') {
        double v = strtod( pCurrent, &pEnd );
        if (pEnd == pCurrent) {
            //fprintf( stderr, "break, parse failed\n" );
            break;
        }
        if (numGot % 2) {
            mapV = v;
            double mm = m_g * mapU + m_h * mapV + 1.0;
            double mx = m_a * mapU + m_b * mapV + m_c;
            double my = m_d * mapU + m_e * mapV + m_f;

            double x = mx / mm;
            double y = my / mm;
            char buffer[1024] = {0};
            sprintf( buffer, " %.3lf %.3lf",x, y );
            m_mapResult += buffer;
        } else {
            mapU = v;
        }
        pCurrent = pEnd;
        ++numGot;
    }
    return m_mapResult.c_str( );
}
void ProjectiveMapping::printInfo( ) const {
    fprintf( stderr, "a=%f\n", m_a );
    fprintf( stderr,  "b=%f\n", m_b );
    fprintf( stderr,  "c=%f\n", m_c );
    fprintf( stderr,  "d=%f\n", m_d );
    fprintf( stderr,  "e=%f\n", m_e );
    fprintf( stderr,  "f=%f\n", m_f );
    fprintf( stderr,  "g=%f\n", m_g );
    fprintf( stderr,  "h=%f\n", m_h );
}
#define X(i) quad[i][0]
#define Y(i) quad[i][1]
int ProjectiveMapping::matrixSquareToQuad(
    const double quad[4][2],
    double m[3][3]
) {
    double sx = X(0) - X(1) + X(2) - X(3);
    double sy = Y(0) - Y(1) + Y(2) - Y(3);
    if (sx == 0 && sy == 0) {
        m[0][0] = X(1) - X(0);
        m[1][0] = X(2) - X(1);
        m[2][0] = X(0);
        m[0][1] = Y(1) - Y(0);
        m[1][1] = Y(2) - Y(1);
        m[2][1] = Y(0);
        m[0][2] = 0;
        m[1][2] = 0;
        m[2][2] = 1.0;
        return 1;
    }
    double dx1 = X(1) - X(2);
    double dx2 = X(3) - X(2);
    double dy1 = Y(1) - Y(2);
    double dy2 = Y(3) - Y(2);
    double del = det2( dx1, dx2, dy1, dy2 );
    if (del == 0) {
        return 0;
    }

    m[0][2] = det2( sx,  dx2, sy,  dy2 ) / del;
    m[1][2] = det2( dx1, sx,  dy1, sy  ) / del;
    m[2][2] = 1.0;
    m[0][0] = X(1) - X(0) + m[0][2] * X(1);
    m[1][0] = X(3) - X(0) + m[1][2] * X(3);
    m[2][0] = X(0);
    m[0][1] = Y(1) - Y(0) + m[0][2] * Y(1);
    m[1][1] = Y(3) - Y(0) + m[1][2] * Y(3);
    m[2][1] = Y(0);
    return 1;
}
int ProjectiveMapping::matrixRectangleToQuad(
    const double quad[4][2],
    double u0, double v0, double u1, double v1,
    double m[3][3]
) {
    double du = u1 - u0;
    double dv = v1 - v0;
    if (du == 0 || dv == 0) {
        return 0;
    }

    if (!matrixSquareToQuad( quad, m )) {
        return 0;
    }
    // rectangle to unit square
    m[0][0] /= du;
    m[1][0] /= dv;
    m[2][0] -= m[0][0] * u0 + m[1][0] * v0;
    m[0][1] /= du;
    m[1][1] /= dv;
    m[2][1] -= m[0][1] * u0 + m[1][1] * v0;
    m[0][2] /= du;
    m[1][2] /= dv;
    m[2][2] -= m[0][2] * u0 + m[1][2] * v0;
    return 1;
}
int ProjectiveMapping::matrixQuadToQuad( const double uvQuad[4][2],
    const double xyQuad[4][2], double mUV2XY[3][3]
) {
    double mSquare2UV[3][3] = {0};
    double mUV2Square[3][3] = {0};
    double mSquare2XY[3][3] = {0};

    if (!matrixSquareToQuad( uvQuad, mSquare2UV )) {
        return 0;
    }
    if (getAdjoint( mSquare2UV, mUV2Square ) ==0.0) {
        printf( "warning, determinant =0\n" );
    }
    if (!matrixSquareToQuad( xyQuad, mSquare2XY )) {
        return 0;
    }

    multiple( mUV2Square, mSquare2XY, mUV2XY );
    return 1;
}
#define ORIG_X orig[0]
#define ORIG_Y orig[1]
#define ORIG_Z orig[2]
#define ORIG_A orig[3]
#define ORIG_CV orig[4]
#define ORIG_CH orig[5]
#

void DcsCoordsTranslate::calculateProjectionFromSamplePosition(
        const double orig[10],
        double x, double y, double z,
        double &vert, double &horz,
        bool return_micron
) {
    double dx = x - ORIG_X;
    double dy = y - ORIG_Y;
    double dz = z - ORIG_Z;
    double da = ORIG_A * 3.1415926 / 180.0;

    double proj_x = -dx * cos( da ) - dy * sin( da );
    //double proj_y =  dx * sin( da ) - dy * cos( da );
    double proj_z = -dz;

    if (return_micron) {
        vert = proj_x * 1000.0;
        horz = proj_z * 1000.0;
        return;
    }
    vert = proj_x / ORIG_CV;
    horz = proj_z / ORIG_CH;
}
int DcsCoordsTranslate::reverseProjectCoords(
        const double targetOrig[10],
        const double sourceOrig[10], 
        size_t       numPoint,
        const double targetX[],
        const double targetY[],
        double       sourceX[],
        double       sourceY[]
) {
    double sCntrX = sourceOrig[9] * sourceOrig[5] * 1000.0;
    double sCntrY = sourceOrig[8] * sourceOrig[4] * 1000.0;
    double tCntrX = targetOrig[9] * targetOrig[5] * 1000.0;
    double tCntrY = targetOrig[8] * targetOrig[4] * 1000.0;

    double v0 = 0;
    double h0 = 0;
    calculateProjectionFromSamplePosition( targetOrig,
        sourceOrig[0], sourceOrig[1], sourceOrig[2],
        v0, h0, true
    );

    double a = (sourceOrig[3] - targetOrig[3]) * 3.1415926 / 180.0;
    if (fabs( cos( a ) ) < 0.01) {
        return 0;
    }

    double hOffset =  -h0 - tCntrX           + sCntrX;
    double vScale  = cos( a );
    double vOffset = (-v0 - tCntrY) / vScale + sCntrY;

    int i;
    for (i = 0; i < numPoint; ++i) {
        sourceX[i] = targetX[i]          + hOffset;
        sourceY[i] = targetY[i] / vScale + vOffset;
    }
    return 1;
}
void DcsCoordsTranslate::parseInputCoords( const char xyList[] ) {
    const char *pCurrent;
    char *pEnd;

    //fprintf( stderr, "enter parseInput\n" );

    if (xyList == NULL) {
        fprintf( stderr, "NULL input\n" );
        return;
    }

    m_inputXVector.clear( );
    m_inputYVector.clear( );
    //fprintf( stderr, "after clear\n" );

    pCurrent = xyList;
    double x;
    double y;
    size_t numGot = 0;
    //char buffer[1024] = {0};
    //strncpy( buffer, pCurrent, 40 );
    //fprintf( stderr, "current=%s\n", buffer );
    while (pCurrent[0] != '\0') {
        //strncpy( buffer, pCurrent, 40 );
        //fprintf( stderr, "current=%s\n", buffer );
        double v = strtod( pCurrent, &pEnd );
        if (pEnd == pCurrent) {
            //fprintf( stderr, "break, parse failed\n" );
            break;
        }
        if (numGot % 2) {
            y = v;
            m_inputXVector.push_back( x );
            m_inputYVector.push_back( y );
        } else {
            x = v;
        }
        pCurrent = pEnd;
        ++numGot;
        //fprintf( stderr, "parse input numGot=%ld x=%lf y=%lf\n", numGot, x, y );
    }
}
void DcsCoordsTranslate::translateProjectionCoords(
        const double sourceOrig[10],
        const double targetOrig[10],
        size_t numPoint,
        const double sourceX[],
        const double sourceY[],
        double targetX[],
        double targetY[]
) {
    double sCntrX = sourceOrig[9] * sourceOrig[5] * 1000.0;
    double sCntrY = sourceOrig[8] * sourceOrig[4] * 1000.0;
    double tCntrX = targetOrig[9] * targetOrig[5] * 1000.0;
    double tCntrY = targetOrig[8] * targetOrig[4] * 1000.0;

    double v0 = 0;
    double h0 = 0;
    calculateProjectionFromSamplePosition( targetOrig,
        sourceOrig[0], sourceOrig[1], sourceOrig[2],
        v0, h0, true
    );
    double a = (sourceOrig[3] - targetOrig[3]) * 3.1415926 / 180.0;

    double hOffset = h0 + tCntrX - sCntrX;
    double vScale  = cos( a );
    double vOffset = v0 + tCntrY - sCntrY * vScale;
    size_t i;
    for (i = 0; i < numPoint; ++i) {
        targetX[i] = sourceX[i]          + hOffset;
        targetY[i] = sourceY[i] * vScale + vOffset;
    }

}
int DcsCoordsTranslate::mapToDisplay( const char inputCoords[],
        size_t &numPoint,
        double *&userX, double *&userY, double *&pixelX, double *&pixelY,
        bool zoomOnly
    ) {
    if (!m_ready) {
        return 0;
    }

    if (m_displayOrig[4] == 0 || m_displayOrig[5] == 0) {
        fprintf( stderr, "no display size in mm yet\n" );
        return 0;
    }

    size_t i;
    // micron to pixel
    double xScale = m_displayWidthPixel  / (m_displayOrig[5] * 1000.0);
    double yScale = m_displayHeightPixel / (m_displayOrig[4] * 1000.0);

    parseInputCoords( inputCoords );
    numPoint = m_inputXVector.size( );

    if (zoomOnly) {
        m_targetXVector.resize( numPoint );
        m_targetYVector.resize( numPoint );
        userX = m_inputXVector.data( );
        userY = m_inputYVector.data( );
        pixelX = m_targetXVector.data( );
        pixelY = m_targetYVector.data( );
        for (i = 0; i < numPoint; ++i) {
            pixelX[i] = userX[i] * xScale;
            pixelY[i] = userY[i] * yScale;
        }
        return 1;
    }

    m_userXVector.resize( numPoint );
    m_userYVector.resize( numPoint );
    m_targetXVector.resize( numPoint );
    m_targetYVector.resize( numPoint );

    userX  = m_userXVector.data( );
    userY  = m_userYVector.data( );
    pixelX = m_targetXVector.data( );
    pixelY = m_targetYVector.data( );

    rotateDelta( m_oCenterX, m_oCenterY, m_oAngle, numPoint,
        m_inputXVector.data( ), m_inputYVector.data( ),
        userX, userY
    );
    translateProjectionCoords( m_originOrig, m_displayOrig,
        numPoint,
        userX,
        userY,
        userX,
        userY
    );
    for (i = 0; i < numPoint; ++i) {
        userX[i] -= m_uCenterX;
        userY[i] -= m_uCenterY;
    }

    // micron to pixel
    for (i = 0; i < numPoint; ++i) {
        pixelX[i] = userX[i] * xScale;
        pixelY[i] = userY[i] * yScale;
    }
    return 1;
}
int DcsCoordsTranslate::mapToOrigin( const char pixelCoords[],
        size_t &numPoint,
        double *&userX, double *&userY,
        double *&originX, double *&originY
) {
    if (!m_ready) {
        return 0;
    }
    if (m_displayWidthPixel == 0 || m_displayHeightPixel == 0) {
        fprintf( stderr, "display size in pixel not ready\n" );
        return 0;
    }

    size_t i;
    //pixel to micron
    double xScale = m_displayOrig[5] * 1000.0 / m_displayWidthPixel;
    double yScale = m_displayOrig[4] * 1000.0 / m_displayHeightPixel;

    parseInputCoords( pixelCoords );
    numPoint = m_inputXVector.size( );

    m_userXVector.resize( numPoint );
    m_userYVector.resize( numPoint );
    m_targetXVector.resize( numPoint );
    m_targetYVector.resize( numPoint );

    userX  = m_userXVector.data( );
    userY  = m_userYVector.data( );
    originX = m_targetXVector.data( );
    originY = m_targetYVector.data( );
    //pixel to micron
    for (i = 0; i < numPoint; ++i) {
        userX[i] = m_inputXVector[i] * xScale;
        userY[i] = m_inputYVector[i] * yScale;
    }

    for (i = 0; i < numPoint; ++i) {
        originX[i] = userX[i] + m_uCenterX;
        originY[i] = userY[i] + m_uCenterY;
    }
    if (!reverseProjectCoords( m_displayOrig, m_originOrig,
        numPoint,
        originX,
        originY,
        originX,
        originY
    )) {
        return 0;
    }
    rotateCalculationToDelta( m_oCenterX, m_oCenterY, -m_oAngle, numPoint,
        originX,
        originY,
        originX,
        originY
    );
        
    return 1;
}
int DcsCoordsTranslate::setup( const char originOrig[],
        const char displayOrig[], const char displaySizePixel[],
        double angle,
        double uCenterX, double uCenterY, double oCenterX, double oCenterY
) {
    int i;
    const char *pCurrent;
    char *pEnd;

    m_ready = false;

    //parse originOrig
    pCurrent = originOrig;
    for (i = 0; i < 10; ++i) {
        double v = strtod( pCurrent, &pEnd );
        if (pEnd == pCurrent) {
            fprintf( stderr, "less than 10 for origin %s\n", originOrig );
            return 0;
        }
        m_originOrig[i] = v;
        pCurrent = pEnd;
    }
    //parse displayOrig
    pCurrent = displayOrig;
    for (i = 0; i < 10; ++i) {
        double v = strtod( pCurrent, &pEnd );
        if (pEnd == pCurrent) {
            fprintf( stderr, "less than 10 for display %s\n", displayOrig );
            return 0;
        }
        m_displayOrig[i] = v;
        pCurrent = pEnd;
    }
    //parse displaySize in Pixel
    pCurrent = displaySizePixel;
    for (i = 0; i < 2; ++i) {
        double v = strtod( pCurrent, &pEnd );
        if (pEnd == pCurrent) {
            fprintf( stderr, "less than 2 for size %s\n", displaySizePixel );
            return 0;
        }
        if (i == 0) {
            m_displayWidthPixel = v;
        } else {
            m_displayHeightPixel = v;
        }
        pCurrent = pEnd;
    }


    m_oAngle = angle;
    m_uCenterX = uCenterX;
    m_uCenterY = uCenterY;
    m_oCenterX = oCenterX;
    m_oCenterY = oCenterY;
    m_ready = true;
    return 1;
}
