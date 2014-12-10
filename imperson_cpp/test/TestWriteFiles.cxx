#include "xos.h"
#include "xos_socket.h"
#include "XosStringUtil.h"
#include "XosTimeCheck.h"
#include "HttpServerHandler.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpServer.h"
#include "InetdServer.h"
#include "ImpFileAccess.h"

// Check how long it takes to write pilatus files to file server.
// Can write 1000 files (6241531 bytes for each file, 1) in 18.2 seconds to data dir on smbdev1, which is about 54 files per seconds.
// Can write 1000 files (3120765 bytes for each file, 1/2) in 15.1 seconds to data dir on smbdev1, which is about 66 files per seconds.
// Can write 1000 files (2080510 bytes for each file, 1/3) in 10.48 seconds to data dir on smbdev1, which is about 95 files per seconds.
// Can write 1000 files (1560382 bytes for each file, 1/4) in 7.9 seconds to data dir on smbdev1, which is about 126 files per seconds.
int testWriteFilesOnly(int argc, char** argv) 
{
	if (argc != 5) {
		printf("Usage: TestWriteFiles <src file> <src file size> <dest dir> <how many>\n");
		return 0;
	}

	int maxFileSize = 7000000;
	int maxNumFiles = 9999;
	std::string srcFile = argv[1];
	int srcFileSize = XosStringUtil::toInt(argv[2], 0);
	std::string destDir = argv[3];
	int numFiles = XosStringUtil::toInt(argv[4], 0);
	
	if (srcFileSize > maxFileSize) {
		printf("ERROR: src file size (%d) exceeds max file size (%d)\n", srcFileSize, maxFileSize); fflush(stdout);
		return 0;
	}

	if (numFiles > maxNumFiles) {
		printf("ERROR: num files to write (%d) exceeds max num files (%d)\n", numFiles, maxNumFiles); fflush(stdout);
	}

	// Read pilatus file
	char* srcFileBuf = new char[srcFileSize];
	FILE* in = fopen(srcFile.c_str(), "r");
	if (in == NULL) {
		printf("Cannot open input file %s\n", srcFile.c_str()); fflush(stdout);
		return 0; 
	}
	size_t numRead=fread(srcFileBuf, 1, srcFileSize, in);
	if (numRead != srcFileSize) {
		printf("ERROR: read file failed\n"); fflush(stdout);
		return 0;
	}
	fclose(in);

	printf("Started writing files to dir %s %d times\n", destDir.c_str(), numFiles); fflush(stdout);
	time_t start = time(NULL);

	// Write file to destDir N times.
	size_t maxChunkSize = 1024;
	size_t chunkSize = 1024;
	size_t numWritten = 0;
	char* ptr;
	std::string rootFileName = "pilatus_";
	std::string destFile;
	size_t destFileSize = srcFileSize;
	for (int i = 1; i <= numFiles; ++i) {
		// Create file name
		destFile = destDir + "/" + rootFileName;
		if (i < 10)
			destFile += "000";
		else if (i < 100)
			destFile += "00";
		else if (i < 1000)
			destFile += "0";

		destFile += XosStringUtil::fromInt(i) + ".cbf";

		// Write file
		FILE* out = fopen(destFile.c_str(), "w");
		if (out == NULL) {
			printf("ERROR: cannot open file %s\n", destFile.c_str()); fflush(stdout);
			return 0;
		}
//		printf("Started writing file %s\n", destFile.c_str()); fflush(stdout);
		numWritten = 0;
		ptr = srcFileBuf;
		while (numWritten < destFileSize) {
			chunkSize = destFileSize - numWritten;
			if (chunkSize > maxChunkSize)
				chunkSize = maxChunkSize;
			fwrite(ptr, 1, chunkSize, out);
			numWritten += chunkSize;
			ptr += chunkSize;
		}
		fclose(out);
//		printf("Finished writing file %s size %d\n", destFile.c_str(), numWritten); fflush(stdout);
	}

	// Print out the time it took to write N files.
	time_t finish = time(NULL);
	double dt = difftime(finish, start);
	printf("dt = %10.2f\n", dt);

	delete srcFileBuf;
}

// Test how long it takes to read N files from socket using imp daemon 'writeFiles' protocol.
int testReadDataFromSocketOnly(int argc, char** argv)
{
	if (argc != 4) {
		printf("Usage: testReadDataFromSocketOnly <port> <sock chunk size> <write file>\n"); fflush(stdout);
		return 0;
	}

	int port = XosStringUtil::toInt(std::string(argv[1]), 0);
	int sockBufSize = XosStringUtil::toInt(std::string(argv[2]), 1024);
	int writeFile = XosStringUtil::toInt(std::string(argv[3]), 0);

	printf("port = %d, sock buf size = %d, write file = %d\n", port, sockBufSize, writeFile); 
	fflush(stdout);

	// Init socket library
	xos_socket_t serverSocket;
	if (xos_socket_library_startup() != XOS_SUCCESS) {
		printf("ERROR: xos_socket_library_startup failed"); fflush(stdout);
	}
	
	// Create server socket
	if (xos_socket_create_server(&serverSocket, (xos_socket_port_t)port) != XOS_SUCCESS) {
		printf("ERROR: xos_socket_create_server failed"); fflush(stdout);
	}

	// Listen on port
	if (xos_socket_start_listening(&serverSocket) != XOS_SUCCESS)
		printf("ERROR: xos_socket_start_listening failed"); fflush(stdout);

	printf("START 1\n"); fflush(stdout);

	// Accept in coming conenction.
	xos_socket_t* socket;
	if ( (socket = (xos_socket_t *)malloc(sizeof(xos_socket_t))) == NULL) {
		printf("ERROR: malloc failed"); fflush(stdout);
		return 0;
	}
	if (xos_socket_accept_connection(&serverSocket, socket) != XOS_SUCCESS) {
		printf("ERROR: xos_socket_accept_connection failed"); fflush(stdout);
		free(socket);
	}
	printf("START 2\n"); fflush(stdout);

	time_t start = time(NULL);

	int lineSize = 1024;
	char* line = new char[lineSize];
	char* sockBuf = new char[sockBufSize];
	int numRead = 0;
	int totRead = 0;
	bool sentHeader = false;
	long totReceived = 0;

//	char* fileBuf = new char[fileBufSize];

	strcpy(line, "");
	strcpy(sockBuf, "");

	// Read first line
	printf("Reading first line\n"); fflush(stdout);
	if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
		printf("ERROR: xos_socket_read_line failed\n"); fflush(stdout);
		return 0;
	}
	totReceived += strlen(line);
	printf("First line ==> %s\n", line);

	printf("Reading header\n"); fflush(stdout);
	bool doneReadHeader = false;
	while (!doneReadHeader) {
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			printf("ERROR: xos_socket_read_line failed\n"); fflush(stdout);
			return 0;
		}
		printf("Got header ==> %s\n", line); fflush(stdout);
		totReceived += strlen(line);
		if (strlen(line) == 0) {
			doneReadHeader = true;
			break;
		}
//		printf("header ==> %s\n", header.c_str()); fflush(stdout);
	} // end while !doneReadHeader
	printf("Done reading header\n"); fflush(stdout);

	// Read http body
	bool hasMoreFiles = true;
	int chunkSize;
	while (hasMoreFiles) {

		// First line is file path
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string fileName = XosStringUtil::trim(std::string(line));
		printf("File ==> %s\n", fileName.c_str()); fflush(stdout);

		// Second line is file size
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string tmp = XosStringUtil::trim(std::string(line));
		int fileSize = XosStringUtil::toInt(tmp, 0);
		printf("Size ==> %d\n", fileSize); fflush(stdout);

		FILE* out = NULL;
		if (writeFile == 1) {
			out = fopen(fileName.c_str(), "w");
			if (out == NULL)
				writeFile = 0;
		}
	
		// Read file content
		totRead = 0;
		chunkSize = sockBufSize < fileSize ? sockBufSize : fileSize;
		while (xos_socket_read(socket, sockBuf, chunkSize) == XOS_SUCCESS) {
			totRead += chunkSize;
			if (writeFile == 1) {
				fwrite(sockBuf, sizeof(char), chunkSize, out);			
			}
			if (totRead >= fileSize) {
				printf("Done reading file %s, totReceived = %ld\n", fileName.c_str(), totReceived); fflush(stdout);
				break;
			}
			chunkSize = fileSize - totRead;
			if (chunkSize > sockBufSize)
				chunkSize = sockBufSize;
		}
		totReceived += totRead;

		// write to dest dir
		if (writeFile == 1) {
			fclose(out);
			out = NULL;
		}

		// Read end of line char
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			hasMoreFiles = false;
			break;
		}
		totReceived += 1;

		// Write in response body that we have done this file
		// If response header has not been sent, then send it first.
		if (!sentHeader) {
			std::string response;
			response = "HTTP/1.1 200 OK\n\n";
			if (xos_socket_write(socket, response.c_str(), response.size()) != XOS_SUCCESS) {
				printf("ERROR: xos_socket_write failed\n"); fflush(stdout);
				break;
			}
			sentHeader = true;
		}

		std::string body = std::string("OK ") + fileName + std::string("\n");
		if (xos_socket_write(socket, body.c_str(), body.size()) != XOS_SUCCESS) {
			printf("ERROR: xos_socket_write failed\n"); fflush(stdout);
			break;
		}

	} // loop over files in http body

	delete[] line;
	delete[] sockBuf;

	xos_socket_destroy(socket);
	free(socket);

	time_t finish = time(NULL);

	double dt = difftime(finish, start);
	printf("Total time = %10.2f seconds, received = %ld\n", dt, totReceived);

	// Close server socket
	if (xos_socket_destroy(&serverSocket) != XOS_SUCCESS)
		printf("xos_socket_destroy failed"); fflush(stdout);

}

// To be run as a daemon
int testReadDataFromStdin(int argc, char** argv)
{
	int port = 61002;
	int sockBufSize = 65536;
	int writeFile = 0;
	
	FILE* log = fopen("/data/bluser/pilatus_test.log", "a");
	if (log == NULL) {
		printf("ERROR: failed to open log file\n"); fflush(stdout);
		return 0;
	}
	time_t start = time(NULL);

	int lineSize = 1024;
	char* line = new char[lineSize];
	char* sockBuf = new char[sockBufSize];
	int numRead = 0;
	int totRead = 0;
	bool sentHeader = false;
	long totReceived = 0;

	strcpy(line, "");
	strcpy(sockBuf, "");

	// Read first line
	fprintf(log, "Reading first line\n"); fflush(log);
	if (fgets(line, lineSize, stdin) == NULL) {
		fprintf(log, "ERROR: read first line failed\n"); fflush(log);
		return 0;
	}
	totReceived += strlen(line);
	fprintf(log, "First line ==> %s\n", line); fflush(log);

	fprintf(log, "Reading header\n"); fflush(log);
	bool doneReadHeader = false;
	std::string header;
	while (!doneReadHeader) {
		if (fgets(line, lineSize, stdin) == NULL) {
			fprintf(log, "ERROR: xos_socket_read_line failed\n"); fflush(log);
			return 0;
		}
		fprintf(log, "Got header ==> %s\n", line); fflush(log);
		totReceived += strlen(line);
		if (strlen(line) == 0) {
			doneReadHeader = true;
			break;
		}
		header = XosStringUtil::trim(std::string(line));
		if (header.size() == 0) {
			doneReadHeader = true;
			break;
		}
		fprintf(log, "header ==> %s\n", header.c_str()); fflush(log);
	} // end while !doneReadHeader
	fprintf(log, "Done reading header\n"); fflush(log);

	// Read http body
	bool hasMoreFiles = true;
	int chunkSize;
	while (hasMoreFiles) {

		// First line is file path
		if (fgets(line, lineSize, stdin) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string fileName = XosStringUtil::trim(std::string(line));
		fprintf(log, "File ==> %s\n", fileName.c_str()); fflush(log);

		// Second line is file size
		if (fgets(line, lineSize, stdin) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string tmp = XosStringUtil::trim(std::string(line));
		int fileSize = XosStringUtil::toInt(tmp, 0);
		fprintf(log, "Size ==> %d\n", fileSize); fflush(log);

		FILE* out = NULL;
		if (writeFile == 1) {
			out = fopen(fileName.c_str(), "w");
			if (out == NULL)
				writeFile = 0;
		}
	
		// Read file content
		totRead = 0;
		chunkSize = sockBufSize < fileSize ? sockBufSize : fileSize;
		while (fread(sockBuf, sizeof(char), chunkSize, stdin) == chunkSize) {
			totRead += chunkSize;
			if (writeFile == 1) {
				fwrite(sockBuf, sizeof(char), chunkSize, out);			
			}
			if (totRead >= fileSize) {
				fprintf(log, "Done reading file %s, totReceived = %ld\n", fileName.c_str(), totReceived); fflush(log);
				break;
			}
			chunkSize = fileSize - totRead;
			if (chunkSize > sockBufSize)
				chunkSize = sockBufSize;
		}
		totReceived += totRead;

		// write to dest dir
		if (writeFile == 1) {
			fclose(out);
			out = NULL;
		}

		// Read end of line char
		if (fgets(line, lineSize, stdin) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += 1;

		// Write in response body that we have done this file
		// If response header has not been sent, then send it first.
		if (!sentHeader) {
			std::string response;
			response = "HTTP/1.1 200 OK\n\n";
			if (fwrite(response.c_str(), sizeof(char), response.size(), stdout) != response.size()) {
				fprintf(log, "ERROR: write header failed\n"); fflush(log);
				break;
			}
			fflush(stdout);
			sentHeader = true;
		}

		std::string body = std::string("OK ") + fileName + std::string("\n");
		if (fwrite(body.c_str(), sizeof(char), body.size(), stdout) != body.size()) {
			fprintf(log, "ERROR: write body failed\n"); fflush(log);
			break;
		}
		fflush(stdout);

	} // loop over files in http body

	delete[] line;
	delete[] sockBuf;

	time_t finish = time(NULL);

	double dt = difftime(finish, start);
	fprintf(log, "Total time = %10.2f seconds, received = %ld\n", dt, totReceived); fflush(log);
	fclose(log);
}

int testReadDataFromStdinMyFgets(int argc, char** argv)
{
	int port = 61002;
	int sockBufSize = 65536;
	int writeFile = 0;
	
	FILE* log = fopen("/data/bluser/pilatus_test.log", "a");
	if (log == NULL) {
		printf("ERROR: failed to open log file\n"); fflush(stdout);
		return 0;
	}
	time_t start = time(NULL);

	int lineSize = 1024;
	char* line = new char[lineSize];
	char* sockBuf = new char[sockBufSize];
	int numRead = 0;
	int totRead = 0;
	bool sentHeader = false;
	long totReceived = 0;

	strcpy(line, "");
	strcpy(sockBuf, "");

	// Read first line
	fprintf(log, "Reading first line\n"); fflush(log);
	if (my_fgets(line, lineSize, fileno(stdin)) == NULL) {
		fprintf(log, "ERROR: read first line failed\n"); fflush(log);
		return 0;
	}
	totReceived += strlen(line);
	fprintf(log, "First line ==> %s\n", line); fflush(log);

	fprintf(log, "Reading header\n"); fflush(log);
	bool doneReadHeader = false;
	std::string header;
	while (!doneReadHeader) {
		if (my_fgets(line, lineSize, fileno(stdin)) == NULL) {
			fprintf(log, "ERROR: xos_socket_read_line failed\n"); fflush(log);
			return 0;
		}
		fprintf(log, "Got header ==> %s\n", line); fflush(log);
		totReceived += strlen(line);
		if (strlen(line) == 0) {
			doneReadHeader = true;
			break;
		}
		header = XosStringUtil::trim(std::string(line));
		if (header.size() == 0) {
			doneReadHeader = true;
			break;
		}
		fprintf(log, "header ==> %s\n", header.c_str()); fflush(log);
	} // end while !doneReadHeader
	fprintf(log, "Done reading header\n"); fflush(log);

	// Read http body
	bool hasMoreFiles = true;
	int chunkSize;
	while (hasMoreFiles) {

		// First line is file path
		if (my_fgets(line, lineSize, fileno(stdin)) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string fileName = XosStringUtil::trim(std::string(line));
		fprintf(log, "File ==> %s\n", fileName.c_str()); fflush(log);

		// Second line is file size
		if (my_fgets(line, lineSize, fileno(stdin)) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += strlen(line);
		std::string tmp = XosStringUtil::trim(std::string(line));
		int fileSize = XosStringUtil::toInt(tmp, 0);
		fprintf(log, "Size ==> %d\n", fileSize); fflush(log);

		FILE* out = NULL;
		if (writeFile == 1) {
			out = fopen(fileName.c_str(), "w");
			if (out == NULL)
				writeFile = 0;
		}
	
		// Read file content
		totRead = 0;
		chunkSize = sockBufSize < fileSize ? sockBufSize : fileSize;
		int numRead = 0;
		while ((numRead=read(fileno(stdin), sockBuf, chunkSize)) > 0) {
			totRead += numRead;
			if (writeFile == 1) {
				fwrite(sockBuf, sizeof(char), numRead, out);			
			}
			if (totRead >= fileSize) {
				fprintf(log, "Done reading file %s, totReceived = %ld\n", fileName.c_str(), totReceived); fflush(log);
				break;
			}
			chunkSize = fileSize - totRead;
			if (chunkSize > sockBufSize)
				chunkSize = sockBufSize;
		}
		totReceived += totRead;

		// write to dest dir
		if (writeFile == 1) {
			fclose(out);
			out = NULL;
		}

		// Read end of line char
		if (my_fgets(line, lineSize, fileno(stdin)) == NULL) {
			hasMoreFiles = false;
			break;
		}
		totReceived += 1;

		// Write in response body that we have done this file
		// If response header has not been sent, then send it first.
		if (!sentHeader) {
			std::string response;
			response = "HTTP/1.1 200 OK\n\n";
			if (fwrite(response.c_str(), sizeof(char), response.size(), stdout) != response.size()) {
				fprintf(log, "ERROR: write header failed\n"); fflush(log);
				break;
			}
			fflush(stdout);
			sentHeader = true;
		}

		std::string body = std::string("OK ") + fileName + std::string("\n");
		if (fwrite(body.c_str(), sizeof(char), body.size(), stdout) != body.size()) {
			fprintf(log, "ERROR: write body failed\n"); fflush(log);
			break;
		}
		fflush(stdout);

	} // loop over files in http body

	delete[] line;
	delete[] sockBuf;

	time_t finish = time(NULL);

	double dt = difftime(finish, start);
	fprintf(log, "Total time = %10.2f seconds, received = %ld\n", dt, totReceived); fflush(log);
	fclose(log);
}

class MyHttServerHandler : public HttpServerHandler 
{
public:
	MyHttServerHandler();
	virtual ~MyHttServerHandler();
	virtual std::string getName() const {
		return "myHttpServer";
	}
	virtual bool isMethodAllowed(const std::string& m) const {
		if ((m == "POST") || (m == "GET"))
			return true;
		return false;
	}
	virtual void doGet(HttpServer* stream) throw (XosException);
	virtual void doPost(HttpServer* stream) throw (XosException) {
		doGet(stream);		
	}
private:
	FILE* log;
};

MyHttServerHandler::MyHttServerHandler() {
	log = fopen("/data/bluser/pilatus_test.log", "a");
	if (log == NULL) {
		printf("ERROR: failed to open log file\n"); fflush(stdout);
		exit(0);
	}
}

MyHttServerHandler::~MyHttServerHandler() {
	if (log != NULL) {
		fclose(log);
		log = NULL;
	}
}

void MyHttServerHandler::doGet(HttpServer* stream) throw (XosException) 
{
	if (stream == NULL) {
		fprintf(log, "ERROR: doGet with NULL stream\n"); fflush(log);
		throw XosException(500, "null stream");
	}

	HttpRequest* request = stream->getRequest();
	HttpResponse* response = stream->getResponse();

	if (request == NULL) {
		fprintf(log, "doGet with NULL request\n"); fflush(log);
		throw XosException(500, "null request");
	}
	if (response == NULL) {
		fprintf(log, "doGet with NULL response\n"); fflush(log);
		throw XosException(500, "null response");
	}

	response->setContentType("text/plain");

	mode_t fileMode;
	bool fileNeedBackup = false;
	bool fileBackuped = false;
	bool impAppend = false;
	bool impWriteBinary = false;
	
	bool writeFile = false;
	bool prepareDestinationFile = false;
	bool isChmod = false;
	
	std::string tmp = "";	
	if (request->getParamOrHeader("impWriteBinary", tmp)) {
		if ((tmp == "true") || (tmp == "true"))
			impWriteBinary = true;
		else
			impWriteBinary = false;
	}
    	
	std::string writeMode = "w";
	if (impAppend)
		writeMode = "a+";
	
	if (impWriteBinary)
		writeMode += "b";
	else
		writeMode += "t";

	int bufSize = 65536;
	char* buf = new char[bufSize]; // 64K

	// Loop until we have no more files to read from request body
	bool hasMore = true;
	int numRead = 0;
	int totRead = 0;
	int totWritten = 0;
	int numWritten = 0;
	std::string body;
	std::string warning;
	FILE* file = NULL;
	while (hasMore) {
		hasMore = stream->nextFile();
		if (!hasMore)
			break;

		std::string impFilePath = stream->getCurFilePath();
		long fileSize = stream->getCurFileSize();
		fprintf(log, "cur filepath = %s size = %d\n", impFilePath.c_str(), fileSize); fflush(stdout);
		
		if (writeFile) {
			if (prepareDestinationFile)
				ImpFileAccess::prepareDestinationFile(
        						impFilePath,
        						fileMode,
        						impAppend,
       		 					fileNeedBackup,
        						fileBackuped,
        						request);
		
			if ((file = fopen(impFilePath.c_str(), writeMode.c_str())) == NULL) {
				fprintf(log, "fopen failed for %s\n", impFilePath.c_str());
				throw XosException(500, "writeFile failed");
			}
		}
    
		fprintf(log, "Started reading file %s, writeFile = %d, prepare = %d, chmod = %d\n", 
				impFilePath.c_str(), writeFile, prepareDestinationFile, isChmod);

		// Read until we have all of the bytes
		numRead = 0;
		totRead = 0;
		totWritten = 0;
		numWritten = 0;
		while ((numRead = stream->readCurFileContent(buf, bufSize)) > 0) {
			if (writeFile) {
			if ((numWritten = fwrite(buf, 1, numRead, file)) != numRead) {
				fclose(file);
				remove(impFilePath.c_str());
				fprintf(log, "ERROR:fwrite failed for %s\n", impFilePath.c_str());
				throw XosException(500, "fwrite failed");
			}
			}       		
			totRead += numRead;
			totWritten += numWritten;
    		}

		fprintf(log, "Finished reading file %s fot %ld, writeFile = %d, prepare = %d, chmod = %d\n", 
			impFilePath.c_str(), totRead, writeFile, prepareDestinationFile, isChmod);
		
		if (writeFile) {
			if (file != NULL) {
				fclose(file);
				file = NULL;
			}
		}
	
		if (totRead != fileSize) {
			sprintf(buf, "Expected file size %ld but got %ld", fileSize, totRead);
			remove(impFilePath.c_str());
			throw XosException(500, buf);
		}

		if (writeFile) {
			if (totWritten < totRead) {
				sprintf(buf, "got (%ld) but written (%ld)", totRead, totWritten);
				remove(impFilePath.c_str());
				throw XosException(500, buf);
			}
		
			if (isChmod) {
				if (chmod( impFilePath.c_str(), fileMode ) != 0 ) {
					fprintf(log, "ERROR: chmod failed for %s\n", impFilePath.c_str());
					throw XosException(500, "chmod failed");
				}
			}
		}
		
		
//		warning = "";
//		if (fileNeedBackup) {
//        		ImpFileAccess::writeBackupWarning(response, warning, impFilePath, fileBackuped);
//			body = XosStringUtil::trim(warning) + "\n";
//		}


    		body = "OK " + impFilePath + "\n";  
   		stream->writeResponseBody((char*)body.c_str(), (int)body.size());
    
	} // end while stream->nextFile()
	
	delete[] buf;

	fprintf(log, "Finished writing all files, writeFile = %d, prepare = %d, chmod = %d\n", 
		writeFile, prepareDestinationFile, isChmod); fflush(log);
	stream->finishWriteResponse();
}

int testReadDataFromInetdServer(int argc, char** argv)
{
	int port = 61002;
	int sockBufSize = 65536;
	int writeFile = 0;
	
	time_t start = time(NULL);

	MyHttServerHandler* handler = new MyHttServerHandler();
	InetdServer* conn = new InetdServer(handler);
	conn->start();

	delete conn;
	delete handler;
	return 0;
}



int main(int argc, char** argv) 
{
	return testWriteFilesOnly(argc, argv);
//	return testReadDataFromSocketOnly(argc, argv);
//	return testReadDataFromStdin(argc, argv);
//	return testReadDataFromStdinMyFgets(argc, argv);
//	return testReadDataFromInetdServer(argc, argv);
}
