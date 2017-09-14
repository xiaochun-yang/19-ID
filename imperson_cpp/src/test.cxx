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
 * testReadFile
 */
static void testReadFile(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/readFile");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    printf("testReadFile PASSED\n"); fflush(stdout);
	    return;
    }
        
    printf("testReadFile FAILED: fileName = %s\n", fileName.c_str()); fflush(stdout);
    
    debugHttp(response, "testReadFile");
    
    throw TestFailed("testReadFile");
    
}

/**
 * testIsFileReadable
 */
static void testIsFileReadable(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/isFileReadable");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    printf("testIsFileReadable PASSED\n"); fflush(stdout);
	    return;
    }
        
    printf("testIsFileReadable FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testIsFileReadable");
    
    throw TestFailed("testIsFileReadable");
    
}

/**
 * testWriteFile
 */
static void testWriteFile(run_info_t& run, const std::string& fileName)
{
	
    const char* body = "This is the request body\n";
	std::string url("/writeFile");
	url +=   "?impFilePath=" + fileName 
			+ "&impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impFileMode=0777";
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setMethod("POST");
    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);
    request->setContentLength(strlen(body));
    request->setContentType("text/plain");

    if (!http.writeRequestBody(body, strlen(body))) {
    	printf("testWriteFile FAILED: error in writeRequestBody\n");
    	throw TestFailed("testWriteFile");
    }

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    printf("testWriteFile PASSED\n"); fflush(stdout);
	    return;
    }
        
    printf("testWriteFile FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testWriteFile");
    
    throw TestFailed("testWriteFile");
    
}

/**
 * testRunExecutable
 */
static void testRunExecutable(run_info_t& run, const std::string& dir)
{
	
    std::string url("/runExecutable");
    url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId
		+ "&impExecutable=/usr/bin/find";
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setMethod("GET");
    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);
    
    request->setHeader("impEnv1", "HOME=/home/" + run.name);

    request->setHeader("impArg1", dir);
    request->setHeader("impArg2", "-name");
    request->setHeader("impArg3", "test");
    
    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
    	    std::string body = response->getBody();
	    if (body.find(dir + "/test") != std::string::npos) {
	    	printf("testRunExecutable PASSED\n"); fflush(stdout);
	    	return;
	    }
    }
        
    printf("testRunExecutable FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testRunExecutable");
    
    throw TestFailed("testrunExecutable");
    
}

/**
 * testRunScript
 */
static void testRunScript(run_info_t& run, const std::string& dir)
{
	
    std::string url("/runScript");
    url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId;
	
	
    HttpClientImp http;

    http.setAutoReadResponseBody(true);

    HttpRequest* request = http.getRequest();

    request->setMethod("GET");
    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);
    
    request->setHeader("impEnv1", "HOME=/home/" + run.name);
    request->setHeader("impShell", "/bin/tcsh");
    request->setHeader("impCommandLine", "/usr/bin/find " + dir + " -name test");
    
    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
    	    std::string body = response->getBody();
	    if (body.find(dir + "/test") != std::string::npos) {
	    	printf("testRunScript PASSED\n"); fflush(stdout);
	    	return;
	    }
    }
        
    printf("testRunScript FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testRunScript");
    
    throw TestFailed("testRunScript");
    
}

/**
 * testListDirectory
 */
static void testListDirectory(run_info_t& run, const std::string& dir)
{
	
	std::string url("/listDirectory");
	url +=   "?impDirectory=" + dir 
			+ "&impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    std::string body = response->getBody();
	    if (body.find("./test") != std::string::npos) {
	    	printf("testListDirectory PASSED\n"); fflush(stdout);
	    	return;
    	    }
    }
        
    printf("testListDirectory FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testListDirectory");
    
    throw TestFailed("testListDirectory");
    
}


/**
 * testGetFilePermissions
 */
static void testGetFilePermissions(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/getFilePermissions");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impFilePath=" + fileName;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    std::string body = response->getBody();
//	    printf("%s\n", response->getBody().c_str());
	    if (body.find("impFileExists=true") != std::string::npos) {
		printf("testGetFilePermissions PASSED\n"); fflush(stdout);
		return;
	    }
    }
        
    printf("testGetFilePermission FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetFilePermissions");
    
    throw TestFailed("testGetFilePermissions");
    
}

/**
 * testGetFileStatus
 */
static void testGetFileStatus(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/getFileStatus");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impFilePath=" + fileName;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	    std::string body = response->getBody();
//	    printf("%s\n", response->getBody().c_str());
	    if (body.find("impFilePath=" + fileName) != std::string::npos) {
		printf("testGetFileStatus PASSED\n"); fflush(stdout);
		return;
	    }
    }
        
    printf("testGetFileStatus FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetFileStatus");
    
    throw TestFailed("testGetFileStatus");
    
}

/**
 * testCreateDirectory
 */
static void testCreateDirectory(run_info_t& run, const std::string& dir)
{
	
	std::string url("/createDirectory");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impDirectory=" + dir
			+ "&impFileMode=0744";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testCreateDirectory PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testCreateDirectory FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testCreateDirectory");
    
    throw TestFailed("testCreateDirectory");
    
}

/**
 * testDeleteDirectory
 */
static void testDeleteDirectory(run_info_t& run, const std::string& dir)
{
	
	std::string url("/deleteDirectory");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impDirectory=" + dir
			+ "&impDeleteChildren=true";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testDeleteDirectory PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testDeleteDirectory FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testDeleteDirectory");
    
    throw TestFailed("testDeleteDirectory");
    
}

/**
 * testCopyFile
 */
static void testCopyFile(run_info_t& run, const std::string& from, const std::string to)
{
	
	std::string url("/copyFile");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impOldFilePath=" + from
			+ "&impNewFilePath=" + to
			+ "&impFileMode=0755";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testCopyFile PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testCopyFile FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testCopyFile");
    
    throw TestFailed("testCopyFile");
    
}

/**
 * testRenameFile
 */
static void testRenameFile(run_info_t& run, const std::string& from, const std::string to)
{
	
	std::string url("/renameFile");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impOldFilePath=" + from
			+ "&impNewFilePath=" + to;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testRenameFile PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testRenameFile FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testRenameFile");
    
    throw TestFailed("testRenameFile");
    
}

/**
 * testDeleteFile
 */
static void testDeleteFile(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/deleteFile");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impFilePath=" + fileName;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testDeleteFile PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testDeleteFile FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testDeleteFile");
    
    throw TestFailed("testDeleteFile");
    
}

/**
 * testCopyDirectory
 */
static void testCopyDirectory(run_info_t& run, const std::string& from, const std::string to)
{
	
	std::string url("/copyDirectory");
	url +=   "?impUser=" + run.name 
			+ "&impSessionID=" + run.sessionId
			+ "&impOldDirectory=" + from
			+ "&impNewDirectory=" + to
			+ "&impMaxDepth=2"
			+ "&impFollowSymlik=false";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	printf("testCopyDirectory PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testCopyDirectory FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testCopyDirectory");
    
    throw TestFailed("testCopyDirectory");
    
}

/**
 * testGetVersion
 */
static void testGetVersion(run_info_t& run)
{
	
	std::string url("/getVersion");
	url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId;
	
printf("yangx url = %s \n", url.c_str());
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	std::string body = response->getBody();
	printf("testGetVersion PASSED: version = %s\n", body.c_str()); fflush(stdout);
	return;
    }
        
    printf("testGetVersion FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetVersion");
    
    throw TestFailed("testGetVersion");
    
}

/**
 * createChildProcess
 */
static pid_t createChildProcess()
{
    // fork the process
    pid_t child_pid;
    if ((child_pid = fork()) == -1) {
        return -1;
    }
    
    if (child_pid != 0) {
	// We are in parent process
	return child_pid;
    } else {
    	// We are in child process
	xos_thread_sleep(10*60*1000); // sleep for 10 minutes
	exit(0);
    }

	return 0;
}

/**
 * testGetProcessStatus
 */
static void testGetProcessStatus(run_info_t& run)
{
	
    // Fork a child process and make the child sleep
    // until we kill it or it exits itself. 
    // Only parent process will return from this call.
    pid_t child_pid = createChildProcess();
        
    if (child_pid < 0)
	    throw TestFailed("testGetProcessStatus: failed to fork");
	
    std::string child_pid_str = XosStringUtil::fromInt(child_pid);
    std::string url("/getProcessStatus");
    url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId
		+ "&impProcessId=" + child_pid_str;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    // Kill the child
    kill(child_pid, SIGKILL);
    
    if (response->getStatusCode() == 200) {
	std::string body = response->getBody();
	std::vector<std::string> ret;
	if (!XosStringUtil::tokenize(body, " \n\r\t", ret))
		throw TestFailed("testGetProcessStatus: cannot tokenize process status string");
	std::vector<std::string>::iterator it = ret.begin();
	std::string found_pid = "";
	bool found = false;
	for (; it != ret.end(); ++it) {
		if (found) {
			found_pid = *it;
			break;
		}
		if (*it == "COMMAND")
			found = true;
	}
	if (found && (found_pid == child_pid_str)) {
		printf("testGetProcessStatus PASSED: pid = %s\n", found_pid.c_str()); fflush(stdout);
		return;
	}
    }
        
    printf("testGetProcessStatus FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetProcessStatus");
    
    throw TestFailed("testGetProcessStatus");
    
}

/**
 * testKillProcess
 */
static void testKillProcess(run_info_t& run)
{
	
    // Fork a child process and make the child sleep
    // until we kill it or it exits itself. 
    // Only parent process will return from this call.
    pid_t child_pid = createChildProcess();
        
    if (child_pid < 0)
	    throw TestFailed("testKillProcess: failed to fork");
	
    std::string child_pid_str = XosStringUtil::fromInt(child_pid);
    std::string url("/killProcess");
    url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId
		+ "&impProcessId=" + child_pid_str;
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	std::string body = response->getBody();
	printf("testKillProcess PASSED: %s\n", body.c_str()); fflush(stdout);
	return;
    }
        
    // Kill the child manually if we couldn't kill it 
    // via the impersonation server
    kill(child_pid, SIGKILL);

    printf("testKillProcess FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testKillProcess");
    
    throw TestFailed("testKillProcess");
    
}

/**
 * testGetImageHeader
 */
static void testGetImageHeader(run_info_t& run, const std::string& fileName)
{
	
	std::string url("/getImageHeader");
	url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId
		+ "&impFilePath=" + fileName
		+ "&impSizeX=400&impSizeY=400&impPercentX=0.5&impPercentY=0.5&impGray=400&impZoom=1.0";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
	std::string body = response->getBody();
//	printf("%s\n", response->getBody().c_str());
	printf("testGetImageHeader PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testGetImageHeader FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetImageHeader");
    
    throw TestFailed("testGetImageHeader");
    
}

/**
 * testGetImage
 */
static void testGetImage(run_info_t& run, 
			const std::string& fileName, 
			const std::string& out_jpeg,
			const std::string& org_jpeg)
{
	
	std::string url("/getImage");
	url +=   "?impUser=" + run.name 
		+ "&impSessionID=" + run.sessionId
		+ "&impFilePath=" + fileName
		+ "&impSizeX=400&impSizeY=400&impPercentX=0.5&impPercentY=0.5&impGray=400&impZoom=1.0";
	
	
    HttpClientImp http;
    http.setAutoReadResponseBody(false);
    HttpRequest* request = http.getRequest();

    request->setHost(run.host);
    request->setPort(run.port);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    if (response->getStatusCode() == 200) {
    	int numRead = 0;
    	int numWritten = 0;
	int totRead = 0;
	int totWritten = 0;
	char buf[5000];
	FILE* stream = fopen(out_jpeg.c_str(), "wb");
	if (stream == NULL)
		throw TestFailed("testGetImage: failed to create output file: " + out_jpeg);
	while ((numRead=http.readResponseBody(buf, 5000)) > 0) {
        	// Write the buffer into the file
        	if ((numWritten = fwrite(buf, 1, numRead, stream)) != numRead) {
           		// close file for writing
           		fclose(stream);
            		// delete the file
            		remove(out_jpeg.c_str());
            		throw TestFailed("testGetImage failed to write jpeg to file " + out_jpeg);
        	}

        	totRead += numRead;
        	totWritten += numWritten;
	}
	fclose(stream);
	
    	// File incomplete
   	if (totWritten != totRead) {
        	throw TestFailed("testGetImage: incomplete jpeg written to file " + out_jpeg);
    	}
	
	// read original jpeg generated for the image
	stream = fopen(org_jpeg.c_str(), "r");
	if (stream == NULL)
		throw TestFailed("testGetImage: failed to open jpeg file " + org_jpeg);
	
	totRead = 0;
	numRead = 0;
	while ((numRead = fread(buf, sizeof(char), 5000, stream)) > 0) {
		totRead += numRead;
	}
	fclose(stream);
	
	// Compare jpeg size to the original jpeg
   	if (totWritten != totRead) {
        	throw TestFailed("testGetImage: jpeg size from " + out_jpeg + " differs from org " + org_jpeg);
    	}
	

    	printf("testGetImage PASSED\n"); fflush(stdout);
	return;
    }
        
    printf("testGetImage FAILED\n"); fflush(stdout);
    
    debugHttp(response, "testGetImage");
    
    throw TestFailed("testGetImage");
    
}

/**
 * Main test routine
 */
int main(int argc, char** argv) 
{
	try {

		if (argc != 6) {
			printf("Usage: test <host> <port> <userName> <sessionId> <test image>\n");
			exit(0);
		}

		LOG_QUICK_OPEN_STDOUT;
		set_save_logger_error(false);
		
		printf("IMPERSON TEST START\n"); fflush(stdout);

		// Create a new user
		int i = 1;

		// Create a new user
		run_info_t run;
		run.host = argv[i]; ++i;
		run.port = atoi(argv[i]); ++i;
		run.name = argv[i]; ++i;
		run.sessionId = argv[i]; ++i;
		
		std::string is_test_image = argv[i]; ++i;
	printf("yangx 1111\n");	
		char buffer[500];
		getcwd(buffer, 500);
		
printf("yangx 1222\n");
		testGetVersion(run);
printf("yangx 1333\n");
		std::string rootDir = std::string(buffer);
		printf("rootDir = %s\n", rootDir.c_str());
		std::string fileName = rootDir + "/test/test1.txt";
		testReadFile(run, fileName);
		testIsFileReadable(run, fileName);
		
printf("yangx 14444\n");
		testWriteFile(run, rootDir + "/test/out1.txt");
		
		testRunExecutable(run, rootDir);
		testRunScript(run, rootDir);
		
		testListDirectory(run, rootDir);
		
		testGetFilePermissions(run, rootDir + "/test/test1.txt");
		testGetFileStatus(run, rootDir + "/test/test1.txt");
		testCreateDirectory(run, rootDir + "/test/test2");
		testDeleteDirectory(run, rootDir + "/test/test2");
		testCopyFile(run, rootDir + "/test/test1.txt", rootDir + "/test/out2.txt");
		testRenameFile(run, rootDir + "/test/out2.txt", rootDir + "/test/out3.txt");
		testDeleteFile(run, rootDir + "/test/out3.txt");
		testCopyDirectory(run, rootDir + "/test", rootDir + "/test/test2");
		testDeleteDirectory(run,  rootDir + "/test/test2");
		
		char thisHost[50];
	   strcpy(thisHost, getenv("HOST"));
		if (strcmp(thisHost, run.host.c_str()) == 0) {
			testGetProcessStatus(run);
			testKillProcess(run);
	   }
		
		if (is_test_image == "true") {
			testGetImageHeader(run, rootDir + "/test/test1.img");
			testGetImage(run, rootDir + "/test/test1.img", rootDir + "/test/out1.jpeg", rootDir + "/test/test1.jpeg");
		}
		
		printf("IMPERSON TEST DONE\n"); fflush(stdout);
		
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



