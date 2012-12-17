#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}

# ===================================================
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
# test.tcl
#
# Test for DiffImageViewer and DiffImage
#
# ===================================================

# load the required standard packages
package require Itcl 3.2
package require Iwidgets 3.0.1
package require BWidget 1.2.1
package require BLT 2.4
package require http

# load local script files
source ./httpsmb.tcl
source ./DiffImageResource.tcl
source ./DiffImageViewer.tcl
source ./DiffImage.tcl
source ./CDiffImage.tcl


######################################################
# 
# printUsage
# Print out command line argument for running 
# the program
#
######################################################
proc printUsage {} {

	puts " "
	puts "Usage: tcl test.tcl <host> <port> <username> <sessionId> <protocol: old/new/http> ?file?"
	puts " "

}


######################################################
# 
# main 
# test <host> <port> <username> <sessionId> <old/new/http> ?file?
# host: Host name of the image server
# port: Port number of image server
# username: User login name
# sessionId: Session id number for this user from 
#            the authentication server
# protocol: Protocol for commnunicating with the image server.
#           The value can be one of the following: old, new or http
#			old => Used with the old image server via socket 
#                  with built-in authentication code.
#           new => Used with the new image server via socket
#                  Authentication is handled by the authentication
#                  server using session id.
#			http=> Use with the new image server via http
#				   Authentication is handled by the authentication
#                  server using session id.
# file: Optional argument. If sepecified, the image will be displayed 
#       when the window become visible. Otherwise, the window will
#       blank image initially display a blank image.
#
######################################################

if { [catch {

	set argc [llength $argv]

	# Expect at least 3 arguments
	if { $argc < 5 } {
		printUsage
		exit
	}


	set host [lindex $argv 0] 
	set port [lindex $argv 1] 
	set user [lindex $argv 2] 
	set session [lindex $argv 3] 
	set protocol [lindex $argv 4] 
	
	
	if { $protocol == "old" } {
	
		puts "Loading old tcl_clibs library"

		# This is the old tcl_clibs that uses auth code
		# Works with the old imgsrv
		load /usr/local/dcs/tcl_clibs/irix/tcl_clibs.so dcs_c_library
		image_channel_allocate_channels 2

	} elseif { $protocol == "new" } {

		puts "Loading new tcl_clibs library"

		# This is the new tcl_clibs that does not use the auth code
		# Works with the new gui protocol of the new imgsrv
		load ../../tcl_clibs/irix/tcl_clibs.so dcs_c_library
		image_channel_allocate_channels 2
		
	}
		
	
	pack [set mainFrame [frame .mainFrame -width 500 -height 700] ] -side bottom
	
	
	# Set global variables that holds default settings for the widgets
	load_default_resources
	

	# Create a diff image viewer
	DiffImageViewer viewer $mainFrame $host $port 500 500 	\
							-protocol $protocol 			\
							-userName $user 				\
							-sessionId $session
	
	# Wait until the window is visible before loading an image.
	# Should it be moved to DiffImageViewer constructor?
	tkwait visibility $mainFrame
	
	# Load the image, if sepecified
	if { $argc > 5 } {
		# Load the image
		set file [lindex $argv 5] 
		viewer load $user $session $file 
	}
			

} err] } {

	puts $err

}


#end main

