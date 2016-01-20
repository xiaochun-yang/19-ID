#include <stdio.h>
#include <stdarg.h>


#include "logging.h"

static int saveLoggerError = 1;

void set_save_logger_error(int flag)
{
    if (flag != 0)
	saveLoggerError = 1;
    else 
	saveLoggerError = 0;
}

void save_logger_error( const char* message )
{
    if (saveLoggerError) { 

    static unsigned long errCount = 0;
    unsigned int thread_id = xos_thread_current_id( );

    struct tm my_localtime;
    time_t now = time( NULL );
    char timeStamp[64] = {0};
    FILE* errStream = fopen( "LOG_SELF_ERROR.txt", "a" );
#ifdef LINUX
    localtime_r( &now, &my_localtime );
#else
    my_localtime = *localtime( &now );
#endif
	sprintf( timeStamp, "%02d/%02d/%02d %02d:%02d:%02d %u",
                            my_localtime.tm_mon + 1,
                            my_localtime.tm_mday,
                            my_localtime.tm_year % 100,
                            my_localtime.tm_hour,
                            my_localtime.tm_min,
                            my_localtime.tm_sec,
                            thread_id );

    if (errStream)
    {
        fprintf( errStream, "[%lu]%s: %s\n", errCount, timeStamp, message );
        fclose( errStream );
    }
    else
    {
        printf( "LOGGER SELF ERROR %lu: thread %u %s\n", errCount, thread_id, message );
    }

    } // saveLoggerError
}

/*********************************************************
 *
 * Adds a child to the children hash table
 *
 *********************************************************/
void get_hex(void* pointer, char* ret)
{
	if (ret)
		sprintf(ret, "%#p", pointer);
}

/*********************************************************
 *
 * Adds a child to the children hash table
 *
 *********************************************************/
static void add_child(logger_t* self, logger_t* child)
{
	char hex[INT_STR_LEN];

	if (!self || !child)
		return;

	get_hex(child, hex);
	if ( xos_hash_add_entry( &self->children, hex,
			(xos_hash_data_t) child ) != XOS_SUCCESS )
	{
		// Do nothing
	}

}
/*********************************************************
 *
 * Removes a child to the children hash table
 *
 *********************************************************/
static void remove_child(logger_t* self, logger_t* child)
{
	char hex[INT_STR_LEN];

	if (!self || !child)
		return;

	get_hex(child, hex);
	if ( xos_hash_delete_entry( &self->children, hex) != XOS_SUCCESS )
	{
		// Do nothing
	}

}

/*********************************************************
 *
 * Initialize a logger_t
 *
 *********************************************************/
void logger_init(logger_t* self,
					const char* name,
					logger_t* parent,
					log_level_t* level)
{
	logger_t* ancester = NULL;

	if (!self)
		return;

	if (name)
		strcpy(self->name, name);
	else
		strcpy(self->name, "");

	self->parent = parent;

	self->level = (log_level_t*)level;
	if (level == NULL) {
		ancester = parent;
		while (ancester) {
			if (ancester->level != NULL) {
				self->level = ancester->level;
				break;
			}
			ancester = ancester->parent;
		}
	}

	// Inherit level from root

	// allow 10 handler initially
	xos_hash_initialize(&self->children, 10, NULL);

	// allow 10 handler initially
	xos_hash_initialize(&self->handlers, 10, NULL);

	// Add this logger as a child of its parent
	if (self->parent != NULL) {
		add_child(self->parent, self);
	}

	self->is_use_parent_handlers = FALSE;
	self->filter = NULL;

	self->loggerLock = malloc( sizeof(xos_mutex_t) );
	if (self->loggerLock) {
		if (xos_mutex_create( self->loggerLock ) != XOS_SUCCESS)
		{
			free( self->loggerLock );
			self->loggerLock = NULL;
		}
	}
    else
    {
        save_logger_error( "malloc for mutex failed" );
        printf( "logger failed to get a mutex\n" );
        exit( -1 );
    }
    self->numHandlers = 0;
}


/*********************************************************
 *
 * Creates a new logger_t
 *
 *********************************************************/
logger_t* logger_new(const char* name,
					logger_t* parent,
					log_level_t* level)
{
	logger_t* self = malloc(sizeof(logger_t));

	logger_init(self, name, parent, level);
	
	return self;
}

/*********************************************************
 *
 * Deallocate memory for member variables of logger_t
 *
 *********************************************************/
void logger_destroy(logger_t* self)
{

	if (!self)
		return;

	remove_child(self->parent, self);
	xos_hash_destroy(&self->children);
	xos_hash_destroy(&self->handlers);

	if (self->loggerLock) {
		xos_mutex_close( self->loggerLock );
		free( self->loggerLock );
		self->loggerLock = NULL;
	}


}

/*********************************************************
 *
 * Deallocate memory for member variables of logger_t
 *
 *********************************************************/
void logger_free(logger_t* self)
{

	if (!self)
		return;

	logger_destroy(self);

	free(self);
}


/*********************************************************
 *
 * Set a filter to control output on this Logger.
 * After passing the initial "level" check, the Logger will call this Filter
 * to check if a log record should really be published.
 *
 *
 * @param newFilter - a filter object (may be null)
 *
 *********************************************************/
void logger_set_filter(logger_t* self, log_filter_t* filter)
{
	if (self)
		self->filter = filter;
}


/*********************************************************
 *
 * Log a message, with no arguments.
 * If the logger is currently enabled for the given message level
 * then the given message is forwarded to all the registered output Handler objects.
 *
 * @param level - One of the message level identifiers, e.g. SEVERE
 * @param msg - The string message (or a key in the message catalog)
 *
 *********************************************************/
log_filter_t* logger_get_filter(logger_t* self)
{
	if (self)
		return self->filter;

	return NULL;
}

/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
void log_r(logger_t* self, log_record_t* record)
{
	xos_iterator_t entryIterator;
	log_handler_t* handler;
	char hex[INT_STR_LEN];
    int num = 0;
	if (!self || !record)
    {
        if (!self) save_logger_error( "self is NULL in log_r" );
        if (!record) save_logger_error( "record is NULL in log_r" );
		return;
    }

	// check if we should publish this message or not based on
	// log level.
	if (!logger_is_loggable(self, log_record_get_level(record)))
	{
//        save_logger_error( "not logable" );
		return;
	}

	/* publish the record through all handlers*/
	if ( xos_hash_get_iterator( &self->handlers, & entryIterator ) != XOS_SUCCESS )
	{
        if (self->numHandlers != 0)
        {
            save_logger_error( "no handlers but numHandler != 0" );
        }
		return;
	}

	/* loop over all hash table entries to find oldest entry */
	while ( xos_hash_get_next( &self->handlers, hex,
						(xos_hash_data_t *) &handler, & entryIterator ) == XOS_SUCCESS )
	{
		log_handler_publish(handler, record);
        ++num;
	}
    if (num < self->numHandlers)
    {
        char message[128] = {0};
        sprintf( message, "only %d of %d handers called", num, self->numHandlers );
        save_logger_error( message );
    }
}

/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
void log_v(logger_t* self, log_level_t* level, const char* format, ...)
{
	va_list     ap;
	log_record_t* record = NULL;

	if (!self || !level || !format)
    {
        if (!self) save_logger_error( "self NULL in log_v" );
        if (!level) save_logger_error( "level NULL in log_v" );
        if (!format) save_logger_error( "format NULL in log_v" );
		return;
    }

	if (self->loggerLock)
	{
		if (xos_mutex_lock( self->loggerLock ) != XOS_SUCCESS) {
            save_logger_error( "failed to get mutex" );
			return;
		}
	}


	va_start(ap, format);
	record = log_record_new_va(level, format, ap);
	log_record_set_logger_name(record, logger_get_name(self));
	va_end(ap);
	log_r(self, record);
	log_record_free(record);

	if (self->loggerLock) xos_mutex_unlock( self->loggerLock );
}



/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
static void log_va(logger_t* self, log_level_t* level, 
				   const char* format, va_list ap)
{
	log_record_t* record = NULL;
    char dummy[2] = {0};

	if (!self || !level || !format)
    {
        if (!self) save_logger_error( "self NULL in log_va" );
        if (!level) save_logger_error( "level NULL in log_va" );
        if (!format) save_logger_error( "format NULL in log_va" );
		return;
    }

	if (self->loggerLock)
	{
		if (xos_mutex_lock( self->loggerLock ) != XOS_SUCCESS) {
            save_logger_error( "failed to get mutex" );
			return;
		}
	}

	record = log_record_new_va(level, format, ap);
	log_record_set_logger_name(record, logger_get_name(self));
	log_record_set_file(record, dummy);
	log_record_set_line(record, 0);
	log_record_set_date(record, dummy);
	log_record_set_time(record, dummy);
	log_r(self, record);
	log_record_free(record);

	if (self->loggerLock) xos_mutex_unlock( self->loggerLock );
}

/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
static void log_details_va(const char* file, 
							int line, 
							const char* date,
							const char* time,
						    logger_t* self, log_level_t* level, 
						    const char* format, va_list ap)
{
	log_record_t* record = NULL;

	if (!self || !level || !format || !file || !date || !time)
    {
        if (!self) {
				if (file != null) {
					char b[500];
					strcpy(b, "");
					sprintf(b, "self NULL in log_details_va, called from file %s", file);
					if (format != null) {
						VSNPRINTF(b, 500, format, ap);
						save_logger_error(b);	
					}
			   } else {
					save_logger_error( "self NULL in log_details_va" );
				}
		  }
        if (!level) save_logger_error( "level NULL in log_details_va" );
        if (!format) save_logger_error( "format NULL in log_details_va" );
        if (!file) save_logger_error( "file NULL in log_details_va" );
        if (!date) save_logger_error( "date NULL in log_details_va" );
        if (!time) save_logger_error( "time NULL in log_details_va" );
		return;
    }

	if (self->loggerLock)
	{
		if (xos_mutex_lock( self->loggerLock ) != XOS_SUCCESS) {
            save_logger_error( "failed to get mutex" );
			return;
		}
	}

	record = log_record_new_va(level, format, ap);
	log_record_set_logger_name(record, logger_get_name(self));
	log_record_set_file(record, file);
	log_record_set_line(record, line);
	log_record_set_date(record, date);
	log_record_set_time(record, time);
	log_r(self, record);
	log_record_free(record);

	if (self->loggerLock) xos_mutex_unlock( self->loggerLock );
}

/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
void log_p(logger_t* self,
			log_level_t* level,
			const char* source_class,
			const char* source_method,
			const char* msg)
{
	log_record_t* record = NULL;

	if (!self || !level || !source_class || !source_method || !msg)
    {
        if (!self) save_logger_error( "self NULL in log_p" );
        if (!level) save_logger_error( "level NULL in log_p" );
        if (!source_class) save_logger_error( "source_class NULL in log_p" );
        if (!source_method) save_logger_error( "source_method NULL in log_p" );
        if (!msg) save_logger_error( "msg NULL in log_p" );
		return;
    }

	if (self->loggerLock)
	{
		if (xos_mutex_lock( self->loggerLock ) != XOS_SUCCESS) {
            save_logger_error( "failed to get mutex" );
			return;
		}
	}

	record = log_record_new(level, msg);
	log_record_set_logger_name(record, logger_get_name(self));
	log_record_set_source_class_name(record, source_class);
	log_record_set_source_method_name(record, source_method);
	log_r(self, record);
	log_record_free(record);

	if (self->loggerLock) xos_mutex_unlock( self->loggerLock );
}


/*********************************************************
 *
 * Log a method entry.
 * This is a convenience method that can be used to log entry to a method.
 * A LogRecord with message "ENTRY", log level FINER, and the given
 * sourceMethod and sourceClass is logged.
 *
 * Parameters:
 * @param sourceClass - name of class that issued the logging request
 * @param sourceMethod - name of method that is being entered
 *
 *********************************************************/
void entering(logger_t* self,
			const char* source_class,
			const char* source_method)
{
	log_p(self, LOG_FINER, source_class, source_method, "ENTRY");
}

/*********************************************************
 *
 * Log a method return.
 * This is a convenience method that can be used to log returning
 * from a method. A LogRecord with message "RETURN", log level FINER,
 * and the given sourceMethod and sourceClass is logged.
 * Parameters:
 * @param sourceClass - name of class that issued the logging request
 * @param sourceMethod - name of the method
 *
 *********************************************************/
void exiting(logger_t* self,
			const char* source_class,
			const char* source_method)
{
	log_p(self, LOG_FINER, source_class, source_method, "RETURN");
}


/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
void loglog(logger_t* self, log_level_t* level, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, level, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a LogRecord.
 * All the other logging methods in this class call through this method
 * to actually perform any logging. Subclasses can override this single
 * method to capture all log activity.
 *
 *********************************************************/
void log_details(const char* file, 
					int line, 
					const char* date,
					const char* time,
					logger_t* self, 
					log_level_t* level, 
					const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, level, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a SEVERE message.
 * If the logger is currently enabled for the SEVERE message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void severe(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_SEVERE, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a SEVERE message.
 * If the logger is currently enabled for the SEVERE message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void severe_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_SEVERE, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a WARNING message.
 * If the logger is currently enabled for the WARNING message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void warning(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_WARNING, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a WARNING message.
 * If the logger is currently enabled for the WARNING message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void warning_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_WARNING, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a INFO message.
 * If the logger is currently enabled for the INFO message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void info(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_INFO, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a INFO message.
 * If the logger is currently enabled for the INFO message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void info_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_INFO, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a CONFIG message.
 * If the logger is currently enabled for the CONFIG message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void config(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_CONFIG, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a CONFIG message.
 * If the logger is currently enabled for the CONFIG message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void config_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_CONFIG, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINE message.
 * If the logger is currently enabled for the FINE message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void fine(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_FINE, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINE message.
 * If the logger is currently enabled for the FINE message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void fine_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_FINE, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINER message.
 * If the logger is currently enabled for the FINER message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void finer(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_FINER, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINER message.
 * If the logger is currently enabled for the FINER message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void finer_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_FINER, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINEST message.
 * If the logger is currently enabled for the FINEST message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 *
 * Parameters:
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void finest(logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_va(self, LOG_FINEST, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Log a FINEST message.
 * If the logger is currently enabled for the FINEST message level
 * then the given message is forwarded to all the registered
 * output Handler objects.
 * Typically, this method is invoked from a macro where __FILE__,
 * __LINE__, __DATE__, __TIME__ macros are automatically added
 * to the function call.
 *
 * Parameters:
 * @param file - Name of the source file 
 * @param line - Line number in the source file
 * @param date - Date 
 * @param time - Time. 
 * @param format - Format for the message
 * @param ... - List of parameters 
 *
 *********************************************************/
void finest_details(const char* file, 
					int line, 
					const char* date,
					const char* time, 
					logger_t* self, const char* format, ...)
{
	va_list     ap;
	va_start(ap, format);
	log_details_va(file, line, date, time, self, LOG_FINEST, format, ap);
	va_end(ap);
}


/*********************************************************
 *
 * Get the log Level that has been specified for this Logger.
 * The result may be null, which means that this logger's effective
 * level will be inherited from its parent.
 *
 * Returns:
 * this Logger's level
 *
 *********************************************************/
log_level_t* logger_get_level(logger_t* self)
{
	if (self)
		return self->level;

	return NULL;
}

/*********************************************************
 *
 * Set the log level specifying which message levels will be logged
 * by this logger. Message levels lower than this value will be
 * discarded. The level value Level.OFF can be used to turn off logging.
 * If the new level is null, it means that this node should inherit
 * its level from its nearest ancestor with a specific (non-null)
 * level value.
 *
 * @param newLevel - the new value for the log level (may be null)
 *
 *********************************************************/
void logger_set_level(logger_t* self, log_level_t* level)
{
	if (self)
		self->level = (log_level_t*)level;

}


/*********************************************************
 *
 * Check if a message of the given level would actually be logged by
 * this logger. This check is based on the Loggers effective level,
 * which may be inherited from its parent.
 *
 * @param level - a message logging level
 * @return true if the given message level is currently being logged.
 *
 *********************************************************/
BOOL logger_is_loggable(logger_t* self, log_level_t* level)
{
	if (!self || !level)
		return FALSE;

	// For example if self->level =  LOG_FINER (2) and level = LOG_WANRING (8)
	// this method will return TRUE
	// For example if self->level =  LOG_SEVERE (7) and level = LOG_FINE (3)
	// this method will return FALSE
	return (log_level_get_int_value(self->level) <= log_level_get_int_value(level));
}

/*********************************************************
 *
 * Get the name for this logger.
 *
 *********************************************************/
const char* logger_get_name(logger_t* self)
{
	if (!self)
		return NULL;

	return self->name;
}


/*********************************************************
 *
 * Add a log Handler to receive logging messages.
 * By default, Loggers also send their output to their parent logger.
 * Typically the root Logger is configured with a set of Handlers that
 * essentially act as default handlers for all loggers.
 *
 * Parameters:
 * @param handler - a logging Handler
 *
 *********************************************************/
void logger_add_handler(logger_t* self, log_handler_t* handler)
{
	char hex[INT_STR_LEN];
	if (!self || !handler)
    {
        if (!self) save_logger_error( "self is null in logger_add_handler" );
        if (!handler) save_logger_error( "handler is null in logger_add_handler" );
        return;
    }

	get_hex(handler, hex);
	if ( xos_hash_add_entry( &self->handlers, hex,
			(xos_hash_data_t) handler ) != XOS_SUCCESS )
	{
		// Do nothing
        save_logger_error( "xos_hash_add_entry failed in logger_add_handler" );
	}
    else {
        ++self->numHandlers;
    }
}

/*********************************************************
 *
 * Remove a log Handler. Returns silently if the given Handler is not found.
 *
 * Parameters:
 * @param handler - a logging Handler
 *
 *********************************************************/
void logger_remove_handler(logger_t* self, log_handler_t* handler)
{
	char hex[INT_STR_LEN];
	if (!self || !handler)
    {
        if (!self) save_logger_error( "self is null in logger_remove_handler" );
        if (!handler) save_logger_error( "handler is null in logger_remove_handler" );
        return;
    }

	get_hex(handler, hex);

	if ( xos_hash_delete_entry( &self->handlers, hex) != XOS_SUCCESS)
	{
        save_logger_error( "xos_hash_delete_entry failed in logger_remove_handler" );
		// Do nothing
	}
    else
    {
        --self->numHandlers;
    }
}


/*********************************************************
 *
 * Get the Handlers associated with this logger.
 *
 *********************************************************/
xos_hash_t* logger_get_handlers(logger_t* self)
{

	if (self)
		return &self->handlers;

	return NULL;
}


/*********************************************************
 *
 * Specify whether or not this logger should send its output to it's
 * parent Logger. This means that any LogRecords will also be written
 * to the parent's Handlers, and potentially to its parent, recursively
 * up the namespace.
 *
 *********************************************************/
void logger_set_use_parent_handlers(logger_t* self, BOOL use_parent_handlers)
{

	if (self)
		self->is_use_parent_handlers = use_parent_handlers;

}


/*********************************************************
 *
 * Discover whether or not this logger is sending its output
 * to its parent logger.
 *
 *********************************************************/
BOOL logger_get_use_parent_handlers(logger_t* self)
{

	if (self)
		return self->is_use_parent_handlers;

	return FALSE;

}


/*********************************************************
 *
 * Set the parent for this Logger. This method is used by the
 * LogManager to update a Logger when the namespace changes.
 * It should not be called from application code.
 *
 * Parameters:
 * @param parent - the new parent logger
 *
 *********************************************************/
void logger_set_parent(logger_t* self, logger_t* parent)
{

	if (self)
		self->parent = parent;

}

/*********************************************************
 *
 * Return the parent for this Logger.
 * This method returns the nearest extant parent in the namespace.
 * Thus if a Logger is called "a.b.c.d", and a Logger called "a.b"
 * has been created but no logger "a.b.c" exists, then a call of
 * getParent on the Logger "a.b.c.d" will return the Logger "a.b".
 *
 * The result will be null if it is called on the root Logger
 * in the namespace.
 *
 * @return nearest existing parent Logger
 *
 *********************************************************/
logger_t* logger_get_parent(logger_t* self)
{

	if (self)
		return self->parent;

	return NULL;

}



xos_mutex_t* logger_get_lock(logger_t* self)
{
	if (self)
		return self->loggerLock;

	return NULL;
}

