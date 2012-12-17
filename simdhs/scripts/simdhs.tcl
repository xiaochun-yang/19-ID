#!/usr/bin/tclsh
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


package require Itcl
#To run this program type "wish simdhs.tcl"

namespace import itcl::*

set SIM_DIR "."
set DCS_TCL_PACKAGES_DIR /usr/local/dcs/dcs_tcl_packages/




#This function verifies the TCLLIBPATH and generates the
#  global directory variables using relative offsets from this path.
proc getBluIceDirectories {} {
	global env
	global BLC_DIR
	global DCS_DIR
   global TCL_CLIBS_DIR

	#set the variable to the tail end name of the blu-ice directory
	set BluIceDirectoryName BluIceWidgets
	set DCSWidgetsDirectoryName DcsWidgets
	
	set foundBLCDirectory 0
	set foundDCSDirectory 0

	if ![info exists env(TCLLIBPATH)] {
		reportBadTCLLIBPATH $BluIceDirectoryName $DCSWidgetsDirectoryName
	}

    #assuming that we are on a linux of some type
    set os [exec uname]
    set ostype [switch $os OSF1 {format decunix} IRIX64 {format irix} default {format linux}]
    if {$ostype == "linux"} {
        set machine [exec uname -m]
        set ostype [switch $machine x86_64 {format linux64} ia64 {format ia64} i686 - default {format linux}]
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

			set TCL_CLIBS_DIR [file join $DCS_DIR tcl_clibs $ostype]
			
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
	puts "The TCLLIBPATH environment variable should define the BluIceWidgets and DcsWidgets directory."
	puts ""
	puts "Example 1:"
		#go up two levels to get the current directory, this user is probably a developer
      set directory [file dirname [file dirname $env(PWD)]] 
		puts "setenv TCLLIBPATH \"[file join $directory $bluiceDir_] [file join $directory $widgetDir_]\" "
      
	puts "Example 2:"
		puts "setenv TCLLIBPATH \"/usr/local/dcs/$widgetDir_ /usr/local/dcs/$bluiceDir_\" "
	puts "---------------------------------------------------------------------------------------"
	puts ""
		
   exit
}


proc loadConfig {beamline_ } {
	global DCS_DIR

	DCS::Config config
	config setConfigDir [file join $DCS_DIR dcsconfig data]
	config setConfigRootName $beamline_
   if {[catch {config load } err] } {
      printAvailableConfigs 
      exit
   } 
}

proc printUsage {} {
	puts "-----------------------------------------------------------------------------"
	puts "Usage: simdhs.tcl beamline [-b]"
	puts " "
   printAvailableConfigs
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


proc handle_network_error {} {
	
	puts "Disconnecting from server..."
	
	#catch { close $socket }	
}

getBluIceDirectories
package require DCSConfig 1.0
package require DCSUtil
package require DCSProtocol

#main
if { [catch {

	set argc [llength $argv]
	
	if { $argc < 1 } {
		printUsage
		exit
	}

    global beamline
   #beamline is the first argument when starting the program
   set beamline [lindex $argv 0]

    if {[lindex $argv 1] == "-b"} {
        ###background running
        source $SIM_DIR/log.tcl
    }

	# Set xterm text in title bar
	puts "\033]2;dhs simulator for $beamline on $env(HOST)\07"

   #load the configuration for the beamline
   loadConfig $beamline

} err] } {
   global errorInfo
   puts $errorInfo	

	puts $err
	exit
}

set serverName [config getDcssHost]
set serverPort [config getDcssHardwarePort]

if { $serverName == $env(HOST) } {
   #host and dcss are same.  connecting to localhost...
   set serverName localhost
}

puts "server port: $serverPort"

source $SIM_DIR/message_handlers.tcl
source $SIM_DIR/motorClass.tcl
source $SIM_DIR/ionChambersClass.tcl
source $SIM_DIR/operations.tcl
source $SIM_DIR/epics.tcl


DCS::DhsProtocol dcss $serverName $serverPort -_reconnectTime 1000 -callback "handle_stoh_messages" -networkErrorCallback "handle_network_error" -hardwareName simDhs

dcss connect

vwait forever
