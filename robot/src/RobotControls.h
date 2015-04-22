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
	
/*
	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL MountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL PrepareSortCrystal( const char argument[], char status_buffer[] );
	virtual BOOL SortCrystal( const char argument[], char status_buffer[] );


	virtual BOOL Config( const char argument[],  char status_buffer[] );

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] );
*/	
	// console dhs operations
	virtual BOOL Init8bmCons(const char argument[], char status_buffer[] );
	virtual BOOL ConnectRobotServer();
        virtual BOOL StartMonitorCounts(const char argument[], char status_buffer[] );
        virtual BOOL StopMonitorCounts(const char argument[], char status_buffer[] );
	virtual BOOL ReadMonitorCounts(const char argument[], char status_buffer[] );
	virtual BOOL ReadAnalog(const char argument[], char status_buffer[] );
	virtual BOOL MoveToNewEnergy(const char argument[], char status_buffer[] );	
	virtual BOOL GetCurrentEnergy(const char argument[], char status_buffer[] );
        virtual BOOL ReadOrtecCounters(const char argument[], char status_buffer[] );
        virtual BOOL readOrtecCounters(const char argument[], char status_buffer[] );
        virtual BOOL MonoStatus(const char argument[], char status_buffer[] );

        //BOOL ConnectRobotServer(const char argument[], char status_buffer[] );
//	BOOL ConnectRobotServer();
	double m_CurrentWavelength;

private:
	BOOL m_CrystalMounted;
};

#endif //#ifndef __ROBOT_SIMULATOR_H__
