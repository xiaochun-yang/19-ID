#include <stdlib.h>
#include <string.h>
#include <tcl.h>
#include <tk.h>

extern "C" {
int imageScaleBilinear( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

int imageResizeBilinear( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

//like subsampling but take average of the block.
int imageSubSampleAvg( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );

int imageDownsizeAreaSample( ClientData cdata, Tcl_Interp* interp,
int objc, Tcl_Obj *CONST objv[] );
};

static char normal_result[] = "normal OK";

typedef struct intAndFraction {
    int   integer0;
    float fraction;
} intAndFraction_t;

static size_t lenStaticRowIFInfo = 480;
static size_t lenStaticColIFInfo = 704;
static intAndFraction_t *staticRowIFInfo =
new intAndFraction_t[lenStaticRowIFInfo];

static intAndFraction_t *staticColIFInfo =
new intAndFraction_t[lenStaticColIFInfo];

static char errMsgFromFunction[1024] = {0};

//local functions
static int bilinearInterpolation( 
    Tk_PhotoImageBlock *pDstBlock,
    const Tk_PhotoImageBlock *pSrcBlock,
    bool flipHorz = false,
    bool flipVert = false
) {
    int row;
    int col;

#ifdef USE_DYNAMIC_MEM
    intAndFraction_t *rowInfo = new intAndFraction_t[pDstBlock->height];
    intAndFraction_t *colInfo = new intAndFraction_t[pDstBlock->width];
#else
    if (pDstBlock->height > lenStaticRowIFInfo ) {
        delete [] staticRowIFInfo;
        lenStaticRowIFInfo = 0;
        staticRowIFInfo = new intAndFraction_t[pDstBlock->height];
        if (staticRowIFInfo == NULL) {
            printf( "run out of memory\n" );
            strcpy( errMsgFromFunction, "run out of memory" );
            return TCL_ERROR;
        }
        lenStaticRowIFInfo = pDstBlock->height;
        printf( "new length for RowIFInfo %lu\n", lenStaticRowIFInfo );
    }
    if (pDstBlock->width > lenStaticColIFInfo ) {
        delete [] staticColIFInfo;
        lenStaticColIFInfo = 0;
        staticColIFInfo = new intAndFraction_t[pDstBlock->width];
        if (staticColIFInfo == NULL) {
            printf( "run out of memory\n" );
            strcpy( errMsgFromFunction, "run out of memory" );
            return TCL_ERROR;
        }
        lenStaticColIFInfo = pDstBlock->width;
        printf( "new length for ColIFInfo %lu\n", lenStaticColIFInfo );
    }
    intAndFraction_t *rowInfo = staticRowIFInfo;
    intAndFraction_t *colInfo = staticColIFInfo;

    memset( staticRowIFInfo, 0,
    lenStaticRowIFInfo * sizeof(staticRowIFInfo[0]) );

    memset( staticColIFInfo, 0,
    lenStaticColIFInfo * sizeof(staticColIFInfo[0]) );
#endif

    //fill the list
    // the 0.5f is from center of pixel.
    //===============================
    // for borders at scale > 1
    // we just duplicate the source border.
    //
    float maxX = pSrcBlock->width - 1;
    int index;
    for (col = 0; col < pDstBlock->width; ++col) {
        if (flipHorz) {
            index = pDstBlock->width - 1 - col;
        } else {
            index = col;
        }
        float x = (0.5f + index) * pSrcBlock->width / pDstBlock->width - 0.5f;

        if (x < 0) {
            colInfo[col].integer0 = 0;
            colInfo[col].fraction = 0;
        } else if (x >= maxX) {
            colInfo[col].integer0 = int(maxX) - 1;
            colInfo[col].fraction = 1.0f;
        } else {
            colInfo[col].integer0 = int(x);
            colInfo[col].fraction = x - colInfo[col].integer0;
        }

    }
    float maxY = pSrcBlock->height - 1;
    for (row = 0; row < pDstBlock->height; ++row) {
        if (flipVert) {
            index = pDstBlock->height - 1 - row;
        } else {
            index = row;
        }
        float y = (0.5f + index) * pSrcBlock->height / pDstBlock->height - 0.5f;

        if (y < 0) {
            rowInfo[row].integer0 = 0;
            rowInfo[row].fraction = 0.0f;
        } else if (y > maxY) {
            rowInfo[row].integer0 = int(maxY) - 1;
            rowInfo[row].fraction = 1.0f;
        } else {
            rowInfo[row].integer0 = int(y);
            rowInfo[row].fraction = y - int(y);
        }
    }

    for (row = 0; row < pDstBlock->height; ++row) {
        for (col = 0; col < pDstBlock->width; ++col) {
            unsigned char * pDst = pDstBlock->pixelPtr +
            row * pDstBlock->pitch + col * pDstBlock->pixelSize;

            int c0 = colInfo[col].integer0;
            int r0 = rowInfo[row].integer0;
            float x = colInfo[col].fraction;
            float y = rowInfo[row].fraction;

            unsigned char *pSrc00 = pSrcBlock->pixelPtr +
            r0 * pSrcBlock->pitch + c0 * pSrcBlock->pixelSize;

            for (int chan = 0; chan < pDstBlock->pixelSize; ++ chan) {
                const unsigned char *pS = pSrc00 + pDstBlock->offset[chan];
                unsigned char *pD = pDst + pDstBlock->offset[chan];

                unsigned char f00 = pS[0];
                unsigned char f10 = pS[pSrcBlock->pixelSize];
                unsigned char f01 = pS[pSrcBlock->pitch];
                unsigned char f11 = pS[pSrcBlock->pitch + pSrcBlock->pixelSize];

                float brightness =
                (f10 - f00) * x +
                (f01 - f00) * y +
                (f11 + f00 - f01 - f10) * x * y +
                f00;

                if (brightness < 0) {
                    printf( "pixel %f <0 at %d %d %d\n", brightness, row, col, chan );
                    printf( "r0=%d c0=%d y=%f x=%f\n", r0, c0, y, x );
                    printf( "f00=%hu f10=%hu f01 =%hu f11=%hu\n", f00, f10, f01, f11 );
                    brightness = 0;
                } else if (brightness > 255) {
                    printf( "pixel %f >255 at %d %d %d\n", brightness, row, col, chan );
                    printf( "r0=%d c0=%d y=%f x=%f\n", r0, c0, y, x );
                    printf( "f00=%hu f10=%hu f01 =%hu f11=%hu\n", f00, f10, f01, f11 );
                    brightness = 255;
                }

                *pD = (unsigned char)brightness;

            }//channel (color)
        }//column
    }//row

    //printf( "done bilinear\n" );

#ifdef USE_DYNAMIC_MEM
    delete [] rowInfo;
    delete [] colInfo;
#endif
    return TCL_OK;
}

//calculate distribution from every source pixel
//good for dramatic downsize
typedef struct weightInfo {
    int dstIndex;
    float weight;
    // if weight < 1, the (1-weight) is for next destination pixel.
} weightInfo_t;

static size_t lenStaticRowWInfo = 480;
static size_t lenStaticColWInfo = 704;
static size_t lenStaticFloatImage = 704 * 480 * 4;
static size_t lenStaticUCharImage = 704 * 480 * 4;

static weightInfo_t *staticRowWInfo =
new weightInfo_t[lenStaticRowWInfo];

static weightInfo_t *staticColWInfo =
new weightInfo_t[lenStaticColWInfo];

static float *staticFloatImage =
new float[lenStaticFloatImage];

static unsigned char *staticUCharImage =
new unsigned char[lenStaticUCharImage];

//caller make sure downsize only
static int downSizeDistribution( 
    Tk_PhotoImageBlock *pDstBlock,
    const Tk_PhotoImageBlock *pSrcBlock,
    int reserveWhite
) {
    int row;
    int col;

    //for reserverWhite
    const int numChanToCheck =
    (pSrcBlock->pixelSize <= 3) ? pSrcBlock->pixelSize : 3;

    const unsigned long whiteThreshold =
    (unsigned long)(numChanToCheck * 255 * 255 * 0.95);

    //printf( "dst: w=%d h=%d, offset=%d %d %d %d\n", pDstBlock->width,
    //pDstBlock->height,
    //pDstBlock->offset[0],
    //pDstBlock->offset[1],
    //pDstBlock->offset[2],
    //pDstBlock->offset[3] );

#ifdef USE_DYNAMIC_MEM
    weightInfo_t *rowInfo = new weightInfo_t[pSrcBlock->height];
    weightInfo_t *colInfo = new weightInfo_t[pSrcBlock->width];
#else
    if (pSrcBlock->height > lenStaticRowWInfo) {
        lenStaticRowWInfo = 0;
        delete [] staticRowWInfo;
        staticRowWInfo = new weightInfo_t[pSrcBlock->height];
        if (staticRowWInfo == NULL) {
            printf( "run out of memory\n" );
            strcpy( errMsgFromFunction, "run out of memory" );
            return TCL_ERROR;
        }
        lenStaticRowWInfo = pSrcBlock->height;
    }
    if (pSrcBlock->width > lenStaticColWInfo) {
        lenStaticColWInfo = 0;
        delete [] staticColWInfo;
        staticColWInfo = new weightInfo_t[pSrcBlock->width];
        if (staticColWInfo == NULL) {
            printf( "run out of memory\n" );
            strcpy( errMsgFromFunction, "run out of memory" );
            return TCL_ERROR;
        }
        lenStaticColWInfo = pSrcBlock->width;
    }
    weightInfo_t *rowInfo = staticRowWInfo;
    weightInfo_t *colInfo = staticColWInfo;

    memset( staticRowWInfo, 0, lenStaticRowWInfo * sizeof(staticRowWInfo[0]) );
    memset( staticColWInfo, 0, lenStaticColWInfo * sizeof(staticColWInfo[0]) );
#endif

    //fill the list
    int maxCol = 0;
    int maxRow = 0;
    float xStepSize = float(pSrcBlock->width) / pDstBlock->width;
    float yStepSize = float(pSrcBlock->height) / pDstBlock->height;
    float coverArea = xStepSize * yStepSize;
    float maxPixel = 255 * coverArea;
    int srcIndex = 0;
    for (col = 1; col <= pDstBlock->width; ++col) {
        float x = xStepSize * col;

        int xInt = int(x);
        float xFra = x - xInt;
        //printf( "processing col=%d x=%f current srcIndex=%d\n", col, x, srcIndex );
        for (; srcIndex < xInt; ++srcIndex) {
            if (srcIndex < pSrcBlock->width) {
                colInfo[srcIndex].dstIndex = col - 1;
                colInfo[srcIndex].weight = 1.0f;

                //DEBUG
                //printf( "setting [%d] to %d w=1.0\n", srcIndex, (col - 1));
            }
        }
        if (xFra > 0) {
            if (srcIndex < pSrcBlock->width) {
                colInfo[srcIndex].dstIndex = col - 1;
                colInfo[srcIndex].weight = xFra;
                //DEBUG
                //printf( "setting [%d] to %d w=%f\n", srcIndex, (col - 1), xFra);
                ++srcIndex;
            }
        }
    }
    maxCol = srcIndex;
    srcIndex = 0;
    for (row = 1; row <= pDstBlock->height; ++row) {
        float y    = yStepSize * row;
        int   yInt = int(y);
        float yFra = y - yInt;

        //printf( "for row=%d, y=%f yInt=%d yFra=%f\n", row, y, yInt, yFra );
        //printf( "srcIndex=%d\n", srcIndex );

        for (; srcIndex < yInt; ++srcIndex) {
            if (srcIndex < pSrcBlock->height) {
                rowInfo[srcIndex].dstIndex = row - 1;
                rowInfo[srcIndex].weight = 1.0f;

                //DEBUG
                //printf( "seting [%d] to %d w=1.0\n", srcIndex, (row - 1));
            }
        }
        if (yFra > 0) {
            if (srcIndex < pSrcBlock->height) {
                rowInfo[srcIndex].dstIndex = row - 1;
                rowInfo[srcIndex].weight = yFra;
                //DEBUG
                //printf( "setting [%d] to %d w=%f\n", srcIndex, (row - 1), yFra);
                ++srcIndex;
            }
        }
    }
    maxRow = srcIndex;

    size_t totalNum =
    pDstBlock->width * pDstBlock->height * pDstBlock->pixelSize;

#ifdef USE_DYNAMIC_MEM
    float *pTmp = new float[totalNum];
    if (pTmp == NULL) {
        printf( "run out of memory\n" );
        strcpy( errMsgFromFunction, "run out of memory" );
        return TCL_ERROR;
    }
#else
    if (totalNum > lenStaticFloatImage) {
        lenStaticFloatImage = 0;
        delete [] staticFloatImage;
        staticFloatImage = new float[totalNum];
        if (staticFloatImage == NULL) {
            printf( "run out of memory\n" );
            strcpy( errMsgFromFunction, "run out of memory" );
            return TCL_ERROR;
        }
        lenStaticFloatImage = totalNum;
        printf( "new floatImage size: %lu\n", totalNum );

    }
    float *pTmp = staticFloatImage;
    //memset( staticFloatImage, 0, lenStaticFloatImage * sizeof(pTmp[0]) );
#endif

    //printf( "maxrow=%d maxcol=%d\n", maxRow, maxCol );
    //printf( "direct cal: maxrow=%d maxcol=%d\n",
    //int(yStepSize * pDstBlock->height),
    //int(xStepSize * pDstBlock->width)
    //);

    memset( pTmp, 0, totalNum * sizeof(pTmp[0]) );

    //printf( "distributing\n");
    for (row = 0; row < maxRow; ++row) {
        int dstRow0 = rowInfo[row].dstIndex;
        float weightRow0 = rowInfo[row].weight;
        //printf( "processing row=%d dstRow=%d w=%f\n", row, dstRow0, weightRow0 );
        for (col = 0; col < maxCol; ++col) {
            const unsigned char *pSrc = pSrcBlock->pixelPtr +
            row * pSrcBlock->pitch + col * pSrcBlock->pixelSize;

            //each source pixel can distribute to 4 destination pixels
            float * pDst[2][2];
            float   totalWeight[2][2];

            //for reserveWhite
            //to direct access the destination image
            unsigned char * pWhiteDst;

            int dstCol0 = colInfo[col].dstIndex;
            float weightCol0 = colInfo[col].weight;

            pDst[0][0] = pTmp +
            dstRow0 * pDstBlock->pitch + dstCol0 * pDstBlock->pixelSize;

            pDst[0][1] = pDst[0][0] + pDstBlock->pixelSize;
            pDst[1][0] = pDst[0][0] + pDstBlock->pitch;
            pDst[1][1] = pDst[0][1] + pDstBlock->pitch;

            totalWeight[0][0] = weightCol0 * weightRow0;
            totalWeight[0][1] = (1.0f - weightCol0) * weightRow0;
            totalWeight[1][0] = weightCol0 * (1.0f - weightRow0);
            totalWeight[1][1] = (1.0f - weightCol0) * (1.0f - weightRow0);

            if (reserveWhite) {
                pWhiteDst = pDstBlock->pixelPtr +
                dstRow0 * pDstBlock->pitch + dstCol0 * pDstBlock->pixelSize;
                if (weightCol0 >= 0.5f) {
                    if (weightRow0 >= 0.5f) {
                        //already calculated
                    } else {
                        pWhiteDst += pDstBlock->pitch;
                    }
                } else {
                    if (weightRow0 >= 0.5f) {
                        pWhiteDst += pDstBlock->pixelSize;
                    } else {
                        pWhiteDst += pDstBlock->pitch + pDstBlock->pixelSize;
                    }
                }
            }
            //DEBUG
#if 0
            if (row < 1 || col >= 700) {
                printf( "[%d, %d]=>DST: %d %d weight %f %f %f %f\n",
                row, col, dstRow0, dstCol0,
                totalWeight[0][0],
                totalWeight[0][1],
                totalWeight[1][0],
                totalWeight[1][1] );
                printf( "offset: %d %d %d %d\n",
                pDst[0][0] - pTmp,
                pDst[0][1] - pTmp,
                pDst[1][0] - pTmp,
                pDst[1][1] - pTmp );

                fflush( stdout );
            
            }
#endif

            int maxOR = 2;
            int maxOC = 2;
            if (dstRow0 >= pDstBlock->height - 1) {
                maxOR = 1;
            }
            if (dstCol0 >= pDstBlock->width - 1) {
                maxOC = 1;
            }
            unsigned long brightness = 0;
            for (int chan = 0; chan < pDstBlock->pixelSize; ++ chan) {
                const unsigned char *pS = pSrc + pSrcBlock->offset[chan];

                if (chan < numChanToCheck) {
                    brightness += pS[0] * pS[0];
                }

                for (int oR = 0; oR < maxOR; ++oR) {
                    for (int oC = 0; oC < maxOC; ++oC) {
                        float *pD = pDst[oR][oC] + pDstBlock->offset[chan];
                        size_t away = pD - pTmp;
                        if (away < totalNum) {
                            *pD += *pS * totalWeight[oR][oC];
                        } else {
                            printf(
                            "boundery: away=%lu exceed %lu at %d %d %d %d %d\n",
                            away, totalNum, row, col, chan, oR, oC);
                        }
                    }
                }
            }//channel (color)
            if (reserveWhite && brightness >= whiteThreshold) {
                //got a white source
                size_t away = pWhiteDst - pDstBlock->pixelPtr;
                if (away < totalNum) {
                    for (int chan = 0; chan < numChanToCheck; ++ chan) {
                        pWhiteDst[pDstBlock->offset[chan]] = 255;
                    }
                }
            }
        }//column
    }//row

    //printf( "scaling back \n" );
    //now convert float to unsigned char

    if (reserveWhite) {
        for (int offset = 0; offset < totalNum; ++offset) {
            if (pDstBlock->pixelPtr[offset] == 255) {
                continue;
            }
            float v = pTmp[offset] / coverArea;
            if (v < 255.5) {
                pDstBlock->pixelPtr[offset] = (unsigned char)(v + 0.5f);
            } else {
                pDstBlock->pixelPtr[offset] = 255;
                printf( "DEBUG pixel =%f > 255 at offset=%d\n", v, offset );
            }
        }
    } else {
        for (int offset = 0; offset < totalNum; ++offset) {
            float v = pTmp[offset] / coverArea;
            if (v < 255.5) {
                pDstBlock->pixelPtr[offset] = (unsigned char)(v + 0.5f);
            } else {
                pDstBlock->pixelPtr[offset] = 255;
                printf( "DEBUG pixel =%f > 255 at offset=%d\n", v, offset );
            }
        }
    }

    //printf( "done bilinear\n" );

#ifdef USE_DYNAMIC_MEM
    delete [] rowInfo;
    delete [] colInfo;
    delete [] pTmp;
#endif

    return TCL_OK;
}

static void subAverage( 
    Tk_PhotoImageBlock *pDstBlock,
    const Tk_PhotoImageBlock *pSrcBlock,
    int xSub,
    int ySub,
    int reserveWhite
) {
    int row;
    int col;

    int num = xSub * ySub;

    int pixelSize = pSrcBlock->pixelSize;
    int pitch     = pSrcBlock->pitch;

    const int numChanToCheck =
    (pSrcBlock->pixelSize <= 3) ? pSrcBlock->pixelSize : 3;

    const unsigned long whiteThreshold =
    (unsigned long)(numChanToCheck * 255 * 255 * 0.95);

    for (row = 0; row < pDstBlock->height; ++row) {
        for (col = 0; col < pDstBlock->width; ++col) {
            unsigned char * pDst = pDstBlock->pixelPtr +
            row * pDstBlock->pitch + col * pDstBlock->pixelSize;

            unsigned char *pSrc00 = pSrcBlock->pixelPtr +
            row * ySub * pSrcBlock->pitch + col * xSub * pSrcBlock->pixelSize;

            for (int chan = 0; chan < pDstBlock->pixelSize; ++ chan) {
                //pSrc00 += pDstBlock->offset[chan];
                //pDst += pDstBlock->offset[chan];
                const unsigned char *pS = pSrc00 + pDstBlock->offset[chan];
                unsigned char *pD = pDst + pDstBlock->offset[chan];

                int sum = 0;
                for (int iy = 0; iy < ySub; ++iy) {
                    for (int ix = 0; ix < xSub; ++ix) {
                        int offsetSub = iy * pitch + ix * pixelSize;

                        unsigned char pixel = pS[offsetSub];
                        sum += pixel;
                    }
                }
                sum /= num;

                *pD = (unsigned char)sum;
            }//channel (color)

            //reserveWhite
            if (reserveWhite) {
                bool isWhite = false;
                for (int iy = 0; iy < ySub; ++iy) {
                    for (int ix = 0; ix < xSub; ++ix) {
                        int offsetSub = iy * pitch + ix * pixelSize;
                        const unsigned char *pS = pSrc00 + offsetSub;

                        unsigned long ll = 0;
                        for (int chan = 0; chan < numChanToCheck; ++chan) {
                            unsigned char pixel = pS[pSrcBlock->offset[chan]];
                            ll += pixel * pixel;
                        }
                        
                        if (ll >= whiteThreshold) {
                            isWhite = true;
                            break;
                        }
                    }
                    if (isWhite) break;
                }
                if (isWhite) {
                    for (int chan = 0; chan < numChanToCheck; ++chan) {
                        pDst[pDstBlock->offset[chan]] = 255;
                    }
                }
            }//reserveWhite
        }//column
    }//row

    //printf( "done subsampleAverage\n" );
}

int imageScaleBilinear( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 4)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "dstImg srcImg xScale [yScale]" );
        return TCL_ERROR;
    }

    char* dstName = Tcl_GetString( objv[1] );
    char* srcName = Tcl_GetString( objv[2] );
    double xScale = 1.0f;
    double yScale = 1.0f;

    if (Tcl_GetDoubleFromObj( interp, objv[3], &xScale ) != TCL_OK) {
        Tcl_SetResult( interp, "xScale is wrong", TCL_STATIC );
        return TCL_ERROR;
    }

    yScale = xScale;
    if (objc > 4) {
        if (Tcl_GetDoubleFromObj( interp, objv[4], &yScale ) != TCL_OK) {
            Tcl_SetResult( interp, "yScale is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }

    if (xScale == 0.0 || yScale == 0.0) {
        Tcl_SetResult( interp, "bad scale", TCL_STATIC );
        return TCL_ERROR;
    }


    //get images: I do not know the error indicator.
    Tk_PhotoHandle dstHandle = Tk_FindPhoto( interp, dstName );
    Tk_PhotoHandle srcHandle = Tk_FindPhoto( interp, srcName );

    if (srcHandle == NULL) {
        Tcl_SetResult( interp, "source image not exists", TCL_STATIC );
        return TCL_ERROR;
    }
    if (dstHandle == NULL) {
        Tcl_SetResult( interp, "destination image not exists", TCL_STATIC );
        return TCL_ERROR;
    }

    Tk_PhotoBlank( dstHandle);

    Tk_PhotoImageBlock srcBlock;
    Tk_PhotoImageBlock dstBlock;
    
    Tk_PhotoGetImage( srcHandle, &srcBlock );
    if (srcBlock.pitch == srcBlock.width) {
        Tcl_SetResult( interp,
        "image format rrrrr ggggg bbbbb not supported", TCL_STATIC );
        return TCL_ERROR;
    }

    //printf( "DEBUG: image width=%d height=%d pitch=%d\n",
    //srcBlock.width, srcBlock.height, srcBlock.pitch );

    if (srcBlock.width < 2 || srcBlock.height < 2) {
        Tcl_SetResult( interp, "image too small for bilinear", TCL_STATIC );
        return TCL_ERROR;
    }

    bool flipHorz = false;
    bool flipVert = false;
    if (xScale < 0) {
        flipHorz = true;
        xScale = -xScale;
    }
    if (yScale < 0) {
        flipVert = true;
        yScale = -yScale;
    }
    dstBlock.width  = int(srcBlock.width  * xScale + 0.0000001);
    dstBlock.height = int(srcBlock.height * yScale + 0.0000001);
    dstBlock.pixelSize = srcBlock.pixelSize;
    if (dstBlock.width < 1 || dstBlock.height < 1) {
        Tcl_SetResult( interp, "destination image too small for bilinear", TCL_STATIC );
        return TCL_ERROR;
    }

    //printf( "DEBUG: new image width=%d height=%d\n",
    //dstBlock.width, dstBlock.height );

    dstBlock.pitch = dstBlock.width * dstBlock.pixelSize;
    memcpy( dstBlock.offset, srcBlock.offset, sizeof(srcBlock.offset) );

#ifdef USE_DYNAMIC_MEM
    dstBlock.pixelPtr =
    new unsigned char[dstBlock.width * dstBlock.height * dstBlock.pixelSize];
    if (dstBlock.pixelPtr == NULL) {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
#else
    size_t totalNum = dstBlock.width * dstBlock.height * dstBlock.pixelSize;
    if (totalNum > lenStaticUCharImage) {
        lenStaticUCharImage = 0;
        delete [] staticUCharImage;
        staticUCharImage = new unsigned char[totalNum];
        if (staticUCharImage == NULL) {
            Tcl_SetResult( interp, "out of memory", TCL_STATIC );
            return TCL_ERROR;
        }
        lenStaticUCharImage = totalNum;
    }
    dstBlock.pixelPtr = staticUCharImage;

    memset( staticUCharImage, 0,
    lenStaticUCharImage * sizeof(staticUCharImage[0]) );
#endif

    int result = bilinearInterpolation( &dstBlock, &srcBlock, flipHorz, flipVert );
    if (result != TCL_OK) {
        Tcl_SetResult( interp, errMsgFromFunction, TCL_STATIC );
    } else {
        Tk_PhotoPutBlock( dstHandle, &dstBlock, 0, 0,
        dstBlock.width, dstBlock.height );

        Tcl_SetResult( interp, normal_result, TCL_STATIC );
    }

#ifdef USE_DYNAMIC_MEM
    delete [] dstBlock.pixelPtr;
#endif

    return result;
}

int imageResizeBilinear( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 4)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "dstImg srcImg width [height]" );
        return TCL_ERROR;
    }

    char* dstName = Tcl_GetString( objv[1] );
    char* srcName = Tcl_GetString( objv[2] );
    int widthNew = 0;
    int heightNew = 0;

    if (Tcl_GetIntFromObj( interp, objv[3], &widthNew ) != TCL_OK) {
        Tcl_SetResult( interp, "width is wrong", TCL_STATIC );
        return TCL_ERROR;
    }

    if (objc > 4) {
        if (Tcl_GetIntFromObj( interp, objv[4], &heightNew ) != TCL_OK) {
            Tcl_SetResult( interp, "height is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }

    // heightNew ==0 means scale the same as width
    if (widthNew == 0) {
        Tcl_SetResult( interp, "bad size", TCL_STATIC );
        return TCL_ERROR;
    }

    //get images: I do not know the error indicator.
    Tk_PhotoHandle dstHandle = Tk_FindPhoto( interp, dstName );
    Tk_PhotoHandle srcHandle = Tk_FindPhoto( interp, srcName );

    if (srcHandle == NULL) {
        Tcl_SetResult( interp, "source image not exists", TCL_STATIC );
        return TCL_ERROR;
    }
    if (dstHandle == NULL) {
        Tcl_SetResult( interp, "destination image not exists", TCL_STATIC );
        return TCL_ERROR;
    }

    Tk_PhotoBlank( dstHandle);

    Tk_PhotoImageBlock srcBlock;
    Tk_PhotoImageBlock dstBlock;
    
    Tk_PhotoGetImage( srcHandle, &srcBlock );
    if (srcBlock.pitch == srcBlock.width) {
        Tcl_SetResult( interp,
        "image format rrrrr ggggg bbbbb not supported", TCL_STATIC );
        return TCL_ERROR;
    }

    if (srcBlock.width < 2 || srcBlock.height < 2) {
        Tcl_SetResult( interp, "image too small for bilinear", TCL_STATIC );
        return TCL_ERROR;
    }

    //printf( "DEBUG: image width=%d height=%d pitch=%d\n",
    //srcBlock.width, srcBlock.height, srcBlock.pitch );

    bool flipHorz = (widthNew < 0);
    dstBlock.width  = abs(widthNew);
    if (heightNew == 0) {
        heightNew = srcBlock.height * dstBlock.width / srcBlock.width;
    }
    bool flipVert = (heightNew < 0);
    dstBlock.height = abs(heightNew);
    dstBlock.pixelSize = srcBlock.pixelSize;
    if (dstBlock.width < 1 || dstBlock.height < 1) {
        Tcl_SetResult( interp, "destination image too small for bilinear", TCL_STATIC );
        return TCL_ERROR;
    }


    dstBlock.pitch = dstBlock.width * dstBlock.pixelSize;
    memcpy( dstBlock.offset, srcBlock.offset, sizeof(srcBlock.offset) );

    //printf( "DEBUG: new image width=%d height=%d\n",
    //dstBlock.width, dstBlock.height );

#ifdef USE_DYNAMIC_MEM
    dstBlock.pixelPtr =
    new unsigned char[dstBlock.width * dstBlock.height * dstBlock.pixelSize];
    if (dstBlock.pixelPtr == NULL) {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
#else
    size_t totalNum = dstBlock.width * dstBlock.height * dstBlock.pixelSize;
    if (totalNum > lenStaticUCharImage) {
        lenStaticUCharImage = 0;
        delete [] staticUCharImage;
        staticUCharImage = new unsigned char[totalNum];
        if (staticUCharImage == NULL) {
            Tcl_SetResult( interp, "out of memory", TCL_STATIC );
            return TCL_ERROR;
        }
        lenStaticUCharImage = totalNum;
    }
    dstBlock.pixelPtr = staticUCharImage;

    memset( staticUCharImage, 0,
    lenStaticUCharImage * sizeof(staticUCharImage[0]) );
#endif

    int result = bilinearInterpolation( &dstBlock, &srcBlock, flipHorz, flipVert );
    if (result != TCL_OK) {
        Tcl_SetResult( interp, errMsgFromFunction, TCL_STATIC );
    } else {
        Tk_PhotoPutBlock( dstHandle, &dstBlock, 0, 0,
        dstBlock.width, dstBlock.height );

        Tcl_SetResult( interp, normal_result, TCL_STATIC );
    }

#ifdef USE_DYNAMIC_MEM
    delete [] dstBlock.pixelPtr;
#endif

    return result;
}
int imageSubSampleAvg( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 4)
    {
        Tcl_WrongNumArgs( interp, 1, objv,
        "dstImg srcImg xSub [ySub] [reserveWhite]" );

        return TCL_ERROR;
    }

    char* dstName = Tcl_GetString( objv[1] );
    char* srcName = Tcl_GetString( objv[2] );
    int xSub = 1;
    int ySub = 1;

    int reserveWhite = 0;

    if (Tcl_GetIntFromObj( interp, objv[3], &xSub ) != TCL_OK) {
        Tcl_SetResult( interp, "xSub is wrong", TCL_STATIC );
        return TCL_ERROR;
    }

    ySub = xSub;
    if (objc > 4) {
        if (Tcl_GetIntFromObj( interp, objv[4], &ySub ) != TCL_OK) {
            Tcl_SetResult( interp, "ySubis wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }
    if (objc > 5) {
        if (Tcl_GetIntFromObj( interp, objv[5], &reserveWhite ) != TCL_OK) {
            Tcl_SetResult( interp, "reserveWhite wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }

    if (xSub < 1 || ySub < 1) {
        Tcl_SetResult( interp, "bad subSample", TCL_STATIC );
        return TCL_ERROR;
    }

    //get images: I do not know the error indicator.
    Tk_PhotoHandle dstHandle = Tk_FindPhoto( interp, dstName );
    Tk_PhotoHandle srcHandle = Tk_FindPhoto( interp, srcName );

    if (srcHandle == NULL) {
        Tcl_SetResult( interp, "source image not exists", TCL_STATIC );
        return TCL_ERROR;
    }
    if (dstHandle == NULL) {
        Tcl_SetResult( interp, "destination image not exists", TCL_STATIC );
        return TCL_ERROR;
    }

    Tk_PhotoBlank( dstHandle);

    Tk_PhotoImageBlock srcBlock;
    Tk_PhotoImageBlock dstBlock;
    
    Tk_PhotoGetImage( srcHandle, &srcBlock );
    if (srcBlock.pitch == srcBlock.width) {
        Tcl_SetResult( interp,
        "image format rrrrr ggggg bbbbb not supported", TCL_STATIC );
        return TCL_ERROR;
    }

    //printf( "DEBUG: image width=%d height=%d pitch=%d\n",
    //srcBlock.width, srcBlock.height, srcBlock.pitch );

    if (xSub == 1 && ySub == 1) {
        //just copy
        Tk_PhotoPutBlock( dstHandle, &srcBlock, 0, 0,
        srcBlock.width, srcBlock.height );

        Tcl_SetResult( interp, normal_result, TCL_STATIC );
        return TCL_OK;
    }

    dstBlock.width     = srcBlock.width / xSub;
    dstBlock.height    = srcBlock.height / ySub;
    dstBlock.pixelSize = srcBlock.pixelSize;
    if (dstBlock.width < 1 || dstBlock.height < 1) {
        Tcl_SetResult( interp, "destination image too small", TCL_STATIC );
        return TCL_ERROR;
    }

    dstBlock.pitch = dstBlock.width * dstBlock.pixelSize;
    memcpy( dstBlock.offset, srcBlock.offset, sizeof(srcBlock.offset) );

#ifdef USE_DYNAMIC_MEM
    dstBlock.pixelPtr =
    new unsigned char[dstBlock.width * dstBlock.height * dstBlock.pixelSize];
    if (dstBlock.pixelPtr == NULL) {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
#else
    size_t totalNum = dstBlock.width * dstBlock.height * dstBlock.pixelSize;
    if (totalNum > lenStaticUCharImage) {
        lenStaticUCharImage = 0;
        delete [] staticUCharImage;
        staticUCharImage = new unsigned char[totalNum];
        if (staticUCharImage == NULL) {
            Tcl_SetResult( interp, "out of memory", TCL_STATIC );
            return TCL_ERROR;
        }
        lenStaticUCharImage = totalNum;
    }
    dstBlock.pixelPtr = staticUCharImage;

    memset( staticUCharImage, 0,
    lenStaticUCharImage * sizeof(staticUCharImage[0]) );
#endif

    subAverage( &dstBlock, &srcBlock, xSub, ySub, reserveWhite );
    Tk_PhotoPutBlock( dstHandle, &dstBlock, 0, 0,
    dstBlock.width, dstBlock.height );

    Tcl_SetResult( interp, normal_result, TCL_STATIC );

#ifdef USE_DYNAMIC_MEM
    delete [] dstBlock.pixelPtr;
#endif

    return TCL_OK;
}
int imageDownsizeAreaSample( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc < 4)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "dstImg srcImg width [height] [reserveWhite]" );
        return TCL_ERROR;
    }

    char* dstName = Tcl_GetString( objv[1] );
    char* srcName = Tcl_GetString( objv[2] );
    int widthNew = 0;
    int heightNew = 0;
    int reserveWhite = 0;

    if (Tcl_GetIntFromObj( interp, objv[3], &widthNew ) != TCL_OK) {
        Tcl_SetResult( interp, "width is wrong", TCL_STATIC );
        return TCL_ERROR;
    }

    if (objc > 4) {
        if (Tcl_GetIntFromObj( interp, objv[4], &heightNew ) != TCL_OK) {
            Tcl_SetResult( interp, "height is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }

    if (objc > 5) {
        if (Tcl_GetIntFromObj( interp, objv[5], &reserveWhite ) != TCL_OK) {
            Tcl_SetResult( interp, "reserveWhite is wrong", TCL_STATIC );
            return TCL_ERROR;
        }
    }

    if (widthNew <= 0 || heightNew <0) {
        Tcl_SetResult( interp, "bad size", TCL_STATIC );
        return TCL_ERROR;
    }


    Tk_PhotoHandle dstHandle = Tk_FindPhoto( interp, dstName );
    Tk_PhotoHandle srcHandle = Tk_FindPhoto( interp, srcName );

    if (srcHandle == NULL) {
        Tcl_SetResult( interp, "source image not exists", TCL_STATIC );
        return TCL_ERROR;
    }
    if (dstHandle == NULL) {
        Tcl_SetResult( interp, "destination image not exists", TCL_STATIC );
        return TCL_ERROR;
    }

    Tk_PhotoBlank( dstHandle);

    Tk_PhotoImageBlock srcBlock;
    Tk_PhotoImageBlock dstBlock;
    
    Tk_PhotoGetImage( srcHandle, &srcBlock );
    if (srcBlock.pitch == srcBlock.width) {
        Tcl_SetResult( interp,
        "image format rrrrr ggggg bbbbb not supported", TCL_STATIC );
        return TCL_ERROR;
    }

    //printf( "DEBUG: image width=%d height=%d pitch=%d\n",
    //srcBlock.width, srcBlock.height, srcBlock.pitch );

    if (heightNew == 0) {
        heightNew = srcBlock.height * widthNew / srcBlock.width;
    }
    if (widthNew > srcBlock.width || heightNew > srcBlock.height) {
        Tcl_SetResult( interp, "only support downsize", TCL_STATIC );
        return TCL_ERROR;
    }

    dstBlock.width  = widthNew;
    dstBlock.height = heightNew;
    dstBlock.pixelSize = srcBlock.pixelSize;

    dstBlock.pitch = dstBlock.width * dstBlock.pixelSize;
    memcpy( dstBlock.offset, srcBlock.offset, sizeof(srcBlock.offset) );

#ifdef USE_DYNAMIC_MEM
    dstBlock.pixelPtr =
    new unsigned char[dstBlock.width * dstBlock.height * dstBlock.pixelSize];
    if (dstBlock.pixelPtr == NULL) {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
#else
    size_t totalNum = dstBlock.width * dstBlock.height * dstBlock.pixelSize;
    if (totalNum > lenStaticUCharImage) {
        lenStaticUCharImage = 0;
        delete [] staticUCharImage;
        staticUCharImage = new unsigned char[totalNum];
        if (staticUCharImage == NULL) {
            Tcl_SetResult( interp, "out of memory", TCL_STATIC );
            return TCL_ERROR;
        }
        lenStaticUCharImage = totalNum;
    }
    dstBlock.pixelPtr = staticUCharImage;

    memset( staticUCharImage, 0,
    lenStaticUCharImage * sizeof(staticUCharImage[0]) );
#endif

    int result = downSizeDistribution( &dstBlock, &srcBlock, reserveWhite );
    if (result != TCL_OK) {
        Tcl_SetResult( interp, errMsgFromFunction, TCL_STATIC );
    } else {
        Tk_PhotoPutBlock( dstHandle, &dstBlock, 0, 0,
        dstBlock.width, dstBlock.height );

        Tcl_SetResult( interp, normal_result, TCL_STATIC );
    }

#ifdef USE_DYNAMIC_MEM
    delete [] dstBlock.pixelPtr;
#endif

    return result;
}
void imageSubAverage(
    Tk_PhotoImageBlock *pDstBlock,
    const Tk_PhotoImageBlock *pSrcBlock,
    int xSub,
    int ySub
    ) {
    subAverage( pDstBlock, pSrcBlock, xSub, ySub, 0 );
}
