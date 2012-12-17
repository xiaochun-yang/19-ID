// BLOB_io1.h : Declaration of the CBLOB_io1

#ifndef __BLOB_IO1_H_
#define __BLOB_IO1_H_

#include "resource.h"       // main symbols

/////////////////////////////////////////////////////////////////////////////
// CBLOB_io1
class ATL_NO_VTABLE CBLOB_io1 : 
	public CComObjectRootEx<CComSingleThreadModel>,
	public CComCoClass<CBLOB_io1, &CLSID_BLOB_io1>,
	public IDispatchImpl<IBLOB_io1, &IID_IBLOB_io1, &LIBID_BLOB_IOLib>
{
public:
	CBLOB_io1()
	{
	}

DECLARE_REGISTRY_RESOURCEID(IDR_BLOB_IO1)

DECLARE_PROTECT_FINAL_CONSTRUCT()

BEGIN_COM_MAP(CBLOB_io1)
	COM_INTERFACE_ENTRY(IBLOB_io1)
	COM_INTERFACE_ENTRY(IDispatch)
END_COM_MAP()

// IBLOB_io1
public:
	STDMETHOD(saveBinFile)(/*[in,out]*/ VARIANT* pBlob,/*[in]*/ long lBlobSize,/*[in]*/ BSTR bstrforName,/*[out,retval]*/ VARIANT* pbstrResult);
	STDMETHOD(loadBinFile)(/*[in]*/ BSTR bstrforName,/*[out,retval]*/ VARIANT* pBlob);
	STDMETHOD(getBlobSize)(/*[in]*/ VARIANT* pBlob,/*[out,retval]*/ VARIANT* pBlobSize);
};

#endif //__BLOB_IO1_H_
