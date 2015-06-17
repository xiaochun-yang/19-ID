#pragma once
#include "robot.h"

class RobotStatusString
{
public:
    RobotStatusString( );
    ~RobotStatusString( ) { }

    void SetStatus( RobotStatus status );
    
	void SetState( const char state[] );
	const char* GetState( ) const { return m_State; }

    void SetWarning( const char message[] );
    void SetCalibrationMessage( const char message[] );
    void SetCalibrationStep( const char step[] );
    void SetMounted( const char port[] );
    void SetPinLost( const char number[] );
    void SetPinMounted( const char number[] );

    const char* GetStatusString( ) const;
private:
    char m_Status[256];
    char m_State[256];  //512
    char m_Warning[512]; //1024
    char m_CalMsg[256];  //1280
    char m_CalStep[32];     //1312
    char m_Mounted[32];     //1346
    char m_NumPinLost[32];  //1358
    char m_NumPinMounted[32];  //1390
    char m_StatusInManual[32];   //1422
    char m_StatusNeedTLCAL[32];   //1454
    char m_StatusNeedCASCAL[32];   //1486
    char m_StatusNeedClear[32];   //1518

    mutable char m_WholeString[2048];
};
