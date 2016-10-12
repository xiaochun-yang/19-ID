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
#include "SilThread.h"
#include "log_quick.h"
#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"


/*******************************************************************
 *
 *
 *
 *******************************************************************/
SilThread::SilThread(ImpersonService* parent, const ImpConfig& c)
	:	m_parent(parent),
		m_config(c),
		m_silId(""), 
		m_eventId(-1),
		m_done(FALSE)
{
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
SilThread::~SilThread()
{
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SilThread::run()
{
	exec();
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
std::string SilThread::getSilId()
{
	std::string id = "";
	
	m_locker.lock();
	id = m_silId;
	m_locker.unlock();
	
	return id;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SilThread::setSilId(std::string id)
{
    //trim the id
    id = XosStringUtil::trim( id );
        
	m_locker.lock();
	m_silId = id;
	m_locker.unlock();
	
	LOG_INFO1("Setting silId to %s", id.c_str());
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
bool SilThread::isDone()
{
	bool ret = FALSE;
	
	m_locker.lock();
	ret = m_done;
	m_locker.unlock();
	
	return ret;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SilThread::stop()
{
	m_locker.lock();
	m_done = true;
	m_locker.unlock();	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
void SilThread::exec()
{

	LOG_INFO("in SilThread::exec enter\n"); fflush(stdout);

    //get blctl sessionID
    //FILE* fh = fopen( "/home/blctl/.bluice/session", "r" );
    //char sessionID[2048] = {0};
    //if (fh)
    //{
    //    fread( sessionID, 2047, 1, fh );
    //    fclose( fh );
    //}

	DcsMessageManager& manager = DcsMessageManager::GetObject();

	int ev = -1;
	std::string curId = getSilId();
	std::string newId = curId;

    std::string casList;
	while (!isDone()) {
	
		try {
	
		    xos_thread_sleep(1000);
		
		    newId = getSilId();
		
		    if (!newId.empty() && (newId != curId)) {
			    LOG_FINEST2("SilThread: silId changed old silId = %s new silId = %s", 
					curId.c_str(), newId.c_str());
			    curId = newId;
			    m_eventId = -1;
		    }
		
            if (XosStringUtil::toInt(curId, 0) !=0)
            {
		        ev = getLatestEventId(curId);
					
		        // new events have been completed
		        if (ev > m_eventId) {
			        m_eventId = ev;
			        std::string contents = curId + " " + XosStringUtil::fromInt(m_eventId);
			        LOG_FINEST3("SilThread: event changed silId = %s eventId = %d, newEventId = %d", 
					    curId.c_str(), m_eventId, ev);
			        DcsMessage* pMsg = manager.NewStringCompletedMessage(
											"sil_event_id", 
											"normal", contents.c_str());
			        m_parent->SendoutDcsMessage( pMsg );
			
		        }
            }
	    } catch (XosException e) {
			LOG_WARNING1("SilThread: %s", e.getMessage().c_str());
		}
		try {
            casList = getCassetteListFromWeb( );
            if (casList != m_cassetteList)
            {
                LOG_INFO2( "cassetteList chagned from %s to %s",
                        m_cassetteList.c_str(), casList.c_str( ) );
                m_cassetteList = casList;
                //update string
			    DcsMessage* pMsg = manager.NewStringCompletedMessage(
											"cassette_list", 
											"normal", m_cassetteList.c_str());
			m_parent->SendoutDcsMessage( pMsg );
            }
		} catch (XosException e) {
			LOG_WARNING1("SilThread cassetteList: %s", e.getMessage().c_str());
		}
    
	}
	LOG_INFO("in SilThread::exec exit\n"); fflush(stdout);
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
int SilThread::getLatestEventId(std::string id)
	throw (XosException)
{

	std::string caFile = m_config.getTrustedCaFile();
	std::string caDir = m_config.getTrustedCaDir();

	HttpClientSSLImp client;

	if (!caFile.empty())
		client.setTrustedCaFile(caFile.c_str());
	if (!caDir.empty())
		client.setTrustedCaDir(caDir.c_str());
	std::string ciphers = m_config.getCiphers();
	if (ciphers.size() > 0)
		client.setCiphers(ciphers.c_str());
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri = m_config.getLatestEventIdUrl( );
            
    if (uri.empty( ))
    {
        LOG_WARNING( "screening.getLatestEventIdUrl not defined in property file" );
        return -1;
    }

    uri += "?silId=" + id;

	std::string host;
	int port;
	std::string requestStr;
	XosStringUtil::parseUrl(uri, host, port, requestStr);
	request->setHost(host);
	request->setPort(port);
	request->setURI(uri);


	LOG_INFO2( "screening host: %s port: %d", host.c_str(), port);
	LOG_INFO1( "getLatestEventIdUrl url: {%s}", uri.c_str( ) );
		
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_INFO2("getLatestEventId: code = %d %s", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase() + uri );
	}
	
	std::string body = response->getBody();	
    //LOG_INFO1("body = %s", body.c_str());
	
	int ev = XosStringUtil::toInt(body, -1);
	
	if (ev == -1) {
		LOG_WARNING2("Failed to get latest event id for sil %s: %s", 
					id.c_str(), body.c_str());
	}
	
	return ev;
	
}

std::string SilThread::getCassetteListFromWeb( )
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
	if (ciphers.size() > 0) {
		LOG_INFO1("using ciphers = %s", ciphers.c_str());
		client.setCiphers(ciphers.c_str());
   }
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();
			
	std::string uri = m_config.getCassetteDataUrl( );
    if (uri.empty( ))
    {
        LOG_INFO( "screening.getCassetteDataUrl not in property file" );
		throw XosException( "screening.getCassetteDataUrl not in property file" );
    }
	uri += "?forBeamLine=" + m_config.getConfigRootName( );

	std::string host;
	int port;
	std::string requestStr;
	XosStringUtil::parseUrl(uri, host, port, requestStr);
	request->setHost(host);
	request->setPort(port);
	request->setURI(uri);


	LOG_INFO2( "screening host: %s port: %d", host.c_str(), port);
	LOG_INFO1( "getCassetteDataUrl url: {%s}", uri.c_str( ) );

    //LOG_INFO2( "host: %s port: %d", m_config.getSilHost( ).c_str( ), m_config.getSilPort( ));
    //LOG_INFO1( "url: {%s}", uri.c_str( ) );
	
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		LOG_INFO2("getCassetteList: code = %d %s", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str());
		throw XosException(response->getStatusPhrase() + uri);
	}
	
				
	std::string body = response->getBody();	
	//LOG_INFO1("body = %s", body.c_str());
    body = convertToString( body );
	
	return body;
}

//replace newline with space
std::string SilThread::convertToString( const std::string& contents )
{
    std::string result = contents;

    bool anyChange = false;

    size_t index = 0;
    while ((index = result.find_first_of( '\n', index )) != std::string::npos)
    {
        anyChange = true;
        result[index] = ' ';
    }

    //if (anyChange)
    //{
    //    LOG_INFO1( "convertToString: %s", result.c_str( ) );
    //}
    return result;
}
