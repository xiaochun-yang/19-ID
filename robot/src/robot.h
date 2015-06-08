#ifndef __ROBOT_H__
#define __ROBOT_H__
#include "xos.h"

typedef const char * LPCTSTR;

//base class for console
enum RobotStatusFlag
{
	FLAG_RESERVED = 1,
	FLAG_ESTOP = 2,
	FLAG_ABORT = 4,
	FLAG_SAFEGUARD = 8,
	FLAG_CALIBRATION = 16,
	FLAG_DCSS_OFFLINE = 32,
	FLAG_DHS_OFFLINE = 64,
	FLAG_INRESET = 128,
	FLAG_INCASSCAL = 256
};

typedef unsigned long RobotStatus;

////////////////////////////ATTENTION////////////////////////////////////
// Any bit change, Blu-Ice interface AND SPEL scrips needs updated     //
/////////////////////////////////////////////////////////////////////////

/*
#define FLAG_ALL                    0xffffffff

//macros for RobotStatus
#define FLAG_NEED_ALL               0x0000007f
#define FLAG_NEED_CAL_ALL           0x0000003C
#define FLAG_NEED_CLEAR             0x00000001
#define FLAG_NEED_RESET             0x00000002
#define FLAG_NEED_CAL_MAGNET        0x00000004
#define FLAG_NEED_CAL_CASSETTE      0x00000008
#define FLAG_NEED_CAL_GONIO         0x00000010
#define FLAG_NEED_CAL_BASIC         0x00000020
#define FLAG_NEED_USER_ACTION       0x00000040

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
*/


#define FLAG_ERROR_NO_GONIO_INFO      0x01
#define FALG_ERROR_DETECTOR_EXTENDED  0x02
#define FALG_ERROR_CRYO_NOT_RETRACTED 0x04
#define FALG_ERROR_NO_SAMPLE	      0x08
#define FLAG_ERROR_GRABBER_STUCK      0x10
#define FLAG_ERROR_GRABBER_STICKY     0x20
#define FLAG_ERROR_SPINDLE_OCCUPIED   0x40
#define FLAG_ERROR_DRY_TIMEOUT	      0x80	

//#define BOOL bool

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
	Robot( ) { }
	virtual ~Robot( ) {}

	//this must be multithread safe and normally called by other thread.
	//should not be time consumming
	virtual RobotStatus GetStatus( ) const = 0;

	//return false if failed: it will be called at the beginning of console thread
	virtual BOOL Initialize( ) = 0;

	virtual void Cleanup( ) = 0;

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

/*
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] ) = 0;
*/
	// Robot operation
	virtual BOOL ClearMountedState( const char argument[],  char status_buffer[] ) = 0;
	virtual BOOL ConnectRobotServer() = 0;
	virtual void ClearMountedState() = 0;
        virtual BOOL MountCrystal( const char argument[],  char status_buffer[] ) = 0;
        virtual BOOL DismountCrystal( const char argument[],  char status_buffer[] ) = 0;
	virtual BOOL CenterGrabber( const char argument[],  char status_buffer[] ) = 0;
	virtual BOOL DryGrabber( const char argument[],  char status_buffer[] ) = 0;
        virtual BOOL GetRobotState( const char argument[],  char status_buffer[] ) = 0;
        virtual BOOL CoolGrabber( const char argument[],  char status_buffer[] ) = 0;
	virtual BOOL MoveToNewEnergy(const char argument[], char status_buffer[] ) = 0;
        virtual BOOL GetCurrentEnergy(const char argument[], char status_buffer[] ) = 0;
        virtual BOOL MonoStatus(const char argument[], char status_buffer[] ) = 0;

    //if you want to sleep in your function, use this semaphore to wait.
    //Stop will wake you up
    virtual void SetSleepSemaphore( xos_semaphore_t* pSem ) { }

    //if you want to sleep in your function, use this event to wait.
    //Stop or SetAbortFlag will wake you up
    virtual void SetSleepEvent( xos_event_t* pEvent ) { }

    //for update messages, you can use above function to poll or you can register a call back to do it
    virtual BOOL RegisterEventListener( RobotEventListener& lisener ) { return true; }
    virtual void UnregisterEventListener( RobotEventListener& lisener ) { }

};

#endif //   #ifndef __ROBOT_H__
