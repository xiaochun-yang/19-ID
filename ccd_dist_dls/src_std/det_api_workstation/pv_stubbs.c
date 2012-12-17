#include	"defs.h"

#ifdef	unix

void	notify_pvcall(char *s)
  {
  	fprintf(stderr,"notify_pvcall: emulated pv function: %s called\n", s);
  }

/***************************************************************************
*                                                                          *
*	Emulations for pvapi routines.
*                                                                          *
***************************************************************************/

int   WINAPI pvAllocateFrameBuffer(BYTE byBoardNum)
  {
  	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvFreeFrameBuffer(BYTE byBoardNum)
  {
  	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvGetFrameAddress(BYTE byBoardNum,LPFRAMEADDRESS s)
  {
  	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvCaptureFrame(BYTE  byBoardNum,
                            DWORD hWindow,
                            DWORD dwMsg,
                            DWORD bUseBoolPtr,
                            DWORD dwPhysAddr,
                            DWORD dwLinaddr)
			      {
			      	notify_pvcall("f");
				return(0);
			  }

int   WINAPI pvInitCapture(BYTE byBoardNum)
  {
  	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSetOptions(BYTE    byBoardNum,
                          DWORD   dwWidth, 
                          DWORD   dwHeight, 
                          DWORD   dwPixelDepth, 
                          DWORD   dwTimeOut,
                          DWORD   dwChannels)
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvUnScrambleFrames(PVOID pSource,
                          PVOID pDest,
                          PSCRAMBLE_FORMAT pFormat,
                          int nNumFrames)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvGetOptions(BYTE byBoardNum, LPSETOP lpOpts)
  {
	notify_pvcall("f");
	return(0);
  }
HANDLE WINAPI pvGetFrameEvent(BYTE byBoardNum)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvReturnVersion(LPSTR lpVersion)
  {
	notify_pvcall("f");
	return(0);
  }
DWORD WINAPI pvGetBoardID(BYTE byBoardNum)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSendSerialCommand(BYTE byBoardNum, BYTE byCommand, WORD wData, BOOL bWaitForAck)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSendMailboxBytes(BYTE byBoardNum, BYTE *pData, WORD wNumBytes )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvAcquireFrame(BYTE byBoardNum, void *pFrameBuf)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvDisableROI(BYTE byBoardNum)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvEnableMultipleROI(BYTE      byBoardNum,
                                 WORD      wNumRegions,
                                 WORD      wLeft,
                                 WORD      wRight,
                                 WORD     *pOffsets,
                                 WORD     *pHeights,
                                 BOOL      bBinROI)
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvEnableMultiChannelROI(BYTE   byBoardNum,
                                   WORD   wNumChannels,
                                   WORD	 *pLefts,
                                   WORD	 *pRights,
                                   WORD  *pBottoms,
                                   WORD  *pTops)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvEnableSingleROI(BYTE byBoardNum, WORD wX1, WORD wY1, WORD wX2, WORD wY2)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvGetDeviceDriverVersionString(LPSTR lpVersion, int nMaxChars)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvGetDLLVersionString(LPSTR lpVersion, int nMaxChars)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetCCDTemperatureCalibrated(BYTE byBoardNum, double dTemp)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetCCDTemperatureRaw(BYTE byBoardNum, BYTE byTemp)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetErrorMode(UINT nErrorMode)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetExposureMode(BYTE byBoardNum, UINT nExposureMode, double dExposureTime)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvGetExposureMode(BYTE byBoardNum, UINT *pnExposureMode, double *pdExposureTime)
  {
	notify_pvcall("f");
	return(0);
  }
int WINAPI pvSetWaitTimes(BYTE     byBoardNum,
                          double   dMasterClock,
                          double   dDiskingWait,
                          double   dParallelWait,
                          double   dAfterExposureWait,
                          double   dPixPeriod,
                          double   dFlushPixPeriod)
  {
	notify_pvcall("f");
	return(0);
  }
int WINAPI pvSetWaitConstants(BYTE byBoardNum,
                              WORD wMasterClock,
                              WORD wDiskingWait,
                              WORD wParallelWait,
                              WORD wAfterExposureWait,
                              WORD wSerialWait,
                              WORD wFlushSerialWait)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSetXBinning(BYTE byBoardNum, WORD wPixelsBinned)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetYBinning(BYTE byBoardNum, WORD wPixelsBinned)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvGetCCDSize(BYTE byBoardNum, int *nWidth, int *nHeight)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetCCDSize(BYTE byBoardNum, int nWidth, int nHeight)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSetPROMPage(BYTE byBoardNum, int nPage)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvCaptureFrameEx( BYTE    byBoardNum,
                               HANDLE *hEvent,
                               BOOL    bContinuous,
                               BYTE    byInterruptMode,
                               BYTE    byNumFrames, 
                               DWORD   dwPhysAddr,
                               DWORD   dwLinAddr)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvCaptureFrameWithTimeStamp( BYTE    byBoardNum,
                                          HANDLE *hEvent,
                                          BOOL    bContinuous,
                                          BYTE    byInterruptMode,
                                          BYTE    byNumFrames, 
                                          DWORD   dwPhysAddr,
                                          DWORD   dwLinAddr,
                                          DWORD  *pTimeStampLo,
                                          DWORD  *pTimeStampHi )
  {
	notify_pvcall("f");
	return(0);
  }

DWORD WINAPI pvGetFrameOrientation(BYTE byBoardNum)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetFrameOrientation( BYTE byBoardNum, DWORD dwFrameOrientation )
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSet8BitBalanceLUT( BYTE byBoardNum, BYTE byChannel, PBYTE pLUT )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSet16BitBalanceLUT( BYTE byBoardNum, BYTE byChannel, PWORD pLUT )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetAdvancedLUT( ULONG ulBoardNum, ULONG ulChannel, PVOID pLUT, ULONG ulFlags )
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSetGain( BYTE byBoardNum, BYTE byGainMode )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetBandwidth( BYTE byBoardNum, BYTE byBandwidth )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetNumI2MRows( BYTE byBoardNum, WORD wNumI2MRows )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetNumLeadInPixels( BYTE byBoardNum, WORD wNumLeadInPixels )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvCancelCapture( BYTE byBoardNum )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvCancelCaptureWithTimeStamp( BYTE byBoardNum, __int64 *pTime )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvCancelNextFrame( BYTE byBoardNum )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetPortName( BYTE byBoardNum, LPCSTR szPortName )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetPortNumber( BYTE byBoardNum, BYTE byPortNum )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvUseLibrary( BYTE byBoardNum, LPCSTR szLibName )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvUseLibraryEx( BYTE byBoardNum, LPCSTR szLibName, BOOL bUpload )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSendSerialCommandEx( BYTE byBoardNum, BYTE byCommand, WORD wData, BOOL bWaitForAck )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvLockMemory( PVOID pMem, DWORD dwSize )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvUnlockMemory( PVOID pMem, DWORD dwSize )
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvGetDeviceInfo( BYTE byBoardNum, WORD *pDeviceID, BYTE *pRevisionID, BYTE *pBoardID )
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvGetDeviceInfoEx( ULONG uBoardNum, 
							   PDEVICEINFO pDevInfo )
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvCaptureFrameToPhysicalAddr( ULONG      ulBoardNum,
                             HANDLE   *hEvent,
                             ULONG     ulFlags,
                             ULONG     pPhysAddr,
							 PVOID     pKrnlAddr)
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvCaptureToBuffer( ULONG ulBoardNum,
							 HANDLE *hEvent,
							 ULONG   ulFlags,
							 int     nNumFrames, 
							 PVOID	pBuffer,
							 int ulLineIncrement,
							 __int64 *pTimeStamp)
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvCaptureToBufferEx( ULONG ulBoardNum,
							 HANDLE *hEvent,
							 ULONG   ulFlags,
							 int     nNumFrames, 
							 PVOID	pBuffer,
							 PVOID	pBufferDirect,
							 int ulLineIncrement,
							 __int64 *pTimeStamp)
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvCaptureMultiToBuffer( PULONG   pulBoardIds,
                                   HANDLE  *hEvent,
                                   ULONG    ulFlags,
                                   int      nNumFrames, 
                                   PUCHAR   pBuffer,
                                   PVOID    pReserved,
                                   __int64 *pTimeStamp)
  {
	notify_pvcall("f");
	return(0);
  }

int   WINAPI pvSetAnalogGainAndOffset( BYTE byBoardNum, 
                                       BYTE byChannel, 
                                       WORD wAnalogGain, 
                                       WORD wAnalogOffset )
  {
	notify_pvcall("f");
	return(0);
  }

int	WINAPI pvGetImageSize(BYTE byBoardNum, int *pnWidth, int *pnHeight);

/* Diagnostics*/
void  WINAPI pvTrace(LPCSTR lpTraceMsg)
  {
	notify_pvcall("f");
  }
void  WINAPI pvEnableTrace(BOOL bEnable)
  {
	notify_pvcall("f");
  }
int WINAPI pvGetCaptureStats( BYTE  byBoardNum, BOOL bReset, PCAPSTATS cap)
  {
	notify_pvcall("f");
	return(0);
  }

/* Functions specific to the ADAPT3 camera*/
int   WINAPI pvCaptureFrameSequence( BYTE       byBoardNum, 
                                     int        nNumFrames, 
                                     PVFRAME   *pFrameArray,
                                     DWORD      dwFlags)
  {
	notify_pvcall("f");
	return(0);
  }
int   WINAPI pvSetShutterMode( BYTE byBoardNum, BYTE byMode )
  {
	notify_pvcall("f");
	return(0);
  }

/* Function specific to the Hydra camera*/
int   WINAPI pvSetMultipleExposureTimes( BYTE    byBoardNum,
                                         UINT    nExposureMode,
                                         BYTE    byNumTimes,
                                         double *dExpStartTimes,
                                         double *dExpEndTimes )
  {
	notify_pvcall("f");
	return(0);
  }

int WINAPI pvWriteBoardIO( BYTE  byBoardNum,
                            DWORD dwOffset,
                            DWORD dwData)
  {
	notify_pvcall("f");
	return(0);
  }
#endif /* unix */
