#!/usr/bin/wish
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
package require Iwidgets 3.0.1
package require BWidget 1.2.1
package require BLT

# load the DCS packages
package require BIWDevice
package require BIWDeviceView

::itcl::class detectorControl {
	global env

	# protected variables
	protected variable canvas
	protected variable frame
	protected variable collectButton
	protected variable shutterSelection
	protected variable motorSelection
	protected variable imageViewer
	protected variable modeSelection

	# protected methods
	protected method constructControlPanel
	public method collectFrame

	constructor { path } {

		# store the path to the frame
		set frame [frame $path.test]

		pack $frame

		# construct the parameter widgets
		constructControlPanel

		# register for changes in client state
		#clientState register $this master
		pack $path
	}

	destructor {

		delete object $shutterSelection
		delete object $motorSelection
		delete object $imageViewer
		delete object $modeSelection
		delete object $collectButton

		delete object fileNameEntry
		delete object directoryEntry
		delete object exposureTimeEntry
		delete object deltaEntry
	}

}


::itcl::body detectorControl::constructControlPanel { } {

	global gDefineScan
	global gColors
	global env
	global gBeamline
	global gDefineRun

	set collectButton [MultipleObjectsButton \#auto $frame.collectButton  {clientState master 1 \
																										centerLoopStatus status inactive \
																										collectRunsStatus status inactive \
																										collectRunStatus status inactive \
																										collectFrameStatus status inactive } \
								  -command "$this collectFrame" \
								  -text "Collect New Image"\
								  -width 20 ]


	#DynamicHelp::register $collectButton balloon \
	#	 "Requests an image from the detector"

	Entry fileNameEntry $frame.fileNameEntry \
		 -prompt "Filename:" -promptWidth 9 -units "" \
		 -value "test"  \
		 -background lightgrey \
		 -onChange "" \
		 -type string \
		 -promptAnchor w \
		 -entryJustify left \
		 -entryWidth 20  \
		 -promptFont $gDefineScan(font) -promptWidth 12

	Entry directoryEntry $frame.directoryEntry \
		 -prompt "Directory:" -promptWidth 9 -units "" \
		 -value "/data/$env(USER)"   \
		 -background lightgrey \
		 -onChange "" \
		 -type string \
		 -promptAnchor w \
		 -entryJustify left \
		 -entryWidth 40   \
		 -promptFont $gDefineScan(font) -promptWidth 12


	Entry exposureTimeEntry $frame.exposureTime \
		 -prompt "Time:" -promptWidth 14 -units "s " \
		 -background lightgrey \
		 -value 1 \
		 -onChange "" \
		 -type positiveFloat \
		 -promptAnchor e \
		 -entryWidth 6  \
		 -decimalPlaces 2 \
		 -promptFont $gDefineScan(font) -promptWidth 12


	Entry deltaEntry $frame.deltaEntry \
		 -prompt "delta:" -promptWidth 14 -units "deg " \
		 -background lightgrey \
		 -value 1.0 \
		 -onChange "" \
		 -type positiveFloat \
		 -promptAnchor e \
		 -entryWidth 6  \
		 -decimalPlaces 2 \
		 -promptFont $gDefineScan(font) -promptWidth 12



	# create the combo box in the user frame
	set shutterSelection [ComboBox \#auto $frame.shutterSelection \
									  -prompt "shutter:" \
									  -background lightgrey \
									  -unitsAnchor w \
									  -entryWidth 10 \
									  -units "" \
									  -showEntry 0 \
									  -type string \
									  -value "NULL" ]

	$shutterSelection configure -menuChoices "shutter NULL"

	# create the combo box in the user frame
	set motorSelection [ComboBox \#auto $frame.motorSelection \
									-prompt "motor:" \
									-background lightgrey \
									-unitsAnchor w \
									-entryWidth 10 \
									-units "" \
									-showEntry 0 \
									-type string  \
									-value "NULL" ]

	$motorSelection configure -menuChoices "gonio_phi gonio_omega NULL"

	set modeSelection [ComboBox \#auto $frame.modeSelection \
								  -prompt "Mode: " \
								  -value [lindex $gDefineRun(modeChoicesSupported) 0] \
								  -promptWidth 7 -entryWidth 15 \
								  -type string -background lightgrey]

	$modeSelection configure -menuChoices $gDefineRun(modeChoicesSupported)

	frame $frame.diffractionImage
	set imageViewer [Diffimage \#auto $frame.diffractionImage $gBeamline(diffImageServerHost) $gBeamline(diffImageServerPort) 500 500]

	grid $frame.fileNameEntry    -row 0 -column 0 -sticky w
	grid $frame.modeSelection    -row 0 -column 1 -sticky w

	grid $frame.directoryEntry   -row 1 -column 0 -columnspan 2 -sticky w

	grid $frame.shutterSelection -row 2 -column 0 -sticky e
	grid $frame.exposureTime     -row 2 -column 1 -sticky w

	grid $frame.motorSelection   -row 3 -column 0 -sticky e
	grid $frame.deltaEntry       -row 3 -column 1 -sticky w

	grid $frame.collectButton    -row 5 -column 0 -columnspan 2

	grid $frame.diffractionImage -row 6 -column 0 -columnspan 2
}

::itcl::body detectorControl::collectFrame {} {
	global env
	global gDefineRun

	# disable the apply button
	#$applyButton configure -state disabled

	set id [start_waitable_operation collectFrame 15 [fileNameEntry getValue] [directoryEntry getValue] $env(USER) [$motorSelection getValue] [$shutterSelection getValue] [deltaEntry getValue] [exposureTimeEntry getValue] [lsearch $gDefineRun(modeChoices) [$modeSelection getValue]] 1 0]
	wait_for_operation $id

	#this next line is a total hack, and will only work for adsc images.
	# The problem is that the detector control program may add a different extension. The Mar
	#program is the worst, with different extensions for different sized images.
	after 5000 "::detectorControl::$imageViewer load [directoryEntry getValue]/[fileNameEntry getValue].img" 
}



proc construct_detector_control_panel {path} {

	detectorControl detector_control $path

}


proc destroy_detector_control_panel {} {

	delete object detector_control
	
}
