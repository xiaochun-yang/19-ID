#ifndef __XOS_DCS_MESSAGE_TWO_WAY_H__
#define __XOS_DCS_MESSAGE_TWO_WAY_H__

#include "activeObject.h"
#include "PointerList.h"
#include "xos.h"

///////////////////////////////////////////////////////////////////////////////
//interface definition, pure abstract class with no memeber variables
//This is push style.
// Currentl, there is no dynamic register/unregister requirement and support,
// by dynamic, we mean in event processing itsefle to register/unregister.
//
//
//
//////////////////////////////////////////////////////////////////////////////
class DcsMessage;

class DcsMessageListener
{
public:
	DcsMessageListener( ) { }
	virtual ~DcsMessageListener( ) { }

	//must not be time consuming,
	//must be thread safe.
	//return TRUE if you eat the message,
	//return FALSE if you want others to deal with it.
	//you also can alter the message before you pass on.
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg ) = 0;
};

class DcsMessageSource
{
public:
	enum constants
	{
		MAX_QUEUE_LENGTH = 10,
	};
	DcsMessageSource( ): m_ListenersQueue( MAX_QUEUE_LENGTH )
    {
        xos_mutex_create( &m_LQLock );
        xos_mutex_create( &m_ProcessLock );
    }

	virtual ~DcsMessageSource( )
    {
        xos_mutex_close( &m_LQLock );
        xos_mutex_close( &m_ProcessLock );
    }

	//must not be time consuming,
	//must be thread safe.
	//It is a stack: the lastest listener process the event first.
	// There should not be a const in the argment 
	virtual BOOL Register( DcsMessageListener& listener ); //will change to throw "too many" in the future
	virtual void Unregister( DcsMessageListener& listener );

protected:
	//help functions
	//It will return TRUE if the message event was eaten and deleted
	//if it return false, no one wants the event, and event has not been deleted yet.
	virtual BOOL ProcessEvent( DcsMessage* pMsg );

private:
	xos_mutex_t m_LQLock;
	xos_mutex_t m_ProcessLock;
	CPPNativeList<DcsMessageListener*> m_ListenersQueue;
};

class DcsMessageTwoWay:
	public activeObject,
	public DcsMessageSource,
	public DcsMessageListener
{
public:
	DcsMessageTwoWay( ) { }
	virtual ~DcsMessageTwoWay( ) { }

	void Connect( DcsMessageTwoWay& partner )
	{
		Register( partner );
		partner.Register( *this );
	}

	void Disconnect( DcsMessageTwoWay& partner )
	{
		Unregister( partner );
		partner.Unregister( *this );
	}
};

#endif //#ifndef __XOS_DCS_MESSAGE_TWO_WAY_H__
