#include <openssl/bio.h>
#include "dcss_gui_client.h"
#include "xos.h"
//int BIO_get_peer_name( BIO* bio, xos_socket_address_t* address );
int BIO_send_dcs_text_message( dcss_bio_t* bio, const char* message );
int BIO_read_fixed_length( dcss_bio_t* bio, char* buffer, int len );
xos_wait_result_t BIO_wait_until_readable( dcss_bio_t* bio, unsigned long timeout_ms );
int BIO_receive_dcs_message( dcss_bio_t* dcssBIO, dcs_message_t* dcsMessage );
/* hide socket or BIO */
int DCSS_read_fixed_length( const client_profile_t* user, char* buf, int len );
int DCSS_send_dcs_text_message( const client_profile_t* user, const char* message );
void DCSS_set_read_timeout( const client_profile_t* user, unsigned long ms );
xos_wait_result_t DCSS_wait_until_readable( const client_profile_t* user,
unsigned long ms );
int DCSS_receive_dcs_message( const client_profile_t* user,
dcs_message_t* dcsMessage );
int DCSS_client_alive( const client_profile_t* user );
int DCSS_set_client_write_buffer_size( const client_profile_t* user, int len );
int DCSS_get_peer_name( const client_profile_t* user, xos_socket_address_t* address );
