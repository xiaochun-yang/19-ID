#include "bilinearMap.h"


BilinearMapping::BilinearMapping( ):
m_ready(false)
{
}
void BilinearMapping::setupAnchorDestination( const double xyList[4][2] ) {
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
const char *BilinearMapping::map( const char uvList[] ) {
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
void BilinearMapping::printInfo( ) const {
    fprintf( stderr, "xa=%f\n", m_ax );
    fprintf( stderr,  "xb=%f\n", m_bx );
    fprintf( stderr,  "xc=%f\n", m_cx );
    fprintf( stderr,  "xd=%f\n", m_dx );
    fprintf( stderr, "ya=%f\n", m_ay );
    fprintf( stderr,  "yb=%f\n", m_by );
    fprintf( stderr,  "yc=%f\n", m_cy );
    fprintf( stderr,  "yd=%f\n", m_dy );
}
int BilinearMapping::inverseM4( const double m[16], double inv[16] ) {
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
