#ifndef __CONSOLE_SERVICE_H__
#define __CONSOLE_SERVICE_H__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "Console.h"
#include "XosMutex.h"
#include <string>
#include <list>


typedef BOOL (Console::*PTR_CONSOLE_FUNC)( const char argument[], char status_buffer[] );

class DcsMessageManager;
class ConsoleService :
	public DcsMessageTwoWay
{
public:
	ConsoleService(void);
	virtual ~ConsoleService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

private:
	static XOS_THREAD_ROUTINE Run( void* pParam )
	{
		ConsoleService* pObj = (ConsoleService*)pParam;
		pObj->ThreadMethod( );
        XOS_THREAD_ROUTINE_RETURN;
	}

	void ThreadMethod( );

	void SendoutDcsMessage( DcsMessage* pMsg );

	BOOL HandleKnownOperations( DcsMessage* pMsg );
        BOOL HandleKnownMotors(DcsMessage* pMsg);
        BOOL HandleKnownStrings(DcsMessage* pMsg);
        BOOL registerMotor(DcsMessage* pMsg);


	////////////////////////////method for each operation//////////////////////

	void Init8bmCons();
	void StartMonitorCounts();
	void StopMonitorCounts();
	void ReadMonitorCounts();
	void ReadAnalog();
	void MoveToNewEnergy();
	void GetCurrentEnergy();
	void ReadOrtecCounters();
	void readOrtecCounters();
	void MonoStatus( );
	
	void WrapConsoleMethod( PTR_CONSOLE_FUNC pMethod );

	// Functions directly being used in this class 
	BOOL MoveToTargetEnergy(double);
	BOOL MonoStable();
	BOOL DcmOnLine();
	BOOL GetEnergy(double *, double);
public:
	BOOL ConnectX4a();

	//////////////DATA
private:
	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue m_MsgQueue;

	//thread
    xos_thread_t m_Thread;
	xos_semaphore_t m_SemThreadWait;    //this is wait for message and stop
    xos_semaphore_t m_SemStopOnly;      //this is for stop only, used as timer

	//Console
	Console* m_pConsole;

	//special data
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentOperation;

	DcsMessage* volatile 	m_pInstantOperation;
        DcsMessage* volatile    m_pInstantMessage;      //operation that is taking place if it is an immediate operation
        DcsMessage* volatile    m_pCurrentMessage;      //operation that is currently taking place


	static struct OperationToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (ConsoleService::*m_pMethod)();
	} m_OperationMap[];

        enum MotorIndex {
                MOTOR_FIRST,
                NUM_MOTOR,                      //must at end
        };

        struct MotorNameStruct {
                const char*         m_localName;
                MotorIndex              m_index;
        };

        static MotorNameStruct m_MotorMap[];
                                                                                                                     
        char m_motorName[NUM_MOTOR][40];
	double CurrentPosition[NUM_MOTOR];
                                                                                                                     
        //used to clean up all messages in the queue when abort received:
        //This flag will be set when abort message is received.
        //and it will be cleared after all messages in the queue are popped out
        volatile bool m_inAborting;


	bool HandleIonChamberRequest( DcsMessage* pMsg );
                                                                                                                         
/*      bool ParseIonChamberRequest(const char* str,
                        std::string& command,
                        std::string& time_secs,
                        BOOL& is_repeated,
                        BOOL is_channel_wanted[]);
*/
};

#endif //#ifndef __CONSOLE_SERVICE_H__
