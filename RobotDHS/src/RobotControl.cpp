// RobotControl.cpp : implementation file
//
#include <signal.h>

#include "stdafx.h"
#include "RobotControl.h"
#include "log_quick.h"
#include "xos_socket.h"
#include "robotSystem.h"

BEGIN_MESSAGE_MAP(RobotControl, CWinApp)
END_MESSAGE_MAP()




//used by signal handler to simulate STOP by Ctl-C
static CRobotSystem* gpSystem = NULL;	

static void ctrl_c_handler( int )
{
	if (gpSystem) gpSystem->OnStop( );
}

//a global function to call if something severe happen and service needs to be stopped.
void robotSystemStop( void )
{
	if (gpSystem) gpSystem->OnStop( );
}
// The one and only application object
RobotControl theApp;

// RobotControl
RobotControl::RobotControl()
{
}

BOOL RobotControl::InitInstance()
{
    DWORD result = 0;
    xos_socket_library_startup( );
	//open trace
	LOG_QUICK_OPEN_WITH_NAME( "RobotEpson" );


	{
		// Create the service object
		CRobotSystem robotSystem;
		gpSystem = &robotSystem;
    
		// Parse for standard arguments (install, uninstall, version etc.)
        if (m_lpCmdLine[0] == _T('\0') || !robotSystem.ParseStandardArgs( m_lpCmdLine )) {

			// Didn't find any standard args so start the service
			// Uncomment the DebugBreak line below to enter the debugger
			// when the service is started.
			//DebugBreak();
            LOG_FINEST( "wait to see if we run as a service" );
			if (!robotSystem.StartService())
			{
                LOG_FINEST( "OK, we run not in service, but as a front process" );
				//must be running at front.
				//setup ctl+C to act as stop signal
				signal( SIGINT, ctrl_c_handler );

				//run from front
				robotSystem.RunFront( );
			}
		}

		result = robotSystem.GetExitCode( );
    }

	LOG_QUICK_CLOSE;
    // When we get here, the service has been stopped
    xos_socket_library_cleanup( );

	return FALSE;
}