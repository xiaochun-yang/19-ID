extern "C" {
#include "xos.h"
#include "xos_log.h"
#include "xos_http.h"
}

#include "XosException.h"
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"

std::string imgSrvServer = "smbdev2";
int imgSrvPort = 15007;
 

/**
 * Read jpeg from image server and returns the jpeg size
 */
static int getImage(const std::string& userName, 
			const std::string& sessionId,
			const std::string& filename)
{

	xos_socket_t socket;
	xos_socket_address_t    address;
    
	std::string url("/getImage");
	url +=   "?fileName=" + filename 
			+ "&userName=" + userName
			+ "&sessionId=" + sessionId
			+ "&sizeX=400&sizeY=400&zoom=1.0&gray=400&percentX=0.5&percentY=0.5";	

	// create an address structure pointing at the authentication server
	xos_socket_address_init( &address );
	xos_socket_address_set_ip_by_name( &address, imgSrvServer.c_str() );
	xos_socket_address_set_port( &address, imgSrvPort );

	// create the socket to connect to server
	if (xos_socket_create_client( &socket ) != XOS_SUCCESS) {
		xos_socket_destroy(&socket);
		throw XosException("Failed in sendRequestLine: xos_socket_create_client");
	}

	// connect to the server
	if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS) {
		xos_socket_destroy(&socket);
		throw XosException("Failed in sendRequestLine: xos_socket_make_connection");
	}

	// create the request packet
	std::string line = std::string("GET ") + url + " HTTP/1.1" + CRLF;
	line += std::string("Host: ") + imgSrvServer + ":" + XosStringUtil::fromInt(imgSrvPort) + CRLF;
	line += std::string("Connection: close") + CRLF;
	line += std::string(CRLF);
	
//	printf("request => %s\n", line.c_str());
	
	
	// write the first line
	if (xos_socket_write( &socket, line.c_str(), line.size()) != XOS_SUCCESS) {
		xos_socket_destroy(&socket);
		throw XosException("Failed in sendRequestLine: xos_socket_write");
	}

	// shutdown the writing side of the socket
	if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 ) {
		xos_socket_destroy(&socket);
		throw XosException("Failed in  SOCKET_SHUTDOWN");
	}

	// Read response
	// read the HTTP result
	char buf[1000];
	int bufSize = 1000;    
	int num;
	int total = 0;
	bool done = false;
	while (!done) {

		buf[0] = '\0';
		num = read(socket.clientDescriptor, buf, bufSize);
		if (num == 0)
			break;
		total += num;
	}
	
	if (xos_socket_destroy(&socket) != XOS_SUCCESS)
		printf("Failed in xos_socket_destroy\n");
	
	return total;
    
}


static void getOneImageManyTimes(const std::string& userName,
				const std::string& sessionId,
				const std::string& fileName,
				int maxLoop)
{
	int numLoop = 0;
	int contentLength = 0;
	while (numLoop < maxLoop) {
		contentLength = getImage(userName, sessionId, fileName);
		printf("loop %d content length = %d bytes\n", numLoop, contentLength); fflush(stdout);
		numLoop += 1;
		xos_thread_sleep(100);
	}
}


/**
 * Get 11 different images so that the cache is changed for each request.
 */
static void getManyImagesManyTimes(const std::string& userName,
				const std::string& sessionId,
				const std::string& imageDir,
				int maxLoop)
{
	int numLoop = 0;
	int contentLength = 0;
	int maxFiles = 11;
	std::string files[11];
	files[0] = imageDir + "/ana2/F3/vinc_F3_021.img";
	files[1] = imageDir + "/ana2/F3/vinc_F3_022.img";
	files[2] = imageDir + "/ana2/F4/vinc_F4_021.img";
	files[3] = imageDir + "/ana2/F4/vinc_F4_022.img";
	files[4] = imageDir + "/ana2/F5/vinc_F5_021.img";
	files[5] = imageDir + "/ana2/F5/vinc_F5_022.img";
	files[6] = imageDir + "/ana2/G3/vinc_G3_021.img";
	files[7] = imageDir + "/ana2/G3/vinc_G3_022.img";
	files[8] = imageDir + "/ana2/H3/vinc_H3_021.img";
	files[9] = imageDir + "/ana2/H3/vinc_H3_022.img";
	files[10] = imageDir + "/ana2/H5/vinc_H5_021.img";
	
	while (numLoop < maxLoop) {
		for (int i = 0; i < maxFiles; ++i) {
			contentLength = getImage(userName, sessionId, files[i]);
			printf("loop %d content length = %d bytes file = %s\n", numLoop, contentLength, files[i].c_str()); fflush(stdout);
			numLoop += 1;
			xos_thread_sleep(100);
		}
	}
}

/**
 */
static void sendBadRequestManyTimes(const std::string& userName, const std::string& sessionId, int maxLoop)
{
	int numLoop = 0;
	int contentLength = 0;
	std::string fileName = "";
	while (numLoop < maxLoop) {
		fileName = "xxx_" + XosStringUtil::fromInt(numLoop);
		contentLength = getImage(userName, sessionId, fileName);
		printf("loop %d content length = %d bytes\n", numLoop, contentLength); fflush(stdout);
		numLoop += 1;
		xos_thread_sleep(100);
	}
}


/**
 * 1. Get the same image for each request. Check if thread is released after a client is done. Check if we will reach 
 *    max thread.
 *    Usage: test_cache <userName> <sessionId> <imagePath>
 * 2. Get a different image each time so that the cache is full and an image is flushed out to make room for the
 *    newly requested image.
 *    Usage: test_cache <userName> <sessionId> <imageDir>
 * 3. Send bad requests many times.
 *    Usage: test_cache <userName> <sessionId> any_string
 */
int  main(int argc, char** argv) 
{
	try {

		if (argc != 5) {
			printf("Usage: test <command> <userName> <sessionId> <imageFile | imageDir | arbitrary_string>\n");
			printf("command: 1=request one image many times, 2=request many images many times, 3=request non-existent image\n");
			printf("Examples:\n");
			printf("test_cache 1 penjitk 109C4EE65D9C03429D8965F0B29DE21E /data/penjitk/dataset/myo_1_001.img\n");
			printf("test_cache 2 penjitk 109C4EE65D9C03429D8965F0B29DE21E /data/penjitk/dataset\n");
			printf("test_cache 3 penjitk 109C4EE65D9C03429D8965F0B29DE21E blabla\n");
			exit(0);
		}

		xos_log_init(stdout);

		// Create a new user
		std::string command = argv[1];
		std::string userName = argv[2];
		std::string sessionId = argv[3];
		std::string fileName = argv[4];
		
		if (command == "1") {
			getOneImageManyTimes(userName, sessionId, fileName, 10000);
		} else if (command == "2") {
			getManyImagesManyTimes(userName, sessionId, fileName, 10000);
		} else if (command == "3") {
			sendBadRequestManyTimes(userName, sessionId, 10000);
		} else {
			printf("Invalid command: %d\n", command.c_str());
		}
		
		printf("Done\n");

		
	} catch (XosException& e) {
		printf("Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("Caught unknown exception in main\n");
	}

	return 0;
	
}



