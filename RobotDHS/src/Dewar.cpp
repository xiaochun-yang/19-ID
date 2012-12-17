#include "StdAfx.h"
#include "dewar.h"
#include "RobotEpsonSymbal.h"
#include "RobotEpson.h"
#include "xos.h"
#include "log_quick.h"

const float Dewar::m_SquareOfRadius = 250.0f * 250.0f;
const float Dewar::m_Radius = 250.0f;

Dewar::Dewar( ):
	m_CenterX(0.0f),
	m_CenterY(0.0f),
    m_PreviousHeartBeat(0),
    m_pRobotEpson(NULL)
{
	vNull.vt = VT_ERROR;
	vNull.scode = DISP_E_PARAMNOTFOUND;
}

Dewar::~Dewar( )
{
}

bool Dewar::PositionIsInDewar( float x, float y ) const
{
	//calculate the distance from (x, y) to center of dewar
	float delt_x = x - m_CenterX;
	float delt_y = y - m_CenterY;

	float square_of_distance = delt_x * delt_x + delt_y * delt_y;

	return (square_of_distance <= m_SquareOfRadius);
}

void Dewar::Initialize( RobotEpson *pRobotEpson )
{
    m_pRobotEpson = pRobotEpson;
}

Dewar::OpenLidResult Dewar::OpenLid( )
{
	LOG_FINE( "+Dewar::OpenLid" );
#ifdef NO_DEWAR_LID
	LOG_FINE( "-Dewar::OpenLid OK no_lid" );
	return OPEN_LID_OK;
#endif
	if (m_pRobotEpson == NULL)
	{
		LOG_FINE( "-Dewar::OpenLid :m_pRobotEpson == NULL" );
		return OPEN_LID_FAILED;
	}

	int retry = 0;
	const int MAX_LID_RETRY = 3;

	//issue the command
	try
	{
		for (retry = 0; retry < MAX_LID_RETRY; ++ retry)
		{
			m_pRobotEpson->m_pSPELCOM->On( OUT_DEWAR_LID_OPEN, vNull, vNull );

			//wait the status indicator
			if (m_pRobotEpson->WaitSw(
				IN_DEWAR_LID_OPEN,	//which bit
				1,					//what value
				6					//how long to wait (seconds)
				))
			{
				if (m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_CLOSE ))
				{
					LOG_SEVERE( "both dewar lid sensors are high" );
					if (m_pRobotEpson->m_pEventListener)
					{
						m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "both lid sensors are high" );
					}
					LOG_FINE( "-Dewar::OpenLid failed both sensors high" );
					return OPEN_LID_FAILED;
				}

				if (retry != 0)
				{
					if (m_pRobotEpson->m_pEventListener)
					{
						char message[1024] = {0};
						sprintf( message, "open lid ok in retry %d", retry );
						m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
					}
				}

				LOG_FINE( "-Dewar::OpenLid OK" );
				return OPEN_LID_OK;
			}

			LOG_WARNING( "open lid time out, wait longer" );
			if (m_pRobotEpson->m_pEventListener)
			{
				m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "open lid time out, wait longer" );
			}
			if (m_pRobotEpson->WaitSw(
				IN_DEWAR_LID_OPEN,	//which bit
				1,					//what value
				60					//how long to wait (seconds)
				))
			{
				if (m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_CLOSE ))
				{
					LOG_SEVERE( "both dewar lid sensors are high" );
					if (m_pRobotEpson->m_pEventListener)
					{
						m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_SEVERE, "both lid sensors are high" );
					}
					LOG_FINE( "-Dewar::OpenLid failed both sensors high" );
					return OPEN_LID_FAILED;
				}
				LOG_FINE( "-Dewar::OpenLid long time" );
				return OPEN_LID_WARNING_LONG_TIME;
			}
			if (m_pRobotEpson->m_pEventListener)
			{
				char message[1024] = {0};
				sprintf( message, "open lid failed, retrying", (retry + 1) );
				m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
			}
			m_pRobotEpson->m_pSPELCOM->Off ( OUT_DEWAR_LID_OPEN, vNull, vNull );
			m_pRobotEpson->RobotDoEvent( 1000 );
		} //for retry

		LOG_FINE( "-Dewar::OpenLid failed" );
		return OPEN_LID_FAILED;

	}
	catch ( CException *e )
	{
        char errorMessage[255+1] = {0};
		e->GetErrorMessage ( errorMessage,  255);
		e->Delete();
        LOG_WARNING1( "Dewar::OpenLid %s", errorMessage );
		LOG_FINE( "-Dewar::OpenLid failed :exeption" );
		return OPEN_LID_FAILED;
	}
}
bool Dewar::CloseLid( )
{
	LOG_FINE( "+Dewar::CloseLid" );
#ifdef NO_DEWAR_LID
	LOG_FINE( "-Dewar::CloseLid :no_lid" );
	return true;
#endif
	bool success = false;

	if (m_pRobotEpson == NULL)
	{
		LOG_FINE( "-Dewar::CloseLid :m_pRobotEpson == NULL" );
		return false;
	}

	//issue the command
	try
	{
		m_pRobotEpson->m_pSPELCOM->Off ( OUT_DEWAR_LID_OPEN, vNull, vNull );

		//wait the indicator
		success = m_pRobotEpson->WaitSw ( IN_DEWAR_LID_CLOSE,	//bit name
			1,									//which value
			5									//how long to wait (seconds)
			);
        if (!success)
        {
            LOG_WARNING( "Dewar::CloseLid timeout" );
        }
		if (m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_OPEN ))
		{
			LOG_SEVERE( "both dewar lid sensors are high" );
			LOG_FINE( "-Dewar::CloseLid failed both sensors high" );
			return false;
		}
	}
	catch ( CException *e )
	{
        char errorMessage[255+1] = {0};
		e->GetErrorMessage ( errorMessage,  255);
		e->Delete();
        LOG_WARNING1( "Dewar::CloseLid %s", errorMessage );
		return false;
	}

	if (success)
	{
		try
		{
			//reset lid monitor flag
			m_pRobotEpson->m_pSPELCOM->SetSPELVar( "g_LidOpened", COleVariant( long(0) ) );

			//m_PreviousHeartBeat = m_pRobotEpson->m_pSPELCOM->Call( "VBGetIOMHeartBeat" );
			CString tempString2( m_pRobotEpson->m_pSPELCOM->GetSPELVar( "g_IOMCounter" ) );
			sscanf( tempString2, "%ld", &m_PreviousHeartBeat );

		}
		catch ( CException *e )
		{
			char errorMessage[255+1] = {0};
			e->GetErrorMessage ( errorMessage,  255);
			e->Delete();
			LOG_WARNING1( "Dewar::CloseLid %s", errorMessage );
		}
	}

	LOG_FINE1( "-Dewar::CloseLid :result = %d", int(success) );
	return success;
}
Dewar::LidState Dewar::GetLidState( ) const
{
	if (m_pRobotEpson == NULL)
	{
		return UNKNOWN;
	}

	try
	{
		//it has both open and close indicators so
		if (m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_OPEN ) && !m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_CLOSE ))
		{
			return OPEN;
		}
		else if (!m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_OPEN ) && m_pRobotEpson->m_pSPELCOM->Sw( IN_DEWAR_LID_CLOSE ))
		{
			return CLOSE;
		}
		else
		{
			return UNKNOWN;
		}
	}
	catch ( CException *e )
	{
        char errorMessage[255+1] = {0};
		e->GetErrorMessage ( errorMessage,  255);
		e->Delete();
        LOG_WARNING1( "Dewar::GetLidState %s", errorMessage );
		return UNKNOWN;
	}
}

bool Dewar::TurnOnHeater( )
{
	LOG_FINE(" +Dewar::TurnOnHeater" );
	if (m_pRobotEpson == NULL)
	{
		LOG_FINE(" -Dewar::TurnOnHeater NULL" );
		return false;
	}

	//turn on airflow and heater. we did not check status here
	m_pRobotEpson->m_NeedTurnOffHeater = true;

#ifndef SKIP_HEATER
	m_pRobotEpson->m_pSPELCOM->On( OUT_AIRFLOW_ON, vNull, vNull );
	m_pRobotEpson->RobotDoEvent( 1000 );
	m_pRobotEpson->m_pSPELCOM->On( OUT_HEATER_ON, vNull, vNull );

    //no need, this function is never used alone.
    //m_pRobotEpson->SelfPollIOBit( );

#endif

	LOG_FINE(" -Dewar::TurnOnHeater OK" );
	return true;
}

bool Dewar::TurnOffHeater( bool noCheck )
{
	LOG_FINE1(" +Dewar::TurnOffHeater inAbort=%d", (int)noCheck );
	if (m_pRobotEpson == NULL)
	{
		LOG_FINE(" -Dewar::TurnOffHeater NULL" );
		return false;
	}
#ifdef SKIP_HEATER
	LOG_FINE(" -Dewar::TurnOffHeater SKIP" );
	return true;
#else
	if (noCheck)
	{
		m_pRobotEpson->m_pSPELCOM->Off ( OUT_HEATER_ON, vNull, vNull );
		m_pRobotEpson->m_pSPELCOM->Off ( OUT_AIRFLOW_ON, vNull, vNull );
		m_pRobotEpson->m_NeedTurnOffHeater = false;
		LOG_FINE(" -Dewar::TurnOffHeater OK in abort" );
		return true;
	}

	LOG_FINE( "turn off heater with check" );

	//turn off the heater first, leave airflow on
	//then we wait the temperature to low cross a threshold
	//then we turn off the airflow

	bool success = false;

	//turn off the heater
	m_pRobotEpson->m_pSPELCOM->Off ( OUT_HEATER_ON, vNull, vNull );

	//wait the temperature to low
	success = m_pRobotEpson->WaitSw(
		IN_HEATER_TEMPERATURE_HIGH,	//bit name
		0,							//value to wait
		25							//how long to wait(seconds)
		);
    //wait 8 seconds to turn off air
    for (int i = 0; i < 8; ++i)
    {
        if (m_pRobotEpson->m_FlagAbort)
        {
            break;
        }
		m_pRobotEpson->RobotDoEvent( 1000 );
    }
	m_pRobotEpson->m_pSPELCOM->Off ( OUT_AIRFLOW_ON, vNull, vNull );
	m_pRobotEpson->m_NeedTurnOffHeater = false;
    //update IO info
    m_pRobotEpson->SelfPollIOBit( );
	LOG_FINE1(" -Dewar::TurnOffHeater %d", (int)success );
	return success;
#endif
}

bool Dewar::WaitHeaterHot( unsigned long seconds )
{
	LOG_FINE1(" +Dewar::WaitHeaterHot time=%lu", seconds );
	if (m_pRobotEpson == NULL)
	{
		LOG_FINE(" -Dewar::WaitHeaterHot NULL" );
		return false;
	}

#ifdef SKIP_HEATER
	LOG_FINE(" -Dewar::WaitHeaterHot SKIPPED" );
	return true;
#else
    TurnOnHeater( );

	//wait the temperature to rise
	bool result =  m_pRobotEpson->WaitSw(
		IN_HEATER_TEMPERATURE_HIGH,	//bit name
		1,							//value to wait
		seconds     				//how long to wait(seconds)
		);

	/* retry if failed */
	if (!result)
	{
		char message[1024] = {0};
		sprintf( message, "heater did not reach hot in %lu seconds, RETRYING...", seconds );

		if (m_pRobotEpson->m_pEventListener)
		{
			m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
		}
		LOG_WARNING( message );

		for (int retry = 0; retry < 4; ++retry)
		{
			TurnOffHeater( true );
			m_pRobotEpson->RobotDoEvent( 1000 );
			TurnOnHeater( );
			result =  m_pRobotEpson->WaitSw(
				IN_HEATER_TEMPERATURE_HIGH,	//bit name
				1,							//value to wait
				seconds     				//how long to wait(seconds)
				);
			if (result)
			{
				sprintf( message, "heater OK in retry %d", retry + 1 );
				if (m_pRobotEpson->m_pEventListener)
				{
					m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
				}
				break;
			}
		} //for retry

		if (!result)
		{
			strcpy( message, "heater retry FAILED" );
			if (m_pRobotEpson->m_pEventListener)
			{
				m_pRobotEpson->m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_ERROR, message );
			}
		}
		LOG_WARNING( message );
	}

	LOG_FINE1(" -Dewar::WaitHeaterHot %d", (int)result );
	return result;
#endif
}
