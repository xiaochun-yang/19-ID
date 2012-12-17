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

# Requires these two source files
#source $AUTH_DIR/httpsmb.tcl
#source $AUTH_DIR/AuthClient.tcl


set loginOk 0

###################################################################
#
# Dialog_Create
# Create a new dialog window (if it does not already exists) 
# or make the existing dialog window visible.
#
###################################################################
proc Dialog_Create { top title args } {

	global dialog
	if [winfo exists $top] {
	
		switch -- [wm state $top] {
			normal {
				# raise a burried window
				raise $top
			}
			withdrawn -
			iconic {
				# open can restore geometry
				wm deiconify $top
				catch { wm geometry $top $dialog(geo,$top) }
			}
		}
		return 0
	
	} else {
	
		eval { toplevel $top } $args
		wm title $top $title
		return 1
	
	}

}


###################################################################
#
# Dialog_Wait
# Make this dialog window behave like a modal dialog. The main
# application is paused until the dialog is dismissed when the
# user clicks OK or cancel button or hits <return> key in the 
# password entry box.
#
###################################################################
proc Dialog_Wait { top varName { focus {} } } {

	upvar $varName var

	
	# Poke the variable if the user nukes the window
	bind $top <Destroy> [list set $varName 0]
	
	# Grab focus for the dialog
	if { [string length $focus] == 0 } {
		set focus $top
	}
	
	set old [focus -displayof $top]
	focus $focus
	catch { tkwait visibility $top }
	catch { grab $top }
	
	# Wait for the dialog to complete 
	puts "waiting for login password..."
	tkwait variable $varName
	puts "Got password"
	catch { grab release $top }
	focus $old
	
}


###################################################################
#
# Dialog_Dismiss
# Make the dialog disappear without deleting it.
#
###################################################################
proc Dialog_Dismiss { top } {

	global dialog
	# Save current size and position
	catch {
			
		# window may have been deleted
		set dialog(geo,$top) [wm geometry $top]
		wm withdraw $top
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
proc Dialog_Login { host port {timeout 5000} } {

	global env
	global loginOk
	
	# dialog name
	set f .login
		
	
	# Create a modal dialog
	if [Dialog_Create $f "Login" -borderwidth 5] {
	
		frame $f.line1
		label $f.line1.userLabel -text "User" 
		entry $f.line1.usernameEntry -state disabled -bg gray -textvariable usernameVar
		pack $f.line1.userLabel -side left
		pack $f.line1.usernameEntry -side right -fill x

		
		frame $f.line2
		label $f.line2.passwordLabel -text "Password"
		entry $f.line2.passwordEntry -show *  -textvariable passwordVar
		bind $f.line2.passwordEntry <Return> { set loginOk 1; break }
		bind $f.line2.passwordEntry <Control-c> { set loginOk 0; break; }
		pack $f.line2.passwordLabel -side left
		pack $f.line2.passwordEntry -side right -fill x

#		frame $f.line3
#		checkbutton $f.line3.gDontAskAgain -text "Don't ask again. I will work offline for now." -variable gDontAskAgain
#		pack $f.line3.gDontAskAgain -side left -fill x

		frame $f.line4
		set b [frame $f.line4.buttons]
		pack $f.line4.buttons -side bottom -fill x
		button $b.ok -text OK -command { set loginOk 1 }
		button $b.cancel -text Cancel -command { set loginOk 0}
		pack $b.ok -side left
		pack $b.cancel -side left
		
		pack $f.line1 -side top -pady 2 -fill x
		pack $f.line2 -side top -pady 2 -fill x
##		pack $f.line3 -side top -pady 2 -fill x
		pack $f.line4 -side top -pady 5
		
	} 
	
	
	# initialize user entry
	upvar #0 [$f.line1.usernameEntry cget -textvariable] user
	set user $env(USER)
	
	# initialize password entry
	upvar #0 [$f.line2.passwordEntry cget -textvariable] password
	set password ""

	# Wait for the variable loginOk to be set.
	# Happens when the user clicks the OK or cancel button
	# or hits the <return> key
	Dialog_Wait $f loginOk $f.line2.passwordEntry
	
	# Hide the dialog
	Dialog_Dismiss $f
	
	
	# If the user clicks ok, the use the password
	# to create a session
	if { $loginOk } {
	
		# we don't check if the password string is empty 
		# since some login may not have a password
		
		# Create a client to connect to the
		# authentication server
		AuthClient client $host $port $timeout

		# Create a session from user name and password
		if { [client createSession $user $password] == 1 } {

			# get the session id for this session
			set sessionId [client getSessionID]

			# Delete the client object
			itcl::delete object client

			return $sessionId

		}

		# Delete the client object
		set errStr [client getMessage]
		itcl::delete object client
		return -code error $errStr
		
	
	}
	
	# The user clicks Cancel.
	return -code error "Login cancelled"

}
