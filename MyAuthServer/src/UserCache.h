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

#ifndef __Include_UserCache_h__
#define __Include_UserCache_h__

#include <string>
#include <map>
#include "XosException.h"

class UserData;

typedef std::map<std::string, UserData> CacheMap;

/****************************************************************
 *
 *	class UserData
 *
 ****************************************************************/ 
class UserData
{

public:

	UserData();
	UserData(const UserData& other);
	
	UserData& operator=(const UserData& other);
	
	std::string unixName;
	std::string realName;
	std::string type;
	std::string officePhone;
	std::string jobTitle;
	std::string	beamline;
	std::string	staff;
	std::string	remoteAccess;
	std::string	enabled;
	std::string	sessionId;
	std::string	password;
	
	std::string BL;
	std::string createTime;
	std::string accessTime;
	std::string dbAuth;
	
	// transient
	bool		setCookie;
		

private:

	void init();
	void copy(const UserData& other);
	
};

/****************************************************************
 *
 *	class UserCache
 *
 ****************************************************************/ 
class UserCache
{
public:

	UserCache() throw (XosException);
	UserCache(const std::string& filename) 
		throw (XosException);
	
	void lock() 
		throw (XosException);
	void unlock() 
		throw (XosException);
	
	bool findUser(const std::string& name, UserData& ret) 
		throw (XosException);
		
	bool findSessionId(const std::string& id, UserData& ret) 
		throw (XosException);
		
	std::string getBeamlineUsers(const std::string& beamline,
				bool includeStaff)
		throw (XosException);
	

private:

	xos_mutex_t cacheMutex;
	CacheMap users;

	void init(const std::string& filename) 
		throw (XosException);
		
	// Ulity func
	bool isTrue(const std::string& str);
};



#endif // __Include_UserCache_h__

