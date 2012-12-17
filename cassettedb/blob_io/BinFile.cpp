// BinFile.cpp: implementation of the CBinFile class.
//
//////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "BinFile.h"

// WIN32,NDEBUG,_WINDOWS,_USRDLL,_UNICODE,_ATL_STATIC_REGISTRY,_ATL_MIN_CRT
// 
#include <stdio.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CBinFile::CBinFile()
{

}

CBinFile::~CBinFile()
{

}

int CBinFile::loadBinFile(SAFEARRAY **ppsa, long *size, char *fileName)
{
    SAFEARRAY* psa= NULL;
	char* psafebuf= NULL;
	int errorCode= -1;
	FILE* f= NULL;
	char* buf= NULL;
	long flng= 0;
	fpos_t pos;
	HRESULT hr= 0;
	long l;
	
	if( ppsa==NULL || size==NULL || fileName==NULL)
	{
		return -1;
	}
	*ppsa= NULL;
	*size= 0;

	//tr_msg(__FILE__, __LINE__,"loadBinFile() %s", fileName);

	f= fopen( fileName, "rb");
	if( f==NULL)
	{
		//tr_err(__FILE__, __LINE__, "Error fopen %s\n", fileName);
		goto ret;
	}
	if( 0!=fseek(f,0,SEEK_END))
	{
		//tr_err(__FILE__, __LINE__, "Error fseek SEEK_END %s\n", fileName);
		goto ret;
	}
	
	// get length of file
	pos= 0;
	if( 0!=fgetpos(f,&pos) || pos<=0)
	{
		//tr_err(__FILE__, __LINE__, "Error fgetpos %s\n", fileName);
		goto ret;
	}
	flng= (long)pos;
	if( 0!=fseek(f,0,SEEK_SET))
	{
		//tr_err(__FILE__, __LINE__, "Error fseek SEEK_SET %s\n", fileName);
		goto ret;
	}

	// alloc memory and read file
	buf= (char*) malloc(flng);
	if( buf==NULL)
	{
		//tr_err(__FILE__, __LINE__, "Error malloc %d\n", flng);
		goto ret;
	}
	if( flng!=(long)fread(buf,1,flng,f))
	{
		//tr_err(__FILE__, __LINE__, "Error fread %d\n", flng);
		goto ret;
	}
	if( 0!=fclose(f))
	{
		//tr_err(__FILE__, __LINE__, "Error fclose %s\n", fileName);
		f= NULL;
		goto ret;
	}
	f= NULL;

	//put the pixels into a safearray
	psa= SafeArrayCreateVector(VT_UI1,0,flng);
    if(psa == NULL)
	{
		errorCode= -3;
		goto ret;
	}
	// Get a pointer to the elements of the array.
	hr = SafeArrayAccessData(psa, (void **)&psafebuf);
	if( FAILED(hr))
	{
		errorCode= -4;
		goto ret;
	}
	for( l = 0; l<flng; l++)
	{
		psafebuf[l]= buf[l];
	}
	free( buf);
	buf= NULL;
	hr = SafeArrayUnaccessData(psa);
	psafebuf= NULL;
	if( FAILED(hr))
	{
		errorCode= -5;
		goto ret;
	}
	
	// OK
	*ppsa= psa;
	*size= flng;
	errorCode= 0;

	//tr_msg(__FILE__, __LINE__,"loadBinFile() OK %s", fileName);

ret:
	if( f!=NULL)
	{
		fclose(f);
	}
	if( buf!=NULL)
	{
		free( buf);
	}
	return errorCode;
}

//=====================================

int CBinFile::saveBinFile(char *fileName, char *data, int lng)
{
	FILE* f;
	int h;

	//tr_msg(__FILE__, __LINE__, "saveBinFile() %s", fileName);
	f = fopen( fileName, "wb");
	if( f == NULL)
	{
		//tr_err(__FILE__, __LINE__, "Error opening save preferences file %s", fileName);
		return 0;
	}

	h = fwrite( data, 1, lng, f);
	if( h != lng)
	{
		fclose(f);
		//tr_err(__FILE__, __LINE__, "Save preferences file %s write error", fileName);
		return h;
	}

	fclose(f);
	//tr_msg(__FILE__, __LINE__, "saveBinFile() OK");
    return h;
}

//=====================================
