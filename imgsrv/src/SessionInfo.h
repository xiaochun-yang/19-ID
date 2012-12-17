#ifndef __Include_SessionInfo_h__
#define __Include_SessionInfo_h__

extern "C" {
#include "xos.h"
}

#include <string>

enum user_type_t {
	USER_TYPE_UNKNOWN,
	USER_TYPE_NONSTAFF,
	USER_TYPE_STAFF
};

/**
 * @class user_info_struct
 * 
 * Representing a user
 */
class SessionInfo 
{
public:

	SessionInfo(const std::string& n, const std::string& s, 
				time_t l=0, user_type_t b=USER_TYPE_UNKNOWN)
		: name(n), sessionId(s), lastValidation(l), type(b)
	{
	}
	
	~SessionInfo() {}

	/**
	 * @brief Login name
	 */
	std::string 	name;
	/**
	 * @brief session id
	 */
	std::string		sessionId;
	/**
	 * @brief The last time a client connects to the 
	 * authentications server with this session id.
	 */
	time_t 	lastValidation;
	/**
	 * @brief Is this staff
	 */
	user_type_t type;
};

#endif // __Include_SessionInfo_h__


