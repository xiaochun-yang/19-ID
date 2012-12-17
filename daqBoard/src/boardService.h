/*******************************************************************\
* FILENAME: boardService.h											*
* CREATED:  8/16/05													*
* AUTHOR:   John O'Keefe											*
* EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com		*
* DESCRIPTION: 														*
* History:															*
* 																	*
* DATE      BY   Ver.   REVISION									*
* ----      --   ----   --------									*
* 08/16/05  JMO  1.00   CREATION									*
\*******************************************************************/
#ifndef boardService_h
#define boardService_h
#include "stdafx.h"
#include "boards.h"
#include "DcsMessageTwoWay.h"
#include "MQueue.h"
#include "DcsMessageManager.h"
#include "DcsMessageService.h"

typedef enum {
    DCS_REGISTER_PSEUDO_MOTOR,
	DCS_CORRECT_MOTOR,
	DCS_MOTOR_MOVE,
	DCS_CONFIGURE_REAL,
	DCS_CONFIGURE_PSEUDO,
	DCS_SET_MOTOR,
	DCS_UNKNOWN_MOTOR
} dcs_motor_message;
typedef enum {
	DCS_REGISTER_STRING,
	DCS_CONFIGURE_STRING,
	DCS_UNKNOWN_STRING
} dcs_string_message;
class DcsMessageManager;
class boardService : public DcsMessageTwoWay {
public: 
	/*public functions**/
	boardService(LPSTR name,int boardNumber );
	BOOL online( ) const { return m_online; }

	virtual ~boardService(void);
	virtual BOOL ConsumeDcsMessage(DcsMessage* pMsg);
	virtual void start();
	virtual void stop();
	virtual void reset();

private:
	/*private functions*/
	static XOS_THREAD_ROUTINE Run(void* pParam){	//this function starts the thread method in its own thread
		boardService* pObj = (boardService*)pParam;
		pObj->ThreadMethod();
        XOS_THREAD_ROUTINE_RETURN;
	}
	BOOL initialize();
	void ThreadMethod();
	void SendoutDcsMessage(DcsMessage* pMsg);
	BOOL HandleKnownOperations(DcsMessage* pMsg);
	void abort(DcsMessage *pMsg);
	int  getBoardNum(DcsMessage* volatile pMsg);
	void setDigitalOutput();
	void pulseDigitalOutput();
	void setDigitalOutputBit();
	void pulseDigitalOutputBit();
	void internalSetDigitalOutput( const char* arg, BOOL fromOperation );
	void readAnalog();
	void getDigitalInput();
	void setAnalogOutput( );
	void internalSetAnalogOutput( const char* arg, BOOL fromOperation, BOOL updateAllMotor );
	void getNumOfDigitalOutputs();
	void getNumOfDigitalInputs();
	void getNumOfAnalogOutputs();
	void getNumOfAnalogInputs();
	BOOL HandleKnownMotors(DcsMessage* pMsg);
	BOOL HandleKnownStrings(DcsMessage* pMsg);
	std::string setLightOutputMotor(int level);
	void getAndSendInputs();
	std::string getDigitalInputs();
	std::string getAnalogInputs();

	BOOL registerOperation(DcsMessage* pMsg);
	BOOL registerString(DcsMessage* pMsg);
	BOOL registerMotor(DcsMessage* pMsg);


private:
	/*private data******/
	BOOL					m_online;
	MQueue					m_MsgQueue;				//boards queue
	boards*					m_pBoard;				//board for this service
	const int				bNum;					//this boards number for method calling
	DcsMessageManager&		m_MsgManager;			
    xos_thread_t			m_Thread;
    xos_semaphore_t			m_SemThreadWait;	//wait for message
	DcsMessage* volatile	m_pCurrentMessage;	//operation that is currently taking place
	DcsMessage* volatile	m_pInstantMessage;	//operation that is taking place if it is an immediate operation

	enum OperationIndex {
		OPERATION_GET_ANALOG_INPUT,
		OPERATION_GET_DIGITAL_INPUT,
		OPERATION_SET_ANALOG_OUTPUT,
		OPERATION_SET_DIGITAL_OUTPUT,
		OPERATION_PULSE_DIGITAL_OUTPUT,
		OPERATION_SET_DIGITAL_OUTPUT_BIT,
		OPERATION_PULSE_DIGITAL_OUTPUT_BIT,
		OPERATION_GET_NUM_ANALOG_INPUT,
		OPERATION_GET_NUM_DIGITAL_INPUT,
		OPERATION_GET_NUM_ANALOG_OUTPUT,
		OPERATION_GET_NUM_DIGITAL_OUTPUT,
		NUM_OPERATION,		//must be last one so it equals the number of operations defined
	};

	enum StringIndex {
		STRING_DI_STATUS,
		STRING_DO_STATUS,
		STRING_AI_STATUS,
		STRING_AO_STATUS,
		NUM_STRING,			//must at end
	};
	enum MotorIndex {
		MOTOR_FIRST,
		MOTOR_SECOND,
		NUM_MOTOR,			//must at end
	};

	static struct OperationToMethod{				//this is how thread method calls the functions
		const char*			m_localName;	
		OperationIndex		m_index;
		bool	            m_Immediately;
		void (boardService::*m_pMethod)();
	} m_OperationMap[];
	struct StringNameStruct {
		const char*         m_localName;
		StringIndex			m_index;
	};
	struct MotorNameStruct {
		const char*         m_localName;
		MotorIndex			m_index;
	};
	static StringNameStruct	m_StringMap[];
	static MotorNameStruct m_MotorMap[];

	char m_operationName[NUM_OPERATION][40];
	char m_stringName[NUM_STRING][40];
	char m_motorName[NUM_MOTOR][40];

	std::string m_previousDIStatus;
	std::string m_previousAIStatus;

	//used to clean up all messages in the queue when abort received:
	//This flag will be set when abort message is received.
	//and it will be cleared after all messages in the queue are popped out
	volatile bool m_inAborting;
};

#endif //ifndef boardService_h