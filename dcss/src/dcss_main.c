/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

/* local include files */
#include <tcl.h>
#include "xos.h"
#include <termios.h>

#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <signal.h>
#include <unistd.h>
#include <pwd.h>

#include "xos_socket.h"
#include "dcss_client.h"
#include "dcss_gui_client.h"
#include "dcss_database.h"
#include "dcss_broadcast.h"
#include "dcss_hardware_client.h"
#include "dcss_device.h"
#include "dcss_collect.h"
#include "wedge.h"
#include "dcss_users.h"
#include "dcss_scripting.h"
#include "DcsConfig.h"
#include "XosStringUtil.h"
#include "XosException.h"
#include "AuthClient.h"
#include "log_quick.h"
#include "loglib_quick.h"
#include "logger.h"
#include "SSLCommon.h"

/* prototypes for functions called by main */
void start_server ( void );
void restore_database ( char * filename );
void dump_database ( char * filename );
void dump_database_for_epics ( char * filename );

//global data
std::string gRequestedBeamlineId;
std::string gBeamlineId;
std::string gLockFileName;
std::string gOutputFileName;
std::string gDefaultUserName;
std::string gUserHomeDir;

std::string gAuthHost;
int         gAuthPort = 0;
bool        gAuthUseSSL = false;

// to make sure self client connect first
xos_semaphore_t gSemSelfClient;
volatile bool   gSelfClientReady = false;

//currently they are the same
static const device_permit_t defaultUserPermit =  {1, 1, 1, 1, 0};
static const device_permit_t defaultStaffPermit = {1, 1, 1, 1, 0};

FILE* gLockFileHandle = NULL;

// Global config
// Uses default config repository set by XosConfig.
DcsConfig gDcssConfig;
double gCircularMotorRange = 0;

//better use host and port from config to construct
AuthClient* gpDefaultUser = NULL;
char gSessionID[4096] = {0};

static log_manager_t* log_manager = NULL;
static log_handler_t* file_handler = NULL;
static log_handler_t* stdout_handler = NULL;
static log_handler_t* udp_handler = NULL;
static log_formatter_t* trace_formatter = NULL;

/* reading dumpfile buffer */
static char dumpFileSection[MAX_NUM_LINE][MAX_LINE_SIZE] = {0};
static int numLineForSection = 0;

static int stringIsPrintable( const char* pString );
static void trimString( char* pString );
static int stringIsPermit( const char *pString );
static int readOneSectionFromDumpfile( FILE* dumpFile );

void initLogging();
void cleanupLogging();
static int  getDefaultUserSessionID( void );

static void handleSignal( int sig_num, siginfo_t *sig_info, void *user_data );

validate_status_t validateSession(user_account_data_t* user, bool isDcssUser);
void initAuthInfo( );
bool initConfig();
bool checkBeamlineId();

/* used too many places to put it into a function */
static void readDevicePermit( generic_device_t *pDevice, int startLine );
static void readHostAndLocalName( generic_device_t *pDevice, const char* pString );

/**
 * Data for controlling the db dump thread.
 */
class DbDumpControlData
{
public:
        
    /**
     * Constructor
     */
    DbDumpControlData()
        : file("db.dump"), 
          sleepMsec(5000)
    {
    }
    
    /**
     * Must sleep at least 1 second
     */
    void setRate(int r)
    {
        sleepMsec = r;
        
        if (sleepMsec < 1000)
            sleepMsec = 1000;
    }
    
    /** 
     */
    int getRate() const
    {
        return sleepMsec;
    }
    
    /**
     */
    std::string getDir() const
    {
        
        size_t pos = 0;
        for (size_t i = 0; i < file.size(); ++i) {
            if (file[i] == '/')
                pos = i;
        }
        
        if (pos < file.size())
            return file.substr(0, pos);
            
        return ".";
    }
    
    
    /**
     * Default file name is db.dump
     */
    void setFilePath(const std::string& f)
    {
        file = f;
        
        if (file.empty())
            file = "db.dump";
    }
    
    /**
     */
    std::string getFilePath() const
    {
        return file;
    }
    
    /**
     */
    std::string getFileName() const
    {
        
        size_t pos = 0;
        for (size_t i = 0; i < file.size(); ++i) {
            if (file[i] == '/')
                pos = i;
        }
        
        if (pos < file.size())
            return file.substr(pos);
            
        return file;
    }
            
private:

    std::string file;
    int sleepMsec;

};

XOS_THREAD_ROUTINE db_dump_thread_routine(DbDumpControlData* data);
XOS_THREAD_ROUTINE dcss_database_flush_thread_routine( void * wait_period );

/****************************************************************
    main:  This function serves to multiplex the functionality
    of the blserver program depending on the command line options
    given.  It can start the server (-s), dump the current
    database (-d), or read in a new database (-r).
****************************************************************/ 
static void printUsage()
{
    printf("\tUsage:\n");        
    printf("\tdcss <beamlineID> -s [-b]          -- starts server [background]\n");
    printf("\tdcss <beamlineID> -s username [-b] -- starts server with username\n");
    printf("\tdcss <beamlineID> -d dumpfile      -- dumps database to dumpfile\n" );
    printf("\tdcss <beamlineID> -d -             -- dumps database to stdout\n" );
    printf("\tdcss <beamlineID> -r dumpfile      -- restores database from dumpfile\n" );
    printf("\tdcss <beamlineID> -r -             -- restores database from stdin\n" );
}

int main( int argc, char *argv[] )
{
    // Expect at least 3 arguments
    if (argc < 3) {
        printUsage();
        exit(1);
    }

    gRequestedBeamlineId = argv[1];

    if (gRequestedBeamlineId[0] == '-') {
        printf("%s is not a valid beamline name\n", argv[1]);
        printUsage();
        exit(1);
    }
    int i;
    bool serverMode = false;
    bool backgroundMode = false;
    for (i = 2; i < argc; ++i)
    {
        if (strcmp( argv[i], "-s" ) == 0)
        {
            serverMode = true;
            if (i < argc - 1)
            {
                if (argv[i+1][0] != '-')
                {
                    gDefaultUserName = argv[i+1];
                }
            }
        }
        if (strcmp( argv[i], "-b" ) == 0)
        {
            backgroundMode = true;
        }
    }

    if (serverMode && backgroundMode)
    {
        restart_in_daemon( argc, argv );
    }

    // Make sure no other dcss is running for this beamline.
	gLockFileName = "/tmp/dcss_" + gRequestedBeamlineId + ".lock";
    gLockFileHandle = checkLockFile( gLockFileName.c_str() );
    if (gLockFileHandle == NULL) {
        printf( "quit\n");
        return -1;
    }
    printf( "check log file passed\n" );

    /* setup signal handling */
    {
        struct sigaction sa;
        sa.sa_sigaction = handleSignal;
        sa.sa_flags = 0;

        if (sigaction( SIGHUP, &sa, NULL ))
        {
            printf( "setup signal handleer failed\n" );
            return -1;
        }

        if (serverMode && backgroundMode)
        {
            sa.sa_sigaction = NULL;
            sa.sa_handler = SIG_IGN;

            //needed for tcl exec
            //sigaction( SIGCHLD, &sa, NULL );

            sigaction( SIGHUP,  &sa, NULL );
            sigaction( SIGTSTP, &sa, NULL );
            sigaction( SIGTTOU, &sa, NULL );
            sigaction( SIGTTIN, &sa, NULL );
        }
    }

    try {
        initLogging();

        // Must be called before reading or writing the database 
        // memory map file.
        if (!initConfig()) {
            LOG_SEVERE("Failed to initialize config\n");
            exit(1);
        }

        if (serverMode)
        {
            Tcl_FindExecutable( argv[0] );
            start_server( );
            return 0;
        } else if (strcmp(argv[2], "-r") == 0) {
            if (argc != 4) {
                printUsage();
                exit(1);
            }
            restore_database(argv[3]);
        } else if (strcmp(argv[2], "-d") == 0) {
            if (argc != 4) {
                printUsage();
                exit(1);
            }
            dump_database(argv[3]);
        } else if (strcmp(argv[2], "-de") == 0) {
            if (argc != 4) {
                printUsage();
                exit(1);
            }
            dump_database_for_epics(argv[3]);
        } else {
            printUsage();
        }                    
            
        cleanupLogging();
    } catch (XosException& e) {
        LOG_SEVERE(e.getMessage().c_str());
        exit(1);
    } catch (...) {
        LOG_SEVERE("Caught unknown error");
        exit(1);
    }
    
    /* report success if called functions return */
    return 0;
}

/****************************************************************
 *
 * initLogging
 *
 ****************************************************************/
void initLogging()
{
    g_log_init();


    log_manager = g_log_manager_new(NULL);
    gpDefaultLogger = g_get_logger(log_manager, "dcss", NULL, LOG_ALL);
    
    
    trace_formatter = log_trace_formatter_new( );

    //open stdout if not in daemon mode
    if (getppid( ) != 1)
    {
        stdout_handler = g_create_log_stdout_handler();
        if (stdout_handler != NULL) {
            log_handler_set_level(stdout_handler, LOG_ALL);
            log_handler_set_formatter(stdout_handler, trace_formatter);
            logger_add_handler(gpDefaultLogger, stdout_handler);
        }
    }
}

/****************************************************************
 *
 * setLogging
 *
 ****************************************************************/
bool updateLogging()
{
    std::string level;
    bool isStdout = true;
    std::string udpHost;
    int udpPort = 0;
    std::string filePattern;
    int fileSize = 31457280;
    int numFiles = 3;
    bool append = false;
    
    
    std::string tmp;
    if (!gDcssConfig.get("dcss.logStdout", tmp)) {
        LOG_WARNING("Could not find dcss.logStdout in config file\n");
        return false;
    }
        
    if (tmp == "false")
        isStdout = false;
        
    
    if (!gDcssConfig.get("dcss.logUdpHost", tmp)) {
        LOG_WARNING("Could not find dcss.logUdpHost in config file\n");
        return false;
    }
        
    if (!gDcssConfig.get("dcss.logUdpPort", tmp)) {
        LOG_WARNING("Could not find dcss.logUdpPort in config file\n");
        return false;
    }
        
    if (!tmp.empty())
        udpPort = XosStringUtil::toInt(tmp, udpPort);
        
    
    if (!gDcssConfig.get("dcss.logFilePattern", filePattern)) {
        LOG_WARNING("Could not find dcss.logFilePattern in config file\n");
        return false;
    }
    filePattern = XosStringUtil::trim(filePattern, " \n\r\t");
    
    if (!gDcssConfig.get("dcss.logFileSize", tmp)) {
        LOG_WARNING("Could not find dcss.logFileSize in config file\n");
        return false;
    }
    
    if (!tmp.empty())
        fileSize = XosStringUtil::toInt(tmp, fileSize);

    if (!gDcssConfig.get("dcss.logFileMax", tmp)) {
        LOG_WARNING("Could not find dcss.logFileMax in config file\n");
        return false;
    }
    
    if (!tmp.empty())
        numFiles = XosStringUtil::toInt(tmp, numFiles);

    if (!gDcssConfig.get("dcss.logLevel", level)) {
        LOG_WARNING("Could not find dcss.logLevel in config file\n");
        return false;
    }
    

    log_level_t* logLevel = log_level_parse(level.c_str());
    
    if (logLevel == NULL)
        logLevel = LOG_ALL;

    logger_set_level(gpDefaultLogger, logLevel);
    
    // Turn off stdout log
    if (!isStdout && stdout_handler) {
        printf("Turning off stdout log\n");
        logger_remove_handler(gpDefaultLogger, stdout_handler);
    }
        
    if (!udpHost.empty() && (udpPort > 0)) {
        udp_handler = log_udp_handler_new(udpHost.c_str(), udpPort);
        if (udp_handler != NULL) {
            log_handler_set_level(udp_handler, logLevel);
            log_handler_set_formatter(udp_handler, trace_formatter);
            logger_add_handler(gpDefaultLogger, udp_handler);
        }
    }
        
    
    if (!filePattern.empty()) {
        file_handler = g_create_log_file_handler(filePattern.c_str(), append, fileSize, numFiles);
        if (file_handler != NULL) {
            log_handler_set_level(file_handler, logLevel);
            log_handler_set_formatter(file_handler, trace_formatter);
            logger_add_handler(gpDefaultLogger, file_handler);
        }
    }

//        log_include_modules(LOG_AUTH_CLIENT_LIB | LOG_HTTP_CPP_LIB);
        log_include_modules(LOG_AUTH_CLIENT_LIB);

    return true;
    
}

/****************************************************************
 *
 * cleanupLogging
 *
 ****************************************************************/
void cleanupLogging()
{
    g_logger_free(log_manager, gpDefaultLogger);

    if (stdout_handler)
    {
        log_handler_free(stdout_handler);
    }
    log_handler_free(udp_handler);
    log_handler_free(file_handler);

    log_formatter_free(trace_formatter);

    g_log_manager_free( log_manager );

    g_log_clean_up();
}

/****************************************************************
 *
 * initConfig
 * Must be called before the database map is read.
 *
 ****************************************************************/
bool initConfig()
{
    
    // Assume that the we are running dcss in dcs/dcss/$MACHINE dir
    gDcssConfig.setConfigRootName(gRequestedBeamlineId);
    
    
    if (!gDcssConfig.load()) {
        LOG_SEVERE1("Failed to load config from %s\n", gDcssConfig.getConfigFile().c_str());
        return false;
    }
        
    
    if (!updateLogging()) {
        LOG_WARNING("Invalid log config for dcss. Use default setting.\n");
        return false;
    }

    gCircularMotorRange = gDcssConfig.getInt( "motor.circular.reset_range", 0 );
    
    return true;
    
}


/****************************************************************
 * Make sure that the requested beamline id passed in as the first 
 * commandline argument is the same as the beamlineID found in the 
 * database. 
 ****************************************************************/
bool checkBeamlineId()
{
    // Get beamline ID
    int deviceNumber = get_device_number("beamlineID");
    if (deviceNumber < 1) {
        LOG_SEVERE("Failed to get beamlineID from database.dat\n");
        return false;
    }
    beamline_device_t* device = acquire_device(deviceNumber);
    if (device == NULL) {
        LOG_SEVERE("Invalid beamlineID from database.dat\n");
        return false;
    }
    
    gBeamlineId = XosStringUtil::trim(device->string.contents);
        
    
    if (release_device(deviceNumber) != XOS_SUCCESS) {
        LOG_SEVERE("Failed to release mutex for beamlineID device\n");
        return false;    
    }
    

    // Make sure the the beamlineID in database map file
    // is the same as the requested beamline passed in as the first 
    // commandline argument.
    if (gBeamlineId != gRequestedBeamlineId) {
        LOG_SEVERE2("beamlineID found in database is %s (expected %s)",
                gBeamlineId.c_str(), gRequestedBeamlineId.c_str());
        return false;
    }    

    LOG_INFO1("beamline = %s\n", gBeamlineId.c_str());
    return true;
}

    


/****************************************************************
    start_server:  Initializes run-time data and starts threads
    to handle incoming client connections and outgoing broadcasts.
****************************************************************/

void start_server( void )
    {
    xos_thread_t    listeningThread;
    xos_thread_t    hardwareThread;
    xos_thread_t    broadcastThread;
    xos_thread_t    privilegeThread;
    xos_thread_t    dbDumpThread;
    xos_thread_t    databaseFlushThread;
    char hostname[200];
    
    try {
        loadDCSSCertificate( gDcssConfig.getDcssCertificate( ).c_str( ) );

        std::string pkFN = gDcssConfig.getDcsRootDir( ) + "/dcss/.pki/"
        + gDcssConfig.getConfigRootName( ) + ".key";

        LOG_FINE1( "loading private key from %s", pkFN.c_str( ) );
        loadDCSSPrivateKey( pkFN.c_str( ), NULL );
        if (dcssPKIReady( )) {
            char plain[128] = "123456789012345678901234567890";
            char cypher[4096] = {0};
            char recovered[128] = {0};

            encryptSID( cypher, sizeof(cypher), plain );
            decryptSID( recovered, sizeof(recovered), cypher );

            if (strcmp( plain, recovered )) {
                LOG_SEVERE( "DCSS certificate does not match private key" );
                exit( -1 );
            }
        }
    } catch (XosException& e) {
        LOG_WARNING( "failed to load DCSS certificate or private key" );
        LOG_WARNING( "will run in unsecured mode" );
    }

    
    server_socket_definition_t serverSocket[3];

    //Get the system name
    if ( gethostname(hostname,100) == -1)
        {
        LOG_SEVERE("main -- The local hostname is unknown\n");
        exit(1);
        }
        

    /* startup socket library */
    if ( xos_socket_library_startup() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error initializing socket library\n");
        exit(1);
    }

        /* initialize the device database index*/
    if ( initialize_database_index() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error initializing database indices\n");
        exit(1);
    }
    if (xos_thread_create( &databaseFlushThread, dcss_database_flush_thread_routine, (void*)1000 ) != XOS_SUCCESS)
    {
        LOG_SEVERE("start_server -- error initializing database flush thread\n");
        exit(1);
    }

    //change the title bar for convenience.
    printf("\033]2;dcss %s on %s\07", gRequestedBeamlineId.c_str(), hostname);

     if (!checkBeamlineId()) {
        exit(1);
    }
    
    
    // Init 
    initAuthInfo( );


    LOG_INFO1("Loaded config from file %s\n", gDcssConfig.getConfigFile().c_str());
    LOG_INFO3("Starting Servers: scripting engine port = %d hardware port = %d gui port = %d\n", 
              gDcssConfig.getDcssScriptPort(),
              gDcssConfig.getDcssHardwarePort(),
              gDcssConfig.getDcssGuiPort()); fflush(stdout);

    LOG_INFO2("imperson host = %s, port = %d\n", 
                gDcssConfig.getImpersonHost().c_str(),
                gDcssConfig.getImpersonPort());
                
    LOG_INFO4("imgsrv host = %s, guiPort = %d, webPort = %d, httpPort = %d\n", 
                gDcssConfig.getImgsrvHost().c_str(),
                gDcssConfig.getImgsrvGuiPort(),
                gDcssConfig.getImgsrvWebPort(),
                gDcssConfig.getImgsrvHttpPort());
                
    
    //try to get default user session id
    if (!getDefaultUserSessionID( )) {
        LOG_SEVERE("start_server -- error try to get default user session id\n");
        exit(1);
    }
    updateLockFile( gLockFileHandle );

    if ( initialize_gui_command_tables() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error intitializing gui command tables\n");
        exit(1);
    }

    LOG_INFO ("Initiliaze gui client\n");
    /* initialize the gui client list */ 
    if ( initialize_gui_client_list() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error initializing gui client list\n"); 
        exit(1);
    }
    
    LOG_INFO ("initialize master client data\n");
    /* initialize  master client data */
    if ( initialize_master_gui_data() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error initializing master client data\n"); 
        exit(1);
    }
        
    LOG_INFO ("Initialize hardware client\n");
    /* initialize the hardware client list */
    if ( initialize_hardware_client_list() != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error initializing hardware client list\n");
        exit(1);
    }

    LOG_INFO ("Initialize broadcast thread\n");
    /* create a thread to handle broadcasts to all GUIs */
    if ( xos_thread_create( &broadcastThread, 
                        (xos_thread_routine_t*)gui_broadcast_handler, 
                        NULL ) != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error creating broadcast thread\n");
        exit(1);
    }

    //should use a semaphore here, wait for the broadcast handler to set up its port
    xos_thread_sleep(500);
    //
    if ( connect_to_broadcast_handler() != XOS_SUCCESS ) 
        {
        LOG_SEVERE("start_server: error connecting to broadcast thread\n");
        exit(1);
        }

    LOG_INFO ("Initializing permitted user table\n");
    if ( initialize_session_cache() == XOS_FAILURE )
        {
        LOG_SEVERE("start_server -- error creating permitted user table\n");
        exit(1);
        }


    /* create a thread to load the permitted user table */
    if ( xos_thread_create( &privilegeThread,
                                    (xos_thread_routine_t*) privilege_thread_routine, 
                                    NULL ) != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error creating user privilege thread\n");
        exit(1);
    }

    LOG_INFO ("handle listening thread\n");

    if (xos_semaphore_create( &gSemSelfClient, 0 ) != XOS_SUCCESS) {
        LOG_SEVERE("start_server -- error creating semaphore for self");
        exit(1);
    }

    serverSocket[0].port = gDcssConfig.getDcssScriptPort();
    serverSocket[0].clientHandlerFunction = (void *)handle_self_client;
    serverSocket[0].multiClient = false;
    

    /* create a thread to handle incoming connections from self clients */
    if ( xos_thread_create( &listeningThread,
                                    (xos_thread_routine_t*)incoming_client_handler, 
                                    &serverSocket[0] ) != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error creating listening thread\n");
        exit(1);
    }

    //there is not evidence that the scripting engine needs a head start, but it feels safer this way.
    xos_thread_sleep(500);

    serverSocket[1].port = gDcssConfig.getDcssHardwarePort();
    serverSocket[1].clientHandlerFunction = (void *)handle_hardware_client;
    serverSocket[1].multiClient = true;

    /* create a thread to handle incoming connections from hardware clients */
    if ( xos_thread_create( &hardwareThread,
                                    (xos_thread_routine_t*)incoming_client_handler, 
                                    &serverSocket[1] ) != XOS_SUCCESS ) {
        LOG_SEVERE("start_server -- error creating listening thread\n");
        exit(1);
    }



    if (gDcssConfig.getDcssUseSSL( )) {
        serverSocket[2].port = gDcssConfig.getDcssGuiPort();
        serverSocket[2].clientHandlerFunction = (void *)gui_SSLclient_handler;
        serverSocket[2].multiClient = true;
        if (xos_thread_create( &hardwareThread,
        (xos_thread_routine_t*)incoming_SSLclient_handler, 
        &serverSocket[2] ) != XOS_SUCCESS ) {
            LOG_SEVERE("start_server -- error creating listening thread\n");
            exit(1);
        }
    } else {
        serverSocket[2].port = gDcssConfig.getDcssGuiPort();
        serverSocket[2].clientHandlerFunction = (void *)gui_client_handler;
        serverSocket[2].multiClient = true;

        /* create a thread to handle incoming connections from gui clients*/
        if (xos_thread_create( &hardwareThread,
        (xos_thread_routine_t*)incoming_client_handler, 
        &serverSocket[2] ) != XOS_SUCCESS ) {
            LOG_SEVERE("start_server -- error creating listening thread\n");
            exit(1);
        }
    }

    // Data for controlling db dump thread
    DbDumpControlData dumpData;
    std::string tmp;
    if (gDcssConfig.get("dcss.dbDumpFlag", tmp) && (tmp == "true")) {
    
        if (gDcssConfig.get("dcss.dbDumpFile", tmp))
            dumpData.setFilePath(tmp);
        if (gDcssConfig.get("dcss.dbDumpRate", tmp))
            dumpData.setRate(XosStringUtil::toInt(tmp, 5000));

        // Create db dump thread
        if ( xos_thread_create( &dbDumpThread,
                                        (xos_thread_routine_t*)db_dump_thread_routine, 
                                        &dumpData ) != XOS_SUCCESS ) {
            LOG_SEVERE("start_server -- error creating db dump thread\n");
            exit(1);
        }
    }




    // Run scripting engine in main thread
    /* create a thread to handle scripted devices */
    scripting_thread(0);


}


/****************************************************************
    restore_database:  Creates a new database (memory-mapped file)
    and reads data into it from the passed ASCII file.  If the 
    name of the ASCII file is '-', then the ASCII data is read
    from the standard input.  This function should be called from
    main() only, after which the program should exit.
****************************************************************/

void restore_database ( char * filename )
{
    FILE *dumpFile;
    int deviceCount;
    int index;
    beamline_device_t *device;
    beamline_device_t *database;
    int numParams;

    int lineNumForPermit;
    int lineNumForDependencies;
    int lineNumForChildren;
    int lineNumForConfig;

    /* open the dumped database */
    if ( strcmp(filename,"-") == 0 ) 
    {
        dumpFile = stdin;
    }
    else
    {
        if ( ( dumpFile = fopen( filename, "r" ) ) == NULL ) {
            LOG_SEVERE( "Open dump database failed\n" );
            exit( -1 );
        }
    }
    
    /* create a new database */
    if ( create_database( &database ) != XOS_SUCCESS ) {
        LOG_SEVERE("dump_database -- error opening database file\n");
        exit(1);
    }
    
    deviceCount = 0;
        
    /* read the dump file */
    while ( TRUE )
    {
        LOG_INFO1("deviceCount: %d\n",deviceCount);
        /* point device pointer to next device in memory map */
        device = database + deviceCount;

        if (readOneSectionFromDumpfile( dumpFile ) == 0)
        {
            LOG_WARNING( "end of file without keyword END" );
            break;
        }

        /* copy device name */
        if (strlen( dumpFileSection[0] ) >= DEVICE_NAME_SIZE)
        {
            LOG_SEVERE2( "device name %s too long >%d",
                dumpFileSection[0], (DEVICE_NAME_SIZE - 1) );
            exit( -1 );
        }
        strcpy( device->generic.name, dumpFileSection[0] );

        if ( strcmp( device->generic.name, "END" ) == 0 )
        {
            break;
        }
        

        /* make sure device name is unique */
        for (index = 0; index < deviceCount; ++index)
        {
            if (!strcmp( device->generic.name, 
                (database + index)->generic.name ))
            {
                LOG_SEVERE2( 
                    "Error device name not unique \"%s\" already at %d",
                    device->generic.name, index );
                exit(1);
            }

        }
                
        /* read the device type */
        if (numLineForSection < 2)
        {
            LOG_SEVERE1( "device %s not fully defined", dumpFileSection[0] );
            exit(1);
        }
        if ( sscanf( dumpFileSection[1], "%d", &device->generic.type ) != 1 )
        {
            LOG_SEVERE1("Error reading device type for %s", dumpFileSection[0]);
            exit(1);
        }
       
        /* print out name of device */
        LOG_INFO1("Adding device %s...\n", device->generic.name ); 

        /* default permit */
        device->generic.permit[USERS] = defaultUserPermit;
        device->generic.permit[STAFF] = defaultStaffPermit;
        strcpy( device->generic.hardwareHost, "self" );
        strcpy( device->generic.hardwareName, device->generic.name );
       
           /* device-type specific operations */
           switch ( device->generic.type )
           {
           case STEPPER_MOTOR:
            if (numLineForSection != 7)
            {
                LOG_SEVERE1( "stepper motor %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
               /* read hardware host information */
            readHostAndLocalName( &device->generic, dumpFileSection[2] );

            /* here new and old are different */
            /* new one permits are right after host and name */
            if (stringIsPermit( dumpFileSection[3] ) &&
                stringIsPermit( dumpFileSection[4] ))
            {
                /* new */
                lineNumForPermit = 3;
                lineNumForDependencies = 5;
                lineNumForConfig = 6;
            }
            else if (stringIsPermit( dumpFileSection[5] ) &&
                stringIsPermit( dumpFileSection[6] ))
            {
                lineNumForPermit = 5;
                lineNumForDependencies = 4;
                lineNumForConfig = 3;
            }
            else
            {
                LOG_SEVERE1( "device %s defined wrong permit lines",
                    device->generic.name );
                exit(1);
            }
            readDevicePermit( &device->generic, lineNumForPermit );
            /* read dependencies string */
            if (strlen(dumpFileSection[lineNumForDependencies]) >= 
                DEPENDENCIES_SIZE)
            {
                LOG_SEVERE1("motor %s dependency too long",
                    device->generic.name);
                 exit(1);
            }
            strcpy( device->motor.dependencies,
                dumpFileSection[lineNumForDependencies] );
            /* nullify string if first character is 0 */
            if ( device->motor.dependencies[0] == '0' ) 
            {
                device->motor.dependencies[0] = 0;
            }

            /* read device parameters */
            numParams = sscanf( dumpFileSection[lineNumForConfig], 
                "%lf %lf %lf %lf %d %d %d %d %d %d %d %d %d %s",
                &device->stepper.position,     
                &device->stepper.upperLimit,
                &device->stepper.lowerLimit,     
                &device->stepper.scaleFactor,
                &device->stepper.speed,             
                &device->stepper.acceleration,
                &device->stepper.backlash,        
                &device->stepper.lowerLimitOn,
                &device->stepper.upperLimitOn,    
                &device->stepper.motorLockOn,
                &device->stepper.backlashOn,     
                &device->stepper.reverseOn,
                &device->stepper.circleMode,
                device->stepper.units );

            if (numParams == 13 )
            {
                LOG_WARNING1("Please add units to stepper motor %s",
                    device->generic.name);
                strcpy(device->stepper.units,"");
            }
            else if (numParams != 14 )
            {
                LOG_SEVERE1("Check device config for stepper motor %s",
                    device->generic.name);
                 exit(1);
            }
            if (strlen(device->motor.units) >= UNITS_SIZE)
            {
                LOG_SEVERE1("motor %s units too long",
                    device->generic.name);
                 exit(1);
            }
            break;
            
        case PSEUDO_MOTOR:
            if (numLineForSection != 8)
            {
                LOG_SEVERE1( "pseudo motor %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            /* read hardware host information */
            readHostAndLocalName( &device->generic, dumpFileSection[2] );

            /* here new and old are different */
            /* new one permits are right after host and name */
            if (stringIsPermit( dumpFileSection[3] ) &&
                stringIsPermit( dumpFileSection[4] ))
            {
                /* new */
                lineNumForPermit = 3;
                lineNumForDependencies = 5;
                lineNumForConfig = 6;
                lineNumForChildren = 7;
            }
            else if (stringIsPermit( dumpFileSection[6] ) &&
                stringIsPermit( dumpFileSection[7] ))
            {
                lineNumForPermit = 6;
                lineNumForDependencies = 4;
                lineNumForConfig = 3;
                lineNumForChildren = 5;
            }
            else
            {
                LOG_SEVERE1( "pseudo motor %s defined wrong permit lines",
                    device->generic.name );
                exit(1);
            }
            readDevicePermit( &device->generic, lineNumForPermit );
            /* read dependencies string */
            if (strlen(dumpFileSection[lineNumForDependencies]) >= 
                DEPENDENCIES_SIZE)
            {
                LOG_SEVERE1("motor %s dependency too long",
                    device->generic.name);
                 exit(1);
            }
            strcpy( device->motor.dependencies,
                dumpFileSection[lineNumForDependencies] );
            /* nullify string if first character is 0 */
            if ( device->motor.dependencies[0] == '0' ) 
            {
                device->motor.dependencies[0] = 0;
            }

            /* read device parameters */
            numParams = sscanf( dumpFileSection[lineNumForConfig],
                "%lf %lf %lf %d %d %d %d %s",
                &device->pseudo.position,     
                &device->pseudo.upperLimit,
                &device->pseudo.lowerLimit,         
                &device->pseudo.lowerLimitOn,
                &device->pseudo.upperLimitOn,    
                &device->pseudo.motorLockOn,
                &device->pseudo.circleMode,
                device->pseudo.units );

            if (numParams == 7 )
            {
                LOG_WARNING1("Please add units to device definition for %s",
                    device->generic.name);
                strcpy(device->pseudo.units,"");
            }
            else if ( numParams != 8 )
            {
                LOG_SEVERE1("psuedo motor %s config wrong",
                    device->generic.name);
                 exit(1);
            }
            if (strlen(device->motor.units) >= UNITS_SIZE)
            {
                LOG_SEVERE1("motor %s units too long",
                    device->generic.name);
                 exit(1);
            }

            /* read children string */
            if (strlen(dumpFileSection[lineNumForChildren]) >= 
                DEPENDENCIES_SIZE)
            {
                LOG_SEVERE1("pseudo motor %s chilren too long",
                    device->generic.name);
                 exit(1);
            }
            strcpy( device->pseudo.children,
                dumpFileSection[lineNumForChildren] );
            break;            

        case ION_CHAMBER:
            switch (numLineForSection)
            {
            case 3:
                break;

            case 5:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "ion chamber %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readDevicePermit( &device->generic, 3 );
                break;

            default:
                LOG_SEVERE1( "ion chamber %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            {
                char strArg0[MAX_LINE_SIZE] = {0};
                char strArg1[MAX_LINE_SIZE] = {0};
                char strArg2[MAX_LINE_SIZE] = {0};
                char strArg3[MAX_LINE_SIZE] = {0};
                if (sscanf( dumpFileSection[2], "%s %s %d %s %s",
                    strArg0, strArg1,
                    &device->ion.counterChannel,
                    strArg2, strArg3 ) != 5 )
                {
                    LOG_SEVERE1( "ion chamber %s config wrong",
                        device->generic.name );
                    exit(1);
                }
                if (strlen( strArg0 ) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "ion chamber %s host name too long",
                        device->generic.name );
                    exit(1);
                }
                if (strlen( strArg1 ) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "ion chamber %s counter name too long",
                        device->generic.name );
                    exit(1);
                }
                if (strlen( strArg2 ) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "ion chamber %s timer name too long",
                        device->generic.name );
                    exit(1);
                }
                if (strlen( strArg2 ) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "ion chamber %s timer type name too long",
                        device->generic.name );
                    exit(1);
                }
                strcpy( device->generic.hardwareHost, strArg0 );
                strcpy( device->generic.hardwareName, strArg1 );
                strcpy( device->ion.timer, strArg2 );
                strcpy( device->ion.timerType, strArg3 );
            }
            break;                                                                                            
        case SHUTTER:
            switch (numLineForSection)
            {
            case 3:
                {
                    char strArg0[MAX_LINE_SIZE] = {0};
                    char strArg1[MAX_LINE_SIZE] = {0};
                    if (sscanf( dumpFileSection[2], "%s %d %s",
                        strArg0, &device->shutter.state, strArg1 ) < 2)
                    {
                        LOG_SEVERE1( "shutter %s config wrong",
                            device->generic.name );
                        exit(1);
                    }
                    if (strlen(strArg0) >= DEVICE_NAME_SIZE)
                    {
                        LOG_SEVERE1( "shutter %s host name too long",
                            device->generic.name );
                        exit(1);
                    }
                    if (strlen(strArg1) >= DEVICE_NAME_SIZE)
                    {
                        LOG_SEVERE1( "shutter %s local name too long",
                            device->generic.name );
                        exit(1);
                    }
                    strcpy( device->generic.hardwareHost, strArg0 );
                    if (strArg1[0] != '\0')
                    {
                        strcpy( device->generic.hardwareName, strArg1 );
                    }
                }
                break;

            case 5:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "shutter %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readDevicePermit( &device->generic, 3 );
                break;

            default:
                LOG_SEVERE1( "ion chamber %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            {
                char strArg0[MAX_LINE_SIZE] = {0};
                char strArg1[MAX_LINE_SIZE] = {0};
                if (sscanf( dumpFileSection[2], "%s %d %s",
                    strArg0, &device->shutter.state, strArg1 ) < 2)
                {
                    LOG_SEVERE1( "shutter %s config wrong",
                        device->generic.name );
                    exit(1);
                }
                if (strlen(strArg0) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "shutter %s host name too long",
                        device->generic.name );
                    exit(1);
                }
                if (strlen(strArg1) >= DEVICE_NAME_SIZE)
                {
                    LOG_SEVERE1( "shutter %s local name too long",
                        device->generic.name );
                    exit(1);
                }
                strcpy( device->generic.hardwareHost, strArg0 );
                if (strArg1[0] != '\0')
                {
                    strcpy( device->generic.hardwareName, strArg1 );
                }
            }
            break;

        case HARDWARE_HOST:
            if (numLineForSection != 3)
            {
                LOG_SEVERE1( "hardware host %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            /* read hardware host parameters */
            {
                char strArg0[MAX_LINE_SIZE] = {0};
                if (sscanf( dumpFileSection[2], "%s %d",
                    strArg0, &device->hardware.protocol ) != 2 )
                {
                    LOG_SEVERE1( "harware host %s config wrong",
                    device->generic.name );
                    exit(1);
                }
                if (strlen(strArg0) >= COMPUTER_NAME_SIZE)
                {
                    LOG_SEVERE1( "hardware host %s computer name too long",
                        device->generic.name );
                    exit(1);
                }
                strcpy( device->hardware.computer, strArg0 );
            }
            break;            
             
        case RUN_VALUES:
            switch (numLineForSection)
            {
            case 3:
                lineNumForConfig = 2;
                break;

            case 6:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "run %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readHostAndLocalName( &device->generic, dumpFileSection[2] );
                readDevicePermit( &device->generic, 3 );

                lineNumForConfig = 5;
                break;

            default:
                LOG_SEVERE1( "run %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            if (strlen(dumpFileSection[lineNumForConfig]) >= MAX_RUN_DEFINITION)
            {
                LOG_SEVERE1( "run %s contents too long",
                    device->generic.name );
                exit(1);
            }
            strcpy( device->runvalues.runDefinition,
                dumpFileSection[lineNumForConfig] );
            LOG_INFO1("{%s}\n",device->runvalues.runDefinition);
            break;
 
        case RUNS_STATUS:
            switch (numLineForSection)
            {
            case 3:
                lineNumForConfig = 2;
                break;

            case 6:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "runs status %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readHostAndLocalName( &device->generic, dumpFileSection[2] );
                readDevicePermit( &device->generic, 3 );
                lineNumForConfig = 5;
                break;

            default:
                LOG_SEVERE1( "runs status %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
                    
            if (sscanf( dumpFileSection[lineNumForConfig], "%d %d %d %d",
                &device->runs.runCount,
                &device->runs.currentRun,
                &device->runs.isActive,
                &device->runs.doseMode ) != 4)
            {
                LOG_WARNING1( "runs status %s config wrong, set to default",
                    device->generic.name );
                device->runs.runCount = 1;
                device->runs.currentRun = 0;
                device->runs.isActive = 0;
                device->runs.doseMode = 0;
            }
            break;

        case OPERATION:
            if (numLineForSection != 5)
            {
                LOG_SEVERE1( "device %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            if (!stringIsPermit( dumpFileSection[3] ) ||
                !stringIsPermit( dumpFileSection[4] ))
            {
                LOG_SEVERE1( "device %s defined wrong permit lines",
                    device->generic.name );
                exit(1);
            }
            readHostAndLocalName( &device->generic, dumpFileSection[2] );
            readDevicePermit( &device->generic, 3 );
            break;                

        case ENCODER:
            switch (numLineForSection)
            {
            case 5:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "device %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readDevicePermit( &device->generic, 3 );
                //fall through
            case 3:
                readHostAndLocalName( &device->generic, dumpFileSection[2] );
                break;

            default:
                LOG_SEVERE1( "device %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            break;                

        case STRING:
            switch (numLineForSection)
            {
            case 3:
            case 4:
                readHostAndLocalName( &device->generic, dumpFileSection[2] );
                lineNumForConfig = 3;
                break;

            case 5:
            case 6:
                if (!stringIsPermit( dumpFileSection[3] ) ||
                    !stringIsPermit( dumpFileSection[4] ))
                {
                    LOG_SEVERE1( "device %s defined wrong permit lines",
                        device->generic.name );
                    exit(1);
                }
                readHostAndLocalName( &device->generic, dumpFileSection[2] );
                readDevicePermit( &device->generic, 3 );
                lineNumForConfig = 5;
                break;

            default:
                LOG_SEVERE1( "device %s defined wrong lines",
                    device->generic.name );
                exit(1);
            }
            device->string.contents[0] = '\0';
            if (lineNumForConfig < numLineForSection)
            {
                if (strlen(dumpFileSection[lineNumForConfig]) >= MAX_STRING_SIZE)
                {
                    LOG_SEVERE1( "string %s contents too long",
                        device->generic.name );
                    exit(1);
                }
                strcpy( device->string.contents,
                    dumpFileSection[lineNumForConfig] );
            }
            break;                

            case OBJECT:
            default:
            
                /* report unrecognized device type and exit */
                LOG_SEVERE ("Unrecognized device type reading dump file.");
                exit(1);
            }
        
        /* update device count */
        if ( deviceCount++ >= MAX_DEVICES )
            {
            LOG_SEVERE("Maximum number of devices exceeded.");
            exit(1);
            }
        }        

    LOG_INFO1 ("A total of %d devices were read in from the dump file.\n",
        deviceCount );
    }

int brief_dump_one_device( beamline_device_t *device, char* buffer, size_t max )
{
    int nWritten = 0;

    switch ( device->generic.type )
    {
    case STEPPER_MOTOR:
        nWritten = snprintf( buffer, max, 
            "%s=%lf %lf %lf %lf %d %d %d %d %d %d %d %d %d %s\n",
            device->generic.name,     
            device->stepper.position,     
            device->stepper.upperLimit,
            device->stepper.lowerLimit,     
            device->stepper.scaleFactor,
            device->stepper.speed,             
            device->stepper.acceleration,
            device->stepper.backlash,        
            device->stepper.lowerLimitOn,
            device->stepper.upperLimitOn,    
            device->stepper.motorLockOn,
            device->stepper.backlashOn,     
            device->stepper.reverseOn,
            device->stepper.circleMode,
            device->stepper.units );
        break;
                
    case PSEUDO_MOTOR:
        nWritten = snprintf( buffer, max, 
            "%s=%lf %lf %lf %d %d %d %d %s\n",
            device->generic.name,     
            device->pseudo.position,     
            device->pseudo.upperLimit,
            device->pseudo.lowerLimit,         
            device->pseudo.lowerLimitOn,
            device->pseudo.upperLimitOn,    
            device->pseudo.motorLockOn,
            device->pseudo.circleMode,
            device->pseudo.units );
        break;            

    case ION_CHAMBER:
        nWritten = snprintf( buffer, max, 
            "%s=%lf\n",
            device->generic.name,     
            device->ion.counts );
        break;    

    case SHUTTER:
        nWritten = snprintf( buffer, max, 
            "%s=%d\n",
            device->generic.name,     
            device->shutter.state );
        break;        
            
    case ENCODER:
        nWritten = snprintf( buffer, max, 
            "%s=%lf\n",
            device->generic.name,     
            device->encoder.position );
        break;

     case STRING:
        nWritten = snprintf( buffer, max, 
            "%s=%s\n",
            device->generic.name,     
            device->string.contents );
        break;

    case OBJECT:
    case HARDWARE_HOST:
    case OPERATION:
    default:
        break;

    }
    if (nWritten > max) {
        return -1;
    } else {
        return nWritten;
    }
}


/****************************************************************
    dump_database:  Writes the contents of the current database
    (memory-mapped file)to the passed ASCII file.  If the 
    name of the ASCII file is '-', then the ASCII data is written
    to the standard output.  This function should be called from
    main() only, after which the program should exit.
****************************************************************/

int dump_one_device( beamline_device_t *device, FILE *outStream )
{
    char *dependencies;

    /* write the device name and type to the dump file */
    if (fprintf( outStream, "%s\n%d\n", 
        device->generic.name, device->generic.type ) < 0)
    {
        LOG_SEVERE("Error writing device name and type to dump file\n");
        return 0;
    }
    /* device-type specific operations */
    switch ( device->generic.type )
    {
    case STEPPER_MOTOR:
        /* write hardware host information */
        if (fprintf( outStream, "%s %s\n",
            device->generic.hardwareHost,
            device->generic.hardwareName ) < 0)
        {
            LOG_SEVERE("Error writing hardwareHost and local name to dump");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        /* write dependency */
        if (device->motor.dependencies[0] == 0) 
        {
             dependencies = "0";
        }
        else
        {
            dependencies = device->motor.dependencies;
        }
        if (fprintf( outStream, "%s\n", dependencies ) < 0)
        {
            LOG_SEVERE("Error writing motor dependency to dump");
            return 0;
        }
        /* write device parameters */
        if (fprintf( outStream, 
            "%lf %lf %lf %lf %d %d %d %d %d %d %d %d %d %s\n",
            device->stepper.position,     
            device->stepper.upperLimit,
            device->stepper.lowerLimit,     
            device->stepper.scaleFactor,
            device->stepper.speed,             
            device->stepper.acceleration,
            device->stepper.backlash,        
            device->stepper.lowerLimitOn,
            device->stepper.upperLimitOn,    
            device->stepper.motorLockOn,
            device->stepper.backlashOn,     
            device->stepper.reverseOn,
            device->stepper.circleMode,
            device->stepper.units ) < 0)
        {
            LOG_SEVERE("Error writing stepper motor config to dump");
            return 0;
        }
        break;
                
    case PSEUDO_MOTOR:
        /* write hardware host information */
        if (fprintf( outStream, "%s %s\n",
            device->generic.hardwareHost,
            device->generic.hardwareName ) < 0)
        {
            LOG_SEVERE("Error writing hardwareHost and local name to dump");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        /* write dependency */
        if (device->motor.dependencies[0] == 0) 
        {
             dependencies = "0";
        }
        else
        {
            dependencies = device->motor.dependencies;
        }
        if (fprintf( outStream, "%s\n", dependencies ) < 0)
        {
            LOG_SEVERE("Error writing motor dependency to dump");
            return 0;
        }
        /* write device parameters */
        if (fprintf( outStream, "%lf %lf %lf %d %d %d %d %s\n",
            device->pseudo.position,     
            device->pseudo.upperLimit,
            device->pseudo.lowerLimit,         
            device->pseudo.lowerLimitOn,
            device->pseudo.upperLimitOn,    
            device->pseudo.motorLockOn,
            device->pseudo.circleMode,
            device->pseudo.units ) < 0)
        {
            LOG_SEVERE("Error writing pseudo motor config to dump");
            return 0;
        }
        /* write children */
        if (fprintf( outStream, "%s\n", device->pseudo.children ) < 0)
        {
            LOG_SEVERE("Error writing pseudo motor children to dump");
            return 0;
        }
        break;            

    case ION_CHAMBER:
        if (fprintf( outStream, "%s %s %d %s %s\n",
                  device->ion.hardwareHost,
                  device->ion.hardwareName,
                  device->ion.counterChannel,
                  device->ion.timer,
                  device->ion.timerType ) < 0 ) {
            LOG_SEVERE("Error writing ion chamber hardware host"
                    " parameters to dump file\n");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        break;    
                                                                                    
    case SHUTTER:
        if (device->shutter.hardwareName[0] == 0)
        {
            if (fprintf( outStream, "%s %d\n",
                device->shutter.hardwareHost,
                device->shutter.state ) < 0)
            {
                LOG_SEVERE("Error writing shutter config to dump");
                return 0;
            }
        }
        else
        {
            if (fprintf( outStream, "%s %d %s\n",
                device->shutter.hardwareHost,
                device->shutter.state,
                device->shutter.hardwareName) < 0)
            {
                LOG_SEVERE("Error writing shutter config to dump");
                return 0;
            }
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        break;        
            
    case HARDWARE_HOST:
        if (fprintf( outStream, "%s %d\n",
            device->hardware.computer,
            device->hardware.protocol ) < 0)
        {
            LOG_SEVERE("Error writing hardware host config to dump");
            return 0;
        }
        break;            
 
    case OPERATION:
        // write hardware host information
        if (fprintf( outStream, "%s %s\n",
            device->operation.hardwareHost,
            device->operation.hardwareName ) < 0)
        {
            LOG_SEVERE("Error writing hardwarehost and local name to dump");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        break;

    case ENCODER:
        if (fprintf( outStream, "%s %s\n",
            device->encoder.hardwareHost,
            device->encoder.hardwareName ) < 0)
        {
            LOG_SEVERE("Error writing encoder config to dump");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
        break;

     case STRING:
        // write hardware host information
        if (fprintf( outStream, "%s %s\n",
            device->string.hardwareHost,
            device->string.hardwareName) < 0)
        {
            LOG_SEVERE("Error writing string hardwarehost to dump");
            return 0;
        }
        /* write permit */
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[STAFF].passiveOk,
            device->generic.permit[STAFF].remoteOk,
            device->generic.permit[STAFF].localOk,
            device->generic.permit[STAFF].inHutchOk,
            device->generic.permit[STAFF].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing staff permission to dump");
            return 0;
        }
        if (fprintf( outStream, "%d %d %d %d %d\n",
            device->generic.permit[USERS].passiveOk,
            device->generic.permit[USERS].remoteOk,
            device->generic.permit[USERS].localOk,
            device->generic.permit[USERS].inHutchOk,
            device->generic.permit[USERS].closedHutchOk ) < 0)
        {
            LOG_SEVERE("Error writing user permission to dump");
            return 0;
        }
            
        // write string contents
        if (fprintf( outStream, "%s\n", device->string.contents ) < 0)
        {
            LOG_SEVERE( "Error writing string contents to dump");
            return 0;
        }
        break;

    case OBJECT:
    default:

        /* report unrecognized device type and exit */
        LOG_SEVERE1 ("Unrecognized device type in database: %d",device->generic.type);
        return 0;
    }

    if (fprintf( outStream, "\n" ) < 0)
    {
        LOG_SEVERE("failed to write the empty line between device");
        return 0;
    }
    return 1;
}


int safe_dump_database( const char *filename )
{
    FILE *dumpFile;
    int deviceCount = get_device_count( );
    int deviceNum;
    int result = 1;
    beamline_device_t *device;

    /* open the dump file */
    if ( strcmp(filename,"-") == 0 ) 
    {
        dumpFile = stdout;
    }
    else
    {
		if ( ( dumpFile = fopen( filename, "w+" ) ) == NULL ) {
            char buffer[1024] = {0};
		    sprintf( buffer, "stog_log error server failed to open %s", filename );
		    write_broadcast_queue( buffer );
			LOG_SEVERE( "Open dump database failed" );
			return 0;
		}
        if (chmod( filename, 0660 )) {
		    LOG_SEVERE( "chmod dump database failed" );
		    return 0;
        }
    }


    /* safe */
    for (deviceNum = 0; deviceNum < deviceCount; ++deviceNum)
    {
        device = acquire_device( deviceNum );
        result = dump_one_device( device, dumpFile );
        release_device( deviceNum );
        if (!result)
        {
            break;
        }
    }
    fprintf( dumpFile, "END\n" );
    fclose( dumpFile );

    return result;
}

int brief_safe_dump_database( char* buffer, size_t max )
{
    int deviceCount = get_device_count( );
    int deviceNum;
    char* next = buffer;
    size_t remain = max;
    int nWritten = 0;

    beamline_device_t *device;

    /* clear buffer first */
    memset( buffer, 0, max );

    /* safe */
    for (deviceNum = 0; deviceNum < deviceCount; ++deviceNum)
    {
        device = acquire_device( deviceNum );
        nWritten = brief_dump_one_device( device, next, remain );
        release_device( deviceNum );
        if (nWritten < 0 || nWritten >= remain) {
            break;
        }
        next += nWritten;
        remain -= nWritten;
    }
    if (deviceNum >= deviceCount) {
        return 1;
    } else {
        return 0;
    }
}

void dump_database ( 
    char * filename 
    )
     
    {
    FILE *dumpFile;
    int deviceCount;
    beamline_device_t *device;
    beamline_device_t *database;
    
    /* open the dump file */
    if ( strcmp(filename,"-") == 0 ) 
        dumpFile = stdout;
    else {
        if ( ( dumpFile = fopen( filename, "w+" ) ) == NULL ) {
            LOG_SEVERE( "Open dump database failed\n" );
            exit(1);
        }
        if (chmod( filename, 0660 )) {
		    LOG_SEVERE( "chmod dump database failed" );
		    exit(1);
        }
    }
        
    /* open the database file */    
    if ( open_database( & database ) != XOS_SUCCESS ) {
        LOG_SEVERE("dump_database -- error opening database file\n");
        exit(1);
    }
    
    deviceCount = 0;
        
    /* read the dump file */
    while ( TRUE )
        {
        /* point device pointer to next device in memory map */
        device = database + deviceCount;
        
        /* check for end of database -- ONLY SAFE WAY OUT OF LOOP! */
        if ( strcmp( device->generic.name, "END" ) == 0 )
            break;
        
        if (!dump_one_device( device, dumpFile ))
        {
            exit( -1 );
        }
        
        /* update device count */
        deviceCount++;
        }        
    
    /* tag end of dump file */
    fprintf( dumpFile, "END\n" );
    fclose( dumpFile );
    }

void generate_dump_file_name( char * filename, int maxLength )
{
    time_t now = time( NULL );
    struct tm my_localtime;
    int ll;

    if (maxLength < 18)
    {
        SNPRINTF( filename, maxLength, "d%lu", now );
        return;
    }

    localtime_r( &now, &my_localtime );
    SNPRINTF(filename, maxLength, "dump%04d%02d%02d%02d%02d%02d",
            my_localtime.tm_year + 1900,
            my_localtime.tm_mon + 1,
            my_localtime.tm_mday,
            my_localtime.tm_hour,
            my_localtime.tm_min,
            my_localtime.tm_sec );

    
    ll = strlen( filename );
    if (maxLength > ll + 11)
    {
        char id[16] = {0};
        sprintf( id, "-%u", xos_thread_current_id( ) );
        strcat( filename, id );
    }
}

/**
 * Thread routine for dumping database to a file
 * periodically.
 */
XOS_THREAD_ROUTINE db_dump_thread_routine(DbDumpControlData* data)
{
    char name[256] = {0};
    std::string tmpFilePath;
    
    if (data == NULL)
        return 0;
        
    bool forever = true;
    while (forever) {
        
        // Generate filename with timestamp
        generate_dump_file_name(name, 255);
        // Append it to the designated dir
        tmpFilePath = data->getDir() + "/" + std::string(name);
        
        // Dump db to the tmp filepath
        // If successful, move it to the designated file.
        if (safe_dump_database(tmpFilePath.c_str())) {
            LOG_INFO1("Dumping database to %s\n", tmpFilePath.c_str());
            LOG_INFO1("Moving database dump file to %s\n", data->getFilePath().c_str());
            rename(tmpFilePath.c_str(), data->getFilePath().c_str());
            // Set permission to rwxrwxrwx
            chmod(data->getFilePath().c_str(), 0664);
        }
        
        xos_thread_sleep(data->getRate());
        
    }

    XOS_THREAD_ROUTINE_RETURN;
}


XOS_THREAD_ROUTINE safe_dump_thread_routine( void )
{
    char filename[256] = {0};
    /* generate dump file name */
    generate_dump_file_name( filename, 255 );
    
    safe_dump_database( filename );

    XOS_THREAD_ROUTINE_RETURN;
}


static void handleSignal( int sig_num, siginfo_t *sig_info, void *user_data )
{
    xos_thread_t    safeDumpThread;

    if (sig_num != SIGHUP) return;

    /* create a thread to call dump database */
    xos_thread_create( &safeDumpThread,
            (xos_thread_routine_t*) safe_dump_thread_routine, NULL );
}
static int getDefaultUserSessionID( void )
{
    if (gDefaultUserName.length( ) == 0) {
        LOG_FINEST( "get default username from config file" );
        if (!gDcssConfig.get("dcss.defaultUserName", gDefaultUserName)) {
            LOG_FINEST( "get default username from who started" );
            {
                struct passwd * pwd = getpwuid( geteuid( ) );
                if (pwd)
                {
                    gDefaultUserName = pwd->pw_name;
                    gUserHomeDir = pwd->pw_dir;
                }
                else
                {
                    LOG_WARNING( "get default username from env LOGNAME" );
                    gDefaultUserName = getenv( "LOGNAME" );
                }
            }
        }
    }
    LOG_FINEST1( "default username: %s", gDefaultUserName.c_str( ) );
    
    if (gUserHomeDir.length( ) == 0) {
        struct passwd * pwd = getpwnam( gDefaultUserName.c_str( ) );
        if (pwd)
        {
            gUserHomeDir = pwd->pw_dir;
        }
        else
        {
            LOG_WARNING( "use /home/USERNAME as home directory" );
            gUserHomeDir = "/home/" + gDefaultUserName;
        }
    }
    char filename[1024 ] = {0};
    int result = 0;
    FILE* fh = NULL;

    if (gpDefaultUser) {
        LOG_SEVERE( "gpDefaultUser is not NULL" );
        return 0;
    }
    gpDefaultUser = new AuthClient( gAuthHost, gAuthPort );
    gpDefaultUser->setUseSSL( gAuthUseSSL );

    //DEBUG
    //gpDefaultUser->setDebugHttp( true );

    //try to get stored gSessionID
    sprintf( filename, "%s/.bluice/session", gUserHomeDir.c_str( ) );
    fh = fopen( filename, "r" );
    if (fh)
    {
        size_t ll = 0;
        fread( gSessionID, sizeof(gSessionID), 1, fh );
        LOG_INFO1( "got stored session: {%.7s}", gSessionID );
        fclose( fh );

        ll = strlen( gSessionID );
        if (ll >1)
        {
            //replace with better way
            char a;
            a = gSessionID[ll -1];
            if (a == '\r' || a== '\n')
            {
                gSessionID[ll-1] = '\0';
                LOG_INFO( "return trimed" );
            }
        }
        LOG_INFO1( "set C gSessionID to {%.7s}", gSessionID );
        
        LOG_INFO( "validating" );

        try {
            if (gpDefaultUser->validateSession( gSessionID, gDefaultUserName ))
            {
                LOG_INFO( "validating OK" );
                result = 1;
            }
            else
            {
                LOG_INFO( "validate session failed" );
            }
        } catch (XosException& e) {
            LOG_SEVERE( "catched error" );
            LOG_SEVERE(e.getMessage().c_str());
        } catch (...) {
            LOG_SEVERE("Caught unknown error");
            exit(1);
        }
    }
    else
    {
        LOG_INFO1( "open session file %s failed", filename );
    }
    if (!result)
    {
        if (getppid( ) == 1)
        {
            LOG_SEVERE( "Please run foreground first to enter password" );
            exit(1);
        }

        char password[128] = {0};
        //ask password and create gSessionID
        printf( "Please input Password for User %s:", gDefaultUserName.c_str( ) );
        // Turn off echo
        struct termios attr;
        if (tcgetattr(STDIN_FILENO, &attr) != 0) {
            LOG_SEVERE("Failed to get terminal settings\n");
            exit(1);
        }
        
        attr.c_lflag &= ~(ECHO);
    
        if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &attr) != 0) {
            LOG_SEVERE("Failed to turn of echo\n");
            exit(1);
        }
        if (scanf("%s", password) != 1)
        {
            LOG_SEVERE( "bad password" );
            return 0;
        }
        attr.c_lflag |= ECHO;
        if (tcsetattr(STDIN_FILENO, TCSANOW, &attr) != 0) {
            LOG_SEVERE("Failed to turn on echo\n");
            exit(1);
        }
        std::string sid = "";
        try {
            gpDefaultUser->createSession( gDefaultUserName.c_str( ), password, false );
            sid  = gpDefaultUser->getSessionID( );
            if (sid.length( ) >= sizeof(gSessionID))
            {
                LOG_SEVERE( "new session ID too long, need to change code: gSession" );
                return 0;
            }
            strcpy( gSessionID, sid.c_str( ) );
            LOG_INFO1( "set C gSessionID to {%s}", gSessionID );
        } catch (XosException& e) {
            LOG_SEVERE(e.getMessage().c_str());
            exit(1);
        } catch (...) {
            LOG_SEVERE("Caught unknown error");
            exit(1);
        }
        //store the id
        sprintf( filename, "%s/.bluice/session", gUserHomeDir.c_str( ) );
        fh = fopen( filename, "w" );
        if (fh)
        {
            fwrite( sid.c_str( ), sid.length( ), 1, fh );
            fclose( fh );
            LOG_INFO1( "new session id {%s} stored", sid.c_str( ) );
        }
    }
    return 1;
}
static void readDevicePermit( generic_device_t *pDevice, int startLine )
{
       if ( sscanf( dumpFileSection[startLine], "%d %d %d %d %d",
         &pDevice->permit[STAFF].passiveOk,
         &pDevice->permit[STAFF].remoteOk,
         &pDevice->permit[STAFF].localOk,
         &pDevice->permit[STAFF].inHutchOk,
         &pDevice->permit[STAFF].closedHutchOk ) != 5 )
    {
        LOG_SEVERE2( "devive %s wrong staff permission %s",
            pDevice->name, dumpFileSection[startLine] );
        exit(1);
    }

    ++startLine;
       if ( sscanf( dumpFileSection[startLine], "%d %d %d %d %d",
         &pDevice->permit[USERS].passiveOk,
         &pDevice->permit[USERS].remoteOk,
         &pDevice->permit[USERS].localOk,
         &pDevice->permit[USERS].inHutchOk,
         &pDevice->permit[USERS].closedHutchOk ) != 5 )
    {
        LOG_SEVERE2( "devive %s wrong user permission %s",
            pDevice->name, dumpFileSection[startLine] );
        exit(1);
    }
}

static int stringIsPrintable( const char* pString )
{
    size_t ll = strlen( pString );
    size_t i;
    for (i = 0; i < ll; ++i)
    {
        if (!isprint( pString[i] ))
        {
            return 0;
        }
    }
    return 1;
}

static void trimString( char* pString )
{
    size_t ll = strlen( pString );

    size_t head = 0; /* first non-space */
    size_t end = 0;  /* beyond last non-space */
    size_t i;
    int finding_head = 1;
    for (i = 0; i < ll; ++i)
    {
        if (isspace(pString[i]))
        {
            if (finding_head)
            {
                head = i + 1;
                end = head;
            }
        }
        else
        {
            if (finding_head)
            {
                finding_head = 0;
            }
            end = i + 1;
        }
    }

    /* trim */
    size_t new_ll = 0;
    if (end > head)
    {
        new_ll = end - head;
    }

    if (new_ll > 0 && head > 0)
    {
        for (i = 0; i < new_ll; ++i)
        {
            pString[i] = pString[i + head];
        }
    }
    pString[new_ll] = '\0';
}

static int stringIsPermit( const char *pString )
{
    size_t ll = strlen( pString );
    if (ll != 9) return 0;

    size_t i;
    for (i = 0; i < ll; ++i)
    {
        if (i % 2)
        {
            if (pString[i] != ' ') return 0;
        }
        else
        {
            if (pString[i] != '1' && pString[i] != '0') return 0;
        }
    }
    return 1;
}

static int readOneSectionFromDumpfile( FILE* dumpFile )
{
    /* init */
    memset( dumpFileSection, 0, sizeof(dumpFileSection) );
    numLineForSection = 0;

    while (1)
    {
        if (feof( dumpFile ) || ferror( dumpFile ))
        {
            break;
        }
        char *pLine = dumpFileSection[numLineForSection];
        fgets( pLine, MAX_LINE_SIZE, dumpFile );
        trimString( pLine );
        if (!stringIsPrintable( pLine ))
        {
            if (numLineForSection > 0)
            {
                printf( "non-printable character found in %s line %d {%s}\n",
                     dumpFileSection[0], numLineForSection, pLine );
            }
            else
            {
                printf( "non-printable character found in name {%s}\n",
                     pLine );
            }
            exit( -1 );
        }
        size_t ll = strlen( pLine );
        if (ll > 0)
        {
            ++numLineForSection;
            if (numLineForSection > MAX_NUM_LINE)
            {
                printf( "exceed max number of lines per section" );
                exit( -1 );
            }
        }
        else
        {
            if (numLineForSection)
            {
                break;
            }
        }
    }
    return numLineForSection;
}
static void readHostAndLocalName( generic_device_t *pDevice, 
    const char* pString )
{
    char strArg0[MAX_LINE_SIZE] = {0};
    char strArg1[MAX_LINE_SIZE] = {0};
    int numInput = sscanf( pString, "%s %s", strArg0, strArg1 );
    if (numInput <= 0)
    {
        LOG_SEVERE1( "device %s lacks host and localname", pDevice->name );
        exit(1);
    }

    if (strlen(strArg0) >= DEVICE_NAME_SIZE)
    {
        LOG_SEVERE1( "device %s host name too long", pDevice->name );
        exit(1);
    }
    strcpy( pDevice->hardwareHost, strArg0 );

    if (numInput == 1)
    {
        LOG_WARNING2( "device %s no localname defined, use default %s",
            pDevice->name, pDevice->hardwareName );

        return;
    }

    if (strlen(strArg1) >= DEVICE_NAME_SIZE)
    {
        LOG_SEVERE1( "device %s local name too long", pDevice->name );
        exit(1);
    }
    strcpy( pDevice->hardwareName, strArg1 );
}
void initAuthInfo( ) {
    gAuthUseSSL = true;
    gAuthHost = gDcssConfig.getAuthSecureHost( );
    gAuthPort = gDcssConfig.getAuthSecurePort( );

    if (gAuthHost.length( ) <= 0 || gAuthPort <=0) {
        gAuthUseSSL = false;
        gAuthHost = gDcssConfig.getAuthHost( );
        gAuthPort = gDcssConfig.getAuthPort( );
        LOG_INFO( "NOT using SSL" );
    }
}
int dump_one_device_for_epics( beamline_device_t *device, FILE *outStream )
{
    if (!strncmp( device->generic.hardwareHost, "epics", 5)) {
        LOG_WARNING1( "skipped %s: host on epics", device->generic.name );
        return 1;
    }

    /* write the device name and type to the dump file */
    /* device-type specific operations */
    switch ( device->generic.type )
    {
    case STEPPER_MOTOR:
    case PSEUDO_MOTOR:
        if (fprintf( outStream, "record(ai, ""$(beamline):%s"")\n{\n", 
            device->generic.name ) < 0)
        {
            LOG_SEVERE("Error writing device name to dump file\n");
            return 0;
        }
        if (fprintf( outStream, "    field(DTYP, ""DCSMotor"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(SCAN, ""I/O Intr"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(INP, ""@%s"")\n", 
            device->generic.name ) < 0
        ) {
            LOG_SEVERE("Error writing INP to dump");
            return 0;
        }
        fprintf( outStream, "    field(DESC, ""Analog input"")\n" );
        fprintf( outStream, "}\n" );
        break;            

    case ION_CHAMBER:
        if (fprintf( outStream, "record(ai, ""$(beamline):%s"")\n{\n", 
            device->generic.name ) < 0)
        {
            LOG_SEVERE("Error writing device name to dump file\n");
            return 0;
        }
        if (fprintf( outStream, "    field(DTYP, ""DCSIonChamber"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(SCAN, ""I/O Intr"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(INP, ""@%s"")\n", 
            device->generic.name ) < 0
        ) {
            LOG_SEVERE("Error writing INP to dump");
            return 0;
        }
        fprintf( outStream, "    field(DESC, ""Analog input"")\n" );
        fprintf( outStream, "}\n" );
        break;            

    case SHUTTER:
        if (fprintf( outStream, "record(bi, ""$(beamline):%s"")\n{\n", 
            device->generic.name ) < 0)
        {
            LOG_SEVERE("Error writing device name to dump file\n");
            return 0;
        }
        if (fprintf( outStream, "    field(DTYP, ""DCSShutter"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(SCAN, ""I/O Intr"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(INP, ""@%s"")\n", 
            device->generic.name ) < 0
        ) {
            LOG_SEVERE("Error writing INP to dump");
            return 0;
        }
        fprintf( outStream, "    field(DESC, ""Binary input"")\n" );
        fprintf( outStream, "}\n" );
        break;            

    case ENCODER:
        if (fprintf( outStream, "record(ai, ""$(beamline):%s"")\n{\n", 
            device->generic.name ) < 0)
        {
            LOG_SEVERE("Error writing device name to dump file\n");
            return 0;
        }
        if (fprintf( outStream, "    field(DTYP, ""DCSEncoder"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(SCAN, ""I/O Intr"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(INP, ""@%s"")\n", 
            device->generic.name ) < 0
        ) {
            LOG_SEVERE("Error writing INP to dump");
            return 0;
        }
        fprintf( outStream, "    field(DESC, ""Analog input"")\n" );
        fprintf( outStream, "}\n" );
        break;            

     case STRING:
        if (fprintf( outStream, "record(waveform, ""$(beamline):%s"")\n{\n", 
            device->generic.name ) < 0)
        {
            LOG_SEVERE("Error writing device name to dump file\n");
            return 0;
        }
        if (fprintf( outStream, "    field(DTYP, ""DCSString"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(SCAN, ""I/O Intr"")\n" ) < 0
        ) {
            LOG_SEVERE("Error writing DTYP to dump");
            return 0;
        }
        if (fprintf( outStream, "    field(INP, ""@%s"")\n", 
            device->generic.name ) < 0
        ) {
            LOG_SEVERE("Error writing INP to dump");
            return 0;
        }
        fprintf( outStream, "    field(DESC, ""Waveform"")\n" );
        fprintf( outStream, "    field(FTVL, ""CHAR"")\n" );
        fprintf( outStream, "    field(NELM, ""1024"")\n" );
        fprintf( outStream, "}\n" );
        break;            

    case HARDWARE_HOST:
    case OPERATION:
    case OBJECT:
    default:
        return 1;
    }

    if (fprintf( outStream, "\n" ) < 0)
    {
        LOG_SEVERE("failed to write the empty line between device");
        return 0;
    }
    return 1;
}

void dump_database_for_epics ( 
    char * filename 
    )
     
    {
    FILE *dumpFile;
    int deviceCount;
    beamline_device_t *device;
    beamline_device_t *database;
    
    /* open the dump file */
    if ( strcmp(filename,"-") == 0 ) 
        dumpFile = stdout;
    else {
        if ( ( dumpFile = fopen( filename, "w+" ) ) == NULL ) {
            LOG_SEVERE( "Open dump database failed\n" );
            exit(1);
        }
        if (chmod( filename, 0660 )) {
		    LOG_SEVERE( "chmod dump database failed" );
		    exit(1);
        }
    }
        
    /* open the database file */    
    if ( open_database( & database ) != XOS_SUCCESS ) {
        LOG_SEVERE("dump_database -- error opening database file\n");
        exit(1);
    }
    
    deviceCount = 0;
        
    /* read the dump file */
    while ( TRUE )
        {
        /* point device pointer to next device in memory map */
        device = database + deviceCount;
        
        /* check for end of database -- ONLY SAFE WAY OUT OF LOOP! */
        if ( strcmp( device->generic.name, "END" ) == 0 )
            break;
        
        if (!dump_one_device_for_epics( device, dumpFile ))
        {
            exit( -1 );
        }
        
        /* update device count */
        deviceCount++;
        }        
    
    /* tag end of dump file */
    fclose( dumpFile );
    }
