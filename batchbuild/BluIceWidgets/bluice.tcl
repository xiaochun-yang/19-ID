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
package require Iwidgets
### This will load our own panedwindow using class IPanedwindow
package require IPanedwindow
namespace import ::itcl::*
package require DCSUtil
package require DCSProtocol
package require DCSVideo


#This function verifies the TCLLIBPATH and generates the
#  global directory variables using relative offsets from this path.
proc getBluIceDirectories {} {
	global env
	global BLC_DIR
	global BLC_DATA
	global BLC_IMAGES
	global DCS_DIR
	global TCL_CLIBS_DIR
    global auto_path

	#set the variable to the tail end name of the blu-ice directory
	set BluIceDirectoryName BluIceWidgets
	set DCSWidgetsDirectoryName DcsWidgets

	
	set foundBLCDirectory 0
	set foundDCSDirectory 0

	if ![info exists env(TCLLIBPATH)] {
		reportBadTCLLIBPATH $BluIceDirectoryName $DCSWidgetsDirectoryName
	}

    set MACHINE [getMachineType]

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

			set TCL_CLIBS_DIR [file join $DCS_DIR tcl_clibs $MACHINE]
			
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
	} else {
        if {[lsearch -exact $auto_path $DCS_DIR] < 1} {
            set auto_path [linsert $auto_path 0 $DCS_DIR]
        }
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

proc printUsage {} {
	puts "-----------------------------------------------------------------------------"
	puts "Usage: bluice.tcl beamline \[classic|developer|videoOnly|chatOnly\]"
	puts " "
   printAvailableConfigs
}

proc printStyles {} {
	printUsage
	puts "Valid Blu-Ice styles are:"
	puts "   classic -  Complete Blu-Ice Gui for users and Staff."
	puts "   developer - Start with Setup tab only.  Widgets can be opened by the user."
	puts "   videoOnly - A light weight application for seeing beamline video."
	puts "   chatOnly - A light weight application for chatting."
	puts "   diffimage - An application for viewing diffraction images."
	puts "-----------------------------------------------------------------------------"
}
proc createControlSystemInterface {} {
package require DCSDevice

	set dcssHostName [config getDcssHost]
	set dcssPort [config getDcssGuiPort]
	set authProtocol [config getDcssAuthProtocol]

	switch $authProtocol {
		0 {
			puts "----------------------------------------------------------------"
			puts "Did not find dcss.authProtocol definition in configuration file."
			puts "Attempting authentication protocol 2."
			puts "----------------------------------------------------------------"
			set authProtocol 2
		}
		1 {
			loadAuthenticationProtocol1Library
		}
		2 {
		}
		default {
			puts "Unknown authentication protocol: $authProtocol"
			exit
		}
	}
	
	DCS::DcssUserProtocol dcss \
		 $dcssHostName \
		 $dcssPort \
         -useSSL [::config getDcssUseSSL] \
		 -authProtocol $authProtocol \
		 -_reconnectTime 1000 \
		 -callback "" \
		 -networkErrorCallback ""

        dcss registerLogger [DCS::Logger::getObject]
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


proc printConfig {} {
	puts "config:"
	puts "	configFile=[config getConfigFile]"
	puts "	defConfigFile=[config getDefaultConfigFile]"
	puts "	useDefault=[config isUseDefault]"
	
	puts "auth:"
	puts "	host=[config getAuthHost]"
	puts "	port=[config getAuthPort]"

	puts "imperson:"
	puts "	host=[config getImpersonHost]"
	puts "	port=[config getImpersonPort]"
	
	puts "imgsrv:"
	puts "	host=[config getImgsrvHost]"
	puts "	guiPort=[config getImgsrvGuiPort]"
	puts "	httpPort=[config getImgsrvHttpPort]"
}

#=============================================================
#
# Check if the session is valid
#
#=============================================================
proc validateSession { _user _sessionId } {

	set client [AuthClient::getObject]

	return [$client validateSession $_sessionId $_user]
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
proc chooseBeamline { beamlines title } {

	if { [catch {
		set beamlineDialog [DCS::BeamlineChooser .beamlineDialog $beamlines $title]
		# Open login dialog
		pack .beamlineDialog
		$beamlineDialog wait
		pack forget .beamlineDialog

		# If the user clicks cancel then we will exit.
		if { [$beamlineDialog isOk] == 0 } {
			puts "No $title was chosen. Program exited."
			exit
		}

		set bl [$beamlineDialog getBeamline]

	} err] } {

		pack forget .beamlineDialog
		puts "Caught error: $err"
		puts "Failed to choose $title. Program exited."
		exit

	}

    destroy .beamlineDialog
	
	
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
    
    set bl [chooseBeamline $allBeamlines Beamline]
    
    return $bl

}

proc loadSessionName { } {
    set fileName [file join ~ .bluice nameList]
    set fileName [file native $fileName]
    if {[catch {open $fileName} h]} {
        return ""
    }
    set nl [read -nonewline $h]
    close $h

    set nl [split $nl \n]
    set ll [llength $nl]
    switch -exact -- $ll {
        0 {
            return ""
        }
        1 {
            return $nl
        }
        default {
            return [chooseBeamline $nl NickName]
        }
    }
}


global gEncryptSID
set gEncryptSID 0
#### to force quit if user is not staff trying developer mode
global gBluIceStyle
set gBluIceStyle classic


setStandardOptions
getBluIceDirectories
package require DCSConfig
package require DCSBeamlineChooser
package require DCSAuthClient
package require DCSLogin
DCS::Config config

#main
if { [catch {

	set style classic
    set extra1 ""

	set argc [llength $argv]

    if {$argc == 0} {
		set beamline [getSessionAndBeamline]		
    }
    if {$argc > 0} {
   		set beamline [lindex $argv 0]
    }
    if {$argc > 1} {
		set style [lindex $argv 1]
        set gBluIceStyle $style
    }
    if {$argc > 2} {
        set extra1 [lindex $argv 2]
    }

    global gNickName
    if {$style == "chatOnly"} {
        set gNickName chatOnly
        if {$extra1 != ""} {
            set gNickName "chatOnly $extra1"
        }
    } else {
        set gNickName [loadSessionName]
    }

    puts "NickName: $gNickName"


   #load the configuration for the beamline
   loadConfig $beamline

    ###DCSS has the same name as this
    global gUseOneTimeTicket
    set gUseOneTimeTicket [::config getBluIceUseOneTimeTicket]

    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorEnergy
    global gMotorDistance
    global gMotorBeamStop
    global gMotorPhi
    global gMotorOmega
    global gMotorVert
    global gMotorHorz
    global gBeamHappyExists
    global gInlineCameraExists
    global gVideoUseStep
    global gSampleMotorSerialMove

    set gMotorBeamWidth  [::config getMotorRunBeamWidth]
    set gMotorBeamHeight [::config getMotorRunBeamHeight]
    set gMotorEnergy     [::config getMotorRunEnergy]
    set gMotorDistance   [::config getMotorRunDistance]
    set gMotorBeamStop   [::config getMotorRunBeamStop]
    set gMotorPhi        [::config getMotorRunPhi]
    set gMotorOmega      [::config getMotorRunOmega]
    set gMotorVert       [::config getMotorRunVert]
    set gMotorHorz       [::config getMotorRunHorz]

    set beamHappyCfg     [::config getStr beam_happy]
    if {[llength $beamHappyCfg] >= 2} {
        set gBeamHappyExists 1
    } else {
        set gBeamHappyExists 0
    }

    set gInlineCameraExists 0
    set inlineLightCfg   [::config getStr light.inline_on]
    if {[llength $inlineLightCfg] >= 2} {
        foreach {board channel} $inlineLightCfg break
        if {$board >=0 && $channel >= 0} {
            set gInlineCameraExists 1
        }
    }

    set gVideoUseStep [::config getInt "bluice.videoUseStep" 0]
    set gSampleMotorSerialMove [::config getInt "sample_move_serial" 0]

    ####global filter label mapping
    DCS::DeviceLabelMap filterLabelMap [config getStr bluice.filterLabelMap]

	#set gBeamline(title)					"BLU-ICE    Beamline 11-1   ****** SIMULATION*********"
	createControlSystemInterface

package require DCSOperationManager

} err] } {
   global errorInfo
   puts $errorInfo	

	puts $err
	exit
}

wm title . "Blu-Ice 5.0 for $beamline."





puts "Building GUI..."
switch $style {

	developer {
package require BLUICECompleteGui
		startSetupTab ::config
	}

	classic {
package require BLUICECompleteGui
		startBluIce ::config
	}
	
	videoOnly {
package require BLUICEVideoNotebook
		startBeamlineVideoNotebook ::config
	}
    chatOnly {
        package require DCSLogView
		startChat ::config
    }

	diffimage {
package require BLUICEDiffImageViewer
		startDiffImageViewer ::config http
	}
    saveRawMsg {
        set prefix ${beamline}rawMsg
        set nextCounter [get_next_counter . $prefix {}]
        set nextCounter [format "%03d" $nextCounter]
        set filename ${prefix}_$nextCounter
        puts "only save raw message into file: $filename"
        dcss configure -m_saveRawMsg $filename
    }

	default {
		printStyles
		exit
	}

}

#puts "Connecting to control system..."
global gEncryptSID
if {[catch {
    DcsSslUtil loadCertificate [::config getDcssCertificate]
    set gEncryptSID 1
} errMsg]} {
    set gEncryptSID 0
    puts "failed to load dcss certificate, running in unsecured mode"
    puts $errMsg
    log_error failed to load dcss certificate, running in unsecured mode
    log_error $errMsg
}
dcss connect
after idle DCS::AsyncWebData::start
#end main
