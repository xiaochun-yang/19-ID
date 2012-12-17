#include "xos.h"
#include "xos_http.h"
#include "XosException.h"
#include "TestGetFilePermissions.h"


/**
 * 
 */
bool TestGetFilePermissions::test() 
{
	printf("\n\n"); fflush(stdout);
	printf("*****************************\n"); fflush(stdout);
	printf("TEST getFilePermissions START\n"); fflush(stdout);

	try {
						

		std::string rootDir = "/usr/local/dcs/imperson_cpp";
		std::string fileName = rootDir + "/test/ImpTestCommon.h";
		std::string description = "";
		std::string url = "";
		
		// TEST 1: 200 OK
		description = "Check file permissions of a file that does exists. Expect 200 OK.";
		url =  "/getFilePermissions?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test1", url, 200, description);

		// TEST 2: missing impUser
		description = "Check file permissions. impUser parameter is missing.";
		url =  "/getFilePermissions?impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test2", url, 432, description);

		// TEST 3: empty string for impUser
		description = "Check file permissions. impUser parameter contains an empty string.";
		url =  "/getFilePermissions?impUser=&impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test3", url, 551, description);

		// TEST 4: missing impSessionID
		description = "Check file permissions. impSessionID parameteris missing.";
		url =  "/getFilePermissions?impUser=" + mUserName + "&impFilePath=" + fileName;
		testBasic("test4", url, 431, description);

		// TEST 5: empty string for impSessionID
		description = "Check file permissions. impSessionID parameter contains an empty string.";
		url =  "/getFilePermissions?impUser=" + mUserName + "&impSessionID=&impFilePath=" + fileName;
		testBasic("test5", url, 551, description);

		// TEST 6: missing impFilePath
		description = "Check file permissions. impFilePath is missing.";
		url =  "/getFilePermissions?impUser=" + mUserName + "&impSessionID=" + mSessionId;
		testBasic("test6", url, 437, description);
				
		// TEST 7:empty string for impFilePath
		description = "Check file permissions. impFilePath parameter contains an empty string.";
		url =  "/getFilePermissions?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=";
		testBasic("test7", url, 440, description);

		
		printf("---------------\n"); fflush(stdout);
		printf("Number of tests = %5d\n", getTestCount()); fflush(stdout);
		printf("Passed          = %5d\n", getPassCount()); fflush(stdout);
		printf("Failed          = %5d\n", getFailureCount()); fflush(stdout);
		printf("---------------\n"); fflush(stdout);
		printf("TEST getFilePermissions  DONE\n"); fflush(stdout);
		
	} catch (XosException& e) {
		printf("TEST getFilePermissions FAILED Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("TEST getFilePermissions FAILED Caught unknown exception in main\n");
	}
	
	return (getFailureCount() == 0);
}
