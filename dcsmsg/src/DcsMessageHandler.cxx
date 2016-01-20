#include "log_quick.h"
#include "XosStringUtil.h"
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
}

void DcsMessageHandler::SetServerInfo ( const char blctlServerString[], unsigned short ServerPort )
{
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	if (m_ServerName[0] == '\0')
	{
        const char* hostname = NULL;
        hostname = getenv( "HOSTNAME" );
        if (hostname == NULL) {
            hostname = getenv( "HOST" );
        }
        if (hostname != NULL && !strcmp( blctlServerString, hostname )) {
		    strncpy( m_ServerName, "localhost", MAX_SERVER_NAME_LENGTH );
        } else {
		    strncpy( m_ServerName, blctlServerString, MAX_SERVER_NAME_LENGTH );
        }
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
	if (!ReceiveDcsConnectionMessage( ) || !SendDcsConnectionMessage( ))
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

bool DcsMessageHandler::ReceiveDcsConnectionMessage ( unsigned int timeout )
{
	try {
		char buffer[256]; //must be bigger than CONNECT_MESSAGE_BUFFER_SIZE(200)

		//clear buffer
		memset( buffer, 0, sizeof(buffer) );

		//receive message
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
	LOG_FINEST1( "Sending: '%s'", m_DHSName );

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

DcsMessage* DcsMessageHandler::CreateAndReceiveDcsMessage( unsigned int timeout )
{
    char logBuffer[9999] = {0};
	DcsMessageManager& msgManager = DcsMessageManager::GetObject( );

	DcsMessage* pMsg = NULL;

	//lock it
#ifndef NO_INTERNAL_LOCK
	XOSSingleLock holdMutex( &m_SyncMtx );
#endif
	try
	{
		char msgHeader[DCS_HEADER_SIZE+1];
		size_t textSize;
		size_t binarySize;

		//receive the header
		memset( msgHeader, 0, sizeof(msgHeader) );
		m_sConnect.readFixedLength( msgHeader, DCS_HEADER_SIZE );
        //LOG_FINEST1( "Message->header: '%s'", msgHeader );

		//get text and binary buffer sizes from header
		if (sscanf( msgHeader, "%lu %lu", &textSize, &binarySize ) != 2)
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

			pMsg->m_pText[textSize] = '\0';
            strncpy( logBuffer, pMsg->m_pText, sizeof(logBuffer) - 1 );
            XosStringUtil::maskSessionId( logBuffer );
			LOG_FINEST1( "Receiving: '%s'", logBuffer );
		}

        //receiving binary if any
        if (binarySize)
		{
			m_sConnect.readFixedLength( pMsg->m_pBinary, binarySize );
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
bool DcsMessageHandler::SendDcsMessage (  const char* pText, const void* pBinary, size_t binarySize, unsigned int timeout )
{
	char header[DCS_HEADER_SIZE];
	size_t textSize = strlen( pText ) + 1;

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
	sprintf ( header, "%12lu %12lu", textSize, binarySize );
    try
    {
	    m_sConnect.write( header, DCS_HEADER_SIZE );
	    if (textSize)
	    {
		    m_sConnect.write( pText, (int)textSize );
	    }

	    if (binarySize)
	    {
		    m_sConnect.write( (const char*)pBinary, (int)binarySize );
	    }
    }
	catch ( XosException& pe ) 
	{
        LOG_WARNING1( "WINSOCK ERROR--%s", pe.getMessage( ).c_str( ) );
		m_State = DISCONNECTED;
		return false;
    }
	LOG_FINEST( "send message done\n" );
	return true;
}

bool DcsMessageHandler::SendAndDeleteDcsMessage( DcsMessage* pMsg, unsigned int timeout )
{
	bool result = SendDcsMessage( pMsg->m_pText, pMsg->m_pBinary, pMsg->m_BinaryBufferSize, timeout );

	DcsMessageManager::GetObject( ).DeleteDcsMessage( pMsg );

	return result;
}
