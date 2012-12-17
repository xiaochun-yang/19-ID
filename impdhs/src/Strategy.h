/*******************************************************************************\
*			  strategy.h  -  description				*
*			     -------------------				*
*   begin		: Thu Jul 13 2006					*
*   author 		: Jonathan O'Keefe					*
*   email		: jmokeefe@slac.stanford.edu, MavSoccer1417@yahoo.com	*
\*******************************************************************************/
#ifndef STRATEGY_H
#define STRATEGY_H
#include "XosThread.h"
#include "DcsMessage.h"
#include "ImpConfig.h"
#include "DcsMessageManager.h"
#include "ImpersonService.h"
#include "TclList.h"
#include <ctype.h>

#include "XosStringUtil.h"
#include "HttpConst.h"
#include "HttpUtil.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "HttpClientSSLImp.h"


class Strategy : public XosThread{
public://functions
	Strategy(ImpersonService* parent, const ImpConfig& c);
	virtual ~Strategy();
	void setNew(std::string newMessage);
	void stop();
	virtual void run();
private://functions
	void exec();
	bool isDone();
	std::string getStrategyFile();
	std::string getRunname();
	void setStatus( const char* status ){
		m_contents.setField( 0, status );
		updateString( );
	}
	void disableButton( ) {
		setStatus("not_ready");
	}
	void enableButton( ) {
		setStatus("ready");
	}
	void updateString();
	int getFirstLine( const std::string& filename, char* buffer, size_t max_length );
	void sendErrorMessage( const char contents[] );
private://data
	enum MonitorState {
		NOT_READY,
		WAITING_MESSAGE,
		MONITORING,
	} m_monitorState;
	ImpersonService*   m_parent;
	const ImpConfig& m_config;
	TclList  m_contents;
	bool m_newMessage;
	bool m_done;
	std::string m_url;
	XosMutex m_locker;
};
#endif
