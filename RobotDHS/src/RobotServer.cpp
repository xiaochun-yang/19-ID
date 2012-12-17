#include "stdafx.h"
#include "RobotServer.h"
#include "SendClientType_Message.h"
#include "RegisterOperation_Message.h"
#include "SoftAbort_Message.h"
#include "MoveTongHome_Message.h"
#include "CoolingTong_Message.h"
#include "PortPostShuttle_Message.h"
#include "PortPostShuttleNext_Message.h"
#include "PortPostShuttleSort_Message.h"
#include "OnPickerAtPostToGoniometer_Message.h"
#include "GoniometerToOnPlacerAtPost_Message.h"
#include "MoveToCheckPoint_Message.h"
#include "CheckDumbbell_Message.h"
#include "ReturnDumbbell_Message.h"
#include "GetRobotState_Message.h"
#include "ResetAllowed_Message.h"
#include "HeatGripper_Message.h"
#include "OpenGripper_Message.h"
#include "CalibrateTool_Message.h"
#include "CalibrateDewar_Message.h"

RobotServer::RobotServer ( ) : CreateOperation ( )
{
	p_StartMsgThrdEvnt = new CEvent ( );

	p_RunQuitEvnt = new CEvent ( );
	p_MonitorQuitEvnt = new CEvent ( );


	m_CRegistry.SetRootKey ( HKEY_LOCAL_MACHINE );

	CWinThread* p_Runthread = AfxBeginThread ( Run, this, THREAD_PRIORITY_NORMAL );

	if ( WaitForSingleObject ( p_StartMsgThrdEvnt->m_hObject, INFINITE ) == WAIT_OBJECT_0 )
	{	
		CWinThread* p_Monitorthread = AfxBeginThread ( Monitor, this, THREAD_PRIORITY_NORMAL );
		if ( m_CRegistry.SetKey("Software\\ROBOT\\RobotControl", FALSE ) )
			m_DcsMessageHandler.SetServerInfo( m_CRegistry.ReadString ( "blctlAddress", "" ), m_CRegistry.ReadInt ( "blctlPort", 0 ) );		
		SetOperations ( );
		CreateOperationStart ( );
		cnswriter ( "*** Robot is alive and well! ***\n\n" );
	}
	else
	{
		cnswriter ( "*** Trouble starting Robot thread *** \n" );
	}

	delete p_StartMsgThrdEvnt;
}

RobotServer::~RobotServer ( )
{
	p_RunQuitEvnt->SetEvent ( );
	p_MonitorQuitEvnt->SetEvent ( );
	delete [] operationList;
	delete p_RunQuitEvnt;
	delete p_MonitorQuitEvnt;
}
	
void RobotServer::SetOperations ( void )
{
	numoperations = 19;		
	operationList = new const char* [numoperations];

	operationList[0] = "stoc_send_client_type";
	operationList[1] = "stoh_register_operation";
	operationList[2] = "stoh_abort_all";
	operationList[3] = "get_robotstate"; /*do NOT change the operationlist number (3) of get_robotstate */
	operationList[4] = "reset_allowed";
	operationList[5] = "move_tong_home";
	operationList[6] = "cooling_tong";
	operationList[7] = "port_post_shuttle";
	operationList[8] = "port_post_shuttle_next";
	operationList[9] = "onpickeratpost_to_goniometer";
	operationList[10] = "goniometer_to_onplaceratpost";
	operationList[11] = "move_to_checkpoint";
	operationList[12] = "check_dumbbell";
	operationList[13] = "return_dumbbell";
	operationList[14] = "open_gripper";
	operationList[15] = "heat_gripper";
	operationList[16] = "calibrate_tool";
	operationList[17] = "calibrate_dewar";
	operationList[18] = "port_post_shuttle_sort";
}


DcsMessage* RobotServer::CreateMessage ( const DcsMessage& m_dcsMessage )
{
	DcsMessage* p_dcsMessage = 0;

	switch ( m_dcsMessage.id )
	{
		case 0: 
			p_dcsMessage = new SendClientType ( &m_DcsMessageHandler );
			break;
		case 1:
			p_dcsMessage = new RegisterOperation ( );
			break;
		case 2:
			p_dcsMessage = new SoftAbort ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 3:
			p_dcsMessage = new GetRobotState ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 4:
			p_dcsMessage = new ResetAllowed ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 5:
			p_dcsMessage = new MoveTongHome ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 6:
			p_dcsMessage = new CoolingTong ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 7:
			p_dcsMessage = new PortPostShuttle ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 8:
			p_dcsMessage = new PortPostShuttleNext ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 9:
			p_dcsMessage = new OnPickerAtPostToGoniometer ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 10:
			p_dcsMessage = new GoniometerToOnPlacerAtPost ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 11:
			p_dcsMessage = new MoveToCheckPoint ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 12:
			p_dcsMessage = new CheckDumbbell ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 13:
			p_dcsMessage = new ReturnDumbbell ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 14:
			p_dcsMessage = new OpenGripper ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 15:
			p_dcsMessage = new HeatGripper ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 16:
			p_dcsMessage = new CalibrateTool ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 17:
			p_dcsMessage = new CalibrateDewar ( &m_DcsMessageHandler, &m_Robot );
			break;
		case 18:
			p_dcsMessage = new PortPostShuttleSort ( &m_DcsMessageHandler, &m_Robot );
			break;
		default:
			p_dcsMessage = new RegisterOperation ( );
			break;
	}

	p_dcsMessage->textBuffer = new char [ strlen(m_dcsMessage.textBuffer) + 1 ];

	strcpy ( p_dcsMessage->textBuffer, m_dcsMessage.textBuffer );

	p_dcsMessage->id = m_dcsMessage.id;
	
	return p_dcsMessage;
}

UINT RobotServer::Run ( LPVOID pThisRun )
{
	RobotServer* stPtr = ( RobotServer* )pThisRun;
	return stPtr->Run_thread ( );
}

UINT RobotServer::Run_thread ( void )
{

	// Inelegant to put robot here, but keeps CSpel in one thread:

	p_RunQuitEvnt->ResetEvent ( );

	CoInitialize (0);

	CSpel m_CSpel;

	HANDLE h[3];
	h[0] = m_MQueue.pSyncEvnt->m_hObject;
	h[1] = p_RunQuitEvnt->m_hObject;
	DWORD retObj;

	m_CSpel.Initialize ( &m_Robot );

	m_CSpel.spelcom.Reset ( );

	m_Robot.Initialize ( &m_CSpel, &m_CRegistry );

	m_Robot.SetRobotFlags ( DHS_OFFLINE );

	p_StartMsgThrdEvnt->SetEvent ( );

	while ( true )
	{	
		switch ( retObj = MsgWaitForMultipleObjectsEx ( 2, h, INFINITE, QS_ALLINPUT, 0 ) )
		{
			case WAIT_OBJECT_0 + 0:
				while ( !m_MQueue.IsEmpty ( )  )
				{
					DcsMessage* p_dcsMessage = 0;
					p_dcsMessage = m_MQueue.RemoveHeadMQueue ( );
					p_dcsMessage->Do ( );
					delete p_dcsMessage;
				}
				m_MQueue.pSyncEvnt->ResetEvent ( );
				break;
			case WAIT_OBJECT_0 + 1:
				m_CSpel.~CSpel ( );
				CoUninitialize ( );
				AfxEndThread ( 0, true );
				break;
			case WAIT_OBJECT_0 + 2:
				DoEvents ( );
		}
	}
	return 0;
}

UINT RobotServer::Monitor ( LPVOID pThisMonitor )
{
	RobotServer* stPtr = ( RobotServer* )pThisMonitor;
	return stPtr->Monitor_thread ( );
}

UINT RobotServer::Monitor_thread ( void )
{
	p_RunQuitEvnt->ResetEvent ( );

	HANDLE h[3];
	h[0] = m_MonitorMQueue.pSyncEvnt->m_hObject;
	h[1] = p_MonitorQuitEvnt->m_hObject;
	DWORD retObj; 

	while ( true )
	{	
		switch ( retObj = MsgWaitForMultipleObjectsEx ( 2, h, INFINITE, QS_ALLINPUT, 0 ) )
		{
			case WAIT_OBJECT_0 + 0:
				while ( !m_MonitorMQueue.IsEmpty ( )  )
				{
					DcsMessage* p_dcsMessage = 0;
					p_dcsMessage = m_MonitorMQueue.RemoveHeadMQueue ( );
					p_dcsMessage->Do ( );
					delete p_dcsMessage;
				}
				m_MonitorMQueue.pSyncEvnt->ResetEvent ( );
				break;
			case WAIT_OBJECT_0 + 1:
				AfxEndThread ( 0, true );
				break;
			case WAIT_OBJECT_0 + 2:
				DoEvents ( );
		}
	}
	return 0;
}
void RobotServer::DoEvents ( )
{
	MSG	msg;
	long sts;

	do {
		if (sts = PeekMessage(&msg, (HWND) NULL, 0, 0, PM_REMOVE)) { 
    		TranslateMessage(&msg);
    		DispatchMessage(&msg);
		}
	} while (sts);
}

void RobotServer::Delay(DWORD ms) 
{
	DWORD start;

	start = GetTickCount();
	do {
		Sleep(10);
		DoEvents();
	} while (GetTickCount() - start < ms);
}

