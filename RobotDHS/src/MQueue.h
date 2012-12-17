#ifndef __XOS_MQUEUE_H__
#define __XOS_MQUEUE_H__

#include "DcsMessage.h"
#include "PointerList.h"
#include "xos.h"

//the object of this queue is DcsMessage*, but it will destroy all DcsMessages
//that pointed by these pointers in its destructor 

//This is NOT a thread-safe class.  It only supports one consumer thread.

class MQueue : public CPPNativeList<DcsMessage*> {

//data
private:

	//This is mutex for accessing the queue
	mutable  xos_mutex_t syncMtx;

//methods
public:

	MQueue ( int max_length );

	~MQueue ( ); 

	BOOL Enqueue ( DcsMessage* ); //synchronized appending 

	void Clear ( );	//reset, Clear

	DcsMessage* Dequeue ( void ); //synchronized retrieval

	int GetCount( ) const;
};

#endif //#ifndef __XOS_MQUEUE_H__
