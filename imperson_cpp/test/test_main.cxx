#include "xos.h"
#include "xos_http.h"
#include "log_quick.h"
#include "TestGetFilePermissions.h"
#include "TestGetFileStatus.h"

/**
 * Main test routine
 */
int main(int argc, char** argv) 
{
		if (argc < 5) {
			printf("Usage: test <host> <port> <userName> <sessionId> <debug level>\n");
			exit(0);
		}

		LOG_QUICK_OPEN_STDOUT;
		set_save_logger_error(false);
		
		// Create a new user
		int i = 1;

		// Create a new user
		std::string impersonHost = argv[i]; ++i;
		int impersonPort = atoi(argv[i]); ++i;
		std::string userName = argv[i]; ++i;
		std::string sessionId = argv[i]; ++i;
		int outputLevel = 0;
		if (argc == 6) {
			outputLevel = atoi(argv[i]); ++i;
		}

		TestGetFilePermissions test1(impersonHost, impersonPort, outputLevel, userName, sessionId);
		test1.test();

		TestGetFileStatus test2(impersonHost, impersonPort, outputLevel, userName, sessionId);
		test2.test();

		LOG_QUICK_CLOSE;

		return 0;
}

