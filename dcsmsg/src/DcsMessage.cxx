#include "log_quick.h"

#include "XosStringUtil.h"
#include "DcsMessage.h"

/*****************************************************************************/
/**
DcsMessage Default Constructor

	Just initialize all to 0 or NULL.
	Buffer allocation will be done in message manager.

 */
DcsMessage::DcsMessage( ):
	m_PrivateData(-1),
	m_TextBufferSize( 0 ),
	m_pText( NULL ),
	m_BinaryBufferSize( 0 ),
	m_pBinary( NULL ),
	m_RealTextBufferSize( 0 ),
	m_RealBinaryBufferSize( 0 ),
    m_type( DCS_UNKNOWN_MSG )
{
	memset( m_ObjectName,		    0, sizeof(m_ObjectName) );
	memset( m_LocalName,		    0, sizeof(m_LocalName) );
    memset( &m_info,                0, sizeof(m_info ) );
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
void DcsMessage::SetAttributes( )
{
    //check to see if this is an operation using existing method
    if (ParseAbortMessage())
    {
        return;
    }
    if (ParseOperationRegisterMessage() )
    {
        return;
    }
    if (ParseOperationStartMessage() )
    {
        return;
    }
    if ( ParseIonChamberRegisterMessage() )
    {
        return;
    }
    if ( ParseIonChamberReadMessage() )
    {
        return;
    }
    if (ParseStringMessage())
    {
        return;
    }
    if (ParseRegisterStringMessage())
    {
        return;
    }
    if (ParseMotorMessage( ))
    {
        return;
    }
    if (ParseEncoderMessage( ))
    {
        return;
    }
    if (ParseShutterMessage( ))
    {
        return;
    }
    m_type = DCS_UNKNOWN_MSG;
}

bool DcsMessage::ParseAbortMessage( )
{
   static const char abort_all[] = "stoh_abort_all";

   if (!strncmp( m_pText, abort_all, 14 ))
   {
      LOG_FINEST( "abort all message\n" );
      m_type = DCS_ABORT_MSG;
      return true;
   }
   return false;
}

//Checks if it is an operation message and parses the handle and name.
//A message without a handle and name will not be considered a valid operation message.
bool DcsMessage::ParseOperationStartMessage( )
{
    char logBuffer[9999] = {0};
   static const char start_operation_header[] = "stoh_start_operation";

   if (strncmp( m_pText, start_operation_header, 20 ))
   {
      //not an operation command
      return false;
   }

   if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_info.operation.handle )
   != 2)
	{
		LOG_WARNING1( "DcsMessage::isOperationMessage arguments missing, text=%s\n", m_pText );
		return false;
	}

   //It appears to be a valid operation message.
   m_type = DCS_OPERATION_START_MSG;

   LOG_FINEST( "Got an operation\n" );
   
   //try to get argument
   char *pChar = strstr( m_pText, m_info.operation.handle );

   if (pChar)
	{
		pChar += strlen( m_info.operation.handle ) + 1;

		m_info.operation.argument =  pChar;
	}

    strncpy( logBuffer, m_info.operation.argument, sizeof(logBuffer) - 1 );
    XosStringUtil::maskSessionId( logBuffer );

	LOG_FINEST3( "operation: %s, %s, %s\n",
    m_ObjectName, m_info.operation.handle, logBuffer );

   return true;
}

bool DcsMessage::ParseStringMessage( )
{
    if (!strncmp( m_pText, "stoh_set_string", 15))
    {
        if (sscanf( m_pText, "%*s %s", m_ObjectName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::ParseStringMessage not got name for tring, text=%s\n", m_pText );
            return false;
        }
	    const char *pChar = strstr( m_pText, m_ObjectName );
	    if (pChar)
	    {
   		    pChar += strlen( m_ObjectName );
            if (*pChar != '\0')
            {
                ++pChar;
            }
	    }
		m_info.string.contents = pChar;

        m_type = DCS_STRING_MSG;
    	LOG_FINEST2( "string: %s, %s\n", m_ObjectName, m_info.string.contents );
        return true;
    }
    if (!strncmp( m_pText, "stoh_configure_string", 21))
    {
        //stoh_configure_string robot_attribute robot {0 0 0}
        if (sscanf( m_pText, "%*s %s", m_ObjectName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for tring, text=%s\n", m_pText );
            return false;
        }
	    const char *pChar = strstr( m_pText, m_ObjectName );
	    if (pChar)
	    {
   		    pChar += strlen( m_ObjectName );
            if (*pChar != '\0')
            {
                ++pChar;
            }
            pChar = strchr( pChar, ' ' );
            if (pChar) ++pChar;
	    }
		m_info.string.contents = pChar;

        m_type = DCS_STRING_MSG;
    	LOG_FINEST2( "string: %s, %s\n", m_ObjectName, m_info.string.contents );
        return true;
    }
    return false;
}
bool DcsMessage::ParseRegisterStringMessage( )
{
    if (!strncmp( m_pText, "stoh_register_string", 20))
    {
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for register string, text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_REGISTER_STRING_MSG;
        return true;
    }
    return false;
}

bool DcsMessage::ParseOperationRegisterMessage( )
{
    if (!strncmp( m_pText, "stoh_register_operation", 23))
    {
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for register operation, text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_OPERATION_REGISTER_MSG;
        return true;
    }
    return false;
}

bool DcsMessage::ParseIonChamberRegisterMessage( )
{
    if (!strncmp( m_pText, "stoh_register_ion_chamber" , 25 ))
    {
        if (sscanf( m_pText, "%*s %s", m_ObjectName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name for register ion chamber text=%s\n", m_pText );
            return false;
        }
        strcpy( m_LocalName, m_ObjectName );
        LOG_FINEST( "register ion chamber message\n" );
        m_type = DCS_ION_CHAMBER_REGISTER_MSG;
        return true;
    }
    else
    {
        return false;
    }
}


bool DcsMessage::ParseIonChamberReadMessage( )
{
    if (!strncmp( m_pText, "stoh_read_ion_chambers" , 22 ))
    {
        //use first ion chamber as object
        if (sscanf( m_pText, "%*s %lf %*s %s",
        &m_info.ion_chamber.time, m_ObjectName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::ParseIonChamberReadMessage not got name, text=%s\n", m_pText );
            return false;
        }
        m_info.ion_chamber.list = strstr( m_pText + 28, m_ObjectName );
        LOG_FINEST( "read ion chamber message\n" );
        m_type = DCS_ION_CHAMBER_READ_MSG;
        return true;
    }
    return false;
}

bool DcsMessage::ParseMotorMessage( )
{
    if (!strncmp( m_pText, "stoh_register_pseudo_motor", 26 ))
    {
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_REGISTER_PSEUDO_MOTOR_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_register_real_motor", 24 ))
    {
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_REGISTER_REAL_MOTOR_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_configure_real_motor", 25 ))
    {
        if (sscanf( m_pText, "%*s %s %*s %s %lf",
        m_ObjectName, m_LocalName, &m_info.motor.position ) != 3)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_CONFIGURE_REAL_MOTOR_MSG;
        return true;
        
    }
    else if (!strncmp( m_pText, "stoh_configure_pseudo_motor", 27 ))
    {
        if (sscanf( m_pText, "%*s %s %*s %s %lf",
        m_ObjectName, m_LocalName, &m_info.motor.position ) != 3)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_CONFIGURE_PSEUDO_MOTOR_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_start_motor_move", 21 ))
    {
        if (sscanf( m_pText, "%*s %s %lf",
        m_ObjectName, &m_info.motor.position ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_MOVE_MOTOR_MSG;
        return true;
    }
    return false;
}
bool DcsMessage::ParseEncoderMessage( )
{
    if (!strncmp( m_pText, "stoh_register_encoder", 21 ))
    {
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_REGISTER_ENCODER_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_get_encoder", 16 ))
    {
        if (sscanf( m_pText, "%*s %s", m_ObjectName ) != 1)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_GET_ENCODER_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_set_encoder", 16 ))
    {
        if (sscanf( m_pText, "%*s %s %lf",
        m_ObjectName, &m_info.encoder.position ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_SET_ENCODER_MSG;
        return true;
    }
    return false;
}
bool DcsMessage::ParseShutterMessage( )
{

    if (!strncmp( m_pText, "stoh_register_shutter", 21 ))
    {
        if (sscanf( m_pText, "%*s %s %*s %s", m_ObjectName, m_LocalName ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_type = DCS_REGISTER_SHUTTER_MSG;
        return true;
    }
    else if (!strncmp( m_pText, "stoh_set_shutter_state", 22 ))
    {
        char state[128] = {0};
        if (sscanf( m_pText, "%*s %s %s", m_ObjectName, state ) != 2)
        {
		    LOG_WARNING1( "DcsMessage::SetAttributes not got name text=%s\n", m_pText );
            return false;
        }
        m_info.shutter.closed = (!strcmp( state, "closed" )) ? true : false;
        m_type = DCS_SET_SHUTTER_MSG;
        return true;
    }
    return false;
}
void DcsMessage::Reset( )
{
	m_PrivateData = -1;
    m_PrivateFunctionIndex = -1;
    m_type = DCS_UNKNOWN_MSG;

	memset( m_ObjectName,		0, sizeof(m_ObjectName) );
	memset( m_LocalName,		0, sizeof(m_LocalName) );
    memset( &m_info,            0, sizeof(m_info) );

	if (m_pText && m_RealTextBufferSize) memset( m_pText, 0, m_RealTextBufferSize );
	if (m_pBinary && m_RealBinaryBufferSize) memset( m_pBinary, 0, m_RealBinaryBufferSize );
}
