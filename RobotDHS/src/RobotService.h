#ifndef __ROBOT_SERVICE_H__
#define __ROBOT_SERVICE_H__

#include "activeObject.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "Robot.h"
#include "RobotStatusString.h"

typedef BOOL (Robot::*PTR_ROBOT_FUNC)( const char argument[], char status_buffer[] );

class DcsMessageManager;
class RobotService :
	public DcsMessageTwoWay, public RobotEventListener
{
public:
	RobotService(void);
	virtual ~RobotService(void);

	//implement activeObject
	virtual void start( );
	virtual void stop( );
	virtual void reset( );

	//implement interface DcsMessageTwoWay
	virtual BOOL ConsumeDcsMessage( DcsMessage* pMsg );

    //implement RobotEventListener
    virtual bool OnRobotEvent( long EventNumber, LPCTSTR EventMessage );
    virtual void OnRobotStatus( RobotStatus currentStatus );
private:
	static UINT Run ( LPVOID pParam )
	{
		RobotService* pObj = (RobotService*)pParam;
		pObj->ThreadMethod( );
        return 0;
	}

	void ThreadMethod( );

	void SendoutDcsMessage( DcsMessage* pMsg );

    //help function
    void UpdateString( const char name[], const char status[], const char contents[] );
    void UpdateStateString( const char contents[] );

    void ProcessAttributeString( const char contents[] );
	////////////////////////////method for each operation//////////////////////
	void GetRobotState( );

	void PrepareMountCrystal( );
	void MountCrystal( );
	
	void PrepareDismountCrystal( );
	void DismountCrystal( );
	
	void PrepareMountNextCrystal( );
	void MountNextCrystal( );
	
	void PrepareMoveCrystal( );
	void MoveCrystal( );

	void PrepareWashCrystal( );
	void WashCrystal( );

    void Standby( );

	void RobotConfig( );
	
	void RobotCalibrate( );

	void WrapRobotMethod( PTR_ROBOT_FUNC pMethod );

	void SendLogNote( const char* msg );
	void SendLogWarning( const char* msg );
	void SendLogError( const char* msg );
	void SendLogSevere( const char* msg );
	void SendHardwareLogWarning( const char* msg );
	void SendHardwareLogError( const char* msg );
	void SendHardwareLogSevere( const char* msg );
	void SendUpdateString( const char* msg );

private:
	//////////////DATA
	//save reference to manager
	DcsMessageManager& m_MsgManager;
	//message queue: messages waiting to execute: this is time consuming message
	MQueue m_MsgQueue;

	//thread
    CWinThread* m_pThread;
	xos_semaphore_t m_SemThreadWait;    //this is wait for message and stop
    xos_event_t m_EvtStopOnly;      //this is for stop only, used as timer

	//robot
	Robot* m_pRobot;

	//special data
	//This is also used as a flag, to check we are already running an operation
	DcsMessage* volatile m_pCurrentOperation;

	DcsMessage* volatile m_pInstantOperation;

    volatile bool m_SendingDetailedMessage;

	//watch dog
	volatile time_t m_timeStampRobotPolling;

    RobotStatusString m_StatusString;

	static struct OperationToMethod
	{
		const char*          m_OperationName;
		bool	             m_Immediately;
		void (RobotService::*m_pMethod)();
        unsigned int         m_TimeoutForNextOperation; //if not 0, it will go home (standby) if next operation does not
                                                        //arrive within the time span.
	} m_OperationMap[];

    //strnigs owned by robot
    static const char* ms_StringStatus;             //set only by robot, read by all
    static const char* ms_StringState;              //set only by robot, read by all
    static const char* ms_StringCassetteStatus;     //set only by robot, read by all
    static const char* ms_StringSampleStatus;       //set only by robot, read by all
    static const char* ms_StringInputBits;			//set only by robot, read by all
    static const char* ms_StringOutputBits;			//set only by robot, read by all

    static const char* ms_StringAttribute;          //set by blu-ice, read by robot

    //"normal" status for sending set_string_completed
    static const char* ms_Normal;

	//strings in this array will get special treatment to keep DCSS in SYNC with robot.
	//If the m_Write is set:
	//		the latest message will be save in case DCSS is disconnected
	//		and will be sent out when DCSS is reconnected
	//
	//If the m_Read is set:
	//		robot will retrieve the contents from DCSS when it is connected to DCSS

	static struct StringList
	{
		const char*				m_StringName;
		size_t					m_NameLength;
		bool					m_Write;
		bool					m_Read;
		DcsMessage* volatile	m_pMsgLatest;
	} m_StringMap[];
};

#endif //#ifndef __ROBOT_SERVICE_H__
