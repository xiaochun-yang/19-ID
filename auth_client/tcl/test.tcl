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

source ./AuthClient.tcl

proc printUsage {} {

	puts " "
	puts "Usage: tcl test.tcl host port createSession username password"
	puts "Usage: tcl test.tcl host port endSession sessionId"
	puts "Usage: tcl test.tcl host port validateSession sessionId"
	puts "Usage: tcl test.tcl host port socket sessionId"
	puts " "

}

#main

if { [catch {

	set argc [llength $argv]

	# Expect at least 3 arguments
	if { $argc < 3 } {
		printUsage
		exit
	}


	set host [lindex $argv 0] 
	set port [lindex $argv 1] 
	set command [lindex $argv 2] 

	AuthClient client $host $port 1000


	if { $command == "createSession" } {
	
		if { $argc != 5 } {
			printUsage
			exit
		}
		
		set userName [lindex $argv 3] 
		set password [lindex $argv 4] 
		
		
		if { [client createSession $userName $password] == 1 } {
		
			puts "Create session OK"
			
		} else {
		
			puts "Failed to create session: [client getMessage]"
		
		}
		
		# print out member variables
		client dump
		
		# print out transaction message
		client getMessage
	
	} elseif { $command == "endSession" } {

		if { $argc != 4 } {
			printUsage
			exit
		}

		set sessionId [lindex $argv 3] 
		
		client endSession $sessionId
		
		# print out transaction message
		puts [client getMessage]
		
		
	} elseif { $command == "validateSession" } {

		if { $argc != 4 } {
			printUsage
			exit
		}

		set sessionId [lindex $argv 3] 

		if { [client validateSession $sessionId] == 1 } {

			puts "Session is valid"

		} else {

			puts "Session is invalid"
		}

		# print out member variables
		client dump
		
		# print out transaction message
		puts [client getMessage]

	} elseif { $command == "socket" } {
	
		if { $argc != 4 } {
			printUsage
			exit
		}

		set sessionId [lindex $argv 3] 

		# Send/receive http message using raw socket
		
		set socketObj [socket $host $port]
		
		puts $socketObj "GET http://$host:$port/gateway/servlet/SessionStatus;jsessionid=$sessionId?AppName=SMBTest&AuthMethod=smb.config_database&ValidBeamlines=True HTTP/1.1" 
		puts $socketObj "Connection: close"
		puts $socketObj "Host: $host:$port"
		puts $socketObj ""
		flush $socketObj
		
		# Read lines
		while { [eof $socketObj] != 1 } {
			if { [gets $socketObj line] >= 0 } {
				puts $line
			}
		}

	
		close $socketObj
					
	}
	
	# Delete the object
	itcl::delete object client

} err] } {

	puts $err

}


#end main

