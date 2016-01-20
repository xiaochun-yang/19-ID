#include "logging.h"


/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
typedef struct __log_console_data
{
	/* stdout or stderr */
	FILE* stream;
} log_console_data_t;



/*********************************************************
 *
 * Flush any buffered output.
 *
 *********************************************************/
static void flush_(log_handler_t* self)
{
	log_console_data_t* console = (log_console_data_t*)self->data_;
	if (!console)
		return;
	fflush(console->stream);
}

/*********************************************************
 *
 * Close the Handler and free all associated resources.
 * The close method will perform a flush and then close the Handler.
 * After close has been called this Handler should no longer be used.
 * Method calls may either be silently ignored or may throw runtime exceptions.
 *
 *********************************************************/
static void close_(log_handler_t* self)
{
	// flush the remaining buffer
	log_console_data_t* console = (log_console_data_t*)self->data_;
	if (!console)
		fflush(console->stream);
	// nothing to close
}

/*********************************************************
 *
 * Called when the base class's destroy() is called.
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	close_(self);
	free((log_console_data_t*)self->data_);
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
	log_console_data_t* data = (log_console_data_t*)self->data_;
	if (data) {
		fprintf(data->stream, "%s", 
			log_formatter_format(log_handler_get_formatter(self), record));
		fflush(data->stream);
	}

}


/*********************************************************
 *
 * Creates a new log_handler_t
 * Default constructor. The resulting Handler has a log level of Level.ALL,
 * no Formatter, and no Filter. A default ErrorManager instance is installed
 * as the ErrorManager.
 *
 *********************************************************/
void log_console_handler_init(log_handler_t* self, FILE* stream)
{
	log_handler_t* __log_handler_init(log_handler_t*);
	log_console_data_t* d = NULL;

	if (!self)
		return;

	// Initialize base class
	__log_handler_init(self);

	d = malloc(sizeof(log_console_data_t));
	if (d) {
		if (stream == stdout)
			d->stream = stdout;
		else if (stream == stderr)
			d->stream = stderr;
	}
	self->data_ = d;
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
log_handler_t* log_console_handler_new(FILE* stream)
{
	log_handler_t* __log_handler_new();

	log_handler_t* self = __log_handler_new();
	
	log_console_handler_init(self, stream);

	return self;
}

