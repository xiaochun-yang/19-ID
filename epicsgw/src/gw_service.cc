#include <math.h>

#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageManager.h"

#include "gw_service.h"
#include "gw_device_mgr.h"
#include "chid_mgr.h"

DcsMessageManager* GatewayService::m_pDcsMsgManager(NULL);
GatewayDeviceManager* GatewayService::m_pDeviceManager(NULL);
ChidManager* GatewayService::m_pChidManager(NULL);

const double GatewayService::FLOAT_TOLERANCE= 0.001;  //1micro
GatewayService::GatewayService( ): m_dcsScanThreadStatus(STOPPED)
, m_aborting(false)
, m_msgQueue( 100 )
{
    LOG_FINEST( "+GatewayService constructor" );
    if (!m_pDcsMsgManager)
    {
        m_pDcsMsgManager = &(DcsMessageManager::GetObject( ));
    }
    if (!m_pDeviceManager)
    {
        m_pDeviceManager = &(GatewayDeviceManager::GetObject( ));
    }
    if (!m_pChidManager)
    {
        m_pChidManager = &(ChidManager::GetObject( ));
    }
    xos_semaphore_create( &m_semWaitStatus, 0 );
    xos_semaphore_create( &m_semMsgQueue, 0 );

    GwBaseDevice::SetDcsMessageSender( this );
    LOG_FINEST( "-GatewayService constructor" );
}
GatewayService::~GatewayService( )
{
    LOG_FINEST( "+GatewayService destructor" );
    xos_semaphore_close( &m_semMsgQueue );
    xos_semaphore_close( &m_semWaitStatus );
    xos_thread_close( &m_dcsThread );
    xos_thread_close( &m_epicsMainThread );
    LOG_FINEST( "-GatewayService destructor" );
}
void GatewayService::epicsMain( )
{
    LOG_FINEST( "enter EpicsMonitorThread" );
    //wait the other thread ready then set the ready flag for the object
    while (m_dcsScanThreadStatus != READY)
    {
        xos_semaphore_wait( &m_semWaitStatus, 0 );
        if (m_CmdStop) break;
    }

    
    if (m_FlagEmergency)
    {
        return;
    }
    if (m_CmdStop)
    {
        SetStatus( STOPPED );
        LOG_INFO( "epics thread stopped at the beginning" );
        return;
    }
    LOG_FINEST( "mark object ready" );
    SetStatus( READY );

    //ca_attach_context( GwBaseDevice::getContext( ) );
        
    while (!m_CmdStop)
    {
        xos_semaphore_wait( &m_semMsgQueue, 0 );
        LOG_FINEST( "epics thread out of waiting" );
		if (m_CmdStop)
		{
			if (m_FlagEmergency)
			{
				//immediately return
				LOG_INFO( "epics thread emergency exit" );
				return;
			}
			else
			{
				//break the loop and clean up
				LOG_INFO( "epics thread quit by STOP" );
				break;
			}
		}//if stopped
        LOG_INFO1( "queue length before dequeue: %d", m_msgQueue.GetCount( ) );
        DcsMessage* pMsg = m_msgQueue.Dequeue( );
        LOG_INFO1( "queue length after dequeue: %d", m_msgQueue.GetCount( ) );
        if (pMsg == NULL)
        {
            LOG_WARNING( "got null from msg queue" );
            continue;
        }
        doTask( pMsg );
        m_pDcsMsgManager->DeleteDcsMessage( pMsg );
    }//end of loop

    if (m_FlagEmergency)
    {
        LOG_INFO( "epics emergency exit" );
        return;
    }

    //clear up epics
    m_pDeviceManager->clearAll( );
    m_pChidManager->clearAll( );

    ca_client_status( 100 );

    LOG_FINEST( "epics thread wait the other thread to quit" );
    //wait other threads to quit first, then flat the object
    while (m_dcsScanThreadStatus != STOPPED)
    {
        xos_semaphore_wait( &m_semWaitStatus, 0 );
    }
    LOG_FINEST( "epics thread flag object and quit" );
    SetStatus(STOPPED);
}
void GatewayService::dcsScan( )
{
    LOG_FINEST( "enter DcsScanThread" );
    m_dcsScanThreadStatus = READY;
    xos_semaphore_post( &m_semWaitStatus );

    LOG_FINEST( "Dcs scan thread looping" );
    unsigned long ticks = 0;
    while (!m_CmdStop)
    {
        m_pDeviceManager->scan( ticks++ );
        xos_thread_sleep( 100 );  // 10 Hz
    }
    LOG_FINEST( "Dcs scan thread quit" );
    m_dcsScanThreadStatus = STOPPED;
    xos_semaphore_post( &m_semWaitStatus );
}
void GatewayService::start( )
{
    if (m_Status != STOPPED)
    {
        LOG_WARNING( "gateway service start when status != STOPPED" );
    }

    SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;

    //CA 3.14.6:
    //the main thread (started by int main( int argc, char** argv))
    //has to create the context to avoid segmentation fault
    //at the exit( ).
    ca_context_create( ca_enable_preemptive_callback );

    //must be called before create epics threads
    GwBaseDevice::setContext( ca_current_context( ) );
    
    xos_thread_create( &m_dcsThread, DcsScanThreadRoutine, this );
    xos_thread_create( &m_epicsMainThread, EpicsThreadRoutine, this );
}
void GatewayService::stop( )
{
    LOG_FINEST( "stop called" );
    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }
    m_CmdStop = true;
    xos_semaphore_post( &m_semMsgQueue );
}
void GatewayService::reset( )
{
}

/*
 *	Attempt to see if doing the steps involved in an oscillation
 *	exposure here rather than in the tcl code can gain an advantage
 *	in overhead.
 */

int	 GatewayService::doGetPV( char *pvName, char *result )
{	
	LOG_FINEST1( " doGetPV %s", pvName );

	EPICSChid* pChid = m_pChidManager->add( pvName );
	ca_pend_io( 0.5 );
	if (pChid == NULL)
	{
		LOG_FINEST( "add chid failed" );
		strcpy(result, "system error");
		return(1);
	}

	while(1)
	{
		if (!pChid->getPV( 0.5 ))
		{
			if(NULL != strstr(pChid->getResult( ), "timeout"))
			{
				LOG_FINEST( "getPV timed out: only a WARNING; retry the getPV" );
				continue;
			}
			LOG_FINEST( "getPV failed" );
			strcpy(result, pChid->getResult( ) );
			return(1);
		}
		else {
			LOG_FINEST( "ca_get ok" );
			strcpy(result, pChid->getResult( ) );
			return(0);
		}
	}
}

int	GatewayService::doPutPV( char *pvName, char *value, char *result)
{	
	EPICSChid* pChid = m_pChidManager->add( pvName );
	ca_pend_io( 0.5 );
	if (pChid == NULL)
	{
		LOG_FINEST( "add chid failed" );
		strcpy(result, "system error");
		return(1);

	}
	pChid->setValue( value );
	while(1)
	{
		if (!pChid->putPV( 0.5 ))
		{
			if(NULL != strstr(pChid->getResult( ), "timeout"))
			{
				LOG_FINEST( "putPV timed out: only a WARNING; retry the putPV" );
				continue;
			}
			LOG_FINEST( "putPV failed" );
			strcpy( result, pChid->getResult( ));
			return(1);
		}
		break;
	}
	while(1)
	{
		if (!pChid->getPV( 0.5 ))
		{
			if(NULL != strstr(pChid->getResult( ), "timeout"))
			{
				LOG_FINEST( "getPV after putPV timed out: only a WARNING; retry the getPV" );
				continue;
			}
			LOG_FINEST( "getPV failed after putPV" );
			strcpy( result, "getPV failed after putPV");
			return(1);
		}
		else 
		{
			LOG_FINEST( "ca_get ok" );
			strcpy( result,  "" );
			return(0);
		}
	}
}

int	 GatewayService::doEpicsGalilExpose( DcsMessage* pMsg )
{	
	char	base_motorPV[1024],  base_oscexecPV[1024],  base_oscstatePV[1024];
	char	stup_motorPV[1024],  movn_motorPV[1024];
	char	sp_oscexecPV[1024],  sp_oscstatePV[1024];
	char	monitor_oscexecPV[1024],  monitor_oscstatePV[1024];

	char	buf[2048], resbuf[2048];
	char	*cp;

	int	executing_osc;
	int	osc_state;
	int	motor_moving;
	int	n_checked;

	LOG_FINEST1( "operation epicsGalilExpose %s", pMsg->GetOperationArgument( ) );
	strcpy(buf, pMsg->GetOperationArgument( ));
	if( NULL != (cp = strstr(buf, "{"))) *cp = ' ';
	if( NULL != (cp = strstr(buf, "}"))) *cp = ' ';

	if( 3 != sscanf(buf, "%s %s %s",  base_motorPV,  base_oscexecPV,  base_oscstatePV))
	{
		LOG_FINEST( "operation epicsGalilExpose: 3 arguments not found for operation");
		return(1);
	}
	sprintf(buf, "operation epicsGalilExpose: base_motorPV: %s base_oscexecPV: %s base_oscstatePV: %s\n",
                                base_motorPV, base_oscexecPV, base_oscstatePV);
	LOG_FINEST1( "%s", buf);

	strcpy(monitor_oscexecPV, base_oscexecPV);
	strcat(monitor_oscexecPV,"_MONITOR");
	strcpy(sp_oscexecPV, base_oscexecPV);
	strcat(sp_oscexecPV, "_SP");
	strcpy(monitor_oscstatePV, base_oscstatePV);
	strcat(monitor_oscstatePV, "_MONITOR");
	strcpy(sp_oscstatePV, base_oscstatePV);
	strcat(sp_oscstatePV, "_SP");
	strcpy(stup_motorPV, base_motorPV);
	strcat(stup_motorPV, ".STUP");
	strcpy(movn_motorPV, base_motorPV);
	strcat(movn_motorPV, "_MOVN_STATUS");

/*	Grab code from this section:

	if( doGetPV( monitor_oscexecPV, resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST1( "operation epicsGalilExpose getPV on monitor_oscexecPV: %s", resbuf );
	if( doGetPV( monitor_oscstatePV, resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST1( "operation epicsGalilExpose getPV on monitor_oscstatePV: %s", resbuf );
	if( doGetPV( movn_motorPV, resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST1( "operation epicsGalilExpose getPV on movn_motorPV: %s", resbuf );
	if( doPutPV( stup_motorPV, "1", resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST( "operation epicsGalilExpose putPV on stup_motorPV: OK" );
	if( doGetPV( movn_motorPV, resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST1( "operation epicsGalilExpose getPV on movn_motorPV: %s", resbuf );

*/
	
	/*
	 *	Set the galil state variable to 0 to make sure we start out OK.
	 */
	if( doPutPV( sp_oscstatePV, "0", resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST( "operation epicsGalilExpose putPV on sp_oscstatePV: OK" );
	/*
	 *	Set the galil exec oscillation variable to 1 start the oscillation
	 */
	if( doPutPV( sp_oscexecPV, "1", resbuf) )
	{
		DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
		sendoutDcsMessage( pReply );
		return(1);
	}
	LOG_FINEST( "operation epicsGalilExpose putPV on sp_oscexePV: OK" );
	/*
	 *	Loop on the state variable readout until 1.
	 *
	 *	Perform periodic .STUP's on the motor PV so status gets sent out to BluIce as the
	 *	motor moves.
	 */
	executing_osc = 1;
	for( n_checked = 0; 1 == executing_osc; n_checked++)
	{
		xos_thread_sleep( 100 );
		if( doGetPV( monitor_oscstatePV, resbuf) )
		{
			DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
			sendoutDcsMessage( pReply );
			return(1);
		}
		LOG_FINEST1( "operation epicsGalilExpose getPV on monitor_oscstatePV: %s", resbuf );
		osc_state = atoi(resbuf);
		if(1 == osc_state)
			executing_osc = 0;
		else
			executing_osc = 1;
		if( (1 == executing_osc) && 1 == (n_checked % 2))
		{
			if( doPutPV( stup_motorPV, "1", resbuf) )
			{
				DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
				sendoutDcsMessage( pReply );
				return(1);
			}
			LOG_FINEST( "operation epicsGalilExpose putPV on stup_motorPV: OK" );
		}
	}

	/*
	 *	Oscillation motion is finished.  Wait for motor to "stop moving".
	 */
	
	motor_moving = 1;
	for( n_checked = 0; (1 == motor_moving) || (n_checked < 2); n_checked++)
	{
		xos_thread_sleep( 50 );
		if( doPutPV( stup_motorPV, "1", resbuf) )
		{
			DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
			sendoutDcsMessage( pReply );
			return(1);
		}
		LOG_FINEST( "operation epicsGalilExpose putPV on stup_motorPV: OK" );
		if( doGetPV( movn_motorPV, resbuf) )
		{
			DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, resbuf );
			sendoutDcsMessage( pReply );
			return(1);
		}
		LOG_FINEST1( "operation epicsGalilExpose getPV on movn_motorPV: %s", resbuf );
		if(NULL != strstr(resbuf, "Not Moving"))
			motor_moving = 0;
		else
			motor_moving = 1;
	}
	return(0);
}

void GatewayService::doTask( DcsMessage* pMsg )
{
    LOG_FINEST( "+GatewayService::doTask" );

    if (pMsg == NULL)
    {
        LOG_FINEST( "-GatewayService::doTask NULL" );
        return;
    }

    LOG_FINEST1( "do task:{%s}", pMsg->GetText( ) );

    const char* pTextMsg = pMsg->GetText( );

    if (pMsg->IsAbortAll( ))
    {
        m_pDeviceManager->abortAll( );
        m_aborting = false;
        LOG_FINEST( "-GatewayService::doTask abort all" );
    }
    else if (pMsg->IsOperation( ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        if (!strcmp( pMsg->GetOperationName( ), "getEPICSPV" ))
        {
            LOG_FINEST1( "operation getEPICPV %s", pMsg->GetOperationArgument( ) );

            EPICSChid* pChid = m_pChidManager->add( pMsg->GetOperationArgument( ) );
            ca_pend_io( 5.0 );
            if (pChid == NULL)
            {
                LOG_FINEST( "add chid failed" );

                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "system error" );
                sendoutDcsMessage( pReply );
            }
            else if (!pChid->getPV( 5.0 ))
            {
                LOG_FINEST( "getPV failed" );
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, pChid->getResult( ) );
                sendoutDcsMessage( pReply );
            }
            else {
                LOG_FINEST( "ca_get ok" );
                char status_buffer[2048] = "normal ";
                strcat( status_buffer, pChid->getResult( ) );
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, status_buffer );
                sendoutDcsMessage( pReply );
            }
        }
        else if (!strcmp( pMsg->GetOperationName( ), "putEPICSPV" ))
        {
            LOG_FINEST1( "operation puttEPICPV %s", pMsg->GetOperationArgument( ) );
            char PVName[64] = {0};
            if (sscanf( pMsg->GetOperationArgument( ), "%s", PVName) != 1)
            {
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "no PVName in argument" );
                sendoutDcsMessage( pReply );
                return;
            }
            EPICSChid* pChid = m_pChidManager->add( PVName );
            ca_pend_io( 5.0 );
            if (pChid == NULL)
            {
                LOG_FINEST( "add chid failed" );

                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "system error" );
                sendoutDcsMessage( pReply );
                return;
            }
            const char* pNewValue =
                strstr( pMsg->GetOperationArgument( ), PVName ) +
                strlen( PVName) + 1; //1: skip ' '

            pChid->setValue( pNewValue );
            if (!pChid->putPV( 5.0 ))
            {
                LOG_FINEST( "putPV failed" );
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, pChid->getResult( ) );
                sendoutDcsMessage( pReply );
                return;
            }
            if (!pChid->getPV( 5.0 ))
            {
                LOG_FINEST( "getPV failed after putPV" );
            }
            else {
                LOG_FINEST( "ca_get ok" );
            }
            char status_buffer[2048] = "normal ";
            strcat( status_buffer, pChid->getResult( ) );
            DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                pMsg, status_buffer );
            sendoutDcsMessage( pReply );
        }
        else if (!strcmp( pMsg->GetOperationName( ), "forceReadString" ))
        {
            LOG_FINEST1( "operation forceReadString %s", pMsg->GetOperationArgument( ) );
            char name[64] = {0};
            if (sscanf( pMsg->GetOperationArgument( ), "%s", name) != 1)
            {
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "no stringName in argument" );
                sendoutDcsMessage( pReply );
                return;
            }
            GwBaseDevice* pDevice = m_pDeviceManager->findDevice( name );
            if (pDevice == NULL)
            {
                char replyMsg[128] = {0};
                strcpy( replyMsg, "cannot find device " );
                strcat( replyMsg, name );
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, replyMsg );
                sendoutDcsMessage( pReply );
                return;
            }
            if (pDevice->refresh( )) {
                DcsMessage* pReply =
                m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "normal OK"
                );
                sendoutDcsMessage( pReply );
            } else {
                DcsMessage* pReply =
                m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "failed"
                );
                sendoutDcsMessage( pReply );
            }
            return;
        }
        else if (!strcmp( pMsg->GetOperationName( ), "dumpDevice" ))
        {
            LOG_FINEST1( "operation dumpDevice %s", pMsg->GetOperationArgument( ) );
            const char* pARG = pMsg->GetOperationArgument( );
            LOG_FINEST2( "pMsg at %p pARG at %p", pMsg, pARG );
            char name[DCS_DEVICE_NAME_SIZE + 1] = {0};
            if (sscanf( pMsg->GetOperationArgument( ), "%s", name) != 1)
            {
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, "no deviceName in argument" );
                sendoutDcsMessage( pReply );
                return;
            }
            GwBaseDevice* pDevice = m_pDeviceManager->findDevice( name );
            if (pDevice == NULL)
            {
                char replyMsg[DCS_DEVICE_NAME_SIZE+ 128] = {0};
                strcpy( replyMsg, "cannot find device " );
                strcat( replyMsg, name );
                DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
                    pMsg, replyMsg );
                sendoutDcsMessage( pReply );
                return;
            }
            pDevice->dumpToOperation( pMsg );
            DcsMessage* pReply =
            m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, "normal OK");
            sendoutDcsMessage( pReply );
            return;
        }
        else if (!strcmp( pMsg->GetOperationName( ), "epicsGalilExpose" ))
        {
	    int expRet;

	    expRet = doEpicsGalilExpose( pMsg );

	    if( 0 == expRet)	/* error messages sent by doEpicsGalilExpose, normal result sent here */
	    {
            	DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage( pMsg, "normal OK");
            	sendoutDcsMessage( pReply );
	    }
            return;
	}
    }
    else if (!strncmp( pTextMsg, "stoh_register_string", 20 ))
    {
        createString( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_register_shutter", 21 ))
    {
        createShutter( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_register_pseudo_motor", 26 ))
    {
        createPseudoMotor( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_register_real_motor", 24 ))
    {
        createRealMotor( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_set_string", 15 ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        setString( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_set_shutter_state", 22 ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        setShutter( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_start_motor_move", 21 ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        moveMotor( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_configure_pseudo_motor", 27 ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        LOG_FINEST1( "got config pseudo motor mesage %s", pTextMsg );
        configPseudoMotor( pMsg );
    }
    else if (!strncmp( pTextMsg, "stoh_configure_real_motor", 25 ))
    {
        if (m_aborting)
        {
            replyAborted( pMsg );
            return;
        }
        LOG_FINEST1( "got config real motor mesage %s", pTextMsg );
        configRealMotor( pMsg );
    }
    else
    {
        LOG_FINEST( "-GatewayService::doTask no match pass on" );
    }
    return;
}

BOOL GatewayService::ConsumeDcsMessage( DcsMessage* pMsg )
{
    LOG_FINEST( "+GatewayService::ConsumeDcsMessage" );

    if (pMsg == NULL)
    {
        LOG_FINEST( "-GatewayService::ConsumeDcsMessage NULL" );
        return TRUE; //we ate it.
    }

    if (pMsg->IsAbortAll( ))
    {
        m_aborting = true; //will be cleared after doTask abort
        m_msgQueue.WaitEnqueue( m_pDcsMsgManager->NewCloneMessage( pMsg ), 10000);
        xos_semaphore_post( &m_semMsgQueue );
        LOG_FINEST( "-GatewayService::ConsumeDcsMessage abort all" );
        return FALSE; //passing on
    }

    BOOL result = m_msgQueue.WaitEnqueue( pMsg, 10000 );
    xos_semaphore_post( &m_semMsgQueue );
    LOG_FINEST( "-GatewayService::ConsumeDcsMessage" );
    return result;
}
void GatewayService::sendoutDcsMessage( DcsMessage* pMsg )
{
    if (!ProcessEvent( pMsg ))
    {
        LOG_WARNING1( "GatewayService::sendoutDcsMessage: no one listen to this one: {%s}", pMsg->GetText( ) );

        m_pDcsMsgManager->DeleteDcsMessage( pMsg );
    }
}

void GatewayService::createString( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    char EPICSName[DCS_DEVICE_NAME_SIZE] = {0};

    if (sscanf( pMsg->GetText( ), "%*s %s %s", name, EPICSName ) != 2)
    {
        LOG_WARNING1( "bad register string msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwString* pString = m_pDeviceManager->addString( name, EPICSName );
        if (pString == NULL)
        {
            LOG_WARNING1( "create string %s failed", name );
        }
    }
}
void GatewayService::setString( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};

    const char* pText = pMsg->GetText( );

    if (sscanf( pText, "%*s %s", name ) != 1)
    {
        LOG_WARNING1( "bad set string msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwString* pString = m_pDeviceManager->findString( name );
        if (pString == NULL)
        {
            LOG_WARNING1( "find string %s failed", name );
        }
        else
        {
            const char* pContents = strstr( pText + 15, name );
            if (pContents) pContents += strlen( name ) + 1;
            pString->sendContents( pContents );
        }
    }
    //completed message will be generated by callback from EPICS
}
void GatewayService::createShutter( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    char EPICSName[DCS_DEVICE_NAME_SIZE] = {0};
    char state[64] = {0};

    if (sscanf( pMsg->GetText( ), "%*s %s %s %s", name, state, EPICSName ) != 3)
    {
        LOG_WARNING1( "bad register shutter msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwShutter* pShutter = m_pDeviceManager->addShutter( name, EPICSName );
        if (pShutter == NULL)
        {
            LOG_WARNING1( "create shutter %s failed", name );
        }
    }
}
void GatewayService::setShutter( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    char state[64] = {0};

    const char* pText = pMsg->GetText( );

    if (sscanf( pText, "%*s %s %s", name, state ) != 2)
    {
        LOG_WARNING1( "bad set shutter msg: {%s}", pMsg->GetText( ) );
            DcsMessage* pReply = m_pDcsMsgManager->NewLog(
                "error", "epicsgw", "bad set shutter message"  );
            sendoutDcsMessage( pReply );
    }
    else
    {
        GwShutter* pShutter = m_pDeviceManager->findShutter( name );
        if (pShutter == NULL)
        {
            LOG_WARNING1( "find shutter %s failed", name );
            DcsMessage* pReply = m_pDcsMsgManager->NewLog(
                "error", "epicsgw", "cannot find that shutter"  );
            sendoutDcsMessage( pReply );
        }
        else
        {
            if (!strcmp( state, "closed" ))
            {
                pShutter->sendState( true );
            }
            else if (!strcmp( state, "open" ))
            {
                pShutter->sendState( false );
            }
            else
            {
                LOG_WARNING1( "bad set shutter msg: {%s}", pMsg->GetText( ) );
                DcsMessage* pReply = m_pDcsMsgManager->NewLog(
                    "error", "epicsgw", "bad set shutter message"  );
                sendoutDcsMessage( pReply );
            }
        }
    }
    //completed message will be generated by callback from EPICS
}
void GatewayService::createPseudoMotor( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    char EPICSName[DCS_DEVICE_NAME_SIZE] = {0};

    if (sscanf( pMsg->GetText( ), "%*s %s %s", name, EPICSName ) != 2)
    {
        LOG_WARNING1( "bad register pseudo motor msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwBaseMotor* pMotor = m_pDeviceManager->addPseudoMotor( name, EPICSName );
        if (pMotor == NULL)
        {
            LOG_WARNING1( "create pmotor %s failed", name );
            return;
        }
        if (pMotor->getConfigFromDCSS( )) {
            DcsMessage* pMsg = m_pDcsMsgManager->NewAskConfigMessage( name );
            sendoutDcsMessage( pMsg );
        }
    }
}
void GatewayService::createRealMotor( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    char EPICSName[DCS_DEVICE_NAME_SIZE] = {0};

    if (sscanf( pMsg->GetText( ), "%*s %s %s", name, EPICSName ) != 2)
    {
        LOG_WARNING1( "bad register real motor msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwBaseMotor* pMotor = m_pDeviceManager->addRealMotor( name, EPICSName );
        if (pMotor == NULL)
        {
            LOG_WARNING1( "create rmotor %s failed", name );
        }
    }
}
void GatewayService::moveMotor( DcsMessage* pMsg )
{
    char name[DCS_DEVICE_NAME_SIZE] = {0};

    const char* pText = pMsg->GetText( );
    double position(0);

    if (sscanf( pText, "%*s %s %lf", name, &position ) != 2)
    {
        LOG_WARNING1( "bad move motor msg: {%s}", pMsg->GetText( ) );
    }
    else
    {
        GwBaseMotor* pMotor = m_pDeviceManager->findMotor( name );
        if (pMotor == NULL)
        {
            LOG_WARNING1( "find motor %s failed", name );
        }
        else
        {
            pMotor->move( position );
        }
    }
}
void GatewayService::configPseudoMotor( DcsMessage* pMsg )
{
    const char* pText = pMsg->GetText( );

    char name[DCS_DEVICE_NAME_SIZE] = {0};
    double position(0);
    double upperLimit(0);   
    double lowerLimit(0);   
    int    upperLimitOn(0);
    int    lowerLimitOn(0);
    int    motorLockOn(0);

    if (sscanf( pText, "%*s %s %*s %*s %lf %lf %lf %d %d %d", 
    name, &position, &upperLimit, &lowerLimit, 
    &lowerLimitOn, &upperLimitOn, &motorLockOn ) != 7)
    {
        LOG_WARNING1( "bad config p motor msg: {%s}", pText );
    }
    else
    {
        GwBaseMotor* pMotor = m_pDeviceManager->findPseudoMotor( name );
        if (pMotor == NULL)
        {
            LOG_WARNING1( "find motor %s failed", name );
        }
        else
        {
            pMotor->pseudoConfig( position, upperLimit, lowerLimit,
                lowerLimitOn, upperLimitOn, motorLockOn
            );
        }
    }
}
void GatewayService::configRealMotor( DcsMessage* pMsg )
{
    const char* pText = pMsg->GetText( );

    char name[DCS_DEVICE_NAME_SIZE] = {0};
    double position(0);
    double upperLimit(0);   
    double lowerLimit(0);   
    double scaleFactor(0);
    int    speed(0);
    int    acceleration(0);
    int    backlashDistance(0);
    int    upperLimitOn(0);
    int    lowerLimitOn(0);
    int    motorLockOn(0);
    int    backlashOn(0);
    int    reverseOn(0);

    if (sscanf( pText, "%*s %s %*s %*s %lf %lf %lf %lf %d %d %d %d %d %d %d %d",
        name,
        &position, &upperLimit, &lowerLimit, &scaleFactor,
        &speed, &acceleration, &backlashDistance,
        &lowerLimitOn, &upperLimitOn, &motorLockOn, &backlashOn, &reverseOn
    ) != 13)
    {
        LOG_WARNING1( "bad config r motor msg: {%s}", pText );
        return;
    }
    GwBaseMotor* pMotor = m_pDeviceManager->findRealMotor( name );
    if (pMotor == NULL)
    {
        LOG_WARNING1( "find motor %s failed", name );
        return;
    }
    pMotor->realConfig( position, upperLimit, lowerLimit, scaleFactor, speed,
        acceleration, backlashDistance, lowerLimitOn, upperLimitOn,
        motorLockOn, backlashOn, reverseOn
    );
}
void GatewayService::replyAborted( DcsMessage* pMsg )
{
    if (pMsg->IsOperation( ))
    {
        DcsMessage* pReply = m_pDcsMsgManager->NewOperationCompletedMessage(
            pMsg, "aborted" );
        sendoutDcsMessage( pReply );
        return;
    }
    const char* pTextMsg = pMsg->GetText( );
    char name[DCS_DEVICE_NAME_SIZE] = {0};
    //for now all messages dealt here follow this format
    sscanf( pTextMsg, "%*s %s", name );

    char errorMsg[256] = {0};
    if (!strncmp( pTextMsg, "stoh_set_string", 15 ))
    {
        sprintf( errorMsg, "aborted set string %s", name );
    }
    else if (!strncmp( pTextMsg, "stoh_set_shutter_state", 22 ))
    {
        sprintf( errorMsg, "aborted change shutter %s", name );
    }
    else if (!strncmp( pTextMsg, "stoh_start_motor_move", 21 ))
    {
        sprintf( errorMsg, "aborted move motor %s", name );
    }
    else if (!strncmp( pTextMsg, "stoh_configure_pseudo_motor", 27 ))
    {
        sprintf( errorMsg, "aborted configure pseudo motor %s", name );
    }
    else if (!strncmp( pTextMsg, "stoh_configure_real_motor", 25 ))
    {
        sprintf( errorMsg, "aborted configure real motor %s", name );
    }

    if (errorMsg[0] != 0)
    {
        DcsMessage* pReply = m_pDcsMsgManager->NewLog(
            "error", "epicsgw", errorMsg  );
        sendoutDcsMessage( pReply );
    }
}
