#include "activeObject.h"
#include "XOSSingleLock.h"

activeObject::activeObject( ):
		m_Status(STOPPED),
        m_ObserverList( 10 ),
        m_CmdStop(FALSE),
        m_CmdReset(FALSE),
		m_FlagEmergency(FALSE)
{
    xos_mutex_create( &m_ObserverQLock );
}
activeObject::~activeObject( )
{
    xos_mutex_close( &m_ObserverQLock );
}

BOOL activeObject::Attach( Observer* pObserver )
{
    if (pObserver == NULL) return FALSE;

    XOSSingleLock holdLock( &m_ObserverQLock );

    return m_ObserverList.AddHead( pObserver );
}
BOOL activeObject::Detach( Observer* pObserver )
{
    if (pObserver == NULL) return TRUE;

    XOSSingleLock holdLock( &m_ObserverQLock );

    return m_ObserverList.RemoveElement( pObserver );
}

//help function for derived class
void activeObject::SetStatus( Status newStatus )
{
    //check to see if any change
    if (newStatus == m_Status) return;

    //set new status
    m_Status = newStatus;

    //broad cast to interested threads to wake up
    XOSSingleLock holdLock( &m_ObserverQLock );
    for (int pos = m_ObserverList.GetFirst( ); pos != LIST_ELEMENT_NOT_FOUND; pos = m_ObserverList.GetNext( pos ))
    {
        Observer* pObserver = m_ObserverList.GetAt( pos );

        if (pObserver)
        {
            pObserver->ChangeNotification( this );
        }
    }
}
