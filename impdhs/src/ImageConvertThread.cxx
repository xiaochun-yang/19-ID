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
#include "ImageConvertThread.h"
int ImageConvertThread::c_inited = 0;

/*******************************************************************
 *
 *
 *
 *******************************************************************/
ImageConvertThread::ImageConvertThread(ImpersonService* parent, DcsMessage* pMsg,
                        const ImpConfig& c)
    : OperationThread(parent, pMsg, c)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
ImageConvertThread::~ImageConvertThread()
{
}

void ImageConvertThread::initialize( )
{
    if (c_inited != 0) return;
    if (m_config.getSmallImageParam( ).length( ) == 0 &&
        m_config.getMediumImageParam( ).length( ) == 0 &&
        m_config.getLargeImageParam( ).length( ) == 0)
    {
        c_inited = -1;
    }
    else
    {
        c_inited = 1;
    }
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void ImageConvertThread::run()
{
    exec();
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void ImageConvertThread::exec()
{
    char logBuffer[9999] = {0};
    initialize( );
        
    std::string user("");
    std::string sessionId("");
    std::string camera("");
    std::string file("");

    std::string small  = m_config.getSmallImageParam( );
    std::string medium = m_config.getMediumImageParam( );
    std::string large  = m_config.getLargeImageParam( );
    LOG_INFO1( "small in image: {%s}", small.c_str( ) );
    LOG_INFO1( "medium in image: {%s}", medium.c_str( ) );
    LOG_INFO1( "large in image: {%s}", large.c_str( ) );


    LOG_FINEST("in ImageConvertThread::run\n"); fflush(stdout);

    DcsMessage* pReply = NULL;
    DcsMessageManager& manager = DcsMessageManager::GetObject();

    try {    

        if (strcmp( m_pMsg->GetOperationName(), OP_IMAGE_CONVERT ) != 0)
            throw XosException("unknown operation");


        // Get operation parameters
        // username sessionID filename
        // Operation arguments include everthing after operationHandler
        char args[8][250] = {{0}};
        if (sscanf(m_pMsg->GetOperationArgument(), "%s %s %s", 
            args[0], args[1], args[2]) != 3)
            throw XosException("Invalid arguments for image_convert operation");


        if (c_inited <= 0)
        {
            throw XosException("none image configed");
        }
        
        user = args[0];
        sessionId = args[1];
        file = args[2];

        //file base name without extension
        size_t pos = file.find_last_of( "." );
        size_t slash = file.find_last_of( "/" );
        std::string base_name = file;
        if (pos != std::string::npos)
        {
            if (slash == std::string::npos ||
                slash < pos)
            {
                base_name = file.substr( 0, pos );
                LOG_FINEST1( "baes filename: %s", base_name.c_str( ) );
            }
        }
        
        // Strip off the prefix PRIVATE
        if (sessionId.find("PRIVATE") == 0)
            sessionId = sessionId.substr(7);

        std::string base_url("");
        base_url = std::string("/getImage?userName=") + user
                + "&sessionId=" + sessionId
                + "&fileName=" + file;

        for (int image_no = 0; image_no < 3; ++image_no)
        {
            std::string url = base_url;
            std::string image_param("");
            std::string jpgfile("");
            switch (image_no)
            {
            case 0:
                image_param = small;
                jpgfile = base_name + "_small.jpg";
                break;
            case 1:
                image_param = medium;
                jpgfile = base_name + "_medium.jpg";
                break;
            case 2:
                image_param = large;
                jpgfile = base_name + "_large.jpg";
                break;
            }
            if (image_param.length( ) == 0)
            {
                continue;
            }
            url += image_param;
            {
                //put intp braces
                //to avoid reuse of http client
                //
                // Get an HttpClient from a factory
                HttpClientImp client;

                // Get the request object
                HttpRequest* request = client.getRequest();

                // Set the request
                request->setHost(m_config.getImageHost());
                request->setPort(m_config.getImagePort());
                request->setMethod(HTTP_GET);
                request->setURI( url );
                memset( logBuffer, 0, sizeof(logBuffer) );
                strncpy( logBuffer, url.c_str( ), sizeof(logBuffer) - 1 );
                XosStringUtil::maskSessionId( logBuffer );
                LOG_INFO1( "image convert url: {%s}", logBuffer );
        
                // Should we read the response ourselves?
                client.setAutoReadResponseBody(false);


                // Send the request and wait for a response
                HttpResponse* response = client.finishWriteRequest();
                LOG_INFO( "client called finishWriteRequest" );

                if (response == NULL)
                    throw XosException("ERROR: invalid HTTP Response from image server\n");

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
                    + "&impFilePath=" + jpgfile
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
                    LOG_INFO1( "relay: %d", numRead );
                    if (!impClient.writeRequestBody(buf, numRead)) {
                        throw XosException("ERROR: failed to write http body to imp server");
                    }
                    LOG_INFO( "called write body" );
                }

                // Send the request and wait for a response
                HttpResponse* impResponse = impClient.finishWriteRequest();
                LOG_INFO( "impclient called finishWriteRequest" );
    
                if (impResponse->getStatusCode() != 200) {
                    LOG_SEVERE2("ImageConvertThread::exec: http error %d %s", 
                        impResponse->getStatusCode(),
                        impResponse->getStatusPhrase().c_str());
                    throw XosException(impResponse->getStatusPhrase());
                }

            }//braces to avoid reuse of http client objects
        }//for image_no 0..2
        if (pReply != NULL) {
            LOG_WARNING1( "message pool leak: 0x%p", pReply );
            manager.DeleteDcsMessage( pReply );
            pReply = NULL;
        }
        pReply = manager.NewOperationCompletedMessage( m_pMsg, "normal");
    } catch (XosException& e) {
        LOG_WARNING(e.getMessage().c_str());
        std::string tmp("error ");
        tmp += e.getMessage();
        if (pReply != NULL) {
            LOG_WARNING1( "message pool leak: 0x%p", pReply );
            manager.DeleteDcsMessage( pReply );
            pReply = NULL;
        }
        pReply = manager.NewOperationCompletedMessage( m_pMsg, tmp.c_str());
    } catch (...) {
        LOG_WARNING("unknown exception in ImageConvertThread::exec"); fflush(stdout);
        if (pReply != NULL) {
            LOG_WARNING1( "message pool leak: 0x%p", pReply );
            manager.DeleteDcsMessage( pReply );
            pReply = NULL;
        }
        pReply = manager.NewOperationCompletedMessage( m_pMsg, "error unknown");
    }
    
    m_parent->SendoutDcsMessage( pReply );
    
    manager.DeleteDcsMessage(m_pMsg);
        
    m_pMsg = NULL;
    
}
