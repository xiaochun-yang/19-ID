#include "xos_hash.h"
#include "log_formatter.h"
#include "log_token_formatter.h"
#include "log_handler.h"


/*********************************************************
 *
 * new token_formatter data structure
 * Print a brief summary of the LogRecord in a human readable format. 
 * The summary will typically be 1 or 2 lines. 
 *
 *********************************************************/
struct __token_format_data
{
	char separator;
	char msg[LOG_TOKEN_MSG_LEN];
	char head[2];
	char tail[2];

};

typedef struct __token_format_data token_format_data_t;


/*********************************************************
 *
 * Get the data from log_formatter_t
 *
 *********************************************************/
static token_format_data_t* get_data(log_formatter_t* self)
{
	return (token_format_data_t*)self->data_;
}

/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 *
 *********************************************************/
static const char* format(log_formatter_t* self, log_record_t* record)
{
	int len = 0;
	char tmp[5];
	xos_hash_t* params;

	token_format_data_t* data = get_data(self);

	if (!data)
		return NULL;

	strcpy(data->msg, "");

	strcpy(data->head, "");

	strcpy(data->tail, "");


	SNPRINTF(data->msg, LOG_TOKEN_MSG_LEN, "%04d%c%s%c%d%c%s%c%d%c%s%c%s%c%s%c%s%c%s%c%d%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%s%c%d%c%s%c%d%c",
			0,
			't',
			THREADID_FIELD,
			data->separator,
			log_record_get_thread_id(record),
			data->separator,
			MILLIS_FIELD,
			data->separator,
			log_record_get_millis(record),
			data->separator,
			LEVEL_FIELD,
			data->separator,
			log_level_get_name(log_record_get_level(record)),
			data->separator,
			LOGGER_FIELD,
			data->separator,
			log_record_get_logger_name(record),
			data->separator,
			SEQUENCE_FIELD,
			data->separator,
			log_record_get_sequence_number(record),
			data->separator,
			CLASS_FIELD,
			data->separator,
			log_record_get_source_class_name(record),
			data->separator,
			METHOD_FIELD,
			data->separator,
			log_record_get_source_method_name(record),
			data->separator,
			MESSAGE_FIELD,
			data->separator,
			log_record_get_message(record),
			data->separator,
			DATE_FIELD,
			data->separator,
			log_record_get_date(record),
			data->separator,
			TIME_FIELD,
			data->separator,
			log_record_get_time(record),
			data->separator,
			FILE_FIELD,
			data->separator,
			log_record_get_file(record),
			data->separator,
			LINE_FIELD,
			data->separator,
			log_record_get_line(record),
			data->separator,
			PROCESSID_FIELD,
			data->separator,
			log_record_get_process_id(record),
			data->separator
			);

	// Now add the params
	params = (xos_hash_t*)log_record_get_parameters(record);
	if (params != NULL) {
		xos_iterator_t entryIterator;
		char* value;
		char name[250];

		/* publish the record through all handlers*/
		if ( xos_hash_get_iterator(params, & entryIterator ) == XOS_SUCCESS ) {

			/* loop over all hash table entries to find oldest entry */
			while ( xos_hash_get_next(params, name,
					(xos_hash_data_t *) &value, & entryIterator ) == XOS_SUCCESS )
			{
				if (value != NULL) {
					strcat(data->msg, name);
					strcat(data->msg, "|");
					strcat(data->msg, value);
					strcat(data->msg, "|");
				}
			}
		}

	}

	// Trucate the message if it's too long
	len = strlen(data->msg);
//	if (len >= LOG_TOKEN_MSG_LEN)
//		data->msg[LOG_TOKEN_MSG_LEN] = '\0';

	// rewrite the first 4 bytes
	len -= 5;
	SNPRINTF(tmp, 5, "%04d", len);
	data->msg[0] = tmp[0];
	data->msg[1] = tmp[1];
	data->msg[2] = tmp[2];
	data->msg[3] = tmp[3];

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

	free((token_format_data_t*)d);

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
	token_format_data_t* data = get_data(self);
	if (data) {
		return data->head;
	}

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
	token_format_data_t* data = get_data(self);
	if (data) {
		return data->tail;
	}

	return NULL;

}


/*********************************************************
 *
 * Init method. Must be called to initialize a log_formatter_t
 * created on stack.
 *
 *********************************************************/
void log_token_formatter_init(log_formatter_t* self, char separator)
{
	// Importing the function
	void __log_formatter_init(log_formatter_t*);

	token_format_data_t* d = NULL;

	if (!self)
		return;

	// Initialize the base class first
	__log_formatter_init(self);

	d = (token_format_data_t*)malloc(sizeof(token_format_data_t));

	d->separator = separator;
	strcpy(d->msg, "");

	self->data_ = (void*)d;
	self->data_free_ = &data_free;
	self->format = &format;
	self->parse = &parse;
	self->get_head = &get_head;
	self->get_tail = &get_tail;
}

/*********************************************************
 *
 * New() method. Must be called to create a log_formatter_t
 * on heap.
 *
 *********************************************************/
log_formatter_t* log_token_formatter_new(char separator)
{
	// Importing the function
	log_formatter_t* __log_formatter_new();

	log_formatter_t* self =  __log_formatter_new();

	if (!separator)
		separator = '|';

	log_token_formatter_init(self, separator);

	return self;

}

