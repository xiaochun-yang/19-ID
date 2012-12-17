#!/usr/local/bin/tclsh
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

# load the required standard packages
package require Itcl 3.2

source ./DcsConfig.tcl

proc printUsage {} {

	puts " "
	puts "Usage: tcl test.tcl"
	puts "Usage: tcl test.tcl <file>"
	puts "Usage: tcl test.tcl <dcs dir> <config root>"
	puts " "

}

#main

if { [catch {

	set argc [llength $argv]
	
	set root "biotestsim"
	
	DcsConfig config

	if { $argc == 0 } {
		
		config setConfigRootName $root
		
	} elseif { $argc == 1 } {
	
		set file [lindex $argv 0]
		
		config setConfigFile $file
		
	} elseif { $argc == 2 } {
	
		set dir [lindex $argv 0]
		set root [lindex $argv 1]
		
		config setConfigDir $dir
		config setConfigRootName $root
		
	} else {
	
		printUsage
		exit
	}
	
	
	config load
	
	puts "config:"
	puts "	configFile=[config getConfigFile]"
	puts "	defConfigFile=[config getDefaultConfigFile]"
	puts "	useDefault=[config isUseDefault]"

	puts "dcss:"
	puts "	host=[config getDcssHost]"
	puts "	guiPort=[config getDcssGuiPort]"
	puts "	scriptPort=[config getDcssScriptPort]"
	puts "	hardwarePort=[config getDcssHardwarePort]"
	set aList [config getDcssDisplays]
	set len [llength $aList]
	for { set i 0 } { $i < $len } { incr i 1 } {
		puts "	display=[lindex $aList $i]"
	}

	puts "auth:"
	puts "	host=[config getAuthHost]"
	puts "	port=[config getAuthPort]"

	puts "imperson:"
	puts "	host=[config getImpersonHost]"
	puts "	port=[config getImpersonPort]"

	puts "imgsrv:"
	puts "	host=[config getImgsrvHost]"
	puts "	webPort=[config getImgsrvWebPort]"
	puts "	guiPort=[config getImgsrvGuiPort]"
	puts "	httpPort=[config getImgsrvHttpPort]"
	puts "	tmpDir=[config getImgsrvTmpDir]"
	puts "	maxIdleTime=[config getImgsrvMaxIdleTime]"

} err] } {

	puts $err

}


#end main

