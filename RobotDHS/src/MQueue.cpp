#include "MQueue.h"
#include "XOSSingleLock.h"

MQueue::MQueue( int max_length ):
	CPPNativeList<DcsMessage*>( max_length )
{
    xos_mutex_create( &syncMtx );
}

MQueue::~MQueue ( void )
{ 
	Clear ( );
    xos_mutex_close( &syncMtx );
}

BOOL MQueue::Enqueue ( DcsMessage* p_DcsM ) 
{
	//lock the mutex before any change
	XOSSingleLock singleLock( &syncMtx );

	BOOL result = AddTail ( p_DcsM );	//super class call

	//signal the waiting event
	if (result)
	{
		return TRUE;
	}
	else
	{
		return FALSE;
	}
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

	//check to see if need to reset waiting event
	return pResult;
}

void MQueue::Clear ( )
{
	XOSSingleLock singleLock ( &syncMtx );
	Clean( );
}

int MQueue::GetCount( ) const
{
	XOSSingleLock singleLock ( &syncMtx );
	return GetLength( );

}