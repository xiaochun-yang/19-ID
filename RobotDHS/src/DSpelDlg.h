#pragma once
#include "spelcomctrl1.h"
#include "resource2.h"

class RobotEpson;

// CDSpelDlg dialog

class CDSpelDlg : public CDialog
{
	DECLARE_DYNAMIC(CDSpelDlg)

public:
	BOOL Initialize( RobotEpson* );

	CDSpelDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~CDSpelDlg();

// Dialog Data
	enum { IDD = IDD_DIALOG1 };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	RobotEpson* p_Robot;

	DECLARE_MESSAGE_MAP()
public:
	CSpelcomctrl1 m_spelcom;
	DECLARE_EVENTSINK_MAP()
	void EventReceivedSpelcomctrl1(long EventNumber, LPCTSTR EventMessage);
};
