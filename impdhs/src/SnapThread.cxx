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
#include "SnapThread.h"


/*******************************************************************
 *
 *
 *
 *******************************************************************/
SnapThread::SnapThread(ImpersonService* parent, DcsMessage* pMsg,
						const ImpConfig& c)
	: OperationThread(parent, pMsg, c)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
SnapThread::~SnapThread()
{
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SnapThread::run()
{
	exec();
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SnapThread::exec()
{
		
		std::string user("");
		std::string sessionId("");
		std::string camera("");
		std::string file("");

		LOG_FINEST("in SnapThread::run\n"); fflush(stdout);

		DcsMessage* pReply = NULL;
		DcsMessageManager& manager = DcsMessageManager::GetObject();

		try {	



		if (strcmp(m_pMsg->GetOperationName(), "snap") != 0)
			throw XosException("unknown operation");


		// Get operation parameters
		// snap operationHandle user sessionId cameraName outputfileName 
		// Operation arguments include everthing after operationHandler
		char param[8][250];
		if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s %s", 
			param[0], param[1], param[2], param[3]) != 4)
			throw XosException("Invalid arguments for snap operation");

		user = param[0];
		sessionId = param[1];
		camera = param[2];
		file = param[3];
		
		// Strip off the prefix PRIVATE
		if (sessionId.find("PRIVATE") == 0)
			sessionId = sessionId.substr(7);

		// Get an HttpClient from a factory
		HttpClientImp client;

		// Get the request object
		HttpRequest* request = client.getRequest();

		// Set the request
		request->setHost(m_config.getCameraHost());
		request->setPort(m_config.getCameraPort());
		request->setMethod(HTTP_GET);
		request->setURI("/BluIceVideo/" + camera 
				+ "/video1/axis-cgi/jpg/image.cgi?camera=2&clock=0&date=0&text=0");


		// Should we read the response ourselves?
		client.setAutoReadResponseBody(false);


		// Send the request and wait for a response
		HttpResponse* response = client.finishWriteRequest();

		if (response == NULL)
			throw XosException("ERROR: invalid HTTP Response from imp server\n");

		if (response->getStatusCode() != 200) {
			throw XosException("ERROR: Got error status code " 
							+ XosStringUtil::fromInt(response->getStatusCode())
							+ " "
							+ response->getStatusPhrase());
		}
						
			
		HttpClientImp impClient;
		impClient.setAutoReadResponseBody(true);

		HttpRequest* impRequest = impClient.getRequest();

		std::string uri("");
		uri += std::string("/writeFile?impUser=") + user
			   + "&impSessionID=" + sessionId
			   + "&impFilePath=" + file
			   + "&impFileMode=0740";

		impRequest->setURI(uri);
		impRequest->setHost(m_config.getImpHost());
		impRequest->setPort(m_config.getImpPort());
		impRequest->setMethod(HTTP_POST);
		impRequest->setContentType(WWW_JPEG);
		impRequest->setChunkedEncoding(true);

		// We need to read the response body ourselves
		char buf[2000];
		int bufSize = 2000;
		int numRead = 0;
		while ((numRead = client.readResponseBody(buf, bufSize)) > 0) {
		
			// Print out what we have read.
			if (!impClient.writeRequestBody(buf, numRead)) {
				throw XosException("ERROR: failed to write http body to imp server");
			}
		}

		// Send the request and wait for a response
		HttpResponse* impResponse = impClient.finishWriteRequest();
	
		if (impResponse->getStatusCode() != 200) {
			LOG_SEVERE2("SnapThread::exec: http error %d %s", 
					impResponse->getStatusCode(),
					impResponse->getStatusPhrase().c_str());
			throw XosException(impResponse->getStatusPhrase());
		}

		pReply = manager.NewOperationCompletedMessage( m_pMsg, "normal");

	} catch (XosException& e) {
		LOG_WARNING(e.getMessage().c_str());
		std::string tmp("error ");
		tmp += e.getMessage();
		pReply = manager.NewOperationCompletedMessage( m_pMsg, tmp.c_str());
	} catch (...) {
		LOG_WARNING("unknown exception in SnapThread::exec"); fflush(stdout);
		pReply = manager.NewOperationCompletedMessage( m_pMsg, "error unknown");
	}
	
	m_parent->SendoutDcsMessage( pReply );
	
	manager.DeleteDcsMessage(m_pMsg);
		
	m_pMsg = NULL;
	
}


