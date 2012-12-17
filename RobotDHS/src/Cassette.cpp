//avoid compile error for logging in c++
//#define bool bool
#include "StdAfx.h"
#include "dewar.h"
#include "RobotEpsonSymbal.h"
#include "RobotEpson.h"
#include "xos.h"
#include "log_quick.h"
#include <math.h>
#include "cassette.h"

//from specification
const float CCassette::m_Radius = 32.0f;
const float CCassette::m_Height = 130.0f;
const float CCassette::m_CalibrationHeight = 135.0f;
const float CCassette::m_CalibrationEdgeHeight = 8.5f;
const float CCassette::m_HeightOfRow = -15.0f; //mm: first row is the highest
const float CCassette::m_ZOfFirstRow = 117.0f; //mm

const float CCassette::m_SuperPuckHeight = 137.0f;
const float CCassette::m_SP_Alpha[NUM_PUCK] = { 45.0f, 45.0f, -45.0f, -45.0f };
const float CCassette::m_SP_R[NUM_PUCK] = { 32.5f, 32.5f, 32.5f, 32.5f };
const float CCassette::m_SP_T[NUM_PUCK] = { 29.0f, 29.0f, -29.0f, -29.0f };
const float CCassette::m_SP_Z[NUM_PUCK] = { 102.5f, 34.5f, 102.5f, 34.5f };
const float CCassette::m_SP_Angle[NUM_PUCK] = { 0.0f, 0.0f, 180.0f, 180.0f };
const float CCassette::m_SP_1_5_Radius = 12.12f;
const float CCassette::m_SP_6_16_Radius = 26.31f;


//from measurement and we will ignore shrink factor for these short distance.
const float CCassette::m_PinDeepInCassette = 3.2f;
const float CCassette::m_PinDeepInPuck = 2.5f;

//from experiments
const float CCassette::m_OverPressDistanceForCassette = 1.0f;
//puck is flat that robot cannot go that deep without ithe cavity hitting the wall
const float CCassette::m_OverPressDistanceForPuck = 0.8f;
const float CCassette::m_ProbeStandbyDistance = 5.0f;
const float CCassette::m_PortReadyDistance = 26.0f;;

float CCassette::m_ShrinkFactor = 1.0f;

//derived variables
const float CCassette::m_InDistanceForCassette = m_PinDeepInCassette + m_OverPressDistanceForCassette;
const float CCassette::m_InDistanceForPuck    =  m_PinDeepInPuck     + m_OverPressDistanceForPuck;

const float CCassette::m_TiltTolerance = 1.0f; //degree
const float CCassette::m_HeightTolerance = 0.4f; //mm


const float DEGREE_TO_RADIAN = 0.01745329251994f;

CCassette::CCassette( char name ):
m_pRobotEpson(NULL),
m_Status(CASSETTE_UNKOWN),
m_CoordiatesReady(false),
m_NeedProbe(false),
m_AnyPortNeedProbe(false),
m_NeedConfigProbe(false),
m_Type(CASSETTE_TYPE_NORMAL),
m_previousDetectedType(CASSETTE_TYPE_NORMAL),
m_CenterX(0),
m_CenterY(0),
m_BottomZ(0),
m_AngleOffset(0),
m_Orientation(PointCoordinate::ARM_ORIENTATION_RIGHTY),
m_CALTopX(0),
m_CALTopY(0),
m_CALTopZ(0),
m_CALBottomX(0),
m_CALBottomY(0),
m_CALBottomZ(0),
m_tiltDX(0),
m_tiltDY(0),
m_Name( name ),
m_topPosition(0),
m_AngleOfFirstColumn(-180.0f),
m_UForNormalStandby(180.0f),
m_UForPuckStandby(180.0f),
m_UForSecondaryStandby(270.0f)
{
    memset( m_PortNeedProbe, 0, sizeof(m_PortNeedProbe) );
	memset( m_forces, 0, sizeof(m_forces) );
	memset( m_StringProbe, 0, sizeof(m_StringProbe) );
    SyncStringStatus( );
	syncStringForce( );
}

void CCassette::Initialize( RobotEpson *pRobotEpson )
{
    m_pRobotEpson = pRobotEpson;
}


//first degree adjustment
void CCassette::tiltAdjust( float dx, float dy, float dz, float& new_dx, float& new_dy, float& new_dz ) const
{
	new_dx = dx;
	new_dy = dy;
	new_dz = dz;

	if (m_tiltDX == 0 && m_tiltDY == 0) return;

	new_dx += dz * m_tiltDX;
	new_dy += dz * m_tiltDY;
	new_dz += -(dy * m_tiltDY + dx * m_tiltDX);
}

bool CCassette::GetIndex( int row, char column, int& index, int* pRowIndex, int* pColumnIndex ) const
{
	int total_column = 0;
	int total_row = 0;

	int colIndex = 0;
	int rowIndex = 0;

	switch (m_Type)
	{
	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		total_column = NUM_COLUMN;
		total_row = NUM_ROW;
		break;

	case CASSETTE_TYPE_SUPERPUCK:
		total_column = NUM_PUCK;
		total_row = NUM_PUCK_PIN;
		break;

	default:
		return false;
	}

	if (column >= 'a' && column <= ('a' + MAX_COLUMN - 1))
	{
		colIndex = column - 'a';
	}
	else if (column >= 'A' && column <= ('A' + MAX_COLUMN - 1))
	{
		colIndex = column - 'A';
	}
	else
	{
		LOG_WARNING( "CCassette::CCassette::GetIndex called with bad column input" );
		return false;
	}

    rowIndex = row - 1;
    if (rowIndex < 0 || rowIndex >= MAX_ROW)
    {
        LOG_WARNING2( "bad row: %d, should be [1-%d]", row, total_row );
		return false;
    }

	index = colIndex * total_row + rowIndex;
	if (pRowIndex)
	{
		*pRowIndex = rowIndex;
	}
	if (pColumnIndex)
	{
		*pColumnIndex = colIndex;
	}
    return true;
}

void CCassette::SetUpDirection( float perfectColumnAAngle, float standbyU, float secondaryStandbyU )
{
	m_AngleOfFirstColumn = perfectColumnAAngle;
	m_UForNormalStandby = standbyU;
	m_UForSecondaryStandby = secondaryStandbyU;
	m_UForPuckStandby = (m_UForNormalStandby + m_UForSecondaryStandby) / 2.0f;
}

CSamplePort::State CCassette::GetPortState( int row, char column ) const
{
	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
		return CSamplePort::PORT_NOT_EXIST;
    }
	return m_Ports[columnIndex][rowIndex].GetState( );
}

void CCassette::InternalSetPortState( int index, int rowIndex, int columnIndex, CSamplePort::State state )
{
	m_Ports[columnIndex][rowIndex].SetState( state, true );
    UpdateStringPortField( index, rowIndex, columnIndex );
	updateStringForcePort( index, rowIndex, columnIndex, true );

    if (state != CSamplePort::PORT_UNKNOWN)
    {
        m_PortNeedProbe[columnIndex][rowIndex] = false;
    }
}


void CCassette::SetPortState( int row, char column, CSamplePort::State state )
{
	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

	if (m_Status == CASSETTE_NOT_EXIST) return;

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
		LOG_WARNING2( "setPortState bad input: row=%d col=%c", row, column );
        return;
    }

	//special case: PORT_MOUNTED only set when the port is empty
	if (state != CSamplePort::PORT_MOUNTED || m_Ports[columnIndex][rowIndex].GetState( ) == CSamplePort::PORT_EMPTY)
	{
		InternalSetPortState( index, rowIndex, columnIndex, state );
	}
}

void CCassette::ClearMounted( )
{
	int num_cleared = 0;
	for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
	{
		for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
		{
			if (m_Ports[columnIndex][rowIndex].GetState( ) == CSamplePort::PORT_MOUNTED)
			{
				m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_EMPTY, true );
				++num_cleared;
			}
		}
	}
	if (num_cleared)
	{
		SyncStringStatus( );
	}
}

void CCassette::SetAllPortState( CSamplePort::State state )
{
	if (m_Status == CASSETTE_NOT_EXIST) return;

	//check input
	switch (state)
	{
	case CSamplePort::PORT_MOUNTED:
	case CSamplePort::PORT_EMPTY:
	case CSamplePort::PORT_SAMPLE_IN:
		LOG_WARNING( "SetAllPortState does not accept normal port state" );
		return;

	case CSamplePort::PORT_UNKNOWN:
		this->SetStatus( CASSETTE_UNKOWN, true );
		return;

	case CSamplePort::PORT_BAD:
		this->SetStatus( CASSETTE_PROBLEM, true );
		return;

	case CSamplePort::PORT_NOT_EXIST:
		this->SetStatus( CASSETTE_ABSENT, true );
		return;

	case CSamplePort::PORT_JAM:
	default:
		break;
	}

	for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
	{
		for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
		{
			m_Ports[columnIndex][rowIndex].SetState( state, true );
	        m_PortNeedProbe[columnIndex][rowIndex] = false;
		}
	}

	SyncStringStatus( );
}

void CCassette::SetColumnPortState( char column, CSamplePort::State state )
{
	if (m_Status == CASSETTE_NOT_EXIST) return;

	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

    if (!GetIndex( 1, column, index, &rowIndex, &columnIndex ))
    {
		LOG_WARNING1( "setColumnPortState bad input: col=%c", column );
        return;
    }

	for (rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
	{
		m_Ports[columnIndex][rowIndex].SetState( state, true );
        m_PortNeedProbe[columnIndex][rowIndex] = false;
	}
	SyncStringStatus( );
}

void CCassette::SetIndexPortState( int start_index, int length, CSamplePort::State state )
{
	if (start_index == 0)
	{
		SetAllPortState( state );
		return;
	}

	--start_index; //now start_index start from 0 for port

	int end_index = start_index + length;

	for (int index = start_index; index < end_index; ++index)
	{
		int rowIndex(0);
		int columnIndex(0);
		if (GetRowColumnIndex( index, rowIndex, columnIndex ))
		{
			InternalSetPortState( index, rowIndex, columnIndex, state );
		}
	}
}

CSamplePort::State CCassette::GetPortFutureState( int row, char column ) const
{
	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return CSamplePort::PORT_UNKNOWN;
    }
	return m_Ports[columnIndex][rowIndex].GetFutureState( );
}

void CCassette::SetPortFutureState( int row, char column, CSamplePort::State state )
{
	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return;
    }

	m_Ports[columnIndex][rowIndex].SetFutureState( state );
}

void CCassette::ResetPortFutureState( )
{
	for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
	{
		for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
		{
			m_Ports[columnIndex][rowIndex].ResetFutureState( );
		}
	}
}

void CCassette::SetUpCoordinates( const PointCoordinate & point )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}

	//save them first
	m_CenterX = point.x;
	m_CenterY = point.y;
	m_BottomZ = point.z;
	m_AngleOffset = point.u;
	m_Orientation = point.o;
	m_tiltDX = 0;
	m_tiltDY = 0;

	//mark the cassette are ready.
	m_CoordiatesReady = true;
}

void CCassette::SetupTilt( const PointCoordinate & topPoint, const PointCoordinate & bottomPoint )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}

	m_CALTopX = topPoint.x;
    m_CALTopY = topPoint.y;
    m_CALTopZ = topPoint.z;
	m_CALBottomX = bottomPoint.x;
    m_CALBottomY = bottomPoint.y;
    m_CALBottomZ = bottomPoint.z;

    //check
    float deltaX = m_CALTopX - m_CALBottomX;
    float deltaY = m_CALTopY - m_CALBottomY;
    float deltaZ = m_CALTopZ - m_CALBottomZ;

    //check Z
    if (fabsf(deltaZ) < m_Height / 2.0f)
    {
        LOG_WARNING1( "in cassette tilt, top/bottom too close, deltaZ only=%f", deltaZ );
        return;
    }

    //check tilt
    float distance = sqrtf( deltaX * deltaX + deltaY * deltaY );
    float angle = distance / deltaZ / DEGREE_TO_RADIAN;
    if (angle > m_TiltTolerance)
    {
        LOG_WARNING1( "in cassette tilt, angle %f degree, is too big", angle );
    }

    //recalculate the bottom center and tilt information.
    deltaX /= deltaZ;
    deltaY /= deltaZ;

	m_tiltDX = deltaX;
	m_tiltDY = deltaY;
	m_CenterX = m_CALBottomX + deltaX * (m_BottomZ - m_CALBottomZ );
    m_CenterY = m_CALBottomY + deltaY * (m_BottomZ - m_CALBottomZ );
}

//this is the position in front of cassette. "G" column
//ignore shrink in horizontal, we do not care.
void CCassette::GetStandbyPoint( int row, char column, PointCoordinate& point ) const
{
    //all 0s will cause robot to fail, (0,0,0) is not reachable
    point.x = 0;
    point.y = 0;
    point.z = 0;
    point.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	int index;
	int rowIndex;
	int columnIndex;

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return;
    }

	float DZ = GetPerfectDZ( rowIndex, columnIndex );
	float u = 0;
	float r = 0;
	switch (m_Type)
	{
	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		u = m_UForNormalStandby;
		r = m_Radius * m_ShrinkFactor + m_PortReadyDistance;
		break;

	case CASSETTE_TYPE_SUPERPUCK:
		u = m_UForPuckStandby;
		r = fabsf(m_SP_T[0]) * m_ShrinkFactor + m_PortReadyDistance;
		break;

	default:
		return;
	}
	//get point for standby
	GetCirclePointForU( u, r, DZ, point );
}
void CCassette::GetSecondaryStandbyPoint( int row, char column, PointCoordinate& point ) const
{
    //all 0s will cause robot to fail, (0,0,0) is not reachable
    point.x = 0;
    point.y = 0;
    point.z = 0;
    point.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	int index;
	int rowIndex;
	int columnIndex;

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return;
    }
	//get DZ
	float DZ = GetPerfectDZ( rowIndex, columnIndex );
	float r = 0;
	switch (m_Type)
	{
	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		r = m_Radius * m_ShrinkFactor + m_PortReadyDistance;
		break;

	case CASSETTE_TYPE_SUPERPUCK:
		r = fabsf(m_SP_T[0]) * m_ShrinkFactor + m_PortReadyDistance;
		break;

	default:
		return;
	}
	GetCirclePointForU( m_UForSecondaryStandby, r, DZ, point );
}

void CCassette::GetProbePoints( PointCoordinate points[4], float& distance ) const
{
	//init to invalid values
	int i = 0;
	for (i = 0; i < 4; ++i)
	{
		points[i].x = 0;
		points[i].y = 0;
		points[i].z = 0;
		points[i].u = 0;
	}
    distance = 0;

	//check cassette info status
	if (!m_CoordiatesReady)
    {
        return;
    }

	float r = m_Radius * m_ShrinkFactor - 3.0f;

	//the 4 points are related to column J, A, D, G
	//column index 9, 0, 3, 6
	int index[4] = {9, 0, 3, 6};


	for (i = 0; i < 4; ++i)
	{
		float phi = m_AngleOfFirstColumn + index[i] * 360.0f / NUM_COLUMN;
		float u = AdjustU( phi + 180.0f );
		float DZ = m_ShrinkFactor * m_CalibrationHeight + 15.0f;
		GetCirclePointForU( u, r, DZ, points[i] );
		//points[i].u += 45.0f; //rotate 45 degree to give cavity some space.
	}
	distance = 25.0f;
}


//passing point is middle of standby point and destination point
void CCassette::GetArcPointsFromStandby( int row, char column, PointCoordinate& pass, PointCoordinate& dest ) const
{
    pass.x = 0;
    pass.y = 0;
    pass.z = 0;
    pass.u = 0;
    dest.x = 0;
    dest.y = 0;
    dest.z = 0;
    dest.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	int index;
	int rowIndex;
	int columnIndex;

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return;
    }
	float DZ = GetPerfectDZ( rowIndex, columnIndex );
	float u = AdjustU( m_AngleOfFirstColumn + m_AngleOffset + columnIndex * 360.0f / NUM_COLUMN  + 180.0f );
	GetArcPointsForU( DZ, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), m_UForNormalStandby, u, pass, dest );
}

void CCassette::GetArcPointsFromPort( int from_row, char from_column, int to_row, char to_column,
									 PointCoordinate& pass, PointCoordinate& dest ) const
{
    pass.x = 0;
    pass.y = 0;
    pass.z = 0;
    pass.u = 0;
    dest.x = 0;
    dest.y = 0;
    dest.z = 0;
    dest.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	int fromRowIndex;
	int fromColumnIndex;
	int fromIndex;
	int toRowIndex;
	int toColumnIndex;
	int toIndex;
    if (!GetIndex( from_row, from_column, fromIndex, &fromRowIndex, &fromColumnIndex ))
    {
        return;
    }
    if (!GetIndex( to_row, to_column, toIndex, &toRowIndex, &toColumnIndex ))
    {
        return;
    }

	//get both points for from and for dest
	PointCoordinate dummy;
	PointCoordinate from;
	GetArcPointsFromStandby( from_row, from_column, dummy, from );
	GetArcPointsFromStandby( to_row, to_column, dummy, dest );

	float pass_u = (from.u + dest.u) / 2.0f;
	float DZ = (GetPerfectDZ( fromRowIndex, fromColumnIndex ) + GetPerfectDZ( toRowIndex, toColumnIndex) ) / 2.0f;
	GetCirclePointForU( pass_u, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), DZ, pass );
}

void CCassette::GetArcPointsToSecondaryStandby( int from_row, char from_column, PointCoordinate& pass, PointCoordinate& dest ) const
{
    pass.x = 0;
    pass.y = 0;
    pass.z = 0;
    pass.u = 0;
    dest.x = 0;
    dest.y = 0;
    dest.z = 0;
    dest.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	int rowIndex;
	int columnIndex;
	int index;
    if (!GetIndex( from_row, from_column, index, &rowIndex, &columnIndex ))
    {
        return;
    }

	float DZ = GetPerfectDZ( rowIndex, columnIndex );
	float u = AdjustU( m_AngleOfFirstColumn + m_AngleOffset + columnIndex * 360.0f / NUM_COLUMN  + 180.0f );
	GetArcPointsForU( DZ, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), u, m_UForSecondaryStandby, pass, dest );
}

void CCassette::GetPortPoint( int row, char column, PointCoordinate& point, PointCoordinate* pPortProbeStandByPoint ) const
{
    point.x = 0;
    point.y = 0;
    point.z = 0;
    point.u = 0;

	if (!m_CoordiatesReady)
    {
        return;
    }

    int columnIndex;
	int rowIndex;
    int index;
    if (!GetIndex( row, column, index, &rowIndex, &columnIndex))
    {
        return;
    }

	switch (m_Type)
	{
	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		{
			float DZ = GetPerfectDZ( rowIndex, columnIndex );
			float u = AdjustU( m_AngleOfFirstColumn + m_AngleOffset + columnIndex * 360.0f / NUM_COLUMN  + 180.0f );
			GetCirclePointForU( u, (m_Radius * m_ShrinkFactor - m_InDistanceForCassette), DZ, point );
			if (pPortProbeStandByPoint)
			{
				GetCirclePointForU( u, (m_Radius * m_ShrinkFactor + m_ProbeStandbyDistance), DZ, *pPortProbeStandByPoint );
			}
		}
		break;

	case CASSETTE_TYPE_SUPERPUCK:
		{
			float DX(0);
			float DY(0);
			float DZ(0);
			
			GetPuckPoint( rowIndex, columnIndex, -m_InDistanceForPuck, point );
			if (pPortProbeStandByPoint)
			{
				GetPuckPoint( rowIndex, columnIndex, m_ProbeStandbyDistance, *pPortProbeStandByPoint );
			}

		}
		break;

	default:
		return;
	}

}


void CCassette::SetStatus( Status status, bool forced_clear )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}
	try
	{
		if (status != CASSETTE_PRESENT && m_Status == CASSETTE_PRESENT)
		{
			saveStatusToFile( );
		}
	}
	catch (...) {}
    switch (status)
    {
    case CASSETTE_PRESENT:
		if (m_NeedConfigProbe)
		{
			ProcessProbeString( );
		}
        m_Status = status;
        break;

	case CASSETTE_NOT_EXIST:
		m_CoordiatesReady = false;
		ClearAllPortNeedProbe( );
	case CASSETTE_ABSENT:
		LOG_FINEST( "set all ports to not exist" );
        SetType( CASSETTE_TYPE_NORMAL, true );
		for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
		{
			for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
			{
				m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_NOT_EXIST, true );
			}
		}
        m_Status = status;
		break;

	case CASSETTE_PROBLEM:
		LOG_FINEST( "set all ports to bad" );
        SetType( CASSETTE_TYPE_NORMAL, true );
		for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
		{
			for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
			{
				m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_BAD, true );
			}
		}
        m_Status = status;
		break;

    default:
        status = CASSETTE_UNKOWN;
    case CASSETTE_UNKOWN:
		LOG_FINEST( "set all ports to unknown status" );
        SetType( CASSETTE_TYPE_NORMAL, forced_clear );
        m_Status = status;
		break;
    }
    SyncStringStatus( ); //update all fields
}

void CCassette::SetInLN2( bool inLN2 )
{
    if (inLN2)
    {
        m_ShrinkFactor = (1.0f - 0.0038873173f); //Al in Liquid N2.
    }
    else
    {
        m_ShrinkFactor = 1.0f;
    }
}
bool CCassette::positionIsValidForNormalCassette( short row, char column ) const
{
	if (column < 'A' || column > ('A' + NUM_COLUMN - 1))
	{
		return false;
	}
    if (row < 1 || row > NUM_ROW)
    {
        return false;
    }
	return true;
}
bool CCassette::positionIsValidForCalibrationCassette( short row, char column ) const
{
	if (column < 'A' || column > ('A' + NUM_COLUMN - 1))
	{
		return false;
	}
    if (row != 1 && row != NUM_ROW)
    {
        return false;
    }
	return true;
}
bool CCassette::positionIsValidForSuperPuck( short row, char column ) const
{
	if (column < 'A' || column > ('A' + NUM_PUCK - 1))
	{
		return false;
	}
    if (row < 1 || row > NUM_PUCK_PIN)
    {
        return false;
    }
	return true;
}

bool CCassette::PositionIsValid( short row, char column ) const
{
	switch (m_Status)
	{
	case CASSETTE_NOT_EXIST:
	case CASSETTE_ABSENT:
		return false;

	case CASSETTE_PRESENT:
		switch (m_Type)
		{
		case CASSETTE_TYPE_NORMAL:
			return positionIsValidForNormalCassette( row, column );

		case CASSETTE_TYPE_CALIBRATION:
			return positionIsValidForCalibrationCassette( row, column );

		case CASSETTE_TYPE_SUPERPUCK:
			return positionIsValidForSuperPuck( row, column );

		default:
			return false;
		}
		return false; //never here

	default:
			return (positionIsValidForNormalCassette( row, column ) ||
				positionIsValidForSuperPuck( row, column ));

	}

    return false; //never here
}

void CCassette::loadStatusFromString( const char * stringStatus )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}

	if (stringStatus == NULL || strlen( stringStatus ) < NUM_STRING_STATUS_LENGTH)
	{
		LOG_WARNING( "bad string in CCassette::loadStatusFromSTring" );
		return;
	}

	switch (stringStatus[0])
	{
	case '0':
		m_Type = CASSETTE_TYPE_NORMAL;
		m_Status = CASSETTE_ABSENT;
		break;
	case '1':
		m_Type = CASSETTE_TYPE_NORMAL;
		m_Status = CASSETTE_PRESENT;
		break;
	case '2':
		m_Type = CASSETTE_TYPE_CALIBRATION;
		m_Status = CASSETTE_PRESENT;
		break;
	case '3':
		m_Type = CASSETTE_TYPE_SUPERPUCK;
		m_Status = CASSETTE_PRESENT;
		break;
	case 'u':
		m_Type = CASSETTE_TYPE_NORMAL;
		m_Status = CASSETTE_UNKOWN;
		break;
	default:
	case 'X':
		m_Type = CASSETTE_TYPE_NORMAL;
		m_Status = CASSETTE_PROBLEM;
		break;
	}

	for (char column = 'A'; column < 'A' + MAX_COLUMN; ++column)
	{
		for (int row = 1; row <= MAX_ROW; ++row)
		{
			int index;
			int rowIndex;
			int columnIndex;
			if (GetIndex( row, column, index, &rowIndex, &columnIndex ))
			{
				CSamplePort::State newState = CSamplePort::State::PORT_UNKNOWN;
				switch (stringStatus[2 + index * 2])
				{
				case 'm':
					newState = CSamplePort::State::PORT_MOUNTED;
					break;
				case '0':
					newState = CSamplePort::State::PORT_EMPTY;
					break;
				case '1':
					newState = CSamplePort::State::PORT_SAMPLE_IN;
					break;
				case '-':
					newState = CSamplePort::State::PORT_NOT_EXIST;
					break;
				case 'b':
					newState = CSamplePort::State::PORT_BAD;
					break;
				case 'j':
					newState = CSamplePort::State::PORT_JAM;
					break;
				case 'u':
				default:
					newState = CSamplePort::State::PORT_UNKNOWN;
					break;
				}
				m_Ports[columnIndex][rowIndex].SetState( newState, true );
			}
		}
	}

	SyncStringStatus( );
}

void CCassette::SyncStringStatus( )
{
    //clear the string
    memset( m_StringStatus, 0, sizeof(m_StringStatus) );
    memset( m_StringStatus, ' ', NUM_STRING_STATUS_LENGTH );

    UpdateStringCassetteField( );

	for (char column = 'A'; column < 'A' + MAX_COLUMN; ++column)
	{
		for (int row = 1; row <= MAX_ROW; ++row)
		{
			int index;
			int rowIndex;
			int columnIndex;
			if (GetIndex( row, column, index, &rowIndex, &columnIndex ))
			{
				UpdateStringPortField( index, rowIndex, columnIndex );
			}
		}
	}
}

void CCassette::UpdateStringCassetteField( )
{
    switch (m_Status)
    {
    case CASSETTE_ABSENT:
        m_StringStatus[0] = '0';
        break;

    case CASSETTE_PRESENT:
		switch (m_Type)
		{
		case CASSETTE_TYPE_CALIBRATION:
	        m_StringStatus[0] = '2';
			break;
		case CASSETTE_TYPE_SUPERPUCK:
	        m_StringStatus[0] = '3';
			break;

		case CASSETTE_TYPE_NORMAL:
		default:
	        m_StringStatus[0] = '1';
			break;
		}
        break;

	case CASSETTE_PROBLEM:
        m_StringStatus[0] = 'X';
        break;

	case CASSETTE_NOT_EXIST:
        m_StringStatus[0] = '-';
        break;

    case CASSETTE_UNKOWN:
    default:
        m_StringStatus[0] = 'u';
    }
}

void CCassette::UpdateStringPortField( int index, int rowIndex, int columnIndex )
{
    size_t position_in_string = 2 + index * 2;

	if (m_Status == CASSETTE_ABSENT)
	{
        m_StringStatus[position_in_string] = '-';
		return;
	}

    switch (m_Ports[columnIndex][rowIndex].GetState( ))
    {
    case CSamplePort::PORT_MOUNTED:
        m_StringStatus[position_in_string] = 'm';
        break;

    case CSamplePort::PORT_EMPTY:
        m_StringStatus[position_in_string] = '0';
        break;

    case CSamplePort::PORT_SAMPLE_IN:
        m_StringStatus[position_in_string] = '1';
        break;

    case CSamplePort::PORT_JAM:
        m_StringStatus[position_in_string] = 'j';
        break;

    case CSamplePort::PORT_BAD:
        m_StringStatus[position_in_string] = 'b';
        break;

    case CSamplePort::PORT_NOT_EXIST:
        m_StringStatus[position_in_string] = '-';
        break;

    case CSamplePort::PORT_UNKNOWN:
    default:
        m_StringStatus[position_in_string] = 'u';
    }
}

void CCassette::syncStringForce( )
{
    //clear the string
    memset( m_stringForce, 0, sizeof(m_stringForce) );
    memset( m_stringForce, ' ', NUM_STRING_FORCE_LENGTH );

    updateStringForceCassette( );

	for (char column = 'A'; column < 'A' + MAX_COLUMN; ++column)
	{
		for (int row = 1; row <= MAX_ROW; ++row)
		{
			int index;
			int rowIndex;
			int columnIndex;
			if (GetIndex( row, column, index, &rowIndex, &columnIndex ))
			{
				updateStringForcePort( index, rowIndex, columnIndex, true );
			}
		}
	}
}

void CCassette::updateStringForceCassette( )
{
	/*
    switch (m_Status)
    {
    case CASSETTE_PRESENT:
	case CASSETTE_PROBLEM:
        break;

    case CASSETTE_ABSENT:
    case CASSETTE_UNKOWN:
    default:
		memset( m_stringForce, 'X', TOP_POSITION_WIDTH );
		return;
    }
	*/

	if (fabsf( m_topPosition ) > 999.9f )
	{
		memset( m_stringForce, 'B', TOP_POSITION_WIDTH );
	}
	else
	{
		char buffer[2 * TOP_POSITION_WIDTH] = {0};
		sprintf( buffer, "%*.1f", TOP_POSITION_WIDTH, m_topPosition );
		memcpy( m_stringForce, buffer, TOP_POSITION_WIDTH );
	}
}
void CCassette::updateStringForcePort( int index, int rowIndex, int columnIndex, bool honorStatus )
{
    size_t position_in_string = TOP_POSITION_WIDTH + 1 + index * (FORCE_WIDTH + 1);

	if (m_Status == CASSETTE_ABSENT)
	{
		memset( m_stringForce + position_in_string, '-', FORCE_WIDTH );
		return;
	}

	if (honorStatus)
	{
		switch (m_Ports[columnIndex][rowIndex].GetState( ))
		{
		case CSamplePort::PORT_EMPTY:
			memset( m_stringForce + position_in_string, 'E', FORCE_WIDTH );
			return;

		case CSamplePort::PORT_MOUNTED:
		case CSamplePort::PORT_SAMPLE_IN:
		case CSamplePort::PORT_JAM:
		case CSamplePort::PORT_BAD:
			break;

		case CSamplePort::PORT_NOT_EXIST:
			memset( m_stringForce + position_in_string, '-', FORCE_WIDTH );
			return;

		case CSamplePort::PORT_UNKNOWN:
		default:
			memset( m_stringForce + position_in_string, 'u', FORCE_WIDTH );
			return;
		}
	}

	float force = m_forces[columnIndex][rowIndex];
	if (force == RobotEpson::PORT_ERROR_EMPTY)
	{
		memset( m_stringForce + position_in_string, 'E', FORCE_WIDTH );
		return;
	}
	if (fabsf( force ) > 99.0f)
	{
		memset( m_stringForce + position_in_string, 'B', FORCE_WIDTH );
		return;
	}
	char buffer[FORCE_WIDTH * 2] = {0};
	if (fabsf( force ) >= 10.0f)
	{
		sprintf( buffer, "%*.0f", FORCE_WIDTH, force );
	}
	else
	{
		sprintf( buffer, "%*.1f", FORCE_WIDTH, force );
	}
	memcpy( m_stringForce + position_in_string, buffer, FORCE_WIDTH );
}

void CCassette::SetType( Type type, bool forced_clear )
{
	m_Type = type;

	switch (m_Type)
	{
	case CASSETTE_TYPE_CALIBRATION:
		for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
		{
			for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
			{
				if (rowIndex == 0 || rowIndex == (NUM_ROW - 1))
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_UNKNOWN, forced_clear );
				}
				else
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_NOT_EXIST, true );
				}
			}
		}
		break;

	case CASSETTE_TYPE_SUPERPUCK:
		for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
		{
			for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
			{
				if (columnIndex < NUM_PUCK)
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_UNKNOWN, forced_clear );
				}
				else
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_NOT_EXIST, true );
				}
			}
		}
		break;

	case CASSETTE_TYPE_NORMAL:
	default:
		for (int columnIndex = 0; columnIndex < MAX_COLUMN; ++columnIndex)
		{
			for (int rowIndex = 0; rowIndex < MAX_ROW; ++rowIndex)
			{
				if (rowIndex < NUM_ROW)
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_UNKNOWN, forced_clear );
				}
				else
				{
					m_Ports[columnIndex][rowIndex].SetState( CSamplePort::PORT_NOT_EXIST, true );
				}
			}
		}
		break;
	}
	if (m_NeedConfigProbe)
	{
		ProcessProbeString( );
	}
}

//it will use the height data to decide whether this is a normall cassette,
//calibration cassette, puck adaptor or error.
bool CCassette::CheckHeight( const float* heights, int numHeights, float* delta )
{
    if (!m_CoordiatesReady)
    {
		if (delta) *delta = 99999.0f;
		LOG_WARNING( "called CCassette::CheckHeight before setup coordinates" );
        return false;
    }

	if (heights == NULL || numHeights <= 0)
	{
		LOG_WARNING( "called CCassette::CheckHeight with no input" );
		return false;
	}

	//take average if more than 1 height points
	float averageHeight = heights[0];
	bool mustBeCalibrationCassette = false;
	bool mustBeSuperPuck = false;
	if (numHeights > 1)
	{
		//check to see if it is super puck adaptor: one number should be 0
		int i = 0;
		for (i = 0; i < numHeights; ++i)
		{
			if (heights[i] == 0.0f)
			{
				mustBeSuperPuck = true;
				break;
			}
		}

		if (mustBeSuperPuck)
		{
			for (i = 1; i < numHeights; ++i)
			{
				averageHeight += heights[i];
			}
			averageHeight /= numHeights - 1;
		}
		else
		{
			float maxH = heights[0];
			float minH = heights[0];

			for (i = 1; i < numHeights; ++i)
			{
				averageHeight += heights[i];
				if (maxH < heights[i]) maxH = heights[i];
				if (minH > heights[i]) minH = heights[i];
			}
			if (maxH - minH > 0.5f * m_CalibrationEdgeHeight * m_ShrinkFactor)
			{
				mustBeCalibrationCassette = true;
				float myThreshold = maxH - 0.5f * m_CalibrationEdgeHeight * m_ShrinkFactor;
				for (int i = 0; i < numHeights; ++i)
				{
					if (heights[i] < myThreshold)
					{
						averageHeight += m_CalibrationEdgeHeight * m_ShrinkFactor;
					}
				}
			}
			averageHeight /= numHeights;
		}
	}
	m_topPosition = averageHeight;
    updateStringForceCassette( );
	
	////// compare with user cassette heights and calibration cassette height
	float dU = averageHeight - (m_Height * m_ShrinkFactor + m_BottomZ);
	if (fabsf(dU) < m_HeightTolerance && !mustBeCalibrationCassette && !mustBeSuperPuck)
	{
		SetType( CASSETTE_TYPE_NORMAL, (m_previousDetectedType != CASSETTE_TYPE_NORMAL) );
		m_previousDetectedType = CASSETTE_TYPE_NORMAL;
		if (delta) *delta = dU;
		return 1;
	}
	
	float dC = averageHeight - (m_CalibrationHeight * m_ShrinkFactor + m_BottomZ);
	if (fabsf(dC) < m_HeightTolerance && !mustBeSuperPuck)
	{
		SetType( CASSETTE_TYPE_CALIBRATION, (m_previousDetectedType != CASSETTE_TYPE_CALIBRATION) );
		m_previousDetectedType = CASSETTE_TYPE_CALIBRATION;

		if (delta) *delta = dC;
		return 1;
	}

	dC = averageHeight - (m_SuperPuckHeight * m_ShrinkFactor + m_BottomZ);
	if (fabsf(dC) < m_HeightTolerance && !mustBeCalibrationCassette)
	{
		SetType( CASSETTE_TYPE_SUPERPUCK, (m_previousDetectedType != CASSETTE_TYPE_SUPERPUCK) );
		m_previousDetectedType = CASSETTE_TYPE_SUPERPUCK;

		if (delta) *delta = dC;
		return 1;
	}


	//OK, failed, find a small delta to return
	if (delta)
	{
		*delta = (fabsf( dU ) < fabsf( dC )) ? dU : dC;
	}
	return 0;
}
void CCassette::setPortForce( int row, char column, float force )
{
	int index = 0;
	int rowIndex(0);
	int columnIndex(0);

    if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
    {
        return;
    }

	m_forces[columnIndex][rowIndex] = force;
    updateStringForcePort( index, rowIndex, columnIndex );
}
void CCassette::clearForce( )
{
	memset( m_forces, 0, sizeof(m_forces) );
	syncStringForce( );
}
//void CCassette::perfectPortOffset( int rowIndex, int columnIndex, float radius, float& dx, float& dy, float& dz, float& u ) const
//{
//	float angle = m_AngleOfFirstColumn + m_AngleOffset + columnIndex * 360.0f / NUM_COLUMN;
//	u = AdjustU(  angle + 180.0f );
//
//	angle *= DEGREE_TO_RADIAN;
//	dx = radius * cosf( angle );
//	dy = radius * sinf( angle );
//	dz = (m_ZOfFirstRow + rowIndex * m_HeightOfRow) * m_ShrinkFactor;
//}

void CCassette::perfectPuckOffset( int rowIndex, int columnIndex, float distance, float& dx, float& dy, float& dz, float& u ) const
{
	//center of the puck decided by columnIndex
	float angle1 = m_SP_Alpha[columnIndex] + m_AngleOfFirstColumn + m_AngleOffset;
	if (m_SP_T[columnIndex] > 0)
	{
		u = AdjustU( angle1 - 90.0f );
	}
	else
	{
		u = AdjustU( angle1 + 90.0f );
	}
	angle1 *= DEGREE_TO_RADIAN;

	float center_x = m_SP_R[columnIndex] * cosf( angle1);
	float center_y = m_SP_R[columnIndex] * sinf( angle1);

	float angle2 = angle1 + 90.0f * DEGREE_TO_RADIAN;
	//distance > 0 means big distance
	float real_T = m_SP_T[columnIndex] + distance;
	if (m_SP_T[columnIndex] < 0)
	{
		real_T = m_SP_T[columnIndex] - distance;
	}
	center_x += real_T * cosf( angle2 );
	center_y += real_T * sinf( angle2 );
	float center_z = m_SP_Z[columnIndex];

	//from center to the port decided by rowIndex in puck coordinate
	float r = m_SP_1_5_Radius;
	float delta = 360.0f / 5.0f;
	if (rowIndex >= 5)
	{
		r = m_SP_6_16_Radius;
		delta = 360.0f / 11.0f;
		rowIndex -= 5;
	}
	float portAngle = (delta * rowIndex + m_SP_Angle[columnIndex]) * DEGREE_TO_RADIAN;	//orientation

	float portHorz = r * cosf( portAngle );
	float portZ = r * sinf( portAngle );

	//project into world coord.
	float angle3 = angle2 + 90.0f * DEGREE_TO_RADIAN;
	if (m_SP_T[columnIndex] < 0)
	{
		angle3 = angle1;
	}

	float portX = portHorz * cosf( angle3 );
	float portY = portHorz * sinf( angle3 );

	dx = (center_x + portX) * m_ShrinkFactor;
	dy = (center_y + portY) * m_ShrinkFactor;
	dz = (center_z + portZ) * m_ShrinkFactor;
}
void CCassette::GetPuckPoint( int rowIndex, int columnIndex, float distance, PointCoordinate& point, float* pPerfectDZ ) const
{
	float DX(0);
	float DY(0);
	float DZ(0);

	perfectPuckOffset( rowIndex, columnIndex, distance, DX, DY, DZ, point.u );

	if (pPerfectDZ) *pPerfectDZ = DZ;

	tiltAdjust( DX, DY, DZ, DX, DY, DZ );
	point.x = m_CenterX + DX;
	point.y = m_CenterY + DY;
	point.z = m_BottomZ + DZ;
	point.o = m_Orientation;

}

float CCassette::GetPerfectDZ( int rowIndex, int columnIndex ) const
{
	float dummy(0);
	float DZ(0);
	if (m_Type == CASSETTE_TYPE_SUPERPUCK)
	{
		perfectPuckOffset( rowIndex, columnIndex, m_PortReadyDistance, dummy, dummy, DZ, dummy );
	}
	else
	{
		DZ = (m_ZOfFirstRow + rowIndex * m_HeightOfRow) * m_ShrinkFactor;
	}
	return DZ;
}
void CCassette::GetCirclePointForU( float u, float radius, float perfectDZ, PointCoordinate& point ) const
{
    point.x = 0;
    point.y = 0;
    point.z = 0;
    point.u = 0;
    if (!m_CoordiatesReady)
    {
        return;
    }

	float DX(0);
	float DY(0);
	float DZ(0);
	float phi = (u + 180.0f) * DEGREE_TO_RADIAN;
	DX = radius * cosf( phi );
	DY = radius * sinf( phi );

	tiltAdjust( DX, DY, perfectDZ, DX, DY, DZ );

	point.x = m_CenterX + DX;
	point.y = m_CenterY + DY;
	point.z = m_BottomZ + DZ;
	point.u = u;
    point.o = m_Orientation;
}
void CCassette::GetArcPointsForU( float DZ, float r, float from_u, float to_u, PointCoordinate& pass, PointCoordinate& dest ) const
{
    pass.x = 0;
    pass.y = 0;
    pass.z = 0;
    pass.u = 0;
    dest.x = 0;
    dest.y = 0;
    dest.z = 0;
    dest.u = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	pass.u = (from_u + to_u) /2.0f;
	GetCirclePointForU( pass.u, r, DZ, pass );
	GetCirclePointForU( to_u, r, DZ, dest );
}

void CCassette::GetCommandForPortFromStandby( int row, char column, char* toPortCmd, char* toStandbyCmd ) const
{
	if (toPortCmd) toPortCmd[0] = 0;
	if (toStandbyCmd) toStandbyCmd[0] = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	if (!m_pRobotEpson) return;

	PointCoordinate standbyPoint;
	GetStandbyPoint( row, column, standbyPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P50, standbyPoint );

	switch (m_Type)
	{
	case CCassette::CASSETTE_TYPE_CALIBRATION:
	case CCassette::CASSETTE_TYPE_NORMAL:
		{
			PointCoordinate destPoint;
			PointCoordinate passPoint;
			GetArcPointsFromStandby( row, column, passPoint, destPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P52, destPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P51, passPoint );
			if (fabs( passPoint.u - destPoint.u ) > 5.0f )
			{
				if (toPortCmd) strcpy( toPortCmd, "Arc P51, P52" );
				if (toStandbyCmd) strcpy( toStandbyCmd, "Arc P51, P50" );
			}
			else
			{
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
				if (toStandbyCmd) strcpy( toStandbyCmd, "Move P50" );
			}
		}
		break;

	case CCassette::CASSETTE_TYPE_SUPERPUCK:
		{
			///////////////////////////get ready point////////////////////////////////////////////
			int index;
			int rowIndex;
			int columnIndex;

			if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
			{
				return;
			}
			PointCoordinate destPoint;
			float DZ;
			GetPuckPoint( rowIndex, columnIndex, m_PortReadyDistance, destPoint, &DZ );
			m_pRobotEpson->assignPoint( RobotEpson::P52, destPoint );

			//////////////////////// compare with standby point///////////
			if (fabsf( destPoint.u - standbyPoint.u ) < 10.0)
			{
				//direct move
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
				if (toStandbyCmd) strcpy( toStandbyCmd, "Move P50" );
			}
			else
			{
				//arc and then shift again
				//arc P51, P55, --->P52
				//           u       u
				PointCoordinate passPoint;
				PointCoordinate tempPoint;
				GetArcPointsForU( DZ, (fabsf(m_SP_T[0]) * m_ShrinkFactor + m_PortReadyDistance), standbyPoint.u, destPoint.u, passPoint, tempPoint );

				m_pRobotEpson->assignPoint( RobotEpson::P51, passPoint );
				m_pRobotEpson->assignPoint( RobotEpson::P55, tempPoint );

				if (toPortCmd) strcpy( toPortCmd, "Arc P51, P55 CP; Move P52" );
				if (toStandbyCmd) strcpy( toStandbyCmd, "Move P55 CP; Arc P51, P50" );
			}
		}
		break;

	default:
		;
	}
}
//normal: Arc P54, P52						back to standby Arc P51, P50
//buck:   Move P57; Arc P58, P59; Move P52  back to standby Move P55; Arc P51, P50
void CCassette::GetCommandForPortFromPort( int from_row, char from_column, int to_row, char to_column, char* toPortCmd, char* toStandbyCmd ) const
{
	if (toPortCmd) toPortCmd[0] = 0;
	if (toStandbyCmd) toStandbyCmd[0] = 0;

	if (!m_CoordiatesReady)
    {
        return;
    }

	if (!m_pRobotEpson) return;

	//new standby derived from destination port
	PointCoordinate standbyPoint;
	GetStandbyPoint( to_row, to_column, standbyPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P50, standbyPoint );

	switch (m_Type)
	{
	case CCassette::CASSETTE_TYPE_CALIBRATION:
	case CCassette::CASSETTE_TYPE_NORMAL:
		{
			PointCoordinate destPoint;
			PointCoordinate passPoint;
			GetArcPointsFromPort( from_row, from_column, to_row, to_column, passPoint, destPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P52, destPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P54, passPoint );
			if (fabs( passPoint.u - destPoint.u ) > 5.0f )
			{
				if (toPortCmd) strcpy( toPortCmd, "Arc P54, P52" );
			}
			else
			{
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
			}
		}
		break;

	case CCassette::CASSETTE_TYPE_SUPERPUCK:
		{
			///////////////////////////get ready point////////////////////////////////////////////
			int fromIndex;
			int fromRowIndex;
			int fromColumnIndex;
			int toIndex;
			int toRowIndex;
			int toColumnIndex;

			if (!GetIndex( from_row, from_column, fromIndex, &fromRowIndex, &fromColumnIndex ))
			{
				return;
			}
			if (!GetIndex( to_row, to_column, toIndex, &toRowIndex, &toColumnIndex ))
			{
				return;
			}
			PointCoordinate destPoint;
			PointCoordinate passPoint3;
			float pDZDest;
			GetPuckPoint( toRowIndex, toColumnIndex, m_PortReadyDistance, destPoint, &pDZDest );
			GetCirclePointForU( destPoint.u, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), pDZDest, passPoint3 );

			m_pRobotEpson->assignPoint( RobotEpson::P52, destPoint );

			PointCoordinate fromPoint;
			PointCoordinate passPoint1;
			float pDZFrom;
			GetPuckPoint( fromRowIndex, fromColumnIndex, m_PortReadyDistance, fromPoint, &pDZFrom );
			GetCirclePointForU( fromPoint.u, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), pDZFrom, passPoint1 );

			PointCoordinate passPoint2;
			float middle_u = (fromPoint.u + destPoint.u) / 2.0f;
			float middle_DZ = (pDZFrom + pDZDest) / 2.0f;
			GetCirclePointForU( middle_u, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), middle_DZ, passPoint2 );
			
			//////////////////////// compare with standby point///////////
			if (fabsf( destPoint.u - fromPoint.u ) < 90.0)
			{
				//direct move
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
			}
			else
			{
				m_pRobotEpson->assignPoint( RobotEpson::P57, passPoint1 );
				m_pRobotEpson->assignPoint( RobotEpson::P58, passPoint2 );
				m_pRobotEpson->assignPoint( RobotEpson::P59, passPoint3 );
				if (toPortCmd) strcpy( toPortCmd, "Move P57; Arc P58, P59; Move P52" );
			}
		}
		break;

	default:
		;
	}

	//get back to standby command
	GetCommandForPortFromStandby( to_row, to_column, NULL, toStandbyCmd );
}
void CCassette::GetCommandForPortFromSecondary( int row, char column, char* toPortCmd, char* toStandbyCmd ) const
{
	if (toPortCmd) toPortCmd[0] = 0;
	if (toStandbyCmd) toStandbyCmd[0] = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	if (!m_pRobotEpson) return;

	//new standby derived from destination port
	PointCoordinate standbyPoint;
	GetStandbyPoint( row, column, standbyPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P50, standbyPoint );

	//get back to standby command this will be for sure fill P52 destination
	GetCommandForPortFromStandby( row, column, NULL, toStandbyCmd );

	switch (m_Type)
	{
	case CCassette::CASSETTE_TYPE_CALIBRATION:
	case CCassette::CASSETTE_TYPE_NORMAL:
		{
			PointCoordinate fromPoint;
			PointCoordinate passPoint;
			GetArcPointsToSecondaryStandby( row, column, passPoint, fromPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P54, passPoint );
			if (fabs( passPoint.u - fromPoint.u ) > 5.0f )
			{
				if (toPortCmd) strcpy( toPortCmd, "Arc P54, P52" );
			}
			else
			{
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
			}
		}
		break;

	case CCassette::CASSETTE_TYPE_SUPERPUCK:
		{
			///////////////////////////get ready point////////////////////////////////////////////
			int index;
			int rowIndex;
			int columnIndex;

			if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
			{
				return;
			}
			//////////////////////// compare with from point///////////
			float to_u = m_pRobotEpson->m_pSPELCOM->CU( COleVariant( "P52") );
			if (fabsf( to_u - m_UForSecondaryStandby ) < 10.0)
			{
				//direct move
				if (toPortCmd) strcpy( toPortCmd, "Move P52" );
			}
			else
			{
				//arc and then shift again
				//arc P51, P55, --->P52
				//           u       u
				float DZ = GetPerfectDZ( rowIndex, columnIndex );
				PointCoordinate passPoint;
				PointCoordinate tempPoint;
				GetArcPointsForU( DZ, (fabsf(m_SP_T[0]) * m_ShrinkFactor + m_PortReadyDistance), m_UForSecondaryStandby, to_u, passPoint, tempPoint );

				m_pRobotEpson->assignPoint( RobotEpson::P58, passPoint );
				m_pRobotEpson->assignPoint( RobotEpson::P59, tempPoint );

				if (toPortCmd) strcpy( toPortCmd, "Arc P58, P59 CP; Move P52" );
			}
		}
		break;

	default:
		;
	}

}
void CCassette::GetCommandForSecondaryFromPort( int row, char column, char* toSecondaryCmd, char* toStandbyCmd ) const
{
	if (toSecondaryCmd) toSecondaryCmd[0] = 0;
	if (toStandbyCmd) toStandbyCmd[0] = 0;

    if (!m_CoordiatesReady)
    {
        return;
    }

	if (!m_pRobotEpson) return;

	int index;
	int rowIndex;
	int columnIndex;
	if (!GetIndex( row, column, index, &rowIndex, &columnIndex ))
	{
		return;
	}

	//new standby derived from destination port
	PointCoordinate standbyPoint;
	GetStandbyPoint( row, column, standbyPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P50, standbyPoint );

	PointCoordinate destPoint;
	GetSecondaryStandbyPoint( row, column, destPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P52, destPoint );

	//prepare P51
	float DZ = GetPerfectDZ( rowIndex, columnIndex );
	float u = (standbyPoint.u + destPoint.u) / 2.0f;
	PointCoordinate tempPoint;
	GetCirclePointForU( u, (m_Radius * m_ShrinkFactor + m_PortReadyDistance), DZ, tempPoint );
	m_pRobotEpson->assignPoint( RobotEpson::P51, tempPoint );


	if (toStandbyCmd) strcpy( toStandbyCmd, "Arc P51, P50" );

	switch (m_Type)
	{
	case CCassette::CASSETTE_TYPE_CALIBRATION:
	case CCassette::CASSETTE_TYPE_NORMAL:
		{
			PointCoordinate dummyPoint;
			PointCoordinate passPoint;
			GetArcPointsToSecondaryStandby( row, column, passPoint, dummyPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P54, passPoint );
			if (fabs( passPoint.u - destPoint.u ) > 5.0f )
			{
				if (toSecondaryCmd) strcpy( toSecondaryCmd, "Arc P54, P52" );
			}
			else
			{
				if (toSecondaryCmd) strcpy( toSecondaryCmd, "Move P52" );
			}
		}
		break;

	case CCassette::CASSETTE_TYPE_SUPERPUCK:
		{

			PointCoordinate fromPoint;
			GetPuckPoint( rowIndex, columnIndex, m_PortReadyDistance, fromPoint );
			PointCoordinate tempPoint;
			PointCoordinate passPoint;
			GetArcPointsForU( DZ, (fabsf(m_SP_T[0]) * m_ShrinkFactor + m_PortReadyDistance), destPoint.u, fromPoint.u, passPoint, tempPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P59, tempPoint );
			m_pRobotEpson->assignPoint( RobotEpson::P58, passPoint );

			if (fabs( passPoint.u - destPoint.u ) > 5.0f )
			{
				if (toSecondaryCmd) strcpy( toSecondaryCmd, "Move P59 CP; Arc P58, P52" );
			}
			else
			{
				if (toSecondaryCmd) strcpy( toSecondaryCmd, "Move P52" );
			}
		}
		break;

	default:
		;
	}
}

//we may only set cassette and save ports for later setting.
bool CCassette::ConfigNeedProbe( const char* pProbeString, char* status_buffer, bool& anySet )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return true;
	}

	if (strlen( pProbeString ) < NUM_STRING_PROBE_LENGTH)
	{
		strcpy( status_buffer, "wrong probe string length" );
		return false;
	}

	anySet = false;

	memcpy( m_StringProbe, pProbeString, NUM_STRING_PROBE_LENGTH );
	for (unsigned long i = 0; i < NUM_STRING_PROBE_LENGTH; ++i)
	{
		if (i % 2)
		{
			if (m_StringProbe[i] != ' ')
			{
				sprintf( status_buffer, "wrong probe string for cassette %c at %lu", m_Name, i );
				return false;
			}
		}
		else
		{
			if (m_StringProbe[i] == '1')
			{
				anySet = true;
			}

		}
	}

	if (m_StringProbe[0] == '1' || (anySet && (m_Status != CASSETTE_PRESENT)))
	{
		SetNeedProbe( true );
	}

	if (m_Status != CASSETTE_PRESENT)
	{
		//delay config until we find out the cassette type
		m_NeedConfigProbe = true;
		return true;
	}
	
	ProcessProbeString( );
	return true;
}

bool CCassette::GetRowColumnIndex( int index, int& rowIndex, int& columnIndex ) const
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return false;
	}

	switch (m_Type)
	{
	case CASSETTE_TYPE_SUPERPUCK:
		if (index >= NUM_PUCK * NUM_PUCK_PIN || index < 0)
		{
			return false;
		}
		rowIndex    = index % NUM_PUCK_PIN;
		columnIndex = index / NUM_PUCK_PIN;
		return true;

	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		if (index >= MAX_NUM_PORT || index < 0)
		{
			return false;
		}
		rowIndex    = index % NUM_ROW;
		columnIndex = index / NUM_ROW;
		return true;

	default:
		;
	}
	return false;
}

void CCassette::ProcessProbeString( )
{
	switch (m_Type)
	{
	case CASSETTE_TYPE_SUPERPUCK:
		for (int port_index = 0; port_index < NUM_PUCK * NUM_PUCK_PIN; ++port_index)
		{
			int offset = port_index * 2 + 2;
			if (m_StringProbe[offset] == '1')
			{
				short row = port_index % NUM_PUCK_PIN + 1;
				char column = port_index / NUM_PUCK_PIN + 'A';
				
				SetPortNeedProbe( row, column, true );
			}
		}
		break;

	case CASSETTE_TYPE_NORMAL:
	case CASSETTE_TYPE_CALIBRATION:
		for (int port_index = 0; port_index < NUM_ROW * NUM_COLUMN; ++port_index)
		{
			int offset = port_index * 2 + 2;
			if (m_StringProbe[offset] == '1')
			{
				short row = port_index % NUM_ROW + 1;
				char column = port_index / NUM_ROW + 'A';
				
				SetPortNeedProbe( row, column, true );
			}
		}
	default:
		return;
	}
	m_NeedConfigProbe = false;
}
float CCassette::GetDetachDistance( ) const
{
	float result(0);
	switch (m_Type)
	{
	case CASSETTE_TYPE_SUPERPUCK:
		result = m_ShrinkFactor * m_OverPressDistanceForPuck;
		break;

	default:
		result = m_ShrinkFactor * m_OverPressDistanceForCassette;
	}
	return result;
}
void CCassette::saveStatusToFile( )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}

	char filename[128] = {0};
	sprintf( filename, "casStatus_%c.txt", m_Name );

	FILE *fhStatus = fopen( filename, "w" );

	fwrite( m_StringStatus, 1, strlen( m_StringStatus ), fhStatus );
	fclose( fhStatus );
}
void CCassette::restoreStatusFromFile( )
{
	if (m_Status == CASSETTE_NOT_EXIST)
	{
		return;
	}

	char filename[128] = {0};
	sprintf( filename, "casStatus_%c.txt", m_Name );

	FILE *fhStatus = fopen( filename, "r" );
	if (fhStatus == NULL) return;

	char statusBuffer[NUM_STRING_STATUS_LENGTH + 1 + 16] = {0};
	if (fread( statusBuffer, 1, NUM_STRING_STATUS_LENGTH, fhStatus ) == NUM_STRING_STATUS_LENGTH)
	{
		loadStatusFromString( statusBuffer );
	}
	fclose( fhStatus );
}