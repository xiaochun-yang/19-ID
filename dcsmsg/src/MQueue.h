#ifndef __XOS_MQUEUE_H__
#define __XOS_MQUEUE_H__

#include "PointerList.h"
#include "xos.h"
#include "DcsMessage.h"

//the object of this queue is DcsMessage*, but it will destroy any DcsMessages
//that pointed by these pointers in its destructor 

class DcsMessageManager;

class MQueue : public CPPNativeList<DcsMessage*> {

//data
private:

	//This is mutex for accessing the queue
	mutable  xos_mutex_t syncMtx;

    mutable xos_event_t m_evtWaitEnqueue;

    //
    static DcsMessageManager* m_pDcsMsgManager;

//methods
    void _clear( );
public:

	MQueue ( int max_length );

	~MQueue ( ); 

	BOOL Enqueue ( DcsMessage* ); //synchronized appending 
    BOOL WaitEnqueue( DcsMessage*, unsigned long timeout ); //milliseconds

	void Clear ( );	//reset, Clear
    void ClearAndEnqueue( DcsMessage* );

	DcsMessage* Dequeue ( void ); //synchronized retrieval

	int GetCount( ) const;
};

#endif //#ifndef __XOS_MQUEUE_H__
