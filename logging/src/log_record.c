#include "xos.h"
//#include "xos_time.h"
#include "log_record.h"

/*********************************************************
 *
 * new log_record_t data structure
 *
 *********************************************************/
struct __log_record
{
    char    msg[LOG_RECORD_MSG_LEN];
    char    logger_name[LOGGER_NAME_LEN];
    const   log_level_t* level;
    long    sequence_number;
    char    source_class_name[LOG_RECORD_SOURCE_LEN];
    char    source_method_name[LOG_RECORD_METHOD_LEN];
    int     thread_id;
	int		process_id;
    time_t  millis;
	char	file[LOG_RECORD_FILE_LEN];
	int		line;
	char	date[LOG_RECORD_DATE_LEN];
	char	time[LOG_RECORD_TIME_LEN];
	xos_hash_t params;

};


/*********************************************************
 *
 * System dependent utility func
 *
 *********************************************************/
int get_process_id()
{
#ifdef WIN32
	return _getpid();
#else
	return getpid();
#endif
}


/*********************************************************
 *
 * local static functions
 *
 *********************************************************/
static int get_sequence_number()
{
    static long unique_id = 0;

    int ret = unique_id;

    ++unique_id;

    return ret;

}

/*********************************************************
 *
 * Initialize member variables of log_record_t
 *
 *********************************************************/
void log_record_init(log_record_t* self, log_level_t* level, 
					 const char* msg)
{
	if (!self)
		return;

    strncpy(self->msg, msg, LOG_RECORD_MSG_LEN);
    strcpy(self->logger_name, "");
    self->level = level;
    self->sequence_number = get_sequence_number();

    strcpy(self->source_class_name, "");
    strcpy(self->source_method_name, "");
    self->thread_id = xos_thread_current_id( );
    self->process_id = get_process_id();
    self->millis = time(NULL);

}

/*********************************************************
 *
 * Initialize member variables of log_record_t
 *
 *********************************************************/
void log_record_init_va(log_record_t* self, log_level_t* level, 
					 const char* format, va_list ap)
{
    if (!self)
        return;
        
        
    strcpy(self->msg, "");

	VSNPRINTF(self->msg, LOG_RECORD_MSG_LEN, format, ap);

	va_end(ap);
	// truncate the msg buffer (in case of overflow)
    strcpy(self->logger_name, "");
    self->level = level;
    self->sequence_number = get_sequence_number();

    strcpy(self->source_class_name, "");
    strcpy(self->source_method_name, "");
    self->thread_id = xos_thread_current_id( );
    self->process_id = get_process_id();
    self->millis = time(NULL);

}

/*********************************************************
 *
 * Deallocate member variables of log_record_t
 *
 *********************************************************/
void log_record_destroy(log_record_t* record)
{

/*	xos_iterator_t entryIterator;
	char name[250];
	char* str;

	if (!record)
			return;


	// publish the record through all handlers
	if ( xos_hash_get_iterator( &record->params, & entryIterator ) != XOS_SUCCESS )
		return;

	// loop over all hash table entries  to free the string 
	while ( xos_hash_get_next( &record->params, name,
						(xos_hash_data_t *) &str, & entryIterator ) == XOS_SUCCESS )
	{
		free(str);
	}

	// Destroy the hash.
	xos_hash_destroy(&record->params);*/
}

 /*********************************************************
 *
 * Creates a new log_record_t
 * Construct a LogRecord with the given level and message values.
 * The sequence property will be initialized with a new unique value.
 * These sequence values are allocated in increasing order within a VM.
 *
 * The millis property will be initialized to the current time.
 *
 * The thread ID property will be initialized with a unique ID for
 * the current thread.
 *
 * All other properties will be initialized to "null".
 *
 *********************************************************/
log_record_t* log_record_new(log_level_t* level, const char* msg)

{
    log_record_t* self = (log_record_t*)malloc(sizeof(log_record_t));

	log_record_init(self, level, msg);


    return self;
}

/*********************************************************
 *
 * Creates a new log_record_t
 * Construct a LogRecord with the given level and message values.
 * The sequence property will be initialized with a new unique value.
 * These sequence values are allocated in increasing order within a VM.
 *
 * The millis property will be initialized to the current time.
 *
 * The thread ID property will be initialized with a unique ID for
 * the current thread.
 *
 * All other properties will be initialized to "null".
 *
 *********************************************************/
log_record_t* log_record_new_va(log_level_t* level, 
								const char* format, va_list ap)
{

	log_record_t* self = (log_record_t*)malloc(sizeof(log_record_t));

	log_record_init_va(self, level, format, ap);

	return self;
}


/*********************************************************
 *
 * Deallocate memory for log_record_t
 *
 *********************************************************/
void log_record_free(log_record_t* self)
{
    if (!self)
        return;

	log_record_destroy(self);

    free(self);
}


/*********************************************************
 *
 * Get the source Logger name's
 *
 *********************************************************/
const char* log_record_get_logger_name(const log_record_t* self)
{
    if (!self)
        return NULL;

    return self->logger_name;
}


/*********************************************************
 *
 * Set the source Logger name.
 *
 *********************************************************/
void log_record_set_logger_name(log_record_t* self,
                                        const char* name)
{
    if (!self)
        return;

    if (!name) {
        strcpy(self->logger_name, "");
    } else {
        strncpy(self->logger_name, name, LOGGER_NAME_LEN);
    }
}


/*********************************************************
 *
 * Get the logging message level, for example Level.SEVERE.
 *
 *********************************************************/
log_level_t* log_record_get_level(const log_record_t* self)
{
    if (!self)
        return NULL;

    return (log_level_t*)self->level;
}



/*********************************************************
 *
 * Set the logging message level, for example Level.SEVERE.
 *
 *********************************************************/
void log_record_set_level(log_record_t* self,
                                log_level_t* level)
{
    if (!self)
        return;

    self->level = level;
}

/*********************************************************
 *
 * Set the logging message level, for example Level.SEVERE.
 *
 *********************************************************/
void log_record_set_level_str(log_record_t* self,
                                const char* level)
{
    if (!self)
        return;

    self->level = log_level_parse(level);
}


/*********************************************************
 *
 * Get the sequence number.
 * Sequence numbers are normally assigned in the LogRecord constructor,
 * which assignes unique sequence numbers to each new LogRecord in increasing order
 *
 *********************************************************/
long log_record_get_sequence_number(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->sequence_number;
}


/*********************************************************
 *
 * Set the sequence number.
 * Sequence numbers are normally assigned in the LogRecord constructor,
 * so it should not normally be necessary to use this method.
 *
 *********************************************************/
void log_record_set_sequence_number(log_record_t* self,
                                    long sequence_number)
{
    if (!self)
        return;

    self->sequence_number = sequence_number;
}


/*********************************************************
 *
 * Get the name of the class that (allegedly) issued the logging request.
 * Note that this sourceClassName is not verified and may be spoofed.
 * This information may either have been provided as part of the logging call,
 * or it may have been inferred automatically by the logging framework.
 * In the latter case, the information may only be approximate and may in
 * fact describe an earlier call on the stack frame.
 *
 * May be null if no information could be obtained.
 *
 *********************************************************/
const char* log_record_get_source_class_name(const log_record_t* self)
{
    if (!self)
        return NULL;

    return self->source_class_name;
}


/*********************************************************
 *
 * Set the name of the class that (allegedly) issued the logging request.
 *
 *********************************************************/
void log_record_set_source_class_name(log_record_t* self,
                                        const char* name)
{
    if (!self)
        return;

    if (!name) {
        strcpy(self->source_class_name, "");
    } else {
        strncpy(self->source_class_name, name, LOG_RECORD_SOURCE_LEN);
    }
}


/*********************************************************
 *
 * Get the name of the method that (allegedly) issued the logging request.
 * Note that this sourceMethodName is not verified and may be spoofed.
 * This information may either have been provided as part of the logging call,
 * or it may have been inferred automatically by the logging framework.
 * In the latter case, the information may only be approximate and may
 * in fact describe an earlier call on the stack frame.
 *
 * May be null if no information could be obtained.
 *
 *********************************************************/
const char* log_record_get_source_method_name(const log_record_t* self)
{
    if (!self)
        return NULL;

    return self->source_method_name;
}


/*********************************************************
 *
 * Set the name of the method that (allegedly) issued the logging request.
 *
 *********************************************************/
void log_record_set_source_method_name(log_record_t* self,
                                        const char* name)
{
    if (!self)
        return;

    if (!name) {
        strcpy(self->source_method_name, "");
    } else {
        strncpy(self->source_method_name, name, LOG_RECORD_SOURCE_LEN);
    }
}


/*********************************************************
 *
 * Get the "raw" log message, before localization or formatting.
 * May be null, which is equivalent to the empty string "".
 *
 * This message may be either the final text or a localization key.
 *
 * During formatting, if the source logger has a localization
 * ResourceBundle and if that ResourceBundle has an entry for this
 * message string, then the message string is replaced with the localized value.
 *
 *********************************************************/
int log_record_get_message_size(const log_record_t* self)
{
    if (!self || !self->msg)
        return 0;

    return strlen(self->msg);
}

/*********************************************************
 *
 * Get the "raw" log message, before localization or formatting.
 * May be null, which is equivalent to the empty string "".
 *
 * This message may be either the final text or a localization key.
 *
 * During formatting, if the source logger has a localization
 * ResourceBundle and if that ResourceBundle has an entry for this
 * message string, then the message string is replaced with the localized value.
 *
 *********************************************************/
const char* log_record_get_message(const log_record_t* self)
{
    if (!self)
        return NULL;

    return self->msg;
}


/*********************************************************
 *
 * Set the "raw" log message, before localization or formatting.
 *
 *********************************************************/
void log_record_set_message(log_record_t* self,
                            const char* msg)
{
    if (!self)
        return;

    if (!msg) {
        strcpy(self->msg, "");
    } else {
        strncpy(self->msg, msg, LOG_RECORD_MSG_LEN);
    }
}


/*********************************************************
 *
 * Get the parameters to the log message.
 * NOT IMPLEMENTED
 *
 *********************************************************/
const xos_hash_t* log_record_get_parameters(const log_record_t* self)
{
/*    if (!self)
        return NULL;

    return &self->params;*/

	return NULL;
}


/*********************************************************
 *
 * Set the parameters to the log message.
 * NOT IMPLEMENTED
 *
 *********************************************************/
void log_record_add_patameter(log_record_t* self,
                                const char* name,
								const char* value)
{
/*	int len;
	char* newstr;

    if (!self)
        return;
	
	// initialize the hash
	if (!self->params.isValid)
		xos_hash_initialize(&self->params, 10, NULL);

	len = strlen(value);
	newstr = (char*)malloc(sizeof(char)*(len+1));
	strcpy(newstr, value);
	if ( xos_hash_add_entry( &self->params, name,
			(xos_hash_data_t) newstr ) != XOS_SUCCESS )
	{
		free(newstr);
	}*/
}

/*********************************************************
 *
 * Get an identifier for the thread where the message originated.
 * This is a thread identifier within the Java VM and may or may not
 * map to any operating system ID.
 *
 *********************************************************/
int log_record_get_thread_id(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->thread_id;
}


/*********************************************************
 *
 * Set an identifier for the thread where the message originated.
 *
 *********************************************************/
void log_record_set_thread_id(log_record_t* self,
                            int id)
{
    if (!self)
        return;

    self->thread_id = id;

}

/*********************************************************
 *
 * Get the process id
 *
 *********************************************************/
int log_record_get_process_id(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->process_id;
}

/*********************************************************
 *
 * Set the process id
 *
 *********************************************************/
void log_record_set_process_id(log_record_t* self, int id)
{
    if (!self)
        return;

    self->process_id = id;
}

/*********************************************************
 *
 * Get event time in milliseconds since 1970.
 *
 *********************************************************/
time_t log_record_get_millis(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->millis;
}


/*********************************************************
 *
 * Set event time.
 *
 *********************************************************/
void log_record_set_millis(log_record_t* self,
                            time_t millis)
{
    if (!self)
        return;

    self->millis = millis;

}


/*********************************************************
 *
 * Get source filename.
 *
 *********************************************************/
const char* log_record_get_file(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->file;
}


/*********************************************************
 *
 * Set source filename.
 *
 *********************************************************/
void log_record_set_file(log_record_t* self,
                            const char* file)
{
    if (!self || !file)
        return;

    strncpy(self->file, file, LOG_RECORD_FILE_LEN);

}


/*********************************************************
 *
 * Get source line number
 *
 *********************************************************/
int log_record_get_line(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->line;
}


/*********************************************************
 *
 * Set source line number
 *
 *********************************************************/
void log_record_set_line(log_record_t* self,
                            int line)
{
    if (!self)
        return;

    self->line = line;

}


/*********************************************************
 *
 * Get date in Mmm dd yyyy format
 *
 *********************************************************/
const char* log_record_get_date(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->date;
}


/*********************************************************
 *
 * Set date in Mmm dd yyyy format
 *
 *********************************************************/
void log_record_set_date(log_record_t* self,
                            const char* date)
{
    if (!self || !date)
        return;

    strncpy(self->date, date, LOG_RECORD_DATE_LEN);

}

/*********************************************************
 *
 * Get time in hh:mm:ss format
 *
 *********************************************************/
const char* log_record_get_time(const log_record_t* self)
{
    if (!self)
        return 0;

    return self->time;
}


/*********************************************************
 *
 * Set time hh:mm:ss format.
 *
 *********************************************************/
void log_record_set_time(log_record_t* self,
                            const char* time)
{
    if (!self || !time)
        return;

    strncpy(self->time, time, LOG_RECORD_TIME_LEN);

}



