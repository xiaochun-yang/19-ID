#include "xos.h"
#include "log_formatter.h"
#include "log_xml_formatter.h"
#include "log_handler.h"

#define LOG_XML_HEAD_LEN 500
#define LOG_XML_TAIL_LEN 500
#define LOG_XML_MSG_LEN 1000

/*********************************************************
 *
 * new xml_formatter data structure
 *
 *********************************************************/
struct __xml_format_data
{
	char	head[LOG_XML_HEAD_LEN];
	char	tail[LOG_XML_TAIL_LEN];
	char	msg[LOG_XML_MSG_LEN];

};

typedef struct __xml_format_data xml_format_data_t;



/*********************************************************
 *
 * Get the data from log_format_t
 *
 *********************************************************/
static xml_format_data_t* get_data(log_formatter_t* self)
{
	return (xml_format_data_t*)self->data_;
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
	xml_format_data_t* data = get_data(self);
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
	xml_format_data_t* data = get_data(self);
	if (data) {
		return data->tail;
	}

	return NULL;

}

/*********************************************************
 *
 * Print a brief summary of the LogRecord in a human readable format.
 * The summary will typically be 1 or 2 lines.
 * 
 * <?xml version="1.0" encoding="UTF-8" standalone="no"?>
 * <!DOCTYPE log SYSTEM "logger.dtd">
 * <log>
 * <record>
 *   <date>2000-08-23 19:21:05</date>
 *   <millis>967083665789</millis>
 *   <sequence>1256</sequence>
 *   <logger>kgh.test.fred</logger>
 *   <level>INFO</level>
 *   <class>kgh.test.XMLTest</class>
 *   <method>writeLog</method>
 *   <thread>10</thread>
 *   <message>Hello world!</message>
 * </record>
 * </log> 
 *
 *********************************************************/
static const char* format(log_formatter_t* self, log_record_t* record)
{
	xml_format_data_t* data = get_data(self);

	if (!data)
		return NULL;

	if (!record)  {
		strcpy(data->msg, "");
		return data->msg;
	}


	{

	char seq[INT_STR_LEN];
	char thread[INT_STR_LEN];
	char process[INT_STR_LEN];
	char millis[INT_STR_LEN];

	sprintf(seq, "%d", log_record_get_sequence_number(record));
	sprintf(thread, "%d", log_record_get_thread_id(record));
	sprintf(process, "%d", log_record_get_process_id(record));
	sprintf(millis, "%lu", (unsigned long)log_record_get_millis(record));

	// Construct an XML string from the given record. 
	// Note that we construct the XML here rather than
	// in the log_record class because we want to separate
	// the formatting and the content of the record. This way
	// we can have more than one DTD for the log record.
	strcpy(data->msg, "");
	strcat(data->msg, "<record>\n");
	strcat(data->msg, "<date>");
	strcat(data->msg, millis);
	strcat(data->msg, "</date>\n");
	strcat(data->msg, "<sequence>");
	strcat(data->msg, seq);
	strcat(data->msg, "</sequence>\n");
	strcat(data->msg, "<logger>");
	strcat(data->msg, log_record_get_logger_name(record));
	strcat(data->msg, "</logger>\n");
	strcat(data->msg, "<level>");
	strcat(data->msg, log_level_get_name(log_record_get_level(record)));
	strcat(data->msg, "</level>\n");
	strcat(data->msg, "<class>");
	strcat(data->msg, log_record_get_source_class_name(record));
	strcat(data->msg, "</class>\n");
	strcat(data->msg, "<method>");
	strcat(data->msg, log_record_get_source_method_name(record));
	strcat(data->msg, "</method>\n");
	strcat(data->msg, "<thread>");
	strcat(data->msg, thread);
	strcat(data->msg, "</thread>\n");
	strcat(data->msg, "<process>");
	strcat(data->msg, process);
	strcat(data->msg, "</process>\n");
	strcat(data->msg, "<message>\n");
	strcat(data->msg, log_record_get_message(record));
	strcat(data->msg, "</message>\n");
	strcat(data->msg, "</record>\n");

	}

	return data->msg;

}


/*********************************************************
 *
 * returns true if the long_str begins with the short_str 
 * 
 *********************************************************/
static BOOL str_begins_with(const char* long_str, const char* short_str)
{
	
	return (strncmp(long_str, short_str, strlen(short_str)) == 0);
}

/*********************************************************
 *
 * Find the first occurence of the chararcter
 * 
 *********************************************************/
static int str_find(const char* long_str, int pos1, int pos2, char c)
{
	
	int i = pos1;

	while (i < pos2) {
		if (long_str[i] == c)
			return i;
		++i;
	}

	return -1;
}

/*********************************************************
 *
 * Find the last occurence of the chararcter
 * 
 *********************************************************/
static int str_rfind(const char* long_str, int pos1, int pos2, char c)
{
	
	int len = strlen(long_str);
	int i = pos1;

	while (i > pos2) {
		if (long_str[i] == c)
			return i;
		--i;
	}

	return -1;
}


/*********************************************************
 *
 * Reconstruct a log_record_t from the string
 * <record>
 * <date>1037928503</date>
 * <sequence>1</sequence>
 * <logger></logger>
 * <level>WARNING</level>
 * <class></class>
 * <method></method>
 * <thread>0</thread>
 * <process>3920</process>
 * <message>
 * 1: This message level WARNING
 * </message>
 * </record> 
 * 
 *********************************************************/
static BOOL find_element(const char* name, BOOL is_empty_element, 
						const char* msg, int* pos1, int* pos2)
{
	int start = *pos1;
	int end = *pos2;

	int i = start;
	while (i < end) {
		// Encountering '<', expect to find either <xxx> or </xxx>
		if (msg[i] == '<') {

			char next = msg[i+1];

			if (next == name[0]) {	// Found '<x'. Expect <xxx

				// Check for the beginning of an element
				if (str_begins_with(&msg[i+1], name))
					*pos1 = i;
				break;

			} else if (next == '/') { // Found '</'. Expect </xxx>

				if (!is_empty_element) {

					if (msg[i+2] == name[0]) {
						if (str_begins_with(&msg[i+2], name)) {
							*pos2 = i+3+strlen(name); // </xxx>
							return TRUE;
						}
					}
				}
				return FALSE;

			} 

		} else if (msg[i] == '/') { // Found '/'. expect '/>' or '/ >'

			if (!is_empty_element)
				return FALSE;

				*pos2 = str_find(msg, i+1, end, '>')+1;
				if (*pos2 > *pos1)
					return TRUE;
		}

		++i;
	}
	return FALSE;
}

/*********************************************************
 *
 * Extract content of an element. Assuming that the 
 * element conforms to the following format
 * <xxx>content</xxx>
 * If the element is found, pos1 will be moved to 
 * the position after the last char of this element.
 * 
 *********************************************************/
static BOOL get_content(const char* name, 
						BOOL is_empty_element, 
						const char* msg, 
						int* pos1, int* pos2, 
						char* ret)
{
	int start = *pos1;
	int end = *pos2;
	int content_start;
	int content_end;

	if (!find_element(name, FALSE, msg, &start, &end))
		return FALSE;

	*pos1 = end;

	// Content starts after <xxx>
	content_start = start + strlen(name) + 3;
	content_end = content_start;

	content_end = str_rfind(msg, end, content_start, '/');
	if (!is_empty_element) {
		--content_end;
	}

	if (content_end < content_start)
		return FALSE;

	if (start == end)
		strcpy(ret, "");

	strncpy(ret, &msg[start], end-start);


	return TRUE;
}

/*********************************************************
 *
 * Reconstruct a log_record_t from the string
 * <record>
 * <date>1037928503</date>
 * <sequence>1</sequence>
 * <logger></logger>
 * <level>WARNING</level>
 * <class></class>
 * <method></method>
 * <thread>0</thread>
 * <process>3920</process>
 * <message>
 * 1: This message level WARNING
 * </message>
 * </record> 
 * 
 *********************************************************/
static xos_result_t parse(log_formatter_t* self, const char* msg, log_record_t* record)
{

	int start = 0;
	int end = strlen(msg);

	char tmp[250];
	long long_data;
	long int_data;

	if (!find_element("record", FALSE, msg, &start, &end))
		goto parse_error;

	// Date
	if (!get_content("date", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	sscanf(tmp, "%d", &long_data);
	log_record_set_millis(record, long_data);

	// Sequence
	if (!get_content("sequence", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	sscanf(tmp, "%d", &long_data);
	log_record_set_sequence_number(record, long_data);

	// Logger
	if (!get_content("logger", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	log_record_set_logger_name(record, tmp);

	// Level
	if (!get_content("level", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	log_record_set_level_str(record, tmp);

	// Class
	if (!get_content("class", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	log_record_set_source_class_name(record, tmp);

	// Method
	if (!get_content("method", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	log_record_set_source_method_name(record, tmp);

	// Thread
	if (!get_content("thread", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	sscanf(tmp, "%d", &int_data);
	log_record_set_thread_id(record, int_data);

	// process
	if (!get_content("process", FALSE, msg, &start, &end, tmp))
		goto parse_error;

	sscanf(tmp, "%d", &int_data);
	log_record_set_process_id(record, int_data);

	{
	char long_str[1000];
	// Message
	if (!get_content("method", FALSE, msg, &start, &end, long_str))
		goto parse_error;

	log_record_set_message(record, long_str);

	}


	return XOS_SUCCESS;


parse_error:

	return XOS_FAILURE;

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

	free((xml_format_data_t*)d);

}


/*********************************************************
 *
 * New() method. Must be called when creating a log_formatter_t
 * on stack.
 *
 *********************************************************/
void log_xml_formatter_init(log_formatter_t* self)
{
	// Importing the function
	void __log_formatter_init(log_formatter_t*);

	xml_format_data_t* d = NULL;

	if (!self)
		return;

	// Initialize the base class first
	__log_formatter_init(self);


	d = (xml_format_data_t*)malloc(sizeof(xml_format_data_t));

	if (d) {

		strcpy(d->head, "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n");
		strcat(d->head, "<!DOCTYPE log>\n");
		strcat(d->head, "<log>\n");

		strcpy(d->tail, "</log>");

	}

	self->data_ = (void*)d;
	self->data_free_ = &data_free;
	self->format = &format;
	self->parse = &parse;
	self->get_head = &get_head;
	self->get_tail = &get_tail;


}


/*********************************************************
 *
 * New() method. Must be called when creating a log_formatter_t
 * on heap.
 *
 *********************************************************/
log_formatter_t* log_xml_formatter_new()
{
	log_formatter_t* __log_formatter_new();

	log_formatter_t* self = __log_formatter_new();

	log_xml_formatter_init(self);

	return self;

}

