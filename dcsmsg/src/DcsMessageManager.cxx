#include "log_quick.h"
#include "DcsMessage.h"
#include "DcsMessageManager.h"
#include "XOSSingleLock.h"

//static instance
DcsMessageManager* DcsMessageManager::stat_pTheSingleObject = NULL;

//constructor
DcsMessageManager::DcsMessageManager( ):
m_AllMessageList( MAX_POOLSIZE ),
m_FreeMessageList( MAX_POOLSIZE ),
m_MaxTextBufferSize(0),
m_MaxBinaryBufferSize(0),
m_NewCount(0),
m_DeleteCount(0)
{
	LOG_FINEST("DcsMessageManager constructor enter");
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
	LOG_FINEST("DcsMessageManager constructor exit");
}

DcsMessageManager::~DcsMessageManager(void)
{
	LOG_FINEST("+DcsMessageManager destructor");
	while (!m_AllMessageList.IsEmpty( ))
	{
		DcsMessage* pMsg = m_AllMessageList.RemoveHead( );

		delete pMsg;
	}
    xos_mutex_close( &m_Lock );
	LOG_FINEST("-DcsMessageManager destructor");
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
char* DcsMessageManager::AllocateBuffer( size_t requiredSize, size_t minSize, size_t &realSize )
{
	size_t newSize = minSize;

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

bool DcsMessageManager::SetMessageBuffers( DcsMessage& msg, size_t textSize, size_t binarySize )
{
	if (textSize > msg.m_RealTextBufferSize)
	{
		char* pNewBuffer = AllocateBuffer( textSize, MIN_TEXT_BUFFER_SIZE, msg.m_RealTextBufferSize );

		if (pNewBuffer == NULL) return false;

		//replace buffer
		if (msg.m_pText) delete [] msg.m_pText;
		msg.m_pText = pNewBuffer;
	}
    msg.m_TextBufferSize = textSize;

	if (binarySize > msg.m_RealBinaryBufferSize)
	{
		char* pNewBuffer = AllocateBuffer( binarySize, MIN_BINARY_BUFFER_SIZE, msg.m_RealBinaryBufferSize );

		if (pNewBuffer == NULL) return false;

		//replace buffer
		if (msg.m_pBinary) delete [] msg.m_pBinary;
		msg.m_pBinary = pNewBuffer;
	}
    msg.m_BinaryBufferSize = binarySize;

	return true;
}

bool DcsMessageManager::AddNewMessageToPool( )
{
	if (m_AllMessageList.GetLength( ) >= m_AllMessageList.GetMaxLength( ))
	{
        LOG_SEVERE( "allMessageList reached max" );
		return false;
	}

	DcsMessage* pMsg = new DcsMessage( );
	if (pMsg == NULL) {
        LOG_SEVERE( "run out of memory" );
        return false;

    }
	if (!SetMessageBuffers( *pMsg, MIN_TEXT_BUFFER_SIZE, MIN_BINARY_BUFFER_SIZE ))
	{
        LOG_SEVERE( "failed to get min buffer" );
		delete pMsg;
		return false;
	}

	//add to the pool
	m_AllMessageList.AddHead( pMsg );
	m_FreeMessageList.AddHead( pMsg );

	return true;
}

DcsMessage* DcsMessageManager::NewDcsMessage(
		size_t text_buffer_size,
		size_t binary_buffer_size
		)
{
	//lock it
	XOSSingleLock hold_lock( &m_Lock );

	//get msg from free pool, if no more, add one.
	if (m_FreeMessageList.IsEmpty( ) && !AddNewMessageToPool( ))
	{
		LOG_SEVERE( "DcsMessageManager::NewDcsMessage NO SPACE" );
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

	LOG_FINEST1( "DcsMessageManager::NewDcsMessage return with 0x%p", pMsg );

	//update statistics
	if (text_buffer_size > m_MaxTextBufferSize)
	{
		m_MaxTextBufferSize = text_buffer_size;
		LOG_FINEST1( "DcsMessageManager::NewDcsMessage: new MAX TEXT SIZE %d\n", m_MaxTextBufferSize );
	}

	if (binary_buffer_size > m_MaxBinaryBufferSize)
	{
		m_MaxBinaryBufferSize = binary_buffer_size;
		LOG_FINEST1( "DcsMessageManager::NewDcsMessage: new MAX BIN SIZE %d\n", m_MaxBinaryBufferSize );
	}

	++m_NewCount;
	return pMsg;
}

void DcsMessageManager::DeleteDcsMessage( DcsMessage* pMsg )
{
	if (pMsg == NULL) return;

	LOG_FINEST1( "DcsMessageManager::DeleteDcsMessage( 0x%p)\n", pMsg );

	//lock it
	XOSSingleLock hold_lock( &m_Lock );

	//safety check
	if (m_AllMessageList.Find( pMsg ) != LIST_ELEMENT_NOT_FOUND &&
		m_FreeMessageList.Find( pMsg ) == LIST_ELEMENT_NOT_FOUND)
	{
		m_FreeMessageList.AddHead( pMsg );
		++m_DeleteCount;
	}
	else
	{
		LOG_WARNING1( "DcsMessageManager::DeleteDcsMessage: BAD address 0x%p", pMsg );
	}
}


DcsMessage* DcsMessageManager::NewDcsTextMessage( const char *message )
{
   DcsMessage* pResult = NewDcsMessage(strlen(message),0);

   if (!pResult) return NULL;

   sprintf( pResult->m_pText, "%s", message );
   return pResult;
}

DcsMessage* DcsMessageManager::NewCloneMessage( const DcsMessage* pSource )
{
	DcsMessage* pResult = NewDcsMessage( pSource->m_TextBufferSize, pSource->m_BinaryBufferSize );

    if (pResult)
    {
        memcpy( pResult->m_pText, pSource->m_pText, pSource->m_TextBufferSize );
        memcpy( pResult->m_pBinary, pSource->m_pBinary, pSource->m_BinaryBufferSize );

        pResult->SetAttributes( );
    }
    return pResult;
}

DcsMessage* DcsMessageManager::NewOperationReplyMessage( const char tag[], const DcsMessage* pSource, const char status[], const void *pBinary, size_t lBinary )
{
	DcsMessage* pResult = NULL;

	size_t textSize = strlen(tag) + 1 + strlen( pSource->GetOperationName( ) ) + 1 
		+ strlen( pSource->GetOperationHandle( ) ) + 1 + strlen( status ) + 1;

	if (pBinary == NULL) {
		lBinary = 0;
	}
	pResult = NewDcsMessage( textSize, lBinary );

	if (!pResult) return NULL;

	LOG_FINEST( "DcsMessageManager::NewOperationReplyMessage" );
	LOG_FINEST1( "tag =%s", tag );
	LOG_FINEST2( "operation = NAME:%s, HANDLE:%s", pSource->GetOperationName( ), pSource->GetOperationHandle( ));
	LOG_FINEST1( "status = %s", status );


	sprintf( pResult->m_pText, "%s %s %s %s",
		tag,
		pSource->GetOperationName( ),
		pSource->GetOperationHandle( ),
		status );

	if (lBinary > 0) {
		memcpy( pResult->m_pBinary, pBinary, lBinary );
	}

	return pResult;
}
DcsMessage* DcsMessageManager::NewOperationCompletedMessage( const DcsMessage* pSource, const char status[], const void *pBinary , size_t lBinary )
{
	static const char tag[] = "htos_operation_completed";

	return NewOperationReplyMessage( tag, pSource, status, pBinary, lBinary );
}

DcsMessage* DcsMessageManager::NewOperationUpdateMessage( const DcsMessage* pSource, const char status[], const void *pBinary, size_t lBinary )
{
	static const char tag[] = "htos_operation_update";

	return NewOperationReplyMessage( tag, pSource, status, pBinary, lBinary );
}

DcsMessage* DcsMessageManager::NewStringCompletedMessage( const char name[], const char status[], const char contents[] )
{
    static const char tag[] = "htos_set_string_completed";

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
        + strlen( status ) + 1 + strlen( contents ) + 1;

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
DcsMessage* DcsMessageManager::NewAskConfigMessage( const char name[] )
{
	static const char tag[] = "htos_send_configuration ";

	DcsMessage* pResult = NULL;

	size_t textSize = strlen( tag ) + strlen( name ) + 1;

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

    size_t textSize = strlen(tag) + 1 + strlen( type ) + 1 + strlen( sender ) + 1 + strlen( contents ) + 1;

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

DcsMessage* DcsMessageManager::NewShutterReportMessage( const char name[], bool closed, const char* status )
{
    static const char tag[] = "htos_report_shutter_state";
    static const char strOpen[] = "open";
    static const char strClosed[] = "closed";
    const char* pState = closed ? strClosed : strOpen;

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
                    + strlen(pState) + 1;

    size_t lStatus = (status == NULL)? 0 : strlen( status );
    if (lStatus > 0) {
        textSize += lStatus + 1;
    }

    pResult = NewDcsMessage( textSize, 0 );

    if (!pResult) return NULL;

    if (lStatus > 0) {
        sprintf( pResult->m_pText, "%s %s %s %s", tag, name, pState, status );
    } else {
        sprintf( pResult->m_pText, "%s %s %s", tag, name, pState );
    }

    //LOG_FINEST1( "shutter message %s", pResult->m_pText );
    return pResult;
}
DcsMessage* DcsMessageManager::NewMotorStartedMessage( const char name[], double position )
{
    static const char tag[] = "htos_motor_move_started";
    char strPosition[64] = {0};
    sprintf( strPosition, "%.5lf", position );

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
                    + strlen(strPosition) + 1;

    pResult = NewDcsMessage( textSize, 0 );

    if (!pResult) return NULL;

    sprintf( pResult->m_pText, "%s %s %s",
        tag,
        name,
        strPosition );

    //LOG_FINEST1( "motor message %s", pResult->m_pText );
    return pResult;
}
DcsMessage* DcsMessageManager::NewMotorUpdateMessage( const char name[], double position, const char status[] )
{
    static const char tag[] = "htos_update_motor_position";
    return NewMotorMoveMessage( tag, name, position, status );
}
DcsMessage* DcsMessageManager::NewMotorDoneMessage( const char name[], double position, const char status[] )
{
    static const char tag[] = "htos_motor_move_completed";
    return NewMotorMoveMessage( tag, name, position, status );
}
DcsMessage* DcsMessageManager::NewMotorMoveMessage( const char tag[], const char name[], double position, const char* pStatus )
{
    char strPosition[64] = {0};
    sprintf( strPosition, "%.5lf", position );

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
                    + strlen(strPosition) + 1 + strlen( pStatus) + 1;

    pResult = NewDcsMessage( textSize, 0 );

    if (!pResult) return NULL;

    sprintf( pResult->m_pText, "%s %s %s %s",
        tag,
        name,
        strPosition,
        pStatus );

    //LOG_FINEST1( "motor message %s", pResult->m_pText );
    return pResult;
}
DcsMessage* DcsMessageManager::NewPseudoMotorConfigMessage( const char name[], double position, double upperLimit, double lowerLimit, bool upperLimitOn, bool lowerLimitOn, bool motorLocked )
{
    static const char tag[] = "htos_configure_device";

    char strPosition[64] = {0};
    char strUpperLimit[64] = {0};
    char strLowerLimit[64] = {0};
    sprintf( strPosition, "%.5lf", position );
    sprintf( strUpperLimit, "%.5lf", upperLimit );
    sprintf( strLowerLimit, "%.5lf", lowerLimit );

    char cULOn = upperLimitOn ? '1' : '0';
    char cLLOn = lowerLimitOn ? '1' : '0';
    char cML   = motorLocked  ? '1' : '0';

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
                    + strlen( strPosition ) + 1 + strlen( strUpperLimit ) + 1
                    + strlen( strLowerLimit) + 1 + 6;

    pResult = NewDcsMessage( textSize, 0 );

    if (!pResult) return NULL;

    sprintf( pResult->m_pText, "%s %s %s %s %s %c %c %c",
        tag,
        name,
        strPosition,
        strUpperLimit,
        strLowerLimit,
        cLLOn,           //here order is a litte bit strange.
        cULOn,
        cML );

    //LOG_FINEST1( "pseudo motor config message %s", pResult->m_pText );
    return pResult;
}
DcsMessage* DcsMessageManager::NewRealMotorConfigMessage( const char name[], double position, double upperLimit, double lowerLimit, double scaleFactor, int speed, int accel, int backlash, bool upperLimitOn, bool lowerLimitOn, bool motorLocked, bool backlashOn, bool reverseOn )
{
    static const char tag[] = "htos_configure_device";

    char strPosition[64] = {0};
    char strUpperLimit[64] = {0};
    char strLowerLimit[64] = {0};
    char strScaleFactor[64] = {0};
    char strSpeed[64] = {0};
    char strAccel[64] = {0};
    char strBacklash[64] = {0};

    sprintf( strPosition, "%.5lf", position );
    sprintf( strUpperLimit, "%.5lf", upperLimit );
    sprintf( strLowerLimit, "%.5lf", lowerLimit );
    sprintf( strScaleFactor, "%.5lf", scaleFactor );
    sprintf( strSpeed, "%d", speed );
    sprintf( strAccel, "%d", accel );
    sprintf( strBacklash, "%d", backlash );

    char cULOn = upperLimitOn ? '1' : '0';
    char cLLOn = lowerLimitOn ? '1' : '0';
    char cML   = motorLocked  ? '1' : '0';
    char cBLOn = backlashOn  ? '1' : '0';
    char cRVOn = reverseOn  ? '1' : '0';

    DcsMessage* pResult = NULL;

    size_t textSize = strlen(tag) + 1 + strlen( name ) + 1
                    + strlen( strPosition ) + 1 + strlen( strUpperLimit ) + 1
                    + strlen( strLowerLimit) + 1 + strlen( strScaleFactor ) + 1
                    + strlen( strSpeed ) + 1 + strlen( strAccel ) + 1
                    + strlen( strBacklash) + 1 + 10;

    pResult = NewDcsMessage( textSize, 0 );

    if (!pResult) return NULL;

    sprintf( pResult->m_pText, "%s %s %s %s %s %s %s %s %s %c %c %c %c %c",
        tag,
        name,
        strPosition,
        strUpperLimit,
        strLowerLimit,
        strScaleFactor,
        strSpeed,
        strAccel,
        strBacklash,
        cLLOn,           //here order is a litte bit strange.
        cULOn,
        cML,
        cBLOn,
        cRVOn );

    //LOG_FINEST1( "real motor config message %s", pResult->m_pText );
    return pResult;
}
DcsMessage* DcsMessageManager::NewSetEncoderDoneMessage( const char name[], double position, const char status[] )
{
    static const char tag[] = "htos_set_encoder_completed";
    return NewMotorMoveMessage( tag, name, position, status );
}
DcsMessage* DcsMessageManager::NewGetEncoderDoneMessage( const char name[], double position, const char status[] )
{
    static const char tag[] = "htos_get_encoder_completed";
    return NewMotorMoveMessage( tag, name, position, status );
}
DcsMessage* DcsMessageManager::NewReportIonChamberErrorMessage( DcsMessage* pMsg, const char reason[] )
{
    static const char tag[] = "htos_report_ion_chambers 0";
    size_t textSize = strlen(tag) + 1 +
    strlen( pMsg->GetOperationArgument( ) ) + 1 + strlen( reason ) + 1 + 10;

	DcsMessage* pResult = NewDcsMessage( textSize, 0 );
	if (!pResult) return NULL;

    sprintf( pResult->m_pText, "%s %s {%s}",
    tag,
    pMsg->GetOperationArgument( ),
    reason );
    return pResult;
}
