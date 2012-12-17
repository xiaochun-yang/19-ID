
#include "log_quick.h"
#include "ImpersonService.h"
#include "ImpersonSystem.h"
#include "DcsMessageManager.h"
#include "XosStringUtil.h"
#include "AutochoochThread.h"
#include "SnapThread.h"
#include "FileAccessThread.h"
#include "SilThread.h"
#include "AllSilThread.h"
#include "Strategy.h"
#include "ImageConvertThread.h"
#include <string>
#include <vector>

#define STRING_SIL_ID "sil_id"
//#define STRING_STRATEGY "strategy_status"
#define STRING_STRATEGY "strategy_file"
#define STRING_SIL_EVENT_ID "sil_event_id"


ImpersonService::OperationToMethod ImpersonService::m_OperationMap[] =
{//  name,								immediately, method to call
	{OP_SNAP,						FALSE, &ImpersonService::doSnap},
	{OP_RUN_AUTOCHOOCH,				FALSE, &ImpersonService::doAutochooch},
	{OP_WRITE_EXCITATION_SCAN_FILE,	FALSE, &ImpersonService::doFileAccess},
	{OP_GET_NEXT_FILE_INDEX,		FALSE, &ImpersonService::doFileAccess},
	{OP_GET_LAST_FILE,				FALSE, &ImpersonService::doFileAccess},
	{OP_COPY_FILE,					FALSE, &ImpersonService::doFileAccess},
	{OP_LIST_FILES,					FALSE, &ImpersonService::doFileAccess},
	{OP_APPEND_TEXT_FILE,			FALSE, &ImpersonService::doFileAccess},
	{OP_READ_TEXT_FILE,				FALSE, &ImpersonService::doFileAccess},
	{OP_IMAGE_CONVERT,				FALSE, &ImpersonService::doImageConvert}
};


/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
ImpersonService::ImpersonService( ):
	m_MsgManager( DcsMessageManager::GetObject( )),
	m_MsgQueue( 1 ),
	m_pCurrentOperation(NULL),
	m_pInstantOperation(NULL),
	m_silThread(NULL),
	m_strategyThread(NULL),
	m_allSilThread(NULL)
{
	LOG_FINEST("ImpersonService constructor enter");
    xos_semaphore_create( &m_SemThreadWait, 0 );
	LOG_FINEST("ImpersonService constructor exit");

	// Create random seed
	srand(time(NULL));


}

/****************************************************************
 *
 * Destructor
 *
 ****************************************************************/
ImpersonService::~ImpersonService( )
{
	stop( );

    xos_semaphore_close( &m_SemThreadWait );

}

/****************************************************************
 *
 * start
 *
 ****************************************************************/
void ImpersonService::start( )
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

	// Start sil thread
	if (m_silThread == NULL)
		m_silThread = new SilThread(this,ImpersonSystem::getInstance()->getConfig());
	if(m_strategyThread == NULL)
		m_strategyThread = new Strategy(this,ImpersonSystem::getInstance()->getConfig());

	if (m_allSilThread == NULL)
		m_allSilThread = new AllSilThread(this,ImpersonSystem::getInstance()->getConfig());
    xos_thread_create( &m_Thread, dcsMsgThreadRoutine, this );

	m_silThread->start();
	m_strategyThread->start();
	m_allSilThread->start();
}

/****************************************************************
 *
 * stop
 *
 ****************************************************************/
void ImpersonService::stop( )
{
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }

    m_silThread->stop();
    m_strategyThread->stop();

    //signal threads
    xos_semaphore_post( &m_SemThreadWait );
}


/****************************************************************
 *
 * reset
 *
 ****************************************************************/
void ImpersonService::reset( )
{
	// Clear message queue
	m_MsgQueue.Clear( );

	// Send abort reply for the unfinished operations
	abort();

}
bool ImpersonService::stringRegistered( const char* pStringName ) const {
    LOG_INFO1( "stringRegistered size %ld", m_registeredString.size( ) );
    return find (m_registeredString.begin(), m_registeredString.end( ), std::string( pStringName)) != m_registeredString.end( );
}

/****************************************************************
 *
 * ConsumeDcsMessage
 * This is called by other thread:
 * we will check the content of the message, if it can be immediately dealt with,
 * we send reply directly, otherwise, it will be put in a queue and wait our own
 * thread to deal with it.
 *
 ****************************************************************/
#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))
BOOL ImpersonService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST( "+ImpersonService::ConsumeDcsMessage" );

	//safety check
	if (pMsg == NULL)
	{
		LOG_WARNING( "ImpersonService::ConsumeDcsMessage called with NULL msg" );
		LOG_FINEST( "-ImpersonService::ConsumeDcsMessage" );
		return TRUE;
	}

    //deal with attribute string
    if (!strncmp( pMsg->GetText( ), "stoh_register_string", 20 ))
    {
		const char* pStringName = pMsg->GetDeviceName( );

        if (!stringRegistered( pStringName )) {
            LOG_INFO1( "stringRegistered %s", pStringName );
            m_registeredString.push_back( pStringName );
        }

		if (!strncmp( pStringName, STRING_SIL_ID, strlen(STRING_SIL_ID)))
		{
			LOG_FINEST1("Got stoh_register_string %s", STRING_SIL_ID);
			//ask DCSS to send contents
			DcsMessage* pAskConfig =
					m_MsgManager.NewAskConfigMessage(STRING_SIL_ID);
			if (pAskConfig)
			{
				SendoutDcsMessage(pAskConfig);
			}
			else
			{
				LOG_WARNING( "string sil_id failed at ask for config" );
			}
			LOG_FINEST1( "%s ask for contents", STRING_SIL_ID);

		}//name match string name
		if(!strncmp(pStringName,STRING_STRATEGY,strlen(STRING_STRATEGY))){
			LOG_FINEST1("Got stoh_register_string %s",STRING_STRATEGY);
			DcsMessage* pAskConfig = m_MsgManager.NewAskConfigMessage(STRING_STRATEGY);
			if (pAskConfig){
				SendoutDcsMessage(pAskConfig);
			}
			else{
				LOG_WARNING( "string_strategy failed at ask for config" );
			}
			LOG_FINEST1( "%s ask for contents", STRING_STRATEGY);
		}

		//delete the messag
        m_MsgManager.DeleteDcsMessage(pMsg);
    	LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: stoh_register_string" );
        return TRUE;
    }//it is register string

	// Handle string
/*    if (!strncmp( pMsg->GetText( ), "stoh_configure_string", 21))
    {
    	char pMsgPrefix[100];
    	char pOwner[100];
    	char pStringName[100];
    	char pStringContent[100];
    	sscanf(pMsg->GetText(), "%s %s %s %s", pMsgPrefix, pStringName, pOwner, pStringContent);
		LOG_FINEST3( "received stoh_configure_string owner=%s, name=%s, contents=%s",
					pOwner, pStringName, pStringContent);
        if (!strncmp(pStringName, STRING_SIL_ID, 
        							strlen(STRING_SIL_ID))) {
        
        	std::string silId = "";
            if (pStringContent != NULL)
            	silId = pStringContent;
	        m_MsgManager.DeleteDcsMessage(pMsg);
	        
	        LOG_INFO1("silId = %s\n", silId.c_str());
	        // reply
			DcsMessage* reply = m_MsgManager.NewStringCompletedMessage(
											STRING_SIL_ID, 
											"normal", silId.c_str());
			if (reply)
				SendoutDcsMessage(reply);
		    LOG_FINEST1( "-ImpersonService::ConsumeDcsMessage: string %s message, done",
		    				STRING_SIL_ID);
            return TRUE;
            
        } else {
    		LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: unsupported string setting, pass on" );
            return FALSE;
        }
    }
*/
    if (pMsg->IsString()){
		LOG_FINEST2( "received string name=\"%s\", contents=\"%s\"",pMsg->GetStringName( ),pMsg->GetStringContents( ));
    	if (!strncmp(pMsg->GetStringName(), STRING_SIL_ID,strlen(STRING_SIL_ID))) {
			std::string silId = "";
        	if (pMsg->GetStringContents() != NULL)
        		silId = pMsg->GetStringContents();
	        m_MsgManager.DeleteDcsMessage(pMsg);
			LOG_INFO1("silId = %s\n", silId.c_str());
			m_silThread->setSilId(silId);
	        // reply
			DcsMessage* reply = m_MsgManager.NewStringCompletedMessage(STRING_SIL_ID,"normal", silId.c_str());
			if (reply)
				SendoutDcsMessage(reply);
			LOG_FINEST1( "-ImpersonService::ConsumeDcsMessage: string %s message, done",STRING_SIL_ID);
			return TRUE;
        }
		else if(!strncmp(pMsg->GetStringName(),STRING_STRATEGY,strlen(STRING_STRATEGY))){
			std::string data = "";
			if(pMsg->GetStringContents() != NULL){
				data = pMsg->GetStringContents();
			}
			m_MsgManager.DeleteDcsMessage(pMsg);
			m_strategyThread->setNew(data);
			DcsMessage* reply = m_MsgManager.NewStringCompletedMessage(STRING_STRATEGY,"normal", data.c_str());
			if (reply)
				SendoutDcsMessage(reply);
			return TRUE;
		}
		else{
			LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: unsupported string setting, pass on" );
			return FALSE;
        }
    }

	//currently we only support operation message and "soft abort message"
	if (!pMsg->IsOperation( ))
	{
		if (pMsg->IsAbortAll( ))
		{
			LOG_FINEST("-ImpersonService::ConsumeDcsMessage: abort unfinished operations");
			abort( );
			m_MsgManager.DeleteDcsMessage( pMsg );
			return TRUE;
		}

		LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: not operation, pass on" );
		return FALSE;
	}

	m_pInstantOperation = pMsg;
	//check to see if this is an operation we can finish immediately

	for (unsigned int i = 0; i < ARRAYLENGTH(m_OperationMap); ++i)
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
						LOG_FINEST1( "added to dcs msg queue, current length=%d\n", m_MsgQueue.GetCount( ) );

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
							strcat( status_buffer, "doing " );
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
			if (m_pInstantOperation)
				m_MsgManager.DeleteDcsMessage( m_pInstantOperation );
			LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: we consume it" );
			return TRUE;
		}//if match one of supported operations
	}//for

	LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: no match operation, pass on" );
	return FALSE;
}

/****************************************************************
 *
 * SendoutDcsMessage
 *
 ****************************************************************/
void ImpersonService::SendoutDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST1( "ImpersonService::SendoutDcsMessage( %s )", pMsg->GetText( ) );

	if (!ProcessEvent( pMsg ))
	{
		LOG_INFO1( "ImpersonService: no one listening to this message, delete it: %s", pMsg->GetText( ) );
		m_MsgManager.DeleteDcsMessage( pMsg );
	}
	LOG_FINEST( "ImpersonService::SendoutDcsMessage exits");
}

/****************************************************************
 *
 * removeCompletedOperations
 *
 ****************************************************************/
void ImpersonService::removeCompletedOperations()
{
	// lock
	if (m_mutex.trylock()) {
		
		if (!activeOperations.empty()) {
		
			// Get the first thread in the list
			OperationThread* aThread = activeOperations.front();
			// Remove it from the list for now
			activeOperations.pop_front();
			if (aThread->isFinished()) {
				// Thread has exited.
				delete aThread;
			} else {
				// Put it back at the end of the list
				activeOperations.push_back(aThread);
			}
		}

		m_mutex.unlock();
		
	}
}


/****************************************************************
 *
 * dcssAuthThreadRoutine
 *
 ****************************************************************/
XOS_THREAD_ROUTINE ImpersonService::monitorThreadRoutine(void * arg )
{

	ImpersonService* self = (ImpersonService*)arg;
	
	if (self == NULL) {
		xos_error("Invalid thread argument for monitorThreadRoutine");
		XOS_THREAD_ROUTINE_RETURN;
	}
	
	bool forever = true;

	//	int cnt =0;
	//loop forever, loading the permissions every 60 seconds
	while (forever) {
	
		self->removeCompletedOperations();	
		xos_thread_sleep(500);
		

	}
		
	// code should never reach here
	XOS_THREAD_ROUTINE_RETURN;
		
}


/****************************************************************
 *
 * Run
 *
 ****************************************************************/
XOS_THREAD_ROUTINE ImpersonService::dcsMsgThreadRoutine(void* arg)
{
	ImpersonService* self = (ImpersonService*)arg;
	
	if (self == NULL) {
		xos_error("Invalid thread argument for monitorThreadRoutine");
		XOS_THREAD_ROUTINE_RETURN;
	}

	xos_thread_t aThread;
    xos_thread_create(&aThread, monitorThreadRoutine, self);

	self->processDcsMessages();
	
	XOS_THREAD_ROUTINE_RETURN;
	
}

/****************************************************************
 *
 * ThreadMethod
 * Called by Run()
 *
 ****************************************************************/
void ImpersonService::processDcsMessages( )
{

    SetStatus( READY );

	LOG_INFO( "Robot Thread ready" );

	while (TRUE)
	{
		//wait operation message comes up or stop command issued.
		LOG_FINEST( "dcs msg thread is waiting" );
        xos_semaphore_wait( &m_SemThreadWait, 0 );
		LOG_FINEST( "dcs msg thread out of waiting" );
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
			continue;
		}

		//OK it is the message ready
		m_pCurrentOperation = m_MsgQueue.GetHead( );	//we did not call Dequeue yet
		//this way we can honor the queue length limit.  Otherwise, you will allow one more
		//operatin pending.

		if (m_pCurrentOperation == NULL)
		{
			m_MsgQueue.Dequeue( );
			continue;
		}

		//deal with it
		if (m_pCurrentOperation->m_PrivateData >= 0 &&
			m_pCurrentOperation->m_PrivateData < (int)ARRAYLENGTH(m_OperationMap))
		{
			//the message is pointed by m_pCurrentOperation, does not need to pass
			(this->*m_OperationMap[m_pCurrentOperation->m_PrivateData].m_pMethod)( );
		}
		else
		{
			LOG_WARNING( "ImpersonService::ThreadMethod: should not been here, the match already did before put into queue\n");
			//remove this message from the queue and delete it
			m_pCurrentOperation = NULL;	//no delete
			m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
		}
		
	}//while


	LOG_INFO( "Robot thread stopped and EvtStopped set" );
    SetStatus( STOPPED );
}


/****************************************************************
 *
 * dcssAuthThreadRoutine
 *
 ****************************************************************/
void ImpersonService::abort()
{
	
	// lock
	m_mutex.lock();
		
	// Loop over operations that are unfinished and send out
	// an abort reply for each operation.
	// Later when the thread that handles the operation actually finishes,
	// the operation completed will be sent out.
	std::list<OperationThread*>::iterator i = activeOperations.begin();
	for (; i != activeOperations.end(); ++i) {
	
		OperationThread* aThread = *i;
		DcsMessage* msg = aThread->getDcsMessage();
		DcsMessage* reply = m_MsgManager.NewOperationCompletedMessage(msg, "abort");

		// The reply message will be deleted in SendoutDcsMessage()
		// if no other handlers want to process it.
		SendoutDcsMessage(reply);
		
	}

	m_mutex.unlock();
		
}


/*******************************************************************
 *
 * // doAutochooch
 *
 *******************************************************************/
void ImpersonService::doAutochooch()
{
	LOG_FINEST("ImpersonService::doAutochooch enter\n");

	DcsMessage* pMsg = m_MsgQueue.Dequeue();
	m_pCurrentOperation = NULL;
	OperationThread* aThread = new AutochoochThread(this, pMsg, 
									ImpersonSystem::getInstance()->getConfig());

	aThread->start();


	// Save the operation handler object in the list
	m_mutex.lock();
	activeOperations.push_back(aThread);
	m_mutex.unlock();
		
		
	LOG_FINEST("ImpersonService::doAutochooch exit\n");
}


/*******************************************************************
 *
 * // Run autochooch on this thread
 *
 *******************************************************************/
void ImpersonService::doSnap()
{
	LOG_FINEST("ImpersonService::doSnap enter\n");
	
	DcsMessage* pMsg = m_MsgQueue.Dequeue();
	m_pCurrentOperation = NULL;
	OperationThread* aThread = new SnapThread(this, pMsg,
										ImpersonSystem::getInstance()->getConfig());
	
	// Save the operation handler object in the list
	m_mutex.lock();
	activeOperations.push_back(aThread);
	m_mutex.unlock();

	aThread->start();
		
	LOG_FINEST("ImpersonService::doSnap exit\n");
}

/*******************************************************************
 *
 * // Run saveCan on this thread
 *
 *******************************************************************/
void ImpersonService::doFileAccess()
{
	LOG_FINEST("ImpersonService::doFileAccess enter\n");
	
	DcsMessage* pMsg = m_MsgQueue.Dequeue();
	m_pCurrentOperation = NULL;
	OperationThread* aThread = new FileAccessThread(this, pMsg,
										ImpersonSystem::getInstance()->getConfig());
	
	// Save the operation handler object in the list
	m_mutex.lock();
	activeOperations.push_back(aThread);
	m_mutex.unlock();

	aThread->start();
		
	LOG_FINEST("ImpersonService::doFileAccess exit\n");
}

void ImpersonService::doImageConvert()
{
	LOG_FINEST("ImpersonService::doImageConvert enter\n");
	
	DcsMessage* pMsg = m_MsgQueue.Dequeue();
	m_pCurrentOperation = NULL;
	OperationThread* aThread = new ImageConvertThread(this, pMsg,
										ImpersonSystem::getInstance()->getConfig());
	
	// Save the operation handler object in the list
	m_mutex.lock();
	activeOperations.push_back(aThread);
	m_mutex.unlock();

	aThread->start();
		
	LOG_FINEST("ImpersonService::doImageConvert exit\n");
}
