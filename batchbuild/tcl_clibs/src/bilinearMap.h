#ifndef DCS_BILINEAR
#define DCS_BILINEAR
#include <math.h>
#include <memory.h>
#include <stdio.h>
#include <vector>
#include <string>

using namespace std;

class BilinearMapping {
public:
    BilinearMapping( );
    virtual ~BilinearMapping( ) { }

    //set up.  This will also reset the matrix
    int setupAnchorSource( const double uvList[4][2] ) {
        m_ready = false;
        memcpy( m_uvList, uvList, sizeof(m_uvList) );
        m_u0 = uvList[0][0];
        m_v0 = uvList[0][1];
        m_u1 = uvList[1][0];
        m_v1 = uvList[1][1];
        m_u2 = uvList[2][0];
        m_v2 = uvList[2][1];
        m_u3 = uvList[3][0];
        m_v3 = uvList[3][1];
        if (m_v0 == m_v1 && m_u1 == m_u2 && m_v2 == m_v3 && m_u3 == m_u0
         && (m_u0 == m_u1 || m_v1 == m_v2)) {
            printf( "bad anchor uv\n" );
            return 0;
        }
        return 1;
    }
    void setupAnchorDestination( const double xyList[4][2] );
    void reset( ) {
        m_ready = false;
    }

    const char*  map( const char uvList[] );
    //DEBUG
    void printInfo( ) const;
    
private:
    static int inverseM4( const double in[16], double out[16] );

private:
    //anchor point source
    double m_uvList[4][2];
    double m_u0;
    double m_v0;
    double m_u1;
    double m_v1;
    double m_u2;
    double m_v2;
    double m_u3;
    double m_v3;
    // mapping matrix:
    double m_ax;
    double m_bx;
    double m_cx;
    double m_dx;

    double m_ay;
    double m_by;
    double m_cy;
    double m_dy;

    // self parse string and generate string
    std::string m_mapResult;

    bool m_ready;
};
#endif
