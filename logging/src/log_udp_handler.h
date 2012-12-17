#ifndef __log_udp_handler_h__
#define __log_udp_handler_h__
#include "log_common.h"
#include "xos_socket.h"
#include "log_level.h"
#include "log_record.h"

#ifdef __cplusplus
extern "C" {
#endif /* _cplusplus */


/*********************************************************
 *
 * Simple network logging Handler. 
 * 
 * LogRecords are published to a network stream connection. By default 
 * the XMLFormatter class is used for formatting. 
 * 
 * Configuration: By default each SocketHandler is initialized using 
 * the following LogManager configuration properties. If properties are 
 * not defined (or have invalid values) then the specified default 
 * values are used. 
 * 
 * java.util.logging.SocketHandler.level specifies the default 
 * level for the Handler (defaults to Level.ALL). 
 * java.util.logging.SocketHandler.filter specifies the name of 
 * a Filter class to use (defaults to no Filter). 
 * java.util.logging.SocketHandler.formatter specifies the name 
 * of a Formatter class to use (defaults to java.util.logging.XMLFormatter). 
 * java.util.logging.SocketHandler.encoding the name of the 
 * character set encoding to use (defaults to the default platform encoding). 
 * java.util.logging.SocketHandler.host specifies the target 
 * host name to connect to (no default). 
 * java.util.logging.SocketHandler.port specifies the target 
 * TCP port to use (no default). 
 * The output IO stream is buffered, but is flushed after 
 * each LogRecord is written.
 *
 *********************************************************/

/*********************************************************
 *
 * new, init, destroy, free methods
 * There is no destroy or free method.
 * A log_handler_t from the log_socket_handler_new() or
 * log_socket_handler_init() methods here is deleted by
 * the log_handler_destroy() or log_handler_free() method.
 *
 *********************************************************/
void log_udp_handler_init(
						log_handler_t* self,
                        const char*  server,
                        xos_socket_port_t port);
log_handler_t* log_udp_handler_new(
                        const char*  server,
                        xos_socket_port_t port);



#ifdef __cplusplus
}
#endif /* _cplusplus */


#endif /* __log_udp_handler_h__ */

