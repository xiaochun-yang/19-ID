#include "xos.h"
#include "xos_socket.h"
#include "HttpMessage.h"
#include "HttpRequest.h"
#include "HttpClientImp.h"
#include "HttpResponse.h"
/**
 * Send HTTP request through simple socket
 */
static void sendRequest(std::string host,
						int port,
						std::string& request)
{
	
	xos_socket_t socket;
	
	if (xos_socket_create_client(&socket) != XOS_SUCCESS) {
		printf("ERROR: Failed to create socket\n"); fflush(stdout);
		return;
	}
	
	xos_socket_address_t addr;
	
	if (xos_socket_address_init(&addr) != XOS_SUCCESS) {
		printf("ERROR: Failed to create socket address\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_ip_by_name(&addr, host.c_str()) != XOS_SUCCESS) {
		printf("ERROR: Failed to set socket address ip my name\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_address_set_port(&addr, port) != XOS_SUCCESS) {
		printf("ERROR: Failed to set socket address port\n"); fflush(stdout);
		return;
	}
	
	if (xos_socket_make_connection(&socket, &addr) != XOS_SUCCESS) {
		printf("ERROR: Failed to make socket connection\n"); fflush(stdout);
		return;
	}
	
	
	if (xos_socket_write(&socket, request.c_str(), request.size()) != XOS_SUCCESS) {
		printf("ERROR: Failed to write to socket\n"); fflush(stdout);
		return;
	}
	
	if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SOCKET_SHUTDOWN_WRITE) != 0 ) {
		printf("ERROR: Failed to shutdown write for socket\n"); fflush(stdout);
		return;
	}
	
	xos_wait_result_t ret;
	while ((ret=xos_socket_wait_until_readable(&socket, 1000)) != XOS_WAIT_SUCCESS) {
		if (ret == XOS_WAIT_FAILURE) {
			printf("ERROR: Failed to wait for socket to be reable\n"); fflush(stdout);
			return;
		}
	}

	int received = 0;
	char responseLine[1000];
	if (xos_socket_read_line(&socket, responseLine, 1000, &received) != XOS_SUCCESS) {
		printf("ERROR: Failed to read HTTP response line\n"); fflush(stdout);
		return;
	}
	
	printf("%s\r\n", responseLine); fflush(stdout);
	
	// Read headers
	char header[1000];
	while (xos_socket_read_line(&socket, header, 1000, &received) == XOS_SUCCESS) {
		// Found an empty line
		if (received == 0)
			break;
			
		printf("%s\r\n", header); fflush(stdout);
	}
	
	// end of header
	printf("\r\n");
	
	
	// Read body
	char body[5000];
	memset(body, 0, 5000);
	received = 0;
	while (xos_socket_read_any_length(&socket, body, 5000, &received) == XOS_SUCCESS) {
		if (received > 0) {
			fwrite(body, sizeof(char), received, stdout);
		}
		memset(body, 0, 5000);
	}
		
	
	if (xos_socket_destroy(&socket) != XOS_SUCCESS) {
		printf("Failed to destroy socket\n"); fflush(stdout);
		return;
	}


}

static void send(const std::string& host, int port, const std::string& uri)
{

	HttpClientImp  client;
	client.setAutoReadResponseBody(true);
	
	HttpRequest* request = client.getRequest();

	request->setURI(uri);
	request->setHost(host);
	request->setPort(port);
	request->setMethod(HTTP_GET);
	
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	int status = response->getStatusCode();
	if (status != 200) {
		printf("%d %s\n", status, response->getStatusPhrase().c_str());
	} else {
		printf("200 %s\n", response->getBody().c_str()); 
	}
}

/**
 * Simple http program for sending request to the authentication server.
 * Response is sent out to stdout.
 */
int main(int argc, char** argv)
{

	if (argc < 4) {
		printf("Usage: http_client <host> <port> <url>\n");
		exit(0);
	}
	
	std::string host = argv[1];
	std::string port = argv[2];
	std::string url = argv[3];
	
//	printf("http_client: url = %s\n", url.c_str());
		
	send(host, atoi(port.c_str()), url);
//	sendRequest(host, atoi(port.c_str()), url);

	
	return 0;
}


