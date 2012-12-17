#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "log_quick.h"

#include <math.h>
BOOL RobotEpson::CALPost(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALPost %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALPost %s", status_buffer );
		return TRUE;
    }

    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CALPost %s", status_buffer );
		return TRUE;
    }

    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALPost %s", status_buffer );
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
        LOG_FINE1( "-RobotEpson::CALPost %s", status_buffer );
		return TRUE;
    }

	UpdateSampleStatus( "calibrate toolset" );

    //call SPEL function
    CALWrapper( "VB_MagnetCal", argument, status_buffer );

	try
	{

		if (!strncmp( status_buffer, "normal", 6 ))
		{
			ClearRobotFlags( FLAG_NEED_CAL_MAGNET );
			InitMagnetPoints( );//this may set flags again
		}

		if (!(GetRobotFlags( ) & FLAG_NEED_ALL))
		{
			SetPowerHigh ( true );
		}
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	ResetCassetteStatus( );

    LOG_FINE1( "-RobotEpson::CALPost %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALCassette(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALCassette %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_NEED_CAL_MAGNET)
    {
		strcpy( status_buffer, "need do magnet calibration first" );
        LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
		return TRUE;
    }

    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
		return TRUE;
    }

    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
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
        LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
		return TRUE;
    }

	UpdateSampleStatus( "calibrate cassette" );
    //call SPEL function
    CALWrapper( "VB_CassetteCal", argument, status_buffer );

	try
	{

		if (!strncmp( status_buffer, "normal", 6 ))
		{
			ClearRobotFlags( FLAG_NEED_CAL_CASSETTE );
			InitCassettePoints( );//this may set flags again
		}

		if (!(GetRobotFlags( ) & FLAG_NEED_ALL))
		{
			SetPowerHigh ( true );
		}
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	ResetCassetteStatus( );

    LOG_FINE1( "-RobotEpson::CALCassette %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALGoniometer(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALGoniometer %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
		return TRUE;
    }

	int init = 0;
	float dx = 0;
    float dy = 0;
    float dz = 0;
    float du = 0;

	if (sscanf( argument, "%d %f %f %f %f", &init, &dx, &dy, &dz, &du ) != 5)
	{
		strcpy( status_buffer, "FAILED: invalid argument" );
        //SetRobotFlags( FLAG_REASON_BAD_ARG );
        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
		return TRUE;
	}

	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
        return TRUE;
	}

    if (robotStatus & FLAG_IN_MANUAL)
    {
        if (!init)
        {
		    strcpy( status_buffer, "only init CAL allowed in manul mode" );
	        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
		    return TRUE;
        }
    }

    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
		return TRUE;
	}

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_GONIOMETER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
		return TRUE;
    }

	UpdateSampleStatus( "calibrate goniometer" );
    CALWrapper( "VB_GonioCal", argument, status_buffer );

	try
	{

		if (!strncmp( status_buffer, "normal", 6 ))
		{
			ClearRobotFlags( FLAG_NEED_CAL_GONIO );
			InitGoniometerPoints( );//this may set flags again
		}

		if (!(GetRobotFlags( ) & FLAG_NEED_ALL))
		{
			SetPowerHigh ( true );
		}
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	ResetCassetteStatus( );

    LOG_FINE1( "-RobotEpson::CALGoniometer %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALCheckGoniometerReachable(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALCheckGoniometerReachable %s", argument );

	float dx = 0;
    float dy = 0;
    float dz = 0;
    float du = 0;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
	{
		strcpy( status_buffer, "FAILED: invalid argument" );
        //SetRobotFlags( FLAG_REASON_BAD_ARG );
        LOG_FINE1( "-RobotEpson::CALCheckGoniometerReachable %s", status_buffer );
		return TRUE;
	}

	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CALCheckGoniometerReachable %s", status_buffer );
        return TRUE;
	}

	strcpy( status_buffer, "normal OK" );

    LOG_FINE1( "-RobotEpson::CALCheckGoniometerReachable %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALBeamLineTool(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALBeamLineTool %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALBeamLineTool %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CALBeamLineTool %s", status_buffer );
		return TRUE;
    }
    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALBeamLineTool %s", status_buffer );
		return TRUE;
	}

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
    case SAMPLE_ON_GONIOMETER:
        break;

    case SAMPLE_ON_TONG:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CALBeamLineTool %s", status_buffer );
		return TRUE;
    }

	UpdateSampleStatus( "calibrate beamline tool" );
    CALWrapper( "VB_BLToolCal", argument, status_buffer );

    if (!strncmp( status_buffer, "normal", 6 ))
    {
        try
        {
            SetPowerHigh ( true );
        }
	    catch ( CException *e )
	    {
            NormalErrorHandle( e, status_buffer );
	    }
    }
    LOG_FINE1( "-RobotEpson::CALBeamLineTool %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALMountBeamLineTool(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALMountTool %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		return TRUE;
    }
    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		return TRUE;
	}

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_GONIOMETER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		return TRUE;
    }

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
        strcpy( status_buffer, "FAILED: invalid argument" );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
        return TRUE;
    }

	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
        return TRUE;
	}

	try
	{
        //check current position
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );

        //check for P0(home) P1(rest)
        if (!CloseToPoint( P0, currentPosition, 100 ) && !CloseToPoint( P1, currentPosition, 100 ))
        {
            SetRobotFlags( FLAG_REASON_NOT_HOME );
            strcpy( status_buffer, "robot must at P0 or P1 to start operation" );
            LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		    return TRUE;
        }
        if (!CheckGripper( ))
        {
			strcpy( status_buffer, "check gripper failed" );
	        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
			SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
            //re-heat
			return TRUE;
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
			strcpy( status_buffer, "open lid time out" );
	        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
			SetRobotFlags( FLAG_REASON_LID_JAM );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
			return TRUE;
        }
        m_pSPELCOM->LimZ( 0 );
		m_pSPELCOM->Jump( COleVariant( "P92" ) );
		SetCurrentPoint ( P92 );
		if (!GripSample( ))
        {
			strcpy( status_buffer, "GripSample failed at beamtool" );
	        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
			return TRUE;
        }
		m_pSPELCOM->Jump( COleVariant( "P1" ) );
		m_pState->currentCassette = 'b';
		m_pState->currentColumn = 'T';
		m_pState->currentRow = 0;
		UpdateState( );
		MoveToGoniometer( );
		if (ReleaseSample( ))
        {
    		MoveFromGoniometerToRestPoint( );
	    	MoveTongHome( );
        }
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
		return TRUE;
	}

	strcpy( status_buffer, "normal" );
    SetRobotFlags( FLAG_IN_TOOL );

    LOG_FINE1( "-RobotEpson::CALMountTool %s", status_buffer );
    return TRUE;

}

BOOL RobotEpson::CALDismountBeamLineTool(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALDismountTool %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "in robot manul mode" );
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		return TRUE;
    }
    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		return TRUE;
	}
	CurrentSampleState currentSampleState = GetSampleState( );
    if (currentSampleState != SAMPLE_ON_GONIOMETER) {
		strcpy( status_buffer, "nothing on goniometer" );
	    LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer
			);
		return TRUE;
	}
	if (!PositionIsBeamlineTool( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn)) {
		strcpy( status_buffer, "only valid after mount beam line tool" );
	    LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		return TRUE;
	}

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
        strcpy( status_buffer, "FAILED: invalid argument" );
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
        return TRUE;
    }
	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
        return TRUE;
	}

	try
	{
        //check current position
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );

        //check for P0(home) P1(rest)
        if (!CloseToPoint( P0, currentPosition, 100 ) && !CloseToPoint( P1, currentPosition, 100 ))
        {
            SetRobotFlags( FLAG_REASON_NOT_HOME );
            strcpy( status_buffer, "robot must at P0 or P1 to start operation" );
            LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		    return TRUE;
        }

        if (!CheckGripper( ))
        {
			SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			strcpy( status_buffer, "check gripper failed" );
	        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
			return TRUE;
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
			SetRobotFlags( FLAG_REASON_LID_JAM );
			strcpy( status_buffer, "open lid time out" );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
            }
	        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
			return TRUE;
        }

		m_pState->currentCassette = 'b';
		m_pState->currentColumn = 'T';
		m_pState->currentRow = 0;
		UpdateState( );		
		
		m_pSPELCOM->LimZ( 0 );
		m_pSPELCOM->Jump( COleVariant( "P1" ) );
		SetCurrentPoint ( P1 );

		MoveToGoniometer( );

		if (!GripSample( ))
        {
			strcpy( status_buffer, "GripSample failed at goniometer" );
	        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
			return TRUE;
        }

        MoveFromGoniometerToRestPoint( );
		m_pSPELCOM->Move( COleVariant( "P91 :Z(-2)" ) );
		setRobotSpeed( SPEED_IN_LN2 );
		m_pSPELCOM->Move( COleVariant( "P91" ) );
		SetCurrentPoint ( P91 );
		if (ReleaseSample( ))
        {
    		MoveTongHome( );
        }
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
		return TRUE;
	}

	strcpy( status_buffer, "normal" );
    ClearRobotFlags( FLAG_IN_TOOL );

    LOG_FINE1( "-RobotEpson::CALDismountTool %s", status_buffer );
    return TRUE;

}

BOOL RobotEpson::CALRun(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALRun %s", argument );
    const char* pRunArgument;
    char functionName[128] = {0};
    long result = 0;

    //get function name and setup argument if any
    pRunArgument = strchr( argument, ' ' );
    if (pRunArgument == NULL)
    {
        strcpy( functionName, argument );
    }
    else
    {
        size_t ll = pRunArgument - argument;
        strncpy( functionName, argument, ll );
        ++pRunArgument; //skip ' '
    }

    CALWrapper( functionName, pRunArgument, status_buffer );

    LOG_FINE1( "-RobotEpson::CALRun %s", status_buffer );
    return TRUE;
}

void RobotEpson::CALWrapper( const char functionName[], const char argument[], char status_buffer[] )
{
    LOG_FINE2( "+RobotEpson::CALWrapper %s, %s", functionName, argument );

	bool LN2AutoFilling = IsAutoFilling( status_buffer );

	if (LN2AutoFilling)
	{
	    LOG_FINE1( "-RobotEpson::CALWrapper %s", status_buffer );
		return;
	}

    EnableEvent( );

    try
    {
        if (argument != NULL && argument[0] != '\0')
        {
            m_pSPELCOM->SetSPELVar( "g_RunArgs$", (COleVariant)argument );
        }
        else
        {
            m_pSPELCOM->SetSPELVar( "g_RunArgs$", (COleVariant)"" );
        }
        m_pSPELCOM->SetSPELVar( "g_RobotStatus", (COleVariant)(0l) );

		//the user may change the attribute "show detailed messages" during calibration
		//and we cannot really change it during calibration,
		//so it is always enabled and upper level will stop passing the message
		//if that attribute is off
        m_pSPELCOM->EnableEvent( RobotEventListener::EVTNUM_USER_PRINT, TRUE );
        //need to be able to be aborted.  Unlike normal operation, cal operations take long time to finish
        //long result = m_pSPELCOM->Call( functionName );
        StartBackgroundTask( TAKSNO_CALIBRATION, functionName );
        //wait until it finish or we received abort message
		RobotDoEvent( 1000 );
        while (m_pSPELCOM->TaskStatus( TAKSNO_CALIBRATION ))
        {
            if (m_FlagAbort)
            {
                LOG_FINE( "user abort calibration" );
				m_pSPELCOM->SetSPELVar( "g_FlagAbort", COleVariant( short(1) ) );
                m_FlagAbort = false;
            }
			LN2AutoFilling = IsAutoFilling( status_buffer );
			if (LN2AutoFilling)
			{
                LOG_INFO( "calibration stopped by LN2 auto-filling" );
				m_pSPELCOM->SetSPELVar( "g_FlagAbort", COleVariant( short(1) ) );
				if (m_pEventListener)
				{
					strcpy( status_buffer, "LN2 auto filling" );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
				}
			}
            RobotDoEvent( 1000 );
        }
        CString tempString( m_pSPELCOM->GetSPELVar( "g_RunResult$" ) );
        strncpy( status_buffer, tempString, MAX_LENGTH_STATUS_BUFFER );

		if (strlen( status_buffer ) == 0)
		{
			strcpy( status_buffer, "check robot status" );
		}

		if (LN2AutoFilling)
		{
			strcpy( status_buffer, "by LN2 auto filling" );
		}

		m_pSPELCOM->SetSPELVar( "g_FlagAbort", COleVariant( short(0) ) );

        //check robot status
	    CString tempString1( m_pSPELCOM->GetSPELVar( "g_RobotStatus" ) );
        LOG_FINEST1( "RobotEpson::CALWrapper: g_RobotStatus=%s", tempString1 );
		long robotStatusFromCAL = 0;
		sscanf( tempString1, "%ld", &robotStatusFromCAL );
        //merge
        if (robotStatusFromCAL != 0)
        {
            SetRobotFlags( robotStatusFromCAL );
        }

		//update time_stamp of calibrations:
		//to simplify, we update all time stamp from the SPEL variables
        CString strTSToolset( m_pSPELCOM->GetSPELVar( "g_TS_Toolset$" ) );
        CString strTSLeft   ( m_pSPELCOM->GetSPELVar( "g_TS_Left_Cassette$" ) );
        CString strTSMiddle ( m_pSPELCOM->GetSPELVar( "g_TS_Middle_Cassette$" ) );
        CString strTSRight  ( m_pSPELCOM->GetSPELVar( "g_TS_Right_Cassette$" ) );
        CString strTSGonio  ( m_pSPELCOM->GetSPELVar( "g_TS_Goniometer$" ) );

		if (m_pEventListener)
		{
			CString strUpdateString = CString("ts_robot_cal ")
				+ "{" + strTSToolset + "} "
				+ "{" + strTSLeft	 + "} "
				+ "{" + strTSMiddle  + "} "
				+ "{" + strTSRight   + "} "
				+ "{" + strTSGonio   +"}";
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_STRING_UPDATE, strUpdateString );
		}

        m_pSPELCOM->EnableEvent( RobotEventListener::EVTNUM_USER_PRINT, FALSE );
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    DisableEvent( );

    LOG_FINE1( "-RobotEpson::CALWrapper %s", status_buffer );
}

BOOL RobotEpson::CALMoveToGoniometer(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALMoveToGoniometer %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & FLAG_NEED_RESET)
    {
		strcpy( status_buffer, "need reset first" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
		return TRUE;
    }
    if (robotStatus & FLAG_NEED_CLEAR)
    {
		strcpy( status_buffer, "need clear first" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
		return TRUE;
    }
    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
		return TRUE;
	}

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_GONIOMETER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
		return TRUE;
    }

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
        strcpy( status_buffer, "FAILED: invalid argument" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
        return TRUE;
    }

	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
        return TRUE;
	}

	try
	{
        //check current position
		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );

        //check for P0(home) P1(rest)
        if (!CloseToPoint( P0, currentPosition, 100 ) && !CloseToPoint( P1, currentPosition, 100 ))
        {
            SetRobotFlags( FLAG_REASON_NOT_HOME );
            strcpy( status_buffer, "robot must at P0 or P1 to start operation" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
		    return TRUE;
        }

        if (!CheckGripper( ))
        {
			strcpy( status_buffer, "check gripper failed" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
	        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
			SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			return TRUE;
        }

        if (!CloseGripper( ))
        {
			strcpy( status_buffer, "close gripper failed at home" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
	        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
			SetRobotFlags( FLAG_REASON_GRIPPER_JAM );
			return TRUE;
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
			strcpy( status_buffer, "open lid time out" );
			if (m_pEventListener)
			{
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
	        LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
			SetRobotFlags( FLAG_REASON_LID_JAM );
			return TRUE;
        }

        //move to goniometer
		if (!GetMotorsOn( ))
		{
			SetMotorsOn( true );
		}
		SetPowerHigh( false );
        m_pSPELCOM->LimZ( 0 );
        m_pSPELCOM->Tool( 0 );
		m_pSPELCOM->Jump( COleVariant( "P1" ) );

		MoveToGoniometer( );

        //reset force sensor
        RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
        ForceCalibrate( );

        //turn of power so that robot can be manually moved
    	SetMotorsOn ( false );
        SetRobotFlags( FLAG_IN_MANUAL );
		strcpy( status_buffer, "normal OK" );
	}
    catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
	}

	ResetCassetteStatus( );

    LOG_FINE1( "-RobotEpson::CALMoveToGoniometer %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::CALMoveHome(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALMoveHome %s", argument );

    //we will ignore all flags for this function
    RobotStatus robotStatus = GetRobotFlags ( );
    if (!(robotStatus & FLAG_IN_MANUAL))
    {
		strcpy( status_buffer, "only allowed in robot manul mode" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
		return TRUE;
    }

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
        strcpy( status_buffer, "FAILED: invalid argument" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
        return TRUE;
    }

    //reset the robot so that it can read the current position
    if (!BringRobotUp( status_buffer))
    {
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
        return TRUE;
    }

    try
    {
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
			LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
			return TRUE;
		}

		if (!GetMotorsOn( ))
		{
			SetMotorsOn( true );
		}
		SetPowerHigh( false );
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
			strcpy( status_buffer, "open lid time out" );
			if (m_pEventListener)
			{
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
	        LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
			SetRobotFlags( FLAG_REASON_LID_JAM );
			return TRUE;
        }

	    ClearRobotFlags( FLAG_IN_MANUAL );

        if (!MoveToHome( ))
        {
            SetRobotFlags( FLAG_REASON_ABORT );
	        SetMotorsOn( false );
            strcpy( status_buffer, "move home faile" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
            return TRUE;
        }
		SetPowerHigh( true );
	    strcpy( status_buffer, "normal OK" );

		//clear some flags if we can get here
		ClearRobotFlags( FLAG_REASON_NOT_HOME );
		ClearRobotFlags( FLAG_NEED_RESET );
		if (!(GetRobotFlags( ) & FLAG_REASON_ALL))
		{
			ClearRobotFlags( FLAG_NEED_CLEAR );
		}
		else
		{
			SetRobotFlags( FLAG_NEED_CLEAR );
		}
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CALMoveHome %s", status_buffer );
	return TRUE;
}

BOOL RobotEpson::CALSaveGoniometerPosition(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALSaveGoniometerPosition %s", argument );
    //we will ignore all flags for this function
    RobotStatus robotStatus = GetRobotFlags ( );
    if (!(robotStatus & FLAG_IN_MANUAL))
    {
		strcpy( status_buffer, "only allowed in robot manul mode" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		return TRUE;
    }

    float dx;
    float dy;
    float dz;
    float du;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
    {
        strcpy( status_buffer, "FAILED: invalid argument" );
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
        return TRUE;
    }

    //reset the robot so that it can read the current position
    if (!ClearLowLevelError( status_buffer))
    {
		if (m_pEventListener)
		{
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
		}
        LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		return TRUE;
    }

    //save current positon to P20, P21
    try
    {
        COleVariant currentPoint( "P*" );
		char message[1024] = {0};

		PointCoordinate old;
		retrievePoint( P21, old );
		if (m_pEventListener)
		{
			sprintf( message, "old P21: %.2f, %.2f, %.2f, %.2f",
		                                old.x, old.y, old.z, old.u);
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, message );
		}

		PointCoordinate currentPosition;
		GetCurrentPosition( currentPosition );
		if (m_pEventListener)
		{
			sprintf( message, "current position: %.2f, %.2f, %.2f, %.2f",
												 currentPosition.x, currentPosition.y, currentPosition.z, currentPosition.u);
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, message );
		}

        //check range
        if (!CloseToPoint( P21, currentPosition, 50 ))
        {
			strcpy( status_buffer, "change too big" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		    return TRUE;
        }

		if (fabsf( old.u - currentPosition.u ) > 45.0f)
        {
            strcpy( status_buffer, "goniometer U change more than 45 degree, no way" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		    return TRUE;
        }

        //check force
		float forces[6] = {0};
		ReadForces( forces );
		if (m_pEventListener)
		{
			sprintf( message, "forces: FZ:%.2f, TX:%.2f, TY:%.2f, TZ:%.2f",
												 forces[2], forces[3], forces[4], forces[5]);
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, message );
		}
        if (fabsf( forces[2] ) > THRESHOLD_MANUAL_GONIO_ZFORCE ||
            fabsf( forces[3] ) > THRESHOLD_MANUAL_GONIO_XTORQUE ||
            fabsf( forces[4] ) > THRESHOLD_MANUAL_GONIO_YTORQUE ||
            fabsf( forces[5] ) > THRESHOLD_MANUAL_GONIO_ZTORQUE)
        {
			strcpy( status_buffer, "forces too strong" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		    return TRUE;
        }

		//for P20
		retrievePoint( P20, old );
		if (m_pEventListener)
		{
			sprintf( message, "old P20: %.2f, %.2f, %.2f, %.2f",
				old.x, old.y, old.z, old.u);
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, message );
		}

        //save the position

		float shrink_adjust = 0.0;
		if (m_desiredLN2Level == LN2LEVEL_HIGH)
		{
			shrink_adjust = SHRINK_ADJUST_FOR_TONG;
		}
		PointCoordinate newPoint;
		newPoint.x = currentPosition.x - dx;
		newPoint.y = currentPosition.y - dy;
		newPoint.z = currentPosition.z - dz - shrink_adjust;
		newPoint.u = currentPosition.u - du;
		newPoint.o = old.o;
		assignPoint( P20, newPoint );
		SavePoints( );
		//so that they may be used by CALMoveHome
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
		    return TRUE;
		}
        SetRobotFlags( FLAG_NEED_CAL_GONIO );

        SetCurrentPoint( P21 );

		PointCoordinate readBack;
		retrievePoint( P20, readBack );
		if (m_pEventListener)
		{
			sprintf( message, "new P20: %.2f, %.2f, %.2f, %.2f",
								        readBack.x, readBack.y, readBack.z, readBack.u );
		    m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, message );
		}

		//clear flag points so that gonio_calibraion will ignore changes from previous calibration result.
		readBack.clear( );
		assignPoint( P76, readBack );

		strcpy( status_buffer, "normal OK" );
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}
	if (m_pEventListener)
	{
		m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_CAL_MSG, status_buffer );
	}
    LOG_FINE1( "-RobotEpson::CALSaveGoniometerPosition %s", status_buffer );
	return TRUE;
}
BOOL RobotEpson::CALPrepareGoniometer(  const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::CALPrepareGoniometer %s", argument );

    //check flags
    RobotStatus robotStatus = GetRobotFlags ( );
    if (robotStatus & (FLAG_NEED_RESET | FLAG_NEED_CLEAR))
    {
		strcpy( status_buffer, "need clear or reset first" );
        LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
		return TRUE;
    }

	float dx = 0;
    float dy = 0;
    float dz = 0;
    float du = 0;

	if (sscanf( argument, "%f %f %f %f", &dx, &dy, &dz, &du ) != 4)
	{
		strcpy( status_buffer, "FAILED: invalid argument" );
        //SetRobotFlags( FLAG_REASON_BAD_ARG );
        LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
		return TRUE;
	}

	if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
	{
        LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
        return TRUE;
	}

    if (robotStatus & FLAG_IN_MANUAL)
    {
		strcpy( status_buffer, "robot in manul mode" );
	    LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
		return TRUE;
    }

    if (!(robotStatus & FLAG_IN_CALIBRATION))
    {
		strcpy( status_buffer, "not in calibration" );
        LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
		return TRUE;
	}

    switch (GetSampleState( ))
    {
    case NO_CURRENT_SAMPLE:
    case SAMPLE_ON_PLACER:
    case SAMPLE_ON_PICKER:
        break;

    case SAMPLE_ON_TONG:
    case SAMPLE_ON_GONIOMETER:
    default:
        strcpy( status_buffer, "sample state wrong: " );
        strcat( status_buffer, GetSampleStateString( ) );
        LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
		return TRUE;
    }

	//everything seem OK, so cool the tong and move to goniometer
	try
	{
		SetPowerHigh( false );
		if (!GenericPrepare( 100, status_buffer ))
		{
			LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
			return TRUE;
		}
		//gripper should be already closed, just in case
		if (!CloseGripper( ))
		{
			MoveTongHome( );
			strcpy( status_buffer, "close gripper failed" );
			LOG_WARNING( status_buffer );
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, status_buffer );
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
            }
			LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
			return TRUE;
		}

		MoveToGoniometer( );
		RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
		ForceCalibrate( );

		if (m_FlagAbort)
		{
			MoveTongHome( );
			strcpy( status_buffer, "aborted" );
			LOG_FINE1( "-RobotEpson::CALPrepareGoniometer %s", status_buffer );
			return TRUE;
		}
		setRobotSpeed( SPEED_IN_LN2 );
		m_pSPELCOM->Move ( (COleVariant)"P24" );
		SetCurrentPoint ( P24 );		
		m_pSPELCOM->Move ( (COleVariant)"P21" );
		SetCurrentPoint ( P21 );
		strcpy( status_buffer, "normal OK" );
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	return TRUE;
}