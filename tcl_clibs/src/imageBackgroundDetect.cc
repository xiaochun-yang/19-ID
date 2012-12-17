#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <tcl.h>
#include <tk.h>
#include <jpeglib.h>
#include <jerror.h>
//#include <jconfig.h>
//#include <jmorecfg.h>

#include <setjmp.h>

#include "imageBackgroundDetect.h"


static const double MIN_SELF_THRESHOLD = 6.0;
static const double MAX_SELF_THRESHOLD = 17.0;
static const double MIN_DIFF_THRESHOLD = 6.0;
static const double MAX_DIFF_THRESHOLD = 15.0;

extern void imageSubAverage(
    Tk_PhotoImageBlock *pDstBlock,
    const Tk_PhotoImageBlock *pSrcBlock,
    int xSub,
    int ySub
    );

static char normal_result[] = "normal OK";

static char errMsgFromFunction[1024] = {0};

typedef struct AttributeStatistics {
double average;
double max;
double min;
} Statistics_t;

typedef struct RGBStatistics {
    Statistics_t red;
    Statistics_t green;
    Statistics_t blue;
} RGBStatistics_t;
typedef struct LABStatistics {
    Statistics_t l;
    Statistics_t a;
    Statistics_t b;
    double       maxDE94;
    double       maxDL;
    size_t       numBad;
    double       selfDE94;
    double       selfDL;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
    int           row;
    int           col;
    double maxL;
    double maxA;
    double maxB;
    bool   candidate;
} LABStatistics_t;
static double diffThreshold = MIN_DIFF_THRESHOLD;
static double selfThreshold = MIN_SELF_THRESHOLD;

//http://en.wikipedia.org/wiki/SRGB
static void RGBtoXYZ( unsigned char r, unsigned char g, unsigned char b,
double &x, double &y, double &z ) {
    const double aa = 0.055;
    const double tt = 0.04045;

    double rr = r / 255.0;
    double gg = g / 255.0;
    double bb = b / 255.0;

    if (rr > tt) {
        rr = pow( (rr + aa) / (1.0 + aa), 2.4 );
    } else {
        rr = rr / 12.92;
    }
    if (gg > tt) {
        gg = pow( (gg + aa) / (1.0 + aa), 2.4 );
    } else {
        gg = gg / 12.92;
    }
    if (bb > tt) {
        bb = pow( (bb + aa) / (1.0 + aa), 2.4 );
    } else {
        bb = bb / 12.92;
    }

    x = 0.412453 * rr + 0.357580 * gg + 0.180423 * bb;
    y = 0.212671 * rr + 0.715160 * gg + 0.072169 * bb;
    z = 0.019334 * rr + 0.119193 * gg + 0.950227 * bb;
}

//http://en.wikipedia.org/wiki/Lab_color_space
static inline double fHelp( double t ) {
    const double const1 = 6.0 * 6.0 * 6.0 / (29.0 * 29.0 * 29.0);
    const double const2 = 29.0 * 29.0 / (6.0 * 6.0 * 3.0);
    const double const3 = 4.0 / 29.0;

    if (t > const1) {
        return cbrt( t );
    } else {
        return const2 * t + const3;
    }
}
// L [0,100], A [-128, 127], B [-128, 127];
static void XYZtoLAB ( double x, double y, double z,
double &l, double &a, double &b ) {
    //D65 white point
    double xn = x / 0.950455;
    double yn = y / 1.0;
    double zn = z / 1.088753;

    l = 116.0 * fHelp( yn ) - 16.0;
    a = 500.0 * (fHelp( xn ) - fHelp( yn ));
    b = 200.0 * (fHelp( yn ) - fHelp( zn ));
}

static size_t debugRGB2LAB = 100;
static void RGBtoLAB( unsigned char red, unsigned char green, unsigned char blue,
double &l, double &a, double &b ) {
    double x;
    double y;
    double z;

    RGBtoXYZ( red, green, blue, x, y, z );
    XYZtoLAB( x, y, z, l, a, b );

    if (debugRGB2LAB > 0) {
        --debugRGB2LAB;
        printf( "rgb %hhu %hhu %hhu xyz: %lf %lf %lf lab: %lf %lf %lf\n",
        red, green, blue, x, y, z, l, a, b );
    }
}

//http://en.wikipedia.org/wiki/Color_difference
static double dE94FromLAB( double l1, double a1, double b1,
double l2, double a2, double b2 ) {
    // we use textile
    //const double Kl = 2.0;
    //const double K1 = 0.048;
    //const double K2 = 0.014;
    // we use graphic arts
    // this one L has more weight.
    const double Kl = 1.0;
    const double K1 = 0.045;
    const double K2 = 0.015;

    double c1 = sqrt( a1 * a1 + b1 * b1 );
    double c2 = sqrt( a2 * a2 + b2 * b2 );

    double dA = a1 - a2;
    double dB = b1 - b2;
    double dL = l1 - l2;
    double dC = c1 - c2;
    
    double dE76 = sqrt( dA * dA + dB * dB + dL * dL );
    double dH2 = dA * dA + dB * dB - dC * dC;
    double dH = (dH2 >= 0)? sqrt( dH2 ):0;

    double item1 = dL / Kl;
    double item2 = dC / (1.0 + K1 * c1);
    double item3 = dH / (1.0 + K2 * c2 );

    return sqrt( item1 * item1 + item2 * item2 + item3 * item3 );
}


typedef struct cielabPixel {
    double l;
    double a;
    double b;
} cielabPixel_t;

size_t        labImageBufferSize = 1024;
cielabPixel_t *pLabImage = new cielabPixel_t[1024];

LABStatistics_t baseNode;  
bool            baseNodeDefined(false);

static double calculateSelfThreshold( double base ) {
    double result = ceil( base * 1.6 );

    if (result < MIN_SELF_THRESHOLD) {
        result = MIN_SELF_THRESHOLD;
    }
    if (result > MAX_SELF_THRESHOLD) {
        result = MAX_SELF_THRESHOLD;
    }
    return result;
}
static double calculateDiffThreshold( double base, double min ) {
    double result = base * 1.25;
    if (result < min) {
        result = min;
    }
    result = ceil( result );

    if (result < MIN_DIFF_THRESHOLD) {
        result = MIN_DIFF_THRESHOLD;
    }
    if (result > MAX_DIFF_THRESHOLD) {
        result = MAX_DIFF_THRESHOLD;
    }
    return result;
}

static void setupThreshold( ) {
    selfThreshold = calculateSelfThreshold( baseNode.selfDL );
    //very much like:
    //diffThreshold = baseNode.selfDL * 1.5;
    diffThreshold = calculateDiffThreshold( baseNode.selfDL,
    baseNode.selfDL + baseNode.maxDL );
}

//ending column or row not included
static int fillLABImage(
    const Tk_PhotoImageBlock *pSrcBlock,
    int   rowStart,
    int   columnStart,
    int   numRow,
    int   numColumn,
    RGBStatistics_t &rgbResult,
    LABStatistics_t &labResult   
 ) {
    int sizeNeeded = numRow * numColumn;
    if (sizeNeeded > labImageBufferSize) {
        if (pLabImage) {
            delete [] pLabImage;
        }
        while (labImageBufferSize < sizeNeeded) {
            labImageBufferSize *= 2;
        }
        pLabImage = new cielabPixel_t[labImageBufferSize];
        if (pLabImage == NULL) {
            strcpy( errMsgFromFunction, "out of memory" );
            printf( "memory ran out\n" );
            return 0;
        }
    }

    memset( &rgbResult, 0, sizeof(RGBStatistics_t) );
    memset( &labResult, 0, sizeof(LABStatistics_t) );

    rgbResult.red.min = 9e99;
    rgbResult.green.min = 9e99;
    rgbResult.blue.min = 9e99;
    labResult.l.min = 9e99;
    labResult.a.min = 9e99;
    labResult.b.min = 9e99;
    labResult.l.max = -9e99;
    labResult.a.max = -9e99;
    labResult.b.max = -9e99;

    int rowEnd = rowStart + numRow;
    int columnEnd = columnStart + numColumn;

    //safety check
    if (rowStart < 0) {
        printf( "rowStart=%d < 0\n", rowStart );
        rowStart = 0;
    }
    if (rowEnd > pSrcBlock->height) {
        printf( "rowEnd=%d > height=%d\n", rowEnd, pSrcBlock->height );
        rowEnd = pSrcBlock->height;
    }
    if (columnStart < 0) {
        printf( "colStart =%d < 0\n", columnStart );
        columnStart = 0;
    }
    if (columnEnd > pSrcBlock->width) {
        printf( "colEnd =%d > width=%d\n", columnEnd, pSrcBlock->width );
        columnEnd = pSrcBlock->width;
    }

    if (pSrcBlock->pixelSize < 3) {
        strcpy( errMsgFromFunction, "format not supported" );
        printf( "image format not supported\n" );
        return 0;
    }
    if (rowStart >= rowEnd || columnStart >= columnEnd) {
        strcpy( errMsgFromFunction, "bad image size" );
        printf( "size 0 image\n" );
        return 0;
    }

    size_t offset = 0;
    for (int row = rowStart; row < rowEnd; ++row) {
        for (int col = columnStart; col < columnEnd; ++col, ++offset) {
            unsigned char *pSrc = pSrcBlock->pixelPtr
            + row * pSrcBlock->pitch
            + col * pSrcBlock->pixelSize;
            unsigned char red   = pSrc[pSrcBlock->offset[0]];
            unsigned char green = pSrc[pSrcBlock->offset[1]];
            unsigned char blue  = pSrc[pSrcBlock->offset[2]];
            double l = 0;
            double a = 0;
            double b = 0;
            RGBtoLAB( red, green, blue, l, a, b );
            pLabImage[offset].l = l;
            pLabImage[offset].a = a;
            pLabImage[offset].b = b;
            if (baseNodeDefined) {
                double dE94  = dE94FromLAB( baseNode.l.average, baseNode.a.average, baseNode.b.average, l, a, b );
                if (dE94 > labResult.maxDE94) {
                    labResult.maxDE94 = dE94;
                    labResult.red = red;
                    labResult.green = green;
                    labResult.blue = blue;
                    labResult.maxL = l;
                    labResult.maxA = a;
                    labResult.maxB = b;
                    labResult.row = row - rowStart;
                    labResult.col = col - columnStart;
                }
                double dL = fabs( l - baseNode.l.average );
                if (dL > diffThreshold) {
                    ++(labResult.numBad);
                }
                if (dL > labResult.maxDL) {
                    labResult.maxDL = dL;
                }
            }

            //statistics
            if (red > rgbResult.red.max) {
                rgbResult.red.max = red;
            }
            if (red < rgbResult.red.min) {
                rgbResult.red.min = red;
            }
            if (green > rgbResult.green.max) {
                rgbResult.green.max = green;
            }
            if (green < rgbResult.green.min) {
                rgbResult.green.min = green;
            }
            if (blue > rgbResult.blue.max) {
                rgbResult.blue.max = blue;
            }
            if (blue < rgbResult.blue.min) {
                rgbResult.blue.min = blue;
            }
            if (l > labResult.l.max) {
                labResult.l.max = l;
            }
            if (l < labResult.l.min) {
                labResult.l.min = l;
            }
            if (a > labResult.a.max) {
                labResult.a.max = a;
            }
            if (a < labResult.a.min) {
                labResult.a.min = a;
            }
            if (b > labResult.b.max) {
                labResult.b.max = b;
            }
            if (b < labResult.b.min) {
                labResult.b.min = b;
            }
            //
            rgbResult.red.average += red;
            rgbResult.green.average += green;
            rgbResult.blue.average += blue;
            labResult.l.average += l;
            labResult.a.average += a;
            labResult.b.average += b;
        }
    }
    rgbResult.red.average /= offset;
    rgbResult.green.average /= offset;
    rgbResult.blue.average /= offset;
    labResult.l.average /= offset;
    labResult.a.average /= offset;
    labResult.b.average /= offset;

    labResult.selfDL    = fabs( labResult.l.max - labResult.l.min );
    labResult.selfDE94  = dE94FromLAB(
    labResult.l.min, labResult.a.min, labResult.b.min,
    labResult.l.max, labResult.a.max, labResult.b.max );

    return 1;
}

static jmp_buf setjmp_buffer;
static void my_error_exit( j_common_ptr cinfo ) {
    printf( "ERROR decompressing jpeg image\n" );
    (*cinfo->err->output_message)( cinfo );
    longjmp( setjmp_buffer, 1 );
}

static int readJpeg( const char *path, Tk_PhotoImageBlock *pDstBlock ) {
    struct jpeg_decompress_struct cinfo;
    struct jpeg_error_mgr jerr;
    JSAMPROW pRows[1];

    cinfo.client_data = &setjmp_buffer;
    cinfo.err = jpeg_std_error( &jerr );
    jerr.error_exit = my_error_exit;
    if (setjmp( setjmp_buffer ) ) {
        jpeg_destroy_decompress( &cinfo );
        printf( "readJpeg failed\n" );
        return 0;
    }

    jpeg_create_decompress( &cinfo );

    FILE *infile = fopen( path, "rb" );
    if (infile == NULL) {
        fprintf( stderr, "cannot open %s\n", path );
        return 0;
    }
    jpeg_stdio_src( &cinfo, infile );

    //header
    jpeg_read_header( &cinfo, TRUE );

    jpeg_start_decompress( &cinfo );
    pDstBlock->pixelPtr = new unsigned char[cinfo.output_width * cinfo.output_height * cinfo.num_components];
    pDstBlock->width = cinfo.output_width;
    pDstBlock->height = cinfo.output_height;
    pDstBlock->pixelSize = cinfo.num_components;
    pDstBlock->pitch = cinfo.output_width * cinfo.num_components;
    pDstBlock->offset[0] = 0;
    pDstBlock->offset[1] = 1;
    pDstBlock->offset[2] = 2;
    pDstBlock->offset[3] = 0;

    pRows[0] = pDstBlock->pixelPtr;
    
    while (cinfo.output_scanline < cinfo.output_height) {
        jpeg_read_scanlines( &cinfo, pRows, 1 );
        pRows[0] += pDstBlock->pitch;
    }
    jpeg_finish_decompress( &cinfo );
    jpeg_destroy_decompress( &cinfo );
    fclose( infile );

    return 1;
}

static int takeAverage( Tk_PhotoImageBlock *pBlock, int xSub, int ySub ) {
    Tk_PhotoImageBlock dstBlock;

    dstBlock.width     = pBlock->width / xSub;
    dstBlock.height    = pBlock->height / ySub;
    dstBlock.pixelSize = pBlock->pixelSize;
    if (dstBlock.width < 1 || dstBlock.height < 1) {
        strcpy( errMsgFromFunction, "destination image too small" );
        return TCL_ERROR;
    }

    dstBlock.pitch = dstBlock.width * dstBlock.pixelSize;
    memcpy( dstBlock.offset, pBlock->offset, sizeof(pBlock->offset) );
    dstBlock.pixelPtr =
    new unsigned char[dstBlock.width * dstBlock.height * dstBlock.pixelSize];
    if (dstBlock.pixelPtr == NULL) {
        strcpy( errMsgFromFunction, "out of memory" );
        return TCL_ERROR;
    }
    imageSubAverage( &dstBlock, pBlock, xSub, ySub );

    delete pBlock->pixelPtr;
    *pBlock = dstBlock;

    return TCL_OK;
}

static LABStatistics_t *pInfoTable = NULL;
static size_t          resultBufferSize = 0;
static int initResultTable( size_t numNeeded ) {
    if (numNeeded > resultBufferSize) {
        if (resultBufferSize == 0) {
            resultBufferSize = 1024;
        }
        while (numNeeded > resultBufferSize) {
            resultBufferSize *= 2;
        }
        if (pInfoTable) {
            delete [] pInfoTable;
        }
        pInfoTable = new LABStatistics_t[resultBufferSize];
        if (pInfoTable == NULL) {
            return 0;
        }
    }
    memset( pInfoTable, 0, resultBufferSize * sizeof(pInfoTable[0]) );
    return 1;
}

// Here we use Tk_PhotoImageBlock srcBlock to hold the raw image.
// Just for in case we need to support tk image, not jpeg.
int jpegBackgroundDetect( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 9)
    {
        Tcl_WrongNumArgs( interp, 1, objv,
        "srcImg grid_cx grid_cy grid_w grid_h grid_col grid_row select_col select_row" );
        return TCL_ERROR;
    }

    char* srcName = Tcl_GetString( objv[1] );
    double cx = 0.5;
    double cy = 0.5;
    double w  = 0.2;
    double h  = 0.2;
    int    numCol = 5;
    int    numRow = 5;
    int    baseCol = -1;
    int    baseRow = -1;

    if (Tcl_GetDoubleFromObj( interp, objv[2], &cx ) != TCL_OK) {
        Tcl_SetResult( interp, "grid center x is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, objv[3], &cy ) != TCL_OK) {
        Tcl_SetResult( interp, "grid center y is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, objv[4], &w ) != TCL_OK) {
        Tcl_SetResult( interp, "grid width is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetDoubleFromObj( interp, objv[5], &h ) != TCL_OK) {
        Tcl_SetResult( interp, "grid height is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetIntFromObj( interp, objv[6], &numCol ) != TCL_OK) {
        Tcl_SetResult( interp, "grid column is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetIntFromObj( interp, objv[7], &numRow ) != TCL_OK) {
        Tcl_SetResult( interp, "grid row is wrong", TCL_STATIC );
        return TCL_ERROR;
    }

    if (Tcl_GetIntFromObj( interp, objv[8], &baseCol ) != TCL_OK) {
        Tcl_SetResult( interp, "base column is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (Tcl_GetIntFromObj( interp, objv[9], &baseRow ) != TCL_OK) {
        Tcl_SetResult( interp, "base row is wrong", TCL_STATIC );
        return TCL_ERROR;
    }
    if (w <= 0.0 || h <= 0.0 || numRow < 1 || numCol < 1) {
        Tcl_SetResult( interp, "bad grid info", TCL_STATIC );
        return TCL_ERROR;
    }

    if (baseRow == -1 && baseCol == -1) {
        baseRow = 0;
        baseCol = numCol - 1;
    }

    printf( "JPEG file: %s\n", srcName );

    if (!initResultTable( numRow * numCol )) {
        Tcl_SetResult( interp,
        "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
    
    Tk_PhotoImageBlock srcBlock;

    if (!readJpeg( srcName, &srcBlock )) {
        Tcl_SetResult( interp,
        "read jpeg file failed", TCL_STATIC );
        return TCL_ERROR;
    }
    printf( "DEBUG: image width=%d height=%d pitch=%d\n",
    srcBlock.width, srcBlock.height, srcBlock.pitch );
    /*
    if (takeAverage( &srcBlock, 2, 2 ) != TCL_OK) {
        delete [] srcBlock.pixelPtr;
        Tcl_SetResult( interp, errMsgFromFunction, TCL_STATIC );
        return TCL_ERROR;
    }
    */

    if (srcBlock.pitch == srcBlock.width) {
        delete [] srcBlock.pixelPtr;
        Tcl_SetResult( interp,
        "image format rrrrr ggggg bbbbb not supported", TCL_STATIC );
        return TCL_ERROR;
    }

    printf( "DEBUG: after average image width=%d height=%d pitch=%d\n",
    srcBlock.width, srcBlock.height, srcBlock.pitch );

    if (srcBlock.width < 2 || srcBlock.height < 2) {
        delete [] srcBlock.pixelPtr;
        Tcl_SetResult( interp, "image too small", TCL_STATIC );
        return TCL_ERROR;
    }

    double cellWidth  = w / numCol;
    double cellHeight = h / numRow;
    double x0 = cx - 0.5 * w;
    double y0 = cy - 0.5 * h;

    int    iWidth  = int(srcBlock.width  * cellWidth);
    int    iHeight = int(srcBlock.height * cellHeight);
    RGBStatistics_t rgbResultBase;
    if (baseRow >= 0 && baseCol >= 0) {
        int iRStart = int(srcBlock.height * (y0 + baseRow * cellHeight));
        int iCStart = int(srcBlock.width  * (x0 + baseCol * cellWidth));
        if (!fillLABImage( &srcBlock, iRStart, iCStart, iHeight, iWidth,
        rgbResultBase, baseNode )) {
            Tcl_SetResult( interp, errMsgFromFunction, TCL_STATIC );
            return TCL_ERROR;
        }

        double diff1 = fabs( baseNode.l.average - baseNode.l.min );
        double diff2 = fabs( baseNode.l.average - baseNode.l.max );
        baseNode.maxDL = (diff1 > diff2) ? diff1 : diff2;
        printf( "basenode maxDL=%lf\n", baseNode.maxDL );

        setupThreshold( );
        baseNodeDefined = true;

        printf( "base diffThreshold=%lf selfThreshold=%lf\n",
        diffThreshold, selfThreshold );
    }

    RGBStatistics_t rgbResult;
    LABStatistics_t labResult;

    size_t numPixelPerNode = iWidth * iHeight;

    double maxSelfDL = 0;
    double minSelfDL = 9e9;

    for (int row = 0; row < numRow; ++row) {
        int iRStart = int(srcBlock.height * (y0 + row * cellHeight));
        for (int col = 0; col < numCol; ++col) {
            int iCStart = int(srcBlock.width *(x0 + col * cellWidth));
            fillLABImage( &srcBlock, iRStart, iCStart, iHeight, iWidth,
            rgbResult, labResult );

            double myL, myA, myB;
            unsigned char myRed = (unsigned char)(rgbResult.red.average);
            unsigned char myGreen = (unsigned char)(rgbResult.green.average);
            unsigned char myBlue = (unsigned char)(rgbResult.blue.average);

            RGBtoLAB( myRed, myGreen, myBlue, myL, myA, myB );

            double badPercent = 100.0 * labResult.numBad / numPixelPerNode;

            if (labResult.selfDL > maxSelfDL) {
                maxSelfDL = labResult.selfDL;
            }
            if (labResult.selfDL < minSelfDL) {
                minSelfDL = labResult.selfDL;
            }

            size_t offset = row * numCol + col;

            pInfoTable[offset] = labResult;
            if (labResult.maxDL <= diffThreshold)  {
                printf( "D" );
            } else {
                printf( " " );
            }
            if (labResult.selfDL <= selfThreshold) {
                printf( "S" );
            } else {
                printf( " " );
            }

            printf( "[%2d,%2d]:dL=%5.1lf selfDL=%5.1lf dE=%6.1lf selfdE=%6.1lf bad=%5.1lf%%\n",
            row, col,
            labResult.maxDL, 
            labResult.selfDL,
            labResult.maxDE94,
            labResult.selfDE94,
            badPercent
            );
        }
    }
    double minPossible = 9e99;
    int nRow = -1;
    int nCol = -1;
    for (int row = 0; row < numRow; ++row) {
        for (int col = 0; col < numCol; ++col) {
            size_t offset = row * numCol + col;
            if (pInfoTable[offset].selfDL <= selfThreshold
            &&  pInfoTable[offset].maxDL  <= MIN_DIFF_THRESHOLD)  {
                if (pInfoTable[offset].selfDL < minPossible) {
                    minPossible = pInfoTable[offset].selfDL;
                    nRow = row;
                    nCol = col;
                }
            }
        }
    }
    minPossible = calculateSelfThreshold( minPossible );
    if (nRow >= 0
    && (nRow != baseRow || nCol != baseCol)
    && selfThreshold > MIN_SELF_THRESHOLD
    && minPossible < MAX_SELF_THRESHOLD
    ) {
        printf( "best base at [%d, %d] selfDL=%lf\n", nRow, nCol, minPossible );
        printf( "use the best base to redo it\n" );
        printf( "self threshold reduced from %lf to %lf\n",
        selfThreshold, minPossible );
        size_t offset = nRow * numCol + nCol;
        baseNode = pInfoTable[offset];
        setupThreshold( );
    }

    printf( "diffThreshold=%lf selfThreshold=%lf\n", diffThreshold, selfThreshold );
    for (int row = 0; row < numRow; ++row) {
        for (int col = 0; col < numCol; ++col) {
            size_t offset = row * numCol + col;
            if (pInfoTable[offset].selfDL <= selfThreshold
            &&  pInfoTable[offset].maxDL  <= diffThreshold)  {
                pInfoTable[offset].candidate = true;
                if (pInfoTable[offset].selfDL < minPossible) {
                    minPossible = pInfoTable[offset].selfDL;
                    nRow = row;
                    nCol = col;
                }
            } else {
                pInfoTable[offset].candidate = false;
            }
        }
    }
    printf( "=================================\n" );
    for (int row = 0; row < numRow; ++row) {
        char line[1024] = {0}; //may not big enough
        for (int col = 0; col < numCol; ++col) {
            size_t offset = row * numCol + col;
            if (pInfoTable[offset].candidate) {
                line[col]='M';
            } else {
                line[col]=' ';
            }
        }
        printf( "%s\n", line );
    }
    printf( "=================================\n" );

    printf( "dL base=%lf min=%lf max=%lf\n", baseNode.selfDL, minSelfDL, maxSelfDL );
    if (baseNode.selfDL * 2 > maxSelfDL) {
        delete [] srcBlock.pixelPtr;

        if (baseNode.selfDL <= 2 * minSelfDL) {
            Tcl_SetResult( interp,
            "all nodes are almost the same", TCL_STATIC );
        } else {
            Tcl_SetResult( interp,
            "template node too noisy", TCL_STATIC );
        }
        return TCL_ERROR;
    }

    Tcl_Obj *pResult = Tcl_NewListObj( 0, NULL );
    Tcl_ListObjAppendElement( interp, pResult, Tcl_NewIntObj(baseRow) );
    Tcl_ListObjAppendElement( interp, pResult, Tcl_NewIntObj(baseCol) );
    /*
    for (int row = 0; row < numRow; ++row) {
        int startCol = 0;
        for (; startCol < numCol; ++startCol) {
            size_t offset = row * numCol + startCol;
            if (!pInfoTable[offset].candidate) {
                break;
            }
        }
        int endCol = numCol - 1;
        for (; endCol > startCol; --endCol) {
            size_t offset = row * numCol + endCol;
            if (!pInfoTable[offset].candidate) {
                break;
            }

        }
        if (startCol + 1 < endCol) {
            for (int col = startCol + 1; col < endCol; ++col) {
                size_t offset = row * numCol + col;
                if (pInfoTable[offset].candidate) {
                    pInfoTable[offset].candidate = false;
                    printf( "turn off [%d %d] by row\n", row, col );
                }
            }
        }
    }
    for (int col = 0; col < numCol; ++col) {
        int startRow = 0;
        for (; startRow < numRow; ++startRow) {
            size_t offset = startRow * numCol + col;
            if (!pInfoTable[offset].candidate) {
                break;
            }
        }
        int endRow = numRow - 1;
        for (; endRow > startRow; --endRow) {
            size_t offset = endRow * numCol + col;
            if (!pInfoTable[offset].candidate) {
                break;
            }
        }
        if (startRow + 1 < endRow) {
            for (int row = startRow + 1; row < endRow; ++row) {
                size_t offset = row * numCol + col;
                if (pInfoTable[offset].candidate) {
                    pInfoTable[offset].candidate = false;
                    printf( "turn off [%d %d] by col\n", row, col );
                }
            }
        }
    }

    printf( "=======final===============\n" );
    */

    int numMasked = 0;
    for (int row = 0; row < numRow; ++row) {
        char line[1024] = {0}; //may not big enough
        for (int col = 0; col < numCol; ++col) {
            size_t offset = row * numCol + col;
            if (pInfoTable[offset].candidate) {
                Tcl_ListObjAppendElement( interp, pResult, Tcl_NewIntObj(row) );
                Tcl_ListObjAppendElement( interp, pResult, Tcl_NewIntObj(col) );
                line[col]='M';
                ++numMasked;
            } else {
                line[col]=' ';
            }
        }
        //printf( "%s\n", line );
    }
    //printf( "=================================\n" );

    delete [] srcBlock.pixelPtr;
    Tcl_SetObjResult( interp, pResult );
    return TCL_OK;
}

