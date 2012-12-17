#include "xos.h"
#include "xos_socket.h"
#include "XosConfig.h"
#include "XosStringUtil.h"
#include "HttpConst.h"

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
	xos_socket_address_init( &address );
	xos_socket_address_set_ip_by_name( &address, host.c_str() );
	xos_socket_address_set_port( &address, port );


	int num = 0;
	int total = 0;
	int bufSize = 8192;
	char buf[8192];
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

		std::string url("/getImage");
		url +=   "?fileName=" + imageFilename 
				+ "&userName=" + userName 
				+ "&sessionId=" + sessionId
				+ "&sizeX=400&sizeY=400&zoom=1.0&gray=400&percentX=0.5&percentY=0.5";	

		std::string line = std::string("GET ") + url + " HTTP/1.1" + CRLF;
		line += std::string("Host: ") + host + ":" + XosStringUtil::fromInt(port) + CRLF;
		line += std::string("Connection: close") + CRLF;
		line += std::string(CRLF);

		// create the socket to connect to server
		xos_socket_t socket;
		if (xos_socket_create_client( &socket ) != XOS_SUCCESS)
			xos_error_exit("Failed in xos_socket_create_client");

		// connect to the server
		if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS)
			xos_error_exit("Failed in xos_socket_make_connection");

		// write the first line
		if (xos_socket_write( &socket, line.c_str(), line.size()) != XOS_SUCCESS)
			xos_error_exit("Failed in xos_socket_write");

		// shutdown the writing side of the socket
		if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 )
			xos_error_exit("Failed in SOCKET_SHUTDOWN");

		
		// convert the file descriptor to a stream
		FILE* in;
		if ( (in=fdopen(socket.clientDescriptor, "r" )) == NULL ) {
			xos_error_exit("Failed in fdopen\n");
		}

		total = 0;
		while (!feof(in)) {

			num = fread(buf, sizeof(char), bufSize, in);

			if (num > 0) {		
				if (total == 0) {
					if (strstr(buf, "200 OK") == NULL) {
						xos_error_exit("Failed to get image: %s\n", buf);
					}
				}
				total += num;
			}

		}

    	
		xos_socket_destroy(&socket);
		
    	printf("Got image %s size = %d numImages = %d\n", 
    			imageFilename.c_str(), total, count);
    			
    	// Sleep in msec
    	printf("entering sleep..."); fflush(stdout);
    	xos_thread_sleep(5000);
    	printf("woken up\n"); fflush(stdout);
    
	
	} // loop forever	
	
	
	return 0;
	
}


