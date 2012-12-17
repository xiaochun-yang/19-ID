/* this file contains the actual definitions of */
/* the IIDs and CLSIDs */

/* link this file in with the server and any clients */


/* File created by MIDL compiler version 5.01.0164 */
/* at Wed Nov 21 13:40:55 2001
 */
/* Compiler settings for T:\PROG\BLOB_io\BLOB_io.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32, ms_ext, c_ext
    error checks: allocation ref bounds_check enum stub_data 
*/
//@@MIDL_FILE_HEADING(  )
#ifdef __cplusplus
extern "C"{
#endif 


#ifndef __IID_DEFINED__
#define __IID_DEFINED__

typedef struct _IID
{
    unsigned long x;
    unsigned short s1;
    unsigned short s2;
    unsigned char  c[8];
} IID;

#endif // __IID_DEFINED__

#ifndef CLSID_DEFINED
#define CLSID_DEFINED
typedef IID CLSID;
#endif // CLSID_DEFINED

const IID IID_IBLOB_io1 = {0x55E74599,0xBE5F,0x47EA,{0x90,0x7F,0x89,0x53,0x53,0x4F,0x89,0xD6}};


const IID LIBID_BLOB_IOLib = {0x0AF39136,0x80FB,0x46F7,{0xAF,0x9D,0xAC,0x92,0x3A,0x4F,0x49,0x78}};


const CLSID CLSID_BLOB_io1 = {0x2F4BEFE0,0x6C41,0x491D,{0xB6,0x2A,0x20,0xAA,0x48,0x4F,0xC2,0x46}};


#ifdef __cplusplus
}
#endif

