#ifndef __XOS_DCS_MESSAGE_H__
#define __XOS_DCS_MESSAGE_H__

#define DCS_HEADER_SIZE 26

#define MAX_OPERATION_NAME_LENGTH 127
#define MAX_OPERATION_HANDLE_LENGTH 127
#define MAX_STRING_NAME_LENGTH 127

class  DcsMessage{
public:

	//following method is not absolutely safe.
	const char* GetText( ) const { return m_pText; }
	//no binary content yet.

	bool IsAbortAll( ) const { return m_IsAbortAll; }

	//if this message is operation
	bool IsOperation( ) const { return m_IsOperation; }
	//if it is operation message, following method will return something
	const char* GetOperationName( ) const { return m_OperationName; }
	const char* GetOperationHandle( ) const { return m_OperationHandle; }
	const char* GetOperationArgument( ) const { return m_OperationArgument; }

    bool IsString( ) const { return m_IsString; }
    const char* GetStringName( ) const { return m_StringName; }
    const char* GetStringContents( ) const { return m_StringContents; }

private:
	friend class DcsMessageManager;	//new/delete
	friend class DcsMessageHandler;	//send/receive
	friend class RobotService;		//send/receive

	//only DcsMessageManager can new/delete
	DcsMessage( );

	virtual ~DcsMessage ( );

	//help method
	virtual void SetAttributes( void );
	virtual void Reset( );


	//==================DATA====================
private:
	//text data
	unsigned int m_TextBufferSize;	//this is required size. actual size may be bigger
	char* m_pText;

	//binary data
	unsigned int m_BinaryBufferSize;	//this is required size.
	char* m_pBinary;

	bool m_IsAbortAll;

    //for string (a distributed global variables with pushing out update)
    bool m_IsString;
    char m_StringName[MAX_STRING_NAME_LENGTH + 1];
    const char* m_StringContents;

	//for operation
	bool m_IsOperation;
	char m_OperationName[MAX_OPERATION_NAME_LENGTH + 1];
	char m_OperationHandle[MAX_OPERATION_HANDLE_LENGTH + 1];
	const char* m_OperationArgument;

	//For manager: this is the real size of buffers allocated
	unsigned int m_RealTextBufferSize;
	unsigned int m_RealBinaryBufferSize;

	//private data for any use: currently used in RobotService to remember the index
	//of operation it supported.  This way, we do not need to scan twice to match the 
	//operation with function calls
	int m_PrivateData;
};

#endif //#ifndef __XOS_DCS_MESSAGE_H__

