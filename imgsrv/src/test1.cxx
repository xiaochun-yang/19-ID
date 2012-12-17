extern "C" {
#include "xos.h"
#include "xos_socket.h"
}

#include "XosTimeCheck.h"

int sizex = 400;
int sizey = 400;
double zoom = 1.0;
double gray = 400.0;
double percentx = 0.5;
double percenty = 0.5;

std::string command = "getImage";

void print_usage_and_exit()
{
	printf("Usage: test1 <protocol> <host> <port> <username> <session id>\n");
	printf("Usage: test1 1 <host> <port> <filename>\n");
	printf("Usage: test1 2 <host> <port> <filename> <username> <session id>\n");
	printf("Usage: test1 3 <host> <port> <command> <filename> <username> <session id>\n");
	printf("protocol = 1 for old protocol\n");
	printf("protocol = 2 for new gui protocol (with user name and session id)\n");
	printf("protocol = 3 for http protocol\n");
	exit(0);
}




void test_old_protocol(int argc, char** argv)
{
	XosTimeCheck timeCheck("TIME check for test_old_protocol");
	
	char* host;
	int port;
	char* imageFilename;

	if (argc != 5) {
		print_usage_and_exit();
	}
	
	host = argv[2];
	port = atoi(argv[3]);
	
	imageFilename = argv[4];

	printf("connecting to %s:%d\n", host, port);

	xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host );
    xos_socket_address_set_port( &address, port );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
        printf("Failed in sendRequestLine: xos_socket_create_client");
        exit(0);
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
        printf("Failed in xos_socket_make_connection");
        exit(0);
    }
    
    
    char buf[200];
	sprintf ( buf, "%s %d %d %lf %lf %lf %lf", 
				 imageFilename, sizex, sizey, 
				 zoom, gray, percentx, percenty );
				 
    printf("Sending request\n");
    fwrite(buf, sizeof(char), 200, stdout);
    printf("\n");
	
				 
    // write the first line
    if (xos_socket_write( &socket, buf, 200) != XOS_SUCCESS) {
        printf("Failed in xos_socket_write");
        exit(0);
    }


	// Read the image. Unknown size.
	bool forever = true;
	int size = 0;
	int total = 0;
	char tmp[1000];
	
	FILE* file = fopen("./test_old.jpg", "wb");
	
	while (forever) {
		size = 0;
		if (xos_socket_read_any_length(&socket, tmp, 1000, &size) != XOS_SUCCESS) {
			if (size > 0) {
				total += size;
				fwrite(tmp, sizeof(char), size, file);
			}
			break;
		}
		if (size > 0) {
			total += size;
			fwrite(tmp, sizeof(char), size, file);
		}
    }
    
    fclose(file);
    
    printf("Finished reading response: image size = %d\n", total);
	
	xos_socket_destroy(&socket);
	
	timeCheck.finish();
	
	exit(0);

	
}


void test_new_protocol(int argc, char** argv)
{
	XosTimeCheck timeCheck("TIME check for test_new_protocol");
	
	char* host;
	int port;
	char* imageFilename;
	char* userName;
	char* sessionId;

	if (argc != 7) {
		print_usage_and_exit();
	}
	
	host = argv[2];
	port = atoi(argv[3]);
	
	imageFilename = argv[4];
	userName = argv[5];
	sessionId = argv[6];

	printf("connecting to %s:%d\n", host, port);


	xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host );
    xos_socket_address_set_port( &address, port );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
        printf("Failed in sendRequestLine: xos_socket_create_client");
        exit(0);
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
        printf("Failed in xos_socket_make_connection");
        exit(0);
    }
    
    
    char buf[200];
	sprintf ( buf, "%s %s %s %d %d %lf %lf %lf %lf", 
				 userName, sessionId, imageFilename, sizex, sizey, 
				 zoom, gray, percentx, percenty );
				 
    printf("Sending request\n");
    fwrite(buf, sizeof(char), 200, stdout);
    printf("\n");
	
				 
    // write the first line
    if (xos_socket_write( &socket, buf, 200) != XOS_SUCCESS) {
        printf("Failed in xos_socket_write");
        exit(0);
    }


	// Read the image. Unknown size.
	bool forever = true;
	int size = 0;
	int total = 0;
	char tmp[1000];
	
	FILE* file = fopen("./test_new.jpg", "wb");
	
	while (forever) {
		size = 0;
		if (xos_socket_read_any_length(&socket, tmp, 1000, &size) != XOS_SUCCESS) {
			if (size > 0) {
				total += size;
				fwrite(tmp, sizeof(char), size, file);
			}
			break;
		}
		if (size > 0) {
			total += size;
			fwrite(tmp, sizeof(char), size, file);
		}
    }
    
    fclose(file);
    
    printf("Finished reading response: image size = %d\n", total);
	
	xos_socket_destroy(&socket);
	
	timeCheck.finish();
	
	exit(0);

	
}

static void test_http_protocol(int argc, char** argv)
{
	char* host;
	char* portStr;
	int port;
	char* command;
	char* imageFilename;
	char* userName;
	char* sessionId;
	std::string CRLF("\012\015");

	if (argc != 8) {
		print_usage_and_exit();
	}
	
	host = argv[2];
	portStr = argv[3];
	port = atoi(portStr);
	
	command = argv[4];
	imageFilename = argv[5];
	userName = argv[6];
	sessionId = argv[7];

	printf("connecting to %s:%d\n", host, port);

	XosTimeCheck timeCheck("TIME check for test_http_protocol");

	xos_socket_t socket;
    xos_socket_address_t    address;
    

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host);
    xos_socket_address_set_port( &address, port);

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
        printf("Failed in xos_socket_create_client");
        exit(0);
    }

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
       printf("Failed in xos_socket_make_connection");
       exit(0);
	}
	
    // create the request packet
	std::string url("/");
	url +=   std::string(command)
			+ std::string("?fileName=") + imageFilename 
			+ std::string("&userName=") + userName
			+ std::string("&sessionId=") + sessionId
			+ std::string("&sizeX=400&sizeY=400&zoom=2.0&gray=400&percentX=0.5&percentY=0.5");	


    std::string line = std::string("GET ") + url + " HTTP/1.1" + CRLF;
	line += std::string("Host: ") + host + ":" + std::string(portStr) + CRLF;
	line += std::string("Connection: close") + CRLF;
	line += CRLF;
		
	printf("request = %s\n", line.c_str()); fflush(stdout);	
	
    // write the first line
    if (xos_socket_write( &socket, line.c_str(), line.size()) != XOS_SUCCESS) {
        printf("Failed in xos_socket_write");
        exit(0);
    }

    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 ) {
        printf("Failed in  SOCKET_SHUTDOWN");
        exit(0);
	}
	
	// Read the image. Unknown size.
	bool forever = true;
	int size = 0;
	int total = 0;
	char tmp[1000];

	FILE* file = fopen("./test_http.jpg", "w");
	
	while (forever) {
		size = 0;
		if (xos_socket_read_any_length(&socket, tmp, 1000, &size) != XOS_SUCCESS) {
			if (size > 0) {
				total += size;
				fwrite(tmp, sizeof(char), size, file);
			}
			break;
		}
		if (size > 0) {
			total += size;
			fwrite(tmp, sizeof(char), size, file);
		}
    }
    
    fclose(file);
    
    printf("Finished reading response: image size = %d\n", total);
	
	xos_socket_destroy(&socket);
	
	timeCheck.finish();
	
	exit(0);

}

int main(int argc, char** argv)

{

	if (argc < 2) {
		print_usage_and_exit();
	}
		
	if (strcmp(argv[1], "1") == 0) {
		test_old_protocol(argc, argv);
	} else if (strcmp(argv[1], "2") == 0) {
		test_new_protocol(argc, argv);
	} else if (strcmp(argv[1], "3") == 0) {
		test_http_protocol(argc, argv);
	} else {
		printf("Invalid protocol\n");
	}
	
	return 0;
	
}



