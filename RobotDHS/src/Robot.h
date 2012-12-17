#pragma once

#include "xos.h"

//base class for robot

typedef DWORD RobotStatus;

////////////////////////////ATTENTION////////////////////////////////////
// Any bit change, Blu-Ice interface AND SPEL scrips needs updated     //
/////////////////////////////////////////////////////////////////////////


#define FLAG_ALL                    0xffffffff

//macros for RobotStatus
#define FLAG_NEED_ALL               0x0000007f
#define FLAG_NEED_CAL_ALL           0x0000003C
#define FLAG_NEED_CLEAR             0x00000001
#define FLAG_NEED_RESET             0x00000002
#define FLAG_NEED_CAL_MAGNET	    0x00000004
#define FLAG_NEED_CAL_CASSETTE	    0x00000008
#define FLAG_NEED_CAL_GONIO		    0x00000010
#define FLAG_NEED_CAL_BASIC		    0x00000020
#define FLAG_NEED_USER_ACTION		0x00000040

//reasons
#define FLAG_REASON_ALL             0x0fffff80
#define FLAG_REASON_PORT_JAM        0x00000080
#define FLAG_REASON_ESTOP           0x00000100
#define FLAG_REASON_SAFEGUARD       0x00000200
#define FLAG_REASON_NOT_HOME        0x00000400
#define FLAG_REASON_CMD_ERROR       0x00000800
#define FLAG_REASON_LID_JAM         0x00001000
#define FLAG_REASON_GRIPPER_JAM     0x00002000
#define FLAG_REASON_LOST_MAGNET     0x00004000
#define FLAG_REASON_COLLISION       0x00008000
#define FLAG_REASON_INIT            0x00010000
#define FLAG_REASON_TOLERANCE       0x00020000
#define FLAG_REASON_LN2LEVEL        0x00040000
#define FLAG_REASON_HEATER_FAIL     0x00080000
#define FLAG_REASON_CASSETTE        0x00100000
#define FLAG_REASON_PIN_LOST        0x00200000
#define FLAG_REASON_WRONG_STATE     0x00400000
#define FLAG_REASON_BAD_ARG         0x00800000
#define FLAG_REASON_SAMPLE_IN_PORT  0x01000000
#define FLAG_REASON_ABORT           0x02000000
#define FLAG_REASON_UNREACHABLE     0x04000000
#define FLAG_REASON_EXTERNAL        0x08000000


//in
#define FLAG_IN_ALL                 0xf0000000
#define FLAG_IN_RESET               0x10000000
#define FLAG_IN_CALIBRATION         0x20000000
#define FLAG_IN_TOOL                0x40000000
#define FLAG_IN_MANUAL              0x80000000

class RobotEventListener
{
public:
    enum EVT_NUM
    {
		//system
        EVTNUM_USER_PRINT = 6,

		//user define
		EVTNUM_USER_DEFINE = 2000,
		EVTNUM_LID_OPEN = 2002,
		EVTNUM_UPDATE = 2003,
		EVTNUM_INPUT = 2004,
		EVTNUM_OUTPUT = 2005,
        EVTNUM_CAL_STEP = 2101,
        EVTNUM_CAL_MSG = 2102,
        EVTNUM_MOUNTED = 2103,
        EVTNUM_PINLOST = 2104,
        EVTNUM_WARNING = 2105,
        EVTNUM_PINMOUNTED = 2106,
        EVTNUM_STATE = 2107,
        EVTNUM_CASSETTE = 2108,
        EVTNUM_SAMPLE = 2109,
		EVTNUM_LOG_NOTE = 2110,
		EVTNUM_LOG_WARNING = 2111,
		EVTNUM_LOG_ERROR = 2112,
		EVTNUM_LOG_SEVERE = 2113,
		EVTNUM_HARDWARE_LOG_WARNING = 2114,
		EVTNUM_HARDWARE_LOG_ERROR = 2115,
		EVTNUM_HARDWARE_LOG_SEVERE = 2116,
		//once we have this once, we should phace out INPUT OUTPUT STATE CASSETTE
		EVTNUM_STRING_UPDATE = 2117,
    };

    RobotEventListener( ) { }
    virtual ~RobotEventListener( ) { }

    virtual bool OnRobotEvent( long EventNumber, LPCTSTR EventMessage ) = 0;
    virtual void OnRobotStatus( RobotStatus currentStatus ) = 0;
};

class Robot
{
public:
	enum AttributeIndex
	{
		ATTRIB_DETAILED_MESSAGE = 0,
		ATTRIB_PROBE_CASSETTE,
		ATTRIB_PROBE_PORT,
		ATTRIB_PIN_LOST_THRESHOLD,
		ATTRIB_CHECK_MAGNET,
		ATTRIB_CHECK_POST,
		ATTRIB_COLLECT_FORCE,
		ATTRIB_REHEAT_TONG,
		ATTRIB_DEVELOP_MODE,
		ATTRIB_STRICT_DISMOUNT,
		ATTRIB_DELAY_CAL,
		ATTRIB_PIN_STRIP_THRESHOLD,
		ATTRIB_WASH_BEFORE_MOUNT,
		ATTRIB_CHECK_PICKER,
		NUM_ATTRIBUTE_FIELD,	//must be last one
	};
	Robot( ) { }
	virtual ~Robot( ) {}

	//this must be multithread safe and normally called by other thread.
	//should not be time consumming
	virtual RobotStatus GetStatus( ) const = 0;
    //if you want to get notified when status changes, using event listener interface

	//this must be multithread safe and normally called by other thread.
	//should not be time consumming
    virtual void SetAttribute( const char attributes[] ) { }
    virtual const char* GetAttribute( ) const { return NULL; }
	virtual const char* GetAttributeField( AttributeIndex index ) const { return NULL; }

	//return false if failed: it will be called at the beginning of robot thread
	virtual BOOL Initialize( ) = 0;

	//called at the end of robot thread
	virtual void Cleanup( ) = 0;

	//it will be called in idle state
	virtual void Poll( ) { }

	//all following methods:
	//it will be called in a loop until return TRUE.
	//it will have chance to send update message
	//it maybe abandonded before return TRUE.  It happens if command STOP or RESET received.
	//if you do not want to be interrupted, finish it in one function call.
	//
	//if you plan to return before finish, better save internal state.
	//max length of status_buffer is 
	enum {
		MAX_LENGTH_STATUS_BUFFER = 127
	};

    //to reset any internal state.  All operations will be called in a loop until
    //they return TRUE, so it is safer to let the robot know that this is a new
    //operation call, not a continuous one.
    virtual void StartNewOperation( ) { }

    //The "prepare" is for cooling the tong and and allow the DCSS
    //can move motors around in the same time
	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] ) =  0;
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] ) = 0;
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] ) = 0;
	virtual BOOL PrepareMoveCrystal( const char argument[], char status_buffer[] ) = 0;
	virtual BOOL PrepareWashCrystal( const char argument[], char status_buffer[] ) = 0;

	virtual BOOL MountCrystal( const char position[],  char status_buffer[] ) =  0;
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] ) = 0;
	virtual BOOL MountNextCrystal( const char position[],  char status_buffer[] ) = 0;
	virtual BOOL MoveCrystal( const char argument[], char status_buffer[] ) = 0;
	virtual BOOL WashCrystal( const char argument[], char status_buffer[] ) = 0;

    //this is opposite of prepare
    virtual BOOL Standby( const char argument[], char status_buffer[] ) = 0;

	virtual BOOL Config( const char argument[],  char status_buffer[] ) = 0;

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] ) = 0;

    virtual void SetAbortFlag( ) { }

    //for update messages, you can use above function to poll or you can register a call back to do it
    virtual BOOL RegisterEventListener( RobotEventListener& lisener ) { return true; }
    virtual void UnregisterEventListener( RobotEventListener& lisener ) { }

    //if you want to sleep in your function, use this event to wait.
    //Stop or SetAbortFlag will wake you up
    virtual void SetSleepEvent( xos_event_t* pEvent ) { }

    //convenient function
    static const char* GetStatusString( RobotStatus status );
};
