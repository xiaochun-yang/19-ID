#include <openssl/bio.h>

#include "xos.h"

int SSL_init( );

void BIO_wait( BIO* bio, struct timeval* timeout );
void SSL_setDebugFlag( int debugFlag );
void SSL_LogSSLError( );

/* for encrypt/decrypt session ID using DCSS certificate */
// output == NULL will return an allocated buffer and caller needs to free it.
// if output != NULL and max_output is too small will cause failure.
// encrypt is only for public key
// decrypt is only for private key
// it only intend for SID, not exceed 100 bytes, so no loop inside
void loadDCSSCertificate( const char* pem_filename );
void loadDCSSPrivateKey( const char* pem_filename, char* pass_phrase );
int  dcssPKIReady( );
char* encryptSID( char* output, size_t max_output, char* input );
char* decryptSID( char* output, size_t max_output, char* input );

//////////////moved drom dcss_ssl////////////////
void bio_write_with_timeout( BIO* bio, const char* buffer, int len,
struct timeval* timeout );

int bio_read_fixed_length( BIO* bio, char* buffer, int length,
struct timeval* timeout );

xos_wait_result_t bio_wait_until_readable( BIO* bio, struct timeval* timeout );
