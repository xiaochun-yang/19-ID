#include "ImpersonSystem.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"

int main(int argc, char** argv) 
{

	try {
	
		if (argc < 2) {
			printf("Usage: test <sessionID> ?chunck?\n");
			exit(0);
		}

		HttpClientImp impClient;
		impClient.setAutoReadResponseBody(true);

		HttpRequest* impRequest = impClient.getRequest();

		std::string uri("");
		uri += std::string("/writeFile?impUser=penjitk")
			   + std::string("&impSessionID=")
			   + std::string(argv[1])
			   + std::string("&impFilePath=/home/penjitk/code/20030910/impdhs/snap/output.jpg")
			   + std::string("&impFileMode=0740");

				
		impRequest->setURI(uri);
		impRequest->setHost("boompc.slac.stanford.edu");
		impRequest->setPort(61001);
		impRequest->setMethod(HTTP_POST);
		impRequest->setContentType(WWW_JPEG);
//		impRequest->setContentType("text/plain");

		bool chunkEncoding = false;
		if (argc == 3)
			chunkEncoding = true; 
		
		// We need to read the response body ourselves
		char buf[1000];
		int bufSize = 1000;
		int numRead = 0;
		std::string body;
		
		std::string file = "/home/penjitk/code/20030910/impdhs/snap/org.jpg";
		
		FILE* is = NULL;
		if (chunkEncoding) {
	
			is = fopen(file.c_str(), "r");
			impRequest->setChunkedEncoding(true);
			while ((numRead = fread(buf, sizeof(char), bufSize, is)) > 0) {
			
				printf("calling writeRequestBody size = %d\n", numRead);
			
				if (!impClient.writeRequestBody((const char*)buf, numRead)) {
					printf("ERROR: failed to write http body to imp server\n");
					exit(0);
				}
				
				
			}
			
			fclose(is);

			
		} else {
		
			size_t total = 0;
			is = fopen(file.c_str(), "r");
			while ((numRead = fread(buf, sizeof(char), bufSize, is)) > 0) {
				total += numRead;
			}
			fclose(is);
			
			
			impRequest->setChunkedEncoding(false);
			impRequest->setContentLength(total);
			
			is = fopen(file.c_str(), "r");
			size_t numWritten = 0;
			while ((numRead = fread(buf, sizeof(char), bufSize, is)) > 0) {
				if (!impClient.writeRequestBody((const char*)buf, numRead)) {
					printf("ERROR: failed to write http body to imp server: written = %d, total = %d\n",
							numWritten, total);
					exit(0);
				}
				numWritten += numRead;
			}
			fclose(is);
			
			if (numWritten != total) {
				printf("ERROR: incomplete file written = %d, total = %d\n",
						numWritten, total);
				exit(0);
			}

		}
		

		// Send the request and wait for a response
		HttpResponse* impResponse = impClient.finishWriteRequest();
	
		if (impResponse->getStatusCode() != 200) {
			printf("SnapThread::exec: http error %d %s\n", 
					impResponse->getStatusCode(),
					impResponse->getStatusPhrase().c_str());
			exit(0);
		}
		
		printf("OK\n"); fflush(stdout);


	} catch (XosException& e) {
		printf(e.getMessage().c_str()); fflush(stdout);
	} catch (...) {
		printf("unknown error\n"); fflush(stdout);
	}
	
	return 0;


}


