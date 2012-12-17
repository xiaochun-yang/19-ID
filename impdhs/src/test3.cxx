#include <ctype.h>
#include "XosStringUtil.h"
#include "XosConfig.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"
#include "log_quick.h"

XosConfig m_config("config.prop");
std::string m_beamline = "";
int m_eventId = -1;
std::string m_trustedCaFile = "";
std::string m_trustedCaDir = "";
std::string m_baseUrl = "";
std::string m_getCassetteDataUrl = "";
std::string m_getLatestEventIdUrl = "";
std::string m_getSilIdAndEventIdUrl = "";
std::string m_silId = "";

std::string m_cassetteList = "";
std::string m_currentContents = "";
std::string m_command = "";
std::string m_ciphers = "";


/*******************************************************************
 *
 * replace newline with space
 *
 *******************************************************************/
std::string convertToString( const std::string& contents )
{
    std::string result = contents;

    bool anyChange = false;

    size_t index = 0;
    while ((index = result.find_first_of( '\n', index )) != std::string::npos)
    {
        anyChange = true;
        result[index] = ' ';
    }

    return result;
}


/*******************************************************************
 *
 *
 *
 *******************************************************************/
int getLatestEventId(std::string id)
{

	const char* caFile = NULL;
	const char* caDir = NULL;
	std::string caFileStr = m_trustedCaFile;
	std::string caDirStr = m_trustedCaDir;
	if (!caFileStr.empty())
		caFile = caFileStr.c_str();
	if (!caDirStr.empty())
		caDir = caDirStr.c_str();

	HttpClientSSLImp client(caFile, caDir);
	if (m_ciphers.size() > 0)
		client.setCiphers(m_ciphers.c_str());
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();

	std::string uri = m_getLatestEventIdUrl;
            
    if (uri.empty( ))
    {
        printf("WARNING screening.getLatestEventIdUrl not defined in property file\n" ); fflush(stdout);
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

	printf( "INFO getLatestEventIdUrl url: {%s}\n", uri.c_str( ) ); fflush(stdout);
		
	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		printf("INFO getLatestEventId: code = %d %s\n", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str()); fflush(stdout);
		throw XosException(response->getStatusPhrase() + uri );
	}
	
	std::string body = response->getBody();	
	
	int ev = XosStringUtil::toInt(body, -1);

	printf("INFO getLatestEventId: %d\n", ev); fflush(stdout);
	
	if (ev == -1) {
		printf("INFO Failed to get latest event id for sil %s: %s\n", 
					id.c_str(), body.c_str()); fflush(stdout);
	}
	
	return ev;
	
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
std::string getCassetteListFromWeb()
{
	const char* caFile = NULL;
	const char* caDir = NULL;
	std::string caFileStr = m_trustedCaFile;
	std::string caDirStr = m_trustedCaDir;
	if (!caFileStr.empty())
		caFile = caFileStr.c_str();
	if (!caDirStr.empty())
		caDir = caDirStr.c_str();

	HttpClientSSLImp client(caFile, caDir);
	if (m_ciphers.size() > 0)
		client.setCiphers(m_ciphers.c_str());
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();
			
	std::string uri = m_getCassetteDataUrl;
    if (uri.empty( ))
    {
        printf( "INFO screening.getCassetteDataUrl not in property file\n" ); fflush(stdout);
		throw XosException( "screening.getCassetteDataUrl not in property file" );
    }
	uri += "?forBeamLine=" + m_beamline;

	std::string host;
	int port;
	std::string requestStr;
	XosStringUtil::parseUrl(uri, host, port, requestStr);
	request->setHost(host);
	request->setPort(port);
	request->setURI(uri);

	printf( "INFO getCassetteDataUrl url: {%s}\n", uri.c_str( ) ); fflush(stdout);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		printf("INFO getCassetteList: code = %d %s\n", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str()); fflush(stdout);
		throw XosException(response->getStatusPhrase() + uri);
	}
	
				
	std::string body = response->getBody();	
	body = convertToString(body );
	printf("INFO getCassetteData: %s\n", body.c_str()); fflush(stdout);
	
	return body;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
std::string getSilAndEventFromWeb()
{
	const char* caFile = NULL;
	const char* caDir = NULL;
	std::string caFileStr = m_trustedCaFile;
	std::string caDirStr = m_trustedCaDir;
	if (!caFileStr.empty())
		caFile = caFileStr.c_str();
	if (!caDirStr.empty())
		caDir = caDirStr.c_str();

	HttpClientSSLImp client(caFile, caDir);
	if (m_ciphers.size() > 0)
		client.setCiphers(m_ciphers.c_str());
	client.setAutoReadResponseBody(true);

	HttpRequest* request = client.getRequest();
			
	std::string uri = m_getSilIdAndEventIdUrl;
    if (uri.empty( ))
    {
        printf( "INFO screening.getSilIdAndEventIdUrl not in property file\n" ); fflush(stdout);
		throw XosException( "screening.getSilIdAndEvnetIdUrl not in property file" );
    }
	uri += "?forBeamLine=" + m_beamline;

	request->setURI(uri);

	printf( "INFO getSilAndEventUrl url: {%s}\n", uri.c_str( ) ); fflush(stdout);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();
	
	if (response->getStatusCode() != 200) {
		printf("INFO getCassetteList: code = %d %s\n", 
					response->getStatusCode(),
					response->getStatusPhrase().c_str()); fflush(stdout);
		throw XosException(response->getStatusPhrase() + uri);
	}
	
				
	std::string body = response->getBody();	
	printf("INFO getSilIdAndEventId: %s\n", body.c_str()); fflush(stdout);
	return body;
}

/*******************************************************************
 *
 *
 *
 *******************************************************************/
int main(int argc, char** argv)
{
	
	set_save_logger_error(0);

	if (argc < 2) {
		printf("Usage: test3 <beamline> [getCassetteData|getLatestEventId|getSilIdAndEventId]\n");
		return 0;
	}

	m_beamline = argv[1];
	m_config.load();

	if (argc == 3) {
		m_command = argv[2];
	}

	m_config.get(m_beamline + ".silId", m_silId);
	m_config.get("trustedCaFile", m_trustedCaFile); 
	m_config.get("trustedCaDir", m_trustedCaDir);
	m_config.get("baseUrl", m_baseUrl);
	m_config.get("ciphers", m_ciphers);
//	m_config.get("getCassetteDataUrl", m_getCassetteDataUrl);
//	m_config.get("getLatestEventIdUrl", m_getLatestEventIdUrl);
//	m_config.get("getSilIdAndEventId", m_getSilIdAndEventIdUrl);
	m_getCassetteDataUrl = m_baseUrl + "/getCassetteData.do";
	m_getLatestEventIdUrl = m_baseUrl + "/getLatestEventId.do";
	m_getSilIdAndEventIdUrl = m_baseUrl + "/getSilIdAndEventId.do";

	printf("main started\n"); fflush(stdout); fflush(stdout);

	int ev = -1;
	std::string curId = m_silId;
	std::string newId = curId;

	std::string casList = "";
	std::string newContents = "";

	// Run one command and exit.
	if (!m_command.empty()) {
		if (m_command == "getCassetteData") {
			getCassetteListFromWeb();
		} else if (m_command == "getLatestEventId") {
			getLatestEventId(curId);
		} else if (m_command == "getSilIdAndEventId") {
			getSilAndEventFromWeb();
		} else {
			printf("Unsupported command: %s\n", m_command.c_str());
			printf("Usage: test3 <beamline> [getCassetteData|getLatestEventId|getSilIdAndEventId]\n");
			fflush(stdout);
		}
		return 0;
	}

	bool done = false;
	// Loop forever
	while (!done) {
	
		// getLatestEventId
		try {
	
		    xos_thread_sleep(1000);
		
		    newId = m_silId;
		
		    if (!newId.empty() && (newId != curId)) {
			    printf("WARNING SilThread: silId changed old silId = %s new silId = %s\n", 
					curId.c_str(), newId.c_str()); fflush(stdout);
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
			        printf("INFO SilThread: event changed silId = %s eventId = %d, newEventId = %d\n", 
					    curId.c_str(), m_eventId, ev); fflush(stdout);			
		        }
            }
		} catch (XosException e) {
			printf("WARNING getLatestEventId: %s\n", e.getMessage().c_str()); fflush(stdout);
		}

		// getCassetteData
		try {
            casList = getCassetteListFromWeb( );
            if (casList != m_cassetteList)
            {
                printf("INFO cassetteList chagned from %s to %s\n",
                        m_cassetteList.c_str(), casList.c_str( ) ); fflush(stdout);
                m_cassetteList = casList;
            }
		} catch (XosException e) {
			printf("WARNING getCassetteData: %s\n", e.getMessage().c_str()); fflush(stdout);
		}
    
		// getSilIdAndEventId
		try {
            newContents = getSilAndEventFromWeb( );
            if (newContents != m_currentContents)
            {
					printf( "INFO sil and event List chagned from %s to %s\n",
						m_currentContents.c_str(), newContents.c_str( ) ); fflush(stdout);
            }
		} catch (XosException e) {
			printf("WARNING getSilIdAndEventId: %s\n", e.getMessage().c_str()); fflush(stdout);
		}

	}
	printf("INFO main exit\n"); fflush(stdout);
}

