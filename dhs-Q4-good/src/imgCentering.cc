
/*
 *
 * The following code based on image developing package dali1.0 which
 *
 * Copyright (c) 1997-1998 by Cornell University.
 *
 * See the file "license.txt" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * imgCentering.cc File:
 *     all functions which are related to dhs_Camera are included in this file
 *
 * Author: Jian Zhong
 * Date:   June 29,2001
 *------------------------------------------------------------------------
 */

/*local include files*/
#include "xos_hash.h"
#include "libimage.h"

#include "math.h"
#include "dhs_config.h"
#include "dhs_database.h"
#include "dhs_messages.h"
#include "dhs_network.h"
#include "dhs_monitor.h"
#include "imgCentering.h"
#include <dirent.h>
#include <signal.h>
#include <sys/wait.h>
#include <string>
#include <map>
#include "log_quick.h"

#ifdef WIN32
  #include <winsock.h>
#else
  #include <arpa/inet.h>
#endif

#ifndef INADDR_NONE
#define INADDR_NONE 0xffffffff  /* should be in <netinet/in.h> */
#endif

#define SUCCESS 0
#define ERROR   -1               /* -1 is error code */
#define ERRORIMAGEISEMPTY -2     /* -2 is error code */

#define MAX_STRING_SIZE 128      /* in bytes */
#define REPLY_SIZE MAX_STRING_SIZE
#define MAX_BUFFER_SIZE 60000    /* in bytes */
#define MAX_RCV_BUFFER 4096      /* in bytes */

#define FILEMODE S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH /* Set permissions for newly created files.
                                                                          * current setting represents owner has
                                                                          * read/write/execute rights, grp user has
                                                                          * read/execute rights and others only have
                                                                          * read rights.
                                                                          */


/////////////////////////////
// change to 1 to save file
//////////////////////////////
static int DEBUG_SAVE_FILE = 0;
static BitImage* maskBitImage = NULL;

/* Macros For Loop Centering */

#define EDGENOISEQUARANTINE 1  /* Eliminate Noises at edge of Image caused by edge detection.
                                          * 2 represent two bytes. If the image size is 100*100 bytes, the
                                          * program will only scan a clipped image whose left upper corner
                                          * is (2,2) and right bottum corner is (98,98).
                                          */

#define VERTICALGAP 5          /* Specify Max. Acceptable Vertical Gap is 5 pixels */

#define LEASTPTS 2             /* The macro is only used in function getMaxMinYbyRange.
                                          * Specify one bucket at least contains two points
                                          */


#define MINWIDTH 2             /* Specify Min. Width. If a width is less than the value,
                                             we will think it's a noise and skip it */

/* Basic Data Structures */


/*
 * deltavalue struct keep the delta width along X axis,
 * it also supports construction of a delta value distribution.
 *
 * Members:
 *     lowY  --- delta width's upper Y value(in pixels)
 *     highY --- delta width's bottum Y value(in pixels)
 *     x     --- current delta width's X position(in pixels)
 */
     /*  Coordinate of one image(in pixels)
        * (0,0) ---------------------> X
        *  |
        *  |
        *  |
        *  |
        *  |
        *  |
        *  |
        *  |
        *  |
        *  Y
        */
struct deltavalue
{
   int lowY;
   int highY;
   int x;
   struct deltavalue * next;
};
typedef struct deltavalue deltavalue;

/*
 * groupPts struct stores the informatoin of one group delta widths
 * which are close to each other in X direction.
 *
 * Members:
 *     head        ---  delta width list of current group.
 *     total       ---  total number of the delta width list.
 *     begin       ---  the x position in pixels of the first element in the delta width list.
 *     end         ---  the x position in pixels of the last element in the delta width list.
 *     endHeight   ---  the mean value of lowY and highY of the last element in the delta width list.
 *                      the value only supports function BoundingBox2. During GetSmallestButTwoWidth
 *                      operation, program only scans from current group begin to this value to pick up
 *                      the smallest but two delta widths. In this way, we can eliminate effects from
 *                      small delta widths around loop tip.
 */
struct groupPts
{
   struct deltavalue* head;
   int total;
   int begin;
   int end;
   float endHeight;
   struct groupPts* next;
};
typedef struct groupPts groupPts;

/* widdiff struct is similar with deltavalue structure.
 * in this struct, difference between highY and lowY is stored instead of
 * storing lowY and highY.
 *
 * Member:
 *     diff --- the value of highY - lowY.
 *     x    --- the x position of the delta width.
 */
typedef struct widdiff
{
   int diff;
   int x;
   struct widdiff* next;
} widdiff;



/**
 * Hash table to keep track of all memory allocated by g_malloc.
 **/
typedef map<long, std::string> LONG2STRING;
LONG2STRING g_heapObjs;

#if !defined __LINE__
#error LINE MACRO is not defined
#endif

#ifdef IMG_DEBUG_MEMORY
#define g_malloc(a) l_malloc(a, __LINE__)

/**
 * Our own version of g_malloc
 **/
static void* l_malloc(unsigned int size, int line_num)
{
    // allocate the memory
    void* blob = malloc(size);

    if (!blob) {
        LOG_SEVERE("ERROR: g_malloc failed to allocate memory\n");
        return NULL;
    }

    char line[250];
    sprintf(line, "size (%d), line (%d)", size, line_num);
    g_heapObjs.insert(LONG2STRING::value_type((long)blob, std::string(line)));

    return blob;
}

static void g_free(void* blob)
{
    LONG2STRING::iterator i = g_heapObjs.find((long)blob);

    if (i == g_heapObjs.end()) {
        LOG_INFO1("ERROR in g_free: %ld\n", (long)blob);
        LONG2STRING::iterator i = g_heapObjs.begin();
        for (; i != g_heapObjs.end(); ++i) {
            LOG_INFO3("obj = %ld, heapObj = %ld, %s\n", (long)blob, i->first, i->second.c_str());
        }
        return;
    }

    // remove the pointer from the hash
    g_heapObjs.erase(i);

    // g_free the actuall memory
    free(blob);
}

int g_countObjs()
{
    return g_heapObjs.size();
}

void g_dumpObjs()
{
    if (g_countObjs() == 0)
        return;

    LONG2STRING::iterator i = g_heapObjs.begin();
    for (; i != g_heapObjs.end(); ++i) {
        LOG_INFO2("%ld: %s\n", i->first, i->second.c_str());
    }
    LOG_INFO1("num objects = %d\n", g_countObjs());
}


#else
#define g_malloc(a) malloc(a)
#define g_free(a) free(a)
int g_countObjs() { return 0; }
void g_dumpObjs() { }
#endif // IMG_DEBUG_MEMORY
void WritePBM8(PnmHdr* hdr, BitImage* r, char* filename);
BitImage* readPNM8( const char* fileName );
bool ImageIsFlat8(BitImage* r);

/*
 * Base64 Encode Function.
 * It is used to encode user name/password string in HTTP 1.0 protocal.
 */
unsigned char alphabet[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

xos_result_t base64encode(char* Input, char* Output)
{
    int bits, c, char_count;
    int leng;
    int CurPos;
    char* srcStr = NULL;

    char_count = 0;
    bits = 0;
    leng = 0;
    CurPos = 0;

    leng = strlen(Input) + 1;
    srcStr = (char*)g_malloc(sizeof(char)*leng);
    bzero(srcStr, leng);
    bzero(Output, MAX_STRING_SIZE);
    strcpy(srcStr,Input);
    leng = 0;

    while ((c = srcStr[leng]) != '\0' )
    {
       leng ++;
       if (c > 255) {
            LOG_SEVERE1("encountered char > 255 (decimal %d)", c);
            return XOS_FAILURE;
        }
        bits += c;
        char_count++;
        if (char_count == 3) {
            Output[CurPos] = (alphabet[bits >> 18]);
            CurPos++;
            Output[CurPos] = (alphabet[(bits >> 12) & 0x3f]);
            CurPos++;
            Output[CurPos] = (alphabet[(bits >> 6) & 0x3f]);
            CurPos++;
            Output[CurPos] = (alphabet[bits & 0x3f]);
            CurPos++;
            bits = 0;
            char_count = 0;
        } else {
            bits <<= 8;
        }
    }
    if (char_count != 0) {
        bits <<= 16 - (8 * char_count);
        Output[CurPos] = (alphabet[bits >> 18]);
        CurPos++;
        Output[CurPos] = (alphabet[(bits >> 12) & 0x3f]);
        CurPos++;
        if (char_count == 1) {
            strcat(Output, "==");
            CurPos += 2;
        } else {
            Output[CurPos] = (alphabet[(bits >> 6) & 0x3f]);
            CurPos ++;
            Output[CurPos] = ('=');
            CurPos ++;
        }
    }

    if(srcStr) g_free(srcStr);
    return XOS_SUCCESS;
}

void WritePGM(
    ByteImage *r,
    char *filename)
{
    int w = ByteGetWidth(r);
    int h = ByteGetHeight(r);
    BitParser *bp = BitParserNew();
    BitStream *bs = BitStreamNew(20 + w*h);
    FILE *f = fopen(filename, "wb");

    BitParserWrap(bp, bs);
    if (f == NULL) {
	fprintf(stderr, "unable to open file %s for writing.\n", filename);
	exit(1);
    }
    PnmHdr* hdr;
    hdr = PnmHdrNew();
    PnmHdrSetWidth(hdr, w);
    PnmHdrSetHeight(hdr, h);
    PnmHdrSetType(hdr, PGM_BIN);
    PnmHdrSetMaxVal(hdr, 255);
    PnmHdrEncode(hdr, bp);
    PgmEncode(r, bp);
    BitStreamFileWrite(bs, f, 0);
    fclose(f);
    BitParserFree(bp);
    BitStreamFree(bs);
    PnmHdrFree(hdr);
}
/* internal function, no safety check */
static int ComputeThresholdMymy( const size_t his[256] ) {
    int i;
    size_t max_his = 0;
    size_t min_his = 0;
    size_t half_max = 0;
    int    max_index = -1;
    int    min_index = -1;

    max_his = his[255];
    max_index = 255;
    min_his = his[255];
    min_index = 255;
    /* find peak for background */
    for (i = 254; i >= 0; --i) {
        if (his[i] > max_his) {
            max_his = his[i];
            max_index = i;
        }
        if (his[i] < min_his) {
            min_his = his[i];
            min_index = i;
        }
    }
    if (max_index == min_index ) {
        LOG_WARNING( "empty image" );
        return 128;
    }

    half_max = max_his / 2;
    int half_index1 = -1;
    int half_index2 = -1;
    for (i = max_index; i > 0; --i) {
        if (his[i] <= half_max) {
            break;
        }
    }
    half_index1 = i;
    for (i = max_index; i < 256; ++i) {
        if (his[i] <= half_max) {
            break;
        }
    }
    half_index2 = i;
    int half_width = half_index2 - half_index1;

    LOG_INFO3( "halfindex: %d %d, width %d\n", half_index1, half_index2, half_width );

    int cut_off =  max_index - 2 * half_width;

    if (cut_off > max_index / 2) {
        cut_off = max_index / 2;
        LOG_WARNING1( "use half max_index: %d", cut_off );
    }

    LOG_INFO1("cutoff: %d", cut_off );
    return cut_off;
}
static void ByteComputeHistogram( ByteImage* src, size_t his[256] ) {
    int i;
    size_t * ptr = NULL;
    int    index = 0;

    memset( his, 0, 256 );

    for (i = 0; i < src->width * src->height; ++i) {
        index = src->firstByte[i];
        ptr = his + index;
        ++(*ptr);
    }

}

/*
 * The Function using Canney Edge Detection to
 * detect a grayscale image's outline. After detection, a
 * PBM(Portable Bitmap Format) format image buffer is outputed.
 *
 * Parameters:
 *      input: r         --- A grayimage buffer.
 *             imgWidth  --- Current image width in pixels.(for example, 352 pixels)
 *             imgHeight --- Current image height in pixels.(for example, 240 pixels)
 *
 * Return:     BitImage  --- A bitmap buffer in which one pixel is represented by 0 or 1.
 */
BitImage*
DetectEdge(ByteImage* r,
              int imgWidth,
              int imgHeight)
{
    ByteImage *smth;       /*Store a smoothed grayimage*/
    BitImage *bit1;        /*Edg detect output*/
    int pw,ph;

    pw = imgWidth;
    ph = imgHeight;

    /*
     * First, smooth the input image.
     */
    smth = ByteNew(pw, ph);
    ByteSmooth(r, smth, 2);

    /*
     * Perform Canny edge detection.
     */
    ByteEdgeDetectCanny(smth, r, 4, 6);
    ByteFree(smth);

    /*
     * Convert the edge detected image into a B&W bit image.
     */
    bit1 = BitNew(pw, ph);
    BitMakeFromThreshold8(r, bit1, 128, 0);

    return bit1;
}

/*
 * JPEGtoPGM Function converts a JPEG image buffer to a Grayscale Image buffer.
 *
 * Description:
 *     In current implementation, we use red scale to represnt the grayscale image.
 *     In other words, after decoding JPEG image, we directly return the red byte image
 *     as the function's output.
 * Parameters:
 *      Input: imgBuffer  --- Source JPEG Image Data Buffer
 *             imgSize    --- JPEG image buffer size in chars
 *
 *      Output:grayPgm    --- Output Grayscale PGM Buffer
 *             imgWidth   --- Current image wide in pixels.
 *             imgHeight  --- Current image height in pixels.
 * Return:     0 --- SUCCESS
 *             -1 --- ERROR
 */
int
JPEGtoPGM(char* imgBuffer,
             int imgSize,
             ByteImage** grayPgm,
             int* imgWidth,
             int* imgHeight)
{
    BitStream *bs;
    BitParser *bp;
    JpegHdr *hdr;
    JpegScanHdr *scanHdr;
    int nc, wi, hi, bw, bh, mbw, mbh, *xdec, *ydec, id, pw, ph;
    ByteImage *y, *u, *v, *r, *g, *b;
    int i;
    ScImage **sclist;

    /*
     * Initialize bitstream and bitparser.
     */
    bs = NEW(BitStream);
    bs->buffer =(unsigned char*)imgBuffer;
    bs->size = imgSize;
    bs->endDataPtr = bs->buffer + imgSize;
    bs->endBufPtr = bs->buffer + imgSize;
    bs->isVirtual = 0;

    bp = BitParserNew();
    BitParserWrap(bp, bs);

    /*
     * First, we read off the JPEG header and scan header.
     */
    hdr = JpegHdrNew();
    JpegHdrParse(bp, hdr);
    scanHdr = JpegScanHdrNew();
    JpegScanHdrParse(bp, hdr, scanHdr);

    /*
     * Find out the number of components, width and height of the image.
     * bw and bh are the dimension of the image in blocks.
     */
    nc = JpegScanHdrGetNumOfComponents(scanHdr);
    wi = JpegHdrGetWidth(hdr);
    hi = JpegHdrGetHeight(hdr);
    bw = (wi+7)/8;
    bh = (hi+7)/8;
    mbw = JpegHdrGetMaxBlockWidth(hdr);
    mbh = JpegHdrGetMaxBlockHeight(hdr);
    xdec = (int *)g_malloc(sizeof(int)*nc);
    ydec = (int *)g_malloc(sizeof(int)*nc);
    sclist = (ScImage **)g_malloc(sizeof(ScImage *)*nc);
    for (i = 0; i < nc; i++) {
        id = JpegScanHdrGetScanId(scanHdr, i);
        xdec[i] = mbw/(JpegHdrGetBlockWidth(hdr, id));
        ydec[i] = mbh/(JpegHdrGetBlockHeight(hdr, id));
        sclist[i] = ScNew(bw/xdec[i], bh/ydec[i]);
    }

    /*
     * Finally, we parse the scan.
     */
    JpegScanParse(bp, hdr, scanHdr, sclist, i);

    /*
     * Prepare to decode the image.
     */
    pw = bw << 3;
    ph = bh << 3;
    y = ByteNew(pw/xdec[0], ph/ydec[0]);
    u = ByteNew(pw/xdec[1], ph/ydec[1]);
    v = ByteNew(pw/xdec[2], ph/ydec[2]);
    r = ByteNew(pw, ph);
    g = ByteNew(pw, ph);
    b = ByteNew(pw, ph);

    /*
     * Perform IDCT and dequantization on the image to get the raw image
     * in YUV color space.
     */
    ScIToByte(sclist[0], y);
    ScIToByte(sclist[1], u);
    ScIToByte(sclist[2], v);


    /*
     * Perform color conversion from YUV to RGB color space.
     */
    if (mbh == 1) {
        YuvToRgb422(y, u, v, r, g, b);
    } else {
        YuvToRgb420(y, u, v, r, g, b);
    }

    /*
     * From the r,g,b we get the gray scale image
     */
    //GetGrayScale(r,g,b);

    *grayPgm = r;
    *imgWidth = pw;
    *imgHeight = ph;

    /*
     * Clean up here.
     */
    JpegScanHdrFree(scanHdr);
    JpegHdrFree(hdr);
    ByteFree(y);
    ByteFree(u);
    ByteFree(v);
    ByteFree(g);
    ByteFree(b);
    g_free(xdec);
    g_free(ydec);

    for (int i = 0; i < nc; ++i ) {
        ScFree(sclist[i]);
    }
    g_free(sclist);

    BitParserFree(bp);
    FREE(bs);

    return 0;
}

/*
 * getImageBuffer Function connects to the camera, takes a snap and then
 * applies edge detection to the snap. Finally, it will return the outline of
 * current camera view in a bitmap format.
 *
 * Description:
 *       The struct CameraInfo pass all the information that is needed to  connect to
 *       camera. All those information is got from central database when the Camera DHS
 *       starts.
 *
 * Parameters :
 *      Input : camera_in  ---  All information needed to connect to the camera.For example,
 *                              camera IP address, port and URL path.
 *      Output: bitBuf     ---  Result after edge detection applied to current camera view.
 *
 * Return     : XOS_SUCCESS --- SUCCESS
 *              XOS_FAILURE --- ERROR
 */


xos_result_t
getImageBuffer(CameraInfo* camera_in,
                    BitImage** bitBuf,
                const char* debugFilePrefix )
{
  int nr = 0;             /* Number of Bytes readed from connecting socket */
  int curBufSize = 0;     /* Point to the size of OutBuffer. Because before we snap a image,
                                   * before we dwonload an image, the image size is unknown.
                                   */
  int count = 0;          /* Store actual buffer size */
  int imgWidth, imgHeight;/* Stor Image Size */
  xos_socket_t      mCommandSocket;  /* socket used to connect to camera */
  char  msg[MAX_STRING_SIZE];
  char* replybuf = NULL;
  char* Pos = NULL;
  char  EncodedStr[MAX_STRING_SIZE];
  char  UsrPwdPair[MAX_STRING_SIZE];
  in_addr_t serverInaddr;       /* Binary IP address */
  char* OutBuffer = NULL;
  char* tmpBuffer = NULL;

  ByteImage *grayBuf = NULL;

  /* for windows platform TCP/IP connection */
#ifdef WIN32
  WSADATA wsaData;
  WSAStartup(MAKEWORD(2,2), &wsaData );
#endif

    size_t his[256] = {0};
    int col;
    ByteImage* bw = NULL;
    int startByte;
    char fileName[1024];
    int threshold;
  /*Combine UsrName and Pwd to the format: UsrName:Pwd*/
  bzero(UsrPwdPair, MAX_STRING_SIZE);
  strcpy(UsrPwdPair, camera_in->mUsrName.c_str());
  strcat(UsrPwdPair,":");
  strcat(UsrPwdPair,camera_in->mPwd.c_str());

  /* Create Socket and Connect to Camera */

  xos_socket_address_t  detectorAddress;

  if ( xos_socket_create_client( &mCommandSocket ) != XOS_SUCCESS ){
     LOG_SEVERE("Error creating detector socket.");
     xos_error_exit("Exit.");
  }

  /* initialize remote camera IP address */
  xos_socket_address_init( &detectorAddress );

  /* If we already have decimal IP address */

  if((serverInaddr = inet_addr(camera_in->mIPAddress.c_str())) != INADDR_NONE ){
      /* conversion succeeded */
        detectorAddress.sin_addr.s_addr = serverInaddr;
  } else if ( xos_socket_address_set_ip_by_name( &detectorAddress, camera_in->mIPAddress.c_str() ) == XOS_FAILURE ){
        LOG_SEVERE("Error: Invalid Camera IP Address!");
        xos_error_exit("Exit.");
  }

  /* set port number */
  xos_socket_address_set_port( &detectorAddress, camera_in->mPort );

 /*
  * Connect to camera.
  * If errors rais, reconnect to camera until successfully connect to camera.
  */
  while ( xos_socket_make_connection( &mCommandSocket, &detectorAddress ) == XOS_FAILURE){
        xos_error("Error: ReConnect to Camera...\n");
        xos_thread_sleep(5000);
  }

  /* Encode user info */
  if ( base64encode(UsrPwdPair, EncodedStr) < 0 ) return XOS_FAILURE;

  /* strcpy(msg,"GET /cgi-bin/fullsize.jpg?camera=1&clock=0&date=0  HTTP/1.0\r\n");
      strcpy(msg,"GET /axis-cgi/jpg/image.cgi?camera=2&clock=0&date=0  HTTP/1.0\r\n");*/

  /* Compose http 1.0 connect string */
  strcpy(msg, "GET ");
  strcat(msg, camera_in->mUrlPath.c_str());
  strcat(msg, "Authorization: Basic ");
  strcat(msg, EncodedStr);
  strcat(msg, "\r\n\r\n");

  LOG_INFO1("HTTP request from camera: %s",msg);
  
  if ( xos_socket_write( &mCommandSocket, msg, strlen(msg) )  != XOS_SUCCESS ){
        LOG_SEVERE("Error: Sending Command raised Errors!\n");
     xos_error_exit("Exit.");
  }

  replybuf = (char*)g_malloc(sizeof(char)*MAX_RCV_BUFFER+1);
  OutBuffer = (char*)g_malloc(sizeof(char)*MAX_BUFFER_SIZE);
  curBufSize = MAX_BUFFER_SIZE;

  nr = recv(mCommandSocket.clientDescriptor,replybuf,MAX_RCV_BUFFER,0);

  if( nr > 0){
      replybuf[nr] = '\0';
  }
  else{
      xos_error("Error: Socket Reading raised Errors!\n");
     goto ERRORFLAG;
  }

  /***************************************************************************
   *Test to see if the request is successfully returned.
   *If request was been executed successfully, the HTTP return code should be 200
   *
   ***************************************************************************/
  if((Pos = strstr(replybuf,"200 OK"))==NULL){
      LOG_SEVERE1("Error: Protocol Format isn't HTTP1.0: %s", replybuf);
     xos_error_exit("Exit.");
  }

  /*Get rid of the http head and find out the begin of image buffer*/
  while(nr){
    if( (Pos = strstr(replybuf,"\xff\xd8\xff")) != NULL){
          nr = nr -(Pos-replybuf);
          break;
     }
    nr = recv(mCommandSocket.clientDescriptor, replybuf, MAX_RCV_BUFFER, 0);
  }

  assert(Pos);

  LOG_INFO("Begin to create Image Buffer\n");

  /* Start downloading image buffer and store in the buffer pointed by OutBuffer.
   * variable count store the actual image buffer size
    */
  if( nr > 0 ){
      memcpy(OutBuffer, Pos, nr);
      count += nr;
  }

  nr = recv(mCommandSocket.clientDescriptor, replybuf, MAX_RCV_BUFFER, 0);

  while ( nr > 0 ){
    replybuf[nr] = '\0';
     if(count+nr > curBufSize){
        LOG_INFO("Increase Buffer Size\n");
        tmpBuffer = (char*)g_malloc(sizeof(char)*(count+nr));
       if(!tmpBuffer){
            xos_error("Error: failed to realloc memory\n");
          return XOS_FAILURE;
       }
         memcpy(tmpBuffer, OutBuffer, count);
         g_free(OutBuffer);
       OutBuffer = tmpBuffer;
         curBufSize = count+nr;
    }

    memcpy(OutBuffer + count, replybuf, nr);
    count += nr;
    nr = recv(mCommandSocket.clientDescriptor, replybuf, MAX_RCV_BUFFER, 0);
  }

  /* Finished download image buffer and shut down connection */
  if ( xos_socket_destroy( &mCommandSocket ) != XOS_SUCCESS ){
        xos_error("detector_thread_routine -- error disconnecting from Camera.\n");
  }

  /* Convert JPEG to GrayScale ByteMap */
  if(JPEGtoPGM(OutBuffer , count , &grayBuf, &imgWidth, &imgHeight) < 0 ){
      goto ERRORFLAG;
  }

    ByteComputeHistogram( grayBuf, his );
    threshold = ComputeThresholdMymy( his );
    if (threshold <= 0) {
        LOG_WARNING( "bad threshold" );
        threshold = 127;
    }
    bw = ByteNew(imgWidth, imgHeight);
    LOG_INFO1( "gray to bw threshold: %d", threshold );
    ByteMakeFromThreshold8( grayBuf, bw, threshold, 1);

    //DEBUG
    if (DEBUG_SAVE_FILE) {
        strcpy( fileName, debugFilePrefix );
        strcat( fileName, "_gray.pgm" );
        WritePGM( grayBuf, fileName );
        strcpy( fileName, debugFilePrefix );
        strcat( fileName, "_bw.pgm" );
        WritePGM( bw, fileName );
    }

    /* Perform Canny Edge Detection*/
    *bitBuf = DetectEdge(grayBuf, imgWidth, imgHeight);

    /* check pin touching top or bottom */
    for (col = 0; col < imgWidth; ++col) {
        int v = bw->firstByte[col];
        //LOG_INFO2("top %d=%d", col, v);
        if (!v) {
            break;
        }
    }
    if (col < imgWidth && col > 0) {
        LOG_WARNING1( "pin touch top, add %d", col );
        int fullByte = col / 8;
        int extraBit = col % 8;
        int i;
        unsigned char* curDest;

        /// have not found why write row 0 will cause getWidthList crash
        curDest = (*bitBuf)->firstByte;
        curDest += (*bitBuf)->parentWidth;

        for (i = 0; i < fullByte; ++i) {
            *curDest = 0xff;
            ++curDest;
        }
        LOG_INFO1( "full byte: %d", fullByte);
        if (extraBit > 0) {
            unsigned char v = 0;
            for (i = 0; i < extraBit; ++i) {
                v |= (1<<i);
            }
            LOG_INFO2( "extra byte: %d 0x%x", extraBit, (int)(v));
            *curDest = v;
        }
    }
    startByte = imgWidth * (imgHeight - EDGENOISEQUARANTINE - 1);
    LOG_INFO1("startByte=%d", startByte);
    for (col = 0; col < imgWidth; ++col) {
        int v = bw->firstByte[startByte + col];
        //LOG_INFO2("bottom %d=%d", col, v);
        if (!v) {
            break;
        }
    }
    if (col < imgWidth && col > 0) {
        LOG_WARNING1( "pin touch bottom, add %d", col );
        int fullByte = col / 8;
        int extraBit = col % 8;
        int i;
        unsigned char* curDest;

        /// have not found why write row 0 will cause getWidthList crash
        curDest = (*bitBuf)->firstByte;
        curDest +=
        (*bitBuf)->parentWidth * (imgHeight - EDGENOISEQUARANTINE - 1);

        for (i = 0; i < fullByte; ++i) {
            *curDest = 0xff;
            ++curDest;
        }
        LOG_INFO1( "full byte: %d", fullByte);
        if (extraBit > 0) {
            unsigned char v = 0;
            for (i = 0; i < extraBit; ++i) {
                v |= (1<<i);
            }
            LOG_INFO2( "extra byte: %d 0x%x", extraBit, (int)(v));
            *curDest = v;
        }
    }

    ByteFree(bw);
    ByteFree(grayBuf);
    if(replybuf) g_free(replybuf);
    if(OutBuffer) g_free(OutBuffer);

    if (DEBUG_SAVE_FILE) {
        strcpy( fileName, debugFilePrefix );
        strcat( fileName, "_edge.pbm" );
        PnmHdr* pnmHdr;
        pnmHdr = PnmHdrNew();
        WritePBM8(pnmHdr, *bitBuf, fileName);
        PnmHdrFree(pnmHdr);
    }
    return XOS_SUCCESS;

 ERRORFLAG:
    LOG_WARNING("failed, disconnect");

  if(replybuf) g_free(replybuf);
  if(OutBuffer) g_free(OutBuffer);

  if ( xos_socket_destroy( &mCommandSocket ) != XOS_SUCCESS ){
        xos_error("detector_thread_routine -- error disconnecting from Camera.\n");
  }

  return XOS_FAILURE;
}
bool ImageIsFlatByte(ByteImage* r) {
    int row;
    int col;
    const unsigned char* startByte;

    int max = 0;
    int min = 255;

    int num_max = 0;
    int num_min = 0;

    int max_row = -1;
    int max_col = -1;
    int min_row = -1;
    int min_col = -1;

    for (row = 0; row < r->height; ++row) {
        startByte = r->firstByte + row * r->parentWidth;
        for (col = 0; col < r->width; ++col) {
            unsigned char v = startByte[col];
            if (v > max) {
                num_max = 0;
                max = v;;
                max_row = row;
                max_col = col;
            } else if (v == max) {
                ++num_max;
            }
            if (v < min) {
                num_min = 0;
                min = v;
                min_row = row;
                min_col = col;
            } else if (v == min) {
                ++num_min;
            }
           
        }
    }
    if (min == max) {
        LOG_INFO1( "image flat %d", max );
        return true;
    } else {
        LOG_INFO3( "image max %d at %d %d", max, max_row, max_col );
        LOG_INFO3( "image min %d at %d %d", min, min_row, min_col );
        LOG_INFO2( "num max %d num min %d", num_max, num_min );
        return false;
    }
}
bool ImageIsFlat8(BitImage* r) {
    int row;
    int col;
    const unsigned char* startByte;

    unsigned char expected_v = (r->firstByte[0] > 0) ? 0xff:0;

    for (row = 0; row < r->height; ++row) {
        startByte = r->firstByte + row * r->parentWidth;
        for (col = 0; col < (r->unitWidth >> 3); ++col) {
            if (startByte[col] != expected_v) {
                LOG_INFO2( "image not all flat at %d %d", row, col );
                return false;
            }
        }
    }
    return true;
}

/**********************************************************************************
           Functions below are for loop centering.
**********************************************************************************/

/*
 * ImageIsEmpty Function checks if there is nothing in current camera view.
 *
 * Description:
 *      In this function, four vertical line is drawed. Two four-pixel wide are at
 *      right and left side of the image. Two eight-pixle wide are at 1/4 and 1/2 width  of
 *      an image. If no line meets points, it will conclude current image is empty.
 *
 * Parameters :
 *      Input : r --- a bitmap image, which should be the result after edge detection.
 *
 * Return     :  0  --- SUCCESS
 *               -1 --- FAILURE
 *               -2 --- ERRORIMAGEISEMPTY
 */
int
ImageIsEmpty(BitImage* r)
{
   register int i;
   register unsigned char ByteSrc;   /* Store Image Buffer's first Byte */
   unsigned char* CurSrc;
    unsigned char direction;
   int bitswidth , width, height;

   bitswidth = r->unitWidth;
   width = r->byteWidth;
   height = r->height;
   CurSrc = r->firstByte;
    direction = 0;

   if(bitswidth > (width<<3)) width ++; /*If the last byte is a partial byte, count it into width*/

   /* i from EDGENOISEQUARANTINE to eliminate noises at the image edge caused by edge detection*/
   for( i = 0; i < height - EDGENOISEQUARANTINE; i ++){
      /* Left Testing */
      ByteSrc = *CurSrc;
      if(ByteSrc & 0x0f) direction |= 0x01;
        /* Half Center Testing */
        ByteSrc = *(CurSrc+(int)(width/4));
        if(ByteSrc & 0xff) direction |= 0x02;
      /* Central Testing */
      ByteSrc = *(CurSrc+(int)(width/2));
      if(ByteSrc & 0xff) direction |= 0x02;
      /* Right Testing */
      ByteSrc = *(CurSrc+(int)(width*3/4));
      if(ByteSrc & 0xff) direction |= 0x04;

        /* prepare next line */
      CurSrc += width;
   }
   if(direction == 0){
       xos_error("Image_is_Empty!\n");
       return ERRORIMAGEISEMPTY;
   }

   return SUCCESS;
}

/*
 * verticalScan Function do vertically scan to eliminate noises along Y direction.
 *
 * Description:
 *       We divide an image as many groups of pts along Y direction, and then pick up the group
 *       , which has most points as our interested region. It'll return the range along Y axis
 *       where our most points are located.
 * Parameters :
 *      Input : r --- BitImage Buffer
 *      Output: lowY  --- upper Y value of the range
 *              highY --- bottum Y value of the range
 * Return:      0 --- SUCCESS
 *              -1 --- ERROR
 */
int
verticalScan(BitImage* r,
                 int* lowY,
                 int* highY)
{
   int bitswidth, width, height;
   register int i,j;
   register unsigned char ByteSrc;
   unsigned char* CurSrc, *tmpSrc;

   groupPts Curgroup, Oldgroup;

   /* The following value is a threshold value to divide points as different groups.
     * If a gap between two continuous points is greater than the continueFlag, we think
     * the next point should blong to another group. In other words, current group ends and
     * a new group starts.
    */
   int continueFlag = 0;

   bitswidth = r->unitWidth;
   width = r->byteWidth;
   height = r->height;
   CurSrc = r->firstByte;

   if(bitswidth > (width<<3)) width ++; /*If the last byte is a partial byte, count it into width*/

   continueFlag = 0;
   Curgroup.total = Oldgroup.total = 0;
   Curgroup.begin = Oldgroup.begin = 0;
    Curgroup.end = Oldgroup.end = 0;

   for( i = 0; i < height-EDGENOISEQUARANTINE;i++){
      tmpSrc = CurSrc + i*width;
      for( j = 0; j < width - EDGENOISEQUARANTINE ; j ++){
           ByteSrc = *(tmpSrc + j);
          /*Check if there exists point*/
          if(ByteSrc & 0xff){
             if(Curgroup.total == 0) Curgroup.begin = i;
             Curgroup.end = i;
              Curgroup.total ++;
             break;
          }
      }
      if((j == width - EDGENOISEQUARANTINE) && Curgroup.total > 0 ){
         continueFlag ++;
         if(continueFlag >= VERTICALGAP){
            continueFlag = 0;
            if(Curgroup.total > Oldgroup.total){
                    Oldgroup.total = Curgroup.total;
                Oldgroup.begin = Curgroup.begin;
                Oldgroup.end = Curgroup.end;
            }
                Curgroup.begin = 0;
                Curgroup.total = 0;
         }
      }
      else
         continueFlag = 0;
   }

   /* Return the group range with most dense distribution along the Y axis */
   if(Oldgroup.total > Curgroup.total){
      *lowY = Oldgroup.begin>0;
      *highY = Oldgroup.end;
   }
   else{
      *lowY = Curgroup.begin;
      *highY = Curgroup.end;
   }
   return SUCCESS;
}

/* Debug Output Grp List */
void OutputGrpList(deltavalue* head, char* fileName)
{
    deltavalue* temp;

    FILE *f = fopen(fileName, "w+");
    if (f == NULL) {
        LOG_SEVERE("Unable to open file widthlist.txt for writing.\n");
        xos_error_exit("Exit.");
    }

     temp = head;
     while( temp != NULL){
        fprintf(f,"x:%d, lowY:%d , highY:%d\n", temp->x, temp->lowY, temp->highY);
         temp = temp->next;
     }
     fclose(f);
}


/*
 * getMaxMinbyRange Function returns UpperLimit and LowerLimit Y value in a specified X range.
 *
 * Description:
 *       The function won't simply return Max. Y value and Min. Y value in the specified X range.
 *       Instead, it use buckets to eliminate noise around the outline in Y direction. First, it caculate
 *       Max. Y value and Min. Y value in the specified X range. Second, it divides the max. delta width
 *       , Max.Y - Max.Y, as many buckets by VERTICALGAP deep. Third, it counts number of delta widths in every bucket.
 *       For example, Max. delta width is 9. It will get two buckets such as 0-4, 5-9. All Y value >= 0 and <= 4
 *       belong to the first bucktet, etc.
 *       After it gets statictcal info. for every bucket, it will do elimination stuff. The elimination order is from
 *       outside to inside. The elimination rule is that one bucket, which has at least 6 members or 2 members and
 *       its next inside bucket also has at least two members, will be kept and stop elimination process, otherwise
 *       will be deleted. Then it will use the remain buckets to recalculate the Y range of the specified X range.
 *       Finally, it'll returns max. and min. Y value in the new Y range along the specified X range as its results.
 *       For example, the bucket array to eliminate noises around max.Y are 0-4 has 3 members, 5-9 has 1 members,
 *       10-14 has 2 members, 15-19 has 3 members, 20-24 has 0 member, 25-29 has 6 members and 30-34 has 1 member.
 *       Then the remain buckets are 0-4,5-9,10-14, 15-19, 20-24,25-29. So the max. Y should <= 29. If above bucket
 *       array is to eliminate noises around min. Y, the remain buckets are 10-14, 15-19 ... and min. Y should >= 10.
 *       Finally, the function will return the min.Y value which >=10 and max. Y value which <=29 in the specified
 *       X range as its results.
 *
 * Parameters :
 *      Input : startwid_in --- delta width list
 *              begin       --- begin of the x range
 *              end         --- end of the x range
 *      Output: MinY        --- upperY of the x range
 *              MaxY        --- bottumY of the x range
 *
 */
void
getMaxMinYbyRange(deltavalue* startwid_in,
                        int begin,
                        int end,
                        int* MinY,
                        int* MaxY)
{
   int i;
   int bucketNum;             /* Store how many ranges between MaxY-MinY */
   int curPos,tmpMaxY,tmpMinY;
   int *bucketAryMin = NULL ; /* Store # of points in every bucket which from MinY */
   int *bucketAryMax = NULL ; /* Store # of points in every bucket which from MaxY */

   deltavalue *startwid,*tmpwid;

    /* Validity Check */
    if ( begin >= end ){
       *MinY = *MaxY = 0;
        return;
    }
    if ( startwid_in == NULL){
       *MinY = *MaxY = 0;
        return;
    }

   /* Get MinY and MaxY in the range */
   *MinY=10000; /* Specify a big number */
   *MaxY=0;
   tmpwid = startwid_in;

   while( (tmpwid!=NULL) && tmpwid->x < begin){
       tmpwid = tmpwid->next;
        if ( tmpwid == NULL ){
          *MinY = *MaxY = 0;
            return;
        }
   }
   startwid = tmpwid;
   for(i = 0; i < end-begin+1; i++){
         if(tmpwid==NULL) break;
        if(tmpwid->lowY < *MinY) *MinY = tmpwid->lowY;
        if(tmpwid->highY > *MaxY) *MaxY = tmpwid->highY;
        tmpwid = tmpwid->next;
   }

   /* Vertical Scan to Eliminate Noise */
   bucketNum = (int)ceil((*MaxY-*MinY+1)/VERTICALGAP) + 1;
   /* if we have few buckets , we will skip elimination process */
     if(bucketNum < 5) return;

   bucketAryMin = (int*)g_malloc(sizeof(int)*bucketNum);
   bucketAryMax = (int*)g_malloc(sizeof(int)*bucketNum);
   /* Initialize Array */
   for( i = 0; i< bucketNum; i++){
    bucketAryMin[i] = 0;
    bucketAryMax[i] = 0;
   }
   tmpwid = startwid;
   for(i = 0; i < end-begin+1; i++){
          if(tmpwid==NULL) break;
        curPos = (int)floor((tmpwid->lowY - *MinY)/VERTICALGAP);
          assert(curPos < bucketNum);
        bucketAryMin[curPos]++;
        curPos = (int)floor((*MaxY - tmpwid->highY)/VERTICALGAP);
          assert(curPos < bucketNum);
        bucketAryMax[curPos]++;
        tmpwid = tmpwid->next;
   }

   /* Eliminate Noises */
    tmpMaxY = *MaxY;
   for(i=0; i < bucketNum - 1 ;i++ ){
    if(((bucketAryMax[i] >= LEASTPTS) && (bucketAryMax[i+1] >= LEASTPTS )) || (bucketAryMax[i] >= 6)){
        tmpMaxY = *MaxY - i*VERTICALGAP;
        break;
    }
   }
    tmpMinY = *MinY;
   for(i=0; i < bucketNum - 1 ;i++ ){
    if(((bucketAryMin[i] >= LEASTPTS) && (bucketAryMin[i+1] >= LEASTPTS)) || (bucketAryMin[i] >= 6)){
        tmpMinY = *MinY + i*VERTICALGAP;
        break;
    }
   }

   if((*MinY!=tmpMinY) || (*MaxY!=tmpMaxY)){

       /* Get MinY and MaxY in the X range
            including edge */
        tmpMinY--;
        tmpMaxY++;

        *MinY=10000; /* Specify a big number */
        *MaxY=0;
        tmpwid = startwid;
          for(i = 0; i < end-begin+1; i++){
           if(tmpwid==NULL) break;
            if((tmpwid->lowY < *MinY) && (tmpwid->lowY >= tmpMinY)) *MinY = tmpwid->lowY;
            if((tmpwid->highY > *MaxY) && (tmpwid->highY <= tmpMaxY)) *MaxY = tmpwid->highY;
             tmpwid = tmpwid->next;
      }
   }

    /* If the function doesn't work, we only return zero value */
    if (*MinY == 10000 || *MaxY == 0) {
         *MinY = *MaxY = 0;
    }

   if ( bucketAryMin) g_free(bucketAryMin);
   if ( bucketAryMax) g_free(bucketAryMax);
}

/*
 * freegrp Function frees memory allocate for the input Grp info.
 */
void
freegrp(groupPts* Grp)
{
   deltavalue* head,*cur;

   if(Grp == NULL) return;
   head = Grp->head;
   while(head!=NULL)
   {
      cur = head->next;
      g_free(head);
      head = cur;
   }
   g_free(Grp);
}

/*
 * GetWidthList Function horizontally scan the outline bitmap by vertical lines.
 *
 * Description:
 *       The function will slice the outline of the loop by two-pixels wide vertical lines.
 *       A delta width list will be constructed.
 *
 * Parameters :
 *      Input : r --- BitImage Buffer
 *              lowY ---  upper Y value of the scan range
 *              highY --- bottum Y value of the scan range
 *      Output: widthList --- A list cantained the whole distribution of delta width values along X axis.
 * Return:      0 --- Success
 *              -1 --- Error
 */
int
GetWidthList(BitImage* r,
                 unsigned int lowY,
                 unsigned int highY,
                 groupPts** widthList)
{
   int width, bitswidth;
   register int i,k;
   register unsigned int j;
   register unsigned char ByteSrc;
   register unsigned char* CurSrc, *tmpSrc;
   int continueFlag;
   deltavalue CurByte[4];     /* Since we use two-pixel width line to scan, there will be four lines in one byte
                                         * , we use the array to store delta width info. for the four lines.
                                         */
   unsigned char outflag;     /* Use the byte to see if all four lines meet points, if all of them do then stop loop
                                         * In other words, if byte is 0 that indicates four delta widths info. have been
                                         * determined. We will try the next byte.
                                         */
   groupPts *curgrp, *oldgrp; /* store group points ouput group with most points*/
   deltavalue *curwid, *tmpwid;

   bitswidth = r->unitWidth;
   width = r->byteWidth;
   CurSrc = r->firstByte;

   if(bitswidth > (width<<3)) width ++; /*If the last byte is a partial byte, count it into width*/

   curgrp = (groupPts*)g_malloc(sizeof(groupPts));
   oldgrp = (groupPts*)g_malloc(sizeof(groupPts));
   oldgrp->head = curgrp->head = NULL;
   oldgrp->total = curgrp->total = 0;
   continueFlag = 0;

   CurSrc = r->firstByte;

   for(i = 0;i < width; i++){
      tmpSrc = CurSrc + i;

      /* From the top to bottom to get UpperY */
      outflag = 0x0f;
      for( j = lowY; j <= highY; j++ ){
         ByteSrc = *(tmpSrc + j*width);
         for( k = 0; k < 4; k ++ ){
               if( (ByteSrc<<(2*k)) & 0xc0 ){
                   if(outflag & (0x08>>k)){
                       CurByte[k].lowY = j;
                        CurByte[k].x = k + i*4;
                        outflag ^= (0x08>>k);
                    }
            }
         }
         if(outflag == 0x00){
            break;
         }
      }

      if(outflag != 0x0f){
         outflag = 0x0f;
         /* From the bottom to top, to get highY */
         for( j = highY ; j >= lowY ; j-- ){
                ByteSrc = *(tmpSrc + j*width);
                for( k = 0; k < 4; k ++){
                    if( (ByteSrc<<(2*k)) & 0xc0 ){
                        if(outflag & (0x08>>k)){
                            CurByte[k].highY = j;
                            outflag ^= (0x08>>k);
                        }
                    }
                }
                if(outflag == 0x00) break;
            }
        }

     /* Alloc Memory to Store Width List */
        for ( k = 0; k < 4; k++){
            if(outflag &(0x08>>k)){
                continueFlag ++;
                if(continueFlag > 2 && curgrp->total > 0){
                    if(curgrp->total > oldgrp->total){
                          freegrp(oldgrp);
                          oldgrp = (groupPts*)g_malloc(sizeof(groupPts));
                          oldgrp->total = curgrp->total;
                          oldgrp->begin = curgrp->begin;
                          oldgrp->head = curgrp->head;
                          oldgrp->end = curgrp->end;
                          oldgrp->endHeight = curgrp->endHeight;
                    } else {
                          freegrp(curgrp);
                          curgrp = (groupPts*)g_malloc(sizeof(groupPts));
                    }
                    curgrp->begin = 0;
                    curgrp->total = 0;
                    curgrp->end = 0;
                    curgrp->head = NULL;
                }
                continue;
            } else {
               continueFlag = 0;
               tmpwid = (deltavalue*) g_malloc(sizeof(deltavalue));
               if (!tmpwid){
                   LOG_SEVERE("Error: Failed to allocate memory!");
                   return -1;
                }
                tmpwid->lowY = CurByte[k].lowY;
                tmpwid->highY = CurByte[k].highY;
                tmpwid->x = CurByte[k].x;
                tmpwid->next = NULL;
                if(curgrp->head == NULL){
                   curgrp->head = tmpwid;
                    curwid = tmpwid;
                    curgrp->begin = tmpwid->x;
                }
                else{
                   curwid->next = tmpwid;
                    curwid = curwid->next;
                }
                curgrp->end = tmpwid->x;
                curgrp->endHeight = (tmpwid->highY + tmpwid->lowY)/2.0;
                curgrp->total++;
            }
        }
    }

    if(oldgrp->total > curgrp->total){
        *widthList = oldgrp;
        freegrp(curgrp);
    } else {
        *widthList = curgrp;
        freegrp(oldgrp);
    }
   return SUCCESS;
}


/*
 * getLoopHeight Function calculate a loop's height in current view.
 *
 * Description:
 *       The return value of this function is stored in the image list. These values
 *       are used to determine where loop will have max. height. Therefore, the absolute
 *       loop height of every loop in the image list is not needed. We only need a value
 *       which is changing according to the change of real loop height. Therefore, this
 *       function only use the right half of a width list of every loop outline. Because
 *       there is at least part of the loop is contained in the right half list, when the
 *       height of this part reach its max., the loop also will reach its max. height while
 *       rotating a loop by 180 degree.
 *       Why it only uses half of the width list? It want to eliminate bad effects bought from
 *       pin base. Also it can speed up calculating height of a loop.
 *       In this function, it also use buckets to eliminate noises, which are some singular delta
 *       widths among a whole width list. Please refer to getMaxMinYbyRange function description to
 *       see how buckets eliminate noises.
 *
 * Parameters :
 *      Input : r          --- Bitmap buffer, result after edge detection
 *      Output: Out_Height --- Height of the current half of width list.
 *              Out_LoopTipY --- Tip's Y value which is obtained in the width list.
 *                               This value will be used in checking loop shifting in Y direction.
 * Return : 0  --- SUCCESS
 *          -1 --- ERROR
 */
int
getLoopHeight(BitImage* r,
                  int* Out_Height,
                  int* Out_LoopTipY)
{

   int bucketNum;   /* Store how many ranges between MaxY-MinY */
   int i, startPos, curPos, tmpLoopHeight, tmpdeltaValue, tmpMaxValue;
   int *bucketAry = NULL ;
   int Img_LowY, Img_HighY;
   groupPts *Grp;
    deltavalue *startwid, *tmpwid, *maxdelta;

    *Out_Height = 0;
    *Out_LoopTipY = 0;
    maxdelta = NULL;


   /* Calculate Loop Height */

   /* Eliminate noises along Y axis */
   verticalScan(r, &Img_LowY, &Img_HighY);

    /* Construct width list for current loop's outline */
   Grp = NULL;
   GetWidthList(r, Img_LowY, Img_HighY, &Grp);

    if ( (Grp != NULL) && (Grp->head != NULL) ){
       tmpwid = Grp->head;
        /* Eliminate pin base noise.
            We only use half of the Grp pts.
         */
        startPos = (Grp->begin + Grp->end)/2;
        while ( (tmpwid != NULL) && (tmpwid->x < startPos ) ){
           tmpwid = tmpwid->next;
        }
        startwid = tmpwid;
        maxdelta = tmpwid;
        while ( tmpwid != NULL ){
           if ( (maxdelta->highY - maxdelta->lowY) < (tmpwid->highY - tmpwid->lowY) ){
               maxdelta = tmpwid;
            }
            tmpwid = tmpwid->next;
        }

        /* Following it will eliminate some Singular Points by Bucket Algorithm */
        if (maxdelta != NULL ){
          /* Vertical Scan to Eliminate Noise */
            tmpLoopHeight = maxdelta->highY - maxdelta->lowY;
             assert(tmpLoopHeight >= 0);
          bucketNum = (int)ceil((tmpLoopHeight + 1)/VERTICALGAP) + 1;
             bucketAry = (int*)g_malloc(sizeof(int)*bucketNum);
             /* Initialize Bucket */
             for ( i=0 ; i<bucketNum; i++ ){
                bucketAry[i] = 0;
             }

             tmpwid = startwid;
             while ( tmpwid != NULL ){
                curPos = (int)floor((tmpLoopHeight - (tmpwid->highY - tmpwid->lowY))/VERTICALGAP);
                 assert(curPos < bucketNum);
                 bucketAry[curPos]++;
                tmpwid = tmpwid->next;
             }
          /* Eliminate Noises */
          for(i=0; i < bucketNum - 1 ;i++ ){
                if(((bucketAry[i] >= LEASTPTS) && (bucketAry[i+1] >= LEASTPTS + 1)) || (bucketAry[i] >= 8)){
                     tmpLoopHeight = tmpLoopHeight - i*VERTICALGAP;
                      break;
                 }
             }

             /* Find Out Loop Height */
             if( tmpLoopHeight != (maxdelta->highY - maxdelta->lowY) ){
             /* Find out the real height */
                tmpLoopHeight++; /* We want to find a height in this range including edge */
                 tmpwid = startwid;
                 tmpMaxValue = 0;
                 while( tmpwid!=NULL ){
                    tmpdeltaValue = tmpwid->highY - tmpwid->lowY;
                     if( (tmpdeltaValue <= tmpLoopHeight) &&
                          (tmpdeltaValue > tmpMaxValue) ){

                         tmpMaxValue = tmpdeltaValue;
                          maxdelta = tmpwid;
                     }
                     tmpwid = tmpwid->next;
                 }
             }
             *Out_Height = maxdelta->highY - maxdelta->lowY + 1;
             *Out_LoopTipY = (int)Grp->endHeight;
        }

    }

    LOG_INFO2("CurHeight:%d,Center:%d\n", *Out_Height, *Out_LoopTipY);

    /* Clean Up */
    if ( Grp ) freegrp(Grp);
    if (bucketAry) g_free(bucketAry);
   return SUCCESS;
}


/*
 * EstimatePinBaseDiameter function will estimate the height of pin base. It's a help
 * function for function GetPinPosition.
 *
 */
int
EstimatePinBaseDiameter( groupPts* Grp )
{
     int endPos = Grp->end/2;
     //int endPos = Grp->end/10;
     int total , count,  mean;
     deltavalue *tmpwid;

    LOG_INFO( "EstimatePinBaseDiameter" );

     /* Firstly get a rough diameter using the mean height of the first half
     * width list, i.e. Grp.
     */

      tmpwid = Grp->head;

      total = 0;
      count = 0;
      while ( (tmpwid != NULL) && (tmpwid->x <= endPos) ){
          /* if current width is too small, we think it's noise and skip it */
          if ( tmpwid->highY - tmpwid->lowY < MINWIDTH ) {
                tmpwid = tmpwid->next;
                continue;
            }
            total +=  tmpwid->highY - tmpwid->lowY;
            count++;
            tmpwid = tmpwid->next;
      }

    if ( count == 0 ) {
        LOG_WARNING( "estimate pin diameter failed" );
        LOG_INFO2( "group begin=%d end=%d",
        Grp->begin, Grp->end );
        tmpwid = Grp->head;

        while (tmpwid != NULL) {
            LOG_INFO3( "point at %d y1=%d y2=%d",
            tmpwid->x, tmpwid->lowY, tmpwid->highY );
            tmpwid = tmpwid->next;
        }

        return ERROR;
    }

      mean = total/count;

    int save_mean = mean;

    LOG_INFO1( "mean: %d", mean );
      /* Converge our average height. Only try 3 times */
      for(int k = 0; k < 3; k++ ){
          tmpwid = Grp->head;
            total = count = 0;
            while ( (tmpwid != NULL) && (tmpwid->x <= endPos) ){
                if ( abs(( tmpwid->highY-tmpwid->lowY ) - mean) <= 5 ){
                    total +=  tmpwid->highY - tmpwid->lowY;
                      count++;
                 }
                 tmpwid = tmpwid->next;
            }

            if ( count == 0 ) {
                LOG_WARNING2("converge failed at k=i, preMean=%d", k, mean );
                return save_mean;
            }
            if ( abs(mean - (total/count)) <= 1 ) break;
            mean = total/count;
            LOG_INFO2( "converge k=%d mean: %d", k, mean );
      }

    LOG_INFO1( "EstimatePinBaseDiameter result: %d", mean );
      return mean;
}



/*
 * GetPinPosition Fuction will return current pin base's right end position in
 * current view.
 *
 * Description :
 *       When a loop is centered in the zoom out mode, we always can see clearly the pin base's end
 *       in the view. Since the diameter of a pin base is much larger than diameter of the fiber of a
 *       loop, we use the position of a dramatica decrease among the delta width list as the end of pin
 *       base.
 *
 * Parameters :
 *      Input : WidthList ---  Current BitImage Delta Width List.
 *
 * Return     : Position in X axis of the pin base's end.
 *              -1 --- ERROR
 */
int
GetPinPosition( groupPts* WidthList, int pinSizeHint )
{

    deltavalue* curPos = WidthList->head;

   /* The value control what point belongs to one group.
    */
   int continueFlag = 0;

    int curHeight = 0;
    int preHeight = 0;
    int HeightThreshold;
    int PinPos = 0;
    int GrpHeight =  EstimatePinBaseDiameter(WidthList);

    if ( GrpHeight < 0 ) {
        LOG_WARNING1( "getPinPosition failed: est returned %d < 0", GrpHeight );
        return ERROR;
    }

   /* In current implementation, a 50% decrease is our limit */
    HeightThreshold = (int)(GrpHeight * 0.50);
    if (pinSizeHint > 1 && HeightThreshold > pinSizeHint) {
        HeightThreshold = pinSizeHint;
    }

   /* Scan Now. We use the following rule to decide what point should be considered continuously.
     * If delta width of current X positon drop below 35% of the current group height, we think
     * there is a gap. If the gap continuousely increase along X dirction,we think current group meet
     * end and that end is what we want to get, pin's X position. We use the return value
    * of verticalScan function as our loop height.
    */

   while ( curPos != NULL  ){
        curHeight = curPos->highY - curPos->lowY;
        LOG_INFO2( "pinPosition: x=%d Height=%d", curPos->x, curHeight);
        curPos = curPos->next;
   }
   curPos = WidthList->head;

    //must to have at least 3 in a row > thresholdl to start
    while (curPos != NULL) {
        preHeight = curPos->highY - curPos->lowY;
        if ( preHeight >= HeightThreshold ) {
            break;
        }
        curPos = curPos->next;
    }

    LOG_INFO1( "pinPosition: threshold: %d", HeightThreshold );
   while ( curPos != NULL  ){
        curHeight = curPos->highY - curPos->lowY;
        /* If curHeight is too small, we will think it's noise and skiop it */
        if ( curHeight < MINWIDTH ) {
           curPos = curPos->next;
           continue;
        }
        LOG_INFO3( "pinPosition: x=%d curHeight=%d preHeight=%d", curPos->x, curHeight, preHeight );
        if( curHeight < HeightThreshold){
            PinPos = curPos->x;
            continueFlag ++;
            LOG_INFO1( "pinPosition: flag=%d", continueFlag);
            if(continueFlag > 3 && curHeight >= preHeight){
                return PinPos;
            }
        }
        else {
            continueFlag = 0;
        }

        curPos = curPos->next;
        preHeight = curHeight;
    }

    return ERROR;
}

/* WritePBM8 Function is from Dali library
 *
 * Parameters :
 *      Input : PnmHdr   --- Support Structure
 *              BitImage --- BitImage Buffer that is wanted to dump to disk
 *              filename --- File Name that user want to store the image buffer
 */

void
WritePBM8(PnmHdr* hdr,
             BitImage* r,
             char* filename)
{
    int w = BitGetWidth(r);
    int h = BitGetHeight(r);
    BitParser *bp = BitParserNew();
    BitStream *bs = BitStreamNew(20 + w*h/8);
    FILE *f = fopen(filename, "w");

    BitParserWrap(bp, bs);
    if (f == NULL) {
        xos_error("Unable to open file for writing.\n");
        return;
    }
    PnmHdrSetWidth(hdr, w);
    PnmHdrSetHeight(hdr, h);
    PnmHdrSetType(hdr, PBM_BIN);
    PnmHdrEncode(hdr, bp);
    PbmEncode8(r, bp);
    BitStreamFileWrite(bs, f, 0);
    fclose(f);
    BitParserFree(bp);
    BitStreamFree(bs);
}

/*
 * GetGrayScale Function converts a colorful image to grayscale one.
 * Descriptions :
 *       Input r,g,b three byte image, then pick up the max value among them
 *       for every pix as our Grayscale value. Output r byteImage store the Grayscale value
 *
 * Parameters :
 *      Input : r --- Red Color Scale
 *              g --- Green Color Scale
 *              b --- Blue Color Scale
 *
 */

void
GetGrayScale(ByteImage *r,
                 ByteImage* g,
                 ByteImage* b)
{
    register unsigned char *currr, *currg, *currb;
    register int i,w,h,grayValue;

    w = r->width;
    h = r->height;

    currr  = r->firstByte;
    currg  = g->firstByte;
    currb  = b->firstByte;

    for (i = 0; i < h; i++) {
            DO_N_TIMES(w,grayValue = max((byte)*currr,(byte)*currg);
                *currr = max((byte)*currb,(byte)grayValue);
            currr++;
            currg++;
            currb++;
        );
    }
}

/*
 * GetDiffGroup Function finds out which group of delta widths which are larger than the threshold
 * has most members.
 *
 * Description:
 *       The function check above threshold value's delta widths. Find which group have most continous points
 *       and return the group's begin and end
 *
 * Parameters :
 *      Input : head --- delta width list
 *              threshold --- threshold value
 *      Output: begin --- the begin of the group that found.
 *              end   --- the end of the group that found.
 *
 */
void
GetDiffGroup(widdiff* head,
                 int searchstart,
                 double threshold,
                 int* begin,
                 int* end)
{
   int total1,total2;
   int continueflag;
   groupPts Curgroup, Oldgroup;
   widdiff *cur;

    *begin = *end = 0;
   Curgroup.begin = Oldgroup.begin = 0;
    Curgroup.end = Oldgroup.end = 0;
   Curgroup.total = Oldgroup.total = 0;
   total1 = total2 = continueflag = 0;

   cur = head;
    /* Move Start Searching Point to searchstart */
    while (cur!=NULL) {
       if ( searchstart <= cur->x ) break;
        cur = cur->next;
    }
    if ( cur == NULL ) {
      /* The operation to move to searchstart point failed.
          Therefore, We'll do search from very beginning.*/
       cur = head;
    }

   while(cur!=NULL){
      if( cur->diff > threshold ){
          if(Curgroup.begin < 1) Curgroup.begin = cur->x;
          Curgroup.end = cur->x;
          Curgroup.total ++;
          continueflag = 0;
      }
      else
          if(Curgroup.total) continueflag ++;

      if(continueflag > 2){

           if(Curgroup.total > Oldgroup.total){
             Oldgroup.begin = Curgroup.begin;
            Oldgroup.end = Curgroup.end;
            Oldgroup.total = Curgroup.total;
         }
         Curgroup.begin = 0;
         Curgroup.total = 0;
            /* New Added */
            continueflag = 0;
      }
      cur = cur->next;
   }
   if(Oldgroup.total > Curgroup.total){
      *begin = Oldgroup.begin;
      *end = Oldgroup.end;
   } else {
      *begin = Curgroup.begin;
      *end = Curgroup.end;
   }
}

/*
 * BoundingBox1 Function determines the bounding box of inputted width list.
 *
 * Description:
 *       The function compare two BitImages(i.e. apply one to substract the other) and output the
 *       Bounding Box for the loop. Return which image has a larger height.
 *       More detail please refer to other documents.
 *
 * Parameters :
 *      Input : Grp1  --- One Width List
 *              Grp2  --- One Width List
 *      OutPut: begin --- left of the returned bounding box
 *              end   --- right of the returned bounding box
 *              MinY  --- Upper of the returned bounding box
 *              MaxY  --- Bottum of the returned bounding box
 *
 * Return     : 1 --- Image one has a larger height.
 *              2 --- Image two has a larger height.
 *              -1 --- ERROR
 */
int
BoundingBox1(groupPts* Grp1,
                 groupPts* Grp2,
                 int* begin,
                 int* end,
                 int* MinY,
                 int* MaxY)
{
   long total;
   double threshold;
   int DeltaNum;
   deltavalue *tmp1,*tmp2; /*width distribution*/
   widdiff *head,*cur;     /*width difference*/

   head = cur = (widdiff*)g_malloc(sizeof(widdiff));
   cur->next = NULL;
   total=0;
   tmp1 = Grp1->head;
   tmp2 = Grp2->head;
   DeltaNum = 1;

   while((tmp1!=NULL) && (tmp2!=NULL)){
       if(tmp1->x == tmp2->x){
            /* If the width is too small, we will skip it */
            if ( (tmp1->highY - tmp1->lowY >= MINWIDTH) && (tmp2->highY - tmp2->lowY >= MINWIDTH) ) {
                if(DeltaNum > 1){
                      cur->next = (widdiff*)g_malloc(sizeof(widdiff));
                        cur = cur->next;
                        cur->next = NULL;
                  }
                  cur->diff = tmp1->highY-tmp1->lowY - tmp2->highY + tmp2->lowY;
                  cur->x = tmp1->x;
                  DeltaNum ++;
             }
          tmp1 = tmp1->next;
          tmp2 = tmp2->next;
       }else if(tmp1->x > tmp2->x){
          tmp2 = tmp2->next;
       }else{
          tmp1 = tmp1->next;
       }
   }

   /* We have few poits to do processing */
   if( DeltaNum < 5){
      /* CLEAN UP */
        if (head != NULL) cur = head->next;
        while(head!=NULL){
            g_free(head);
            head = cur;
            if(cur) cur = cur->next;
        }
        return ERROR;
    }

    /* Since the fiber isn't real cylinder, so at different position
        there may be deviation between fiber widths.
        First use the left half of delta list as sample to estimate the width
        deviation. Count delta width difference which is less than 5 pixels in the sample.
        Why? Because there is an assumption that a fiber width won't deviate much.
        From the practical experience, we use threshold 3 assuming fiber is cylinder
        and also can get good answer in most cases */
    int estdiff = 0;
    total = 0;
    cur = head;
    int sampleRange = Grp1->end / 2 ;
    int sampleSize = 0;
    while( cur!=NULL && (cur->x < sampleRange) ){
       if ( abs(cur->diff) < 5 ){
           total += cur->diff;
            sampleSize += 1;
        }
        cur = cur->next;
    }

    if ( (sampleSize > 0) && ( total > 0) ) {
       estdiff = total/sampleSize;
        threshold = estdiff + 3.0;
    } else {
       /* By 99% confidence */
      threshold = 3.0;
    }

   /* Check Most continous Points above that threshold from where and end where*/

   GetDiffGroup(head, 0, threshold, begin, end);

   if ( *end <= *begin ){
        xos_error(" Function GetDiffGroup return an invalid pair begin/end \n");
        return ERROR;
    }

   /* Search for the neck point, where is the nearest point where diff < 1 */
   /* Now we use Threshold Value to compensate that error */

   *begin = (int)((*begin - threshold < 0)?0:*begin-threshold);

   /* Give it accurate loop end */
   *end = Grp1->end;

   /* Get MinY and MaxY in the range */
   getMaxMinYbyRange( Grp1->head, *begin, *end, MinY, MaxY);

   /* CLEAN UP */
   if ( head!=NULL ) cur = head->next;
   while(head!=NULL){
      g_free(head);
      head = cur;
      if(cur) cur = cur->next;
   }

   return SUCCESS;
}

/*
 * GetSmallestButTwoWidth Fuction estimates a rough diameter of loop's fiber.
 *
 * Description:
 *       Get the smallest but two width among one group points
 *       Why here not use the smallest width? Since we want to eliminate noises, in some cases
 *       we may get much smaller width(i.e. 0 ) than it should be because of the loop outline
 *       isn't a continuous curve.
 *
 * Parameters :
 *      Input : head    --- width list.
 *              loopend --- the end of searching.
 *                          Using the value can eliminate small delta widths around loop tip.
 *
 * Return     : width   --- estimated fiber width.
 *
 */
int
GetSmallestButTwoWidth(widdiff* head,
                              int loopend)
{
   int s1,s2,s3;
   widdiff *cur;

   /* s1 store the smallest value, s2 store the smallest but one, s3 store the smallest but two*/
   s1=s2=s3= 10000;

   cur = head;
    if (cur == NULL) return 0;
   while(cur!=NULL){
      /* We only scan to the Maximam Width */
      if(cur->x >= loopend ) break;
      if(cur->diff >= 3) /* skip invalid small delta widths */
        {
        if( cur->diff <= s1 )
             s1 = cur->diff;
            else if( cur->diff <= s2 )
             s2 = cur->diff;
        else if( cur->diff <= s3 )
             s3 = cur->diff;
      }
      cur = cur->next;
   }

   /* If no point is qualified, pick up the smallest width */
    if ( s3 == 10000 ){
        cur = head;
        while( cur!=NULL){
            if(cur->diff >= 3) /* skip invalid delta value */
            {
                if( cur->diff < s3 )
                    s3 = cur->diff;
            }
            cur = cur->next;
        }
    }

    /* If we stil don't find qualified S3 return 0 */
    if (s3 == 10000 ) return 0;

   return s3;
}


/*
 * GetRangeByValRange Function return a group whose delta width is in the specified value rang
 * has most members.
 *
 * Description:
 *       Get a delta width group in the specified value range.
 *
 * Parameters :
 *      Input : head --- pointed towidth list.
 *              MinV, MaxV --- specify a value range.
 *
 *      Output: begin --- begin of the group found.
 *              end   --- end of the group found.
 */
void
GetRangeByValRange(widdiff* head,
                         int MinV,
                         int MaxV,
                         int* begin,
                         int* end)
{
   int total1,total2;
   int continueflag;
   groupPts Curgroup, Oldgroup;
   widdiff *cur;

    *begin = *end = 0;
   Curgroup.begin = Oldgroup.begin = 0;
    Curgroup.end = Oldgroup.end = 0;
   Curgroup.total = Oldgroup.total = 0;
   total1 = total2 = continueflag = 0;
   cur = head;
   while(cur!=NULL){
      if(MinV <= cur->diff && cur->diff <= MaxV){
          if(Curgroup.begin < 1) Curgroup.begin = cur->x;
          Curgroup.end = cur->x;
          Curgroup.total ++;
          continueflag = 0;
      }
      else
          if(Curgroup.total) continueflag ++;

      /* If gap is big engough, we will end current group and start a new group */
      if(continueflag > 2){
         if(Curgroup.total > Oldgroup.total){
             Oldgroup.begin = Curgroup.begin;
            Oldgroup.end = Curgroup.end;
            Oldgroup.total = Curgroup.total;
         }
         Curgroup.begin = 0;
         Curgroup.total = 0;
            /* New Add */
            continueflag = 0;
      }
      cur = cur->next;
   }

   if(Oldgroup.total > Curgroup.total){
      *begin = Oldgroup.begin;
      *end = Oldgroup.end;
   } else {
     *begin = Curgroup.begin;
     *end = Curgroup.end;
   }
}


/*
 * BoundingBox2 Function implements Detectc Loop Algorithm 2
 *
 * Description :
 *       The Algorithm is based on that the fiber which hold the loop is always keep a cynlinder
 *       figure and its diameter is much smaller than the loop diameter.
 *
 * Parameters :
 *      Input :Grp --- Image's Delta Width List along the X axis
 *      Output:
 *             begin --- bounding box left value
 *             end --- bounding box right value
 *             MinY --- bounding box top value
 *             MaxY --- bounding box bottom value
 * return:     0 --- SUCESS
 *             -1 --- ERROR
 */
int
BoundingBox2(groupPts* Grp,
                 int* begin,
                 int* end,
                 int* MinY,
                 int* MaxY)
{
   int i,fiberwidth,startPos;
   float total, mean , dev, samplesize;
   float threshold;
   deltavalue *tmpwid;   /*width distribution*/
   widdiff *head,*cur;   /*width difference*/
   int MaxWidth_x;       /* X value when width is Maxiam*/
   int Maxdiff;          /* Max. height for specified x position */

    head = cur = NULL;
   tmpwid = Grp->head;
    startPos = Grp->begin + (Grp->end - Grp->begin)*3/4;
   Maxdiff = MaxWidth_x = 0;

    while(tmpwid!=NULL){
      if(head==NULL){
         head = (widdiff*)g_malloc(sizeof(widdiff));
           cur = head;
         cur->next = NULL;
        }
        else {
            cur->next = (widdiff*)g_malloc(sizeof(widdiff));
           cur = cur->next;
         cur->next = NULL;
        }

        cur->diff = tmpwid->highY - tmpwid->lowY ;
        cur->x = tmpwid->x;

        /* Find x position as a end to search loop fiber width. The main purpose is to eliminate
            some small delta value points at right end of the loop*/
        if( (cur->x >= startPos) && (cur->diff > Maxdiff) ){
            Maxdiff = cur->diff;
            MaxWidth_x = cur->x;
        }
        tmpwid = tmpwid->next;
    }
    LOG_INFO2( "maxDiff=%d at x=%d", Maxdiff, MaxWidth_x );

   /* we use the smallest but two width value as our pre-estimated fiber width */
   fiberwidth =  GetSmallestButTwoWidth(head, MaxWidth_x);
   LOG_INFO1( "fiberwidth got=%d", fiberwidth );

   /*
    * Get most continous group points in the range of the pre-estimated fiber width
    * and Use these points to statistcally estimate the fiber width
    */
   GetRangeByValRange(head,fiberwidth - 5 ,fiberwidth + 5, begin, end);

    LOG_INFO2( "fiber range from GetRangeByValRange: index %d to %d", *begin, *end );

   cur = head;
   total = 0;

   while(cur!=NULL ){
       if(cur->x >= *begin) break;
       cur = cur->next;
   }

   samplesize = 0;
   while( (cur!=NULL) && (cur->x <= *end) ) {
       total += cur->diff;
         samplesize ++;
       cur = cur->next;
   }

    /* Get Fiber Width Distribution */
    startPos = 0; /* set the search beginning for loop part */
    if ( samplesize > 1 ) /* if the samplesize is too small, it's nonesense to calcaulate mean and dev */
    {
       /* Set from where to find Loop Part.
            But if the estimated fiber end is close to the whole width list's end,
            we won't use the estimated fiber's begin as the search beginning.
         */
       if(*end + 5 < Grp->end) {
           startPos = *begin;
        }

        mean = total/samplesize;

        dev = 0;
        cur = head;
        while(cur!=NULL ){
            if(cur->x == *begin) break;
            cur = cur->next;
        }

        for( i = 0; i < samplesize; i ++ ) {
            dev += (cur->diff-mean)*(cur->diff-mean);
            cur = cur->next;
        }
        dev = sqrt(dev/(samplesize-1));

        /* With 90% confidence interval*/
        threshold = 1.645 * dev;

        /* subtraction the mean */
        cur = head;
        while(cur != NULL){
            cur->diff -= (int)mean;
            cur = cur->next;
        }
    }
    else {
        threshold = 2.0;
    }

    LOG_INFO1( "threshold %f", threshold );

   GetDiffGroup( head, startPos, threshold, begin, end);
    LOG_INFO2( "loop range from GetDiffGroup: index %d to %d", *begin, *end );

   if ( *end <= *begin ) {
        LOG_INFO(" Function GetDiffGroup return an invalid pair begin/end \n");
        return ERROR;
    }

    /* Finding BoundingBox failed,set *begin to Grp's begin. That means we will return the whole thing as our boundingbox */
    if( (*begin < Grp->begin) || ( (*end - *begin) <= 1 ) ) {
        *begin = Grp->begin;
        LOG_WARNING( "alg1 failed");
    }
   /* Give it accurate loop end */
   *end = Grp->end;

   /* Get MinY and MaxY in the range */
   getMaxMinYbyRange(Grp->head, *begin, *end, MinY, MaxY);

   /* CLEAN UP */
   if (head!=NULL) cur = head->next;
   while(head!=NULL) {
      g_free(head);
      head = cur;
      if(cur) cur = cur->next;
   }

    return SUCCESS;
}

/*
 * The function clean up the memory of a ImageList
 *
 * Parameters :
 *      Input : head --- Image List to be g_free.
 *
 */
void
freeImageList(ImageList *head)
{
    ImageList  *curImg,*tmpImg;

    curImg = head;
    while(curImg!=NULL) {
         tmpImg = curImg;
          tmpImg->Index = 0;
          curImg = curImg->next;
        BitFree(tmpImg->img);
          g_free(tmpImg);
    }
     head = NULL;
}

/*
 * The function draw a rectangle in a BitImage.
 *
 * Parameters :
 *      Input : img --- Bitmap Buffer.
 *              left, right, MinY, MaxY --- Specified Bounding Box.
 *              filename --- Specify the name of a file to store the bitmap.
 *
 */
void
drawRectangle(BitImage* img,
                  int left,
                  int right,
                  int MinY,
                  int MaxY,
                  char* filename)
{
   int width, bitswidth,leftByte,rightByte;
   register int i;
   register unsigned char *ByteSrc1,*ByteSrc2;
   register unsigned char* CurSrc;
   unsigned char byteMask1 = 0xc0;
   unsigned char byteMask2 = 0xc0;
   PnmHdr* pnmHdr;
   BitImage* r;

   r = BitNew(img->unitWidth,img->height);
   BitCopy8(img,r);

   bitswidth = r->unitWidth;
   width = r->byteWidth;
   CurSrc = r->firstByte;

   if(bitswidth > (width<<3)) width ++; /*If the last byte is a partial byte, count it into width*/

   leftByte = (int)floor((left+1)/4);
   rightByte = (int)floor((right+1)/4);

   for(i=1;i<= left-leftByte*4;i++)
      byteMask1 >>= 2;

   for(i=1;i<= right-rightByte*4;i++)
      byteMask2 >>= 2;

   for(i=MinY;i<=MaxY;i++) {
      ByteSrc1 = CurSrc + leftByte + i*width;
      ByteSrc2 = CurSrc + rightByte + i*width;
      (*ByteSrc1) |= byteMask1;
      (*ByteSrc2) |= byteMask2;
   }

   for(i=leftByte+1;i < rightByte;i++) {
      ByteSrc1 = CurSrc + i  + MinY*width;
      ByteSrc2 = CurSrc + i  + MaxY*width;
      *ByteSrc1 = 0xff;
      *ByteSrc2 = 0xff;
   }

    /**********************************************************************/
    pnmHdr = PnmHdrNew();
    WritePBM8(pnmHdr, r, filename);

    BitFree(r);
     PnmHdrFree(pnmHdr);
}

/*
 * Dump ImageList form Memory to Disk Image Files.
 *
 * Parameters :
 *      Input : picHead --- Image List
 *              dirName --- Directory where to store this image list.
 */
int
DumpImageList(ImageList* picHead,
                  char* dirName)
{
      int i = 1;
      DIR *dp = NULL;

      char tmpName[256];
      ImageList* tmpImg;
     PnmHdr* pnmHdr;

      pnmHdr = PnmHdrNew();
      tmpImg = picHead;
     if( (dp=opendir(dirName)) == NULL ) {
          /* Create a Directory */
          if( mkdir(dirName, FILEMODE) < 0 ) {
             xos_error( " Creating Dump Directory Failed.\n");
              return ERROR;
          }
      }

      while(tmpImg != NULL ) {
          /* compose file name */
          bzero(tmpName,256);
          /* Create Tempory File Name */
          strcpy(tmpName, "img");
          sprintf(tmpName,"%s_%d.pbm",tmpName,i);
          WritePBM8(pnmHdr, tmpImg->img , tmpName);
          i++;
          tmpImg = tmpImg->next;
      }

      if (dp) closedir(dp);
      PnmHdrFree(pnmHdr);

      return XOS_SUCCESS;
}


/*
 * The following fuction insert a loop image buffer into a list of loop images.
 * The return value is the loop's height.
 *
 * Parameters :
 *      Input : picHead --- Image List.
 *              new_img --- Image to be added.
 *              Index   --- Newly added images's index.
 * Return     : Current Image's Loop Height.
 *
 */
int
InsertImageList(ImageList** picHead,
                     BitImage* new_img,
                     int Index)
{
/* The following two variables is used to record
    loop shifting displacement */
     static int loopCenterHeight_UpperY ;
     static int loopCenterHeight_LowerY ;
     static int maxHeight;

    int curHeight = 0;
     int curLoopCenterY = 0;
     int maxLoopShift = 0; /* This variable guanrantee that our image list is a list of images which are in focus */
    ImageList* oldImage = NULL;
    ImageList* curImage = NULL;

    getLoopHeight(new_img, &curHeight, &curLoopCenterY);

    oldImage = curImage = *picHead;
    while(curImage!=NULL){
         oldImage = curImage;
           curImage = curImage->next;
    }
    curImage = (ImageList*)g_malloc(sizeof(ImageList));
    if(*picHead == NULL) {
         *picHead = curImage;
         loopCenterHeight_LowerY = loopCenterHeight_UpperY = curLoopCenterY;
         maxHeight = curHeight;
     }
    else {
         oldImage->next = curImage;
         if ( maxHeight < curHeight ) maxHeight = curHeight;
         if ( loopCenterHeight_UpperY > curLoopCenterY ) {
            loopCenterHeight_UpperY = curLoopCenterY;
         }
         else if ( loopCenterHeight_LowerY < curLoopCenterY ) {
            loopCenterHeight_LowerY = curLoopCenterY;
         }

         /* maxLoopShift will be the max(ImageHeight/4, maxHeight/2)
             where ImageHeight represents whole image height, i.e 240 pixels,
             maxHeight represents current max image height among current image list.
          */
         maxLoopShift = (int)((new_img->height)*0.25);
         maxLoopShift = (maxLoopShift > (int)(maxHeight*0.5))?maxLoopShift:(int)(maxHeight*0.5);

         if ( loopCenterHeight_LowerY - loopCenterHeight_UpperY > maxLoopShift ) {
             curHeight = -1;
         }
         LOG_INFO2("maxHeight:%d, maxLoopShift:%d\n",maxHeight,maxLoopShift); fflush(stdout);
     }
    curImage->next = NULL;
    curImage->img = new_img;
    curImage->height = curHeight;
    curImage->Index = Index;

    return curHeight;
}

/*
 * Centering Function returns bounding boxs for current loop.
 *
 * Description :
 *       Only one thing to mention here is it determine which boundingbox algorithm to use
 *       by the height ratio, larger loop height to smaller loop height. It makes sense because
 *       Algorithm one need a centain height difference between two images while the algorithm two
 *       don't have that requirement. Algorithm 1 uses one image delta width list to subtract the
 *       other image width list, which will eliminate some fixed errors or fixed part(i.e. pin base )
 *       in the image. Therefore, it seems algorithm one is more reliable than algorithm two so it keep
 *       using two algorithm here.
 *
 * Parameters :
 *      Input : MaxImg --- A loop Image with a larger height,
 *              MinImg --- A loop Image with a smaller height,
 *      Output: BigBox --- Bounding Box for MaxImg
 *              SmlBox --- Bounding Box for SmlImg
 *
 */
int
Centering(ImageList* MaxImg,
             ImageList* MinImg,
             BoundingBox* BigBox,
             BoundingBox* SmlBox)
{

   float    MaxMinRatio;
   int left,right,MinY,MaxY;
   int MaxImg_LowY,MaxImg_HighY, MinImg_LowY, MinImg_HighY;
   groupPts *Grp1,*Grp2;

   verticalScan(MaxImg->img, &MaxImg_LowY, &MaxImg_HighY);
   verticalScan(MinImg->img, &MinImg_LowY, &MinImg_HighY);

   /* Calculate Bounding Box */
   Grp1 = Grp2 = NULL;
   GetWidthList(MaxImg->img, MaxImg_LowY, MaxImg_HighY, &Grp1);
    GetWidthList(MinImg->img, MinImg_LowY, MinImg_HighY, &Grp2);

    if ( (Grp1 == NULL) || (Grp2 == NULL) ) return ERROR;

    left = right = MinY = MaxY = 0;
    if((MaxMinRatio = (float)(MaxImg->height)/(float)(MinImg->height)) >= 2.0){
         LOG_INFO1("Algorithm1:%f\n", MaxMinRatio);
         if( BoundingBox1(Grp1, Grp2, &left, &right, &MinY, &MaxY) < 0) {
                freegrp(Grp1);
                freegrp(Grp2);
                return ERROR;
          }
    }
    else{
         LOG_INFO1("Algorithm2:%f\n",MaxMinRatio);
          if( BoundingBox2(Grp1,&left, &right, &MinY, &MaxY) < 0) {
                freegrp(Grp1);
                freegrp(Grp2);
                return ERROR;
          }
  }

    /* Check Result */
    if ( MaxY - MinY < 5 ) {
    /* If the height for the Image with Max. Delta Width is less than 5 pixel, we think the result is wrong */
        LOG_INFO("Get Wrong Answer.\n");
         freegrp(Grp1);
         freegrp(Grp2);
         return ERROR;
    }

    /* Output Result */
   BigBox->UpperLeftX = left;
   BigBox->UpperLeftY = MinY;
   BigBox->LowRightX  = right;
   BigBox->LowRightY  = MaxY;

    right = Grp2->end;
    getMaxMinYbyRange(Grp2->head, left, right, &MinY, &MaxY);
   SmlBox->UpperLeftX = left;
   SmlBox->UpperLeftY = MinY;
   SmlBox->LowRightX  = right;
   SmlBox->LowRightY  = MaxY;

    freegrp(Grp1);
    freegrp(Grp2);

    return XOS_SUCCESS;
}

/* Return the specified image of specified index from the Image List
 *
 * Parameters :
 *      Input : picHead --- Image List
 *              Index   --- Index of the image that is wanted
 */
ImageList*
GetImage(ImageList* picHead,
            int index)
{
    ImageList *tmpimg = NULL;

    tmpimg = picHead;
    while(tmpimg!=NULL){
         if(tmpimg->Index == index){
            return tmpimg;
          }
          tmpimg = tmpimg->next;
    }
    return NULL;
}

bool DeltaGroupIsMicroMount( groupPts *grp , int min_diff ) {
    if (grp == NULL || grp->head == NULL) {
        LOG_WARNING( "DeltaGroupIsMicroMount called with NULL grp" );
        return false;
    }

    //1. Most of upper y should be higher than tip and most of lower y
    //   should be lower than tip.
    const float RANGE_OF_TIP_CHECK = 0.8f;
    //
    //2. Max Diff should be close to left edge.
    //
    //max height must occuer in the left 30% of image
    const float RANGE_OF_MAX_HEIGHT = 0.3f;

    //3. The ratio between curve area and right triangle should be in a range
    //   of [1, 1.5]  1.5 is from half level, half triangle.
    const double AREA_RATIO_MIN = 0.9;
    const double AREA_RATIO_MAX = 1.5;

    //4. If want to go further, use least square line fit.

    const int tip_x = grp->end;
    const double tip_y = grp->endHeight;
    LOG_INFO2( "tip: x=%d y=%lf", tip_x, tip_y );

    int x_maxUpperDiff = -1;
    int x_maxLowerDiff = -1;
    double maxUpperDiff = 0;
    double maxLowerDiff = 0;
    int xUpperStart = -1; //skip level line, especially top or bottom image edge
    int xLowerStart = -1; //skip level line, especially top or bottom image edge
    double diffUpperStart = 0;
    double diffLowerStart = 0;
    double yUpperStart = 0;
    double yLowerStart = 0;
    int xUpperFirstNegativeNeight = -1;
    int xLowerFirstNegativeNeight = -1;
    double upperArea = 0;
    double lowerArea = 0;

    deltavalue *curP = grp->head;

    for (curP = grp->head; curP != NULL; curP = curP->next) {
        int upperY = curP->lowY;
        int lowerY = curP->highY;
        //LOG_INFO3( "curP x=%d, upperY=%d, lowerY=%d",
        //curP->x, upperY, lowerY );

        if (upperY > 0) {
            double upperDiff = tip_y - upperY;
            //remember where is the max diff
            if (upperDiff > maxUpperDiff) {
                maxUpperDiff = upperDiff;
                x_maxUpperDiff = curP->x;
            }
            //remember first negative
            if (xUpperFirstNegativeNeight == -1 && upperDiff < 0) {
                xUpperFirstNegativeNeight = curP->x;
            }

            //check to start integration or not
            // it will start after curve goes down say 5 units
            if (xUpperStart < 0) {
                if (yUpperStart < upperDiff) {
                    //still going up
                    yUpperStart = upperDiff;
                }
                if (yUpperStart > upperDiff + 5) {
                    xUpperStart = curP->x;
                    diffUpperStart = upperDiff;
                    LOG_INFO2( "upper set startx to %d diff=%lf",
                    xUpperStart, diffUpperStart );
                }
            }
            if (xUpperStart >= 0) {
                upperArea += upperDiff;
                //LOG_INFO3( "upper INT. for x=%d diff=%lf a=%lf",
                //curP->x, upperDiff, upperArea );
            }
        }
        if (lowerY > 0) {
            double lowerDiff = lowerY - tip_y;
            if (lowerDiff > maxLowerDiff) {
                maxLowerDiff = lowerDiff;
                x_maxLowerDiff = curP->x;
            }
            if (xLowerFirstNegativeNeight == -1 && lowerDiff < 0) {
                xLowerFirstNegativeNeight = curP->x;
            }
            if (xLowerStart < 0) {
                if (yLowerStart < lowerDiff) {
                    yLowerStart = lowerDiff;
                }
                if (yLowerStart > lowerDiff + 5) {
                    xLowerStart = curP->x;
                    diffLowerStart = lowerDiff;
                }
            }
            if (xLowerStart >= 0) {
                lowerArea += lowerDiff;
            }
        }
    }

    bool result = true;

    //check condition 0: min_diff
    double startDiff = diffUpperStart + diffLowerStart;
    if (startDiff < min_diff) {
        LOG_WARNING3( "DeltaGroupIsMicroMount: min_diff check failed: %lf+%lf<%d",
        diffUpperStart, diffLowerStart, min_diff );
        
        result = false;
    } else {
        LOG_INFO3( "DeltaGroupIsMicroMount: min_diff %lf+%lf>=%d",
        diffUpperStart, diffLowerStart, min_diff );
    }

    //check condition 1: tip
    int xAllowedFirstBadDiff = int(grp->end * RANGE_OF_TIP_CHECK);
    if (xUpperFirstNegativeNeight >= 0 &&
    xUpperFirstNegativeNeight < xAllowedFirstBadDiff) {
        LOG_WARNING2( "upper tip check failed. first neg at %d < %d",
        xUpperFirstNegativeNeight, xAllowedFirstBadDiff);
        result = false;
    }
    if (xLowerFirstNegativeNeight >= 0 &&
    xLowerFirstNegativeNeight < xAllowedFirstBadDiff) {
        LOG_WARNING2( "lower tip check failed. first neg at %d < %d",
        xLowerFirstNegativeNeight, xAllowedFirstBadDiff);
        result = false;
    }

    //check condition 2: maxDiff location
    int xAllowedMaxDiff = int(grp->end * RANGE_OF_MAX_HEIGHT);
    LOG_INFO1( "allowed max location [0-%d", xAllowedMaxDiff);
    if (x_maxUpperDiff > xAllowedMaxDiff) {
        LOG_WARNING1( "upper maxDiff location check failed. at %d",
        x_maxUpperDiff);
        result = false;
    } else {
        LOG_INFO2( "upper maxDiff location at %d <= %d",
        x_maxUpperDiff, xAllowedMaxDiff);
    }
    if (x_maxLowerDiff > xAllowedMaxDiff) {
        LOG_WARNING2( "lower maxDiff location check failed. at %d > %d",
        x_maxLowerDiff, xAllowedMaxDiff);
        result = false;
    } else {
        LOG_INFO2( "lower maxDiff location check at %d <= %d",
        x_maxLowerDiff, xAllowedMaxDiff);
    }

    //check condition 3
    double upperTriangleArea = (tip_x - xUpperStart) * (diffUpperStart + 1) / 2.0;
    double lowerTriangleArea = (tip_x - xLowerStart) * (diffLowerStart + 1) / 2.0;

    double ratioUpper = 0;
    double ratioLower = 0;
    if (upperTriangleArea <= 0) {
        LOG_WARNING1( "upper triangle area %lf <=0", upperTriangleArea );
        result = false;
    } else {
        ratioUpper = upperArea / upperTriangleArea;
        LOG_INFO1( "upper area ratio =%lf", ratioUpper );
        if (ratioUpper < AREA_RATIO_MIN || ratioUpper > AREA_RATIO_MAX) {
            LOG_WARNING( "upper area ratio out of range" );
            result = false;
        }
    }
    if (lowerTriangleArea <= 0) {
        LOG_WARNING1( "lower triangle area %lf <=0", lowerTriangleArea );
        result = false;
    } else {
        ratioLower = lowerArea / lowerTriangleArea;
        LOG_INFO1( "lower area ratio =%lf", ratioLower );
        if (ratioLower < AREA_RATIO_MIN || ratioLower > AREA_RATIO_MAX) {
            LOG_WARNING( "lower area ratio out of range" );
            result = false;
        }
    }
    if (result) {
        LOG_INFO( "still microMount" );
    }

    //////////////////// LOG /////////////////////
    {
        FILE* ff = fopen( "isMacroMount.txt", "a" );
        if (ff) {
            char timeStamp[1024] = {0};
            time_t now = time( NULL );
            ctime_r( &now, timeStamp );

            size_t ll = strlen( timeStamp );
            if (ll > 0) {
                //replace \n to ' '
                --ll;
                timeStamp[ll] = ' ';
            }

            if (result) {
                strcat( timeStamp, "YES" );
            } else {
                strcat( timeStamp, " NO" );
            }

            fprintf( ff, "%s startDiff: %.0lf first neg (%d %d) max diff location(%d %d) area ratio (%.3lf %.3lf)\n",
            timeStamp,
            startDiff,
            xUpperFirstNegativeNeight, xLowerFirstNegativeNeight,
            x_maxUpperDiff, x_maxLowerDiff,
            ratioUpper, ratioLower
            );
            fclose( ff );
        }
    }
    //////////////////// LOG /////////////////////

    return result;
}

bool ImageIsMicroMount( BitImage *bitBuf ) {
    if (bitBuf == NULL) {
        return false;
    }
    int Img_HighY, Img_LowY;
    int scanResult = 0;

    groupPts *Grp = NULL;
    if( (scanResult = ImageIsEmpty(bitBuf)) == ERRORIMAGEISEMPTY ) {
        return false;
    }
    Img_HighY = Img_LowY = 0;
    verticalScan(bitBuf, &Img_LowY, &Img_HighY);
    LOG_INFO2("verticalScan result: %d %d", Img_LowY, Img_HighY);
    if ( Img_HighY - Img_LowY < MINWIDTH ) {
        return false;
    }

    LOG_INFO("GetWidthList");
    /* Horizontal Scan to get the Loop Tip's Position */
    GetWidthList(bitBuf, Img_LowY, Img_HighY, &Grp);

    if (Grp->end < bitBuf->unitWidth / 4) {
        LOG_WARNING1( "ImageIsMicroMount: grp too short: %d", Grp->end );
        return false;
    }

    bool result =  DeltaGroupIsMicroMount( Grp, bitBuf->height / 2 );
    
    freegrp(Grp);

    return result;
}
/* Functions Below is used for DHS to process commands from DCSS */

/*
 * Function: handle_getLoopTip
 * Return the position of the right most point of a loop.
 * Return value is written into the parameters "operationResult" in the following format
 * 1. htos_operation_completed operationHandle normal %X %Y Img_Wide Img_Height when ifaskPinPosFlag = 0
 *    or htos_operation_completed operationHandle normal %X %Y %PinPos when ifaskPinPosFlag = 1
 * 2. htos_operation_completed operationHandle errorTipNotInView +/-
 */
xos_result_t
handle_getLoopTip(CameraInfo* camera_in,
                        const char* operationHandle,
                        char* operationResult,
                        int ifaskPinPosFlag)
{
    int Img_HighY, Img_LowY, PinPos;
    int scanResult = 0;
    char debugPrefix[1024] = "getLoopTip_";

    BitImage *bitBuf    = NULL;
    xos_result_t      result;

   groupPts *Grp = NULL;
    strcat( debugPrefix, operationHandle );

   /* Get Image from Web Camera and change the color image to gray bitimage */
   if( (result =  getImageBuffer(camera_in, &bitBuf, debugPrefix)) ==  XOS_FAILURE) {
        return  XOS_FAILURE;
    }
    if (maskBitImage) {
        if (DEBUG_SAVE_FILE) {
            char fileName[1024] = {0};
            strcpy( fileName, debugPrefix );
            strcat( fileName, "_mask.pbm" );
            PnmHdr* pnmHdr;
            pnmHdr = PnmHdrNew();
            WritePBM8(pnmHdr, maskBitImage, fileName);
            PnmHdrFree(pnmHdr);
        }

        int rr = BitIntersect8( bitBuf, maskBitImage, bitBuf );
        if (rr == DVM_BIT_OK) {
            LOG_INFO( "mask applied" );
        } else {
            LOG_WARNING1( "mask apply failed: BitIntersect8 failed %d", rr );
        }
        if (DEBUG_SAVE_FILE) {
            char fileName[1024] = {0};
            strcpy( fileName, debugPrefix );
            strcat( fileName, "_afterMask.pbm" );
            PnmHdr* pnmHdr;
            pnmHdr = PnmHdrNew();
            WritePBM8(pnmHdr, bitBuf, fileName);
            PnmHdrFree(pnmHdr);
        }

    }

    LOG_INFO("ImageIsEmpty?");

   /* Decide if View is suitable for analysising */
    /* htos_operation_completed operationHandle errorTipNotInView +/- */
   if( (scanResult = ImageIsEmpty(bitBuf)) == ERRORIMAGEISEMPTY ) {
        sprintf(operationResult, "htos_operation_completed getLoopTip %s error TipNotInView +", operationHandle );
        BitFree(bitBuf);
        return XOS_SUCCESS;
    }


   /* Vertical Scan BitImage to eliminate Noise */
    LOG_INFO("verticalScan");
    Img_HighY = Img_LowY = 0;
   verticalScan(bitBuf, &Img_LowY, &Img_HighY);
    LOG_INFO2("verticalScan result: %d %d", Img_LowY, Img_HighY);

    /* Check again if the image is good enought */
    if ( Img_HighY - Img_LowY < MINWIDTH ) {
        sprintf(operationResult, "htos_operation_completed getLoopTip %s error TipNotInView +", operationHandle );
        BitFree(bitBuf);
        return XOS_SUCCESS;
    }

    LOG_INFO("GetWidthList");
    /* Horizontal Scan to get the Loop Tip's Position */
   GetWidthList(bitBuf, Img_LowY, Img_HighY, &Grp);

    /* When ifaskPinPosFlag is set, we should calculate the end pos of pin */
    PinPos = 0;
   if ( ifaskPinPosFlag > 0 ) {
        LOG_INFO("GetPinPosition");
        if ((PinPos = GetPinPosition(Grp, ifaskPinPosFlag)) < 0) {
            PinPos = 0;
            LOG_INFO("GetPinPos Operation Failed may due to Loop and Pin isn't clear engough!\n");
        }
    }


    /////////////////////////////////////////////////////
    ///////// DEBUG hook ////////////////////////////////
    bool isMicroMount = false;
    if ( ifaskPinPosFlag < 0 ) {
        if (Grp->end > bitBuf->unitWidth / 4) {
            isMicroMount =  DeltaGroupIsMicroMount( Grp, bitBuf->height / 2 );
        }
    }
    /////////////////////////////////////////////////////
    ///////// DEBUG hook ////////////////////////////////

   /* Compose the Return String */
    if ( ifaskPinPosFlag == 0 ) {
        sprintf(operationResult, "htos_operation_completed getLoopTip %s normal %f %f %d %d", operationHandle, (float)(Grp->end*2.0)/bitBuf->unitWidth, (float)(Grp->endHeight)/bitBuf->height , bitBuf->unitWidth, bitBuf->height);
    }
    else if (ifaskPinPosFlag > 0) {
        sprintf(operationResult, "htos_operation_completed getLoopTip %s normal %f %f %f", operationHandle, (float)(Grp->end*2.0)/bitBuf->unitWidth, (float)(Grp->endHeight)/bitBuf->height, (float)(PinPos*2.0)/bitBuf->unitWidth );
    } else {
        //special DEBUG
        int value = (isMicroMount) ? 1 : 0;
        sprintf(operationResult, "htos_operation_completed getLoopTip %s normal %f %f %d", operationHandle, (float)(Grp->end*2.0)/bitBuf->unitWidth, (float)(Grp->endHeight)/bitBuf->height, value );
    }

    LOG_INFO("free grp");
    freegrp(Grp);
    LOG_INFO("free bitBuf");
    BitFree(bitBuf);

    return XOS_SUCCESS;
}

/*
 * Function: handle_addImageToList
 *
 * Description :
 *       Process addImageToList message. Snap an image from camera, then use edge detection
 *       to the image buffer, finally add the bitmap from edge detection to DHS image list. After added
 *       the bitmap to DHS image list, the loop heighe is return. If the loop height is 0, it indicates
 *       current camera view is not good for loop detection. If the loop height is -1, it indicates that
 *       loop shift in Y axis is too much(exceed half height of the loop). That menas the result of centering
 *       by loop tip is not good.
 *
 * Parameters :
 *      Input : camera_in --- info. needed to connect to a camera.
 *              imgIndex  --- index for newly added image.
 *              ImgLst    --- pointed to DHS image list.
 *              operationHandle --- message handle
 *      Output:
 *              operationResult --- result string to be sent back to DCSS.
 */
xos_result_t handle_addImageToList(CameraInfo* camera_in,
                                              int imgIndex,
                                              ImageList** ImgLst ,
                                              const char* operationHandle,
                                              char* operationResult)
{
    int Img_HighY, Img_LowY;
    BitImage *bitBuf    = NULL;
    xos_result_t      result;
    int curLoopHeight = 0;
    char debugPrefix[1024] = "addImageToList_";

    strcat( debugPrefix, operationHandle );

    if (imgIndex == -1) {
        int curSave = DEBUG_SAVE_FILE;

        DEBUG_SAVE_FILE = 1;
        result =  getImageBuffer(camera_in, &bitBuf, debugPrefix);
        DEBUG_SAVE_FILE = curSave;
        if (result ==  XOS_FAILURE) {
            return  XOS_FAILURE;
        }
        if (ImageIsFlat8( bitBuf )) {
            BitFree( bitBuf );
            sprintf(operationResult,
            "htos_operation_completed addImageToList %s failed flat image",
            operationHandle );
            return XOS_SUCCESS;
        }

        //convert the invert bitBuf into mask
        {
            int row;
            int col;
            for (row = 0; row < bitBuf->height; ++row) {
                for (col = 0; col < bitBuf->parentWidth; ++col) {
                    unsigned char* p = bitBuf->firstByte +
                    row * bitBuf->parentWidth + col;
                    *p = ~(*p);
                }
            }
        }

        maskBitImage = bitBuf;

        sprintf(operationResult, "htos_operation_completed addImageToList %s normal %s", operationHandle, debugPrefix );
        return XOS_SUCCESS;
    }
    if (imgIndex == -2) {
        if (maskBitImage) {
            BitFree( maskBitImage );
            maskBitImage = NULL;
        }
        sprintf(operationResult, "htos_operation_completed addImageToList %s normal maskBitImage cleared", operationHandle );
        return XOS_SUCCESS;
    }
    if (imgIndex == -3) {
        const char fileName[] = "centerLoopMask.pgm";
        maskBitImage = readPNM8( fileName );
        if (maskBitImage && ImageIsFlat8( maskBitImage )) {
            LOG_WARNING( "mask image is flat, remove " );
            BitFree( maskBitImage );
            maskBitImage = NULL;
        }
        if (maskBitImage) {
            sprintf(operationResult, "htos_operation_completed addImageToList %s normal %s loaded into mask", operationHandle, fileName );
        } else {
            sprintf(operationResult, "htos_operation_completed addImageToList %s failed", operationHandle );
        }
        return XOS_SUCCESS;
    }

   /* Get Image from Web Camera and change the color image to gray bitimage */
   if ( (result =  getImageBuffer(camera_in, &bitBuf, debugPrefix)) ==  XOS_FAILURE) {
        return  XOS_FAILURE;
    }

    if (maskBitImage) {
        if (DEBUG_SAVE_FILE) {
            char fileName[1024] = {0};
            strcpy( fileName, debugPrefix );
            strcat( fileName, "_mask.pbm" );
            PnmHdr* pnmHdr;
            pnmHdr = PnmHdrNew();
            WritePBM8(pnmHdr, maskBitImage, fileName);
            PnmHdrFree(pnmHdr);
        }

        int rr = BitIntersect8( bitBuf, maskBitImage, bitBuf );
        if (rr == DVM_BIT_OK) {
            LOG_INFO( "mask applied" );
        } else {
            LOG_WARNING1( "mask apply failed: BitIntersect8 failed %d", rr );
        }
    }

    /* Start a new ImageList */
   if ( imgIndex == 0 ) {
        freeImageList(*ImgLst);
        *ImgLst = NULL;
    }

    /* Valid Check */
    if( ImageIsEmpty(bitBuf) == ERRORIMAGEISEMPTY ) {
        BitFree( bitBuf );
        sprintf(operationResult, "htos_operation_completed getLoopTip %s error TipNotInView +", operationHandle );
        return XOS_SUCCESS;
    }

    /* First Vertical Scan to See if Loop is out of view */

    verticalScan(bitBuf, &Img_LowY, &Img_HighY);

    /*if ( ( Img_HighY - Img_LowY + 1 ) > ( 0.95 * bitBuf->height ) ) {
        sprintf(operationResult, "htos_operation_completed addImageToList %s error ImageOutofView",  operationHandle);
        return XOS_SUCCESS;
        }*/

    LOG_INFO1("ImgIndexInAddImagetoList:%d\n",imgIndex);

    /* Get current Image View of Camera and Insert it into the ImgLst */
    curLoopHeight = InsertImageList(ImgLst, bitBuf, imgIndex);

    switch(curLoopHeight)
    {
       case 0:
            sprintf(operationResult, "htos_operation_completed addImageToList %s error NoHeightInfo", operationHandle);
            freeImageList(*ImgLst);
            *ImgLst = NULL;
            break;
       case -1:
            sprintf(operationResult, "htos_operation_completed addImageToList %s error PhaseICenterResultIsNotGood", operationHandle);
            freeImageList(*ImgLst);
            *ImgLst = NULL;
            break;
       default:
           sprintf(operationResult, "htos_operation_completed addImageToList %s normal %d %f", operationHandle, curLoopHeight, float(curLoopHeight) / bitBuf->height );
    }

    return XOS_SUCCESS;
}

/*
 * Function: handle_findBoundingBox
 *
 * Description:
 *       The function is used to process message findBoundingBox from DCSS.
 *       It firstly pick an image with max. height from the DHS image list,then calculate
 *       the position of the image which is 90 degree away from the picked image. By the two
 *       image, it determines the bounding box for current loop in the image list.
 *
 * Parameters :
 *      Input : ImgLst    --- pointed to DHS image list.
 *              operationHandle --- message handle
 *              MethodFlag --- specify how to pick images from the image list.
 *                             (Now it picks the image with global max. loop height)
 *      Output:
 *              operationResult --- result string to be sent back to DCSS.
 */
xos_result_t handle_findBoundingBox(ImageList** ImgLst,
                                                const char* operationHandle,
                                                const char* MethodFlag,
                                                char* operationResult)
{

    ImageList *MinImg, *MaxImg, *tmpImg; /*MaxImg means an image with max. loop height
                                                        *MinImg means an image with min. loop height*/

    int tmpHeight,MinHeight, MaxHeight;
    int Both_MaxIndex, Both_MinIndex;
     float ImgHeight, ImgWidth;
     BoundingBox BigBox, SmlBox;         /* BigBox stores BoundingBox for MaxImg
                                                      * SmlBox stores BoundingBox for MinImg */

    if (*ImgLst == NULL) {
       sprintf(operationResult, "htos_operation_completed findBoundingBox %s error no image list", operationHandle );
       return XOS_SUCCESS;
    }

     if (strstr(MethodFlag, "Both")) {
         /* Scan All Images to get Min and Max Loop Height */
         MinHeight = 100000;
         MaxHeight = 0;
         tmpImg = *ImgLst;
         while ( tmpImg != NULL ) {
             tmpHeight = tmpImg->height;
             if (tmpHeight > MaxHeight) {
                 MaxHeight = tmpHeight;
                 Both_MaxIndex = tmpImg->Index;
             }
             tmpImg = tmpImg->next;
         }

         /* Calculate Min. Image Index instead of global Min. Image Index*/
         if ( Both_MaxIndex + 9 > 17 ) {
             Both_MinIndex = Both_MaxIndex + 9 - 18;
         }
         else
             Both_MinIndex = Both_MaxIndex + 9;

         /* Begin Centering Process */
         MaxImg = GetImage(*ImgLst, Both_MaxIndex);
         MinImg = GetImage(*ImgLst, Both_MinIndex);
         if (Centering( MaxImg , MinImg, &BigBox, &SmlBox)< 0) {
                  sprintf(operationResult, "htos_operation_completed findBoundingBox %s error CurrentSettingsAreNotSuitableForCentering", operationHandle );
                    return XOS_SUCCESS;
         }

         /* Get img size */
         ImgWidth =  (float)MaxImg->img->unitWidth;
         ImgHeight = (float)MaxImg->img->height;

         sprintf(operationResult, "htos_operation_completed findBoundingBox %s normal %d %d %f %f %f %f %f %f %f %f", operationHandle,
                    Both_MaxIndex,
                    Both_MinIndex,
                    2.0*BigBox.UpperLeftX/ImgWidth,
                    1.0*BigBox.UpperLeftY/ImgHeight,
                    2.0*BigBox.LowRightX/ImgWidth,
                    1.0*BigBox.LowRightY/ImgHeight,
                    2.0*SmlBox.UpperLeftX/ImgWidth,
                    1.0*SmlBox.UpperLeftY/ImgHeight,
                    2.0*SmlBox.LowRightX/ImgWidth,
                    1.0*SmlBox.LowRightY/ImgHeight
                    );
     }
     else {
         xos_error(" Can't Handle specified Method in Centering Process\n");
         return XOS_FAILURE;
     }

      /* For Debug Use */
        LOG_INFO("writing out pbm with rectange");
      drawRectangle(MaxImg->img,BigBox.UpperLeftX,BigBox.LowRightX,BigBox.UpperLeftY,BigBox.LowRightY,"./log/result.pbm");
      //DumpImageList(*ImgLst,"./testData");

     /* Clean Up Memory */
     freeImageList(*ImgLst);
     *ImgLst = NULL;

     return XOS_SUCCESS;
}


/*
 * Function: handle_getPinDiameters
 * The function is mainly used by Pin ID detection.
 * Parameters:
 *        length --- specified length;
 *        number --- specified needed number of diameters.From right most of pin to left,
 *                   return diameter for each length.
 *
 * Return:
 *        Diameters of the specified length of pin in pixels
 */
xos_result_t
handle_getPinDiameters(CameraInfo* camera_in,
                              const char* operationHandle,
                              char* operationResult,
                              int length,
                              int number)
{
    int Img_HighY, Img_LowY;
    int ImgHeight, ImgLength;
    int scanResult = 0;
   BitImage *bitBuf = NULL;
    xos_result_t      result;

   groupPts *Grp = NULL;
    char debugPrefix[1024] = "getPinDiameters_";

    strcat( debugPrefix, operationHandle );


   /* Get Image from Web Camera and change the color image to gray bitimage */
   if( (result =  getImageBuffer(camera_in, &bitBuf, debugPrefix)) ==  XOS_FAILURE)
    {
        return  XOS_FAILURE;
    }
    ImgHeight = bitBuf->height;
    ImgLength = bitBuf->unitWidth;

   /* Decide if View is suitable for analysising */
    /* htos_operation_completed operationHandle errorTipNotInView +/- */
   if( (scanResult = ImageIsEmpty(bitBuf)) == ERRORIMAGEISEMPTY )
    {
        sprintf(operationResult, "htos_operation_completed getPinDiameters %s error PinNotInView +", operationHandle );
        return XOS_SUCCESS;
    }

   /* Vertical Scan BitImage to eliminate Noise */
    Img_HighY = Img_LowY = 0;
   verticalScan(bitBuf, &Img_LowY, &Img_HighY);

    /* Horizontal Scan to get the outline of pin */
   GetWidthList(bitBuf, Img_LowY, Img_HighY, &Grp);
    if (Grp == NULL ){
        sprintf(operationResult, "htos_operation_completed getPinDiameters %s error ScanDeltaWidthListRaisedError", operationHandle );
        return XOS_SUCCESS;
    }

   /* Check input number is a valid number */
    if ( (number > 8) || (number <= 0) ){
        sprintf(operationResult, "htos_operation_completed getPinDiameters %s error RequireTooManyDiametersOrNegativeNumber", operationHandle );
        return XOS_SUCCESS;
    }

    /* Check length is reasonable */
    if ( (length <= 0) || (length*number > Grp->end) ){
       sprintf(operationResult, "htos_operation_completed getPinDiameters %s error InvalidLengthParameter", operationHandle );
        return XOS_SUCCESS;
    }

    /* Begin to Calculate Diameters */
    int safegap = length/3;  /* Avoid to sample points around every step's edge */
    float* DiameterResults = (float*)g_malloc(2*number*sizeof(float));
    float SampleLowYTotal = 0.0;
    float SampleHighYTotal = 0.0;

    deltavalue *curWid;

    /* if number > 1, we will do a prepare work first to deal with pin's movement isn't horizontal */
    if ( number > 1 ) {
       int validend = 0; /* store the index of the last element of delta width list */
       int count = 0;

        /* store delata width list value for reversely scanning */
       int* lowY  = (int*)g_malloc(sizeof(int)*(Grp->end+1));
        int* highY = (int*)g_malloc(sizeof(int)*(Grp->end+1));
        float* upperY = (float*)g_malloc(sizeof(float)*number);
        float* bottumY = (float*)g_malloc(sizeof(float)*number);

        memset(lowY, 0 , (sizeof(int)*(Grp->end+1)));
        memset(highY, 0, (sizeof(int)*(Grp->end+1)));

        curWid = Grp->head;
        while( curWid != NULL ){
            if (curWid->highY - curWid->lowY > 30 ) {
               lowY[curWid->x] = curWid->lowY;
                 highY[curWid->x] = curWid->highY;
                 if ( validend < curWid->x ) validend = curWid->x;
             }
             curWid = curWid->next;
        }

        /* Roughly Get Height Distribution  */
        count = 0;
        SampleHighYTotal = SampleLowYTotal = 0.0;
        for( int i = 0; i < number ; i++ ){
           for ( int j = validend - i*length - safegap; j >= validend - (i+1)*length+safegap; j--){
              if ( lowY[j]*highY[j] > 0 ){
                 SampleLowYTotal += lowY[j];
                    SampleHighYTotal += highY[j];
                    count++;
                }
            }
            if ( count < 1 ){
               sprintf(operationResult, "htos_operation_completed getPinDiameters %s error ScanDeltaWidthListIsNotGoodForPinIDDetction", operationHandle );
                 return XOS_SUCCESS;
            }

            upperY[i] = SampleLowYTotal/count;
            bottumY[i] = SampleHighYTotal/count;
            count = 0;
            SampleHighYTotal = 0.0;
            SampleLowYTotal = 0.0;
        }

        /* Accurrately Get Heigt Distribution */
        int upperYcount = 0;
        int bottumYcount = 0;
        int curend = 0;
        int curstart = 0;
        for( int i = 0; i < number ; i++ ){
           upperYcount = 0;
            bottumYcount = 0;
            SampleHighYTotal = 0.0;
            SampleLowYTotal = 0.0;
           curend = validend - (i+1)*length - safegap;
            curend = (curend < 0)?0:curend;
            if ( i == 0 ) {
               curstart = validend;
            }
            else {
               curstart = validend - i*length + safegap;
            }

            float tmpupperY = upperY[i];
            float tmpbottumY = bottumY[i];
            /* Converge our average height */
            for(int k = 0; k <= 3; k++ ){
               for ( int j = curstart; j>=curend; j-- ){
                  if ( lowY[j]*highY[j] > 0 ){
                       if ( (lowY[j] > upperY[i] - 14) && (lowY[j] < upperY[i] + 14) ){
                          SampleLowYTotal += lowY[j];
                            upperYcount ++;
                        }
                        if ( (highY[j] > bottumY[i] - 14) && (highY[j] < bottumY[i] + 14) ){
                          SampleHighYTotal += highY[j];
                            bottumYcount ++;
                        }
                    }
                }
                if ( upperYcount > 0) tmpupperY = SampleLowYTotal/upperYcount;
                if ( bottumYcount > 0) tmpbottumY = SampleHighYTotal/bottumYcount;

                if ( (abs((int)(tmpupperY - upperY[i])) <= 1) && (abs((int)(tmpbottumY - bottumY[i])) <= 1) ){
                   upperY[i] = tmpupperY;
                    bottumY[i] = tmpbottumY;
                    break;
                }
                upperY[i] = tmpupperY;
                bottumY[i] = tmpbottumY;
            }
        }

        for ( int i = 0; i < number; i++ ) {
            DiameterResults[2*i] = upperY[i];
             DiameterResults[2*i+1] = bottumY[i];
        }

        g_free(lowY);
        g_free(highY);
        g_free(upperY);
        g_free(bottumY);
    }
    else {
       int SampleCount = 0;
        int curPos1 = Grp->end;
        int curPos2 = Grp->end;
       curWid = Grp->head;
       curPos1 -= length;
        while ( curWid != NULL ) {
           if ( (curWid->x >= (curPos1 + safegap)) && (curWid->x <= (curPos2 - safegap)) ){
              SampleLowYTotal += (curWid->lowY);
                SampleHighYTotal += (curWid->highY);
                SampleCount ++;
            }
            curWid = curWid->next;
        }
        if ( SampleCount < 2 ){
            sprintf(operationResult, "htos_operation_completed getPinDiameters %s error ScanDeltaWidthListIsNotGoodForPinIDDetction", operationHandle );
             return XOS_SUCCESS;
        }

        DiameterResults[0]   = SampleLowYTotal/(float)(SampleCount);
        DiameterResults[1] = SampleHighYTotal/(float)(SampleCount);

    }

    /* Compose Result Message */
    char *StrPos = NULL;
    sprintf(operationResult, "htos_operation_completed getPinDiameters %s normal %f %d", operationHandle, (2.0*Grp->end/ImgLength) ,number);
    for ( int j = 0; j < number ; j++ ){
       StrPos = operationResult + strlen(operationResult);
        sprintf(StrPos, " %f %f", (1.0*DiameterResults[2*j]/ImgHeight), (1.0*DiameterResults[2*j+1]/ImgHeight));
    }

    g_free(DiameterResults);
    freegrp(Grp);
    BitFree(bitBuf);

    return XOS_SUCCESS;
}

/* copied from dali example */
BitImage* readPNM8( const char* fileName ) {
    FILE* f;
    BitStream* inbs;
    BitParser* inbp;
    PnmHdr*    hdr;
    BitImage*  r;
    int w;
    int h;
    int t;
    struct stat f_stat;

    LOG_INFO1( "readPNM8: %s", fileName );

    if (stat( fileName, &f_stat )) {
        LOG_WARNING1( "readPNM8 failed to stat file %s", fileName );
        return NULL;
    }

    LOG_INFO1( "filesize: %lu", f_stat.st_size );
    f = fopen( fileName, "r" );
    if (f == NULL) {
        LOG_WARNING1( "readPNM8 failed to open file %s", fileName );
        return NULL;
    }

    hdr = PnmHdrNew( );
    inbs = BitStreamNew( f_stat.st_size );
    inbp = BitParserNew( );
    BitParserWrap( inbp, inbs);
    int byteRead = BitStreamFileRead( inbs, f, 0 );
    LOG_INFO1( "byteRead: %d", byteRead );
    fclose( f );
    int total = PnmHdrParse( inbp, hdr );
    LOG_INFO1( "PnmHdrParse returned %d", total );
    if (total <= 0) {
        LOG_WARNING( "PnmHdrParse failed" );
        BitParserFree( inbp );
        BitStreamFree( inbs );
        PnmHdrFree( hdr );
        return NULL;
    }

    w = PnmHdrGetWidth( hdr );
    h = PnmHdrGetHeight( hdr );
    t = PnmHdrGetType( hdr );

    LOG_INFO3( "w=%d h=%d t=%d", w, h, t );


    r = BitNew( w, h );
    if (r == NULL) {
        LOG_WARNING( "BitNww failed" );
        BitParserFree( inbp );
        BitStreamFree( inbs );
        PnmHdrFree( hdr );
        return NULL;
    }

    int rr;
    int failed = 0;

    switch (t) {
    case PBM_TEXT:
    case PBM_BIN:
        LOG_INFO1( "file is PBM w=%d", w);
        if (w % 8) {
            rr = PbmParse( inbp, r );
        } else {
            rr = PbmParse8( inbp, r );
        }
        if (rr <= 0) {
            LOG_WARNING1( "PbmParse failed: %d", rr );
            failed = 1;
        }
        break;

    case PGM_TEXT:
    case PGM_BIN:
        {
            LOG_INFO( "file is PGM");
            ByteImage* tempImg = ByteNew( w, h );
            if (tempImg == NULL) {
                LOG_WARNING( "ReadPNM8 ByteNew failed" );
                failed = 1;
            }
            if (!failed) {
                rr = PgmParse( inbp, tempImg );
                if (rr <=0) {
                    LOG_WARNING1( "PgmParse failed: %d", rr );
                    failed = 1;
                }
            }
            if (!failed) {
                if (ImageIsFlatByte( tempImg )) {
                    LOG_WARNING( "flat pgm file" );
                    failed = 1;
                }
            }
            if (!failed) {
                rr = BitMakeFromThreshold8( tempImg, r, 254, 0 );
                if (rr) {
                    LOG_WARNING1( "BitMakeFromThreshold8 failed: %d", rr );
                    failed = 1;
                }
            }
            if (tempImg) ByteFree(tempImg);
        }
        break;

    default:
        LOG_WARNING1( "unsupported image type=%d", t );
        failed = 1;
    }

    BitParserFree( inbp );
    BitStreamFree( inbs );
    PnmHdrFree( hdr );

    if (!failed) {
        return r;
    } else {
        BitFree( r );
        return NULL;
    }
}
