#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}
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

# load the required standard packages
package require Itcl
namespace import ::itcl::*



#This function verifies the TCLLIBPATH and generates the
#  global directory variables using relative offsets from this path.
proc getBluIceDirectories {} {
	global env
	global BLC_DIR
	global BLC_DATA
	global BLC_IMAGES
	global DCS_DIR

	#set the variable to the tail end name of the blu-ice directory
	set BluIceDirectoryName BluIceWidgets
	set DCSWidgetsDirectoryName DcsWidgets

	
	set foundBLCDirectory 0
	set foundDCSDirectory 0

	if ![info exists env(TCLLIBPATH)] {
		reportBadTCLLIBPATH $BluIceDirectoryName $DCSWidgetsDirectoryName
	}

	#Search through the TCLLIBPATH environment variable
	#  for the Blu-ice and DCSWidgets directories.
	foreach directory $env(TCLLIBPATH) {
		
		#looking for the blu-ice directory
		if { [file tail $directory] == $BluIceDirectoryName} {
			set BLC_DIR $directory
			set BLC_DATA [file join $directory data]
			set BLC_IMAGES [file join $directory images]
			
			#go up one directory level to get the DCS root directory
			set DCS_DIR [file dirname $directory]

			set foundBLCDirectory 1
		}
		
		#looking for the Dcs Widgets directory
		if { [file tail $directory] == $DCSWidgetsDirectoryName } {
			set foundDCSDirectory 1
		}
	}
	
	#Guard against incorrectly defined TCLLIBPATH environment variable
	if { $foundDCSDirectory == 0 || $foundBLCDirectory == 0 } {
		reportBadTCLLIBPATH $BluIceDirectoryName $DCSWidgetsDirectoryName
	}
}

proc reportBadTCLLIBPATH { bluiceDir_  widgetDir_ } {
	global env

	puts ""
	puts "---------------------------------------------------------------------------------------"
	puts "The TCLLIBPATH environment variable should define the blu-ice and DcsWidgets directory."
	puts ""
	puts "Example:"
	if { [file tail $env(PWD)] == $bluiceDir_} {
		#print the current directory, this user is probably a developer
		puts "setenv TCLLIBPATH \"$env(PWD) [file join [file dirname $env(PWD)] $widgetDir_] /usr/local/lib\" "
	} else {
		puts "setenv TCLLIBPATH \"/usr/local/dcs/$widgetDir_ /usr/local/dcs/$bluiceDir_ /usr/local/lib\" "
	}
	puts "---------------------------------------------------------------------------------------"
	puts ""
		
		exit
}

proc setStandardOptions {} {
	option add *foreground black
	option add *background lightgrey
	option add *MotorViewEntry*menuBackground white
	option add *MotorViewEntry*font  "*-helvetica-bold-r-normal--12-*-*-*-*-*-*-*"
	option add *MotorViewEntry*Mismatch  red
	option add *MotorViewEntry*Match  black
	option add *MotorViewEntry*activebackground #c0c0ff
	option add *Entry*activebackground white
	option add *Button*background #c0c0ff
	option add *DisabledForeground gray55 
	option add *OptimizeButton*background #c0c0ff
	option add *OptimizeButton*activebackground #c0c0ff
	option add *MenuEntry*Label*activebackground #c0c0ff
	option add *MenuEntry*Label*background #c0c0ff
}

proc loadConfig {beamline_ } {
	global DCS_DIR

	config setConfigDir [file join $DCS_DIR dcsconfig data]
	config setConfigRootName $beamline_
   if {[catch {config load } err] } {
      printAvailableConfigs 
      exit
   } 
}

proc printAvailableConfigs {} {

	global DCS_DIR
  
   puts "Possible beamline names are:"

   foreach configFile [glob [file join $DCS_DIR dcsconfig data *.config]] {
      set configFilename [file tail $configFile]
      set beamlineId [lindex [split $configFilename .] 0]
      if { $beamlineId == "default"} continue
      puts $beamlineId
   }

}


#=============================================================
#
# Check if the session is valid
#
#=============================================================
proc validateSession { _user _sessionId } {

	set client [AuthClient::getObject]

	if { [catch {$client updateSession $_sessionId 1} err ] } {
		puts $err
		return -code $err
	}

	if { ![$client isSessionValid] } {
		return 0
	}
	
#	if { $_user != [$client getUserId] } {
#		return 0
#	}
	
	return 1
	
}

#=============================================================
#
# Open a login window and wait for the user to login or cancel.
#
#=============================================================
proc login { } {
	global dialog

	if { [catch {
		set loginDialog [DCS::Login .loginDialog]
		# Open login dialog
		pack .loginDialog
		$loginDialog wait
		pack forget .loginDialog

		# If the user clicks cancel then we will exit.
		if { [$loginDialog isOk] == 0 } {
			puts "Login cancelled"
			exit
		}
				

	} err] } {

		pack forget .loginDialog
		puts $err
		puts "Login failed"
		return -code $err

	}
	
}


#=============================================================
#
# Open a beamline chooser dialog and wait for the user
# to choose a beamline or cancel.
#
#=============================================================
proc chooseBeamline { beamlines } {

	if { [catch {
		set beamlineDialog [DCS::BeamlineChooser .beamlineDialog $beamlines]
		# Open login dialog
		pack .beamlineDialog
		$beamlineDialog wait
		pack forget .beamlineDialog

		# If the user clicks cancel then we will exit.
		if { [$beamlineDialog isOk] == 0 } {
			puts "No beamline was chosen. Program exited."
			exit
		}

		set bl [$beamlineDialog getBeamline]

	} err] } {

		pack forget .beamlineDialog
		puts "Caught error: $err"
		puts "Failed to choose beamline. Program exited."
		exit

	}
	
	
	return $bl
}

#=============================================================
#
# Copied from DcssUserProtocol::connect
# Check if the stored session id is valid.
# At this point we don't to which beamline to connect.
# 1) Check if there is a valid session id for this user.
# 	1.1) If there is a valid session id in /home/<user>/.bluice/session
#    	file then get the beamline from the auth server
#    	for the given session id.
# 		1.1.1) If the user has access to only one beamline
#    		then set the beamline to that one and we are done.
# 		1.1.2) If this session has access to more than one beamline
#    		then open a dialog box and list out all available beamlines.
# 	1.2) If there isn't a valid session id then open a login dialog box.
#      The auth server will create a new session id for the given 
#      user name and password, and will tell us to which beamlines
#      the user has access.
# 		1.2.1) If the user has access to only one beamline
#    		then set the beamline to that one and we are done.
# 		1.2.2) If this session has access to more than one beamline
#    		then open a dialog box and list out all available beamlines.

# Load default config so that we get the authentication server info
#
#=============================================================
proc getSessionAndBeamline { } {

	global env

	# Need to load default config first
	# in order to find out about auth server
	# host and port before knowing the beamline
	# name.
	loadConfig "default"

	#try to get the stored value if possible
	set _sessionId [DCS::DcssUserProtocol::getStoredSessionId]
	if { $_sessionId != "" } {
		if { ![validateSession $env(USER) $_sessionId] } {
			puts "Cached session id is invalid."
			set _sessionId ""
		}
	}

	# No valid session id
	# Open a login dialog box and ask the user to login
	# Wait until user clicks ok or cancel in the login dialog
	# before proceeding.
	if {$_sessionId == "" } {
		puts "User needs to login."
		login
	} 

	# Get beamline(s) from auth server
	set auth [AuthClient::getObject]
    set _beamlines [$auth getBeamlines]
   puts "beamlines = $_beamlines"

	if { $_beamlines == "NONE" || $_beamlines == "" } {
			set msg "User $env(USER) has no permission to access any beamline at this time. Please contact support staff."
			puts "$msg"
			# Hide root window
			wm withdraw .
			# Display eror message
			tk_messageBox -message "$msg" -title "Blu-Ice Message Window" -icon error -type ok
			exit
	}

    if { $_beamlines == "ALL" } {
    	set _beamlines [$auth getAllBeamlines]
    }
    
    # In case there are more than one beamlines
    set allBeamlines {}
    foreach {bl} [split $_beamlines {;}] {
    	lappend allBeamlines $bl
    }
    
    if { [llength $allBeamlines] == 1 } {
    	return $bl
    }
    
   set bl [chooseBeamline $allBeamlines]
    
    return $bl

}


setStandardOptions
getBluIceDirectories
package require DCSConfig
package require DCSBeamlineChooser
package require DCSAuthClient
package require DCSProtocol
package require DCSLogin
DCS::Config config

#main
if { [catch {

	set style classic

	set argc [llength $argv]
	
	if { $argc == 1 } {	
	} elseif { $argc == 2} {
		set style [lindex $argv 1]
	} else {
	
		# No beamline is specified in the command line
		set beamline [getSessionAndBeamline]
	
	}
	
	if { $argc != 0} {
   		#beamline is the first argument when starting the program
   		set beamline [lindex $argv 0]
   	}

	# Load config for the selected beamline
	loadConfig $beamline
	
	set bluiceHost [config getBluIceDefaultHost]

    set fifoName $env(FIFO_NAME)

	if { $bluiceHost == "" } {
		puts "Cannot find config bluice.defaultHost for beamline: $beamline"
        set bluiceHost $env(HOSTNAME)
		exit
	} else {
	

	# Launch an xterm and ssh to the beamline computer
	# then run bluice from there.

    }
	
	puts "Starting bluice on $bluiceHost"
    set fifo [open $fifoName w]
    puts $fifo "$bluiceHost $beamline"
    close $fifo
    puts "Done"
	exit

} err] } {
   global errorInfo
   puts $errorInfo	

	puts $err
	exit
}

#end main
