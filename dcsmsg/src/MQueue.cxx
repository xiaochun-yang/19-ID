#include "MQueue.h"
#include "XOSSingleLock.h"
#include "DcsMessageManager.h"

DcsMessageManager* MQueue::m_pDcsMsgManager(NULL);


MQueue::MQueue( int max_length ):
	CPPNativeList<DcsMessage*>( max_length )
{
    xos_mutex_create( &syncMtx );
    xos_event_create( &m_evtWaitEnqueue, TRUE, FALSE );
    if (m_pDcsMsgManager == NULL)
    {
        m_pDcsMsgManager = &(DcsMessageManager::GetObject( ));
    }
}

MQueue::~MQueue ( void )
{ 
    m_pDcsMsgManager = NULL; //so Clear will not try do delete messages
	Clear ( );
    xos_event_close( &m_evtWaitEnqueue );
    xos_mutex_close( &syncMtx );
}

BOOL MQueue::Enqueue( DcsMessage* pDcsM ) 
{
	//lock the mutex before any change
	XOSSingleLock singleLock( &syncMtx );

	BOOL result = AddTail( pDcsM );	//super class call

    if (result && IsFull( )) xos_event_reset( &m_evtWaitEnqueue );

    return result;
}
BOOL MQueue::WaitEnqueue ( DcsMessage* pDcsM, unsigned long timeout ) 
{
    if (Enqueue( pDcsM )) return TRUE;

    if (xos_event_wait( &m_evtWaitEnqueue, timeout ) != XOS_WAIT_SUCCESS)
    {
        return FALSE;
    }
    return Enqueue( pDcsM );
}

DcsMessage* MQueue::Dequeue ( void ) 
{
	DcsMessage *pResult = NULL;

	//lock the mutex
	XOSSingleLock singleLock ( &syncMtx );

	//get head if gain the mutex
	if (!IsEmpty( )) {
		pResult = RemoveHead ( );
	}
    xos_event_set( &m_evtWaitEnqueue );

	//check to see if need to reset waiting event
	return pResult;
}

void MQueue::Clear ( )
{
	XOSSingleLock singleLock ( &syncMtx );
    _clear( );
}
void MQueue::_clear ( )
{
    if (m_pDcsMsgManager)
    {
        while (!IsEmpty( ))
        {
            DcsMessage* pMsg = RemoveHead( );
            m_pDcsMsgManager->DeleteDcsMessage( pMsg );
        }
    }
	Clean( );
    xos_event_set( &m_evtWaitEnqueue );
}

void MQueue::ClearAndEnqueue ( DcsMessage* pMsg )
{
	XOSSingleLock singleLock ( &syncMtx );
    _clear( );
	AddTail( pMsg );
    if (!IsFull( )) xos_event_set( &m_evtWaitEnqueue );
}

int MQueue::GetCount( ) const
{
	XOSSingleLock singleLock ( &syncMtx );
	return GetLength( );

}

