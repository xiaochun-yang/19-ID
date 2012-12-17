#include "xos_socket.h"
#include "logging.h"


#define UDP_NAME_LEN 250
#define UDP_READ_LEN 1000
#define UDP_WRITE_LEN 1000

/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
typedef struct __log_udp_data
{
	char			server[UDP_NAME_LEN];
	xos_socket_port_t	port;
	xos_socket_t	udp;
    int				cur_size;


} log_udp_data_t;


/*********************************************************
 *
 * Must be called before any other methods of this class
 * can be used.
 *
 *********************************************************/
void g_log_udp_handler_init()
{
	xos_socket_library_startup();
}

/*********************************************************
 *
 * Must be called when the application no longer need
 * to call any other methods of this class.
 *
 *********************************************************/
void g_log_udp_handler_clean_up()
{
	xos_socket_library_cleanup();
}

/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
 static log_udp_data_t* get_data(void* d)
 {
    if (!d)
        return NULL;

    return (log_udp_data_t*)d;

 }


/*********************************************************
 *
 * Check if the file has reached the maximum size
 *
 *********************************************************/
static void flush_(log_handler_t* self)
{
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
    log_udp_data_t* data = get_data(self->data_);
//	const char* tail = NULL;
//	int len;

    if (!data)
        return;

/*	tail = log_formatter_get_tail(log_handler_get_formatter(self), self);
	len = strlen(tail);
	// Send log message to udp stream
	xos_udp_write( &data->udp, tail, len);
	data->cur_size += len;*/

	/* disconnect from listening port */
	xos_socket_destroy(&data->udp); 



}

/*********************************************************
 *
 * Called when the base class's destroy() is called.
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	close_(self);
	free((log_udp_data_t*)self->data_);
}


/*********************************************************
 *
 *
 *
 *********************************************************/
 static void open_(log_handler_t* self)
 {

    // flush the remaining buffer
    log_udp_data_t* data = get_data(self->data_);

    if (!data)
        return;


	/* create the client udp */
	if ( xos_udp_create_client( &data->udp, data->server, data->port ) == XOS_FAILURE ) 
	{
		close_(self);
		return;
	}	


    data->cur_size = 0;

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
    log_udp_data_t* data = get_data(self->data_);
	log_formatter_t* formatter = NULL;
	int len = 0;
	const char* str = NULL;

    // At this point we can assume that, if the stream is not already opened,
    // there is something wrong. We should try to open or write to the stream.
    if (!data || !data->udp.connectionGood)
        return;

	
	formatter = log_handler_get_formatter(self);

/*	if (data->cur_size == 0)
	{
		// Add head
		const char* head = log_formatter_get_head(formatter, self);
		len = strlen(head);
		// Send log message to udp stream
		if ( xos_udp_write( &data->udp, head, len) != XOS_SUCCESS )
		{
			close_(self);
		}
		data->cur_size += len;
	}*/

	
	str = log_formatter_format(formatter, record);
	if (!str)
		return;
		
	len = strlen(str);

	// Send log message to udp stream
	if ( xos_udp_write( &data->udp, str, len) != XOS_SUCCESS )
	{
		close_(self);
	}

	data->cur_size += len;


}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
void log_udp_handler_init(
						log_handler_t* self,
                        const char*  server,
                        xos_socket_port_t port)
{
    void __log_handler_init(log_handler_t*);
    log_udp_data_t* d = NULL;

    if (!self)
        return;

	__log_handler_init(self);

	d = malloc(sizeof(log_udp_data_t));
    if (d) {
        strcpy(d->server, server);
        d->port = port;
		d->cur_size = 0;
	}

    self->data_ = d;
	self->formatter = NULL;
	self->filter = NULL;
	self->level = LOG_ALL;
    self->close = &close_;
    self->flush = &flush_;
    self->publish = &publish;
    self->destroy = &destroy;

    // Open a udp stream here.
	open_(self);

}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
log_handler_t* log_udp_handler_new(
                        const char*  server,
                        xos_socket_port_t port)
{
    log_handler_t* __log_handler_new();

    log_handler_t* self = __log_handler_new();
    
	log_udp_handler_init(self, server, port);

    return self;
}



