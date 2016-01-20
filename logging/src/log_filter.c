#include "log_filter.h"

/*********************************************************
 *
 * A Filter can be used to provide fine grain control over what is logged,
 * beyond the control provided by log levels.
 *
 * Each Logger and each Handler can have a filter associated with it.
 * The Logger or Handler will call the isLoggable method to check if a
 * given LogRecord should be published. If isLoggable returns false,
 * the LogRecord will be discarded.
 *
 *********************************************************/

/*********************************************************
 * Check if a given log record should be published.
 *********************************************************/
BOOL is_loggable(log_filter_t* self, log_record_t* record)
{
	return LOG_TRUE;
}


/*********************************************************
 * Creates a new log_filter_t
 *********************************************************/
log_filter_t* __log_filter_new()
{
	log_filter_t* self = (log_filter_t*)malloc(sizeof(log_filter_t));

	if (!self)
		return NULL;

	self->data_ = NULL;
	self->data_free_ = NULL;

	self->is_loggable = &is_loggable;

	return self;
}


/*********************************************************
 * Deletes a log_filter_t
 *********************************************************/
void log_filter_free(log_filter_t* self)
{
	if (!self)
		return;

	if (self->data_ && self->data_free_) {
		self->data_free_(self->data_);
	}

	self->data_ = NULL;

	free(self);

}


