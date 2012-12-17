#ifndef __XOS_ACTIVE_OBJECT_H__
#define __XOS_ACTIVE_OBJECT_H__

#include "xos.h"
#include "PointerList.h"

//this is interface class for some common feature of active class
//which has its own thread. (by interface, here means no memeber variables)

//after constructor, the thread should be in suspended state.

class activeObject;
class Observer
{
public:
    Observer( ) { }
    virtual ~Observer( ) { }

    //interface
    virtual void ChangeNotification( activeObject* pSubject ) { }
};

class activeObject
{
public:
	enum Status
	{
		STOPPED,
		STARTTING,
		READY,
		STOPPING,
	};
	activeObject( );
	virtual ~activeObject( );

	//status
	virtual Status GetStatus( ) const { return m_Status; }
    virtual BOOL Attach( Observer* pObserver );
    virtual BOOL Detach( Observer* pObserver );

    //command
	virtual void start( ) = 0;
	virtual void reset( ) = 0;
	virtual void stop( ) = 0;
	virtual void emergencyStop( )
	{
		m_FlagEmergency = TRUE;
		stop( );
	}

protected:
    void SetStatus( Status newStatus );

    ///////////////////////////////DATA///////////////////////
    //status
	volatile Status m_Status;
    //event list to signal when status is changed.
	CPPNativeList<Observer*>    m_ObserverList;
    xos_mutex_t                 m_ObserverQLock;

	//command
	volatile BOOL	m_CmdStop;
	volatile BOOL	m_CmdReset;
	volatile BOOL	m_FlagEmergency;
};

#endif // #ifndef __XOS_ACTIVE_OBJECT_H__
