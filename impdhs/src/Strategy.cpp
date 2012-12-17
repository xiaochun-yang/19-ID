/***********************************************************************\
*			  strategy.cpp  -  description								*
*			     -------------------									*
*   begin		: Thu Jul 13 2006										*
*   author 		: Jonathan O'Keefe										*
*   email		: jmokeefe@slac.stanford.edu, mavsoccer1417@yahoo.com	*
\***********************************************************************/
#include "Strategy.h"
Strategy::Strategy(ImpersonService* parent, const ImpConfig& c):
	m_monitorState(NOT_READY),
	m_parent(parent),
	m_config(c),
	m_contents(3, 512),
	m_newMessage(FALSE),
	m_done(FALSE),
	m_url(""){
}
Strategy::~Strategy(){}
void Strategy::run(){
	LOG_FINE("In Strategy::run");
	exec();
}
void Strategy::stop(){
	LOG_FINE("In Strategy::stop");
	m_locker.lock();
	m_done = TRUE; //set the flag so that program can end
	m_locker.unlock();
}
bool Strategy::isDone(){
	bool ret = FALSE;
	m_locker.lock();
	ret = m_done;
	m_locker.unlock();
	return ret;	//returns whether or not stop has been called
}
std::string Strategy::getStrategyFile(){
	std::string fullPath = "";
	m_locker.lock();
	fullPath = m_contents.getField( 1 );
	m_locker.unlock();
	return fullPath;
}
std::string Strategy::getRunname(){
	std::string fullPath = "";
	m_locker.lock();
	fullPath = m_contents.getField( 2 );
	m_locker.unlock();
	return fullPath;
}
void Strategy::setNew(std::string contents){
	m_locker.lock();
	m_contents.parse( std::string("not_ready " + contents).c_str());
	m_newMessage = TRUE;
	m_locker.unlock();
}
void Strategy::exec(){
	LOG_INFO("in Strategy::exec enter\n"); fflush(stdout);
	std::string curFile                       = "";
	std::string curRunname                    = "";
	m_url = m_config.getStr( "strategy.statusUrl" );
	LOG_INFO1( "url: %s", m_url.c_str( ));
	const unsigned int MAX_WAIT_LOOP          = 60;
	bool file_opened_once                     = false;
	unsigned int loop_wait_to_first_open_file = 0;
	char previousStatus[1024]                 = {0};
	while (!isDone()){
		try{
			LOG_INFO("strategy wait new message");
			xos_thread_sleep(1000);
			/*If there is a new message set the
			  new message as the current message.
			  If its status is hide send back
			  hide to dcss.  If it has a '/' then
			  set the button to not_ready. Else
			  set it to ready and let blu-ice
			  handle parsing*/
			if (m_newMessage){
				m_newMessage = FALSE;		//set the new message flag to false
				file_opened_once  = FALSE;	//set the opened flag to false
				loop_wait_to_first_open_file = 0;	//reset the loop counter to 0
				previousStatus[0] = '\0';
				curRunname = getRunname( );
				curFile = getStrategyFile( );    	//set the current file to the new file
				LOG_INFO2( "new string: file: %s runname %s", curFile.c_str(),curRunname.c_str());
				if(curFile[0] != '/'){
					enableButton( );	//if no '/' then send back ready and let blu-ice parse message
					m_monitorState = WAITING_MESSAGE;
				}
				else{
					disableButton( );	//else send back not_ready
					m_monitorState = MONITORING;
				}
			}
			else{
				LOG_INFO( "Out of sleep with no new message" );
			}
			if (m_monitorState != MONITORING) {
				LOG_INFO( "strategy does not have a file to monitor" );
				continue;	//go back to begginning of loop
			}
			LOG_INFO1( "strategy is monitoring file %s", curFile.c_str( ) );
			char firstLine[1024] = {0};
			if (getFirstLine( curFile, firstLine, sizeof(firstLine) )){
				LOG_INFO("strategy: file readable" );
				file_opened_once  = true;
				LOG_INFO1( "status line: %s", firstLine );
				if (!strncmp( firstLine, "done", 4) ||!strncmp( firstLine, "error", 5 )){
					m_monitorState = WAITING_MESSAGE;
					enableButton( );
				}
				else if(!strncmp(firstLine, "running",7) || !strncmp(firstLine,"pending",7)){
					if (strcmp( previousStatus, firstLine )){
						setStatus( firstLine );
						LOG_INFO1( "update status to %s", firstLine );
	std::string m_status;
					}
				}
				else{
					strcpy(firstLine,"errorSvr");
					if (strcmp( previousStatus, firstLine )){
						setStatus(firstLine);
					}
				}
				strcpy( previousStatus, firstLine );
			}
			else{
				LOG_INFO("strategy: file not readable yet" );
				if (!file_opened_once){
					++loop_wait_to_first_open_file;
					if (loop_wait_to_first_open_file > MAX_WAIT_LOOP){
						setStatus( "errorSvr" );
						m_monitorState = WAITING_MESSAGE;
					}
				}
			}	std::string m_status;

		}
		catch (XosException e) {
			LOG_WARNING1("Strategy: %s", e.getMessage().c_str());
		}
	}
	LOG_INFO("in Strategy::exec exit\n"); fflush(stdout);
}
int Strategy::getFirstLine( const std::string& filename, char* buffer, size_t max_length )
{
    if (max_length < 2)
    {
        return 0;
    }
    --max_length;

	HttpClientSSLImp client;
	// Should we read the response ourselves?
	client.setAutoReadResponseBody(false);

	HttpRequest* request = client.getRequest();
    std::string url = m_url;
	url += "?beamline=" + m_config.getConfigRootName( );
    url += "&file=" + filename;
    LOG_INFO1( "full url: %s", url.c_str( ) );

	request->setMethod(HTTP_GET);
	request->setURI(url);

	// Send the request and wait for a response
	HttpResponse* response = client.finishWriteRequest();

	if (response == NULL)
    {
        LOG_SEVERE( "invalid HTTP Response from imp server");
        return 0;
    }

	if (response->getStatusCode() != 200) {
		std::string msg = "Got error status code " 
						+ XosStringUtil::fromInt(response->getStatusCode())
						+ " "
						+ response->getStatusPhrase();
        LOG_SEVERE( msg.c_str( ) );
        return 0;
	}

	// We need to read the response body ourselves
	int numRead = 0;
	numRead = client.readResponseBody(buffer, max_length);
    if (numRead <= 0)
    {
        LOG_WARNING( "read error from http response" );
        return 0;
    }
    LOG_INFO1( "nread: %d", numRead );
    buffer[numRead] = '\0';
    LOG_INFO1( "raw line: %s", buffer );
    std::string temp = buffer;
    temp = XosStringUtil::trim( temp );
    strcpy( buffer, temp.c_str( ));

    for (int i = 0; i < numRead; ++i)
    {
        if (isspace( buffer[i] ))
        {
            buffer[i] = '\0';
            break;
        }
    }
    LOG_INFO1( "cooked line: %s", buffer );
    return 1;
}
void Strategy::updateString(){
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	DcsMessage* pMsg = manager.NewStringCompletedMessage(
		"strategy_status", "normal",m_contents.getList());
	m_parent->SendoutDcsMessage( pMsg );
}
void Strategy::sendErrorMessage ( const char contents[] ){
	DcsMessageManager& manager = DcsMessageManager::GetObject();
	DcsMessage* pMsg = manager.NewLog( "error", "impdhs", contents );
	m_parent->SendoutDcsMessage( pMsg );
}
