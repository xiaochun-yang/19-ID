#include "xos.h"
#include <string>
#include <vector>
#include "XosStringUtil.h"
#include "UserCache.h"


/****************************************************************
 *
 *	Constructor
 *
 ****************************************************************/ 
UserData::UserData()
{
	init();
}

/****************************************************************
 *
 *	Copy Constructor
 *
 ****************************************************************/ 
UserData::UserData(const UserData& other)
{
	copy(other);
}

/****************************************************************
 *
 *	operator=
 *
 ****************************************************************/ 
UserData& UserData::operator=(const UserData& other)
{
	this->copy(other);
	
	return *this;
}

/****************************************************************
 *
 *	init
 *
 ****************************************************************/ 
void UserData::init()
{
	unixName = "NA";
	realName = "NA";
	type = "NA";
	officePhone = "NA";
	jobTitle = "NA";
	beamline = "NA";
	staff = "FALSE";
	remoteAccess = "FALSE";
	enabled = "FALSE";
	sessionId = "NA";
	password = "";
	
	createTime = "NA";
	accessTime = "NA";
	BL = "NA";
	dbAuth = "FALSE";
}


/****************************************************************
 *
 *	copy
 *
 ****************************************************************/ 
void UserData::copy(const UserData& other)
{
	unixName = other.unixName;
	realName = other.realName;
	type = other.type;
	officePhone = other.officePhone;
	jobTitle = other.jobTitle;
	beamline = other.beamline;
	staff = other.staff;
	remoteAccess = other.remoteAccess;
	enabled = other.enabled;
	sessionId = other.sessionId;
	password = other.password;
	
	createTime = other.createTime;
	accessTime = other.accessTime;
	BL = other.BL;
	dbAuth = other.dbAuth;
}


/****************************************************************
 *
 *	Constructor
 *
 ****************************************************************/ 
UserCache::UserCache()
	throw (XosException)
{
	init("./users.txt");
}

/****************************************************************
 *
 *	Constructor
 *
 ****************************************************************/ 
UserCache::UserCache(const std::string& filename)
	throw (XosException)
{
	init(filename);
}


/****************************************************************
 *
 *	init
 *
 ****************************************************************/ 
void UserCache::init(const std::string& filename)
	throw (XosException)
{
	// initialize the user permissions table mutex
	if ( xos_mutex_create( &cacheMutex ) == XOS_FAILURE )
		throw XosException("Failed to initialize cache mutex");
		
	lock();
	
    FILE* is = fopen(filename.c_str(), "r");
    if (!is) {
    	printf("MyAuthServer -- Failed to open file %s\n", filename.c_str());
    	exit(0);
    }
    
	
	char buf[500];
	UserData user;
	while (!feof(is)) {
	
		if (fgets(buf, 500, is) == NULL)
			{
				printf("Reached end of file\n");
				break;
                        }
			
		if (strlen(buf) < 2)
			continue;
			
		if (buf[0] == '#') {
			printf("Skipping comment line: %s\n", buf);
			continue;
		}
				
		
		std::vector<std::string> ret;
		if (!XosStringUtil::tokenize(buf, ",\n\r", ret) || (ret.size() != 11)) {
			printf("skipping user data: %s\n", buf);
			continue;
		}
		
				
		user.unixName = ret[0];
		puts (user.unixName.c_str());
		user.realName = ret[1];
		user.type = ret[2];
		user.officePhone = ret[3];
		user.jobTitle = ret[4];
		user.beamline = ret[5];
		user.staff = ret[6];
		user.remoteAccess = ret[7];
		user.enabled = ret[8];
		user.sessionId = ret[9];
		user.password = ret[10];
		//users[user.sessionId] = user;
		users.insert(CacheMap::value_type(user.sessionId, user));
		printf("map size: %d \n", users.size() );
	}
    fclose(is);
	
	CacheMap::const_iterator i = users.begin();
	while ( i != users.end() ) {
		printf("userMap: %s \n", i->second.unixName.c_str() );
		i++;
	}
	
	unlock();
}

/****************************************************************
 *
 *	findUser
 *
 ****************************************************************/ 
bool UserCache::findUser(const std::string& name, UserData& ret)
	throw (XosException)
{
	lock();
	
	CacheMap::const_iterator i = users.begin();
	CacheMap::const_iterator end = users.end();
	for (; i != end; ++i) {

		printf("findUser: %s == %s\n", name.c_str(), i->second.unixName.c_str() );
	
		if (i->second.unixName == name) {
			ret = i->second;
			unlock();
			return true;
		}
		
	}
	
	puts("end of cache");
			
	unlock();
	return false;
}

/****************************************************************
 *
 *	findSessionId
 *
 ****************************************************************/ 
bool UserCache::findSessionId(const std::string& id, UserData& ret)
	throw (XosException)
{
	lock();
	
	CacheMap::const_iterator i = users.find(id);
	if (i != users.end()) {
		
		ret = i->second;
		
		unlock();
		return true;
	}
	
	unlock();
	return false;
}

bool UserCache::isTrue(const std::string& str)
{
	if (str.empty())
		return false;
		
	return ((str == "Y") || (str == "y")
		|| (str == "YES") || (str == "yes") || (str == "Yes")
		|| (str == "TRUE") || (str == "true") || (str == "True"));
	
}

/****************************************************************
 *
 *	getBeamlineUsers
 *
 ****************************************************************/ 
std::string UserCache::getBeamlineUsers(const std::string& beamline, bool includeStaff)
	throw (XosException)
{
	// Returns users that have access to the given beamline
	lock();
	
	CacheMap::const_iterator i = users.begin();
	CacheMap::const_iterator end = users.end();
	std::string ret = "";
	for (; i != end; ++i) {
		printf("includeStaff = %d unixName = %s staff flag = %s beamline = %s\n",
			includeStaff, i->second.unixName.c_str(),
			i->second.staff.c_str(),
			i->second.beamline.c_str());
		if (includeStaff && isTrue(i->second.staff)) {
			printf("  STAFF\n");
			// Include staff regardless of beamline field
			if (!ret.empty())
				ret += ";";
			ret += i->second.unixName;
		} else {
		
			printf("  USER\n");
		// For example, if the requested beamline is BL7-1
		// user's beamline field must be one of the following formats:
		// ALL
		// BL7-1
		// BL7-1;BL9-2;BL1-5
		// BL9-2;BL7-1;BL1-5
		// BL9-2;BL1-5;BL7-1
		// This check should work even if the user has BL7-11 (BL7-1 is substring of BL7-11).
		if ((i->second.beamline == "ALL") ||
		    (i->second.beamline == beamline) ||
		    (i->second.beamline.find(";" + beamline) != std::string::npos) ||
		    (i->second.beamline.find(beamline + ";") != std::string::npos)) {
			if (!ret.empty())
				ret += ";";
			ret += i->second.unixName;
		}
		
		}		
	}	
	
	unlock();
	
	return ret;
}

/****************************************************************
 *
 *	lock
 *
 ****************************************************************/ 
void UserCache::lock()
	throw (XosException)
{
	// Lock the table
	if ( xos_mutex_lock(&cacheMutex) != XOS_SUCCESS)
		throw XosException("Failed to lock cache mutex");
}

/****************************************************************
 *
 *	unlock
 *
 ****************************************************************/ 
void UserCache::unlock()
	throw (XosException)
{
	// Unlock the cahce
	if ( xos_mutex_unlock(&cacheMutex) != XOS_SUCCESS)
		throw XosException("Failed to unlock cache mutex");
}


