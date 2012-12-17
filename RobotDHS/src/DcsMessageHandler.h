#ifndef __XOS_DCSMESSAGEHANDLER_H__
#define __XOS_DCSMESSAGEHANDLER_H__

#include "DcsMessage.h"

//for xos_cpp socket
#include "XosSocket.h"
#include "XosException.h"
#include "XosSocketAddress.h"

class DcsMessage;
class DcsMessageHandler {

#define MAX_SERVER_NAME_LENGTH 127
#define MAX_DHS_NAME_LENGTH 127
#define CONNECT_MESSAGE_BUFFER_SIZE 200

//methods:
public:
	enum ConnectionState
	{
		DISCONNECTED,
		CONNECTING_SOCKET,
		CONNECTING_PROTOCOL,
		CONNECTED,
	};

	DcsMessageHandler( );
	~DcsMessageHandler( ); 


	xos_mutex_t& GetLock( ) { return m_SyncMtx; }

	void SetServerInfo( const char hostname[], unsigned short portNum );
    void SetDHSName( const char DHSClientName[] );
    
	bool ConnectToDCSS( );
    void Disconnect( ); //only called when program stop.


	bool WaitForInMessage( unsigned int wait_seconds = 0xffffffff );

	ConnectionState GetState( ) const { return m_State; }

	DcsMessage* CreateAndReceiveDcsMessage( unsigned int timeout_secons = 0 );

	bool SendDcsMessage( const char* pText, const char* pBinary, unsigned int binarySize, unsigned int timeout_seconds = 0 );
	bool SendAndDeleteDcsMessage( DcsMessage* pMsg, unsigned int timeout_seconds = 0 );	//this will also delete the message

private:
 
    DcsMessageHandler( const DcsMessageHandler& );

    DcsMessageHandler& operator =(const DcsMessageHandler&);

	bool MakeSocketConnection( );

	//these 2 methods are used in setup initial connection with DCSS using fixed 200 bytes message
	bool ReceiveDcsConnectionMessage( unsigned int timeout_seonds = 0 );
	bool SendDcsConnectionMessage( unsigned int timeout_seconds = 0 );


//data
private:	
	xos_mutex_t		    m_SyncMtx;

	XosSocket           m_sConnect;

	XosSocketAddress    m_ServerAddress;

	char			    m_ServerName[MAX_SERVER_NAME_LENGTH + 1];
	char			    m_DHSName[CONNECT_MESSAGE_BUFFER_SIZE + 1];

	unsigned short      m_ServerPort;

	volatile ConnectionState m_State;
};

#endif //#ifndef __XOS_DCSMESSAGEHANDLER_H__

