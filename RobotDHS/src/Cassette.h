#pragma once

#include "RobotPoint.h"

//we assume that all cassette are vertical.

//assume the angle between each column is equal and = 360/(number of columns)

//For each port, the robot will need 2 position.
//One is called "OUT" position, which the place that robot has to go to before
//and after pick or place the sample.
//The other is called "IN" position, which the place that robot has to go to put
//the sample in the post.
//So, in picking: the picker(strong magnet field) will go to "OUT-IN-OUT"
// in placing, the placer will go "OUT-IN-OUT"

//You can calculate the radius for IN postion from sample pin and cassette port specifications.
//You can calculate the Radius for OUT position from sample pin, the dumbbell, and cassette specifications.
//The values here are copied from original codes.  They basically are from experiment

//#define TEST_PORT_PROBE

//need to access hardware to prepare data for port
class RobotEpson;

class CSamplePort
{
public:
	CSamplePort( ): m_State(PORT_UNKNOWN), m_FutureState(PORT_UNKNOWN) { }
	~CSamplePort( ) { }

	enum State
	{
		PORT_UNKNOWN,
		PORT_EMPTY,
		PORT_MOUNTED,
		PORT_SAMPLE_IN,
		PORT_JAM,
		PORT_BAD, //bad by reason other than jam
		PORT_NOT_EXIST,
	};
	
	State GetState( ) const { return m_State; }
	void  SetState( State state, bool forced ) {
		bool ok_to_change = false;
		if (forced || state != PORT_UNKNOWN)
		{
			ok_to_change = true;
		}
		else
		{
			//want set to unknown and not forced
			switch (m_State)
			{
			case PORT_UNKNOWN:
			case PORT_EMPTY:
			case PORT_MOUNTED:
			case PORT_SAMPLE_IN:
			case PORT_NOT_EXIST:
				ok_to_change = true;
				break;

			case PORT_JAM:
			case PORT_BAD:
				; //skip change: these are sticky states.
			}
		}
		if (ok_to_change)
		{
			m_State = state;
			m_FutureState = state;
		}
	}

    State GetFutureState( ) const { return m_FutureState; }
    void  SetFutureState( State state ) { m_FutureState = state; }
	void  ResetFutureState( ) { m_FutureState = m_State; }
	
private:
    //we need 2 sets of states.  One for real state
    //The other for checking state in moving samples.
    //We support multiple movings in one operation.  It checks the list
    //as if the moving is going on.
	State m_State;
    State m_FutureState;
};

//because many properties we need to access before we know the cassette type,
//we cannot store 2D info into 1D array any more.
class CCassette
{
public:
	enum constants
	{
		NUM_COLUMN	= 12,
		NUM_ROW		= 8,
		NUM_PUCK = 4,
		NUM_PUCK_PIN = 16,
		//summary
		MAX_COLUMN = 12, // max of NUM_COLUMN and NUM_PUCK
		MAX_ROW = 16,    // max of NUM_ROW    and NUM_PUCK_PIN

		/////////////////// NNNNNNNNNNNNNNNEEEEEEEEEEEEEEEEEEEDDDDDDDD
		MAX_NUM_PORT = (NUM_COLUMN * NUM_ROW),
		NUM_STRING_STATUS_LENGTH = MAX_NUM_PORT * 2 + 1,
		TOP_POSITION_WIDTH = 6,
		FORCE_WIDTH = 4,
		NUM_STRING_FORCE_LENGTH = MAX_NUM_PORT * (FORCE_WIDTH + 1) + TOP_POSITION_WIDTH,
		NUM_STRING_PROBE_LENGTH = MAX_NUM_PORT * 2 + 1,
	};

	enum Status
	{
		CASSETTE_UNKOWN,
		CASSETTE_ABSENT,
		CASSETTE_PRESENT,
		CASSETTE_PROBLEM,
		CASSETTE_NOT_EXIST //once in, you cannot get out
	};

	enum Type
	{
		CASSETTE_TYPE_NORMAL = 1,
		CASSETTE_TYPE_CALIBRATION,
		CASSETTE_TYPE_SUPERPUCK,
	};

	CCassette( char name = 'u' );
	~CCassette( ) { }

	void Initialize( RobotEpson *pRobotEpson );


    char GetName( ) const { return m_Name; }

	//secondary standby is used in moving crystals to take short cut between middle cassette and other casette
	void SetUpDirection( float perfectColumnAAngle, float standbyU, float secondaryStandbyU );
	//x, y, z is the bottom center of cassette.
	//All x, y, z, and angleOffset should come from cassette calibration
	void SetUpCoordinates( const PointCoordinate & point );
    void SetupTilt( const PointCoordinate & topPoint, const PointCoordinate & bottomPoint );

    //for cassette itself
    Status GetStatus( ) const { return m_Status; }
	//float  GetCenterX( ) const { return m_CenterX; }
	//float  GetCenterY( ) const { return m_CenterY; }
	//float  GetBottomZ( ) const { return m_BottomZ; }
	//float  GetAngleOffset( ) const { return m_AngleOffset; }
    //short  GetOrientation( ) const { return m_Orientation; }

	//this will set cassette type
	bool   CheckHeight( const float* height, int numHeight, float* delta );

	Type   GetType( ) const { return m_Type; }

    const char* GetStringStatus( ) const { return m_StringStatus; }

	//for load status from string
	//use with extreme care.
	void loadStatusFromString( const char * stringStatus );
	void restoreStatusFromFile( );
    
    void   SetStatus( Status status, bool forced_clear );

    //for ports
    bool PositionIsValid( short row, char column ) const;
	void GetSecondaryStandbyPoint( int row, char column, PointCoordinate& point ) const;
    void GetProbePoints( PointCoordinate points[4], float& distance ) const;

	void GetPortPoint( int row, char column, PointCoordinate& point, PointCoordinate* pPortProbeStandByPoint = NULL ) const;
	float GetDetachDistance( ) const;

	//////////////////new version setup commands////////////////////
	// P50 cassette standby
	// P52 port ready position
	// other points you cannot count on.
	//
	//make sure command buffer are long enough
	void GetCommandForPortFromStandby( int row, char column, char* toPortCmd, char* toStandbyCmd ) const;
	void GetCommandForPortFromPort( int from_row, char from_column, int to_row, char to_column, char* toPortCmd, char* toStandbyCmd ) const;
	void GetCommandForPortFromSecondary( int row, char column, char* toPortCmd, char* toStandbyCmd ) const;
	void GetCommandForSecondaryFromPort( int row, char column, char* toSecondaryCmd, char* toStandyCmd = NULL ) const;

	CSamplePort::State GetPortState( int row, char column ) const;
    void               SetPortState( int row, char column, CSamplePort::State state );

	void               ClearMounted( ); //this will change mounted to empty

	//help functions: only allow PORT_UNKNOWN, PORT_JAM, PORT_BAD, and PORT_NOT_EXIST,
	void               SetAllPortState( CSamplePort::State state );
	void               SetColumnPortState(  char column, CSamplePort::State state );
	//this one is more convenient for GUI:
	//When cassette type is unknown, internal type is assumed "normal cassette",
	//but the user can select superpuck view.  In this case, port "lB1" from the user's view
	//is not mapped to the internal lB1 port.
	void               SetIndexPortState( int start_index, int length, CSamplePort::State state );

	CSamplePort::State GetPortFutureState( int row, char column ) const;
    void               SetPortFutureState( int row, char column, CSamplePort::State state );
    void               ResetPortFutureState( );

	void setPortForce( int row, char column, float force );
	const char* getStringForce( ) const { return m_stringForce; }
	void clearForce( );


    //probing
#ifdef TEST_PORT_PROBE
    bool   NeedProbe( ) const { return true; }
    bool   AnyPortNeedProbe( ) const { return true; }
    bool   PortNeedProbe( short row, char column ) const { return true; };
#else
    bool   NeedProbe( ) const { return m_NeedProbe; }
    bool   AnyPortNeedProbe( ) const { return m_AnyPortNeedProbe; }
    bool   PortNeedProbe( short row, char column ) const
	{
		int index;
		int rowIndex;
		int columnIndex;
		if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
		{
			return false;
		}
		return m_PortNeedProbe[columnIndex][rowIndex];
	};
#endif
    void   SetNeedProbe( bool needProbe )
	{
		if (m_Status == CASSETTE_NOT_EXIST)
		{
			m_NeedProbe = false;
			return;
		}
		m_NeedProbe = needProbe;
	}
    void   SetPortNeedProbe( short row, char column, bool needProbe = true )
	{ 
		int index;
		int rowIndex;
		int columnIndex;
		if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
		{
			return;
		}
		m_PortNeedProbe[columnIndex][rowIndex] = needProbe;
		if (needProbe)
		{
			m_AnyPortNeedProbe = true;
		}
	}
    void   ClearAllPortNeedProbe( ) {
		memset( m_PortNeedProbe, 0, sizeof(m_PortNeedProbe) );
		m_AnyPortNeedProbe = false;
		m_NeedConfigProbe = false;
	}

	//we need to save probe string because it is set before we know the cassette type, we will process it once we know the cassette type
	void   ProcessProbeString( );
	bool   ConfigNeedProbe( const char* pProbeString, char* status_buffer, bool& anySet );

    //this will affect Z for each row and cassette height, radius
    static void   SetInLN2( bool InLN2 );

	//static float GetRadius( ) { return m_Radius * m_ShrinkFactor; }

	//reduce angle to  (-180, +180]
	static float NarrowAngle( float angle )
	{
		while (angle <= -180.0f)
		{
			angle += 360.0f;
		}
		while (angle > 180.0f)
		{
			angle -= 360.0f;
		}
		return angle;
	}

private:
	//moved here from public because not used yet.
	void GetStandbyPoint( int row, char column, PointCoordinate& point ) const;
	//it will always take shorter pass from standby position (-180, +180]
	void GetArcPointsFromStandby( int row, char column, PointCoordinate& pass, PointCoordinate& dest ) const;
	//because limitation of U and try to avoid worst case, you may go around almost a circle to get next column in some case.
	void GetArcPointsFromPort( int from_row, char from_column, int to_row, char to_column, PointCoordinate& pass, PointCoordinate& dest ) const;
	void GetArcPointsToSecondaryStandby( int from_row, char from_column, PointCoordinate& pass, PointCoordinate& dest ) const;
	
	//for puck
	void GetArcPointsForU( float DZ, float r, float from_u, float to_u, PointCoordinate& pass, PointCoordinate& dest ) const;

	inline float  GetTop( ) const { return m_Height * m_ShrinkFactor + m_BottomZ; }
    inline float  GetCalibrationTop( ) const { return m_CalibrationHeight * m_ShrinkFactor + m_BottomZ; }

	//adjust u (++360 or --360) so it will match arc from standby point
	float AdjustU( float u ) const
	{
		float diff_u = NarrowAngle( u - m_UForNormalStandby );
		u = m_UForNormalStandby + diff_u;
		return u;
	}

	void SetType( Type type, bool forced_clear );
	void InternalSetPortState( int index, int rowIndex, int columnIndex, CSamplePort::State state );

	void SyncStringStatus( );
    void UpdateStringCassetteField( );
    void UpdateStringPortField( int index, int rowIndex, int columnIndex );

	void syncStringForce( );
	void updateStringForceCassette( );
	void updateStringForcePort( int index, int rowIndex, int columnIndex, bool honorStatus = false );

	void saveStatusToFile( );

    bool GetIndex( int row, char column, int& index, int* rowIndex = NULL, int* colIndex = NULL ) const;
	bool GetRowColumnIndex( int index, int& rowIndex, int& columnIndex ) const;

	//from the center of the bottom
	//void perfectPortOffset( int rowIndex, int columnIndex, float radius, float& dx, float& dy, float& dz, float& u ) const;
	void perfectPuckOffset( int rowIndex, int columnIndex, float distance, float& dx, float& dy, float& dz, float& u ) const;

	void tiltAdjust( float dx, float dy, float dz, float& new_dx, float& new_dy, float& new_dz ) const;

	float GetPerfectDZ( int rowIndex, int columnIndex ) const;

	void GetCirclePointForU( float u, float radius, float perfectDZ, PointCoordinate& point ) const;
	void GetPuckPoint( int rowIndex, int columnIndex, float distance, PointCoordinate& point, float* pPerfectDZ = NULL ) const;

    bool positionIsValidForNormalCassette( short row, char column ) const;
    bool positionIsValidForCalibrationCassette( short row, char column ) const;
    bool positionIsValidForSuperPuck( short row, char column ) const;

    RobotEpson*  m_pRobotEpson;

    char   m_Name;
	Status m_Status;
	bool m_CoordiatesReady;
    bool m_NeedProbe;
    bool m_AnyPortNeedProbe;
    bool m_PortNeedProbe[MAX_COLUMN][MAX_ROW];
	char m_StringProbe[NUM_STRING_PROBE_LENGTH + 1 + 16]; //16 is extra
	bool m_NeedConfigProbe;

	Type m_Type;
	Type m_previousDetectedType;
    CSamplePort m_Ports[MAX_COLUMN][MAX_ROW];

    char m_StringStatus[NUM_STRING_STATUS_LENGTH + 1 + 16]; //16 is extra for safety

	//save all forces of probing
	float m_topPosition;
	float m_forces[MAX_COLUMN][MAX_ROW];
	// force first will be height of cassette -213.4, then forces for ports -8.5 -12
	char  m_stringForce[NUM_STRING_FORCE_LENGTH + 1 + 16];


    //these from cassette calibration
	//data type float here is because the robot system only return float, not double
	float m_CenterX;	//millimeter
	float m_CenterY;
	float m_BottomZ;
	float m_AngleOffset;	//degree
    PointCoordinate::ArmOrientation   m_Orientation;    //arm orientation

    //directly from calibration
    float m_CALTopX;
    float m_CALTopY;
    float m_CALTopZ;
    float m_CALBottomX;
    float m_CALBottomY;
    float m_CALBottomZ;

	float m_tiltDX;
	float m_tiltDY;

	float m_AngleOfFirstColumn;	//angle of first column related to the cassette. this not shrink.
	float m_UForNormalStandby;
	float m_UForPuckStandby;
	float m_UForSecondaryStandby;

	//class wide
    //from experiment
	static const float m_PinDeepInCassette;
	static const float m_PinDeepInPuck;

	//puck is flat that robot cannot go that deep without ithe cavity hitting the wall
	static const float m_OverPressDistanceForCassette;
	static const float m_OverPressDistanceForPuck;
	static const float m_PortReadyDistance;

	static const float m_ProbeStandbyDistance;

	static const float m_InDistanceForCassette;
	static const float m_InDistanceForPuck;	//for puck

    //from room temperature specification
    static const float m_Radius;
	static const float m_Height;
	static const float m_CalibrationHeight;
	static const float m_CalibrationEdgeHeight;
	static const float m_SuperPuckHeight;
	static const float m_HeightOfRow;
	static const float m_ZOfFirstRow;
    static const float m_TiltTolerance;
	static const float m_HeightTolerance;
	//in Liquid N2, they shrink
	static float m_ShrinkFactor;

	//for super puck adaptor
	static const float m_SP_Alpha[NUM_PUCK];
	static const float m_SP_R[NUM_PUCK];
	static const float m_SP_T[NUM_PUCK];
	static const float m_SP_Z[NUM_PUCK];
	static const float m_SP_Angle[NUM_PUCK];
	static const float m_SP_1_5_Radius;
	static const float m_SP_6_16_Radius;
};
