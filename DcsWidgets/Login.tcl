###################################################################
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
###################################################################

# login.tcl provides Dialog_Login method which brings up a dialog box
# for the user to type in a password and get back a session id.
#
# Example:
#
#	if { [catch {
#		
#		set session [Dialog_Login smb.slac.stanford.edu 8084]
#		puts "session = $session"
#				
#	} err] } {
#		puts $err
#		puts "Login failed"
#		exit	
#	}
#
# load standard packages

package provide DCSLogin 1.0
package require DCSTitledFrame

package require Iwidgets

# Requires these two source files
package require http
package require DCSAuthClient

set _loginDialogWait 0

class DCS::Login {
	inherit itk::Widget
	
	itk_option define -validSessionCallback validSessionCallback ValidSessionCallback ""
	itk_option define -controlSystem controlSystem ControlSystem "::dcss"

	public method handleLogin
	public method handleCancel
	public method wait
	public method isOk
	
	private method clearPassword
	public proc storeSessionId

	private variable _client
	private variable m_ok

	
	constructor { args } {
		global env
		
		itk_component add frame {
			DCS::TitledFrame $itk_interior.label 
		} {}
		
		set cs [$itk_component(frame) childsite]

		pack $cs -expand 1 -fill both
		
		itk_component add userLabel {
			label $cs.userLabel -text "User"
		} {}
 
		itk_component add userEntry {
			entry $cs.userEntry -state normal -bg white
		} {}

		itk_component add passwordLabel {
			label $cs.passwordLabel -text "Password"
		} {}
 
		itk_component add passwordEntry {
			entry $cs.passwordEntry -state normal -bg white -show *
		} {}

		set buttonFrame [frame $cs.bf] 

		itk_component add ok {
			button $buttonFrame.ok -text "Ok" -state normal -command "$this handleLogin"
		} {}
		
		itk_component add cancel {
			button $buttonFrame.cancel -text "Cancel" -state normal -command "$this handleCancel"
		} {}

		grid $itk_component(frame) -row 0 -column 0 -sticky news

		grid $itk_component(userLabel) -row 0 -column 0 -sticky e
		grid $itk_component(userEntry) -row 0 -column 1 -sticky ew
		grid $itk_component(passwordLabel) -row 1 -column 0 -stick e
		grid $itk_component(passwordEntry) -row 1 -column 1 -sticky ew

		grid $buttonFrame -row 2 -column 0 -columnspan 2

		grid $itk_component(ok) -row 0 -column 0 -sticky e
		grid $itk_component(cancel) -row 0 -column 1 -sticky w

		#insert the current users name into the dialog box
		eval itk_initialize $args
		$itk_component(userEntry) insert 0 $env(USER)

		bind $itk_component(passwordEntry) <Return> "$this handleLogin ; break"
		bind $itk_component(passwordEntry) <Control-c> "$this handleCancel ; break"

		# Create a client to connect to the authentication server
		set _client [AuthClient::getObject]

		if { [$_client sslEnabled] } {
			$itk_component(frame) configure -labelText "Beamline Login" 
		} else {
			$itk_component(frame) configure -labelText "Beamline Login (INSECURE)" 
		}
				
		# Login maybe called before ::dcss is created.
		if { [info exists $itk_option(-controlSystem)] } {
			$itk_option(-controlSystem) addLoginWidget $this
		}
	}

	destructor {
	}
}


###################################################################
# 
# Dialog_Login
# Creates a modal dialog for entering a password and get
# a session id from the authentication server.
# If the user clicks the cancel button, the function
# will return 0 indicating that the login fails.
# If the user clicks the OK button or clicks the <return>
# key, the user name and password will be sent to the
# the authentication server. If the authentication is
# successful, the function will return the session id.
# Otherwise it will throw an exception.
# 
###################################################################
body DCS::Login::handleLogin {} {

	global _loginDialogWait

	# initialize user entry
	set user [$itk_component(userEntry) get]
	set password [$itk_component(passwordEntry) get]
	
	# we don't check if the password string is empty 
	# since some login may not have a password

	# Create a session from user name and password
	set authorized [$_client createSession $user $password ]
	clearPassword
	
	#guard against unauthorized attempts
	if { ! $authorized } {
		set errStr [$_client getMessage]
		return -code error $errStr
	}

	# get the session id for this session
	set sessionId [$_client getSessionID]
	
	if {$itk_option(-validSessionCallback) != "" } {
		eval $itk_option(-validSessionCallback) $user $sessionId
	} else {
		if { ![$_client isSessionValid] } {
			return -code "Invalid session"
		}
	}

	storeSessionId $user $sessionId
    #puts "LOGIN [string range $sessionId 0 6]"
		
	set m_ok 1
	set _loginDialogWait 1
	
	return $sessionId	
}


body DCS::Login::storeSessionId {user_ sessionId_ } {
	global env

	if { $env(USER) != $user_ } {
		#can't cache the session id for a different user
		return
	}

	if [catch {
		#create the directory
		set directory [file join ~$user_ .bluice] 
        set directory [file native $directory]
		file mkdir $directory
		#make the directory readable only by this user
		file attributes $directory -permissions 0700

		#open the file for storing the sessionId
		set filename [file join $directory session]
		set fileId [open $filename w]
		puts $fileId $sessionId_
		close $fileId

		#make the file readable only by this user
		file attributes $filename -permissions 0600
	} err ] {
		puts "-----------------------------------"
		puts "Could not cache the sessionId: $err"
		puts "-----------------------------------"
		return ""
	}
}

body DCS::Login::handleCancel {} {

	global _loginDialogWait

	clearPassword
		
	set m_ok 0
	set _loginDialogWait 0
}

body DCS::Login::clearPassword {} {
	$itk_component(passwordEntry) delete 0 end
}

body DCS::Login::isOk { } {

	return $m_ok
	
}

body DCS::Login::wait {} {

	global _loginDialogWait

	tkwait variable _loginDialogWait
}



