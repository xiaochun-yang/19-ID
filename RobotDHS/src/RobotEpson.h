#pragma once
#include "stdafx.h"

#include "Robot.h"
#include "MMapfile.h"
#include "Registry.h"

#include "RobotPoint.h"
#include "Cassette.h"
#include "Dewar.h"

#include "TclList.h"

#ifdef EPSON_VB_4
#include "spelcomctrl1.h"
#include "DSpelDlg.h"
#define SPEL_COM_CLASS_NAME    CSpelcomctrl1
#define SPEL_DIALOG_CLASS_NAME CDSpelDlg

#elif defined( EPSON_VB_3 )
#include "spelcom3.h"
#include "SpelDlg.h"
#define SPEL_COM_CLASS_NAME    CSPELCom3
#define SPEL_DIALOG_CLASS_NAME CSpelDlg

#else
#error Must define EPSON_VB_3 or EPSON_VB_4
#endif

using namespace std;

//wait 1 second before reading force
#define WAIT_TIME_BEFORE_READ_FORCE 100
//wait 1 millisecond between sampling force
#define WAIT_TIME_BETWEEN_READ_FORCE 1
//wait 2 second before reset force sensor
#define WAIT_TIME_BEFORE_RESET_FORCE_SENSOR 2000

//because SPELCOM only support single thread style, the creation is called in Initialize
//and destruction is called in Cleanup.  These two methods are called in the same Robot thread.

//dumbbell has two ends, one is called picker, the other placer.
//Picker is used to extract the sample from cassette.
//Placer is used to put the sample back to cassette.


class RobotEpson: public Robot {
public:
	enum CurrentSampleState
	{
		NO_CURRENT_SAMPLE,
		SAMPLE_ON_TONG,
		SAMPLE_ON_PLACER,
		SAMPLE_ON_PICKER,
		SAMPLE_ON_GONIOMETER
	};
	enum DumbbellState
	{
		DUMBBELL_OUT,	//not in port of dewar, not in tong,
		DUMBBELL_RAISED,	// in tong, out of dewar
		DUMBBELL_IN_CRADLE,
		DUMBBELL_IN_TONG
	};
	enum PortForceStatus
	{
		PORT_FORCE_OK,
		PORT_FORCE_TOO_SMALL,
		PORT_FORCE_TOO_BIG
	};
	enum LPoint
	{
	P0, P1, P2, P3, P4, P5, P6, P7, P8, P9, P10,
	P11, P12, P13, P14, P15, P16, P17, P18, P19, P20,
	P21, P22, P23, P24, P25, P26, P27, P28, P29, P30,
	P31, P32, P33, P34, P35, P36, P37, P38, P39, P40,
	P41, P42, P43, P44, P45, P46, P47, P48, P49, P50,
	P51, P52, P53, P54, P55, P56, P57, P58, P59, P60,
	P61, P62, P63, P64, P65, P66, P67, P68, P69, P70,
	P71, P72, P73, P74, P75, P76, P77, P78, P79, P80,
	P81, P82, P83, P84, P85, P86, P87, P88, P89, P90,
	P91, P92, P93, P94, P95, P96, P97, P98, P99, P100
	};
	enum ToolSet
	{
		pickerTool,
		placerTool,
        tempTool
	};

    enum ForceName
    {
        FORCE_XFORCE = 1,
        FORCE_YFORCE,
        FORCE_ZFORCE,
        FORCE_XTORQUE,
        FORCE_YTORQUE,
        FORCE_ZTORQUE
    };
    enum LN2Level
    {
        LN2LEVEL_LOW,
        LN2LEVEL_HIGH
    };

	//these numbers are also used to calculate the angle = num * 90 degrees.
	enum PerfectOrientation
	{
		DIRECTION_X_AXIS = 0,
		DIRECTION_Y_AXIS = 1,
		DIRECTION_MX_AXIS = 2,
		DIRECTION_MY_AXIS = 3
	};

	enum RobotSpeed {
		SPEED_FAST = 0,
		SPEED_IN_LN2,
		SPEED_SAMPLE, //slower than in LN2
		SPEED_PROBE,  //very slow in force touching
		SPEED_DANCE,  //in heater
		NUM_SPEED, //must at last so it will equal to number of speed defined.
	};

    enum Constants
    {
        FORCE_READ_TIMES = 100,
        FORCE_BINARY_CROSS_TIMES = 6,
        FORCE_RETRY_TIMES = 3,
		FORCE_SAFE_ARRAY_LENGTH = 7,

		TIME_DELAY_AFTER_LN2_FILLING = 600,	//forbid calibration within 10 minutes after auto fill
		TIME_SPAN_FOR_LN2_LEVEL_CALIBRATION = 7200,		// if LN2 level is not normal for continuous this long, all calibration will be turned on
		TIME_SPAN_FOR_LN2_WARNING = 300,    // inspection will be turned on if LN2 level is not normal for this long

		COMMAND_BUFFER_LENGTH = 1024,
		PORT_ERROR_EMPTY = -99,
    };

	struct RobotSpeedSetup {
		short go_acc;
		short go_dcc;
		short go_speed;

		short move_acc;
		short move_dcc;
		short move_speed;

		RobotSpeedSetup( short ga, short gd, short gs, short ma, short md, short ms ):
		go_acc(ga),
		go_dcc(gd),
		go_speed(gs),
		move_acc(ma),
		move_dcc(md),
		move_speed(ms)
		{
		}
		RobotSpeedSetup( ):
		go_acc(0),
		go_dcc(0),
		go_speed(0),
		move_acc(0),
		move_dcc(0),
		move_speed(0)
		{
		}

	};

	RobotEpson( );

	~RobotEpson( );

	virtual BOOL Initialize( );
	virtual void Cleanup( );
	virtual void Poll( );

	virtual RobotStatus GetStatus( ) const { return GetRobotFlags( ); }
	virtual void SetAttribute( const char attributes[] );
	virtual const char* GetAttribute( ) const {
		return m_attributeList.getList( );
	}
	virtual const char* GetAttributeField( AttributeIndex index ) const {
		return m_attributeList.getField( index );
	}

    virtual void StartNewOperation( );

	virtual BOOL PrepareMountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareDismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL PrepareMountNextCrystal( const char position[],  char status_buffer[] );

	virtual BOOL MountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL DismountCrystal( const char position[],  char status_buffer[] );
	virtual BOOL MountNextCrystal( const char position[],  char status_buffer[] );

    //allow same port put back.
    //currently, we do NOT allow sorting if sample already on goniometer
	virtual BOOL PrepareMoveCrystal( const char argument[], char status_buffer[] );
	virtual BOOL MoveCrystal( const char argument[], char status_buffer[] );

	virtual BOOL PrepareWashCrystal( const char argument[], char status_buffer[] );
	virtual BOOL WashCrystal( const char argument[], char status_buffer[] );

    virtual BOOL Standby( const char argument[], char status_buffer[] );

	virtual BOOL Config( const char argument[],  char status_buffer[] );

	virtual BOOL Calibrate( const char argument[],  char status_buffer[] );

    virtual void SetAbortFlag( ) { m_FlagAbort = true; if (m_pSleepEvent) xos_event_set( m_pSleepEvent );}

    virtual BOOL RegisterEventListener( RobotEventListener& lisener );
    virtual void UnregisterEventListener( RobotEventListener& lisener );
    //also controlled by help function enable/disable event

    virtual void SetSleepEvent( xos_event_t* pEvent ) { m_pSleepEvent = pEvent; }

	static PerfectOrientation AngleToOrientation( float angle )
	{
		while (angle < 0.0f)
		{
			angle += 360.0f;
		}
		int dir_index = int( angle / 90.0 + 0.5);
		dir_index %= 4;
		switch (dir_index)
		{
		case 0:
			return DIRECTION_X_AXIS;
		default:
		case 1:
			return DIRECTION_Y_AXIS;
		case 2:
			return DIRECTION_MX_AXIS;
		case 3:
			return DIRECTION_MY_AXIS;
		}
	}
	static float OrientationToAngle( PerfectOrientation dir )
	{
		const float PI = 3.14159265359f;
		return dir * PI / 2.0f;
	}

    friend class SPEL_DIALOG_CLASS_NAME;
    friend class Dewar;
    friend class CCassette;
private:
    void UpdateRobotFlags( RobotStatus status );
    
    //as long as 1-to-many relation is valid between "reaon" and "need", we will automatically set "need"
	void SetRobotFlags( RobotStatus flags );

	void ClearRobotFlags( RobotStatus flags );

	//the desired ln2 level is used both in DHS and spel scripts ( calibration need it)
	int  SetDesiredLN2LevelInSPEL( bool high, char* status_buffer );
    void CopyDesiredLN2LevelFromSPEL( );
    void SetLN2Level( LN2Level );
    void CheckLN2Level( );

	RobotStatus GetRobotFlags( ) const { return m_pState->status; }

    void SetGonioSample( char cassette, short row, char column, bool update = true );
    void SetTongSample( char cassette, short row, char column, bool update = true );
    void SetPickerSample( char cassette, short row, char column, bool update = true );
    void SetPlacerSample( char cassette, short row, char column, bool update = true );

    void UpdateMounted( );

	void SetPowerHigh ( bool high );
	void setRobotSpeed( RobotSpeed speed );

	void SetCurrentPoint( LPoint point );

	void SetSampleState( CurrentSampleState state );

	LPoint GetCurrentPoint( void ) const;

	CurrentSampleState GetSampleState( void ) const;
    const char* GetSampleStateString( ) const;

	void SavePoints ( void );

	BOOL GetEstop ( void );

	void Reset ( void );

	//if return false, status_buffer will be filled
	bool SetGoniometerPoints ( float dx, float dy, float dz, float du, char* status_buffer );

	void ReadToolSet( const ToolSet, PointCoordinate& point );

	CString GetLastError ( void );

	long GetLastErrorNumber ( void );

	bool OpenGripper( void );

	bool CloseGripper( bool noCheck = false );

	void InitCassetteCoords ( const char );

	bool MoveToCoolPoint ( void );

	void MoveToPlacer ( );

	bool MoveToHome ( );
	bool StandbyAtCoolPoint( ); //instead of going home, go to LN2 dewar and open gripper

	bool GetMagnet ( void );

	void PutMagnet ( bool check_tolerance = false, bool collect_force = false );

	void MoveToPortViaStandby( char, short, char ); //from post standby

	void MoveFromPortToPost( )
	{
		MoveFromPortToStandby( );
		MoveFromCassetteToPost( );
	}
	void MoveFromPortToStandby( void );
	void MoveFromCassetteToPost ( void ); //to post standby

	void MoveToPortFromSecondaryStandby( char cassette, int row, char column );

	void MoveFromPortToSecondaryStandby( char cassette, int row, char column );

	void MoveToGoniometer ( void );

	void MoveFromGoniometerToPlacer( void );

	void MoveFromGoniometerToRestPoint( void ); //used both for go home and dismount beamline tool
	void MoveFromGoniometerToDewarSide( void );

	void MoveFromGoniometerToPicker( void ); //used by sample washing
	void MoveFromGoniometerToRescuePoint( void );

	void Detach( void );

	bool MoveToCheckGripperPos( float dx, float dy, float dz, float du );
	bool MoveFromP18ToP1( );

	bool CheckDumbbell ( void );
	bool MoveUpForSampleRescue( const char argument[], char status_buffer[] );

	//return port force if option is on or 0 if option is off
	PortForceStatus MoveIntoPort( float& portError );
	bool ConfirmBigForce( float portError );
	void UpdatePinLost( );
	CSamplePort::State PutSampleIntoPort( void );
	CSamplePort::State GetSampleFromPort( void );

	//it will go back to the original position after strip dumbbell by using current port
	bool StripDumbbell( void );

	bool GripSample( void );

	bool ReleaseSample( void );

	void SetMotorsOn( bool );

	BOOL GetMotorsOn( void );

	BOOL GetPause( void );

	void Cont( void );

	bool ReturnDumbbell ( void );

	void Abort ( bool flag_only = false );

	void ResetAbort ( );

	bool BetweenP1_Home ( const PointCoordinate& point ) const;
	
	bool InDewarArea ( const PointCoordinate& point ) const;

	bool InFrontArea ( const PointCoordinate& point ) const;

	bool Dance ( void );

	DumbbellState GetDumbbellState( void ) const;

	void SetDumbbellState ( DumbbellState );

    //function for force sensor
	bool ForceCalibrate ( void );

    float ReadForce( int forceName );
    void  ReadForces( float forces[6] );
	void  LogRawForce( int forceName );
	void  LogRawForces( );

    //void  ReadForces( float forces[] ); //no one needs this yet
    int NarrowMinMax( int forceIndex, float& minValue, float& maxValue);
    float AverageForce( int forceIndex, float minValue, float maxValue);
    void ReadRawForces( float rowForces[6] ); //wrap vendor VARIANT call

    void GenericMove( const PointCoordinate& position, bool withForceTrigger );
    void StepMove( const PointCoordinate& step, bool withForceTrigger );
    void SetupForceTrigger( int forceName, float threshold );

    void ForceBinaryCross( int forceName, const PointCoordinate& previousPosition, float previousForce, float threshold, int numSteps );
    bool ForceScan( int forceName, float threshold, const PointCoordinate& destinationPosition, int numSteps, bool fineTune );

    static void GetTouchParameters( int forceName, float& threshold, float& min, float& initStepSize );
    bool ForceTouch( int forceName, const PointCoordinate& destinationPosition, bool fineTune );

    static float HyperStepSize( const PointCoordinate& step );
    static float HyperDistance( const PointCoordinate& position1, const PointCoordinate& position2 );
    static bool  ForceExceedThreshold( int forceName, float currentForce, float threshold );

	void InitializeMMap ( void );

	void TwistRelease ( );

	//void CalculateCassetteArcXY ( float*, float*, const float, const float );

	void SetDerivedLPoint ( LPoint, LPoint, float, float, float, float, bool direct_x = false, bool direct_y = false, bool direct_z = false, bool direct_u = false);

	CCassette& GetCassette( const char cassette  );
	const CCassette& GetConstCassette( const char cassette  ) const;

    //added during implementation
    bool GenericPrepare( int cooling_seconds, char status_buffer[] );
    bool OKToMount( char cassette, short row, char column, char status_buffer[] );
    bool OKToDismount( char cassette, short row, char column, char status_buffer[] );
    bool OKToMountNext( char dism_cassette, short dism_row, char dism_column,
                        char m_cassette,    short m_row,    char m_column, char status_buffer[] );
    bool OKToMove( const char argument[], char status_buffer[] );
    bool OKToWash( char status_buffer[] );

    bool OKToClear( char status_buffer[] = NULL ) const;

    bool CassetteIsValid( char cassette ) const;
    bool PositionIsValid( char cassette, short row, char column ) const;
	bool PositionIsBeamlineTool( char cassette, short row, char column ) const;

	//return 1 if any need probe is set to 1
	bool ProcessProbeArgument( const char* argument, char* status_buffer );

    bool ProbeCassettes( char status_buffer[] );
    bool ProbeOneCassette( CCassette& theCassette, char status_buffer[] );
    bool TouchCassetteTop( const PointCoordinate& standby, float distance, char cassettName, float& top, char status_buffer[] );
	void ProbePorts( CCassette& theCassette );


    void RobotWait( UINT milliSeconds );
    void RobotDoEvent( UINT milliSeconds, HANDLE handle = NULL );

    bool PortPostShuttle( bool putSample, char cassette, short row, char column );

    void MoveTongHome( );

    bool GoniometerToPlacer( );
    bool GoniometerToPicker( ); //for washing

    bool PickerToGoniometer( );

    void TwistOffMagnet( );

	BOOL CFGStripperTakeMagnet( const char argument[], char status_buffer[] );
	BOOL CFGStripperRun( const char argument[], char status_buffer[] );
	BOOL CFGStripperGoHome( const char argument[], char status_buffer[] );

	BOOL CFGPortJamAction( const char argument[], char status_buffer[] );

	BOOL CFGResetAllowed( const char argument[], char status_buffer[] );
    BOOL CFGMoveToCheckPoint( const char argument[], char status_buffer[] );
    BOOL CFGOpenGripper( const char argument[], char status_buffer[] );
    BOOL CFGHeatGripper( const char argument[], char status_buffer[] );
    BOOL CFGCheckDumbbell( const char argument[], char status_buffer[] );
    BOOL CFGReturnDumbbell( const char argument[], char status_buffer[] );
    BOOL CFGProbe( const char argument[], char status_buffer[] );
    BOOL CFGCheckHeater( const char argument[], char status_buffer[] );
    BOOL CFGCheckGripper( const char argument[], char status_buffer[] );
    BOOL CFGCheckLid( const char argument[], char status_buffer[] );
    BOOL CFGLLOpenGripper( const char argument[], char status_buffer[] );
    BOOL CFGLLCloseGripper( const char argument[], char status_buffer[] );
    BOOL CFGLLOpenLid( const char argument[], char status_buffer[] );
    BOOL CFGLLCloseLid( const char argument[], char status_buffer[] );
    BOOL CFGHWOutputSwitch( const char argument[], char status_buffer[] );
	BOOL CFGCommand( const char argument[], char status_buffer[] );
	BOOL CFGStepUp( const char argument[], char status_buffer[] );

    BOOL CALPost(  const char argument[], char status_buffer[] );
    BOOL CALCassette(  const char argument[], char status_buffer[] );
    BOOL CALGoniometer(  const char argument[], char status_buffer[] );
    BOOL CALBeamLineTool(  const char argument[], char status_buffer[] );
	BOOL CALMountBeamLineTool(  const char argument[], char status_buffer[] );
	BOOL CALDismountBeamLineTool(  const char argument[], char status_buffer[] );
	BOOL CALMoveToGoniometer(  const char argument[], char status_buffer[] );
	BOOL CALMoveHome(  const char argument[], char status_buffer[] );
	BOOL CALSaveGoniometerPosition(  const char argument[], char status_buffer[] );
	BOOL CALPrepareGoniometer(  const char argument[], char status_buffer[] );
	BOOL CALCheckGoniometerReachable(  const char argument[], char status_buffer[] );

    BOOL CALRun( const char argument[], char status_buffer[] );
    void CALWrapper( const char functionName[], const char argument[], char status_buffer[] );

    bool ProcessMoveArgument( const char*& pRemainArgument,
                      char& source_cassette, char& source_column, short& source_row,
                      char& target_cassette, char& target_column, short& target_row );

	//only called when the lid is opened manually
	void LidOpenCallback( );

	//forbid
	Robot& operator= (const Robot&);

    //help
    void InitPoints( );
    void InitBasicPoints( );
    void InitMagnetPoints( );
    void InitCassettePoints( );
    void InitGoniometerPoints( );

	bool CheckToolSet( ToolSet ts );
    bool CheckPoint( LPoint p );
    bool CheckGripper( ) { return CloseGripper( ) && OpenGripper( ) && CloseGripper( ); }
	bool CheckHeater( );
	bool CheckLid( bool only_status_check );
	bool PassSelfTest( bool forced, char* status_buffer );

    void EnableEvent( ) { m_EventEnabled = true; }
    void DisableEvent( ) { m_EventEnabled = false; }
    bool InRecoverablePosition( );
    bool CloseToPoint( LPoint pt, float x, float y, float range = 5.0 ) const;
    bool CloseToPoint( LPoint pt, const PointCoordinate& point, float range = 5.0 ) const;
    bool SetupTemperaryToolSet( LPoint fromPointNum );

	void StartBackgroundTask( short taskNum, const char * pSPELFunctionName );
    void StopBackgroundTask( short taskNum );

    //new function for moving magnet from port to port directly.
    //it will be used in mount next and move crystal
    void MoveFromPortToPort( char fromCassette, char fromColumn, short fromRow, char toCassette, char toColumn, short toRow );

    void MoveFromPortToPortInSameCassette( char cassette, char fromColumn, short fromRow, char toColumn, short toRow );

    //it will move the tong back to home and heat it.
    //It only starts when the tong is at P3, P23.
    //It will go back to starting position with gripper open at the end.
    //in Abort, it may end up at P0, P1, P2, P3, P23
    bool ReHeatTongAndCheckGripper( );

    //create text message from memory map file
    void UpdateState( );

    void UpdateCassetteStatus( );
    void UpdateSampleStatus( const char* text, bool add_current_sample = false );
	void updateForces( );

    void CollectStatusInfo( char* status_buffer, const char* default_text );
    void AppendOldMessage( char* status_buffer );

    void NormalErrorHandle( CException *e, char* status_buffer );

    //used internally in MountCrystal, DismountCrystal and MountNextCrystal
    bool Mounting( char cassette, short row, char column );
    bool Dismounting( char cassette, short row, char column );
    bool Washing( int times );

	//used by Washing and Mouting and Mount Next
	void doWash( int times ); //end up in P4

    void ClearAll( );
	void ClearMounted( );
	void ResetCassetteStatus( bool forced_clear = false );

	bool ClearLowLevelError( char* status_buffer );
    bool BringRobotUp( char* status_buffer );

	//listen to input port event and keep timestamps for special event like
	//LN2 is filling           (abort and prevent calibration)
	//LN2 level low (alarm)	   (disable robot)
	void IOBitMonitor( long EventNumber, const char* pMsg );
	void IOBitMonitor( long EventNumber, unsigned long value );
	bool IsAutoFilling( char* status_buffer );
	void SelfPollIOBit( );

	//return 0 if failed to get I/O value
	bool SelfPollIOBit( volatile unsigned long& input, volatile unsigned long& output );

    //replace SPELCOM WaitSW and TW if the time to wait
    //is way more than 1 second and you want to make sure
    //the IO bit changes are updated.
    bool WaitSw( short BitNumber, BOOL Condition, int TimeInterval );

	void CheckModel( );

	bool GonioReachable( char* status_buffer );

	bool ShutDownSystem( char* status_buffer, bool restart = true );

	bool GoThroughStripper( char* status_buffer, bool retakeMagnet = true );

	bool getAttributeFieldBool( AttributeIndex index ) {
		int result = 0;
		sscanf( m_attributeList.getField( index ), "%d", &result );
		return result != 0;
	}
	int getAttributeFieldInt( AttributeIndex index ) {
		int result = 0;
		sscanf( m_attributeList.getField( index ), "%d", &result );
		return result;
	}

	void adjustForHamptonPinIfFlagged( void );
	bool retryWithPositionAdjust( void );

    void GetCurrentPosition( PointCoordinate& point  ) const;
	void assignPoint( LPoint pointNumber, const PointCoordinate& point );
	void retrievePoint( LPoint pointNumber, PointCoordinate& point ) const;

private:
	enum MountNextTask
	{
		MOUNT_NEXT_NONE = 0,
		MOUNT_NEXT_MOUNT = 1,
		MOUNT_NEXT_DISMOUNT = 2,
		MOUNT_NEXT_FULL = 3
	};

    xos_event_t* m_pSleepEvent;
	xos_event_t m_EvtSPELResetOK;

	//only append if you need to add new item
	struct RobotEpsonState
	{
		volatile RobotStatus		status;
		volatile CurrentSampleState	sampleState;        //will be phased out gradually
		volatile DumbbellState		dumbbellState;
		volatile LPoint				currentPoint;
        volatile LN2Level           currentLN2Level;
        volatile char               mounted_cassette;
        volatile short              mounted_row;
        volatile char               mounted_column;

        volatile unsigned long      num_pin_mounted;	//user cannot reset
        volatile unsigned long      num_pin_lost;		//user cannot reset
		volatile unsigned long      num_pin_mounted_before_lost;	//"clear/reset" will clear it

		//user/staff see:
        volatile unsigned long      num_pin_mounted_short_trip;			//user can reset (displayed in status)
		volatile unsigned long      num_pin_lost_short_trip;			//"clear/reset" will clear it (displayed in status)

		//internal safety check
		//move to cassette will set current cassette and row,
		//move to port will set column
		volatile char	currentCassette;
		volatile int	currentRow;
		volatile char	currentColumn;

		//stripper counters
		volatile unsigned long		num_pin_stripped;
		volatile unsigned long		num_pin_stripped_short_trip;  //authorized staff can clear it

		//pre-fetch
        volatile char               tongCassette;
        volatile short              tongRow;
        volatile char               tongColumn;
        volatile char               pickerCassette;
        volatile short              pickerRow;
        volatile char               pickerColumn;
        volatile char               placerCassette;
        volatile short              placerRow;
        volatile char               placerColumn;

		//puck
		volatile unsigned long		num_puck_pin_mounted;
        volatile unsigned long      num_puck_pin_mounted_short_trip;//staff can reset it

		//moveCrystal
		volatile unsigned long      num_pin_moved;
		volatile unsigned long      num_puck_pin_moved; //origin or destination is puck
	};

	struct CosSinForAngle {
		float cosValue;
		float sinValue;
	};

	//for Epson COM: these pointers will be initialize in Initialize( ) by robot thread
	SPEL_COM_CLASS_NAME*  m_pSPELCOM;
    SPEL_DIALOG_CLASS_NAME*   m_pCSpel;      //to receive event of EPson COM

	//dummy just to simplify writing.
	COleVariant vNull;

	//for tool set calibration: the results are stored in win registry by other programs.
	CRegistry m_Registry;

	//for memory map of robot state: permanent storage between runs, reboots.
	MMapFile					m_MMapFile; 
	//volatile RobotEpsonState*	m_pState;
	RobotEpsonState*	m_pState;
	//in case memory map failed.
	//RobotEpsonState	volatile	m_LocalStateOnlyUSedWhenMMapFailed;
	RobotEpsonState	m_LocalStateOnlyUSedWhenMMapFailed;

    //for event listener Q: we only support 1 listener now
    RobotEventListener* volatile m_pEventListener;

    bool volatile                m_EventEnabled;
    bool volatile                m_FlagAbort;
    bool volatile                m_NeedBringUp;
	bool volatile				 m_NeedTurnOffHeater;
	volatile bool				 m_InAbort;
	volatile bool				 m_InEventProcess;
	volatile bool				 m_SPELAbortCalled;
	volatile bool				 m_NeedAbort;

	//objects
	CCassette m_LeftCassette, m_MiddleCassette, m_RightCassette;
	Dewar m_Dewar;

    int     m_OperationState;

    time_t  m_TimeInLN2;
    time_t  m_TimeOutLN2;

    char    m_ErrorMessageForOldFunction[MAX_LENGTH_STATUS_BUFFER + 1];

    bool    m_Warning; //only give warning, robot is OK to continue next operation
    bool    m_CheckMagnet;
	unsigned int m_MountNextTask;

	float	m_ArmLength;
	float	m_Arm1Length;
	float	m_Arm2Length;
	float   m_MinR;
	float   m_Arm1AngleLimit;

	float	m_RectangleX0;
	float	m_RectangleX1;
	float	m_RectangleY0;
	float	m_RectangleY1;

    //readforce
    float m_RawForces[6][FORCE_READ_TIMES];
	float m_ThresholdMin[6];
	float m_ThresholdMax[6];
	int	  m_NumValidSample[6];

    bool  m_OnlyAlongAxis; //if true, tong direction move will be only along one Axis X or Y or Z or U
	//followins 2 used in reading all forces in one function
	SAFEARRAY* m_pForcesSafeVector;
	VARIANT    m_ForcesVariant; 

	//IOBitMonitor
	volatile bool   m_CheckAutoFilling;	//if set to false, the robot will ignore the filling

	time_t			m_TSLN2Filling;		//timestamp for latest LN2 filling bit on
	time_t			m_TSLN2Alarm;		//timestamp for earliest contineous alarm bit on
	time_t			m_TSBackgroundTask;	//timestamp for IOBitMonitor called by background task in Robot controller
	unsigned long volatile	m_LastIOInputBitMap;
	unsigned long volatile	m_LastIOOutputBitMap;

	volatile LN2Level		m_desiredLN2Level;

	PointCoordinate::ArmOrientation		m_armOrientation;

	PerfectOrientation	m_dumbbellOrientation;
	PerfectOrientation	m_downstreamOrientation;
	PerfectOrientation	m_goniometerOrientation;
	CosSinForAngle      m_dumbbellDirScale;
	CosSinForAngle      m_downstreamDirScale;
	CosSinForAngle      m_goniometerDirScale;

	bool				m_stripperInstalled;
	char				m_strCoolingPoint[64];   //if stripper in installed, cooling point will be lower than P3
										  // the contents of this string should be something like "P* :Z(-200)"

	float			m_TQScale;

	TclList			m_attributeList;
	bool			m_inCmdProbing;

	time_t			m_tsAbort;

	unsigned long volatile m_numCycleToWash;

	volatile bool	m_hamptonPin;

	//must be filled for any more to cassette port
	char            m_cmdBackToStandby[1024];

    bool            m_tongConflict;

	RobotSpeedSetup m_speed[NUM_SPEED];

	static       float N2_LEVEL;                //for jump limit no out of LN2
	static const float MAGNET_HEAD_RADIUS;
	static const float TONG_CAVITY_RADIUS;
	static const float SAFETY_Z_BUFFER_FOR_MOVING_TO_GONIOMETER;
	static const float SAFETY_X_BUFFER_FOR_MOVING_TO_GONIOMETER;
	static const float GONIOMETER_MOUNT_STANDBY_DISTANCE;
	static const float GONIOMETER_DISMOUNT_SIDEMOVE_DISTANCE;

	//for right hand tong used on left hand goniometer
	//we will need to move around to avoid knock off sample
	static const float CONFLICT_GONIOMETER_BACKOFF_DISTANCE;
	static const float CONFLICT_GONIOMETER_SIDEMOVE_DISTANCE;

    //for magnet post position check
    static const float THRESHOLD_ZFORCE;
    static const float THRESHOLD_XTORQUE;
    static const float THRESHOLD_YTORQUE;
    static const float THRESHOLD_ZTORQUE;
    //for port check(empty or not)
    static const float THRESHOLD_PORTCHECK;	//less than this value will be considered empty port
    static const float THRESHOLD_PORTJAM;	//large than this value will be considered pin damaged.
    //for magnet check (lost or not)
    static const float THRESHOLD_MAGNETCHECK;
	//for picker check (sample pulled out or not)
    static const float THRESHOLD_PICKERCHECK;

    //for manual put tong on goniometer
    static const float THRESHOLD_MANUAL_GONIO_ZFORCE;
    static const float THRESHOLD_MANUAL_GONIO_XTORQUE;
    static const float THRESHOLD_MANUAL_GONIO_YTORQUE;
    static const float THRESHOLD_MANUAL_GONIO_ZTORQUE;

	static const float SHRINK_ADJUST_FOR_TONG; //just an estimated number
	//used when manually set goniometer position in room temperature

	//strip dumbbell parameters
	static const float STRIP_PLACER_SIDEWAY;
	static const float STRIP_PLACER_STICKOUT;
	static const float STRIP_PLACER_DISTANCE;

	//washing
	static const float WASH_DISTANCE_U;
	static const float WASH_DISTANCE_Z;

	//outside scripts depend on this message, do not change.
	static const char* STATUS_OUT_OF_RANGE_Z;
	static const char* STATUS_OUT_OF_RANGE_XY;
};

typedef struct
{
    const char*         pSubCommand;
    size_t              CmdLength;
    BOOL (RobotEpson::*FunctionToCall)( const char[], char[] );
} SubCommandMap;

class InEventHolder {
public:
	InEventHolder( ): m_pValue(NULL) {};
	InEventHolder( volatile bool *pValue ): m_pValue(pValue) {
		*m_pValue = true;
	}

	~InEventHolder( ) {
		if (m_pValue)
		{
			*m_pValue = false;
		}
	}
private:
	volatile bool* m_pValue;
};
