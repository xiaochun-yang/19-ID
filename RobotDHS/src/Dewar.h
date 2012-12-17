#pragma once
#include "xos.h"

//we assume all cassettes are uniformly sit on the same circle around dewar center.
//so, we can get dewar center from average of all cassettes center.

//need to access hardware for lid openning/closing and status
class RobotEpson;

class Dewar
{
public:
	enum LidState
	{
		UNKNOWN,
		OPEN,
		CLOSE
	};

    enum OpenLidResult
    {
        OPEN_LID_FAILED,
        OPEN_LID_OK,
        OPEN_LID_WARNING_LONG_TIME
    };

	Dewar( );
	~Dewar( );

	//check wether point(x,y) is within dewar
	bool PositionIsInDewar( float x, float y ) const;

	//must call this before call Lid and Heater
	void Initialize( RobotEpson *pRobotEpson );

	//lid: may be time consuming
	OpenLidResult OpenLid( );
	bool CloseLid( );
	LidState GetLidState( ) const;

	//heater
	bool TurnOnHeater( );
	bool TurnOffHeater( bool noCheck = false );

    bool WaitHeaterHot( unsigned long seconds = 60 ); 

private:

	float m_CenterX;
	float m_CenterY;
    mutable long m_PreviousHeartBeat;
	//we do not care Z of Dewar
    RobotEpson*  m_pRobotEpson;

	static const float m_SquareOfRadius;
    static const float m_Radius;

	//dummy just to simplify writing.
	COleVariant vNull;

};
