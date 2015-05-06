#ifndef __ROBOT_H__
#define __ROBOT_H__
#include "xos.h"

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
        virtual BOOL ReadOrtecCounters( const char argument[],  char status_buffer[] ) = 0;
        virtual BOOL CoolGrabber( const char argument[],  char status_buffer[] ) = 0;
	virtual BOOL MoveToNewEnergy(const char argument[], char status_buffer[] ) = 0;
        virtual BOOL GetCurrentEnergy(const char argument[], char status_buffer[] ) = 0;
        virtual BOOL MonoStatus(const char argument[], char status_buffer[] ) = 0;

    //if you want to sleep in your function, use this semaphore to wait.
    //Stop will wake you up
    virtual void SetSleepSemaphore( xos_semaphore_t* pSem ) { }
};

#endif //   #ifndef __ROBOT_H__
