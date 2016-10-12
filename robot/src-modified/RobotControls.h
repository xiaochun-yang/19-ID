#ifndef __ROBOT_CONTROLS_H__
#define __ROBOT_CONTROLS_H__


#include "robot.h"

class RobotControls :
	public Robot
{
public:
	RobotControls(void);
	~RobotControls(void);

	virtual BOOL Initialize( );
	virtual void Cleanup( ) {}

	virtual RobotStatus GetStatus( ) const;
	virtual BOOL MountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] );
	virtual void ClearMountedState(){m_CrystalMounted=0;};
/*
	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] );


	virtual BOOL PrepareSortCrystal( const char argument[], char status_buffer[] );
	virtual BOOL SortCrystal( const char argument[], char status_buffer[] );


	virtual BOOL Config( const char argument[],  char status_buffer[] );

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] );
*/	
	// console dhs operations
	virtual BOOL ClearMountedState(const char argument[], char status_buffer[] );
	virtual int ConnectRobotServer();
	virtual int disConnectRobotServer();
        virtual BOOL StartMonitorCounts(const char argument[], char status_buffer[] );
        virtual BOOL StopMonitorCounts(const char argument[], char status_buffer[] );
	virtual BOOL CenterGrabber(const char argument[], char status_buffer[] );
	virtual BOOL DryGrabber(const char argument[], char status_buffer[] );
	virtual BOOL MoveToNewEnergy(const char argument[], char status_buffer[] );	
	virtual BOOL GetCurrentEnergy(const char argument[], char status_buffer[] );
        virtual BOOL GetRobotState(const char argument[], char status_buffer[] );
        virtual BOOL CoolGrabber(const char argument[], char status_buffer[] );
        virtual BOOL MonoStatus(const char argument[], char status_buffer[] );
	virtual void SetSleepEvent( xos_event_t* pEvent ) { m_pSleepEvent = pEvent; }
	virtual BOOL RegisterEventListener( RobotEventListener& lisener );
	virtual void UnregisterEventListener( RobotEventListener& lisener );
        
	//BOOL ConnectRobotServer(const char argument[], char status_buffer[] );
	BOOL ReadRobotStatus(int , char *);
        int  readRobotState(int);
	BOOL CheckConnection();
	BOOL serverStillConnected();
	BOOL CommandParse( const char *, char * );
	double m_CurrentWavelength;

private:
	xos_event_t* m_pSleepEvent;
	BOOL m_CrystalMounted;
	//for event listener Q: we only support 1 listener now
    	RobotEventListener* volatile m_pEventListener;
};

#endif //#ifndef __ROBOT_SIMULATOR_H__
