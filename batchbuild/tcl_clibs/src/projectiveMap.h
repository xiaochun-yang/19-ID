#ifndef DCS_PROJECTIVE
#define DCS_PROJECTIVE
#include <math.h>
#include <memory.h>
#include <stdio.h>
#include <vector>
#include <string>

using namespace std;

class ProjectiveMapping {
public:
    ProjectiveMapping( );
    virtual ~ProjectiveMapping( ) { }

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
class DcsCoordsTranslate {
public:
    DcsCoordsTranslate( )
    : m_inputXVector(1024)
    , m_inputYVector(1024)
    , m_userXVector(1024)
    , m_userYVector(1024)
    , m_targetXVector(1024)
    , m_targetYVector(1024)
    , m_ready(false)
    { }
    ~DcsCoordsTranslate( ) { }

    void reset( ) { m_ready = false; }

    //check all Orig, cv ch pixel size cannot be 0
    int setup( const char originOrig[],
        const char displayOrig[], const char displayPixelSize[],
        double angle,
        double uCenterX, double uCenterY, double oCenterX, double oCenterY
    );

    int mapToDisplay( const char inputCoords[],
        size_t &numPoint,
        double *&userX, double *&userY, double *&pixelX, double *&pixelY,
        bool zoomOnly = false
    );

    int mapToOrigin( const char pixelCoords[],
        size_t &numPoint,
        double *&userX, double *&userY, double *&originX, double *&originY
    );

private:
    void parseInputCoords( const char xyList[] );

    static inline void rotateDeltaToDelta( double angle,
        size_t numPoint,
        const double dx[], const double dy[], double dxOut[], double dyOut[]
    ) {
        double cA = cos( angle );
        double sA = sin( angle );

        size_t i;
        for (i = 0; i < numPoint; ++ i) {
            dxOut[i] = cA * dx[i] - sA * dy[i];
            dyOut[i] = sA * dx[i] + cA * dy[i];
        }
    }
    static inline void rotateDelta( double cx, double cy,
        double angle,
        size_t numPoint,
        const double dx[], const double dy[], double xOut[], double yOut[]
    ) {
        rotateDeltaToDelta( angle, numPoint, dx, dy, xOut, yOut );
        size_t i;
        for (i = 0; i < numPoint; ++ i) {
            xOut[i] += cx;
            yOut[i] += cy;
        }
    }
    static inline void rotateCalculation( double cx, double cy,
        double angle,
        size_t numPoint,
        const double x[], const double y[], double xOut[], double yOut[]
    ) {
        size_t i;
        double *dx = new double[numPoint];
        double *dy = new double[numPoint];
        for (i = 0; i < numPoint; ++ i) {
            dx[i] = x[i] - cx;
            dy[i] = y[i] - cy;
        }
        rotateDelta( cx, cy, angle, numPoint, dx, dy, xOut, yOut );
        delete [] dx;
        delete [] dy;
    }
    static inline void rotateCalculationToDelta( double cx, double cy,
        double angle,
        size_t numPoint,
        const double x[], const double y[], double dxOut[], double dyOut[]
    ) {
        double *dx = new double[numPoint];
        double *dy = new double[numPoint];
        size_t i;
        for (i = 0; i < numPoint; ++ i) {
            dx[i] = x[i] - cx;
            dy[i] = y[i] - cy;
        }
        rotateDeltaToDelta( angle, numPoint, dx, dy, dxOut, dyOut );
        delete [] dx;
        delete [] dy;
    }

    static int reverseProjectCoords(
        const double targetOrig[10],
        const double sourceOrig[10], 
        size_t       numPoint,
        const double targetX[],
        const double targetY[],
        double       sourceX[],
        double       souceY[]
    );
    static void calculateProjectionFromSamplePosition(
        const double orig[10],
        double x, double y, double z,
        double &vert, double &horz,
        bool return_micron = false
    );

    static void translateProjectionCoords(
        const double sourceOrig[10],
        const double targetOrig[10],
        size_t numPoint,
        const double sourceX[],
        const double sourceY[],
        double targetX[],
        double targetY[]
    );

    bool   m_ready;
    double m_uCenterX;
    double m_uCenterY;
    double m_oCenterX;
    double m_oCenterY;
    double m_oAngle;
    double m_displayWidthPixel;
    double m_displayHeightPixel;
    double m_originOrig[10];
    double m_displayOrig[10];

    vector<double> m_inputXVector;
    vector<double> m_inputYVector;

    vector<double> m_userXVector;
    vector<double> m_userYVector;

    vector<double> m_targetXVector;
    vector<double> m_targetYVector;
};
#endif
