// 
// Copyright © 2002 Rigaku/MSC, Inc.
//                  9009 New Trails Drive  
//                  The Woodlands, TX, USA  77381  
// 
// The contents are unpublished proprietary source  
// code of Rigaku/MSC, Inc.  
// 
// All rights reserved   
// 
// serial.c          Initial author: T.L.Hendrixson                  Sep 2002
//
// Description:
//
//
// ToDo:
//
//

/****************************************************************************
 *                              Include Files                               *
 ****************************************************************************/

#ifdef WIN32
#pragma warning(disable:4786) // so warning about debug term > 255 chars ignored
#endif

#include <stdio.h>
#include <stdlib.h>

#include "serial.h"
#include "MSCVerbose.h"
#include "DevErrCode.h"

#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif  /* __cplusplus */


/****************************************************************************
 *                               Definitions                                *
 ****************************************************************************/

/****************************************************************************
 *                                 Typedefs                                 *
 ****************************************************************************/

/****************************************************************************
 *                          Structure definitions                           *
 ****************************************************************************/

/****************************************************************************
 *                               Enumerations                               *
 ****************************************************************************/

/****************************************************************************
 *                                Constants                                 *
 ****************************************************************************/

/****************************************************************************
 *                             Global variables                             *
 ****************************************************************************/


      // The level of verbosity of diagnostic output printed.
   long m_lVerboseLevel = 0;

      // indicates if handshaking being used
   int m_bUseHandshaking = 1; // indicates if handshaking being used

      // handshaking start character
   char m_cXON = 0x11;
      // handshaking stop character
   char m_cXOFF = 0x13;

      // number of bits per byte
   int m_nBitsPerByte = 8;
      // current port number
   int m_nPortID = 1;

      // read/write mode of port
   enum eSerial_Mode     m_eMode = eSerialMode_ReadWrite;
      // parity used by port
   enum eSerial_Parity   m_eParity = eSerialParity_None;
      // connection state of port
   enum eSerial_State    m_eState = eSerialState_Available;
      // number of stop bits used by port
   enum eSerial_StopBits m_eStopBits = eSerialStopBits_One;
      // type of port
   enum eSerial_Type     m_eType = eSerialType_Terminal;

      // input baud rate
   long m_lBaudRate = 9600;
      // timeout for read/write operations (in ms)
   long m_lTimeout = 1000;

      // port settings before opening
   DCB m_oOriginalSettings;  
      // port settings specified by class
   DCB m_oCurrentSettings;   

      // file handle for accessing port
   HANDLE m_oFileHandle;  

char *g_asSerialMode[eSerialMode_NumModes+1] = {"Unknown","read-write",
            "read only","write only","Number of modes"};
char *g_asSerialParity[eSerialParity_NumParities+1] = {"Unknown","none",
            "even","odd","mark","Number of parities"};
char *g_asSerialState[eSerialState_NumStates+1] = {"Unknown","Available",
            "Connected","Number of states"};
char *g_asSerialStopBits[eSerialStopBits_NumStopBits+1] = {"Unknown","one",
            "one and a half","two","Number of stop bits"};
char *g_asSerialType[eSerialType_NumTypes+1] = {"Unknown","terminal",
            "modem","hardware flow control","Number of types"};


/****************************************************************************
 *                            External variables                            *
 ****************************************************************************/

/****************************************************************************
 *                           Function prototypes                            *
 ****************************************************************************/

   // Applies the current timeout value to the port.  Note that for some
   // implementations, this may be essentially a dummy routine, with the
   // timeouts being handled in software in the nReadRequest() and
   // nWriteRequest() routines.
int nApplyTimeoutToPort(void);
   // Performs operating system and/or device specific steps to close a
   // connection to a port.
   // Should be supplied by the derived class.
int nClosePort(void);
   // Performs operating system and/or device specific steps to open a
   // connection to a port.
   // Should be supplied by the derived class.
int nOpenPort(void);
   // Generates the appropriate system calls needed in order to read
   // data from the port.
   // Should be supplied by the derived class.
int nReadRequest(char *pcBuffer, long *plReadBytes,
                 char *pcEndOfRead);
   // Generates the appropriate system calls needed in order to write
   // data to the port.
   // Should be supplied by the derived class.
int nWriteRequest(char *pcBuffer, long *plBytesToWrite);

/****************************************************************************
 ****************************************************************************/
int nClose(void) 
{ 
   return nDisconnect(); 
}

/****************************************************************************
 ****************************************************************************/
int nConnect(void)
{
   int nStatus;

/*
 * If connected, try to close an already open port.
 */
   if(eSerialState_Connected == m_eState){
      if(DEV_SUCCESS != nDisconnect()){
         return DEV_FAILED;
      }
   }

/*
 * Check the read/write mode
 */
   if(eSerialMode_Unknown == m_eMode || eSerialMode_NumModes == m_eMode){
      return DEV_FAILED;
   }

/*
 * Check the type of port
 */
   if(eSerialType_Unknown == m_eType || eSerialType_NumTypes == m_eType){
      return DEV_FAILED;
   }

/*
 * Make sure that the port ID has been set.
 */
   if(0 >= m_nPortID){
      return DEV_FAILED;
   }

/*
 * Open the port.
 */
   nStatus = nOpenPort();

   if(DEV_SUCCESS != nStatus){
      return nStatus;
   }

   m_eState = eSerialState_Connected;

   return nStatus;
}

/****************************************************************************
 ****************************************************************************/
int nDisconnect(void)
{
   int nStatus;

/*
 * Make sure the serial port is connected.
 */
   if(eSerialState_Connected != m_eState){
      return DEV_FAILED;
   }

/*
 * Close the file and set the state to available or unknown (if error).
 */
   nStatus = nClosePort();

   if(DEV_SUCCESS == nStatus)
      m_eState = eSerialState_Available;
   else{
      m_eState = eSerialState_Unknown;
   }

   return nStatus;
}

/****************************************************************************
 ****************************************************************************/
int nOpen(void)
{ 
   return nConnect(); 
}

/****************************************************************************
 ****************************************************************************/
int bIsConnected(void)
{
   if(eSerialState_Connected == m_eState)
      return 1;
   else
      return 0;
}

/****************************************************************************
 ****************************************************************************/
int
nRead(char *pcBuffer,
               long *plReadBytes,
               char *pcEndOfRead)
{
   int nStatus;

/*
 * Make sure the serial port is connected.
 */
   if(eSerialState_Connected != m_eState){
      return DEV_FAILED;
   }

/*
 * Make sure the number of bytes is legit
 */
   if(NULL == plReadBytes){
      return DEV_FAILED;
   }
   else if(0 >= *plReadBytes){
      return DEV_FAILED;
   }

/*
 * Read the bytes from the port
 */
   nStatus = nReadRequest(pcBuffer,plReadBytes,pcEndOfRead);

   return nStatus;
}

/****************************************************************************
 * This routine writes *plWriteBytes characters from memory location        *
 * pcBuffer to the serial port.  On output, *plWriteBytes contains the      *
 * number of bytes actually written.                                        *
 ****************************************************************************/
int
nWrite(char *pcBuffer,
                long *plWriteBytes)
{
   int nStatus;

/*
 * Make sure the serial port is connected.
 */
   if(eSerialState_Connected != m_eState){
      return DEV_FAILED;
   }

/*
 * Make sure the number of bytes is legit
 */
   if(NULL == plWriteBytes){
      return DEV_FAILED;
   }
   else if(0 >= *plWriteBytes){
      return DEV_FAILED;
   }

/*
 * Write the data to the port.
 */
   nStatus = nWriteRequest(pcBuffer,plWriteBytes);

   return nStatus;
}



/****************************************************************************
 * This routione adds the verbose level specified to the current verbose    *
 * levels.                                                                  *
 ****************************************************************************/
int
nAddVerboseLevel(long lLevel)
{
/*
 * Make sure the verbose level is legitmate.
 */
   if(0 > lLevel){
      return DEV_FAILED;
   }

// Added the verbose level to what is already there.

   m_lVerboseLevel |= lLevel;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine sets what the serial port will consider to be the number of *
 * bits in a byte.                                                          *
 ****************************************************************************/
int
nSetBitsPerByte(int nBitsPerByte)
{
/*
 * Make sure the serial port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

/*
 * Make sure the number of bits is legitimate
 */
   if(0 >= nBitsPerByte){
      return DEV_FAILED;
   }

// Set the number of bits per byte

   m_nBitsPerByte = nBitsPerByte;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine sets whether or not the serial port is to use XON/XOFF      *
 * handshaking, and uses the characters cXON and cXOFF and the XON and XOFF *
 * characters, respectively.                                                *
 ****************************************************************************/
int
nSetHandshaking(int bValue, char cXON, char cXOFF)
{

/*
 * Make sure the port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

// Set the handshaking usage.

   m_bUseHandshaking = bValue;

// If using handshaking, set the characters to use.

   if(0 != bValue){
      m_cXON = cXON;
      m_cXOFF = cXOFF;
   }

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine sets the baud rate used for communication.  It is assumed   *
 * that the input and output baud rates are the same.                       *
 ****************************************************************************/
int
nSetBaudRate(long lBaudRate)
{

/*
 * Make sure the port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

/*
 * Make sure the baud rate is legitimate
 */
   if(0 >= lBaudRate){
      return DEV_FAILED;
   }

// Set the baud rate.

   m_lBaudRate = lBaudRate;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine set the read/write mode of the serial port.                 *
 ****************************************************************************/
int
nSetMode(enum eSerial_Mode eMode)
{
/*
 * Make sure the serial port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

/*
 * Set the mode.
 */
   m_eMode = eMode;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine set the type of parity used by the serial port.             *
 ****************************************************************************/
int
nSetParity(enum eSerial_Parity eParity)
{

/*
 * Make sure the port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

// Set the parity.

   m_eParity = eParity;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine serts the port ID and the type of the serial port.          *
 ****************************************************************************/
int
nSetPortID(int nID, enum eSerial_Type eType)
{
   int nStatus;

   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

/*
 * Make sure the type is valid.
 */
   if(eSerialType_Unknown == eType || eSerialType_NumTypes == eType){
      return DEV_FAILED;
   }


/*
 * Set the type of port
 */
   nStatus = nSetType(eType);
/*
 * Set the port ID
 */
   if(DEV_SUCCESS == nStatus)
      m_nPortID = nID;

   return nStatus;
}

/****************************************************************************
 * This routine sets the number of stop bits used by the serial port.       *
 ****************************************************************************/
int
nSetStopBits(enum eSerial_StopBits eStopBits)
{

/*
 * Make sure that the port is not connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

// Set the number of stop bits.

   m_eStopBits = eStopBits;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine sets the timeout value (in seconds) used on reads from and  *
 * writes to the * serial port.                                             *
 ****************************************************************************/
int
nSetTimeout(double dSeconds)
{
/*
 * Make the timeout valueis legitimate.  Note that zero is a legitimate value,
 * it means that if nothing there, return immediately.
 */
   if(0 > dSeconds){
      return DEV_FAILED;
   }

// Store timeout value in milliseconds

   m_lTimeout = (long)(dSeconds*1000.);

/*
 * If connected, apply the timeout value to the line now.
 */
   if(eSerialState_Connected == m_eState){
      if(DEV_SUCCESS != nApplyTimeoutToPort()){
         return DEV_FAILED;
      }
   }

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine set the type of serial port.                                *
 ****************************************************************************/
int
nSetType(enum eSerial_Type eType)
{
/*
 * Make sure the port is not already connected.
 */
   if(eSerialState_Connected == m_eState){
      return DEV_FAILED;
   }

/*
 * Only terminal type ports are supported for now.
 */
   if(eSerialType_Terminal != eType){
      return DEV_FAILED;
   }

// Set the serial port type

   m_eType = eType;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine sets the verbosee level.                                    *
 ****************************************************************************/
int
nSetVerboseLevel(long lLevel)
{
/*
 * Make sure that it is a legitimate level
 */
   if(0 > lLevel){
      return DEV_FAILED;
   }

// Set the verbose level.

   m_lVerboseLevel = lLevel;

   return DEV_SUCCESS;
}



/****************************************************************************
 ****************************************************************************/
long lGetBaudRate(void) { return m_lBaudRate; }

/****************************************************************************
 ****************************************************************************/
int nGetBitsPerByte(void) { return m_nBitsPerByte; }

/****************************************************************************
 ****************************************************************************/
int bGetHandshaking(void) { return m_bUseHandshaking; }

/****************************************************************************
 ****************************************************************************/
enum eSerial_Mode eGetMode(void) { return m_eMode; }

/****************************************************************************
 ****************************************************************************/
enum eSerial_Parity eGetParity(void) { return m_eParity; }

/****************************************************************************
 ****************************************************************************/
int nGetPortID(void) { return m_nPortID; }

/****************************************************************************
 ****************************************************************************/
enum eSerial_State eGetState(void) { return m_eState; }

/****************************************************************************
 ****************************************************************************/
enum eSerial_StopBits eGetStopBits(void) { return m_eStopBits; }

/****************************************************************************
 ****************************************************************************/
double dGetTimeout(void)
{
   double d;
   d = (double)m_lTimeout/1000.;
   return d;
}


/****************************************************************************
 ****************************************************************************/
enum eSerial_Type eGetType(void) { return m_eType; }

/****************************************************************************
 ****************************************************************************/
long lGetVerboseLevel(void) { return m_lVerboseLevel; }

/****************************************************************************
 ****************************************************************************/
char cGetXOFFCharacter(void) { return m_cXOFF; }

/****************************************************************************
 ****************************************************************************/
char cGetXONCharacter(void)  { return m_cXON; }




/****************************************************************************
 * This routine applys the timeout value for reads and writes to the port.  *
 ****************************************************************************/
int
nApplyTimeoutToPort(void)
{
   int nTimeout;
   COMMTIMEOUTS oCommTimeouts;

/*
 * Make sure file handle is valid.
 */
   if(INVALID_HANDLE_VALUE == m_oFileHandle){
      return DEV_FAILED;
   }

// Get the communications timeout object

   if(!GetCommTimeouts(m_oFileHandle,&oCommTimeouts)){
      return DEV_FAILED;
   }

// Set the timeout in milliseconds.

   nTimeout = (int)(dGetTimeout()*1000.);
   oCommTimeouts.ReadIntervalTimeout = 0;
   oCommTimeouts.ReadTotalTimeoutMultiplier = 0;
   oCommTimeouts.ReadTotalTimeoutConstant = nTimeout;
   oCommTimeouts.WriteTotalTimeoutMultiplier = 0;
   oCommTimeouts.WriteTotalTimeoutConstant = nTimeout;

// Set the timeout attribute.

   if(!SetCommTimeouts(m_oFileHandle,&oCommTimeouts)){
      return DEV_FAILED;
   }

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine closes the serial port.                                     *
 ****************************************************************************/
int
nClosePort(void)
{

// Make sure the file handle is valid

   if(INVALID_HANDLE_VALUE == m_oFileHandle){
      return DEV_FAILED;
   }

// Clean out the I/O buffers

   PurgeComm(m_oFileHandle,PURGE_TXABORT|PURGE_RXABORT|PURGE_TXCLEAR|
             PURGE_RXCLEAR);

// Reset the port characteristics to what they were when we opened it.

   if(!SetCommState(m_oFileHandle,&m_oOriginalSettings)){
      return DEV_FAILED;
   }

// Close the port

   if(!CloseHandle(m_oFileHandle)){
      return DEV_FAILED;
   }
   m_oFileHandle = INVALID_HANDLE_VALUE;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine opens the serial port.                                      *
 ****************************************************************************/
int
nOpenPort(void)
{
   int bBaudOkay;
   enum eSerial_Mode eMode;
   enum eSerial_Type eType;
   enum eSerial_StopBits eStop;
   enum eSerial_Parity eParity;
   int n,nStatus;
   long l;
   DWORD oIOMode;
   char sPortName[1024];

// Is this type of serial port supported.

   eType = eGetType();
   if(eSerialType_Terminal != eType){
      return DEV_FAILED;
   }

// Build the filename for the port

   sprintf(sPortName,"COM%d",nGetPortID());

// Extract the I/O mode for opening the port.

   eMode = eGetMode();
   if(eSerialMode_ReadWrite == eMode)
      oIOMode = GENERIC_READ|GENERIC_WRITE;
   else if(eSerialMode_ReadOnly == eMode)
      oIOMode = GENERIC_READ;
   else if(eSerialMode_WriteOnly == eMode)
      oIOMode = GENERIC_WRITE;
   else{
      return DEV_FAILED;
   }

// Open the port.

   m_oFileHandle = CreateFile(sPortName,oIOMode,0,NULL,OPEN_EXISTING,
                              0,NULL);

   if(INVALID_HANDLE_VALUE == m_oFileHandle){
      m_oFileHandle = INVALID_HANDLE_VALUE;
      return DEV_FAILED;
   }

// Now set the port characteristics.  First get the current settings.

   if(!GetCommState(m_oFileHandle,&m_oOriginalSettings)){
      CloseHandle(m_oFileHandle);
      m_oFileHandle = INVALID_HANDLE_VALUE;
      return DEV_FAILED;
   }

   m_oCurrentSettings = m_oOriginalSettings;

// Set the baud rate

   l = lGetBaudRate();
   switch(l){
      case 110:    // fall though, break intentionally missing
      case 300:    // fall though, break intentionally missing
      case 600:    // fall though, break intentionally missing
      case 1200:   // fall though, break intentionally missing
      case 2400:   // fall though, break intentionally missing
      case 4800:   // fall though, break intentionally missing
      case 9600:   // fall though, break intentionally missing
      case 14400:  // fall though, break intentionally missing
      case 19200:  // fall though, break intentionally missing
      case 38400:  // fall though, break intentionally missing
      case 56000:  // fall though, break intentionally missing
      case 57600:  // fall though, break intentionally missing
      case 115200: // fall though, break intentionally missing
      case 128000: // fall though, break intentionally missing
      case 256000: bBaudOkay = 1;  break;
      default:     bBaudOkay = 0; break;
   }
   if(0 == bBaudOkay){
      CloseHandle(m_oFileHandle);
      m_oFileHandle = INVALID_HANDLE_VALUE;
      return DEV_FAILED;
   }
   m_oCurrentSettings.BaudRate = l;

// Set the character size

   n = nGetBitsPerByte();
   if(5 > n || 8 < n){
      fprintf(stderr,"WARNING Unsupported number of bits per character: %d",n);
   }
   else
      m_oCurrentSettings.ByteSize = n;

// Set stop bits

   eStop = eGetStopBits();
   if(eSerialStopBits_Two == eStop)
      m_oCurrentSettings.StopBits = 2;
   else if(eSerialStopBits_OneAndHalf == eStop)
      m_oCurrentSettings.StopBits = 1;
   else if(eSerialStopBits_One == eStop)
      m_oCurrentSettings.StopBits = 0;
   else{
      fprintf(stderr,"WARNING Unsupported number of stop bits: %s",
         g_asSerialStopBits[eStop]);
   }

// Parity

   eParity = eGetParity();
   if(eSerialParity_None == eParity){
      m_oCurrentSettings.Parity = 0;
      m_oCurrentSettings.fParity = 0;
   }
   else if(eSerialParity_Odd == eParity){
      m_oCurrentSettings.Parity = 1;
      m_oCurrentSettings.fParity = 1;
   }
   else if (eSerialParity_Even == eParity){
      m_oCurrentSettings.Parity = 2;
      m_oCurrentSettings.fParity = 1;
   }
   else if(eSerialParity_Mark == eParity){
      m_oCurrentSettings.Parity = 3;
      m_oCurrentSettings.fParity = 1;
   }
   else{
      fprintf(stderr,"WARNING Unsupported parity: %s",
         g_asSerialParity[eParity]);
   }

// Handshaking

   m_oCurrentSettings.fInX = m_oCurrentSettings.fOutX = bGetHandshaking();
   m_oCurrentSettings.XonChar = cGetXONCharacter();
   m_oCurrentSettings.XoffChar = cGetXOFFCharacter();


// Set other info not currently supported in class.

   m_oCurrentSettings.fOutxDsrFlow = m_oCurrentSettings.fOutxCtsFlow = 0;
   m_oCurrentSettings.fDtrControl = DTR_CONTROL_ENABLE;
   m_oCurrentSettings.fRtsControl = DTR_CONTROL_ENABLE;
   m_oCurrentSettings.XonLim = 100;
   m_oCurrentSettings.XoffLim = 100;
   m_oCurrentSettings.fBinary = 1;

// Apply setting to port

   if(!SetCommState(m_oFileHandle,&m_oCurrentSettings)){
      CloseHandle(m_oFileHandle);
      m_oFileHandle = INVALID_HANDLE_VALUE;
      return DEV_FAILED;
   }

// Apply the timeout value to the port

   nStatus = nApplyTimeoutToPort();

   return nStatus;
}

/****************************************************************************
 * This routine performs a read from the serial port.  Data read are placed *
 * in pcBuffer.  The read will terminate for one of the following reasons:  *
 *   (a) *plReadBytes bytes have been read from the port                    *
 *   (b) character matching *pcEndOfLine is read from the port              *
 *   (c) an error occurred while attempting to read from the port           *
 *   (d) no character was available to read within the timeout period       *
 * The first two cases return DEV_SUCCESS, and the last two return          *
 * DEV_FAILED and DEV_TIMEOUT, respectively.  On return from a read request *
 * plReadBytes will contain the number of bytes actually read from the      *
 * serial port.                                                             *
 ****************************************************************************/
int
nReadRequest(char *pcBuffer,
                         long *plReadBytes,
                         char *pcEndOfLine)
{
   char *pc;
   unsigned long ulRead;
   long lMaxLen,lLen;
   BOOL b;
   DWORD dw;

   lMaxLen = *plReadBytes;
   lLen = 0;
   pc = pcBuffer;
   *pc = '\0';

// Read from the serial port, one character at a time

   while(1){

      b = ReadFile(m_oFileHandle,(LPVOID)pc,1,&ulRead,NULL);

// Error occurred during read

      if(!b){
         *plReadBytes = lLen;
         dw = GetLastError();
         return DEV_FAILED;
      }

// Read timed out without getting a character

      else if(0 == ulRead){
         *plReadBytes = lLen;
         return DEV_TIMEOUT;
      }

// Successfully read a character

      else{
         lLen++;

// If requested, output the character read

         if(0 != (m_lVerboseLevel&MSCVerboseRead)){
            fprintf(stdout,"serial port %d ----> ",nGetPortID());
            if(isprint((int)(*pc)))
               fprintf(stdout,"%c",*pc);
            else
               fprintf(stdout,"unprintable");
            fprintf(stdout," (%d)\n",(int)(*pc));
         }

// If it was the end-of-read character or we have read in the maximum number
// of characters, leave now.

         if((NULL != pcEndOfLine && NULL != strstr(pc,pcEndOfLine)) ||
         lLen == lMaxLen){
            *plReadBytes = lLen;
            return DEV_SUCCESS;
         }

// Prepare for next character to be read

         pc++;
         *pc = '\0';
      }

   }   // end of while() loop

   // should never get here, but this will keep the compiler happy

   return DEV_FAILED;
}

/****************************************************************************
 * This routine performs a write to the serial port.  Data are written from *
 * pcBuffer.  The write will terminate for one of the following reasons:    *
 *   (a) *plWriteBytes bytes have been written to the port                  *
 *   (b) an error occurred while attempting to write to the port            *
 *   (c) no character was able to be written within the timeout period      *
 * The first case returns DEV_SUCCESS, and the last two return DEV_FAILED   *
 * and DEV_TIMEOUT, respectively.  On return from a write request,          *
 * plWriteBytes will contain the number of bytes actually written to the    *
 * serial port.                                                             *
 ****************************************************************************/
int
nWriteRequest(char *pcBuffer,
                          long *plWriteBytes)
{
   char *pc;
   unsigned long ulWrote;
   long lMaxLen,lLen;
   BOOL b;
   DWORD dw;

   lMaxLen = *plWriteBytes;
   lLen = 0;
   pc = pcBuffer;

// Write to the serial port, one character at a time.

   while(lLen != lMaxLen){

      b = WriteFile(m_oFileHandle,pc,1,&ulWrote,NULL);

// Error occurred while writing the character

      if(!b){
         *plWriteBytes = lLen;
         dw = GetLastError();
         return DEV_FAILED;
      }

// Write timed out without writing a character

      else if(0 == ulWrote){
         return DEV_TIMEOUT;
      }

// Successfuly wrote a character, so increment the counters

      else{

// If requested, output the character written

         if(0 != (m_lVerboseLevel&MSCVerboseWrite)){
            fprintf(stdout,"serial port %d <---- ",nGetPortID());
            if(isprint((int)(*pc)))
               fprintf(stdout,"%c",*pc);
            else
               fprintf(stdout,"unprintable");
            fprintf(stdout," (%d)\n",(int)(*pc));
         }

         lLen++;
         pc++;
      }
   }

   *plWriteBytes = lLen;

   return DEV_SUCCESS;
}

#ifdef __cplusplus
}
#endif  /* __cplusplus */

