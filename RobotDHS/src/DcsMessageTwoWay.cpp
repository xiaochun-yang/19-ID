#include "xos.h"
#include "XOSSingleLock.h"
#include "DcsMessageTwoWay.h"

BOOL DcsMessageSource::Register( DcsMessageListener& listener )
{
	XOSSingleLock lockQueue( &m_LQLock );

	if (m_ListenersQueue.Find( &listener ) != LIST_ELEMENT_NOT_FOUND)
	{
		return TRUE;
	}
	else
	{
		m_ListenersQueue.AddHead( &listener );
		return TRUE;
	}
}

void DcsMessageSource::Unregister( DcsMessageListener& listener )
{
	XOSSingleLock lockQueue( &m_LQLock );

	m_ListenersQueue.RemoveElement( &listener );

}

BOOL DcsMessageSource::ProcessEvent( DcsMessage* pMsg )
{

	if (pMsg == NULL) return TRUE;

	//we will need a local copy of the listeners queue.
	xos_mutex_lock( &m_LQLock );
	CPPNativeList<DcsMessageListener*> localCopyOfQ( m_ListenersQueue );
	xos_mutex_unlock( &m_LQLock );


	//process the event
	XOSSingleLock holdProcess( &m_ProcessLock );

	for (int position = localCopyOfQ.GetFirst( ); position != LIST_ELEMENT_NOT_FOUND; position = localCopyOfQ.GetNext( position ))
	{
		DcsMessageListener* pListener = localCopyOfQ.GetAt( position );
		BOOL result = pListener->ConsumeDcsMessage( pMsg );

		if (result) return TRUE;
	}

	//OK, reach here, no one want to deal with this event
	return FALSE;
}

