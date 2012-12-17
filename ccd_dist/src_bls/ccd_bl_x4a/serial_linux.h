#ifndef SERIAL_H
#define SERIAL_H

//# 
//# Copyright © 2004 Rigaku/MSC, Inc.
//#                  9009 New Trails Drive  
//#                  The Woodlands, TX, USA  77381  
//# 
//# The contents are unpublished proprietary source  
//# code of Rigaku/MSC, Inc.
//#
//# Use of this source code without written permission
//# from Rigaku/MSC, Inc. is prohibited.
//# 
//# All rights reserved   
//# 
//# serial.h           Initial author: T.L.Hendrixson                Sep 2004
//#

/****************************************************************************
 *                              Include Files                               *
 ****************************************************************************/

/****************************************************************************
 *                               Definitions                                *
 ****************************************************************************/

/****************************************************************************
 *                          Structure definitions                           *
 ****************************************************************************/

/****************************************************************************
 *                               Enumerations                               *
 ****************************************************************************/
#define	true	(1)

#ifdef __cplusplus
extern "C" {
#endif  /* __cplusplus */

// eSerial_Mode is used to indicate what sort of I/O access should
// be used when connecting to the serial port.
enum eSerial_Mode {
      // There is no indication of what access to use when connecting to the
      // port.  Setting the mode to this value will cause an error when
      // attempting to connect to the port.
   eSerialMode_Unknown,
      // The I/O access to use when connecting to the port is to allow both
      // read and write access.
   eSerialMode_ReadWrite,
      // The I/O access to use when connecting to the port is to allow only
      // read access.
   eSerialMode_ReadOnly,
      // The I/O access to use when connecting to the port is to allow only
      // write access.
   eSerialMode_WriteOnly,
      // This indicates the total number of I/O access modes.  Setting the
      // mode to this value will cause an error when attempting to connect
      // to the port.
   eSerialMode_NumModes
};

// eSerial_State is used to indicate the current connection state of the serial
// port.
enum eSerial_State {
      // The connection state is unknown.  Setting the state to this
      // value will cause errors when attempting to read from or write to the
      // serial port.
   eSerialState_Unknown,
      // The connection state is disconnected, and hence available for
      // establishing a connection.
   eSerialState_Available,
      // The connection state is connected, and read and write operations
      // are available (if allowed by the I/O aceess mode).
   eSerialState_Connected,
      // This indicates the total number of connection states.  Setting the
      // state to this value will cause errors when attempting to read from
      // or write to the serial port.
   eSerialState_NumStates
};

// eSerial_Type is used to indicate the type of serial port connection
// that should be made.  Note that not all types are supported on all
// operating systems.
enum eSerial_Type {
      // The type of port is unknown.  Setting the type to this
      // value will cause errors when attempting to read from or write to the
      // serial port.
   eSerialType_Unknown,
      // The port will be used for communicating with simple devices,
      // including most terminals.
   eSerialType_Terminal,
      // The port will used for communicating with devices that use
      // modem control signals.
   eSerialType_Modem,
      // The port will be used for communicating with devices that
      // understand hardware flow control signals.
   eSerialType_FlowControl,
      // This indicates the total number of types.  Setting the
      // type to this value will cause an error when attempting to connect
      // to the port.
   eSerialType_NumTypes
};

// eSerial_Parity is used to indicate the parity used by the serial port
// connection.  Not all parity types are supported on all operating
// systems.
enum eSerial_Parity {
      // The parity is unknown.  Setting the parity to this
      // value will cause errors when attempting to read from or write to the
      // serial port.
   eSerialParity_Unknown,
      // The port will use no parity, or parity generation/detection
      // is disabled.
   eSerialParity_None,
      // The port will use even parity.
   eSerialParity_Even,
      // The port will use odd parity.
   eSerialParity_Odd,
      // The port will use mark parity.
   eSerialParity_Mark,
      // This indicates the total number of parity types.  Setting the
      // parity to this value will cause an error when attempting to connect
      // to the port.
   eSerialParity_NumParities
};

// eSerial_StopBits is used to indicate the number of stop bits used by the
// serial port connection.
enum eSerial_StopBits {
      // The number of stop bits is unknown.  Setting the stop bits to this
      // value will cause errors when attempting to read from or write to the
      // serial port.
   eSerialStopBits_Unknown,
      // One stop bit will be used.
   eSerialStopBits_One,
      // One and a half stop bits will be used.
   eSerialStopBits_OneAndHalf,
      // Two stop bits will be used.
   eSerialStopBits_Two,
      // This indicates the total number of stop bit types.  Setting the
      // stop bits to this value will cause an error when attempting to connect
      // to the port.
   eSerialStopBits_NumStopBits
};

/****************************************************************************
 *                                 Typedefs                                 *
 ****************************************************************************/

/****************************************************************************
 *                                Constants                                 *
 ****************************************************************************/

/****************************************************************************
 *                            External variables                            *
 ****************************************************************************/

/****************************************************************************
 *                           Function prototypes                            *
 ****************************************************************************/

//#Routines for connecting/disconnecting the serial port

      // Closes the connection to the port.  If the connection cannot be
      // closed, this routine will return an error code other than DEV_SUCCESS.
   int nClose(void);
      // Opens a connection to the port.
   int nConnect(void);
      // Closes the connection to the port.  If the connection cannot be
      // closed, this routine will return an error code other than DEV_SUCCESS.
   int nDisconnect(void);
      // Opens a connection to the port.
   int nOpen(void);

//#Routine for checking state of device

      // Returns a integer indicating if the class is connected to a port
      // (<i>1</i>) or not (<i>0</i>)
   int bIsConnected(void);

//#Routines for reading from and writing to the serial port

      // Reads data from the port.  Data is placed in the array pointed to
      // by "pcBuffer".  It is up to the calling routine to ensure that
      // "pcBuffer" contains sufficient space to hold all of the data.
      // "plReadBytes" is an address in memory to which a long int can be
      // written.  On input to the routine, this should contain the maximum
      // number of bytes to read from the serial port.  On output, this
      // will contain the number of bytes actually read from the serial port.
      // "pcEndOfRead" is a pointer to a NULL-terminated character string that
      // contains one or more characters that will be used to indicate that
      // the read has finished.  On output from the routine, the data will
      // contain the characters in "pcEndOfRead" if they are encountered
      // during the read.  For example, in order to read at most 64
      // characters from a serial port, stopping the read when the characters
      // "end-of-read" are encountered, your code might look like:
      // <srcblock>
      // long BytesToRead;
      // int nStatus;
      // char Array[64];
      //
      // BytesToRead = 64;
      // nStatus = nRead(Array,&BytesToRead,"end-of-read");
      // if(DEV_SUCCESS != nStatus){
      //    cout << "Error reading from serial port\n";
      // }
      // else
      //    cout << "Read " << BytesToRead << " from serial port.\n";
      // </srcblock>
   int nRead(char *pcBuffer, long *plReadBytes, char *pcEndOfRead);
      // Writes data, from the array pointed to by "pcBuffer", to the port.
      // "plWriteBytes" is an address in memory to which a long int can be
      // written.  On input to the routine, this should contain the maximum
      // number of bytes to write to the serial port.  On output, this
      // will contain the number of bytes actually written to the serial port.
   int nWrite(char *pcBuffer, long *plWriteBytes);

//#Routines for setting values of parameters

      // Adds the specified verbosity level to the level of verbosity of
      // diagnostic output printed.
   int nAddVerboseLevel(long lLevel);
      // Sets the default baud rate for both reads and writes.
      // Can only be used if the class is not connected to a port.
   int nSetBaudRate(long lBaudRate);
      // Sets the number of bits in a byte.
      // Can only be used if the class is not connected to a port.
   int nSetBitsPerByte(int nBitsBerByte);
      // Sets whether XON/XOFF handshaking is used (<i>1</i>) or not
      // (<i>0</i>).
      // If used, the characters "cXON" and "cXOFF" will be used as the
      // XON and XOFF handshaking characters, respectively.
      // Can only be used if the class is not connected to a port.
   int nSetHandshaking(int bValue, char cXON, char cXOFF);
      // Sets the I/O access mode for the port.
      // Can only be used if the class is not connected to a port.
   int nSetMode(enum eSerial_Mode eMode);
      // Sets the parity of the port.
      // Can only be used if the class is not connected to a port.
   int nSetParity(enum eSerial_Parity eParity);
      // Sets the port ID number and type of the port.
      // Can only be used if the class is not connected to a port.
   int nSetPortID(int nID, enum eSerial_Type eType);
      // Sets the number of stop bits.
      // Can only be used if the class is not connected to a port.
   int nSetStopBits(enum eSerial_StopBits eStopBits);
      // Sets the default timeout value for reads from and writes to the port.
      // The timeout value is specified in seconds.
   int nSetTimeout(double dSeconds);
      // Sets the type of port.
      // Can only be used if the class is not connected to a port.
   int nSetType(enum eSerial_Type eType);
      // Sets the level of verbosity of diagnostic output printed.
   int nSetVerboseLevel(long lLevel);


//#Routines for getting values of parameters

      // Returns the current baud rate for the port (in bps).
   long lGetBaudRate(void);
      // Returns the number of bits per byte used by the port.
   int nGetBitsPerByte(void);
      // Returns a bool indicating if XON/XOFF handshaking is enabled
      // (<i>true</i>) or disabled (<i>false</i>).
   int bGetHandshaking(void);
      // Returns the current I/O access mode.
   enum eSerial_Mode eGetMode(void);
      // Returns the type of parity used by the port.
   enum eSerial_Parity eGetParity(void);
      // Returns the numerical ID for the port.
   int nGetPortID(void);
      // Returns the current connection state.
   enum eSerial_State eGetState(void);
      // Returns the number of stop bits used by the port.
   enum eSerial_StopBits eGetStopBits(void);
      // Returns the default timeout value used by the port.  The value
      // returned is in seconds.
   double dGetTimeout(void);
      // Returns the type of serial port.
   enum eSerial_Type eGetType(void);
      // Returns the level of verbosity of diagnostic output printed.
   long lGetVerboseLevel(void);
      // Returns the XOFF character used by the port, regardless of whether
      // or not handshaking is turned on.
   char cGetXOFFCharacter(void);
      // Returns the XON character used by the port, regardless of whether
      // or not handshaking is turned on.
   char cGetXONCharacter(void);

#ifdef __cplusplus
}
#endif  /* __cplusplus */


#endif /* SERIAL_H */

