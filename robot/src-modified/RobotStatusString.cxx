//#include "StdAfx.h"
#include "RobotStatusString.h"

#define MY_CLEAR( a ) memset( a, 0, sizeof(a) )
#define WRAP_STRING( a, b, c ) \
    strcpy( a, b ); \
    strcat( a, " {" ); \
    strncat( a, c, (sizeof(a) - strlen(a) - 2 ) );\
    strcat( a, "}" )
RobotStatusString::RobotStatusString( )
{
    strcpy( m_Status,  "status: 0 need_reset: 0 need_cal: 0" );
    strcpy( m_State,   " state: self-testing" );
    strcpy( m_Warning, " warning: {}" );
    strcpy( m_CalMsg,  " cal_msg: {}" );
    strcpy( m_CalStep, " cal_step: {0 of 100}" );
    strcpy( m_Mounted, " mounted: {}" );
    strcpy( m_NumPinLost, " pin_lost: 0" );
    strcpy( m_NumPinMounted, " pin_mounted: 0" );
    strcpy( m_StatusInManual, " manual_mode: 0" );
    strcpy( m_StatusNeedTLCAL, " need_mag_cal: 0" );
    strcpy( m_StatusNeedCASCAL, " need_cas_cal: 0" );
    strcpy( m_StatusNeedClear, " need_clear: 0" );
    MY_CLEAR( m_WholeString );
}
void RobotStatusString::SetStatus( RobotStatus status )
{
    int need_reset = (status & FLAG_NEED_RESET) ? 1 : 0;
    int need_cal  = (status & FLAG_NEED_CAL_ALL) ? 1 : 0;

    sprintf( m_Status, "status: %lu need_reset: %d need_cal: %d", status, need_reset, need_cal );

    if (status & FLAG_IN_MANUAL)
    {
        strcpy( m_StatusInManual, " manual_mode: 1" );
    }
    else
    {
        strcpy( m_StatusInManual, " manual_mode: 0" );
    }

    if (status & FLAG_NEED_CAL_MAGNET)
    {
        strcpy( m_StatusNeedTLCAL, " need_mag_cal: 1" );
    }
    else
    {
        strcpy( m_StatusNeedTLCAL, " need_mag_cal: 0" );
    }

	if (status & FLAG_NEED_CAL_CASSETTE)
    {
        strcpy( m_StatusNeedCASCAL, " need_cas_cal: 1" );
    }
    else
    {
        strcpy( m_StatusNeedCASCAL, " need_cas_cal: 0" );
    }

	if (status & FLAG_NEED_CLEAR)
    {
        strcpy( m_StatusNeedClear, " need_clear: 1" );
    }
    else
    {
        strcpy( m_StatusNeedClear, " need_clear: 0" );
    }
}
void RobotStatusString::SetState( const char state[] )
{
    WRAP_STRING( m_State, " state:", state );
}
void RobotStatusString::SetWarning( const char message[] )
{
    WRAP_STRING( m_Warning, " warning:", message );
}
void RobotStatusString::SetCalibrationMessage( const char message[] )
{
    WRAP_STRING( m_CalMsg, " cal_msg:", message );
}
void RobotStatusString::SetCalibrationStep( const char step[] )
{
    WRAP_STRING( m_CalStep, " cal_step:", step );
}
void RobotStatusString::SetMounted( const char port[] )
{
    WRAP_STRING( m_Mounted, " mounted:", port );
}
void RobotStatusString::SetPinLost( const char number[] )
{
    WRAP_STRING( m_NumPinLost, " pin_lost:", number );
}
void RobotStatusString::SetPinMounted( const char number[] )
{
    WRAP_STRING( m_NumPinMounted, " pin_mounted:", number );
}

const char* RobotStatusString::GetStatusString( ) const
{
    strcpy( m_WholeString, m_Status );
    strcat( m_WholeString, m_State );
    strcat( m_WholeString, m_Warning );
    strcat( m_WholeString, m_CalMsg );
    strcat( m_WholeString, m_CalStep );
    strcat( m_WholeString, m_Mounted );
    strcat( m_WholeString, m_NumPinLost );
    strcat( m_WholeString, m_NumPinMounted );
    strcat( m_WholeString, m_StatusInManual );
    strcat( m_WholeString, m_StatusNeedTLCAL );
    strcat( m_WholeString, m_StatusNeedCASCAL );
    strcat( m_WholeString, m_StatusNeedClear );

    return m_WholeString;
}
