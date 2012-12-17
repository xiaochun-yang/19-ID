#include "robotexception.h"
#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "log_quick.h"

#include <math.h>

//#define ALWAYS_SLOW

void RobotEpson::SetPowerHigh ( bool powerhigh)
{
#ifdef ALWAYS_SLOW
	m_speed[SPEED_FAST]   = RobotSpeedSetup( 5, 5, 10, 40, 40, 50 );
	m_speed[SPEED_IN_LN2] = RobotSpeedSetup( 5, 5, 10, 40, 40, 50 );

	if (m_pSPELCOM->GetPowerHigh( ))
    {
        m_pSPELCOM->SetPowerHigh ( powerhigh );
    }
#else
	if ( powerhigh )
	{
		m_speed[SPEED_FAST]   = RobotSpeedSetup( 40, 40, 100, 4000, 4000, 1000 );
		m_speed[SPEED_IN_LN2] = RobotSpeedSetup( 20, 20,  50,  150,  150,  200 );
        if (!m_pSPELCOM->GetPowerHigh( ))
        {
        	m_pSPELCOM->SetPowerHigh ( powerhigh );
        }
	}
	else 
	{
		m_speed[SPEED_FAST]   = RobotSpeedSetup( 10, 10,  25, 1000, 1000,  250 );
		m_speed[SPEED_IN_LN2] = RobotSpeedSetup(  5,  5,  10,   40,   40,   50 );
        if (m_pSPELCOM->GetPowerHigh( ))
        {
        	m_pSPELCOM->SetPowerHigh ( powerhigh );
        }
	}
#endif

	//following do not care high power or not
	m_speed[SPEED_PROBE]  = RobotSpeedSetup( 5, 10, 2, 5, 5, 2 );
	m_speed[SPEED_DANCE]  = RobotSpeedSetup( 10, 10, 1, 40, 40, 50 );
	m_speed[SPEED_SAMPLE] = RobotSpeedSetup( 5, 5, 7, 150, 150, 200 );
}


void RobotEpson::setRobotSpeed( RobotSpeed speed )
{
	RobotSpeed index = SPEED_IN_LN2;
	switch (speed)
	{
	case SPEED_IN_LN2:
	case SPEED_PROBE:
	case SPEED_DANCE:
	case SPEED_SAMPLE:
	case SPEED_FAST:
		index = speed;
		break;

	default:
		index = SPEED_IN_LN2;
	}
	m_pSPELCOM->Accel ( m_speed[index].go_acc, m_speed[index].go_dcc );
	m_pSPELCOM->Speed ( m_speed[index].go_speed );
#ifdef EPSON_VB_4
	float move_speed = m_speed[index].move_speed;
	m_pSPELCOM->AccelS ( m_speed[index].move_acc, COleVariant( m_speed[index].move_dcc ) );
	m_pSPELCOM->SpeedS ( move_speed, COleVariant( move_speed ), COleVariant( move_speed ) );
#else
	m_pSPELCOM->AccelS ( m_speed[index].move_acc );
	m_pSPELCOM->SpeedS ( m_speed[index].move_speed );
#endif
}
bool RobotEpson::SetupTemperaryToolSet( LPoint fromPointNum )
{
	PointCoordinate point;
	retrievePoint( fromPointNum, point );
	if (point.x == 0.0f || point.y == 0.0f)
    {
        return false;
    }
#ifdef EPSON_VB_4
	m_pSPELCOM->TLSet( 3, point.x, point.y, point.z, point.u, COleVariant(short(0)), COleVariant(short(0)) );
#else
	m_pSPELCOM->TLSet( 3, point.x, point.y, point.z, point.u );
#endif
    return true;
}

