#ifndef __include_ImpTestCommon_h__
#define __include_ImpTestCommon_h__

#include "xos.h"
#include "xos_http.h"
#include <string>
/**
 */
class ImpTestCommon
{

public:

	ImpTestCommon(const std::string& host, int port, int level, 
						const std::string& user, const std::string& session)
		: mImpersonHost(host),
		  mImpersonPort(port),
		  mOutputLevel(level),
		  mTestCount(0),
		  mPassCount(0),
		  mUserName(user),
		  mSessionId(session)
	{
		// do nothing
	}

	ImpTestCommon()
		: mImpersonHost("localhost"),
		  mImpersonPort(61001),
		  mOutputLevel(0),
		  mTestCount(0),
		  mPassCount(0),
		  mUserName(""),
		  mSessionId("")
	{
		// do nothing
	}
	
	virtual ~ImpTestCommon()
	{
	}

	virtual bool test() = 0;

	void setImpersonHost(const std::string& s)
	{
		mImpersonHost = s;
	}

	std::string getImpersonHost()
	{
		return mImpersonHost;
	}

	void setImpersonPort(int p)
	{
		mImpersonPort = p;
	}

	int getImpersonPort()
	{	
		return mImpersonPort;
	}

	void setOutputLevel(int p)
	{
		mOutputLevel = p;
	}

	int getOutputLevel()
	{	
		return mOutputLevel;
	}

	void setUserName(const std::string& user)
	{
		mUserName = user;
	}

	std::string getUserName()
	{
		return mUserName;
	}

	void setSessionId(const std::string& session)
	{
		mSessionId = session;
	}

	std::string getSessionId()
	{
		return mSessionId;
	}
	int getTestCount()
	{
		return mTestCount;
	}

	int getPassCount()
	{
		return mPassCount;
	}

	int getFailureCount()
	{
		return mTestCount - mPassCount;
	}	


protected:

	std::string mUserName;
	std::string mSessionId;

	int sendRequest(const std::string& url, std::string& phrase);
	bool testBasic(const std::string& testName, const std::string& url, 
					int expectedCode, const std::string& description);

private:

	std::string mImpersonHost;
	int mImpersonPort;
	int mOutputLevel;
	int mTestCount;
	int mPassCount;
	
};

#endif // __include_ImpTestCommon_h__

