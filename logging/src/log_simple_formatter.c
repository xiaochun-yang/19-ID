#include "log_formatter.h"
#include "log_simple_formatter.h"
#include "log_handler.h"


/*********************************************************
 *
 * new simple_formatter data structure
 * Print a brief summary of the LogRecord in a human readable format. 
 * The summary will typically be 1 or 2 lines. 
 *
 *********************************************************/
struct __simple_format_data
{
	char msg[LOG_SIMPLE_MSG_LEN];

};

typedef struct __simple_format_data simple_format_data_t;


/*********************************************************
 *
 * Get the data from log_formatter_t
 *
 *********************************************************/
static simple_format_data_t* get_data(log_formatter_t* self)
{
	return (simple_format_data_t*)self->data_;
}

/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 *
 *********************************************************/
static const char* format(log_formatter_t* self, log_record_t* record)
{
	simple_format_data_t* data = get_data(self);
	strcpy(data->msg, log_record_get_message(record));

	return data->msg;
}

/*********************************************************
 *
 * Reconstruct a log_record_t from the string
 *********************************************************/
static xos_result_t parse(log_formatter_t* self, const char* msg, log_record_t* record)
{
	if (self && msg && record) {
		// TODO
	}
	
	return XOS_SUCCESS;
}


/*********************************************************
 *
 * Deallocate memory for log_formatter_t
 *
 *********************************************************/
static void data_free(void* d)
{
	if (!d)
		return;

	free((simple_format_data_t*)d);

}


/*********************************************************
 *
 * Init method. Must be called to initialize a log_formatter_t
 * created on stack.
 *
 *********************************************************/
void log_simple_formatter_init(log_formatter_t* self)
{
	// Importing the function
	void __log_formatter_init(log_formatter_t*);

	simple_format_data_t* d = NULL;

	if (!self)
		return;

	// Initialize the base class first
	__log_formatter_init(self);

	d = (simple_format_data_t*)malloc(sizeof(simple_format_data_t));

	self->data_ = (void*)d;
	self->data_free_ = &data_free;
	self->format = &format;
	self->parse = &parse;
}

/*********************************************************
 *
 * New() method. Must be called to create a log_formatter_t
 * on heap.
 *
 *********************************************************/
log_formatter_t* log_simple_formatter_new()
{
	// Importing the function
	log_formatter_t* __log_formatter_new();

	log_formatter_t* self =  __log_formatter_new();

	log_simple_formatter_init(self);

	return self;

}

