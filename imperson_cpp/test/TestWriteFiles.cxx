#include "xos.h"
#include "xos_socket.h"
#include "XosStringUtil.h"
#include "XosTimeCheck.h"

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

//	char* fileBuf = new char[fileBufSize];

	strcpy(line, "");
	strcpy(sockBuf, "");

	// Read first line
	printf("Reading first line\n"); fflush(stdout);
	if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
		printf("ERROR: xos_socket_read_line failed\n"); fflush(stdout);
		return 0;
	}
	printf("First line ==> %s\n", line);

	printf("Reading header\n"); fflush(stdout);
	bool doneReadHeader = false;
	while (!doneReadHeader) {
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			printf("ERROR: xos_socket_read_line failed\n"); fflush(stdout);
			return 0;
		}
		printf("Got header ==> %s\n", line); fflush(stdout);
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
		std::string fileName = XosStringUtil::trim(std::string(line));
		printf("File ==> %s\n", fileName.c_str()); fflush(stdout);

		// Second line is file size
		if (xos_socket_read_line(socket, line, lineSize, &numRead) != XOS_SUCCESS) {
			hasMoreFiles = false;
			break;
		}
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
				printf("Done reading file %s\n", fileName.c_str()); fflush(stdout);
				break;
			}
			chunkSize = fileSize - totRead;
			if (chunkSize > sockBufSize)
				chunkSize = sockBufSize;
		}

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
	printf("Total time = %10.2f seconds\n", dt);

	// Close server socket
	if (xos_socket_destroy(&serverSocket) != XOS_SUCCESS)
		printf("xos_socket_destroy failed"); fflush(stdout);

}

int main(int argc, char** argv) 
{
//	return testWriteFilesOnly(argc, argv);
	return testReadDataFromSocketOnly(argc, argv);
}
