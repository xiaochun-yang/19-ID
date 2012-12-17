extern "C" {
#include "xos.h"
}

#include "XosException.h"
#include "AuthClient.h"
#include "log_quick.h"


static void printUsage()
{
	printf("\n");
	printf("Usage: test host port createSession username password\n");
	printf("Usage: test host port endSession sessionId\n");
	printf("Usage: test host port validateSession sessionId username\n");
	printf("\n");
}

void test()
	throw (XosException)
{
	throw XosException("test exception");
}


void http_test();

/**********************************************************
 *
 * main
 *
 **********************************************************/
int main(int argc, char** argv)
{
    try {
    
//	printf("calling LOG_QUICK_OPEN\n"); fflush(stdout);
//	LOG_QUICK_OPEN;
//	printf("after calling LOG_QUICK_OPEN\n"); fflush(stdout);

	set_save_logger_error(false);

    if (argc < 4) {
    	printUsage();
    	exit(0);
    }

    
//    http_test();
    
    std::string host = argv[1];
    int port = XosStringUtil::toInt(argv[2], 8084);
    std::string command = argv[3];
    

	AuthClient client(host, port);
	client.setDebugHttp(true);
	
	if (command == "createSession") {
	
		if (argc != 6) {
			printUsage();
			exit(0);
		}
	
		std::string userName = argv[4];
		std::string password = argv[5];
		
		client.createSession(userName, password, false);
			
	
	} else if (command == "endSession") {
	
		if (argc != 5) {
			printUsage();
			exit(0);
		}
	
		std::string sessionId = argv[4];
		
		client.endSession(sessionId);
			
	
	} else if (command == "validateSession") {
	
		if (argc != 6) {
			printUsage();
            printf( "arc=%d\n", argc );
			exit(0);
		}
	
		std::string sessionId = argv[4];
		std::string username = argv[5];

		if (!client.validateSession(sessionId, username)) {
			printf("Invalid session: %s\n", sessionId.c_str());
			client.dump();
		}
		
	} else {
    	printUsage();
    	exit(0);
	}
	
	
	client.dump();

//	LOG_QUICK_CLOSE;


    } catch (XosException& e) {
        printf("Caught XosException: %s\n", e.getMessage().c_str()); fflush(stdout);
    } catch (std::exception& e) {
        printf("Caught std::exception: %s\n", e.what());  fflush(stdout);
    } catch (...) {
        printf("Caught unexpected exception\n");  fflush(stdout);
    }

    return 0;
}


