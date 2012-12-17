#include "robotexception.h"
#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "log_quick.h"

#include <math.h>

void robotSystemStop( void );

void RobotEpson::UpdateRobotFlags( RobotStatus status )
{
    //turn on "need" bits according to "reason bit


    if (m_pState->status != status)
    {
        m_pState->status = status;
		FlushViewOfFile( m_pState, 0 );
        //push out the changes
        if (m_pEventListener)
        {
            m_pEventListener->OnRobotStatus( m_pState->status );
        }
    }
}


void RobotEpson::SetRobotFlags( RobotStatus flags )
{
	if (flags & (FLAG_REASON_ESTOP |
		         FLAG_REASON_SAFEGUARD |
				 FLAG_REASON_UNREACHABLE |
		         FLAG_REASON_NOT_HOME |
				 FLAG_REASON_CMD_ERROR |
				 FLAG_REASON_ABORT))
	{
		LOG_FINEST( "set need turn off heater in robot flag" );
		m_NeedTurnOffHeater = true;
	}

    //if cmd error is secondary error caused by others, ignore it
    if (m_pState->status & FLAG_REASON_ALL)
    {
        flags &= ~FLAG_REASON_CMD_ERROR;
    }

    //check "need" bit according to "reason"
    //case 1: definitely need reset:
    if (flags & (
        FLAG_REASON_NOT_HOME |
        FLAG_REASON_CMD_ERROR |
        FLAG_REASON_ABORT))
    {
		if (!(m_pState->status & FLAG_NEED_USER_ACTION))
		{
			flags |= FLAG_NEED_RESET;
		}
    }

    //case 2: need reset or clear
    if (flags & (
		FLAG_REASON_ESTOP |
        FLAG_REASON_SAFEGUARD |
        FLAG_REASON_LID_JAM |
        FLAG_REASON_GRIPPER_JAM |
        FLAG_REASON_LOST_MAGNET |
        FLAG_REASON_HEATER_FAIL |
        FLAG_REASON_WRONG_STATE |
        FLAG_REASON_UNREACHABLE))
    {
        if (OKToClear( ))
        {
            flags |= FLAG_NEED_CLEAR;
        }
        else
        {
            flags |= FLAG_NEED_RESET;
        }
    }

    if ((flags & FLAG_REASON_PORT_JAM) && !(m_pState->status & FLAG_NEED_USER_ACTION))
    {
        if (OKToClear( ))
        {
            flags |= FLAG_NEED_CLEAR;
        }
        else
        {
            flags |= FLAG_NEED_RESET;
        }
    }


    //case 3: only need clear
    if (flags & (
        FLAG_REASON_CASSETTE |
        FLAG_REASON_PIN_LOST |
		FLAG_REASON_SAMPLE_IN_PORT |
        FLAG_REASON_BAD_ARG))
    {
        flags |= FLAG_NEED_CLEAR;
    }

    //case 4: need reset and cal
    if (flags & FLAG_REASON_COLLISION)
    {
        flags |= FLAG_NEED_RESET | FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_GONIO;
    }

    //case 5: need cal
    //if (flags & FLAG_REASON_LN2LEVEL)
    //{
    //    flags |= FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_CASSETTE | FLAG_NEED_CAL_GONIO;
    //}

    //case 6: check need cal
    if (flags & (
        FLAG_REASON_INIT |
        FLAG_REASON_TOLERANCE))
    {
        if (!(flags & FLAG_NEED_CAL_ALL))
        {
            flags |= FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_CASSETTE | FLAG_NEED_CAL_GONIO;
        }
    }

	//send severe log message if reset is flagged
	if (!(m_pState->status & FLAG_NEED_RESET) && (flags & FLAG_NEED_RESET))
	{
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "Robot needs reset" );
		}
	}

    RobotStatus newStatus = m_pState->status | flags;

    if ((newStatus & FLAG_NEED_RESET) && (newStatus & FLAG_NEED_CLEAR))
    {
        newStatus &= ~FLAG_NEED_CLEAR;
    }

    UpdateRobotFlags( newStatus );

}

void RobotEpson::ClearRobotFlags( RobotStatus flags )
{
    RobotStatus newStatus = m_pState->status;
    newStatus &= ~flags;

	//clear reasons if no needs are flagged
    if (!(newStatus & FLAG_NEED_ALL))
    {
        newStatus &= ~FLAG_REASON_ALL;
    }

    UpdateRobotFlags( newStatus );
}


void RobotEpson::SetLN2Level( LN2Level newLevel )
{
	if (m_pState->currentLN2Level != newLevel)
	{
	    m_pState->currentLN2Level = newLevel;
		CheckLN2Level( );
	}
}

int RobotEpson::SetDesiredLN2LevelInSPEL( bool high, char* status_buffer )
{
	try
	{
		COleVariant ln2_high( short(1) );
		COleVariant ln2_low( short(0) );

		if (high)
		{
			m_pSPELCOM->SetSPELVar( "g_LN2LevelHigh", ln2_high );
		}
		else
		{
			m_pSPELCOM->SetSPELVar( "g_LN2LevelHigh", ln2_low );
		}
		CopyDesiredLN2LevelFromSPEL( );
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
		return 0;
	}
	LOG_WARNING( "ALARM: manual setting LN2 level triggered all calibration flags " );
	SetRobotFlags( FLAG_REASON_LN2LEVEL | FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_CASSETTE | FLAG_NEED_CAL_GONIO );
	return 1;
}

void RobotEpson::CopyDesiredLN2LevelFromSPEL( )
{
    CString tempString( m_pSPELCOM->GetSPELVar( "g_LN2LevelHigh" ) );
	if (!tempString.CompareNoCase( "true" ))
	{
		m_desiredLN2Level = LN2LEVEL_HIGH;
		CCassette::SetInLN2( true );
	}
	else
	{
		m_desiredLN2Level = LN2LEVEL_LOW;
		CCassette::SetInLN2( false );
	}
	UpdateState( );
}

//current policy:
//if desired LN2 level is high, it will set flag if the real level goes low
//if desired LN2 level is low, we do not care the real level then.
void RobotEpson::CheckLN2Level( )
{
	const RobotStatus LN2_STATUS = FLAG_REASON_LN2LEVEL | FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_CASSETTE | FLAG_NEED_CAL_GONIO;

	//check if flag already set
	if ((GetRobotFlags( ) & LN2_STATUS) == LN2_STATUS) return;

	//only set flag if deisre is high but current is low
    if (m_pState->currentLN2Level == LN2LEVEL_LOW &&
		m_desiredLN2Level == LN2LEVEL_HIGH)
    {
		LOG_WARNING( "ALARM: LN2 level triggered all calibration flags " );
        SetRobotFlags( LN2_STATUS );
    }
}

void RobotEpson::SetCurrentPoint( LPoint point )
{
    if (m_pState->currentPoint == point) return;

	m_pState->currentPoint = point;
    UpdateState( );
}

void RobotEpson::SetSampleState( CurrentSampleState state )
{
    if (m_pState->sampleState == state) return;

	m_pState->sampleState = state;
    UpdateState( );
}

RobotEpson::LPoint RobotEpson::GetCurrentPoint ( void ) const
{
	return m_pState->currentPoint;
}

RobotEpson::CurrentSampleState RobotEpson::GetSampleState( void ) const
{
	return m_pState->sampleState;
}

RobotEpson::DumbbellState RobotEpson::GetDumbbellState ( void ) const
{
	return m_pState->dumbbellState;
}

void RobotEpson::SetDumbbellState ( DumbbellState Ds )
{
	if (m_pState->dumbbellState == Ds) return;

	m_pState->dumbbellState = Ds;
    UpdateState( );
}

void RobotEpson::InitializeMMap ( void )
{
	void* bAddress = 0;

	if (m_MMapFile.OpenMemMap ( sizeof(*m_pState), &bAddress ))
	{
		m_pState = &m_LocalStateOnlyUSedWhenMMapFailed;
	}
	else
	{
		m_pState = (RobotEpsonState*)bAddress;
	}
}


void RobotEpson::SavePoints ( void )
{
	m_pSPELCOM->SavePoints ( "robot1.pnt" );
}

void RobotEpson::SetMotorsOn ( bool on )
{
	m_pSPELCOM->SetMotorsOn ( on );
}

BOOL RobotEpson::GetMotorsOn ( void )
{
	return m_pSPELCOM->GetMotorsOn ( );
}

BOOL RobotEpson::GetPause ( void )
{
	return m_pSPELCOM->PauseOn ( );
}

void RobotEpson::Cont ( void )
{
	m_pSPELCOM->Cont ( );
}

CString RobotEpson::GetLastError ( void )
{
	return m_pSPELCOM->GetErrorMessage ( );
}

long RobotEpson::GetLastErrorNumber ( void )
{
	return m_pSPELCOM->GetErrorNumber ( );
}

void RobotEpson::Abort ( bool flag_only )
{
	LOG_FINE( "+Abort" );

	if (m_InEventProcess)
	{
		LOG_FINEST( "abort called by event process set need to bring robot up" );
		m_NeedBringUp = true;
	}

	if (flag_only)
	{
		m_NeedAbort = true;
		LOG_FINE( "-Abort flag only" );
		return;
	}

	if (m_SPELAbortCalled)
	{
		m_NeedAbort = false;
		LOG_FINE( "-Abort: already called not cleared yet" );
		return;
	}


	time_t now = time( NULL );
	if (now < m_tsAbort + 10)
	{
		LOG_WARNING( "abort again too soon, within 10 seconds from last abort" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "hardware aborts too close within 10 seconds" );
		}
		LOG_FINE( "-abort" );
		return;
	}
	m_tsAbort = now;
	m_NeedAbort = false;

	if (m_InAbort)
	{
		m_NeedAbort = false;
		LOG_WARNING( "abort in abort: abort already in process" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "hardware abort already in process" );
		}
		LOG_WARNING1( "in event=%d", (int)m_InEventProcess );
		LOG_FINE( "-Abort" );
		return;
	}
	InEventHolder inAbort( &m_InAbort );
	xos_event_reset( &m_EvtSPELResetOK );
	LOG_FINEST( "call SPEL abort" );
	m_SPELAbortCalled = true;
	m_pSPELCOM->Abort ( );
	LOG_FINEST( "SPEL abort end" );
	xos_event_set( &m_EvtSPELResetOK );
	LOG_FINE( "-Abort" );
}

void RobotEpson::ResetAbort ( )
{
	if (xos_event_wait( &m_EvtSPELResetOK, 1 ) != XOS_WAIT_SUCCESS)
	{
		LOG_WARNING( "skip resetAbort while EVENT SPELResetOK is not signaled" );

		time_t now = time( NULL );
		if (now > m_tsAbort + 30)
		{
            if (m_pEventListener)
            {
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "Please REBOOT robot PC. No response from controller" );
				RobotWait( 3000 );
				robotSystemStop( );
            }
		}
		throw new RobotException( "flag for reset OK is not signaled" );
	}
	m_pSPELCOM->ResetAbort ( );
}

BOOL RobotEpson::GetEstop ( )
{
	return m_pSPELCOM->EstopOn ( );
}

void RobotEpson::Reset ( )
{
	m_pSPELCOM->Reset ( );
}

///////////////////////////////////////////////
//check whether robot can reach goniometer
//It checks P22 for X and Y, checks P21 for Z
// P22 is more outside than P21 in (X, Y)
//
//First it check to see if the distance from P22 to original point (0,0)
// is too long or too short for robot to reach
//
//Second if the P22 is in a special area close to back end of the robot,
// more tight check will be done.
//
//Third check the hight of the P21
bool RobotEpson::GonioReachable( char* status_buffer )
{
	if (m_ArmLength <= 0)
	{
		//arm length not initialized or unknow, we cannot check
		return true;
	}

	//get points
	PointCoordinate Point21;
	PointCoordinate Point22;
	retrievePoint( P21, Point21 );
	retrievePoint( P22, Point22 );
    
#ifndef MIXED_ARM_ORIENTATION
	//check orientation
	if (Point22.o != m_armOrientation)
	{
		strcpy( status_buffer, "gonio P22 orientation wrong" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
		}
		SetRobotFlags( FLAG_REASON_UNREACHABLE );
		SetRobotFlags( FLAG_NEED_CAL_GONIO );
		return false;
	}
#endif

	///////////////// Check radius range //////////////////////////
	float P22Distance = Point22.getRadius( );

	if (P22Distance >= m_ArmLength || P22Distance <= m_MinR)
	{
		LOG_WARNING3( "gonio out of reach: dist=%f, armlength=%f minlengt2=%f", P22Distance, m_ArmLength, m_MinR );
		strcpy( status_buffer, STATUS_OUT_OF_RANGE_XY );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
		}
		SetRobotFlags( FLAG_REASON_UNREACHABLE );
		return false;
	}
	else
	{
		char message[1024] = {0};
		sprintf( message, "gonio: dist=%f, armlength=%f minlengt2=%f", P22Distance, m_ArmLength, m_MinR );
		LOG_FINEST( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
		}
	}

	////////////////////// check forbidden rectangle ///////////////////////////
	if (Point22.x >= m_RectangleX0 && Point22.x <= m_RectangleX1 &&
		Point22.y >= m_RectangleY0 && Point22.y <= m_RectangleY1)
	{
		LOG_WARNING2( "gonio out of reach: forbidden rectangle: P22: %f, %f", Point22.x, Point22.y );
		LOG_WARNING2( "gonio out of reach: rectangle X: %f, %f", m_RectangleX0, m_RectangleX1 );
		LOG_WARNING2( "gonio out of reach: rectangle Y: %f, %f", m_RectangleY0, m_RectangleY1 );
		strcpy( status_buffer, STATUS_OUT_OF_RANGE_XY );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
		}
		SetRobotFlags( FLAG_REASON_UNREACHABLE );
		return false;
	}

	////////////////////// Check area ////////////////////////////////
	if (Point22.y < 0.0f)
	{
		float angleFromAxisY = atan2f( fabsf(Point22.x), fabsf(Point22.y) );
		if (angleFromAxisY < m_Arm1AngleLimit)
		{
			//it must be within the circle of second arm
			float SecondArmCenterX = m_Arm1Length * sinf( m_Arm1AngleLimit );
			float SecondArmCenterY = m_Arm1Length * cosf( m_Arm1AngleLimit );

			float X2 = fabsf( Point22.x ) - SecondArmCenterX;
			float Y2 = fabsf( Point22.y ) - SecondArmCenterY;

			float Distance = sqrtf( X2 * X2 + Y2 * Y2 );

			if (Distance >= m_Arm2Length)
			{
				char message[1024] = {0};
				sprintf( message, "gonio out of reach by arm2:: dist=%f, arml2ength=%f", Distance, m_Arm2Length );
				LOG_WARNING( message );
				strcpy( status_buffer, STATUS_OUT_OF_RANGE_XY );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				}
				SetRobotFlags( FLAG_REASON_UNREACHABLE );
				return false;
			}
			else
			{
				char message[1024] = {0};
				sprintf( message, "gonio arm2:: dist=%f, arml2ength=%f", Distance, m_Arm2Length );
				LOG_FINEST( message );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
				}
			}
		}
	}

	//check Z
	if (Point21.z > -SAFETY_Z_BUFFER_FOR_MOVING_TO_GONIOMETER)
	{
		LOG_WARNING2( "table too high, gonioZ=%f >%f", Point21.z, -SAFETY_Z_BUFFER_FOR_MOVING_TO_GONIOMETER );
		strcpy( status_buffer, STATUS_OUT_OF_RANGE_Z );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
		}
        SetRobotFlags( FLAG_REASON_UNREACHABLE );
		return false;
	}
	else
	{
		char message[1024] = {0};
		sprintf( message, "gonio Z: %f limit: %f", Point21.z, -SAFETY_Z_BUFFER_FOR_MOVING_TO_GONIOMETER );
		LOG_FINEST( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
		}
	}

	//OK reach here, everything OK
	return true;
}


bool RobotEpson::SetGoniometerPoints ( float dx, float dy, float dz, float du, char* status_buffer )
{
    const float PI = 3.14159265359f;

	//goniometer orientation is 180 from U20
	m_goniometerOrientation = AngleToOrientation( m_pSPELCOM->CU( COleVariant("P20") ) + 180.0f );
	m_goniometerDirScale.cosValue = cosf( OrientationToAngle( m_goniometerOrientation ) );
	m_goniometerDirScale.sinValue = sinf( OrientationToAngle( m_goniometerOrientation ) );

	if ((m_downstreamOrientation == DIRECTION_X_AXIS && m_goniometerOrientation == DIRECTION_Y_AXIS) ||
	(m_downstreamOrientation == DIRECTION_Y_AXIS  && m_goniometerOrientation == DIRECTION_MX_AXIS) ||
	(m_downstreamOrientation == DIRECTION_MX_AXIS && m_goniometerOrientation == DIRECTION_MY_AXIS) ||
	(m_downstreamOrientation == DIRECTION_MY_AXIS && m_goniometerOrientation == DIRECTION_X_AXIS))
	{
	    m_tongConflict = true;
	}
	else
	{
	    m_tongConflict = false;
	}

	//P21 is the real goniometer point which will be used in robot movement.
	SetDerivedLPoint ( P21, P20, 
						dx, dy, dz, du );

	//P24 move to detach goniometer head along it.
	//float DetachAngle = m_goniometerOrientation * PI / 2.0f;
	float DetachDX = GONIOMETER_MOUNT_STANDBY_DISTANCE * m_goniometerDirScale.cosValue;
	float DetachDY = GONIOMETER_MOUNT_STANDBY_DISTANCE * m_goniometerDirScale.sinValue;
   	SetDerivedLPoint ( P24, P21, DetachDX, DetachDY, 0, 0 );

	//P23 down stream shift from P21.  In case of conflict tong, move away along goniometer too.
	//float SideStepAngle = m_downstreamOrientation * PI / 2.0f;
	float SideStepDX = GONIOMETER_DISMOUNT_SIDEMOVE_DISTANCE * m_downstreamDirScale.cosValue;
	float SideStepDY = GONIOMETER_DISMOUNT_SIDEMOVE_DISTANCE * m_downstreamDirScale.sinValue;
	float ExtraDX = 0;
	float ExtraDY = 0;
    if (m_tongConflict)    
	{
		SideStepDX = CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.cosValue;
		SideStepDY = CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.sinValue;

		ExtraDX = CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.cosValue;
		ExtraDY = CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.sinValue;
	}

	SetDerivedLPoint ( P23, P21, SideStepDX + ExtraDX, SideStepDY + ExtraDY, 0, 0 );

	//XY of P22 should be the corner of rectangle defined by P24-P21-P23.
	SetDerivedLPoint ( P22, P21, 
		DetachDX + SideStepDX, DetachDY + SideStepDY,  -1,   0,
		false,                 false,                 true, false );

	//check if robot can reach goniometer
	if (!GonioReachable( status_buffer ))
	{
		return false;
	}

    //setup points to arc from P18 to goniometer
	PointCoordinate Point18;
	PointCoordinate Point22;

	retrievePoint( P18, Point18 );
	retrievePoint( P22, Point22 );
	///////we just want to move from P18 to P22 smoothly
	// so P18-P28-P38(ARC), then move to P22.
	// we will move along axes and will move the shorter distance first
	float DX = fabsf( Point22.x - Point18.x );
	float DY = fabsf( Point22.y - Point18.y );

	//no need to merge the similar codes, it is easy to read and find bug this way
	PointCoordinate arcEnd;
	PointCoordinate arcMid;
	if (DX > DY)
	{
		//we arc to X axis first then move along X axis
		if (Point18.x > Point22.x && Point18.y > Point22.y)
		{
			arcEnd.x = Point18.x - (Point18.y - Point22.y);
			arcEnd.y = Point22.y;
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x - (1.0f - 0.707f) * (Point18.y - Point22.y);
			arcMid.y = Point18.y - 0.707f * (Point18.y - Point22.y);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x > Point22.x && Point18.y < Point22.y)
		{
			arcEnd.x = Point18.x + (Point22.y - Point18.y);
			arcEnd.y = Point22.y;
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x - (1.0f - 0.707f) * (Point22.y - Point18.y);
			arcMid.y = Point18.y + 0.707f * (Point22.y - Point18.y);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x < Point22.x && Point18.y > Point22.y)
		{
			arcEnd.x = Point18.x + (Point18.y - Point22.y);
			arcEnd.y = Point22.y;
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x + (1.0f - 0.707f) * (Point18.y - Point22.y);
			arcMid.y = Point18.y - 0.707f * (Point18.y - Point22.y);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x < Point22.x && Point18.y < Point22.y)
		{
			arcEnd.x = Point18.x + (Point22.y - Point18.y);
			arcEnd.y = Point22.y;
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x + (1.0f - 0.707f) * (Point22.y - Point18.y);
			arcMid.y = Point18.y + 0.707f * (Point22.y - Point18.y);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else
		{
		}
	}
	else
	{
		if (Point18.x > Point22.x && Point18.y > Point22.y)
		{
			arcEnd.x = Point22.x;
			arcEnd.y = Point18.y - (Point18.x - Point22.x);
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x - 0.707f * (Point18.x - Point22.x);
			arcMid.y = Point18.y - (1.0f - 0.707f) * (Point18.x - Point22.x);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x > Point22.x && Point18.y < Point22.y)
		{
			arcEnd.x = Point22.x;
			arcEnd.y = Point18.y + (Point18.x - Point22.x);
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x - 0.707f * (Point18.x - Point22.x);
			arcMid.y = Point18.y + (1.0f - 0.707f) * (Point18.x - Point22.x);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x < Point22.x && Point18.y > Point22.y)
		{
			arcEnd.x = Point22.x;
			arcEnd.y = Point18.y - (Point22.x - Point18.x);
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x + 0.707f * (Point22.x - Point18.x);
			arcMid.y = Point18.y - (1.0f - 0.707f) * (Point22.x - Point18.x);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else if (Point18.x < Point22.x && Point18.y < Point22.y)
		{
			arcEnd.x = Point22.x;
			arcEnd.y = Point18.y + (Point22.x - Point18.x);
			arcEnd.z = Point18.z;
			arcEnd.u = Point22.u;

			arcMid.x = Point18.x + 0.707f * (Point22.x - Point18.x);
			arcMid.y = Point18.y + (1.0f - 0.707f) * (Point22.x - Point18.x);
			arcMid.z = Point18.z;
			arcMid.u = (Point22.u + Point18.u) / 2.0f;
		}
		else
		{
		}
	}
	assignPoint( P28, arcMid );
	assignPoint( P38, arcEnd );
#ifdef _DEBUG
	SavePoints( );
#endif
	return true;
}

bool RobotEpson::OpenGripper ( )
{
	m_pSPELCOM->Off ( OUT_GRIPPER_CLOSE, vNull, vNull );
	if (!WaitSw( IN_GRIPPER_OPEN, 1, 10 ))
	{
        strcpy( m_ErrorMessageForOldFunction, "Opening Grippers timed out" );
		LOG_SEVERE( m_ErrorMessageForOldFunction );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, m_ErrorMessageForOldFunction );
		}

        if (getAttributeFieldBool( ATTRIB_DEVELOP_MODE) )
        {
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_ABORT );
            SetMotorsOn( false );
        }
        return false;
	}
	else if (m_pSPELCOM->Sw( IN_GRIPPER_CLOSE ))
	{
		strcpy( m_ErrorMessageForOldFunction, "Gripper sensor logical wrong in opening: all high" );
		LOG_SEVERE( m_ErrorMessageForOldFunction );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
		}
        SetRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_ABORT );
        SetMotorsOn( false );
		return false;
	}
    else
    {
		if (m_pSPELCOM->Sw( IN_GRIPPER_CLOSE ))
		{
		}
		return true;
    }
}

bool RobotEpson::CloseGripper( bool noCheck )
{
	m_pSPELCOM->On ( OUT_GRIPPER_CLOSE, vNull, vNull );
	if (!WaitSw( IN_GRIPPER_CLOSE, 1, 10 ))
	{
        if (!noCheck && getAttributeFieldBool( ATTRIB_DEVELOP_MODE ))
        {
			strcpy( m_ErrorMessageForOldFunction, "Closing Grippers timed out" );
			LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}

            SetRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_ABORT );
            SetMotorsOn( false );
	        return false;
        }
		//try it again

		m_pSPELCOM->Off ( OUT_GRIPPER_CLOSE, vNull, vNull );
		WaitSw( IN_GRIPPER_OPEN, 1, 10 );
		m_pSPELCOM->On ( OUT_GRIPPER_CLOSE, vNull, vNull );
		if (!WaitSw( IN_GRIPPER_CLOSE, 1, 10 ))
		{
			strcpy( m_ErrorMessageForOldFunction, "Closing Grippers timed out in retry" );
			LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, m_ErrorMessageForOldFunction );
			}
	        return false;
		}
		else if (m_pSPELCOM->Sw( IN_GRIPPER_OPEN ))
		{
			strcpy( m_ErrorMessageForOldFunction, "Gripper sensor logical wrong in closing retry: all high" );
			LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
			SetRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_ABORT );
			SetMotorsOn( false );
			return false;
		}
		else
		{
			char warning[] = "Closing Grippers timed out, retry OK";
			LOG_WARNING( warning );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, warning );
			}
			return true;
		}
	}
	else if (m_pSPELCOM->Sw( IN_GRIPPER_OPEN ))
	{
		strcpy( m_ErrorMessageForOldFunction, "Gripper sensor logical wrong in closing: all high" );
		LOG_SEVERE( m_ErrorMessageForOldFunction );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
		}
        SetRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_ABORT );
        SetMotorsOn( false );
		return false;
	}
    else
    {
        return true;
    }
}

bool RobotEpson::Dance ( )
{
	setRobotSpeed( SPEED_DANCE );

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
	float zlim = currentPosition.z + 15;

	m_pSPELCOM->LimZ ( zlim );

	for (int i=0; i<2; i++ )
	{
		m_pSPELCOM->Jump ( (COleVariant)"P0 +U(10)" );
		m_pSPELCOM->Jump ( (COleVariant)"P0 -U(10)" );
	}

	m_pSPELCOM->Jump ( (COleVariant)"P0" );
	
	m_pSPELCOM->LimZ ( 0 );

	return true;
}

//may throw
void RobotEpson::ReadToolSet( const ToolSet tl, PointCoordinate& point )
{
    char command[200]= {0};
    sprintf( command, "P51 = TLSet(%d)", tl + 1);
    m_pSPELCOM->ExecSPELCmd( command );
	retrievePoint( P51, point );
}


//may throw
bool RobotEpson::CheckToolSet ( ToolSet tl )
{
	PointCoordinate point;

    ReadToolSet( tl, point );

    if (point.x == 0 || point.y == 0 || point.u == 0)
    {
        return false;
    }
    else
    {
        return true;
    }
}

bool RobotEpson::CheckPoint( LPoint p )
{
	PointCoordinate point;
	retrievePoint( p, point );
    if (point.x == 0 || point.y == 0)
    {
        return false;
    }
    else
    {
        return true;
    }
}


void RobotEpson::InitCassetteCoords ( const char cassette )
{	
	CCassette& theCassette = GetCassette ( cassette );
	LPoint p;
	LPoint topP;
	LPoint bottomP;
	PointCoordinate point;
	PointCoordinate topPoint;
	PointCoordinate bottomPoint;

	//we want standby point is between dumbbell post and the cassette
	float UP6 = m_pSPELCOM->CU( COleVariant( "P6") );
	float standbyU = m_dumbbellOrientation * 90.0f + 90.0f;
	standbyU = UP6 + CCassette::NarrowAngle( standbyU - UP6 );
	float secondaryStandbyU = standbyU;

	//column A angle is different now for each cassette
	//we get it from SPEL, so that we only have one place to store and change the settting
	float column_A_Angle = 0;
	const char *variableName = NULL;

	switch ( cassette )
	{
		case 'l':
			variableName = "g_Perfect_LeftCassette_Angle";
			p = P34;
			bottomP = P41;
			topP = P44;
			secondaryStandbyU -= 90.0f;
			break;
		case 'm':
			variableName = "g_Perfect_MiddleCassette_Angle";
			p = P35;
			bottomP = P42;
			topP = P45;
			break;
		case 'r':
			variableName = "g_Perfect_RightCassette_Angle";
			p = P36;
			bottomP = P43;
			topP = P46;
			secondaryStandbyU += 90.0f;
			break;
	}
	CString tempString1( m_pSPELCOM->GetSPELVar( variableName ) );
	if (sscanf( tempString1, "%f", &column_A_Angle ) != 1)
	{
		SetRobotFlags( FLAG_NEED_CAL_CASSETTE | FLAG_REASON_INIT );
		if (m_pEventListener)
		{
			char message[1024] = {0};
			sprintf( message, "SPEL global preserved variable %s not defined", variableName );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, message );
		}
		return;
	}

	theCassette.SetUpDirection( column_A_Angle, standbyU, secondaryStandbyU );

	retrievePoint( p, point );
	retrievePoint( topP, topPoint );
	retrievePoint( bottomP, bottomPoint );

	theCassette.SetUpCoordinates( point );

	theCassette.SetupTilt( topPoint, bottomPoint );
}

CCassette& RobotEpson::GetCassette ( const char cassette  )
{
	switch ( cassette )
	{
		case 'l':
			return  m_LeftCassette;
			break;
		case 'm':
			return  m_MiddleCassette;
			break;
		case 'r':
			return  m_RightCassette;
			break;
		default://to avoid warning in compiling
			return m_LeftCassette;
	}
}

const CCassette& RobotEpson::GetConstCassette ( const char cassette  ) const
{
	switch ( cassette )
	{
		case 'l':
			return  m_LeftCassette;
			break;
		case 'm':
			return  m_MiddleCassette;
			break;
		case 'r':
			return  m_RightCassette;
			break;
		default://to avoid warning in compiling
			return m_LeftCassette;
	}
}


bool RobotEpson::MoveToCoolPoint ( void )
{
	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move( (COleVariant)"P* :Z(-1)" );

	if (m_FlagAbort)
	{
		return false;
	}

	setRobotSpeed( SPEED_FAST );
#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go( (COleVariant)"P1 CP" );
	SetCurrentPoint ( P1 );
	m_pSPELCOM->Go ( (COleVariant)"P2" );
#else
	m_pSPELCOM->Move( (COleVariant)"P1 CP" );
	SetCurrentPoint ( P1 );
	m_pSPELCOM->Move ( (COleVariant)"P2" );
#endif
	SetCurrentPoint ( P2 );

	if (m_FlagAbort)
	{
#ifdef MIXED_ARM_ORIENTATION
		m_pSPELCOM->Go( (COleVariant)"P1 CP" );
#else
		m_pSPELCOM->Move( (COleVariant)"P1" );
#endif
		SetCurrentPoint ( P1 );
		return false;
	}

	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P3" );		
	SetCurrentPoint ( P3  );

    return true;
}

void RobotEpson::MoveToPlacer ( void )
{
	setRobotSpeed( SPEED_FAST );
	m_pSPELCOM->Move ( (COleVariant)"P27 :Z(0)" );

	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P27");
	SetCurrentPoint ( P27  );
}

bool RobotEpson::MoveToHome ( )
{
	bool success = false;

 	switch (GetSampleState( ))
	{
	case NO_CURRENT_SAMPLE:
	case SAMPLE_ON_GONIOMETER:
		break;

	case SAMPLE_ON_TONG:
	case SAMPLE_ON_PLACER:
	case SAMPLE_ON_PICKER:
	default:
		{
            char error_msg[] = "sample state wrong, cannot go home";
            LOG_WARNING( error_msg );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, error_msg );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, error_msg );

            }
		}
        SetMotorsOn( false );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
        return false;
	}

	switch (GetDumbbellState( ))
	{
	case DUMBBELL_OUT:
	case DUMBBELL_IN_CRADLE:
		break;

	case DUMBBELL_RAISED:
	case DUMBBELL_IN_TONG:
	default:
		{
            char error_msg[] = "tong state wrong, cannot go home";
            LOG_WARNING( error_msg );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, error_msg );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, error_msg );

            }
		}
        SetMotorsOn( false );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
        return false;
	}

   LPoint currentPoint = GetCurrentPoint ( );

    m_pSPELCOM->Tool( 0 );
	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
    //check real robot position against what we remembered
    switch ( currentPoint )
	{
	case P0:
	case P1:
	case P2:
	case P3:
	case P93:
	case P94:
	case P15:
	case P25:
	case P18:
    case P89:
    case P21:
        if (!CloseToPoint( currentPoint, currentPosition) )
        {
			LOG_WARNING3( "(%f, %f) not close to point %d", currentPosition.x, currentPosition.y, (int)currentPoint );
            return false;
        }
        break;

    case P22:
        if (!CloseToPoint( currentPoint, currentPosition, 100) )
        {
			LOG_WARNING2( "(%f, %f) not close to P22 r= 100", currentPosition.x, currentPosition.y );
            return false;
        }
        break;

    default:
		LOG_WARNING1( "not supported current point %d", (int)currentPoint );
        return false;
    }

	setRobotSpeed( SPEED_FAST );

    switch ( GetCurrentPoint ( ) )
	{
	case P0:
		m_Dewar.CloseLid( ); //ignore errors here
        return true;

	case P3:
	case P93:
	case P94:
	case P15:
	case P25:
		m_pSPELCOM->Move( (COleVariant)"P2 CP" );
		SetCurrentPoint ( P2 );
        //fall through
	case P2:
        m_pSPELCOM->Move( (COleVariant)"P2" );
#ifdef MIXED_ARM_ORIENTATION
		m_pSPELCOM->Go( (COleVariant)"P1" );
#else
		m_pSPELCOM->Move( (COleVariant)"P1" );
#endif
		SetCurrentPoint ( P1 );
        //fall through
	case P1:
        m_pSPELCOM->Move( (COleVariant)"P1" );
  		success = true;
		break;

    case P21:
    case P22:
		{
			//move away from gonometer by 5 mm
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(%3f) +Y(%.3f)",
				5.0f * m_goniometerDirScale.cosValue,
				5.0f * m_goniometerDirScale.sinValue );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
		}
		m_pSPELCOM->Move ( (COleVariant)"P22" );
		SetCurrentPoint ( P22 );

		switch (m_Dewar.OpenLid( ))
        {
        case Dewar::OPEN_LID_WARNING_LONG_TIME:
            {
                char openlid_msg[] = "OpenLid took very long time";
                LOG_WARNING( openlid_msg );
                if (m_pEventListener)
                {
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
                }
            }
            //falling through
        case Dewar::OPEN_LID_OK:
            MoveFromGoniometerToRestPoint( );
		    success = true;
            break;

        case Dewar::OPEN_LID_FAILED:
        default:
            strcpy( m_ErrorMessageForOldFunction, "OpenLid timeout" );
            LOG_WARNING( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_LID_JAM );
            SetMotorsOn( false );
        }
        break;

	case P18:
        switch (m_Dewar.OpenLid( ))
        {
        case Dewar::OPEN_LID_WARNING_LONG_TIME:
            {
                char openlid_msg[] = "OpenLid took very long time";
                LOG_WARNING( openlid_msg );
                if (m_pEventListener)
                {
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
                }
            }
            //falling through
        case Dewar::OPEN_LID_OK:
#ifdef MIXED_ARM_ORIENTATION
		    m_pSPELCOM->Go( (COleVariant)"P1" );
#else
		    m_pSPELCOM->Move( (COleVariant)"P1" );
#endif
		    SetCurrentPoint ( P1 );
		    success = true;
            break;

        case Dewar::OPEN_LID_FAILED:
        default:
            strcpy( m_ErrorMessageForOldFunction, "OpenLid timeout" );
            LOG_WARNING( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_LID_JAM );
            SetMotorsOn( false );
        }
		break;

	case P89:
		m_pSPELCOM->Move( COleVariant( "P* :Z(-1)" ) );
		success = true;
		break;
	}
	
	if ( success )
	{
		m_Dewar.CloseLid( ); //ignore errors here
		m_pSPELCOM->Move ( (COleVariant)"P0 :Z(-1)" );

		setRobotSpeed( SPEED_IN_LN2 ); //not really in LN2, but slow is safe here.
		m_pSPELCOM->Move ( (COleVariant)"P0" );
		SetCurrentPoint ( P0 );
		OpenGripper ( ); //ignore errors here.
	}
	return success;
}

bool RobotEpson::GetMagnet( void )
{
	UpdateSampleStatus( "take dumbbell" );
    LPoint currentPoint = GetCurrentPoint( );

    if (currentPoint != P3)
    {
        SetRobotFlags( FLAG_REASON_ABORT );
        SetMotorsOn( false );
        return false;
    }

    if (!OpenGripper( ) && !ReHeatTongAndCheckGripper( ))
    {
        MoveTongHome( );
        SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
        SetMotorsOn( false );
        return false;
    }

	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P6" );
	SetCurrentPoint ( P6 );

	SetDumbbellState( DUMBBELL_IN_TONG );

    if (GetRobotFlags( ) & FLAG_IN_RESET )
	{
        //in reset, we will not check magnet
		return true;
	}


	if (!CloseGripper( ))
    {
        if (!OpenGripper( ))
        {
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }

        //try reheat
    	m_pSPELCOM->Move ( (COleVariant)"P3" );
    	SetCurrentPoint ( P3 );

        if (!ReHeatTongAndCheckGripper( ))
        {
            MoveTongHome( );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }

        //try close it again
	    m_pSPELCOM->Move ( (COleVariant)"P6" );
	    SetCurrentPoint ( P6 );
	    if (!CloseGripper( ))
        {
            if (!OpenGripper( ))
            {
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
		        SetMotorsOn( false );
                return false;
            }
        	m_pSPELCOM->Move ( (COleVariant)"P3" );
        	SetCurrentPoint ( P3 );
            MoveTongHome( );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			if (m_pEventListener)
			{
				strcpy( m_ErrorMessageForOldFunction, "gripper cannot close in get_maget, mayby toolset calibration is off" );
	            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
	            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
	        SetMotorsOn( false );
            return false;
        }
    }

    if (!getAttributeFieldBool( ATTRIB_CHECK_MAGNET ))
    {
        return true;
    }

    if (!m_CheckMagnet)
    {
        return true;
    }

    //move a little bit, then check the force sensor,
    //if no force readback, we lost the magnet
    RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
    ForceCalibrate( );

	switch (m_dumbbellOrientation)
	{
	case DIRECTION_X_AXIS:
	case DIRECTION_MX_AXIS:
	    m_pSPELCOM->Move( (COleVariant)"P* +Y(0.5)" );
		break;
	case DIRECTION_Y_AXIS:
	case DIRECTION_MY_AXIS:
		m_pSPELCOM->Move( (COleVariant)"P* +X(0.5)" );
		break;
	}

    float currentForce = ReadForce( FORCE_YTORQUE );
#ifdef _DEBUG
	LOG_FINEST1( "check magnet, readback force=%f", currentForce );
#endif
	m_pSPELCOM->Move ( (COleVariant)"P6" );
    if (fabsf(currentForce) < THRESHOLD_MAGNETCHECK)
    {
        strcpy( m_ErrorMessageForOldFunction, "Lost Magnet" );
		LOG_SEVERE( m_ErrorMessageForOldFunction );
        SetRobotFlags( FLAG_REASON_LOST_MAGNET );

        if (!OpenGripper( ))
        {
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
    	m_pSPELCOM->Move ( (COleVariant)"P3" );
    	SetCurrentPoint ( P3 );
        //MoveTongHome( );
        //flag FLAG_REASON_LOST_MAGNET already set
        SetMotorsOn( false );
        return false;        
    }
    m_CheckMagnet = false;

    return true;
}

void RobotEpson::PutMagnet( bool check_tolerance, bool collect_force )
{
    UpdateSampleStatus( "put back dumbbell" );
    if (check_tolerance || collect_force)
    {
        //RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
        ForceCalibrate( );
    }

	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P6" );
	SetCurrentPoint ( P6 );

    if (check_tolerance || collect_force)
    {
        float forces[6] = {0};
        ReadForces( forces );
        char log_message[256]= {0};
        sprintf( log_message, "zforce: %f torques: %f, %f, %f", forces[2], forces[3], forces[4], forces[5] );
        LOG_FINEST( log_message );

        if (check_tolerance)
        {
            if (fabsf( forces[2] ) > THRESHOLD_ZFORCE ||
                fabsf( forces[3] ) > THRESHOLD_XTORQUE ||
                fabsf( forces[4] ) > THRESHOLD_YTORQUE ||
                fabsf( forces[5] ) > THRESHOLD_ZTORQUE)
            {
			    //try again
			    m_pSPELCOM->Move ( (COleVariant)"P6 +Z(20)" );
			    RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
			    ForceCalibrate( );
			    m_pSPELCOM->Move ( (COleVariant)"P6" );
			    RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
			    memset( forces, 0, sizeof(forces) );
			    ReadForces( forces );
			    sprintf( log_message, "read second time: zforce: %f torques: %f, %f, %f", forces[2], forces[3], forces[4], forces[5] );
			    LOG_FINEST( log_message );

                static const char msg[256] = "need magnet calibration flag set by tolerance";

                if (fabsf( forces[2] ) > THRESHOLD_ZFORCE ||
				    fabsf( forces[3] ) > THRESHOLD_XTORQUE ||
				    fabsf( forces[4] ) > THRESHOLD_YTORQUE ||
				    fabsf( forces[5] ) > THRESHOLD_ZTORQUE)
			    {
                    if (m_pEventListener)
                    {
                        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, msg );
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, msg );
                    }
				    LOG_WARNING( msg );
			    }
			    if (fabsf( forces[2] ) > 5 * THRESHOLD_ZFORCE ||
				    fabsf( forces[3] ) > 5 * THRESHOLD_XTORQUE ||
				    fabsf( forces[4] ) > 5 * THRESHOLD_YTORQUE ||
				    fabsf( forces[5] ) > 5 * THRESHOLD_ZTORQUE)
			    {
				    SetRobotFlags( FLAG_NEED_CAL_MAGNET | FLAG_REASON_TOLERANCE );
				    LOG_WARNING( msg );
			    }
            }
        }//if (check_tolerance)
    }
    
    if (!OpenGripper( ))
    {
		SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
        if (m_pEventListener)
        {
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, "open gripper failed in PutMagnet" );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "Gripper jam at PutMagnet" );
        }
		LOG_WARNING( "Gripper jam at PutMagnet" );
        SetMotorsOn( false );
        return;
    }
	m_pSPELCOM->Move ( (COleVariant)"P3" );
	SetCurrentPoint ( P3 );
	SetDumbbellState( DUMBBELL_IN_CRADLE );
	CloseGripper( ); //ignore errors here
}

void RobotEpson::MoveToPortViaStandby( char cassette, short row, char column )
{
	char moveCommand[COMMAND_BUFFER_LENGTH] = {0};
	//this will fill P50, P52
	GetCassette( cassette ).GetCommandForPortFromStandby( row, column, moveCommand, m_cmdBackToStandby );

	PointCoordinate currentPosition;
	PointCoordinate Point4;
	PointCoordinate Point6;
	PointCoordinate Point50;

	GetCurrentPosition( currentPosition );
	retrievePoint( P4, Point4 );
	retrievePoint( P6, Point6 );
	retrievePoint( P50, Point50 );

	float zlim;
	zlim = max( currentPosition.z, Point50.z );
	zlim = max( Point4.z, zlim );
	zlim += 5.0f;
	float desired_u = Point50.u;
	float current_u = currentPosition.u;
	float current_z = currentPosition.z;
    short tl = m_pSPELCOM->GetTool( );
	
	//check zlim
	if (zlim > 0.0f || zlim < Point6.z)
	{
		SetRobotFlags( FLAG_REASON_ABORT | FLAG_NEED_RESET );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "failed to get standby point" );
        }
        SetMotorsOn( false );
        return;
	}


	float DZ = zlim - current_z;
	float DU = desired_u - current_u;

	setRobotSpeed( SPEED_SAMPLE );
	//we want move u to CU(P50) with current toolset but we want to rotate in toolset 0. So:
	char cmd[COMMAND_BUFFER_LENGTH]={0};
	m_pSPELCOM->Tool( 0 );
	sprintf( cmd, "Move P*+Z(%.3f);Go P*+U(%.3f)", DZ, DU );
	m_pSPELCOM->ExecSPELCmd( cmd );

	m_pSPELCOM->Tool( tl );
	sprintf( cmd, "Move P50:Z(%.3f) CP;Move P50", zlim );
	m_pSPELCOM->ExecSPELCmd( cmd );

	SetCurrentPoint ( P50 );
	m_pSPELCOM->LimZ ( 0 );

	//move to port ready
	m_pSPELCOM->ExecSPELCmd( moveCommand );
	SetCurrentPoint ( P52 );
	m_pState->currentCassette = cassette;
	m_pState->currentColumn = column;
	m_pState->currentRow = row;
    UpdateState( );
}

void RobotEpson::MoveFromCassetteToPost ( void )
{
	m_pSPELCOM->Tool( 0 );

	setRobotSpeed( SPEED_SAMPLE );

	PointCoordinate Point4;
	PointCoordinate Point49;
	PointCoordinate currentPosition;

	GetCurrentPosition( currentPosition );
	retrievePoint( P4, Point4 );

	Point49.z = max ( Point4.z, currentPosition.z );
	Point49.x = (Point4.x + currentPosition.x) / 2;
	Point49.y = (Point4.y + currentPosition.y) / 2;
	Point49.u = currentPosition.u;
	Point49.o = Point4.o;
	assignPoint( P49, Point49 );

	m_pSPELCOM->LimZ ( Point49.z + 5.0f );
	m_pSPELCOM->Move ( (COleVariant)"P49" );
	m_pSPELCOM->Jump ( (COleVariant)"P4" );
	SetCurrentPoint ( P4 );
	m_pSPELCOM->LimZ ( 0 );
}


void RobotEpson::MoveFromPortToStandby ( void )
{
	if (strncmp( m_cmdBackToStandby, "Move", 4) && 
		strncmp( m_cmdBackToStandby, "Arc", 3) &&
		strncmp( m_cmdBackToStandby, "Go", 2) &&
		strncmp( m_cmdBackToStandby, "Jump", 4))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "no back to standby command" );
        }
		throw new RobotException( "internal logical error, may need to reboot robot PC" );
	}
	m_pSPELCOM->ExecSPELCmd( m_cmdBackToStandby );
	SetCurrentPoint ( P50 );
}

void RobotEpson::MoveToGoniometer ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move to goniometer" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

    UpdateSampleStatus( "move to goniometer" );
	setRobotSpeed( SPEED_FAST );
	m_pSPELCOM->Move( (COleVariant)"P2 CP" );
	SetCurrentPoint ( P2 );

#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go( (COleVariant)"P18 CP" );
#else
	m_pSPELCOM->Move( (COleVariant)"P18 CP" );
#endif

	SetCurrentPoint ( P18 );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P38 CP" );
	m_pSPELCOM->Move( (COleVariant)"P22" );
	SetCurrentPoint ( P22 );
}

void RobotEpson::MoveFromGoniometerToPlacer ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move from goniometer to placer" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

	UpdateSampleStatus( "gonio to dumbbell" );
	setRobotSpeed( SPEED_FAST );
    m_pSPELCOM->Move( (COleVariant)"P38 CP" );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18 CP" );
	SetCurrentPoint( P18 );

#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go ( (COleVariant)"P27 :Z(0)" );
#else
	m_pSPELCOM->Move ( (COleVariant)"P27 :Z(0)" );
#endif
	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P27");
	SetCurrentPoint ( P27  );
}

void RobotEpson::MoveFromGoniometerToPicker ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move from goniometer to picker" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

    UpdateSampleStatus( "gonio to dumbbell" );
	setRobotSpeed( SPEED_FAST );
    m_pSPELCOM->Move( (COleVariant)"P38 CP" );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18 CP" );
	SetCurrentPoint( P18 );

#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go ( (COleVariant)"P17 :Z(0)" );
#else
	m_pSPELCOM->Move ( (COleVariant)"P17 :Z(0)" );
#endif
	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P17");
	SetCurrentPoint ( P17  );
}


void RobotEpson::MoveFromGoniometerToRestPoint ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move from goniometer to rest place" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

    UpdateSampleStatus( "go home from goniometer" );
	setRobotSpeed( SPEED_FAST );
    m_pSPELCOM->Move( (COleVariant)"P38 CP" );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18 CP" );
	SetCurrentPoint( P18 );

#ifdef MIXED_ARM_ORIENTATION
    m_pSPELCOM->Go( (COleVariant)"P1" );
#else
    m_pSPELCOM->Move( (COleVariant)"P1" );
#endif
	SetCurrentPoint( P1 );
}
void RobotEpson::MoveFromGoniometerToDewarSide ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move from goniometer to dewar side" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

    UpdateSampleStatus( "go home from goniometer" );
	setRobotSpeed( SPEED_FAST );
    m_pSPELCOM->Move( (COleVariant)"P38 CP" );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18" );
	SetCurrentPoint( P18 );
}

bool RobotEpson::GripSample ( void )
{
    UpdateSampleStatus( "grip sample" );
	setRobotSpeed( SPEED_IN_LN2 );

	if ( GetCurrentPoint ( )  == P22 )
	{
		m_pSPELCOM->Move ( (COleVariant)"P23" );
		SetCurrentPoint ( P23 );
		if (!OpenGripper ( ) && !ReHeatTongAndCheckGripper( ))
        {
            if (GetCurrentPoint( ) == P23)
            {
		        m_pSPELCOM->Move ( (COleVariant)"P22" );
		        SetCurrentPoint ( P22 );
                MoveFromGoniometerToRestPoint( );
            }
            MoveTongHome( );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
		//temp code special for 11-3
		if (m_tongConflict)
		{
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(%.3f) +Y(%.3f)",
				-CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.cosValue,
				-CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.sinValue );
		    //if (m_downstreamOrientation == DIRECTION_X_AXIS)
		    //{
    		//	sprintf( cmd, "P* -X(%.3f)", CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE );
    		//}
    		//else
    		//{
    		//	sprintf( cmd, "P* +X(%.3f)", CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE );
    		//}
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
		}
		m_pSPELCOM->Move ( (COleVariant)"P21" );
		SetCurrentPoint ( P21 );
		adjustForHamptonPinIfFlagged( ); //check if need inside
	    if (!CloseGripper( ))
        {
            if (!OpenGripper( ))
            {
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
		        SetMotorsOn( false );
                return false;
            }
			//before go reheat the tong, try again with adjusted position
			if (!retryWithPositionAdjust( ))
			{
				if (!OpenGripper( ))
				{
					SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
					SetMotorsOn( false );
					return false;
				}

				if (m_tongConflict)
				{
					//back off from gonometer
					char cmd[1024] = {0};
					sprintf( cmd, "P* +X(%.3f) +Y(%.3f)",
						CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.cosValue,
						CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.sinValue );
					COleVariant VAcmd( cmd );
					m_pSPELCOM->Move( VAcmd );
				}

				m_pSPELCOM->Move ( (COleVariant)"P23" );
				SetCurrentPoint ( P23 );
				if (!ReHeatTongAndCheckGripper( ))
				{
					if (GetCurrentPoint( ) == P23)
					{
						m_pSPELCOM->Move ( (COleVariant)"P22" );
						SetCurrentPoint ( P22 );
						MoveFromGoniometerToRestPoint( );
					}
					MoveTongHome( );
					SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
					SetMotorsOn( false );
					return false;
				}
				//retry
				if (m_tongConflict)
				{
					//move up stream
					char cmd[1024] = {0};
					sprintf( cmd, "P* +X(%.3f) +Y(%.3f)",
						-CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.cosValue,
						-CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE * m_downstreamDirScale.sinValue );
					COleVariant VAcmd( cmd );
					m_pSPELCOM->Move( VAcmd );
				}
				m_pSPELCOM->Move ( (COleVariant)"P21" );
				SetCurrentPoint ( P21 );
				adjustForHamptonPinIfFlagged( ); //check if need inside
			}
	        if (!CloseGripper( ))
            {
                if (!OpenGripper( ))
                {
                    SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			        SetMotorsOn( false );
                    return false;
                }
				if (m_tongConflict)
				{
					//back off from gonometer
					char cmd[1024] = {0};
					sprintf( cmd, "P* +X(%.3f) +Y(%.3f)",
						CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.cosValue,
						CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.sinValue );
					COleVariant VAcmd( cmd );
					m_pSPELCOM->Move( VAcmd );
				}
		        m_pSPELCOM->Move ( (COleVariant)"P23" );
		        SetCurrentPoint ( P23 );
		        m_pSPELCOM->Move ( (COleVariant)"P22" );
		        SetCurrentPoint ( P22 );
                MoveFromGoniometerToRestPoint( );
                MoveTongHome( );
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				if (m_pEventListener)
				{
					strcpy( m_ErrorMessageForOldFunction, "gripper cannot close at goniometer, maybe goniometer calibration is off" );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
				}
		        SetMotorsOn( false );
                return false;
            }
        }

        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "gripsample at P21: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }

        TwistRelease ( );
		SetGonioSample( 0, 0, 0 );
		SetTongSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
		SetSampleState ( SAMPLE_ON_TONG );
		UpdateSampleStatus( "on tong", true );

		m_pSPELCOM->Move ( (COleVariant)"P22" );
		SetCurrentPoint ( P22 );
	}
	else if ( GetCurrentPoint ( ) == P3 ) 
	{
        if (getAttributeFieldBool( ATTRIB_CHECK_PICKER ) && CloseGripper( ))
		{
			//use cavity to side touch the dumbbell to determin wether sample is on it.
			m_pSPELCOM->Move( (COleVariant)"P93 +U(90)" );
			m_pSPELCOM->Go( (COleVariant)"P93" );
			SetCurrentPoint( P93 );
	        ForceCalibrate( );
			m_pSPELCOM->Move( (COleVariant)"P5" );
			SetCurrentPoint( P5 );			
		    float currentForce = ReadForce( FORCE_YTORQUE );
			m_pSPELCOM->Move( (COleVariant)"P93" );
			SetCurrentPoint( P93 );
			LOG_INFO1( "check_picker force=%.3f", currentForce );

		    if (fabsf(currentForce) < THRESHOLD_PICKERCHECK)
			{
				LOG_WARNING( "failed to pull out sample from cassette" );
				SetPickerSample( 0, 0, 0, false );
				SetSampleState( NO_CURRENT_SAMPLE );

				//mark that port bad
				GetCassette( m_pState->currentCassette ).SetPortState( m_pState->currentRow, m_pState->currentColumn, CSamplePort::PORT_JAM );
			    UpdateCassetteStatus( );

				if (m_pEventListener)
				{
					strcpy( m_ErrorMessageForOldFunction, "failed to pull sample out" );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
				}
				//MoveTongHome( );
				return false;
			}
			//OK
			if (!OpenGripper ( ) && !ReHeatTongAndCheckGripper( ))
			{
				MoveTongHome( );
				SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				SetMotorsOn( false );
				return false;
			}
			m_pSPELCOM->Arc ( (COleVariant)"P15", (COleVariant)"P16" );
			SetCurrentPoint ( P16 );
		}
		else
		{
			if (!OpenGripper ( ) && !ReHeatTongAndCheckGripper( ))
			{
				MoveTongHome( );
				SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				SetMotorsOn( false );
				return false;
			}
			m_pSPELCOM->Move( (COleVariant)"P93 +U(90) CP" );
			m_pSPELCOM->Arc ( (COleVariant)"P15", (COleVariant)"P16" );
			SetCurrentPoint ( P16 );
		}

		adjustForHamptonPinIfFlagged( ); //check if need inside
	    if (!CloseGripper( ))
        {
            if (!OpenGripper( ))
            {
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
		        SetMotorsOn( false );
                return false;
            }
			//before go reheat the tong, try again with adjusted position
			if (!retryWithPositionAdjust( ))
			{
				if (!OpenGripper( ))
				{
					SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
					SetMotorsOn( false );
					return false;
				}
    			m_pSPELCOM->Arc( (COleVariant)"P15", (COleVariant)"P93 +U(90) CP" );
    			m_pSPELCOM->Move( (COleVariant)"P3" );
				SetCurrentPoint( P3 );
				if (!ReHeatTongAndCheckGripper( ))
				{
					MoveTongHome( );
					SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
					SetMotorsOn( false );
					return false;
				}
				//retry
				m_pSPELCOM->Move( (COleVariant)"P93 +U(90) CP" );
				m_pSPELCOM->Arc ( (COleVariant)"P15", (COleVariant)"P16" );
				SetCurrentPoint ( P16 );
			}
	        if (!CloseGripper( ))
            {
                if (!OpenGripper( ))
                {
                    SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			        SetMotorsOn( false );
                    return false;
                }
    		    m_pSPELCOM->Arc( (COleVariant)"P15", (COleVariant)"P93 +U(90) CP" );
    		    m_pSPELCOM->Move( (COleVariant)"P3" );
		        SetCurrentPoint( P3 );
                MoveTongHome( );
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				if (m_pEventListener)
				{
					strcpy( m_ErrorMessageForOldFunction, "gripper cannot close at picker, mayby toolset calibration is off" );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
				}
		        SetMotorsOn( false );
                return false;
            }
        }

        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "gripsample at P16: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }

        TwistRelease( );
		SetPickerSample( 0, 0, 0, false );
		SetTongSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
		SetSampleState ( SAMPLE_ON_TONG );
		UpdateSampleStatus( "on tong", true );
	}
	else if ( GetCurrentPoint ( )  == P92 )
	{
		if (!OpenGripper ( ))
        {
            MoveTongHome( );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
		m_pSPELCOM->Move ( (COleVariant)"P90" );
		SetCurrentPoint ( P90 );
	    if (!CloseGripper( ))
        {
            if (!OpenGripper( ))
            {
                SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
		        SetMotorsOn( false );
                return false;
            }
		    m_pSPELCOM->Move( (COleVariant)"P92" );
		    SetCurrentPoint( P92 );
            MoveTongHome( );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			if (m_pEventListener)
			{
				strcpy( m_ErrorMessageForOldFunction, "gripper cannot close at beamline tool post, mayby calibration is off" );
	            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
	            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
	        SetMotorsOn( false );
            return false;
        }
        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "gripsample at P90: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }
        TwistRelease( );
		SetTongSample( 'b', 0, 'T', false );
		SetSampleState ( SAMPLE_ON_TONG );
		UpdateSampleStatus( "on tong", true );
	}
    return true;
}

bool RobotEpson::ReleaseSample ( void )
{
    UpdateSampleStatus( "release sample" );
	setRobotSpeed( SPEED_IN_LN2 );

	if ( GetCurrentPoint ( ) == P22 )
	{
			
		m_pSPELCOM->Move ( (COleVariant)"P24" );
		SetCurrentPoint ( P24 );		
		m_pSPELCOM->Move ( (COleVariant)"P21" );
		SetCurrentPoint ( P21 );
        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "releas esample at P21: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }
		if (!OpenGripper ( ))
        {
            TwistRelease ( );

			m_pSPELCOM->Move ( (COleVariant)"P22" );
		    SetCurrentPoint ( P22 );
            MoveFromGoniometerToPlacer( );
            strcpy( m_ErrorMessageForOldFunction, "Opening gripper failed at goniometer to release sample" );
		    LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
		SetSampleState( SAMPLE_ON_GONIOMETER );
		SetTongSample( 0, 0, 0, false ); //clear what's in tong
        SetGonioSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn );

		if (m_tongConflict)
		{
			//back off from gonometer
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(%.3f) +Y(%.3f)",
				CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.cosValue,
				CONFLICT_GONIOMETER_BACKOFF_DISTANCE * m_goniometerDirScale.sinValue );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
		}
		m_pSPELCOM->Move ( (COleVariant)"P23" );
		SetCurrentPoint ( P23 );

		//move closer to robot to avoid directly above sample and disturbing the air
		{
			//move away from gonometer by 40 mm while raise to P22
			char cmd[1024] = {0};
			sprintf( cmd, "P22 +X(%3f) +Y(%.3f)",
				40.0f * m_goniometerDirScale.cosValue,
				40.0f * m_goniometerDirScale.sinValue );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
		}
		SetCurrentPoint ( P22 );
		CloseGripper ( );//ignore the error here, it will go back to home
	}
	else if ( GetCurrentPoint ( ) == P17 )
	{
		m_pSPELCOM->Move ( (COleVariant)"P16" );
		SetCurrentPoint ( P16 );
        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "releas esample at P16: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }
		if (!OpenGripper ( ))
        {
		    m_pSPELCOM->Move ( (COleVariant)"P17" );
		    SetCurrentPoint ( P17 );
            strcpy( m_ErrorMessageForOldFunction, "Opening gripper failed at picker to release sample" );
		    LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }

		SetTongSample( 0, 0, 0, false );
        SetPickerSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
		SetSampleState ( SAMPLE_ON_PICKER );

        UpdateSampleStatus( "on picker", true );
  		m_pSPELCOM->Arc( (COleVariant)"P15", (COleVariant)"P93 +U(90) CP" );
  		m_pSPELCOM->Move( (COleVariant)"P3" );
	    SetCurrentPoint( P3 );
	}
	else if ( GetCurrentPoint ( ) == P27 )
	{
		m_pSPELCOM->Move ( (COleVariant)"P26" );
		SetCurrentPoint ( P26 );
        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "releas esample at P26: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }
		if (!OpenGripper ( ))
        {
		    m_pSPELCOM->Move ( (COleVariant)"P27" );
		    SetCurrentPoint ( P27 );
            strcpy( m_ErrorMessageForOldFunction, "Opening gripper failed at placer to release sample" );
		    LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
		SetTongSample( 0, 0, 0, false );
        SetPlacerSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
		SetSampleState ( SAMPLE_ON_PLACER );
        UpdateSampleStatus( "on placer", true );
		m_pSPELCOM->Arc( (COleVariant)"P25", (COleVariant)"P94 CP" );
		m_pSPELCOM->Move( (COleVariant)"P3" );
		SetCurrentPoint ( P3 );
	}
	else if ( GetCurrentPoint ( ) == P91 )
	{
		m_pSPELCOM->Move ( (COleVariant)"P90" );
		SetCurrentPoint ( P90 );
        if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
        {
		    float forces[6] = {0};
		    ReadForces( forces );
		    char log_message[256] = {0};
		    sprintf( log_message, "release esample at P90: FZ: %f, TX: %f, TY: %f, TZ: %f",
			    forces[2], forces[3], forces[4], forces[5] );
		    LOG_FINEST( log_message );
        }
		if (!OpenGripper ( ))
        {
		    m_pSPELCOM->Move ( (COleVariant)"P91" );
		    SetCurrentPoint ( P91 );
            strcpy( m_ErrorMessageForOldFunction, "Opening gripper failed at beamtool to release sample" );
		    LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
	        SetMotorsOn( false );
            return false;
        }
		SetTongSample( 0, 0, 0, false );
		SetSampleState ( NO_CURRENT_SAMPLE );
		m_pSPELCOM->Move ( (COleVariant)"P92" );
		SetCurrentPoint ( P92 );
	}
    return true;
}

RobotEpson::PortForceStatus RobotEpson::MoveIntoPort( float& portError )
{
	PortForceStatus result = PORT_FORCE_OK;
	bool force_sensor_ok = false;
	PointCoordinate point;
	CCassette& theCassette = GetCassette( m_pState->currentCassette );

	theCassette.GetPortPoint( m_pState->currentRow, m_pState->currentColumn, point );
	assignPoint( P53, point );

    if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ) ||
		getAttributeFieldBool( ATTRIB_PROBE_PORT ) || m_inCmdProbing)
	{
	    RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
		force_sensor_ok = ForceCalibrate( );
	}

	m_pSPELCOM->Move ( (COleVariant)"P53" );
	SetCurrentPoint ( P53 );

	if (!force_sensor_ok)
	{
		//ignore force sensor
		return PORT_FORCE_OK;
	}

	//read force
	float currentForce;
    if (getAttributeFieldBool( ATTRIB_COLLECT_FORCE ))
	{
		float forces[6] = {0};
		ReadForces( forces );
		char log_message[256] = {0};
		sprintf( log_message, "force at port: FZ: %f, TX: %f, TY: %f, TZ: %f",
			forces[2], forces[3], forces[4], forces[5] );
		LOG_FINEST( log_message );

		currentForce = forces[3];
		LOG_FINEST1( "port force = %f", currentForce );
	}
	else
	{
		currentForce = ReadForce(FORCE_XTORQUE);
		LOG_FINEST1( "port force = %f", currentForce );
	}

	if (getAttributeFieldBool( ATTRIB_PROBE_PORT ) || m_inCmdProbing)
	{
		float distanceFromForce = fabsf( currentForce / m_TQScale );
		portError = distanceFromForce - theCassette.GetDetachDistance( );
		if (distanceFromForce < THRESHOLD_PORTCHECK)
		{
		    portError = PORT_ERROR_EMPTY;
			result = PORT_FORCE_TOO_SMALL;
		}
		else if (portError > THRESHOLD_PORTJAM)
		{
			//log raw force and read again
			LogRawForces( );

			char warning[1024] = {0};

			sprintf( warning, "may be port jam (force=%f), reading force again", currentForce );

			LOG_WARNING( warning );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, warning );
			}
			RobotWait( 3000 );
			currentForce = ReadForce(FORCE_XTORQUE);
			sprintf( warning, "second time reading port force = %f", currentForce );
			LOG_FINEST( warning );
			LogRawForces( );
			distanceFromForce = fabsf( currentForce / m_TQScale );
			portError = distanceFromForce - theCassette.GetDetachDistance( );
			if (portError > THRESHOLD_PORTJAM)
			{
				result = PORT_FORCE_TOO_BIG;
			}//second time force still big
			else
			{
				LOG_INFO( "second time force reading is within the range" );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "second time force reading is within the range" );
				}
			}
		}
	}
	return result;
}

void RobotEpson::UpdatePinLost( void )
{
	char warning[1024] = {0};
	sprintf( warning, "lost pin for port %c%c%i", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );

	//adjust counters
	++(m_pState->num_pin_lost);
	++(m_pState->num_pin_lost_short_trip);
	FlushViewOfFile( m_pState, 0 );

	//update string
	if (m_pEventListener)
	{
		char strNumber[32] = {0};
		sprintf( strNumber, "%d", m_pState->num_pin_lost_short_trip );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINLOST, strNumber );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, warning );
	}

	unsigned long pin_lost_threshold = (unsigned long)getAttributeFieldInt( ATTRIB_PIN_LOST_THRESHOLD );
	if (pin_lost_threshold > 0 && m_pState->num_pin_lost_short_trip >= pin_lost_threshold)
	{
		//flag the screening to stop
		SetRobotFlags( FLAG_REASON_PIN_LOST );
	}
	LOG_WARNING( warning );
	m_Warning = true;
}

bool RobotEpson::ConfirmBigForce( float portError )
{
	bool result = false;

	RobotWait( 3000 );
	float standby_force = ReadForce(FORCE_XTORQUE);
	LOG_FINEST1( "standby force = %f", standby_force );
	LogRawForces( );
	float resident = fabsf( standby_force / m_TQScale );
	if ((portError - resident) > THRESHOLD_PORTJAM)
	{
		LOG_WARNING( "port force really is big, port jam confirmed" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, "port force really is big, jam confirmed" );
		}
		result = true;
	}
	else
	{
		LOG_INFO( "force diff not so big" );
		result = false;
	}

	return result;
}

CSamplePort::State RobotEpson::PutSampleIntoPort( void )
{
	CSamplePort::State result = CSamplePort::PORT_UNKNOWN;

	short tl = m_pSPELCOM->GetTool( );

    float portError = PORT_ERROR_EMPTY;
	CCassette& theCassette = GetCassette( m_pState->currentCassette );

	//move dumbbell into port and read forces
	PortForceStatus currentPortForceStatus = MoveIntoPort( portError );
	theCassette.setPortForce( m_pState->currentRow, m_pState->currentColumn, portError );
	updateForces( );

	//any case: just twist off and move to port standby position
	TwistOffMagnet( );
	m_pSPELCOM->Move ( (COleVariant)"P52" );
	SetCurrentPoint ( P52 );

	//check standby force if port force is too big
	if (currentPortForceStatus == PORT_FORCE_TOO_BIG && !ConfirmBigForce( portError ))
	{
		currentPortForceStatus = PORT_FORCE_OK;
	}

	//deal with port force status
	switch (currentPortForceStatus)
	{
	case PORT_FORCE_OK:
		result = CSamplePort::PORT_SAMPLE_IN;
		theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
	    UpdateCassetteStatus( );
		break;
		
	case PORT_FORCE_TOO_SMALL:
		UpdatePinLost( );
		result =  CSamplePort::PORT_EMPTY;
		theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
	    UpdateCassetteStatus( );
        UpdateSampleStatus( "pin lost", true );
		break;

	default:
		UpdateSampleStatus( "port jam", true );
		result = CSamplePort::PORT_JAM;
		theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
	    UpdateCassetteStatus( );

		//sample may still be on dumbbell
		switch (tl)
		{
		case 2:
			SetSampleState( SAMPLE_ON_PLACER );
			break;

		case 1:
			SetSampleState( SAMPLE_ON_PICKER );
			break;

		default:
			;
		}

		if (m_pEventListener)
		{
			char warning[1024] = {0};
			sprintf( warning, "port jam in putting crystal into %c%c%d", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, warning );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, warning );
		}
		if (!m_stripperInstalled || !StripDumbbell( ))
		{
			m_ErrorMessageForOldFunction[0] = '\0';
			char message[1024] = {0};
			sprintf( message, "port jam in putting crystal into %c%c%d", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
			//this will trigger reset
			SetRobotFlags( FLAG_REASON_PORT_JAM );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, message );
				if (!(GetRobotFlags( ) & FLAG_NEED_USER_ACTION))
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "please check whether pin is on dumbbell placer side" );
				}
			}

			m_Dewar.TurnOffHeater( true );

			//move robot home
			//MoveFromPortToPost( );
			//PutMagnet ( );
			//MoveTongHome( );
			SetMotorsOn( false );
			throw new RobotException( message );
		}
	}

	SetSampleState( NO_CURRENT_SAMPLE );
	switch (tl)
	{
	case 2:
		SetPlacerSample( 0, 0, 0 );
		break;

	case 1:
		SetPickerSample( 0, 0, 0 );
		break;

	default:
		;
	}
	return result;
}

CSamplePort::State RobotEpson::GetSampleFromPort( void )
{
	CSamplePort::State result = CSamplePort::PORT_UNKNOWN;

    UpdateSampleStatus( "get sample from port" );

	float portError = PORT_ERROR_EMPTY;
	CCassette& theCassette = GetCassette( m_pState->currentCassette );

	//move dumbbell into port and read forces
	PortForceStatus currentPortForceStatus = MoveIntoPort( portError );
	theCassette.setPortForce( m_pState->currentRow, m_pState->currentColumn, portError );
	updateForces( );

	//deal with port force status
	switch (currentPortForceStatus)
	{
	case PORT_FORCE_OK:
		m_pSPELCOM->Move ( (COleVariant)"P52" );
		SetCurrentPoint ( P52 );

        SetPickerSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
		SetSampleState( SAMPLE_ON_PICKER );
        UpdateSampleStatus( "on picker", true );
		result = CSamplePort::PORT_EMPTY;
   		theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
		UpdateCassetteStatus( );
		break;
		
	case PORT_FORCE_TOO_SMALL:
		TwistOffMagnet( );
		m_pSPELCOM->Move ( (COleVariant)"P52" );
		SetCurrentPoint ( P52 );
		{
			char warning[1024] = {0};
			sprintf( warning, "port %c%c%i empty in mounting", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, warning );
			}
			result = CSamplePort::PORT_EMPTY;
   			theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
			UpdateCassetteStatus( );
			LOG_WARNING( warning );
		}
		m_Warning = true;
		break;
		
	default:
		TwistOffMagnet( );
		m_pSPELCOM->Move ( (COleVariant)"P52" );
		SetCurrentPoint ( P52 );
		//do further check
		if (ConfirmBigForce( portError ))
		{
			result = CSamplePort::PORT_JAM;
			UpdateSampleStatus( "port jam", true );
   			theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
			UpdateCassetteStatus( );
			if (m_pEventListener)
			{
				char warning[1024] = {0};
				sprintf( warning, "port jam at %c%c%d or cassette sit not right", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, warning );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, warning );
			}
			if (!m_stripperInstalled || !StripDumbbell( ))
			{
				m_ErrorMessageForOldFunction[0] = '\0';
				char message[1024] = {0};
				sprintf( message, "port jam at %c%c%d or cassette sit not right", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
				//sample may be on picker
		        SetPickerSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
				SetSampleState( SAMPLE_ON_PICKER );

				//here will trigger need reset because the robot is not at home yet.
				SetRobotFlags( FLAG_REASON_PORT_JAM );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, message );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "please check whether pin is on dumbbell picker side" );
				}

				m_Dewar.TurnOffHeater( true );

				//move robot home
				//MoveFromPortToPost( );
				//PutMagnet ( );
				//MoveTongHome( );
				SetMotorsOn( false );
				throw new RobotException( message );
			}
		}
		else
		{
			LOG_INFO( "re-fetch sample" );
			m_pSPELCOM->Move ( (COleVariant)"P53" );
			SetCurrentPoint ( P53 );
			m_pSPELCOM->Move ( (COleVariant)"P52" );
			SetCurrentPoint ( P52 );

	        SetPickerSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn, false );
			SetSampleState( SAMPLE_ON_PICKER );
			UpdateSampleStatus( "on picker", true );
			result = CSamplePort::PORT_EMPTY;
   			theCassette.SetPortState( m_pState->currentRow, m_pState->currentColumn, result );
			UpdateCassetteStatus( );
		}//not confirmed 
	}//switch
	return result;
}

void RobotEpson::TwistRelease ( )
{
	if (m_tongConflict && GetCurrentPoint( ) == P21)
	{
		if (SetupTemperaryToolSet( P13 ))
		{
			m_pSPELCOM->Tool( 3 );
			m_pSPELCOM->Go( COleVariant("P* -U(45)") );
			const float PI = 3.14159265359f;
			float angleInRad = m_pSPELCOM->CU( COleVariant( "P*" ) ) /180.0f * PI;
			float dx = -10.0f * cosf( angleInRad );
			float dy = -10.0f * sinf( angleInRad );
			char command[200] = {0};
			sprintf( command, "P* +X(%.3f) +Y(%.3f)", dx, dy);
			COleVariant VAcmd( command );
			m_pSPELCOM->Move( VAcmd );
			m_pSPELCOM->Tool( 0 );
		}
		else
		{
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "twist off toolset setup failed" );
			}
			SetRobotFlags( FLAG_NEED_RESET | FLAG_NEED_CAL_MAGNET | FLAG_REASON_INIT );
			SetMotorsOn( false );
			throw new RobotException( "twist off toolset setup failed" );
		}
	}
	else
	{
		if (SetupTemperaryToolSet( P12 ))
		{
			m_pSPELCOM->Tool( 3 );
			m_pSPELCOM->Go( COleVariant("P* +U(45)") );
			const float PI = 3.14159265359f;
			float angleInRad = m_pSPELCOM->CU( COleVariant( "P*" ) ) /180.0f * PI;
			float dx = -10.0f * cosf( angleInRad );
			float dy = -10.0f * sinf( angleInRad );
			char command[200] = {0};
			sprintf( command, "P* +X(%.3f) +Y(%.3f)", dx, dy);
			COleVariant VAcmd( command );
			m_pSPELCOM->Move( VAcmd );
			m_pSPELCOM->Tool( 0 );
		}
		else
		{
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "twist off toolset setup failed" );
			}
			SetRobotFlags( FLAG_NEED_RESET | FLAG_NEED_CAL_MAGNET | FLAG_REASON_INIT );
			SetMotorsOn( false );		
			throw new RobotException( "twist off toolset setup failed" );
		}
	}
}

void RobotEpson::SetDerivedLPoint ( LPoint pDerived, LPoint p,
                                   float dx, float dy, float dz, float du,
								   bool direct_x, bool direct_y, bool direct_z, bool direct_u )
{
	PointCoordinate point;
	retrievePoint( p, point );
#ifndef MIXED_ARM_ORIENTATION
	if (point.o != m_armOrientation)
	{
		char message[1024] = {0};
		sprintf( message, "point %hi orientation wrong", p );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, message );
			SetRobotFlags( FLAG_NEED_CAL_BASIC | FLAG_REASON_INIT );
			return;
		}

	}
#endif

    point.x += dx;
    point.y += dy;
    point.z += dz;
    point.u += du;

	if (direct_x) point.x = dx;
	if (direct_y) point.y = dy;
	if (direct_z) point.z = dz;
	if (direct_u) point.u = du;

	this->assignPoint( pDerived, point );
}


bool RobotEpson::OKToMount( char cassette, short row, char column, char status_buffer[] )
{
    //check position range
    if (!PositionIsValid( cassette, row, column ))
    {
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd mount: invalid position", cassette, column, row );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "invalid position" );
	    //SetRobotFlags( FLAG_REASON_BAD_ARG );
        return false;
    }

    //check robot status
	if (GetRobotFlags( ))
	{
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd mount: Robot Status", cassette, column, row );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "Robot Status Not ready" );
		return false;
	}

    //check sample state
    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
        break;
    case SAMPLE_ON_GONIOMETER:  //this one only set need clear
    case SAMPLE_ON_TONG:        //these one set need reset
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    default:
        {
            char sampleStatus[256] = {0};
	        sprintf( sampleStatus, "%c%c%hd mount: sample state wrong", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
        }
        strcpy( status_buffer, "sample state wrong: already has " );
        strcat( status_buffer, GetSampleStateString( ) );
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
		return false;
    }

    //check cassette status
    CCassette& theCassette  = GetCassette( cassette );
    switch (theCassette.GetStatus( ))
    {
    case CCassette::CASSETTE_ABSENT:
        {
            char sampleStatus[256] = {0};
	        sprintf( sampleStatus, "%c%c%hd mount: cassette absent", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
        }

        strcpy( status_buffer, "cassette absent" );
	    //SetRobotFlags( FLAG_REASON_CASSETTE );
        return false;

    case CCassette::CASSETTE_UNKOWN:
        theCassette.SetNeedProbe( true );
    case CCassette::CASSETTE_PRESENT:
    default:
        break;
    }

    //check port status
    switch (theCassette.GetPortState( row, column ))
    {
	case CSamplePort::PORT_MOUNTED:
		sprintf( status_buffer, "%c%c%hd already mounted", cassette, column, row );
		UpdateSampleStatus( status_buffer );
		return false;

	case CSamplePort::PORT_EMPTY:
		{
			char sampleStatus[256] = {0};
			sprintf( sampleStatus, "%c%c%hd empty port", cassette, column, row );
			UpdateSampleStatus( sampleStatus );
			strcpy( status_buffer, "normal n 0 N empty port" );
		}
		return false;

	case CSamplePort::PORT_JAM:
		sprintf( status_buffer, "%c%c%hd previous port jam", cassette, column, row );
		UpdateSampleStatus( status_buffer );
		return false;

	case CSamplePort::PORT_BAD:
		sprintf( status_buffer, "%c%c%hd previous port bad", cassette, column, row );
		UpdateSampleStatus( status_buffer );
		return false;

	case CSamplePort::PORT_SAMPLE_IN:
	case CSamplePort::PORT_UNKNOWN:
	default:
		break;
	}

    //OK
    return true;
}

bool RobotEpson::OKToDismount( char cassette, short row, char column, char status_buffer[] )
{
    //check position range
    if (!PositionIsValid( cassette, row, column ))
    {
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd dismount: invalid position", cassette, column, row );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "invalid position" );
	    //SetRobotFlags( FLAG_REASON_BAD_ARG );
        return false;
    }

    //check robot status
	if (GetRobotFlags( ))
	{
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd dismount: check failed Robot Status", cassette, column, row );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "Robot Status Not ready" );
		return false;
	}

    //check sample state
    switch (GetSampleState( ))
    {
    case SAMPLE_ON_GONIOMETER:
        if (getAttributeFieldBool( ATTRIB_STRICT_DISMOUNT) &&
            (cassette != m_pState->mounted_cassette ||
                row != m_pState->mounted_row ||
                column != m_pState->mounted_column))
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd dismount: check failed only strict dismount is ON", cassette, column, row );
            UpdateSampleStatus( sampleStatus );

            strcpy( status_buffer, "Mismatch with mounted crystal" );
		    return false;
        }
        break;

    case NO_CURRENT_SAMPLE:
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd: nothing on goniometer", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, "nothing on goniometer skip dismount" );
			}
        }
        strcpy( status_buffer, "normal n 0 N nothing on goniometer" );
		return false;

    case SAMPLE_ON_TONG:    //need reset
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd dismount: check failed, sample state wrong", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
        }
		return false;
    }


    //check cassette status
    CCassette& theCassette  = GetCassette( cassette );
    switch (theCassette.GetStatus( ))
    {
    case CCassette::CASSETTE_ABSENT:
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd dismount: check failed, cassette absent", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
        }

        strcpy( status_buffer, "cassette absent" );
	    //SetRobotFlags( FLAG_REASON_CASSETTE );
        return false;

    case CCassette::CASSETTE_PRESENT:
        //check port status
        switch (theCassette.GetPortState( row, column ))
        {
        case CSamplePort::PORT_MOUNTED:
        case CSamplePort::PORT_EMPTY:
            break;

        case CSamplePort::PORT_SAMPLE_IN:
            {
                char sampleStatus[256] = {0};
                sprintf( sampleStatus, "%c%c%hd dismount: check failed, already has sample in", cassette, column, row );
                UpdateSampleStatus( sampleStatus );
            }

            strcpy( status_buffer, "port already has sample in it" );
            SetRobotFlags( FLAG_REASON_SAMPLE_IN_PORT );
            return false;

		case CSamplePort::PORT_JAM:
			sprintf( status_buffer, "%c%c%hd previous port jam", cassette, column, row );
			UpdateSampleStatus( status_buffer );
			return false;

		case CSamplePort::PORT_BAD:
			sprintf( status_buffer, "%c%c%hd previous port bad", cassette, column, row );
			UpdateSampleStatus( status_buffer );
			return false;

        case CSamplePort::PORT_UNKNOWN:
        default:
            theCassette.SetPortNeedProbe( row, column );
        }
        break;

    case CCassette::CASSETTE_UNKOWN:
    default:
        theCassette.SetNeedProbe( true );
        theCassette.SetPortNeedProbe( row, column );
    }

    //OK
    return true;
}

//changed to allow dismount and mount the same port
bool RobotEpson::OKToMountNext( char dism_cassette, short dism_row, char dism_column,
                                char mnt_cassette,  short mnt_row,  char mnt_column, char status_buffer[] )
{
	if (!PositionIsValid( dism_cassette, dism_row, dism_column ))
	{
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd mountnext: check failed, invalid dismount position", dism_cassette, dism_column, dism_row );
        UpdateSampleStatus( sampleStatus );

	    strcpy( status_buffer, "dismount position not valid" );
	    //SetRobotFlags( FLAG_REASON_BAD_ARG );
        return false;
	}
	if (!PositionIsValid( mnt_cassette, mnt_row, mnt_column ))
	{
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%%chd mountnext: check failed, invalid mount position", mnt_cassette, mnt_column, mnt_row );
        UpdateSampleStatus( sampleStatus );
	    strcat( status_buffer, "mount position invalid" );
	    //SetRobotFlags( FLAG_REASON_BAD_ARG );
        return false;
	}

    status_buffer[0] = '\0';

    //check robot status
	if (GetRobotFlags( ))
	{
        char sampleStatus[256] = {0};
        sprintf( sampleStatus, "%c%c%hd mountnext: check failed: Robot Status", dism_cassette, dism_column, dism_row );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "Robot Status Not ready" );
		return false;
	}

	m_MountNextTask = MOUNT_NEXT_FULL;
    //check sample state
	switch (GetSampleState( ))
	{
	case SAMPLE_ON_GONIOMETER:
        if (getAttributeFieldBool( ATTRIB_STRICT_DISMOUNT ) &&
            (dism_cassette != m_pState->mounted_cassette ||
                dism_row != m_pState->mounted_row ||
                dism_column != m_pState->mounted_column))
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd dismount: check failed only strict dismount is ON", dism_cassette, dism_column, dism_row );
            UpdateSampleStatus( sampleStatus );

            strcpy( status_buffer, "Mismatch with mounted crystal" );
		    return false;
        }
        break;

	case NO_CURRENT_SAMPLE:
		if (dism_cassette != mnt_cassette ||
			dism_row      != mnt_row ||
			dism_column   != mnt_column)
		{
			m_MountNextTask  = MOUNT_NEXT_MOUNT; //clear dismout bit
		}
		else
		{
			m_MountNextTask  = 0;
		}
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
	default:
        {
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd mountnext: check failed, wrong sample state", dism_cassette, dism_column, dism_row );
            UpdateSampleStatus( sampleStatus );
        }
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
		return false;
    }

	if (m_MountNextTask & MOUNT_NEXT_DISMOUNT)
	{
	    CCassette& DismCassette  = GetCassette( dism_cassette );
        switch (DismCassette.GetStatus( ))
        {
        case CCassette::CASSETTE_ABSENT:
            {
                char sampleStatus[256] = {0};
                sprintf( sampleStatus, "%c%c%hd mountnext: check failed, dismounting cassette absent", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( sampleStatus );
            }
            strcpy( status_buffer, "dismount cassette absent" );
	        //SetRobotFlags( FLAG_REASON_CASSETTE );
            return false;

        case CCassette::CASSETTE_PRESENT:
            //check port status
            switch (DismCassette.GetPortState( dism_row, dism_column ))
            {
            case CSamplePort::PORT_EMPTY:
	        case CSamplePort::PORT_MOUNTED:
                break;

            case CSamplePort::PORT_SAMPLE_IN:
                {
                    char sampleStatus[256] = {0};
                    sprintf( sampleStatus, "%c%c%hd mountnext: check failed, port already has sample in", dism_cassette, dism_column, dism_row );
                    UpdateSampleStatus( sampleStatus );
                }
	            strcpy( status_buffer, "dismount port already has sample in" );
                SetRobotFlags( FLAG_REASON_SAMPLE_IN_PORT );
			    return false;

            case CSamplePort::PORT_JAM:
                sprintf( status_buffer, "%c%c%hd previous port jam", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( status_buffer );
			    return false;

            case CSamplePort::PORT_BAD:
                sprintf( status_buffer, "%c%c%hd previous port bad", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( status_buffer );
			    return false;

            case CSamplePort::PORT_UNKNOWN:
            default:
                DismCassette.SetPortNeedProbe( dism_row, dism_column );
            }//switch (DismCassette.GetPortState( dism_row, dism_column ))
            break;

        case CCassette::CASSETTE_UNKOWN:
        default:
            DismCassette.SetNeedProbe( true );
            DismCassette.SetPortNeedProbe( dism_row, dism_column );
        }//switch (DismCassette.GetStatus( ))
   	}

	if (m_MountNextTask & MOUNT_NEXT_MOUNT)
	{
		//check cassette status
		CCassette& MntCassette  = GetCassette( mnt_cassette );

		switch (MntCassette.GetStatus( ))
        {
        case CCassette::CASSETTE_ABSENT:
            {
                char sampleStatus[256] = {0};
                sprintf( sampleStatus, "%c%c%hd mountnext: check failed, mounting cassette absent", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( sampleStatus );
            }
            strcpy( status_buffer, "mount cassette absent" );
	        //SetRobotFlags( FLAG_REASON_CASSETTE );
            return false;

        case CCassette::CASSETTE_PRESENT:
            //check port status
            switch (MntCassette.GetPortState( mnt_row, mnt_column ))
            {
            case CSamplePort::PORT_JAM:
				sprintf( status_buffer, "%c%c%hd previous port jam", mnt_cassette, mnt_column, mnt_row );
                UpdateSampleStatus( status_buffer );
				return false;

            case CSamplePort::PORT_BAD:
				sprintf( status_buffer, "%c%c%hd previous port bad", mnt_cassette, mnt_column, mnt_row );
                UpdateSampleStatus( status_buffer );
				return false;

            case CSamplePort::PORT_EMPTY:
				if (dism_cassette != mnt_cassette ||
					dism_row      != mnt_row ||
					dism_column   != mnt_column)
				{
    				m_MountNextTask &= ~MOUNT_NEXT_MOUNT;
				}
			    break;

	        case CSamplePort::PORT_MOUNTED:
            case CSamplePort::PORT_SAMPLE_IN:
            case CSamplePort::PORT_UNKNOWN:
            default:
                break;
            }
            break;

        case CCassette::CASSETTE_UNKOWN:
        default:
            MntCassette.SetNeedProbe( true );
		}
	}
    //OK
    if (m_MountNextTask == 0)
    {
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, "nothing on goniometer and empty port skip whole mountNext" );
		}
        strcpy( status_buffer, "normal n 0 N normal n 0 N nothing on gonio and empty port" );
        return false;
    }
    else
    {
		if (m_pEventListener)
		{
			if (!(m_MountNextTask & MOUNT_NEXT_MOUNT))
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, "port empty skip mount part of mountNext" );
			}
			if (!(m_MountNextTask & MOUNT_NEXT_DISMOUNT))
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, "nothing on goniometer skip dismount part of mountNext" );
			}
		}
        return true;
    }
}

bool RobotEpson::OKToMove( const char argument[], char status_buffer[] )
{

	//reset port future status
	m_LeftCassette.ResetPortFutureState( );
	m_MiddleCassette.ResetPortFutureState( );
	m_RightCassette.ResetPortFutureState( );

    char  source_cassette;
    char  source_column;
    short source_row;

    char  target_cassette;
    char  target_column;
    short target_row;

    const char* pRemainArgument = argument;

	//check input
	if (pRemainArgument == NULL || pRemainArgument[0] == '\0')
	{
        strcpy( status_buffer, "move list empty" );
        UpdateSampleStatus( status_buffer );
		return false;
	}

    //check robot status
	if (GetRobotFlags( ))
	{
        UpdateSampleStatus( "Robot not Ready" );

        strcpy( status_buffer, "Robot Status Not ready" );
		return false;
	}

    //check sample state
	switch (GetSampleState( ))
	{
	case NO_CURRENT_SAMPLE:
        break;

	case SAMPLE_ON_GONIOMETER:
    case SAMPLE_ON_TONG:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
	default:
        UpdateSampleStatus( "move: check failed, wrong sample state" );
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
		return false;
    }

	//check positions
    while (ProcessMoveArgument( pRemainArgument,
        source_cassette, source_column, source_row,
        target_cassette, target_column, target_row ))
    {
        //check position range
        if (!PositionIsValid( source_cassette, source_row, source_column ))
        {

            sprintf( status_buffer ,"%c%c%hi->%c%c%hi invalid origin address",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;
        }
        if (!PositionIsValid( target_cassette, target_row, target_column ))
        {
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi invalid destination address",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;
        }

        //check cassette status
        CCassette& sourceCassette = GetCassette( source_cassette );
        CCassette& targetCassette = GetCassette( target_cassette );
        switch (sourceCassette.GetStatus( ))
        {
        case CCassette::CASSETTE_ABSENT:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin cassette absent",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;

        case CCassette::CASSETTE_PROBLEM:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin cassette problem",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;

        case CCassette::CASSETTE_PRESENT:
            break;

        case CCassette::CASSETTE_UNKOWN:
        default:
            sourceCassette.SetNeedProbe( true );
        }

        switch (targetCassette.GetStatus( ))
        {
        case CCassette::CASSETTE_ABSENT:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination cassette absent",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;
        case CCassette::CASSETTE_PROBLEM:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination cassette problem",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;


        case CCassette::CASSETTE_PRESENT:
            break;

        case CCassette::CASSETTE_UNKOWN:
        default:
            targetCassette.SetNeedProbe( true );
        }

		//check port status
		switch (sourceCassette.GetPortFutureState( source_row, source_column ))
		{
		case CSamplePort::PORT_EMPTY:
		case CSamplePort::PORT_MOUNTED:
			switch (sourceCassette.GetPortState( source_row, source_column ))
			{
			case CSamplePort::PORT_EMPTY:
			case CSamplePort::PORT_MOUNTED:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin port empty",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
				break;

			default:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin port double booked",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
			}
			UpdateSampleStatus( status_buffer );
            return false;

		case CSamplePort::PORT_JAM:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin port jam",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;

		case CSamplePort::PORT_BAD:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin port bad",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;

		case CSamplePort::PORT_NOT_EXIST:
            sprintf( status_buffer ,"%c%c%hi->%c%c%hi origin port not exist",
                source_cassette, source_column, source_row,
                target_cassette, target_column, target_row );
            UpdateSampleStatus( status_buffer );
            return false;

        case CSamplePort::PORT_UNKNOWN:
        default:
            sourceCassette.SetPortNeedProbe( source_row, source_column );
            break;
		}
        if (source_cassette != target_cassette || source_column != target_column || source_row != target_row)
        {
            switch (targetCassette.GetPortFutureState( target_row, target_column ))
            {
            case CSamplePort::PORT_EMPTY:
                break;

            case CSamplePort::PORT_MOUNTED:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port empty but mounted",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
				UpdateSampleStatus( status_buffer );
				return false;

			case CSamplePort::PORT_SAMPLE_IN:
				if (targetCassette.GetPortState( target_row, target_column ) == CSamplePort::PORT_SAMPLE_IN)
				{
					sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port sample in",
						source_cassette, source_column, source_row,
						target_cassette, target_column, target_row );
				}
				else
				{
					sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port double booked",
						source_cassette, source_column, source_row,
						target_cassette, target_column, target_row );
				}
				UpdateSampleStatus( status_buffer );
				return false;

            case CSamplePort::PORT_JAM:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port jam",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
				UpdateSampleStatus( status_buffer );
				return false;

            case CSamplePort::PORT_BAD:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port bad",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
				UpdateSampleStatus( status_buffer );
				return false;

			case CSamplePort::PORT_NOT_EXIST:
				sprintf( status_buffer ,"%c%c%hi->%c%c%hi destination port not exist",
					source_cassette, source_column, source_row,
					target_cassette, target_column, target_row );
				UpdateSampleStatus( status_buffer );
				return false;

            case CSamplePort::PORT_UNKNOWN:
            default:
                targetCassette.SetPortNeedProbe( target_row, target_column );
                break;
			}
        }
        //simulate moving
        sourceCassette.SetPortFutureState( source_row, source_column, CSamplePort::PORT_EMPTY );
        targetCassette.SetPortFutureState( target_row, target_column, CSamplePort::PORT_SAMPLE_IN );

		if (m_pEventListener)
		{
			sprintf( status_buffer ,"%c%c%hi->%c%c%hi check OK",
				source_cassette, source_column, source_row,
				target_cassette, target_column, target_row );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, status_buffer );
		}
    }
	if (pRemainArgument[0] != '\0')
	{
        strcpy( status_buffer, "move list syntax wrong" );
        UpdateSampleStatus( status_buffer );
		return false;
	}

    //OK
    return true;
}

bool RobotEpson::OKToWash( char status_buffer[] )
{
    //check robot status
	if (GetRobotFlags( ))
	{
        char sampleStatus[256] = {0};
        strcpy( sampleStatus, "wash: check failed Robot Status" );
        UpdateSampleStatus( sampleStatus );

        strcpy( status_buffer, "Robot Status Not ready" );
		return false;
	}

    //check sample state
    switch (GetSampleState( ))
    {
    case SAMPLE_ON_GONIOMETER:
        break;

    case NO_CURRENT_SAMPLE:
        {
            char sampleStatus[256] = {0};
            strcpy( sampleStatus, "wash: nothing on goniometer" );
            UpdateSampleStatus( sampleStatus );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, "nothing on goniometer skip wash" );
			}
        }
        strcpy( status_buffer, "normal nothing on goniometer" );
		return false;

    case SAMPLE_ON_TONG:    //need reset
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
		SetRobotFlags( FLAG_REASON_WRONG_STATE );
        {
            char sampleStatus[256] = {0};
            strcpy( sampleStatus, "wash: check failed, sample state wrong" );
            UpdateSampleStatus( sampleStatus );
        }
		return false;
    }
    //OK
    return true;
}

bool RobotEpson::OKToClear( char status_buffer[] ) const
{
    //LOG_FINE( "+RobotEpson::OKToClear" );

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_GONIOMETER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    default:
        if (status_buffer)
        {
            strcpy( status_buffer, "sample state wrong: " );
            strcat( status_buffer, GetSampleStateString( ) );
        }
        //LOG_FINE( "-RobotEpson::OKToClear bad sample state" );
        return false;
    }

    if (GetDumbbellState( ) != DUMBBELL_IN_CRADLE)
    {
        if (status_buffer)
        {
            strcpy( status_buffer, "dumpbell not in cradle" );
        }
        //LOG_FINE( "-RobotEpson::OKToClear bad dumpbell state" );
        return false;
    }

    //LOG_FINE( "-RobotEpson::OKToClear Yes" );
    return true;
}
bool RobotEpson::CassetteIsValid( char cassette ) const
{
    switch (cassette)
    {
    case 'l':
    case 'm':
    case 'r':
        return true;

    default:
        return false;
    }
}

bool RobotEpson::PositionIsValid( char cassette, short row, char column ) const
{
	if (!CassetteIsValid( cassette ))
	{
		return false;
	}

    const CCassette& theCassette = GetConstCassette( cassette );

    return theCassette.PositionIsValid( row, column );
}
bool RobotEpson::PositionIsBeamlineTool( char cassette, short row, char column ) const
{
	if (cassette == 'b' && column == 'T' && row == 0)
	{
		return true;
	}
	return false;
}

void RobotEpson::RobotWait( UINT milliSeconds )
{
    if (m_pSleepEvent)
    {
        //xos_event_wait( m_pSleepEvent, milliSeconds );
		RobotDoEvent( milliSeconds, m_pSleepEvent->handle );
    }
    else
    {
		RobotDoEvent( milliSeconds );
    }
}
void RobotEpson::RobotDoEvent( UINT milliSeconds, HANDLE handle )
{
    UINT start, timeRemaining, timeNow;
    start = GetTickCount();
    timeRemaining = milliSeconds;

	DWORD handleCount = 0;
	HANDLE hArray[1] = {handle};
	HANDLE* pInputHandles = NULL;
	if (handle != NULL)
	{
		handleCount = 1;
		pInputHandles = hArray;
	}

    do {
        // Sleep until timeout or event occurs
        DWORD result = MsgWaitForMultipleObjects(handleCount, pInputHandles, 0, timeRemaining, QS_ALLINPUT);
		switch (result)
		{
		case WAIT_OBJECT_0:
			break;
		case WAIT_OBJECT_0 + 1:
			if (handleCount == 0)
			{
				LOG_FINE1( "wait multilpe got result=%lu with handle count =0", result );
			}
			break;
		case WAIT_TIMEOUT:
			return;
		case WAIT_FAILED:
			{
				DWORD ernum = ::GetLastError( );
				LOG_FINEST1( "RobotDoEvent failed with errno=%lu", ernum );
			}
			break;
		default:
			LOG_FINEST1( "default=%lu", result );
		}
        timeNow = GetTickCount();
        if (timeNow - start >= timeRemaining)
        {
			LOG_FINEST("check again got timeout");
            return;
        }
        else if (timeNow < start)
        {
            // Handle GetTickCount 49.7 day wrap around
            start = timeNow;
        }
        timeRemaining = timeRemaining - (timeNow - start);
        start = timeNow;

        MSG msg;
        long sts;
        do
        {
            if (sts = PeekMessage(&msg, (HWND) NULL, 0, 0, PM_REMOVE))
            {
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        } while (sts);

		if (result == WAIT_OBJECT_0 && handleCount != 0)
		{
			LOG_FINEST( "out of do event by signal" );
			break;
		}
    } while(1);
}

bool RobotEpson::PortPostShuttle( bool putSample, char cassette, short row, char column )
{
	short tlset = putSample ? 2 : 1;
	char sampleStatus[256] = {0};

	m_pSPELCOM->Tool( 0 );
    if (!GetMagnet( )) return false; //GetMagnet already set flags

    sprintf( sampleStatus, "move to port %c%c%hi", cassette, column, row );
	UpdateSampleStatus( sampleStatus );
	
	m_pSPELCOM->Tool( tlset );
    MoveToPortViaStandby( cassette, row, column );

    bool result = false;

	if (putSample)
	{
        sprintf( sampleStatus, "put %c%c%hi into port", cassette, column, row );
	    UpdateSampleStatus( sampleStatus );
		switch (PutSampleIntoPort( ))
		{
		case CSamplePort::PORT_SAMPLE_IN:
            UpdateSampleStatus( "dismounted", true );
			result = true;
			break;
		}
	}
	else
	{
        sprintf( sampleStatus, "get %c%c%hi from port", cassette, column, row );
	    UpdateSampleStatus( sampleStatus );
		CSamplePort::State getResult = GetSampleFromPort( );
		result = (GetSampleState( ) == SAMPLE_ON_PICKER);
	}
	if (!GetMotorsOn( ))
	{
		return false;
	}

	UpdateSampleStatus( "move away" );
	MoveFromPortToPost( );

	if (!putSample && getAttributeFieldBool( ATTRIB_WASH_BEFORE_MOUNT) && m_numCycleToWash > 0)
	{
		LOG_FINE1( "washing before mount: %lu", m_numCycleToWash );
		doWash( m_numCycleToWash );
	}

	PutMagnet( getAttributeFieldBool( ATTRIB_CHECK_POST ), getAttributeFieldBool( ATTRIB_COLLECT_FORCE ) );
    if (m_desiredLN2Level == LN2LEVEL_HIGH)
    {
        m_Dewar.TurnOnHeater( );
    }

    return result;
}

void RobotEpson::MoveTongHome( )
{
    bool need_heating = GetCurrentPoint( ) != P0;

	UpdateSampleStatus( "go home" );

    //in most of the cases, heater already turned on before calling this function.
    if (need_heating && m_desiredLN2Level == LN2LEVEL_HIGH)
    {
        m_Dewar.TurnOnHeater( );
    }

	//to support go home in the middle of moveCrystal
	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
	if (GetCurrentPoint( ) == P52 &&
        CloseToPoint( P52, currentPosition) &&
		GetDumbbellState( ) == DUMBBELL_IN_TONG &&
		m_pSPELCOM->GetTool( ) == 1)
	{
		MoveFromPortToPost( );
		PutMagnet( );
	}

    if (!MoveToHome( ))
    {
        SetRobotFlags( FLAG_REASON_ABORT );
        SetMotorsOn( false );
        return;
    }
    if (!need_heating)
	{
		UpdateSampleStatus( "done" );
		return;
	}

    if (m_desiredLN2Level == LN2LEVEL_HIGH)
    {
		if (m_pEventListener)
		{
			char msg[256] = "drying tong";
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, msg );
			UpdateSampleStatus( msg );
		}

        if (!m_Dewar.WaitHeaterHot( /* default 60 seconds */ ))
        {
            const static char msg[] = "heater failed to reach predefined temperature";
            SetRobotFlags( FLAG_REASON_HEATER_FAIL );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, msg );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, msg );
            }
			LOG_WARNING( msg );
        }
        RobotWait( 25000 ); //30 seconds
        Dance ( );
    }
    m_Dewar.TurnOffHeater( );
	UpdateSampleStatus( "done" );
}

bool RobotEpson::GoniometerToPlacer( )
{
    MoveToGoniometer( );
    if (!GripSample( ))
    {
        return false;
    }
    MoveFromGoniometerToPlacer( );
    if (!ReleaseSample( ))
    {
        //already aborted
        return false;
    }

    return true;
}

bool RobotEpson::GoniometerToPicker( )
{
    MoveToGoniometer( );
    if (!GripSample( ))
    {
        return false;
    }
    MoveFromGoniometerToPicker( );
    if (!ReleaseSample( ))
    {
        //already aborted
        return false;
    }

    return true;
}

bool RobotEpson::PickerToGoniometer( )
{
    if (!GripSample( ))
    {
        return false;
    }

    MoveToGoniometer( );

    if (!ReleaseSample( ))
    {
        return false;
    }

    //MoveFromGoniometerToRestPoint( );
    MoveFromGoniometerToDewarSide( );
    return true;
}

const char* RobotEpson::GetSampleStateString( ) const
{
    static const char noSample[] = "no current sample";
    static const char onTong[] = "sample on tong";
    static const char onPlacer[] = "sample on placer";
    static const char onPicker[] = "sample on picker";
    static const char onGonio[] = "sample on goniometer";

    switch (GetSampleState( ))
    {
    case SAMPLE_ON_TONG:
        return onTong;

    case SAMPLE_ON_PLACER:
        return onPlacer;

    case SAMPLE_ON_PICKER:
        return onPicker;

    case SAMPLE_ON_GONIOMETER:
        return onGonio;

    case NO_CURRENT_SAMPLE:
    default:
        return noSample;
    }
}

void RobotEpson::InitPoints( )
{
	PointCoordinate currentPosition;
    try
    {
		GetCurrentPosition( currentPosition );

        InitBasicPoints( );
        InitMagnetPoints( );
        InitCassettePoints( );
        InitGoniometerPoints( );
    }
	catch ( CException *e )
	{
        char errorMessage[MAX_LENGTH_STATUS_BUFFER+1] = {0};
		e->GetErrorMessage ( errorMessage,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete();
        LOG_WARNING1( "RobotEpson::Initialize %s", errorMessage );
        SetRobotFlags( FLAG_NEED_CAL_CASSETTE | FLAG_REASON_INIT );
		return;
	}

    if (CloseToPoint( P0, currentPosition ))
    {
        SetCurrentPoint( P0 );
    }
    else if (CloseToPoint( P1, currentPosition ))
    {
        SetCurrentPoint( P1 );
    }
    else
    {
        SetRobotFlags( FLAG_REASON_NOT_HOME );
    }
}

void RobotEpson::InitBasicPoints( )
{
    if (!CheckPoint( P0 ) || //home
        !CheckPoint( P1 ) || //rest point
        !CheckPoint( P18 )) //clear of bowl: opposite of P1 to dewar
    {
        SetRobotFlags( FLAG_NEED_CAL_BASIC | FLAG_REASON_INIT );
        return;
    }

	//set up arm system according to P1 and P18
	PointCoordinate Point1;
	PointCoordinate Point18;
    retrievePoint( P1, Point1 );
	retrievePoint( P18, Point18 );

	//check arm orientation
	char message[1024] = {0};
#ifdef MIXED_ARM_ORIENTATION
	if (m_pEventListener)
	{
		strcpy( message, "mixed arm orientation" );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, message );
	}
#else
	if (Point1.o == Point18.o)
	{
		m_armOrientation = Point1.o;

		switch (m_armOrientation)
		{
		case PointCoordinate::ARM_ORIENTATION_RIGHTY:
			strcpy( message, "arm orientation right" );
			break;
		case PointCoordinate::ARM_ORIENTATION_LEFTY:
			strcpy( message, "arm orientation left" );
			break;
		default:
			strcpy( message, "bad arm orientation" );
			SetRobotFlags( FLAG_NEED_CAL_BASIC | FLAG_REASON_INIT );
			break;
		}

		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
		}
	}
	else
	{
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "Conflict arm orientation between basic points P1 and P18" );
		}
		SetRobotFlags( FLAG_NEED_CAL_BASIC | FLAG_REASON_INIT );
		return;
	}
#endif
	//we retrieve beamline orientation
    CString tempString1( m_pSPELCOM->GetSPELVar( "g_Perfect_DownStream_Angle" ) );
	float downStreamAngle = 180.0f; //default
	sscanf( tempString1, "%f", &downStreamAngle );
	m_downstreamOrientation = AngleToOrientation( downStreamAngle );
	m_downstreamDirScale.cosValue = cosf( OrientationToAngle( m_downstreamOrientation ) );
	m_downstreamDirScale.sinValue = sinf( OrientationToAngle( m_downstreamOrientation ) );
	switch (m_downstreamOrientation)
	{
	case DIRECTION_X_AXIS:
		strcpy( message, "beamline down stream orientation +X AXIS" );
		break;
	case DIRECTION_Y_AXIS:
		strcpy( message, "beamline down stream orientation +Y AXIS" );
		break;
	case DIRECTION_MX_AXIS:
		strcpy( message, "beamline down stream orientation -X AXIS" );
		break;
	case DIRECTION_MY_AXIS:
		strcpy( message, "beamline down stream orientation -Y AXIS" );
	}
	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
	}
    CString tempString2( m_pSPELCOM->GetSPELVar( "g_Jump_LimZ_LN2" ) );
	sscanf( tempString2, "%f", &N2_LEVEL );
	sprintf( message, "LimZ for LN2: %.3f", N2_LEVEL );
	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, message );
	}
}

void RobotEpson::InitMagnetPoints( )
{
    if (!CheckPoint( P6 ) ||     //magnet post
        !CheckPoint( P16 ) ||    //picker
        !CheckPoint( P26 ) ||    //placer
        !CheckPoint( P10 ) ||    //toolset for picker twistoff
        !CheckPoint( P11 ) ||    //toolset for placer twistoff
        !CheckPoint( P12 ) ||    //toolset for cavity twistoff
        !CheckToolSet( pickerTool ) ||
	    !CheckToolSet( placerTool ))
    {
        SetRobotFlags( FLAG_NEED_CAL_MAGNET | FLAG_REASON_INIT );
        return;
    }

	//get u of P6 to decide orientation of bumbbell
	PointCoordinate point;
	retrievePoint( P6, point );

	m_dumbbellOrientation = AngleToOrientation( point.u );
	m_dumbbellDirScale.cosValue = cosf( OrientationToAngle( m_dumbbellOrientation ) );
	m_dumbbellDirScale.sinValue = sinf( OrientationToAngle( m_dumbbellOrientation ) );

	SetDerivedLPoint ( P4, P6,
						0, 0, 30, 0 );

	//const float PI = 3.14159265359f;
	//float moveAngle = m_dumbbellOrientation * PI / 2.0f;
	//P17 is from P16 and move along dumbbell for 10 mm
	float  DX = 10.0f * m_dumbbellDirScale.cosValue;
	float  DY = 10.0f * m_dumbbellDirScale.sinValue;
	SetDerivedLPoint ( P17, P16, 
						DX, DY, 0, 0 );

	//P27 is from P26 and move again dumbell for 10 mm
	//moveAngle = (m_dumbbellOrientation + 2) * PI / 2.0f;
	//DX = 10.0f * cosf( moveAngle );
	//DY = 10.0f * sinf( moveAngle );
	SetDerivedLPoint ( P27, P26, 
						-DX, -DY, 0, 0 );

	//move away 20 mm from dumbbell
	//P6---->P3   P16---->P93     P26--->P94
	//moveAngle = (m_dumbbellOrientation + 1) * PI / 2.0f;
	DX = -20.0f * m_dumbbellDirScale.sinValue;
	DY =  20.0f * m_dumbbellDirScale.cosValue;
	SetDerivedLPoint( P3,   P6, DX, DY, 0, 0 );

	DX = -35.0f * m_dumbbellDirScale.sinValue;
	DY =  35.0f * m_dumbbellDirScale.cosValue;
	SetDerivedLPoint( P93, P16, DX, DY, 0, 0 );
	SetDerivedLPoint( P94, P26, DX, DY, 0, 0 );

	SetDerivedLPoint ( P2, P3, 
						0,     0,     -2,   0,
						false, false, true, false ); //direct set or relative change

	//0.5 is space buffer to make sure tong not touch dumbbell head
	float DX5 = -(MAGNET_HEAD_RADIUS + TONG_CAVITY_RADIUS + 0.5f) * m_dumbbellDirScale.sinValue;
	float DY5 =  (MAGNET_HEAD_RADIUS + TONG_CAVITY_RADIUS + 0.5f) * m_dumbbellDirScale.cosValue;
	SetDerivedLPoint( P5, P16, DX5, DY5, 0, 0 );


	//P15: used in arc from P93 to P16
	DX /= 2.0;
	DY /= 2.0;

	//moveAngle = m_dumbbellOrientation * PI / 2.0f;
	float DX15 = DX + 35.0f / 2.0f * m_dumbbellDirScale.cosValue;
	float DY15 = DY + 35.0f / 2.0f * m_dumbbellDirScale.sinValue;
	SetDerivedLPoint ( P15, P16, DX15, DY15, 0, 0 );

	//P25: used in arc from P26 to P3
	//moveAngle = (m_dumbbellOrientation + 2) * PI / 2.0f;
	float DX25 = DX - 35.0f / 2.0f * m_dumbbellDirScale.cosValue;
	float DY25 = DY - 35.0f / 2.0f * m_dumbbellDirScale.sinValue;
	SetDerivedLPoint ( P25, P26, DX25, DY25, 0, 0 );

	m_stripperInstalled = CheckPoint( P8 );
	if (m_stripperInstalled)
	{
		PointCoordinate Point4;
		PointCoordinate Point8;

		retrievePoint( P4, Point4 );
		retrievePoint( P8, Point8 );


		//P82 is from P8 with head stick out
		//moveAngle = (m_dumbbellOrientation - 1) * PI / 2.0f;
		DX =  STRIP_PLACER_STICKOUT * m_dumbbellDirScale.sinValue;
		DY = -STRIP_PLACER_STICKOUT * m_dumbbellDirScale.cosValue;
		SetDerivedLPoint( P82, P8, DX, DY, 0,   0 );

		//P81 is from P82, move again dumbbell direction
		//moveAngle = (m_dumbbellOrientation + 2) * PI / 2.0f;
		DX = -STRIP_PLACER_SIDEWAY * m_dumbbellDirScale.cosValue;
		DY = -STRIP_PLACER_SIDEWAY * m_dumbbellDirScale.sinValue;
		SetDerivedLPoint( P81, P82, DX, DY, 0,   0 );	

		//P80 is same as P81 just Z is high
		float P4Z = Point4.z;
		SetDerivedLPoint( P80, P81, 0, 0, P4Z, 0, false, false, true, false ); //absolute Z

		//P83 is from P82 move away
		//moveAngle = (m_dumbbellOrientation + 1) * PI / 2.0f;
		DX = -STRIP_PLACER_DISTANCE * m_dumbbellDirScale.sinValue;
		DY =  STRIP_PLACER_DISTANCE * m_dumbbellDirScale.cosValue;
		SetDerivedLPoint( P83, P82, DX, DY, 0, 0 );

		//P84 is 2 mm over strike from P82
		//moveAngle = (m_dumbbellOrientation - 1) * PI / 2.0f;
		DX =  2.0f * m_dumbbellDirScale.sinValue;
		DY = -2.0f * m_dumbbellDirScale.cosValue;
		SetDerivedLPoint( P84, P82, DX, DY, 0,   0 );

		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, "robot has dumbbell stripper installed" );
		}

		float P8Z = Point8.z;
		sprintf( m_strCoolingPoint, "P* :Z(%d)", int(P8Z) );
	}
	//try to read scale factors from post calibration
	try
	{
	    CString tempString1( m_pSPELCOM->GetSPELVar( "g_TQScale_Picker" ) );
	    CString tempString2( m_pSPELCOM->GetSPELVar( "g_TQScale_Placer" ) );
		float scale1 = m_TQScale;
		float scale2 = m_TQScale;


		sscanf( tempString1, "%f", &scale1 );
		sscanf( tempString2, "%f", &scale2 );
		LOG_FINEST2( "got scale factor from robot: %f %f", scale1, scale2 );
		m_TQScale = 0.5f * (fabsf( scale1) + fabsf( scale2 ));
	}
	catch ( CException *e )
	{
		char message[MAX_LENGTH_STATUS_BUFFER+1] = {0};

		e->GetErrorMessage ( message,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete ( );
		LOG_WARNING1( "failed to get scale factor from robot: %s", message );
	}
}

void RobotEpson::InitCassettePoints( )
{
    if (!CheckPoint( P6 )  ||	 //dumbell cradle needed to decide cassette orientation
		!CheckPoint( P34 ) ||    //left
        !CheckPoint( P35 ) ||    //middle
        !CheckPoint( P36 ) ||    //right
                                 // for tilt:
        !CheckPoint( P41 ) ||    // left bottom center
        !CheckPoint( P42 ) ||    // middle bottom center
        !CheckPoint( P43 ) ||    // right bottom center
        !CheckPoint( P44 ) ||    // left top center
        !CheckPoint( P45 ) ||    // middle top center
        !CheckPoint( P46 ))      // right top center
    {
        SetRobotFlags( FLAG_NEED_CAL_CASSETTE | FLAG_REASON_INIT );
        return;
    }
    InitCassetteCoords ( 'l' );
    InitCassetteCoords ( 'm' );
    InitCassetteCoords ( 'r' );
}

void RobotEpson::InitGoniometerPoints( )
{
    if (!CheckPoint( P20 ))
    {
        SetRobotFlags( FLAG_NEED_CAL_GONIO | FLAG_REASON_INIT );
        return;
    }
}

bool RobotEpson::CloseToPoint( LPoint pt, float x, float y, float range ) const
{
    if (range < 0.0)
    {
        range = 5.0;
    }

    float range2 = range * range;

	PointCoordinate point;

    try
    {
		retrievePoint( pt, point );
    }
	catch ( CException *e )
	{
        char errorMessage[MAX_LENGTH_STATUS_BUFFER+1] = {0};
		e->GetErrorMessage ( errorMessage,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete();
        LOG_WARNING1( "RobotEpson::CloseToPoint %s", errorMessage );

        return false;
	}

    float deltaX = point.x - x;
    float deltaY = point.y - y;
    float distance2 = deltaX * deltaX + deltaY * deltaY;

    if (distance2 <= range2)
    {
        return true;
    }
    else
    {
        return false;
    }
}
bool RobotEpson::CloseToPoint( LPoint pt, const PointCoordinate& point, float range ) const
{
	return CloseToPoint( pt, point.x, point.y, range );
}

bool RobotEpson::GenericPrepare( int cooling_seconds, char status_buffer[] )
{
    static CCassette* const cassettes[3] = { &m_LeftCassette, &m_MiddleCassette, &m_RightCassette };

    bool   probeCassette = false;
    bool   probeOK = false;

	try 
	{
        //check (current point, gripper, lid) before start to move
		PointCoordinate Point3;
		PointCoordinate currentPosition;

		GetCurrentPosition( currentPosition );
		retrievePoint( P3, Point3 );

        //check for P0(home) P1(rest)
        if (!CloseToPoint( P0, currentPosition ) && !CloseToPoint( P1, currentPosition ) && !CloseToPoint( P3, currentPosition ))
        {
            SetRobotFlags( FLAG_REASON_NOT_HOME );
            strcpy( status_buffer, "robot must at P0, P1 or P3 to start operation" );
		    return false;
        }

		if (!CloseToPoint( P3, currentPosition ))
		{
			if (!CheckGripper( ))
			{
				SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				strcpy( status_buffer, "CheckGripper Failed" );
				return false;
			}

			switch (m_Dewar.OpenLid( ))
			{
			case Dewar::OPEN_LID_WARNING_LONG_TIME:
				{
					char openlid_msg[] = "OpenLid took very long time";
					LOG_WARNING( openlid_msg );
					if (m_pEventListener)
					{
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
					}
				}
				//falling through
			case Dewar::OPEN_LID_OK:
				break;

			case Dewar::OPEN_LID_FAILED:
			default:
				//SetRobotFlags( FLAG_REASON_LID_JAM );
				strcpy( status_buffer, "OpenLid Failed" );
				return false;
			}

			UpdateSampleStatus( "moving to Dewar" );

			//move to cool point
			if (!MoveToCoolPoint ( ))
			{
				if (m_FlagAbort)
				{
					MoveTongHome( );
    				strcpy( status_buffer, "User Aborted" );
				}
				else
				{
    				strcpy( status_buffer, "MoveToCoolPoint Failed" );
				}
				return false;
			}

			if (m_FlagAbort)
			{
				MoveTongHome( );
				strcpy( status_buffer, "aborted" );
				return false;
			}

			if (m_desiredLN2Level == LN2LEVEL_HIGH)
			{
				m_TimeInLN2 = time( NULL );
				if (m_pEventListener)
				{
					char msg[256] = {0};
					sprintf( msg, "cooling tong for %d seconds", cooling_seconds );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, msg );
					UpdateSampleStatus( msg );
				}

				if (m_stripperInstalled)
				{
					COleVariant cooling_point( m_strCoolingPoint );
					m_pSPELCOM->Move( cooling_point );
	  				RobotWait( 1000 * cooling_seconds );
					m_pSPELCOM->Move( (COleVariant)"P3" );
				}
				else
				{
	  				RobotWait( 1000 * cooling_seconds );
				}
			}
			else
			{
				RobotWait( 1000 );
			}

		}
		else
		{
			//close to P3 in XY
			//this is for stripper installed case
			if (currentPosition.distance( Point3 ) > 1.0)
			{
				m_pSPELCOM->Move( (COleVariant)"P3" );
			}
		}

		if (m_FlagAbort)
		{
			MoveTongHome( );
			strcpy( status_buffer, "aborted" );
			return false;
		}

		//check gripper again after cooling
        if (!CheckGripper( ))
        {
			//after reheat, the tong is open
			if (!ReHeatTongAndCheckGripper( ) || !CloseGripper( ))
			{
    			MoveTongHome( );
				SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
				strcpy( status_buffer, "CheckGripper Failed after cooling" );
				return false;
			}
        }

		if (m_FlagAbort)
		{
			MoveTongHome( );
			strcpy( status_buffer, "aborted" );
			return false;
		}
        //probe cassette if needed
        if ( getAttributeFieldBool( ATTRIB_PROBE_CASSETTE ) ||
			 getAttributeFieldBool( ATTRIB_PROBE_PORT ) || m_inCmdProbing)
        {
            for (int i = 0; i < 3; ++i)
            {
                if (cassettes[i]->NeedProbe( ) || cassettes[i]->AnyPortNeedProbe( ))
                {
                    probeCassette = true;
                }
            }
            if (probeCassette)
            {
                if (!GetMagnet( ))
                {
			        strcpy( status_buffer, "GetMagnet Failed for probing" );
			        return false;
                }
                probeOK = ProbeCassettes( status_buffer );
                PutMagnet( );
            }
        }
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
		return false;
	}

	if (m_FlagAbort)
	{
		try
		{
			MoveTongHome( );
		}
		catch ( CException *e )
		{
            NormalErrorHandle( e, status_buffer );
			strncat( status_buffer, "in aborting", (MAX_LENGTH_STATUS_BUFFER - strlen(status_buffer)) );
			return false;
		}
		strcpy( status_buffer, "aborted" );
		return false;
	}

	//check result of probing
    if (probeCassette && !probeOK)
    {
		try
		{
            //ProbeCassettes filled status_buffer
            if (m_desiredLN2Level == LN2LEVEL_HIGH)
            {
                m_Dewar.TurnOnHeater( );
            }
			MoveTongHome( );
            //AppendOldMessage( status_buffer );
        }
		catch ( CException *e )
		{
            NormalErrorHandle( e, status_buffer );
			strncat( status_buffer, "in homing after probe failed", (MAX_LENGTH_STATUS_BUFFER - strlen(status_buffer)) );
		}
        return false;
    }

	if (m_FlagAbort)
	{
		try
		{
			MoveTongHome( );
		}
		catch ( CException *e )
		{
            NormalErrorHandle( e, status_buffer );
			strncat( status_buffer, "in aborting", (MAX_LENGTH_STATUS_BUFFER - strlen(status_buffer)) );
			return false;
		}
		strcpy( status_buffer, "aborted" );
		return false;
	}
    return true;
}

bool RobotEpson::ProbeCassettes( char status_buffer[] )
{
    static CCassette* const cassettes[3] = { &m_LeftCassette, &m_MiddleCassette, &m_RightCassette };

	bool result = true;

	char local_status_buffer[MAX_LENGTH_STATUS_BUFFER + 1] = {0};

	status_buffer[0] = 0;

    for (int i = 0; i < 3; ++i)
    {
        if (!cassettes[i]->NeedProbe( ) && !cassettes[i]->AnyPortNeedProbe( )) continue;

        if (cassettes[i]->NeedProbe( ))
        {
			if (m_pEventListener)
			{
				char msg[256] = {0};
				sprintf( msg, "probing cassette %c", cassettes[i]->GetName( ) );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, msg );
                UpdateSampleStatus( msg );
			}

			if (!ProbeOneCassette( *cassettes[i], local_status_buffer ))
            {
                result = false;
				if (m_FlagAbort) break;
				
				//append error message to status_buffer
				size_t space_left = MAX_LENGTH_STATUS_BUFFER - strlen( status_buffer );
				if (space_left)
				{
					strncat( status_buffer, local_status_buffer, space_left );
				}
                continue;//skip port probing
            }
        }//if (cassettes[i]->NeedProbe( ))
        if ((getAttributeFieldBool( ATTRIB_PROBE_PORT ) || m_inCmdProbing) && cassettes[i]->AnyPortNeedProbe( ))
        {
            ProbePorts( *cassettes[i] );
        }
		if (m_FlagAbort) break;
    }//for cassettes

	setRobotSpeed( SPEED_IN_LN2 );
    m_pSPELCOM->Tool( 0 );
    m_pSPELCOM->LimZ( N2_LEVEL );
    m_pSPELCOM->Jump( (COleVariant)"P6" );

    return result;
}

bool RobotEpson::TouchCassetteTop( const PointCoordinate& standby, float distance, char cassetteName, float& top, char status_buffer[] )
{
	assignPoint( P52, standby );
	m_pSPELCOM->LimZ( N2_LEVEL );
	m_pSPELCOM->Jump( (COleVariant)"P52" );
	PointCoordinate FDest;

	RobotWait( 2 * WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
	ForceCalibrate( );
	GetCurrentPosition( FDest );
	FDest.z -= distance;
	if (!ForceTouch( -FORCE_ZFORCE, FDest, false ))
	{
		if (m_FlagAbort)
		{
			strcpy( status_buffer, "aborted" );
		}
		else
		{
			sprintf( status_buffer, "cassette %c absent ", cassetteName );
			LOG_WARNING( status_buffer );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
			}
		}
		return false;
	}//if (!ForceTouch( -FORCE_ZFORCE, FDest, false ))

	//save result
	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
	top = currentPosition.z - MAGNET_HEAD_RADIUS;

	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move( COleVariant( "P52" ) );
	return true;
}

bool RobotEpson::ProbeOneCassette( CCassette& theCassette, char status_buffer[] )
{
    PointCoordinate standby[4];
	float distance = 0.0f;
	float heights[4] = {0};
	float delta = 0;
	bool foundAtFirstProbe = false;
	char cassetteName = theCassette.GetName( );

	switch (cassetteName)
	{
	case 'l':
		UpdateSampleStatus( "probe left cassette" );
		break;

	case 'm':
		UpdateSampleStatus( "probe middle cassette" );
		break;

	case 'r':
		UpdateSampleStatus( "probe right cassette" );
		break;
	}

    m_pSPELCOM->Tool( 1 );

    theCassette.GetProbePoints( standby, distance );

	for (int i = 0; i < 4; ++i)
	{
		if (!TouchCassetteTop( standby[i], distance, cassetteName, heights[i], status_buffer ))
		{
			if (i == 0)
			{
				if (!m_FlagAbort)
				{
					theCassette.SetStatus( CCassette::CASSETTE_ABSENT, true );
					UpdateCassetteStatus( );
					updateForces( );

					//SetRobotFlags( FLAG_REASON_CASSETTE );
					LOG_WARNING( status_buffer );
					if (i != 0)
					{
						LOG_SEVERE1( "strange thing: probe cassette height failed at i=%d", i );
					}
					UpdateSampleStatus( status_buffer );
				}
				return false;
			}
			else
			{
				//maybe super puck adaptor
				heights[i] = 0;
			}
		}

		if (i == 0)
		{
			if (theCassette.CheckHeight( heights, 1, &delta ))
			{
				LOG_INFO1( "in cassette probing, first point dz=%f OK", delta );
				foundAtFirstProbe = true;
				break;
			}
			else
			{
				sprintf( status_buffer, "cassette %c maybe sit not right, trying more points", theCassette.GetName( ) );
				LOG_WARNING( status_buffer );
				LOG_WARNING1( "in cassette probing, first point dz=%f", delta );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, status_buffer );
					UpdateSampleStatus( status_buffer );
				}
			}//if (theCassette.CheckHeight( heights, 1, &delta ))
		}//if (i == 0)
	}//for (int i = 0; i < 4; ++i)

	setRobotSpeed( SPEED_IN_LN2 );

	if (!foundAtFirstProbe && !theCassette.CheckHeight( heights, 4, &delta ))
	{
		LOG_WARNING1( "cassette probing failed even after 4 points average, dz=%f", delta );
        theCassette.SetStatus( CCassette::CASSETTE_PROBLEM, true );
        UpdateCassetteStatus( );
		updateForces( );

		sprintf( status_buffer, "cassette %c sit not right dz=%f mm", cassetteName, delta );
	    SetRobotFlags( FLAG_REASON_CASSETTE );
	    LOG_WARNING( status_buffer );
        if (m_pEventListener)
        {
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
			UpdateSampleStatus( status_buffer );
        }
        return false;
	}

	theCassette.SetStatus( CCassette::CASSETTE_PRESENT, false );
	theCassette.SetNeedProbe( false );
	UpdateCassetteStatus( );
	updateForces( );

	switch (theCassette.GetType( ))
	{
	case CCassette::CASSETTE_TYPE_NORMAL:
		sprintf( status_buffer, "found normal cassette %c dz: %.3f ", cassetteName, delta );
		break;

	case CCassette::CASSETTE_TYPE_CALIBRATION:
		sprintf( status_buffer, "found calibration cassette %c dz: %.3f ", cassetteName, delta );
		break;

	case CCassette::CASSETTE_TYPE_SUPERPUCK:
		sprintf( status_buffer, "found super puck adaptor %c dz: %.3f ", cassetteName, delta );
		break;

	}
	LOG_FINE( status_buffer );

	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, status_buffer );
		UpdateSampleStatus( status_buffer );
	}
	return true;
}

//move from Force In position to Touch position,
//then arc then back off
void RobotEpson::TwistOffMagnet( )
{
    const float PI = 3.14159265359f;
    const float ANGLE = PI / 3.0f; //60 degree
    const float ANGLE_IN_DEGREE = 60.0f;

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

    short tl = m_pSPELCOM->GetTool( );
	float currentMagnetAngle = currentPosition.u * PI / 180.0f;

    char log_message[256] = {0};
	//sprintf( log_message, "twist off current (%f, %f, %f, %f)", currentPosition.x, currentPosition.y, currentPosition.z, currentPosition.u );
	//LOG_FINEST( log_message );

	//float detachDistance = CCassette::GetDetachDistance( );
	float detachDistance = GetCassette( m_pState->currentCassette ).GetDetachDistance( );
	float detachDX = -detachDistance * cosf( currentMagnetAngle );
	float detachDY = -detachDistance * sinf( currentMagnetAngle );
    char cmdDetach[200];
    sprintf( cmdDetach, "P* +X(%.3f) +Y(%.3f)", detachDX, detachDY );
    COleVariant detach( cmdDetach );
	//sprintf( log_message, "detach (%f, %f)", detachDX, detachDY );
	//LOG_FINEST( log_message );

    float angleToArc;
    float angleToArcInDegree;
	LPoint tempTlSetNum = P11;

    switch (tl)
    {
    case 1:
        angleToArc = ANGLE;
        angleToArcInDegree = ANGLE_IN_DEGREE;
		tempTlSetNum = P10;
        break;
    case 2:
        angleToArc = -ANGLE;
        angleToArcInDegree = -ANGLE_IN_DEGREE;
		tempTlSetNum = P11;
        break;
    default:
        return;
    }
	char cmdRot[200];
	sprintf( cmdRot, "P* +U(%.3f)", angleToArcInDegree );
	COleVariant rot( cmdRot );


    float MagnetAngleAtEnd = currentMagnetAngle + angleToArc;
    float MoveFurtherDX = -10.0f * cosf( MagnetAngleAtEnd );
    float MoveFurtherDY = -10.0f * sinf( MagnetAngleAtEnd );
    char cmdFurther[200];
    sprintf( cmdFurther, "P* +X(%.3f) +Y(%.3f)", MoveFurtherDX, MoveFurtherDY );
    COleVariant further( cmdFurther );
	//sprintf( log_message, "further (%f, %f)", MoveFurtherDX, MoveFurtherDY );
	//LOG_FINEST( log_message );

    if (!SetupTemperaryToolSet( tempTlSetNum ))
    {
        return;
    }

	//OK do the move
    m_pSPELCOM->Tool( 3 );
    m_pSPELCOM->Move( detach );
	m_pSPELCOM->Go( rot );
	m_pSPELCOM->Tool( tl );
    m_pSPELCOM->Move( further );
}

void RobotEpson::ProbePorts( CCassette& theCassette )
{
	char cassetteName = theCassette.GetName( );
	char fullCasName[8] = {0};
	switch (cassetteName)
	{
	case 'l':
		strcpy( fullCasName,"left" );
		break;
	case 'm':
		strcpy( fullCasName,"middle" );
		break;

	case 'r':
		strcpy( fullCasName,"right" );
		break;
	}

	short previousTool = m_pSPELCOM->GetTool( );

	bool finished_all = true;

	COleVariant standbyVA( "P52" );
	COleVariant destVA( "P53" );

    m_pSPELCOM->Tool( 2 );
    m_pSPELCOM->LimZ( N2_LEVEL );
    for (char column = 'A'; column < 'A' + CCassette::MAX_COLUMN; ++column)
    {
        bool inColumn = false;
        //jump to the column if any port in this column need probing
        for (short row = 1; row < 1+ CCassette::MAX_ROW; ++row)
        {
			if (!theCassette.PositionIsValid( row, column)) { continue; }
            if (!theCassette.PortNeedProbe( row, column )) { continue; }


			if (m_FlagAbort)
			{
				finished_all = false;
				break;
			}

			//inform
			char status_message[1024] = {0};
			sprintf( status_message, "probe %s %c%hd", fullCasName, column, row );
			UpdateSampleStatus( status_message );

	        PointCoordinate standbyP;
	        PointCoordinate destP;
	        theCassette.GetPortPoint( row, column, destP, &standbyP );
			assignPoint( P52, standbyP );
			assignPoint( P53, destP );
            if (inColumn)
            {
                m_pSPELCOM->Move( standbyVA );
            }
            else
            {
                m_pSPELCOM->Jump( standbyVA );
				RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
				ForceCalibrate( );
				inColumn = true;
            }
			SetCurrentPoint( P52 );

	        m_pSPELCOM->Move( destVA );
			SetCurrentPoint( P53 );

	        float currentForce = ReadForce(FORCE_XTORQUE);
			float distanceFromForce = fabsf( currentForce / m_TQScale );
			float portError = distanceFromForce - theCassette.GetDetachDistance( );
#ifdef _DEBUG
	        char message[256]={0};
            sprintf( message, "probing port[%c%hi%c] force=%f", theCassette.GetName( ), row, column, currentForce );
	        LOG_FINEST( message );
#endif
			if (distanceFromForce < THRESHOLD_PORTCHECK)
            {
		        theCassette.SetPortState( row, column, CSamplePort::PORT_EMPTY );
				portError = PORT_ERROR_EMPTY;
	        }
			else if (portError > THRESHOLD_PORTJAM)
		    {
		        theCassette.SetPortState( row, column, CSamplePort::PORT_JAM );
				LogRawForces( );
				//SetRobotFlags( FLAG_REASON_CASSETTE );
				if (m_pEventListener)
				{
					sprintf( m_ErrorMessageForOldFunction, "port jam at %c %hd %c", theCassette.GetName( ), row, column );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, m_ErrorMessageForOldFunction );
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, m_ErrorMessageForOldFunction );
					UpdateSampleStatus( m_ErrorMessageForOldFunction );
				}
		    }
	        else
	        {
		        theCassette.SetPortState( row, column, CSamplePort::PORT_SAMPLE_IN );
	        }
			theCassette.setPortForce( row, column, portError );
			updateForces( );

            UpdateCassetteStatus( );
			theCassette.SetPortNeedProbe( row, column, false );

	        TwistOffMagnet( );
	        //m_pSPELCOM->Move( standbyVA );
			SetCurrentPoint( P52 );	//mark not at P53
        }//for row
		if (m_FlagAbort)
		{
			finished_all = false;
			break;
		}
    }//for column
	if (finished_all)
	{
		theCassette.ClearAllPortNeedProbe( );
	}
}

void RobotEpson::StopBackgroundTask( short taskNum )
{
	if (m_pSPELCOM->TaskStatus( taskNum ))
	{
		m_pSPELCOM->Quit( taskNum );
	}
}


void RobotEpson::StartBackgroundTask( short taskNum, const char * pSPELFunctionName )
{
	if (m_pSPELCOM->TaskStatus( taskNum ))
	{
		m_pSPELCOM->Quit( taskNum );
		LOG_WARNING2( "task %d still alive in tryring to start %s for it", (int)taskNum, pSPELFunctionName );
	}

	VARIANT myVariant;
	VariantInit( &myVariant );
	myVariant.vt = VT_BOOL;
	myVariant.boolVal = 1;
	m_pSPELCOM->Xqt( taskNum, pSPELFunctionName, myVariant );
    m_TSBackgroundTask = time( NULL );
}

//default case will be the old:
//  move from port
//  move from cassette
//  move to cassette
//  move to port
//it will end up in tool 1
//because the space limit and the magnet may hold sample, we have few choices.
//only can skip MoveFromCassetteToPost

void RobotEpson::MoveFromPortToPort( char fromCassette, char fromColumn, short fromRow, char toCassette, char toColumn, short toRow )
{

    //CASE 1: same cassette
    if (fromCassette == toCassette)
    {
        MoveFromPortToPortInSameCassette( fromCassette, fromColumn, fromRow, toColumn, toRow );
        return;
    }

    if (fromCassette != 'm' && toCassette != 'm')
    {
        MoveFromPortToStandby( );
        MoveToPortViaStandby( toCassette, toRow, toColumn );
        return;
    }

#if 1
    //involve middle cassette
    if (fromCassette == 'm')
    {
        MoveFromPortToStandby( );

		//move to secondary standby point of dest cassette
	    COleVariant portStandbyVA( "P52" );
		PointCoordinate secondaryStandby;
		GetCassette( toCassette ).GetSecondaryStandbyPoint( toRow, toColumn, secondaryStandby );
		assignPoint( P52, secondaryStandby );
        m_pSPELCOM->Move( portStandbyVA );

		//move to the port
		MoveToPortFromSecondaryStandby( toCassette, toRow, toColumn );
        return;
    }
    else
    {
        //toCassette == 'm'
		MoveFromPortToSecondaryStandby( fromCassette, fromRow, fromColumn );
        MoveToPortViaStandby( toCassette, toRow, toColumn );
    }

#else
    //default case
	short currentTLSET = m_pSPELCOM->GetTool( );
	MoveFromPortToPost( );
	m_pSPELCOM->Tool( currentTLSET );
    MoveToPortViaStandby( toCassette, toRow, toColumn );
#endif
}


void RobotEpson::MoveFromPortToSecondaryStandby ( char cassette, int row, char column )
{
	char moveCmd[COMMAND_BUFFER_LENGTH] = {0};
	GetCassette( cassette ).GetCommandForSecondaryFromPort( row, column, moveCmd, m_cmdBackToStandby );
	m_pSPELCOM->ExecSPELCmd( moveCmd );
	SetCurrentPoint ( P52 );
	m_pState->currentCassette = 0;
	m_pState->currentColumn = 0;
	m_pState->currentRow = 0;
    UpdateState( );
}

void RobotEpson::MoveToPortFromSecondaryStandby ( char cassette, int row, char column )
{
	char moveCmd[COMMAND_BUFFER_LENGTH] = {0};
	GetCassette( cassette ).GetCommandForPortFromSecondary( row, column, moveCmd, m_cmdBackToStandby );

	m_pSPELCOM->ExecSPELCmd( moveCmd );
	SetCurrentPoint ( P52 );
	m_pState->currentCassette = cassette;
	m_pState->currentColumn = column;
	m_pState->currentRow = row;
    UpdateState( );
}

void RobotEpson::MoveFromPortToPortInSameCassette( char cassette, char fromColumn, short fromRow, char toColumn, short toRow )
{
	char moveCmd[COMMAND_BUFFER_LENGTH] = {0};
	GetCassette( cassette ).GetCommandForPortFromPort( fromRow, fromColumn, toRow, toColumn, moveCmd, m_cmdBackToStandby );

	m_pSPELCOM->ExecSPELCmd( moveCmd );
	SetCurrentPoint ( P52 );
	m_pState->currentCassette = cassette;
	m_pState->currentColumn = toColumn;
	m_pState->currentRow = toRow;
    UpdateState( );
}

void RobotEpson::SetGonioSample( char cassette, short row, char column, bool update )
{
    m_pState->mounted_cassette = cassette;
    m_pState->mounted_row = row;
    m_pState->mounted_column = column;

	FlushViewOfFile( m_pState, 0 );

	if (update)
	{
		UpdateMounted( );
	}
}
void RobotEpson::SetTongSample( char cassette, short row, char column, bool update )
{
    m_pState->tongCassette = cassette;
    m_pState->tongRow = row;
    m_pState->tongColumn = column;
	FlushViewOfFile( m_pState, 0 );

	if (update)
	{
	    UpdateState( );
	}
}
void RobotEpson::SetPickerSample( char cassette, short row, char column, bool update )
{
    m_pState->pickerCassette = cassette;
    m_pState->pickerRow = row;
    m_pState->pickerColumn = column;
	FlushViewOfFile( m_pState, 0 );

	if (update)
	{
	    UpdateState( );
	}
}
void RobotEpson::SetPlacerSample( char cassette, short row, char column, bool update )
{
    m_pState->placerCassette = cassette;
    m_pState->placerRow = row;
    m_pState->placerColumn = column;
	FlushViewOfFile( m_pState, 0 );

	if (update)
	{
	    UpdateState( );
	}
}

void RobotEpson::UpdateMounted( )
{
    char mounted[32] = {0};

	//clear mounted in any case
	m_LeftCassette.ClearMounted( );
	m_MiddleCassette.ClearMounted( );
	m_RightCassette.ClearMounted( );

	if (GetSampleState( ) == SAMPLE_ON_GONIOMETER)
    {
		if (PositionIsValid( m_pState->mounted_cassette, m_pState->mounted_row, m_pState->mounted_column ))
		{
			//flag the port as mounted
			GetCassette( m_pState->mounted_cassette ).SetPortState( m_pState->mounted_row, m_pState->mounted_column, CSamplePort::PORT_MOUNTED );

			//increase counters
			++m_pState->num_pin_mounted;
			++m_pState->num_pin_mounted_short_trip;
			if (GetCassette( m_pState->mounted_cassette ).GetType( ) == CCassette::CASSETTE_TYPE_SUPERPUCK)
			{
				++m_pState->num_puck_pin_mounted;
				++m_pState->num_puck_pin_mounted_short_trip;
			}
			if (m_pState->num_pin_lost_short_trip == 0)
			{
				++m_pState->num_pin_mounted_before_lost;
			}

			if (m_pEventListener)
			{
				sprintf( mounted, "%lu", m_pState->num_pin_mounted_short_trip );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINMOUNTED, mounted );
			}
			sprintf( mounted, "%c %hd %c", 
				m_pState->mounted_cassette,
				m_pState->mounted_row,
				m_pState->mounted_column );
		}
		else if (PositionIsBeamlineTool( m_pState->mounted_cassette, m_pState->mounted_row, m_pState->mounted_column ))
		{
			sprintf( mounted, "%c %hd %c", 
				m_pState->mounted_cassette,
				m_pState->mounted_row,
				m_pState->mounted_column );
		}
    }
    if (m_pEventListener)
    {
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_MOUNTED, mounted );
    }
	FlushViewOfFile( m_pState, 0 );
    UpdateCassetteStatus( );
}

bool RobotEpson::ReHeatTongAndCheckGripper( )
{

    //====================check pre-condition=====================
    //if robot is NOTconfiged to reheat, failed
    if (!getAttributeFieldBool( ATTRIB_REHEAT_TONG ))
    {
        return false;
    }

    //if we run in room temperature, fail it.
    if (m_desiredLN2Level != LN2LEVEL_HIGH)
    {
        LOG_WARNING( "only reheating the tong in LN2" );
        return false;
    }

    //if the robot is not on P3 or P23, fail it
    LPoint currentPoint = GetCurrentPoint( );

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

    switch (currentPoint)
    {
    case P3:
	case P93:
    case P23:
        if (!CloseToPoint( currentPoint, currentPosition ))
        {
            LOG_WARNING( "not really at P3 or P23 or P93" );
            return false;
        }
        break;

    default:
        LOG_WARNING( "reheating tong must start at P3 or P23 or P93" );
        return false;
    }

    //==========================move tong home=====================
    LOG_FINE( "re-heat gripper" );
    m_Dewar.TurnOnHeater( );

    switch (currentPoint)
    {
    case P3:
	case P93:
        m_pSPELCOM->Move( COleVariant( "P* :Z(-1)" ) );
#ifdef MIXED_ARM_ORIENTATION
        m_pSPELCOM->Go( COleVariant( "P1 :Z(-1)" ) );
#else
        m_pSPELCOM->Move( COleVariant( "P1 :Z(-1)" ) );
#endif
        m_pSPELCOM->Move( COleVariant( "P1" ) );
        SetCurrentPoint( P1 );
        break;

    case P23:
        m_pSPELCOM->Move( COleVariant( "P22" ) );
        SetCurrentPoint( P22 );
   		MoveFromGoniometerToRestPoint( ); //this will move tong to P1
        break;
    }
	setRobotSpeed( SPEED_IN_LN2 );
    m_pSPELCOM->Move( COleVariant( "P* :Z(-1)" ) );
    m_pSPELCOM->Move( COleVariant( "P0 :Z(-1)" ) );
    m_pSPELCOM->Move( COleVariant( "P0" ) );
    SetCurrentPoint( P0 );
    OpenGripper( ); //ignore failure, we in reheating

    if (m_FlagAbort)
	{
	    m_Dewar.TurnOffHeater( );
		return false;
	}

    //=============================heat the tong===================
    bool result = m_Dewar.WaitHeaterHot( );

    if (result)
    {
        RobotWait( 30000 ); //30 seconds
        Dance ( );
        result = CheckGripper( );
    }

    m_Dewar.TurnOffHeater( );

    if (m_FlagAbort) return false;

    //============================move to cool point and cool it down====================
    if (!MoveToCoolPoint( )) return false; //only fail on abort

    if (result)
    {
  		RobotWait( 40000 ); //40 seconds

        //check gripper again after cooling
        result = CheckGripper( );

    }

    if (m_FlagAbort) return false;

	setRobotSpeed( SPEED_IN_LN2 );
	//=========================move tong back to starting position
    switch (currentPoint)
    {
    case P3:
        break;

	case P93:
        m_pSPELCOM->Move( COleVariant( "P93" ) );
        SetCurrentPoint( P93 );
        break;

    case P23:
        CloseGripper( );  //ignore error here
        MoveToGoniometer( );
		setRobotSpeed( SPEED_IN_LN2 );
        m_pSPELCOM->Move( COleVariant( "P23" ) );
        SetCurrentPoint( P23 );

        break;
    }

    if (result)
    {
        result = OpenGripper( );
    }

    LOG_FINE1( "re-heat gripper done, result=%d", result );
    return result;
}

void RobotEpson::UpdateState( )
{
	FlushViewOfFile( m_pState, 0 );
    if (!m_pEventListener)
    {
        return;
    }

    //generate the string from state

    char strState[2048] = {0};
    switch (m_pState->sampleState)
    {
    case NO_CURRENT_SAMPLE:
        strcat( strState, "{no} " );
        break;

    case SAMPLE_ON_TONG:
        strcat( strState, "{on tong} " );
        break;

    case SAMPLE_ON_PLACER:
        strcat( strState, "{on placer} " );
        break;

    case SAMPLE_ON_PICKER:
        strcat( strState, "{on picker} " );
        break;

    case SAMPLE_ON_GONIOMETER:
        strcat( strState, "{on gonio} " );
        break;

    default:
        strcat( strState, "{bad state} " );
    }                                                           // 19

    switch (m_pState->dumbbellState)
    {
    case DUMBBELL_OUT:
        strcat( strState, "{out} " );
        break;

    case DUMBBELL_RAISED:
        strcat( strState, "{raised} " );
        break;

    case DUMBBELL_IN_CRADLE:
        strcat( strState, "{in cradle} " );
        break;

    case DUMBBELL_IN_TONG:
        strcat( strState, "{in tong} " );
        break;

    default:
        strcat( strState, "{bad state} " );
    }                                                           // 19

    if (m_pState->currentPoint >= P0 && m_pState->currentPoint <= P100)
    {
        char number[16] = {0};
        sprintf( number, "P%d ", m_pState->currentPoint );
        strcat( strState, number );
    }
    else
    {
        strcat( strState, "Wrong " );
    }                                                           // 7

    switch (m_desiredLN2Level)
    {
    case LN2LEVEL_LOW:
        strcat( strState, "no " );
        break;

    case LN2LEVEL_HIGH:
        strcat( strState, "yes " );
        break;

    default:
        strcat( strState, "wrong " );
    }                                                           // 12
    //current port
	{
		char currentPort[64] = {0};
		if (PositionIsValid( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn ) ||
			PositionIsBeamlineTool( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn ))
		{
			sprintf( currentPort, "{%c %d %c} ", m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn );
		}
		else
		{
			strcpy( currentPort, "{invalid} " );
		}
		strcat( strState, currentPort );                       // 10
	}

	{
		char internal_counters[256] = {0};						//30
		sprintf( internal_counters, "%lu %lu %lu ",
			m_pState->num_pin_mounted,
			m_pState->num_pin_lost,
			m_pState->num_pin_mounted_before_lost );
		strcat( strState, internal_counters );
	}

	//add sample on goniometer or not
    if (PositionIsValid( m_pState->mounted_cassette,
				m_pState->mounted_row,
                m_pState->mounted_column ))
	{
		strcat( strState, "1 " );
	}
	else
	{
		strcat( strState, "0 " );
	}                                                           //2

	//strip counters
	{
		char internal_counters[256] = {0};						//20
		sprintf( internal_counters, "%lu %lu ",
			m_pState->num_pin_stripped,
			m_pState->num_pin_stripped_short_trip );
		strcat( strState, internal_counters );
	}

	{
		char tongPort[64] = {0};
		if (PositionIsValid( m_pState->tongCassette, m_pState->tongRow, m_pState->tongColumn ))
		{
			sprintf( tongPort, "{%c %d %c} ", m_pState->tongCassette, m_pState->tongRow, m_pState->tongColumn );
		}
		else
		{
			strcpy( tongPort, "{invalid} " );
		}
		strcat( strState, tongPort );                       // 10
	}

	{
		char pickerPort[64] = {0};
		if (PositionIsValid( m_pState->pickerCassette, m_pState->pickerRow, m_pState->pickerColumn ))
		{
			sprintf( pickerPort, "{%c %d %c} ", m_pState->pickerCassette, m_pState->pickerRow, m_pState->pickerColumn );
		}
		else
		{
			strcpy( pickerPort, "{invalid} " );
		}
		strcat( strState, pickerPort );                       // 10
	}

	{
		char placerPort[64] = {0};
		if (PositionIsValid( m_pState->placerCassette, m_pState->placerRow, m_pState->placerColumn ))
		{
			sprintf( placerPort, "{%c %d %c} ", m_pState->placerCassette, m_pState->placerRow, m_pState->placerColumn );
		}
		else
		{
			strcpy( placerPort, "{invalid} " );
		}
		strcat( strState, placerPort );                       // 10
	}

	{
		char puck_counters[256] = {0};						//20
		sprintf( puck_counters, "%lu %lu ",
			m_pState->num_puck_pin_mounted,
			m_pState->num_puck_pin_mounted_short_trip );
		strcat( strState, puck_counters );
	}
	{
		char move_counters[256] = {0};						//20
		sprintf( move_counters, "%lu %lu ",
			m_pState->num_pin_moved,
			m_pState->num_puck_pin_moved );
		strcat( strState, move_counters );
	}

    //send out
    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STATE, strState );
}

bool RobotEpson::Mounting( char cassette, short row, char column )
{
    if (!PortPostShuttle( false, cassette, row, column ))
    {
        return false;
    }

    if (!PickerToGoniometer( ))
    {
        return false;
    }


    return (GetRobotFlags( ) & (FLAG_NEED_CLEAR | FLAG_NEED_RESET)) == 0;
}

bool RobotEpson::Dismounting( char cassette, short row, char column )
{
    bool result = GoniometerToPlacer( ) && PortPostShuttle( true, cassette, row, column );
    if (result)
    {
        result = (GetRobotFlags( ) & (FLAG_NEED_CLEAR | FLAG_NEED_RESET)) == 0;
    }

    return result;
}

bool RobotEpson::Washing( int times )
{
	if (!GoniometerToPicker( )) return false;

	if (!m_FlagAbort)
	{
		//take dumbbell and jump to P3 at height of P4
		m_pSPELCOM->Tool( 0 );
		if (!GetMagnet( )) return false; //GetMagnet already set flags
		doWash( times );
		PutMagnet( );
	}//first m_FlagAbort
    if (!PickerToGoniometer( )) return false;

    return (GetRobotFlags( ) & (FLAG_NEED_CLEAR | FLAG_NEED_RESET)) == 0;
}
void RobotEpson::doWash( int times )
{
		m_pSPELCOM->Tool( 0 );
		setRobotSpeed( SPEED_IN_LN2 );

		PointCoordinate Point4;

		retrievePoint( P4, Point4 );
		float z4 = Point4.z;
		char washStandbyPoint[64] = {0};
		char ZMove[64] = {0};
		char ZBack[64] = {0};
		char UMove[64] = {0};
		char UBack[64] = {0};
		sprintf( washStandbyPoint, "P3:Z(%f)", z4 );
		sprintf( UMove, "P* +U(%f)", WASH_DISTANCE_U );
		sprintf( UBack, "P* -U(%f)", WASH_DISTANCE_U );

		if (m_stripperInstalled)
		{
			sprintf( ZMove, "P* -Z(%f)", WASH_DISTANCE_Z );
			sprintf( ZBack, "P* +Z(%f)", WASH_DISTANCE_Z );
		}
		else
		{
			sprintf( ZMove, "P* +Z(%f)", WASH_DISTANCE_Z );
			sprintf( ZBack, "P* -Z(%f)", WASH_DISTANCE_Z );
		}

		m_pSPELCOM->LimZ ( z4 + 5.0f );
		m_pSPELCOM->Jump ( (COleVariant)washStandbyPoint );
		SetCurrentPoint ( P3 );

		//move in 2 directions: arc in horizontal and up and down
		m_pSPELCOM->Tool( 2 );
		for (int i = 0; i < times; ++i)
		{
			for (int step = 0; step < 4; ++step)
			{
				switch (step)
				{
				case 0:
					m_pSPELCOM->Go( (COleVariant)UMove );
					break;
				case 1:
					m_pSPELCOM->Go( (COleVariant)UBack );
					break;
				case 2:
					m_pSPELCOM->Go( (COleVariant)ZMove );
					break;
				case 3:
					m_pSPELCOM->Go( (COleVariant)ZBack );
					break;
				}
				if (m_FlagAbort) break;
			}
		}

		m_pSPELCOM->Tool( 0 );
		m_pSPELCOM->Jump ( (COleVariant)"P4" );
		SetCurrentPoint ( P4 );
}

void RobotEpson::UpdateCassetteStatus( )
{
    if (!m_pEventListener) return;

    static char StringCassette[CCassette::NUM_STRING_STATUS_LENGTH * 3 + 3 +16] = {0}; //16 is safe buffer

    strcpy( StringCassette, m_LeftCassette.GetStringStatus( ) );
    strcat( StringCassette, " " );
    strcat( StringCassette, m_MiddleCassette.GetStringStatus( ) );
    strcat( StringCassette, " " );
    strcat( StringCassette, m_RightCassette.GetStringStatus( ) );

    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CASSETTE, StringCassette );
}
void RobotEpson::updateForces( )
{
    if (!m_pEventListener) return;

    char StringForces[CCassette::NUM_STRING_FORCE_LENGTH + 1 + 20 + 16] = {0}; //16 is safe buffer

	strcpy( StringForces, "robot_force_left " );
    strcat( StringForces, m_LeftCassette.getStringForce( ) );
    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STRING_UPDATE, StringForces );

	strcpy( StringForces, "robot_force_middle " );
    strcat( StringForces, m_MiddleCassette.getStringForce( ) );
    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STRING_UPDATE, StringForces );

	strcpy( StringForces, "robot_force_right " );
    strcat( StringForces, m_RightCassette.getStringForce( ) );
    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STRING_UPDATE, StringForces );


    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STRING_UPDATE, StringForces );
}

void RobotEpson::UpdateSampleStatus( const char* text, bool add_current_sample )
{
    if (!m_pEventListener) return;

    const char* pMsg = text;
    static char localMsg[64] = {0};

    if (add_current_sample && PositionIsValid( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn ))
    {
        sprintf( localMsg, "%c%c%d ", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
        size_t ll = strlen( localMsg );
        int left_space = sizeof(localMsg) - 1 - ll;
        if (left_space > 0)
        {
            strncat( localMsg, text, left_space );
        }
        pMsg = localMsg;
    }
    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_SAMPLE, pMsg );

	//added for logger
	if (!strcmp( text, "mounted" ) || !strcmp( text, "dismounted" ))
	{
	    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, pMsg );
	}
}

void RobotEpson::CollectStatusInfo( char* status_buffer, const char* default_text )
{
    if (!(GetRobotFlags( ) & (FLAG_NEED_RESET | FLAG_NEED_CLEAR)))
    {
        if (status_buffer != default_text)
        {
            strcpy( status_buffer, default_text );
        }
        AppendOldMessage( status_buffer );
    }
    else
    {
        if (strlen( m_ErrorMessageForOldFunction ))
        {
            strcpy( status_buffer, m_ErrorMessageForOldFunction );
            memset( m_ErrorMessageForOldFunction, 0 , sizeof(m_ErrorMessageForOldFunction) );
        }
        else
        {
            strcpy( status_buffer, "failed look at status for detail" );
        }
    }
}
void RobotEpson::AppendOldMessage( char* status_buffer )
{
    if (strlen( m_ErrorMessageForOldFunction ))
    {
        size_t ll = strlen( status_buffer );
        int space_left = MAX_LENGTH_STATUS_BUFFER - ll - 1;
        if (space_left > 0)
        {
            strcat( status_buffer, " " );
            strncat( status_buffer, m_ErrorMessageForOldFunction, space_left );
            memset( m_ErrorMessageForOldFunction, 0 , sizeof(m_ErrorMessageForOldFunction) );
        }
    }
}

void RobotEpson::NormalErrorHandle( CException *e, char* status_buffer )
{
	e->GetErrorMessage ( status_buffer,  MAX_LENGTH_STATUS_BUFFER);
	e->Delete();
    AppendOldMessage( status_buffer );
    SetRobotFlags( FLAG_REASON_CMD_ERROR );
    LOG_SEVERE( status_buffer );
}

void RobotEpson::ResetCassetteStatus( bool forced_clear )
{
    m_LeftCassette.SetStatus( CCassette::CASSETTE_UNKOWN, forced_clear );
    m_MiddleCassette.SetStatus( CCassette::CASSETTE_UNKOWN, forced_clear );
    m_RightCassette.SetStatus( CCassette::CASSETTE_UNKOWN, forced_clear );
    UpdateCassetteStatus( );
	updateForces( );
}

void RobotEpson::ClearMounted( )
{
    SetSampleState( NO_CURRENT_SAMPLE );
    SetGonioSample( 0, 0, 0 );
    //normal members
	m_pState->currentCassette = 0;
	m_pState->currentRow = 0;
	m_pState->currentColumn = 0;

	ResetCassetteStatus( );
    UpdateState( );
    UpdateSampleStatus( "robot resetted" );
}

void RobotEpson::ClearAll( )
{
	ClearRobotFlags( FLAG_NEED_RESET | FLAG_NEED_CLEAR | FLAG_NEED_USER_ACTION | FLAG_IN_ALL );
	SetDumbbellState( DUMBBELL_IN_CRADLE );

	ClearMounted( );
	ResetCassetteStatus( true ); //forced clear

    if (m_pEventListener)
    {
        char empty[2] = {0};
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, empty );
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_STEP, "0 of 100" );
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, empty );
    }
}

bool RobotEpson::ClearLowLevelError(  char* status_buffer )
{
	char called_function[128] ={0};
	try
	{
		RobotDoEvent( 3000 );

		//check
		if (m_InAbort)
		{
			strcpy( status_buffer, "aborting in process, not finished yet" );
			LOG_FINE( "skip clear low level error, aborting not finished yet" );
			return false;
		}


		if (m_NeedAbort)
		{
			strcpy( called_function, "Abort" );
			Abort( );
			RobotDoEvent( 2000 );
		}

		//this is repeated here on purpose: hutch door maybe opened any time.
		if (m_InAbort)
		{
			strcpy( status_buffer, "aborting in process, not finished yet" );
			LOG_FINE( "skip clear low level error, aborting not finished yet" );
			return false;
		}
		strcpy( called_function, "ResetAbort" );
		ResetAbort( );
		m_SPELAbortCalled = false;
		if (!m_pSPELCOM->TasksExecuting( ))
		{
			strcpy( called_function, "Reset" );
			Reset( );
		}
	}
	catch ( CException *e )
	{
    	e->GetErrorMessage ( status_buffer,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete ( );
		LOG_FINE2( "RobotEpson::ClearLowLevelError: %s failed %s", called_function, status_buffer );

		//check the fatal error
		if (strstr( status_buffer, "Abort already in cycle" ))
		{
			if (m_pEventListener)
			{
				const char fatal[] = "PLEASE REBOOT THE ROBOT PC";
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_SEVERE, fatal );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, fatal );
			}
			RobotWait( 3000 );
			robotSystemStop( );
		}

		return false;
	}
	return true;
}

bool RobotEpson::BringRobotUp( char* status_buffer )
{
	bool abort_cleared = false;
	bool heater_OK = false;
	bool home_OK = false;

    LOG_FINE( "+RobotEpson::BringRobotUp" );

	if (m_InAbort)
	{
		LOG_WARNING( "found InAbort in BringRobotUp" );
	    LOG_FINE( "-RobotEpson::BringRobotUp" );
		return false;
	}

	if (m_InEventProcess)
	{
		LOG_WARNING( "found InEventProcess in BringRobotUp" );
	    LOG_FINE( "-RobotEpson::BringRobotUp" );
		return false;
	}

	if (!ClearLowLevelError( status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::BringRobotUp %s", status_buffer );
		return false;
	}

	LOG_FINE( "turn off heater in bring up" );
	try
	{
		m_Dewar.TurnOffHeater( true );
		heater_OK = true;
	}
	catch ( CException *e )
	{
    	e->GetErrorMessage ( status_buffer,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete ( );
		LOG_FINE1( "RobotEpson::BringRobotUp: turn off heater failed %s", status_buffer );
	}

	//check if we need to turn need_clear to need_reset if robot not at home
	RobotStatus robotStatus = GetRobotFlags( );
	
	try
	{
		LOG_FINE( "check if robot is at home" );
		m_pSPELCOM->SetTimeOut ( 10 );
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
		m_pSPELCOM->SetTimeOut ( 0 );

        //check for P0(home) P1(rest)
        if (!CloseToPoint( P0, currentPosition ) && !CloseToPoint( P1, currentPosition ) && !(robotStatus & FLAG_IN_MANUAL))
        {
			LOG_FINE( "robot not at home" );
			SetRobotFlags( FLAG_REASON_NOT_HOME );
        }
		home_OK = true;
	}
	catch ( CException *e )
	{
    	e->GetErrorMessage ( status_buffer,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete ( );
		LOG_FINE1( "RobotEpson::BringRobotUp:  get current position failed %s", status_buffer );
	}

	if (heater_OK && home_OK)
	{
		m_NeedBringUp = false;
	}

    //check to see if safeguard or estop are still on
    try
    {
		LOG_FINE( "check safeguard still on or not" );
        if (m_pSPELCOM->SafetyOn( ))
        {
			if (!(GetRobotFlags( ) & FLAG_REASON_SAFEGUARD))
			{
				SetRobotFlags( FLAG_REASON_SAFEGUARD );
			}
            strcpy( status_buffer, "Safeguard still On" );
            LOG_FINE1( "-RobotEpson::BringRobotUp %s", status_buffer );
		    return false;
        }

		LOG_FINE( "check emergency stop still on or not" );
		if (GetEstop( ))
        {
			if (!(GetRobotFlags( ) & FLAG_REASON_ESTOP))
			{
				SetRobotFlags( FLAG_REASON_ESTOP );
			}
            strcpy( status_buffer, "Emergency Stop still On" );
            LOG_FINE1( "-RobotEpson::BringRobotUp %s", status_buffer );
		    return false;
        }

		LOG_FINE( "start background task" );
		StartBackgroundTask( TASKNO_LID_MONITOR, "LidMonitor" );
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::BringRobotUp failed in check EStop and Ssfe Guard %s", status_buffer );
	    return false;
	}
    LOG_FINE( "-RobotEpson::BringRobotUp OK" );
    return true;
}

void RobotEpson::LidOpenCallback( )
{
#ifndef NO_DEWAR_LID
	//reset cassette status
	ResetCassetteStatus( );
#endif
}

void RobotEpson::IOBitMonitor( long EventNumber, const char* pMsg )
{
	unsigned long value = 0;
	if (sscanf( pMsg, "%lu", &value ) != 1) return;

    m_TSBackgroundTask = time( NULL );
	IOBitMonitor( EventNumber, value );
}
void RobotEpson::IOBitMonitor( long EventNumber, unsigned long value )
{
	//these two bits are 0 when they are active
	static const unsigned long LN2_FILLING(1 << IN_LN2_FILLING);
	static const unsigned long LN2_LEVEL_NORMAL(1 << IN_LN2_LEVEL_NORMAL);
	static const unsigned long LN2_MODE_AUTO(1 << IN_LN2_MODE_AUTO);

	//input bits are updated every seconds no matter it changed or not
	//output bits are updated only if there is a change
	if (EventNumber == RobotEventListener::EVTNUM_INPUT)
	{
		time_t timeNow = time( NULL );

#ifndef SKIP_LN2_CHECK
		///////////////// LN2 AUTO FILLING //////////////////
		if (!(value & LN2_FILLING))
		{
			m_TSLN2Filling = timeNow;		
		}
		//log
		if (!(value & LN2_FILLING) && (m_LastIOInputBitMap & LN2_FILLING))
		{
			LOG_INFO( "LN2 filling started" );
		}
		if ((value & LN2_FILLING) && !(m_LastIOInputBitMap & LN2_FILLING))
		{
			LOG_INFO( "LN2 filling ended" );
		}

		//////////////// LN2 LEVEL ///////////////////////////
		if (value & LN2_LEVEL_NORMAL)
		{
			m_TSLN2Alarm = 0;	//clear the time stamp for alarm
			SetLN2Level( LN2LEVEL_HIGH );
		}
		else
		{
			//check whether the alarm bit is keeping on for more than a defined time span
			if (m_TSLN2Alarm == 0)
			{
				m_TSLN2Alarm = timeNow;
			}
			else if (m_desiredLN2Level == LN2LEVEL_HIGH)
			{
				if (timeNow > m_TSLN2Alarm + TIME_SPAN_FOR_LN2_WARNING)
				{
					if (!(GetRobotFlags( ) & FLAG_REASON_LN2LEVEL))
					{
						LOG_WARNING( "ALARM: LN2 level triggered inspection" );
					}
			        SetRobotFlags( FLAG_REASON_LN2LEVEL | FLAG_NEED_CLEAR );
				}
				if (timeNow > m_TSLN2Alarm + TIME_SPAN_FOR_LN2_LEVEL_CALIBRATION)
				{
					//this will trigger need calibration
					SetLN2Level( LN2LEVEL_LOW );
				}
			}
		}
		//////////////// LN2 MODE ///////////////////////////
		if (!(value & LN2_MODE_AUTO) && (m_LastIOInputBitMap & LN2_MODE_AUTO) && (m_desiredLN2Level == LN2LEVEL_HIGH))
		{
			if (!(GetRobotFlags( ) & FLAG_REASON_LN2LEVEL))
			{
				LOG_WARNING( "ALARM: LN2 autofilling mode triggered inspection flags " );
			}
			SetRobotFlags( FLAG_REASON_LN2LEVEL | FLAG_NEED_CLEAR );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, "Must turn on LN2 auto filling to use robot" );
			}
		}
#endif
		if (m_LastIOInputBitMap == value) return;
	}

	switch (EventNumber)
	{
	case RobotEventListener::EVTNUM_INPUT:
		m_LastIOInputBitMap = value;
		//LOG_FINEST1( "new IO input bit value=0x%lx", value );
		break;

	case RobotEventListener::EVTNUM_OUTPUT:
		m_LastIOOutputBitMap = value;	//this value is saved for DHS itself to check in safety guard open case
										//the background IOMonitor task will not be able to run.
		//LOG_FINEST1( "new IO output bit value=0x%lx", value );
		break;
	}

	///////////// Send out String update message ///////////////////////

	//for now, we only need first 16 bits.
	char outMessage[64] = {"0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0"};
	//create the message
	for (int i = 0; i < 16; ++i)
	{
		if (value & (1 << i))
		{
			outMessage[2 * i] = '1';
		}
	}

	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( EventNumber, outMessage );
	}
}

bool RobotEpson::IsAutoFilling( char* status_buffer )
{
	static const unsigned long LN2_FILLING(1 << IN_LN2_FILLING);

	if (!m_CheckAutoFilling) return false;

	if (!getAttributeFieldBool( ATTRIB_DELAY_CAL)) return false;

	time_t timeNow = time( NULL );

	if (timeNow >= m_TSLN2Filling + TIME_DELAY_AFTER_LN2_FILLING)
	{
		return false;
	}

	//fill status_buffer if not NULL
	if (status_buffer)
	{
		if (!(m_LastIOInputBitMap & LN2_FILLING))
		{
			strcpy( status_buffer, "LN2 is still filling now" );
		}
		else
		{
			time_t timeToWait = m_TSLN2Filling + TIME_DELAY_AFTER_LN2_FILLING - timeNow;

			if (timeToWait > TIME_DELAY_AFTER_LN2_FILLING) timeToWait = TIME_DELAY_AFTER_LN2_FILLING;
			time_t minutes = (timeToWait + 59) / 60;

			sprintf( status_buffer, "LN2 filling delay, please wait %lu minuts more", minutes );
		}
	}

	return true;
}

bool RobotEpson::CheckHeater( )
{
	bool passed = m_Dewar.WaitHeaterHot( );
	m_Dewar.TurnOffHeater( );
	return passed;
}

bool RobotEpson::CheckLid( bool only_status_check )
{
#ifdef NO_DEWAR_LID
	char openlid_msg[] = "CheckLid: no_lid";
    LOG_WARNING( openlid_msg );
    if (m_pEventListener)
    {
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
        m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, openlid_msg );
    }
	return true;
#endif
	//check to see if already failed or not
	BOOL in_open = m_pSPELCOM->Oport( OUT_DEWAR_LID_OPEN );
	Dewar::LidState lid_state = m_Dewar.GetLidState( );

	if ((in_open && lid_state != Dewar::OPEN) || (!in_open && lid_state != Dewar::CLOSE))
	{
		return false;
	}

	if (only_status_check)
	{
		return true;
	}

	//passed first check, we will open or close it to see it does that or not

	bool result = m_Dewar.CloseLid( );

	if (result)
	{
        switch (m_Dewar.OpenLid( ))
        {
        case Dewar::OPEN_LID_WARNING_LONG_TIME:
            {
                char openlid_msg[] = "OpenLid took very long time";
                LOG_WARNING( openlid_msg );
                if (m_pEventListener)
                {
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, openlid_msg );
                }
            }
			break;

		case Dewar::OPEN_LID_OK:
            break;

        case Dewar::OPEN_LID_FAILED:
			{
				char openlid_msg[] = "OpenLid failed in check lid";
				LOG_SEVERE( openlid_msg );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, openlid_msg );
				}
			}
        default:
			result = false;
        }
	}

	if (!in_open)
	{
		//need to test close again
		if (!m_Dewar.CloseLid( ))
		{
			result = false;
		}
	}

	return result;
}

void RobotEpson::SelfPollIOBit( )
{
	volatile unsigned long input_dummy = 0;
	volatile unsigned long output_dummy = 0;
    SelfPollIOBit( input_dummy, output_dummy );
}
bool RobotEpson::SelfPollIOBit( volatile unsigned long& input, volatile unsigned long& output )
{
	if (m_NeedBringUp)
	{
		LOG_WARNING( "found need bring robot up in SelfPollIObit" );
		return false;
	}

	if (m_InAbort)
	{
		LOG_WARNING( "found InAbort in SelfPollIObit" );
		return false;
	}

	if (m_InEventProcess)
	{
		LOG_WARNING( "found InEventProcess in SelfPollIObit" );
		return false;
	}

	if (m_SPELAbortCalled)
	{
		LOG_WARNING( "found abort called in SelfPollIObit" );
		return false;
	}

	RobotDoEvent( 10 );

	//get input bits
	input  = m_pSPELCOM->In( 0 ) + (m_pSPELCOM->In( 1 ) << 8);

	//get output bits: function Out is set bits, not reading
	output = 0;
	for (short i = 0; i < 16; ++i)
	{
		output |= m_pSPELCOM->Oport( i ) << i;
	}

	//we simulate the IOMonitor background task do:
	//always send input bits, only send out output bits if changed.
	//check lid opend manually.
	static const unsigned long IN_LID_CLOSED(1 << IN_DEWAR_LID_CLOSE);
	static const unsigned long OUT_OPEN_LID(1 << OUT_DEWAR_LID_OPEN);

    //if lid becomes not closed and not caused by output
	if (!(input  & IN_LID_CLOSED) &&
		(m_LastIOInputBitMap & IN_LID_CLOSED) &&
		!(output & OUT_OPEN_LID))
	{
		LidOpenCallback( );
	}

	IOBitMonitor( RobotEventListener::EVTNUM_INPUT, input );
	if (m_LastIOOutputBitMap != output)
	{
		IOBitMonitor( RobotEventListener::EVTNUM_OUTPUT, output );
	}

	return true;
}

bool RobotEpson::WaitSw( short BitNumber, BOOL Condition, int TimeInterval )
{
    volatile unsigned long input = 0;
    volatile unsigned long output = 0;
    bool result = false;


	//LOG_FINE3( "+RobotEpson::WaitSw %d %d %d", (int)BitNumber, (int)Condition, (int)TimeInterval );

	if (m_NeedBringUp)
	{
		LOG_WARNING( "found need bring robot up in WaitSw" );
		return false;
	}

	if (m_InAbort)
	{
		LOG_WARNING( "found InAbort in WaitSw" );
		return false;
	}

	if (m_InEventProcess)
	{
		LOG_WARNING( "found InEventProcess in WaitSw" );
		return false;
	}

	if (m_SPELAbortCalled)
	{
		LOG_WARNING( "found abort called in WaitSw" );
		return false;
	}

    //this is in case the bit turned real quick:
    //like in normal case of gripper
    m_pSPELCOM->WaitSw( BitNumber, Condition, 1.0f );
    result = !m_pSPELCOM->TW( );
    if (result || TimeInterval <= 1)
    {
        SelfPollIOBit( input, output );
		//LOG_FINE1( "-RobotEpson::WaitSw Got it at first try: result=%d", (int)result );
        return result;
    }

    //TimeInterval > 1 and bit not show up in 1 second
    unsigned long condition_mask = 1 << BitNumber;
    unsigned long condition_value = Condition ? condition_mask : 0;
    --TimeInterval; //we already waited 1 second
    for (int i = 0; i < TimeInterval; ++i)
    {
		//LOG_FINEST1( "in WaitSW, i=%d", i );
        //get IO Bits
        if (!SelfPollIOBit( input, output ))
		{
			return false;
		}

        //check if satisfy condition
        if ((input & condition_mask) == condition_value)
        {
			//LOG_FINE1( "got desired bit value at i=%d", i);
            result = true;
            break;
        }
        
        //check if abort or stop
        //if (m_FlagAbort)
        //{
		//	LOG_FINE( "got abort flag" );
        //    break;
        //}
        //sleep 1 second
		RobotDoEvent( 1000 );
    }

    //at the end, do one more IO update
    SelfPollIOBit( input, output );

	if (!result)
	{
		input  = m_pSPELCOM->In( 0 ) + (m_pSPELCOM->In( 1 ) << 8);
        if ((input & condition_mask) == condition_value)
        {
			LOG_FINE( "got desired bit value at the end checking" );
            result = true;
        }
	}

	//LOG_FINE1( "-RobotEpson::WaitSw: result=%d", (int)result );
    return result;
}

void RobotEpson::CheckModel( )
{
	CString model( m_pSPELCOM->RobotModel( ) );

	if (!strncmp( model, "ES55", 4 ) || !strncmp( model, "E2S55", 5 ))
	{
		m_ArmLength = 550;
		m_Arm1Length = 315;
		m_Arm2Length = 235;
		m_MinR = 203;
		m_Arm1AngleLimit = 0.95993f;	//(180-125) degree
	}
	else if (!strncmp( model, "ES45", 4 ) || !strncmp( model, "E2S45", 5 ))
	{
		m_ArmLength = 450;
		m_Arm1Length = 215;
		m_Arm2Length = 235;
		m_MinR = 174;
		m_Arm1AngleLimit = 1.308997f;	//(180-105) degree

		//forbidden rectangle
		m_RectangleX0 = -165;
		m_RectangleX1 = 165;
		m_RectangleY0 = -450;
		m_RectangleY1 = 0;
	}
	else
	{
		LOG_WARNING1( "unknow robot model %s, range check disabled", model );
	}
}

bool RobotEpson::GoThroughStripper( char* status_buffer, bool retakeMagnet )
{
    short tl = m_pSPELCOM->GetTool( );

	m_pSPELCOM->Go( (COleVariant)"P80" );
	SetCurrentPoint ( P80 );
	m_pSPELCOM->Move( (COleVariant)"P81" );
	SetCurrentPoint ( P81 );
	m_pSPELCOM->Move( (COleVariant)"P82" );
	SetCurrentPoint ( P82 );
	m_pSPELCOM->Move( (COleVariant)"P83" );
	SetCurrentPoint ( P83 );

	//putback magnet
	m_pSPELCOM->Tool( 0 );
	m_pSPELCOM->LimZ( N2_LEVEL );
	m_pSPELCOM->Jump( (COleVariant) "P4" );
	PutMagnet( );

	//stripp again to knock off crystal from stripper
	m_pSPELCOM->Tool( tl );
	m_pSPELCOM->Jump( (COleVariant)"P83" );
	SetCurrentPoint ( P83 );

	m_pSPELCOM->Move( (COleVariant)"P84" );
	SetCurrentPoint ( P84 );
	m_pSPELCOM->Move( (COleVariant)"P83" );
	SetCurrentPoint ( P83 );

	//re-take magnet
	m_pSPELCOM->Tool( 0 );
	m_pSPELCOM->Jump( (COleVariant)"P3" );
	SetCurrentPoint ( P3 );

    SetPlacerSample( 0, 0, 0 );
	SetSampleState( NO_CURRENT_SAMPLE );

	if (!retakeMagnet) return true;
	if (!GetMagnet( ))
	{
		strcpy( status_buffer, "failed to get dumbbell" );
		return false;
	}
	return true;
}

bool RobotEpson::StripDumbbell( void )
{
	char message[1024] = {0};

	//check whether the stripper is enable or pass the threshold
	if (!m_stripperInstalled)
	{
		strcpy( message, "stripper not installed or not calibrated" );
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		return false;
	}	

	int threshold = getAttributeFieldInt( ATTRIB_PIN_STRIP_THRESHOLD );
	if (threshold == 0)
	{
		strcpy( message, "pin stripper not enabled" );
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		return false;
	}

	//check pre-conditions to strip dumbbell
    short tl = m_pSPELCOM->GetTool( );
	switch (tl)
	{
	case 2:
		break;

	case 1:
	default:
		strcpy( message, "cannot start strip dumbbell for port jam: only implemented for placer" );
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		return false;
	}

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
	if (GetCurrentPoint( ) != P52 || !CloseToPoint( P52, currentPosition ))
	{
		strcpy( message, "cannot start strip dumbbell for port jam: not in right point" );
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		return false;
	}

	if (threshold < 0 || m_pState->num_pin_stripped_short_trip >= (unsigned long)threshold)
	{
		SetRobotFlags( FLAG_NEED_USER_ACTION );
		//save all points so that we can resume even after reboot
		SavePoints( );
		if (threshold < 0)
		{
			strcpy( message, "port jam need user action" );
		}
		else
		{
			sprintf( message, "strip pin reached threshold %d", threshold );
		}
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		UpdateSampleStatus( "port jam need user action", true );
		return false;
	}


	//move to above post position
	MoveFromPortToPost( );

	//strip placer
	UpdateSampleStatus( "stripping dumbbell for port jam", true );
	
	m_pSPELCOM->Tool( tl );
	if (!GoThroughStripper( message ))
	{
		LOG_WARNING( message );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		}
		return false;
	}
	
	++(m_pState->num_pin_stripped);
	++(m_pState->num_pin_stripped_short_trip);
	UpdateState( );

	sprintf( message, "There is a chance that sample from %c%c%d may be stripped.", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
	LOG_WARNING( message );
	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, message );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
	}
	//go back to the origianl position
	m_pSPELCOM->Tool( tl );
	MoveToPortViaStandby( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn );
	return true;
}
bool RobotEpson::StandbyAtCoolPoint ( )
{
	bool success = false;

    LPoint currentPoint = GetCurrentPoint ( );

    m_pSPELCOM->Tool( 0 );
	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

    //check real robot position against what we remembered
    switch ( currentPoint )
	{
	case P1:
	case P2:
	case P3:
	case P18:
    case P21:
        if (!CloseToPoint( currentPoint, currentPosition ) )
        {
			LOG_WARNING3( "(%f, %f) not close to point %d", currentPosition.x, currentPosition.y, (int)currentPoint );
            return false;
        }
        break;

    case P22:
        if (!CloseToPoint( currentPoint, currentPosition, 100) )
        {
			LOG_WARNING2( "(%f, %f) not close to P22 r= 100", currentPosition.x, currentPosition.y );
            return false;
        }
        break;

    default:
		LOG_WARNING1( "not supported current point %d", (int)currentPoint );
        return false;
    }

	m_Dewar.TurnOffHeater( true );

	setRobotSpeed( SPEED_IN_LN2 );
    switch ( GetCurrentPoint ( ) )
	{
    case P21:
    case P22:
		{
			//move away from gonometer by 5 mm
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(%3f) +Y(%.3f)",
				5.0f * m_goniometerDirScale.cosValue,
				5.0f * m_goniometerDirScale.sinValue );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
		}
		m_pSPELCOM->Move ( (COleVariant)"P22" );
		SetCurrentPoint ( P22 );

		switch (m_Dewar.OpenLid( ))
        {
        case Dewar::OPEN_LID_WARNING_LONG_TIME:
            {
                char openlid_msg[] = "OpenLid took very long time";
                LOG_WARNING( openlid_msg );
                if (m_pEventListener)
                {
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
                }
            }
            //falling through
        case Dewar::OPEN_LID_OK:
            MoveFromGoniometerToRescuePoint( );
		    success = true;
            break;

        case Dewar::OPEN_LID_FAILED:
        default:
            strcpy( m_ErrorMessageForOldFunction, "OpenLid timeout" );
            LOG_WARNING( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_LID_JAM );
            SetMotorsOn( false );
        }
        break;

	case P1:
	case P2:
	case P3:
	case P18:
        switch (m_Dewar.OpenLid( ))
        {
        case Dewar::OPEN_LID_WARNING_LONG_TIME:
            {
                char openlid_msg[] = "OpenLid took very long time";
                LOG_WARNING( openlid_msg );
                if (m_pEventListener)
                {
                    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );
                }
            }
            //falling through
        case Dewar::OPEN_LID_OK:
			setRobotSpeed( SPEED_FAST );
			m_pSPELCOM->Move ( (COleVariant)"P* :Z(0)" );
#ifdef MIXED_ARM_ORIENTATION
			m_pSPELCOM->Go ( (COleVariant)"P3 :Z(0)" );
#else
			m_pSPELCOM->Move ( (COleVariant)"P3 :Z(0)" );
#endif
			setRobotSpeed( SPEED_IN_LN2 );
			m_pSPELCOM->Move ( (COleVariant)"P3");
			SetCurrentPoint ( P3  );
		    success = true;
            break;

        case Dewar::OPEN_LID_FAILED:
        default:
            strcpy( m_ErrorMessageForOldFunction, "OpenLid timeout" );
            LOG_WARNING( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, m_ErrorMessageForOldFunction );
			}
            SetRobotFlags( FLAG_REASON_LID_JAM );
        }
		break;
	}
	
	if ( success )
	{
		if (m_stripperInstalled)
		{
			COleVariant cooling_point( m_strCoolingPoint );
			m_pSPELCOM->Move( cooling_point );
		}
		OpenGripper ( ); //ignore errors here.
	}
	return success;
}
void RobotEpson::MoveFromGoniometerToRescuePoint ( void )
{
	if (!CloseGripper( ))
	{
		SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_CMD_ERROR );
		SetMotorsOn( false );
        if (m_pEventListener)
        {
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "gripper open while move from goniometer to rescue place" );
        }
		throw new RobotException( "software_severe gripper open while travel to gonometer" );
	}

    UpdateSampleStatus( "go home from goniometer" );
	setRobotSpeed( SPEED_FAST );
    m_pSPELCOM->Move( (COleVariant)"P38 CP" );
    m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18 CP" );
	SetCurrentPoint( P18 );

#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go ( (COleVariant)"P3 :Z(0)" );
#else
	m_pSPELCOM->Move ( (COleVariant)"P3 :Z(0)" );
#endif
	setRobotSpeed( SPEED_IN_LN2 );
	m_pSPELCOM->Move ( (COleVariant)"P3");
	SetCurrentPoint ( P3  );
}

//no safety check, only called internally
void RobotEpson::adjustForHamptonPinIfFlagged( void )
{
	const float PI = 3.14159265359f;

	//need change if in the future goniometer not along +Y axis
	if (m_hamptonPin)
	{
		char point[128] = {0};
		//float angle = m_dumbbellOrientation * PI / 2.0f + PI;
		float DX = -0.5f * m_dumbbellDirScale.cosValue;
		float DY = -0.5f * m_dumbbellDirScale.sinValue;
		sprintf( point, "P* +X(%.3f) +Y(%.3f)", DX, DY );
		m_pSPELCOM->Move( (COleVariant)point );
	}
}
bool RobotEpson::retryWithPositionAdjust( void )
{
	const float PI = 3.14159265359f;

	//need change if in the future goniometer not along +Y axis
	if (m_hamptonPin)
	{
		char point[128] = {0};
		//float angle = m_dumbbellOrientation * PI / 2.0f;
		float DX = 0.5f * m_dumbbellDirScale.cosValue;
		float DY = 0.5f * m_dumbbellDirScale.sinValue;
		sprintf( point, "P*+X(%.3f)+Y(%.3f)", DX, DY );
		m_pSPELCOM->Move( (COleVariant)point );
	}
	else
	{
		char point[128] = {0};
		//float angle = m_dumbbellOrientation * PI / 2.0f + PI;
		float DX = -0.5f * m_dumbbellDirScale.cosValue;
		float DY = -0.5f * m_dumbbellDirScale.sinValue;
		sprintf( point, "P*+X(%.3f)+Y(%.3f)", DX, DY );
		m_pSPELCOM->Move( (COleVariant)point );
	}

	if (!CloseGripper( ))
	{
		return false;
	}

	//OK, success after adjust position, save it
	char message[1024] = {0};
	if (m_hamptonPin)
	{
		m_hamptonPin = 0;
		strcpy( message, "success after positin adjust: removed hampton pin adjust" );
	}
	else
	{
		m_hamptonPin = 1;
		strcpy( message, "success after positin adjust: added hampton pin adjust" );
	}

	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
	}

	return true;
}
void RobotEpson::assignPoint( LPoint pointNumber, const PointCoordinate& point )
{
	m_pSPELCOM->SetPoint( (COleVariant)(short)pointNumber, 
					point.x, 
					point.y, 
					point.z, 
					point.u, 
					0, 
					(short)point.o );
}
void RobotEpson::retrievePoint( LPoint pointNumber, PointCoordinate& point ) const
{
	//do not use string like "P1" to GetPoint of "P1".
	//It will return "P*" in some version of drivers.
	//always use number directly
	COleVariant Vnum( (short)pointNumber );
	short local_o = 0;
	m_pSPELCOM->GetPoint( Vnum, &point.x, &point.y, &point.z, &point.u, &point.localNum, &local_o );
	point.o = (PointCoordinate::ArmOrientation)local_o;
}
void RobotEpson::GetCurrentPosition( PointCoordinate& point ) const
{
    static const COleVariant currentPoint( "P*" );

	point.x = m_pSPELCOM->CX( currentPoint );
	point.y = m_pSPELCOM->CY( currentPoint );
	point.z = m_pSPELCOM->CZ( currentPoint );
	point.u = m_pSPELCOM->CU( currentPoint );
	point.o = m_pSPELCOM->Pls( 2 ) > 0 ? PointCoordinate::ARM_ORIENTATION_RIGHTY : PointCoordinate::ARM_ORIENTATION_LEFTY;
	point.localNum = 0; //always 0, we do not use any local coordinate system.
}
