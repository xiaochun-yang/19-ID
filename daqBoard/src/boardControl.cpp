//
#include "stdafx.h"

#include <signal.h>
#include "Registry.h"
#include "log_quick.h"
#include "DcsConfig.h"
#include "boardSystem.h"

#include "boardControl.h"

BEGIN_MESSAGE_MAP(boardControl, CWinApp)
END_MESSAGE_MAP()

boardSystem *gpSystem = NULL;

static void ctrl_c_handler( int )
{
	if (gpSystem) gpSystem->OnStop( );
}

//a global function to call if something severe happen and service needs to be stopped.
void boardSystemStop( void )
{
	if (gpSystem) gpSystem->OnStop( );
}
// The one and only application object
boardControl theApp;

boardControl::boardControl()
{
}

BOOL boardControl::InitInstance()
{
    DWORD result = 0;
    xos_socket_library_startup( );
	//open trace
	LOG_QUICK_OPEN_WITH_NAME( "boardControl" );


	{
		//need load config before instantiate the system.
		DcsConfig& dcsConfig(DcsConfigSingleton::GetDcsConfig( ));
		dcsConfig.setConfigDir( "\\dcs\\dcsconfig\\data" );

		if (m_lpCmdLine[0] == _T('\0')) {
			LOG_INFO( "get service parameters" );
			CRegistry winRegistry;

			winRegistry.SetRootKey( HKEY_LOCAL_MACHINE );
			if (winRegistry.SetKey("SYSTEM\\CurrentControlSet\\Services\\daqBoard", FALSE ))
			{
				CString config_dir = winRegistry.ReadString ( "dcsconfig_dir", "" );
				if (config_dir != "") {
					dcsConfig.setConfigDir( std::string( config_dir ) );
					LOG_INFO1( "use %s as dcsconfig dir", (const char*)config_dir );
				}

				CString param = winRegistry.ReadString ( "parameters", "" );

				if (param != "") {
					LOG_INFO1( "use service arguments %s", (const char*)param );
					dcsConfig.setConfigRootName( std::string( param ) );
				} else {
					LOG_SEVERE( "NOT BEAMLINE in command argument or service argument" );
					return FALSE;
				}
			}
			else
			{
				LOG_SEVERE( "NOT BEAMLINE in command argument or service argument" );
				return FALSE;
			}			
		} else {
			LOG_INFO1( "use command line %s", m_lpCmdLine );
			dcsConfig.setConfigRootName( m_lpCmdLine );
		}

		bool configLoadOK = dcsConfig.load( );

		// Create the service object
	    boardSystem *mySys = boardSystem::getInstance();
		gpSystem = mySys;
    
		// Parse for standard arguments (install, uninstall, version etc.)
        if (!mySys->ParseStandardArgs( m_lpCmdLine )) {
			// Didn't find any standard args so start the service
			if (configLoadOK) {
				// Uncomment the DebugBreak line below to enter the debugger
				// when the service is started.
				//DebugBreak();
				LOG_FINEST( "wait to see if we run as a service" );
				if (!mySys->StartService())
				{
					LOG_FINEST( "OK, we run not in service, but as a front process" );
					//must be running at front.
					//setup ctl+C to act as stop signal
					signal( SIGINT, ctrl_c_handler );

					//run from front
					mySys->RunFront( );
				}
			} else {
				LOG_SEVERE( "failed to load config" );
			}
		}

		result = mySys->GetExitCode( );
    }

	LOG_QUICK_CLOSE;
    // When we get here, the service has been stopped
    xos_socket_library_cleanup( );

	return FALSE;
}