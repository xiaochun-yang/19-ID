#include "log_quick.h"
#include "DcsMessageService.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

DcsMessageService::DcsMessageService( int max_queue_length ):
m_MsgQueue( max_queue_length )
{
	LOG_FINEST("DcsMessageService constructor enter");
    xos_mutex_create( &m_Lock );
    xos_semaphore_create( &m_SemSenderWait, 0 );
    xos_event_create( &m_EvtReceiverWait, TRUE, FALSE );
	LOG_FINEST("DcsMessageService constructor exit");
}

DcsMessageService::~DcsMessageService( )
{
	LOG_FINEST("+DcsMessageService destructor");
	stop( );
    xos_mutex_close( &m_Lock );
    xos_semaphore_close( &m_SemSenderWait );
    xos_event_close( &m_EvtReceiverWait );
	LOG_FINEST("-DcsMessageService destructor");
}

void DcsMessageService::SetupDCSSServerInfo( const char serverName[], int port )
{
	m_DCSSConnection.SetServerInfo( serverName, port );
}

void DcsMessageService::SetDHSName( const char name[] )
{
	m_DCSSConnection.SetDHSName( name );
}

//current, not check whether threads already running.
//we will start sender first, because there nothing to send at the beginning.
//The socket connection will be setup by either thread who meets it first.
void DcsMessageService::start( )
{
	//make sure all threads are stopped
	if (m_Status != STOPPED)
	{
		LOG_WARNING( "DcsMessageService:: called start when it is still not in stopped state" );
		return;
	}

    //set status to starting, this may cause broadcase if any one is interested in status change
	SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;
    
    //start threads: will start sender first, the receiver will wait until sender is done the connection
    xos_event_reset( &m_EvtReceiverWait );

    xos_thread_create( &m_SenderThread, SenderRun, this );
    xos_thread_create( &m_ReceiverThread, ReceiverRun, this );
}


void DcsMessageService::stop( )
{
    //set flags
    xos_event_reset( &m_EvtReceiverWait );
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }

    //signal threads
    xos_semaphore_post( &m_SemSenderWait );
    //sender will signal receiver
    if (m_FlagEmergency)
    {
        xos_event_set( &m_EvtReceiverWait );
    }
}

void DcsMessageService::SenderThreadMethod( )
{
	//try to connect
    LOG_FINEST( "SENDER wait for socket lock 11111" );
	xos_mutex_lock( &m_Lock );
	LOG_FINEST( "SENDER got socket lock 111111" );
	while (!m_DCSSConnection.ConnectToDCSS( ))
	{
        xos_thread_sleep( 5000 );
		LOG_FINEST( "trying to connect to DCSS" );
        if (m_CmdStop)
        {
            xos_event_set( &m_EvtReceiverWait );
        	LOG_INFO( "sender stopped in first connection" );
            return;
        }
	}
	xos_mutex_unlock( &m_Lock );
	LOG_FINEST( "SENDER unlock socket lock 11111111111" );

	LOG_INFO( "connected to DCSS with DCS protocol, sender ready" );

	//OK sender is ready, tell receiver to continue
    xos_event_set( &m_EvtReceiverWait );

	LOG_FINEST( "SENDER enter loop" );
	//loop
	while (!m_CmdStop)
	{
        xos_semaphore_wait( &m_SemSenderWait, 0 );
		LOG_FINEST( "SENDER out of waiting" );

		//check to see if it is stop
		if (m_CmdStop)
		{
			if (m_FlagEmergency)
			{
				//immediately return
				LOG_INFO( "SENDER emergency exit" );
				return;
			}
			else
			{
				//break the loop and clean up
				LOG_INFO( "SENDER quit by command STOP" );
				break;
			}
		}

		//message in queue of sending out?
		LOG_FINEST( "SENDER wait for socket lock" );
    	xos_mutex_lock( &m_Lock );
		LOG_FINEST( "SENDER got socket lock" );
		SendMessageToDCSS( );	//may loop inside to reconnect to the server
	    xos_mutex_unlock( &m_Lock );
		LOG_FINEST( "SENDER release socket lock" );
	}//while (TRUE)

    xos_event_set( &m_EvtReceiverWait );

	LOG_INFO( "sender stopped" );
	return;
}

void DcsMessageService::ReceiverThreadMethod( )
{
	//wait sender done initial connection first
	LOG_FINEST( "receiver is waiting sender done for start" );
    xos_event_wait( &m_EvtReceiverWait, 0 );
	LOG_FINEST( "receiver waiting done" );
    if (m_FlagEmergency)
    {
        return;
    }
    if (m_CmdStop)
    {
        SetStatus( STOPPED );
    	LOG_INFO( "receiver stopped at the beginning" );
        return;
    }

	//no initialization needed for now, so just set the status
	SetStatus( READY );
    LOG_INFO( "receiver ready: whole DcsMessageService Ready" );
	
    //loop
    while (!m_CmdStop)
	{
		BOOL no_message = TRUE;
		while (no_message)
		{
			no_message = !m_DCSSConnection.WaitForInMessage( 1 );	//just wait 1 second
			if (m_CmdStop)
			{
				break;
			}
		}

        //OK we have message waiting in socket
		if (m_CmdStop)
		{
			break;
		}

		LOG_FINEST( "RECEIVER wait socket lock" );
		xos_mutex_lock( &m_Lock );
		LOG_FINEST( "RECEIVER got socket lock" );
		ReceiveMessageFromDCSS( );
		xos_mutex_unlock( &m_Lock );
		LOG_FINEST( "RECEIVER release socket lock" );
	}

	if (m_FlagEmergency)
	{
		LOG_INFO( "receiver emergency exit" );
		return;
	}

	//wait sender stop first
	LOG_FINEST( "receiver is waiting sender done for stop" );
    xos_event_wait( &m_EvtReceiverWait, 0 );
	LOG_FINEST( "waiting done" );
    if (m_FlagEmergency)
    {
	    LOG_FINEST( "receiver quit at emergency" );
        return;
    }

	LOG_FINEST( "receiver disconnect DCSS" );
    m_DCSSConnection.Disconnect( );

    LOG_INFO( "receiver stopped: means this active object stopped" );
    SetStatus( STOPPED );   //this will signal the observers.
}


void DcsMessageService::ReceiveMessageFromDCSS( )
{
	//retrieve the message from socket
	DcsMessage* pMsg = m_DCSSConnection.CreateAndReceiveDcsMessage( );

	//check the message
	if ( pMsg )
	{
		//if messag OK, send to listeners
		if (!ProcessEvent( pMsg ))
		{
			//no one take it, so log it and delete it.
			if (pMsg->IsAbortAll( ))
			{
                //the queue should not be cleared
			}
			else
			{
				LOG_WARNING1( "no one takes this message: %s", pMsg->GetText( ) );
			}
			DcsMessageManager::GetObject( ).DeleteDcsMessage( pMsg );
		}
	}
	else 
	{
        xos_thread_sleep( 1000 );
		//lost connection, reconnect
		LOG_INFO( "lost socket connection in receiving message");
		while (!m_DCSSConnection.ConnectToDCSS( ))
		{
            xos_thread_sleep( 5000 );
			LOG_FINEST( "trying to connect to DCSS" );

			if (m_CmdStop) break;
		}
	}
}

void DcsMessageService::SendMessageToDCSS( )
{
	DcsMessage* pMsg = NULL;

	while ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
	{
		//send it out: it will delete the message even if it failed to sent it out.
		if (!m_DCSSConnection.SendAndDeleteDcsMessage( pMsg ))
		{
			//send failed, re-connect
			LOG_INFO( "lost socket connection in sending");
			xos_thread_sleep( 1000 );
			while (!m_DCSSConnection.ConnectToDCSS( ))
			{
				xos_thread_sleep( 5000 );
				LOG_FINEST( "trying to connect to DCSS" );
				if (m_CmdStop) break;
			}
		}
		if (m_CmdStop) break;
	}
}

BOOL DcsMessageService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	if (pMsg)
	{
		if (!m_MsgQueue.WaitEnqueue( pMsg, 1000 ))
		{
			LOG_SEVERE( "DcsMessageService Message Queue FULL: quit" );
            stop( );
			return FALSE; //we do not eat it.
		}
		LOG_FINEST1( "DcsMessageService::ConsumeDcsMessage: added to queue, current length=%d", m_MsgQueue.GetCount( ) );
	}

    //wake up sender: it is OK even in case no message was added to the queue
    xos_semaphore_post( &m_SemSenderWait );

	return TRUE;
}

//this function not used yet
void DcsMessageService::reset( )
{
    DcsMessageManager& theManager = DcsMessageManager::GetObject( );

    DcsMessage* pMsg = NULL;

    if ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
    {
		theManager.DeleteDcsMessage( pMsg );
    }
}

