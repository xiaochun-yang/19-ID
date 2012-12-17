#include <sys/select.h>
#include <openssl/crypto.h>
#include <openssl/bio.h>
#include <openssl/ssl.h>
#include <openssl/evp.h>
#include <openssl/err.h>

#include "XosMutex.h"
#include "log_quick.h"

#include "SSLCommon.h"

static int SSL_init_result = -1;
static int SSL_DEBUG = 0;
static XosMutex* pStaticLocks = NULL;
static int maxStaticLocks = 0;

static EVP_PKEY* publicKey = NULL;
static EVP_PKEY* privateKey = NULL;

int dcssPKIReady( ) {
    if (SSL_init_result != 1) return 0;
    if (publicKey == NULL) return 0;
    if (privateKey == NULL) return 0;

    return 1;
}

void SSL_LogSSLError( ) {
    unsigned long en;
    while ((en = ERR_get_error( )) != 0) {
        int nLib    = ERR_GET_LIB( en );
        int nFunc   = ERR_GET_FUNC( en );
        int nReason = ERR_GET_REASON( en );
        LOG_WARNING5( "SSL ERROR: %lu, %s lib: %s fun: %s reason: %s",
        en, ERR_error_string( en, NULL ),
        ERR_lib_error_string( nLib ),
        ERR_func_error_string( nFunc ),
        ERR_reason_error_string( nReason ) );
    }
}


/* static locking */
static void myLockingFunction( int mode, int n, const char* file, int line ) {
    if (pStaticLocks == NULL) {
        LOG_SEVERE( "SSL static locks not initialized" );
        exit( -1 );
    }
    if (n >= maxStaticLocks) {
        LOG_SEVERE2( "SSL static locks index %d > max %d", n, maxStaticLocks );
        exit( -1 );
    }

    try {
        if (mode & CRYPTO_LOCK) {
            pStaticLocks[n].lock( );
        } else {
            pStaticLocks[n].unlock( );
        }
    } catch (XosException& e) {
        LOG_SEVERE1( "mutext lock/unlock failed: %s", e.getMessage().c_str( ) );
    }
}
static unsigned long myIdFunction( void ) {
    return xos_thread_current_id( );
}

/* dynamic locking */
// It is required to use "struct CRYPTO_dynlock_value" by the man page.
// So we cannot use class and have to use calloc
struct CRYPTO_dynlock_value {
    xos_mutex_t lock;
};
static struct CRYPTO_dynlock_value* myDynCreate(
const char* file, int line ) {
    struct CRYPTO_dynlock_value* pResult = NULL;

    pResult = (CRYPTO_dynlock_value*)calloc(1, sizeof(*pResult) );
    if (pResult != NULL) {
        xos_mutex_create( &pResult->lock );
    }
    return pResult;
}
static void myDynLock( int mode, struct CRYPTO_dynlock_value* l,
const char* file, int line ) {
    if (mode & CRYPTO_LOCK) {
        xos_mutex_lock( &l->lock );
    } else {
        xos_mutex_unlock( &l->lock );
    }
}
static void myDynDestroy( struct CRYPTO_dynlock_value* l,
const char* file, int line ) {
    xos_mutex_close( &l->lock );
    free( l );
}

int SSL_init( ) {
    if (SSL_init_result != -1) {
        return SSL_init_result;
    }

    maxStaticLocks = CRYPTO_num_locks( );
    if (SSL_DEBUG > 0) {
        LOG_FINEST1( "CRYPTO_num_locks: %d", maxStaticLocks );
    }
    if (maxStaticLocks > 0) {
        try {
            pStaticLocks = new XosMutex[maxStaticLocks];
        } catch (XosException& e) {
            if (pStaticLocks) {
                delete [] pStaticLocks;
                pStaticLocks = NULL;
            }
            maxStaticLocks = 0;
        }
        if (pStaticLocks == NULL) {
            LOG_SEVERE( "SSL_init: static locks creation failed" );
            SSL_init_result  = 0;
            return 0;
        }
    }

    /* set call backs */
    CRYPTO_set_locking_callback( myLockingFunction );
    CRYPTO_set_id_callback( myIdFunction );
    CRYPTO_set_dynlock_create_callback( myDynCreate );
    CRYPTO_set_dynlock_lock_callback( myDynLock );
    CRYPTO_set_dynlock_destroy_callback( myDynDestroy );

    SSL_load_error_strings( );
    SSL_library_init( );
    ERR_load_BIO_strings( );
    ERR_load_SSL_strings( );
    OpenSSL_add_all_algorithms( );
    SSL_init_result  = 1;
    return 1;
}

/* this is for non-blocking BIO to wait
 * in some rare case, it will poll with
 * 200ms sleep */

/* 200 ms MUST less than 1 second */
static const unsigned long BIO_POLL_SLEEP_UTIME = 200000;
static void BIO_poll( struct timeval* timeout ) {
    if (SSL_DEBUG > 10) {
        if (timeout) {
            double time_in_ms = 
            timeout->tv_usec / 1000.0 + timeout->tv_sec * 1000.0;

            LOG_FINEST1( "+BIO_poll %lfms", time_in_ms );
        } else {
            LOG_FINEST( "+BIO_poll forever" );
        }
    }
    if (timeout == NULL) {
        usleep( BIO_POLL_SLEEP_UTIME );
        if (SSL_DEBUG > 10) {
            LOG_FINEST( "-BIO_poll forever" );
        }
    }

    if (timeout->tv_usec >= BIO_POLL_SLEEP_UTIME) {
        usleep( BIO_POLL_SLEEP_UTIME );
        timeout->tv_usec -= BIO_POLL_SLEEP_UTIME;
        if (SSL_DEBUG > 10) {
            LOG_FINEST( "-BIO_poll reduced tv_usec" );
        }
        return;
    }
    if (timeout->tv_sec > 0) {
        usleep( BIO_POLL_SLEEP_UTIME );
        --timeout->tv_sec;
        timeout->tv_usec += 1000000 - BIO_POLL_SLEEP_UTIME;
        if (SSL_DEBUG > 10) {
            LOG_FINEST( "-BIO_poll --tv_sec" );
        }
        return;
    }
    if (timeout->tv_usec >0) {
        /* give one more chance to try */
        usleep( timeout->tv_usec );
        timeout->tv_usec = 0;
        if (SSL_DEBUG > 10) {
            LOG_FINEST( "-BIO_poll final less than sleep time" );
        }
        return;
    }
    LOG_WARNING( "BIO_poll timeout " );
    if (SSL_DEBUG > 10) {
        LOG_FINEST( "-BIO_poll timeout" );
    }
    throw XosException( "BIO_poll failed" );
}
void BIO_wait( BIO* bio, struct timeval* timeout ) {
    int nReadyRead  = BIO_pending( bio );
    int nReadyWrite = BIO_wpending( bio );

    if (SSL_DEBUG > 0) {
        if (timeout) {
            double time_in_ms = 
            timeout->tv_usec / 1000.0 + timeout->tv_sec * 1000.0;
            LOG_FINEST1( "+BIO_wait %lfms", time_in_ms );
        } else {
            LOG_FINEST( "+BIO_wait forever" );
        }
        LOG_FINEST2( "ready r: %d w: %d", nReadyRead, nReadyWrite );
    }
    if (nReadyRead > 0 || nReadyWrite > 0) {
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-BIO_wait r or w already ready" );
            exit( -1 );
        }
        return;
    }

    if (!BIO_should_retry( bio )) {
        LOG_WARNING( "BIO_wait BIO_shoud_retry returned FALSE" );
        if (SSL_DEBUG > 0) {
            SSL_LogSSLError( );
            LOG_FINEST( "-BIO_wait no retry" );
            exit( -1 );
        }
        int nn = ERR_get_error( );
        if (nn == 0) {
            throw XosException( "should_not_retry" );
        } else {
            throw XosException( ERR_error_string( nn, NULL ) );
        }
    }

    int h = BIO_get_fd( bio, NULL );
    if (h < 0) {
        LOG_WARNING1( "BIO_wait: BIO_get_fd returned %d", h );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-BIO_wait BIO_get_fd failed" );
        }
        throw XosException( "BIO_get_fd failed" );
    }

    fd_set readMask;
    fd_set writeMask;
    fd_set errorMask;
    fd_set* pRead = NULL;
    fd_set* pWrite = NULL;

    FD_ZERO( &readMask );
    FD_SET( h, &readMask );
    FD_ZERO( &writeMask );
    FD_SET( h, &writeMask );
    FD_ZERO( &errorMask );
    FD_SET( h, &errorMask );

    //get which we should try
    if (BIO_should_io_special( bio )) {
        pRead = &readMask;
        pWrite = &writeMask;

        if (SSL_DEBUG > 0) {
            int reason = BIO_get_retry_reason( bio );
            switch (reason) {
            case BIO_RR_SSL_X509_LOOKUP:
                LOG_FINEST( "should_io_special: x509 look up" );
                break;

            case BIO_RR_CONNECT:
                LOG_FINEST( "should_io_special: connect" );
                break;

            case BIO_RR_ACCEPT:
                LOG_FINEST( "should_io_special: accept" );
                break;

            default:
                LOG_FINEST1( "should_io_special reason=%d", reason );
            }
        }
    }

    if (BIO_should_read( bio )) {
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "should_read" );
        }
        pRead = &readMask;
    }
    if (BIO_should_write( bio )) {
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "should_write" );
        }
        pWrite = &writeMask;
    }

    if (pRead == NULL && pWrite == NULL) {
        LOG_WARNING( "BIO_wait: polling" );
        BIO_poll( timeout );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-BIO_wait polled" );
        }
        return;
    }

    int result =  select( h + 1, pRead, pWrite, &errorMask, timeout );
    if (result > 0) {
        if (SSL_DEBUG > 0) {
            if (pRead && FD_ISSET( h, pRead)) {
                LOG_FINEST( "read ready" );
            }
            if (pWrite && FD_ISSET( h, pWrite)) {
                LOG_FINEST( "write ready" );
            }
            if (FD_ISSET( h, &errorMask)) {
                LOG_FINEST( "error ready" );
            }
        }
    } else if (result == 0) {
        LOG_WARNING( "BIO_wait select timeout" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-BIO_wait timeout" );
        }
        throw XosException( "BIO_wait timeout" );
    } else {
        LOG_WARNING( "BIO_wait select failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-BIO_wait failed" );
        }
        throw XosException( "BIO_wait failed" );
    }
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-BIO_wait OK" );
    }
}
void SSL_setDebugFlag( int debugFlag ) {
    SSL_DEBUG = debugFlag;
}
void loadDCSSCertificate( const char* pem_filename ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST1( "+loadDCSSCertificate %s", pem_filename );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "loadDCSSCertificate SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSCertificate SSL_init failed" );
        }
        throw XosException( "loadDCSSCertificate: SSL_init failed" );
    }

    if (publicKey) {
        EVP_PKEY_free( publicKey );
        publicKey = NULL;
    }

    BIO* fbio = BIO_new_file( pem_filename,"rb" );
    if (fbio == NULL) {
        LOG_WARNING( "loadDCSSCertificate BIO_new_file failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSCertificate file bio failed" );
        }
        throw XosException( "loadDCSSCertificate: file bio failed" );
    }
    X509* x509 = NULL;
    PEM_read_bio_X509( fbio, &x509, NULL, NULL );
    BIO_free_all( fbio );
    if (x509 == NULL) {
        LOG_WARNING( "loadDCSSCertificate PEM_read_bio_X509 failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSCertificate read x509 failed" );
        }
        throw XosException( "loadDCSSCertificate: read x509 failed" );
    }

    publicKey = X509_get_pubkey( x509 );
    if (publicKey == NULL) {
        LOG_WARNING( "loadDCSSCertificate X509_get_pubkey failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSCertificate get pub key failed" );
        }
        throw XosException( "loadDCSSCertificate: get pub key failed" );
    }
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-loadDCSSCertificate OK" );
    }
}
void loadDCSSPrivateKey( const char* pem_filename, char* pass_phrase ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST1( "+loadDCSSPrivateKey %s", pem_filename );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "loadDCSSPrivateKey SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSPrivateKey SSL_init failed" );
        }
        throw XosException( "loadDCSSPrivateKey: SSL_init failed" );
    }

    if (privateKey) {
        EVP_PKEY_free( privateKey );
        privateKey = NULL;
    }

    BIO* fbio = BIO_new_file( pem_filename,"rb" );
    if (fbio == NULL) {
        LOG_WARNING( "loadDCSSPrivateKey BIO_new_file failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSPrivateKey file bio failed" );
        }
        throw XosException( "loadDCSSPrivateKey: file bio failed" );
    }
    PEM_read_bio_PrivateKey( fbio, &privateKey, NULL, pass_phrase );
    BIO_free_all( fbio );

    if (privateKey == NULL) {
        LOG_WARNING( "loadDCSSPrivateKey REM_read_bio_PrivateKey failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-loadDCSSPrivateKey read prv key failed" );
        }
        throw XosException( "loadDCSSPrivateKey: read private key failed" );
    }
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-loadDCSSPrivateKey OK" );
    }
}

static char* base64Encode( char* output, size_t max_output,
unsigned char* input, size_t input_size ) {
    BIO* mbio;
    BIO* b64bio;

    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+base64Encode" );
    }

    if (output) {
        memset( output, 0, max_output );
    }

    b64bio = BIO_new( BIO_f_base64() );
    mbio   = BIO_new( BIO_s_mem( ) );

    b64bio = BIO_push( b64bio, mbio );

    BIO_write( b64bio, input, input_size );
    BIO_flush( b64bio );

    char * pResult = NULL;
    int result_len = BIO_get_mem_data( b64bio, &pResult );
    if (result_len <= 0 || pResult == NULL) {
        LOG_WARNING( "base64Encode failed at get mem data" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-base64Encode failed at get mem data" );
        }
        return NULL;
    }

    char *result = output;
    if (result == NULL) {
        result = (char*)calloc( result_len + 1, 1 );
    } else {
        if (result_len >= max_output) {
            LOG_WARNING( "base64Encode output buffer too small" );
            if (SSL_DEBUG > 0) {
                LOG_FINEST( "-base64Encode output buffer too small" );
            }
            return NULL;
        }
    }
    memcpy( result, pResult, result_len );

    BIO_free_all( b64bio );
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-base64Encode OK" );
    }
    return result;
}
static unsigned char* base64Decode( unsigned char* output, size_t& output_size,
size_t max_output, char* input ) {
    BIO* mbio;
    BIO* b64bio;
    BIO* rbio;  //result buffer
    unsigned char buffer[1024] = {0};
    int result_length = 0;
    int oneTime;

    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+base64Decode" );
    }

    output_size = 0;

    if (output) {
        memset( output, 0, max_output );
    }

    mbio   = BIO_new_mem_buf( input, -1 );
    b64bio = BIO_new( BIO_f_base64() );
    rbio   = BIO_new( BIO_s_mem( ) );

    b64bio = BIO_push( b64bio, mbio );

    while (1) {
        oneTime = BIO_read( b64bio, buffer, sizeof(buffer));
        if (SSL_DEBUG > 10) {
            LOG_FINEST1( "oneTime: %d", oneTime );
        }
        if (oneTime <= 0) break;

        if (BIO_write( rbio, buffer, oneTime ) != oneTime) {
            LOG_WARNING( "base64Decode BIO_write failed" );
            SSL_LogSSLError( );
            if (SSL_DEBUG > 0) {
                LOG_FINEST( "-base64Decode BIO_write failed" );
            }
            return NULL;
        }
    }
    BIO_free_all( b64bio );
    BIO_flush( rbio );

    unsigned char* pResult;
    int result_len = BIO_get_mem_data( rbio, &pResult );
    if (result_len <= 0 || pResult == NULL) {
        LOG_WARNING( "base64Decode BIO_get_mem_data failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-base64Decode get mem data failed" );
        }
        return NULL;
    }

    unsigned char* result = output;
    if (result == NULL) {
        //no need for extra 1 byte, result are binary
        result = (unsigned char*)calloc( result_len, 1 );
    } else {
        if (result_len > max_output) {
            LOG_WARNING( "base64Decode output buffer too small" );
            if (SSL_DEBUG > 0) {
                LOG_FINEST( "-base64Decode output buffer too small" );
            }
            return NULL;
        }
    }

    memcpy( result, pResult, result_len );
    output_size = result_len;

    BIO_free_all( rbio );
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-base64Decode OK" );
    }
    return result;
}
#if OPENSSL_VERSION_NUMBER < 0x10000000L
char* encryptSID( char* output, size_t max_output, char* input ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+encryptSID" ); /* do not log the SID */
    }
    if (output) {
        memset( output, 0, max_output );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "encryptSID: SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: SSL_init failed" );
        }
        return NULL;
    }
    if (publicKey == NULL) {
        LOG_WARNING( "encryptSID: no public key" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: no public key" );
        }
        return NULL;
    }

    unsigned char binary[1024]; // should be big enough
    int ll = EVP_PKEY_encrypt( binary, (unsigned char*)input, strlen( input ),
    publicKey );

    if (ll <= 0) {
        LOG_WARNING( "encryptSID: EVP_PKEY_encrypt failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: EVP_PKEY_encrypt failed" );
        }
        return NULL;
    }

    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-encryptSID: OK followed by base64Encode" );
    }
    return base64Encode( output, max_output, binary, ll );
}
char* decryptSID( char* output, size_t max_output, char* input ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+decryptSID" );
    }

    if (output) {
        memset( output, 0, max_output );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "decryptSID: SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: SSL_init failed" );
        }
        return NULL;
    }
    if (privateKey == NULL) {
        LOG_WARNING( "decryptSID: no private key" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: no private key" );
        }
        return NULL;
    }

    unsigned char binary[1024] = {0};
    size_t ll = 0;
    if (!base64Decode( binary, ll, 1024, input )) {
        LOG_WARNING( "decryptSID: base64Decode failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: base64Decode failed" );
        }
        return NULL;
    }
    unsigned char plain[1024] = {0};
    int plain_len = EVP_PKEY_decrypt( plain, binary, ll, privateKey );
    if (plain_len <= 0) {
        LOG_WARNING( "decryptSID: EVP_PKEY_decrypt failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: EVP_PKEY_decrypt failed" );
        }
        return NULL;
    }
    char* result = output;
    if (result == NULL) {
        result = (char*)calloc( plain_len + 1, 1 );
    } else {
        if (plain_len >= max_output) {
            LOG_WARNING( "decryptSID: output buffer too small" );
            if (SSL_DEBUG > 0) {
                LOG_FINEST( "-decryptSID: output buffer too small" );
            }
            return NULL;
        }
    }

    memcpy( result, plain, plain_len );
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-decryptSID OK" );
    }
    return result;
}
#else
char* encryptSID( char* output, size_t max_output, char* input ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+encryptSID" ); /* do not log the SID */
    }
    if (output) {
        memset( output, 0, max_output );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "encryptSID: SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: SSL_init failed" );
        }
        return NULL;
    }
    if (publicKey == NULL) {
        LOG_WARNING( "encryptSID: no public key" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: no public key" );
        }
        return NULL;
    }

    EVP_PKEY_CTX* pkContext = EVP_PKEY_CTX_new( publicKey, NULL );
    if (pkContext == NULL) {
        LOG_WARNING( "encryptSID: EVP_PKEY_CTX_new failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: EVP_PKEY_CTX_NEW failed" );
        }
        return NULL;
    }
    int ll = EVP_PKEY_encrypt_init( pkContext );
    if (ll <= 0) {
        LOG_WARNING( "encryptSID: EVP_PKEY_encrypt_init failed" );
        SSL_LogSSLError( );
        EVP_PKEY_CTX_free( pkContext );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: EVP_PKEY_encrypt_init failed" );
        }
        return NULL;
    }

    unsigned char binary[1024]; //should be big enough
    size_t        binLen = 1023;

    ll = EVP_PKEY_encrypt( pkContext, binary, &binLen, (unsigned char*)input, strlen( input ) );

    if (ll <= 0) {
        LOG_WARNING( "encryptSID: EVP_PKEY_encrypt failed" );
        SSL_LogSSLError( );
        EVP_PKEY_CTX_free( pkContext );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: EVP_PKEY_encrypt failed" );
        }
        return NULL;
    }
    EVP_PKEY_CTX_free( pkContext );
    if (binLen > 1023) {
        LOG_WARNING( "encryptSID: EVP_PKEY_encrypt failed: need buffer > 1023 (SOFTWARE CHANGE)" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-encryptSID: EVP_PKEY_encrypt failed" );
        }
        return NULL;
    }

    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-encryptSID: OK followed by base64Encode" );
    }
    return base64Encode( output, max_output, binary, binLen );
}
char* decryptSID( char* output, size_t max_output, char* input ) {
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "+decryptSID" );
    }

    if (output) {
        memset( output, 0, max_output );
    }
    if (!SSL_init( )) {
        LOG_WARNING( "decryptSID: SSL_init failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: SSL_init failed" );
        }
        return NULL;
    }
    if (privateKey == NULL) {
        LOG_WARNING( "decryptSID: no private key" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: no private key" );
        }
        return NULL;
    }

    unsigned char binary[1024] = {0};
    size_t binLen = 0;
    if (!base64Decode( binary, binLen, 1024, input )) {
        LOG_WARNING( "decryptSID: base64Decode failed" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: base64Decode failed" );
        }
        return NULL;
    }

    EVP_PKEY_CTX* pkContext = EVP_PKEY_CTX_new( privateKey, NULL );
    if (pkContext == NULL) {
        LOG_WARNING( "decryptSID: EVP_PKEY_CTX_new failed" );
        SSL_LogSSLError( );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: EVP_PKEY_CTX_NEW failed" );
        }
        return NULL;
    }
    int ll = EVP_PKEY_decrypt_init( pkContext );
    if (ll <= 0) {
        LOG_WARNING( "decryptSID: EVP_PKEY_decrypt_init failed" );
        SSL_LogSSLError( );
        EVP_PKEY_CTX_free( pkContext );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: EVP_PKEY_decrypt_init failed" );
        }
        return NULL;
    }

    unsigned char plain[1024] = {0};
    size_t        plnLen = 1023;
    ll = EVP_PKEY_decrypt( pkContext, plain, &plnLen, binary, binLen );
    if (ll <= 0) {
        LOG_WARNING( "decryptSID: EVP_PKEY_decrypt failed" );
        SSL_LogSSLError( );
        EVP_PKEY_CTX_free( pkContext );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: EVP_PKEY_decrypt failed" );
        }
        return NULL;
    }
    if (plnLen > 1023) {
        LOG_WARNING( "decryptSID: EVP_PKEY_decrypt failed: need buffer > 1023 (SOFTWARE CHANGE)" );
        if (SSL_DEBUG > 0) {
            LOG_FINEST( "-decryptSID: EVP_PKEY_decrypt failed" );
        }
        return NULL;
    }
    char* result = output;
    if (result == NULL) {
        result = (char*)calloc( plnLen + 1, 1 );
    } else {
        if (plnLen >= max_output) {
            LOG_WARNING( "decryptSID: output buffer too small" );
            if (SSL_DEBUG > 0) {
                LOG_FINEST( "-decryptSID: output buffer too small" );
            }
            return NULL;
        }
    }

    memcpy( result, plain, plnLen );
    if (SSL_DEBUG > 0) {
        LOG_FINEST( "-decryptSID OK" );
    }
    return result;
}
#endif

void bio_write_with_timeout( BIO* bio, const char* buffer, int len,
struct timeval* timeout ) {
    int left = len;
    int oneTime = 0;
    const char* ptr = buffer;

    while(left > 0) {
        oneTime = BIO_write( bio, ptr, left );
        if (oneTime == left) {
            /* this should be the most of the cases */
            return; /* all done */
        }
        if (oneTime > 0) {
            left -= oneTime;
            ptr  += oneTime;
            continue;
        }
        BIO_wait( bio, timeout ); /* may throw */
    }
}
int bio_read_fixed_length( BIO* bio, char* buffer, int length,
struct timeval* timeout ) {
    int result = 0;
    int oneTime = 0;
    int total = 0;

    try {
        while(total < length) {
            oneTime = BIO_read( bio, buffer + total, (length - total) );
            if (oneTime > 0) {
                total += oneTime;
            } else {
                BIO_wait( bio, timeout );
            }
        }
        result = 1;
    } catch ( XosException& e ) {
        LOG_WARNING1("BIO_read_fixed_length failed: %s", e.getMessage( ).c_str( ));
    } catch (...) {
    }
    return result;
}
xos_wait_result_t bio_wait_until_readable( BIO* bio, struct timeval* timeout ) {

    int nReadyRead = BIO_pending( bio );
    if (nReadyRead > 0) return XOS_WAIT_SUCCESS;

    int h = BIO_get_fd( bio, NULL );
    if (h < 0) {
        LOG_WARNING( "BIO_wait_until_readable: BIO_get_fd failed" );
        SSL_LogSSLError( );
        return XOS_WAIT_FAILURE;
    }
    fd_set readMask;
    FD_ZERO(&readMask);
    FD_SET(h, &readMask);
    /* here we should setup the errorMask too,
     * but to be consistent with the old socket code,
     * it is ignored.
     */
    int status = select( (h + 1), &readMask, NULL, NULL, timeout );

    if (status > 0) {
        return XOS_WAIT_SUCCESS;
    } else if (status == 0) {
        return XOS_WAIT_TIMEOUT;
    }
    LOG_WARNING( "BIO_wait_until_readable: select failed" );
    return XOS_WAIT_FAILURE;
}
