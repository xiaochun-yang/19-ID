#ifndef __ROBOT_SERVICE_H__
#define __ROBOT_SERVICE_H__

#include "DhsService.h"
#include "Robot.h"

typedef BOOL (Robot::*PTR_ROBOT_FUNC)( const char argument[], char status_buffer[] );

class RobotService :
	public DhsService
{
public:
	RobotService(void);
	virtual ~RobotService(void);

protected:
    // implement DhsService
    virtual void callFunction( int functionIndex, int objectIndex );

private:
	////////////////////////////method for each operation//////////////////////
	void GetRobotState( );

	void PrepareMountCrystal( );
	void MountCrystal( );
	
	void PrepareDismountCrystal( );
	void DismountCrystal( );
	
	void PrepareMountNextCrystal( );
	void MountNextCrystal( );
	
	void PrepareSortCrystal( );
	void SortCrystal( );

	void RobotConfig( );
	
	void RobotCalibrate( );

	void WrapRobotMethod( PTR_ROBOT_FUNC pMethod );

	//////////////DATA
private:
	//robot
	Robot* m_pRobot;

    typedef void (RobotService::*standardFunction)();
	static standardFunction s_myFunctionTable[];

    static DeviceMap s_myOperationMap[];
    static DeviceMap s_myStringMap[];
};

#endif //#ifndef __ROBOT_SERVICE_H__
