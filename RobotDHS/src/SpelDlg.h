//{{AFX_INCLUDES()
#include "spelcom3.h"
#include "resource.h"
//}}AFX_INCLUDES
#if !defined(AFX_SPELDLG_H__D61F0303_31BD_11D4_A94A_00104B113D60__INCLUDED_)
#define AFX_SPELDLG_H__D61F0303_31BD_11D4_A94A_00104B113D60__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000
// SpelDlg.h : header file
//

/////////////////////////////////////////////////////////////////////////////
// CSpelDlg dialog
class RobotEpson;

class CSpelDlg : public CDialog
{
// Construction
public:
	BOOL Initialize( RobotEpson* );
	CSpelDlg(CWnd* pParent = NULL);   // standard constructor

// Dialog Data
	//{{AFX_DATA(CSpelDlg)
	enum { IDD = IDD_SPEL };
	CSPELCom3	m_spelcom;
	//}}AFX_DATA


// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CSpelDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	RobotEpson* p_Robot;

	// Generated message map functions
	//{{AFX_MSG(CSpelDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnEventReceivedSpelcomctrl1(long EventNumber, LPCTSTR EventMessage);
	DECLARE_EVENTSINK_MAP()
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_SPELDLG_H__D61F0303_31BD_11D4_A94A_00104B113D60__INCLUDED_)
