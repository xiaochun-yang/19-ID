#include "xos.h"
#include "xos_socket.h"
#include "HttpMessage.h"
#include "HttpRequest.h"
#include "HttpClientImp.h"
#include "HttpResponse.h"

//std::string host("smbfs.slac.stanford.edu");
//int port = 14007;
//std::string uri("http://smbfs.slac.stanford.edu:14007/getImage?fileName=/data/penjitk/dataset/pseudomad/myo3_4_E1_001.img&sizeX=400&sizeY=400&percentX=0.5&percentY=0.5&gray=400&zoom=1.0&userName=penjitk&sessionId=16BBA959EE263D11914D18939747DD66");
//std::string uri("http://smb.slac.stanford.edu:8080/imagetext/servlet/BluIceImageStream?beamline=9-1&camera=sample");

std::string host = "";
int port = 0;
std::string uri = "";
std::string fileName = "";

static void test1()
{
	printf("test started\n"); fflush(stdout);
	
	xos_socket_t socket;
	
	if (xos_socket_create_client(&socket) != XOS_SUCCESS) {
		printf("Failed to create socket\n"); fflush(stdout);
		return;
	}
	
	xos_socket_address_t addr;
	
	if (xos_socket_address_init(&addr) != XOS_SUCCESS) {
		printf("Failed to create socket address\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_ip_by_name(&addr, host.c_str()) != XOS_SUCCESS) {
		printf("Failed to set socket address ip my name\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_port(&addr, port) != XOS_SUCCESS) {
		printf("Failed to set socket address port\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_make_connection(&socket, &addr) != XOS_SUCCESS) {
		printf("Failed to make socket connection\n"); fflush(stdout);
		return;
	}
	
	char request[5000];
	
	strcpy(request, "GET ");
	strcat(request, uri.c_str());
	strcat(request, " HTTP/1.1\r\n");
	strcat(request, "User-Agent: http test/0.1\r\n");
	strcat(request, "Host: ");
	strcat(request, host.c_str());
	strcat(request, ":");
	strcat(request, XosStringUtil::fromInt(port).c_str());
	strcat(request, "\r\n");
	strcat(request, "Accept: text/html, image/gif, image/jpeg, *; q=.2, */*; q=.2\r\n");
	strcat(request, "Connection: keep-alive\r\n");
	strcat(request, "\r\n");
	
	
	printf("Writing HTTP request: %s\n", request); fflush(stdout);
	if (xos_socket_write(&socket, request, strlen(request)) != XOS_SUCCESS) {
		printf("Failed to write to socket\n"); fflush(stdout);
		return;
	}
	
	if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SOCKET_SHUTDOWN_WRITE) != 0 ) {
		printf("Failed to shutdown write for socket\n"); fflush(stdout);
		return;
	}
	
	xos_wait_result_t ret;
	printf("Waiting for socket to be reable\n"); fflush(stdout);
	while ((ret=xos_socket_wait_until_readable(&socket, 1000)) != XOS_WAIT_SUCCESS) {
		if (ret == XOS_WAIT_FAILURE) {
			printf("Failed to wait for socket to be reable\n"); fflush(stdout);
			return;
		}
	}

	printf("Reading from socket\n"); fflush(stdout);
	int received = 0;
	char responseLine[1000];
	if (xos_socket_read_line(&socket, responseLine, 1000, &received) != XOS_SUCCESS) {
		printf("Failed to read HTTP response line\n"); fflush(stdout);
		return;
	}
	
	printf("%s\n", responseLine); fflush(stdout);
	
	// Read headers
	char header[1000];
	while (xos_socket_read_line(&socket, header, 1000, &received) == XOS_SUCCESS) {
		// Found an empty line
		if (received == 0)
			break;
			
		printf("%s\n", header); fflush(stdout);
	}
	

   // Open file in binary mode
   FILE* stream = fopen(fileName.c_str(), "w+b" );
	
	// Read body
	char body[5000];
	memset(body, 0, 5000);
	received = 0;
	while (xos_socket_read_any_length(&socket, body, 5000, &received) == XOS_SUCCESS) {
		printf("got body size = %d\n", received);
		if (received > 0) {
//			body[received] = '\0';
//			printf(body); fflush(stdout);
			if (stream)
				fwrite(body, sizeof(char), received, stream);
		}
		memset(body, 0, 5000);
	}
	
	if (stream)
		fclose( stream );
		
	stream = NULL;

	
	
	if (xos_socket_destroy(&socket) != XOS_SUCCESS) {
		printf("Failed to destroy socket\n"); fflush(stdout);
		return;
	}

	printf("\ntest finished\n"); fflush(stdout);

}


static void test2()
{
//	printf("test started\n"); fflush(stdout);

	HttpClientImp  client;
	client.setAutoReadResponseBody(true);
	
	HttpRequest* request = client.getRequest();
	
	request->setURI(uri);
	request->setHost(host);
	request->setPort(port);
	request->setMethod(HTTP_GET);
	
//	printf("Sending HTTP request\n"); fflush(stdout);


	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
//	printf("Got response\n"); fflush(stdout);

	if (response->getStatusCode() != 200) {
		printf("Failed to browse %s: %s\n", 
				uri.c_str(),
				response->getStatusPhrase().c_str());
		fflush(stdout);
	}
	
//	printf(response->getBody().c_str()); fflush(stdout);
	
//	printf("\ntest finished\n"); fflush(stdout);
	
	
}

static void test3()
{
//	printf("test started\n"); fflush(stdout);

	HttpClientImp*  client = new HttpClientImp();
	client->setAutoReadResponseBody(true);
	
	HttpRequest* request = client->getRequest();
	
	request->setURI(uri);
	request->setHost(host);
	request->setPort(port);
	request->setMethod(HTTP_GET);
	
//	printf("Sending HTTP request\n"); fflush(stdout);


	// Send the request and wait for a response
	HttpResponse* response = client->finishWriteRequest();
	
//	printf("Got response\n"); fflush(stdout);

	if (response->getStatusCode() != 200) {
		printf("Failed to browse %s: %s\n", 
				uri.c_str(),
				response->getStatusPhrase().c_str());
		fflush(stdout);
	}
	
//	printf(response->getBody().c_str()); fflush(stdout);
	
//	printf("\ntest finished\n"); fflush(stdout);
	
	delete client;
	
}


static void test4(char* request)
{
	printf("test started\n"); fflush(stdout);
	
	xos_socket_t socket;
	
	if (xos_socket_create_client(&socket) != XOS_SUCCESS) {
		printf("Failed to create socket\n"); fflush(stdout);
		return;
	}
	
	xos_socket_address_t addr;
	
	if (xos_socket_address_init(&addr) != XOS_SUCCESS) {
		printf("Failed to create socket address\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_ip_by_name(&addr, host.c_str()) != XOS_SUCCESS) {
		printf("Failed to set socket address ip my name\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_port(&addr, port) != XOS_SUCCESS) {
		printf("Failed to set socket address port\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_make_connection(&socket, &addr) != XOS_SUCCESS) {
		printf("Failed to make socket connection\n"); fflush(stdout);
		return;
	}
	
	
	
	printf("Writing HTTP request: %s\n", request); fflush(stdout);
	if (xos_socket_write(&socket, request, strlen(request)) != XOS_SUCCESS) {
		printf("Failed to write to socket\n"); fflush(stdout);
		return;
	}
	
	if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SOCKET_SHUTDOWN_WRITE) != 0 ) {
		printf("Failed to shutdown write for socket\n"); fflush(stdout);
		return;
	}
	
	xos_wait_result_t ret;
	printf("Waiting for socket to be reable\n"); fflush(stdout);
	while ((ret=xos_socket_wait_until_readable(&socket, 1000)) != XOS_WAIT_SUCCESS) {
		if (ret == XOS_WAIT_FAILURE) {
			printf("Failed to wait for socket to be reable\n"); fflush(stdout);
			return;
		}
	}

	printf("Reading from socket\n"); fflush(stdout);
	int received = 0;
	char responseLine[1000];
	if (xos_socket_read_line(&socket, responseLine, 1000, &received) != XOS_SUCCESS) {
		printf("Failed to read HTTP response line\n"); fflush(stdout);
		return;
	}
	
	printf("%s\n", responseLine); fflush(stdout);
	
	// Read headers
	char header[1000];
	while (xos_socket_read_line(&socket, header, 1000, &received) == XOS_SUCCESS) {
		// Found an empty line
		if (received == 0)
			break;
			
		printf("%s\n", header); fflush(stdout);
	}
	

   // Open file in binary mode
   FILE* stream = fopen(fileName.c_str(), "w+b" );
	
	// Read body
	char body[5000];
	memset(body, 0, 5000);
	received = 0;
	while (xos_socket_read_any_length(&socket, body, 5000, &received) == XOS_SUCCESS) {
		printf("got body size = %d\n", received);
		if (received > 0) {
//			body[received] = '\0';
//			printf(body); fflush(stdout);
			if (stream)
				fwrite(body, sizeof(char), received, stream);
		}
		memset(body, 0, 5000);
	}
	
	if (stream)
		fclose( stream );
		
	stream = NULL;

	
	
	if (xos_socket_destroy(&socket) != XOS_SUCCESS) {
		printf("Failed to destroy socket\n"); fflush(stdout);
		return;
	}

	printf("\ntest finished\n"); fflush(stdout);

}


int main(int argc, char** argv)
{

	if (argc < 5) {
		printf("Usage: test <host> <port> <url> <output filename>\n");
		exit(0);
	}
	
	host = argv[1];
	port = atoi(argv[2]);
	uri = argv[3];
	fileName = argv[4];
	
	xos_socket_library_startup();
	
	char request[5000];
	
	strcpy(request, 
"GET /gateway/servlet/SessionStatus;jsessionid=test?AppName=SMBTest HTTP/1.0\r\n"
"Host: smb:8180\r\n"
"Accept: text/html, text/plain, audio/mod, image/*, video/mpeg, video/*, application/pgp, application/pdf, application/postscript, message/partial, message/external-body, x-be2, application/andrew-inset, text/richtext, text/enriched, x-sun-attachment\r\n"
"Accept: audio-file, postscript-file, default, mail-file, sun-deskset-message, application/x-metamail-patch, application/msword, application/x-java-jnlp-file, text/sgml, */*;q=0.01\r\n"
"Accept-Encoding: gzip, compress\r\n"
"Accept-Language: en\r\n"
"User-Agent: Lynx/2.8.4rel.1 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6b\r\n\r\n");

	printf("\n\n**********************\n");
	printf("quest from blctlxx: this should NOT work\n");
	test4(request);

	strcpy(request, 
"GET /gateway/servlet/SessionStatus;jsessionid=test?AppName=SMBTest HTTP/1.0\r\n"
"Host: smb:8180\r\n"
"Accept: text/html, text/plain, image/jpeg, image/*, text/sgml, video/mpeg, application/postscript, */*;q=0.01\r\n"
"Accept-Encoding: gzip, compress\r\n"
"Accept-Language: en\r\n"
"User-Agent: Lynx/2.8.4rel.1 libwww-FM/2.14 SSL-MM/1.4.1 OpenSSL/0.9.6i\r\n\r\n");

	printf("\n\n**********************\n");
	printf("quest from smb: this should work\n");
	test4(request);

	strcpy(request, 
"GET http://smb:8180/gateway/servlet/SessionStatus;jsessionid=test?AppName=SMBTest&ValidBeamlines=True HTTP/1.1\r\n"
"Host: smb:8180\r\n\r\n");
	printf("\n\n**********************\n");
	printf("quest from TEST program: this should work\n");
	test4(request);



	xos_socket_library_cleanup();
	
	return 0;
}


