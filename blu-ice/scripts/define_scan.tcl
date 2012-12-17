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



set gDefineScan(range_mode) 				start_end
set gDefineScan(inProgress)				0
set gDefineScan(dynamic_update)			1
set gDefineScan(scan_count_value) 		1
set gDefineScan(scan_period_value)		0
set gDefineScan(scan_pause_value)		0.0
set gDefineScan(scan_time_value)			0.1
set gDefineScan(scan_counts_value)		10000
set gDefineScan(scan_period_units)		"min"
set gDefineScan(overlay) 					1
set gDefineScan(motor1,name) 				time
set gDefineScan(motor2,name) 				"(none)"

set gDevice(time,units) 					{ sec min hrs }
set gDevice(time,scanUnits) 				{ sec min hrs }
set gScan(scanStoppedByUser)				0
proc define_scan { args } {

	# global variables
	global gDevice
	
	# find out how many arguments were passed
	set argc [llength $args]

	# bring up scan window for current motor if 0 arguments
	if { $argc == 0 } {
		popDefineScanWindow $gDevice(control,motor) NULL
		return
	}
	
	# bring up scan window for specified motor if 1 argument
	if { $argc == 1 } {
		# scan single specified motor
		set motor1 [expandMotorAbbrev $args]
		if { ! [ isMotor $motor1 ] } {
			log_error "Motor $motor1 doesn't exist!"
			return
		} else {
			popDefineScanWindow  $motor1 NULL
			return
		}
	}
	
	# bring up scan window for specified motor if 2 arguments
	if { $argc == 2 } {
		# scan two specified motors
		set motor1 [ expandMotorAbbrev [lindex $args 0] ]
		set motor2 [ expandMotorAbbrev [lindex $args 1] ]
		
		foreach motor "$motor1 $motor2" {
			if { ! [ isMotor $motor ] } {
				log_error "Motor $motor doesn't exist!"
				return
			}
		}
		
		popDefineScanWindow $motor1 $motor2
		return
	}

	# otherwise too many arguments
	log_error wrong # args: should be \"start_scan ?motor1? ?motor2?\"
}


proc popDefineScanWindow { motor1 motor2 } {

	# global variables
	global gDevice
	global gDefineScan
	
	# set motor1 to "(none)" if empty string
	if { $motor1 == "" } {
		set motor1 "last"
	}

	if { $motor2 == "NULL" } {
		set motor2 "(none)"
	}	
	
	
	# create the scan document for the motor if it doesn't exist
	if { ! [mdw_document_exists define_scan] } {
		create_mdw_document define_scan "Define Scan" 716 530 \
			"construct_define_scan $motor1 $motor2" "destroy_define_scan"
	} else {
		if { $motor1 != "last" } {
			set gDefineScan(motor1,name) $motor1
			reset_range_parameters motor1
		}
	}
		
	# show the document
	show_mdw_document define_scan	
}

proc construct_define_scan { motor1 motor2 parent } {

	# global variables
	global gDevice
	global gDefineScan
	global gScan
	global gColors
	global gSafeEntry
	global gLabeledFrame
	
	# initialize parameters based on arguments
	if { $motor1 != "last" } {
		set gDefineScan(motor1,name) $motor1
		set gDefineScan(motor2,name) $motor2
	}
	
	if { ! [info exists gDefineScan(reference)] } {
		set gDefineScan(signal) [lindex $gDevice(ion_chamber_list) 0]
		set gDefineScan(reference) "(none)"
	}
	
	# create the menu frame
	set menuFrame [ frame $parent.menu		\
		-height			30								\
		-borderwidth	2								\
		-relief			raised						\
		-background 	$gColors(unhighlight) ]
	pack $menuFrame -fill x

	# make the file menu
	pack [ menubutton $menuFrame.file -text "File"	\
		-menu $menuFrame.file.menu] -side left
	set menu [menu $menuFrame.file.menu -tearoff 0]
	$menu add command -label "Load Definition"	\
		-command "load_definition"
	$menu add command -label "Save Definition"	\
		-command "save_definition"
	$menu add separator
	$menu add command -label "Start Scan"	\
		-command "makeScanCommand"
	$menu add separator
	$menu add command -label "Close Window" \
		-command "destroy_mdw_document define_scan"
	
	# make the options menu
	pack [ menubutton $menuFrame.options -text "Options"	\
		-menu $menuFrame.options.menu] -side left
	create_define_scan_options_menu $menuFrame.options.menu
	
	# create the motor ranges labeled frame
	set labelFrame [ labeledFrame $parent.motorRanges \
		-label "Scan Axes" -width 670 -height 95 ]
	place $labelFrame -x 10 -y 32	
	set frame $gLabeledFrame(motorRanges,frame)

	# create the six columnar frames for the six entry fields per motor
	foreach column { Axis Points Start End Step Units } {
		pack [ set gDefineScan(scan_${column}_frame) [ 
			frame $frame.scan_${column}_frame ] ] \
			-side left -padx 4
		pack [ set gDefineScan(scan_${column}_label) [
			label $frame.scan_${column}_frame.scan_${column}_label 	\
			-text "$column" -font $gDefineScan(font) ] ]
	}
	
	# create the recenter buttons in a seventh frame
	pack [ set gDefineScan(scan_button_frame) [ 
			frame $frame.scan_button_frame ] ] \
			-side left -padx 4
	pack [ label $gDefineScan(scan_button_frame).label \
		-text ""  -font $gDefineScan(font) ]
	pack [ button $gDefineScan(scan_button_frame).button1 -command "reset_axis_center motor1"\
		-text "Update" -font $gDefineScan(font) -borderwidth 2 -pady 0 -padx 3] -pady 4
	pack [ button $gDefineScan(scan_button_frame).button2 -command "reset_axis_center motor2"\
		-text "Update" -font $gDefineScan(font) -borderwidth 2 -pady 0 -padx 3] -pady 4

	bind $gDefineScan(scan_Start_label) <Button> toggle_scan_range_mode 
	bind $gDefineScan(scan_End_label) <Button> toggle_scan_range_mode 
		
	# make the 6 fields per motor
	foreach motor { motor1 motor2 } {
	
		# first field is a motor selection combo box
		if { $motor == "motor1" } {
			set choices "time $gDevice(motor_list)"
		} else {
			set choices "(none) $gDevice(motor_list)"
		} 
		pack [ comboBox $gDefineScan(scan_Axis_frame).scan_${motor}_name  \
			-variable gDefineScan($motor,name) 	\
			-choices $choices 						\
			-command "reset_range_parameters $motor" \
			-width 16 -font $gDefineScan(font) -menufont $gDefineScan(font) \
			-cbreak 27 \
			] -pady 4 -padx 4	
		
		# second field is the start/center entry
		pack [ safeEntry $gDefineScan(scan_Start_frame).${motor}_start_entry	\
			-variable gDefineScan($motor,start)	-width 9 -font $gDefineScan(font) 			\
			-type float -command "scan_start_changed $motor" ] -pady 4
		setSafeEntryTrace	gDefineScan($motor,center) 				\
			$gSafeEntry(${motor}_start_entry,entry) float	\
			"scan_center_changed $motor"
		
		# third field is the end/width entry
		pack [ safeEntry $gDefineScan(scan_End_frame).${motor}_end_entry 	\
			-variable gDefineScan($motor,end) -width 9 -font $gDefineScan(font) 			\
			-type float -command "scan_end_changed $motor"] -pady 4	
		setSafeEntryTrace	gDefineScan($motor,width) 				\
			$gSafeEntry(${motor}_end_entry,entry) float	\
			"scan_width_changed $motor"
		
		# fourth field is the step entry
		pack [ safeEntry $gDefineScan(scan_Step_frame).${motor}_step_entry	\
			-variable gDefineScan($motor,step) -width 7 -font $gDefineScan(font) 			\
			-type float -command "scan_step_changed $motor"] -pady 4	

		# fifth field is the points entry
		pack [ safeEntry $gDefineScan(scan_Points_frame).${motor}_points_entry	\
			-variable gDefineScan($motor,points) -width 6 -font $gDefineScan(font) 				\
			-type positive_int -command "scan_points_changed $motor"] -pady 4	

		set gDefineScan($motor,units) ""
		# sixth field is a units selection combo box
		pack [ comboBox $gDefineScan(scan_Units_frame).scan_${motor}_units	\
			-variable gDefineScan($motor,units) -width 7 -cwidth 5 -font $gDefineScan(font) \
			-menufont $gDefineScan(font) -command "save_axis_parameters $motor" ] -pady 4	

		# set the initial entry values
		reset_range_parameters $motor
	}
	
	# create the detectors dialog box
	place [ labeledFrame $parent.detectors	\
		-label "Detectors" -width 300	-height 75 ] \
		-x 10 -y 158
	pack [ comboBox $gLabeledFrame(detectors,frame).signal  	\
		-variable gDefineScan(signal) -choices $gDevice(ion_chamber_list) \
		 -width 10 -cwidth 12 -font $gDefineScan(font) -prompt "Signal: "	\
		-promptwidth 10 -menufont $gDefineScan(font) ] -pady 4 -padx 40
	pack [ comboBox $gLabeledFrame(detectors,frame).reference  	\
		-variable gDefineScan(reference) -choices "(none) $gDevice(ion_chamber_list)" \
		 -width 10 -cwidth 8 -font $gDefineScan(font) -prompt "Reference: " \
		 -promptwidth 10 -menufont $gDefineScan(font) ] -pady 4 -padx 40

	# create the timing dialog box
	place [ labeledFrame $parent.timing \
		-label "Timing" -width 300 -height 75 ] -x 10 -y 267	
	pack [ safeEntry $gLabeledFrame(timing,frame).scan_time_entry 	\
		-variable gDefineScan(scan_time_value) -width 8 	\
		-font $gDefineScan(font) -type positive_float \
		-label "Integration time: " -labelwidth 18 -labelanchor e \
		-units " sec" ] -pady 4 -padx 20
	pack [ safeEntry $gLabeledFrame(timing,frame).scan_pause_entry 	\
		-variable gDefineScan(scan_pause_value) -width 8 	\
		-font $gDefineScan(font) -type positive_float 		\
		-label "Motor settling time: " -labelwidth 18 -labelanchor e \
		-units " sec" ] -pady 4 -padx 20 
		
	# create the filters dialog box
	place [ labeledFrame $parent.foils 									\
		-label "Foils" -width 300 -height 75 ]	\
		-x 10 -y 377
	pack [set filtersFrame [ frame $gLabeledFrame(foils,frame).subframe ] ] \
		-side top -anchor center -padx 80
	fill_filters_frame $filtersFrame
	
	# create the repeat dialog box
	set labelFrame [ labeledFrame $parent.repeats \
		-label "Repeat" -width 337 -height 75 ]
	place $labelFrame \
		-x 342 -y 158
	set timingFrame $gLabeledFrame(repeats,frame)

	# create controls for scan count
	pack [ set frame [ frame $timingFrame.scanCountFrame ]] \
		-anchor w
	pack [ safeEntry $frame.scan_count_entry 	\
		-label "Number of scans: " -labelwidth 20 -labelanchor e \
		-variable gDefineScan(scan_count_value) -width 8	\
		-font $gDefineScan(font) -type positive_int ] -side left -pady 4
	pack [ set frame [ frame $timingFrame.scanPeriodFrame ]] \
		-anchor w
	pack [ safeEntry $frame.scan_delay_entry 	\
		-label "Delay between scans: " -labelwidth 20 -labelanchor e \
		-variable gDefineScan(scan_period_value) -width 8 	\
		-font $gDefineScan(font) -type positive_float ] -side left -pady 4
	pack [ comboBox $frame.scanPeriodUnits -choices "sec min hrs" -font $gDefineScan(font) \
		-variable gDefineScan(scan_period_units) -menufont $gDefineScan(font) \
		-width 5 -cwidth 3 \
		] -side left -pady 4 -padx 7

	# create the files labeled frame
	place [ labeledFrame $parent.files	\
		-label "Files" -width 337 -height 75 ] \
		-x 342 -y 267
	pack [ safeEntry $gLabeledFrame(files,frame).scan_delay_entry 	\
		-variable gScan(file_root) -width 15 -justification right	\
		-font $gDefineScan(font) -label "Filename root: " -labelFont $gDefineScan(font) \
		-labelwidth 14 ] -pady 4 -padx 30 -anchor w
	pack [ safeEntry $gLabeledFrame(files,frame).scan_num_entry 	\
		-variable gScan(file_num) -width 5 -justification right	\
		-font $gDefineScan(font) -type positive_int \
		-label "Scan Number: " -labelFont $gDefineScan(font) \
		-labelwidth 14 ] -pady 4 -padx 30 -anchor w
	get_next_scan_filenum

	# create the plot labeled frame
	place [ labeledFrame $parent.scan	\
		-label "Scan" -width 337 -height 75 ] \
		-x 342 -y 377
	
	# create the control buttons
	#pack [set gDefineScan(OverlayCheck) [checkbutton $gLabeledFrame(scan,frame).overlay \
	#	-text "Overlay plots" -width 12 -variable gDefineScan(overlay) ]] -side left -padx 25 -pady 15
	set gDefineScan(OverlayCheck) [checkbutton $gLabeledFrame(scan,frame).overlay \
		-text "Overlay plots" -width 12 -variable gDefineScan(overlay)] 
	pack [ set gDefineScan(StartButton) [button $gLabeledFrame(scan,frame).start 	\
														 -text "Start Scan" -width 10 -command {start_new_scan} ]] -side left -padx 90 -pady 15

	# disable the start button if scan is in progress
	if { $gScan(status) != "inactive" } {
		$gDefineScan(StartButton) configure -state disabled
	}	

	# set flag indicating define scan is in progress
	set gDefineScan(inProgress) 1

	scan_range_mode_changed 
}


proc fill_filters_frame { filtersFrame } {

	# global variables
	global gDevice
	global gDefineScan

	# create and fill the filters selection frame
	pack [set frame [ frame $filtersFrame.1 ] ] \
		-side left -anchor n -padx 5 -pady 2

	# initialize frame to pack buttons in and number of buttons
	set button_count 1

	# make a checkbox for each foil
	foreach device $gDevice(foil_list) {

		# break out if this is button 13
		if { $button_count == 13 } {
			break
		}

		# change to right frame if this button number 5
		if { $button_count == 4 } {
			pack [set frame [ frame $filtersFrame.2 ] ] \
				-side left -anchor n -padx 5 -pady 2
		} elseif { $button_count == 7 } {
			pack [set frame [ frame $filtersFrame.3 ] ] \
				-side left -anchor n -padx 5 -pady 3
		} elseif { $button_count == 10 } {
			pack [set frame [ frame $filtersFrame.4 ] ] \
				-side left -anchor n -padx 5 -pady 4
		}
		
		# set the initial state of each selection
		if { $gDevice($device,state) == "closed" } {
			set gDefineScan(${device}_selected) 1
		} else {
			set gDefineScan(${device}_selected) 0
		}

		# create the checkbutton
		set buttonName [getUniqueName]
		set gDefineScan(${device}_button) [ checkbutton $frame.${buttonName}	\
															 -variable gDefineScan(${device}_selected)	\
															 -text "$device" 							\
															 -fg black -activeforeground black \
															 -command "scan_filter_button_command $device" \
															 -anchor w ]
		
		# pack the button
		pack $gDefineScan(${device}_button) \
			 -anchor w
		
		# keep track of how many buttons have been packed
		incr button_count
	}
}


proc scan_filter_button_command { device } {

	# global variables
	global gDevice
	global gDefineScan

	if { ($gDefineScan(${device}_selected) && $gDevice($device,state)=="closed") || \
		  ( (!$gDefineScan(${device}_selected) && $gDevice($device,state)=="open") ) } {
		$gDefineScan(${device}_button) configure -fg black -activeforeground black
	} else {
		$gDefineScan(${device}_button) configure -fg red -activeforeground red
	}
}

proc start_new_scan {} {

	# global variables
	global gDefineScan
	global gScan
		
	# disable the start and add buttons
	$gDefineScan(StartButton) configure -state disabled

	# reset completion flag
	set gScan(completionState) incomplete
	
	# try to do the scan
	do_command [make_scan_command]
	
	# enable the start button
	$gDefineScan(StartButton) configure -state normal
}


proc create_define_scan_options_menu { menu } {

	menu $menu -tearoff 0

	$menu add radio -label "Scan range by start/end" \
		-command scan_range_mode_changed -variable gDefineScan(range_mode)	\
		-value start_end
		
	$menu add radio -label "Scan range by center/width" \
		-command scan_range_mode_changed	-variable gDefineScan(range_mode)		\
		-value center_width
			
	$menu add separator
	
	$menu add check -label "Dynamic update" \
		-variable gDefineScan(dynamic_update)

	return $menu
}


proc destroy_define_scan {} {
	
	# global variables
	global gDefineScan
	global gDevice

	# set flag indicating define scan not in progress
	set gDefineScan(inProgress) 0

	# activate scan button on motor control
	$gDevice(control,scanButton) configure -state normal
}


proc toggle_scan_range_mode {} {

	# global variables
	global gDefineScan
	
	# toggle the range mode value
	if { $gDefineScan(range_mode) == "center_width" } {
		set gDefineScan(range_mode) "start_end"
	} else {
		set gDefineScan(range_mode) "center_width"
	}

	# update the gui accordingly
	scan_range_mode_changed
}


proc scan_range_mode_changed {} {

	# global variables
	global gDefineScan
	global gSafeEntry
	
	# return if define scan window not around
	if { ! $gDefineScan(inProgress) } {
		return
	}
		
	if { $gDefineScan(range_mode) == "start_end" } {
		$gDefineScan(scan_Start_label) configure -text "Start"
		$gDefineScan(scan_End_label) configure -text "End"
		foreach motor { motor1 motor2 } {
			$gSafeEntry(${motor}_start_entry,entry) configure \
				-textvariable gDefineScan($motor,start)
			$gSafeEntry(${motor}_end_entry,entry) configure \
				-textvariable gDefineScan($motor,end)
		}	
	} else {
		$gDefineScan(scan_Start_label) configure -text "Center"
		$gDefineScan(scan_End_label) configure -text "Width"
		foreach motor { motor1 motor2 } {
			$gSafeEntry(${motor}_start_entry,entry) configure \
				-textvariable gDefineScan($motor,center)
			$gSafeEntry(${motor}_end_entry,entry) configure \
				-textvariable gDefineScan($motor,width)
		}
	}
}

proc scan_start_changed { motorNum } {

	# global variables
	global gDefineScan

	# return if not in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		# set end and center based on new start and old width
		if { [is_float $gDefineScan($motorNum,start)] && \
			[is_float $gDefineScan($motorNum,width)] } {
			set gDefineScan($motorNum,end) \
				[expr double( [trim $gDefineScan($motorNum,start)] ) + 	\
					 double([trim $gDefineScan($motorNum,width)]) ]
			set gDefineScan($motorNum,center) \
				[expr double([trim $gDefineScan($motorNum,start)]) +	\
					 double([trim $gDefineScan($motorNum,width)]) / 2 ]		
		}
	}
	save_axis_parameters $motorNum
}


proc scan_end_changed { motorNum } {

	# global variables
	global gDefineScan

	# return if not in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		if { [is_float $gDefineScan($motorNum,start)] && \
			[is_float $gDefineScan($motorNum,end)] } {
			set gDefineScan($motorNum,width)	\
				[expr double([trim $gDefineScan($motorNum,end)]) -	\
					 double([trim $gDefineScan($motorNum,start)]) ]
			set gDefineScan($motorNum,center)	\
				[expr double([trim $gDefineScan($motorNum,start)]) + 	\
					 double([trim $gDefineScan($motorNum,width)]) / 2 ]
			if { [is_int $gDefineScan($motorNum,points)] && ($gDefineScan($motorNum,points) > 1) } {
				set gDefineScan($motorNum,step) \
					[expr double([trim $gDefineScan($motorNum,width)]) /	\
						 ( double([trim $gDefineScan($motorNum,points)]) - 1 )]
			}
		}
	}
	save_axis_parameters $motorNum
}


proc scan_width_changed { motorNum } {

	# global variables
	global gDefineScan

	# return only if in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		if { [is_float $gDefineScan($motorNum,center)] && \
			[is_float $gDefineScan($motorNum,width)] } {
			set radius [ expr double([trim $gDefineScan($motorNum,width)]) / 2 ]
			set gDefineScan($motorNum,start) [expr double([trim $gDefineScan($motorNum,center)]) -	\
				$radius ]
			set gDefineScan($motorNum,end) [expr double([trim $gDefineScan($motorNum,center)]) + 	\
				$radius ]
		
			if { [is_int $gDefineScan($motorNum,points)] } {
				set gDefineScan($motorNum,step) \
					[expr double([trim $gDefineScan($motorNum,width)]) / 	\
						 ( double([trim $gDefineScan($motorNum,points)]) - 1 )]
			}
		}
	}
	save_axis_parameters $motorNum

}



proc scan_center_changed { motorNum } {

	# global variables
	global gDefineScan
	global gMutex
			
	# return only if in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		# set start and end based on new center and old width
		if { [is_float $gDefineScan($motorNum,center)] && \
			[is_float $gDefineScan($motorNum,width)] } {
			set radius [ expr double([trim $gDefineScan($motorNum,width)]) / 2 ]
			set gDefineScan($motorNum,start) [expr double([trim $gDefineScan($motorNum,center)]) -	\
				$radius ]
			set gDefineScan($motorNum,end) [expr double([trim $gDefineScan($motorNum,center)]) +		\
				$radius ]
		}
	}
	save_axis_parameters $motorNum
}



proc scan_points_changed { motorNum } {

	# global variables
	global gDefineScan

	# return only if in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		if { [is_int $gDefineScan($motorNum,points)] && \
			[is_float $gDefineScan($motorNum,width)] } {
			if { $gDefineScan($motorNum,points) > 1 } {
				set gDefineScan($motorNum,step) \
					[expr double([trim $gDefineScan($motorNum,width)]) /	\
						 ( [trim $gDefineScan($motorNum,points)] - 1 ) ] 
			} else {
				set gDefineScan($motorNum,step) 0.0
			}
		}
	}
	save_axis_parameters $motorNum
}


proc scan_step_changed { motorNum } {

	# global variables
	global gDefineScan

	# return only if in dynamic update mode
	if { $gDefineScan(dynamic_update) } {

		set step [trim $gDefineScan($motorNum,step)]
		set width [trim $gDefineScan($motorNum,width)]

		if { [is_float $step] && [is_float $width] } {
		
			# set number of points
			if { abs($step) <= abs($width) && abs($step) > 0 } {
				set gDefineScan($motorNum,points) \
					[expr abs( round( double($width) / $step ) ) + 1 ]
			} else {
				set gDefineScan($motorNum,points) 1
			}
			
			# set sign of width
			if { $step * $width < 0 } {
				set gDefineScan($motorNum,width) [expr -$width]
				scan_width_changed $motorNum
			}
		}
	}
	save_axis_parameters $motorNum
}


proc reset_range_parameters { motorNum args } {

	# global variables
	global gComboBox
	global gDevice
	global gSafeEntry
	global gDefineScan

	# get name of motor
	set motor $gDefineScan($motorNum,name)
	
	# blank out all fields if (none) selected
	if { $motor == "(none)" } {
		foreach field { start end center width step points units } {
			set gDefineScan($motorNum,$field) ""
		}
		foreach field { start end step points } {
			$gSafeEntry(${motorNum}_${field}_entry,entry) configure	\
				-state disabled
		}
		comboBoxSetChoices scan_${motorNum}_units	""
		return
	}

	set gDefineScan(selectMotorInProgess) 1
	
	# do the units combo box
	comboBoxSetChoices scan_${motorNum}_units $gDevice($motor,scanUnits)

	# activate all fields
	foreach field { start end step points } {
		$gSafeEntry(${motorNum}_${field}_entry,entry) configure	\
			-state normal
	}

	# restore previous values for this motor if they exist
	if { [info exists gDevice($motor,scan,points) ] } {
	
		set gDefineScan($motorNum,center) 	$gDevice($motor,scan,center) 
		set gDefineScan($motorNum,width) 	$gDevice($motor,scan,width) 
		set gDefineScan($motorNum,start) 	$gDevice($motor,scan,start) 
		set gDefineScan($motorNum,end) 		$gDevice($motor,scan,end) 
		set gDefineScan($motorNum,step) 		$gDevice($motor,scan,step) 
		set gDefineScan($motorNum,points) 	$gDevice($motor,scan,points) 
		set gDefineScan($motorNum,units) 	$gDevice($motor,scan,units) 
		scan_center_changed $motorNum
		
	} else {
	
		set gDefineScan($motorNum,units) [lindex $gDevice($motor,scanUnits) 0]
		
		# set the center, width, and points parameters
		if { $motor == "time" } {
			set gDefineScan($motorNum,center)	[format "%.2f" 10 ]
			set gDefineScan($motorNum,width) 	20.0
			set gDefineScan($motorNum,points) 	21
		} else {
			set gDefineScan($motorNum,center)	[format "%.2f" $gDevice($motor,scaled)]
			set gDefineScan($motorNum,width) 	2.0
			set gDefineScan($motorNum,points) 	21
		}
		
		# calculate start and end values
		scan_center_changed $motorNum
		
		# finally calculate the step value
		set gDefineScan($motorNum,step) \
			[expr $gDefineScan($motorNum,width) / ( $gDefineScan($motorNum,points) - 1 )]
	}
		
	# activate all fields
	foreach field { start end step points } {
		$gSafeEntry(${motorNum}_${field}_entry,entry) configure	\
			-state normal
	}

	set gDefineScan(selectMotorInProgess) 0
		
	# save the parameters for this motor
	save_axis_parameters $motorNum
}


proc save_axis_parameters { motorNum args } {
	
	# global variables
	global gDevice
	global gDefineScan

	# get name of motor
	set motor $gDefineScan($motorNum,name)
	
	# only do the following if motor selection not in progess
	if { ! $gDefineScan(selectMotorInProgess) } {
	
		set gDevice($motor,scan,center) $gDefineScan($motorNum,center)
		set gDevice($motor,scan,width) $gDefineScan($motorNum,width)
		set gDevice($motor,scan,start) $gDefineScan($motorNum,start)
		set gDevice($motor,scan,end) $gDefineScan($motorNum,end)
		set gDevice($motor,scan,step) $gDefineScan($motorNum,step)
		set gDevice($motor,scan,points) $gDefineScan($motorNum,points)
		set gDevice($motor,scan,units) $gDefineScan($motorNum,units)
	}
}


proc reset_axis_center { motorNum } {

	# global variables
	global gDevice
	global gDefineScan

	# get name of motor
	set motor $gDefineScan($motorNum,name)

	if { $motor == "(none)" } return
	if { $motor == "time" } {
		set gDefineScan($motorNum,center)	[format "%.2f" [expr [trim $gDefineScan($motorNum,width)] / 2] ]
	} else {
		if { $gDefineScan($motorNum,units) == "steps" } {
			set gDefineScan($motorNum,center) $gDevice($motor,unscaled)
		} else {
			set gDefineScan($motorNum,center) $gDevice($motor,scaled)
		}
	}			

	scan_center_changed $motorNum
	scan_start_changed $motorNum
}


proc make_scan_command {} {

	# global variables
	global gDefineScan
	global gDevice
	
	# make sure a scan axis was selected
	if { $gDefineScan(motor1,name) == "(none)" && 
			$gDefineScan(motor2,name) == "(none)" } {
		log_error "No scan axes selected!"
		return
	}
	
	# construct the two motor arguments
	foreach motorNum { motor1 motor2 } {
		set $motorNum ""
		if { $gDefineScan(${motorNum},name) != "(none)" } {
			lappend $motorNum 			\
			$gDefineScan(${motorNum},name)	\
			$gDefineScan(${motorNum},points)	\
			$gDefineScan(${motorNum},start)	\
			$gDefineScan(${motorNum},end)		\
			$gDefineScan(${motorNum},step)	\
			$gDefineScan(${motorNum},units)
		}
	}
	
	# construct the detectors argument
	set detectors $gDefineScan(signal)
	if { $gDefineScan(reference) != "(none)" } {
		lappend detectors $gDefineScan(reference)
	}
		
	# construct the filters argument
	set filters ""
	foreach device $gDevice(foil_list) {
		if { ! [info exists gDefineScan(${device}_selected)] } {
			break
		}
		if { $gDefineScan(${device}_selected) } {
			lappend filters $device
		}
	}

	# construct the timing argument
	if { [is_float $gDefineScan(scan_time_value)] } {
		set timing $gDefineScan(scan_time_value)
	} else {
		log_error "No time per point entered!"
		return
	}
			
	if { [is_float $gDefineScan(scan_pause_value)] } {
		lappend timing $gDefineScan(scan_pause_value)
	} else {
		lappend timing 0
	}

	if { $motor1 != "" || $motor2 != "" } {
		if { [is_float $gDefineScan(scan_count_value)] && \
				$gDefineScan(scan_count_value) > 0 } {
			lappend timing $gDefineScan(scan_count_value)
		} else {
			lappend timing 1
		}
	} else {
		if { [is_float $gDefineScan(scan_count_value)] && \
				$gDefineScan(scan_count_value) > 1 } {
			lappend timing $gDefineScan(scan_count_value)
		} else {
			lappend timing 2
		}
	}

	if { [is_float $gDefineScan(scan_period_value)] && \
		$gDefineScan(scan_period_value) >= 0 } {
		lappend timing $gDefineScan(scan_period_value)
	} else {
		lappend timing 0.01
	}
	
	lappend timing $gDefineScan(scan_period_units)
	
	# construct and issue the scan command
	return [list start_scan $motor1 $motor2 $detectors $filters $timing] 
}


proc set_definition { motor1 motor2 detectors filters timing } {

	# global variables
	global gDefineScan
	global gDevice

	# extract motor1's parameters
	parse_motor_parameters $motor1 name points start end step units unitIndex
	set gDefineScan(motor1,name) $name
	reset_range_parameters motor1
	set gDefineScan(motor1,points) $points
	set gDefineScan(motor1,step) $step
	set gDefineScan(motor1,start) $start
	set gDefineScan(motor1,end) $end
	set gDefineScan(motor1,units) $units
	scan_end_changed motor1
	
	# extract motor2's parameters
	if { $motor2 != "" } {
		parse_motor_parameters $motor2 name points start end step units unitIndex
		set gDefineScan(motor2,name) $name
		reset_range_parameters motor2
		set gDefineScan(motor2,points) $points
		set gDefineScan(motor2,step) $step
		set gDefineScan(motor2,start) $start
		set gDefineScan(motor2,end) $end
		set gDefineScan(motor2,units) $units
		scan_end_changed motor2
	} else {
		set gDefineScan(motor2,name) "(none)"
		reset_range_parameters motor2
	}	
	
	# set detectors
	set gDefineScan(signal) [lindex $detectors 0]
	if { [llength $detectors] == 2 } {
		set gDefineScan(reference) [lindex $detectors 1]
	} else {
		set gDefineScan(reference) "(none)"
	}
	
	# set filters
	foreach device $gDevice(foil_list) {
		set gDefineScan(${device}_selected) 0
		scan_filter_button_command $device
	}
	foreach device $filters {
		set gDefineScan(${device}_selected) 1
		scan_filter_button_command $device
	}
	
	# extract timing information
	parse_timing_parameters $timing 	gDefineScan(scan_time_value)	\
		gDefineScan(scan_pause_value) gDefineScan(scan_count_value) \
		gDefineScan(scan_period_value) gDefineScan(scan_period_units) 
}


proc load_definition {} {

	# global variables
	global gDefineScan
	global gDevice

	# prompt user for name of definition file
	set filename [tk_getOpenFile]
	
	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}
	
	# make sure file is readable
	if { ! [file readable $filename] } {
		log_error "File $filename is not readable."
		return
	}
	
	# open the file
	if [ catch {open $filename r} fileHandle ] {
		log_error "File $filename could not be opened."
		return
	}

	# get the scan definition information
	read_scan_file_header $fileHandle motor1 motor2 detectors filters timing

	# close the file
	close $fileHandle

	# set the definition
	set_definition $motor1 $motor2 $detectors $filters $timing
}



proc save_definition {} {

	set command [make_scan_command]
	
	# prompt user for name of definition file
	set filename [tk_getSaveFile]
	
	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}
	
	# open scan data file
	if { [catch {set f [open $filename w ] } ] } {
		log_error "Error opening $filename."
		return
	}
	
	# write the scan definition information
	write_scan_file_header \
		$f	\
		$filename \
		[lindex $command 1] \
		[lindex $command 2] \
		[lindex $command 3] \
		[lindex $command 4] \
		[lindex $command 5]
	
	# close the definition file
	close $f
}


proc write_scan_file_header { fileHandle filename motor1 motor2 \
	detectors filters timing } {

		puts $fileHandle "# file       $filename"
		puts $fileHandle "# date       [time_stamp]"
		puts $fileHandle "# motor1     $motor1"
		puts $fileHandle "# motor2     $motor2"
		puts $fileHandle "# detectors  $detectors"
		puts $fileHandle "# filters    $filters"
		puts $fileHandle "# timing     $timing"
		puts $fileHandle "\n\n"	
}


proc read_scan_file_header { fileHandle m1 m2 d f t } {
	
	# access variables
	upvar $m1 	motor1
	upvar $m2 	motor2
	upvar $d		detectors
	upvar $f		filters
	upvar $t		timing
	
	# discard first two lines of file
	gets $fileHandle buffer
	gets $fileHandle buffer
	
	# read motor 1 parameters
	gets $fileHandle buffer
	set motor1 [lrange $buffer 2 7]
	
	# read motor 2 parameters
	gets $fileHandle buffer
	set motor2 [lrange $buffer 2 7]	

	# read detector parameters
	gets $fileHandle buffer
	set detectors [lrange $buffer 2 3]

	# read filter parameters
	gets $fileHandle buffer
	set filters [lrange $buffer 2 3]

	# read timing parameters
	gets $fileHandle buffer
	set timing [lrange $buffer 2 6]

}


proc parse_motor_parameters { motor p0 p1 p2 p3 p4 p5 p6 } {
  
	# access variables
	upvar $p0 name
	upvar $p1 points
	upvar $p2 start
	upvar $p3 end
	upvar $p4 step
	upvar $p5 units
	upvar $p6 unitIndex

	# extract the motor parameters
	set name 	 	[lindex $motor 0]
	set points 		[lindex $motor 1]
	set start  		[lindex $motor 2]
	set end	 		[lindex $motor 3]
	set step 	 	[lindex $motor 4]
	set units		[lindex $motor 5]
	
	set unitIndex 	[expr ![string compare $units steps]]
}


proc parse_timing_parameters { timing p0 p1 p2 p3 p4 } {
  
	# access variables
	upvar $p0 scan_time
	upvar $p1 scan_pause
	upvar $p2 scan_count
	upvar $p3 scan_period
	upvar $p4 scan_units

	# extract the motor parameters
	set scan_time		[lindex $timing 0]
	set scan_pause 	[lindex $timing 1]
	set scan_count 	[lindex $timing 2]
	set scan_period	[lindex $timing 3]
	set scan_units		[lindex $timing 4]
}

set gUserScan(inUse) 0
set gUserScan(plotExists) 0

