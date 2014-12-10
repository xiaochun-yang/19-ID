
#include "log_quick.h"
#include "xiaSaturnService.h"
#include "xiaSaturnSystem.h"
#include "DcsMessageManager.h"
#include "XosStringUtil.h"
#include <string>
#include <vector>
#include "xiaSaturnAPI.h"

xiaSaturnService::OperationToMethod xiaSaturnService::m_OperationMap[] =
{//  name,								immediately, method to call
	{"acquireSpectrum", TRUE, &xiaSaturnService::acquireSpectrum}
};


/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/
xiaSaturnService::xiaSaturnService( ):
	m_MsgManager( DcsMessageManager::GetObject( )),
	m_MsgQueue( 1 ),
	m_pCurrentOperation(NULL),
	m_pInstantOperation(NULL)
{
	LOG_FINEST("xiaSaturnService constructor enter");
	xos_semaphore_create( &m_SemThreadWait, 0 );

   xiaSaturnInit();

	xiaSaturn_stop();

	LOG_FINEST("xiaSaturnService constructor exit");
}



/****************************************************************
 *
 * Destructor
 *
 ****************************************************************/
xiaSaturnService::~xiaSaturnService( )
{
   stop( );
   xos_semaphore_close( &m_SemThreadWait );
}

/****************************************************************
 *
 * start
 *
 ****************************************************************/
void xiaSaturnService::start( )
{

   if (m_Status != STOPPED)
   {
      LOG_WARNING( "called start when it is still not in stopped state" );
      return;
   }

   //set status to starting, this may cause broadcast if any one is interested in status change
	SetStatus( STARTTING );

   //reset all flags

   m_CmdStop = FALSE;
   m_CmdReset = FALSE;
   m_FlagEmergency = FALSE;

   xos_thread_create( &m_Thread, dcsMsgThreadRoutine, this );
}

/****************************************************************
 *
 * stop
 *
 ****************************************************************/
void xiaSaturnService::stop( )
{
   m_CmdStop = TRUE;
   if (m_Status == READY)
   {
      SetStatus( STOPPING );
   }

   //signal threads
   xos_semaphore_post( &m_SemThreadWait );
}


/****************************************************************
 *
 * reset
 *
 ****************************************************************/
void xiaSaturnService::reset( )
{
   // Clear message queue
   m_MsgQueue.Clear( );

	// Send abort reply for the unfinished operations
   abort();
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
BOOL xiaSaturnService::ConsumeDcsMessage( DcsMessage* pMsg )
{
   LOG_FINEST( "+xiaSaturnService::ConsumeDcsMessage" );

   //safety check
   if (pMsg == NULL)
   {
      LOG_WARNING( "xiaSaturnService::ConsumeDcsMessage called with NULL msg" );
      LOG_FINEST( "-xiaSaturnService::ConsumeDcsMessage" );
      return TRUE;
   }

   switch ( pMsg->ClassifyMessageType() )
   {
      case DCS_OPERATION_START_MSG:
         if ( HandleKnownOperations(pMsg) ) return TRUE;
         break;

      case DCS_ABORT_MSG:
         LOG_FINEST("-xiaSaturnService::ConsumeDcsMessage: abort unfinished operations");
         abort( );
         m_MsgManager.DeleteDcsMessage( pMsg );
         return TRUE;

      case DCS_ION_CHAMBER_READ_MSG:
         HandleIonChamberRequest(pMsg);
         m_MsgManager.DeleteDcsMessage( pMsg );
         return TRUE;

      case DCS_ION_CHAMBER_REGISTER_MSG:
         LOG_FINEST("-xiaSaturnService::ConsumeDcsMessage: consume ion chamber message.XXXXXX");
         m_MsgManager.DeleteDcsMessage( pMsg );
         //consume this message without doing anything
         return TRUE;

      case DCS_UNKNOWN_MSG:
         LOG_FINEST( "-xiaSaturnService::ConsumeDcsMessage: not recognized, pass on" );
         return FALSE;

      default:
        break;
   }
   LOG_FINEST( "-xiaSaturnService::ConsumeDcsMessage: not a message for that can be handled, pass on" );
   return FALSE;
}

BOOL xiaSaturnService::HandleKnownOperations( DcsMessage* pMsg )
{
   m_pInstantOperation = pMsg;
   //check to see if this is an operation we can finish immediately
   printf("OPNAME: %s\n", m_pInstantOperation->GetOperationName());
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
         LOG_FINEST( "-xiaSaturnService::ConsumeDcsMessage: we consume it" );
         return TRUE;
      }//if match one of supported operations
   }//for

   //not interested in this operation message
   return FALSE;
}

// Got stoh_read_ion_chambers
bool xiaSaturnService::HandleIonChamberRequest( DcsMessage* pMsg ) {
   std::string tmp;
   std::string time_secs;
   BOOL is_repeated = FALSE;

   ParseIonChamberRequest(pMsg->GetText(),
         tmp, time_secs, is_repeated );

   // Issue an asynchronous command.
   // When the result is ready, this dhs must send
   // a response htos_report_ion_chambers time_secs repeat counts
   //adac_read_ion_chambers(time_secs.c_str(), is_repeated,
   //     is_channel_wanted);

   return TRUE;
}

/****************************************************************
 *
 * SendoutDcsMessage
 *
 ****************************************************************/
void xiaSaturnService::SendoutDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST1( "xiaSaturnService::SendoutDcsMessage( %s )", pMsg->GetText( ) );
	if (!ProcessEvent( pMsg ))
	{
		LOG_INFO1( "xiaSaturnService: no one listening to this message, delete it: %s", pMsg->GetText( ) );
		m_MsgManager.DeleteDcsMessage( pMsg );
	}
	LOG_FINEST( "xiaSaturnService::SendoutDcsMessage exits");
}


/****************************************************************
 *
 * Run
 *
 ****************************************************************/
XOS_THREAD_ROUTINE xiaSaturnService::dcsMsgThreadRoutine(void* arg)
{
	xiaSaturnService* self = (xiaSaturnService*)arg;

	if (self == NULL) {
		xos_error("Invalid thread argument for monitorThreadRoutine");
		XOS_THREAD_ROUTINE_RETURN;
	}

	self->processDcsMessages();

	XOS_THREAD_ROUTINE_RETURN;
}

/****************************************************************
 *
 * ThreadMethod
 * Called by Run()
 *
 ****************************************************************/
void xiaSaturnService::processDcsMessages( )
{
 	SetStatus( READY );
	LOG_INFO( "xiaSaturn Service Thread ready" );

	while (TRUE) {

      //wait operation message comes up or stop command issued.
      LOG_FINEST( "dcs msg thread is waiting" );
      xos_semaphore_wait( &m_SemThreadWait, 0 );
      LOG_FINEST( "dcs msg thread out of waiting" );

      //check to see if it is stop
      if (m_CmdStop) {
         if (m_FlagEmergency) {
            //immediately return
            LOG_INFO( "xiaSaturn thread emergency exit" );
            return;
         }	else {
            //break the loop and clean up
            LOG_INFO( "xiaSaturn thread quit by STOP" );
            break;
         }
      }//if stopped
      // guard against empty message queue
      if (m_MsgQueue.IsEmpty( ))	continue;

      //OK a message is ready
      m_pCurrentOperation = m_MsgQueue.GetHead( );

      //we did not call Dequeue yet
      //this way we can honor the queue length limit.  Otherwise, you will allow one more
      //operation pending.
      //
      if (m_pCurrentOperation == NULL) {
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
         LOG_WARNING( "xiaSaturnService::ThreadMethod: should not been here, the match already did before put into queue\n");
         //remove this message from the queue and delete it
         m_pCurrentOperation = NULL;	//no delete
         m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
      }
   }//while

   LOG_INFO( "xiaSaturn thread stopped and EvtStopped set" );
   SetStatus( STOPPED );
}


/****************************************************************
 *
 * dcssAuthThreadRoutine
 *
 ****************************************************************/
void xiaSaturnService::abort()
{
	xiaSaturn_stop();

}



/*******************************************************************
 *
 * Acquire the Spectrum
 *
 *******************************************************************/
void xiaSaturnService::acquireSpectrum()
{
	//long timeMsecs = 0;

	LOG_FINEST("xiaSaturnService::acquireSpectrum enter\n");

	// Issue an asynchronous command.
	xiaSaturn_start(m_pInstantOperation->GetText());

   LOG_FINEST("xiaSaturnService::acquireSpectrum exit\n");
}

/********************************************************************
 *
 * The request string is in the following format
 * stoh_read_ion_chambers time_secs is_repeated [channel_name]+
 *
 ********************************************************************/
bool xiaSaturnService::ParseIonChamberRequest(const char* str,
      std::string& command,
      std::string& time_secs,
      BOOL& is_repeated )
{

   #define NUM_CHANNELS 1
   if (!str || !*str )
      return false;

   std::string message(str);
   std::list<std::string> tokens;
   size_t beg = 0;

   for (size_t i = 0; i < message.length(); ++i)
   {
      if (message[i] == ' ') {
         tokens.push_back(message.substr(beg, i-beg));
         beg = i+1;
      }
   }

   if (beg < message.length())
      tokens.push_back(message.substr(beg));

   command = tokens.front();
   tokens.pop_front();

   time_secs = tokens.front();
   tokens.pop_front();

   std::string tmp = tokens.front();
   tokens.pop_front();
   is_repeated = atoi(tmp.c_str());

   while (tokens.size() > 0) {
      const std::string& channel = tokens.front();
      int ordinal = atoi(channel.substr(1).c_str());
      tokens.pop_front();
   }
   return true;
}

