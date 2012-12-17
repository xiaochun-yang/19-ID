#include "xos.h"
#include "xos_http.h"
#include "XosTimeCheck.h"
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"

// Impersonation host and port
static std::string g_impHost = "blcpu4.slac.stanford.edu";
static int g_impPort = 61001;

static std::string g_inputFile = "/tmp/test.img";

int main(int argc, char** argv)
{
	try {
	
	if (argc != 4) {
		printf("Usage: read_image <userName> <sessionID> <fileName>\n");
		exit(0);
	}
	
	std::string userName = argv[1];
	std::string sessionId = argv[2];
	std::string fileName = argv[3];	
	
	XosTimeCheck* check = new XosTimeCheck("read_image");

	HttpClientImp client2;
	// Should we read the response ourselves?
	client2.setAutoReadResponseBody(true);

	HttpRequest* request2 = client2.getRequest();

	std::string uri = "";
	uri += std::string("/writeFile?impUser=") + userName
		   + "&impSessionID=" + sessionId
		   + "&impFilePath=" + fileName
		   + "&impFileMode=0740";

	request2->setURI(uri);
	request2->setHost(g_impHost);
	request2->setPort(g_impPort);
	request2->setMethod(HTTP_POST);

	request2->setContentType("text/plain");
	// Don't know the size of the entire content
	// so set transfer encoding to chunk so that
	// we don't have to set the Content-Length header.
	request2->setChunkedEncoding(true);
	
	FILE* input = fopen(g_inputFile.c_str(), "r");
	
	if (input == NULL)
		throw XosException("Cannot open file " + g_inputFile);

	// We need to read the response body ourselves
	char buf[10000];
	int bufSize = 10000;
	size_t numRead = 0;
	size_t sentTotal = 0;
	while ((numRead = fread(buf, sizeof(char), bufSize, input)) > 0) {
		// Send what we have read
		if (!client2.writeRequestBody(buf, numRead)) {
			fclose(input);
			throw XosException("failed to write http body to imp server");
		}
		sentTotal += numRead;
	}

	// Send the request and wait for a response
	HttpResponse* response2 = client2.finishWriteRequest();

	if (response2->getStatusCode() != 200) {
		printf("FileAccessThread::copyFile: http error %d %s\n", 
				response2->getStatusCode(),
				response2->getStatusPhrase().c_str());
		fclose(input);
		throw XosException(response2->getStatusPhrase());
	}
	
	printf("Sent %d bytes for file %s \n", sentTotal, fileName.c_str());
	
	delete check;
	return 0;
	
	} catch (XosException& e) {
		printf("Caught XosException: %s\n", e.getMessage().c_str());
	} catch (std::exception& e) {
		printf("Caught std::exception: %s\n", e.what());
	} catch (...) {
		printf("Caught unknown exception\n");
	}
	
	return 1;

	
}
