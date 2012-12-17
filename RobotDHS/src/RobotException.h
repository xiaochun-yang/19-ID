#pragma once
#include "afx.h"

class RobotException :
	public CException
{
public:
	RobotException( const char* message );

	virtual BOOL GetErrorMessage(
		LPTSTR lpszError,
		UINT nMaxError,
		PUINT pnHelpContext = NULL 
	);

	virtual ~RobotException(void);

	DECLARE_DYNAMIC(RobotException)

private:
	RobotException(void); //prohibit default constructor

	char m_message[200];
};
