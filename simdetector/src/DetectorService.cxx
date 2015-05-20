
#include "log_quick.h"
#include "DetectorService.h"
#include "DcsMessageManager.h"
#include "Detector.h"
#include "SimDetector.h"
#include "DetectorFactory.h"
#include <string>
#include "XosStringUtil.h"

#define STRING_DETECTOR_TYPE "detectorType"

/**
 * Operation to method map
 */
DetectorService::MsgToMethod DetectorService::m_msgActionMap[] =
{//  name,								type, immediately, method to call
	{"detector_collect_image",			FALSE, &DetectorService::detectorCollectImage},
	{"detector_transfer_image",			TRUE, &DetectorService::detectorTransferImage},
	{"detector_oscillation_ready",		TRUE, &DetectorService::detectorOscillationReady},
	{"detector_stop",                   TRUE, &DetectorService::detectorStop},
	{"detector_reset_run",           	TRUE, &DetectorService::detectorResetRun}
};


/**
 * Constructor
 */
DetectorService::DetectorService(const std::string& type):
	m_MsgManager( DcsMessageManager::GetObject( )),
	m_MsgQueue( 1 ),
	m_pDetector(NULL),
	m_detectorClass(type),
	m_pCurrentOperation(NULL),
	m_pInstantOperation(NULL)
{
    xos_semaphore_create( &m_SemThreadWait, 0 );
    xos_semaphore_create( &m_SemStopOnly, 0 );
    
}

/**
 * Destructor
 */
DetectorService::~DetectorService( )
{
	stop( );
	delete m_pDetector;

    xos_semaphore_close( &m_SemStopOnly );
    xos_semaphore_close( &m_SemThreadWait );
}

/**
 * Start
 */
void DetectorService::start( )
{
    // Create a detector for the given type
    m_pDetector = DetectorFactory::newDetector(m_detectorClass);
    
    if (m_pDetector == NULL) {
    	LOG_SEVERE1("Failed to create detector of type %s\n", m_detectorClass.c_str());
    	return;
    }
       	

    m_pDetector->SetSleepSemaphore( &m_SemStopOnly );

    if (m_Status != STOPPED)
	{
		LOG_WARNING( "called start when it is still not in stopped state" );
		return;
	}

    //set status to starting, this may cause broadcase 
    // if any one is interested in status change
	SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;

    xos_thread_create( &m_Thread, Run, this );

}

/**
 * Stop
 */
void DetectorService::stop( )
{
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }

    //signal threads
    xos_semaphore_post( &m_SemThreadWait );
}


//this function not used yet
void DetectorService::reset( )
{
    DcsMessageManager& theManager = DcsMessageManager::GetObject( );

    DcsMessage* pMsg = NULL;

    if ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
    {
		theManager.DeleteDcsMessage( pMsg );
    }
}

//this is called by other thread:
//we will check the content of the message, if it can be immediately dealt with,
//we send reply directly, otherwise, it will be put in a queue and wait our own
//thread to deal with it.
#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))
BOOL DetectorService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST( "+DetectorService::ConsumeDcsMessage" );

	//safety check
	if (pMsg == NULL)
	{
		LOG_WARNING( "DetectorService::ConsumeDcsMessage called with NULL msg" );
		LOG_FINEST( "-DetectorService::ConsumeDcsMessage" );
		return TRUE;
	}

    //deal with attribute string
    if (!strncmp( pMsg->GetText( ), "stoh_register_string", 20 ))
    {
		const char* pStringName = pMsg->GetText( ) + 21;
		if (!strncmp( pStringName, STRING_DETECTOR_TYPE, strlen(STRING_DETECTOR_TYPE)))
		{
			LOG_FINEST1("Got stoh_register_string %s", STRING_DETECTOR_TYPE);
			//ask DCSS to send contents
			DcsMessage* pAskConfig = 
					m_MsgManager.NewAskConfigMessage(STRING_DETECTOR_TYPE);
			if (pAskConfig)
			{
				SendoutDcsMessage(pAskConfig);
			}
			else
			{
				LOG_WARNING( "string detectorType failed at ask for config" );
			}
			LOG_FINEST1( "%s ask for contents", STRING_DETECTOR_TYPE);

		}//name match string name

		//delete the messag 
        m_MsgManager.DeleteDcsMessage(pMsg);
    	LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: stoh_register_string" );
        return TRUE;
    }//it is register string


    if (pMsg->IsString())
    {
		LOG_FINEST2( "received string name=\"%s\", contents=\"%s\"",
			pMsg->GetStringName( ),
			pMsg->GetStringContents( ));
        if (!strncmp(pMsg->GetStringName(), STRING_DETECTOR_TYPE, 
        							strlen(STRING_DETECTOR_TYPE))) {
        
			std::string tmp;
         if (pMsg->GetStringContents() != NULL)
            	tmp = pMsg->GetStringContents();

			m_MsgManager.DeleteDcsMessage(pMsg);

			std::string tmp1 = "";
			if ((tmp.find("{") != std::string::npos) && (tmp.find("}") != std::string::npos))
					tmp1 = tmp.substr(1, tmp.size()-2);
			else if (tmp.find("{") != std::string::npos)
					tmp1 = tmp.substr(1);
			else if (tmp.find("}") != std::string::npos)
					tmp1 = tmp.substr(0, tmp.size()-1);
			else
					tmp1 = tmp;
	        	
			std::string type = XosStringUtil::trim(tmp1, " \n\r\t");
	      LOG_INFO1("Detector type = %s\n", type.c_str());
			m_pDetector->setDetectorType(type);
	              
	        // reply
			DcsMessage* reply = m_MsgManager.NewStringCompletedMessage(
											STRING_DETECTOR_TYPE, 
											"normal", type.c_str());
			if (reply)
				SendoutDcsMessage(reply);
		    LOG_FINEST1( "-ImpersonService::ConsumeDcsMessage: string %s message, done",
		    				type.c_str());
            return TRUE;
            
        } else {
    		LOG_FINEST( "-ImpersonService::ConsumeDcsMessage: unsupported string setting, pass on" );
            return FALSE;
        }
    }


	//currently we only support operation message and "soft abort message"
	if (!pMsg->IsOperation( ))
	{
		if (pMsg->IsAbortAll( ))
		{
            //you can set a flag here
            //do not clear the message queue.
            //The DCSS may wait for the operation completed message forever.
            //Abort message should not be eaten.
		}
		LOG_FINEST( "-DetectorService::ConsumeDcsMessage: not operation, pass on" );
		return FALSE;
	}

	m_pInstantOperation = pMsg;
	//check to see if this is an operation we can finish immediately

	for (unsigned int i = 0; i < ARRAYLENGTH(m_msgActionMap); ++i)
	{
		if (!strcmp( m_pInstantOperation->GetOperationName( ), m_msgActionMap[i].m_OperationName ))
		{
			LOG_FINEST1( "match operation%d", i );
			m_pInstantOperation->m_PrivateData = i;
			if (m_msgActionMap[i].m_Immediately)
			{
				LOG_FINEST( "immediately" );
				(this->*m_msgActionMap[i].m_pMethod)();
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
						LOG_FINEST1( "added to Detector queue, current length=%d\n", m_MsgQueue.GetCount( ) );

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
			if (m_pInstantOperation) m_MsgManager.DeleteDcsMessage( m_pInstantOperation );
			LOG_FINEST( "-DetectorService::ConsumeDcsMessage: we consume it" );
			return TRUE;
		}//if match one of supported operations
	}//for

	LOG_FINEST( "-DetectorService::ConsumeDcsMessage: no match operation, pass on" );
	return FALSE;
}

/**
 */
void DetectorService::SendoutDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST1( "DetectorService::SendoutDcsMessage( %s )", pMsg->GetText( ) );

	if (!ProcessEvent( pMsg ))
	{
		LOG_INFO1( "DetectorService: no one listening to this message, delete it: %s", pMsg->GetText( ) );
		m_MsgManager.DeleteDcsMessage( pMsg );
	}
}

/**
 */
void DetectorService::ThreadMethod( )
{

	//init the detector
	if ((m_pDetector == NULL) || !m_pDetector->Initialize())
	{
		LOG_SEVERE( "detector initialization failed. thread quit" );
        SetStatus( STOPPED );
		return;
	}
	
    SetStatus( READY );

	LOG_INFO( "Detector Thread ready" );

	while (TRUE)
	{
		//wait operation message comes up or stop command issued.
        xos_semaphore_wait( &m_SemThreadWait, 0 );
		LOG_FINEST( "Detector thread out of waiting" );
		//check to see if it is stop
		if (m_CmdStop)
		{
			if (m_FlagEmergency)
			{
				//immediately return
				LOG_INFO( "Detector thread emergency exit" );
				return;
			}
			else
			{
				//break the loop and clean up
				LOG_INFO( "Detector thread quit by STOP" );
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
			m_pCurrentOperation->m_PrivateData < (int)ARRAYLENGTH(m_msgActionMap))
		{
			//the message is pointed by m_pCurrentOperation, does not need to pass
			(this->*m_msgActionMap[m_pCurrentOperation->m_PrivateData].m_pMethod)();
		}
		else
		{
			LOG_WARNING( "DetectorService::ThreadMethod: should not been here, the match already did before put into queue\n");
			//remove this message from the queue and delete it
			m_pCurrentOperation = NULL;	//no delete
			m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
		}
	}//while

    //clean up before exit
    m_pDetector->Cleanup( );

	LOG_INFO( "Detector thread stopped and EvtStopped set" );
    SetStatus( STOPPED );
}

/**
 * Handle instant message
 */
void DetectorService::handleInstantMessage( PTR_DETECTOR_FUNC pMethod )
{
	char status_buffer[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
	
	// Call the method
	(m_pDetector->*pMethod)( m_pInstantOperation->GetOperationArgument( ), 
							 status_buffer );

	//make a DcsMessage for it and send out
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( 
									m_pInstantOperation, 
									status_buffer );
	SendoutDcsMessage( pReply );
		
}

/**
 * Handle detector_collect_image operation
 */
void DetectorService::detectorCollectImage()
{
	char status_buffer[MAX_LENGTH_STATUS_BUFFER + 1] = {0};

	if (!m_pDetector->detectorCollectImage(
						m_pCurrentOperation->GetOperationArgument( ), 
						status_buffer )) {

		// Wait for operation update string
		// waitForOperationUpdate() will not return until 
		// there is a message string to be sent
		// or when the operation is completed or an error occurs.
		while (!m_pDetector->detectorCollectImageUpdate(status_buffer))
		{
			if (status_buffer[0] != '\0') {

				status_buffer[MAX_LENGTH_STATUS_BUFFER] = '\0';
				//update
				DcsMessage* pReply = m_MsgManager.NewOperationUpdateMessage( 
							m_pCurrentOperation, status_buffer );
				SendoutDcsMessage( pReply );

				//check if stop command in effect
				if (m_CmdStop)
				{
					LOG_INFO( "DetectorService::handleQueueMessage: got stop during looping" );
					m_pCurrentOperation = NULL;
					m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
					return;
				}
			}
		}
		
	}

	//The order is important here: the creation of reply message needs current operation message,
	//you cannot delete it yet.
	//You must set the current operation to NULL and remove it from Queue before you send out reply

	//final reply
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pCurrentOperation, status_buffer );

	//before sending out, do clear first to prepare for next message
	//remove this message from the queue and delete it
	m_pCurrentOperation = NULL;
	m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
	
	//send the reply out at the last step
	SendoutDcsMessage( pReply );

	// If finished successfully then send
	// htos_string_completed lastImageCollected normal <filename>
	if (m_pDetector->lastImageCollected(status_buffer)) {
		char msg[255];
		snprintf(msg, 255, "htos_set_string_completed lastImageCollected normal %s",
				status_buffer);
		DcsMessage* strMsg = m_MsgManager.NewDcsTextMessage(msg);
		SendoutDcsMessage( strMsg );
	}
	
}


/**
 */
void DetectorService::detectorTransferImage( )
{
	handleInstantMessage( &Detector::detectorTransferImage );
}

/**
 */
void DetectorService::detectorOscillationReady( )
{
	handleInstantMessage( &Detector::detectorOscillationReady );
}

/**
 */
void DetectorService::detectorStop( )
{
	handleInstantMessage( &Detector::detectorStop );
}

/**
 */
void DetectorService::detectorResetRun( )
{
	handleInstantMessage( &Detector::detectorResetRun );
}



