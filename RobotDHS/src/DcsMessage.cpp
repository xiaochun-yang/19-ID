#define NO_LOG
#include "log_quick.h"

#include "DcsMessage.h"

/*****************************************************************************/
/**
DcsMessage Default Constructor

	Just initialize all to 0 or NULL.
	Buffer allocation will be done in message manager.

 */
DcsMessage::DcsMessage( ):
	m_TextBufferSize( 0 ),
	m_pText( NULL ),
	m_BinaryBufferSize( 0 ),
	m_pBinary( NULL ),
	m_IsAbortAll( false ),
	m_IsOperation( false ),
	m_IsString( false ),
    m_OperationArgument( NULL ),
    m_StringContents( NULL ),
	m_RealTextBufferSize( 0 ),
	m_RealBinaryBufferSize( 0 ),
	m_PrivateData(-1)
{
	memset( m_OperationName,		0, sizeof(m_OperationName) );
	memset( m_OperationHandle,		0, sizeof(m_OperationHandle) );
	memset( m_StringName,		    0, sizeof(m_StringName) );
}

/*****************************************************************************/
/**
DcsMessage Destructor

	release the buffers if the manager forgot to.
 */
DcsMessage::~DcsMessage ( void )
{ 
	//clear up buffers if allocated
	if (m_pText)
	{
		delete [] m_pText;
	}

	if (m_pBinary)
	{
		delete [] m_pBinary;
	}
}

/*****************************************************************************/
/**
DcsMessage::SetAttributes

	This is a help method to fill operation attributes if this message
	is an operation message.

	Because this is a help class, there is no safety check.

 */

#define START_EQUAL( a ) (!strncmp( m_pText, a, (sizeof(a) - 1) ))
void DcsMessage::SetAttributes( )
{
	char dummy1[128];

	static const char start_operation_header[] = "stoh_start_operation";
	static const char abort_all[] = "stoh_abort_all";
	static const char set_string_header[] = "stoh_set_string";
    static const char config_string_header[] = "stoh_configure_string";

	if (START_EQUAL(abort_all))
	{
		LOG_FINEST( "abort all message\n" );
		m_IsAbortAll = true;
		return;
	}

	if (START_EQUAL(start_operation_header))
	{
	    if (sscanf( m_pText, "%s %s %s", dummy1, m_OperationName, m_OperationHandle ) != 3)
	    {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got all attributes for operation, text=%s\n", m_pText );
		    return;
	    }

	    //try to get argument
	    const char *pChar = strstr( m_pText, m_OperationHandle );
	    if (pChar)
	    {
   		    pChar += strlen( m_OperationHandle );
            if (*pChar != '\0')
            {
                ++pChar;
            }
		    m_OperationArgument = pChar;
	    }
	    m_IsOperation = true;
    	LOG_FINEST3( "operation: %s, %s, %s\n", m_OperationName, m_OperationHandle, m_OperationArgument );
        return;
    }

    if (START_EQUAL(set_string_header))
    {
        if (sscanf( m_pText, "%*s %s", m_StringName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for tring, text=%s\n", m_pText );
            return;
        }
	    const char *pChar = strstr( m_pText, m_StringName );
	    if (pChar)
	    {
   		    pChar += strlen( m_StringName );
            if (*pChar != '\0')
            {
                ++pChar;
            }
	    }
		m_StringContents = pChar;

        m_IsString = true;
    	LOG_FINEST2( "string: %s, %s\n", m_StringName, m_StringContents );
        return;
    }
	if (START_EQUAL(config_string_header))
    {
        //stoh_configure_string robot_attribute robot {0 0 0}
        if (sscanf( m_pText, "%*s %s", m_StringName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for tring, text=%s\n", m_pText );
            return;
        }
	    const char *pChar = strstr( m_pText, m_StringName );
	    if (pChar)
	    {
   		    pChar += strlen( m_StringName );
            if (*pChar != '\0')
            {
                ++pChar;
            }
            pChar = strchr( pChar, ' ' );
            if (pChar) ++pChar;
	    }
		m_StringContents = pChar;

        m_IsString = true;
    	LOG_FINEST2( "string: %s, %s\n", m_StringName, m_StringContents );
        return;
    }
}

void DcsMessage::Reset( )
{
	m_TextBufferSize = 0;
	m_BinaryBufferSize = 0;
	m_IsAbortAll = false;
	m_IsOperation = false;
	m_IsString = false;
	m_PrivateData = -1;
    m_OperationArgument = NULL;
    m_StringContents =  NULL;

	memset( m_OperationName,		0, sizeof(m_OperationName) );
	memset( m_OperationHandle,		0, sizeof(m_OperationHandle) );

	if (m_pText && m_RealTextBufferSize) memset( m_pText, 0, m_RealTextBufferSize );
	if (m_pBinary && m_RealBinaryBufferSize) memset( m_pBinary, 0, m_RealBinaryBufferSize );
}
