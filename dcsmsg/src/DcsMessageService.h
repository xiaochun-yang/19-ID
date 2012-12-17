#ifndef __XOS_DCS_MESSAGE_SERVICE_H__
#define __XOS_DCS_MESSAGE_SERVICE_H__

#include "activeObject.h"
#include "DcsMessage.h"
#include "DcsMessageHandler.h"
#include "MQueue.h"

#include "DcsMessageTwoWay.h"
#include "xos.h"

class DcsMessageService:
	public DcsMessageTwoWay
{
public:
	DcsMessageService( int max_queue_length = 10 );
	~DcsMessageService(void);

    void SetupDCSSServerInfo( const char servername[], int port );
    void SetDHSName( const char name[] );

	//implement interface activeObject
	virtual void start( );
	virtual void reset( );	//currenly, only clean up the outging message queue.
    virtual void stop( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

private:
	static XOS_THREAD_ROUTINE SenderRun( void* pParam )
	{
		DcsMessageService* pObj = (DcsMessageService*)pParam;
		pObj->SenderThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}
	static XOS_THREAD_ROUTINE ReceiverRun( void* pParam )
	{
		DcsMessageService* pObj = (DcsMessageService*)pParam;
		pObj->ReceiverThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}

	void SenderThreadMethod( );
	void ReceiverThreadMethod( );

	void ReceiveMessageFromDCSS( );
	void SendMessageToDCSS( );



	////////////////////////////////DATA//////////////////////////////
private:
	//socket wrapper
	DcsMessageHandler m_DCSSConnection;

	//message queue: messages waiting to send out to DCSS
	MQueue m_MsgQueue;

    //sender thread will wait on this event for message or command
    xos_semaphore_t m_SemSenderWait;

    //receiver will wait on this event if it was not waiting on socket.
    //If it is waiting on socket, will poll command flags every second.
    xos_event_t m_EvtReceiverWait;

	//thread
	xos_thread_t m_SenderThread;
	xos_thread_t m_ReceiverThread;

	//lock for socket access
	xos_mutex_t m_Lock;
};

#endif //#ifndef __XOS_DCS_MESSAGE_SERVICE_H__

