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

    double mm[4][4];
    mm[0][0] = 1;
    mm[0][1] = m_u0;
    mm[0][2] = m_v0;
    mm[0][3] = m_u0 * m_v0;

    mm[1][0] = 1;
    mm[1][1] = m_u1;
    mm[1][2] = m_v1;
    mm[1][3] = m_u1 * m_v1;

    mm[2][0] = 1;
    mm[2][1] = m_u2;
    mm[2][2] = m_v2;
    mm[2][3] = m_u2 * m_v2;

    mm[3][0] = 1;
    mm[3][1] = m_u3;
    mm[3][2] = m_v3;
    mm[3][3] = m_u3 * m_v3;

    double inv[4][4] = {0};

    if (inverseM4( (const double *)mm, (double*)inv )) {
        m_ax = inv[0][0] * x0 + inv[0][1] * x1 + inv[0][2] * x2 + inv[0][3] * x3;
        m_bx = inv[1][0] * x0 + inv[1][1] * x1 + inv[1][2] * x2 + inv[1][3] * x3;
        m_cx = inv[2][0] * x0 + inv[2][1] * x1 + inv[2][2] * x2 + inv[2][3] * x3;
        m_dx = inv[3][0] * x0 + inv[3][1] * x1 + inv[3][2] * x2 + inv[3][3] * x3;

        m_ay = inv[0][0] * y0 + inv[0][1] * y1 + inv[0][2] * y2 + inv[0][3] * y3;
        m_by = inv[1][0] * y0 + inv[1][1] * y1 + inv[1][2] * y2 + inv[1][3] * y3;
        m_cy = inv[2][0] * y0 + inv[2][1] * y1 + inv[2][2] * y2 + inv[2][3] * y3;
        m_dy = inv[3][0] * y0 + inv[3][1] * y1 + inv[3][2] * y2 + inv[3][3] * y3;
        m_ready = 1;
    } else {
        m_ready = 0;
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

            double x = m_ax + m_bx * mapU + m_cx * mapV + m_dx * mapU * mapV;
            double y = m_ay + m_by * mapU + m_cy * mapV + m_dy * mapU * mapV;
            char buffer[1024];
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
    fprintf( stderr, "xa=%f\n", m_ax );
    fprintf( stderr,  "xb=%f\n", m_bx );
    fprintf( stderr,  "xc=%f\n", m_cx );
    fprintf( stderr,  "xd=%f\n", m_dx );
    fprintf( stderr, "ya=%f\n", m_ay );
    fprintf( stderr,  "yb=%f\n", m_by );
    fprintf( stderr,  "yc=%f\n", m_cy );
    fprintf( stderr,  "yd=%f\n", m_dy );
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
int ProjectiveMapping::inverseM4( const double m[16], double inv[16] ) {
    double det;
    int i;

    inv[0] = m[5]  * m[10] * m[15] - 
             m[5]  * m[11] * m[14] - 
             m[9]  * m[6]  * m[15] + 
             m[9]  * m[7]  * m[14] +
             m[13] * m[6]  * m[11] - 
             m[13] * m[7]  * m[10];

    inv[4] = -m[4]  * m[10] * m[15] + 
              m[4]  * m[11] * m[14] + 
              m[8]  * m[6]  * m[15] - 
              m[8]  * m[7]  * m[14] - 
              m[12] * m[6]  * m[11] + 
              m[12] * m[7]  * m[10];

    inv[8] = m[4]  * m[9] * m[15] - 
             m[4]  * m[11] * m[13] - 
             m[8]  * m[5] * m[15] + 
             m[8]  * m[7] * m[13] + 
             m[12] * m[5] * m[11] - 
             m[12] * m[7] * m[9];

    inv[12] = -m[4]  * m[9] * m[14] + 
               m[4]  * m[10] * m[13] +
               m[8]  * m[5] * m[14] - 
               m[8]  * m[6] * m[13] - 
               m[12] * m[5] * m[10] + 
               m[12] * m[6] * m[9];

    inv[1] = -m[1]  * m[10] * m[15] + 
              m[1]  * m[11] * m[14] + 
              m[9]  * m[2] * m[15] - 
              m[9]  * m[3] * m[14] - 
              m[13] * m[2] * m[11] + 
              m[13] * m[3] * m[10];

    inv[5] = m[0]  * m[10] * m[15] - 
             m[0]  * m[11] * m[14] - 
             m[8]  * m[2] * m[15] + 
             m[8]  * m[3] * m[14] + 
             m[12] * m[2] * m[11] - 
             m[12] * m[3] * m[10];

    inv[9] = -m[0]  * m[9] * m[15] + 
              m[0]  * m[11] * m[13] + 
              m[8]  * m[1] * m[15] - 
              m[8]  * m[3] * m[13] - 
              m[12] * m[1] * m[11] + 
              m[12] * m[3] * m[9];

    inv[13] = m[0]  * m[9] * m[14] - 
              m[0]  * m[10] * m[13] - 
              m[8]  * m[1] * m[14] + 
              m[8]  * m[2] * m[13] + 
              m[12] * m[1] * m[10] - 
              m[12] * m[2] * m[9];

    inv[2] = m[1]  * m[6] * m[15] - 
             m[1]  * m[7] * m[14] - 
             m[5]  * m[2] * m[15] + 
             m[5]  * m[3] * m[14] + 
             m[13] * m[2] * m[7] - 
             m[13] * m[3] * m[6];

    inv[6] = -m[0]  * m[6] * m[15] + 
              m[0]  * m[7] * m[14] + 
              m[4]  * m[2] * m[15] - 
              m[4]  * m[3] * m[14] - 
              m[12] * m[2] * m[7] + 
              m[12] * m[3] * m[6];

    inv[10] = m[0]  * m[5] * m[15] - 
              m[0]  * m[7] * m[13] - 
              m[4]  * m[1] * m[15] + 
              m[4]  * m[3] * m[13] + 
              m[12] * m[1] * m[7] - 
              m[12] * m[3] * m[5];

    inv[14] = -m[0]  * m[5] * m[14] + 
               m[0]  * m[6] * m[13] + 
               m[4]  * m[1] * m[14] - 
               m[4]  * m[2] * m[13] - 
               m[12] * m[1] * m[6] + 
               m[12] * m[2] * m[5];

    inv[3] = -m[1] * m[6] * m[11] + 
              m[1] * m[7] * m[10] + 
              m[5] * m[2] * m[11] - 
              m[5] * m[3] * m[10] - 
              m[9] * m[2] * m[7] + 
              m[9] * m[3] * m[6];

    inv[7] = m[0] * m[6] * m[11] - 
             m[0] * m[7] * m[10] - 
             m[4] * m[2] * m[11] + 
             m[4] * m[3] * m[10] + 
             m[8] * m[2] * m[7] - 
             m[8] * m[3] * m[6];

    inv[11] = -m[0] * m[5] * m[11] + 
               m[0] * m[7] * m[9] + 
               m[4] * m[1] * m[11] - 
               m[4] * m[3] * m[9] - 
               m[8] * m[1] * m[7] + 
               m[8] * m[3] * m[5];

    inv[15] = m[0] * m[5] * m[10] - 
              m[0] * m[6] * m[9] - 
              m[4] * m[1] * m[10] + 
              m[4] * m[2] * m[9] + 
              m[8] * m[1] * m[6] - 
              m[8] * m[2] * m[5];

    det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8] + m[3] * inv[12];

    if (det == 0)
        return 0;

    det = 1.0 / det;

    for (i = 0; i < 16; i++)
        inv[i] = inv[i] * det;

    return 1;
}
