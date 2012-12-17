#ifndef __Include_ImpersonService_h__
#define __Include_ImpersonService_h__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "XosMutex.h"
#include <string>
#include <list>
#include <algorithm>

class SilThread;
class AllSilThread;
class Strategy;
class OperationThread;
class DcsMessageManager;
class Imperson;

class ImpersonService : public DcsMessageTwoWay
{
public:
	ImpersonService(void);
	virtual ~ImpersonService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

	void SendoutDcsMessage( DcsMessage* pMsg );
	
	bool stringRegistered( const char* pStringName ) const;

private:

	static XOS_THREAD_ROUTINE dcsMsgThreadRoutine( void* pParam );

	// Thread routine for monitoring operation threads
	// and clean them up the ones that are done.
	static XOS_THREAD_ROUTINE monitorThreadRoutine(void* arg);

	// Called by dcsMsgThreadRoutine
	void processDcsMessages();
	
	// Called by monitorThreadRoutine
	void removeCompletedOperations();
	
	void doAutochooch();
	void doSnap();
	void doFileAccess();
	void doImageConvert();
	
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
	 
	SilThread*    m_silThread;
	Strategy*     m_strategyThread;
	AllSilThread* m_allSilThread;

    std::list<std::string> m_registeredString;

	static struct OperationToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (ImpersonService::*m_pMethod)();
	} m_OperationMap[];

};

#endif //#ifndef __Include_ImpersonService_h__
