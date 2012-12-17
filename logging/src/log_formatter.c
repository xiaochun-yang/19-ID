#include "log_formatter.h"
#include "log_handler.h"



/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 *
 *********************************************************/
static const char* format(log_formatter_t* self, log_record_t* record)
{
	return NULL;
}

/*********************************************************
 *
 * Reconstruct a log_record_t from the string
 *********************************************************/
static xos_result_t parse(log_formatter_t* self, const char* ret, log_record_t* record)
{
	// Do nothing
	return XOS_FAILURE;
}

/*********************************************************
 *
 * Localize and format the message string from a log record.
 * This method is provided as a convenience for Formatter
 * subclasses to use when they are performing formatting.
 * The message string is first localized to a format string using
 * the record's ResourceBundle. (If there is no ResourceBundle,
 * or if the message key is not found, then the key is used as
 * the format string.) The format String uses java.text style formatting.
 *
 * If there are no parameters, no formatter is used.
 * Otherwise, if the string contains "{0" then java.text.MessageFormat
 * is used to format the string.
 * Otherwise no formatting is performed.
 *
 *********************************************************/
static const char* format_message(log_formatter_t* self, log_record_t* record)
{
	return self->format(self, record);
}

/*********************************************************
 *
 * Return the header string for a set of formatted records.
 * This base class returns an empty string, but this may be
 * overriden by subclasses.
 *
 *********************************************************/
static const char* get_head(log_formatter_t* self, log_handler_t* handler)
{
	return NULL;
}


/*********************************************************
 *
 * Return the tail string for a set of formatted records.
 * This base class returns an empty string, but this may be
 * overriden by subclasses.
 *
 *********************************************************/
static const char* get_tail(log_formatter_t* self, log_handler_t* handler)
{

	return NULL;
}


/*********************************************************
 *
 * A Formatter provides support for formatting LogRecords.
 *
 * Typically each logging Handler will have a Formatter associated with it.
 * The Formatter takes a LogRecord and converts it to a string.
 *
 * Some formatters (such as the XMLFormatter) need to wrap head and tail
 * strings around a set of formatted records. The getHeader and getTail
 * methods can be used to obtain these strings.
 *
 *
 *********************************************************/
void __log_formatter_init(log_formatter_t* self)
{
	if (!self)
		return;

	self->data_ = NULL;
	self->data_free_ = NULL;

	self->format = &format;
	self->format_message = &format_message;
	self->get_head = &get_head;
	self->get_tail = &get_tail;
	self->parse = &parse;
}

/*********************************************************
 *
 * A Formatter provides support for formatting LogRecords.
 *
 * Typically each logging Handler will have a Formatter associated with it.
 * The Formatter takes a LogRecord and converts it to a string.
 *
 * Some formatters (such as the XMLFormatter) need to wrap head and tail
 * strings around a set of formatted records. The getHeader and getTail
 * methods can be used to obtain these strings.
 *
 *
 *********************************************************/
log_formatter_t* __log_formatter_new()
{
	log_formatter_t* self = (log_formatter_t*)malloc(sizeof(log_formatter_t));

	// Do not call init(). Expect the subclass to call it
	// in the subclass's init().
//	__log_formatter_init(self);

	return self;

}

/*********************************************************
 *
 * Deallocate memory for log_formatter_t
 *
 *********************************************************/
void log_formatter_destroy(log_formatter_t* self)
{

	if (self->data_ && self->data_free_) {
		self->data_free_(self->data_);
	}

}


/*********************************************************
 *
 * Deallocate memory for log_formatter_t
 *
 *********************************************************/
void log_formatter_free(log_formatter_t* self)
{
	if (!self)
		return;

	log_formatter_destroy(self);

	free(self);

}


/*********************************************************
 *
 * Public method
 *
 *********************************************************/
const char* log_formatter_format(log_formatter_t* self, log_record_t* record)
{
	if (!self)
		return NULL;
	
	return self->format(self, record);
}


/*********************************************************
 *
 * Public method
 *
 *********************************************************/
const char* log_formatter_format_message(log_formatter_t* self, log_record_t* record)
{
	if (!self)
		return NULL;

	return self->format_message(self, record);
}


/*********************************************************
 *
 * Public method
 *
 *********************************************************/
const char* log_formatter_get_head(log_formatter_t* self, 
								   log_handler_t* handler)
{
	if (!self)
		return NULL;

	return self->get_head(self, handler);
}

/*********************************************************
 *
 * Public method
 *
 *********************************************************/
const char* log_formatter_get_tail(log_formatter_t* self,
									log_handler_t* handler)
{
	if (!self)
		return NULL;

	return self->get_tail(self, handler);
}

/*********************************************************
 *
 * Public method
 *
 *********************************************************/
xos_result_t log_formatter_parse(log_formatter_t* self, const char* ret,
						log_record_t* record)
{
	if (!self)
		return XOS_FAILURE;

	return self->parse(self, ret, record);
}



