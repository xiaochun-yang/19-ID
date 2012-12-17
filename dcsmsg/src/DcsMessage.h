#ifndef __XOS_DCS_MESSAGE_H__
#define __XOS_DCS_MESSAGE_H__

#include <string.h>

#define DCS_HEADER_SIZE 26

#define MAX_OBJECT_NAME_LENGTH 127
#define MAX_OPERATION_HANDLE_LENGTH 127
#define MAX_STRING_NAME_LENGTH 127


typedef enum 
{
    DCS_ABORT_MSG,
    // operation messages
    DCS_OPERATION_REGISTER_MSG,
    DCS_OPERATION_START_MSG,
    DCS_ION_CHAMBER_REGISTER_MSG,
    DCS_ION_CHAMBER_READ_MSG,

    //string
    DCS_REGISTER_STRING_MSG,
    DCS_STRING_MSG, //config or set

    //motor
    DCS_REGISTER_REAL_MOTOR_MSG,
    DCS_REGISTER_PSEUDO_MOTOR_MSG,
    DCS_CONFIGURE_PSEUDO_MOTOR_MSG,
    DCS_CONFIGURE_REAL_MOTOR_MSG,
    DCS_MOVE_MOTOR_MSG,

    //encoder
    DCS_REGISTER_ENCODER_MSG,
    DCS_SET_ENCODER_MSG,
    DCS_GET_ENCODER_MSG,

    //shutter
    DCS_REGISTER_SHUTTER_MSG,
    DCS_SET_SHUTTER_MSG,

    DCS_UNKNOWN_MSG
} dcs_message_id_t;


class  DcsMessage{
public:
    //will be remove next version
	bool IsOperation( ) const { return (m_type == DCS_OPERATION_START_MSG); }
	bool IsAbortAll( ) const { return m_type == DCS_ABORT_MSG; }
    bool IsString( ) const { return (m_type == DCS_STRING_MSG); }
	const char* GetOperationName( ) const { return m_ObjectName; }
    const char* GetMotorName( ) const { return m_ObjectName; }
    const char* GetStringName( ) const { return m_ObjectName; }
    const char* GetIonChamberName( ) const { return m_ObjectName; }

	const char* GetText( ) const { return m_pText; }
    dcs_message_id_t ClassifyMessageType( ) const { return m_type; }

    const char* GetDeviceName( ) const { return m_ObjectName; }
    const char* GetLocalName( ) const { return m_LocalName; }

	const char* GetOperationHandle( ) const { return m_info.operation.handle; }
	const char* GetOperationArgument( ) const {
        return m_info.operation.argument;
    }

    double      GetMotorPosition( ) const { return m_info.motor.position; }

    const char* GetStringContents( ) const { return m_info.string.contents; }

    double      GetEncoderPosition( ) const { return m_info.encoder.position; }

    double      GetIonChamberTime( ) const { return m_info.ion_chamber.time; }
    const char* GetIonChamberList( ) const { return m_info.ion_chamber.list; }

    bool        GetShutterClosed( ) const { return m_info.shutter.closed; }

	int m_PrivateData;            //device index
	int m_PrivateFunctionIndex;   //function index

private:
	friend class DcsMessageManager;	//new/delete
	friend class DcsMessageHandler;	//send/receive

	//only DcsMessageManager can new/delete
	DcsMessage( );

	virtual ~DcsMessage ( );

	//help method
	virtual void Reset( );

private:
    //this one will call all ParseXXXXMessage
    void SetAttributes( );

    bool ParseOperationRegisterMessage( );
    bool ParseOperationStartMessage();
    bool ParseAbortMessage();
    bool ParseIonChamberRegisterMessage();
    bool ParseIonChamberReadMessage( );
    bool ParseRegisterStringMessage( );
    bool ParseStringMessage( );
    bool ParseMotorMessage( );    
    bool ParseEncoderMessage( );    
    bool ParseShutterMessage( );    
private:
    struct operation_info {
	    char handle[MAX_OPERATION_HANDLE_LENGTH + 1];
	    const char* argument;
    };
    struct motor_info {
        double position;
    };
    struct string_info {
        const char* contents;
    };
    struct ion_chamber_info {
        char* list;
        double time;
    };
    struct encoder_info {
        double position;
    };
    struct shutter_info {
        bool closed;
    };

    union detail_info {
        operation_info   operation;
        motor_info       motor;
        string_info      string;
        ion_chamber_info ion_chamber;
        encoder_info     encoder;
        shutter_info     shutter;
    };

	//==================DATA====================
private:
	//text data
    //this is required size. actual size may be bigger
	size_t m_TextBufferSize;
	char* m_pText;

	//binary data
	size_t m_BinaryBufferSize;	//this is required size.
	char* m_pBinary;

	char m_ObjectName[MAX_OBJECT_NAME_LENGTH + 1];
	char m_LocalName[MAX_OBJECT_NAME_LENGTH + 1];

	//For manager: this is the real size of buffers allocated
	size_t m_RealTextBufferSize;
	size_t m_RealBinaryBufferSize;

    dcs_message_id_t m_type;
    detail_info      m_info;
};

#endif //#ifndef __XOS_DCS_MESSAGE_H__

