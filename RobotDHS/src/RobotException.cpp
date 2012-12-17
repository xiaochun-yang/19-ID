#include "robotexception.h"

IMPLEMENT_DYNAMIC(RobotException, CException)

RobotException::RobotException(void)
{
}
RobotException::RobotException( const char* message )
{
	memset( m_message, 0, sizeof(m_message) );
	strncpy( m_message, message, sizeof(m_message) - 1 );
}

BOOL RobotException::GetErrorMessage(
LPTSTR lpszError,
UINT nMaxError,
PUINT pnHelpContext ) {

	strncpy( lpszError, m_message, nMaxError - 1 );
	return TRUE;
}

RobotException::~RobotException(void)
{
}
