// 
// Copyright © 2004 Rigaku/MSC, Inc.
//                  9009 New Trails Drive  
//                  The Woodlands, TX, USA  77381  
// 
// The contents are unpublished proprietary source  
// code of Rigaku/MSC, Inc.  
// 
// Use of this source code without written permission
// from Rigaku/MSC, Inc. is prohibited.
// 
// All rights reserved   
// 
// serial.c          Initial author: T.L.Hendrixson                 Jan 2004
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

#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <dirent.h>
#include <termio.h>

#include "serial_linux.h"
#include "MSCVerbose.h"
#include "DevErrCode.h"

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


      // file descriptor for accessing port
   int m_nFileDescriptor;  

      // port settings specified by class
   struct termios m_oCurrentSettings;  
      // port settings before opening
   struct termios m_oOriginalSettings; 


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
/*
 * Make sure file descriptor is valid.
 */
   if(0 >= m_nFileDescriptor){
      return DEV_FAILED;
   }

/*
 * Set the timeout in tenths of a second.
 * Using this method will only work if the time out is less than 25.6 seconds.
 * So, we will set the timeout value to a tenth of a second and then take 
 * care of longer times in software.
 */
   m_oCurrentSettings.c_cc[VTIME] = 1;
   m_oCurrentSettings.c_cc[VMIN] = 0;
   
// Set the timeout attribute.

   if(0 > tcsetattr(m_nFileDescriptor,TCSADRAIN,&m_oCurrentSettings)){
      return DEV_FAILED;
   }
   tcgetattr(m_nFileDescriptor,&m_oCurrentSettings);

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine closes the serial port.                                     *
 ****************************************************************************/
int
nClosePort(void)
{

// Make sure the file descriptor is valid

   if(0 >= m_nFileDescriptor){
      return DEV_FAILED;
   }

// Clean out the IO buffers

   tcflush(m_nFileDescriptor,TCIOFLUSH);

// Reset the port characteristics to what they were when we opened it.

   if(0 > tcsetattr(m_nFileDescriptor,TCSADRAIN,&m_oOriginalSettings)){
      return DEV_FAILED;
   }

// Close the port
   
   if(0 > close(m_nFileDescriptor)){
      return DEV_FAILED;
   }
   m_nFileDescriptor = -1;

   return DEV_SUCCESS;
}

/****************************************************************************
 * This routine opens the serial port.                                      *
 ****************************************************************************/
int
nOpenPort(void)
{
   enum eSerial_Mode eMode;
   enum eSerial_Type eType;
   enum eSerial_StopBits eStop;
   enum eSerial_Parity eParity;
   int n,nIOMode,nStatus;
   long l;
   tcflag_t oCFlag;
   speed_t oBaud;
   char sPortName[1024];

// Is this type of serial port supported.

   eType = eGetType();
   if(eSerialType_Terminal != eType){
      return DEV_FAILED;
   }

// Build the filename for the port

   sprintf(sPortName,"/dev/ttyS%d",nGetPortID()-1);

// Extract the I/O mode for opening the port.

   eMode = eGetMode();
   if(eSerialMode_ReadWrite == eMode)
      nIOMode = O_RDWR;
   else if(eSerialMode_ReadOnly == eMode)
      nIOMode = O_RDONLY;
   else if(eSerialMode_WriteOnly == eMode)
      nIOMode = O_WRONLY;
   else{
      return DEV_FAILED;
   }

// Open the port.

   m_nFileDescriptor = open(sPortName,nIOMode);

   if(0 >= m_nFileDescriptor){
      m_nFileDescriptor = -1;
      return DEV_FAILED;
   }

// Now set the port characteristics.  First get the current settings.

   if(0 > tcgetattr(m_nFileDescriptor,&m_oOriginalSettings)){
      close(m_nFileDescriptor);
      m_nFileDescriptor = -1;
      return DEV_FAILED;
   }

   m_oCurrentSettings = m_oOriginalSettings;
   oCFlag = 0;
   oBaud = 0;

// Set the baud rate

   l = lGetBaudRate();
   switch(l){
      case    50: oBaud = B50;    break;
      case    75: oBaud = B75;    break;
      case   110: oBaud = B110;   break;
      case   134: oBaud = B134;   break;
      case   150: oBaud = B150;   break;
      case   200: oBaud = B200;   break;
      case   300: oBaud = B300;   break;
      case   600: oBaud = B600;   break;
      case  1200: oBaud = B1200;  break;
      case  1800: oBaud = B1800;  break;
      case  2400: oBaud = B2400;  break;
      case  4800: oBaud = B4800;  break;
      case  9600: oBaud = B9600;  break;
      case 19200: oBaud = B19200; break;
      case 38400: oBaud = B38400; break;
      default   : oBaud = 0;      break;
   }
   if(0 == oBaud){
      close(m_nFileDescriptor);
      m_nFileDescriptor = -1;
      return DEV_FAILED;
   }
   oCFlag = oBaud;

// Set the character size

   n = nGetBitsPerByte();
   if(5 == n)
      oCFlag |= CS5;
   else if(6 == n)
      oCFlag |= CS6;
   else if(7 == n)
      oCFlag |= CS7;
   else if(8 == n)
      oCFlag |= CS8;
   else{
      fprintf(stderr,"WARNING Unsupported number of bits per character: %d",n);
   }
//  the line following the else was moved above.
//   else
//     m_oCurrentSettings.ByteSize = n;

// Do we need to be able to read from this line?

   if(eSerialMode_ReadWrite == eMode || eSerialMode_ReadOnly == eMode)
      oCFlag |= CREAD;

// Set stop bits

   eStop = eGetStopBits();
   if(eSerialStopBits_Two == eStop)
      oCFlag |= CSTOPB;
   else if(eSerialStopBits_One != eStop){
      fprintf(stderr,"WARNING Unsupported number of stop bits: %s",
         g_asSerialStopBits[eStop]);
   }

// Parity

   eParity = eGetParity();
   if(eSerialParity_Odd == eParity)
      oCFlag |= (PARENB|PARODD);
   else if (eSerialParity_Even == eParity)
      oCFlag |= PARENB;
   else if(eSerialParity_None != eParity){
      fprintf(stderr,"WARNING Unsupported parity: %s",
         g_asSerialParity[eParity]);
   }

// Is this a local direct connection with no modem control?

   if(eSerialType_Modem != eType)
      oCFlag |= CLOCAL;

// Don't send DTR signal when disconnect. (maybe option later?)

   oCFlag |= HUPCL;

// RTS/CTS flow control

   if(eSerialType_FlowControl == eType)
      oCFlag |= CRTSCTS;
  
// Handshaking

   if(true == bGetHandshaking()){
      m_oCurrentSettings.c_iflag |= IXON;
      if(0x11 != cGetXONCharacter()){
         fprintf(stderr,"WARNING XOFF character other than START (0x11, control-Q)\n");
         fprintf(stderr,"is not supported on Linux.\n");
      }
      if(0x13 != cGetXOFFCharacter()){
         fprintf(stderr,"WARNING XOFF character other than STOP (0x13, control-S)\n");
         fprintf(stderr,"is not supported on Linux.\n");
      }
   }
   else
      m_oCurrentSettings.c_iflag &= ~IXON;

// Don't convert <CR> to <NL> on input

   m_oCurrentSettings.c_iflag &= ~ICRNL;

// Assign control mode settings

   m_oCurrentSettings.c_cflag = oCFlag;

// turn off any local interpretation of characters

   m_oCurrentSettings.c_lflag = 0;

// Apply setting to port

   if(0 > tcsetattr(m_nFileDescriptor,TCSADRAIN,&m_oCurrentSettings)){
      close(m_nFileDescriptor);
      m_nFileDescriptor = -1;
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
   int nRead;
   long lMaxLen,lLen;
   double dEndTime,dNowTime;

   lMaxLen = *plReadBytes;
   lLen = 0;
   pc = pcBuffer;
   *pc = '\0';

/*
 * Since problem with termio port timeout (only works if timout is less than
 * 25.6 seconds), will have to do it in software.
 * Figure out the point at which we will consider the write to be timed out.
 */
   dEndTime = dGetTimeOfDay()+dGetTimeout();

// Read from the serial port, one character at a time

   while(1){

      nRead = read(m_nFileDescriptor,pc,1);

// Error occurred during read

      if(-1 == nRead){
         if(EINTR == errno)
            continue;
         *plReadBytes = lLen;
         return DEV_FAILED;
      }

// Read timed out without getting a character

      else if(0 == nRead){
         dNowTime = dGetTimeOfDay();
         if(dNowTime >= dEndTime){
            *plReadBytes = lLen;
            return DEV_TIMEOUT;
         }
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
   int nWrote;
   long lMaxLen,lLen;
   double dEndTime,dNowTime;

   lMaxLen = *plWriteBytes;
   lLen = 0;
   pc = pcBuffer;

/*
 * Figure out the point at which we will consider the write to be timed out.
 */
   dEndTime = dGetTimeOfDay()+dGetTimeout();

// Write to the serial port, one character at a time.

   while(lLen != lMaxLen){

      nWrote = write(m_nFileDescriptor,pc,1);

// Error occurred while writing the character

      if(-1 == nWrote){
         if(EINTR == errno)
            continue;
         *plWriteBytes = lLen;
         return DEV_FAILED;
      }

// Write timed out without writing a character

      else if(0 == nWrote){
         dNowTime = dGetTimeOfDay();
         if(dNowTime >= dEndTime){
            *plWriteBytes = lLen;
            return DEV_TIMEOUT;
         }
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

