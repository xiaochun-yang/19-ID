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


   create_new_set gDevice(moving_motor_list)
	
	set gDevice(control,motor)			{}
	set gDevice(control,value)			0.10
	set gDevice(control,units)			{}
	set gDevice(control,unitBox)		{}
	set gDevice(control,unitList)		"mm $gFont(micron) deg mrad eV keV $gFont(angstrom) steps scaled unscaled s % V"
	
	# set scale factors between length units
	set gScale(mm,mm) 									""
	set gScale($gFont(micron),$gFont(micron)) 	""
	set gScale(mm,$gFont(micron)) 					"1000. *"
	set gScale($gFont(micron),mm) 					"0.001 *"
	
	# set scale factors between angle units
	set gScale(deg,deg)		""
	set gScale(mrad,mrad)	""
	set gScale(deg,mrad)		"17.45329 *"
	set gScale(mrad,deg)		"0.05729578 *"
   set gScale(%,%)         ""
   set gScale(s,s)         ""
   set gScale(counts,counts) ""
   set gScale(V,V)         ""

	# set scale factors between energy units
	set gScale(eV,eV)		""
	set gScale(keV,keV)	""
	set gScale($gFont(angstrom),$gFont(angstrom))		""
	set gScale(eV,keV) 						"0.001 *"
	set gScale(eV,$gFont(angstrom))		"12398. /"
	set gScale(keV,eV)						"1000. *"
	set gScale(keV,$gFont(angstrom))		"12.398 /"
	set gScale($gFont(angstrom),eV)		"12398. /"
	set gScale($gFont(angstrom),keV)		"12.398 /"

	set gFormat(places,mm)						3
	set gFormat(places,deg)						3
	set gFormat(places,$gFont(micron))		1
	set gFormat(places,mrad)					2
	set gFormat(places,eV)						2
	set gFormat(places,keV)						4
   set gFormat(places,$gFont(angstrom))	3
   set gFormat(places,%)                  2
   set gFormat(places,s)                  2
   set gFormat(places,counts)             1
   set gFormat(places,V)                  1
	
proc get_scaled_value_in_units { motor units } {
	
	# global variables
	global gScale
	global gDevice
	
	return [expr $gScale($gDevice($motor,scaledUnits),$units) $gDevice($motor,scaled) ]
}


proc convert_scaled_units { value fromUnits toUnits } {
	
	# global variables
	global gScale
	
	return [expr $gScale($fromUnits,$toUnits) $value ]
}


namespace eval nScripts {
	proc rad { deg } { expr $deg / 57.2975 }
	proc deg { rad } { expr $rad * 57.2975 }
}


proc create_motor_control { frame } {

	global gWindows
	global gDevice
	global gColors
	global gFont
	global gScale
	global gMode
		
#	set frame $gWindows(control,frame)

	set selectFrame [ frame $frame.selectFrame ]

	# create the motor selection label
	pack [ label $selectFrame.label	\
		-text "Selected Motor  "		\
		-font $gFont(large) 				\
	]  -side top
	
	# sort the motor list
	set gDevice(motor_list) [lsort $gDevice(motor_list) ]
	
	# create the motor selection combo box
	pack [ comboBox $selectFrame.combo		\
		-variable gDevice(control,motor)	\
		-command "selectMotorCommand"		\
		-choices $gDevice(motor_list)		\
		-width 15								\
		-cbreak 27								\
		-font $gFont(large)					\
		-menufont $gFont(large)				\
	] -side top
	
	pack $selectFrame	\
		-side left			\
		-padx 5 -pady 5

	frame $frame.move
	pack $frame.move 	\
		-side left		\
		-padx 3			\
		-pady 3
	
	frame $frame.moveButtons
	frame $frame.moveEntries
	pack $frame.moveButtons $frame.moveEntries 	\
		-in $frame.move									\
		-side top -expand 1 -fill x -pady 3
		
	# make the relative move button
	set gDevice(control,moveByButton) [
		button $frame.moveBy		\
			-text "Move by"		\
			-width 6 				\
			-state disabled		\
			-command { 
			do_command "move $gDevice(control,motor) by \
				$gDevice(control,value) $gDevice(control,units)" } ]
		
	# make the absolute move button
	set gDevice(control,moveToButton) [
		button $frame.moveTo		\
			-text "Move to"		\
			-width 6					\
			-state disabled		\
			-command { 
			do_command "move $gDevice(control,motor) to \
				$gDevice(control,value) $gDevice(control,units)" } ]
	
	# make the set button
	set gDevice(control,HomeToButton) [
		button $frame.homeTo				\
			-text "Home"					\
			-width 6							\
			-state disabled				\
			-command {		
				log_current_position $gDevice(control,motor); \
					do_command "configure $gDevice(control,motor) position \
					$gDevice(control,value) $gDevice(control,units)" 
			} ]
	
	# pack the move buttons
	pack $frame.moveBy $frame.moveTo	\
		-in $frame.moveButtons								\
		-side left -padx 1

	# make the number entry frame
	set placeFrame [frame $frame.placeFrame]
	pack $placeFrame -in $frame.moveEntries -side left -pady 2

	# make the number selection combo box
	pack [comboBox $frame.choices -variable gDevice(control,value) \
		-choices "-1000 -500 -270 -200 -180 -100 -90 -50 -45 -20 -10 -5 -2 -1 -.5 -.2 -.1 \
		-.05 -.02 -.01 -.005 -.002 -.001 0.000\
		1000 500 270 200 180 100 90 50 45 20 10 5 2 1 .5 .2 .1 \
		.05 .02 .01 .005 .002 .001 0.000" \
		-cbreak 24 -noentry 1 -width 10 \
		-font $gFont(large) -menufont $gFont(small) ]	\
		-in $frame.placeFrame -padx 3

	# make the number entry
	set entry [entry $frame.entry 	\
		-justify right		\
		-width 11			\
		-textvariable gDevice(control,value)	]
	place $frame.entry				\
		-in $frame.placeFrame	\
		-x 0 -y 0
	trace variable gDevice(control,value) w \
		"traceFloatEntry gDevice(control,value) $entry"
	storeValue gDevice(control,value) $gDevice(control,value)

	# make the units combo box
	pack [ comboBox $frame.units			\
		-variable gDevice(control,units)	-command { selectUnitsCommand }	\
		-width 7 -cwidth 5 -font $gFont(large) -menufont $gFont(large)					\
		]	-side left -in $frame.moveEntries

	# make the abort frame
	pack [frame $frame.aborts] -side left -padx 1

	# make the soft abort button
	button $frame.abortHard	\
		-text "Emerg Stop"	\
		-state normal 			\
		-width 9					\
		-bg $gColors(red)		\
		-fg yellow				\
		-activeforeground yellow \
		-activebackground $gColors(red) \
		-command { do_command "abort hard" }

	# make the hard abort button
	button $frame.abortSoft	\
		-text "Abort"			\
		-state normal 			\
		-width 9					\
		-bg $gColors(lightRed)		\
		-activebackground $gColors(lightRed) \
		-command { do_command "abort soft" }
		
	# pack the abort/abort all buttons
	pack $frame.abortHard $frame.abortSoft		\
		-in $frame.aborts								\
		-side top -pady 1
	
	#make the correct/undo frame
	pack [frame $frame.do] -side left -padx 1

	# make the correct button
	set gDevice(control,correctButton) [
		button $frame.correct	\
			-text "Correct"		\
			-state disabled 		\
			-width 9					\
			-command { do_command correct $gDevice(control,motor)} ]
		
	# make the undo button
	set gDevice(control,undoButton) [
		button $frame.undo	\
			-text "Undo Move"		\
			-state disabled 		\
			-width 9					\
			-command { undo $gDevice(control,motor) } ]
			
	# pack the correct and undo buttons
	pack $frame.correct $frame.undo	\
		-in $frame.do						\
		-side top -pady 1

	#make the scan/config frame
	frame $frame.scanConfig
	pack $frame.scanConfig	\
		-side left -padx 1

	# make the scan button
	set gDevice(control,scanButton) [
		button $frame.scan	\
		-text "Scan"		\
		-width 9				\
		-command { do define_scan } ] 
			
	# make the configure button
	button $frame.configure	\
		-text "Configure"		\
		-width 9					\
		-command { do configure $gDevice(control,motor) }		

	# pack the scan/config buttons
	pack $frame.scan $frame.configure	\
		-in $frame.scanConfig				\
		-side top -pady 1
	
	# enable event handlers for become master/slave events
	becomeMasterHook add updateMotorControlButtons
	becomeSlaveHook add updateMotorControlButtons
}


set gDevice(control,lastHighlightedMotor) {}

proc update_motor_highlight {} {

	# global variables
	global gDevice
	
	set currentMotor $gDevice(control,motor)
	set lastMotor $gDevice(control,lastHighlightedMotor)

	# highlight the current motor
	update_motor_label $currentMotor
	
	# unhighlight previous motor if different from current motor
	if { $currentMotor != $lastMotor } {

		# unhighlight the previous motor
		if { $lastMotor != {} } {
			update_motor_label $lastMotor
		}	
		set gDevice(control,lastHighlightedMotor) $currentMotor
	}
}


proc update_motor_label { motor } {

	# global variables
	global gDevice
	
	if { $motor == $gDevice(control,motor) } {
	
		# highlight the current motor if currently selected
		catch {$gDevice($motor,label) configure \
			-background $gDevice($motor,selectedbackground)	\
			-foreground $gDevice($motor,selectedforeground) }
			
	} else {
	
		# otherwise unhighlight it
		catch { $gDevice($motor,label) configure	\
			-background $gDevice($motor,background)	\
			-foreground $gDevice($motor,foreground) }
	}
}


proc update_motor_highlight_colors { motor } {

	# global variables
	global gDevice
	global gColors

	if { $gDevice($motor,status) == "inactive" } {
		set gDevice($motor,foreground)			$gColors(motor,foreground)
		set gDevice($motor,background)			$gColors(motor,background)
		set gDevice($motor,selectedforeground)	$gColors(motor,selectedforeground)
		set gDevice($motor,selectedbackground)	$gColors(motor,selectedbackground)
	} else {
		set gDevice($motor,foreground)			$gColors(motor,activeforeground)
		set gDevice($motor,background)			$gColors(motor,activebackground)
		set gDevice($motor,selectedforeground)	$gColors(motor,activeselectedforeground)
		set gDevice($motor,selectedbackground)	$gColors(motor,activeselectedbackground)
	}
	
	# update the label itself
	update_motor_label $motor
}


proc selectMotorCommand { motor } {

	# global variables
	global gDevice
	global gMode
	
	# display component window
	show_motor $motor
	
	# selet the motor
	do_command "select_motor $motor"
}




proc correct { motor } {

	# global variables
	global gDevice

	# correct the motor
	do_command "correct $motor"
}


proc selectUnitsCommand { units } {

	# global variables
	global gDevice

	# select the units if this was invoked from the combobox
	do_command "set_units $units" 
}


proc motorArrow { canvas motor upX upY midCoord downX downY \
							{plus_x NULL} {plus_y NULL} {minus_x NULL} {minus_y NULL} } {

	# global variables
	global gDevice
	global gColors
	global gFont

	set taglist "{arrow $gDevice($motor,units)}"

	# draw the arrow
	set arrow \
		[ eval $canvas create line $upX $upY $midCoord $downX $downY \
			-arrow both -smooth true -splinesteps 100 -width 5 \
			-fill black -tags $taglist ]

	# bind mouse button click to increment function
	$canvas bind $arrow <Button-1> \
		"motorArrowCommand $canvas $motor $upX $upY $downX $downY %x %y"	

	# draw plus sign
	if { $plus_x != "NULL" && $plus_y != "NULL" } {
		set plus [ $canvas create text $plus_x $plus_y -text "+" -font $gFont(sign)]
		$canvas bind $plus <Button-1> "motorArrowCommand $canvas $motor \
			$upX $upY $downX $downY $upX $upY"
	} 

	# draw minus sign
	if { $minus_x != "NULL" && $minus_y != "NULL" } {
		set minus [ $canvas create text $minus_x $minus_y -text "-" -font $gFont(sign)]
		$canvas bind $minus <Button-1> "motorArrowCommand $canvas $motor \
			$upX $upY $downX $downY $downX $downY"
	}
}


proc motorArrowCommand { canvas motor upX upY downX downY x y } {

	# global variables
	global gDevice

	# make sure this motor is the selected one
	if { $gDevice(control,motor) != $motor } {
		log_error "Motor must be selected before increment arrows work!"
		return
	}
	
	activate_mdw_document $gDevice($motor,component)
	
	# check that a valid value has been specified
	if { ! [ isExpr $gDevice(control,value) ] || $gDevice(control,value) <= 0} {
		log_error "A positive value was not specified."
		return
	}

	# check if incrementing or decrementing
	if { [distance $x $y $upX $upY] < [distance $x $y $downX $downY] } {
		# doing increment
		set value [ expr $gDevice(control,value) ]
	} else {	
		# doing decrement
		set value [ expr (-1) * $gDevice(control,value) ]
	}
	
	# execute the move
	do_command "move $motor by $value $gDevice(control,units)"
}

proc handleScaledValueClick { motor {window {}} } {

	# global variables
	global gDevice
	
	# select motor if not currently selected
	if { $motor != $gDevice(control,motor) } {
		select_motor $motor $window
	}
	
	# set the units to the current value
	set_units $gDevice($motor,currentScaledUnits)
}

proc handleScaledValueDoubleClick { motor } {

	# global variables
	global gDevice
	
	# select motor if not currently selected
	if { $motor != $gDevice(control,motor) } {
		select_motor $motor
	}
	
	# change units to next scaled unit
	if { $gDevice($motor,currentUnitIndex) >= $gDevice($motor,scaledUnitCount) } {
		set_units $gDevice($motor,scaledUnits)
	} else {
		set unitIndex [expr $gDevice($motor,currentUnitIndex) + 1]
		set_units [lindex $gDevice($motor,units) $unitIndex]
	}
}


proc motorView { canvas mot x y anchor {width 110} {height 43} {labelsize 9} } {

	# global variables
	global gColors
	global gDevice
	global gLabeledFrame
	global gFont
	
	set comp $gDevice($mot,component) 

	# create the labeled frame
	set labelFrame [ labeledFrame $canvas.$mot -font $gFont(small)	\
		-label " $mot " -width $width -height $height -y 8 ]
	set frame $gLabeledFrame($mot,frame)
	set gDevice($mot,label) $gLabeledFrame($mot,label)
	update_motor_highlight_colors $mot
	
	$canvas create window $x $y	\
		-window $canvas.$mot	\
		-anchor $anchor
	
	bind $labelFrame 			 <Button-1> "select_motor $mot; activate_mdw_document $gDevice($mot,component)"
	bind $frame 	  			 <Button-1> "select_motor $mot; activate_mdw_document $gDevice($mot,component)"
	bind $gDevice($mot,label) <Button-1> "select_motor $mot; activate_mdw_document $gDevice($mot,component)"
	bind $gDevice($mot,label) <Double-1> "select_motor $mot; do configure $mot"

	# create frame for scaled value
	set scaledFrame [ frame $frame.scaledFrame ]
	
	# get the units for the scaled value
	set units [lindex $gDevice($mot,units) 0 ]
	
	# put up the units for the scaled value
	pack [ label $scaledFrame.unit -textvariable gDevice($mot,currentScaledUnits)	\
		-foreground $gColors($gDevice($mot,scaledUnits)) -font $gFont(small) ] -side right
	
	# put up the scaled value
	pack [ label $scaledFrame.num	-foreground $gColors($units)	-font $gFont(small) \
		-textvariable gDevice($mot,scaledDisplay) -width $labelsize	-anchor e]	\
		-side right	-fill x -expand 1

	# bind button click on units to select motor and change increment units
	bind $scaledFrame.unit <Button-1> \
			"handleScaledValueClick $mot; activate_mdw_document $gDevice($mot,component)"
	bind $scaledFrame.unit <Double-1> \
			"handleScaledValueDoubleClick $mot; activate_mdw_document $gDevice($mot,component)"
			
	# bind button click on value to select motor and change increment units
	bind $scaledFrame.num <Button-1> \
			"handleScaledValueClick $mot; activate_mdw_document $gDevice($mot,component)"
	bind $scaledFrame.num <Double-1> \
			"handleScaledValueDoubleClick $mot; activate_mdw_document $gDevice($mot,component)"
	
	# do next block only if real motor
	if { $gDevice($mot,type) == "real_motor" } {
	
		# create frame for unscaled value
		set unscaledFrame [ frame $frame.unscaledFrame ]

		# get the units for the unscaled value	
		set units $gDevice($mot,unscaledUnits)	
		
		# put up the units for the unscaled value
		pack [ label $unscaledFrame.unit	-font $gFont(small) \
			-text $units -foreground $gColors($units) ] -side right

		# put up the unscaled value
		pack [label $unscaledFrame.num						\
			-foreground $gColors($units) -font $gFont(small) \
			-textvariable gDevice($mot,unscaledDisplay)	\
			-anchor e ] -side right	-fill x -expand 1

		# bind button click on units to change increment units
		bind $unscaledFrame.unit <Button-1> \
			"select_motor $mot;set_units $units; activate_mdw_document $gDevice($mot,component)"
	
		# bind button click on value to select motor and change increment units
		bind $unscaledFrame.num <Button-1> \
			"select_motor $mot;set_units $units; activate_mdw_document $gDevice($mot,component)"

		# pack the two frames
		pack $scaledFrame $unscaledFrame -fill x -expand 1 -padx 3
		
		} else {
		
			# pack the single frame
			pack $scaledFrame -pady 11 -fill x -expand 1 -padx 3
		
		}
	
	# put labeled frame on canvas
	$canvas create window $x $y	\
			-window $canvas.$mot	\
			-anchor $anchor
	} 



proc ion_chamber_view_old { canvas detector subscript x y anchor {width 110} {height 40} {labelsize 10} } {

	# global variables
	global gColors
	global gDevice
	global gLabeledFrame
	global gFont
	
	# create the labeled frame
	set labelFrame [ labeledFrame $canvas.$detector -font "courier 12 bold"	\
		-label "I " -width $width -height $height -y 4 ]
	set frame $gLabeledFrame($detector,frame)
	set gDevice($detector,label) $gLabeledFrame($detector,label)


	place [ label $canvas.$detector.subscipt -text $subscript -font "helvetica 10 bold" ] \
		-x 26 -y 10
	
	$canvas create window $x $y	\
		-window $canvas.$detector	\
		-anchor $anchor
	
	# create frame for counts value
	pack [ set countsFrame [ frame $frame.countsFrame ] ] \
		-pady 1 -fill x -expand 1 -padx 3

	# put up the scaled value
	pack [ label $countsFrame.num	-foreground $gColors(counts) -font $gFont(large) \
		-textvariable gDevice($detector,cps) -width $labelsize -anchor e]	\
		-side right	-fill x -expand 1 -pady 5
	
	# put labeled frame on canvas
	$canvas create window $x $y		\
			-window $canvas.$detector	\
			-anchor $anchor
	} 

proc ion_chamber_view { canvas detector subscript x y } {

	# global variables
	global gColors
	global gDevice
	global gFont

	set frame [frame $canvas.i${detector}frame -relief groove \
		-borderwidth 2 -width 100 -height 30]

	$canvas create window $x $y -window $frame -anchor n

	place [ label $frame.i$detector -text "I" -font "courier 12 bold" ] \
		-x 0 -y 0
	place [ label $frame.i${detector}sub -text $subscript -font "helvetica 10 bold" ] \
		-x 10 -y 6
	
	place [label $frame.i${detector}val -foreground $gColors(counts) -font $gFont(small) \
		-textvariable gDevice($detector,cps) -anchor e -width 8] -x 25 -y 0
	} 





proc updateMotorControlButtons {} {

	# global variables
	global gDevice
	global gScan
	
	# return immediately if scanning
	if { $gScan(status) == "scanning" } {
		return
	}

	# turn off everything by default
	$gDevice(control,correctButton) configure -state disabled
	$gDevice(control,moveByButton) configure -state disabled
	$gDevice(control,moveToButton) configure -state disabled
	$gDevice(control,homeToButton) configure -state disabled
	$gDevice(control,undoButton) configure -state disabled
	
	# turn off everything if not the master
	if { ! [dcss is_master] } {		
		return
	}
		
	# get selected motor and its status
	set motor $gDevice(control,motor)

	# turn off everything except "abort all" if no motor selected
	#   or if scan is just starting
	if { $motor == "" || $gScan(status) == "starting" } {		
		return
	}
	
	set status $gDevice($motor,status)

	if { $status == "inactive" } {
	
		$gDevice(control,moveByButton) configure -state normal
		$gDevice(control,moveToButton) configure -state normal
		$gDevice(control,homeToButton) configure -state normal
		
#		if {$gDevice($motor,type) == "real_motor" } {
#			$gDevice(control,homeToButton) configure -state normal
#		}
			
		if { $gDevice($gDevice(control,motor),undoCommand) != "" }  {
			$gDevice(control,undoButton) configure -state normal
		}
		
		if { $gDevice($gDevice(control,motor),type) == "pseudo_motor" } {
			$gDevice(control,correctButton) configure -state normal
		}
				
	}
}


proc create_real_motor { motor abbrev component units } {

	# global variables
	global gDevice
		
	# initialize generic motor parameters
	create_generic_motor $motor $abbrev $component $units

	set gDevice($motor,type)					real_motor
	set gDevice($motor,scaledUnitCount)		[expr [llength $units] - 1]
	set gDevice($motor,units)					"$units steps"
	set gDevice($motor,scaledUnits)			[lindex $units 0]
	set gDevice($motor,currentUnits)			[lindex $units 0]
	set gDevice($motor,currentScaledUnits)	[lindex $units 0]
	set gDevice($motor,unscaledUnits)		steps
	set gDevice($motor,scanUnits)				"$gDevice($motor,scaledUnits) steps"
	set gDevice($motor,unscaled)				0
	set gDevice($motor,scaledLowerLimit) 	0
	set gDevice($motor,scaledUpperLimit)	0
	set gDevice($motor,scaleFactor)			1.0	
	set gDevice($motor,speed)					0
	set gDevice($motor,acceleration)			0
	set gDevice($motor,scaledBacklash)		0
	set gDevice($motor,reverseOn)				0		

 	#trace unscaled position
	trace variable gDevice($motor,unscaled) w \
		"traceMotorUnscaled $motor"

	# trace scaled position
	trace variable gDevice($motor,scaled) w \
		"traceMotorScaled $motor"

	# create the RealMotor object
	namespace eval device "RealMotor $motor"
	device::$motor configure -unitsList $units
}


proc create_pseudo_motor { motor abbrev component units } {

	# global variables
	global gDevice
		
		
	# initialize generic motor parameters
	create_generic_motor $motor $abbrev $component $units
	
	set gDevice($motor,type)					pseudo_motor
	set gDevice($motor,units)					$units
	set gDevice($motor,scaledUnitCount)		[expr [llength $units] - 1]
	set gDevice($motor,scaledUnits)			[lindex $units 0]
	set gDevice($motor,currentUnits)			[lindex $units 0]
	set gDevice($motor,currentScaledUnits)	$gDevice($motor,scaledUnits)
	set gDevice($motor,scanUnits)				$gDevice($motor,scaledUnits)

	# trace scaled position
	trace variable gDevice($motor,scaled) w \
		"traceMotorScaled $motor"

	# create the Motor object
	namespace eval device "Motor $motor"
	device::$motor configure -unitsList $units
}




proc create_generic_motor { motor abbrev component units } {

	# global variables
	global gDevice
	global gColors
	
	add_motor_abbrev $motor $abbrev
	
	set gDevice($motor,component) 			$component
	set gDevice($motor,scaled)					0
	set gDevice($motor,scaledLowerLimit) 	-100
	set gDevice($motor,scaledUpperLimit)	100
	set gDevice($motor,currentUnitIndex)	0
	set gDevice($motor,lockOn)					0
	set gDevice($motor,backlashOn)			0
	set gDevice($motor,lowerLimitOn)			1
	set gDevice($motor,upperLimitOn)			1
	set gDevice($motor,configInProgress)	0
	set gDevice($motor,status)					inactive
	set gDevice($motor,undoCommand)			""
	set gDevice($motor,errorCode)				none
	set gDevice($motor,foreground)			$gColors(motor,foreground)
	set gDevice($motor,background)			$gColors(motor,background)
	set gDevice($motor,selectedforeground)	$gColors(motor,selectedforeground)
	set gDevice($motor,selectedbackground)	$gColors(motor,selectedbackground)
	set gDevice($motor,selectedWindow) 		""
	set gDevice($motor,startedByPoll)		0
	set gDevice($motor,updateCount)			0
	
	lappend gDevice(motor_list) $motor
}




proc motor_exists { motor } {

	# global variables
	global gDevice

	if { [lsearch $gDevice(motor_list) $motor] == -1 } {
		return 0
	} else {
		return 1
	}
}


proc add_motor_abbrev { motor abbrev } {

	# global variables
	global gAbbrev

	set gAbbrev(abbrev,$motor) $abbrev
	set gAbbrev(expand,$abbrev) $motor
}


proc expandMotorAbbrev { abbrev } {

	# global variables
	global gAbbrev
	
	if { [info exists gAbbrev(expand,$abbrev)] } {
		return $gAbbrev(expand,$abbrev)
	} else {
		return $abbrev
	}
}

proc get_motor_abbrev { motor } {

	# global variables
	global gAbbrev
	
	if { [info exists gAbbrev(abbrev,$motor)] } {
		return $gAbbrev(abbrev,$motor)
	} else {
		return $motor
	}
}



proc pop_motors_status {} {

	# global variables
	global gDevice

	# create the scan document for the motor if it doesn't exist
	if { ! [mdw_document_exists motors_status] } {
		create_mdw_document motors_status "Motors Status" 360 390 \
			construct_motors_status destroy_motors_status
	}
		
	# show the document
	show_mdw_document motors_status
}


proc construct_motors_status { parent } {

	# global variables
	global gDevice
	global gColors
	global gFont

	# create a spacer frame at the top of the window
	pack [frame $parent.spacerFrame -highlightthickness 0\
		-borderwidth 0 -height 0 -background $gColors(light) \
		] -side top -expand 0 -fill x
	
	# create the frame to hold the scrolled canvas
	pack [frame $parent.canvasFrame -relief sunken -borderwidth 2] \
		-side top -expand true -fill both 
	
	# create a frame to put on the scrolling canvas
	set frame [frame $parent.textFrame -bg $gColors(light)]

	# add a line to the scrolled region for each motor
	foreach motor $gDevice(motor_list) {
		label $frame.${motor}name -text " $motor" \
			-font $gFont(small) -bg $gColors(light) -width 16 -anchor w
		label $frame.${motor}position -textvariable gDevice($motor,scaledDisplay)\
			-font $gFont(small) -bg $gColors(light) -width 9 -anchor e
		label $frame.${motor}units -textvariable gDevice($motor,currentScaledUnits)\
			-font $gFont(small) -bg $gColors(light) -width 5 -anchor w
		label $frame.${motor}status -textvariable gDevice($motor,status)\
			-font $gFont(small) -bg $gColors(light) -width 8 -anchor w
		grid $frame.${motor}name $frame.${motor}position \
			$frame.${motor}units $frame.${motor}status
			
		bind $frame.${motor}name <Button-1> \
			"select_motor $motor motors_status"	
		bind $frame.${motor}name <Double-1> \
			"select_motor $motor motors_status; configure $motor"

		bind $frame.${motor}position <Button-1> \
			"handleScaledValueClick $motor motors_status"	
		bind $frame.${motor}position <Double-1> \
			"handleScaledValueDoubleClick $motor"
			
		bind $frame.${motor}units <Button-1> \
			"handleScaledValueClick $motor motors_status"
		bind $frame.${motor}units <Double-1> \
			"handleScaledValueDoubleClick $motor"
	}
	
	# get geometry of frame after it stabilizes
	update idletasks
	set bbox [grid bbox $frame 0 0]
	set incr [lindex $bbox 3]
	set width [winfo reqwidth $frame]
	set height [expr $incr * [llength $gDevice(motor_list)]]
	
	# put the frame on a scrolled canvas
	scrolledCanvas $parent.canvasFrame.canvas 	\
		-background $gColors(light) -incr $incr	\
		-window $frame -height $height -width $width
}

proc destroy_motors_status { } {

}


proc reset_all {} {

	# global variables
	global gDevice
 
 	# loop over all motors
 	foreach motor $gDevice(motor_list) {
		if { $gDevice($motor,status) != "inactive" } {
			reset_motor $motor
		}
	}
}


proc reset_motor { {motor default} } {

	# global variables
	global gDevice

	if { $motor == "all" } {
		reset_all
		return 
	}
	
	# handle default argument
	if { $motor == "default" } {
		# report error if no motor selected
		if { $gDevice(control,motor) == "" } {
			log_error "No motor has been selected."
			return
		} else {
			set motor $gDevice(control,motor)
		}
	}
	
	# get motor name from abbreviation
	set motor [expandMotorAbbrev $motor ]

	# make sure motor exists
	if { ! [isMotor $motor] } {
		log_error "No such motor $motor."
		return
		}
	
	if { $gDevice($motor,status) == "inactive" } {
		log_error "Motor $motor is inactive."
		return
		}

	handle_move_complete	$motor
	log_note "The status of motor $motor has been reset."
}



proc handle_move_complete { motor } {
	
	# global variables
	global gDevice
	global gConfig
	global gScan

	# activate undo button if motor is selected
	if { $gDevice(control,motor) == $motor } {
		
		# but don't activate undo if no undo message
		if { $gDevice($gDevice(control,motor),undoCommand) != "" }  {
			$gDevice(control,undoButton) configure -state normal
		}
	}
		
	# update the motor object
	device::$motor configure -status "inactive"
	
	set gDevice($motor,status) inactive
	remove_from_set gDevice(moving_motor_list) $motor
	update_motor_highlight_colors $motor
	
	# activate apply button in configure if unapplied changes
	if { $gDevice($motor,configInProgress) } {
		$gConfig($motor,apply) configure -state normal
	}	
	
	updateMotorControlButtons
	refresh_beamline_configuration
}

proc after_info {} {

	puts "**** Schedule after events *****"

	foreach event [after info] {

		puts "$event: [after info $event]"
	}
	puts "********************************"
}


proc check_update_count { motor } {

	# global variables
	global gDevice
	
	if { $gDevice($motor,updateCount) } {
		set gDevice($motor,updateCount) 0
	}
}


proc handle_move_start { motor {startedByPoll 0} } {
	
	# global variables
	global gDevice
	global gConfig

	# this commented out code prevents motors from being tagged as moving
	# until they get three updates from DCSS (if started by polling)
	# We can put it back in if there are performance problems
#	if { $startedByPoll && $gDevice($motor,updateCount) < 3 } {
#		incr gDevice($motor,updateCount)
#		after 1000 "check_update_count $motor"
#		return
#	} else {
#		set gDevice($motor,updateCount) 0
#	}
	
	# update the motor object
	device::$motor configure \
		 -status "moving" \
		 -startedByPoll $startedByPoll \
		 -timedOut 0 \
		 -timeoutCount 0

	# update status of motor
	set gDevice($motor,status) moving
	set gDevice($motor,startedByPoll) $startedByPoll
	set gDevice($motor,timedOut) 0
	set gDevice($motor,timeoutCount) 0
	add_to_set gDevice(moving_motor_list) $motor
	
	# update the gui
	update_motor_highlight_colors $motor
	update_motor_highlight
	updateMotorControlButtons	

	# activate apply button in configure if unapplied changes
	if { $gDevice($motor,configInProgress) } {
		$gConfig($motor,apply) configure -state disabled
	}	
}



proc update_polled_motors {} {

	# global variables
	global gDevice
	
	# check each moving motor
	foreach motor $gDevice(moving_motor_list) {
		
		if { $gDevice($motor,startedByPoll) } {
			
			# move is complete if no updates in last 1 second
			if { $gDevice($motor,timedOut) } {
				incr gDevice($motor,timeoutCount)
				  print "Timeout count for $motor = $gDevice($motor,timeoutCount)"
				
				if { $gDevice($motor,startedByPoll) } {
					set timeoutMax 5
				} else {
					set timeoutMax 25
				}
				
				if { $gDevice($motor,timeoutCount) > $timeoutMax } {
					print "Motor $motor timed out and is assumed complete."
					set gDevice($motor,timeoutCount) 0
					handle_move_complete $motor
				}
			} else {
				print "Resetting timeout count of $motor to 0"
				set gDevice($motor,timeoutCount) 0
			}
			
			# reset the timeout
			set gDevice($motor,timedOut) 1
		}
	}
	
	after 200 update_polled_motors
}
