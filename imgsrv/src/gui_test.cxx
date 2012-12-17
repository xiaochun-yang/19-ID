#include "xos.h"
#include "xos_socket.h"
#include "XosConfig.h"
#include "XosStringUtil.h"



int main(int argc, char** argv)

{	

	if (argc < 2) {
		printf("Usage gui_test <config file>\n");
		exit(0);
	}
	
	std::string configFile = argv[1];
	
	bool forever = true;
	int count = 0;
	
	int sizex = 400;
	int sizey = 400;
	double zoom = 1.0;
	double gray = 400.0;
	double percentx = 0.5;
	double percenty = 0.5;

	std::string host;
	int port;
	std::string imageFilename("");
	std::string userName("");
	std::string sessionId("");
	std::string dir("");
	std::string fileRoot("");
	int startIndex;
	int endIndex;

	XosConfig config(configFile);
	
	if (!config.load())
		xos_error_exit("Failed to load config\n");


	if (!config.get("host", host))
		xos_error_exit("Missing host config\n");
	std::string str;
	if (!config.get("port", str))
		xos_error_exit("Missing port config\n");
	port = atoi(str.c_str());
	if (!config.get("userName", userName))
		xos_error_exit("Missing userName config\n");
	if (!config.get("sessionId", sessionId))
		xos_error_exit("Missing sessionId config\n");
	if (!config.get("dir", dir))
		xos_error_exit("Missing dir config\n");
	if (!config.get("fileRoot", fileRoot))
		xos_error_exit("Missing fileRoot config\n");
	if (!config.get("startIndex", str))
		xos_error_exit("Missing startIndex config\n");
	startIndex = atoi(str.c_str());
	if (!config.get("endIndex", str))
		xos_error_exit("Missing endIndex config\n");
	endIndex = atoi(str.c_str());

	xos_socket_address_t    address;
    xos_socket_t socket;

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, host.c_str() );
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

	//initialize the input buffers for the socket messages
	dcs_message_t dcsMessage;
	xos_initialize_dcs_message( &dcsMessage, 10, 10 );

	int size = 0;
	int total = 0;
	int bufSize = 8192;
	char buf[8192];
	char token[26];
	bool hasMoreToRead = true;
	int index = startIndex;
	while (forever) {
	
		++count;
		
		++index;
		
		if (index > endIndex)
			index = startIndex;
		
		imageFilename = dir + "/" + fileRoot;
		
		if (index < 10)
			imageFilename += "0";
		
		imageFilename += XosStringUtil::fromInt(index) + ".img";

		char textMessage[200];
		sprintf(textMessage, "%s %s %s %d %d %lf %lf %lf %lf", 
					 userName.c_str(), sessionId.c_str(), imageFilename.c_str(), 
					 sizex, sizey, zoom, gray, percentx, percenty );
		
		// Send a request
		if (xos_send_dcs_text_message (&socket, textMessage) != XOS_SUCCESS) {
		
			printf("Failed to send dcs request message\n");
			goto cleanup_and_exit;
		
		}
			
		// Get image header
		if (xos_receive_dcs_message(&socket, &dcsMessage) != XOS_SUCCESS) {

			printf("Failed to receive dcs request message\n");
			goto cleanup_and_exit;
		}
		printf("Got dcs response: %s\n", dcsMessage.textInBuffer); fflush(stdout);

		// Get Image
		size = 0;
		total = 0;
		while (hasMoreToRead) {

			if (xos_socket_read(&socket, buf, bufSize) != XOS_SUCCESS) {
				printf("Failed in xos_socket_read\n");
				goto cleanup_and_exit;
			}
			if (strstr(buf,"stoc_END_JPEG_NEXT_BUFFER") == NULL) {
				total += bufSize;
			} else {
				sscanf((char*)(buf+26),"%s", token);
				size=atoi(token);
				printf("about to read last chunk size %d\n", size);
				if (xos_socket_read(&socket, buf, size) != XOS_SUCCESS) {
					printf("Failed to read image last chunk\n");
					goto cleanup_and_exit;
				}
				total += size;
				break;
			}
    	}
    	
    	printf("Got image %s size = %d numImages = %d\n", 
    			imageFilename.c_str(), total, count);
    			
    	// Sleep in msec
    	printf("entering sleep..."); fflush(stdout);
    	xos_thread_sleep(100);
    	printf("woken up\n"); fflush(stdout);
    
	
	} // loop forever	
	
cleanup_and_exit:

	xos_destroy_dcs_message(&dcsMessage);
	xos_socket_destroy(&socket);
	

	
	return 0;	
}


