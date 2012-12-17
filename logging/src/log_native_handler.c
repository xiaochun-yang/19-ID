#include <stdio.h>
#include "logging.h"
#include "log_handler.h"
#include "log_native_handler.h"

void __log_handler_init(log_handler_t* self);
log_handler_t* __log_handler_new();

#ifdef WIN32


/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
typedef struct __log_native_data
{
    HANDLE hEventLog;
    char   logName[LOGGER_NAME_LEN];
} log_native_data_t;



/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
static log_native_data_t* get_data(void* d)
{
    return (log_native_data_t*)d;
}

static void add_event_source( const char* source )
{
    HKEY hKey;
    DWORD existStatus;
    DWORD dwData;

    char keyName[512] = {0};
    char *pChar;

    strcpy( keyName, "SYSTEM\\CurrentControlSet\\Services\\EventLog\\Application\\" );
    strcat( keyName, source );
 
    // Add your source name as a subkey under the Application 
    // key in the EventLog registry key.
 
    if (RegCreateKeyEx(
            HKEY_LOCAL_MACHINE,
            keyName,
            0,
            NULL,
            REG_OPTION_NON_VOLATILE,
            KEY_ALL_ACCESS,
            NULL,
            &hKey,
            &existStatus) != ERROR_SUCCESS)
    {
        return;
    }

    if (existStatus != REG_CREATED_NEW_KEY)
    {
        RegCloseKey( hKey );
        return;
    }
 
    // Set the name of the message file.
    //here we use keyName just as a buffer
    strcpy( keyName, __FILE__ );
    pChar = strrchr( keyName, '\\' );
    if (pChar)
    {
        ++pChar; //skip '\'
        strcpy( pChar, "messages.dll" );
    }
    else
    {
        strcpy( keyName, "messages.dll" );
    }
 
    // Add the name to the EventMessageFile subkey.  
    if (RegSetValueEx(hKey,             // subkey handle 
            "EventMessageFile",       // value name 
            0,                        // must be zero 
            REG_EXPAND_SZ,            // value type 
            (LPBYTE) keyName,         // pointer to value data 
            strlen(keyName) + 1))       // length of value data 
    {
        RegCloseKey( hKey );
        return;
    }
 
    // Set the supported event types in the TypesSupported subkey. 
 
    dwData = EVENTLOG_ERROR_TYPE | EVENTLOG_WARNING_TYPE | 
        EVENTLOG_INFORMATION_TYPE; 
 
    RegSetValueEx(hKey,      // subkey handle 
            "TypesSupported",  // value name 
            0,                 // must be zero 
            REG_DWORD,         // value type 
            (LPBYTE) &dwData,  // pointer to value data 
            sizeof(DWORD));    // length of value data 
 
    RegCloseKey(hKey); 
}

static void close_(log_handler_t* self)
{
    // flush the remaining buffer
    log_native_data_t* data = get_data(self->data_);
    if (!data)
        return;

    if (data->hEventLog)
    {
        DeregisterEventSource(data->hEventLog); 
    }
}

/*********************************************************
 *
 *
 *
 *********************************************************/
static void open_(log_handler_t* self)
{
    log_native_data_t* data = get_data(self->data_);
    if (!data) return;

    add_event_source( data->logName );

    data->hEventLog = RegisterEventSource(
        NULL,               // uses local computer 
        data->logName);     // source name 
}

/*********************************************************
 *
 * Publish a LogRecord.
 * The logging request was made initially to a Logger object,
 * which initialized the LogRecord and forwarded it here.
 *
 * The Handler is responsible for formatting the message,
 * when and if necessary. The formatting should include localization.
 *
 *********************************************************/
static void publish(log_handler_t* self, log_record_t* record)
{
    log_native_data_t*  data = get_data(self->data_);
	log_formatter_t*    formatter = NULL;
	const char**        Messages;
    const char*         OneMessage;
    WORD                eventType = EVENTLOG_INFORMATION_TYPE;

    // At this point we can assume that, if the stream is not already opened,
    // there is something wrong. We should try to open or write to the stream.
    if (!data || !data->hEventLog) return;

	
	formatter = log_handler_get_formatter(self);
    
    //hard code, revise in the future with log_level.c
    switch (log_level_get_int_value(log_record_get_level(record)))
    {
    case 4: //info
        eventType = EVENTLOG_INFORMATION_TYPE;
        break;

    case 5: //info
        eventType = EVENTLOG_INFORMATION_TYPE;
        break;

    case 6: //warning
        eventType = EVENTLOG_WARNING_TYPE;
        break;

    case 7: //severe
        eventType = EVENTLOG_ERROR_TYPE;
        break;

    case 8:
    case 0:
    case 1:
    case 2:
    case 3:
    default:
        eventType = EVENTLOG_SUCCESS;
    }

    OneMessage = log_record_get_message( record );
    Messages = &OneMessage;

    //fprintf(data->stream, str);
    ReportEvent(
        data->hEventLog,      // event log handle 
        eventType,            // event type 
        0,                    // category zero 
        0x101,                // event identifier 
        NULL,                 // no user security identifier 
        1,                    // one substitution string 
        0,                    // no data 
        Messages,          // pointer to string array 
        NULL);                // pointer to data 

}

static void flush_(log_handler_t* self)
{
}


/*********************************************************
 *
 * Called when the base class's destroy() is called.
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	close_(self);
	    
	free((log_native_data_t*)self->data_);
}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
static void log_native_handler_init( log_handler_t* self, const char* logName )
{
    log_native_data_t* d = NULL;

    if (!self) return;

	__log_handler_init(self);
	
	d = malloc(sizeof(log_native_data_t));
    if (d)
    {
        d->hEventLog = NULL;
        strcpy( d->logName, logName ); //no safety check.
    }
    self->data_ = d;
	self->formatter = NULL;
	self->filter = NULL;
	self->level = LOG_ALL;
    self->close = &close_;
    self->flush = &flush_;
    self->publish = &publish;
    self->destroy = &destroy;

    open_(self);
}


log_handler_t* log_native_handler_new( const char* logName )
{
    log_handler_t* self = __log_handler_new();

	log_native_handler_init(self,  logName );

    return self;
}

#else
log_handler_t* log_native_handler_new( const char* logName )
{
    return NULL;
}

#endif
