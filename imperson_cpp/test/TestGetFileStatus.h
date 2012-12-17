#ifndef __include_TestGetFileStatus_h__
#define __include_TestGetFileStatus_h__

#include "xos.h"
#include "xos_http.h"
#include "ImpTestCommon.h"

/**
 */
class TestGetFileStatus : public ImpTestCommon
{

public:

	TestGetFileStatus(const std::string& host, int port, int level, 
					const std::string& user, const std::string& session)
		:  ImpTestCommon(host, port, level, user, session)
	{
	}

	virtual ~TestGetFileStatus()
	{
	}

	virtual bool test();

};

#endif // __include_TestGetFileStatus_h__
