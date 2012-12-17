#ifndef ROBOTSERVER_H
#define ROBOTSERVER_H

#include "CreateOperation.h"
#include "robot.h"

class RobotServer : public CreateOperation {

//members:
public:

	Robot m_Robot;

private:

	CEvent *p_StartMsgThrdEvnt, *p_RunQuitEvnt, *p_MonitorQuitEvnt;

	CRegistry m_CRegistry;

//methods:
private:

	void SetOperations ( void );
	
	static UINT Run ( LPVOID );

	UINT Run_thread ( void );

	static UINT Monitor ( LPVOID );

	UINT Monitor_thread ( void );

	void Delay ( DWORD );

	void DoEvents ( );

public:

	RobotServer ( );

	~RobotServer ( );

	virtual DcsMessage* CreateMessage ( const DcsMessage& );

};

#endif

