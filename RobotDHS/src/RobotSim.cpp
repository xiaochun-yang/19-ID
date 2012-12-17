#include "robotsim.h"
#include "log_quick.h"

#define SLEEP_TIME 100

RobotSim::RobotSim(void):
m_CrystalMounted(FALSE)
{
}

RobotSim::~RobotSim(void)
{
}

BOOL RobotSim::Initialize( )
{
	LOG_FINEST( "RobotSim::Initialize called" );

	//testing waiting robot to initialize.
	Sleep( 10000 );

	return TRUE;
}



RobotStatus RobotSim::GetStatus( ) const
{
	LOG_FINEST( "RobotSim::GetStatus called" );

	RobotStatus result;
	result = 0;

	return result;
}


BOOL RobotSim::PrepareMountCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::PrepareMountCrystal called( %s)", argument );

	Sleep( SLEEP_TIME );
	if (m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::PrepareMountCrystal: BAD, crystal already mounted" );
		strcpy( status_buffer, "BAD one crystal already mounted" );
	}
	else
	{
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}


BOOL RobotSim::MountCrystal( const char argument[], char status_buffer[] )
{
	static int state_counter = 0;

	LOG_FINEST1( "RobotSim::MountCrystal called( %s)", argument );

	Sleep( SLEEP_TIME );
	if (m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::MountCrystal: BAD, crystal already mounted" );
		strcpy( status_buffer, "BAD one crystal already mounted" );
		return TRUE;
	}
	else
	{
		if (state_counter < 5 )
		{
			++state_counter;
			sprintf( status_buffer, "doing the job %d", state_counter );
			return false;
		}
		else
		{
			state_counter = 0;
			m_CrystalMounted = TRUE;
			strcpy( status_buffer, "normal" );
			return TRUE;
		}
	}
}


BOOL RobotSim::PrepareDismountCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::PrepareDismountCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::PrepareDismountCrystal:BAD, crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}

BOOL RobotSim::DismountCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::DismountCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::DismountCrystal:BAD crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		m_CrystalMounted = FALSE;
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}

BOOL RobotSim::PrepareMountNextCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::PrepareMountNextCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::PrepareMountNextCrystal: BAD, crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}


BOOL RobotSim::MountNextCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::MountNextCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	if (!m_CrystalMounted)
	{
		LOG_WARNING( "RobotSim::MountNextCrystal:BAD, crystal not mounted yet" );
		strcpy( status_buffer, "BAD crystal not mounted yet" );
	}
	else
	{
		strcpy( status_buffer, "normal" );
	}
	return TRUE;
}

BOOL RobotSim::PrepareMoveCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::PrepareMoveCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}

BOOL RobotSim::MoveCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::MoveCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}

BOOL RobotSim::PrepareWashCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::PrepareWashCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}

BOOL RobotSim::WashCrystal( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::WashCrystal called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}


BOOL RobotSim::Standby( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::Standby called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}



BOOL RobotSim::Config( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::Config called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal 1" );
	return TRUE;
}

BOOL RobotSim::Calibrate( const char argument[], char status_buffer[] )
{
	LOG_FINEST1( "RobotSim::Calibrate called( %s)", argument );
	Sleep( SLEEP_TIME );
	strcpy( status_buffer, "normal" );
	return TRUE;
}
