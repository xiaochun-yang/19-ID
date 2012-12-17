#include "xos_socket.h"
#include "logging.h"


#define SOCKET_NAME_LEN 250
#define SOCKET_READ_LEN 1000
#define SOCKET_WRITE_LEN 1000

/*********************************************************
 *
 * new log_handler_t data structure
 *
 *********************************************************/
typedef struct __log_socket_data
{
	char				server[SOCKET_NAME_LEN];
	xos_socket_port_t	port;
	BOOL				is_keep_alive;

	xos_socket_t		socket;
//	char				readBuff[SOCKET_READ_LEN];
//	char				writeBuff[SOCKET_WRITE_LEN];

    int					cur_size;


} log_socket_data_t;


/*********************************************************
 *
 * Must be called before any other methods of this class
 * can be used.
 *
 *********************************************************/
void g_log_socket_handler_init()
{
	xos_socket_library_startup();
}

/*********************************************************
 *
 * Must be called when the application no longer need
 * to call any other methods of this class.
 *
 *********************************************************/
void g_log_socket_handler_clean_up()
{
	xos_socket_library_cleanup();
}

/*********************************************************
 *
 * Deallocate memory for log_handler_t
 *
 *********************************************************/
 static log_socket_data_t* get_data(void* d)
 {
    if (!d)
        return NULL;

    return (log_socket_data_t*)d;

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
    log_socket_data_t* data = get_data(self->data_);
//	const char* tail = NULL;
//	int len;

    if (!data)
        return;

/*	tail = log_formatter_get_tail(log_handler_get_formatter(self), self);
	len = strlen(tail);
	// Send log message to socket stream
	xos_socket_write( &data->socket, tail, len);
	data->cur_size += len;*/

	/* disconnect from listening port */
	xos_socket_destroy(&data->socket); 



}

/*********************************************************
 *
 * Called when the base class's destroy() is called.
 *
 *********************************************************/
static void destroy(log_handler_t* self)
{
	close_(self);
	free((log_socket_data_t*)self->data_);
}


/*********************************************************
 *
 *
 *
 *********************************************************/
 static void open_(log_handler_t* self)
 {

    // flush the remaining buffer
    log_socket_data_t* data = get_data(self->data_);
	xos_socket_address_t		serverAddress;

    if (!data)
        return;


	/* create the client socket */
	if ( xos_socket_create_client( &data->socket ) == XOS_FAILURE ) 
	{
		close_(self);
		return;
	}	

	/* set address of image server using listening port */
	xos_socket_address_init( & serverAddress );
	xos_socket_address_set_ip_by_name( & serverAddress, data->server );
	xos_socket_address_set_port( & serverAddress, data->port );

	/* connect to listening port on image server */
	if ( xos_socket_make_connection( &data->socket, &serverAddress) == XOS_FAILURE ) 
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
    log_socket_data_t* data = get_data(self->data_);
	log_formatter_t* formatter = NULL;
	int len = 0;
	const char* str = NULL;

    // At this point we can assume that, if the stream is not already opened,
    // there is something wrong. We should try to open or write to the stream.
    if (!data)
        return;

	if (!data->is_keep_alive)
		open_(self);

	if (!data->socket.connectionGood)
		return;

	
	formatter = log_handler_get_formatter(self);

/*	if (data->cur_size == 0)
	{
		// Add head
		const char* head = log_formatter_get_head(formatter, self);
		len = strlen(head);
		// Send log message to socket stream
		if ( xos_socket_write( &data->socket, head, len) != XOS_SUCCESS )
		{
			close_(self);
		}
		data->cur_size += len;
	}*/

	
	str = log_formatter_format(formatter, record);
	len = strlen(str);

	// Send log message to socket stream
	if ( xos_socket_write( &data->socket, str, len) != XOS_SUCCESS )
	{
		close_(self);
	}

	data->cur_size += len;

	if (!data->is_keep_alive)
		close_(self);


}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
void log_socket_handler_init(
						log_handler_t* self,
                        const char*  server,
                        xos_socket_port_t port,
						BOOL is_keep_alive)
{
    void __log_handler_init(log_handler_t*);
    log_socket_data_t* d = NULL;

    if (!self)
        return;

	__log_handler_init(self);

	d = malloc(sizeof(log_socket_data_t));
    if (d) {
        strcpy(d->server, server);
        d->port = port;
        d->is_keep_alive = is_keep_alive;    
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

    // Open a file stream here.
    if (d->is_keep_alive)
		open_(self);

}


/*********************************************************
 *
 * Initialize a FileHandler to write to the given filename.
 *
 *********************************************************/
log_handler_t* log_socket_handler_new(
                        const char*  server,
                        xos_socket_port_t port,
						BOOL is_keep_alive
                        )
{
    log_handler_t* __log_handler_new();

    log_handler_t* self = __log_handler_new();
    
	log_socket_handler_init(self, server, port, is_keep_alive);

    return self;
}



