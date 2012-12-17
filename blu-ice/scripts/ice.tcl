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

# define global symbols
set DCS_DIR /usr/local/dcs
set BLC_DIR ${DCS_DIR}/blu-ice
set AUTH_DIR ${DCS_DIR}/auth_client/tcl
set BLC_SCRIPTS ${BLC_DIR}/scripts
set BLC_DATA ${BLC_DIR}/data
set BLC_IMAGES ${BLC_DIR}/images
set DCS_TCL_PACKAGES_DIR ${DCS_DIR}/dcs_tcl_packages

# make sure there is exactly one argument
if { $argc < 1 } {
	catch [puts "Usage: ice <beamline_name> ?session_id?"]
	exit
}

# hide toplevel window
wm withdraw .

# display the splash screen
source $BLC_SCRIPTS/splash.tcl
create_splash_screen $BLC_IMAGES/splash.gif



set gScan(fake) 0

# generate security keys for the user
#catch {exec /usr/local/dcs/blu-ice/scripts/genkey.sh}
#load /usr/local/dcs/tcl_clibs/linux/tcl_clibs.so dcs_c_library

proc loadAuthenticationProtocol1Library {} {
	global env
	global DCS_DIR
	global BLC_DIR

	#load the library
	set auth1Directory [file join $DCS_DIR tcl_clibs $env(OSTYPE) tcl_clibs.so]
	if [catch {load $auth1Directory dcs_c_library} err] {
		puts $err
		puts "Could not load library for authentication protocol 1.0"
		exit
	}
	
	# generate security keys for the user
	if { [catch {exec [file join $BLC_DIR scripts genkey.sh]} err] } {
        puts $err
    }
}


loadAuthenticationProtocol1Library

#Configure the Diffraction Image Server Location and port
set gBeamline(diffImageServerHost) 134.79.31.20
set gBeamline(diffImageServerPort) 14001
#allocate maximum number image channels for acquiring diffraction image jpegs
image_channel_allocate_channels 2

# Session id for this user
# blu-ice sends the session id to dcss 
# for authentication
# 
# Note for developers:
# If you have your own version of blu-ice and dcss and
# don't care for security, set gSessionId to any string
# so that the login window will not come up.
set gSessionId ""
set gAuthHost smb.slac.stanford.edu
set gAuthPort 8180
set gAuthTimeout 3000
set gAuthProtocol 1
set gWorkingOffline 0

# session id is not supplied as command line argument
# We need to pop up a window and ask for it
if { $argc >= 2 } {

	set gSessionId [lindex $argv 1]
	
}


source $AUTH_DIR/httpsmb.tcl
source $AUTH_DIR/AuthClient.tcl
source $BLC_SCRIPTS/login.tcl

set beamline [lindex $argv 0]

# set beam line environment based on command line argument
switch $beamline {

 	smblx6 {
		set gBeamline(title)					"BLU-ICE    Beamline 9-2   *******GUENTERS SIMULATION(liveVideo!!!)*********"
 		set gBeamline(beamlineId) smblx6
 		set gBeamline(simulation) 1
 		set gBeamline(detector) Q4CCD
 		set gBeamline(goniometer) HUBER
 
 		set gBeamline(serverName) smblx6
 		set gBeamline(serverPort) 14243
		set gBeamline(energyScanDir)     UP
 		set gBeamline(moveableEnergy) 1
 		set gBeamline(moveableBeamstop) 0
 		set gBeamline(zoomableCamera) 1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      0
#gw		set gBeamline(liveVideo)			0
		set gBeamline(liveVideo)			1
		#set gBeamline(videoPath)         "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
		#set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		#set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=1"
		#set gBeamline(sampleVideoPath)   "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
		#set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		#set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=2"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=9-2"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl92.dat"
 	}

 	smblx5 {
		set gBeamline(title)					"BLU-ICE    Beamline 11-1   *******SCOTTS SIMULATION*********"
 		set gBeamline(beamlineId) bl92sim
 		set gBeamline(simulation) 1
 		set gBeamline(detector) Q315CCD
 		set gBeamline(goniometer) HUBER
 
 		set gBeamline(serverName) smblx5
 		set gBeamline(serverPort) 15242
 		set gBeamline(moveableEnergy) 1
 		set gBeamline(moveableBeamstop) 0
 		set gBeamline(zoomableCamera) 1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			0
		#set gBeamline(videoPath)         "/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=2"
		#set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		#set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=1"
		#set gBeamline(sampleVideoPath)   "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
		#set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		#set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=4"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=9-2"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl92.dat"
 	}

 	smblx4 {
 		set gBeamline(beamlineId) bl92sim
 		set gBeamline(simulation) 1
 		set gBeamline(detector) Q4CCD
 		set gBeamline(goniometer) HUBER
 
 		set gBeamline(serverName) smblx4
 		set gBeamline(serverPort) 14247
 		set gBeamline(moveableEnergy) 1
 		set gBeamline(moveableBeamstop) 0
 		set gBeamline(zoomableCamera) 1
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl92.dat"
 	}

	bl92sim {
		set gBeamline(title)					"BLU-ICE    Beamline 9-2   *******SIMULATION*********"
		set gBeamline(beamlineId) 			bl92sim
		set gBeamline(simulation) 			1
		set gBeamline(detector) 			Q315CCD
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blcpu1
		set gBeamline(serverPort) 			15242
		set gBeamline(moveableEnergy) 	1
		set gBeamline(moveableBeamstop) 	0
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			1
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			0
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)   "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=4"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=9-2"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl92.dat"
	}

	bl92 {
 		set gBeamline(title)					"BLU-ICE    Beamline 9-2"
		set gBeamline(beamlineId) 			bl92
		set gBeamline(simulation) 			0
		set gBeamline(detector)   			Q315CCD
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blctl92
		set gBeamline(serverPort) 			14243
		set gBeamline(moveableEnergy) 	1
		set gBeamline(energyScanDir)     UP
		set gBeamline(moveableBeamstop) 	0
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			1
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			1
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)		"/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=2"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)   	":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-2&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl92/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=9-2"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl92.dat"
	}

	bl15 {
 		set gBeamline(title)					"BLU-ICE    Beamline 1-5"
		set gBeamline(beamlineId) 			bl15
		set gBeamline(simulation) 			0
		set gBeamline(detector)   			Q4CCD
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blctl15
		set gBeamline(serverPort) 			14243
		set gBeamline(moveableEnergy) 	1
		set gBeamline(energyScanDir)     UP
		set gBeamline(moveableBeamstop) 	1
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			1
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			1
		#set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		#set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl15/video1/axis-cgi/jpg/image.cgi?camera=1"
		#set gBeamline(sampleVideoPath)   "/BluIceVideo/bl15/video1/axis-cgi/jpg/image.cgi?camera=2"
		#set gBeamline(ptzPath)				"/BluIceVideo/bl15/video1/axis-cgi/com/ptz.cgi"
		#set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=2"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=1-5&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=1-5&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl15/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=1-5"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl15.dat"
	}

	bl71 {
		set gBeamline(title)					"BLU-ICE    Beamline 7-1"
		set gBeamline(beamlineId) 			bl71
		set gBeamline(simulation) 			0
		set gBeamline(detector) 			MAR345
		set gBeamline(goniometer) 			MARBASE
		set gBeamline(serverName) 			bl711
		set gBeamline(serverPort) 			14242
		set gBeamline(moveableEnergy) 	0
		set gBeamline(moveableBeamstop) 	0
		set gBeamline(zoomableCamera) 	0
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      1
		set gBeamline(liveVideo)			0
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl71/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleideoPath)    "/BluIceVideo/bl71/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl71/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=4"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=7-1&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=7-1&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl71/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=7-1"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl71.dat"
	}
		
	bl91 {
		set gBeamline(title)					"BLU-ICE    Beamline 9-1"
		set gBeamline(beamlineId) 			bl91
		set gBeamline(simulation) 			0
		set gBeamline(detector) 			Q315CCD
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blctl91
		set gBeamline(serverPort) 			14243
		set gBeamline(moveableEnergy) 	1
		set gBeamline(energyScanDir)     UP
		set gBeamline(moveableBeamstop) 	1
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      1
		set gBeamline(liveVideo)			1
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl91/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)   "/BluIceVideo/bl91/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl91/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=1"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-1&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=9-1&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl91/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=9-1"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl91.dat"
	}

	bl111 {
		set gBeamline(title)					"BLU-ICE    Beamline 11-1"
		set gBeamline(beamlineId) 			bl11
		set gBeamline(simulation) 			0
		set gBeamline(detector) 			Q315CCD 	
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blctl111
		set gBeamline(serverPort) 			14243
		set gBeamline(moveableEnergy) 	1
		set gBeamline(energyScanDir)     DOWN
		set gBeamline(moveableBeamstop) 	1
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			1
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)   "/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl11/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=3"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-1&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-1&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl11/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=11-1"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl11.dat"
	}

	bl11sim {
		set gBeamline(title)					"BLU-ICE    Beamline 11-1   *******SIMULATION*******"
		set gBeamline(beamlineId) 			bl11
		set gBeamline(simulation) 			1
		set gBeamline(detector) 			MAR345	
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			bl111
		set gBeamline(serverPort) 			14244
		set gBeamline(moveableEnergy) 		0
		set gBeamline(moveableBeamstop) 	1
		set gBeamline(zoomableCamera) 		1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      	0
		set gBeamline(liveVideo)			0
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)   "/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl11/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=4"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-1&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-1&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl71/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=11-1"
		set gBeamline(periodicFile)  		"$BLC_DATA/periodic_bl11.dat"
	}

	bl113 {
		set gBeamline(title)					"BLU-ICE    Beamline 11-3"
		set gBeamline(beamlineId) 			bl113
		set gBeamline(simulation) 			0
		set gBeamline(detector) 			Q4CCD 	
		set gBeamline(goniometer) 			HUBER
		set gBeamline(serverName) 			blctl113
		set gBeamline(serverPort) 			14243
		set gBeamline(moveableEnergy) 	1
		set gBeamline(energyScanDir)     DOWN
		set gBeamline(moveableBeamstop) 	1
		set gBeamline(zoomableCamera) 	1
		set gBeamline(doubleMono)			0
		set gBeamline(upwardMirror)      0
		set gBeamline(liveVideo)			1
#		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
#		set gBeamline(hutchVideoPath)   	"/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=1"
#		set gBeamline(sampleVideoPath)   "/BluIceVideo/bl11/video1/axis-cgi/jpg/image.cgi?camera=2"
#		set gBeamline(ptzPath)				"/BluIceVideo/bl11/video1/axis-cgi/com/ptz.cgi"
#		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=3"
		set gBeamline(videoServerUrl)		"http://smb.slac.stanford.edu"
		set gBeamline(hutchVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-3&camera=hutch"
		set gBeamline(sampleVideoPath)		":8080/imagetext/servlet/BluIceImageStream?beamline=11-3&camera=sample"
		set gBeamline(ptzPath)				"/BluIceVideo/bl113/video1/axis-cgi/com/ptz.cgi"
		set gBeamline(videoTitleUrl)		"http://smb.slac.stanford.edu:8080/imagetext/servlet/ImageText?location=11-3"
		set gBeamline(periodicFile)  "$BLC_DATA/periodic_bl113.dat"
	}


	default {
		puts "Unknown beamline: $beamline"
		exit
	}
}

# delete the following line after fixing message_handlers.tcl
set serverName $gBeamline(serverName)

# load the required standard packages
package require Itcl 3.2
package require Iwidgets 3.0.1
package require BWidget 1.2.1
package require BLT 2.4
package require http

# load the BIW packages
package require BIWMenu
package require BIWUtil
package require BIWCif
package require BIWGraph
package require BIWResolution



# load the DCS packages
package require BIWDevice
package require BIWDeviceView

# source all Tcl files
source $BLC_SCRIPTS/default_rc.tcl
source $BLC_SCRIPTS/SafeEntry.tcl
source $BLC_SCRIPTS/util.tcl
source $BLC_SCRIPTS/set.tcl
source $BLC_SCRIPTS/traces.tcl
source $BLC_SCRIPTS/blcommon.tcl
source $BLC_SCRIPTS/typed_command.tcl
source $BLC_SCRIPTS/mdw_document.tcl
source $BLC_SCRIPTS/beamline_gui.tcl
source $BLC_SCRIPTS/filters.tcl
source $BLC_SCRIPTS/motor_control.tcl
source $BLC_SCRIPTS/configure_motor.tcl
source $BLC_SCRIPTS/hardware_commands.tcl
source $BLC_SCRIPTS/message_handlers.tcl
source $DCS_TCL_PACKAGES_DIR/DcsNetworkProtocol.tcl
source $BLC_SCRIPTS/define_scan.tcl
source $BLC_SCRIPTS/scan.tcl
source $BLC_SCRIPTS/plot.tcl
source $BLC_SCRIPTS/cursors.tcl
source $BLC_SCRIPTS/scanlog.tcl
source $BLC_SCRIPTS/mega_widget.tcl
source $BLC_SCRIPTS/classify_field.tcl
source $DCS_TCL_PACKAGES_DIR/DcsRunSequencer.tcl
source $DCS_TCL_PACKAGES_DIR/DcsRunSequenceViewer.tcl
source $BLC_SCRIPTS/dice_tabs.tcl
source $BLC_SCRIPTS/Diffimage.tcl
source $BLC_SCRIPTS/user_scan.tcl
source $BLC_SCRIPTS/centering.tcl
source $BLC_SCRIPTS/hutch.tcl
source $BLC_SCRIPTS/detectorControl.tcl


ClientState clientState

load_default_resources
initialize_components
create_top_window
create_main_windows


puts "Connecting to $gBeamline(serverName) on port $gBeamline(serverPort)."
DcssClient dcss $gBeamline(serverName) $gBeamline(serverPort) -_reconnectTime 1000 -callback "handle_stog_messages" -networkErrorCallback "handle_network_error"
create_folder_tabs

# configure balloon help
DynamicHelp::configure -bg $gColors(light) -font $gFont(small)


# start connections to DCSS
dcss connect

# show the GUI
wm deiconify .

# pop the splash screen to the front
raise_splash_screen

# force wish to display the GUI
update

# destroy the splash screen
destroy_splash_screen

#poll_ion_chambers
# start polling state of motors in BLU-ICE
after 1000 update_polled_motors
puts 2
