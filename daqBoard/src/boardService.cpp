/*******************************************************************\
* FILENAME: boardService.cpp										*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION:														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#include "boardService.h"
#include "daqBoard1000.h"//included for getBoards
#include "boardSystem.h" //included for abort
extern 	boardSystem *syst;
/*public functions**/
/***********************************\
* this is the list of functions		*
* that can be called. immediate is	*
* a flag that lets handle known		*
* operations if it is to be called	*
* immediately or put in the queue.	*
* immediate should only be true if	*
* then function does not call or	*
* depend on the hardware. the first *
* column is the name blu-ice calls	*
* it by.  The third column is the	*
* functions name					*
\***********************************/

//all boards share the same operation names
//because they share the sample name, you should not eat the register messages.
//we may change the mapping to individual board has its own operations in the future if needed.
boardService::OperationToMethod boardService::m_OperationMap[] = {
	{"GET_AI",		OPERATION_GET_ANALOG_INPUT,			FALSE,  &boardService::readAnalog},
	{"GET_DI",		OPERATION_GET_DIGITAL_INPUT,		FALSE,	&boardService::getDigitalInput},
	{"SET_AO",		OPERATION_SET_ANALOG_OUTPUT,		FALSE,  &boardService::setAnalogOutput},
	{"SET_DO",		OPERATION_SET_DIGITAL_OUTPUT,		FALSE,  &boardService::setDigitalOutput},
	{"PULSE_DO",	OPERATION_PULSE_DIGITAL_OUTPUT,		FALSE,  &boardService::pulseDigitalOutput},
	{"SET_DO_BIT",	OPERATION_SET_DIGITAL_OUTPUT_BIT,	FALSE,  &boardService::setDigitalOutputBit},
	{"PULSE_DO_BIT",OPERATION_PULSE_DIGITAL_OUTPUT_BIT,	FALSE,  &boardService::pulseDigitalOutputBit},
	{"GET_NUM_AI",	OPERATION_GET_NUM_ANALOG_INPUT,		TRUE,	&boardService::getNumOfAnalogInputs},
	{"GET_NUM_DI",	OPERATION_GET_NUM_DIGITAL_INPUT,	TRUE,	&boardService::getNumOfDigitalInputs},
	{"GET_NUM_AO",	OPERATION_GET_NUM_ANALOG_OUTPUT,	TRUE,	&boardService::getNumOfAnalogOutputs},
	{"GET_NUM_DO",	OPERATION_GET_NUM_DIGITAL_OUTPUT,	TRUE,	&boardService::getNumOfDigitalOutputs},
	//  name,				immediately,	 method to call
};

//these are just prefix for the string names, board number will be appended to them
//for example, DISTATUS0 is for board 0, DISTATUS1 is for board 1
boardService::StringNameStruct boardService::m_StringMap[] = {
	{"DISTATUS",		STRING_DI_STATUS},
	{"DOSTATUS",        STRING_DO_STATUS},
	{"AISTATUS",        STRING_AI_STATUS},
	{"AOSTATUS",        STRING_AO_STATUS},
};
//these are just prefix for the motor names, board number will be appended to them
//here we did not use MAO0 MAO1 because they are confusing when you append 
//board number to them: MAO00, MAO10 are for board 0, MAO01, MAO11 are for board 1
boardService::MotorNameStruct boardService::m_MotorMap[] = {
	{"MFIRST",			MOTOR_FIRST},
	{"MSECOND",			MOTOR_SECOND},
};

boardService::boardService(LPSTR name,int boardNumber ):
bNum(boardNumber),
m_online(FALSE),
m_pBoard(NULL),
m_MsgQueue(0),
m_MsgManager(DcsMessageManager::GetObject()),
m_pCurrentMessage(NULL),
m_pInstantMessage(NULL),
m_inAborting(false)
{
	LOG_FINE("In boardService::boardService\n");
	LOG_INFO1("My Board number is %d",bNum);

    xos_semaphore_create(&m_SemThreadWait, 0);

	memset( m_operationName, 0, sizeof(m_operationName) );
	memset( m_stringName, 0, sizeof(m_stringName) );
	memset( m_motorName, 0, sizeof(m_motorName) );

	m_pBoard = new daqBoard1000(name, boardNumber );
	if (m_pBoard) {
		m_online = m_pBoard->online( );
	}

	LOG_FINE("Leaving boardService::boardService\n");
}
boardService::~boardService(){
	if (m_pBoard)
	{
		delete m_pBoard;
	}
	xos_semaphore_close(&m_SemThreadWait);
}
void boardService::stop(){
	if(!m_CmdStop){
		LOG_INFO("In boardService::stop");
		m_CmdStop = TRUE;
		xos_semaphore_post( &m_SemThreadWait );

	}
}
void boardService::start(){
	if (m_Status != STOPPED){
		LOG_WARNING("called start when it is still not in stopped state");
		return;
	}
	m_CmdStop		= FALSE;
	m_CmdReset		= FALSE;
	m_FlagEmergency = FALSE;
	xos_thread_create(&m_Thread, Run, this);
}
void boardService::reset(){
	m_MsgQueue.Clear();
	m_pBoard->abortAll(true);//true means it is reset and not abort
}
/***********************************\
* Consume message is called by the	*
* dcs.  It checks what kind of		*
* message it is and if it belongs	*
* to this board.  If it does, it	*
* sends it to HandleKnownOperations	*
* otherwise it lets the message		*
* pass through to the next board	*
* service							*
\***********************************/
BOOL boardService::ConsumeDcsMessage(DcsMessage * pMsg){
	LOG_FINEST1("+boardService::ConsumeDcsMessage  %d",bNum);
	if (pMsg == NULL){
		LOG_WARNING("boardService::ConsumeDcsMessage called with NULL msg");
		LOG_FINEST("-boardService::ConsumeDcsMessage");
		return TRUE;
	}
	switch (pMsg->ClassifyMessageType()){//this only classifies operations it does not classify motors or other server messages.
		case DCS_OPERATION_START_MSG:
			int commands_bNum;
			if((commands_bNum = getBoardNum(pMsg)) == bNum){	
				LOG_INFO1("In boardService::DCS_OPERATION_START_MSG for board %d", bNum );
				return HandleKnownOperations(pMsg);
			}
			return false;

		case DCS_ABORT_MSG:
			LOG_FINEST("-boardService::ConsumeDcsMessage: abort unfinished operations");
			//set the flag
			m_inAborting = true;
			//clone a abort message and put it into the queue
			//the flag will be cleared when this message got processed.
			//so all messages before this will be aborted.
			if (m_MsgQueue.Enqueue(m_MsgManager.NewCloneMessage( pMsg ))){
				xos_semaphore_post( &m_SemThreadWait );
				m_pInstantMessage = NULL;
			}
			//abort any current operation
			abort(pMsg);
			return false;

		case DCS_OPERATION_REGISTER_MSG:
			return registerOperation( pMsg );

		case DCS_REGISTER_PSEUDO_MOTOR_MSG:
			return registerMotor( pMsg );

		case DCS_MOVE_MOTOR_MSG:
		case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
			return HandleKnownMotors(pMsg);

		case DCS_REGISTER_STRING_MSG:
			return registerString( pMsg );

		case DCS_STRING_MSG:
			return HandleKnownStrings(pMsg);

		case DCS_UNKNOWN_MSG:
		default:
			LOG_INFO("In boardService::default\n");
			break;
	}
	LOG_FINEST("-boardService::ConsumeDcsMessage: not a message for that can be handled, pass on");
	return FALSE;
}

/***********************************\
* HandleKnownMotors takes the		*
* the message and finds out what	*
* type of motorMove it is. currently*
* their is only one motor the light	*
* motor								*
\***********************************/
BOOL boardService::HandleKnownMotors( DcsMessage *pMsg ) {
	m_pInstantMessage = pMsg;
	for (int i = 0; i < NUM_MOTOR; ++i)
	{
		if (!strcmp( m_motorName[i], pMsg->GetMotorName( ) ))
		{
			LOG_FINEST1("match motor%d", i);
			m_pInstantMessage->m_PrivateData = i;
			if (m_MsgQueue.Enqueue(m_pInstantMessage)){
				xos_semaphore_post( &m_SemThreadWait );
				m_pInstantMessage = NULL;
			}
			else
			{//should not get here unless the queues are set to have a limit m_MsgQueue(0) means no limit
				char status_buffer[128] = "busy";
				if (m_pCurrentMessage){
					strcat(status_buffer, "doing ");
					strcat(status_buffer, m_pCurrentMessage->GetOperationName());
					strcat(status_buffer, " ");
					strcat(status_buffer, m_pCurrentMessage->GetOperationHandle());
				}
				LOG_FINEST1("%s",status_buffer);
				DcsMessage* pReply = m_MsgManager.NewMotorDoneMessage( pMsg->GetMotorName( ), 0.0, status_buffer );
				if (pReply == NULL) {
					LOG_WARNING( "dcs msg mgr returned null msg at busy status" );
				}
				SendoutDcsMessage(pReply);
			}
			if (m_pInstantMessage) 
				m_MsgManager.DeleteDcsMessage(m_pInstantMessage);
			LOG_FINEST("-boardService::ConsumeDcsMessage: we consume it");
			return TRUE;
		}//if !strcmp
	}//for int i
	return false;
}
BOOL boardService::HandleKnownStrings(DcsMessage* pMsg){
	m_pInstantMessage = pMsg;
	for (int i = 0; i < NUM_STRING; ++i)
	{
		if (!strcmp( m_stringName[i], pMsg->GetStringName( ) ))
		{
			LOG_FINEST1("match string%d", i);
			m_pInstantMessage->m_PrivateData = i;
			if (m_MsgQueue.Enqueue(m_pInstantMessage)){
				xos_semaphore_post( &m_SemThreadWait );
				m_pInstantMessage = NULL;
			}
			else
			{//should not get here unless the queues are set to have a limit m_MsgQueue(0) means no limit
				char status_buffer[128] = "busy";
				if (m_pCurrentMessage){
					strcat(status_buffer, "doing ");
					strcat(status_buffer, m_pCurrentMessage->GetOperationName());
					strcat(status_buffer, " ");
					strcat(status_buffer, m_pCurrentMessage->GetOperationHandle());
				}
				LOG_FINEST1("%s",status_buffer);
				DcsMessage* pReply = m_MsgManager.NewMotorDoneMessage( pMsg->GetMotorName( ), 0.0, status_buffer );
				if (pReply == NULL) {
					LOG_WARNING( "dcs msg mgr returned null msg at busy status for string handling" );
				}
				SendoutDcsMessage(pReply);
			}
			if (m_pInstantMessage) 
				m_MsgManager.DeleteDcsMessage(m_pInstantMessage);
			LOG_FINEST("-boardService::ConsumeDcsMessage: we consume it");
			return TRUE;
		}//if !strcmp
	}//for int i
	return false;

	return false;
}
/***********************************\
* handle knownoperations takes the	*
* message and finds outs which one	*
* it is.  if it is a recognized		*
* operation it will check to see if	*
* it needs to be done immediately	*
* or if it is to be put in the		*
* queue.  If it is immediate then	*
* it starts the operation otherwise *
* puts the message into the queue	*
* for thread method to pick up		*
\***********************************/
BOOL boardService::HandleKnownOperations(DcsMessage* pMsg) {
	m_pInstantMessage = pMsg;
	LOG_INFO1("OPNAME: %s\n", m_pInstantMessage->GetOperationName());
	for (int i = 0; i < NUM_OPERATION; ++i) {
		if (!strcmp(m_pInstantMessage->GetOperationName(), m_operationName[i])){
			LOG_FINEST1("match operation%d", i);
			m_pInstantMessage->m_PrivateData = i;
			if (m_OperationMap[i].m_Immediately){
				LOG_FINEST("immediately");
				(this->*m_OperationMap[i].m_pMethod)();
			}
			else{
				if (m_MsgQueue.Enqueue(m_pInstantMessage)){
					xos_semaphore_post( &m_SemThreadWait );
					m_pInstantMessage = NULL;
				}
				else{//should not get here unless the queues are set to have a limit m_MsgQueue(0) means no limit
					char status_buffer[MAX_OPERATION_HANDLE_LENGTH + 11] = "busy";
					if (m_pCurrentMessage){
						strcat(status_buffer, "doing ");
						strcat(status_buffer, m_pCurrentMessage->GetOperationName());
						strcat(status_buffer, " ");
						strcat(status_buffer, m_pCurrentMessage->GetOperationHandle());
					}
					LOG_FINEST1("%s",status_buffer);
					DcsMessage* pReply = m_MsgManager.NewOperationCompletedMessage(m_pInstantMessage, status_buffer);
					if (pReply == NULL) {
						LOG_WARNING( "dcs msg mgr returned null msg at busy status for operation" );
					}
					SendoutDcsMessage(pReply);
				}
			}
			if (m_pInstantMessage) 
				m_MsgManager.DeleteDcsMessage(m_pInstantMessage);
			LOG_FINEST("-boardService::ConsumeDcsMessage: we consume it");
			return TRUE;
		} 
	}
	return FALSE;
}
/***********************************\
* sendoutDcsMessage sends the given	*
* message out to anyone who is		*
* listening.  The dcs is who picks	*
* it up and it procces the message	*
\***********************************/
void boardService::SendoutDcsMessage(DcsMessage* pMsg){
	if (pMsg == NULL) {
		LOG_SEVERE( "null msg to send to dcss" );
		return;
	}

	LOG_FINEST1("boardService::SendoutDcsMessage(%s)", pMsg->GetText());
	if (!ProcessEvent(pMsg)){
		LOG_INFO1("clientService: no one listening to this message, delete it: %s", pMsg->GetText());
		m_MsgManager.DeleteDcsMessage(pMsg);
	}
}
/***********************************\
* intializes the board that is		*
* connected to this service			*
\***********************************/
BOOL boardService::initialize(){
	return m_pBoard->initialize();
}
std::string boardService::getAnalogInputs(){
	const char arg[] = "0";
	return m_pBoard->readAnalog( arg );
}
std::string boardService::getDigitalInputs(){
	const char arg[] = "0";

	return m_pBoard->getDigitalInput( arg );
}
void boardService::getAndSendInputs(){
	if (m_stringName[STRING_DI_STATUS][0] != 0)
	{
		std::string DIO = getDigitalInputs();

		if (m_previousDIStatus != DIO)
		{
			m_previousDIStatus = DIO;
			if (strncmp( DIO.c_str(), "normal", 6))
			{
				SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage( m_stringName[STRING_DI_STATUS],"error", DIO.c_str()));
			}
			else
			{
				SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage( m_stringName[STRING_DI_STATUS],"normal", DIO.c_str() + 7));
			}
		}
	}
	if (m_stringName[STRING_AI_STATUS][0] != 0)
	{
		std::string AIO = getAnalogInputs();
		if (m_previousAIStatus != AIO)
		{
			m_previousAIStatus = AIO;
			if (strncmp( AIO.c_str( ), "normal", 6))
			{
				SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage( m_stringName[STRING_AI_STATUS],"error",AIO.c_str()));
			}
			else
			{
				SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage( m_stringName[STRING_AI_STATUS],"normal",AIO.c_str()+ 7));
			}
		}
	}
}
/***********************************\
* threadMethod is what starts the	*
* functions when a message is		*
* enqueued in handleKnownOperations	*
* it wakes up this method.  This	*
* method then calls the particular	*
* method that was enqueued			*
\***********************************/
void boardService::ThreadMethod(){
	if (m_pBoard == NULL || !initialize()){
		LOG_SEVERE("board initialization failed. thread quit");
		return;
	}
	LOG_INFO("Board Thread ready");
	while (TRUE){
		switch (xos_semaphore_wait( &m_SemThreadWait, 1000 ))
		{
        case XOS_WAIT_TIMEOUT:
		    if (!m_MsgQueue.IsEmpty( ))
		    {
			    LOG_WARNING( "message queue not empty while no semaphore posted" );
		    }
            break;

        case XOS_WAIT_SUCCESS:
        case XOS_WAIT_FAILURE:
        default:
			;
        }

		//LOG_FINEST("Board thread out of waiting");
		m_pBoard->clearAbort( );
		if (m_CmdStop){
			if (m_FlagEmergency){
				LOG_INFO("Board thread emergency exit");
				return;
			}
			else{
				LOG_INFO("Board thread quit by STOP");
				break;
			}
		}
		if (m_MsgQueue.IsEmpty()){
			getAndSendInputs();
			continue;
		}
		m_pCurrentMessage = m_MsgQueue.GetHead();
		if (m_pCurrentMessage == NULL){
			m_MsgQueue.Dequeue();
			LOG_INFO("Message got Dequeued in boardService::ThreadMethod\n");
			continue;
		}
		switch (m_pCurrentMessage->ClassifyMessageType( ))
		{
		case DCS_ABORT_MSG:
			m_inAborting = false;
			break;

	 	case DCS_OPERATION_START_MSG:
			if (m_inAborting)
			{
				SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, "aborted" ) );
			}
			else if (m_pCurrentMessage->m_PrivateData >= 0 && m_pCurrentMessage->m_PrivateData < NUM_OPERATION){
				LOG_INFO("IN boardService::ThreadMethod starting method\n");
				(this->*m_OperationMap[m_pCurrentMessage->m_PrivateData].m_pMethod)();
			}
			else {
				LOG_WARNING("BoardService::ThreadMethod: should never be here, the match was done before it was put into queue\n");
			}
			break;

		case DCS_MOVE_MOTOR_MSG:
		case DCS_CONFIGURE_PSEUDO_MOTOR_MSG:
			if (m_pCurrentMessage->m_PrivateData >= 0 && m_pCurrentMessage->m_PrivateData < NUM_MOTOR)
			{
				if (m_inAborting)
				{
					SendoutDcsMessage( 
						m_MsgManager.NewMotorDoneMessage( m_pCurrentMessage->GetMotorName( ),
						m_pBoard->readSingleAnalogOutput( m_pCurrentMessage->m_PrivateData ), "aborted" ));
				}
				else
				{
					//construct an argument like operation is send
					char arg[128] = {0};
					sprintf( arg, "%d %d %lf", bNum, m_pCurrentMessage->m_PrivateData, m_pCurrentMessage->GetMotorPosition( ) );
					internalSetAnalogOutput( arg, FALSE, FALSE );
				}
			}
			break;

		case DCS_STRING_MSG:
			//string is easy to abort, DCSS only update contents when status is "normal"
			if (m_inAborting)
			{
				SendoutDcsMessage( m_MsgManager.NewStringCompletedMessage( m_pCurrentMessage->GetStringName( ), "aborted", "aborted" ) );
				break;
			}

			switch (m_pCurrentMessage->m_PrivateData)
			{
			case STRING_DO_STATUS:
				{
					DWORD output = 0;
					const char* contents = m_pCurrentMessage->GetStringContents( );
					size_t ll = strlen( contents );
					int index = 0;
					for (size_t i = 0; i < ll; ++i)
					{
						switch (contents[i])
						{
						case '1':
							output |= 1 << index;
						case '0':
							++index;
						case ' ':
							;
						}
					}
					char arg[128] = {0};
					sprintf( arg, "%d %lu 65535", bNum, output );
					internalSetDigitalOutput( arg, FALSE );
				}
				break;

			case STRING_AO_STATUS:
				{
					double pos[2] = {0};
					if (sscanf( m_pCurrentMessage->GetStringContents( ), "%lf %lf", &pos[0], &pos[1] ) == 2)
					{
						//construct an argument like operation is send
						//only update string and motors after both of them are updated.
						char arg[128] = {0};
						sprintf( arg, "%d %d %lf", bNum, 0, pos[0] );
						m_pBoard->setAnalogOutput( arg );

						sprintf( arg, "%d %d %lf", bNum, 1, pos[1] );
						internalSetAnalogOutput( arg, FALSE, TRUE );
					}
				}
				break;

			default:
				; //ignore
			}
			break;

		default:
			LOG_WARNING1( "strange unsupported message in queue: %s", m_pCurrentMessage->GetText( ) );
			break;
		}
		m_MsgManager.DeleteDcsMessage( m_pCurrentMessage );
		DcsMessage* pTmp = m_MsgQueue.Dequeue();
		if (m_pCurrentMessage != pTmp) {
			LOG_WARNING2( "bad msg point from dequeue %p != %p", m_pCurrentMessage, pTmp );
		}
		m_pCurrentMessage = NULL;
	}
	LOG_INFO("Board thread stopped and EvtStopped set");
}
/***********************************\
* abort tells the board to abort	*
* it then stops itself and and		*
* tells the boardSystem to stop as	*
* well.  The boardSystem will only	*
* listen to one stop and just		*
* ignore the rest					*
\***********************************/
void boardService::abort(DcsMessage *pMsg){
	m_pBoard->abortAll(false);
	LOG_INFO1("ABORTING ALL FOR BOARD NUMBER %d",bNum);
}
/***********************************\
* getBoardNum gets the board number	*
* from each operation that this		*
* service consumes.  consume will	*
* compare it to its own board		*
* number and decide if this message	*
* belongs to it						*
\***********************************/
int  boardService::getBoardNum(DcsMessage* volatile pMsg){
	int num = -1;
	int numArg = sscanf(pMsg->GetOperationArgument(),"%d",&num);
	if(numArg!=1){
		m_pInstantMessage =NULL;
		SendoutDcsMessage(m_MsgManager.NewOperationCompletedMessage(pMsg, "error Board Number must follow  the command"));
		return -1;
	}
	return num;
}
void boardService::setDigitalOutput()
{
	internalSetDigitalOutput( m_pCurrentMessage->GetOperationArgument(), TRUE );
}

void boardService::pulseDigitalOutput()
{
	std::string result = m_pBoard->pulseDigitalOutput( m_pCurrentMessage->GetOperationArgument());
	SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );

	std::string readback = m_pBoard->readDigitalOutput( );
	if (m_stringName[STRING_DO_STATUS][0] != 0)
	{
		SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage(m_stringName[STRING_DO_STATUS],"normal",readback.c_str()));
	}
}

void boardService::setDigitalOutputBit()
{
	std::string result = m_pBoard->setDigitalOutputBit( m_pCurrentMessage->GetOperationArgument());
	SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );

	std::string readback = m_pBoard->readDigitalOutput( );
	if (m_stringName[STRING_DO_STATUS][0] != 0)
	{
		SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage(m_stringName[STRING_DO_STATUS],"normal",readback.c_str()));
	}
}


void boardService::pulseDigitalOutputBit()
{
	std::string result = m_pBoard->pulseDigitalOutputBit( m_pCurrentMessage->GetOperationArgument());
	SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );

	std::string readback = m_pBoard->readDigitalOutput( );
	if (m_stringName[STRING_DO_STATUS][0] != 0)
	{
		SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage(m_stringName[STRING_DO_STATUS],"normal",readback.c_str()));
	}
}


void boardService::internalSetDigitalOutput( const char* arg, BOOL fromOperation )
{
	if (fromOperation)
	{
		std::string result = m_pBoard->setDigitalOutput( arg );
		SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );
	}
	else
	{
		m_pBoard->setDigitalOutput( arg );
	}

	std::string readback = m_pBoard->readDigitalOutput( );

	if (m_stringName[STRING_DO_STATUS][0] != 0)
	{
		SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage(m_stringName[STRING_DO_STATUS],"normal",readback.c_str()));
	}

}
void boardService::readAnalog(){
	std::string result = m_pBoard->readAnalog( m_pCurrentMessage->GetOperationArgument());
	SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );
}
void boardService::getDigitalInput(){
	std::string result = m_pBoard->getDigitalInput( m_pCurrentMessage->GetOperationArgument());
	SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );
}
void boardService::setAnalogOutput( ){
	const char *arg = m_pCurrentMessage->GetOperationArgument();
	internalSetAnalogOutput( arg, TRUE, FALSE );
}
void boardService::internalSetAnalogOutput( const char* arg, BOOL fromOperation, BOOL updateAllMotor )
{
	int brdNum  = -1;
	int channel = -1;
	float volts = -1;
	sscanf(arg,"%d %d %f",&brdNum,&channel, &volts);
	if (fromOperation)
	{
		std::string result = m_pBoard->setAnalogOutput( arg );
		SendoutDcsMessage( m_MsgManager.NewOperationCompletedMessage( m_pCurrentMessage, result.c_str( ) ) );
	}
	else
	{
		m_pBoard->setAnalogOutput( arg );
	}

	std::string readback = m_pBoard->readAnalogOutput( );

	if (m_stringName[STRING_AO_STATUS][0] != 0)
	{
		SendoutDcsMessage(m_MsgManager.NewStringCompletedMessage(m_stringName[STRING_AO_STATUS],"normal",readback.c_str()));
	}

	for (int i = 0; i < NUM_MOTOR; ++i)
	{
		if (!updateAllMotor && i != channel) continue;

		if (m_motorName[i][0] != 0)
		{
			std::string format = "";
			if (i > 0)
			{
				format += "%*f ";
			}
			format += "%lf";
			double pos = 0.0;
			if (sscanf( readback.c_str( ), format.c_str( ), &pos ) == 1)
			{
				SendoutDcsMessage(m_MsgManager.NewMotorDoneMessage( m_motorName[i], pos, "normal" ) );
			}
		}
	}
}
/*instant functions no call to the hardware*\
* getNumOfDigitalOutputs,					*
* getNumOfDigitalInputs,					*
* getNumOfAnalogOutputs,					*
* getNumOfAnalogInputs	is a group of		*
* functions that is called immediately		*
* by handleKnownOperations it immediately	*
* calls the board and gets the requested	*
* information.  Hardware is	not involved	*
* at all.  the information is then returned	*
* to the dcss								*
\*******************************************/
void boardService::getNumOfDigitalOutputs(){
	std::string result = m_pBoard->getNumOfDigitalOutputs();
	SendoutDcsMessage(m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage,result.c_str()));
}
void boardService::getNumOfDigitalInputs(){
	std::string result = m_pBoard->getNumOfDigitalInputs();
	SendoutDcsMessage(m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage,result.c_str()));
}
void boardService::getNumOfAnalogOutputs(){
	std::string result = m_pBoard->getNumOfAnalogOutputs();
	SendoutDcsMessage(m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage,result.c_str()));
}
void boardService::getNumOfAnalogInputs(){
	std::string result = m_pBoard->getNumOfAnalogInputs();
	SendoutDcsMessage(m_MsgManager.NewOperationCompletedMessage( m_pInstantMessage,result.c_str()));
}

BOOL boardService::registerOperation(DcsMessage* pMsg)
{
	for (unsigned int i = 0; i < sizeof(m_OperationMap)/sizeof(m_OperationMap[0]); ++i){
		//size_t name_length = strlen(m_OperationMap[i].m_localName);
		if (!strcmp( pMsg->GetLocalName( ), m_OperationMap[i].m_localName ))
		{
			LOG_INFO2( "register operation %s for %s", pMsg->GetOperationName( ), pMsg->GetLocalName( ) );
			strcpy( m_operationName[m_OperationMap[i].m_index], pMsg->GetOperationName( ) );
		}
	}
	return FALSE;
}


BOOL boardService::registerString(DcsMessage* pMsg)
{
	for (unsigned int i = 0; i < sizeof(m_StringMap)/sizeof(m_StringMap[0]); ++i){
		size_t name_length = strlen(m_StringMap[i].m_localName);
		if (!strncmp( pMsg->GetLocalName( ), m_StringMap[i].m_localName, name_length ))
		{
			//get board number
			int boardnum_ = -1;
			sscanf( pMsg->GetLocalName( ) + name_length, "%d", &boardnum_ );
			if (boardnum_ == bNum)
			{
				LOG_INFO2( "register string %s for %s", pMsg->GetStringName( ), pMsg->GetLocalName( ) );
				strcpy( m_stringName[m_StringMap[i].m_index], pMsg->GetStringName( ) );

				//ask for config so that we can restore the output
				if (i == STRING_DO_STATUS || i == STRING_AO_STATUS)
				{
					SendoutDcsMessage( m_MsgManager.NewAskConfigMessage( pMsg->GetStringName( ) ) );
				}

				m_MsgManager.DeleteDcsMessage( pMsg );
				return TRUE;
			}
		}
	}
	return FALSE;
}
BOOL boardService::registerMotor(DcsMessage* pMsg)
{
	for (unsigned int i = 0; i < sizeof(m_MotorMap)/sizeof(m_MotorMap[0]); ++i){
		size_t name_length = strlen(m_MotorMap[i].m_localName);
		if (!strncmp( pMsg->GetLocalName( ), m_MotorMap[i].m_localName, name_length ))
		{
			//get board number
			int boardnum_ = -1;
			sscanf( pMsg->GetLocalName( ) + name_length, "%d", &boardnum_ );
			if (boardnum_ == bNum)
			{
				LOG_INFO2( "register motor %s for %s", pMsg->GetMotorName( ), pMsg->GetLocalName( ) );
				strcpy( m_motorName[m_MotorMap[i].m_index], pMsg->GetMotorName( ) );
				m_MsgManager.DeleteDcsMessage( pMsg );
				return TRUE;
			}
		}
	}
	return FALSE;
}
