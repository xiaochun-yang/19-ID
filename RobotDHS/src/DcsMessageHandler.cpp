#include "log_quick.h"
#include "DcsMessageHandler.h"
#include "DcsMessageManager.h"

#include "XOSSingleLock.h"

//lock will be implemented in calling class.
#define NO_INTERNAL_LOCK

DcsMessageHandler::DcsMessageHandler( ):
m_ServerPort( 0 ),
m_State( DISCONNECTED )
{
	memset( m_ServerName, 0, sizeof(m_ServerName) );
	memset( m_DHSName, 0, sizeof(m_DHSName) );
    xos_mutex_create( &m_SyncMtx );
}

DcsMessageHandler::~DcsMessageHandler ( )
{
    xos_mutex_close( &m_SyncMtx );
	Disconnect( );
}

void DcsMessageHandler::SetServerInfo ( const char blctlServerString[], unsigned short ServerPort )
{
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	if (m_ServerName[0] == '\0')
	{
		strncpy( m_ServerName, blctlServerString, MAX_SERVER_NAME_LENGTH );
		m_ServerPort = ServerPort;
		LOG_INFO1( "m_ServerName points to: '%s'", m_ServerName );
		m_ServerAddress.setAddress( m_ServerName, ServerPort );
	}
	else
	{
		LOG_WARNING1( "ServerInfo already set: %s", m_ServerName );
	}
}

void DcsMessageHandler::SetDHSName( const char DHSName[] )
{
    static const char header[] = "htos_client_is_hardware ";
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	if (m_DHSName[0] == '\0')
	{
        strcpy( m_DHSName, header );
		strncat( m_DHSName, DHSName,  sizeof(m_DHSName) - sizeof(header) );
		LOG_INFO1( "m_DHSName points to: '%s'", DHSName );
	}
	else
	{
		LOG_WARNING1( "DHSName already set: %s", m_DHSName );
	}
}


void DcsMessageHandler::Disconnect( )
{
    m_sConnect.shutdownOutput( );
    m_sConnect.shutdownInput( );
	m_State = DISCONNECTED;
}


bool DcsMessageHandler::ConnectToDCSS( )
{
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif

    LOG_FINEST( "+DcsMessageHandler::ConnectToDCSS" );

	m_State = DISCONNECTED;

	if (m_ServerName[0] == '\0')
	{
        LOG_WARNING( "need to call SetServerInfo before call ConnectToDCSS" );
        LOG_FINEST( "-DcsMessageHandler::ConnectToDCSS" );
		return false;
	}
	if (m_DHSName[0] == '\0')
	{
        LOG_WARNING( "need to call SetDHSName before call ConnectToDCSS" );
        LOG_FINEST( "-DcsMessageHandler::ConnectToDCSS" );
		return false;
	}

	m_State = CONNECTING_SOCKET;
	if (!MakeSocketConnection( ))
	{
		LOG_WARNING( "MakeSocketConnection failed" );
        LOG_FINEST( "-DcsMessageHandler::ConnectToDCSS" );
		m_State = DISCONNECTED;
		return false;
	}

	m_State = CONNECTING_PROTOCOL;
	if (!ReceiveDcsConnectionMessage( 10 ) || !SendDcsConnectionMessage( 10 ))
	{
		LOG_WARNING( "protocol connection failed" );
        LOG_FINEST( "-DcsMessageHandler::ConnectToDCSS" );
		m_State = DISCONNECTED;
		return false;
	}

	m_State = CONNECTED;

    LOG_FINEST( "-DcsMessageHandler::ConnectToDCSS OK" );
	return true;

}

bool DcsMessageHandler::MakeSocketConnection ( )
{
	bool success = true;

    LOG_FINEST( "+DcsMessageHandler::MakeSocketConnection" );

	try
	{
		m_sConnect.clean( );
		m_sConnect.connect ( m_ServerAddress );

		//EVENT LOG
		LOG_INFO2( "connected to %s at port %d", m_ServerName, (int)m_ServerPort );
	}
	catch ( XosException& pe )
	{
		LOG_WARNING1( "Unable to connect to server: %s", m_ServerName );
		LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage().c_str() );
		xos_thread_sleep( 5000 );
		success = false;
	}
    LOG_FINEST( "-DcsMessageHandler::MakeSocketConnection" );
	return success;
}


bool DcsMessageHandler::WaitForInMessage ( unsigned int wait_seconds )
{
    return m_sConnect.waitUntilReadable( wait_seconds * 1000 ) == XOS_WAIT_SUCCESS;
}

bool DcsMessageHandler::ReceiveDcsConnectionMessage ( unsigned int timeout_seconds )
{
	try {
		char buffer[256]; //must be bigger than CONNECT_MESSAGE_BUFFER_SIZE(200)

		//clear buffer
		memset( buffer, 0, sizeof(buffer) );

		//receive message
		if (timeout_seconds)
		{
			m_sConnect.setReadTimeout( 1000 * timeout_seconds );
		}
		m_sConnect.readFixedLength( buffer, CONNECT_MESSAGE_BUFFER_SIZE );

		//check message
		if (!strcmp( buffer, "stoc_send_client_type" ))
		{
			return true;
		}
		else
		{
			LOG_WARNING1( "socket receiveing connect message wrong: %s", buffer );
		}
	}
	catch ( XosException& pe ) 
	{
		LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage().c_str() );
	}
	return false;
}

bool DcsMessageHandler::SendDcsConnectionMessage ( unsigned int timeout )
{
	//time out is not implemented yet in lower layer software
	//LOG_FINEST1( "Sending: '%s'", m_DHSName );

	try
    {
        m_sConnect.write( m_DHSName, CONNECT_MESSAGE_BUFFER_SIZE );
    }
	catch ( XosException& pe ) 
	{
		LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage().c_str() );
        return false;
	}
	return true;
}

DcsMessage* DcsMessageHandler::CreateAndReceiveDcsMessage( unsigned int timeout_seconds )
{
	DcsMessageManager& msgManager = DcsMessageManager::GetObject( );

	DcsMessage* pMsg = NULL;

	//lock it
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	try
	{
		char msgHeader[DCS_HEADER_SIZE + 1];	//no need + 1
		unsigned int textSize;
		unsigned int binarySize;

		//receive the header
		memset( msgHeader, 0, sizeof(msgHeader) );
		if (timeout_seconds)
		{
			m_sConnect.setReadTimeout( 1000 * timeout_seconds );
		}
		m_sConnect.readFixedLength( msgHeader, DCS_HEADER_SIZE );

		//LOG_FINEST1( "Message->header: '%s'", msgHeader );
		//get text and binary buffer sizes from header
		if (sscanf( msgHeader, " %d %d", &textSize, &binarySize ) != 2)
		{
			LOG_WARNING1( "received message header content not right '%s'", msgHeader );
			m_State = DISCONNECTED;
			return NULL;
		}

		//get a message from manager with size requirement
		pMsg = msgManager.NewDcsMessage( textSize + 1, binarySize );

		if (pMsg == NULL)
		{
			return NULL;
		}

		//receive text if any
		if (textSize)
		{
			m_sConnect.readFixedLength( pMsg->m_pText, textSize );
			pMsg->m_TextBufferSize = textSize;

			pMsg->m_pText[pMsg->m_TextBufferSize] = '\0';
			LOG_FINEST1( "Receiving: '%s'", pMsg->m_pText );
		}

		//receiving binary if any
		if (binarySize) 
		{
			m_sConnect.readFixedLength( pMsg->m_pBinary, binarySize );
			pMsg->m_BinaryBufferSize = binarySize;			
		}

		//everything ok if you get here

		//before return it, fill operation attributes if it is an operation message
		pMsg->SetAttributes( );

		return pMsg;
	}
	catch ( XosException& pe ) 
	{
        LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage( ).c_str( ) );
		if (pMsg) msgManager.DeleteDcsMessage( pMsg );
		pMsg = NULL;
	}
	m_State = DISCONNECTED;
	return NULL;
}

#define DCSS_NOT_SUPPORT_BINARY
//time out is not implemented yet in lower layer software
bool DcsMessageHandler::SendDcsMessage (  const char* pText, const char* pBinary, unsigned int binarySize, unsigned int timeout )
{
	char header[DCS_HEADER_SIZE + 1] = {0};
	size_t textSize = strlen( pText );

    if (textSize > 0)
    {
        switch (pText[textSize - 1])
        {
        case '\r':
        case '\n':
            --textSize;
        }
    }

#ifdef DCSS_NOT_SUPPORT_BINARY
	if (binarySize)
	{
		LOG_WARNING( "DCSS does not support receiving bianry messag yet, we will not send binary data" );
		binarySize = 0;
	}
#endif

	if ((pText == NULL || pText[0] == '\0') && binarySize == 0)
	{
		LOG_INFO( "empty message, sending ignored" );
		//nothing needs to be sent.
		return true;
	}

	//lock it
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	//send header
	sprintf ( header, "%12d %12d", textSize, binarySize );
    try
    {
	    m_sConnect.write( header, DCS_HEADER_SIZE );
	    if (textSize)
	    {
		    m_sConnect.write( pText, (int)textSize );
	    }

	    if (binarySize)
	    {
		    m_sConnect.write( pBinary, (int)binarySize );
	    }
    }
	catch ( XosException& pe ) 
	{
        LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage( ).c_str( ) );
		m_State = DISCONNECTED;
		return false;
    }
	//LOG_FINEST( "send message done\n" );
	return true;
}

bool DcsMessageHandler::SendAndDeleteDcsMessage( DcsMessage* pMsg, unsigned int timeout )
{
	//LOG_FINEST1( "sending %s", pMsg->m_pText );
	bool result = SendDcsMessage( pMsg->m_pText, pMsg->m_pBinary, pMsg->m_BinaryBufferSize, timeout );

	DcsMessageManager::GetObject( ).DeleteDcsMessage( pMsg );

	return result;
}
