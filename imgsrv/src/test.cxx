extern "C" {
#include "xos.h"
#include "xos_log.h"
#include "xos_http.h"
}

#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"

std::string impersonHost = "biotest";
int impersonPort = 61000;

std::string imgSrvServer = "biotest";
int imgSrvPort = 6003;

/**
 * @struct user_info_struct
 * 
 */
 
 // http://biotest:6003/getImage?fileName=/data/penjitk/images/low_1/4c10p3_1_025.img&userName=penjitk&sessionId=F4771E5EFB02A7507B9FFB8B993F266D&sizeX=400&sizeY=400&zoom=1.0&gray=400&percentX=0.5&percentY=0.5
 
typedef struct user_info_struct user_info_t;
struct user_info_struct {

	/**
	 * @brief Login name
	 */
	std::string 	name;
	/**
	 * @brief session id
	 */
	std::string		sessionId;
	/**
	 * @brief The last time a client connects to the 
	 * authentications server with this session id.
	 */
	time_t 	lastValidation;
};


static void debugHttp(const HttpResponse* res, const std::string& title)
{
    if (!res)
        return;

    printf("********************\n");
    printf("START HTTP RESPONSE: %s\n", title.c_str());

    printf("%s %d %s\n", res->getVersion().c_str(),
                         res->getStatusCode(),
                         res->getStatusPhrase().c_str());

    // Results are in the response headers
    // Fill the member variables

    printf(res->getHeaderString().c_str());

    printf("\n%s\n", res->getBody().c_str());

    printf("END HTTP RESPONSE\n");
    printf("********************\n");
}

static bool validate_user(user_info_t& user,
						  const std::string& fileName,
						  std::string& reason)
{
	
	std::string url("/isFileReadable");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + user.name 
			+ "&impSessionID=" + user.sessionId;
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setHost(impersonHost);
    request->setPort(impersonPort);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    debugHttp(response, "In validate_user");
    
	if (response->getStatusCode() == 200) {
    
    	std::string str;
    	if (response->getHeader("isFileReadable", str)) {
    		if (XosStringUtil::equalsNoCase(str, "TRUE")) {
    			user.lastValidation = time(NULL);
    			return true;
    		}
    		reason = "File does not exist or permission denied.";
    		return false;
    	}
    	    
    } 
	
	reason = response->getStatusPhrase();
	
	return false;
}


static void readFile(user_info_t& user,
						  const std::string& fileName,
						  std::string& reason)
{
	
	std::string url("/readFile");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + user.name 
			+ "&impSessionID=" + user.sessionId;
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setHost(impersonHost);
    request->setPort(impersonPort);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    debugHttp(response, "In validate_user");
    
}

static void listDirectory(user_info_t& user,
						  const std::string& dir,
						  std::string& reason)
{
	
	std::string url("/listDirectory");
	url +=   "?impDirectory=" + dir 
			+ "&impUser=" + user.name 
			+ "&impSessionID=" + user.sessionId;
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setHost(impersonHost);
    request->setPort(impersonPort);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    debugHttp(response, "In listDirectory");
    
}

static void getImage1(user_info_t& user,
						  const std::string& filename,
						  std::string& reason)
{
	
	std::string url("/getImage");
	url +=   "?fileName=" + filename 
			+ "&userName=" + user.name 
			+ "&sessionId=" + user.sessionId
			+ "&sizeX=100&sizeY=100&zoom=1.0&gray=1.0&percentX=100.0&percentY=100.0";	
	
    HttpClientImp http;

//    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setHost(imgSrvServer);
    request->setPort(imgSrvPort);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    debugHttp(response, "In getImage");
    
    FILE* file = fopen("./image.jpg", "w");
    
    char buf[1000];
    int size = 0;
    while ((size = http.readResponseBody(buf, 1000)) > 0) {
    
    	fwrite(buf, sizeof(char), size, file);
    	
    }
    
    fclose(file);
    
}

static void getImage(user_info_t& user,
						  const std::string& filename,
						  std::string& reason)
{

	xos_socket_t socket;
    xos_socket_address_t    address;
    
	std::string url("/getImage");
	url +=   "?fileName=" + filename 
			+ "&userName=" + user.name 
			+ "&sessionId=" + user.sessionId
			+ "&sizeX=400&sizeY=400&zoom=1.0&gray=400&percentX=0.5&percentY=0.5";	

    // create an address structure pointing at the authentication server
    xos_socket_address_init( &address );
    xos_socket_address_set_ip_by_name( &address, imgSrvServer.c_str() );
    xos_socket_address_set_port( &address, imgSrvPort );

    // create the socket to connect to server
    if (xos_socket_create_client( &socket ) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestLine: xos_socket_create_client");

    // connect to the server
    if (xos_socket_make_connection( &socket, &address ) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestLine: xos_socket_make_connection");

    // create the request packet
    std::string line = std::string("GET ") + url + " HTTP/1.1" + CRLF;
	line += std::string("Host: ") + imgSrvServer + ":" + XosStringUtil::fromInt(imgSrvPort) + CRLF;
	line += std::string("Connection: close") + CRLF;
	line += std::string(CRLF);
	
	printf("request => %s\n", line.c_str());
	
	
    // write the first line
    if (xos_socket_write( &socket, line.c_str(), line.size()) != XOS_SUCCESS)
        throw XosException("Failed in sendRequestLine: xos_socket_write");

    // shutdown the writing side of the socket
    if ( SOCKET_SHUTDOWN(socket.clientDescriptor, SHUT_WR) != 0 )
        throw XosException("Failed in  SOCKET_SHUTDOWN");

	// Read response
    // read the HTTP result
    char buf[1000];
    int bufSize = 1000;    
	int num;
	FILE* in;
    // convert the file descriptor to a stream
    if ( (in=fdopen(socket.clientDescriptor, "r" )) == NULL ) {
        throw XosException("Failed in receiveResponseLine: fdopen\n");
    }
    
    printf("******************\n");
    while (!feof(in)) {


        buf[0] = '\0';

		num = fread(buf, sizeof(char), bufSize, in);
		
		if (num > 0) {		
			fwrite(buf, sizeof(char), num, stdout);
			fflush(stdout);
		}

    }
    
    printf("\n");
    printf("******************\n");
    
    xos_socket_destroy(&socket);
    fclose(in);

}

static void getImage3(user_info_t& user,
						  const std::string& filename,
						  std::string& reason)
{
	xos_http_t http;
	std::string url("/getImage");
	url +=   "?fileName=" + filename 
			+ "&userName=" + user.name 
			+ "&sessionId=" + user.sessionId
			+ "&sizeX=100&sizeY=100&zoom=1.0&gray=1.0&percentX=100.0&percentY=100.0";	
	
	/* initialize the http structure */
	xos_http_init( &http, 512, 20480 );

	/* start the http get request */
	xos_http_start_get( &http, imgSrvServer.c_str(), imgSrvPort,  url.c_str());
	
	/* write the http request header */
	xos_http_write_header( &http, "Connection", "close" );
	xos_http_write_header( &http, "Host", "biotest:6003" );
	xos_http_finish_header( &http );

	/* finish the http request and read the response */
	xos_http_finish_get( &http );

	printf("Response size = %d\n", http.responseSize ); 

	puts( http.responseBuffer );
	
}

int  main(int argc, char** argv) 
{
	try {

		if (argc != 4) {
			printf("Usage: test <userName> <sessionId> <fileName>\n");
			exit(0);
		}

		xos_log_init(stdout);

		// Create a new user
		user_info_t user;
		user.name = argv[1];
		user.sessionId = argv[2];
		user.lastValidation = 0;

		std::string fileName = argv[3];
		std::string reason;
	/*	
		bool ret = validate_user(user, fileName, reason);


		if (ret)
			printf("validate_user returns TRUE\n");
		else
			printf("validate_user returns FALSE: %s\n", reason.c_str());

	*/	
	//	readFile(user, fileName, reason);
	//	listDirectory(user, fileName, reason);
		getImage(user, fileName, reason);

		
	} catch (XosException& e) {
		printf("Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("Caught unknown exception in main\n");
	}

	return 0;
	
}



