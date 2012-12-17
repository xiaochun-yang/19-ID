#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "DcsMessageManager.h"
#include "log_quick.h"

#include <math.h>

void robotSystemStop( );


float RobotEpson::N2_LEVEL = 0.0f;
const float RobotEpson::MAGNET_HEAD_RADIUS = 4.72f;
const float RobotEpson::TONG_CAVITY_RADIUS = 7.06f;

//these two values from BL9-1 cryojet
const float RobotEpson::SAFETY_Z_BUFFER_FOR_MOVING_TO_GONIOMETER = 41.0f;
const float RobotEpson::SAFETY_X_BUFFER_FOR_MOVING_TO_GONIOMETER = 21.0f;

//this 3.5 must be larger than 3.0 which is overlap of cavity and goniometer head
//search "#define GONIO_OVER_MAGNET_HEAD 3.0" in robotdefs.inc in SPEL codes.
const float RobotEpson::GONIOMETER_MOUNT_STANDBY_DISTANCE = 3.5f;

const float RobotEpson::GONIOMETER_DISMOUNT_SIDEMOVE_DISTANCE = 15.0f;

//we use these parameter when we use wrong tong for goniometer.
//to avoid knock off the pin after mounting, the robot needs to
//back off this distance before move aside.
//this value should be equal or greater than the distance between
// the longest ping we allow and the tong trunck.
const float RobotEpson::CONFLICT_GONIOMETER_BACKOFF_DISTANCE = 10.0f;
// the sidemove should be bigger than normal GONIOMETER_DISMOUNT_SIDEMOVE_DISTANCE
// it should clear the finger from cryojet
const float RobotEpson::CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE = 30.0f;

const float RobotEpson::THRESHOLD_ZFORCE = 5.0f;
const float RobotEpson::THRESHOLD_XTORQUE = 0.5f;
const float RobotEpson::THRESHOLD_YTORQUE = 0.5f;
const float RobotEpson::THRESHOLD_ZTORQUE = 0.5f;
const float RobotEpson::THRESHOLD_PORTCHECK = 0.1f;
const float RobotEpson::THRESHOLD_PORTJAM = 1.0f;
const float RobotEpson::THRESHOLD_MAGNETCHECK = 0.5f;
const float RobotEpson::THRESHOLD_PICKERCHECK = 0.7f;
const float RobotEpson::THRESHOLD_MANUAL_GONIO_ZFORCE   = 20.0f;
const float RobotEpson::THRESHOLD_MANUAL_GONIO_XTORQUE  = 10.0f;
const float RobotEpson::THRESHOLD_MANUAL_GONIO_YTORQUE  = 10.0f;
const float RobotEpson::THRESHOLD_MANUAL_GONIO_ZTORQUE  = 10.0f;
const float RobotEpson::SHRINK_ADJUST_FOR_TONG  = 0.6f;
const float RobotEpson::STRIP_PLACER_SIDEWAY  = 20.0f;
const float RobotEpson::STRIP_PLACER_STICKOUT  = 8.0f;
const float RobotEpson::STRIP_PLACER_DISTANCE  = 20.0f;
const float RobotEpson::WASH_DISTANCE_U = 90.0f;
const float RobotEpson::WASH_DISTANCE_Z = 60.0f;

const char* RobotEpson::STATUS_OUT_OF_RANGE_Z = "out of robot range in Z";
const char* RobotEpson::STATUS_OUT_OF_RANGE_XY = "out of robot range in XY";

RobotEpson::RobotEpson( ):
    m_pSleepEvent(NULL),
	m_pSPELCOM(NULL),
	m_pCSpel(NULL),
	m_pState(NULL),
    m_pEventListener(NULL),
    m_EventEnabled(false),
    m_OperationState(0),
    m_OnlyAlongAxis(false),
    m_Warning(false),
    m_CheckMagnet(true),
	m_ArmLength(0),
	m_Arm1Length(0),
	m_Arm2Length(0),
	m_MinR(0),
	m_Arm1AngleLimit(0),
	m_RectangleX0(0),
	m_RectangleX1(0),
	m_RectangleY0(0),
	m_RectangleY1(0),
    m_LeftCassette( 'l' ),
    m_MiddleCassette( 'm' ),
    m_RightCassette( 'r' ),
	m_pForcesSafeVector( NULL ),
	m_CheckAutoFilling(true),
	m_TSLN2Filling(0),
	m_TSLN2Alarm(0),
    m_TSBackgroundTask(0),
	m_LastIOInputBitMap(0),
	m_LastIOOutputBitMap(0),
	m_desiredLN2Level(LN2LEVEL_HIGH),
	m_FlagAbort(false),
	m_NeedBringUp(false),
	m_NeedTurnOffHeater(false),
	m_InAbort(false),
	m_SPELAbortCalled(false),
	m_NeedAbort(false),
	m_InEventProcess(false),
	m_armOrientation(PointCoordinate::ARM_ORIENTATION_RIGHTY),
	m_dumbbellOrientation(DIRECTION_Y_AXIS),
	m_downstreamOrientation(DIRECTION_MX_AXIS),
	m_goniometerOrientation(DIRECTION_Y_AXIS),
	m_stripperInstalled(false),
    m_attributeList( NUM_ATTRIBUTE_FIELD, 15 ),
	m_TQScale(6.0f),
	m_inCmdProbing(false),
	m_tsAbort(0),
	m_numCycleToWash(0),
	m_hamptonPin(false),
	m_tongConflict(false)
{
	InitializeMMap ( );

	vNull.vt = VT_ERROR;
	vNull.scode = DISP_E_PARAMNOTFOUND;
    memset( m_ErrorMessageForOldFunction, 0, sizeof(m_ErrorMessageForOldFunction));
	m_pForcesSafeVector = SafeArrayCreateVector(VT_R4, 0, FORCE_SAFE_ARRAY_LENGTH);  //Vector of float
    if (m_pForcesSafeVector == NULL)
    {
        LOG_SEVERE( "create safe array failed" );
    }
	m_ForcesVariant.vt = VT_ARRAY|VT_R4;
	m_ForcesVariant.parray = m_pForcesSafeVector;

	memset( m_RawForces, 0, sizeof(m_RawForces) );
	memset( m_ThresholdMin, 0, sizeof(m_ThresholdMin) );
	memset( m_ThresholdMax, 0, sizeof(m_ThresholdMax) );
	memset( m_NumValidSample, 0, sizeof(m_NumValidSample) );
	memset( m_strCoolingPoint, 0, sizeof(m_strCoolingPoint) );
	memset( m_cmdBackToStandby, 0, sizeof(m_cmdBackToStandby) );

    xos_event_create( &m_EvtSPELResetOK, true, true ); //manual, init signaled

	m_dumbbellDirScale.cosValue = cosf( OrientationToAngle( m_dumbbellOrientation ) );
	m_dumbbellDirScale.sinValue = sinf( OrientationToAngle( m_dumbbellOrientation ) );
	m_downstreamDirScale.cosValue = cosf( OrientationToAngle( m_downstreamOrientation ) );
	m_downstreamDirScale.sinValue = sinf( OrientationToAngle( m_downstreamOrientation ) );
	m_goniometerDirScale.cosValue = cosf( OrientationToAngle( m_goniometerOrientation ) );
	m_goniometerDirScale.sinValue = sinf( OrientationToAngle( m_goniometerOrientation ) );
}

RobotEpson::~RobotEpson( void )
{
    xos_event_close( &m_EvtSPELResetOK );
    if (m_pForcesSafeVector != NULL)
	{
	    SafeArrayDestroy(m_pForcesSafeVector);
	}
}

void RobotEpson::StartNewOperation( )
{ 
    m_OperationState = 0;
    m_Warning = false;
    m_FlagAbort = false;

    m_LeftCassette.SetNeedProbe( false );
    m_MiddleCassette.SetNeedProbe( false );
    m_RightCassette.SetNeedProbe( false );

    m_LeftCassette.ClearAllPortNeedProbe( );
    m_MiddleCassette.ClearAllPortNeedProbe( );
    m_RightCassette.ClearAllPortNeedProbe( );
	m_inCmdProbing = false;
	m_numCycleToWash = 0;
    //clear sleep sem. it may be set by previous abort
    if (m_pSleepEvent)
    {
        xos_event_reset( m_pSleepEvent );
    }
}


///////////////////////WRAP old robot to new robot///////////////////////////////////////////
BOOL RobotEpson::Initialize( )
{
    LOG_FINE( "+RobotEpson::Initialize" );

	// Initialize activeX containner environment
    AfxEnableControlContainer();
	if (!AfxOleInit())
	{
		AfxMessageBox("Error.  Failed to Initialize OLE.");
		return FALSE;
	}

    //create container
    if (m_pCSpel == NULL)
    {
        m_pCSpel = new SPEL_DIALOG_CLASS_NAME();
        m_pSPELCOM = &(m_pCSpel->m_spelcom);
        m_Dewar.Initialize( this );
		m_LeftCassette.Initialize( this );
		m_MiddleCassette.Initialize( this );
		m_RightCassette.Initialize( this );

#ifdef LEFT_CASSETTE_NOT_EXIST
		m_LeftCassette.SetStatus( CCassette::CASSETTE_NOT_EXIST, true );
#endif

#ifdef MIDDLE_CASSETTE_NOT_EXIST
		m_MiddleCassette.SetStatus( CCassette::CASSETTE_NOT_EXIST, true );
#endif

#ifdef RIGHT_CASSETTE_NOT_EXIST
		m_RightCassette.SetStatus( CCassette::CASSETTE_NOT_EXIST, true );
#endif
    }

    //connect to activeX
	try
	{
		if (!m_pCSpel->Initialize( this ))
		{
			return FALSE;
		}

		ResetAbort( );
		Reset( );

		//setup project
		m_Registry.SetRootKey( HKEY_LOCAL_MACHINE );
		if ( m_Registry.SetKey("Software\\ROBOT\\RobotControl", FALSE ) )
		{
			m_pSPELCOM->SetProject ( m_Registry.ReadString ( "projectFile", "" ) );

			if (!m_pSPELCOM->ProjectBuildComplete( ))
			{
				m_pSPELCOM->BuildProject( );
			}
		}
		//start IO monitor task
		{
			char message[MAX_LENGTH_STATUS_BUFFER+1] = {0};
			if (!BringRobotUp( message ))
			{
				LOG_WARNING( message );
			}
		}

		m_pSPELCOM->SetTimeOut ( 0 );
		m_pSPELCOM->JRange( 4, -180000, 180000 ); //-300, +300 degree
        m_pSPELCOM->Tool( 0 );
		//m_pSPELCOM->SetSafetyDialog ( false );

		CheckModel( );

        //one restart, we are not in reset or cal any more
        ClearRobotFlags( FLAG_IN_RESET | FLAG_IN_CALIBRATION );

        //basic cal points will be check in init point
        ClearRobotFlags( FLAG_NEED_CAL_BASIC );

        //all cal point will be checked in init, so we can clear them if they are flagged by only by init
        if ((GetRobotFlags( ) & FLAG_REASON_ALL) == FLAG_REASON_INIT)
        {
            ClearRobotFlags( FLAG_NEED_CAL_ALL );
        }
        UpdateMounted( );

        UpdateState( );

        UpdateCassetteStatus( );
		updateForces( );
        UpdateSampleStatus( "robot restarted" );

        if (m_pEventListener)
        {
            char mounted[32]= {0};
			sprintf( mounted, "%lu", m_pState->num_pin_mounted_short_trip );
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINMOUNTED, mounted );
        }

		//init all points and toolsets
		//may set flags
		{
            if (m_pEventListener)
            {
                m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, "self-testing...." );
            }
			

			char message[MAX_LENGTH_STATUS_BUFFER+1] = {0};
			if (!PassSelfTest( true, message ))
			{
	    		LOG_SEVERE( message );
			}
			else
			{
				message[0] = 0;
			}
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, message );
			}
		}

		CopyDesiredLN2LevelFromSPEL( );
		SetLN2Level( m_desiredLN2Level );
		InitPoints( );

		FILE* fhCleanup = fopen( "RobotShutDown.OK", "r" );
		if (!fhCleanup)
		{
			SetRobotFlags( FLAG_NEED_RESET );
		}
		else
		{
			fclose( fhCleanup );
			fhCleanup = NULL;
			::remove( "RobotShutDown.OK" );

			if (GetRobotFlags( ) == 0)
			{
				if (!GetMotorsOn( ))
				{
					SetMotorsOn( true );
				}
				SetPowerHigh( true );
			}

		}

        if (GetRobotFlags( ) & FLAG_NEED_CAL_BASIC)
        {
    		LOG_SEVERE( "need to setup basic points P0, P1, P18 to run" );
        }
	}
	catch ( CException *e )
	{
		char message[MAX_LENGTH_STATUS_BUFFER+1] = {0};

		e->GetErrorMessage ( message,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete ( );
		LOG_FINE1( "-RobotEpson::Initialize robot failed: %s", message );
		return FALSE;
	}

    LOG_FINE( "-RobotEpson::Initialize" );
	return TRUE;
}

void RobotEpson::Cleanup( )
{
    LOG_FINE( "+RobotEpson::Cleanup" );

	//create file marking shutdown OK
	//so that next time it will not force reset
	FILE* fhCleanup = fopen( "RobotShutDown.OK", "w" );
	fclose( fhCleanup );

    if (m_pCSpel != NULL)
    {
		try
		{
	        Abort( );
		}
		catch ( CException *e )
		{
			char message[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
			e->GetErrorMessage ( message,  MAX_LENGTH_STATUS_BUFFER);
			e->Delete();
			LOG_FINE1( "in RobotEpson::Cleanup Abort caused %s", message );
		}
		catch (...)
		{
		}
        delete m_pCSpel;
        m_pCSpel = NULL;
    }
    LOG_FINE( "-RobotEpson::Cleanup" );
}

void RobotEpson::SetAttribute( const char attributes[] )
{
	bool prev_probe_cassette = getAttributeFieldBool( ATTRIB_PROBE_CASSETTE );

	m_attributeList.parse( attributes );

	bool new_probe_cassette = getAttributeFieldBool( ATTRIB_PROBE_CASSETTE );
	bool new_probe_port = getAttributeFieldBool( ATTRIB_PROBE_PORT );

    if (!new_probe_cassette && new_probe_port)
	{
		if (prev_probe_cassette)
		{
			m_attributeList.setField( ATTRIB_PROBE_PORT, "0" );
		}
		else
		{
			m_attributeList.setField( ATTRIB_PROBE_CASSETTE, "1" );
		}
	}
}

void RobotEpson::Poll( )
{
	//LOG_FINEST( "+RobotEpson::Poll" );

	RobotDoEvent( 10 );

	FlushViewOfFile( m_pState, 0 );

	if (m_InAbort)
	{
		RobotDoEvent( 1000 );
		LOG_FINEST( "-RobotEpson::Poll: still in abort" );
		return;
	}

	try
	{
		if (m_NeedBringUp)
		{
			LOG_INFO( "bring robot up in Poll" );
			char message[MAX_LENGTH_STATUS_BUFFER+1] = {0};
			if (!BringRobotUp( message ))
			{
				LOG_WARNING( message );
				return;
			}
		}

		time_t timeNow = time( NULL );
        //background task interval is 1 second. 3 seconds no update,
        //the task must be dead
		if (timeNow > m_TSBackgroundTask + 3)
		{
			if (m_NeedTurnOffHeater && !m_SPELAbortCalled)
			{
				m_Dewar.TurnOffHeater( true );
			}

			//log warning
			if (!(GetRobotFlags( ) & (FLAG_NEED_CLEAR | FLAG_NEED_RESET)))
			{
				LOG_WARNING( "background task dead set need bring up" );
				m_NeedBringUp = true;
			}
			SelfPollIOBit( );
		}
	}
	catch ( CException *e )
	{
		char message[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
		e->GetErrorMessage ( message,  MAX_LENGTH_STATUS_BUFFER);
		e->Delete();

		if (strstr( message, "abort" ))
		{
			//next time, ResetAbort will be called.
			m_SPELAbortCalled = true;
		}

		LOG_FINE1( "in RobotEpson::Poll caused %s", message );
	}
	catch (...)
	{
	}
	//LOG_FINEST( "-RobotEpson::Poll" );
}


//MAX_LENGTH_STATUS_BUFFER

BOOL RobotEpson::PrepareMountCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::PrepareMountCrystal %s", position );
    static char cassette;
    static short row;
    static char column;
    static float dx;
    static float dy;
    static float dz;
    static float du;

    m_CheckMagnet = true;

    switch (m_OperationState)
    {
    case 0:
        //get and check position info
        cassette = 0;
        row = 0;
        column = 0;
        dx = 0;
		dy = 0;
        dz = 0;
		du = 0;

	    if (sscanf( position, "%c %hd %c %f %f %f %f", &cassette, &row, &column, &dx, &dy, &dz, &du ) != 7)
        {
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
            strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
            return TRUE;
        }
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
	        sprintf( sampleStatus, "%c%c%hd failed, gonio unreachable", cassette, column, row );
            UpdateSampleStatus( sampleStatus );

			MoveTongHome( );
            LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
			return TRUE;
		}

        if (!OKToMount( cassette, row, column, status_buffer ))
	    {
			if (strncmp( status_buffer, "normal", 6 ))
			{
	            char sampleStatus[256] = {0};
		        sprintf( sampleStatus, "%c%c%hd not OK to mount", cassette, column, row );
			    UpdateSampleStatus( sampleStatus );
			}

			LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK we need to send an update to let DCSS know we are going to proceed this message
        strcpy( status_buffer, "OK to prepare" );
        m_OperationState = 1;
        LOG_FINE1( "-RobotEpson::PrepareMountCrystal update %s", status_buffer );
        return FALSE;   //will send a update message and call us again.

    case 1:
        m_OperationState = 0;
        if (!GenericPrepare( 30, status_buffer ))
        {
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK
        sprintf( status_buffer, "normal %c %hd %c", cassette, row, column );
        LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
        return TRUE;
    default:
        m_OperationState = 0;
        strcpy( status_buffer, "BAD internal operation state" );
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
        LOG_FINE1( "-RobotEpson::PrepareMountCrystal %s", status_buffer );
        return TRUE;
    }

}

BOOL RobotEpson::PrepareDismountCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::PrepareDismountCrystal %s", position );
    static char cassette;
    static short row;
    static char column;
    static float dx;
    static float dy;
    static float dz;
    static float du;

    m_CheckMagnet = true;
    switch (m_OperationState)
    {
    case 0:
        //get and check position info
        cassette = 0;
        row = 0;
        column = 0;
        dx = 0;
		dy = 0;
        dz = 0;
		du = 0;

	    if (sscanf( position, "%c %hd %c %f %f %f %f", &cassette, &row, &column, &dx, &dy, &dz, &du ) != 7)
        {
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
            strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
            return TRUE;
        }
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
	        sprintf( sampleStatus, "%c%c%hd failed, gonio unreachable", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
			MoveTongHome( );
            LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
			return TRUE;
		}

        if (!OKToDismount( cassette, row, column, status_buffer ))
        {
			if (strncmp( status_buffer, "normal", 6 ))
			{
	            char sampleStatus[256] = {0};
		        sprintf( sampleStatus, "%c%c%hd not OK to dismount", cassette, column, row );
			    UpdateSampleStatus( sampleStatus );
			}
            LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
            return TRUE;
        }
        m_OperationState = 1;
        strcpy( status_buffer, "OK to prepare" );
        LOG_FINE1( "-RobotEpson::PrepareDismountCrystal update %s", status_buffer );
        return FALSE;

    case 1:
        //move to the cooling position
        if (!GenericPrepare( 35, status_buffer ))
        {
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK
        sprintf( status_buffer, "normal %c %hd %c", cassette, row, column );
        LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
        return TRUE;

    default:
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
        m_OperationState = 0;
        strcpy( status_buffer, "BAD internal operation state" );
        LOG_FINE1( "-RobotEpson::PrepareDismountCrystal %s", status_buffer );
        return TRUE;
    }
}

BOOL RobotEpson::PrepareMountNextCrystal( const char position[],  char status_buffer[] )
{

    LOG_FINE1( "+RobotEpson::PrepareMountNextCrystal %s", position );
    static char dism_cassette;
    static short dism_row;
    static char dism_column;

    static char mnt_cassette;
    static short mnt_row;
    static char mnt_column;

    static float dx;
    static float dy;
    static float dz;
    static float du;

    m_CheckMagnet = true;
    switch (m_OperationState)
    {
    case 0:
        //get and check position info
        dism_cassette = 0;
        dism_row = 0;
        dism_column = 0;

        mnt_cassette = 0;
        mnt_row = 0;
        mnt_column = 0;

        dx;
        dz;

	    if (sscanf( position, "%c %hd %c %c %hd %c %f %f %f %f",
            &dism_cassette, &dism_row, &dism_column,
            &mnt_cassette, &mnt_row, &mnt_column,
            &dx, &dy, &dz, &du ) != 10)
        {
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
            strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
            return TRUE;
        }
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd failed, gonio unreachable", dism_cassette, dism_column, dism_row );
            UpdateSampleStatus( sampleStatus );

			MoveTongHome( );
            LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
			return TRUE;
		}

		//check sample post status
        if (!OKToMountNext( dism_cassette, dism_row, dism_column, mnt_cassette, mnt_row, mnt_column, status_buffer ))
        {
			if (strncmp( status_buffer, "normal", 6 ))
			{
			    UpdateSampleStatus( "not OK to mountNext" );
			}
            LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
            return TRUE;
        }

        m_OperationState = 1;
        strcpy( status_buffer, "OK to prepare" );
        LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal update %s", status_buffer );
        return FALSE;

    case 1:
        //move to the cooling position
        if (!GenericPrepare( 35, status_buffer ))
        {
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK
		sprintf( status_buffer, "normal %c %hd %c normal %c %hd %c",
			dism_cassette, dism_row, dism_column,
			mnt_cassette, mnt_row, mnt_column);
        LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
        return TRUE;

    default:
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
        m_OperationState = 0;
        strcpy( status_buffer, "BAD internal operation state" );
        LOG_FINE1( "-RobotEpson::PrepareMountNextCrystal %s", status_buffer );
        return TRUE;
    }
}

BOOL RobotEpson::PrepareMoveCrystal( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::PrepareMoveCrystal %s", argument );
    //because we support multiple pairs in sorting, it is very difficult to check
    //port status.  One port empty now may be filled in the sorting.
    //so most checking are done during the sorting.
    //here we only check robot status and cassette status
    m_CheckMagnet = true;
    switch (m_OperationState)
    {
    case 0:
        {
            if (!OKToMove( argument, status_buffer ))
            {
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				}
                LOG_FINE1( "-RobotEpson::PrepareMoveCrystal %s", status_buffer );
                return TRUE;
            }
            m_OperationState = 1;
            strcpy( status_buffer, "OK to prepare" );
            LOG_FINE1( "-RobotEpson::PrepareMoveCrystal update %s", status_buffer );
            return FALSE;
        }

    case 1:
        //move to the cooling position
        if (!GenericPrepare( 35, status_buffer ))
        {
            LOG_FINE1( "-RobotEpson::PrepareMoveCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK
        if (!OKToMove( argument, status_buffer ))
        {
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
			}
            LOG_FINE1( "-RobotEpson::PrepareMoveCrystal %s", status_buffer );
            return TRUE;
		}
        strcpy( status_buffer, "normal" );
        LOG_FINE1( "-RobotEpson::PrepareMoveCrystal %s", status_buffer );
        return TRUE;

    default:
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
        m_OperationState = 0;
        strcpy( status_buffer, "BAD internal operation state" );
        LOG_FINE1( "-RobotEpson::PrepareMoveCrystal %s", status_buffer );
        return TRUE;
    }
}

BOOL RobotEpson::PrepareWashCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::PrepareWashCrystal %s", position );
    static float dx;
    static float dy;
    static float dz;
    static float du;
	static int   times;

    m_CheckMagnet = true;
    switch (m_OperationState)
    {
    case 0:
        //get and check position info
        dx = 0;
		dy = 0;
        dz = 0;
		du = 0;
		times = 0;

	    if (sscanf( position, "%d %f %f %f %f", &times, &dx, &dy, &dz, &du) != 5 || times < 0)
        {
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
            strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
            return TRUE;
        }
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
	        strcpy( sampleStatus, "wash sample failed, gonio unreachable" );
            UpdateSampleStatus( sampleStatus );
			MoveTongHome( );
            LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
			return TRUE;
		}

        if (!OKToWash( status_buffer ))
        {
			if (strncmp( status_buffer, "normal", 6 ))
			{
	            char sampleStatus[256] = {0};
		        strcpy( sampleStatus, "not OK to wash" );
			    UpdateSampleStatus( sampleStatus );
			}
            LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
            return TRUE;
        }
        m_OperationState = 1;
        strcpy( status_buffer, "OK to Wash" );
        LOG_FINE1( "-RobotEpson::PrepareWashCrystal update %s", status_buffer );
        return FALSE;

    case 1:
        //move to the cooling position
        if (!GenericPrepare( 35, status_buffer ))
        {
            UpdateSampleStatus( status_buffer );
            LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
		    return TRUE;
	    }

        //OK
        strcpy( status_buffer, "normal" );
        LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
        return TRUE;

    default:
        SetRobotFlags( FLAG_REASON_WRONG_STATE );
        m_OperationState = 0;
        strcpy( status_buffer, "BAD internal operation state" );
        LOG_FINE1( "-RobotEpson::PrepareWashCrystal %s", status_buffer );
        return TRUE;
    }
}


BOOL RobotEpson::MountCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::MountCrystal %s", position );
	char cassette;
	short row;
	char column;
    float dx;
    float dy;
    float dz;
    float du;

    try
    {
		//get and check position info
		int argc = sscanf( position, "%c %hd %c %f %f %f %f %lu", &cassette, &row, &column, &dx, &dy, &dz, &du, &m_numCycleToWash);
		if (argc < 7)
		{
			strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );

			MoveTongHome( );

			//SetRobotFlags( FLAG_REASON_BAD_ARG );
			LOG_FINE1( "-RobotEpson::MountCrystal %s", status_buffer );
			return TRUE;
		}
		else if (argc == 7)
		{
			m_numCycleToWash = 0;
		}

		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            UpdateSampleStatus( "gonio unreachable" );
			MoveTongHome( );
			LOG_FINE1( "-RobotEpson::MountCrystal %s", status_buffer );
			return TRUE;
		}

		//check port status
		if (!OKToMount( cassette, row, column, status_buffer ))
		{
            UpdateSampleStatus( "not OK to mount" );
			MoveTongHome( );
			LOG_FINE1( "-RobotEpson::MountCrystal %s", status_buffer );
			return TRUE;
		}

		if ( GetCurrentPoint ( ) != P3 )
		{
            UpdateSampleStatus( "wrong state" );
			MoveTongHome( );
			strcpy( status_buffer, "FAILED, need to call PrepareMountCrystal first" );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
			LOG_FINE1( "-RobotEpson::MountCrystal %s", status_buffer );
			return TRUE;
		}

        if (Mounting( cassette, row, column ))
        {
            UpdateSampleStatus( "mounted", true );
            sprintf( status_buffer, "normal %c %hd %c", cassette, row, column );
        }
        else
        {
            CollectStatusInfo( status_buffer, "normal n 0 N" );
        }

        //MoveTongHome( ); //we need to send finish message before moving tong home
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    LOG_FINE1( "-RobotEpson::MountCrystal %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::DismountCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::DismountCrystal %s", position );
	char cassette;
	short row;
	char column;
    float dx;
    float dy;
    float dz;
    float du;

    try
    {
		//get and check position info
		if (sscanf( position, "%c %hd %c %f %f %f %f", &cassette, &row, &column, &dx, &dy, &dz, &du ) != 7)
		{
			MoveTongHome( );
			strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
			LOG_FINE1( "-RobotEpson::DismountCrystal %s", status_buffer );
			return TRUE;
		}

		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
            sprintf( sampleStatus, "%c%c%hd failed, gonio unreachable", cassette, column, row );
            UpdateSampleStatus( sampleStatus );
			MoveTongHome( );

			LOG_FINE1( "-RobotEpson::DismountCrystal %s", status_buffer );
			return TRUE;
		}

		//check sample post status
		if (!OKToDismount( cassette, row, column, status_buffer ))
		{
            UpdateSampleStatus( "not OK to dismount" );
			MoveTongHome( );
			LOG_FINE1( "-RobotEpson::DismountCrystal %s", status_buffer );
			return TRUE;
		}

		if ( GetCurrentPoint ( ) != P3 )
		{
            UpdateSampleStatus( "wrong state" );
			MoveTongHome( );
			strcpy( status_buffer, "FAILED, need to call PrepareDismountCrystal first" );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
			LOG_FINE1( "-RobotEpson::DismountCrystal %s", status_buffer );
			return TRUE;
		}

        if (Dismounting( cassette, row, column ))
        {
            UpdateSampleStatus( "dismounted", true );
            sprintf( status_buffer, "normal %c %hd %c", cassette, row, column );
        }
        else
        {
            CollectStatusInfo( status_buffer, "normal n 0 N" );
        }

        //MoveTongHome( ); //we need to send finish message before moving tong home
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    LOG_FINE1( "-RobotEpson::DismountCrystal %s", status_buffer );
    return TRUE;
}

//If dismount part is done successfully, even mount part failed, it will return
//"normal"
BOOL RobotEpson::MountNextCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::MountNextCrystal %s", position );
    char sampleStatus[256] = {0};
 	char dism_cassette;
	short dism_row;
	char dism_column;

	char mnt_cassette;
	short mnt_row;
	char mnt_column;

    float dx;
    float dy;
    float dz;
    float du;

	bool dismount_finished_ok = false;

    try
    {
		//get and check position info
		int argc = sscanf( position, "%c %hd %c %c %hd %c %f %f %f %f %lu",
			&dism_cassette, &dism_row, &dism_column,
			&mnt_cassette, &mnt_row, &mnt_column,
			&dx, &dy, &dz, &du, &m_numCycleToWash );
		if (argc < 10)
		{
			MoveTongHome( );
			strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
			LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
			return TRUE;
		}
		else if (argc == 10)
		{
			m_numCycleToWash = 0;
		}

		//check DZ
		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            sprintf( sampleStatus, "%c%c%hd failed, gonio unreachable", dism_cassette, dism_column, dism_row );
            UpdateSampleStatus( sampleStatus );

			MoveTongHome( );

			LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
			return TRUE;
		}

		//check sample post status
		if (!OKToMountNext( dism_cassette, dism_row, dism_column, mnt_cassette, mnt_row, mnt_column, status_buffer ))
		{
            UpdateSampleStatus( "not OK to mountNext" );
			MoveTongHome( );
			LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
			return TRUE;
		}

		if ( GetCurrentPoint ( ) != P3 )
		{
            UpdateSampleStatus( "wrong state" );
			MoveTongHome( );
			strcpy( status_buffer, "FAILED, need to call PrepareMountNextCrystal first" );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
			LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
			return TRUE;
		}

		switch (m_MountNextTask)
		{
		case MOUNT_NEXT_NONE:
			MoveTongHome( );
			strcpy( status_buffer, "normal n 0 N normal n 0 N should not be here" );
            break;

		case MOUNT_NEXT_MOUNT:
			dismount_finished_ok = true;
			//mount only: copied from MountCrystal
            if (Mounting( mnt_cassette, mnt_row, mnt_column ))
            {
                UpdateSampleStatus( "mounted", true );
                sprintf( status_buffer, "normal n 0 N normal %c %hd %c nothing on goniometer", mnt_cassette, mnt_row, mnt_column );
            }
            else
            {
                CollectStatusInfo( status_buffer, "normal n 0 N normal n 0 N" );
            }
			break;

		case MOUNT_NEXT_DISMOUNT:
			//dismount only: copied from dismount
            if (Dismounting( dism_cassette, dism_row, dism_column ))
            {
                UpdateSampleStatus( "dismounted", true );
                sprintf( status_buffer, "normal %c %hd %c normal n 0 N", dism_cassette, dism_row, dism_column );
            }
            else
            {
                CollectStatusInfo( status_buffer, "normal n 0 N normal n 0 N" );
            }
			break;

		case MOUNT_NEXT_FULL:
			if (!GoniometerToPlacer( ))
            {
                sprintf( sampleStatus, "%c%c%hd mountnext: dismount failed", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( sampleStatus );

                strcpy( status_buffer, "Failed: GoniometerToPlacer" );
                break;
            }

			if (!GetMagnet ( ))
            {
                sprintf( sampleStatus, "%c%c%hd mountnext: GetMagnet failed", dism_cassette, dism_column, dism_row );
                UpdateSampleStatus( sampleStatus );
                strcpy( status_buffer, "Failed: GetMagnet failed at the beginning" );
                break;
            }

            UpdateSampleStatus( "move to port", true );
			m_pSPELCOM->Tool( 2 );
			MoveToPortViaStandby( dism_cassette, dism_row, dism_column );

			if (PutSampleIntoPort( ) == CSamplePort::PORT_SAMPLE_IN)
			{
				UpdateSampleStatus( "dismounted", true );
				dismount_finished_ok = true;
			}
			if (!GetMotorsOn( ))
			{
				UpdateSampleStatus( "robot stopped" );
				strcpy( status_buffer, "failed put sample into cassette" );
				//SetRobotFlags( FLAG_REASON_WRONG_STATE );
				LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
				return TRUE;
			}

			MoveFromPortToStandby ( );//no matter what, try



            if (m_FlagAbort || (GetRobotFlags( ) & (FLAG_NEED_CLEAR | FLAG_NEED_RESET)))
            {
                UpdateSampleStatus( "abort" );
				MoveFromCassetteToPost( );
				PutMagnet( );

				if (m_desiredLN2Level == LN2LEVEL_HIGH)
				{
					m_Dewar.TurnOnHeater( );
				}
				MoveTongHome( );
                sprintf( status_buffer, "normal %c %hd %c aborted", dism_cassette, dism_row, dism_column );
                CollectStatusInfo( status_buffer, status_buffer );
                break;
			}

            //continue to mount next crystal
            sprintf( sampleStatus, "%c%c%hd mounting", mnt_cassette, mnt_column, mnt_row );
            UpdateSampleStatus( sampleStatus );
			if (dism_cassette != mnt_cassette)
			{
				MoveFromCassetteToPost( );
			}

            sprintf( sampleStatus, "%c%c%hd robot move to port", mnt_cassette, mnt_column, mnt_row );
            UpdateSampleStatus( sampleStatus );
			m_pSPELCOM->Tool( 1 );
			MoveToPortViaStandby( mnt_cassette, mnt_row, mnt_column );
            {
				GetSampleFromPort( );
				if (!GetMotorsOn( ))
				{
					UpdateSampleStatus( "robot stopped" );
					strcpy( status_buffer, "failed to get sample from cassette" );
					LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
					return TRUE;
				}

				bool pick_sample = (GetSampleState( ) == SAMPLE_ON_PICKER);

				MoveFromPortToPost( );

				if (getAttributeFieldBool( ATTRIB_WASH_BEFORE_MOUNT) && m_numCycleToWash > 0)
				{
					LOG_FINE1( "washing before mountnext: %lu", m_numCycleToWash );
					doWash( m_numCycleToWash );
				}
			    PutMagnet( getAttributeFieldBool( ATTRIB_CHECK_POST), getAttributeFieldBool( ATTRIB_COLLECT_FORCE ) );

			    if (m_desiredLN2Level == LN2LEVEL_HIGH)
			    {
				    m_Dewar.TurnOnHeater( );
			    }

			    //old OnPickerAtPostToGoniometer
			    if (!(GetRobotFlags( ) & (FLAG_NEED_RESET | FLAG_NEED_CLEAR)) && pick_sample)
			    {
				    if (PickerToGoniometer( ))
                    {
                        UpdateSampleStatus( "mounted", true );
				        sprintf( status_buffer, "normal %c %hd %c normal %c %hd %c",
					        dism_cassette, dism_row, dism_column,
					        mnt_cassette, mnt_row, mnt_column);
                    }
                    else
                    {
                        strcpy( status_buffer, "PickerToGoniometer failed" );
                    }
			    }
			    else
			    {
				    MoveTongHome( );
                    sprintf( status_buffer, "normal %c %hd %c normal n 0 N", dism_cassette, dism_row, dism_column );
                    CollectStatusInfo( status_buffer, status_buffer );
			    }
            }
			break;
		default:
			MoveTongHome( );
            sprintf( status_buffer, "bad task for mountnext 0X%X", m_MountNextTask );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
		}
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

	//deal with cases that dismount OK but mount failed.
	if (strncmp( status_buffer, "normal", 6 ) && dismount_finished_ok)
	{
		char tmp_buffer[MAX_LENGTH_STATUS_BUFFER + 1] = {0};
		size_t space_left = 0;

		//send out error message first
        if (m_pEventListener)
        {
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
        }

		switch (m_MountNextTask)
		{
		case MOUNT_NEXT_MOUNT:
			strcpy( tmp_buffer, "normal n 0 N " );
			space_left = MAX_LENGTH_STATUS_BUFFER - strlen( tmp_buffer );
			strncat( tmp_buffer, status_buffer, space_left );
			strcpy( status_buffer, tmp_buffer );
			break;

		case MOUNT_NEXT_FULL:
            sprintf( tmp_buffer, "normal %c %hd %c ", dism_cassette, dism_row, dism_column );
			space_left = MAX_LENGTH_STATUS_BUFFER - strlen( tmp_buffer );
			strncat( tmp_buffer, status_buffer, space_left );
			strcpy( status_buffer, tmp_buffer );
			break;
		}
	}
    LOG_FINE1( "-RobotEpson::MountNextCrystal %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::MoveCrystal( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::MoveCrystal %s", argument );
    
    char  source_cassette;
    char  source_column;
    short source_row;

    char  target_cassette;
    char  target_column;
    short target_row;

    bool firstTime = true;
    char previousCassette;
    char previousColumn;
    short previousRow;

	const char* pRemainArgument = argument;

	PointCoordinate currentPosition;
	GetCurrentPosition( currentPosition );
	try
	{
		switch (GetCurrentPoint( ))
		{
		case P3:
			if (!OKToMove( argument, status_buffer ))
			{
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				}
				MoveTongHome( );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}

			if (!GetMagnet ( ))
			{
				strcpy( status_buffer, "FAILED, GetMagnet Failed" );
				UpdateSampleStatus( status_buffer );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}
			break;

		case P52:
			if (CloseToPoint( P52, currentPosition) &&
				GetDumbbellState( ) == DUMBBELL_IN_TONG &&
				m_pSPELCOM->GetTool( ) == 1)
			{
				if (!OKToMove( argument, status_buffer ))
				{
					if (m_pEventListener)
					{
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
					}
					MoveTongHome( );
					LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
					return TRUE;
				}
				firstTime = false;
				previousCassette = m_pState->currentCassette;
				previousColumn   = m_pState->currentColumn;
				previousRow      = m_pState->currentRow;
			}
			else
			{
				SetMotorsOn( false );
				SetRobotFlags( FLAG_REASON_WRONG_STATE );
				strcpy( status_buffer, "FAILED, bad state" );
				UpdateSampleStatus( "bad state" );
				//SetRobotFlags( FLAG_REASON_WRONG_STATE );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}
			break;

		default:
			MoveTongHome( );
			strcpy( status_buffer, "FAILED, need to call PrepareMoveCrystal first" );
            UpdateSampleStatus( "bad state" );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
			LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
			return TRUE;
		}

	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	    LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
		return TRUE;
	}

	strcpy( status_buffer, "normal" );

    //do the job
    try
    {
        m_pSPELCOM->Tool( 1 );

        while (ProcessMoveArgument( pRemainArgument,
            source_cassette, source_column, source_row,
            target_cassette, target_column, target_row ))
        {
            char sampleStatus[256] = {0};

            if (m_FlagAbort)
		    {
			    strcpy( status_buffer, "aborted" );
			    break;
		    }
            if (firstTime)
            {
                MoveToPortViaStandby( source_cassette, source_row, source_column );
                firstTime = false;
            }
            else
            {
                MoveFromPortToPort( previousCassette, previousColumn, previousRow, source_cassette, source_column, source_row );
            }
            previousCassette = source_cassette;
            previousColumn = source_column;
            previousRow = source_row;
           	CSamplePort::State portState = GetSampleFromPort(  );
			if (!GetMotorsOn( ))
			{
				UpdateSampleStatus( "robot stopped" );
				strcpy( status_buffer, "failed to get sample from cassette" );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}
			if (GetSampleState( ) != SAMPLE_ON_PICKER)
			{
				//check if port jam or port empty
				if ((GetRobotFlags( ) & (FLAG_NEED_RESET | FLAG_NEED_CLEAR)))
				{
					if (strlen( m_ErrorMessageForOldFunction ))
					{
						strcpy( status_buffer, m_ErrorMessageForOldFunction );
						memset( m_ErrorMessageForOldFunction, 0 , sizeof(m_ErrorMessageForOldFunction) );
					}
					else
					{
						strcpy( status_buffer, "check robot status" );
					}
					break;
				}
				else if (portState == CSamplePort::PORT_EMPTY || portState == CSamplePort::PORT_MOUNTED)
				{
	                sprintf( sampleStatus, "empty source %c%c%hi->%c%c%hi",
		                source_cassette, source_column, source_row,
			            target_cassette, target_column, target_row );
				    UpdateSampleStatus( sampleStatus );
					if (m_pEventListener)
					{
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, sampleStatus );
					}
					break;
				}
				else
				{
					sprintf( sampleStatus, "port jam at source %c%c%hi->%c%c%hi",
		                source_cassette, source_column, source_row,
			            target_cassette, target_column, target_row );
				    UpdateSampleStatus( sampleStatus );
					if (m_pEventListener)
					{
						m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, sampleStatus );
					}
					break;
				}
            }
            MoveFromPortToPort( source_cassette, source_column, source_row, target_cassette, target_column, target_row );
            previousCassette = target_cassette;
            previousColumn = target_column;
            previousRow = target_row;

			CSamplePort::State putResult = PutSampleIntoPort( );
			if (!GetMotorsOn( ))
			{
				strcpy( status_buffer, "check status" );
				UpdateSampleStatus( "failed" );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}
            if ((GetRobotFlags( ) & (FLAG_NEED_RESET | FLAG_NEED_CLEAR)))
            {
				if (strlen( m_ErrorMessageForOldFunction ))
				{
					strcpy( status_buffer, m_ErrorMessageForOldFunction );
					memset( m_ErrorMessageForOldFunction, 0 , sizeof(m_ErrorMessageForOldFunction) );
				}
				else
				{
					strcpy( status_buffer, "check robot status" );
				}
                break;
            }

			bool needStop = false;
			switch (putResult)
            {
			case CSamplePort::PORT_SAMPLE_IN:
	            sprintf( sampleStatus, "moved: %c%c%hi->%c%c%hi",
		            source_cassette, source_column, source_row,
			        target_cassette, target_column, target_row );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_NOTE, sampleStatus );
				}
				++m_pState->num_pin_moved;
				if (GetCassette( source_cassette ).GetType( ) == CCassette::CASSETTE_TYPE_SUPERPUCK ||
					GetCassette( target_cassette ).GetType( ) == CCassette::CASSETTE_TYPE_SUPERPUCK)
				{
					++m_pState->num_puck_pin_moved;
				}
				break;

			case CSamplePort::PORT_EMPTY:
                sprintf( sampleStatus, "move: lost pin at target %c%c%hi->%c%c%hi",
                    source_cassette, source_column, source_row,
                    target_cassette, target_column, target_row );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, sampleStatus );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, sampleStatus );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, sampleStatus );
				}
				needStop = true;
				break;

			case CSamplePort::PORT_JAM:
                sprintf( sampleStatus, "move: port jam at target %c%c%hi->%c%c%hi",
                    source_cassette, source_column, source_row,
                    target_cassette, target_column, target_row );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_WARNING, sampleStatus );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, sampleStatus );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, sampleStatus );
				}
				needStop = true;
				break;

			default:
				strcpy( sampleStatus, "bad result of putSampleIntoPort" );
				needStop = true;
            }
            UpdateSampleStatus( sampleStatus );
			if (needStop)
			{
				SetMotorsOn( false );
				SetRobotFlags( FLAG_REASON_WRONG_STATE );
				strcpy( status_buffer, sampleStatus );
				LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
				return TRUE;
			}
        }//while
		//MoveFromPortToPost( );
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
        LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
        return TRUE;
	}

    LOG_FINE1( "-RobotEpson::MoveCrystal %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::WashCrystal( const char position[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::WashCrystal %s", position );
    float dx;
    float dy;
    float dz;
    float du;
	int   times;

    try
    {
		//get and check position info
		if (sscanf( position, "%d %f %f %f %f", &times, &dx, &dy, &dz, &du ) != 5 || times < 0)
		{
			MoveTongHome( );
			strcpy( status_buffer, "FAILED: invalid argument" );
            UpdateSampleStatus( status_buffer );
            //SetRobotFlags( FLAG_REASON_BAD_ARG );
			LOG_FINE1( "-RobotEpson::WashCrystal %s", status_buffer );
			return TRUE;
		}

		if (!SetGoniometerPoints( dx, dy, dz, du, status_buffer ))
		{
            char sampleStatus[256] = {0};
            strcpy( sampleStatus, "wash failed, gonio unreachable" );
            UpdateSampleStatus( sampleStatus );
			MoveTongHome( );

			LOG_FINE1( "-RobotEpson::WashCrystal %s", status_buffer );
			return TRUE;
		}

		//check sample post status
		if (!OKToWash( status_buffer ))
		{
            UpdateSampleStatus( "not OK to Wash" );
			MoveTongHome( );
			LOG_FINE1( "-RobotEpson::WashCrystal %s", status_buffer );
			return TRUE;
		}

		if ( GetCurrentPoint ( ) != P3 )
		{
            UpdateSampleStatus( "wrong state" );
			MoveTongHome( );
			strcpy( status_buffer, "FAILED, need to call PrepareWashCrystal first" );
            //SetRobotFlags( FLAG_REASON_WRONG_STATE );
			LOG_FINE1( "-RobotEpson::WashCrystal %s", status_buffer );
			return TRUE;
		}

        if (Washing( times ))
        {
            UpdateSampleStatus( "Washed", true );
            strcpy( status_buffer, "normal" );
        }
        else
        {
            CollectStatusInfo( status_buffer, "normal" );
        }

        //MoveTongHome( ); //we need to send finish message before moving tong home
    }
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    LOG_FINE1( "-RobotEpson::WashCrystal %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::Standby( const char argument[], char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::Standby %s", argument );

	if (GetRobotFlags( ) & FLAG_NEED_RESET )
	{
		strcpy( status_buffer, "need reset" );
		return TRUE;
	}
	if (GetRobotFlags( ) & FLAG_NEED_USER_ACTION )
	{
		strcpy( status_buffer, "need user action" );
		return TRUE;
	}
	if (!GetMotorsOn( ))
	{
		strcpy( status_buffer, "motors off" );
		return TRUE;
	}

	try
	{
		if (!strcmp( argument, "low_power" ))
		{
			SetPowerHigh( false );
		    MoveTongHome( );
			SetPowerHigh( true );
			strcpy( status_buffer, "normal OK" );
		}
		else if (!strcmp( argument, "rescue_sample" ))
		{
			StandbyAtCoolPoint( );
		    SetMotorsOn( false );
			SetRobotFlags( FLAG_NEED_RESET | FLAG_REASON_NOT_HOME | FLAG_REASON_PIN_LOST );
            strcpy( status_buffer, "please rescue the sample if it is still in the cavity of tong" );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, status_buffer );
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
			}
		}
		else if (!strcmp( argument, "skip_heating" ))
		{
			StandbyAtCoolPoint( );
			strcpy( status_buffer, "normal OK" );
		}
		else
		{
		    MoveTongHome( );
			strcpy( status_buffer, "normal OK" );
		}
	}
	catch ( CException *e )
	{
        NormalErrorHandle( e, status_buffer );
	}

    LOG_FINE1( "-RobotEpson::Standby %s", status_buffer );
    return TRUE;
}

///////////////////////////////////////////////////
#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))
#define CFGMAP_ELEMENT( a ) { str##a, sizeof(str##a), &RobotEpson::CFG##a }
#define CALMAP_ELEMENT( a ) { str##a, sizeof(str##a), &RobotEpson::CAL##a }

BOOL RobotEpson::Config( const char argument[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::Config %s", argument );

    static const char strResetAllowed[] = "reset_allowed";
    static const char strMoveToCheckPoint[] = "move_to_checkpoint";
    static const char strOpenGripper[] = "open_gripper";
    static const char strHeatGripper[] = "heat_gripper";
    static const char strCheckDumbbell[] = "check_dumbbell";
    static const char strReturnDumbbell[] = "return_dumbbell";
    static const char strProbe[] = "probe";

	//check
	static const char strCheckHeater[] = "check_heater";
	static const char strCheckGripper[] = "check_gripper";
	static const char strCheckLid[] = "check_lid";

	//low level: these will check related input bits and may set flags
	static const char strLLOpenGripper[]  = "ll_open_gripper";
	static const char strLLCloseGripper[] = "ll_close_gripper";
	static const char strLLOpenLid[]      = "ll_open_lid";
	static const char strLLCloseLid[]     = "ll_close_lid";

	//hardware test: No check, No flag setting
	static const char strHWOutputSwitch[] = "hw_output_switch";

	//commands to test stripper
	//may be discarded in the future.
	static const char strStripperTakeMagnet[]	= "stripper_take_dumbbell";
	static const char strStripperRun[]			= "stripper_run";
	static const char strStripperGoHome[]		= "stripper_go_home";
	static const char strPortJamAction[]		= "port_jam_action";

	//SPEL command
    static const char strCommand[] = "command";

	//to raise robot step by step to rescue sample during reset
	static const char strStepUp[]		= "raise_robot";


	//also support
	//"reset_counter"
	//"clear"
	//"clear_status"
	//"clear_all"
	//"set_flags"
	//"get_meminfo"
	//"shutdown"
	//"clear_mounted"
	//"set_check_filling on/off"
	//"set_desired_ln2_level high/low"
	//"reset_strip_counter"

    SubCommandMap commandMap[] = 
    {
        CFGMAP_ELEMENT( StripperTakeMagnet ),
        CFGMAP_ELEMENT( StripperRun ),
        CFGMAP_ELEMENT( StripperGoHome ),
        CFGMAP_ELEMENT( PortJamAction ),


        CFGMAP_ELEMENT( ResetAllowed ),
        CFGMAP_ELEMENT( MoveToCheckPoint ),
        CFGMAP_ELEMENT( OpenGripper ),
        CFGMAP_ELEMENT( HeatGripper ),
        CFGMAP_ELEMENT( CheckDumbbell ),
        CFGMAP_ELEMENT( ReturnDumbbell ),
        CFGMAP_ELEMENT( Probe ),
        CFGMAP_ELEMENT( CheckHeater ),
        CFGMAP_ELEMENT( CheckGripper ),
        CFGMAP_ELEMENT( CheckLid ),
        CFGMAP_ELEMENT( LLOpenGripper ),
        CFGMAP_ELEMENT( LLCloseGripper ),
        CFGMAP_ELEMENT( LLOpenLid ),
        CFGMAP_ELEMENT( LLCloseLid ),
        CFGMAP_ELEMENT( LLOpenGripper ),
        CFGMAP_ELEMENT( HWOutputSwitch ),
        CFGMAP_ELEMENT( StepUp ),
        CFGMAP_ELEMENT( Command )
    };

    for (int i = 0; i < ARRAYLENGTH( commandMap ); ++i)
    {
		if (!strncmp( argument, commandMap[i].pSubCommand, commandMap[i].CmdLength - 1 ))
        {
			UpdateSampleStatus( commandMap[i].pSubCommand );
            BOOL result = (this->*commandMap[i].FunctionToCall)( argument +commandMap[i].CmdLength, status_buffer );
			UpdateSampleStatus( "" );

            LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
            return result;
        }
    }

	//special cases
	if (!strncmp( argument, "set_index_state", 14 ))
	{
		int start_index(-1);
		int length(0);
		char cState   = 'b';

		if (sscanf( argument, "%*s %d %d %c", &start_index, &length, &cState ) != 3) {
			strcpy( status_buffer, "bad arguments: start_index length state" );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		LOG_FINE3( "set_index_state: %d %d %c", start_index, length, cState );

		//check
		char cassette('n');
		
		//first index is for cassette status
		const int NUM_INDEX_PER_CASSETTE = CCassette::MAX_NUM_PORT + 1;

		if (start_index < 0)
		{
			strcpy( status_buffer, "bad start_index < 0 " );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}
		else if (start_index < NUM_INDEX_PER_CASSETTE)
		{
			cassette = 'l';
		}
		else if (start_index < 2 * NUM_INDEX_PER_CASSETTE)
		{
			cassette = 'm';
		}
		else if (start_index < 3 * NUM_INDEX_PER_CASSETTE)
		{
			cassette = 'r';
		}
		else
		{
			sprintf( status_buffer, "bad start_index too big, max %d",  (3 * CCassette::MAX_NUM_PORT - 1));
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}
		CCassette& theCassette = GetCassette( cassette );

		//convert state from char
		CSamplePort::State portState(CSamplePort::PORT_BAD);
		switch (cState)
		{
		case 'u':
			portState = CSamplePort::PORT_UNKNOWN;
			LOG_FINE( "port state unknow" );
			break;

		case 'j':
			portState = CSamplePort::PORT_JAM;
			LOG_FINE( "port state jam" );
			break;

		case 'b':
			portState = CSamplePort::PORT_BAD;
			LOG_FINE( "port state bad" );
			break;

		case '-':
			portState = CSamplePort::PORT_NOT_EXIST;
			LOG_FINE( "port state not_exist" );
			break;

		default:
			strcpy( status_buffer, "bad port state only allow u j b" );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		int start_in_cassette = start_index % NUM_INDEX_PER_CASSETTE;
		theCassette.SetIndexPortState( start_in_cassette, length, portState );
        UpdateCassetteStatus( );

        sprintf( status_buffer, "normal index ports %d %d set to %c", start_index, length, cState);

        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_port_state", 14 ))
	{
		char cassette = 'n';
		char column   = 'N';
		short row     = -1;
		char cState   = 'b';

		if (sscanf( argument, "%*s %c%c%hd %c", &cassette, &column, &row, &cState ) != 4) {
			strcpy( status_buffer, "bad arguments: cCR s" );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		LOG_FINE4( "set_port_state: %c %c %hd %c", cassette, column, row,cState );

		//check cassette
		switch (cassette)
		{
		case 'l':
		case 'm':
		case 'r':
			break;

		default:
			strcpy( status_buffer, "bad cassette only allow l m r" );
			LOG_FINE1( "bad cassette %c", cassette );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}
		CCassette& theCassette = GetCassette( cassette );
		
		if (column != 'X')
		{
			//check row and column
			short row_to_check = row;
			if (row == 0)
			{
				//row == 0 means all rows
				row_to_check = 1;
			}
			if (!theCassette.PositionIsValid( row_to_check, column ))
			{
				strcpy( status_buffer, "bad port row or column" );
				LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
				return TRUE;
			}
		}

		//convert state from char
		CSamplePort::State portState(CSamplePort::PORT_BAD);
		switch (cState)
		{
		case 'u':
			portState = CSamplePort::PORT_UNKNOWN;
			LOG_FINE( "port state unknow" );
			break;

		case 'j':
			portState = CSamplePort::PORT_JAM;
			LOG_FINE( "port state jam" );
			break;

		case 'b':
			portState = CSamplePort::PORT_BAD;
			LOG_FINE( "port state bad" );
			break;

		case '-':
			portState = CSamplePort::PORT_NOT_EXIST;
			LOG_FINE( "port state not_exist" );
			break;

		default:
			strcpy( status_buffer, "bad port state only allow u j b" );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}


		//deal with special cases
		if (column == 'X')
		{
			theCassette.SetAllPortState( portState );
		}
		else if (row == 0)
		{
			theCassette.SetColumnPortState( column, portState );
		}
		else
		{
			//set the port state
			theCassette.SetPortState( row, column, portState );
		}

        UpdateCassetteStatus( );

        sprintf( status_buffer, "normal port %c%c%hd set to %c", cassette, column, row, cState );

        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "clear_force", 11 ))
	{
		m_LeftCassette.clearForce( );
		m_MiddleCassette.clearForce( );
		m_RightCassette.clearForce( );
		updateForces( );
		strcpy( status_buffer, "normal all forces cleared" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_desired_ln2_level", 21 ))
	{
		if (strstr( (argument + 21), "low" ) || strstr( (argument + 21), "0" ))
		{
			if (SetDesiredLN2LevelInSPEL( false, status_buffer ))
			{
				if (m_desiredLN2Level == LN2LEVEL_LOW)
				{
					strcpy( status_buffer, "normal set desired LN2 level to low" );
				}
				else
				{
					strcpy( status_buffer, "failed: readback not agree with setting" );
				}
			}
		}
		else
		{
			if (SetDesiredLN2LevelInSPEL( true, status_buffer ))
			{
				if (m_desiredLN2Level == LN2LEVEL_HIGH)
				{
					strcpy( status_buffer, "normal set desired LN2 level to high" );
				}
				else
				{
					strcpy( status_buffer, "failed: readback not agree with setting" );
				}
			}
		}
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_check_filling", 18 ))
	{
		if (strstr( (argument + 18), "off" ) || strstr( (argument + 18), "0" ))
		{
			m_CheckAutoFilling = false;
			strcpy( status_buffer, "normal check LN2 auto filing turned off" );
		}
		else
		{
			m_CheckAutoFilling = true;
			strcpy( status_buffer, "normal check LN2 auto filing turned on" );
		}
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strcmp( argument, "shutdown" ))
	{
		robotSystemStop( );

		strcpy( status_buffer, "normal system shutdown" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strcmp( argument, "reboot" ))
	{
		if (!ShutDownSystem( status_buffer, true ))
		{
			return TRUE;
		}

		strcpy( status_buffer, "normal system reboot" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strcmp( argument, "get_meminfo" ))
	{
		DcsMessageManager& theMsgManager = DcsMessageManager::GetObject( );		
        if (m_pEventListener)
        {
			sprintf( status_buffer, "max text size=%lu", theMsgManager.GetMaxTextSize( ) );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
			sprintf( status_buffer, "max binary size=%lu", theMsgManager.GetMaxBinarySize( ) );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
			sprintf( status_buffer, "max pool size=%lu", theMsgManager.GetMaxPoolSize( ) );
			m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_UPDATE, status_buffer );
		}
		sprintf( status_buffer, "new: %lu delete %lu", theMsgManager.GetNewCount( ), theMsgManager.GetDeleteCount( ) );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strcmp( argument, "reset_permanent_counter" ))
    {
        m_pState->num_pin_mounted = 0;
        m_pState->num_pin_lost = 0;
		m_pState->num_pin_stripped = 0;
		m_pState->num_puck_pin_mounted = 0;
		m_pState->num_pin_moved = 0;
		m_pState->num_puck_pin_moved = 0;
		FlushViewOfFile( m_pState, 0 );
        if (m_pEventListener)
        {
            char empty[2] = {0};
			empty[0] = '0';
			empty[1] = 0;
            //m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINMOUNTED, empty );
        }
        strcpy( status_buffer, "normal counter resetted" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
    }

	if (!strcmp( argument, "reset_mounted_counter" ))
    {
		m_pState->num_pin_mounted_short_trip = 0;
		m_pState->num_puck_pin_mounted_short_trip = 0;
		m_pState->num_pin_lost_short_trip = 0;
		FlushViewOfFile( m_pState, 0 );
        if (m_pEventListener)
        {
            char empty[2] = {0};
			empty[0] = '0';
			empty[1] = 0;
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINMOUNTED, empty );
        }
        strcpy( status_buffer, "normal counter resetted" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
    }
	if (!strcmp( argument, "reset_stripped_counter" ))
    {
		m_pState->num_pin_stripped_short_trip = 0;
	    UpdateState( );
        strcpy( status_buffer, "normal counter resetted" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
    }


	if (!strcmp( argument, "reset_cassette" ))
    {
		ResetCassetteStatus( true ); //forced clear
        strcpy( status_buffer, "normal cassette status resetted" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
    }

	if (!strncmp( argument, "set_flags", 9))
    {
		RobotStatus flags = 0;
		if (strstr( (argument + 9), "reset" ))
		{
			flags |= FLAG_NEED_RESET | FLAG_REASON_EXTERNAL;
		}
		if (strstr( (argument + 9), "clear" ))
		{
			flags |= FLAG_NEED_CLEAR | FLAG_REASON_EXTERNAL;
		}
		if (strstr( (argument + 9), "gonio" ))
		{
			flags |= FLAG_NEED_CAL_GONIO | FLAG_REASON_EXTERNAL;
		}

		if (strstr( (argument + 9), "cassette" ))
		{
			flags |= FLAG_NEED_CAL_CASSETTE | FLAG_REASON_EXTERNAL;
		}

		if (strstr( (argument + 9), "magnet" ))
		{
			flags |= FLAG_NEED_CAL_MAGNET | FLAG_REASON_EXTERNAL;
		}

		if (strstr( (argument + 9), "ln2" ))
		{
			flags |= FLAG_REASON_LN2LEVEL | FLAG_NEED_CAL_MAGNET | FLAG_NEED_CAL_CASSETTE | FLAG_NEED_CAL_GONIO;
			flags &= ~FLAG_REASON_EXTERNAL;
		}

		if (flags != 0)
		{
			SetRobotFlags( flags );
		}

        strcpy( status_buffer, "normal flags set" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}

	if (!strncmp( argument, "clear_mounted", 13))
	{
		ClearMounted( );
        strcpy( status_buffer, "normal mouted cleared" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_mounted", 11 ))
	{
		char cas = 'n';
		int  row = -1;
		char column = 'N';

		if (sscanf( argument + 11 + 1, "%c %c %d", &cas, &column, &row ) != 3 &&
			sscanf( argument + 11 + 1, "%c%c%d", &cas, &column, &row ) != 3)
		{
			strcpy( status_buffer, "bad argument for mounted: should be cassette column row" );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		if (PositionIsBeamlineTool( cas, (short)row, column ))
		{
			SetSampleState( SAMPLE_ON_GONIOMETER );
			//normal members
			m_pState->currentCassette = cas;
			m_pState->currentRow = row;
			m_pState->currentColumn = column;
			SetGonioSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn );
			sprintf( status_buffer, "normal mounted set to %c %c %d", cas, column, row );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		if (!PositionIsValid( cas, (short)row, column ))
		{
			strcpy( status_buffer, "bad argument for mounted: position invalid" );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}

		///////////////////////////////////////
		SetSampleState( SAMPLE_ON_GONIOMETER );
		SetDumbbellState( DUMBBELL_IN_CRADLE );
		//normal members
		m_pState->currentCassette = cas;
		m_pState->currentRow = row;
		m_pState->currentColumn = column;
        SetGonioSample( m_pState->currentCassette, m_pState->currentRow, m_pState->currentColumn );

		//ResetCassetteStatus( );
		GetCassette( cas ).SetPortState( row, column, CSamplePort::PORT_UNKNOWN );
		GetCassette( cas ).SetPortNeedProbe( row, column );
	    UpdateCassetteStatus( );
		UpdateState( );
		UpdateSampleStatus( "robot resetted" );

		sprintf( status_buffer, "normal mounted set to %c %c %d", cas, column, row );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_picker", 11 ))
	{
		char cas = 'n';
		int  row = -1;
		char column = 'N';

		if (sscanf( argument + 11 + 1, "%c %c %d", &cas, &column, &row ) != 3 &&
			sscanf( argument + 11 + 1, "%c%c%d", &cas, &column, &row ) != 3)
		{
			strcpy( status_buffer, "bad argument for picker: should be cassette column row" );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}
		if (!PositionIsValid( cas, (short)row, column ))
		{
			cas = 'n';
			row = 0;
			column = 'N';
		}

        SetPickerSample( cas, row, column );

		GetCassette( cas ).SetPortState( row, column, CSamplePort::PORT_EMPTY );
	    UpdateCassetteStatus( );
		UpdateState( );

		sprintf( status_buffer, "normal picker set to %c %c %d", cas, column, row );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "get_hampton_pin", 15))
	{
        sprintf( status_buffer, "normal hampton_pin=%d", m_hamptonPin );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_hampton_pin", 15))
	{
		if (strstr( (argument + 15), "1" ) || strstr( (argument + 15), "t" ))
		{
			m_hamptonPin = 1;
		}
		else
		{
			m_hamptonPin = 0;
		}
        sprintf( status_buffer, "normal hampton_pin=%d", m_hamptonPin );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "restore_cassette", 16))
	{
		size_t ll = strlen( argument );
		if (ll == 16)
		{
			m_LeftCassette.restoreStatusFromFile( );
			m_MiddleCassette.restoreStatusFromFile( );
			m_RightCassette.restoreStatusFromFile( );
		}
		else if (ll < 21 && argument[16] == ' ')
		{
			const char * pCassetteName = &(argument[17]);
			while (*pCassetteName != '\0')
			{
				switch (*pCassetteName)
				{
				case 'l':
					m_LeftCassette.restoreStatusFromFile( );
					break;
				case 'm':
					m_MiddleCassette.restoreStatusFromFile( );
					break;
				case 'r':
					m_RightCassette.restoreStatusFromFile( );
					break;
				}//switch
				++pCassetteName;
			}//while
		}
		UpdateCassetteStatus( );
		strcpy( status_buffer, "normal reloaded" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}
	if (!strncmp( argument, "set_cassette_state", 18))
	{
		size_t ll = strlen( argument );
		if (ll != (18 + 3 + CCassette::NUM_STRING_STATUS_LENGTH))
		{
			strcpy( status_buffer, "bad status string" );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}
		const char * pCassetteName = &(argument[19]);
		switch (*pCassetteName)
		{
		case 'l':
			m_LeftCassette.loadStatusFromString( argument + 21 );
			break;
		case 'm':
			m_MiddleCassette.loadStatusFromString( argument + 21 );
			break;
		case 'r':
			m_RightCassette.loadStatusFromString( argument + 21 );
			break;
		default:
			strcpy( status_buffer, "wrong cassette" );
			LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
		}//switch
		UpdateCassetteStatus( );
		strcpy( status_buffer, "normal loaded" );
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}


	if (!strcmp( argument, "clear_all" ) || !strcmp( argument, "clear" ) || !strcmp( argument, "clear_status" ))
	{
		//clear pin lost counters
		m_pState->num_pin_lost_short_trip = 0;
        m_pState->num_pin_mounted_before_lost = 0;
		m_pState->num_pin_stripped_short_trip = 0;
		FlushViewOfFile( m_pState, 0 );

        if (m_pEventListener)
        {
            char empty[2] = {0};
			empty[0] = '0';
			empty[1] = 0;
            m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_PINLOST, empty );
        }

        if (!BringRobotUp( status_buffer ))
	    {
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
	    }
		ClearRobotFlags( FLAG_REASON_SAFEGUARD | FLAG_REASON_ESTOP );

		if (!PassSelfTest( false, status_buffer ))
	    {
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
	    }
		ClearRobotFlags( FLAG_REASON_GRIPPER_JAM | FLAG_REASON_HEATER_FAIL | FLAG_REASON_LID_JAM );

	    if (!strcmp( argument, "clear" ))
        {
            if (!OKToClear( status_buffer ))
            {
                LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		        return TRUE;
            }
            try
            {
				PointCoordinate currentP;
				GetCurrentPosition( currentP );

                //check for P0(home) P1(rest)
                if (!CloseToPoint( P0, currentP ) && !CloseToPoint( P1, currentP ))
                {
                    strcpy( status_buffer, "robot not at home, need reset" );
					SetRobotFlags( FLAG_REASON_NOT_HOME );
                    LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		            return TRUE;
                }
				ClearRobotFlags( FLAG_REASON_NOT_HOME );
			}
	        catch ( CException *e )
	        {
                NormalErrorHandle( e, status_buffer );
	            LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			    return TRUE;
	        }
			//check to see if cassette not sit right
			if ((GetRobotFlags( ) & FLAG_REASON_CASSETTE) &&
				(m_LeftCassette.GetStatus( ) == CCassette::CASSETTE_PROBLEM ||
					m_MiddleCassette.GetStatus( ) == CCassette::CASSETTE_PROBLEM ||
					m_RightCassette.GetStatus( ) == CCassette::CASSETTE_PROBLEM))
			{
				strcpy( status_buffer, "Cassette Sitting problem needs real inspection" );
				if (m_pEventListener)
				{
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_WARNING, status_buffer );
					m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_LOG_ERROR, status_buffer );
				}
	            LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
				return TRUE;
			}

			//this may clear all reasons if all needs are cleared
            ClearRobotFlags( FLAG_NEED_CLEAR ); //may be set again later in this function if something failed.
        } else {
            //(!strcmp( argument, "clear_all" ) || !strcmp( argument, "clear_status" ))
            //persistent members (saved in memmap file)
    		ClearRobotFlags( FLAG_ALL );
			SetDumbbellState( DUMBBELL_IN_CRADLE );
        }
        if (!strcmp( argument, "clear_all" ))
        {
            ClearAll( );
        }

        try
        {
			CopyDesiredLN2LevelFromSPEL( );
			SetLN2Level( m_desiredLN2Level );
			InitPoints( ); //may set flag again
		}
	    catch ( CException *e )
	    {
            NormalErrorHandle( e, status_buffer );
	        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
			return TRUE;
	    }

        UpdateState( );

		if (!GetRobotFlags( ))
		{
            try
            {
			    if (!GetMotorsOn( ))
			    {
				    SetMotorsOn( true );
			    }
			    SetPowerHigh( true );
        		strcpy( status_buffer, "normal 0 all cleared" );
            }
	        catch ( CException *e )
	        {
                NormalErrorHandle( e, status_buffer );
	        }
		}
        else
        {
            strcpy( status_buffer, "failed check robot status" );
        }
        LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
		return TRUE;
	}

    strcpy( status_buffer, "Not implemented yet" );
    LOG_FINE1( "-RobotEpson::Config %s", status_buffer );
    return TRUE;
}

BOOL RobotEpson::Calibrate( const char argument[],  char status_buffer[] )
{
    LOG_FINE1( "+RobotEpson::Calibrate %s", argument );
    
    static const char strPost[]         = "magnet_post";
    static const char strCassette[]     = "cassette";
    static const char strGoniometer[]   = "goniometer";

    //these two are for mount/dismount from a special place where a beamline calibration tool will sit.
    static const char strBeamLineTool[]         = "beamline_tool";
    static const char strMountBeamLineTool[]    = "mount_beamline_tool";
    static const char strDismountBeamLineTool[] = "dismount_beamline_tool";
    
    //this is for manual set goniometer position before auto goniometer cal
    static const char strMoveToGoniometer[]         = "move_to_goniometer";
    static const char strMoveHome[]                 = "move_home";
    static const char strSaveGoniometerPosition[]  = "save_goniometer_position";

	//check goniometer reachable
	static const char strCheckGoniometerReachable[]  = "check_goniometer_reachable";

	//this will be called before "goniometer" so that move to goniometer and move back to home will
	//NOT be part of goniometer calibration.
	//This way, once the result is saved, the operation will not be aborted by auto-filling
	//It is still not the same as prepare for mount/dismount.
	//Prepare mount/dismount only cool the tong, not really move the tong to the goniomter
	//So before call this, all table and goniometer motors should be ready in access position
	static const char strPrepareGoniometer[]		= "prepare_goniometer";

    static const char strRun[]   = "run";

    SubCommandMap commandMap[] = 
    {
        CALMAP_ELEMENT( Post ),
        CALMAP_ELEMENT( Cassette ),
        CALMAP_ELEMENT( Goniometer ),
        CALMAP_ELEMENT( BeamLineTool ),
        CALMAP_ELEMENT( MountBeamLineTool ),
        CALMAP_ELEMENT( DismountBeamLineTool ),
        CALMAP_ELEMENT( MoveToGoniometer ),
        CALMAP_ELEMENT( MoveHome ),
        CALMAP_ELEMENT( SaveGoniometerPosition ),
        CALMAP_ELEMENT( PrepareGoniometer ),
        CALMAP_ELEMENT( CheckGoniometerReachable ),
        CALMAP_ELEMENT( Run )
    };

    if (strncmp( argument, strDismountBeamLineTool, sizeof(strDismountBeamLineTool) ))
    {
        SetRobotFlags( FLAG_IN_CALIBRATION );
    }

    for (int i = 0; i < ARRAYLENGTH( commandMap ); ++i)
    {
		if (!strncmp( argument, commandMap[i].pSubCommand, commandMap[i].CmdLength - 1 ))
        {
            BOOL result = (this->*commandMap[i].FunctionToCall)( argument +commandMap[i].CmdLength, status_buffer );
            ClearRobotFlags( FLAG_IN_CALIBRATION );
		    UpdateSampleStatus( "" );
            LOG_FINE1( "-RobotEpson::Calibrate %s", status_buffer );
            return result;
        }
    }

    strcpy( status_buffer, "Not implemented yet" );
    
    ClearRobotFlags( FLAG_IN_CALIBRATION );

    LOG_FINE1( "-RobotEpson::Calibrate %s", status_buffer );

    return TRUE;
}

BOOL RobotEpson::RegisterEventListener( RobotEventListener& listener )
{
    if (m_pEventListener) return false;
    m_pEventListener = &listener;
    return true;
}
void RobotEpson::UnregisterEventListener( RobotEventListener& listener )
{
    if (m_pEventListener == &listener) m_pEventListener = NULL;
}

bool RobotEpson::PassSelfTest( bool forced, char* status_buffer )
{
	//check lid uses check this argument to decide whether try to open/close lid
	const char argument[] = "selftest";

	bool gripper_OK = true;
	bool lid_OK = true;
	bool heater_OK = true;

	if (forced || (GetRobotFlags( ) & FLAG_REASON_GRIPPER_JAM))
	{
		CFGCheckGripper( argument, status_buffer );
		if (strncmp( status_buffer, "normal", 6 ))
		{
			gripper_OK = false;
		}
	}


	if (forced || (GetRobotFlags( ) & FLAG_REASON_LID_JAM))
	{
		CFGCheckLid( argument, status_buffer );
		if (strncmp( status_buffer, "normal", 6 ))
		{
			lid_OK = false;
		}
	}

	if (forced || (GetRobotFlags( ) & FLAG_REASON_HEATER_FAIL))
	{
		CFGCheckHeater( argument, status_buffer );
		if (strncmp( status_buffer, "normal", 6 ))
		{
			heater_OK = false;
		}
	}

	//if not forced, then clear flags
	if (!forced)
	{
		if (gripper_OK) ClearRobotFlags( FLAG_REASON_GRIPPER_JAM );
		if (lid_OK)     ClearRobotFlags( FLAG_REASON_LID_JAM );
		if (heater_OK)  ClearRobotFlags( FLAG_REASON_HEATER_FAIL );
	}


	if (gripper_OK && lid_OK && heater_OK)
	{
		return true;
	}

	//fill status_buffer
	strcpy( status_buffer, "self test failed:" );
	if (!gripper_OK)
	{
		strcat( status_buffer, " gripper jam" );
	}
	if (!lid_OK)
	{
		strcat( status_buffer, " lid jam" );
	}
	if (!heater_OK)
	{
		strcat( status_buffer, " heater failure" );
	}

	return false;
}

bool RobotEpson::ShutDownSystem( char* status_buffer, bool restart )
{
	HANDLE hToken; 
	TOKEN_PRIVILEGES tkp; 
 
	// Get a token for this process. 
 
	if (!OpenProcessToken(GetCurrentProcess(), 
        TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, &hToken))
	{
		strcpy( status_buffer, "OpenProcessToken" );
		LOG_WARNING( status_buffer );
		return false;
	}
 
	// Get the LUID for the shutdown privilege. 
 
	LookupPrivilegeValue(NULL, SE_SHUTDOWN_NAME, 
        &tkp.Privileges[0].Luid); 
 
	tkp.PrivilegeCount = 1;  // one privilege to set    
	tkp.Privileges[0].Attributes = SE_PRIVILEGE_ENABLED; 
 
	// Get the shutdown privilege for this process. 
 
	AdjustTokenPrivileges(hToken, FALSE, &tkp, 0, 
        (PTOKEN_PRIVILEGES)NULL, 0); 
 
	// Cannot test the return value of AdjustTokenPrivileges. 
 
	DWORD err_num = ::GetLastError( );

	if (err_num != (DWORD)ERROR_SUCCESS)
	{
		sprintf( status_buffer, "AdjustTokenPrivileges: %lu", err_num ); 
		LOG_WARNING( status_buffer );
	}
 
	// Shut down the system and force all applications to close. 

	UINT flags = EWX_SHUTDOWN | EWX_FORCE;
	if (restart) flags |= EWX_REBOOT;
 
	if (!ExitWindowsEx(  flags, 0 )) 
	{
		sprintf( status_buffer, "ExitWindowsEx: %lu", ::GetLastError( ) ); 
		LOG_WARNING( status_buffer );
		return false;
	}
	return true;
}
