
#include "log_quick.h"
#include "DhsService.h"
#include "DcsMessageManager.h"

DhsService::DhsService( ):
	m_MsgManager( DcsMessageManager::GetObject( )),
	m_MsgQueue( 100 ),
	m_pInstantMessage(NULL),
	m_pCurrentMessage(NULL),
    m_aborting(false),
    m_pOperationMap(NULL),
    m_numOperation(0),
    m_pStringMap(NULL),
    m_numString(0),
    m_pMotorMap(NULL),
    m_numMotor(0),
    m_pIonChamberMap(NULL),
    m_numIonChamber(0),
    m_pEncoderMap(NULL),
    m_numEncoder(0),
    m_pOperationName(NULL),
    m_pStringName(NULL),
    m_pMotorName(NULL),
    m_pIonChamberName(NULL),
    m_pEncoderName(NULL),
    m_pShutterName(NULL)
{
    xos_semaphore_create( &m_SemMsgQueue, 0 );
}

DhsService::~DhsService( )
{
	stop( );

    xos_semaphore_close( &m_SemMsgQueue );
    
    if (m_pOperationName)  delete []m_pOperationName;
    if (m_pStringName)     delete []m_pStringName;
    if (m_pMotorName)      delete []m_pMotorName;
    if (m_pIonChamberName) delete []m_pIonChamberName;
    if (m_pEncoderName)    delete []m_pEncoderName;
    if (m_pShutterName)    delete []m_pShutterName;
}
//void DhsService::setupFunctionTable( pStandardFunction table[], int num )
//{
//    m_pFunctionTable = table;
//    m_numFunction = num;
//}
void DhsService::setupMapOperation( DeviceMap map[], int num )
{
    m_pOperationMap = map;
    m_numOperation = num;

    if (m_pOperationName) {
        delete []m_pOperationName;
        m_pOperationName = NULL;
    }
    if (m_numOperation > 0) {
        m_pOperationName = new DeviceName[m_numOperation];
		memset( m_pOperationName, 0, m_numOperation * sizeof(DeviceName) );
    }
}
void DhsService::setupMapString( DeviceMap map[], int num )
{
    m_pStringMap = map;
    m_numString = num;

    if (m_pStringName) {
        delete []m_pStringName;
        m_pStringName = NULL;
    }
    if (m_numString > 0) {
        m_pStringName = new DeviceName[m_numString];
		memset( m_pStringName, 0, m_numString * sizeof(DeviceName) );
    }
}
void DhsService::setupMapMotor( DeviceMap map[], int num )
{
    m_pMotorMap = map;
    m_numMotor = num;

    if (m_pMotorName) {
        delete []m_pMotorName;
        m_pMotorName = NULL;
    }
    if (m_numMotor > 0) {
        m_pMotorName = new DeviceName[m_numMotor];
		memset( m_pMotorName, 0, m_numMotor * sizeof(DeviceName) );
    }
}
void DhsService::setupMapEncoder( DeviceMap map[], int num )
{
    m_pEncoderMap = map;
    m_numEncoder = num;

    if (m_pEncoderName) {
        delete []m_pEncoderName;
        m_pEncoderName = NULL;
    }
    if (m_numEncoder > 0) {
        m_pEncoderName = new DeviceName[m_numEncoder];
		memset( m_pEncoderName, 0, m_numEncoder * sizeof(DeviceName) );
    }
}
void DhsService::setupMapIonChamber( DeviceMap map[], int num )
{
    m_pIonChamberMap = map;
    m_numIonChamber = num;

    if (m_pIonChamberName) {
        delete []m_pIonChamberName;
        m_pIonChamberName = NULL;
    }
    if (m_numIonChamber > 0) {
        m_pIonChamberName = new DeviceName[m_numIonChamber];
		memset( m_pIonChamberName, 0, m_numIonChamber * sizeof(DeviceName) );
    }
}
void DhsService::setupMapShutter( DeviceMap map[], int num )
{
    m_pShutterMap = map;
    m_numShutter = num;

    if (m_pShutterName) {
        delete []m_pShutterName;
        m_pShutterName = NULL;
    }
    if (m_numShutter > 0) {
        m_pShutterName = new DeviceName[m_numShutter];
		memset( m_pShutterName, 0, m_numShutter * sizeof(DeviceName) );
    }
}
void DhsService::clearDcsMessagePointer( DcsMessage* &pMsg )
{
    if (pMsg)
    {
        m_MsgManager.DeleteDcsMessage( pMsg );
        pMsg = NULL;
    }
}

void DhsService::start( )
{
    if (m_Status != STOPPED)
	{
		LOG_WARNING( "called start when it is still not in stopped state" );
		return;
	}

    //set status to starting, this may cause broadcase if any one is interested in status change
	SetStatus( STARTTING );

    //reset all flags
    m_CmdStop = FALSE;
    m_CmdReset = FALSE;
    m_FlagEmergency = FALSE;

    xos_thread_create( &m_Thread, Run, this );
}

void DhsService::stop( )
{
    m_CmdStop = TRUE;

    if (m_Status == READY)
    {
        SetStatus( STOPPING );
    }

    //signal threads
    xos_semaphore_post( &m_SemMsgQueue );
}


//this function not used yet
void DhsService::reset( )
{
    DcsMessageManager& theManager = DcsMessageManager::GetObject( );

    DcsMessage* pMsg = NULL;

    if ((pMsg = m_MsgQueue.Dequeue( )) != NULL)
    {
		theManager.DeleteDcsMessage( pMsg );
    }
}

//this is called by other thread:
//we will check the content of the message, if it can be immediately dealt with,
//we send reply directly, otherwise, it will be put in a queue and wait our own
//thread to deal with it.
#define ARRAYLENGTH( a ) (sizeof(a)/sizeof(a[0]))
BOOL DhsService::ConsumeDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST( "+DhsService::ConsumeDcsMessage" );

	//safety check
	if (pMsg == NULL)
	{
		LOG_WARNING( "DhsService::ConsumeDcsMessage called with NULL msg" );
		LOG_FINEST( "-DhsService::ConsumeDcsMessage" );
		return TRUE;
	}

    switch (pMsg->ClassifyMessageType( ))
    {
    case DCS_ABORT_MSG:
        LOG_FINEST("DhsService::ConsumeDcsMessage:: got abort");
        m_aborting = true;
		//clone a abort message and put it into the queue
		//the flag will be cleared when this message got processed.
		//so all messages before this will be aborted.
		if (m_MsgQueue.Enqueue(m_MsgManager.NewCloneMessage( pMsg ))){
			xos_semaphore_post( &m_SemMsgQueue );
		}
		//abort any current function
		Abort( );
		return false;
        
    case DCS_OPERATION_REGISTER_MSG:
    case DCS_ION_CHAMBER_REGISTER_MSG:
    case DCS_REGISTER_STRING_MSG:
    case DCS_REGISTER_REAL_MOTOR_MSG:
    case DCS_REGISTER_PSEUDO_MOTOR_MSG:
    case DCS_REGISTER_ENCODER_MSG:
    case DCS_REGISTER_SHUTTER_MSG:
        LOG_FINEST("Registering device...");
        return registerDevice( pMsg );


    case DCS_OPERATION_START_MSG:
    case DCS_ION_CHAMBER_READ_MSG:
    case DCS_STRING_MSG:
    case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
    case DCS_CONFIGURE_REAL_MOTOR_MSG:
    case DCS_MOVE_MOTOR_MSG:
    case DCS_SET_ENCODER_MSG:
    case DCS_GET_ENCODER_MSG:
    case DCS_SET_SHUTTER_MSG:
        //may enqueu, may immediately execute the function
        LOG_INFO("Handling Message");
        return handleMessage( pMsg );

    case DCS_UNKNOWN_MSG:
    default:
        LOG_WARNING("Unknown message");
    }
    LOG_WARNING("Unknown problem.");
    return FALSE;
}

void DhsService::sendoutDcsMessage( DcsMessage* pMsg )
{
	LOG_FINEST1( "DhsService::sendoutDcsMessage( %s )", pMsg->GetText( ) );

	if (!ProcessEvent( pMsg ))
	{
		m_MsgManager.DeleteDcsMessage( pMsg );
        LOG_SEVERE( "outgoing messae queue full, quit" );
        stop( );
	}
}

void DhsService::ThreadMethod( )
{
	//init the robot
	if (!Initialize( ))
	{
		LOG_SEVERE( "initialization failed. thread quit" );
        SetStatus( STOPPED );
		return;
	}

    SetStatus( READY );

	LOG_INFO( "dhs Thread ready" );

	while (TRUE) {
        m_pCurrentMessage = waitMessageFromQueue( );
        if (m_CmdStop) {
            if (m_FlagEmergency) {
                LOG_INFO( "Dhs thread emergency exit" );
                return;
            }
            LOG_INFO( "dhs thread quit by STOP" );
            break;
        }
        //LOG_FINEST1("Current message address: %X", m_pCurrentMessage);   
        if (m_pCurrentMessage == NULL) {
            Poll( );
            continue;
        }
        int funcIndex = m_pCurrentMessage->m_PrivateFunctionIndex;
        int objIndex = m_pCurrentMessage->m_PrivateData;
        if (m_aborting) {
            replyAborted( m_pCurrentMessage );
        } else {
            forNewMessage( );
            callFunction( funcIndex, objIndex );
        }

        m_MsgManager.DeleteDcsMessage( m_pCurrentMessage );
        m_pCurrentMessage = NULL;
        m_MsgQueue.Dequeue( );
    }
    //clean up before exit
    Cleanup( );

	LOG_INFO( "thread stopped" );
    SetStatus( STOPPED );
}

BOOL DhsService::registerDevice( DcsMessage* pMsg )
{
    LOG_INFO1( "DhsService::registerDevice %s", pMsg->GetText( ) );
    LOG_INFO2( "devicename %s localname %s", pMsg->GetDeviceName( ), pMsg->GetLocalName( ) );
    int total = 0;
    DeviceMap* pMap = NULL;
    DeviceName* pName = NULL;
    bool dummy = false;

    if (!prepareMap( pMsg, total, pMap, pName, dummy ))
    {
        LOG_WARNING( "prepareMap failed" );
        return FALSE;
    }
    LOG_INFO1( "total: %d", total );

    int i = 0;
    for (i = 0; i < total; ++i)
    {
        if (!strncmp( pMsg->GetLocalName( ), pMap[i].m_localName,
        strlen(pMap[i].m_localName) ))
        {
            LOG_INFO2( "register device %s for %s",
            pMsg->GetDeviceName( ), pMsg->GetLocalName( ) );

            strcpy( pName[i], pMsg->GetDeviceName( ) );
            pMsg->m_PrivateData = i;
            pMsg->m_PrivateFunctionIndex = pMap[i].m_indexMethodInit;
            int funcIndex = pMsg->m_PrivateFunctionIndex;
            if (pMap[i].m_immediate)
            {
                LOG_FINEST( "immediate" );
                m_pInstantMessage = pMsg;
                callFunction( funcIndex, i );
                //delete message
                m_MsgManager.DeleteDcsMessage( pMsg );
            }
            else
            {
                enqueueMessage( pMsg );
            }

            if (pMap[i].m_askConfig)
            {
                askConfig( pName[i] );
            }

            return TRUE;
        }
    }
    return FALSE;
}
void DhsService::askConfig( const char* deviceName )
{
    DcsMessage* pAskConfig = m_MsgManager.NewAskConfigMessage( deviceName );
    if (pAskConfig)
    {
        sendoutDcsMessage( pAskConfig );
    }
    else
    {
        LOG_WARNING( "new dcsmessage failed at ask for config" );
    }
    LOG_FINEST1( "%s ask for config", deviceName );
}
BOOL DhsService::enqueueMessage( DcsMessage* pMsg )
{
    BOOL result = m_MsgQueue.WaitEnqueue( pMsg, 1000 );
    //it is OK to post even it failed to put in the message
    xos_semaphore_post( &m_SemMsgQueue );

    return result;
}
BOOL DhsService::handleMessage( DcsMessage* pMsg )
{
    LOG_INFO1( "DEVICENAME: %s", pMsg->GetDeviceName( ) );

    int total = 0;
    DeviceMap* pMap = NULL;
    DeviceName* pName = NULL;
	bool callSecondMethod = false;

    if (!prepareMap( pMsg, total, pMap, pName, callSecondMethod ))
    {
        return FALSE;
    }

    for (int i = 0; i < total; ++i)
    {
        if (!strcmp( pMsg->GetDeviceName( ), pName[i] ))
        {
            LOG_FINEST1( "match %d", i );
            pMsg->m_PrivateData = i;
            if (callSecondMethod)
            {
                pMsg->m_PrivateFunctionIndex = pMap[i].m_indexMethod2;
            }
            else
            {
                pMsg->m_PrivateFunctionIndex = pMap[i].m_indexMethod;
            }
            int funcIndex = pMsg->m_PrivateFunctionIndex;
            if (pMap[i].m_immediate)
            {
                LOG_FINEST( "immediate" );
                m_pInstantMessage = pMsg;
                callFunction( funcIndex, i );
                //delete message
                m_MsgManager.DeleteDcsMessage( pMsg );
            }
            else
            {
                enqueueMessage( pMsg );
            }
            return TRUE;
        }
    }
    LOG_FINEST( "no match for operation, pass on" );
    return FALSE;
}
BOOL DhsService:: prepareMap( const DcsMessage* pMsg,
int& total, DeviceMap* &pMap, DeviceName* &pName, bool& secondMethod ) const
{
    total = 0;
    pMap = NULL;
    pName = NULL;
    secondMethod  = false;

    switch (pMsg->ClassifyMessageType( ))
    {
    case DCS_OPERATION_REGISTER_MSG:
    case DCS_OPERATION_START_MSG:
        total = m_numOperation;
        pMap  = m_pOperationMap;
        pName = m_pOperationName;
        break;

    case DCS_ION_CHAMBER_REGISTER_MSG:
    case DCS_ION_CHAMBER_READ_MSG:
        total = m_numIonChamber;
        pMap  = m_pIonChamberMap;
        pName = m_pIonChamberName;
        break;

    case DCS_REGISTER_STRING_MSG:
    case DCS_STRING_MSG:
        total = m_numString;
        pMap  = m_pStringMap;
        pName = m_pStringName;
        break;

    case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
    case DCS_CONFIGURE_REAL_MOTOR_MSG:
        secondMethod = true;
    case DCS_REGISTER_REAL_MOTOR_MSG:
    case DCS_REGISTER_PSEUDO_MOTOR_MSG:
    case DCS_MOVE_MOTOR_MSG:
        total = m_numMotor;
        pMap  = m_pMotorMap;
        pName = m_pMotorName;
        break;

    case DCS_SET_ENCODER_MSG:
        secondMethod = true;
    case DCS_REGISTER_ENCODER_MSG:
    case DCS_GET_ENCODER_MSG:
        total = m_numEncoder;
        pMap  = m_pEncoderMap;
        pName = m_pEncoderName;
        break;

    case DCS_SET_SHUTTER_MSG:
        secondMethod = true;
    case DCS_REGISTER_SHUTTER_MSG:
        total = m_numShutter;
        pMap  = m_pShutterMap;
        pName = m_pShutterName;
        break;

    default:
        return FALSE;
    }
    return TRUE;
}
DcsMessage* DhsService::waitMessageFromQueue( )
{
    if (xos_semaphore_wait( &m_SemMsgQueue, 1000 ) == XOS_WAIT_TIMEOUT &&
    !m_MsgQueue.IsEmpty( ))
    {
        LOG_WARNING( "message queue not empty while no semaphore posted" );
    }
    if (m_MsgQueue.IsEmpty( ))
    {
        return NULL;
    }
    DcsMessage* result = m_MsgQueue.GetHead( );

    if (result == NULL)
    {
        m_MsgQueue.Dequeue( );
    }
    return result;
}
void DhsService::replyAborted( DcsMessage* pMsg ) {
    if (pMsg == NULL) return;

    switch (pMsg->ClassifyMessageType( ))
    {
    case DCS_ABORT_MSG:
        //this is the end of list before we received abort message
        m_aborting = false;
        break;
    case DCS_OPERATION_START_MSG:
        sendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( 
        pMsg, "aborted" ) );
        break;
    case DCS_ION_CHAMBER_READ_MSG:
        sendoutDcsMessage( m_MsgManager.NewReportIonChamberErrorMessage (
        pMsg, "aborted" ) );
        break;
    case DCS_STRING_MSG:
        sendoutDcsMessage( m_MsgManager.NewStringCompletedMessage (
        pMsg->GetDeviceName( ), "aborted", "aborted" ) );
        break;
    case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
    case DCS_CONFIGURE_REAL_MOTOR_MSG:
    case DCS_MOVE_MOTOR_MSG:
        sendoutDcsMessage( m_MsgManager.NewMotorDoneMessage(
        pMsg->GetDeviceName( ), 0.0, "aborted" ) );
        break;
    case DCS_SET_ENCODER_MSG:
        sendoutDcsMessage( m_MsgManager.NewSetEncoderDoneMessage(
        pMsg->GetDeviceName( ), 0.0, "aborted" ) );
        break;
    case DCS_GET_ENCODER_MSG:
        sendoutDcsMessage( m_MsgManager.NewGetEncoderDoneMessage(
        pMsg->GetDeviceName( ), 0.0, "aborted" ) );
        break;
    default:
        ;
    }
}
bool DhsService::stringRegistered( int index ) const {
    if (index < 0 || index >= m_numString) {
        return false;
    }
    if (m_pStringName[index][0] == '\0') {
        return false;
    }
    return true;
}
bool DhsService::stringRegistered( const char* stringName ) const {
    if (m_numString <= 0) {
        return false;
    }
    for (int i = 0; i < m_numString; ++i) {
        if (!strcmp( m_pStringName[i], stringName) ) {
            return true;
        }
    }

    return false;
}
