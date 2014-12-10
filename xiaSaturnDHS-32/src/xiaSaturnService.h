#ifndef __Include_xiaSaturnService_h__
#define __Include_xiaSaturnService_h__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "XosMutex.h"
#include <string>
#include <list>

class OperationThread;
class DcsMessageManager;

class xiaSaturnService : public DcsMessageTwoWay
{
public:
	xiaSaturnService(void);
	virtual ~xiaSaturnService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

	void SendoutDcsMessage( DcsMessage* pMsg );
	xiaSaturnService  getThis( );

private:

	static XOS_THREAD_ROUTINE dcsMsgThreadRoutine( void* pParam );

	// Thread routine for monitoring operation threads
	// and clean them up the ones that are done.
	static XOS_THREAD_ROUTINE monitorThreadRoutine(void* arg);

	// Called by dcsMsgThreadRoutine
	void processDcsMessages();

	BOOL HandleKnownOperations( DcsMessage* pMsg );

	// Called by monitorThreadRoutine
	void removeCompletedOperations();

	void setOutputRegister();
	void acquireSpectrum();

	// Handle operation abort message
	void abort();

	// Methods for locking/unlocking activeOperations list
	void initLock();
	bool tryLock();
	void lock();
	void unlock();
	void destroyLock();





	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue m_MsgQueue;

	//thread
    xos_thread_t m_Thread;
	xos_semaphore_t m_SemThreadWait;    //this is wait for message and stop

	//special data
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentOperation;

	DcsMessage* volatile m_pInstantOperation;

	// Operations currently running in separate threads
	std::list<OperationThread*> activeOperations;

	/**
	 * @brief Mutex for locking activeOperations
	 *
	 **/
	 XosMutex			m_mutex;

	static struct OperationToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (xiaSaturnService::*m_pMethod)();
	} m_OperationMap[];

	bool HandleIonChamberRequest( DcsMessage* pMsg );

	bool ParseIonChamberRequest(const char* str,
			std::string& command,
			std::string& time_secs,
			BOOL& is_repeated );
};

#endif //#ifndef __Include_xiaSaturnService_h__
