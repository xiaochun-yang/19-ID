
#include "log_quick.h"
#include "DcsMessageManager.h"
#include "RobotService.h"
#include "Robot.h"
#include "RobotSim.h"
RobotService::standardFunction RobotService::s_myFunctionTable[] =
{
    &RobotService::GetRobotState,
    &RobotService::PrepareMountCrystal,
    &RobotService::MountCrystal,
    &RobotService::PrepareDismountCrystal,
    &RobotService::DismountCrystal,
    &RobotService::PrepareMountNextCrystal,
    &RobotService::MountNextCrystal,
    &RobotService::RobotConfig,
    &RobotService::RobotCalibrate,
};

RobotService::DeviceMap RobotService::s_myOperationMap[] =
{//  name,						 ask_config, init_fun, immed
	{"get_robotstate",					FALSE, -1, TRUE,  0, -1},

	{"mount_crystal",                   FALSE, -1, FALSE, 2, -1},
	{"prepare_mount_crystal",           FALSE, -1, FALSE, 1, -1},

	{"prepare_dismount_crystal",		FALSE, -1, FALSE, 4, -1},
	{"dismount_crystal",				FALSE, -1, FALSE, 3, -1},

	{"prepare_mount_next_crystal",		FALSE, -1, FALSE, 6, -1},
	{"mount_next_crystal",				FALSE, -1, FALSE, 5, -1},

	{"robot_config",					FALSE, -1, FALSE, 7, -1},
	
	{"robot_calibrate",					FALSE, -1, FALSE, 8, -1}
};


RobotService::RobotService( ):
	m_pRobot(NULL)
{
    m_pRobot = new RobotSim;
    setupMapOperation( s_myOperationMap, sizeof(s_myOperationMap) / sizeof(s_myOperationMap[0] ) );
}

RobotService::~RobotService( )
{
	stop( );
	delete m_pRobot;

}
void RobotService::callFunction( int funcIndex, int objIndex )
{
    static int numFunction = sizeof(s_myFunctionTable) / 
    sizeof(s_myFunctionTable[0]);

    if (funcIndex >= 0 && funcIndex < numFunction) {
        (this->*s_myFunctionTable[funcIndex])();
    }
}

//no hardware access, pure software.
void RobotService::GetRobotState( )
{
	//get status from the robot
	RobotStatus status = m_pRobot->GetStatus( );

	//create string from it: current max info is 121 from following 
	char status_buffer[128] = {0};
	sprintf( status_buffer, "normal %lu", status ); //about 20 bytes

	//give more human readable message after machine readable value
	if (status & FLAG_ESTOP)
	{
		strcat( status_buffer, " EMERGENCY_STOP" );		//15 chars
	}
	if (status & FLAG_ABORT)
	{
		strcat( status_buffer, " ABORT" );				//6
	}
	if (status & FLAG_SAFEGUARD)
	{
		strcat( status_buffer, " SAFEGUARD" );			//10
	}
	if (status & FLAG_CALIBRATION)
	{
		strcat( status_buffer, " CALIBRATION" );		//12
	}
	if (status & FLAG_DCSS_OFFLINE)
	{
		strcat( status_buffer, " DCSS_OFFLINE" );		//13
	}
	if (status & FLAG_DHS_OFFLINE)
	{
		strcat( status_buffer, " DHS_OFFLINE" );		//12
	}
	if (status & FLAG_INRESET)
	{
		strcat( status_buffer, " IN_RESET" );			//9
	}
	if (status & FLAG_INCASSCAL)
	{
		strcat( status_buffer, " IN_CASSETTE_CALIBRATION" );	//24
	}

	//make a DcsMessage for it and send out
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage, status_buffer );
	sendoutDcsMessage( pReply );
}

void RobotService::WrapRobotMethod( PTR_ROBOT_FUNC pMethod )
{
	char status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER + 1] = {0};

	//run the function and get result
	while (!(m_pRobot->*pMethod)( m_pCurrentMessage->GetOperationArgument( ), status_buffer ))
	{
        status_buffer[Robot::MAX_LENGTH_STATUS_BUFFER] = '\0';
		//update
		DcsMessage* pReply = m_MsgManager.NewOperationUpdateMessage( m_pCurrentMessage, status_buffer );
		sendoutDcsMessage( pReply );

		//check if stop command in effect
		if (m_CmdStop)
		{
			LOG_INFO( "RobotService::WrapRobotMethod: got stop during looping" );
			m_pCurrentMessage = NULL;
			m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );
			return;
		}
	}

	//The order is important here: the creation of reply message needs current operation message,
	//you cannot delete it yet.
	//You must set the current operation to NULL and remove it from Queue before you send out reply

	//final reply
	DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, status_buffer );

	//before sending out, do clear first to prepare for next message
	//remove this message from the queue and delete it
	m_pCurrentMessage = NULL;
	m_MsgManager.DeleteDcsMessage( m_MsgQueue.Dequeue( ) );

	//send the reply out at the last step
	sendoutDcsMessage( pReply );

}

void RobotService::PrepareMountCrystal( )
{
	WrapRobotMethod( &Robot::PrepareMountCrystal );
}

void RobotService::MountCrystal( )
{
	WrapRobotMethod( &Robot::MountCrystal );
}

void RobotService::PrepareDismountCrystal( )
{
	WrapRobotMethod( &Robot::PrepareDismountCrystal );
}

void RobotService::DismountCrystal( )
{
	WrapRobotMethod( &Robot::DismountCrystal );
}

void RobotService::PrepareMountNextCrystal( )
{
	WrapRobotMethod( &Robot::PrepareMountNextCrystal );
}

void RobotService::MountNextCrystal( )
{
	WrapRobotMethod( &Robot::MountNextCrystal );
}

void RobotService::PrepareSortCrystal( )
{
	WrapRobotMethod( &Robot::PrepareSortCrystal );
}

void RobotService::SortCrystal( )
{
	WrapRobotMethod( &Robot::SortCrystal );
}


void RobotService::RobotConfig( )
{
	WrapRobotMethod( &Robot::Config );
}

void RobotService::RobotCalibrate( )
{
	WrapRobotMethod( &Robot::Calibrate );
}
