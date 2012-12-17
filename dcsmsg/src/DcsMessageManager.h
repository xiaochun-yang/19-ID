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
	DcsMessageManager( );
	~DcsMessageManager( );

	static DcsMessageManager& GetObject( );

	//new DcsMessage
	DcsMessage* NewDcsMessage(
		size_t text_buffer_size,
		size_t binary_buffer_size
		);

	void DeleteDcsMessage( DcsMessage* pMsg );

	//convenient methods
	DcsMessage* NewCloneMessage( const DcsMessage* pSource );

	DcsMessage* NewOperationCompletedMessage( const DcsMessage* pSource, const char status[], const void *pBinary = NULL, size_t lBinary = 0 );
	DcsMessage* NewOperationUpdateMessage( const DcsMessage* pSource, const char status[], const void *pBinary = NULL, size_t lBinary = 0 );
    
	DcsMessage* NewDcsTextMessage(const char message[]);
    
    DcsMessage* NewStringCompletedMessage( const char name[], const char status[], const char contents[] );

    DcsMessage* NewLog( const char type[], const char sender[], const char contents[] );

    DcsMessage* NewShutterReportMessage( const char name[], bool closed, const char * status = NULL );

    DcsMessage* NewMotorStartedMessage( const char name[], double position );
    DcsMessage* NewMotorUpdateMessage( const char name[], double position, const char status[] );
    DcsMessage* NewMotorDoneMessage( const char name[], double position, const char status[] );
    DcsMessage* NewPseudoMotorConfigMessage( const char name[], double position, double upperLimit, double lowerLimit, bool upperLimitOn, bool lowerLimitOn, bool motorLocked );
    DcsMessage* NewRealMotorConfigMessage( const char name[], double position, double upperLimit, double lowerLimit, double scaleFactor, int speed, int accel, int backlash, bool upperLimitOn, bool lowerLimitOn, bool motorLocked, bool backlashOn, bool reverseOn );
		 
    DcsMessage* NewAskConfigMessage( const char name[] );
    DcsMessage* NewGetEncoderDoneMessage( const char name[], double position, const char status[] );
    DcsMessage* NewSetEncoderDoneMessage( const char name[], double position, const char status[] );
    DcsMessage* NewReportIonChamberErrorMessage( DcsMessage* pMsg, const char reason[] );

	size_t GetMaxTextSize( ) const { return m_MaxTextBufferSize; }
	size_t GetMaxBinarySize( ) const { return m_MaxBinaryBufferSize; }
	size_t GetMaxPoolSize( ) const { return m_AllMessageList.GetLength( ); }
	size_t GetNewCount( ) const { return m_NewCount; }
	size_t GetDeleteCount( ) const { return m_DeleteCount; }
private:

	//help method
	char* AllocateBuffer( size_t size, size_t minSize, size_t& realSize );
	bool SetMessageBuffers( DcsMessage& msg, size_t textSize, size_t binarySize );
	bool AddNewMessageToPool( );

	DcsMessage* NewOperationReplyMessage( const char tag[], const DcsMessage* pSource, const char status[], const void *pBinary = NULL, size_t lBinary = 0 );
	DcsMessage* NewMotorMoveMessage( const char tag[], const char name[], double position, const char* pStatus );

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

	//constants:
	enum {
		MIN_TEXT_BUFFER_SIZE = 1024,
		MIN_BINARY_BUFFER_SIZE = 1024,
		INIT_POOLSIZE = 10,
		MAX_POOLSIZE = 100,
	};

	//=============== static area ====================
	static DcsMessageManager* stat_pTheSingleObject;

};

#endif //#ifndef __XOS_DCS_MESSAGE_MANAGER_H__
