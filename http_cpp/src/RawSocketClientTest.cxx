#include "xos.h"
#include "xos_socket.h"
#include "HttpMessage.h"
#include "HttpRequest.h"
#include "HttpClientImp.h"
#include "HttpResponse.h"

std::string host = "";
int port = 0;
std::string inputFileName = "";
std::string outputFileName = "";


static void test()
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
	
	FILE* in = fopen(inputFileName.c_str(), "r");
	
	if (in == NULL) {
		printf("Failed to open %s file for reading\n");
		return;
	}
	
	char buf[5000];
	size_t numBytes = 0;
	while ((numBytes = fread(buf, sizeof(char), 5000, in)) > 0) {
		if (xos_socket_write(&socket, buf, numBytes) != XOS_SUCCESS) {
			printf("Failed to write to socket\n"); fflush(stdout);
			fclose(in);
			return;
		}
	}
	
	fclose(in);
	
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
   FILE* stream = fopen(outputFileName.c_str(), "w");
	
	// Read body
	char body[5000];
	memset(body, 0, 5000);
	received = 0;
	while (xos_socket_read_any_length(&socket, body, 5000, &received) == XOS_SUCCESS) {
		printf("got body size = %d\n", received);
		if (received > 0) {
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
		printf("Usage: rawsocketclient_test <host> <port> <input filename> <output filename>\n");
		exit(0);
	}
	
	host = argv[1];
	port = atoi(argv[2]);
	inputFileName = argv[3];
	outputFileName = argv[4];
	
	xos_socket_library_startup();
	
	test();
	
	xos_socket_library_cleanup();
	
	return 0;
}


