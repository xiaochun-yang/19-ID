#include "xos.h"
#include "xos_http.h"
#include "log_quick.h"
#include "XosException.h"
#include "HttpClientImp.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpConst.h"
#include "ImpTestCommon.h"

/**
 * 
 */
int ImpTestCommon::sendRequest(const std::string& url, std::string& phrase)
{
		
    HttpClientImp http;
    http.setAutoReadResponseBody(true);
    HttpRequest* request = http.getRequest();

    request->setHost(mImpersonHost);
    request->setPort(mImpersonPort);
    request->setURI(url);

    HttpResponse* response = http.finishWriteRequest();
    
    int code = response->getStatusCode();
	 phrase = response->getStatusPhrase();
     
	return code;      
}

/**
 */
bool ImpTestCommon::testBasic(const std::string& testName, 
						const std::string& url, 
						int expectedCode, 
						const std::string& description)
{
	bool pass = false;

	printf("---------------\n"); fflush(stdout);
	if (mOutputLevel > 1) {
		printf("%s: %s\n", testName.c_str(), description.c_str()); fflush(stdout);
	}
	try {

		std::string phrase = "";
		int code = sendRequest(url, phrase);
		if (code == expectedCode) {
			pass = true;
			if (mOutputLevel > 0) {
				printf("%s passed: got expected code %d %s\n", testName.c_str(), code, phrase.c_str()); fflush(stdout);
			} else {
				printf("%s passed\n", testName.c_str()); fflush(stdout);
			}
		} else {
			printf("%s failed. Expected %d but got %d %s\n", testName.c_str(), expectedCode, code, phrase.c_str()); fflush(stdout);
		}

	} catch (XosException& e) {
		printf("%s failed: XosException %s\n", testName.c_str(), e.getMessage().c_str()); fflush(stdout);
	} catch (...) {
		printf("%s failed unknown exception\n", testName.c_str()); fflush(stdout);
	}

	++mTestCount;
	if (pass)
		++mPassCount;

	return pass;
}

