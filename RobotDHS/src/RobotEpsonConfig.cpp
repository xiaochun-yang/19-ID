#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "Cassette.h"
#include "log_quick.h"

#include <math.h>

BOOL RobotEpson::CFGStripperTakeMagnet(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGStripperTakeMagnet" );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
    }

    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
    }

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_GONIOMETER:
    case SAMPLE_ON_PLACER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_PICKER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
    }

	if (GetDumbbellState ( ) != DUMBBELL_IN_CRADLE) 
	{
		strcpy( status_buffer, "dumbbell not in cradle" );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
	}

	//////////////////////////take dumbbell and move to P1 with lid open////////
	//from home to cool point
    if (!GenericPrepare( 3, status_buffer ))
    {
        UpdateSampleStatus( status_buffer );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
	}
	//take magnet
    if (!GetMagnet( ))
	{
		strcpy( status_buffer, "failed to get dumbbell" );
        LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
		return TRUE;
	}
	//jump to P1
    m_pSPELCOM->LimZ( 0.0f );
	m_pSPELCOM->Jump( COleVariant( "P1" ) );

    SetDumbbellState( DUMBBELL_RAISED );

    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGStripperTakeMagnet %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGStripperGoHome(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGStripperGoHome" );

    //check pre-conditions
	if (GetDumbbellState ( ) != DUMBBELL_RAISED) 
	{
		strcpy( status_buffer, "not in stripper testing" );
        LOG_FINE1( "-RobotEpson::CFGStripperGoHome %s", status_buffer );
		return TRUE;
	}

	try
	{
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
        //check for P1(rest)
        if (!CloseToPoint( P1, currentPosition ))
        {
			strcpy( status_buffer, "not in stripper testing" );
			LOG_FINE1( "-RobotEpson::CFGStripperGoHome %s", status_buffer );
			return TRUE;
        }
		//////////////put back dumbell and go home////////
		m_pSPELCOM->Move ( (COleVariant)"P2" );
		SetCurrentPoint ( P2 );
		m_pSPELCOM->Move ( (COleVariant)"P4" );
		SetCurrentPoint ( P4 );
		PutMagnet ( );
		if (m_desiredLN2Level == LN2LEVEL_HIGH)
		{
			m_Dewar.TurnOnHeater( );
		}
		MoveTongHome( );
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	    LOG_FINE1( "-RobotEpson::CFGStripperGoHome %s", status_buffer );
		return TRUE;
	}
	
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGStripperGoHome %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGStripperRun(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGStripperRun" );

	if (!m_stripperInstalled)
	{
		strcpy( status_buffer, "stripper not installed" );
        LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
		return TRUE;
	}

    //check pre-conditions
	if (GetDumbbellState ( ) != DUMBBELL_RAISED) 
	{
		strcpy( status_buffer, "need to run get magnet first" );
        LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
		return TRUE;
	}

	try
	{
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
        //check for P1(rest)
        if (!CloseToPoint( P1, currentPosition ))
        {
			strcpy( status_buffer, "need to run get magnet first" );
			LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
			return TRUE;
        }
		setRobotSpeed( SPEED_IN_LN2 );
		//////////////strip the cyrstal and come back///////////////
		//strip placer
		m_pSPELCOM->Tool( 0 );
		m_pSPELCOM->Move ( (COleVariant)"P2" );
		SetCurrentPoint ( P2 );
		m_pSPELCOM->Move ( (COleVariant)"P4" );
		SetCurrentPoint ( P4 );

		m_pSPELCOM->Tool( 2 );
		if (!GoThroughStripper( status_buffer ))
		{
			LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
			return TRUE;
		}

		m_pSPELCOM->Tool( 0 );
		m_pSPELCOM->Move ( (COleVariant)"P* :Z(-1)" );
#ifdef MIXED_ARM_ORIENTATION
		m_pSPELCOM->Go ( (COleVariant)"P1" );
#else
		m_pSPELCOM->Move ( (COleVariant)"P1" );
#endif
		SetCurrentPoint ( P1 );
	    SetDumbbellState( DUMBBELL_RAISED );
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	    LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
		return TRUE;
	}
	
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGStripperRun %s", status_buffer );
    return TRUE;
}


BOOL RobotEpson::CFGPortJamAction(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGPortJamAction" );

	if (strcmp( argument, "strip" ))
	{
		ClearRobotFlags( FLAG_NEED_USER_ACTION );
		SetRobotFlags( FLAG_REASON_PORT_JAM | FLAG_NEED_RESET );

		strcpy( status_buffer, "nomal set to need reset" );
        LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
		return TRUE;
	}

	switch (GetSampleState( ))
	{
	case NO_CURRENT_SAMPLE:
	case SAMPLE_ON_PLACER:
	case SAMPLE_ON_GONIOMETER:
		break;

	case SAMPLE_ON_PICKER:
		strcpy( status_buffer, "not support picker stripping" );
        LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
		return TRUE;

	default:
		strcpy( status_buffer, "sample state wrong" );
        LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
		return TRUE;
	}

	LPoint currentPoint = GetCurrentPoint( );
	switch (currentPoint)
	{
	case P0:
	case P1:
	case P2:
	case P3:
		if (GetDumbbellState( ) != DUMBBELL_IN_CRADLE)
		{
			strcpy( status_buffer, "dumbbell not in cradle" );
			LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
			return TRUE;
		}
		break;

	case P4:
	case P6:
	case P52:
		if (GetDumbbellState( ) != DUMBBELL_IN_TONG)
		{
			strcpy( status_buffer, "not holding the dumbbell" );
			LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
			return TRUE;
		}
		break;

	default:
		strcpy( status_buffer, "cannot start strip dumbbell for port jam: not in supported places" );
		LOG_WARNING( status_buffer );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
		}
	    LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
		return TRUE;
	}
	try
	{
		switch (currentPoint)
		{
		case P0:
		case P1:
		case P2:
		case P3:
		case P4:
		case P6:
			m_pSPELCOM->Tool( 0 );
			break;

		case P52:
			m_pSPELCOM->Tool( 2 );
			break;
		}

		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
		//////case 1: original, the robot will power off standing by the jammed port
		//////case 2: new: tong is back in cradle,
		if (!CloseToPoint( currentPoint, currentPosition ))
		{
			strcpy( status_buffer, "cannot start strip dumbbell for port jam: not really at the right point" );
			LOG_WARNING( status_buffer );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
			}
			LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
			return TRUE;
		}

		if (!GetMotorsOn( ))
		{
			SetMotorsOn( true );
		}
		SetPowerHigh( true );

		switch (currentPoint)
		{
		case P0:
		case P1:
			if (!GenericPrepare( 30, status_buffer ))
			{
				return true;
			}
			//fall through
		case P3:
		    if (!GetMagnet( ))
			{
				strcpy( status_buffer, "failed to get dumbbell" );
				LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
				return TRUE;
			}
			//fall through
		case P6:
			m_pSPELCOM->Tool( 0 );
			CloseGripper( true ); //ignore errors here 
			m_pSPELCOM->Move ( (COleVariant)"P4" );
			SetCurrentPoint ( P4 );
		case P4:
			break;

		case P52:
			//move to above post position
			m_pSPELCOM->Tool( 2 );
			MoveFromPortToPost( );
			break;

		default:
			strcpy( status_buffer, "wrong place" );
			LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
			return TRUE;
		}


		//strip placer
		UpdateSampleStatus( "stripping dumbbell for port jam", true );
	
		m_pSPELCOM->Tool( 2 );
		if (!GoThroughStripper( status_buffer, false ))
		{
			LOG_WARNING( status_buffer );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
			}
			return TRUE;
		}
	
		++(m_pState->num_pin_stripped);
		++(m_pState->num_pin_stripped_short_trip);
		UpdateState( );

		sprintf( status_buffer, "There is a chance that sample from %c%c%d may be stripped.", m_pState->currentCassette, m_pState->currentColumn, m_pState->currentRow );
		LOG_WARNING( status_buffer );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
		}

		//////////////go home////////
		MoveTongHome( );
		if (GetMotorsOn( ))
		{
			ClearRobotFlags( FLAG_REASON_PORT_JAM | FLAG_NEED_USER_ACTION | FLAG_NEED_RESET );
		}
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	    LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
		return TRUE;
	}
	
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGPortJamAction %s", status_buffer );
    return TRUE;
}


BOOL RobotEpson::CFGResetAllowed( const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGResetAllowed" );

	SetRobotFlags ( FLAG_IN_RESET );

    //init return statut to "0" means bad
    strcpy( status_buffer, "normal 0" );   //max length is MAX_LENGTH_STATUS_BUFFER

    if (!BringRobotUp( status_buffer))
    {
        LOG_FINE1( "-RobotEpson::CFGResetAllowed %s", status_buffer );
		return TRUE;
    }

    //whether in areas we can handle automatically (move to P0 or P1)
	if (!InRecoverablePosition( ))
    {
        strcpy( status_buffer, "Not in recoverable position, please manually move robot close to heater" );
		SetMotorsOn( false );
        LOG_FINE1( "-RobotEpson::CFGResetAllowed %s", status_buffer );
		return TRUE;
    }

	strcpy ( status_buffer, "normal 1" );

	try
	{
		if (!GetMotorsOn( ))
        {
			SetMotorsOn( true );
        }
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGResetAllowed robot function SetMotorsOn failed %s", status_buffer );
		return TRUE;
	}

	try
	{
		SetPowerHigh ( false );
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGResetAllowed robot function SetPowerHigh failed %s", status_buffer );
		return TRUE;
	}

    LOG_FINE1( "-RobotEpson::CFGResetAllowed %s", status_buffer );

    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGMoveToCheckPoint(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGMoveToCheckPoint" );


	if (!(GetRobotFlags( ) & FLAG_IN_RESET))
	{
        strcpy( status_buffer, "RobotDHSError: not in reset" );
        LOG_FINE1( "-RobotEpson::CFGMoveToCheckPoint %s", status_buffer );
		return TRUE;
	}

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
		strcpy( status_buffer, "RobotDHSError: BAD argument, should be dx dy dz du" );
        LOG_FINE1( "-RobotEpson::CFGMoveToCheckPoint %s", status_buffer );
		return TRUE;
    }

	try
	{
		SetPowerHigh ( false );
		if (!MoveToCheckGripperPos( dx, dy, dz, du ))
		{
			SetMotorsOn ( false );
			strcpy( status_buffer, "RobotDHSError: robot can not move from current position" );
            LOG_FINE1( "-RobotEpson::CFGMoveToCheckPoint %s", status_buffer );
		    return TRUE;
		}
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGMoveToCheckPoint %s", status_buffer );
		return TRUE;
	}

	if (GetDumbbellState ( ) == DUMBBELL_IN_TONG)
	{
		SetDumbbellState( DUMBBELL_RAISED );
	}
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGMoveToCheckPoint %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGOpenGripper(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGOpenGripper" );


	if (!(GetRobotFlags( ) & FLAG_IN_RESET))
	{
        strcpy( status_buffer, "RobotDHSError: not in reset" );
        LOG_FINE1( "-RobotEpson::CFGOpenGripper %s", status_buffer );
		return TRUE;
	}

	try
	{
		if (!OpenGripper( ))
        {
            strcpy( status_buffer, "open gripper failed" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CFGOpenGripper %s", status_buffer );
            return TRUE;
        }
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGOpenGripper %s", status_buffer );
		return TRUE;
	}

	CurrentSampleState currentSampleState = GetSampleState( );

	if (GetDumbbellState ( ) == DUMBBELL_RAISED) 
	{
		SetDumbbellState ( DUMBBELL_OUT );
		if ( currentSampleState == SAMPLE_ON_PICKER || currentSampleState == SAMPLE_ON_PLACER )
        {
		    SetSampleState( NO_CURRENT_SAMPLE );
			SetPickerSample( 0, 0, 0, false );
			SetPlacerSample( 0, 0, 0 );
        }
	}

	if ( currentSampleState == SAMPLE_ON_TONG || currentSampleState == SAMPLE_ON_GONIOMETER )
    {
        SetSampleState( NO_CURRENT_SAMPLE );
		SetTongSample( 0, 0, 0, false );
		SetGonioSample( 0, 0, 0 );
    }

    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGOpenGripper %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGHeatGripper(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGHeatGripper %s", argument );

    UINT heatingTime = 0;

    sscanf( argument, "%u", &heatingTime );

	if (heatingTime ==0)
	{
		//zero means wait forever in our program
		heatingTime = 2;
	}

	if (heatingTime > 40)
	{
		heatingTime = 40;
	}

	try 
	{
        m_Dewar.TurnOnHeater( );
		if (!MoveToHome( ))
        {
            strcpy( status_buffer, "RobotDHSError: can not move home from this position" );
            LOG_FINE1( "-RobotEpson::CFGHeatGripper %s", status_buffer );
            return TRUE;
        }
        if (!m_Dewar.WaitHeaterHot( /* default 60 seconds */ ))
        {
            strcpy( status_buffer, "RobotDHSError: heater failed" );
            SetRobotFlags( FLAG_REASON_HEATER_FAIL );
            LOG_FINE1( "-RobotEpson::CFGHeatGripper %s", status_buffer );
            return TRUE;
        }
        RobotWait( heatingTime * 1000 );
		Dance ( );
        m_Dewar.TurnOffHeater( );

		//decide whether turn on high power mode
		//this function is called more than once in the resetting procedure.  The last call has arguments like "20 done"
		if (strstr( argument, "done"))
		{
	        SetPowerHigh( true );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGHeatGripper %s", status_buffer );
		return TRUE;
	}
	
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGHeatGripper %s", status_buffer );
    return TRUE;
}


BOOL RobotEpson::CFGCheckDumbbell(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGCheckDumbbell" );

	if (!(GetRobotFlags( ) & FLAG_IN_RESET))
	{
        strcpy( status_buffer, "RobotDHSError: not in reset" );
        LOG_FINE1( "-RobotEpson::CFGCheckDumbbell %s", status_buffer );
		return TRUE;
	}

	try 
	{
		if (!CheckDumbbell( ))
		{
            strcpy( status_buffer, "RobotDHSError: restart reset" );
            LOG_FINE1( "-RobotEpson::CFGCheckDumbbell %s", status_buffer );
		    return TRUE;
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGCheckDumbbell %s", status_buffer );
		return TRUE;
	}
	
    SetDumbbellState( DUMBBELL_RAISED );

    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGCheckDumbbell %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGReturnDumbbell(  const char argument[], char status_buffer[] )
{
    LOG_FINE( "+RobotEpson::CFGReturnDumbbell" );

	if (!(GetRobotFlags( ) & FLAG_IN_RESET))
	{
        strcpy( status_buffer, "RobotDHSError: not in reset" );
        LOG_FINE1( "-RobotEpson::CFGReturnDumbbell %s", status_buffer );
		return TRUE;
	}

	try 
	{
        if (ReturnDumbbell( ))
        {
            SetDumbbellState( DUMBBELL_IN_CRADLE );
        }
		else
		{
			strcpy( status_buffer, "return dumbbell failed.  Restart Reset procedure" );
			LOG_FINE1( "-RobotEpson::CFGReturnDumbbell %s", status_buffer );
			return TRUE;
		}

        if (m_desiredLN2Level == LN2LEVEL_HIGH)
        {
            m_Dewar.TurnOnHeater( );    //it will be turned off in following message of heatGripper
        }

		//clear everything
		ClearAll( );

		//clear up indiviual reason flags:
		RobotStatus flags_not_to_clear = FLAG_REASON_COLLISION |
										 FLAG_REASON_INIT |
										 FLAG_REASON_TOLERANCE |
										 FLAG_REASON_LN2LEVEL;
		ClearRobotFlags( FLAG_REASON_ALL & (~flags_not_to_clear) );

		//start io monitor
		//StartBackgroundTask( TASKNO_LID_MONITOR, "LidMonitor" );
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGReturnDumbbell %s", status_buffer );
		return TRUE;
	}
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGReturnDumbbell %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGProbe( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGProbe %s", argument );

	//parse and check argument
	bool bad_argument = false;

	unsigned long length = strlen( argument );

	//                 c p p p p c p p p p c p p p p
	//the argument is "1 1 1 1 1 1 1 1 1 1 1 1 1 1 1" for 4 ports per cassette

	unsigned long length_expected = 3 * (CCassette::NUM_COLUMN * CCassette::NUM_ROW * 2 + 2) -1;

	if (length != length_expected)
	{
		LOG_FINE2("bad argument len = %lu != %lu", length, length_expected );
		bad_argument = true;
	}

	for (unsigned long i = 0; i < length; ++i)
	{
		if (i % 2)
		{
			if (argument[i] != ' ')
			{
				LOG_FINE2("bad argument at %i %c should be space", i, argument[i]);
				bad_argument = true;
				break;
			}
		}
	}

	if (bad_argument)
	{
        //SetRobotFlags( FLAG_REASON_BAD_ARG );
        strcpy( status_buffer, "FAILED: invalid argument" );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
        return TRUE;
	}

	//check robot state
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need reset or inspection first" );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_NEED_CAL_MAGNET)
    {
		strcpy( status_buffer, "need do toolset calibration first" );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
    }

    if (robotStatus & FLAG_NEED_CAL_CASSETTE)
    {
		strcpy( status_buffer, "need do cassette calibration first" );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
    }

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_GONIOMETER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
    }

	//set need_probe flags
	if (!ProcessProbeArgument( argument, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );
		return TRUE;
	}
	//do the job
	UpdateSampleStatus( "probe" );
	try
	{
		m_inCmdProbing = true;	//force probe even attributes are off
		bool result = GenericPrepare( 30, status_buffer );
		m_inCmdProbing = false; //no need, it will be cleared on init of operation.

		MoveTongHome( );
		if (result)
		{
			strcpy( status_buffer, "normal probe done" );
		}
	}
	catch ( CException *e )
	{
		UpdateSampleStatus( "" );
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGProbe robot function failed %s", status_buffer );
		return TRUE;
	}

	UpdateSampleStatus( "" );
    LOG_FINE1( "-RobotEpson::CFGProbe %s", status_buffer );

    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGCheckHeater( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGCheckHeater %s", argument );

	bool in_selftest = !strcmp( argument, "selftest" );

	try
	{
		ResetAbort( );

		if (!CheckHeater( ))
		{
            strcpy( status_buffer, "check_heater failed" );
            SetRobotFlags( FLAG_REASON_HEATER_FAIL );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
			if (!in_selftest)
			{
				ClearRobotFlags( FLAG_REASON_HEATER_FAIL );
			}
            strcpy( status_buffer, "normal check_heater passed" );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGCheckHeater %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGCheckGripper( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGCheckGripper %s", argument );

	bool in_selftest = !strcmp( argument, "selftest" );

	try
	{
		ResetAbort( );
		if (!CheckGripper( ))
		{
			strcpy( status_buffer, "check_gripper failed" );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
			if (!in_selftest)
			{
				ClearRobotFlags( FLAG_REASON_GRIPPER_JAM );
			}
            strcpy( status_buffer, "normal check_gripper passed" );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGCheckGripper %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGCheckLid( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGCheckLid %s", argument );

	bool in_selftest = !strcmp( argument, "selftest" );

	bool only_status_check = in_selftest;

	try
	{
		ResetAbort( );
		if (!CheckLid( only_status_check ))
		{
			strcpy( status_buffer, "check_lid failed" );
            SetRobotFlags( FLAG_REASON_LID_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
            strcpy( status_buffer, "normal check_lid passed" );
			if (!in_selftest)
			{
				ClearRobotFlags( FLAG_REASON_LID_JAM );
			}
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGCheckLid %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGLLOpenGripper( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGLLOpenGripper %s", argument );

	try
	{
		ResetAbort( );
		if (!OpenGripper( ))
		{
			strcpy( status_buffer, "low level open gripper failed" );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
            strcpy( status_buffer, "normal open gripper OK" );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGLLOpenGripper %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGLLCloseGripper( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGLLCloseGripper %s", argument );

	try
	{
		ResetAbort( );
		if (!CloseGripper( ))
		{
			strcpy( status_buffer, "low level close gripper failed" );
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
            strcpy( status_buffer, "normal close gripper OK" );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGLLCloseGripper %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGLLOpenLid( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGLLOpenLid %s", argument );

	try
	{
		ResetAbort( );

        //check for P0(home) P1(rest)
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
        //check for P1(rest)
        if (!CloseToPoint( P0, currentPosition ) && !CloseToPoint( P1, currentPosition ))
        {
            strcpy( status_buffer, "robot must at home to do low level lid command" );
            LOG_FINE1( "-RobotEpson::CFGLLOpenLid %s", status_buffer );
		    return TRUE;
        }

		if (!m_Dewar.OpenLid( ))
		{
			strcpy( status_buffer, "low level open Lid failed" );
            SetRobotFlags( FLAG_REASON_LID_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
            strcpy( status_buffer, "normal open lid OK" );
		}

		//once you try this command, it like you forced lid open
		LidOpenCallback( );
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGLLOpenLid %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGLLCloseLid( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGLLCloseLid %s", argument );

	try
	{
		ResetAbort( );

        //check for P0(home) P1(rest)
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
        //check for P1(rest)
        if (!CloseToPoint( P0, currentPosition ) && !CloseToPoint( P1, currentPosition ))
        {
            strcpy( status_buffer, "robot must at home to do low level lid command" );
            LOG_FINE1( "-RobotEpson::CFGLLCloseLid %s", status_buffer );
		    return TRUE;
        }

		if (!m_Dewar.CloseLid( ))
		{
			strcpy( status_buffer, "low level close lid failed" );
            SetRobotFlags( FLAG_REASON_LID_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			LOG_WARNING( status_buffer );
		}
		else
		{
            strcpy( status_buffer, "normal close lid OK" );
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGLLCloseLid %s", status_buffer );
    return TRUE;    //no more loop call
}

BOOL RobotEpson::CFGHWOutputSwitch( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGHWOutputSwitch %s", argument );

	short bit_num = -1;

	if (sscanf( argument, "%hd", &bit_num ) != 1 || bit_num < 0)
	{
		strcpy( status_buffer, "bad argument: bit number expected" );
		LOG_FINE1( "-RobotEpson::CFGHWOutputSwitch %s", status_buffer );
		return TRUE;    //no more loop call
	}

	try
	{
		ResetAbort( );
		
		//check current on/off
		if (m_pSPELCOM->Oport( bit_num ))
		{
			m_pSPELCOM->Off( bit_num, vNull, vNull );
		}
		else
		{
			m_pSPELCOM->On( bit_num, vNull, vNull );
		}
		SelfPollIOBit( );
		strcpy( status_buffer, "normal OK" );
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CFGHWOutputSwitch %s", status_buffer );
    return TRUE;    //no more loop call
}



BOOL RobotEpson::CFGCommand(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CFGCommand %s", argument );

	try
	{
	    m_pSPELCOM->ExecSPELCmd( argument );
	    strcpy( status_buffer, "normal " );
		strncat( status_buffer, m_pSPELCOM->Reply( ), MAX_LENGTH_STATUS_BUFFER - 7 ); //7 is length of "normal "
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    LOG_FINE1( "-RobotEpson::CFGCommand %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CFGStepUp(  const char argument[], char status_buffer[] )
{
	LOG_FINE1( "+RobotEpson::CFGStepUp: %s", argument );

	if (!(GetRobotFlags( ) & FLAG_IN_RESET))
	{
        strcpy( status_buffer, "RobotDHSError: not in reset" );
        LOG_FINE1( "-RobotEpson::CFGStepUp %s", status_buffer );
		return TRUE;
	}

	try 
	{
		if (!MoveUpForSampleRescue( argument, status_buffer ))
		{
            LOG_FINE1( "-RobotEpson::CFGStepUp %s", status_buffer );
		    return TRUE;
		}
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CFGStepUp %s", status_buffer );
		return TRUE;
	}
	
    strcpy( status_buffer, "normal" );
    LOG_FINE1( "-RobotEpson::CFGStepUp %s", status_buffer );
    return TRUE;
}


//move robot to place that's safe to jump P1
void RobotEpson::Detach( void )
{
    //specal case: in home(P0) or rest(P1) or P3(cool)
    PointCoordinate currentP;
    

	CurrentSampleState sampleState = GetSampleState( );

    if (GetCurrentPoint ( ) == P53)
	{
		//try both toolset
		short toolset = 0;

		m_pSPELCOM->Tool( 1 );
	    GetCurrentPosition( currentP );
		if (CloseToPoint( P53, currentP ))
		{
			toolset = 1;
		}
		else
		{
			m_pSPELCOM->Tool( 2 );
		    GetCurrentPosition( currentP );
			if (CloseToPoint( P53, currentP ))
			{
				toolset = 2;
			}
		}

		if (toolset != 0)
		{
			LOG_FINEST( "move from P53 to P52" );
			TwistOffMagnet( );
			m_pSPELCOM->Move ( (COleVariant)"P52" );
			SetCurrentPoint ( P52 );
		}
		m_pSPELCOM->Tool( 0 );
        return;
	}

    GetCurrentPosition( currentP );
	switch ( sampleState )
	{
	case SAMPLE_ON_PICKER:
        //after putMagnet and before take the sample
        if ((GetCurrentPoint( ) == P3 || GetCurrentPoint( ) == P16) && CloseToPoint( P16, currentP ))
        {
			LOG_FINEST( "sample on picker, move away 5mm" );
			const float PI = 3.14159265359f;
			//float moveAngle = m_dumbbellOrientation * PI / 2.0f;
			float DX = 5.0f * m_dumbbellDirScale.cosValue;
			float DY = 5.0f * m_dumbbellDirScale.sinValue;
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(.3f) +Y(.3f)", DX, DY );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
        }
		break;

	case SAMPLE_ON_TONG:
		if ( GetCurrentPoint ( ) == P16 && CloseToPoint( P16, currentP ))
        {
			LOG_FINEST( "at P16, move away 5 mm" );
			const float PI = 3.14159265359f;
			//float moveAngle = m_dumbbellOrientation * PI / 2.0f;
			float DX = 5.0f * m_dumbbellDirScale.cosValue;
			float DY = 5.0f * m_dumbbellDirScale.sinValue;
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(.3f) +Y(.3f)", DX, DY );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
        }
		else if ( GetCurrentPoint ( ) == P26 && CloseToPoint( P26, currentP ))
        {
			LOG_FINEST( "at P26, move away 5 mm" );
			const float PI = 3.14159265359f;
			//float moveAngle = (m_dumbbellOrientation + 2) * PI / 2.0f;
			float DX = -5.0f * m_dumbbellDirScale.cosValue;
			float DY = -5.0f * m_dumbbellDirScale.sinValue;
			char cmd[1024] = {0};
			sprintf( cmd, "P* +X(.3f) +Y(.3f)", DX, DY );
			COleVariant VAcmd( cmd );
			m_pSPELCOM->Move( VAcmd );
        }
	}
}

bool RobotEpson::MoveFromP18ToP1( )
{
	//safety check
	if (GetCurrentPoint( ) != P18)
	{
		LOG_WARNING( "MoveFromP18ToP1 failed, current point is not P18" );
		return false;
	}

    PointCoordinate currentP;
    GetCurrentPosition( currentP );
	if (!CloseToPoint( P18, currentP ))
	{
		LOG_WARNING( "MoveFromP18ToP1 failed, current position not close to P18" );
		return false;
	}

	//open lid
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
		if (m_pEventListener)
		{
			char errorMsg[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
			strcpy( errorMsg, "open lid failed" );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, errorMsg );
		}
		LOG_WARNING( "MoveFromP18ToP1 failed: opend lid failed" );
        return false;
    }

	//move
	m_pSPELCOM->Move ( (COleVariant)"P* :Z(-1)" );
#ifdef MIXED_ARM_ORIENTATION
	m_pSPELCOM->Go ( (COleVariant)"P1" );
#else
	m_pSPELCOM->Move ( (COleVariant)"P1" );
#endif
	SetCurrentPoint ( P1 );
	return true;
}

//move to P1, close lid, then move to P2
bool RobotEpson::MoveToCheckGripperPos( float dx, float dy, float dz, float du )
{
	char errorMsg[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
	bool success = false;

	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		if (m_pEventListener)
		{
			strcpy( errorMsg, "motor is not on in resetting" );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, errorMsg );
		}
		return false;
	}

	setRobotSpeed( SPEED_IN_LN2 );
    m_pSPELCOM->Tool ( 0 );
    m_pSPELCOM->LimZ( 0.0f );

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

	if (CloseToPoint( P38, currentPosition ))
	{
		m_pSPELCOM->Move ( (COleVariant)"P* :Z(-1)" );
		m_pSPELCOM->Arc( (COleVariant)"P28", (COleVariant)"P18" );
		SetCurrentPoint( P18 );
		if (!MoveFromP18ToP1( ))
		{
			return false;
		}
	}
	else if (CloseToPoint( P28, currentPosition ) || CloseToPoint( P18, currentPosition ))
	{
		m_pSPELCOM->Move ( (COleVariant)"P* :Z(-1)" );
		m_pSPELCOM->Move ( (COleVariant)"P18" );
		SetCurrentPoint ( P18 );
		if (!MoveFromP18ToP1( ))
		{
			return false;
		}
	}
	else if (InDewarArea( currentPosition )) 
	{
#ifndef NO_DEWAR_LID
		if ( m_Dewar.GetLidState( ) ==Dewar::UNKNOWN)
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
					}
                }
                //falling through
            case Dewar::OPEN_LID_OK:
                break;

            case Dewar::OPEN_LID_FAILED:
            default:
				if (m_pEventListener)
				{
					strcpy( errorMsg, "open lid failed" );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, errorMsg );
				}
                return false;
            }
		}
#endif
		//known position
		Detach( );

		m_pSPELCOM->Jump( (COleVariant)"P1" );
		SetCurrentPoint ( P1 );
	}
	else if (CloseToPoint( P0, currentPosition, 20 ) ||
			 CloseToPoint( P3, currentPosition ) ||
			 BetweenP1_Home( currentPosition ))
    {
        m_pSPELCOM->Jump( (COleVariant)"P1" );
		SetCurrentPoint( P1 );
    }
	else
	{
		strcpy( errorMsg, "not in area to safely move" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, errorMsg );
		}
		LOG_WARNING( errorMsg );
		return false;
	}

	//re-check
	if (GetCurrentPoint( ) != P1)
	{
		strcpy( errorMsg, "not at P1 in the last step of MoveToCheckGripperPos" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, errorMsg );
		}
		LOG_WARNING( errorMsg );
		return false;
	}
	GetCurrentPosition( currentPosition );
	if (!CloseToPoint( P1, currentPosition ))
	{
		strcpy( errorMsg, "not really at P1 in the last step of MoveToCheckGripperPos" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, errorMsg );
		}
		LOG_WARNING( errorMsg );
		return false;
	}

	//move to check point
	if (!m_Dewar.CloseLid( ))
    {
		strcpy( errorMsg, "close lid failed" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, errorMsg );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, errorMsg );
		}
		LOG_WARNING( errorMsg );
        return false;
    }
	m_pSPELCOM->Move ( (COleVariant)"P2" );
	SetCurrentPoint ( P2 );
	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		return false;
	}
	return true;
}

bool RobotEpson::CheckDumbbell ( void )
{
	bool success = false;

	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		return false;
	}

	setRobotSpeed( SPEED_IN_LN2 );

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

	if ( success = (CloseToPoint( P0, currentPosition ) && (GetDumbbellState( ) != DUMBBELL_RAISED)))
	{
        //check before move
        if (!CheckGripper( ))
        {
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, "gripper jam" );
            }
            SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
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
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, openlid_msg );
				}
            }
            //falling through
        case Dewar::OPEN_LID_OK:
            break;

        case Dewar::OPEN_LID_FAILED:
        default:
            {
                char openlid_msg[] = "Open Lid failed";
                LOG_WARNING( openlid_msg );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, openlid_msg );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, openlid_msg );

				}
            }
            SetRobotFlags( FLAG_REASON_LID_JAM );
			return false;
        }
		if (!MoveToCoolPoint( )) return false;
		if (!GetMagnet ( )) return false;

		//need to close gripper in case sample is on picker or placer
		//clear DEBUG MODE so that close gripper will not trigger abort in case of gripper jam
		CloseGripper( true ); //ignore errors here 

		m_pSPELCOM->Move ( (COleVariant)"P4" );
		SetCurrentPoint ( P4 );
	}
	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		return false;
	}
	return success;
}

bool RobotEpson::ReturnDumbbell ( void )
{
	bool success = false;

	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		return false;
	}
	setRobotSpeed( SPEED_IN_LN2 );

	if ( success = ( ( GetCurrentPoint ( ) == P2 )  && ( GetDumbbellState ( ) == DUMBBELL_OUT ) ) )
	{
#ifdef MIXED_ARM_ORIENTATION
		m_pSPELCOM->Go ( (COleVariant)"P1" );
#else
		m_pSPELCOM->Move ( (COleVariant)"P1" );
#endif
		SetCurrentPoint ( P1 );
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
            strcpy( m_ErrorMessageForOldFunction, "Opening dewar lid timed out" );
		    LOG_SEVERE( m_ErrorMessageForOldFunction );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, m_ErrorMessageForOldFunction );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, m_ErrorMessageForOldFunction );
			}
			SetRobotFlags ( FLAG_REASON_LID_JAM );
			return false;
        }
		m_pSPELCOM->Move ( (COleVariant)"P2" );
		SetCurrentPoint ( P2 );
		m_pSPELCOM->Move ( (COleVariant)"P4" );
		SetCurrentPoint ( P4 );
		PutMagnet ( );
	}
	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		return false;
	}
	return success;
}

bool RobotEpson::ProcessProbeArgument( const char* argument, char* status_buffer )
{
	CCassette* const cassettes[3] = { &m_LeftCassette, &m_MiddleCassette, &m_RightCassette };

	//this number is hardcoded according to CCassette::NUM_ROW * CCassette::NUM_COLUMN
	static const int cassette_probe_index[3] = {
		0,
		CCassette::NUM_COLUMN * CCassette::NUM_ROW * 2 + 2,
		2 * (CCassette::NUM_COLUMN * CCassette::NUM_ROW * 2 + 2)
	};
	static const char cas_name[3] = {'l', 'm', 'r'};
	bool anySet = false;

	for (int cas_index = 0; cas_index < 3; ++cas_index)
	{
		int offset = cassette_probe_index[cas_index];
		bool anySetForThisCassette = false;
		if (!cassettes[cas_index]->ConfigNeedProbe( argument + offset, status_buffer, anySetForThisCassette ))
		{
			return false;
		}

		anySet = anySet || anySetForThisCassette;
	}

	if (!anySet)
	{
		strcpy( status_buffer, "no cassette or port selected" );
		return false;
	}

	return true;
}

bool RobotEpson::InRecoverablePosition( )
{
    //check to see if we are in HOME or any pre-calibrated points
    try
    {
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );

        //check for P0(home) P1(rest)
        if (CloseToPoint( P0,  currentPosition ) ||
			CloseToPoint( P1,  currentPosition ) ||
			CloseToPoint( P2,  currentPosition ) ||
			CloseToPoint( P3,  currentPosition ) ||
			CloseToPoint( P6,  currentPosition ) ||
			CloseToPoint( P18, currentPosition ) ||
			CloseToPoint( P28, currentPosition ) ||
			CloseToPoint( P38, currentPosition ))
        {
            return true;
        }

	    if (InDewarArea( currentPosition ) || BetweenP1_Home( currentPosition ))
        {
            return true;
        }

		if (InFrontArea( currentPosition ))
		{
			if (m_pEventListener)
			{
				strcpy( m_ErrorMessageForOldFunction, "robot in front area, please manually move it to rest position and restart resetting" );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, m_ErrorMessageForOldFunction );
			}
			return false;
		}
    }
	catch ( CException *e )
	{
        char errorMessage[MAX_LENGTH_STATUS_BUFFER+1] = {0};
		e->GetErrorMessage ( errorMessage,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete();
        LOG_WARNING1( "RobotEpson::InRecoverablePosition %s", errorMessage );
	}
	if (m_pEventListener)
	{
		strcpy( m_ErrorMessageForOldFunction, "robot not in auto recover position.  Please manually move it to rest position and restart resetting " );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, m_ErrorMessageForOldFunction );
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, m_ErrorMessageForOldFunction );
	}
    return false;
}

bool RobotEpson::InFrontArea ( const PointCoordinate& point ) const
{
	PointCoordinate Point20;
	retrievePoint( P20, Point20 );

	if (Point20.x * point.x > 0.0f && Point20.y * point.y > 0.0f)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool RobotEpson::InDewarArea ( const PointCoordinate& point ) const
{
	float eps = 10;
	PointCoordinate Point1;
	PointCoordinate Point18;
	retrievePoint( P1, Point1 );
	retrievePoint( P18, Point18 );

	float start = Point18.x;
	float end = Point1.x;

	if (start > end)
	{
		//left hand system
		start = Point1.x;
		end = Point18.x;
	}

	start -= eps;
	end += eps;

    if (point.x <= end && point.x >= start)
    {
		LOG_FINEST( "inDewar returned true" );
        return true;
    }
    else
    {
		LOG_FINEST( "inDewar returned false" );
        return false;
    }
}

bool RobotEpson::BetweenP1_Home ( const PointCoordinate& point ) const
{
	PointCoordinate Point0;
	PointCoordinate Point1;

	retrievePoint( P0, Point0 );
	retrievePoint( P1, Point1 );

	float d01 = Point0.distance( Point1 );

	if (point.distance( Point0 ) <= d01 && point.distance( Point1 ) <= d01)
	{
		return true;
	}

	return false;
}

bool RobotEpson::MoveUpForSampleRescue ( const char argument[], char status_buffer[] )
{
	if (!m_pSPELCOM->GetMotorsOn( ))
	{
		strcpy( status_buffer, "motor not on" );
		return false;
	}
	setRobotSpeed( SPEED_IN_LN2 );

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );

	if (!CloseToPoint( P6, currentPosition ))
	{
		strcpy( status_buffer, "only can be called at dumbbell post" );
		return false;
	}

	if (GetDumbbellState( ) != DUMBBELL_RAISED)
	{
		strcpy( status_buffer, "only can be called to raise dumbbell" );
		return false;
	}

	float step_size = 5.0;

	if (sscanf( argument, "%f", &step_size ) != 1)
	{
		step_size = 5.0;
	}
	if (step_size < 0.0)
	{
		strcpy( status_buffer, "only can RAISE robot" );
		return false;
	}

	char move_command[128] = {0};
	sprintf( move_command, "P* +Z(%f)", step_size );
	COleVariant mmmm( move_command );

	m_pSPELCOM->Move( mmmm );
	return true;
}
