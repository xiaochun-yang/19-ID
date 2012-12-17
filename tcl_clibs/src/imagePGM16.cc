#include <string.h>
#include <tk.h>

static void MedianFilter( unsigned short *pBuffer, int width, int height,
int size );
static int PGM16Format_fileMatch(
Tcl_Channel chan,
CONST char *fileName,
Tcl_Obj *format,
int *widthPtr,
int *heightPtr,
Tcl_Interp *interp
);

static int PGM16Format_fileRead(
Tcl_Interp *interp,
Tcl_Channel chan,
CONST char *fileName,
Tcl_Obj *format,
Tk_PhotoHandle imageHandle,
int destX,
int destY,
int width,
int height,
int srcX,
int srcY
);


Tk_PhotoImageFormat gPGM16Format = {
"pgm16",
PGM16Format_fileMatch,
NULL,
PGM16Format_fileRead,
NULL,
NULL,
NULL
};

typedef struct GrayscaleHistogram_t {
    size_t count[65536];
    size_t total;
} GrayscaleHistogram;


static int PGM16Format_fileMatch(
Tcl_Channel chan,
CONST char *fileName,
Tcl_Obj *format,
int *widthPtr,
int *heightPtr,
Tcl_Interp *interp
) {

    if (format != NULL) {
        printf( "calling PGM16Format_fileMatch format=%s\n", Tcl_GetString( format ) );
    }

    char header[1024] = {0};
    Tcl_Seek( chan, 0, SEEK_SET );
    int nRead = Tcl_Read( chan, header, 1023 );
    if (strncmp( header, "P5", 2)) {
        return 0;
    }
    unsigned int max = 0;
    int width = 0;
    int height = 0;

    if (sscanf( header, "P5 %d %d %u", &width, &height, &max ) < 3) {
        return 0;
    }
    if (max <= 255) {
        return 0;
    }
    if (widthPtr != NULL) {
        *widthPtr = width;
    }
    if (heightPtr != NULL) {
        *heightPtr = height;
    }
    return 1;
}

static void swapBytes( unsigned short *pBuffer, size_t length ) {
    for (size_t i = 0; i < length; ++i) {
        pBuffer[i] = (pBuffer[i]  << 8) | (pBuffer[i] >> 8);
    }
}
static void trimToImage(
unsigned short *pBuffer, int width, int height,
int srcX, int srcY, Tk_PhotoImageBlock *dstBlock ) {

    int dstSize = dstBlock->width * dstBlock->height;

    if (srcX == 0 && srcY == 0) {
        for (int i = 0; i < dstSize; ++i) {
            dstBlock->pixelPtr[i] = (unsigned char)(pBuffer[i] >> 8);
        }
    } else {
        for (int i = 0; i < dstSize; ++i) {
            int srcCol = i % dstBlock->width + srcX;
            int srcRow = i / dstBlock->width + srcY;
            int srcOffset = srcCol + srcRow * width;
            dstBlock->pixelPtr[i] = (unsigned char)(pBuffer[srcOffset] >> 8);
        }
    }
}

static void normalizeToImage(
unsigned short *pBuffer, int width, int height,
int srcX, int srcY, Tk_PhotoImageBlock *dstBlock,
double darkCut, double whiteCut, bool count ) {

    static size_t histogram[65536] = {0};
    memset( histogram, 0, sizeof(histogram) );

    int dstSize = dstBlock->width * dstBlock->height;

    //fill histogram
    unsigned short max = 0;
    unsigned short min = 65535;
    if (srcX == 0 && srcY == 0) {
        for (int i = 0; i < dstSize; ++i) {
            unsigned short v = pBuffer[i];
            if (v > max) max = v;
            if (v < min) min = v;
            ++histogram[v];
        }
    } else {
        for (int i = 0; i < dstSize; ++i) {
            int srcCol = i % dstBlock->width + srcX;
            int srcRow = i / dstBlock->width + srcY;
            int srcOffset = srcCol + srcRow * width;
            unsigned short v = pBuffer[srcOffset];
            if (v > max) max = v;
            if (v < min) min = v;
            ++histogram[v];
        }
    }
    printf( "from image: min=%hu, max=%hu\n", min, max );
    if (max <= min) {
        memset( dstBlock->pixelPtr, 0, dstSize );
        return;
    }
    int imgMax = max;
    int imgMin = min;

    if (darkCut >= 0 && darkCut <= 100) {
        if (count) {
            size_t darkCount = size_t(dstSize * darkCut / 100);
            size_t sum = 0;
            for (int v = 0; v < 65536; ++v) {
                sum += histogram[v];
                if (sum >= darkCount) {
                    min = v;
                    printf( "shift min to %hu by count darkCut\n", min );
                    break;
                }
            }
        } else {
            min = (unsigned short)(imgMin + (imgMax - imgMin) * darkCut / 100);
            printf( "shift min to %hu by darkCut\n", min );
        }
    }
    if (whiteCut >= 0 && whiteCut <= 100) {
        if (count) {
            size_t whiteCount = size_t(dstSize * whiteCut / 100);
            printf( "whiteCount=%lu\n", whiteCount );
            size_t sum = 0;
            for (int v = 0; v < 65536; ++v) {
                sum += histogram[v];
                //printf( "hist[%7d]=%12lu sum=%lu\n", v, histogram[v], sum );
                if (sum >= whiteCount) {
                    max = v;
                    printf( "shift max to %hu by count whiteCut\n", max );
                    break;
                }
            }
        } else {
            max = (unsigned short)(imgMin + (imgMax - imgMin) *whiteCut / 100);
            printf( "shift max to %hu by whiteCut\n", max );
        }
    }

    int gap = max - min;
    //generate pixel mapping
    for (int i = 0; i < min; ++i) {
        histogram[i] = 0;
    }
    for (int i = min; i < max; ++i) {
        if (histogram[i] > 0) {
            histogram[i] = (i - min) * 255 / gap;
        }
    }
    for (int i = max; i < 65536; ++i) {
        histogram[i] = 255;
    }

    //mapping
    if (srcX == 0 && srcY == 0) {
        for (int i = 0; i < dstSize; ++i) {
            unsigned short v = pBuffer[i];
            dstBlock->pixelPtr[i] = (unsigned char)histogram[v];
        }
    } else {
        for (int i = 0; i < dstSize; ++i) {
            int srcCol = i % dstBlock->width + srcX;
            int srcRow = i / dstBlock->width + srcY;
            int srcOffset = srcCol + srcRow * width;
            unsigned short v = pBuffer[srcOffset];
            dstBlock->pixelPtr[i] = (unsigned char)histogram[v];
        }
    }
}
static void equalizeToImage(
unsigned short *pBuffer, int width, int height,
int srcX, int srcY, Tk_PhotoImageBlock *dstBlock ) {

    static size_t histogram[65536] = {0};
    static size_t cdf[65536] = {0};
    memset( histogram, 0, sizeof(histogram) );
    memset( cdf,       0, sizeof(cdf) );

    int dstSize = dstBlock->width * dstBlock->height;

    //fill histogram
    unsigned short max = 0;
    unsigned short min = 65535;
    if (srcX == 0 && srcY == 0) {
        for (int i = 0; i < dstSize; ++i) {
            unsigned short v = pBuffer[i];
            if (v > max) max = v;
            if (v < min) min = v;
            ++histogram[v];
        }
    } else {
        for (int i = 0; i < dstSize; ++i) {
            int srcCol = i % dstBlock->width + srcX;
            int srcRow = i / dstBlock->width + srcY;
            int srcOffset = srcCol + srcRow * width;
            unsigned short v = pBuffer[srcOffset];
            if (v > max) max = v;
            if (v < min) min = v;
            ++histogram[v];
        }
    }
    if (max == min) {
        memset( dstBlock->pixelPtr, 0, dstSize );
        return;
    }

    //generate cdf
    int iStart = (min > 1)?min:1;
    for (int i = iStart; i <= max; ++i) {
        cdf[i] = cdf[i - 1] + histogram[i];
    }
    //generate pixel mapping
    size_t cdfMin  = cdf[min];
    size_t aNumber = cdf[max] - cdfMin;
    size_t half = aNumber / 2;
    for (int i = min; i <= max; ++i) {
        // half is there to simulator round
        histogram[i] = ((cdf[i] - cdfMin) * 255 + half) / aNumber;
    }

    //mapping
    if (srcX == 0 && srcY == 0) {
        for (int i = 0; i < dstSize; ++i) {
            unsigned short v = pBuffer[i];
            dstBlock->pixelPtr[i] = (unsigned char)histogram[v];
        }
    } else {
        for (int i = 0; i < dstSize; ++i) {
            int srcCol = i % dstBlock->width + srcX;
            int srcRow = i / dstBlock->width + srcY;
            int srcOffset = srcCol + srcRow * width;
            unsigned short v = pBuffer[srcOffset];
            dstBlock->pixelPtr[i] = (unsigned char)histogram[v];
        }
    }
}


static int PGM16Format_fileRead(
Tcl_Interp *interp,
Tcl_Channel chan,
CONST char *fileName,
Tcl_Obj *format,
Tk_PhotoHandle imageHandle,
int destX,
int destY,
int width,
int height,
int srcX,
int srcY
) {
    printf( "calling PGM16Format_fileRead\n" );

    if (srcX >= width) {
        Tcl_SetResult( interp, "srcX >= width", TCL_STATIC );
        return TCL_ERROR;
    }
    if (srcY >= height) {
        Tcl_SetResult( interp, "srcY >= height", TCL_STATIC );
        return TCL_ERROR;
    }

    bool normalize = false;
    bool count = false;
    bool equalize = false;
    double darkCut = 0;
    double whiteCut = 0;
    bool medianFilter = false;
    if (format != NULL) {
        if (strstr( Tcl_GetString( format ), "normalize")) {
            printf( "normalize\n" );
            normalize = true;
            darkCut = 0;
            whiteCut = 0;
        }
        const char *pFound = strstr( Tcl_GetString( format ), "cut_" );
        if (pFound) {
            pFound += 4; //skip "cut_"
            double arg1 = 0;
            double arg2 = 0;
            if (sscanf( pFound, "%lf_%lf", &arg1, &arg2 ) == 2) {
                normalize = true;
                darkCut = arg1;
                whiteCut = arg2;
                if (strstr( Tcl_GetString( format ), "count")) {
                    count = true;
                    printf( "histogram count stretch %lf%% to %lf%%\n", darkCut, whiteCut );
                } else {
                    printf( "histogram stretch %lf%% to %lf%%\n", darkCut, whiteCut );
                }
            }
        }
    
        if (strstr( Tcl_GetString( format ), "equalize")) {
            printf( "equalize\n" );
            equalize = true;
        }
        if (strstr( Tcl_GetString( format ), "median")) {
            printf( "median filter\n" );
            medianFilter = true;
        }
        pFound = strstr( Tcl_GetString( format ), "threshold_" );
        if (pFound) {
            double arg1;
            pFound += 10;
            if (sscanf( pFound, "%lf", &arg1 ) == 1) {
                normalize = true;
                whiteCut = darkCut = arg1;
                if (strstr( Tcl_GetString( format ), "count")) {
                    count = true;
                    printf( "count threshold %lf%%\n", arg1 );
                } else {
                    printf( "threshold %lf%%\n", arg1 );
                }
            }
        }
    }

    //read header
    Tcl_DString header;
    Tcl_DStringInit( &header );
    Tcl_Seek( chan, 0, SEEK_SET );
    int nRead = Tcl_Gets( chan, &header );

    if (nRead < 10) {
        Tcl_SetResult( interp, "wrong header", TCL_STATIC );
        return TCL_ERROR;
    }
    // only support int for image in tcl
    int srcWidth = 0;
    int srcHeight = 0;
    sscanf( Tcl_DStringValue(&header), "%*s %d %d", &srcWidth, &srcHeight );

    //allocate buffer
    int srcSize = srcWidth * srcHeight;
    printf( "width=%d height=%d size=%d\n", srcWidth, srcHeight, srcSize );
    unsigned short *srcImageBuffer = new unsigned short[srcSize];
    if (srcImageBuffer == NULL) {
        Tcl_SetResult( interp, "out of memory", TCL_STATIC );
        return TCL_ERROR;
    }
    //memset( srcImageBuffer, 0,  srcSize * sizeof(unsigned int) );

    //read the image
    printf( "calling Tcl_Read\n ");
    nRead = Tcl_Read( chan, (char*)srcImageBuffer, srcSize * sizeof(unsigned int) );
    printf( "nRead=%d\n", nRead );
    if (nRead < srcSize) {
        // less than one half data??
        delete [] srcImageBuffer;
        Tcl_SetResult( interp, "too few image data", TCL_STATIC );
        return TCL_ERROR;
    }

    swapBytes( srcImageBuffer, srcSize );
    if (medianFilter) {
        MedianFilter( srcImageBuffer, srcWidth, srcHeight, 3 );
    }

    //prepare destination image
    Tk_PhotoBlank( imageHandle );
    Tk_PhotoImageBlock dstBlock;

    dstBlock.pixelPtr  = new unsigned char[srcSize];
    dstBlock.width     = srcWidth - srcX;
    dstBlock.height    = srcHeight - srcY;
    dstBlock.pitch     = dstBlock.width;
    dstBlock.pixelSize = 1;

    dstBlock.offset[0]  = 0;
    dstBlock.offset[1]  = 0;
    dstBlock.offset[2]  = 0;
    dstBlock.offset[3]  = 0;

    if (normalize) {
        normalizeToImage(
            srcImageBuffer, srcWidth, srcHeight, srcX, srcY, &dstBlock, 
            darkCut, whiteCut, count 
        );
    } else if (equalize) {
        equalizeToImage(
            srcImageBuffer, srcWidth, srcHeight, srcX, srcY, &dstBlock
        );
    } else {
        trimToImage(
            srcImageBuffer, srcWidth, srcHeight, srcX, srcY, &dstBlock
        );
    }

    printf( "calling putBlock\n" );
    Tk_PhotoPutBlock( imageHandle, &dstBlock, destX, destY, width, height );
    
    delete [] srcImageBuffer;
    delete [] dstBlock.pixelPtr;
    printf( "done\n" );
    return TCL_OK;
}

//copied and modified from wiki Median Filter
static void deleteColumnPixelsFromHistogram( 
unsigned short *pBuffer, int width, int height,
int row,
int column,
int size,
GrayscaleHistogram *pHist
) {
    int i;
    unsigned short pixel;

    if (column < 0 || column >= width) {
        return;
    }
    int iStart = row - size;
    if (iStart < 0) {
        iStart = 0;
    }
    for (i = iStart; i <= row + size && i < height; ++i) {
        int offset = i * width + column;
        pixel = pBuffer[offset];
        pHist->count[pixel]--;
        pHist->total--;
    }
}

static void addColumnPixelsFromHistogram( 
unsigned short *pBuffer, int width, int height,
int row,
int column,
int size,
GrayscaleHistogram *pHist
) {
    int i;
    unsigned short pixel;

    if (column < 0 || column >= width) {
        return;
    }
    int iStart = row - size;
    if (iStart < 0) {
        iStart = 0;
    }
    for (i = iStart; i <= row + size && i < height; ++i) {
        int offset = i * width + column;
        pixel = pBuffer[offset];
        pHist->count[pixel]++;
        pHist->total++;
    }
}
static void moveDownHistogram( 
unsigned short *pBuffer, int width, int height,
int row,
int size,
GrayscaleHistogram *pHist
) {
    //deleteRowPixels
    int i;
    unsigned short pixel;

    int row_to_delete = row - size - 1;

    if (row_to_delete >= 0 && row_to_delete < height) {
        for (i = 0; i <= size && i < width; ++i) {
            int offset = row_to_delete * width + i;
            pixel = pBuffer[offset];
            pHist->count[pixel]--;
            pHist->total--;
        }
    }

    //Add RowPixels
    int row_to_add = row + size;
    if (row_to_add >= 0 && row_to_add < height) {
        for (i = 0; i <= size && i < width; ++i) {
            int offset = row_to_add * width + i;
            pixel = pBuffer[offset];
            pHist->count[pixel]++;
            pHist->total++;
        }
    }
}

//just to verify the moveDown is correct.
static void initializeHistogram( 
unsigned short *pBuffer, int width, int height,
int row,
int size,
GrayscaleHistogram *pHist
) {
    memset( pHist, 0, sizeof(*pHist) );
    for (int i = 0; i <= size && i < width; ++i) {
        addColumnPixelsFromHistogram( pBuffer, width, height,
        row, i, size, pHist );
    }
}

static size_t median( const GrayscaleHistogram *pHist ) {
    size_t mm = pHist->total / 2;

    size_t i;
    size_t sum = 0;
    for (i = 0; i < 65536; ++i) {
        sum += pHist->count[i];
        if (sum >= mm) {
            break;
        }
    }
    return i;
}

static void grayscale256Rescale( unsigned char *pBuffer, size_t buffer_size ) {
    unsigned char max = 0;
    unsigned char min = 255;

    size_t i;
    for (i = 0; i < buffer_size; ++i) {
        unsigned char p = pBuffer[i];
        if (p > max) {
            max = p;
        }
        if (p < min ) {
            min = p;
        }
    }
    if (max == 255 && min == 0) {
        printf( "no need to scale again for grayscale256\n" );
        return;
    }

    int dd = max - min;
    if (dd > 0) {
        for (i = 0; i < buffer_size; ++i) {
            pBuffer[i] = (unsigned char)(255 * (pBuffer[i] - min) / dd);
        }
    }
}

static void MedianFilter(
unsigned short *pBuffer, int width, int height, int size ) {
    if (pBuffer == NULL
    || width <= 0
    || height <= 0
    || size <= 0) {
        return;
    }

    size_t buffer_size = width * height;
    unsigned short *pOut = new unsigned short[buffer_size];
    if (pOut == NULL) {
        printf( "run out of memory for median filter\n" );
        return;
    }
    memset( pOut, 0, buffer_size * sizeof(unsigned short) );
    //this is safer and can hide problems
    //memcpy( pOut, pBuffer, buffer_size * sizeof(unsigned short) );

    int row;
    int col;
    GrayscaleHistogram hist;
    GrayscaleHistogram header_hist;

    for (row = 0; row < height; ++row) {
        if (row == 0) {
            initializeHistogram( pBuffer, width, height,
            0, size, &header_hist );
        } else {
            moveDownHistogram( pBuffer, width, height,
            row, size, &header_hist );
        }

        size_t row_offset = row * width;
        for (col = 0; col < width; ++col) {
            if (col == 0) {
                //initializeHistogram( pBuffer, width, height,
                //row, size, &hist );
                hist = header_hist;
            } else {
                deleteColumnPixelsFromHistogram( pBuffer, width, height,
                    row, col - size - 1, size, &hist );
                addColumnPixelsFromHistogram( pBuffer, width, height,
                    row, col + size, size, &hist );

            }
            size_t offset = row_offset + col;
            pOut[offset] = median( &hist );
        }
    }

    ////re-scale again
    memcpy( pBuffer, pOut, buffer_size * sizeof(unsigned short) );

    delete [] pOut;
}
