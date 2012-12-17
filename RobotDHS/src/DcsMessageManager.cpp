#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

//static instance
DcsMessageManager* DcsMessageManager::stat_pTheSingleObject = NULL;

//constructor
DcsMessageManager::DcsMessageManager( ):
m_MaxTextBufferSize(0),
m_MaxBinaryBufferSize(0),
m_NewCount(0),
m_DeleteCount(0),
m_AllMessageList( MAX_POOLSIZE ),
m_FreeMessageList( MAX_POOLSIZE )
{
	if (stat_pTheSingleObject != NULL)
	{
		throw "only one DcsMessageManager allowed in whole system";
	}

    xos_mutex_create( &m_Lock );

    //populate the pool
	for (int i = 0; i < INIT_POOLSIZE; ++i)
	{
		if (!AddNewMessageToPool( )) break;
	}

	stat_pTheSingleObject = this;
}

DcsMessageManager::~DcsMessageManager(void)
{
	while (!m_AllMessageList.IsEmpty( ))
	{
		DcsMessage* pMsg = m_AllMessageList.RemoveHead( );

		delete pMsg;
	}
    xos_mutex_close( &m_Lock );
}

DcsMessageManager& DcsMessageManager::GetObject( )
{
	if (stat_pTheSingleObject == NULL)
	{
		LOG_WARNING( "please create DcsMessageManager at the beginning of the program" );
		stat_pTheSingleObject = new DcsMessageManager;
	}

	return *stat_pTheSingleObject;
}



//this is a help method only used in SetMessageBuffers
char* DcsMessageManager::AllocateBuffer( unsigned int requiredSize, unsigned int minSize, unsigned int&realSize )
{
	unsigned int newSize = minSize;

	//calculate the new size that will satisfy the requirement
	if (newSize < 1) newSize = 1;

	while (newSize < requiredSize)
	{
		newSize <<= 1;
	}

	//allocate the buffer
	char *pBuffer = new char[newSize];

	if (pBuffer)
	{
		realSize = newSize;
	}

	return pBuffer;
}

bool DcsMessageManager::SetMessageBuffers( DcsMessage& msg, unsigned int textSize, unsigned int binarySize )
{
	if (textSize > msg.m_RealTextBufferSize)
	{
		char* pNewBuffer = AllocateBuffer( textSize, MIN_TEXT_BUFFER_SIZE, msg.m_RealTextBufferSize );

		if (pNewBuffer == NULL) return false;

		//replace buffer
		if (msg.m_pText) delete [] msg.m_pText;
		msg.m_pText = pNewBuffer;
	}

	if (binarySize > msg.m_RealBinaryBufferSize)
	{
		char* pNewBuffer = AllocateBuffer( binarySize, MIN_BINARY_BUFFER_SIZE, msg.m_RealBinaryBufferSize );

		if (pNewBuffer == NULL) return false;

		//replace buffer
		if (msg.m_pBinary) delete [] msg.m_pBinary;
		msg.m_pBinary = pNewBuffer;
	}

	return true;
}

bool DcsMessageManager::AddNewMessageToPool( )
{
	if (m_AllMessageList.GetLength( ) >= m_AllMessageList.GetMaxLength( ))
	{
		return false;
	}

	DcsMessage* pMsg = new DcsMessage( );
	if (pMsg == NULL) return false;

	if (!SetMessageBuffers( *pMsg, MIN_TEXT_BUFFER_SIZE, MIN_BINARY_BUFFER_SIZE ))
	{
		delete pMsg;
		return false;
	}

	//add to the pool
	m_AllMessageList.AddHead( pMsg );
	m_FreeMessageList.AddHead( pMsg );

	return true;
}

DcsMessage* DcsMessageManager::NewDcsMessage(
		unsigned int text_buffer_size,
		unsigned int binary_buffer_size
		)
{
	//lock it
	XOSSingleLock hold_lock( &m_Lock );

	//get msg from free pool, if no more, add one.
	if (m_FreeMessageList.IsEmpty( ) && !AddNewMessageToPool( ))
	{
		LOG_SEVERE( "DcsMessageManager::NewDcsMessage NO SPACE" );
		LOG_INFO3( "spool length=%lu, newed=%lu deleted=%lu",
			GetMaxPoolSize( ), GetNewCount( ), GetDeleteCount( ) );
		return NULL;
	}
	DcsMessage* pMsg = m_FreeMessageList.RemoveHead( );	//we are sure this will not be null

	//adjust message's buffer is necessary
	if (!SetMessageBuffers( *pMsg, text_buffer_size, binary_buffer_size ))
	{
		m_FreeMessageList.AddTail( pMsg );
		LOG_SEVERE( "DcsMessageManager::NewDcsMessage NO BUFFER" );
		return NULL;
	}

	//reset all
	pMsg->Reset( );

	//LOG_FINEST1( "DcsMessageManager::NewDcsMessage return with 0x%p", pMsg );

	//update statistics
	if (text_buffer_size > m_MaxTextBufferSize)
	{
		m_MaxTextBufferSize = text_buffer_size;
		//LOG_FINEST1( "DcsMessageManager::NewDcsMessage: new MAX TEXT SIZE %d\n", m_MaxTextBufferSize );
	}

	if (binary_buffer_size > m_MaxBinaryBufferSize)
	{
		m_MaxBinaryBufferSize = binary_buffer_size;
		//LOG_FINEST1( "DcsMessageManager::NewDcsMessage: new MAX BIN SIZE %d\n", m_MaxBinaryBufferSize );
	}

	++m_NewCount;
	//LOG_FINEST2( "new new=%lu delete=%lu", m_NewCount, m_DeleteCount );
	return pMsg;
}

void DcsMessageManager::DeleteDcsMessage( DcsMessage* pMsg )
{
	if (pMsg == NULL) return;

	//LOG_FINEST1( "DcsMessageManager::DeleteDcsMessage( 0x%p)\n", pMsg );

	//lock it
	XOSSingleLock hold_lock( &m_Lock );

	//safety check
	if (m_AllMessageList.Find( pMsg ) != LIST_ELEMENT_NOT_FOUND &&
		m_FreeMessageList.Find( pMsg ) == LIST_ELEMENT_NOT_FOUND)
	{
		m_FreeMessageList.AddHead( pMsg );
		++m_DeleteCount;
		//LOG_FINEST2( "delete: new=%lu delete=%lu", m_NewCount, m_DeleteCount );
	}
	else
	{
		LOG_WARNING1( "DcsMessageManager::DeleteDcsMessage: BAD address 0x%p", pMsg );
	}
}


DcsMessage* DcsMessageManager::NewOperationReplyMessage( const char tag[], const DcsMessage* pSource, const char status[] )
{
	DcsMessage* pResult = NULL;

    if (!pSource->IsOperation( ))
    {
        LOG_WARNING1( "try to create a operation reply for non operation message %s", pSource->GetText( ) );
        return NULL;
    }

	unsigned int textSize = (unsigned int)(strlen(tag) + 1 + strlen( pSource->GetOperationName( ) ) + 1 
		+ strlen( pSource->GetOperationHandle( ) ) + 1 + strlen( status ) + 1);

	pResult = NewDcsMessage( textSize, 0 );

	if (!pResult) return NULL;

	//LOG_FINEST( "DcsMessageManager::NewOperationReplyMessage" );
	//LOG_FINEST1( "tag =%s", tag );
	//LOG_FINEST2( "operation = NAME:%s, HANDLE:%s", pSource->GetOperationName( ), pSource->GetOperationHandle( ));
	//LOG_FINEST1( "status = %s", status );


	sprintf( pResult->m_pText, "%s %s %s %s",
		tag,
		pSource->GetOperationName( ),
		pSource->GetOperationHandle( ),
		status );

	return pResult;
}
DcsMessage* DcsMessageManager::NewOperationCompletedMessage( const DcsMessage* pSource, const char status[] )
{
	static const char tag[] = "htos_operation_completed";

	return NewOperationReplyMessage( tag, pSource, status );
}

DcsMessage* DcsMessageManager::NewOperationUpdateMessage( const DcsMessage* pSource, const char status[] )
{
	static const char tag[] = "htos_operation_update";

	return NewOperationReplyMessage( tag, pSource, status );
}
DcsMessage* DcsMessageManager::NewStringCompletedMessage( const char name[], const char status[], const char contents[] )
{
	static const char tag[] = "htos_set_string_completed";

	DcsMessage* pResult = NULL;

	unsigned int textSize = (unsigned int)(strlen(tag) + 1 + strlen( name ) + 1 
		+ strlen( status ) + 1 + strlen( contents ) + 1);

	pResult = NewDcsMessage( textSize, 0 );

	if (!pResult) return NULL;

	sprintf( pResult->m_pText, "%s %s %s %s",
		tag,
		name,
		status,
        contents);

    //LOG_FINEST1( "string completed message %s", pResult->m_pText );

	return pResult;
}

DcsMessage* DcsMessageManager::NewClone( const DcsMessage* pSource )
{
	DcsMessage* pResult = NewDcsMessage( pSource->m_TextBufferSize, pSource->m_BinaryBufferSize );

	if (pResult)
	{
		memcpy( pResult->m_pText, pSource->m_pText, pSource->m_TextBufferSize );
		memcpy( pResult->m_pBinary, pSource->m_pBinary, pResult->m_BinaryBufferSize );
	}

	return pResult;
}

DcsMessage* DcsMessageManager::NewAskConfigMessage( const char name[] )
{
	static const char tag[] = "htos_send_configuration ";

	DcsMessage* pResult = NULL;

	unsigned int textSize = (unsigned int)(strlen( tag ) + strlen( name ) + 1);

	pResult = NewDcsMessage( textSize, 0 );

	if (!pResult) return NULL;

	strcpy( pResult->m_pText, tag );
	strcat( pResult->m_pText, name );

	//LOG_FINEST1( "Ask config message: %s", pResult->m_pText );
	return pResult;
}

DcsMessage* DcsMessageManager::NewLog( const char type[], const char sender[], const char contents[] )
{
	static const char tag[] = "htos_log";

	DcsMessage* pResult = NULL;

	unsigned int textSize = (unsigned int)(strlen(tag) + 1 + strlen( type ) + 1 + strlen( sender ) + 1 + strlen( contents ) + 1);

	pResult = NewDcsMessage( textSize, 0 );

	if (!pResult) return NULL;

	sprintf( pResult->m_pText, "%s %s %s %s",
		tag,
		type,
		sender,
        contents);

    //LOG_FINEST1( "log message %s", pResult->m_pText );

	return pResult;
}
