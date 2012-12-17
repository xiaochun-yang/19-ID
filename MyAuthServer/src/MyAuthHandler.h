/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the 
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209. 

************************************************************************/

#ifndef __Include_MuAuthHandler_h__
#define __Include_MuAuthHandler_h__

#include <string>

#include "XosException.h"
#include "HttpServerHandler.h"
#include "UserCache.h"

class HttpServer;


/****************************************************************
 *
 *	class MyAuthHandler
 *
 ****************************************************************/ 
class MyAuthHandler : public HttpServerHandler
{

public:

	MyAuthHandler(UserCache* c);
	
	virtual ~MyAuthHandler()
	{
	}
	
	virtual std::string getName() const
	{
		return name;
	}
	
	virtual bool isMethodAllowed(const std::string& m) const
	{
		return true;
	}
	
    virtual void doGet(HttpServer* conn)
        throw (XosException);
	
    virtual void doPost(HttpServer* conn)
        throw (XosException);

private:

	std::string name;
	UserCache* cache;
	
	
	void appLogin(HttpServer* server, UserData& user)
		throw (XosException);	
	void webLogin(HttpServer* server, UserData& user)
		throw (XosException);	
	void appForward(HttpServer* server, UserData& user)
		throw (XosException);	
	void sessionStatus(HttpServer* server, UserData& user)
		throw (XosException);
	void endSession(HttpServer* server, UserData& user)
		throw (XosException);
	void oneTimeSession(HttpServer* server, UserData& user)
		throw (XosException);
	void beamlineUsers(HttpServer* server)
		throw (XosException);
	
	
};

#endif // __Include_MuAuthHandler_h__

