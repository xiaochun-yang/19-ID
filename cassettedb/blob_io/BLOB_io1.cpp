// BLOB_io1.cpp : Implementation of CBLOB_io1
#include "stdafx.h"
#include "BLOB_io.h"
#include "BLOB_io1.h"

#include "BinFile.h"


/////////////////////////////////////////////////////////////////////////////
// CBLOB_io1


STDMETHODIMP CBLOB_io1::getBlobSize(VARIANT *pBlob, VARIANT *pBlobSize)
{
	// TODO: Add your implementation code here
	HRESULT hr= 0;
    SAFEARRAY* psa= NULL;
	long errorCode= 0;
	long lSize;

	lSize= 0;

	// free old variant resources
	hr= VariantClear( pBlobSize);
	if( FAILED(hr))
	{
		//errorCode= -1;
		//goto ret;
		VariantInit( pBlobSize);
	}

    //Verify the Variant contains SafeArray
	if( ((pBlob->vt) & VT_ARRAY)==0 )
	{
		errorCode= -2;
		goto ret;
	}
	psa= pBlob->parray;
	if( psa==NULL)
	{
		errorCode= -3;
		goto ret;
	}
	// get number of SafeArray elements
    if( SafeArrayGetDim(psa) == 1)
	{
		long UpperBounds= 0;
		long LowerBounds= 0;;
		SafeArrayGetLBound(psa, 1, &LowerBounds);
		SafeArrayGetUBound(psa, 1, &UpperBounds);
		//if( LowerBounds!=0 || (UpperBounds+1)!=lBlobSize)
		if( LowerBounds!=0 || UpperBounds<0)
		{
			errorCode= -4;
			goto ret;
		}
		lSize= UpperBounds+1;
	}
	else
	{
		errorCode= -5;
		goto ret;
	}

	// OK

ret:
	pBlobSize->vt= VT_I4;
	pBlobSize->lVal= lSize;
	//pErrorCode->vt= VT_I4;
	//pErrorCode->lVal= errorCode;
	if( errorCode!=0)
	{
		//return E_INVALIDARG;
		return S_OK;
	}
	return S_OK;
}

//==============================================================================

STDMETHODIMP CBLOB_io1::loadBinFile(BSTR bstrforName, VARIANT *pBlob)
{
	// TODO: Add your implementation code here
	// TODO: Add your implementation code here
	HRESULT hr= 0;
    SAFEARRAY* psa= NULL;
	char* pbuf= NULL;
	long errorCode= 0;
	char szName[300];
	long l= 0;
	long lSize= 0;
	VARIANT var;
	CBinFile binf;

	var.vt= 0;
	var.lVal= 0;
	memset( szName, 0, sizeof(szName));

	// convert BSTR --> char[]
	l= WideCharToMultiByte( CP_ACP,0, bstrforName,-1, szName, sizeof(szName)-1,NULL,NULL);
	
	// free old variant resources
	hr= VariantClear( pBlob);
	if( FAILED(hr))
	{
		//errorCode= -1;
		//goto ret;
		VariantInit( pBlob);
	}
	
	lSize= 0;
	psa= NULL;
	hr= 0;
	hr= binf.loadBinFile(&psa, &lSize, szName);
		
	if( hr!=0 || psa==NULL || lSize<=0)
	{
		errorCode= -2;
		goto ret;
	}

	// read element on index=1 to test if the SafeArray is OK
	l= 1;
	hr = SafeArrayGetElement(psa, &l, &var);
	if( FAILED(hr))
	{
		errorCode= -6;
		goto ret;
	}

	// file OK
	errorCode= 0;
	pBlob->vt= VT_ARRAY|VT_UI1;
	pBlob->parray= psa;
	

ret:
	//pErrorCode->vt= VT_I4;
	//pErrorCode->lVal= errorCode;
	if( errorCode!=0)
	{
		return E_INVALIDARG;
	}
	return S_OK;
}

//==============================================================================

STDMETHODIMP CBLOB_io1::saveBinFile(VARIANT *pBlob, long lBlobSize, BSTR bstrforName, VARIANT *pbstrResult)
{
	// TODO: Add your implementation code here
	HRESULT hr= 0;
    SAFEARRAY* psa= NULL;
	char* pbuf= NULL;
	long errorCode= 0;
	char* pData;
	BSTR bstrResult;
	char szName[300];
	long l;
	long lSize;
	VARIANT var;
	CBinFile binf;

	bstrResult= NULL;
	pData= NULL;
	var.vt= 0;
	var.lVal= 0;
	memset( szName, 0, sizeof(szName));

	// convert BSTR --> char[]
	l= WideCharToMultiByte( CP_ACP,0, bstrforName,-1, szName, sizeof(szName)-1,NULL,NULL);
	
	// free old variant resources
	hr= VariantClear( pbstrResult);
	if( FAILED(hr))
	{
		//errorCode= -1;
		//goto ret;
		VariantInit( pbstrResult);
	}

    //Verify the Variant contains SafeArray
	if( ((pBlob->vt) & VT_ARRAY)==0 )
	{
		errorCode= -2;
		goto ret;
	}
	psa= pBlob->parray;
	if( psa==NULL)
	{
		errorCode= -3;
		goto ret;
	}
	// verify number of SafeArray elements
    if( SafeArrayGetDim(psa) == 1)
	{
		long UpperBounds= 0;
		long LowerBounds= 0;;
		SafeArrayGetLBound(psa, 1, &LowerBounds);
		SafeArrayGetUBound(psa, 1, &UpperBounds);
		//if( LowerBounds!=0 || (UpperBounds+1)!=lBlobSize)
		if( LowerBounds!=0 || (UpperBounds+1)<lBlobSize)
		{
			//errorCode= -4;
			errorCode= UpperBounds;
			//errorCode= LowerBounds;
			goto ret;
		}
	}
	else
	{
		errorCode= -5;
		goto ret;
	}

	pData= NULL;
	// Get a pointer to the elements of the array
	hr = SafeArrayAccessData(psa, (void **)&pData);
	if( FAILED(hr))
	{
		errorCode= -6;
		goto ret;
	}
	
	lSize= 0;
	lSize= binf.saveBinFile( szName, pData, lBlobSize);
	// free the pointer to the elements of the array
	hr = SafeArrayUnaccessData(psa);
	pData= NULL;
	if( FAILED(hr))
	{
		errorCode= -7;
		goto ret;
	}

	// OK
	bstrResult= SysAllocString( L"OK");
	errorCode= 0;
	pbstrResult->vt= VT_BSTR;
	pbstrResult->bstrVal= bstrResult;
	
ret:
	//pErrorCode->vt= VT_I4;
	//pErrorCode->lVal= errorCode;
	if( errorCode!=0)
	{
		return E_INVALIDARG;
	}

	return S_OK;
}

//==============================================================================
