#ifndef __XOS_DCS_MESSAGE_MANAGER_H__
#define __XOS_DCS_MESSAGE_MANAGER_H__

#include "PointerList.h"
#include "xos.h"

class DcsMessage;
class DcsOperationMsg;

//this class is responsible for Dhs Message pool managment.  This is a singlton class
class DcsMessageManager
{
public:
	//constants:
	enum {
		MIN_TEXT_BUFFER_SIZE = 1024,
		MIN_BINARY_BUFFER_SIZE = 1024,
		INIT_POOLSIZE = 10,
		MAX_POOLSIZE = 100,
	};

	DcsMessageManager( );
	~DcsMessageManager( );

	static DcsMessageManager& GetObject( );

	//new DcsMessage
	DcsMessage* NewDcsMessage(
		unsigned int text_buffer_size,
		unsigned int binary_buffer_size
		);

	void DeleteDcsMessage( DcsMessage* pMsg );

	//convenient methods to create new DcsMessage
	DcsMessage* NewOperationCompletedMessage( const DcsMessage* pSource, const char status[] );
	DcsMessage* NewOperationUpdateMessage( const DcsMessage* pSource, const char status[] );
    DcsMessage* NewStringCompletedMessage( const char name[], const char status[], const char contents[] );
    DcsMessage* NewAskConfigMessage( const char name[] );
	DcsMessage* NewClone( const DcsMessage* pSource );
	DcsMessage* NewLog( const char type[], const char sender[], const char contents[] );

	//statistics
	size_t GetMaxTextSize( ) const { return m_MaxTextBufferSize; }
	size_t GetMaxBinarySize( ) const { return m_MaxBinaryBufferSize; }
	size_t GetMaxPoolSize( ) const { return m_AllMessageList.GetLength( ); }
	size_t GetNewCount( ) const { return m_NewCount; }
	size_t GetDeleteCount( ) const { return m_DeleteCount; }
private:

	//help method
	char* AllocateBuffer( unsigned int size, unsigned int minSize, unsigned int& realSize );
	bool SetMessageBuffers( DcsMessage& msg, unsigned int textSize, unsigned int binarySize );
	bool AddNewMessageToPool( );

	DcsMessage* NewOperationReplyMessage( const char tag[], const DcsMessage* pSource, const char status[] );

	//===================member=======================
private:
	//sync lock
	xos_mutex_t m_Lock;


	CPPNativeList<DcsMessage*> m_AllMessageList;
	CPPNativeList<DcsMessage*> m_FreeMessageList;

	//history data for statistics
	volatile size_t m_MaxTextBufferSize;
	volatile size_t m_MaxBinaryBufferSize;

	volatile size_t m_NewCount;
	volatile size_t m_DeleteCount;


	//=============== static area ====================
	static DcsMessageManager* stat_pTheSingleObject;

};

#endif //#ifndef __XOS_DCS_MESSAGE_MANAGER_H__
