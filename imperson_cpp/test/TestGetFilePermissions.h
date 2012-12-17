#ifndef __include_TestGetFilePermissions_h__
#define __include_TestGetFilePermissions_h__

#include "xos.h"
#include "xos_http.h"
#include "ImpTestCommon.h"

/**
 */
class TestGetFilePermissions : public ImpTestCommon
{

public:

	TestGetFilePermissions(const std::string& host, int port, int level, 
					const std::string& user, const std::string& session)
		:  ImpTestCommon(host, port, level, user, session)
	{
	}

	virtual ~TestGetFilePermissions()
	{
	}

	virtual bool test();

};

#endif // __include_TestGetFilePermissions_h__
