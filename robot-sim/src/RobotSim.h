#ifndef __ROBOT_SIMULATOR_H__
#define __ROBOT_SIMULATOR_H__


#include "Robot.h"

class RobotSim :
	public Robot
{
public:
	RobotSim(void);
	~RobotSim(void);

	virtual BOOL Initialize( );
	virtual void Cleanup( ) {}

	virtual RobotStatus GetStatus( ) const;

	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL MountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL MountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL PrepareSortCrystal( const char argument[], char status_buffer[] );
	virtual BOOL SortCrystal( const char argument[], char status_buffer[] );


	virtual BOOL Config( const char argument[],  char status_buffer[] );

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] );

private:
	BOOL m_CrystalMounted;
};

#endif //#ifndef __ROBOT_SIMULATOR_H__
