#include "xos.h"
#include "logging.h"



/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
void log_handler_destroy(log_handler_t* self)
{
	if (!self)
		return;


	// Call the subclass to 
	self->destroy(self);

}


/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
void log_handler_free(log_handler_t* self)
{
	if (!self)
		return;


	log_handler_destroy(self);

	free(self);
}

/*********************************************************
 *
 * Flush any buffered output.
 *
 *********************************************************/
void log_handler_flush(log_handler_t* self)
{
	if (self)
		self->flush(self);
}

/*********************************************************
 *
 * Close the Handler and free all associated resources.
 * The close method will perform a flush and then close the Handler.
 * After close has been called this Handler should no longer be used.
 * Method calls may either be silently ignored or may throw runtime exceptions.
 *
 *********************************************************/
void log_handler_close(log_handler_t* self)
{
	if (self)
		self->close(self);
}

/*********************************************************
 *
 * Return the character encoding for this Handler.
 *
 *********************************************************/
const char* log_handler_get_encoding(const log_handler_t* self)
{
	return NULL;
}


/*********************************************************
 *
 * Get the current Filter for this Handler.
 *
 *********************************************************/
log_filter_t* log_handler_get_filter(const log_handler_t* self)
{
	if (self)
		return self->filter;

	return NULL;

}

/*********************************************************
 *
 * Return the Formatter for this Handler.
 *
 *********************************************************/
log_formatter_t* log_handler_get_formatter(const log_handler_t* self)
{
	if (self)
		return self->formatter;

	return NULL;
}

/*********************************************************
 *
 * Get the log level specifying which messages will be logged by
 * this Handler. Message levels lower than this level will be discarded.
 *
 *********************************************************/
log_level_t* log_handler_get_level(const log_handler_t* self)
{
	if (self)
		return self->level;

	return NULL;
}

/*********************************************************
 *
 * Check if this Handler would actually log a given LogRecord.
 * This method checks if the LogRecord has an appropriate Level
 * and whether it satisfies any Filter. It also may make other
 * Handler specific checks that might prevent a handler from
 * logging the LogRecord.
 *
 *********************************************************/
BOOL log_handler_is_loggable(const log_handler_t* self, log_record_t* record)
{
	if (!self)
		return LOG_FALSE;


	if (log_level_get_int_value(self->level) <=
			log_level_get_int_value(log_record_get_level(record)))
		return TRUE;

	if (self->filter) {
		return self->filter->is_loggable(self->filter, record);
	}

	return FALSE;

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
void log_handler_publish(log_handler_t* self, log_record_t* record)
{
	if (self && log_handler_is_loggable(self, record)) {
		self->publish(self, record);
	}
}

/*********************************************************
 *
 * Protected convenience method to report an error to this Handler's
 * ErrorManager. Note that this method retrieves and uses the ErrorManager
 * without doing a security check. It can therefore be used in environments where the caller may be non-privileged.
 *
 *********************************************************/
static void report_error(log_handler_t* self, const char* msg, int code)
{
	// do nothing
}

/*********************************************************
 *
 * Set the character encoding used by this Handler.
 * The encoding should be set before any LogRecords are written to the Handler.
 *
 *********************************************************/

static void set_encoding(log_handler_t* self, const char* encoding)
{
	// Not implemented
}


/*********************************************************
 *
 * Set a Filter to control output on this Handler.
 * For each call of publish the Handler will call this Filter
 * (if it is non-null) to check if the LogRecord should be published or discarded.
 *
 *********************************************************/
void log_handler_set_filter(log_handler_t* self, log_filter_t* filter)
{
	if (self) {
		self->filter = filter;
	}
}

/*********************************************************
 *
 * Set a Formatter. This Formatter will be used to format LogRecords
 * for this Handler.
 * Some Handlers may not use Formatters, in which case the Formatter
 * will be remembered, but not used.
 *
 *********************************************************/
void log_handler_set_formatter(log_handler_t* self, log_formatter_t* formatter)
{
	if (self) {
		self->formatter = formatter;
	}
}

/*********************************************************
 *
 * Set the log level specifying which message levels will be logged by
 * this Handler. Message levels lower than this value will be discarded.
 * The intention is to allow developers to turn on voluminous logging,
 * but to limit the messages that are sent to certain Handlers.
 *
 *********************************************************/
void log_handler_set_level(log_handler_t* self, log_level_t* level)
{
	if (self) {
		self->level = level;
	}
}

/*********************************************************
 *
 * dummy
 *
 *********************************************************/
static void close_(log_handler_t* self)
{
}


/*********************************************************
 *
 * dummy
 *
 *********************************************************/
static void flush_(log_handler_t* self)
{
}


/*********************************************************
 *
 * dummy
 *
 *********************************************************/
static void publish(log_handler_t* self, log_record_t* record)
{
	// do nothing
}

/*********************************************************
 *
 * dummy
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	// do nothing
}



/*********************************************************
 *
 * Init memory for log_handler_t
 *
 *********************************************************/
void __log_handler_init(log_handler_t* self)
{
	if (!self)
		return;


	self->data_ = NULL;
	self->filter = NULL;
	self->formatter = NULL;
	self->level = LOG_INFO;

	self->close = &close_;
	self->flush = &flush_;
	self->publish = &publish;
	self->destroy = &destroy;

}


/*********************************************************
 *
 * Creates a new log_handler_t
 * Default constructor. The resulting Handler has a log level of Level.ALL,
 * no Formatter, and no Filter. A default ErrorManager instance is installed
 * as the ErrorManager.
 *
 *********************************************************/
log_handler_t*  __log_handler_new()
{
	log_handler_t* self = (log_handler_t*)malloc(sizeof(log_handler_t));

	// Null the pointers and set methods to default.
	__log_handler_init(self);

	return self;
}

