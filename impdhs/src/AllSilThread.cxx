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

#include <ctype.h>
#include "DcsMessage.h"
#include "DcsMessageManager.h"
#include "ImpersonService.h"
#include "ImpersonSystem.h"
#include "AllSilThread.h"
#include "log_quick.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"


#define SIL_AND_EVENT_STRING_NAME "sil_and_event_list"

/*******************************************************************
 *
 *
 *
 *******************************************************************/
AllSilThread::AllSilThread(ImpersonService* parent, const ImpConfig& c)
:m_stopFlag(FALSE)
,m_parent(parent)
,m_config(c)
,m_currentContents("")
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
AllSilThread::~AllSilThread()
{
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AllSilThread::run()
{
	exec();
}


void AllSilThread::stop()
{
	m_stopFlag = true;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void AllSilThread::exec()
{

	LOG_INFO("in AllSilThread::exec enter");

	DcsMessageManager& manager = DcsMessageManager::GetObject();

    std::string newContents;
    std::string detailContents;
    std::vector<std::string> contentsList;


    bool stringRegistered = false;

    bool anyDetailStringRegistered = false;
    bool detailRegistered[4] = {false, false, false, false};

    const char detailedStringName[4][80] = {
        "sil_detail_no",
        "sil_detail_left",
        "sil_detail_middle",
        "sil_detail_right"
    };


	while (!m_stopFlag) {
		try {
            int i = 0;

            if (!stringRegistered) {
                stringRegistered = m_parent->stringRegistered( SIL_AND_EVENT_STRING_NAME );
                LOG_INFO1( "trying to see if string %s registered", SIL_AND_EVENT_STRING_NAME );
            }

            //change to i=1 if you want sil_detail_no"
            for (i = 1; i < 4; ++i) {
                if (!detailRegistered[i]) {
                    detailRegistered[i] =
                    m_parent->stringRegistered( detailedStringName[i] );
                    LOG_INFO1( "trying to see if string %s registered", detailedStringName[i] );
                }

                if (detailRegistered[i]) {
                    anyDetailStringRegistered = true;
                }
            }


            if (!anyDetailStringRegistered) {
                newContents = getSilAndEventFromWeb( );
            } else {
                detailContents = getSilAndEventFromWeb( true );
	            XosStringUtil::tokenize( detailContents, "\n", contentsList);
                if (contentsList.size() != 4) {
                    LOG_WARNING1("got bad contents of detailed sil %s", detailContents.c_str());
                    newContents = getSilAndEventFromWeb( );
                } else {
                    long sil[4] = {-1, -1, -1, -1};
                    long evt[4] = {-1, -1, -1, -1};

                    for (i = 0; i < 4; ++i) {
                        if (sscanf( contentsList[i].c_str(), "%ld %ld", sil+i, evt+i ) != 2) {
                            LOG_WARNING1( "sscanf failed to get 2 integers from %s", contentsList[i].c_str( ));
                        }
                    }
                    //enough for 8 long numbers
                    char line[256] = {0};
                    snprintf( line, sizeof(line), "%ld %ld %ld %ld %ld %ld %ld %ld",
                    sil[0], evt[0],
                    sil[1], evt[1],
                    sil[2], evt[2],
                    sil[3], evt[3] );

                    //LOG_INFO1( "brief from detail: %s", line );

                    newContents = line;
                }
            }
            if (newContents != m_currentContents)
            {
                LOG_INFO2( "sil and event List chagned from %s to %s",
                        m_currentContents.c_str(), newContents.c_str( ) );


                if (stringRegistered) {
                    //update string
			        DcsMessage* pMsg = manager.NewStringCompletedMessage(
                        SIL_AND_EVENT_STRING_NAME,
                        "normal", newContents.c_str()
                    );
			        m_parent->SendoutDcsMessage( pMsg );
                    m_currentContents = newContents;
                }
            }
            //change to i = 0 if you care sil_detail_no
            int maxI = 4;
            if (maxI > contentsList.size()) {
                maxI = contentsList.size();
            }
            for (i = 1; i < maxI; ++i) {
                if (m_detailContents[i] != contentsList[i]) {
                    LOG_INFO3( "%s chagned from %s to %s",
                    detailedStringName[i],
                    m_detailContents[i].c_str(),
                    contentsList[i].c_str() );


                    if (detailRegistered[i]) {
			            DcsMessage* pMsg = manager.NewStringCompletedMessage(
                        detailedStringName[i],
                        "normal", contentsList[i].c_str()
                        );
			            m_parent->SendoutDcsMessage( pMsg );
                        m_detailContents[i] = contentsList[i];
                    }
                }
            }


		} catch (XosException e) {
			LOG_WARNING1("AllSilThread sil_and_event_list: %s", e.getMessage().c_str());
		}
    
		xos_thread_sleep(1000);
	}
	LOG_INFO("in AllSilThread::exec exit");
}

std::string AllSilThread::getSilAndEventFromWeb( bool detail )
	throw (XosException)
{
	const char* caFile = NULL;
	const char* caDir = NULL;
	std::string caFileStr = m_config.getTrustedCaFile();
	std::string caDirStr = m_config.getTrustedCaDir();
	if (!caFileStr.empty())
		caFile = caFileStr.c_str();
	if (!caDirStr.empty())
		caDir = caDirStr.c_str();
	HttpClientSSLImp client(caFile, caDir);
	std::string ciphers = m_config.getCiphers();
	if (ciphers.size() > 0)
		client.setCiphers(ciphers.c_str());
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();
			
	std::string uri = m_config.getSilAndEventUrl( );
    if (uri.empty( ))
    {
        LOG_INFO( "screening.getSilIdAndEventIdUrl not in property file" );
		throw XosException( "screening.getSilIdAndEvnetIdUrl not in property file" );
    }
	uri += "?forBeamLine=" + m_config.getConfigRootName( );

    if (detail) {
        uri += "&detail=true";
    }

	request->setURI(uri);

	LOG_INFO1( "getSilAndEventUrl url: {%s}", uri.c_str( ) );

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_INFO2("getSilIdAndEventId: code = %d %s", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase() + uri);
	}
	
				
	std::string body = response->getBody();	
	return body;
}
