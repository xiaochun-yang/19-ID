#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

#
# AuthClient.tcl
#
# Connects to the authentication server via HTTP to create, end
# or validate a session.
#
# ===================================================

# ===================================================
#
# AuthClient.tcl --
#
#	Utility class that allows application to connect to the authentication server to
#	create/validate/end a sesssion. This class encapsulates the HTTP connection
#	so that the application does not need to deal with parsing raw HTTP request
#	or response.
#	Excerpt from the Authication server document by K.Sharp V1.1.
#	
#	Unless the servlet engine is down, each request will receive a response consisting
#	of a text-only web page with the following information found both as headers in
#	the HTTP header response and as text within the response body:
#	
#	For non-web applications that would like to create a session for a user, make an
#	HTTP request to:
#
#
# http://smb.slac.stanford.edu:8084/gateway/servlet/APPLOGIN?userid=<userid>&passwd=<encodedid>& appname=<application name> where <userid> is the userid in clear text, <encodedid> is the Base64 encoded hash of the userid and password, and <application name> is the name of the calling application. All these parameters are required. AppName must match a list of permitted applications, and the call to APPLOGIN must come from a trusted IP address. If successful, the http response will include an SMBSessionID cookie and the session information specified in section 3. If unsuccessful, the http response will consist of a response code 403 (Forbidden).
#
#	
#	Sessions create for non web-base applications (that is, those sessions create by
#	calls to the APPLOGIN servlet) will time-out 72 hours after they are created.
#	No activity is required on the session to keep it alive within that period.
#	
#			
#
# Rough version history:
# V0_1	Based on SMBGatewaySession java class by K.Sharp.
#
# ===================================================

package provide DCSAuthClient 2.0

package require Itcl




# http in tcl 8.3 does not work with the Authentication server
# since the "Host" header in the request does not contain 
# port number ( host:port ). This is fixed in 8.4.3.
# Use http.tcl instead for now.
package require http
package require DCSUtil

# ===================================================
#
# class AuthClient
#
# ===================================================
::itcl::class AuthClient {

   #variable for storing singleton doseFactor object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

	private common _sslReady 1

	#load the ssl library if possible when class is loaded
	if { [catch {package require tls} err ] } {
		puts "---------------------------------"
		puts "Could not load ssl library."
		puts "Using unencrypted authentication."
		set _sslReady 0
		puts "---------------------------------"
	} else {
		#register the https library
		http::register https 443 [list ::tls::socket]
	}

	# Methods
	public method createSession { userid password } {}
	public method endSession { { sessionId "" } } {}
	public method validateSession { sessionid, username } {}
	public method updateSession { sessionid isRecheckDb } {}
	public method getSessionID {} {}
	public method getTicket {} {}
	public method isSessionValid {} {}
	public method getCreationTime {} {}
	public method getLastAcessTime {} {}
	public method getUserId {} {}
	public method getUserName {} {}
	public method getUserType {} {}
	public method getBeamlines {} {}
	public method getUserPriv {} {}
	public method getBL { index} {}
	public method getUserStaff {} {}
	public method getMessage {} {}
	public method dump {} {}
	public method sslEnabled {} {return $_sslReady}
	public method getAllBeamlines {} {}

    ####### no id check ####
    public method getAuthorizedUserList { }

# Private 

	# Variables that can be reset by clearParams
	
	
	private variable m_sessionCreation ""
	private variable m_sessionLastAccessed ""
	private variable m_userId ""
	private variable m_userName ""
	private variable m_userType ""
	private variable m_beamlines ""
	private variable m_userPriv ""
	private variable m_officePhone ""
	private variable m_jobTitle ""
	private variable m_remoteAccess 0
	private variable m_enabled 0
	private variable m_userStaff 0
	# either smb_config_database or smb_urm
	private variable m_authMethod "smb_config_database" 

	private variable m_sessionId ""
	private variable m_sessionValid 0
	private variable m_bl "FFFFFFF"

	# Internal variables

	private variable m_appName "BluIce"
	private variable m_servletHost ""
	private variable m_servletPort ""
	private variable m_servletSecureHost ""
	private variable m_servletSecurePort ""
	private variable m_timeout 30000
	private variable m_message ""
	private variable m_allBeamlines ""
	
	private variable m_base64Chars [split "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/" {}]


	# Methods
	private method clearParams {} {}
	private method updateData { isParseCookie headers } {}
	private method debugHttp { nameOfArray }
	private method base64Encode { aString } {}
	private method base64Decode { aString } {}
	private method isTrue { aString } {}

	constructor { } {
	
      enforceUniqueness

      if {$_sslReady} {
         #give the config file the chance to override ssl use
         set _sslReady [::config getBluIceUseSsl]
       }
         
      #set _sslReady 0
    

      
        set m_servletSecureHost [::config getAuthSecureHost]
        set m_servletSecurePort [::config getAuthSecurePort]
        set m_servletHost [::config getAuthHost]
        set m_servletPort [::config getAuthPort]
        set m_timeout 30000 
	}

}


#return the singleton object
body AuthClient::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body AuthClient::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


# ===================================================
#
# AuthClient::clearParams --
#
#     See documentaion for details.
#
# Arguments:
#     proto           URL protocol prefix, e.g. https
#     port            Default port for protocol
#     command         Command to use to create socket
# Results:
#     list of port and command that was registered.
#
# ===================================================
::itcl::body AuthClient::clearParams {} {

	set m_sessionId ""
	set m_sessionValid 0
	set m_sessionCreation ""
	set m_sessionLastAccessed ""
	set m_userId ""
	set m_userName ""
	set m_userType ""
	set m_beamlines ""
	set m_userPriv ""
	set m_bl "FFFFFFF"
	set m_officePhone ""
	set m_jobTitle ""
	set m_remoteAccess 0
	set m_enabled 0
	set m_userStaff 0

}


# ===================================================
#
# AuthClient::createSession
#
# Creates a new session by logging on to the Authentication Gateway 
# server. Get an id for this session.
#
# Arguments:
#     userid           User login name
#     password         Password
#     isDbAuth         0 or 1. 1 if authentication is to be done against
#					   the User Resource Database; false if it is to be
#					   done against Beamline Configuration database.
# Results:
#     Returns 1 if successful. Returns 0 if authorization fails. Returns
#     an error if there is an error in the http transaction.
#
# ===================================================
::itcl::body AuthClient::createSession { userid password } {

	# Reset the internal parameters
	clearParams
	
	set m_message ""
	
	set m_userId $userid

	# encode the user id and password before sending it to the server
	set encodedStr [base64Encode $userid:$password]

	# Replace '=' character with a url encoded string.
#	set encodedStr [string replace $encodedStr "=" "%3D"]
	regsub -all {=} $encodedStr "%3D" urlEncodedStr

    
	# Set the url to be sent to the server
	if { $_sslReady && $m_servletSecureHost != ""} {
		set url "https://$m_servletSecureHost:$m_servletSecurePort/gateway/servlet/APPLOGIN?userid=$m_userId&passwd=$urlEncodedStr&AppName=$m_appName"
	} else {
		set url "http://$m_servletHost:$m_servletPort/gateway/servlet/APPLOGIN?userid=$m_userId&passwd=$urlEncodedStr&AppName=$m_appName"
	}
	#&AuthMehod=$m_authMethod
    puts "yangxurl $url"	
	log_note "yangxurl= $url"	
	
	set httpObjName ""
	
	# Send an HTTP request and block while waiting for a response.
	if { [catch {

		# Block until the transaction completes
		if { $m_timeout <= 0 } {
			# Block until we get a response
			set httpObjName [http::geturl $url]
		} else {
			# Block until we get a response or timeout
			set httpObjName [http::geturl $url -timeout $m_timeout]
		}

		# Convert the return value from http::geturl to a local array variable.
		upvar #0 $httpObjName httpObj

		# Current status: pending, ok, eof or reset
		set status $httpObj(status)

		# Response first line
		set replystatus $httpObj(http)

		# First word in the respone first line
		set replycode [lindex $replystatus 1]
		
		# prints out the http response
		#debugHttp $httpObjName
		
		set m_message $httpObj(body)

	} err] } {

		
		if { [string length $httpObjName] > 0 } {
			http::cleanup $httpObjName
		}
		return -code error "ERROR in AuthClient::createSession: $err"

	}
	
        
	if { $status!="ok" } {
	
		# http status is no ok.
		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::createSession: Got http status $status"
		
	} elseif { $replycode == 401 } {
	
		set m_message "Authorization failed"
		return 0
				
	} elseif { $replycode != 200 } {
	
		# http response code is not 200
		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::createSession: Got http response code $replycode"
                
	}
	
	# assume everything is ok
	# update member variables with the response header values.
	updateData 1 $httpObj(meta)
	set m_message "create session OK"
	http::cleanup $httpObjName

	return 1
		
	
	
}


# ===================================================
#
# AuthClient::endSession
#
# Ends the current session by calling the EndSession servlet.
#
# Arguments:
#     sessionId        Optional argument. Session id.
#
# Results:
#     Do not return a value if the session is ended successfully or if the session is already invalid.
#     Returns an error if there is an error in the http connection. An the result can not 
# 	  be determined.
#
# ===================================================
::itcl::body AuthClient::endSession { { sessionId "" } } {

	if { [string length $sessionId] > 0 } {
		set m_sessionId $sessionId
	}
	
	if { [string length $m_sessionId] < 1 } {
		return -code error "ERROR in AuthClient::updateSession: invalid sessionid"
	}
	
	if { $_sslReady && $m_servletSecureHost != ""} {
		set url "https://$m_servletSecureHost:$m_servletSecurePort/gateway/servlet/EndSession;jsessionid=$m_sessionId?AppName=$m_appName&AuthMethod=$m_authMethod"
    } else {
	    set url "http://$m_servletHost:$m_servletPort/gateway/servlet/EndSession;jsessionid=$m_sessionId?AppName=$m_appName&AuthMethod=$m_authMethod"
    }
	

	set httpObjName ""

	if { [catch {

		# Block until the transaction completes
		if { $m_timeout <= 0 } {
			# Block until we get a response
			set httpObjName [http::geturl $url]
		} else {
			# Block until we get a response or timeout
			set httpObjName [http::geturl $url -timeout $m_timeout]
		}

		# Convert the return value from http::geturl to a local array variable.
		upvar #0 $httpObjName httpObj

		# Current status: pending, ok, eof or reset
		set status $httpObj(status)

		# Response first line
		set replystatus $httpObj(http)

		# First word in the respone first line
		set replycode [lindex $replystatus 1]

#		debugHttp $httpObjName
		set m_message $httpObj(body)
		
	} err] } {

		if { [string length $httpObjName] > 0 } {
			http::cleanup $httpObjName
		}
		return -code error "ERROR in AuthClient::endSession:$err"

	}

	if { $status!="ok" } {
	
		# http status is no ok.
		
		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::endSession: Got http status $status"
		
	} elseif { $replycode!=200 } {
	
		# http response code is not 200

		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::endSession: Got http response code $replycode"
                
	} else {
	
		# assume everything is ok
		# update member variables with the response header values.
		updateData 0 $httpObj(meta)
		set m_message "end session OK: $httpObj(body)"
		http::cleanup $httpObjName
		
	}


}


# ===================================================
#
# AuthClient::validateSession
#
# Checks if the session id is valid.
#
# Arguments:
#     sessionId        Session id.
#     username         user name
#
# Results:
#     Returns 1 if the session is valid. Other wise returns false.
#     Returns an error if there is an error in the http connection and the 
#     status of the session cannot be determined. 
#
# ===================================================
::itcl::body AuthClient::validateSession { sessionid username } {
    puts "calling validateSession"

	clearParams
	
	updateSession $sessionid 1

    if {$m_userId != $username} {
	    clearParams
    }
	
	return $m_sessionValid
}


# ===================================================
#
# AuthClient::updateSession
#
# Updates the session data by calling the SessionStatus servlet.
# Also rechecks the database for beamline access if the recheckDatabase
# arameter is true. The session data is saved as data members.
#
# Arguments:
#     sessionId        Session id.
#     isRecheckDb      forces a recheck of beamline access if 1.
#
# Results:
#     Does not return a value if the func runs successfully.
#     Returns an error if there is an error in the http connection and the 
#     result cannot be determined. 
#
# ===================================================
::itcl::body AuthClient::updateSession { sessionid isRecheckDb } {

	clearParams

	set m_sessionId $sessionid
	
	if { [string length $m_sessionId] < 1 } {
		return -code error "ERROR in AuthClient::updateSession: invalid sessionid"
	}
	
	if { $_sslReady && $m_servletSecureHost != ""} {
		set url "https://$m_servletSecureHost:$m_servletSecurePort/gateway/servlet/SessionStatus;jsessionid=$m_sessionId?AppName=$m_appName&AuthMethod=$m_authMethod"
    } else {
	    set url "http://$m_servletHost:$m_servletPort/gateway/servlet/SessionStatus;jsessionid=$m_sessionId?AppName=$m_appName&AuthMethod=$m_authMethod"
    }
		


	if { $isRecheckDb == 1 } {
		append url "&ValidBeamlines=True"
	}

	set httpObjName ""

	if { [catch {

		# Block until the transaction completes
		if { $m_timeout <= 0 } {
			# Block until we get a response
			set httpObjName [http::geturl $url]
		} else {
			# Block until we get a response or timeout
			set httpObjName [http::geturl $url -timeout $m_timeout]
		}

		# Convert the return value from http::geturl to a local array variable.
		upvar #0 $httpObjName httpObj

		# Current status: pending, ok, eof or reset
		set status $httpObj(status)

		# Response first line
		set replystatus $httpObj(http)

		# First word in the respone first line
		set replycode [lindex $replystatus 1]
				
#		debugHttp $httpObjName
		set m_message $httpObj(body)
				
	} err] } {

		if { [string length $httpObjName] > 0 } {
			http::cleanup $httpObjName
		}
		return -code error "ERROR in AuthClient::updateSession: $err"

	}

	if { $status!="ok" } {
	
		# http status is no ok.
		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::updateSession: Got http status $status"
		
	} elseif { $replycode == 403 } {
	
		# authentication failed
		clearParams
		http::cleanup $httpObjName
		
	} elseif { $replycode!=200 } {
	
		# http response code is not 200
		http::cleanup $httpObjName
		return -code error "ERROR in AuthClient::updateSession: Got http response code $replycode"
                
	} else {
	
		# assume everything is ok
		# update member variables with the response header values.
		updateData 0 $httpObj(meta)
		set m_message "update session OK"
		http::cleanup $httpObjName
		
	}
	
}

::itcl::body AuthClient::getTicket { } {
	if {[string length $m_sessionId] < 1 } {
		log_error "ERROR in AuthClient::getTicket: invalid sessionid"
        return invalid
	}
    return [getTicketFromSessionId $m_sessionId]
}
# ===================================================
#
# AuthClient::updateData
#
# Update member variables with the response header values.
#
# Arguments:
#     isParseCookie weather or not to parse the cookie headers.
#     headers       An array of key and value for the response headers.
#
# Results:
#     Does not return a value if the func runs successfully.
#     Returns an error if there is an error in the http connection and the 
#     result cannot be determined. 
#
# ===================================================
::itcl::body AuthClient::updateData { isParseCookie headers } {

	foreach { key value } $headers {

		if { [string equal -nocase $key "Auth.SessionValid"] } {
					
		    set m_sessionValid [isTrue $value]
			 			
		} elseif { [string equal -nocase $key "Auth.SessionCreation"] } {
		
			set m_sessionCreation $value
		
		} elseif { [string equal -nocase $key "Auth.SessionAccessed"] } {
		
		    set m_sessionLastAccessed $value
		
		} elseif { [string equal -nocase $key "Auth.UserID"] } {
		
		    set m_userId $value
		
		} elseif { [string equal -nocase $key "Auth.UserName"] } {
		
		    set m_userName $value
		
		} elseif { [string equal -nocase $key "Auth.UserType"] } {
		
		    set m_userType $value
		
		} elseif { [string equal -nocase $key "Auth.Beamlines"] } {

		    set m_beamlines $value
		
		} elseif { [string equal -nocase $key "Auth.UserPriv"] } {
		
		    set m_userPriv $value
		
		} elseif { [string equal -nocase $key "Auth.BL"] } {
			
		    set m_bl $value
				
		} elseif { [string equal -nocase $key "Auth.OfficePhone"] } {
		
			set m_officePhone $value
			
		} elseif { [string equal -nocase $key "Auth.JobTitle"] } {
		
			set m_jobTitle $value
			
		} elseif { [string equal -nocase $key "Auth.RemoteAccess"] } {
		
		    set m_remoteAccess [isTrue $value]
			
		} elseif { [string equal -nocase $key "Auth.Enabled"] } {
		
		    set m_enabled [isTrue $value]
			
		} elseif { [string equal -nocase $key "Auth.UserStaff"] } {
		
		    set m_userStaff [isTrue $value]
		    
		} elseif { [string equal -nocase $key "Auth.AllBeamlines"] } {
		
		    set m_allBeamlines $value
		
		} elseif { [string equal -nocase $key "Set-Cookie"] } {
		
			if { $isParseCookie == 1 } {
					
				# Fine SessionID field in Set-Cookie header using regular expression
				if { [regexp {SMBSessionID=([1234567890ABCDEF]*);} $value match tmp] == 1 } {
					set m_sessionId $tmp
				}
				
			}
			
		} 
	
	}

	
}

# ===================================================
#
# AuthClient::getSessionID
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns the session id string 
#
# ===================================================
::itcl::body AuthClient::getSessionID {} {

	return $m_sessionId
	
}

# ===================================================
#
# AuthClient::isSessionValid
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns 1 if the session is valid, else returns 0.
#
# ===================================================
::itcl::body AuthClient::isSessionValid {} {

	return $m_sessionValid
	
}

# ===================================================
#
# AuthClient::getCreationTime
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns number of milliseconds since since midnight, Jan 1, 1970, UTC.
#
# ===================================================
::itcl::body AuthClient::getCreationTime {} {

	return $m_sessionCreation
	
}

# ===================================================
#
# AuthClient::getLastAcessTime
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns the time in millisecons since midnight, Jan 1, 1970, UTC.
#
# ===================================================
::itcl::body AuthClient::getLastAcessTime {} {

	return $m_sessionLastAccessed;
	
}

# ===================================================
#
# AuthClient::getUserId
#
# Returns the result of the latest http transaction.
#
# Returns login name of the user.
#
# Arguments:
#
# Results:
#     User's login name.
#
# ===================================================
::itcl::body AuthClient::getUserId {} {

	return $m_userId
	
}


# ===================================================
#
# AuthClient::getUserName
#
# Returns the result of the latest http transaction.
#
# Returns display name of the user.
# Displaty name is the first and last names of the user if a single
# userid was used, or if a Unix id was used, the user name found in the beamline
# configuration database (phase I) or the researchName found in the user resource
# database (phase II).
#
#
# Arguments:
#
# Results:
#     User's display name.
#
# ===================================================
::itcl::body AuthClient::getUserName {} {

	return $m_userName
	
}

# ===================================================
#
# AuthClient::getUserType
#
# Returns the result of the latest http transaction.
#
#
# Arguments:
#
# Results:
#     Returns the type (UNIX, WEB, and/or NT) of user.
#
# ===================================================
::itcl::body AuthClient::getUserType {} {

	return $m_userType
	
}


# ===================================================
#
# AuthClient::getBeamlines
#
# Returns the result of the latest http transaction.
#
# Returns a string in the form: "bl;bl;bl", as found in the Beamline Configuration Database.
# 
# For example, a response of "bl1-5;bl7-1;bl9-1;bl9-2;bl11-1" or "ALL" both
# mean the user is currently active at all beamlines. A response of "9-1"
# means the user is currently active only at beamline 9-1.
#
# Arguments:
#
# Results:
#     A string representing a list of beamline names 
#     this user can access in this session.
#
# ===================================================
::itcl::body AuthClient::getBeamlines {} {

	return $m_beamlines
	
}

# ===================================================
#
# AuthClient::getUserPriv
#
# Returns the result of the latest http transaction.
#
#
# Arguments:
#
# Results:
#     Returns privilege level of the user. Deprecated. Always returns 0.
#
# ===================================================
::itcl::body AuthClient::getUserPriv {} {

	return $m_userPriv
	
}

# ===================================================
#
# AuthClient::getBL
#
# Returns the result of the latest http transaction.
#
# Checks if the given beam line is accessible by this user session.
# The parameter index indicates which beamline to check where 0=1-5, 1=7-1,
# 2=9-1, 3=9-2, 4=11-1, 5=11-3.
#
# Arguments:
#
# Results:
#     Returns 1 if the given beamline is accessible by this session.
#
# ===================================================
::itcl::body AuthClient::getBL { index } {

	if { [string index $m_bl $index] == "T" } {
		return 1
	} 
	
	return 0
	
}


# ===================================================
#
# AuthClient::getUserStaff
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns 1 if the user is a staff, else returns 0
#
# ===================================================
::itcl::body AuthClient::getUserStaff {} {

	return $m_userStaff
	
}


# ===================================================
#
# AuthClient::getMessage
#
# Returns the result of the latest http transaction.
#
# Arguments:
#
# Results:
#     Returns the transaction message.
#
# ===================================================
::itcl::body AuthClient::getMessage {} {

	return $m_message
	
}


# ===================================================
#
# AuthClient::getAllBeamlines
#
# Returns names of all available beamlines separated 
# by commas.
#
# Arguments:
#
# Results:
#     Returns names of all available beamlines separated 
# 	  by commas.
#
# ===================================================
::itcl::body AuthClient::getAllBeamlines {} {

	return $m_allBeamlines
	
}

::itcl::body AuthClient::getAuthorizedUserList { } {
    set beamlineID [::config getConfigRootName]
	if { $_sslReady && $m_servletSecureHost != ""} {
		set url "https://$m_servletSecureHost:$m_servletSecurePort/gateway/servlet/BeamlineUsers?beamline=$beamlineID&userName=$m_userId&accessID=$m_sessionId"
	} else {
		set url "http://$m_servletHost:$m_servletPort/gateway/BeamlineUsers?beamline=$beamlineID&userName=$m_userId&accessID=$m_sessionId"
	}

    set token [http::geturl $url -timeout 2000]
    upvar #0 $token state
    checkHttpStatus $token
    array set meta $state(meta)
    http::cleanup $token

    if {![info exists meta(blusers.users)]} {
        return {}
    }
    return [split $meta(blusers.users) ";"]
}

# ===================================================
#
# AuthClient::dump
#
# Prints out values of the member variables.
#
#
# Arguments:
#
# Results:
# 	The function does not return a value.   
#
# ===================================================
::itcl::body AuthClient::dump {} {

	puts "START AuthClient::dump"
	puts "sessionId           = $m_sessionId"
	puts "sessionValid        = $m_sessionValid"
	puts "sessionCreation     = $m_sessionCreation"
	puts "sessionLastAccessed = $m_sessionLastAccessed"
	puts "userId              = $m_userId"
	puts "userName            = $m_userName"
	puts "userType            = $m_userType"
	puts "beamlines           = $m_beamlines"
	puts "userPriv            = $m_userPriv"
	puts "bl                  = $m_bl"
	puts "appName             = $m_appName"
	puts "userStaff           = $m_userStaff"
	puts "allbeamlines        = $m_allBeamlines"

	puts "servletHost         = $m_servletHost"
	puts "servletPort         = $m_servletPort"
	puts "message             = $m_message"
	puts "END AuthClient::dump"
	
}


# ===================================================
#
# AuthClient::base64Decode
#
# Utility function to decode a string from base64 encoded string
#
#
# Arguments:
#     aString       Base64 encoded string to be decoded
#
# Results:
# 	Decoded string  
#
# ===================================================
::itcl::body AuthClient::base64Decode { aString } {

    set output {}
    set group 0
    set j 18
    foreach char [split $aString {}] {
    
		if [string compare $char "="] {
			set bits [lindex $m_base64Chars $char]
			set group [expr {$group | ($bits << $j)}]
		}

		if {[incr j -6] < 0} {
			scan [format %06x $group]] %2x%2x%2x a b c
			append output [format %c%c%c $a $b $c]
			set group 0
			set j 18
		}
		
    }
    
    return $output
}

# ===================================================
#
# AuthClient::base64Decode
#
# Utility function to encode a string in base64 
#
#
# Arguments:
#     aString       Input string to be encoded
#
# Results:
# 	Base64 encoded string  
#
# ===================================================
::itcl::body AuthClient::base64Encode { aString } {


    set result {}
    set state 0
    set length 0
    foreach {c} [split $aString {}] {
	scan $c %c x
	switch [incr state] {
	    1 {	append result [lindex $m_base64Chars [expr {($x >>2) & 0x3F}] ] }
	    2 { append result [lindex $m_base64Chars [expr {(($old << 4) & 0x30) | (($x >> 4) & 0xF)}] ] }
	    3 { append result [lindex $m_base64Chars [expr {(($old << 2) & 0x3C) | (($x >> 6) & 0x3)}] ]
	    append result [lindex $m_base64Chars [expr {($x & 0x3F)}] ]
	    set state 0}
	}
	set old $x
	incr length
	if {$length >= 72} {
	    append result \n
	    set length 0
	}
    }
    set x 0
    switch $state {
	0 { # OK }
	1 { append result [lindex $m_base64Chars [expr {(($old << 4) & 0x30)}] ]== }
	2 { append result [lindex $m_base64Chars [expr {(($old << 2) & 0x3C)}] ]= }
    }
    
    return $result

}

# ===================================================
#
# AuthClient::istrue
#
# Utility function to return 1 or 0.
#
#
# Arguments:
#     aString       Base64 encoded string to be decoded
#
# Results:
# 	1 if the input string is T or TRUE or Y or YES. Case insensitive.
#   0 otherwise
#
# ===================================================
::itcl::body AuthClient::isTrue { aString } {

    if { [string compare -nocase $aString "t"] == 0 } {
    	return 1
    } elseif { [string compare -nocase $aString "true"] == 0 } {
    	return 1
    } elseif { [string compare -nocase $aString "y"] == 0 } {
    	return 1
    } elseif { [string compare -nocase $aString "yes"] == 0 } {
    	return 1
    }
	     
    return 0
}


# ===================================================
#
# debugHttp
#
# Print out http 
#
# ===================================================
::itcl::body AuthClient::debugHttp { httpObjName } {

	if { [catch {

		upvar $httpObjName httpObj

		puts "url         => $httpObj(url)"
		puts "totalsize   => $httpObj(totalsize)"
		puts "currentsize => $httpObj(currentsize)"
		puts "type        => $httpObj(type)"
#		puts "error       => $httpObj(error)"
		puts "status      => $httpObj(status)"
		
		puts "http        => $httpObj(http)"
		foreach { key value} $httpObj(meta) {
			puts "header      => $key: $value"
		}
		puts "body        => $httpObj(body)"
	
	} err] } {

	}
}
