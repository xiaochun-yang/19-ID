
#include "RobotEpson.h"
//#include "RobotSim.h"
#include "robotservice.h"
#include "DcsMessageManager.h"
#include "Robot.h"
#include "log_quick.h"

void robotSystemStop( void );

#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))

//All prepare_XXXXXXXXX messages will need 2 reply (1 update, 1 final)
//One is almost immediately to check whether the state/status is allowed
//to do the prepare, the other is sent at the end of prepare.
//This is because that DCSS can use the first reply to decide whether
//start move motors around to prepare for the following operation too.
//The content of update message is NOT checked for now
//
// following operations should go together.  The reason for cutting them into
// 3 phases is to parallel prepare_xxxxx with some other no-robot operation
// and release system during robot_standby operation
//
// prepare_mount_crystal + mount_crystal + robot_standby
// prepare_dismount_crystal + dismount_crystal + robot_standby
// prepare_mount_next_crystal + mount_next_crystal + robot_standby
// prepare_move_crystal + move_crystal + robot_standby
// prepare_wash_crystal + wash_crystal + robot_standby
//
// 
//
//
RobotService::OperationToMethod RobotService::m_OperationMap[] =
{//  name,								immediately, method to call                     timeout (in seconds) to go home after operation
	{"get_robotstate",					TRUE,  &RobotService::GetRobotState,             0},

	{"prepare_mount_crystal",           FALSE, &RobotService::PrepareMountCrystal,       300},
	{"mount_crystal",                   FALSE, &RobotService::MountCrystal,              30},

	{"prepare_dismount_crystal",		FALSE, &RobotService::PrepareDismountCrystal,    300},
	{"dismount_crystal",				FALSE, &RobotService::DismountCrystal,           4},

	{"prepare_mount_next_crystal",		FALSE, &RobotService::PrepareMountNextCrystal,   300},
	{"mount_next_crystal",				FALSE, &RobotService::MountNextCrystal,          30},

    {"prepare_move_crystal",			FALSE, &RobotService::PrepareMoveCrystal,        4},
	{"move_crystal",					FALSE, &RobotService::MoveCrystal,               4},

    {"prepare_wash_crystal",			FALSE, &RobotService::PrepareWashCrystal,        300},
	{"wash_crystal",					FALSE, &RobotService::WashCrystal,               30},

    {"robot_standby",                   FALSE, &RobotService::Standby,                   0},

	{"robot_config",					FALSE, &RobotService::RobotConfig,               0},
	
	{"robot_calibrate",					FALSE, &RobotService::RobotCalibrate,            0}
};

//DCSStrings are like distributed global variables.  It is pushed out when it changes.
//DCSStrings supported in robot
RobotService::StringList RobotService::m_StringMap[] =
{
	//name				//name length	//write		//read 		//Msg Latest
	{"robot_status",	12,				true,		false,		NULL},
	{"robot_state",		11,				true,		false,		NULL},
	{"robot_cassette",	14,				true,		false,		NULL},
	{"robot_sample",	12,				true,		false,		NULL},
	{"robot_attribute",	15,				false,		true,		NULL},
	{"robot_input",		11,				true,		false,		NULL},
	{"robot_output",	12,				true,		false,		NULL}
};

const char* RobotService::ms_StringStatus(m_StringMap[0].m_StringName);
//the robot_staus is a text string with fields:
//0: "status:"
//1: status_num         0- 400000000
//2: "need_reset:"
//3: need_reset         0 or 1
//4: "need_cal:"
//5: need_calibration   0 or 1
//6: "state:"
//7: state              {idle} {prepare_mount_crystal}
//8: "warning:"
//9: warning message    {empty port in mounting}
//10:"cal_msg:"
//11:calibration message {touching seat} {....}
//12:"cal_step:"
//13:calibration steps  {d of d} {+d} {-d}
//14:"mounted:"
//15:{} or port position been mounted like {l 4 A}
//16:"pin_lost:"
//17:number of pin lost
//18:"pin_mounted:"
//19:number of pin mounted from last reset

//example "status: 0 need_reset: 0 need_cal: 0 state: idle warning: {} cal_msg: {done} cal_step: {0 of 100} mounted: {m 4 A} pin_lost: 0 pin_mounted: 100"

const char* RobotService::ms_StringState(m_StringMap[1].m_StringName);
//example "{sample on tong} {magnet on cradle} P0 {in lN2} {current port: m 5 B}"

const char* RobotService::ms_StringCassetteStatus(m_StringMap[2].m_StringName);
//example "2 {1 1 0 2 ...} 0 {0 0 0 0 .....} 2 {2 2 2 1 1 1 000 ...}"
//first field is left cassette status
//second field is a list of port status for left cassette

const char* RobotService::ms_StringSampleStatus(m_StringMap[3].m_StringName);
//examples "l3A mounting", "l3A empty", "l3A mounted", "l3A dismounting"
//this string is for display only.  You can parse robot_status and robot_state to get the same information

const char* RobotService::ms_StringAttribute(m_StringMap[4].m_StringName);
//0:    0/1:                send detailed message in calibration
//1:    0/1:                probe cassette
//2:    0/1:                probe port
//3:    unsigned integer:   lost pin threshold to set NEED_CLEAR FLAG
//4:    0/1:                check magnet, using force sensor to make sure that magnet is there
//5:    0/1:                post calibration threshold check
//6:    0/1:                collect force info at all contacts of tong (post, cassette, goniometer

const char* RobotService::ms_StringInputBits(m_StringMap[5].m_StringName);
const char* RobotService::ms_StringOutputBits(m_StringMap[6].m_StringName);

//we only need "normal" as string status
const char* RobotService::ms_Normal("normal");

RobotService::RobotService( ):
	m_MsgQueue( 3 ),
	m_pCurrentOperation(NULL),
	m_pInstantOperation(NULL),
    m_SendingDetailedMessage(false),
	m_timeStampRobotPolling(0),
	m_pRobot(NULL),
	m_MsgManager( DcsMessageManager::GetObject( ))
{
    xos_semaphore_create( &m_SemThreadWait, 0 );
    xos_event_create( &m_EvtStopOnly, true, false );
    //m_pRobot = new RobotSim;
    m_pRobot = new RobotEpson;

    m_pRobot->SetSleepEvent( &m_EvtStopOnly );
    m_pRobot->RegisterEventListener( *this );
}

#define CLEAR_MSG_POINTER( p ) if (p)		\
{											\
	m_MsgManager.DeleteDcsMessage( p );		\
	p = NULL;								\
}

RobotService::~RobotService( )
{
    m_pRobot->UnregisterEventListener( *this );
	stop( );
	delete m_pRobot;

    xos_event_close( &m_EvtStopOnly );
    xos_semaphore_close( &m_SemThreadWait );

	CLEAR_MSG_POINTER(m_pCurrentOperation);
	CLEAR_MSG_POINTER(m_pInstantOperation);

	for (int i = 0; i < ARRAYLENGTH(m_StringMap); ++i)
	{
		CLEAR_MSG_POINTER(m_StringMap[i].m_pMsgLatest);
	}
}

void RobotService::start( )
{
    if (m_Status != STOPPED)
	{
		LOG_WARNING( "called start when it is still not in stopped state" );
		return;
	}

    //set status to starting, this may cause broadcase if any one is interested in status change
	SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;

    //robot thread must be MFC thread, it will call activeX control.
    //xos_thread_create( &m_Thread, Run, this );
  	m_pThread = AfxBeginThread ( Run, this, THREAD_PRIORITY_NORMAL );

}

void RobotService::stop( )
{
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }
    m_pRobot->SetAbortFlag( );

    //signal threads
    xos_semaphore_post( &m_SemThreadWait );
}


void RobotService::reset( )
{
	DcsMessageManager& theMsgManager = DcsMessageManager::GetObject( );
	DcsMessage* pMsg = NULL;
	
	while ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
	{
		LOG_WARNING1( "message discarded in RobotService::reset: %s", pMsg->GetText( ) );
		theMsgManager.DeleteDcsMessage( pMsg );
	}
}

//this is called by other thread:
//we will check the content of the message, if it can be immediately dealt with,
//we send reply directly, otherwise, it will be put in a queue and wait our own
//thread to deal with it.
BOOL RobotService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST( "+RobotService::ConsumeDcsMessage" );

	//we may need to move this watchdog part into dedicated watchdog thread
	if (m_timeStampRobotPolling != 0)
	{
		time_t time_now = time( NULL );
		if (time_now > m_timeStampRobotPolling + 30)
		{
			SendLogSevere( "Please REBOOT robot PC.  Robot controller timeout." );
			robotSystemStop( );
			LOG_FINEST( "-RobotService::ConsumeDcsMessage watchdog stop whole system" );
			return TRUE;
		}
	}

	//safety check
	if (pMsg == NULL)
	{
		LOG_WARNING( "RobotService::ConsumeDcsMessage called with NULL msg" );
		LOG_FINEST( "-RobotService::ConsumeDcsMessage" );
		return TRUE;
	}

    //deal with attribute string
    if (!strncmp( pMsg->GetText( ), "stoh_register_string", 20 ))
    {
		const char* pStringName = pMsg->GetText( ) + 21;
		for (int i = 0; i < ARRAYLENGTH(m_StringMap); ++i)
		{
			if (!strncmp( pStringName, m_StringMap[i].m_StringName, m_StringMap[i].m_NameLength ))
			{
				if (m_StringMap[i].m_Write)
				{
					if (m_StringMap[i].m_pMsgLatest)
					{
						//it is important that the pointer cleared here first.
						//SendoutDcsMessage may put it back in case DCSS is disconnect during the function call
						DcsMessage* pTryOut = m_StringMap[i].m_pMsgLatest;
						m_StringMap[i].m_pMsgLatest = NULL;
						SendoutDcsMessage( pTryOut );
						pTryOut = NULL;
					}
				}//if need write

				if (m_StringMap[i].m_Read)
				{
					//ask DCSS to send contents
					DcsMessage* pAskConfig = m_MsgManager.NewAskConfigMessage( m_StringMap[i].m_StringName );
					if (pAskConfig)
					{
						SendoutDcsMessage( pAskConfig );
					}
					else
					{
						LOG_WARNING( "new dcsmessage failed at ask for config" );
					}
    				LOG_FINEST1( "%s ask for contents", m_StringMap[i].m_StringName );
				}//if need read
				
				//if name match, break the loop
				break;
			}//name match string name
		}//loop
		//delete the messag 
        CLEAR_MSG_POINTER(pMsg);
    	LOG_FINEST( "-RobotService::ConsumeDcsMessage: stoh_register_string" );
        return TRUE;
    }//it is register string

    if (!strncmp( pMsg->GetText( ), "stoh_register", 13 ))
    {
        //ignore these messages
        CLEAR_MSG_POINTER(pMsg);
    	LOG_FINEST( "-RobotService::ConsumeDcsMessage: register, ignore" );
        return TRUE;
    }

	if (pMsg->IsAbortAll( ))
	{
		//this message must be passed on, not deleted
        m_pRobot->SetAbortFlag( );
        if (m_pCurrentOperation)
        {
            UpdateStateString( "aborting" );
		}
    	LOG_FINEST( "-RobotService::ConsumeDcsMessage: reset message" );
        return FALSE;
	}

    if (pMsg->IsString( ))
    {
		LOG_FINEST2( "received string name=\"%s\", contents=\"%s\"",
			pMsg->GetStringName( ),
			pMsg->GetStringContents( ));
        if (!strcmp( pMsg->GetStringName( ), ms_StringAttribute ))
        {
            ProcessAttributeString( pMsg->GetStringContents( ) );
	        CLEAR_MSG_POINTER(pMsg);
		    LOG_FINEST( "-RobotService::ConsumeDcsMessage: string detailed message, done" );
            return TRUE;
        }
        else
        {
    		LOG_FINEST( "-RobotService::ConsumeDcsMessage: unsupported string setting, pass on" );
            return FALSE;
        }
    }

    if (!pMsg->IsOperation( ))
	{
		LOG_FINEST( "-RobotService::ConsumeDcsMessage: not operation, pass on" );
		return FALSE;
	}

	m_pInstantOperation = pMsg;
	//check to see if this is an operation we can finish immediately

	for (int i = 0; i < ARRAYLENGTH(m_OperationMap); ++i)
	{
		if (!strcmp( m_pInstantOperation->GetOperationName( ), m_OperationMap[i].m_OperationName ))
		{
			LOG_FINEST1( "match operation%d", i );
			m_pInstantOperation->m_PrivateData = i;
			if (m_OperationMap[i].m_Immediately)
			{
				LOG_FINEST( "immediately" );
				(this->*m_OperationMap[i].m_pMethod)( );
			}
			else
			{
				//check to see if it is repeated operation
				if (m_pCurrentOperation &&
					!strcmp( m_pCurrentOperation->GetOperationHandle( ), m_pInstantOperation->GetOperationHandle( ) ) &&
					!strcmp( m_pCurrentOperation->GetOperationName( ),   m_pInstantOperation->GetOperationName( ) ))
				{
					LOG_INFO( "ignore the same operation message" );
					//ignore it
				}
				else
				{
					//put it in the queue, our own thread will take care of it
					if (m_MsgQueue.Enqueue( m_pInstantOperation ))
					{
						LOG_FINEST1( "added to Robot queue, current length=%d\n", m_MsgQueue.GetCount( ) );

                        //wake up the worker thread
                        xos_semaphore_post ( &m_SemThreadWait );

						//do not delete this message yet, we put it into a queue
						m_pInstantOperation = NULL;
					}
					else
					{
						//send reply: busy

						//11 = strlen("busy doing") + 1
						char status_buffer[MAX_OPERATION_HANDLE_LENGTH + 11] = "busy";

						if (m_pCurrentOperation)
						{
							strcat( status_buffer, " doing " );
							strcat( status_buffer, m_pCurrentOperation->GetOperationName( ) );
							strcat( status_buffer, " " );
							strcat( status_buffer, m_pCurrentOperation->GetOperationHandle( ) );
						}
						LOG_FINEST( "reply busy" );
						DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pInstantOperation, status_buffer );
						SendoutDcsMessage( pReply );
					}//need to send busy
				}//if can ignore
			}//if immediate
			CLEAR_MSG_POINTER(m_pInstantOperation);
			LOG_FINEST( "-RobotService::ConsumeDcsMessage: we consume it" );
			return TRUE;
		}//if match one of supported operations
	}//for

	LOG_FINEST( "-RobotService::ConsumeDcsMessage: no match operation, pass on" );
	return FALSE;
}

bool RobotService::OnRobotEvent( long EventNumber, LPCTSTR EventMessage )
{
    switch (EventNumber)
    {
    case EVTNUM_CAL_STEP:
        m_StatusString.SetCalibrationStep( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
        return true;

    case EVTNUM_CAL_MSG:
        m_StatusString.SetCalibrationMessage( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
		//also update robot message
        UpdateString( ms_StringSampleStatus, ms_Normal, EventMessage );
        return true;
        
    case EVTNUM_MOUNTED:
        m_StatusString.SetMounted( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
        return true;
        
    case EVTNUM_WARNING:
        m_StatusString.SetWarning( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
        return true;
        
	case EVTNUM_PINLOST:
        m_StatusString.SetPinLost( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
        return true;

	case EVTNUM_PINMOUNTED:
        m_StatusString.SetPinMounted( EventMessage );
        UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
        return true;

    case EVTNUM_STATE:
        UpdateString( ms_StringState, ms_Normal, EventMessage );
        return true;

    case EVTNUM_CASSETTE:
        UpdateString( ms_StringCassetteStatus, ms_Normal, EventMessage );
        return true;

    case EVTNUM_SAMPLE:
        UpdateString( ms_StringSampleStatus, ms_Normal, EventMessage );
        return true;

	case EVTNUM_INPUT:
	    UpdateString( ms_StringInputBits, ms_Normal, EventMessage );
		return true;

	case EVTNUM_OUTPUT:
	    UpdateString( ms_StringOutputBits, ms_Normal, EventMessage );
		return true;
	case EVTNUM_LOG_NOTE:
		SendLogNote( EventMessage );
		return true;

	case EVTNUM_LOG_WARNING:
		SendLogWarning( EventMessage );
		return true;

	case EVTNUM_LOG_ERROR:
		SendLogError( EventMessage );
		return true;

	case EVTNUM_LOG_SEVERE:
		SendLogSevere( EventMessage );
		return true;

	case EVTNUM_HARDWARE_LOG_WARNING:
		SendHardwareLogWarning( EventMessage );
		return true;

	case EVTNUM_HARDWARE_LOG_ERROR:
		SendHardwareLogError( EventMessage );
		return true;

	case EVTNUM_HARDWARE_LOG_SEVERE:
		SendHardwareLogSevere( EventMessage );
		return true;

	case EVTNUM_STRING_UPDATE:
		SendUpdateString( EventMessage );
		return true;
    }
    //all other must be during operation running

    if (m_pCurrentOperation == NULL) return false;

    if (EventNumber != EVTNUM_USER_PRINT || m_SendingDetailedMessage)
    {
        DcsMessage* pReply = m_MsgManager.NewOperationUpdateMessage( m_pCurrentOperation, EventMessage );
        SendoutDcsMessage( pReply );
    }
    return true;
}

void RobotService::OnRobotStatus( RobotStatus currentStatus )
{
    m_StatusString.SetStatus( currentStatus );
    UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
}

void RobotService::SendoutDcsMessage( DcsMessage* pMsg )
{
	if (pMsg == NULL) return;

	LOG_FINEST1( "RobotService::SendoutDcsMessage( %s )", pMsg->GetText( ) );

	if (!ProcessEvent( pMsg ))
	{
		LOG_INFO1( "RobotService: no one listening to this message: %s", pMsg->GetText( ) );
		//keep the last string completed message so that it will be sent out once DCSS is reconnected
		if (!strncmp( pMsg->GetText( ), "htos_set_string_completed", 25 ))
		{
			const char* pStringName = pMsg->GetText( ) + 26; //also skip the space

			for (int i = 0; i < ARRAYLENGTH(m_StringMap); ++i)
			{
				if (!strncmp( pStringName, m_StringMap[i].m_StringName, m_StringMap[i].m_NameLength ))
				{
					if (m_StringMap[i].m_Write)
					{
						LOG_FINE1( "save latest for %s", m_StringMap[i].m_StringName );
						CLEAR_MSG_POINTER( m_StringMap[i].m_pMsgLatest );
						m_StringMap[i].m_pMsgLatest = pMsg;
						pMsg = NULL;
					}//need save so that we can write once DCSS is connected
					break;
				}//match name
			}//loop string map
		}//if it is string completed message

		if (pMsg)
		{
			LOG_INFO1( "RobotService: no one listening to this message, delete it: %s", pMsg->GetText( ) );
	        CLEAR_MSG_POINTER(pMsg);
		}
	}
}

void RobotService::ThreadMethod( )
{
    SetStatus( READY );

	UpdateStateString( "self-testing" );
	//init the robot


	if (m_pRobot == NULL || !m_pRobot->Initialize( ))
	{
		robotSystemStop( );
		LOG_SEVERE( "robot initialization failed. thread quit" );
        SetStatus( STOPPED );
		return;
	}

	LOG_INFO( "Robot Thread ready" );

	//init status strings
	OnRobotStatus( m_pRobot->GetStatus( ));
    UpdateStateString( "idle" );

    time_t timeNow = 0;
    time_t timeToGoHome = 0;
	while (TRUE)
	{
		if (strcmp( m_StatusString.GetState( ), " state: {idle}" ) && m_MsgQueue.IsEmpty( ))
		{
			LOG_FINEST1( "current state={%s}", m_StatusString.GetState( ) );

			if (timeToGoHome == 0)
			{
				LOG_FINEST( "set state to idle" );
				UpdateStateString( "idle" );
			}
			else
			{
				LOG_FINEST( "set state to waiting" );
				UpdateStateString( "waiting_followup" );
			}

		}
		//wait operation message comes up or stop command issued.
        switch (xos_semaphore_wait( &m_SemThreadWait, 1000 ))
        {
        case XOS_WAIT_TIMEOUT:
		    if (!m_MsgQueue.IsEmpty( ))
		    {
			    LOG_WARNING( "robot queue not empty while no semaphore posted" );
		    }
            break;

        case XOS_WAIT_SUCCESS:
        case XOS_WAIT_FAILURE:
        default:
    		LOG_FINEST( "Robot thread out of waiting" );
        }
		//check to see if it is stop
		if (m_CmdStop)
		{
			if (m_FlagEmergency)
			{
				//immediately return
				LOG_INFO( "Robot thread emergency exit" );
				return;
			}
			else
			{
				//break the loop and clean up
				LOG_INFO( "Robot thread quit by STOP" );
				break;
			}
		}//if stopped

		if (m_MsgQueue.IsEmpty( ))
		{
			//process window's event
			MSG msg;
			long sts;
			do
			{
				if (sts = PeekMessage(&msg, (HWND) NULL, 0, 0, PM_REMOVE))
				{
					TranslateMessage(&msg);
					DispatchMessage(&msg);
				}
			} while (sts);

            //check if need to go home after time out
            timeNow = time( NULL );
			if (m_pRobot->GetStatus( ) & FLAG_NEED_ALL)
			{
				//skip time out check if need reset or user action
				timeToGoHome = 0;
			}
            if (timeToGoHome > 0 && timeNow > timeToGoHome)
            {
			    LOG_FINE( "time to go home" );

				SendLogError( "Went home because of timeout for waiting message" );
				UpdateString( ms_StringSampleStatus, ms_Normal, "error: timeout waiting for message" );

                char status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER + 1] = {0};
                m_pRobot->Standby( status_buffer, status_buffer );
                LOG_FINE1(" result of time to go home: %s", status_buffer );
                timeToGoHome = 0;
            }

			//poll robot
			m_timeStampRobotPolling = time( NULL );
			m_pRobot->Poll( );
			m_timeStampRobotPolling = 0;
			continue;
		}

		//OK it is the message ready
		m_pCurrentOperation = m_MsgQueue.Dequeue( );

		if (m_pCurrentOperation == NULL)
		{
			continue;
		}

		//deal with it
		int mapIndex = m_pCurrentOperation->m_PrivateData;
		if (mapIndex >= 0 && mapIndex < ARRAYLENGTH(m_OperationMap))
		{
            char state_msg[80] = {0};
            strncpy( state_msg, m_pCurrentOperation->GetOperationName( ), sizeof(state_msg) - 1 );
			const char * extra = m_pCurrentOperation->GetOperationArgument( );
			if (extra && extra[0] != 0)
			{
				int left = sizeof(state_msg) - 2 -strlen( state_msg );
				if (left > 0)
				{
					if (strncmp( extra, "probe", 5 ))
					{
						strcat( state_msg, " " );
						strncat( state_msg, extra, left );
					}
					else
					{
						strcat( state_msg, " probe" );
					}
				}
			}
            UpdateStateString( state_msg );
			//the message is pointed by m_pCurrentOperation, does not need to pass
			(this->*m_OperationMap[mapIndex].m_pMethod)( );
            //above call will also clear m_pCurrentOperation
            
            //check if need to set up timer for go home message
            if (m_OperationMap[mapIndex].m_TimeoutForNextOperation)
            {
                timeToGoHome = time( NULL ) + m_OperationMap[mapIndex].m_TimeoutForNextOperation;
            }
            else
            {
                timeToGoHome = 0;
            }
		}
		else
		{
			LOG_WARNING( "RobotService::ThreadMethod: should not been here, the match already did before put into queue\n");
			CLEAR_MSG_POINTER(m_pCurrentOperation);
		}
	}//while
    UpdateStateString( "offline" );

    //clean up before exit
    m_pRobot->Cleanup( );

	LOG_INFO( "Robot thread stopped and EvtStopped set" );
    SetStatus( STOPPED );
}

//no hardware access, pure software.
void RobotService::GetRobotState( )
{
	//get status from the robot
	RobotStatus status = m_pRobot->GetStatus( );

	char status_buffer[512] = {0};
	sprintf( status_buffer, "normal %lu", status ); //about 20 bytes

	LOG_FINEST1( "GetRobotState status=%lX", status );

    if (status != 0)
    {
        strncat( status_buffer, Robot::GetStatusString( status ), sizeof(status_buffer) - 1 - strlen(status_buffer) );
    }

	//make a DcsMessage for it and send out
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pInstantOperation, status_buffer );
	SendoutDcsMessage( pReply );
}

void RobotService::WrapRobotMethod( PTR_ROBOT_FUNC pMethod )
{
	char status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER + 1] = {0};

    m_pRobot->StartNewOperation( );
    m_StatusString.SetWarning( "" );
    UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );

	//run the function and get result
	while (!(m_pRobot->*pMethod)( m_pCurrentOperation->GetOperationArgument( ), status_buffer ))
	{
        status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER] = '\0';
		//update
		DcsMessage* pReply = m_MsgManager.NewOperationUpdateMessage( m_pCurrentOperation, status_buffer );
		SendoutDcsMessage( pReply );

		//check if stop command in effect
		if (m_CmdStop)
		{
			LOG_INFO( "RobotService::WrapRobotMethod: got stop during looping" );
			CLEAR_MSG_POINTER( m_pCurrentOperation );
			return;
		}
	}

    //update warning message if status_buffer not start with "normal"
    if (strncmp( status_buffer, "normal", 6 ))
    {
        m_StatusString.SetWarning( status_buffer );
    }

	//final reply
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pCurrentOperation, status_buffer );
	CLEAR_MSG_POINTER( m_pCurrentOperation );
	//send the reply out at the last step
	SendoutDcsMessage( pReply );
}

void RobotService::PrepareMountCrystal( )
{
	WrapRobotMethod( &Robot::PrepareMountCrystal );
}

void RobotService::MountCrystal( )
{
	WrapRobotMethod( &Robot::MountCrystal );

    //uncomment if decide we move tong tome not waiting the command
    //Standby( );
}

void RobotService::PrepareDismountCrystal( )
{
	WrapRobotMethod( &Robot::PrepareDismountCrystal );
}

void RobotService::DismountCrystal( )
{
	WrapRobotMethod( &Robot::DismountCrystal );

    //uncomment if decide we move tong tome not waiting the command
    //Standby( );
}

void RobotService::PrepareMountNextCrystal( )
{
	WrapRobotMethod( &Robot::PrepareMountNextCrystal );
}

void RobotService::MountNextCrystal( )
{
	WrapRobotMethod( &Robot::MountNextCrystal );

    //uncomment if decide we move tong tome not waiting the command
    //Standby( );
}

void RobotService::PrepareMoveCrystal( )
{
	WrapRobotMethod( &Robot::PrepareMoveCrystal );
}

void RobotService::MoveCrystal( )
{
	WrapRobotMethod( &Robot::MoveCrystal );
}

void RobotService::PrepareWashCrystal( )
{
	WrapRobotMethod( &Robot::PrepareWashCrystal );
}

void RobotService::WashCrystal( )
{
	WrapRobotMethod( &Robot::WashCrystal );
}


void RobotService::Standby( )
{
	WrapRobotMethod( &Robot::Standby );
}

void RobotService::RobotConfig( )
{
	WrapRobotMethod( &Robot::Config );
}

void RobotService::RobotCalibrate( )
{
	WrapRobotMethod( &Robot::Calibrate );
}

void RobotService::UpdateStateString( const char contents[] )
{
    m_StatusString.SetState( contents );
    UpdateString( ms_StringStatus, ms_Normal, m_StatusString.GetStatusString( ) );
}


void RobotService::UpdateString( const char name[], const char status[], const char contents[] )
{
    DcsMessage* pMsg = m_MsgManager.NewStringCompletedMessage( name, status, contents );
    SendoutDcsMessage( pMsg );
}

void RobotService::ProcessAttributeString( const char contents[] )
{
	LOG_FINEST1( "+RobotService::ProcessAttributeString: %s", contents );

	m_pRobot->SetAttribute( contents );

    //setup attributes
	int value = 0;
	sscanf( m_pRobot->GetAttributeField( Robot::ATTRIB_DETAILED_MESSAGE ), "%d", &value );

	m_SendingDetailedMessage = (value != 0);

	UpdateString( ms_StringAttribute, ms_Normal, m_pRobot->GetAttribute( ) );
	LOG_FINEST( "-RobotService::ProcessAttributeString" );
}

void RobotService::SendLogNote( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "note", "robot", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendLogWarning( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "warning", "robot", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendLogError( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "error", "robot", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendLogSevere( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "severe", "robot", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendHardwareLogWarning( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "warning", "robot_hardware", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendHardwareLogError( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "error", "robot_hardware", msg );
    SendoutDcsMessage( pMsg );
}
void RobotService::SendHardwareLogSevere( const char* msg )
{
    DcsMessage* pMsg = m_MsgManager.NewLog( "severe", "robot_hardware", msg );
    SendoutDcsMessage( pMsg );
}
//the format of msg is "string_name string_contents"
void RobotService::SendUpdateString( const char* msg )
{
	char stringName[1024] = {0};
	const char* stringContents = NULL;

	stringContents = strchr( msg, ' ' );
	size_t nameLength = 0;
	if (stringContents)
	{
		nameLength = stringContents - msg;
	}
	else
	{
		nameLength = strlen( msg );
	}
	if (nameLength >= sizeof(stringName))
	{
		LOG_SEVERE1( "SendUpdateString: string name too long %lu", nameLength );
		return;
	}
	strncpy( stringName, msg, nameLength );

	++stringContents; //skip ' '
    UpdateString( stringName, ms_Normal, stringContents );
}
