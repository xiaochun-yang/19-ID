/* this ALWAYS GENERATED file contains the definitions for the interfaces */


/* File created by MIDL compiler version 5.01.0164 */
/* at Wed Nov 21 13:40:55 2001
 */
/* Compiler settings for T:\PROG\BLOB_io\BLOB_io.idl:
    Oicf (OptLev=i2), W1, Zp8, env=Win32, ms_ext, c_ext
    error checks: allocation ref bounds_check enum stub_data 
*/
//@@MIDL_FILE_HEADING(  )


/* verify that the <rpcndr.h> version is high enough to compile this file*/
#ifndef __REQUIRED_RPCNDR_H_VERSION__
#define __REQUIRED_RPCNDR_H_VERSION__ 440
#endif

#include "rpc.h"
#include "rpcndr.h"

#ifndef __RPCNDR_H_VERSION__
#error this stub requires an updated version of <rpcndr.h>
#endif // __RPCNDR_H_VERSION__

#ifndef COM_NO_WINDOWS_H
#include "windows.h"
#include "ole2.h"
#endif /*COM_NO_WINDOWS_H*/

#ifndef __BLOB_io_h__
#define __BLOB_io_h__

#ifdef __cplusplus
extern "C"{
#endif 

/* Forward Declarations */ 

#ifndef __IBLOB_io1_FWD_DEFINED__
#define __IBLOB_io1_FWD_DEFINED__
typedef interface IBLOB_io1 IBLOB_io1;
#endif 	/* __IBLOB_io1_FWD_DEFINED__ */


#ifndef __BLOB_io1_FWD_DEFINED__
#define __BLOB_io1_FWD_DEFINED__

#ifdef __cplusplus
typedef class BLOB_io1 BLOB_io1;
#else
typedef struct BLOB_io1 BLOB_io1;
#endif /* __cplusplus */

#endif 	/* __BLOB_io1_FWD_DEFINED__ */


/* header files for imported files */
#include "oaidl.h"
#include "ocidl.h"

void __RPC_FAR * __RPC_USER MIDL_user_allocate(size_t);
void __RPC_USER MIDL_user_free( void __RPC_FAR * ); 

#ifndef __IBLOB_io1_INTERFACE_DEFINED__
#define __IBLOB_io1_INTERFACE_DEFINED__

/* interface IBLOB_io1 */
/* [unique][helpstring][dual][uuid][object] */ 


EXTERN_C const IID IID_IBLOB_io1;

#if defined(__cplusplus) && !defined(CINTERFACE)
    
    MIDL_INTERFACE("55E74599-BE5F-47EA-907F-8953534F89D6")
    IBLOB_io1 : public IDispatch
    {
    public:
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE getBlobSize( 
            /* [in] */ VARIANT __RPC_FAR *pBlob,
            /* [retval][out] */ VARIANT __RPC_FAR *pBlobSize) = 0;
        
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE loadBinFile( 
            /* [in] */ BSTR bstrforName,
            /* [retval][out] */ VARIANT __RPC_FAR *pBlob) = 0;
        
        virtual /* [helpstring][id] */ HRESULT STDMETHODCALLTYPE saveBinFile( 
            /* [out][in] */ VARIANT __RPC_FAR *pBlob,
            /* [in] */ long lBlobSize,
            /* [in] */ BSTR bstrforName,
            /* [retval][out] */ VARIANT __RPC_FAR *pbstrResult) = 0;
        
    };
    
#else 	/* C style interface */

    typedef struct IBLOB_io1Vtbl
    {
        BEGIN_INTERFACE
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *QueryInterface )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ REFIID riid,
            /* [iid_is][out] */ void __RPC_FAR *__RPC_FAR *ppvObject);
        
        ULONG ( STDMETHODCALLTYPE __RPC_FAR *AddRef )( 
            IBLOB_io1 __RPC_FAR * This);
        
        ULONG ( STDMETHODCALLTYPE __RPC_FAR *Release )( 
            IBLOB_io1 __RPC_FAR * This);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetTypeInfoCount )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [out] */ UINT __RPC_FAR *pctinfo);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetTypeInfo )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ UINT iTInfo,
            /* [in] */ LCID lcid,
            /* [out] */ ITypeInfo __RPC_FAR *__RPC_FAR *ppTInfo);
        
        HRESULT ( STDMETHODCALLTYPE __RPC_FAR *GetIDsOfNames )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ REFIID riid,
            /* [size_is][in] */ LPOLESTR __RPC_FAR *rgszNames,
            /* [in] */ UINT cNames,
            /* [in] */ LCID lcid,
            /* [size_is][out] */ DISPID __RPC_FAR *rgDispId);
        
        /* [local] */ HRESULT ( STDMETHODCALLTYPE __RPC_FAR *Invoke )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ DISPID dispIdMember,
            /* [in] */ REFIID riid,
            /* [in] */ LCID lcid,
            /* [in] */ WORD wFlags,
            /* [out][in] */ DISPPARAMS __RPC_FAR *pDispParams,
            /* [out] */ VARIANT __RPC_FAR *pVarResult,
            /* [out] */ EXCEPINFO __RPC_FAR *pExcepInfo,
            /* [out] */ UINT __RPC_FAR *puArgErr);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE __RPC_FAR *getBlobSize )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ VARIANT __RPC_FAR *pBlob,
            /* [retval][out] */ VARIANT __RPC_FAR *pBlobSize);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE __RPC_FAR *loadBinFile )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [in] */ BSTR bstrforName,
            /* [retval][out] */ VARIANT __RPC_FAR *pBlob);
        
        /* [helpstring][id] */ HRESULT ( STDMETHODCALLTYPE __RPC_FAR *saveBinFile )( 
            IBLOB_io1 __RPC_FAR * This,
            /* [out][in] */ VARIANT __RPC_FAR *pBlob,
            /* [in] */ long lBlobSize,
            /* [in] */ BSTR bstrforName,
            /* [retval][out] */ VARIANT __RPC_FAR *pbstrResult);
        
        END_INTERFACE
    } IBLOB_io1Vtbl;

    interface IBLOB_io1
    {
        CONST_VTBL struct IBLOB_io1Vtbl __RPC_FAR *lpVtbl;
    };

    

#ifdef COBJMACROS


#define IBLOB_io1_QueryInterface(This,riid,ppvObject)	\
    (This)->lpVtbl -> QueryInterface(This,riid,ppvObject)

#define IBLOB_io1_AddRef(This)	\
    (This)->lpVtbl -> AddRef(This)

#define IBLOB_io1_Release(This)	\
    (This)->lpVtbl -> Release(This)


#define IBLOB_io1_GetTypeInfoCount(This,pctinfo)	\
    (This)->lpVtbl -> GetTypeInfoCount(This,pctinfo)

#define IBLOB_io1_GetTypeInfo(This,iTInfo,lcid,ppTInfo)	\
    (This)->lpVtbl -> GetTypeInfo(This,iTInfo,lcid,ppTInfo)

#define IBLOB_io1_GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)	\
    (This)->lpVtbl -> GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)

#define IBLOB_io1_Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)	\
    (This)->lpVtbl -> Invoke(This,dispIdMember,riid,lcid,wFlags,pDispParams,pVarResult,pExcepInfo,puArgErr)


#define IBLOB_io1_getBlobSize(This,pBlob,pBlobSize)	\
    (This)->lpVtbl -> getBlobSize(This,pBlob,pBlobSize)

#define IBLOB_io1_loadBinFile(This,bstrforName,pBlob)	\
    (This)->lpVtbl -> loadBinFile(This,bstrforName,pBlob)

#define IBLOB_io1_saveBinFile(This,pBlob,lBlobSize,bstrforName,pbstrResult)	\
    (This)->lpVtbl -> saveBinFile(This,pBlob,lBlobSize,bstrforName,pbstrResult)

#endif /* COBJMACROS */


#endif 	/* C style interface */



/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE IBLOB_io1_getBlobSize_Proxy( 
    IBLOB_io1 __RPC_FAR * This,
    /* [in] */ VARIANT __RPC_FAR *pBlob,
    /* [retval][out] */ VARIANT __RPC_FAR *pBlobSize);


void __RPC_STUB IBLOB_io1_getBlobSize_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE IBLOB_io1_loadBinFile_Proxy( 
    IBLOB_io1 __RPC_FAR * This,
    /* [in] */ BSTR bstrforName,
    /* [retval][out] */ VARIANT __RPC_FAR *pBlob);


void __RPC_STUB IBLOB_io1_loadBinFile_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);


/* [helpstring][id] */ HRESULT STDMETHODCALLTYPE IBLOB_io1_saveBinFile_Proxy( 
    IBLOB_io1 __RPC_FAR * This,
    /* [out][in] */ VARIANT __RPC_FAR *pBlob,
    /* [in] */ long lBlobSize,
    /* [in] */ BSTR bstrforName,
    /* [retval][out] */ VARIANT __RPC_FAR *pbstrResult);


void __RPC_STUB IBLOB_io1_saveBinFile_Stub(
    IRpcStubBuffer *This,
    IRpcChannelBuffer *_pRpcChannelBuffer,
    PRPC_MESSAGE _pRpcMessage,
    DWORD *_pdwStubPhase);



#endif 	/* __IBLOB_io1_INTERFACE_DEFINED__ */



#ifndef __BLOB_IOLib_LIBRARY_DEFINED__
#define __BLOB_IOLib_LIBRARY_DEFINED__

/* library BLOB_IOLib */
/* [helpstring][version][uuid] */ 


EXTERN_C const IID LIBID_BLOB_IOLib;

EXTERN_C const CLSID CLSID_BLOB_io1;

#ifdef __cplusplus

class DECLSPEC_UUID("2F4BEFE0-6C41-491D-B62A-20AA484FC246")
BLOB_io1;
#endif
#endif /* __BLOB_IOLib_LIBRARY_DEFINED__ */

/* Additional Prototypes for ALL interfaces */

unsigned long             __RPC_USER  BSTR_UserSize(     unsigned long __RPC_FAR *, unsigned long            , BSTR __RPC_FAR * ); 
unsigned char __RPC_FAR * __RPC_USER  BSTR_UserMarshal(  unsigned long __RPC_FAR *, unsigned char __RPC_FAR *, BSTR __RPC_FAR * ); 
unsigned char __RPC_FAR * __RPC_USER  BSTR_UserUnmarshal(unsigned long __RPC_FAR *, unsigned char __RPC_FAR *, BSTR __RPC_FAR * ); 
void                      __RPC_USER  BSTR_UserFree(     unsigned long __RPC_FAR *, BSTR __RPC_FAR * ); 

unsigned long             __RPC_USER  VARIANT_UserSize(     unsigned long __RPC_FAR *, unsigned long            , VARIANT __RPC_FAR * ); 
unsigned char __RPC_FAR * __RPC_USER  VARIANT_UserMarshal(  unsigned long __RPC_FAR *, unsigned char __RPC_FAR *, VARIANT __RPC_FAR * ); 
unsigned char __RPC_FAR * __RPC_USER  VARIANT_UserUnmarshal(unsigned long __RPC_FAR *, unsigned char __RPC_FAR *, VARIANT __RPC_FAR * ); 
void                      __RPC_USER  VARIANT_UserFree(     unsigned long __RPC_FAR *, VARIANT __RPC_FAR * ); 

/* end of Additional Prototypes */

#ifdef __cplusplus
}
#endif

#endif
