#include <stdio.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/err.h>

#include "XosException.h"
#include "log_quick.h"
#include "DcsConfig.h"
#include "SSLCommon.h"
#include "dcss_ssl.h"

int DCSS_get_peer_name( const client_profile_t* user, xos_socket_address_t* address ) {
    int h = -1;
    socklen_t len =sizeof(*address);

    if (address == NULL) {
        LOG_WARNING( "DCSS_get_peer_name address=NULL" );
        return 0;
    }
    
    if (user == NULL) {
        LOG_WARNING( "DCSS_get_peer_name user==NULL" );
        return 0;
    }
    if (user->usingBIO) {
        if (user->dcss_bio == NULL) {
            LOG_WARNING( "DCSS_get_peer_name dcss_bio==NULL" );
            return 0;
        }
        h = BIO_get_fd( user->dcss_bio->bio, NULL );
        if (h < 0) {
            LOG_WARNING( "BIO_get_fd failed." );
            SSL_LogSSLError( );
        }
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_get_peer_name socket==NULL" );
            return 0;
        }
        //h = user->socket->clientDescriptor;
        return (xos_socket_get_peer_name(user->socket, address) == 0);
    }

    if (getpeername( h, (struct sockaddr*)address, &len ) < 0) {
        int nn = errno;
        LOG_WARNING1( "failed to get peer name: errno=%d", nn );
        return 0;
    }

    xos_socket_address_print( address );

    return 1;
}
int BIO_send_dcs_text_message( dcss_bio_t* dcssBIO, const char* msg ) {
    if (dcssBIO == NULL) {
        LOG_WARNING( "BIO_send_dcs_text_message dcssBio==NULL" );
        return 0;
    }
    if (dcssBIO->connectionActive == 0) {
        return 0;
    }

    if (msg == NULL) return 1;

    int len = strlen( msg );
    if (len <= 0) return 1;

    //LOG_FINEST1( "+BIO_send_dcs_text_message: %s", msg );

    int result = 0;

    char header[64] = {0};
    xos_mutex_t*    lock    = &dcssBIO->lock;
    BIO*            bio     = dcssBIO->bio;
    /* copy timeout so the original one will not be changed */
    struct timeval  timeoutVAL = dcssBIO->timeout;
    /* we will not allow wait forever
     * so default timeout is 1 second
     */
    if (timeoutVAL.tv_sec == 0 && timeoutVAL.tv_usec == 0) {
        LOG_WARNING( "not allow wait forever" );
        timeoutVAL.tv_sec = 1;
    }

    ++len; /* here is to include the '\0' at the end */
    sprintf( header,"%12d %12d ", len, 0 ); /* length should be 26 */ 

    xos_mutex_lock( lock );
    try {
        if (1) {
            /* this is disconnect on time out */
            bio_write_with_timeout( bio, header, DCS_HEADER_SIZE, &timeoutVAL );
            bio_write_with_timeout( bio, msg, len, &timeoutVAL );
            while (BIO_flush( bio ) != 1) {
                BIO_wait( bio, &timeoutVAL );
            }
            result = 1;
        } else {
            /* this is disconnect on buffer full */
            if (BIO_write( bio, header, DCS_HEADER_SIZE ) == DCS_HEADER_SIZE &&
            BIO_write( bio, msg, len ) == len) {
                while (BIO_flush( bio ) != 1) {
                    BIO_wait( bio, &timeoutVAL );
                }
                result = 1;
            }
        }
    } catch ( XosException& e ) {
        LOG_WARNING1("BIO_send_dcs_text_message failed: %s", e.getMessage( ).c_str( ));
    } catch (...) {
    }
    if (!result) {
        dcssBIO->connectionActive = 0;
    }
    xos_mutex_unlock( lock );

    //LOG_FINEST1( "-BIO_send_dcs_text_message: %d", result );
    return result;
}
int BIO_read_fixed_length( dcss_bio_t* dcssBIO, char* buffer, int length ) {
    if (dcssBIO == NULL) {
        LOG_WARNING( "BIO_read_fixed_length dcssBIO==NULL" );
        return 0;
    }
    if (dcssBIO->connectionActive == 0) {
        return 0;
    }

    if (buffer == NULL || length <= 0) return 1;

    xos_mutex_t*    lock    = &dcssBIO->lock;
    BIO*            bio     = dcssBIO->bio;
    /* copy timeout so the original one will not be changed */
    struct timeval  timeoutVAL = dcssBIO->timeout;
    struct timeval* timeout = NULL;
    if (timeoutVAL.tv_sec != 0 || timeoutVAL.tv_usec != 0) {
        timeout = &timeoutVAL;
    }
    xos_mutex_lock( lock );
    int result = bio_read_fixed_length( bio, buffer, length, timeout );
    if (!result) {
        dcssBIO->connectionActive = 0;
    }
    xos_mutex_unlock( lock );

    return result;
}
xos_wait_result_t BIO_wait_until_readable( dcss_bio_t* dcssBIO,
unsigned long timeout_ms ) {
    if (dcssBIO == NULL) {
        LOG_WARNING( "BIO_wait_until_readable dcssBIO==NULL" );
        return XOS_WAIT_FAILURE;
    }
    if (dcssBIO->connectionActive == 0) {
        return XOS_WAIT_FAILURE;
    }

    xos_mutex_t*    lock    = &dcssBIO->lock;
    BIO*            bio     = dcssBIO->bio;
    struct timeval* timeout = NULL;
    struct timeval timeoutVAL;

    if (timeout_ms != 0) {
        timeoutVAL.tv_sec = timeout_ms / 1000;
        timeoutVAL.tv_usec = (timeout_ms % 1000) * 1000;
        timeout = &timeoutVAL;
    }

    xos_wait_result_t result= bio_wait_until_readable( bio, timeout );
    if (result == XOS_WAIT_FAILURE) {
        dcssBIO->connectionActive = 0;
    }
    if (result != XOS_WAIT_SUCCESS) {
        return result;
    }
    
    /* now check again with lock */
    xos_mutex_lock( lock );
    result= bio_wait_until_readable( bio, timeout );
    if (result == XOS_WAIT_FAILURE) {
        dcssBIO->connectionActive = 0;
    }
    if (result != XOS_WAIT_SUCCESS) {
        LOG_WARNING( "BIO_wait_until_readable: middle of writing" );
    }
    xos_mutex_unlock( lock );
    return result;
}
int BIO_receive_dcs_message( dcss_bio_t* dcssBIO, dcs_message_t* dcsMessage ) {
    if (dcssBIO == NULL) {
        LOG_WARNING( "BIO_receive_dcs_message dcssBIO==NULL" );
        return 0;
    }
    if (dcssBIO->connectionActive == 0) {
        return 0;
    }

    if (dcsMessage == NULL) return 0;

    dcsMessage->textInSize = 0;
    dcsMessage->binaryInSize = 0;

    xos_mutex_t*    lock    = &dcssBIO->lock;
    BIO*            bio     = dcssBIO->bio;
    /* copy timeout so the original one will not be changed */
    struct timeval  timeoutVAL = dcssBIO->timeout;
    struct timeval* timeout = NULL;
    if (timeoutVAL.tv_sec != 0 || timeoutVAL.tv_usec != 0) {
        timeout = &timeoutVAL;
    }
    char header[64] = {0};
    xos_mutex_lock( lock );
    int result = bio_read_fixed_length( bio, header, DCS_HEADER_SIZE, timeout );
    if (result && sscanf( header,
    "%d %d", &dcsMessage->textInSize, &dcsMessage->binaryInSize ) != 2) {
        result = 0;
    }
    if (result && xos_adjust_dcs_message(
    dcsMessage, dcsMessage->textInSize + 1, dcsMessage->binaryInSize
    ) != XOS_SUCCESS) {
        result = 0;
    }
    if (result && dcsMessage->textInSize > 0) {
        result = bio_read_fixed_length(
        bio, dcsMessage->textInBuffer, dcsMessage->textInSize, timeout );

        if (result) {
            dcsMessage->textInBuffer[dcsMessage->textInSize] = '\0';
        }
    }
    if (result && dcsMessage->binaryInSize > 0) {
        result = bio_read_fixed_length( bio, dcsMessage->binaryInBuffer, dcsMessage->binaryInSize, timeout );
    }
    if (!result) {
        dcssBIO->connectionActive = 0;
    }
    xos_mutex_unlock( lock );

    return result;
}
int DCSS_send_dcs_text_message( const client_profile_t* user, const char* message ) {
    if (message == NULL || message[0] == '\0') {
        LOG_WARNING( "DCSS_send_dcs_text_message message==NULL" );
        return 1;
    }
    if (user == NULL) {
        LOG_WARNING( "DCSS_send_dcs_text_message with user==NULL" );
        return 0;
    }

    if (user->usingBIO) {
        return BIO_send_dcs_text_message( user->dcss_bio, message );
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_send_dcs_text_message socket==NULL" );
            return 0;
        }
        if (xos_send_dcs_text_message( user->socket, message ) == XOS_SUCCESS) {
            return 1;
        }
    }
    return 0;
}
int DCSS_read_fixed_length( const client_profile_t* user,
char* buffer, int len ) {
    if (user == NULL) {
        LOG_WARNING( "DCSS_read_fixed_length with user==NULL" );
        return 0;
    }
    if (user->usingBIO) {
        return BIO_read_fixed_length( user->dcss_bio, buffer, len );
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_read_fixed_length socket==NULL" );
            return 0;
        }
        if (xos_socket_read( user->socket, buffer, len ) == XOS_SUCCESS) {
            return 1;
        }
    }
    return 0;
}
void DCSS_set_read_timeout( const client_profile_t* user, unsigned long ms ) {
    if (user == NULL) {
        LOG_WARNING( "DCSS_set_read_timeout user==NULL" );
        return;
    }
    if (user->usingBIO) {
        if (user->dcss_bio == NULL) {
            LOG_WARNING( "DCSS_set_read_timeout using dcss_bio==NULL" );
            return;
        }
        user->dcss_bio->timeout.tv_sec = ms / 1000;
        user->dcss_bio->timeout.tv_usec = (ms % 1000) * 1000;
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_set_read_timeout with socket=NULL" );
            return;
        }
        xos_socket_set_read_timeout( user->socket, ms );
    }
}
xos_wait_result_t DCSS_wait_until_readable( const client_profile_t* user,
unsigned long ms ) {
    if (user == NULL) {
        LOG_WARNING( "DCSS_wait_until_readable user==NULL" );
        return XOS_WAIT_FAILURE;
    }
    if (user->usingBIO) {
        return BIO_wait_until_readable( user->dcss_bio, ms );
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_wait_until_readable socket==NULL" );
            return XOS_WAIT_FAILURE;
        }
        return xos_socket_wait_until_readable( user->socket, ms );
    }
}
int DCSS_receive_dcs_message( const client_profile_t* user,
dcs_message_t* dcsMessage ) {
    if (user == NULL) {
        LOG_WARNING( "DCSS_receive_dcs_message user==NULL" );
        return 0;
    }
    if (user->usingBIO) {
        return BIO_receive_dcs_message( user->dcss_bio, dcsMessage );
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_receive_dcs_message socket==NULL" );
            return 0;
        }
        if (xos_receive_dcs_message( user->socket, dcsMessage ) ==
        XOS_SUCCESS) {
            return 1;
        }
    }
    return 0;
}
int DCSS_client_alive( const client_profile_t* user ) {
    if (user == NULL) {
        LOG_WARNING( "DCSS_client_alive user==NULL" );
        return 0;
    }
    if (user->usingBIO) {
        if (user->dcss_bio == NULL) {
            LOG_WARNING( "DCSS_client_alive dcss_bio==NULL" );
            return 0;
        }
        return user->dcss_bio->connectionActive;
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_client_alive socket==NULL" );
            return 0;
        }
        return user->socket->connectionActive;
    }
}
int DCSS_set_client_write_buffer_size( const client_profile_t* user, int len ) {
    int h = -1;

    if (user == NULL) {
        LOG_WARNING( "DCSS_set_client_write_buffer_size user==NULL" );
        return 0;
    }
    if (user->usingBIO) {
        if (user->dcss_bio == NULL) {
            LOG_WARNING( "DCSS_set_client_write_buffer_size dcss_bio==NULL" );
            return 0;
        }
        h = BIO_get_fd( user->dcss_bio->bio, NULL );
    } else {
        if (user->socket == NULL) {
            LOG_WARNING( "DCSS_set_client_write_buffer_size socket==NULL" );
            return 0;
        }
        h = user->socket->clientDescriptor;
    }

	if (setsockopt( h, SOL_SOCKET, SO_SNDBUF, &len, sizeof(len) )
    == -1) {
        int nn = errno;
        LOG_WARNING1( "set socket send buffer size failed: %d", nn );
        return 0;
    }
    return 1;
}
