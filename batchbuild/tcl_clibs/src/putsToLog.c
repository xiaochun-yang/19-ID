#include <tcl.h>
#include <log_quick.h>

bool isLoggingDirectoryWritable(char * logFilePattern);
bool isDirectoryWritable( const char * dirpath );

static log_manager_t* log_manager = NULL;
static log_handler_t* file_handler = NULL;
static log_handler_t* stdout_handler = NULL;
static log_handler_t* udp_handler = NULL;
static log_formatter_t* trace_formatter = NULL;

extern "C" int putsToLog( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    const char dummy[2] = {0};
    const char* pMsg = dummy;
    const char* pFile = dummy;
    int line = 0;

    if (objc < 2)
    {
        return TCL_OK;
    }
    pMsg = Tcl_GetString( objv[1] );
    if (objc >=3)
    {
        pFile = Tcl_GetString( objv[2] );
    }
    if (objc >=4)
    {
        if (Tcl_GetIntFromObj( interp, objv[3], &line ) != TCL_OK)
        {
            line = 0;
        }
    }

    //LOG_INFO( pMsg );
    info_details( pFile, line, dummy, dummy, gpDefaultLogger, pMsg );

    return TCL_OK;
}
extern "C" int initPutsLogger( ClientData cdata, Tcl_Interp* interp, int objc, Tcl_Obj *CONST objv[] )
{
    if (objc != 8)
    {
        Tcl_WrongNumArgs( interp, 1, objv, "application-name file-pattern file-size num-files level stdout(true/false) append(true/false)" );
        return TCL_ERROR;
    }

    char* pAppName = Tcl_GetString( objv[1] );
    char* pFilePattern = Tcl_GetString( objv[2] );
    char* pFileSize = Tcl_GetString( objv[3] );
    char* pNumFiles = Tcl_GetString( objv[4] );
    char* pLevel = Tcl_GetString( objv[5] );
    char* pStdout = Tcl_GetString( objv[6] );
    char* pAppend = Tcl_GetString( objv[7] );

	bool isStdout = true;
	int fileSize = 31457280;
	int numFiles = 3;
	bool append = false;

	log_level_t* logLevel = NULL;
//	log_level_t* logLevel = log_level_parse( pLevel );
 //   printf("set log level");
 //   return 0;

	if (logLevel == NULL)
		logLevel = LOG_ALL;
	logger_set_level(gpDefaultLogger, logLevel);
	
	if ( strcmp( pStdout, "false") == 0 ) isStdout = false;
	if ( strcmp( pStdout, "true") == 0 ) isStdout = true;
	if ( strcmp( pAppend, "false") == 0 ) append = false;
	if ( strcmp( pAppend, "true") == 0 ) append = true;
	
    //printf("set fileSize name %s", pFileSize);
    sscanf( pFileSize, "%d", &fileSize);
    sscanf( pNumFiles, "%d", &numFiles);
    //printf("set fileSize %d", fileSize);

    g_log_init();

    if (objc < 2)
    {
        return TCL_OK;
    }

    log_manager = g_log_manager_new(NULL);
    gpDefaultLogger = g_get_logger(log_manager, pAppName, NULL, LOG_ALL);
    
    trace_formatter = log_trace_formatter_new( );

    //open stdout if not in daemon mode
    if (getppid( ) != 1 && isStdout)
    {
        stdout_handler = g_create_log_stdout_handler();
        if (stdout_handler != NULL) {
            log_handler_set_level(stdout_handler, LOG_ALL);
            log_handler_set_formatter(stdout_handler, trace_formatter);
            logger_add_handler(gpDefaultLogger, stdout_handler);
        }
    }

	if ( ! isLoggingDirectoryWritable(pFilePattern) ) {
        Tcl_SetResult( interp, "logging directory not writable", TCL_STATIC );
        return TCL_ERROR;
    }
	
	file_handler = g_create_log_file_handler( pFilePattern, append, fileSize, numFiles);
   if (file_handler != NULL) {
		log_handler_set_level(file_handler, logLevel);
		log_handler_set_formatter(file_handler, trace_formatter);
		logger_add_handler(gpDefaultLogger, file_handler);
	}

    Tcl_SetResult( interp, "logging initialized", TCL_STATIC );
	return TCL_OK;
}



bool isLoggingDirectoryWritable(char * logFilePattern) {
	
	char * lastSlashPtr = strrchr(logFilePattern,'/');
	
	if (lastSlashPtr == (char *)null) {
		LOG_SEVERE1("Logging directory needs full path: %s", logFilePattern);
		return false;
	}
	
	int lastSlash=lastSlashPtr - logFilePattern + 1;
	char logDirectory[500];
	strncpy(logDirectory,logFilePattern,lastSlash);
	logDirectory[lastSlash]=0x00;
	
	if ( !isDirectoryWritable( logDirectory )) {
		LOG_SEVERE1("Cannot write to logging directory: %s", logDirectory);
		return false;
	}
	
	return true;
}

bool isDirectoryWritable( const char * dirpath ) {
    return access( dirpath, W_OK )?false:true;
}


