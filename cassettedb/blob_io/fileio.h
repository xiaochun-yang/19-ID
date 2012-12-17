// BinFile.h: interface for the CBinFile class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_BINFILE_H__CA3B6341_4E0D_11D4_88AD_0050DAB8B19A__INCLUDED_)
#define AFX_BINFILE_H__CA3B6341_4E0D_11D4_88AD_0050DAB8B19A__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

class CBinFile  
{
public:
	int saveBinFile( char* fileName, char* data, int lng);
	int loadBinFile( SAFEARRAY** ppsa, long* size, char* fileName);
	CBinFile();
	virtual ~CBinFile();

};

#endif // !defined(AFX_BINFILE_H__CA3B6341_4E0D_11D4_88AD_0050DAB8B19A__INCLUDED_)
