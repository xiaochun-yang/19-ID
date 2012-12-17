// SpelDlg.cpp : implementation file
//

#include "stdafx.h"
#include "resource.h"
#include "spelDlg.h"
#include "log_quick.h"
#include "RobotEpson.h"


#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CSpelDlg dialog


CSpelDlg::CSpelDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CSpelDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CSpelDlg)
	//}}AFX_DATA_INIT
}


void CSpelDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CSpelDlg)
	DDX_Control(pDX, IDC_SPELCOMCTRL1, m_spelcom);
	//}}AFX_DATA_MAP
}


BEGIN_MESSAGE_MAP(CSpelDlg, CDialog)
	//{{AFX_MSG_MAP(CSpelDlg)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CSpelDlg message handlers

BOOL CSpelDlg::OnInitDialog() 
{
	CDialog::OnInitDialog();
	
	
	return FALSE;  // return TRUE unless you set the focus to a control
	              // EXCEPTION: OCX Property Pages should return FALSE
}


BOOL CSpelDlg::Initialize( RobotEpson* RobotPtr )
{

	// Create modeless, invisible dialog
	if (!Create(IDD_SPEL))
		return FALSE; 

	p_Robot = RobotPtr;

	m_spelcom.SetPortOpen(true);

	// Uncomment the line below if using the security option
	
	// m_spelcom.LogIn("admin", "");
	return TRUE;

}


BEGIN_EVENTSINK_MAP(CSpelDlg, CDialog)
    //{{AFX_EVENTSINK_MAP(CSpelDlg)
	ON_EVENT(CSpelDlg, IDC_SPELCOMCTRL1, 2 /* EventReceived */, OnEventReceivedSpelcomctrl1, VTS_I4 VTS_BSTR)
	//}}AFX_EVENTSINK_MAP
END_EVENTSINK_MAP()

void CSpelDlg::OnEventReceivedSpelcomctrl1(long EventNumber, LPCTSTR EventMessage) 
{
	if (p_Robot->m_InEventProcess)
	{
		LOG_WARNING( "received another event during event processing" );
	}

	InEventHolder hold_a_boolean( &p_Robot->m_InEventProcess );
	switch ( EventNumber ) 
	{
		//SYSTEM EVENT
		case 1:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d PAUSE", EventNumber );
			break;
		case 2:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d SAFE GUARD OPEN", EventNumber );

			if (p_Robot->m_pEventListener)
			{
				static const char message[] = "Safeguard latched";
				p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
				p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
			}

			p_Robot->SetRobotFlags ( FLAG_REASON_SAFEGUARD );
			p_Robot->Abort( ); //flag only
			break;
		case 3:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d SAFE GUARD CLOSED", EventNumber );
			break;
		case 4:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d PROJECT BUILD STATUS", EventNumber );
			break;
		case 5:
			LOG_FINEST2( "In ServiceEvents -- EventNumber = %d GENERAL ERROR %s", EventNumber, EventMessage );
			{
                //retrieve errNo
                long errNo = 0;

                if (sscanf( EventMessage, "%*s %ld", &errNo ) == 1)
                {
					LOG_FINEST1( "got errno=%ld in events", errNo );
				    switch(errNo)
				    {
				    case 173:
                    case 174:
					case 5040:
					case 5041:
    				    p_Robot->SetRobotFlags( FLAG_REASON_COLLISION );
						if (p_Robot->m_pEventListener)
						{
							char message[] = "robot collision detected";
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, message );
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
						}
                        break;

                    case 125:
    				    p_Robot->SetRobotFlags( FLAG_REASON_UNREACHABLE );
						if (p_Robot->m_pEventListener)
						{
							char message[] = "unreachable position";
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
						}
                        break;

					case 620:
					case 621:
					case 4003:
					case 4026:
					case 4027:
					case 4028:
					case 4029:
						if (p_Robot->m_pEventListener)
						{
							char message[] = "Robot Drive Unit Error: Please check its power and recycle power of all robot modules";
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, message );
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
						}
						break;

					default:
						if (p_Robot->m_pEventListener)
						{
							char message[512] = {0};
							strcpy( message, "Robot reported following error: " );
							size_t left_space = sizeof(message) - 1 - strlen( message );
							strncat( message, EventMessage, left_space );
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
							p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
						}
						break;
				    }
                }
			}
		    p_Robot->SetRobotFlags( FLAG_REASON_ABORT );
			break;
		case 6:
            LOG_FINEST2( "In ServiceEvents -- EventNumber = %d USER PRINT: %s", EventNumber, EventMessage );
			break;
		case 7:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d ESTOP ON", EventNumber );
			if (p_Robot->m_pEventListener)
			{
				static const char message[] = "Emergency Stop";
				p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
				p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
			}
			p_Robot->SetRobotFlags ( FLAG_REASON_ESTOP );

			//select one
			p_Robot->m_NeedBringUp = true;
			//p_Robot->Abort( ); //this will kill all tasks.

			break;
		case 8:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d ESTOP OFF", EventNumber );
			break;

		//USER DEFINED EVENT
		case RobotEventListener::EVTNUM_LID_OPEN:
			LOG_FINEST1( "In ServiceEvents -- EventNumber = %d LID OPEN MANUALLY", EventNumber );
			p_Robot->LidOpenCallback( );
			break;

		case RobotEventListener::EVTNUM_INPUT:
		case RobotEventListener::EVTNUM_OUTPUT:
			//1 call per second too many to log
			//LOG_FINEST2( "In ServiceEvents -- EventNumber = %d INPUT BITS", EventNumber, EventMessage );
			//make sure it will be passed out
			p_Robot->IOBitMonitor( EventNumber, EventMessage );
			return;

		default:
			if (EventNumber < RobotEventListener::EVTNUM_LID_OPEN)
			{
				if (p_Robot->m_pEventListener)
				{
					char message[2048] = {0};
					sprintf( message, "In ServiceEvents -- UNKNOWN EVENT EventNumber = %d", EventNumber );
					p_Robot->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
				}
				LOG_FINEST2( "In ServiceEvents -- UNKNOWN EVENT EventNumber = %d EventMessage=%s", EventNumber, EventMessage );
			}
	}

    //call event listners
    if (p_Robot->m_pEventListener && p_Robot->m_EventEnabled)
    {
        p_Robot->m_pEventListener->OnRobotEvent( EventNumber, EventMessage );
    }
}
