#include "xos.h"
#include "XosStringUtil.h"
#include "HttpServerHandler.h"
#include "HttpServer.h"
#include "SocketServer.h"
#include "HttpRequest.h"
#include "HttpResponse.h"
#include "MyAuthHandler.h"

/****************************************************************
 *
 * Constructor
 *
 ****************************************************************/ 
MyAuthHandler::MyAuthHandler(UserCache* c)
	: name("My Authentication Server/1.0"), cache(c)
{
}


/****************************************************************
 *
 * webLogin
 *
 ****************************************************************/ 
void MyAuthHandler::webLogin(HttpServer* conn, UserData& user)
	throw (XosException)
{
}

/****************************************************************
 *
 * appForward
 *
 ****************************************************************/ 
void MyAuthHandler::appForward(HttpServer* conn, UserData& user)
	throw (XosException)
{
}

/****************************************************************
 *
 * sessionStatus
 * http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?AppName=<application name>
 * http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?ValidBeamlines=True&AppName=<application name> 
 *
 ****************************************************************/ 
void MyAuthHandler::sessionStatus(HttpServer* conn, UserData& user)
	throw (XosException)
{

	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	
	std::string appName;
	if (!request->getParamOrHeader("AppName", appName)) 
		throw XosException(400, "Invalid appname parameter");
			
	std::string resource = request->getResource();
	size_t pos = resource.find(";jsessionid=");
	if (pos == std::string::npos) {
		throw XosException(400, "Invalid jsessionid parameter");
	}
	std::string sessionId = resource.substr(pos+12);
	
	if (cache->findSessionId(sessionId, user)) {
		response->setHeader("Auth.SessionValid", "TRUE");
	} else {
		response->setHeader("Auth.SessionValid", "FALSE");
	}
		
	user.setCookie = false;
	
	
}

/****************************************************************
 *
 * GetOneTimeSession
 * http://smb.slac.stanford.edu:8084/gateway/servlet/GetOneTimeSession?AppName=BluIce&AuthMethod=smb_config_database&ValidBeamlines=True
 * http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus?AppName=BluIce&AuthMethod=smb_config_database&ValidBeamlines=True 
 *
 ****************************************************************/ 
void MyAuthHandler::oneTimeSession(HttpServer* conn, UserData& user)
	throw (XosException)
{

	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	std::string sessionId;
	std::string appName;
	if (!request->getParamOrHeader("SMBSessionID", sessionId))
		throw XosException(400, "Invalid SMBSessionID parameter");
	if (!request->getParamOrHeader("AppName", appName))
		throw XosException(400, "Invalid AppName parameter");
	
	if (cache->findSessionId(sessionId, user)) {
	printf("oneTimeSession: found sessionId %s\n", sessionId.c_str());
		response->setHeader("Auth.SessionValid", "TRUE");
	} else {
	printf("oneTimeSession: Did not find sessionId %s\n", sessionId.c_str());
		response->setHeader("Auth.SessionValid", "FALSE");
	}
      
	user.setCookie = false;
	   	
}

/****************************************************************
 *
 * endSession
 *
 ****************************************************************/ 
void MyAuthHandler::endSession(HttpServer* conn, UserData& user)
	throw (XosException)
{
}

/****************************************************************
 *
 * appLogin
 * http://smb.slac.stanford.edu:8084/gateway/servlet/APPLOGIN?userid=<userid>&passwd=<encodedid>& appname=<application name> 	
 *
 ****************************************************************/ 
void MyAuthHandler::appLogin(HttpServer* conn, UserData& user)
	throw (XosException)
{
	printf("in appLogin 1\n"); fflush(stdout);

	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	std::string unixName;
	std::string appName;
	std::string passwd;
	if (!request->getParamOrHeader("userid", unixName))
		throw XosException(400, "Invalid userid parameter");
	if (!request->getParamOrHeader("passwd", passwd)) 
		throw XosException(400, "Invalid passwd parameter");
	if (!request->getParamOrHeader("AppName", appName)) 
		throw XosException(400, "Invalid appname parameter");
	
	if (!cache->findUser(unixName, user))
		throw XosException(401, "Authorization failed");
   
   //check password   
   if ( user.password != passwd ) {
      printf ("%s != %s \n", user.password.c_str(), passwd.c_str());
		throw XosException(401, "Authorization failed");
   }
      
	user.setCookie = true;
	

   printf("unixName: %s   appName %s   passwd %s\n", unixName.c_str(), appName.c_str(), passwd.c_str()  );
   
	printf("in appLogin 2\n"); fflush(stdout);
}

/****************************************************************
 * http://smb.slac.stanford.edu:8084/gateway/servlet/EndSession;jsessionid=<SMBSessionID>?AppName=<application name>
 * http://smb.slac.stanford.edu:8084/gateway/servlet/BeamlineUsers?beamline=<beamlineName>&includeStaff=<Y|N>&forcedrefresh=<Y|N>
 ****************************************************************/ 
void MyAuthHandler::beamlineUsers(HttpServer* conn)
	throw (XosException)
{

	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	std::string beamline;
	bool includeStaff = FALSE;
	bool forcedRefresh = FALSE;
	if (!request->getParamOrHeader("beamline", beamline))
		throw XosException(500, "Invalid beamline parameter");
	std::string tt = "N";
	if (request->getParamOrHeader("includestaff", tt) && (tt == "Y"))
		includeStaff = TRUE;
		
	tt = "N";
	if (request->getParamOrHeader("forcedrefresh", tt) && (tt == "Y")) 
		forcedRefresh = TRUE;
	         
	std::string users = cache->getBeamlineUsers(beamline, includeStaff);

	response->setHeader("Connection", "close");
	response->setHeader("Content-Type", "text/plain");
	
	// Response header
	response->setHeader("blusers.beamline", beamline);
	response->setHeader("blusers.users", users);
 
 	// Compose response body
	std::string endofline("\n");
	std::string body("");
	body += "blusers.beamline=" + beamline + endofline;
	body += "blusers.users=" + users + endofline;
	
	// Send response
	response->setContentLength(body.size());
	conn->writeResponseBody(body.c_str(), body.size());
	conn->finishWriteResponse();
	
} 	

/****************************************************************
 *
 *	doGet
 * https://smb.slac.stanford.edu/gateway/servlet/WEBLOGIN?URL=<URL>&URLSession=<URLSession>&Message=<Message>&AppName=<AppName>&dnAuth=<dbAuth> 
 * http://smb.slac.stanford.edu:8084/gateway/servlet/APPLOGIN?userid=<userid>&passwd=<encodedid>& appname=<application name> 	
 * https://smb.slac.stanford.edu:8084/gateway/servlet/APPFORWARD?URL=<app url>&AppName=<application name>&SMBSessionID=<session id>
 * http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?AppName=<application name>
 * http://smb.slac.stanford.edu:8084/gateway/servlet/SessionStatus;jsessionid=<SMBSessionID>?ValidBeamlines=True&AppName=<application name> 
 * Response
 *
 * HTTP/1.1 200 OK
Content-Type: text/plain
Connection: close
UserStaff: TRUE
UserType: UNIX
SessionValid: TRUE
UserID: penjitk
SessionCreation: 1059078457876
UserPriv: 0
Date: Thu, 24 Jul 2003 20:27:37 GMT
Server: Apache Tomcat/4.0.6 (HTTP/1.1 Connector)
UserName: Penjit Kanjanarat
SessionAccessed: 1059078457876
Beamlines: ALL
Set-Cookie: SMBSessionID=D2BB62C1738DE3A43404C4041DDEA3BF;Domain=.slac.stanford.edu;Path=/
Set-Cookie: JSESSIONID=D2BB62C1738DE3A43404C4041DDEA3BF;Path=/gateway

SMBSessionID=D2BB62C1738DE3A43404C4041DDEA3BF
SessionValid=TRUE
SessionCreation=1059078457876
SessionAccessed=1059078457876
UserID=penjitk
UserName=Penjit Kanjanarat
UserType=UNIX
UserPriv=0
UserStaff=TRUE
Beamlines=ALL
 *
 ****************************************************************/ 
void MyAuthHandler::doGet(HttpServer* conn)
	throw (XosException)
{
	
	HttpRequest* request = conn->getRequest();
	HttpResponse* response = conn->getResponse();
	
	std::string resource(request->getResource());
	UserData user;
	user.setCookie = false;
	if (resource.find("APPLOGIN") != std::string::npos) {
		appLogin(conn, user);
	} else if (resource.find("WEBLOGIN") != std::string::npos) {
		webLogin(conn, user);
	} else if (resource.find("APPFORWARD") != std::string::npos) {
		appForward(conn, user);
	} else if (resource.find("SessionStatus") != std::string::npos) {
		sessionStatus(conn, user);
	} else if (resource.find("GetOneTimeSession") != std::string::npos) {
		oneTimeSession(conn, user);
	} else if (resource.find("EndSession") != std::string::npos) {
		endSession(conn, user);
	} else if (resource.find("BeamlineUsers") != std::string::npos) {
		beamlineUsers(conn);
		return;
	} else {
		throw XosException(400, "Invalid command");
	}
	
	std::string t = XosStringUtil::fromInt(time(NULL));
	
	response->setHeader("Connection", "close");
	response->setHeader("Content-Type", "text/plain");
   if ( user.staff == std::string("TRUE") ) {              
	   response->setHeader("Auth.UserStaff", "Y");
   } else {
	   response->setHeader("Auth.UserStaff", "N");
   }
	response->setHeader("Auth.RemoteAccess", user.remoteAccess);
	response->setHeader("Auth.Enabled", user.enabled);		
	response->setHeader("Auth.UserType", user.type);
	response->setHeader("Auth.UserID", user.unixName);
	response->setHeader("Auth.SessionCreation", t);
	response->setHeader("Auth.UserName", user.realName);
	response->setHeader("Auth.SessionAccessed", t);
	response->setHeader("Auth.Beamlines", user.beamline);
	
	if (user.setCookie) {
		char cookieStr[500];
		sprintf(cookieStr, "SMBSessionID=%s;Domain=.slac.stanford.edu;Path=/", user.sessionId.c_str());
		response->setHeader("Set-Cookie", cookieStr);
      sprintf(cookieStr, "SMBSessionID=%s;Path=/gateway", user.sessionId.c_str());
		response->setHeader("Set-Cookie", cookieStr);
	}
	
	std::string endofline("\n");
	
	std::string body("");
	//body += "JSESSIONID=" + user.sessionId + endofline;
	body += "Auth.SessionKey=SMBSessionID" + endofline;
	body += "Auth.SMBSessionID=" + user.sessionId + endofline;
	body += "Auth.SessionValid=TRUE" + endofline;
	body += "Auth.SessionCreation=" + t + endofline;
	body += "Auth.SessionAccessed=" + t + endofline;
	body += "Auth.UserID=" +  user.unixName + endofline;
	body += "Auth.UserName=" +  user.realName + endofline;
	body += "Auth.UserType=" +  user.type + endofline;

   if ( user.staff == std::string("TRUE") ) {              
	   body += "Auth.UserStaff=Y" + endofline;
   } else {
	   body += "Auth.UserStaff=N"  + endofline;
   }

   body += "Auth.Beamlines=" +  user.beamline + endofline;
	
	response->setContentLength(body.size());
		
   printf("response: %s\n", body.c_str());

   
	conn->writeResponseBody(body.c_str(), body.size());
	conn->finishWriteResponse();
		
}


/****************************************************************
 *
 *	doPost
 *
 ****************************************************************/ 
void MyAuthHandler::doPost(HttpServer* conn)
	throw (XosException)
{
	doGet(conn);
}


