#include "xos.h"
#include "xos_http.h"
#include "XosException.h"
#include "TestGetFileStatus.h"

/**
 * 
 */
bool TestGetFileStatus::test() 
{
	printf("\n\n"); fflush(stdout);
	printf("****************************\n"); fflush(stdout);
	printf("TEST getFileFileStatus START\n"); fflush(stdout);

	try {
						

		std::string rootDir = "/usr/local/dcs/imperson_cpp";
		std::string fileName = rootDir + "/test/ImpTestCommon.h";
		std::string description = "";
		std::string url = "";
		
		// TEST 1: 200 OK
		description = "Check file status of a file that exists. Expect 200 OK.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test1", url, 200, description);

		// TEST 2: missing impUser
		description = "Check file status. impUser parameter is missing.";
		url =  "/getFileStatus?impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test2", url, 432, description);

		// TEST 3: empty string for impUser
		description = "Check file status. impUser parameter contains an empty string.";
		url =  "/getFileStatus?impUser=&impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test3", url, 551, description);

		// TEST 4: missing impSessionID
		description = "Check file status. impSessionID parameteris missing.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impFilePath=" + fileName;
		testBasic("test4", url, 431, description);

		// TEST 5: empty string for impSessionID
		description = "Check file status. impSessionID parameter contains an empty string.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=&impFilePath=" + fileName;
		testBasic("test5", url, 551, description);

		// TEST 6: missing impFilePath
		description = "Check file status. impFilePath is missing.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId;
		testBasic("test6", url, 437, description);
				
		// TEST 7:empty string for impFilePath
		description = "Check file status. impFilePath parameter contains an empty string.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=";
		testBasic("test7", url, 440, description);

		// TEST 8: missing impShowSymlinkStatus
		description = "Check file status. impShowSymlinkStatus is missing.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=" + fileName;
		testBasic("test8", url, 200, description);
				
		// TEST 9:empty string for impShowSymlinkStatus
		description = "Check file status. impShowSymlinkStatus parameter contains an empty string.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId 
					+ "&impFilePath=" + fileName + "&impShowSymlinkStatus=";
		testBasic("test9", url, 200, description);
		
		// TEST 10: file path does not start with /.
		description = "Check file status of a file that does not exist.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=junk_file";
		testBasic("test10", url, 440, description);

		// TEST 11: file does not exist.
		description = "Check file status of a file that does not exist.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=/junk_file";
		testBasic("test11", url, 558, description);

		// TEST 12: File path contains ~
		description = "Check file status of a file. File path begins with tilde.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=~blctl";
		testBasic("test12", url, 200, description);

		// TEST 13: File path contains ..
		description = "Check file status of a file. File path contains dot dot.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=/../junkfile";
		testBasic("test13", url, 440, description);

		// TEST 13: File path contains ./
		description = "Check file status of a file. File path contains dot slash.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=/./junkfile";
		testBasic("test13", url, 440, description);


		// TEST 14: File path ends with '.'.
		description = "Check file status of a file. File path ends with dot. ";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=/junkfile.";
		testBasic("test14", url, 440, description);

/*		// TEST 15: Dir is not readable by this user.
		std::string not_readable_dir = rootDir + "/not_readable_dir";
		// Create directory and set rwx for owner.
		mkdir(not_readable_dir.c_str(), 0400);
		// Set file mode in case dir already exist and mkdir fails.
		chmod(not_readable_dir.c_str(), 0400);
		description = "Check file status of a dir which is not readable.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=" + not_readable_dir;
		testBasic("test15", url, 558, description);
		chmod(not_readable_dir.c_str(), 0700);
		remove(not_readable_dir.c_str());

		// TEST16: 
		std::string ff = rootDir + "/not_readable_file";
		FILE* stream = fopen(ff.c_str(), "w");
		if (stream == NULL)
			throw new XosException("Cannot create file " + ff);
		fprintf(stream, "this file is only readable by blctl\n");
		fclose(stream);
		stream = NULL;
		chmod(ff.c_str(), 0400); // only execute/search by owner
		description = "Check file status file which is not readable.";
		url =  "/getFileStatus?impUser=" + mUserName + "&impSessionID=" + mSessionId + "&impFilePath=" + ff;
		testBasic("test16", url, 558, description);
		chmod(ff.c_str(), 0700);
		remove(ff.c_str());*/


		printf("---------------\n"); fflush(stdout);
		printf("Number of tests = %5d\n", getTestCount()); fflush(stdout);
		printf("Passed          = %5d\n", getPassCount()); fflush(stdout);
		printf("Failed          = %5d\n", getFailureCount()); fflush(stdout);
		printf("---------------\n"); fflush(stdout);
		printf("TEST getFileFileStatus DONE\n"); fflush(stdout);
		
	} catch (XosException& e) {
		printf("TEST getFileFileStatus FAILED Caught XosException in main: %s\n", e.getMessage().c_str());
	} catch (...) {
		printf("TEST getFileFileStatus FAILED Caught unknown exception in main\n");
	}
	
	return (getFailureCount() == 0);
}



