/**********************************************************************************
                        Copyright 2002
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.


                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
 of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
 Leland Stanford Junior University, nor their employees, makes any war-
 ranty, express or implied, or assumes any liability or responsibility
 for accuracy, completeness or usefulness of any information, apparatus,
 product or process disclosed, or represents that its use will not in-
 fringe privately-owned rights.  Mention of any product, its manufactur-
 er, or suppliers shall not, nor is it intended to, imply approval, dis-
 approval, or fitness for any particular use.  The U.S. and the Univer-
 sity at all times retain the right to use and disseminate the furnished
 items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.


                       Permission Notice

 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
 BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
 EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
 THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*********************************************************************************/

#include "DcsMessage.h"
#include "DcsMessageManager.h"
#include "ImpersonService.h"
#include "ImpersonSystem.h"
#include "log_quick.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientImp.h"
#include "FileAccessThread.h"

#define MAX_LINE_LENGTH 1000
#define BUF_SIZE 5000

std::string FileAccessThread::headerFixed = 
"# Information about the currently defined axes\n"
"_graph_axes.xLabel			\"Energy (eV)\"\n"
"_graph_axes.x2Label			\"\"\n"
"_graph_axes.yLabel			\"Counts\"\n"
"_graph_axes.y2Label			\"\"\n\n"

"# write information about the plot background\n"
"_graph_background.showGrid\n\n"	

"# data for trace scan\n"
"data_\n"
"_trace.name 	scan\n"
"_trace.xLabels	\"{Energy (eV)}\"\n"
"_trace.hide		0\n\n"

"loop_\n"
"_sub_trace.name\n"
"_sub_trace.yLabels\n"
"_sub_trace.color\n"
"_sub_trace.width\n"
"_sub_trace.symbol\n"
"_sub_trace.symbolSize\n"
"counts \"{Signal Counts} Counts\" darkgreen 1 circle 2\n\n"

"loop_\n"
"_sub_trace.x\n"
"_sub_trace.y1\n";


/*******************************************************************
 *
 *
 *
 *******************************************************************/
FileAccessThread::FileAccessThread(ImpersonService* parent, DcsMessage* pMsg,
									const ImpConfig& c)
	: OperationThread(parent, pMsg, c)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
FileAccessThread::~FileAccessThread()
{
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void FileAccessThread::run()
{
	exec();
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void FileAccessThread::exec()
{
	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();

	try {
					

		LOG_FINEST("in FileAccessThread::run\n"); fflush(stdout);

		if (strcmp(m_pMsg->GetOperationName(), OP_GET_LAST_FILE) == 0) {
			pReply = doGetLastFile();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_GET_NEXT_FILE_INDEX) == 0) {
			pReply = doGetNextFileIndex();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_COPY_FILE) == 0) {
			pReply = doCopyFile();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_WRITE_EXCITATION_SCAN_FILE) == 0) {
			pReply = doWriteExcitationScanFile();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_LIST_FILES) == 0) {
			pReply = doListFiles();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_APPEND_TEXT_FILE) == 0) {
			pReply = doAppendTextFile();
		} else if (strcmp(m_pMsg->GetOperationName(), OP_READ_TEXT_FILE) == 0) {
			pReply = doReadTextFile();
		} else {
			throw XosException("unknown operation");
		}
		
	} catch (XosException& e) {
		LOG_WARNING(e.getMessage().c_str());
		std::string tmp("error ");
		tmp += e.getMessage();
		pReply = manager.NewOperationCompletedMessage( m_pMsg, tmp.c_str());
	} catch (...) {
		LOG_WARNING("unknown exception in FileAccessThread::exec"); fflush(stdout);
		pReply = manager.NewOperationCompletedMessage( m_pMsg, "error unknown");
	}
		
	
	m_parent->SendoutDcsMessage( pReply );
	manager.DeleteDcsMessage(m_pMsg);
		
	m_pMsg = NULL;
		
}

/*******************************************************************
 *
 * getNextFileIndex <operationId> <user> <sessionId> <dir> <pattern>
 * For example,
 * getNextFileIndex 144 penjitk UYWKJSWQOW4564332WLWEUQ9759 /data/penjitk/dataset/test1 infl_1_*.img
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doGetNextFileIndex() 
	throw(XosException)
{

	// Get operation parameters
	// getLastFile <operationId> <user> <sessionId> <dir> <filter>
	// Operation arguments include everthing after operationHandler
	char param[8][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s", 
		param[0], param[1], param[2], param[3]) != 4)
		throw XosException("Wrong number of arguments");

	std::string user = param[0];
	std::string sessionId = param[1];
	std::string dir = param[2];
	std::string filter = param[3];

	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);
		
		
	
	size_t thePos = filter.find('*');
	if (thePos == std::string::npos)
		throw XosException("Missing * in file pattern");
		
	std::string prefix = filter.substr(0, thePos);
	std::string suffix = "";
	
	if (thePos < (filter.size()-1))
		suffix = filter.substr(thePos+1);

	HttpClientImp impClient;
	// Should we read the response ourselves?
	impClient.setAutoReadResponseBody(false);

	HttpRequest* impRequest = impClient.getRequest();

	std::string uri("");
	uri += std::string("/listDirectory?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impDirectory=" + dir
		   + "&impFileFilter=" + filter
		   + "&impFileType=file"	  // exclude subdirs
		   + "&impShowDetails=false"; // only want file names

	impRequest->setURI(uri);
	impRequest->setHost(m_config.getImpHost());
	impRequest->setPort(m_config.getImpPort());
	impRequest->setMethod(HTTP_GET);

	// Send the request and wait for a response
	HttpResponse* response = impClient.finishWriteRequest();

	if (response == NULL)
		throw XosException("invalid HTTP Response from imp server\n");

	if (response->getStatusCode() != 200) {
		throw XosException("Got error status code " 
						+ XosStringUtil::fromInt(response->getStatusCode())
						+ " "
						+ response->getStatusPhrase());
	}


	// We need to read the response body ourselves
	char buf[2000];
	int bufSize = 2000;
	std::string str("");
	while (impClient.readResponseBody(buf, bufSize) > 0) {
		str += buf;
	}
	
	std::vector<std::string> fileList;
	std::string lastFile("");		
	if (!XosStringUtil::tokenize(str, "\r\n", fileList) || (fileList.size() == 0)) {
		lastFile = "";
	}

	// Find the last file
	std::vector<std::string>::iterator i = fileList.begin();
	
	size_t nextNum = 0;
	size_t maxNum = 0;
	size_t num = 0;
	std::string file = *i;
	size_t pos = 0;
	// If directory contains no file of given file pattern,
	// the result contains only one line of text, which is "200 OK".
	if (file.find("200 OK") == std::string::npos) {
	
		for (; i != fileList.end(); ++i) {
		
			// File name starts with dot slash, e.g. "./readme.txt"
			file = *i;
			
			if (file.find("./") == 0)
				file = file.substr(2);
				
			pos = file.find(suffix);
			// Ignore invalid file name
			if (pos == std::string::npos)
				continue;
			num = XosStringUtil::toInt(file.substr(thePos, file.size()-pos-1), INT_MAX);
			
			// Skip file that has invalid number
			if (num == INT_MAX)
				continue;
				
			// Keep the highest number
			if (maxNum < num)
				maxNum = num;
		}
		
		nextNum = maxNum + 1;
				
	} else {
		// If the directory contains no file of the given pattern,
		// then the next index is 0.
		nextNum = 0;
	}
	

	std::string status = "normal " + XosStringUtil::fromInt(nextNum);

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, status.c_str());

	
	return pReply;
	
}

/*******************************************************************
 *
 * getLastFile <operationId> <user> <sessionId> <dir> <filter>
 * For example,
 * getLastFile 144 penjitk UYWKJSWQOW4564332WLWEUQ9759 /data/penjitk/dataset/test1 infl_1_*.img
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doGetLastFile() 
	throw(XosException)
{
		

	LOG_FINEST("in FileAccessThread::doGetLastFile\n"); fflush(stdout);


	// Get operation parameters
	// getLastFile <operationId> <user> <sessionId> <dir> <filter>
	// Operation arguments include everthing after operationHandler
	char param[8][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s", 
		param[0], param[1], param[2], param[3]) != 4)
		throw XosException("Invalid arguments for getLastFile operation");

	std::string user = param[0];
	std::string sessionId = param[1];
	std::string dir = param[2];
	std::string filter = param[3];

	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);

	HttpClientImp impClient;
	// Should we read the response ourselves?
	impClient.setAutoReadResponseBody(false);

	HttpRequest* impRequest = impClient.getRequest();

	std::string uri("");
	uri += std::string("/listDirectory?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impDirectory=" + dir
		   + "&impFileFilter=" + filter
		   + "&impFileType=file"	  // exclude subdirs
		   + "&impShowDetails=false"; // only want file names

	impRequest->setURI(uri);
	impRequest->setHost(m_config.getImpHost());
	impRequest->setPort(m_config.getImpPort());
	impRequest->setMethod(HTTP_GET);

	// Send the request and wait for a response
	HttpResponse* response = impClient.finishWriteRequest();

	if (response == NULL)
		throw XosException("invalid HTTP Response from imp server\n");

	if (response->getStatusCode() != 200) {
		throw XosException("Got error status code " 
						+ XosStringUtil::fromInt(response->getStatusCode())
						+ " "
						+ response->getStatusPhrase());
	}


	// We need to read the response body ourselves
	char buf[2000];
	int bufSize = 2000;
	std::string str("");
	while (impClient.readResponseBody(buf, bufSize) > 0) {
		str += buf;
	}
	
	std::vector<std::string> fileList;
	std::string lastFile("");		
	if (!XosStringUtil::tokenize(str, "\r\n", fileList) || (fileList.size() == 0)) {
		lastFile = "";
	}

	// Find the last file
	std::vector<std::string>::iterator i = fileList.begin();
	lastFile = *i;
	if (lastFile.find("200 OK") != std::string::npos) {
		lastFile = "Not found";
	} else {
	
		for (; i != fileList.end(); ++i) {
			if (*i > lastFile)
				lastFile = *i;
		}
	} 
	

	std::string status = "normal " + lastFile;

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, status.c_str());

	
	return pReply;
	
}


/*******************************************************************
 *
 * copyFile <operationId> <user1> <sessionId1> <file1> <user2> <sessionId2> <file2>
 * For example,
 * copyFile 144 penjitk UYWKJSWQOW4564332WLWEUQ975 /data/penjitk/image1.img joeuser DGHJEREWWPPOKLDR32843ILFRT /data/joeuser/test/test1.img
 * copyFile 144 penjitk UYWKJSWQOW4564332WLWEUQ975 /data/penjitk/image1.img penjitk UYWKJSWQOW4564332WLWEUQ975 /data/penjitk/test/test1.img
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doCopyFile() 
	throw(XosException)
{
		
	LOG_FINEST("in FileAccessThread::doCopyFile\n"); fflush(stdout);

	// Operation arguments include everthing after operationHandler
	char param[8][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s %s %s", 
		param[0], param[1], param[2], param[3],
		param[4], param[5]) != 6)
		throw XosException("Invalid arguments for copyFile operation");

	std::string fromUser = param[0];
	std::string fromSessionId = param[1];
	std::string fromFile = param[2];

	std::string toUser = param[3];
	std::string toSessionId = param[4];
	std::string toFile = param[5];
	
	// Strip off the prefix PRIVATE
	if (fromSessionId.find("PRIVATE") == 0)
		fromSessionId = fromSessionId.substr(7);

	if (toSessionId.find("PRIVATE") == 0)
		toSessionId = toSessionId.substr(7);
		
	// Use copyFile command if copying file 
	// for a single user
	// Otherwise, read file from one user 
	// and then write it for another user
	if (fromUser == toUser) {
	
		copyFile(fromUser, fromSessionId, fromFile, toFile);
	
	} else {

		copyFile(fromUser, fromSessionId, fromFile,
				 toUser, toSessionId, toFile);

	}


	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, "normal");

	
	return pReply;

}

/*******************************************************************
 *
 * writeExcitationScanFile <operationId> <user> <sessionId> <fullPathName> <percentDeadTime> <referenceCounts> <delta> {num0 num1 num2 num3 ... numN}

 * For example,
 * getLastFile 144 penjitk UYWKJSWQOW4564332WLWEUQ975 /data/penjitk/scanFile.bip {datapoints.....} 
 *******************************************************************/
DcsMessage* FileAccessThread::doWriteExcitationScanFile() 
	throw(XosException)
{
		

	LOG_FINEST("in FileAccessThread::doWriteExcitationScanFile\n"); fflush(stdout);

	std::string datapoints;
//	float percentDeadTime = 0.0;
//	int referenceCounts = 0;

	// Operation arguments include everthing after operationHandler
	const char* pArgs = m_pMsg->GetOperationArgument();

    //msgHeader and data are separated by '{'
	char* str = (char *) strrchr( pArgs, '{');
	if (str == NULL) {
		throw XosException("Missing datapoint list");
	}

    //parse header
    int headerLength = str - pArgs;
    std::string msgHeader( pArgs, headerLength );

    std::vector<std::string> headerField;
    if (!XosStringUtil::tokenize( msgHeader, " \t\r\n", headerField ) ||
    headerField.size( ) < 6) {
		throw XosException("Invalid args for writeExcitationScan operation");
    }
	std::string user         = headerField[0];
	std::string sessionId    = headerField[1];
	std::string fullPathName = headerField[2];
    std::string deadTime     = headerField[3];
    std::string refCount     = headerField[4];
    std::string strDelta     = headerField[5];
    std::string edge         = "unknown";
    std::string energy       = "-1";
    std::string scanTime     = "0";
    std::string beamline     = "unknown";
    double delta = XosStringUtil::toDouble( strDelta, -1.0 );
    if (delta < 0.0) {
		throw XosException("Invalid delta value: " + strDelta );
    }

    if (headerField.size( ) >= 10) {
        edge     = headerField[6];
        energy   = headerField[7];
        scanTime = headerField[8];
        beamline = headerField[9];
    }

    //generate headerDynamic
    std::string headerDynamic = "\n# Information about the graph title"
    "\n_graph_title.text \"Excitation Scan of " + edge + " Edge\"";

    headerDynamic += "\n_input.user " + user;
    headerDynamic += "\n_input.deadTime " + deadTime;
    headerDynamic += "\n_input.referenceCount " + refCount;
    headerDynamic += "\n_input.delta " + strDelta;
    headerDynamic += "\n_input.edge " + edge;
    headerDynamic += "\n_input.energy " + energy;
    headerDynamic += "\n_input.scanTime " + scanTime;
    headerDynamic += "\n_input.beamline " + beamline;
    headerDynamic += "\n";


	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);

	
	++str;

	datapoints = str;
	while (datapoints[datapoints.size()-1] == '}') {
		datapoints.erase(datapoints.size()-1);
	}

	std::string dataStr("");
	int row = 0;
	size_t start = 0;
	size_t size = datapoints.size();
	size_t it = start;
    //may add more checks here.
	for (; it < size; ++it) {
		if (datapoints[it] == ' ') {
			double x = delta*row + delta/2.0;
			dataStr += XosStringUtil::fromDouble(x) + " " 
					+ datapoints.substr(start, it-start) + "\n";
			++row;
			start = it+1;
		} 
	}
	
	// Last one
	dataStr += XosStringUtil::fromDouble(delta*row + delta/2.0) + " " 
				+ datapoints.substr(start) + "\n";

	
	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/writeFile?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impFilePath=" + fullPathName
		   + "&impFileMode=0740";
		   
	
	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);
	
	
	request->setContentType("text/plain");
	request->setContentLength(
        headerDynamic.size( ) + headerFixed.size() + dataStr.size()
    );
	

	client.writeRequestBody((char*)headerDynamic.c_str(),
        (int)headerDynamic.size());
	client.writeRequestBody((char*)headerFixed.c_str(), (int)headerFixed.size());
	client.writeRequestBody((char*)dataStr.c_str(), (int)dataStr.size());


	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();

	
	if (response->getStatusCode() != 200) {
		LOG_SEVERE2("AutochoochThread::doWriteExcitationScanFile: http error %d %s", 
				response->getStatusCode(),
				response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase());
	}


	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, "normal");

	
	return pReply;

}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void FileAccessThread::copyFile(const std::string& name, 
					const std::string& sid,
					const std::string& oldPath, 
					const std::string& newPath)
	throw (XosException)
{
	HttpClientImp client;
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri;
	uri += std::string("/copyFile?impUser=") + name
		   + "&impSessionID=" + sid
		   + "&impOldFilePath=" + oldPath
		   + "&impNewFilePath=" + newPath
		   + "&impFileMode=0740";
		   

	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_GET);
	
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_WARNING2("Failed to move file from %s to %s", oldPath.c_str(), newPath.c_str());
		throw XosException(std::string("Failed to move output file ") 
						+ response->getStatusPhrase());
	}
	
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void FileAccessThread::copyFile(const std::string& fromUser, 
					const std::string& fromSessionId,
					const std::string& fromFile, 
					const std::string& toUser, 
					const std::string& toSessionId, 
					const std::string& toFile)
	throw (XosException)
{

	HttpClientImp client1;
	// Should we read the response ourselves?
	client1.setAutoReadResponseBody(false);

	HttpRequest* request1 = client1.getRequest();

	std::string uri("");
	uri += std::string("/readFile?impUser=") + fromUser
		   + "&impSessionID=" + fromSessionId
		   + "&impFilePath=" + fromFile;

	request1->setURI(uri);
	request1->setHost(m_config.getImpHost());
	request1->setPort(m_config.getImpPort());
	request1->setMethod(HTTP_GET);

	// Send the request and wait for a response
	HttpResponse* response1 = client1.finishWriteRequest();

	if (response1 == NULL)
		throw XosException("invalid HTTP Response from imp server\n");

	if (response1->getStatusCode() != 200) {
		throw XosException("Got error status code " 
						+ XosStringUtil::fromInt(response1->getStatusCode())
						+ " "
						+ response1->getStatusPhrase());
	}



	HttpClientImp client2;
	// Should we read the response ourselves?
	client2.setAutoReadResponseBody(true);

	HttpRequest* request2 = client2.getRequest();

	uri = "";
	uri += std::string("/writeFile?impUser=") + toUser
		   + "&impSessionID=" + toSessionId
		   + "&impFilePath=" + toFile
		   + "&impFileMode=0740";

	request2->setURI(uri);
	request2->setHost(m_config.getImpHost());
	request2->setPort(m_config.getImpPort());
	request2->setMethod(HTTP_POST);

	request2->setContentType("text/plain");
	// Don't know the size of the entire content
	// so set transfer encoding to chunk so that
	// we don't have to set the Content-Length header.
	request2->setChunkedEncoding(true);

	// We need to read the response body ourselves
	char buf[2000];
	int bufSize = 2000;
	int numRead = 0;
	while ((numRead = client1.readResponseBody(buf, bufSize)) > 0) {
		// Print out what we have read.
		if (!client2.writeRequestBody(buf, numRead)) {
			throw XosException("failed to write http body to imp server");
		}
	}

	// Send the request and wait for a response
	HttpResponse* response2 = client2.finishWriteRequest();

	if (response2->getStatusCode() != 200) {
		LOG_SEVERE2("FileAccessThread::copyFile: http error %d %s", 
				response2->getStatusCode(),
				response2->getStatusPhrase().c_str());
		throw XosException(response2->getStatusPhrase());
	}


}


/*******************************************************************
 *
 * listFiles <operationId> <user> <sessionId> <dir> <filter>
 * For example,
 * listFiles 144 penjitk UYWKJSWQOW4564332WLWEUQ9759 /data/penjitk/dataset/test1 infl*.img
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doListFiles() 
	throw(XosException)
{


	// Get operation parameters
	// getLastFile <operationId> <user> <sessionId> <dir> <filter>
	// Operation arguments include everthing after operationHandler
	char param[8][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s", 
		param[0], param[1], param[2], param[3]) != 4)
		throw XosException("Invalid arguments for listFiles operation");

	std::string user = param[0];
	std::string sessionId = param[1];
	std::string dir = param[2];
	std::string filter = param[3];

	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);
		
		
	HttpClientImp impClient;
	// Should we read the response ourselves?
	impClient.setAutoReadResponseBody(false);

	HttpRequest* impRequest = impClient.getRequest();

	std::string uri("");
	uri += std::string("/listDirectory?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impDirectory=" + dir
		   + "&impFileFilter=" + filter
		   + "&impFileType=file"	  // exclude subdirs
		   + "&impShowDetails=false"; // only want file names

	impRequest->setURI(uri);
	impRequest->setHost(m_config.getImpHost());
	impRequest->setPort(m_config.getImpPort());
	impRequest->setMethod(HTTP_GET);

	// Send the request and wait for a response
	HttpResponse* response = impClient.finishWriteRequest();

	if (response == NULL)
		throw XosException("invalid HTTP Response from imp server\n");

	if (response->getStatusCode() != 200) {
		throw XosException("Got error status code " 
						+ XosStringUtil::fromInt(response->getStatusCode())
						+ " "
						+ response->getStatusPhrase());
	}


	// We need to read the response body ourselves
	char buf[2000];
	int bufSize = 2000;
	std::string str("");
	while (impClient.readResponseBody(buf, bufSize) > 0) {
		str += buf;
	}
	
	std::vector<std::string> fileList;
	std::string files("");		
	if (XosStringUtil::tokenize(str, "\r\n", fileList) && (fileList.size() > 0)) {

		// Find the last file
		std::vector<std::string>::iterator i = fileList.begin();
		
		std::string file = *i;

		// If directory contains no file of given file pattern,
		// the result contains only one line of text, which is "200 OK".
		if (file.find("200 OK") == std::string::npos) {

			for (; i != fileList.end(); ++i) {

				// File name starts with dot slash, e.g. "./readme.txt"
				file = *i;

				if (file.find("./") == 0)
					 files += " " + file.substr(2);
				else
					files += " " + file;
					
				printf("files = %s\n", files.c_str());

			}
		}
		
	}

	std::string status = "normal" + files;

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, status.c_str());

	
	return pReply;
	
}


/*******************************************************************
 *
 * doAppendTextFile
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doAppendTextFile()
	throw (XosException)
{

	// Get operation parameters
	// appendTextFile <operationId> <user> <sessionId> <file> <text>
	// Operation arguments include everthing after operationHandler
	char param[3][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s", 
		param[0], param[1], param[2]) != 3)
		throw XosException("Invalid arguments for appendTextFile operation");

	std::string user = param[0];
	std::string sessionId = param[1];
	std::string file = param[2];
	
	int offset = strlen(param[0]) + strlen(param[1]) + strlen(param[2]) + 3;
	const char* text = m_pMsg->GetOperationArgument() + offset;
	

	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);


	HttpClientImp client;
	// Should we read the response ourselves?
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri = "";
	uri += std::string("/writeFile?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impFilePath=" + file
		   + "&impWriteBinary=false&impAppend=true";
		   
	LOG_INFO1("uri = %s\n", uri.c_str());

	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_POST);

	request->setContentType("text/plain");
	// Don't know the size of the entire content
	// so set transfer encoding to chunk so that
	// we don't have to set the Content-Length header.
	request->setChunkedEncoding(true);

	if (!client.writeRequestBody(text, strlen(text))) {
		throw XosException("failed to write http body to imp server");
	}

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();

	if (response->getStatusCode() != 200) {
		LOG_SEVERE2("FileAccessThread::doAppendTextFile: http error %d %s", 
				response->getStatusCode(),
				response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase());
	}

	std::string status = "normal";

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	pReply = manager.NewOperationCompletedMessage( m_pMsg, status.c_str());

	
	return pReply;

}

/*******************************************************************
 *
 * doReadTextFile
 *
 *******************************************************************/
DcsMessage* FileAccessThread::doReadTextFile()
	throw (XosException)
{
	// Get operation parameters
	// readTextFile <operationId> <user> <sessionId> <file>
	// Operation arguments include everthing after operationHandler
	char param[3][250];
	if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s", 
		param[0], param[1], param[2]) != 3)
		throw XosException("Invalid arguments for readTextFile operation");

	std::string user = param[0];
	std::string sessionId = param[1];
	std::string file = param[2];
		

	// Strip off the prefix PRIVATE
	if (sessionId.find("PRIVATE") == 0)
		sessionId = sessionId.substr(7);


	HttpClientImp client;
	// Should we read the response ourselves?
	client.setAutoReadResponseBody(false);

	HttpRequest* request = client.getRequest();

	std::string uri("");
	uri += std::string("/readFile?impUser=") + user
		   + "&impSessionID=" + sessionId
		   + "&impFilePath=" + file;

	request->setURI(uri);
	request->setHost(m_config.getImpHost());
	request->setPort(m_config.getImpPort());
	request->setMethod(HTTP_GET);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();

	if (response == NULL)
		throw XosException("invalid HTTP Response from imp server\n");

	if (response->getStatusCode() != 200) {
		throw XosException("Got error status code " 
						+ XosStringUtil::fromInt(response->getStatusCode())
						+ " "
						+ response->getStatusPhrase());
	}

	DcsMessage* pReply = NULL;
	DcsMessageManager& manager = DcsMessageManager::GetObject();

	// We need to read the response body ourselves
	char buf[BUF_SIZE];
	int bufSize = BUF_SIZE;
	int numRead = 0;
	while ((numRead = client.readResponseBody(buf, bufSize)) > 0) {
	
		// Chop buffer into lines
		// Send each line as dcs update message
		std::vector<std::string> ret;
		if (!XosStringUtil::tokenize(buf, "\r\n", ret)) 
			throw XosException("failed to parse file " + file);

		for (size_t i = 0; i < ret.size(); ++i) {
			std::string line = ret[i];
			if (line.size() > MAX_LINE_LENGTH)
				throw XosException("line too long");
			// Send dcs update message
			pReply = manager.NewOperationUpdateMessage(m_pMsg, line.c_str());
			m_parent->SendoutDcsMessage( pReply );
		}
			
	}

	std::string status = "normal";
	pReply = manager.NewOperationCompletedMessage(m_pMsg, status.c_str());

	
	return pReply;

}




