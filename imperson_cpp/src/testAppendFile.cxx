#include "xos.h"
#include "xos_http.h"
#include "log_quick.h"

#ifdef IRIX
#include "sys/types.h"
#include "signal.h"
#endif
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include <map>

class TestFailed : public XosException
{
public:
	TestFailed(const std::string& s)
		: XosException(s) {}
};


typedef struct run_info_struct run_info_t;

struct run_info_struct {

	/**
	 * @brief host name
	 */
	std::string host;
	 
	/**
	 * @brief port number
	 */
	int port;

	/**
	 * @brief Login name
	 */
	std::string 	name;
	/**
	 * @brief session id
	 */
	std::string		sessionId;
	
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

/**
 * appendFile
 */
static void appendFile(const std::string& host,
							  int port,
							  const std::string& user,
							  const std::string& sessionId, 
							  const std::string& fileName,
							  int index)
{
	
	char body[500];
	double val1 = index/1.676;
	double val2 = index/93.42;
	double val3 = index/2.321;
	double val4 = index/7.422;
	sprintf(body, "%d %7.4f %7.4f %7.4f %7.4f\n", index, val1, val2, val3, val4);
	std::string url("/writeFile");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + user 
			+ "&impSessionID=" + sessionId
			+ "&impAppend=true";
	
	 printf("appendFile url =%s\n", url.c_str());
	
    HttpClientImp http;
	 http.setReadTimeout(15000); // 15 seconds read timeout

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setMethod("POST");
    request->setHost(host);
    request->setPort(port);
    request->setURI(url);
    request->setContentLength(strlen(body));
    request->setContentType("text/plain");
    
    if (!http.writeRequestBody(body, strlen(body))) {
    	printf("appendFile FAILED: error in writeRequestBody\n");
    	throw TestFailed("appendFile");
    }
	
HttpResponse* response = null;
	try {

    response = http.finishWriteRequest();
   } catch (XosException& e) {
		printf("in test appendFile: finishWriteRequest failed: %s\n", e.getMessage().c_str());
	   throw e;
	}
    
    if (response->getStatusCode() == 200) {
		  printf(body); fflush(stdout);
	    return;
    }
    printf("appendFile FAILED\n"); fflush(stdout);
    
    debugHttp(response, "appendFile");
    
    throw TestFailed("appendFile");
    
}

/**
 * Main test routine
 */
int main(int argc, char** argv) 
{
	try {

		if (argc != 6) {
			printf("Usage: test <host> <port> <userName> <sessionId> <output file>\n");
			exit(0);
		}

		LOG_QUICK_OPEN_STDOUT;

		char buffer[500];
		getcwd(buffer, 500);

		std::string host = argv[1];
		int port = atoi(argv[2]);
		std::string user = argv[3];
		std::string sessionId = argv[4];
		std::string fileName = std::string(buffer) + "/" + argv[5];

		printf("output file = %s\n", fileName.c_str());
						
		int count = 0;
		bool done = false;
		while (!done) {
		
			++count;
			appendFile(host, port, user, sessionId, fileName, count);
			xos_thread_sleep(1000);

		}
								
		LOG_QUICK_CLOSE;

	} catch (TestFailed& e) {
		printf("IMPERSON TEST FAILED in %s\n", e.getMessage().c_str());
	} catch (XosException& e) {
		printf("IMPERSON TEST FAILED Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("IMPERSON TEST FAILED Caught unknown exception in main\n");
	}
	
	return 0;
}



