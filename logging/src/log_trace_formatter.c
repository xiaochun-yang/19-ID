#include "xos_hash.h"
#include "log_formatter.h"
#include "log_trace_formatter.h"
#include "log_handler.h"
#include "log_record.h"


/*********************************************************
 *
 * new trace_formatter data structure
 * Print a brief summary of the LogRecord in a human readable format. 
 * The summary will typically be 1 line. 
 *
 *********************************************************/
struct __trace_format_data
{
	char msg[LOG_SIMPLE_MSG_LEN];
};

typedef struct __trace_format_data trace_format_data_t;


/*********************************************************
 *
 * Get the data from log_formatter_t
 *
 *********************************************************/
static trace_format_data_t* get_data(log_formatter_t* self)
{
	return (trace_format_data_t*)self->data_;
}

/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 *
 *********************************************************/
static const char* format(log_formatter_t* self, log_record_t* record)
{
	trace_format_data_t* data = get_data(self);
	time_t time_value;
	struct tm time_now;
	
/*	char buffer[128] = {0};*/

	if (!data)
		return NULL;

	strcpy(data->msg, "");

	time( &time_value );
#ifdef LINUX
	localtime_r( &time_value, &time_now );	//thread safe version
#else
	time_now = *localtime( &time_value );
#endif



	//the format will be:
	//DATE TIME ThreadID LEVEL MESSAGE (FILE LINE CLASS METHOD)\n

	//create timestamp: "MM/DD/YY HH/mm/ss"
	if (SNPRINTF( data->msg, LOG_SIMPLE_MSG_LEN, "%02d/%02d/%02d %02d:%02d:%02d %8u %8s    %s",
			time_now.tm_mon + 1,
			time_now.tm_mday,
			time_now.tm_year % 100,
			time_now.tm_hour,
			time_now.tm_min,
			time_now.tm_sec,
			log_record_get_thread_id( record ),
			log_level_get_name( log_record_get_level( record ) ),
			log_record_get_message( record )) < 0) 
	{

		// String has been truncated by snprintf. Then forget about the rest
		data->msg[LOG_SIMPLE_MSG_LEN-2] = '\n';
		data->msg[LOG_SIMPLE_MSG_LEN-1] = '\0';
		return data->msg;
		
	}
			
			


//	strcat( data->msg, "    " );
//	strcat( data->msg, log_record_get_message( record ) ); //no overflow.

	

	//take \n out of the record's msg
	{
		size_t len = strlen(data->msg );
		if (len > 0 && data->msg[len - 1] == '\n') 
			data->msg[len - 1] = '\0';
	}
/*

	//extra: file, line, class, method
	strcat( data->msg, " {" );
	strcat( data->msg, log_record_get_file( record ) );

	sprintf( buffer, " %d", log_record_get_line( record ) );
	strcat( data->msg,  buffer);

	strcat( data->msg, " " );
	strcat( data->msg, log_record_get_source_class_name( record ) );

	strcat( data->msg, " " );
	strcat( data->msg, log_record_get_source_method_name( record ) );

	strcat( data->msg, "}\n" );

*/
	{
		char buf[500];

        const char* file_name = log_record_get_file( record );
        int line_num = log_record_get_line( record );
        const char* class_name = log_record_get_source_class_name( record );
        const char* method_name = log_record_get_source_method_name( record );

        if ((file_name && file_name[0]) ||
            (class_name && class_name[0]))
        {
            if (line_num == 0)
            {
		        SNPRINTF( buf, 500, " {%s %s %s}\n", 
                    file_name, class_name, method_name );
            }
            else
            {
		        SNPRINTF( buf, 500, " {%s %d %s %s}\n", 
                    file_name, line_num, class_name, method_name );
            }
		    // append as much as data->msg can hold
		    strncat(data->msg, buf, LOG_SIMPLE_MSG_LEN - 1 - strlen(data->msg));
        }
        else
        {
		    strcat(data->msg, "\n");
        }
	}
	
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

	free((trace_format_data_t*)d);

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
	return "";
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
	return "";
}


/*********************************************************
 *
 * Init method. Must be called to initialize a log_formatter_t
 * created on stack.
 *
 *********************************************************/
void log_trace_formatter_init(log_formatter_t* self )
{
	// Importing the function
	void __log_formatter_init(log_formatter_t*);

	trace_format_data_t* d = NULL;

	if (!self)
		return;

	// Initialize the base class first
	__log_formatter_init(self);

	d = (trace_format_data_t*)malloc(sizeof(trace_format_data_t));

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
log_formatter_t* log_trace_formatter_new( void )
{
	// Importing the function
	log_formatter_t* __log_formatter_new();

	log_formatter_t* self =  __log_formatter_new();

	log_trace_formatter_init( self );

	return self;

}

