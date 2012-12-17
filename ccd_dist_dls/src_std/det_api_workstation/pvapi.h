/***************************************************************************
*                                                                          *
*    FILE:           pvapi.h                                               *
*    DESCRIPTION:    External interface definition for PVAPI.DLL.          *
*                                                                          *
***************************************************************************/

#ifndef __PVAPI_H__
#define __PVAPI_H__

#ifdef __cplusplus
/* This prevents name mangling when we are being called from C++*/
extern "C" {
#endif

/* Define the data structures used internally in the DLL*/

/* SetOp structure used to retrieve options*/
typedef struct _SETOP
{
   ULONG sFrameWidth;
   ULONG sFrameHeight;     
   ULONG sPixelDepth;
   ULONG sTimeout;
   ULONG sChannels;
   UCHAR BoardNumber;
} SETOP;
typedef SETOP * LPSETOP;

/* FrameAddress structure used to retrieve frame information for a given board.*/
typedef struct _FRAMEADDRESS
{
   ULONG RetVal;              /* Return value - 0 if address valid*/
   ULONG LinearAddress;       /* Frame linear address*/
   ULONG PhysicalAddress;     /* Frame physical address*/
   ULONG MemSize;
   ULONG DoneFlagPtr;         /* Pointer to done flag*/
} FRAMEADDRESS, *PFRAMEADDRESS, *LPFRAMEADDRESS;

/* PVFRAME structure used with pvCaptureFrameSequence*/
typedef struct _PVFRAME
{
   int               nStructSize;
   unsigned long     ulTimeStampLo;
   unsigned long     ulTimeStampHi;
   int               nFrameComplete;
   unsigned short   *pFrameData;
} PVFRAME;

/* Used with pvGetDeviceInfoEx*/
typedef struct _DEVICEINFO
{
   ULONG    dwSize;
   USHORT   wDeviceID;
   UCHAR    byRevisionID;
   UCHAR    byBoardID;
   USHORT   wSubsysVendorID;
   USHORT   wSubsysDeviceID;
   ULONG    ulLineBufferSize;
   ULONG    ulNumChannels;
   ULONG    ulHWCaps;
   ULONG    ulBoardSpeed;
} DEVICEINFO, * PDEVICEINFO;

typedef struct _CAPSTATS
{
   ULONG    dwSize;
   ULONG    dwNumFrames;
   ULONG    dwLinesSkipped;
   ULONG    dwFramesMissed;
   ULONG    dwChannelsMissed;
   ULONG    ulLastError;
} CAPSTATS, * PCAPSTATS;

/* SCRAMBLE_FORMAT structure*/
typedef struct _SCRAMBLE_FORMAT
{
   ULONG sSize;
   int   sCameraType;
   ULONG sFrameWidth;
   ULONG sFrameHeight;     
   ULONG sPixelDepth;
   int   sChannels;
   ULONG sOrientation;
   ULONG sFlags;
   PVOID *sLuts;     /* a pointer to an array of size sChannels, */
                     /* of sPixelDepth-sPixelDepth LUTs*/
                     /* if channel X requires no LUT then sLUT[X] = NULL is ok*/
                     /* if no LUTs at all are required, sLUT = NULL is ok*/
} SCRAMBLE_FORMAT;
typedef SCRAMBLE_FORMAT * PSCRAMBLE_FORMAT;


/* Define error return codes*/
#define SUCCESS                        0
#define GENERIC_ERROR                  -1
#define ERROR_IO_ADDRESS_BAD           -2
#define ERROR_BOARD_NOT_WORKING        -3
#define ERROR_SERIAL_LINK_BAD          -4
#define ERROR_CAPTURE_TIME_OUT         -5
#define ERROR_MEMORY_ALLOCATION_FAILED -6
#define ERROR_INVALID_BOARDID          -7
#define ERROR_NOT_ENOUGH_MEM           -8
#define ERROR_NO_DRIVER                -9
#define ERROR_INVALID_CHANNEL          -10
#define ERROR_BAD_PARAMETER            -11
#define ERROR_BUSY_CAPTURING           -12
#define ERROR_REGISTRY                 -13
#define ERROR_SERIAL_INPUT_LINK_BAD    -14
#define ERROR_SERIAL_NO_ACK            -15
#define ERROR_CANT_OPEN_PORT           -16
#define ERROR_BAD_CAMERA_TYPE          -17
#define ERROR_SERIAL_NO_RESPONSE       -18
#define ERROR_SERIAL_BAD_RESPONSE      -19
#define ERROR_SERIAL_WRITE_ERROR       -20
#define ERROR_SERIAL_READ_ERROR        -21
#define ERROR_SERIAL_CANT_OPEN_PORT    -22
#define ERROR_SERIAL_PORT_INIT_ERROR   -23
#define ERROR_NO_MORE_CHANNELS         -24
#define ERROR_NOT_CAPTURING            -25
#define ERROR_CAPTURE_CANCELED         -26
#define ERROR_INVALID_ORIENTATION      -27
#define ERROR_NOT_INITIALIZED          -28
#define ERROR_BAD_CAMERA               -29
#define ERROR_NOT_ENOUGH_RAM           -30
#define ERROR_INVALID_BINNING          -31
#define ERROR_INVALID_INTERRUPT_MODE   -32

#ifndef VPVIEW_DRIVER

/* Define the functions*/
int   WINAPI pvAllocateFrameBuffer(BYTE byBoardNum);
int   WINAPI pvFreeFrameBuffer(BYTE byBoardNum);
int   WINAPI pvGetFrameAddress(BYTE byBoardNum,LPFRAMEADDRESS);

int   WINAPI pvCaptureFrame(BYTE  byBoardNum,
                            DWORD hWindow,
                            DWORD dwMsg,
                            DWORD bUseBoolPtr,
                            DWORD dwPhysAddr,
                            DWORD dwLinaddr);

int   WINAPI pvInitCapture(BYTE byBoardNum);

int   WINAPI pvSetOptions(BYTE    byBoardNum,
                          DWORD   dwWidth, 
                          DWORD   dwHeight, 
                          DWORD   dwPixelDepth, 
                          DWORD   dwTimeOut,
                          DWORD   dwChannels);

int WINAPI pvUnScrambleFrames(PVOID pSource,
                          PVOID pDest,
                          PSCRAMBLE_FORMAT pFormat,
                          int nNumFrames);

int   WINAPI pvGetOptions(BYTE byBoardNum, LPSETOP lpOpts);
HANDLE WINAPI pvGetFrameEvent(BYTE byBoardNum);
int   WINAPI pvReturnVersion(LPSTR lpVersion);
DWORD WINAPI pvGetBoardID(BYTE byBoardNum);
int   WINAPI pvSendSerialCommand(BYTE byBoardNum, BYTE byCommand, WORD wData, BOOL bWaitForAck);
int   WINAPI pvSendMailboxBytes(BYTE byBoardNum, BYTE *pData, WORD wNumBytes );
int   WINAPI pvAcquireFrame(BYTE byBoardNum, void *pFrameBuf);
int   WINAPI pvDisableROI(BYTE byBoardNum); 

int   WINAPI pvEnableMultipleROI(BYTE      byBoardNum,
                                 WORD      wNumRegions,
                                 WORD      wLeft,
                                 WORD      wRight,
                                 WORD     *pOffsets,
                                 WORD     *pHeights,
                                 BOOL      bBinROI);

int WINAPI pvEnableMultiChannelROI(BYTE   byBoardNum,
                                   WORD   wNumChannels,
                                   WORD	 *pLefts,
                                   WORD	 *pRights,
                                   WORD  *pBottoms,
                                   WORD  *pTops);

int   WINAPI pvEnableSingleROI(BYTE byBoardNum, WORD wX1, WORD wY1, WORD wX2, WORD wY2);
int   WINAPI pvGetDeviceDriverVersionString(LPSTR lpVersion, int nMaxChars);
int   WINAPI pvGetDLLVersionString(LPSTR lpVersion, int nMaxChars);
int   WINAPI pvSetCCDTemperatureCalibrated(BYTE byBoardNum, double dTemp);
int   WINAPI pvSetCCDTemperatureRaw(BYTE byBoardNum, BYTE byTemp);
int   WINAPI pvSetErrorMode(UINT nErrorMode);
int   WINAPI pvSetExposureMode(BYTE byBoardNum, UINT nExposureMode, double dExposureTime);
int   WINAPI pvGetExposureMode(BYTE byBoardNum, UINT *pnExposureMode, double *pdExposureTime);
int WINAPI pvSetWaitTimes(BYTE     byBoardNum,
                          double   dMasterClock,
                          double   dDiskingWait,
                          double   dParallelWait,
                          double   dAfterExposureWait,
                          double   dPixPeriod,
                          double   dFlushPixPeriod);
int WINAPI pvSetWaitConstants(BYTE byBoardNum,
                              WORD wMasterClock,
                              WORD wDiskingWait,
                              WORD wParallelWait,
                              WORD wAfterExposureWait,
                              WORD wSerialWait,
                              WORD wFlushSerialWait);

int   WINAPI pvSetXBinning(BYTE byBoardNum, WORD wPixelsBinned);
int   WINAPI pvSetYBinning(BYTE byBoardNum, WORD wPixelsBinned);

int   WINAPI pvGetCCDSize(BYTE byBoardNum, int *nWidth, int *nHeight);
int   WINAPI pvSetCCDSize(BYTE byBoardNum, int nWidth, int nHeight);

int   WINAPI pvSetPROMPage(BYTE byBoardNum, int nPage);

int   WINAPI pvCaptureFrameEx( BYTE    byBoardNum,
                               HANDLE *hEvent,
                               BOOL    bContinuous,
                               BYTE    byInterruptMode,
                               BYTE    byNumFrames, 
                               DWORD   dwPhysAddr,
                               DWORD   dwLinAddr);

int   WINAPI pvCaptureFrameWithTimeStamp( BYTE    byBoardNum,
                                          HANDLE *hEvent,
                                          BOOL    bContinuous,
                                          BYTE    byInterruptMode,
                                          BYTE    byNumFrames, 
                                          DWORD   dwPhysAddr,
                                          DWORD   dwLinAddr,
                                          DWORD  *pTimeStampLo,
                                          DWORD  *pTimeStampHi );

DWORD WINAPI pvGetFrameOrientation(BYTE byBoardNum);
int   WINAPI pvSetFrameOrientation( BYTE byBoardNum, DWORD dwFrameOrientation );

int   WINAPI pvSet8BitBalanceLUT( BYTE byBoardNum, BYTE byChannel, PBYTE pLUT );
int   WINAPI pvSet16BitBalanceLUT( BYTE byBoardNum, BYTE byChannel, PWORD pLUT );
int   WINAPI pvSetAdvancedLUT( ULONG ulBoardNum, ULONG ulChannel, PVOID pLUT, ULONG ulFlags );

int   WINAPI pvSetGain( BYTE byBoardNum, BYTE byGainMode );
int   WINAPI pvSetBandwidth( BYTE byBoardNum, BYTE byBandwidth );
int   WINAPI pvSetNumI2MRows( BYTE byBoardNum, WORD wNumI2MRows );
int   WINAPI pvSetNumLeadInPixels( BYTE byBoardNum, WORD wNumLeadInPixels );
int   WINAPI pvCancelCapture( BYTE byBoardNum );
int   WINAPI pvCancelCaptureWithTimeStamp( BYTE byBoardNum, __int64 *pTime );
int   WINAPI pvCancelNextFrame( BYTE byBoardNum );
int   WINAPI pvSetPortName( BYTE byBoardNum, LPCSTR szPortName );
int   WINAPI pvSetPortNumber( BYTE byBoardNum, BYTE byPortNum );
int   WINAPI pvUseLibrary( BYTE byBoardNum, LPCSTR szLibName );
int   WINAPI pvUseLibraryEx( BYTE byBoardNum, LPCSTR szLibName, BOOL bUpload );
int   WINAPI pvSendSerialCommandEx( BYTE byBoardNum, BYTE byCommand, WORD wData, BOOL bWaitForAck );
int   WINAPI pvLockMemory( PVOID pMem, DWORD dwSize );
int   WINAPI pvUnlockMemory( PVOID pMem, DWORD dwSize );

int   WINAPI pvGetDeviceInfo( BYTE byBoardNum, WORD *pDeviceID, BYTE *pRevisionID, BYTE *pBoardID );
int   WINAPI pvGetDeviceInfoEx( ULONG uBoardNum, 
							   PDEVICEINFO pDevInfo );

int WINAPI pvCaptureFrameToPhysicalAddr( ULONG      ulBoardNum,
                             HANDLE   *hEvent,
                             ULONG     ulFlags,
                             ULONG     pPhysAddr,
							 PVOID     pKrnlAddr);

int WINAPI pvCaptureToBuffer( ULONG ulBoardNum,
							 HANDLE *hEvent,
							 ULONG   ulFlags,
							 int     nNumFrames, 
							 PVOID	pBuffer,
							 int ulLineIncrement,
							 __int64 *pTimeStamp);

int WINAPI pvCaptureToBufferEx( ULONG ulBoardNum,
							 HANDLE *hEvent,
							 ULONG   ulFlags,
							 int     nNumFrames, 
							 PVOID	pBuffer,
							 PVOID	pBufferDirect,
							 int ulLineIncrement,
							 __int64 *pTimeStamp);

int WINAPI pvCaptureMultiToBuffer( PULONG   pulBoardIds,
                                   HANDLE  *hEvent,
                                   ULONG    ulFlags,
                                   int      nNumFrames, 
                                   PUCHAR   pBuffer,
                                   PVOID    pReserved,
                                   __int64 *pTimeStamp);

int   WINAPI pvSetAnalogGainAndOffset( BYTE byBoardNum, 
                                       BYTE byChannel, 
                                       WORD wAnalogGain, 
                                       WORD wAnalogOffset );

int	WINAPI pvGetImageSize(BYTE byBoardNum, int *pnWidth, int *pnHeight);

#ifdef _PVGENESIS
int WINAPI pvSetOffsetFrame( LPCSTR szFile );
int WINAPI pvSetGainFrame( LPCSTR szFile );
int WINAPI pvStartStreamToVideo();
int WINAPI pvStopStreamToVideo();
int WINAPI pvAutoContrast( int nMode );
int WINAPI pvVideoConvolve( int nFunc );
int WINAPI pvVideoAccumulate( BOOL bEnable );
int WINAPI pvVideoErode( BOOL bEnable );
int WINAPI pvVideoDilate( BOOL bEnable );
int WINAPI pvVideoWarp( int nWarpFunc );
int WINAPI pvVideoSpin( BOOL bEnable );
int WINAPI pvVideoSineWarp( BOOL bEnable );
int WINAPI pvVideoBinarize( int nLow, int nHigh, int nCondition, int nVal1, int nVal2 );
int WINAPI pvVideoSubtractImage( LPCSTR szImageFile );

/* Auto contrast information*/
#define PV_AC_NONE         0
#define PV_AC_ONCE         1
#define PV_AC_CONTINUOUS   2

/* pvVideoConvolve functions*/
#define IM_SMOOTH          0x40000080
#define IM_LAPLACIAN_EDGE  0x40000081
#define IM_LAPLACIAN_EDGE2 0x40000082
#define IM_SHARPEN         0x40000083
#define IM_SHARPEN2        0x40000084
#define IM_HORIZ_EDGE      0x40000085
#define IM_VERT_EDGE       0x40000086
#define IM_SOBEL_EDGE      0x40000087
#define IM_PREWITT_EDGE    0x40000088
#define IM_ROBERTS_EDGE    0x40000089

/* pvVideoBinarize constants*/
#define IM_CLEAR_OPERATION  0
#define IM_IN_RANGE         1
#define IM_OUT_RANGE        2
#define IM_EQUAL            3
#define IM_NOT_EQUAL        4
#define IM_GREATER          5
#define IM_LESS             6
#define IM_GREATER_OR_EQUAL 7
#define IM_LESS_OR_EQUAL    8

#endif  /* _PVGENESIS*/

/* Diagnostics*/
void  WINAPI pvTrace(LPCSTR lpTraceMsg);
void  WINAPI pvEnableTrace(BOOL bEnable);
int WINAPI pvGetCaptureStats( BYTE  byBoardNum, BOOL bReset, PCAPSTATS cap);

/* Functions specific to the ADAPT3 camera*/
int   WINAPI pvCaptureFrameSequence( BYTE       byBoardNum, 
                                     int        nNumFrames, 
                                     PVFRAME   *pFrameArray,
                                     DWORD      dwFlags);
int   WINAPI pvSetShutterMode( BYTE byBoardNum, BYTE byMode );

/* Function specific to the Hydra camera*/
int   WINAPI pvSetMultipleExposureTimes( BYTE    byBoardNum,
                                         UINT    nExposureMode,
                                         BYTE    byNumTimes,
                                         double *dExpStartTimes,
                                         double *dExpEndTimes );

#endif /* undefined VPVIEW_DRIVER*/

/* Number of possible boards*/
#define MAX_BOARDS         4

/* Gain definitions*/
#define PV_HI_GAIN         -1
#define PV_LO_GAIN         -2
#define MAX_PAGES          9

/* Error modes*/
#define PV_EM_SILENT       0
#define PV_EM_MESSAGE      1
#define PV_EM_LOG          2

/* Old exposure modes - provided for backward compatibility only*/
#define PV_XM_EXTERNAL     0
#define PV_XM_INTERNAL     1
#define PV_XM_VIDEO        2

/* New exposure modes*/
#define PV_XM_EXT_TRIGGER        0
#define PV_XM_SOFT_TRIGGER       1
#define PV_XM_INT_TRIGGER        2
#define PV_XM_EXT_GATE           3
#define PV_XM_DELAYED_ENABLE     0x8000      /* Bit flag*/

/* Interrupt modes*/
#define PV_FRAMEINT        0
#define PV_LINEINT         1
#define PV_ADAPTINT        2
#define PV_CHANNELINT      3

/* Camera types*/
#define PV_CAM_SVFULL      0
#define PV_CAM_SVXFER      1
#define PV_CAM_PLUTO12     2
#define PV_CAM_PLUTO14     3
#define PV_CAM_ADAPT       4
#define PV_CAM_HYDRA       5
#define PV_CAM_FASTONE     6

/* Bandwidth*/
#define PV_BW_HIGH         1
#define PV_BW_LOW          0

/* Parallel speeds*/
#define PV_FAST_PARALLEL   1
#define PV_SLOW_PARALLEL   0
#define PV_VAR_PARALLEL    2

/* Serial speeds*/
#define PV_FAST_SERIAL     1
#define PV_SLOW_SERIAL     0
#define PV_VAR_SERIAL      2

/* Capture frame sequence flags*/
#define PV_CFS_PRELOCK        0x00000001
#define PV_CFS_PRELOCKBLOCK   0x00000002
#define PV_CFS_INTERNALTRIG   0x00000004

/* CaptureToBuffer flags*/
#define PV_INTERRUPT_FLAGS    0x0000000F
#define PV_NOMEMINCREMENT     0x00000010
#define PV_NO_EXPOSURE        0x00000080
#define PV_16_to_8            0x00000800
#define PV_TIMESTAMPS_BEFORE_FRAMES         0x00002000
#define PV_SIGNAL_ON_N_FRAMES 0x00004000
#define PV_CAPTURE_CONTINUOUS 0x00008000
#define PV_ALL_TIMESTAMPS_BEFORE_FRAMES     0x00010000
#define PV_TIMESTAMPS_BEFORE_TO_BETWEEN     0x00020000

/* Shutter modes*/
#define PV_SHUTTER_TIMED   0
#define PV_SHUTTER_CLOSED  1
#define PV_SHUTTER_OPEN    2

/* ROI modes*/
#define     PV_ROI_NONE          0
#define     PV_ROI_SINGLE        1
#define     PV_ROI_MULTI         2
#define     PV_ROI_MULTI_CHANNEL 3

/* One by one non-flipped non-shifted frame*/
#define DEF_FRAME_ORIENTATION 0x00110000

#define FRAME_GROUPING        0x80000000
#define CHANNEL_HORZ_FLIP     0x00000001 
#define CHANNEL_VERT_FLIP     0x00000100 
#define FRAME_WIDTH_MASK      0x000F0000
#define FRAME_WIDTH_SHIFT     16
#define FRAME_HEIGHT_MASK     0x00F00000
#define FRAME_HEIGHT_SHIFT    20
#define CHANNEL_SHIFT_MASK    0x0F000000
#define CHANNEL_SHIFT_SHIFT   24

/* define some SetBufferedLUT flags*/
#define PV_SBLUT_DISABLE_ALL  0x00000000
#define PV_SBLUT_16_to_16     0x00000001
#define PV_SBLUT_8_to_8       0x00000002
#define PV_SBLUT_16_to_8      0x00000003

/* Hardware Capabilities flags*/
#define PV_CAP_HW_FLIP        0x00000001
#define PV_CAP_HW_LUT         0x00000002
#define PV_CAP_HW_CAMERA      0x00000004

/* Board device types*/
#define PV_LYNX_ID         0x4750
#define PV_LYNX_S_ID       0x8163
#define PV_LION_ID         0x2071
#define PV_LION_M_ID       0x2131

#ifdef __cplusplus
/* This closes out the earlier extern C block*/
}
#endif

#endif /* __PVAPI_H__*/
