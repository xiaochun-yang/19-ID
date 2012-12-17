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



proc update_motor_to_config { motor } {

	# global variables
	global gDevice
	global gConfig

	# common parameters
	set gConfig($motor,scaled) 				[format "%.3f" $gDevice($motor,scaled)]
	set gConfig($motor,scaledLowerLimit)	[format "%.3f" $gDevice($motor,scaledLowerLimit)]
	set gConfig($motor,scaledUpperLimit) 	[format "%.3f" $gDevice($motor,scaledUpperLimit)]
	set gConfig($motor,lowerLimitOn) 		$gDevice($motor,lowerLimitOn)
	set gConfig($motor,upperLimitOn) 		$gDevice($motor,upperLimitOn)
	set gConfig($motor,lockOn)					$gDevice($motor,lockOn)

	# real motor parameters
	if { $gDevice($motor,type) == "real_motor" } {
		set gConfig($motor,scaledBacklash) 		[format "%.3f" $gDevice($motor,scaledBacklash)]
		set gConfig($motor,unscaled) 				[expr round($gDevice($motor,unscaled)) ]
		set gConfig($motor,unscaledLowerLimit) \
			[expr round($gDevice($motor,scaledLowerLimit) * $gDevice($motor,scaleFactor)) ]
		set gConfig($motor,unscaledUpperLimit) \
			[expr round($gDevice($motor,scaledUpperLimit) * $gDevice($motor,scaleFactor)) ]
		set gConfig($motor,unscaledBacklash)	\
			[expr round($gDevice($motor,scaledBacklash) * $gDevice($motor,scaleFactor)) ]
		set gConfig($motor,speed) 					[expr round($gDevice($motor,speed)) ]
		set gConfig($motor,acceleration) 		[expr round($gDevice($motor,acceleration)) ]
		set gConfig($motor,scaleFactor) 			[format "%.3f" $gDevice($motor,scaleFactor) ]
		set gConfig($motor,backlashOn) 			$gDevice($motor,backlashOn)
		set gConfig($motor,reverseOn) 			$gDevice($motor,reverseOn)
	}
	
	# reset changed flags
	reset_config_changed_flags $motor
}


proc reset_config_changed_flags { motor } {

	# global variables
	global gConfig
	global gDevice
	
	# reset common flags
	set gConfig($motor,scaled,changed)			0
	set gConfig($motor,upperLimit,changed)		0
	set gConfig($motor,lowerLimit,changed)		0
	set gConfig($motor,lowerLimitOn,changed)	0
	set gConfig($motor,upperLimitOn,changed)	0
	set gConfig($motor,lockOn,changed)			0

	# reset real motor flags
	if { $gDevice($motor,type) == "real_motor" } {
		set gConfig($motor,scaleFactor,changed)	0
		set gConfig($motor,speed,changed)			0
		set gConfig($motor,acceleration,changed)	0
		set gConfig($motor,backlash,changed)		0
		set gConfig($motor,backlashOn,changed)		0
		set gConfig($motor,reverseOn,changed)		0
	}
}


proc apply_real_config { motor } {

	# global variables
	global gDevice
	global gConfig
	
	# make sure gui is master
	if { ! [dcss is_master] } {
		log_error "Configuration changes not applied.  GUI is not master."
		return
	}
	
	# make sure no fields are blank
	foreach field { 									\
			gConfig($motor,scaledUpperLimit) 	\
			gConfig($motor,scaled)					\
			gConfig($motor,scaledUpperLimit)		\
			gConfig($motor,scaleFactor) 			\
			gConfig($motor,speed)					\
			gConfig($motor,acceleration)			\
			gConfig($motor,scaledBacklash) } {
		if { [is_blank [eval set $field] ] } {
			log_error "Configuration changes not applied.  One or more fields are blank."
			return
		}
	}

	# make sure scale factor is nonzero
	if { $gConfig($motor,scaleFactor) < 0.0000001 } {
		log_error "Configuration changes not applied.  Scale factor must be greater than zero."
		return
		}
	
	# make sure speed is nonzero
	if { $gConfig($motor,speed) <= 0.0 } {
		log_error "Configuration changes not applied.  Speed must be positive."
		return
		}
	# make sure acceleration is nonzero
	if { $gConfig($motor,acceleration) < 0.0000001 } {
		log_error "Configuration changes not applied.  Acceleration must be greater \
			than zero."
		return
		}



	
	set backlash [expr round($gConfig($motor,scaledBacklash) * \
										  $gConfig($motor,scaleFactor) ) ]
	
	dcss sendMessage "gtos_configure_device $motor \
			$gConfig($motor,scaled)\
			$gConfig($motor,scaledUpperLimit)\
			$gConfig($motor,scaledLowerLimit)\
			$gConfig($motor,scaleFactor)\
			$gConfig($motor,speed)\

			$gConfig($motor,acceleration)\
			$backlash\
			$gConfig($motor,lowerLimitOn)\
			$gConfig($motor,upperLimitOn)\
			$gConfig($motor,lockOn)\
			$gConfig($motor,backlashOn)\
			$gConfig($motor,reverseOn) "

	update_motor_to_config $motor
	
	# set focus to main window
	focus .
	
	# re-enable motor moves
	set gDevice($motor,configInProgress) 0
	

	# turn each of the checkbutton labels black
	foreach parameter { upperLimitOn lowerLimitOn lockOn backlashOn reverseOn } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black	\
			-activeforeground black
	}

	# turn each of the entry labels black
	foreach parameter { backlash scaleFactor speed acceleration upperLimit lowerLimit scaled } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black
	}

	# turn the config motor label black
	$gConfig($motor,label) configure \
		-foreground black

	# disable the apply button
	$gConfig($motor,apply) configure \
		-state disabled	\
		-foreground black	\
		-activeforeground black
		
	# set cancel button back to "close"
	$gConfig($motor,cancel) configure -text "Close"  -command "destroy_mdw_document ${motor}config"
			
	# reset changed flags
	reset_config_changed_flags $motor
	}






proc apply_pseudo_config { motor } {

	# global variables
	global gDevice
	global gConfig
	
	# make sure gui is master
	if { ! [dcss is_master] } {
		log_error "Configuration changes not applied.  GUI is not master."
		return
	}
	
	# make sure no fields are blank
	foreach field { 									\
			gConfig($motor,scaledUpperLimit) 	\
			gConfig($motor,scaled)					\
			gConfig($motor,scaledUpperLimit) } {
		if { [is_blank [eval set $field] ] } {
			log_error "Configuration changes not applied.  One or more fields are blank."
			return
		}
	}



	dcss sendMessage "gtos_configure_device $motor \
			$gConfig($motor,scaled) 			\
			$gConfig($motor,scaledUpperLimit)\
			$gConfig($motor,scaledLowerLimit)\
			$gConfig($motor,lowerLimitOn)\
			$gConfig($motor,upperLimitOn)\
			$gConfig($motor,lockOn)	"

	update_motor_to_config $motor
	
	# set focus to main window
	focus .
	
	# re-enable motor moves
	set gDevice($motor,configInProgress) 0
	
	# turn each of the checkbutton labels black
	foreach parameter { upperLimitOn lowerLimitOn lockOn } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black	\
			-activeforeground black
	}

	# turn each of the entry labels black
	foreach parameter { upperLimit lowerLimit scaled } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black
	}

	# turn the config motor label black
	$gConfig($motor,label) configure \
		-foreground black

	# disable the apply button
	$gConfig($motor,apply) configure \
		-state disabled	\
		-foreground black	\
		-activeforeground black
		
	# set cancel button back to "close"
	$gConfig($motor,cancel) configure -text "Close" -command "destroy_mdw_document ${motor}config"
			
	# reset changed flags
	reset_config_changed_flags $motor

	}







proc undo_pseudo_config { motor } {

	# global variables
	global gDevice
	global gConfig
	
	update_motor_to_config $motor
	
	# set focus to main window
	focus .
	
	# re-enable motor moves
	set gDevice($motor,configInProgress) 0
	
	# turn each of the checkbutton labels black
	foreach parameter { upperLimitOn lowerLimitOn lockOn } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black	\
			-activeforeground black
	}

	# turn each of the entry labels black
	foreach parameter { upperLimit lowerLimit scaled } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground black
	}

	# turn the config motor label black
	$gConfig($motor,label) configure \
		-foreground black

	# disable the apply button
	$gConfig($motor,apply) configure \
		-state disabled	\
		-foreground black	\
		-activeforeground black
		
	# set cancel button back to "close"
	$gConfig($motor,cancel) configure -text "Close" -command "destroy_mdw_document ${motor}config"
			
	# reset changed flags
	reset_config_changed_flags $motor

	}












proc updateUpperLimitEntryStates { motor } {

	# global variables
	global gConfig
	global gWindows

	# disable upper limit fields if disabled
	if { ! $gConfig($motor,upperLimitOn) } {
		$gWindows(config,$motor,scaledUpperLimitEntry) config -state disabled \
			-foreground grey	
		catch { $gWindows(config,$motor,unscaledUpperLimitEntry) config -state disabled \
			-foreground grey }
	} else { 
		$gWindows(config,$motor,scaledUpperLimitEntry) config -state normal \
			-foreground black
		catch { $gWindows(config,$motor,unscaledUpperLimitEntry) config -state normal \
			-foreground black }
	}	
}


proc updateLowerLimitEntryStates { motor } {

	# global variables
	global gConfig
	global gWindows

	
	# disable upper limit fields if disabled
	if { ! $gConfig($motor,lowerLimitOn) } {
		$gWindows(config,$motor,scaledLowerLimitEntry) config -state disabled \
			-foreground grey	
		catch { $gWindows(config,$motor,unscaledLowerLimitEntry) config -state disabled \
			-foreground grey }
	} else { 
		$gWindows(config,$motor,scaledLowerLimitEntry) config -state normal \
			-foreground black
		catch { $gWindows(config,$motor,unscaledLowerLimitEntry) config -state normal \
			-foreground black }
	}
}


proc construct_real_config { motor parent } {

	# global variables
	global gDevice
	global gConfig
	global gColors
	global gLabeledFrame
	global gWindows
	
	# update config values to current motor values
	update_motor_to_config $motor

	# make the motor name label
	set gConfig($motor,label) [label $parent.label -text "$motor" \
		-font "*-helvetica-medium-r-normal--34-*-*-*-*-*-*-*" ]
	pack $parent.label -pady 15

	# create motion parameter labeled frame
	set labelFrame [ labeledFrame $parent.limits \
		-label "Position and Limits" -width 400 -height 215 ]
	set positionFrame $gLabeledFrame(limits,frame)
	place $labelFrame -x 20 -y 60	

	# make a frame to hold the position entries
	set entryFrame [ frame $positionFrame.entry ]
	bind $entryFrame <Button-1> "activate_mdw_document ${motor}config"	
	pack $entryFrame -pady 0

	# make the upper limit entries
	doubleScaleEntry $parent.upper "Upper limit: " 	\
		$gDevice($motor,scaledUnits) 						\
		gConfig($motor,scaledUpperLimit)					\
		gConfig($motor,unscaledUpperLimit)				\
		gConfig($motor,scaleFactor)						\
		$motor upperLimit

	# store paths to limit entry fields
	set gWindows(config,$motor,scaledUpperLimitEntry) $parent.upper.scaled.entry
	set gWindows(config,$motor,unscaledUpperLimitEntry) $parent.upper.unscaled.entry

	# update the entry field states
	updateUpperLimitEntryStates $motor
	
	# make the set position entries
	doubleScaleEntry $parent.position "Position: " \
		$gDevice($motor,scaledUnits) 							\
		gConfig($motor,scaled) 									\
		gConfig($motor,unscaled)								\
		gConfig($motor,scaleFactor)							\
		$motor scaled

	# make the lower limit entries
	doubleScaleEntry $parent.lower "Lower limit: "	\
		$gDevice($motor,scaledUnits) 						\
		gConfig($motor,scaledLowerLimit)					\
		gConfig($motor,unscaledLowerLimit)				\
		gConfig($motor,scaleFactor)							\
		$motor lowerLimit

	# store paths to limit entry fields
	set gWindows(config,$motor,scaledLowerLimitEntry) $parent.lower.scaled.entry
	set gWindows(config,$motor,unscaledLowerLimitEntry) $parent.lower.unscaled.entry

	# update the entry field states
	updateLowerLimitEntryStates $motor

	# pack the position frame
	pack  $parent.upper $parent.position $parent.lower \
		-in $entryFrame										\
		-padx 10 -pady 4
		
	# make a frame to hold the position check boxes
	set checkFrame [ frame $parent.positionChecks ]
	pack $parent.positionChecks 	\
		-in $entryFrame			\
		-pady 10
	
	# make the three position checkboxes
	set gConfig($motor,upperLimitOn,widget) [
		checkbutton $checkFrame.checkUpper			\
			-text "Enable upper limit" 				\
			-font $gConfig(font)							\
			-variable gConfig($motor,upperLimitOn)	\
			-command "real_config_parameter_changed $motor upperLimitOn 1;updateUpperLimitEntryStates $motor" ]
	set gConfig($motor,lowerLimitOn,widget) [
			checkbutton $checkFrame.checkLower		\
			-text "Enable lower limit" 				\
			-font $gConfig(font)							\
			-variable gConfig($motor,lowerLimitOn)	\
			-command "real_config_parameter_changed $motor lowerLimitOn 1;updateLowerLimitEntryStates $motor" ]
	set gConfig($motor,lockOn,widget) [
		checkbutton $checkFrame.checkLock	\
		-text "Lock motor" 						\
		-font $gConfig(font)						\
		-variable gConfig($motor,lockOn)		\
		-command "real_config_parameter_changed $motor lockOn 1" ]
	
	pack $checkFrame.checkUpper $checkFrame.checkLower $checkFrame.checkLock \
		-anchor w -pady 4

	# create stepper motor parameter labeled frame
	set labelFrame [ labeledFrame $parent.motion \
		-label "Stepper Motor" -width 330 -height 215 ]
	set frame $gLabeledFrame(motion,frame)

	place $labelFrame -x 450 -y 60

	# make the scale factor entry
	set entry [doubleLabelEntry $frame.scale "Scale factor: " 	\
	 	" steps/$gDevice($motor,scaledUnits)" 14 10 14	\
		gConfig($motor,scaleFactor) gConfig($motor,scaleFactor,widget) ]
	clearTraces gConfig($motor,scaleFactor) 
	trace variable gConfig($motor,scaleFactor) w \
		"traceConfigScaleFactor $motor $entry"
	storeValue gConfig($motor,scaleFactor) $gConfig($motor,scaleFactor)

	# make the speed entry
	set entry [doubleLabelEntry $frame.speed "Speed: " " steps/sec" \
		14 10 14	gConfig($motor,speed) gConfig($motor,speed,widget) ]
	clearTraces gConfig($motor,speed)
	trace variable gConfig($motor,speed) w \
		"tracePositiveIntEntry gConfig($motor,speed) $entry $motor speed"
	storeValue gConfig($motor,speed) $gConfig($motor,speed)
	
	# make the acceleration entry
	set entry [doubleLabelEntry $frame.accel "Accel. time: " " msec" \
		14 10 14	gConfig($motor,acceleration) gConfig($motor,acceleration,widget) ]
	clearTraces gConfig($motor,acceleration)
	trace variable gConfig($motor,acceleration) w \
		"tracePositiveIntEntry gConfig($motor,acceleration) $entry $motor acceleration"
	storeValue gConfig($motor,acceleration) $gConfig($motor,acceleration)
		
	# make the backlash entry
	set backlashframe [frame $frame.backlash]
	set gConfig($motor,backlash,widget) [label $backlashframe.label \
		-text "Backlash: "		\
		-font $gConfig(font)		\
		-width 10 					\
		-anchor e ]
	set valueFrame [frame $backlashframe.valueFrame ] 
	set gConfig($motor,backlash,value) [entry $valueFrame.value \
		-font $gConfig(font)					\
		-justify right							\
		-width 10 ]
	if { ![info exists gConfig($motor,backlashUnits)] || \
		$gConfig($motor,backlashUnits) == "" } {
			set gConfig($motor,backlashUnits) "steps"
	}
	comboBox $valueFrame.${motor}_units					\
		-variable gConfig($motor,backlashUnits)		\
		-command "backlashUnitsChanged $motor"			\
		-choices "$gDevice($motor,scaledUnits) steps"	\
		-font $gConfig(font) -menufont $gConfig(font)\
		-width 6
		

	backlashUnitsChanged $motor
		
	pack $valueFrame.value $valueFrame.${motor}_units \
		-side left
	pack $backlashframe.label $backlashframe.valueFrame \
		-side left -padx 2
	storeValue gConfig($motor,scaledBacklash) $gConfig($motor,scaledBacklash)
	storeValue gConfig($motor,unscaledBacklash) $gConfig($motor,unscaledBacklash)

	# pack the stepper motor entries
	pack $frame.scale $frame.speed $frame.accel $frame.backlash \
		-pady 4		

	# create the stepper motor checkboxes
	set checkFrame [ frame $frame.motionChecks ]
	pack $frame.motionChecks 	\
		-pady 10
	set gConfig($motor,backlashOn,widget) [
		checkbutton $checkFrame.checkBacklash	\
		-text "Enable anti-backlash"	 			\
		-font $gConfig(font)							\
		-variable gConfig($motor,backlashOn)	\
		-command "real_config_parameter_changed $motor backlashOn 1" ]
	set gConfig($motor,reverseOn,widget) [
		checkbutton $checkFrame.checkReverse	\
		-text "Reverse motor direction" 			\
		-font $gConfig(font)							\
		-variable gConfig($motor,reverseOn)		\
		-command "real_config_parameter_changed $motor reverseOn 1" ]
	pack $checkFrame.checkBacklash $checkFrame.checkReverse \
		-anchor w -pady 4

	# make the Apply button
	set gConfig($motor,apply) [button $parent.apply \
		-text "Apply"		\
		-width 10			\
		-state disabled	\
		-command "apply_real_config $motor" ]
	place $parent.apply -x 260 -y 340

	# make the Cancel button
	set gConfig($motor,cancel) [button $parent.cancel	\
		-text "Close"			\
		-width 10				\
		-command "destroy_mdw_document ${motor}config"]
	place $parent.cancel -x 410 -y 340
}



proc construct_pseudo_config { motor parent } {

	# global variables
	global gDevice
	global gConfig
	global gColors
	global gLabeledFrame
	global gSafeEntry
	global gWindows
	
	# update config values to current motor values
	update_motor_to_config $motor

	# make the motor name label
	set gConfig($motor,label) [label $parent.label -text "$motor" \
		-font "*-helvetica-medium-r-normal--34-*-*-*-*-*-*-*" ]
	pack $parent.label -pady 15

	# create motion parameter labeled frame
	set labelFrame [ labeledFrame $parent.limits \
		-label "Position and Limits" -width 280 -height 215 ]
	set positionFrame $gLabeledFrame(limits,frame)
	place $labelFrame -x 20 -y 60	

	# make a frame to hold the position entries
	set entryFrame [ frame $positionFrame.entry ]
	pack $entryFrame -pady 0

	pack [ safeEntry $entryFrame.${motor}_upper_limit	\
		-variable gConfig($motor,scaledUpperLimit) -units " $gDevice($motor,scaledUnits)" -width 10 	\
		-label "Upper limit: " -type float -font $gConfig(font) -labelwidth 15 \
		-command "real_config_parameter_changed $motor upperLimit 0" ] -pady 4 -padx 10
	set gConfig($motor,upperLimit,widget) $gSafeEntry(${motor}_upper_limit,label)

	# store paths to limit entry fields
	set gWindows(config,$motor,scaledUpperLimitEntry) $gSafeEntry(${motor}_upper_limit,entry);

	# update the entry field states
	updateUpperLimitEntryStates $motor

	pack [ safeEntry $entryFrame.${motor}_scaled	\
		-variable gConfig($motor,scaled) -units " $gDevice($motor,scaledUnits)" -width 10 	\
		-label "Position: " -type float -font $gConfig(font) -labelwidth 15 -state normal \
		-command "real_config_parameter_changed $motor scaled 0" ] -pady 4 -padx 10
	set gConfig($motor,scaled,widget) $gSafeEntry(${motor}_scaled,label)

	pack [ safeEntry $entryFrame.${motor}_lower_limit	\
		-variable gConfig($motor,scaledLowerLimit) -units " $gDevice($motor,scaledUnits)" -width 10 	\
		-label "Lower limit: " -type float -font $gConfig(font) -labelwidth 15  \
		-command "real_config_parameter_changed $motor lowerLimit 0"] -pady 4 -padx 10
	set gConfig($motor,lowerLimit,widget) $gSafeEntry(${motor}_lower_limit,label)

	# store paths to limit entry fields
	set gWindows(config,$motor,scaledLowerLimitEntry) $gSafeEntry(${motor}_lower_limit,entry);

	# update the entry field states
	updateLowerLimitEntryStates $motor


	# make a frame to hold the position check boxes
	set checkFrame [ frame $parent.positionChecks ]
	pack $parent.positionChecks 	\
		-in $entryFrame			\
		-pady 10
	
	# make the three position checkboxes
	set gConfig($motor,upperLimitOn,widget) [
		checkbutton $checkFrame.checkUpper			\
			-text "Enable upper limit" 				\
			-font $gConfig(font)							\
			-variable gConfig($motor,upperLimitOn)	\
			-command "real_config_parameter_changed $motor upperLimitOn 1;updateUpperLimitEntryStates $motor" ]
	set gConfig($motor,lowerLimitOn,widget) [
			checkbutton $checkFrame.checkLower		\
			-text "Enable lower limit" 				\
			-font $gConfig(font)							\
			-variable gConfig($motor,lowerLimitOn)	\
			-command "real_config_parameter_changed $motor lowerLimitOn 1;updateLowerLimitEntryStates $motor" ]
	set gConfig($motor,lockOn,widget) [
		checkbutton $checkFrame.checkLock	\
		-text "Lock motor" 						\
		-font $gConfig(font)						\
		-variable gConfig($motor,lockOn)		\
		-command "real_config_parameter_changed $motor lockOn 1" ]
	
	pack $checkFrame.checkUpper $checkFrame.checkLower $checkFrame.checkLock \
		-anchor w -pady 4 -padx 50

	# make the Apply button
	set gConfig($motor,apply) [button $parent.apply \
		-text "Apply"		\
		-width 10			\
		-state disabled	\
		-command "apply_pseudo_config $motor" ]
	place $parent.apply -x 30 -y 340

	# make the Cancel button
	set gConfig($motor,cancel) [button $parent.cancel	\
		-text "Close"			\
		-width 10				\
		-command "destroy_mdw_document ${motor}config"]
	place $parent.cancel -x 180 -y 340
}



proc destroy_motor_config { motor } {

	# global variables
	global gDevice
	
	set gDevice($motor,configInProgress) 0
}


proc backlashUnitsChanged { motor args } {

	# global variables
	global gConfig

	if { $gConfig($motor,backlashUnits) == "steps" } {
		$gConfig($motor,backlash,value) configure \
			-textvariable gConfig($motor,unscaledBacklash)
		clearTraces gConfig($motor,unscaledBacklash)
		trace variable gConfig($motor,unscaledBacklash) w \
			"traceUnscaledEntry gConfig($motor,unscaledBacklash) \
			gConfig($motor,scaledBacklash) gConfig($motor,scaleFactor)	\
			 $gConfig($motor,backlash,value) $motor backlash"	
		clearTraces gConfig($motor,scaledBacklash)		
	} else {
		$gConfig($motor,backlash,value) configure \
			-textvariable gConfig($motor,scaledBacklash)
		clearTraces gConfig($motor,scaledBacklash)
		trace variable gConfig($motor,scaledBacklash) w \
			"traceScaledEntry gConfig($motor,scaledBacklash) \
			gConfig($motor,unscaledBacklash) gConfig($motor,scaleFactor)	\
			 $gConfig($motor,backlash,value) $motor backlash"
		clearTraces gConfig($motor,unscaledBacklash)
	}
}


proc real_config_parameter_changed { motor parameter {isCheckbutton 0} } {

	# global variables
	global gConfig
	global gColors

	# return immediately if already changed
	if { $gConfig($motor,$parameter,changed) } {
		return 
	}
	
	# record the change
	set gConfig($motor,$parameter,changed) 1
	real_config_changed $motor
	
	# change color of label

	if { $isCheckbutton } {
		$gConfig($motor,$parameter,widget) configure \
			-foreground $gColors(changed)					\
			-activeforeground $gColors(changed)
	} else {
		$gConfig($motor,$parameter,widget) configure \
			-foreground $gColors(changed)	
	}
}


proc real_config_changed { motor } {

	# global variables
	global gDevice
	global gConfig
	global gColors

	set gDevice($motor,configInProgress) 1
	
	$gConfig($motor,label) configure \
		-foreground $gColors(changed)

	$gConfig($motor,apply) configure 	\
			-foreground $gColors(changed)	\
			-activeforeground $gColors(changed)

	# set cancel button to "Cancel"
	$gConfig($motor,cancel) configure -text "Cancel"

	# activate apply button only if motor is inactive
	if { $gDevice($motor,status) == "inactive" } {
		$gConfig($motor,apply) configure -state normal
	}
}


proc doubleScaleEntry { frame label units scaled unscaled scale motor parameter } {

	# global variables
	global gConfig

	# make the scaled and unscaled entries
	frame $frame
	set scaledEntry [ doubleLabelEntry $frame.scaled $label \
		" $units" 12 10 4  $scaled gConfig($motor,$parameter,widget) ]
	set unscaledEntry [ doubleLabelEntry $frame.unscaled "" \
		" steps" 0 10 5 $unscaled ]
	pack $frame.scaled $frame.unscaled \
		-side left -padx 1

	storeValue $unscaled [set $unscaled]
	storeValue $scaled [set $scaled]

	clearTraces $scaled
	trace variable $scaled w \
		"traceScaledEntry $scaled $unscaled $scale $scaledEntry $motor $parameter" 

	clearTraces $unscaled
	trace variable $unscaled w \
		"traceUnscaledEntry $unscaled $scaled $scale $unscaledEntry $motor $parameter" 		
}


proc storeValue { key value } {

	# global variables
	global gStorage
	
	set gStorage($key) $value
	
	}
	

proc recallValue { key } {

	# global variables
	global gStorage
	
	return $gStorage($key)
}




proc doubleLabelEntry { frame leftLabel rightLabel leftWidth entryWidth \
								rightWidth variable {widget default} } {

	# global variables
	global gDevice
	global gConfig
	global gColors
	
	if { $widget == "default" } {
		set widget discard
	}
	
	# create frame to hold labels and entry
	frame $frame
	
	# create the left label
	set $widget [ label $frame.left -text $leftLabel -width $leftWidth	\
		-foreground black	-anchor e -font $gConfig(font) ]

	# create the right label
	label $frame.right -text $rightLabel -foreground black	\
		-width $rightWidth -font $gConfig(font) -anchor w
		
	# create the entry
	set entry [
		entry $frame.entry 			\
			-width $entryWidth		\
			-justify right				\
			-foreground black		\
			-textvariable $variable \
			-font $gConfig(font) ]

	# pack the labels and entry
	pack $frame.left $frame.entry $frame.right -side left
	
	# return the entry
	return $entry
}



proc setScaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,scaled) $value
	
	if { $gDevice($motor,type) == "real_motor" } {
		set gDevice($motor,unscaled) \
			[expr ($gDevice($motor,scaled) * $gDevice($motor,scaleFactor) ) ]
	}
}


proc setUnscaledValue { motor value } {

	# global variables
	global gDevice

	set gDevice($motor,unscaled) $value
	
	set gDevice($motor,scaled) 											\
		[expr ($gDevice($motor,unscaled) / $gDevice($motor,scaleFactor) ) ]
}


proc getScaledValue { motor unscaled } {

	# global variables
}


proc popConfigureWindow { motor } {
	
	# global variables
	global gDevice
	global gDocument
	
	# expand motor name abbreviation
	set motor [expandMotorAbbrev $motor ]
	
	# check for null string
	if { $motor == "" } {
		log_error "No motor has been selected."
		return
	}
		
	# make sure motor exists
	if { ! [motor_exists $motor] } {
		log_error "Motor $motor does not exist."
		return
	}		
	
	# create the configure document for the motor if it doesn't exist
	if { [mdw_document_exists ${motor}config] } {
		show_mdw_document ${motor}config
	} else {
		if { $gDevice($motor,type) == "real_motor" } {
			create_mdw_document ${motor}config "$motor configuration" 820 430 \
				"construct_real_config $motor" "destroy_motor_config $motor"
		} else {
			create_mdw_document ${motor}config "$motor configuration" 350 430 \
				"construct_pseudo_config $motor" "destroy_motor_config $motor"
		}
		# show the document
		show_mdw_document ${motor}config
		set gDocument(${motor}config,activateCommand) "select_motor $motor ${motor}config"
	}
	
	select_motor $motor ${motor}config
	
	# return with no further processing
	return
}


proc configUnitedParameter { motor parameter value units } {

	# global variables
	global gDevice
	global gConfig
			
	# use scaled units if none specified
	if { $units == "" } {
		set units [lindex $gDevice($motor,scaledUnits) 0]
	} 
			
	# determine type of units
	set unitIndex [lsearch $gDevice($motor,units) $units]
	
	# check if motor can be moved in units of current increment
	if { $unitIndex == -1 } {
		log_error "Motor $motor cannot be moved in $units."
		return -1
	}
			
	# handle optional scaled units
	set displayValue $value
	if { $units != "steps" && $unitIndex > 0 } {
		set value [convert_scaled_units $value \
			$units $gDevice($motor,scaledUnits) ]
		set unitIndex 0
	}
		
	# handle each possible parameter		
	switch $parameter {
		
		position {	
			if { $unitIndex == 0 } {
				setScaledValue $motor $value
			} else {
				setUnscaledValue $motor $value
			}
			log "Position of motor $motor set to $displayValue $units."
		}
		
		backlash {
			if { $unitIndex == 0 } {
				setBacklashFromScaledValue $motor $value
			} else {
				setBacklashFromUnscaledValue $motor $value
			}
			log "Backlash for motor $motor set to $displayValue $units."
		}		
	
		lower_limit {
			if { $unitIndex == 0 } {
				setLowerLimitFromScaledValue $motor $value
			} else {
				setLowerLimitFromUnscaledValue $motor $value
			}
			log "Lower limit for motor $motor set to $displayValue $units."
		}
		
		upper_limit {
			if { $unitIndex == 0 } {
				setUpperLimitFromScaledValue $motor $value			
			} else {
				setUpperLimitFromUnscaledValue $motor $value 
			}
			log "Upper limit for motor $motor set to $displayValue $units."
		}	
	}
}


proc configUnitlessParameter { motor parameter value } {

	# global variables
	global gDevice
	global gConfig
			
	# handle each possible parameter		
	switch $parameter {
		
		speed {
			if { $value >= 0 } {
				setSpeedValue $motor $value
				log "Speed for motor $motor set to $gDevice($motor,speed) steps/sec."
			} else {
				log_error "Motor speed must be greater or equal to 0 step/sec."
			}

		}
		
		acceleration {
			if { $value >= 1 } {		
				setAccelerationValue $motor $value
				log "Acceleration for motor $motor set to \
					$gDevice($motor,acceleration) steps/sec**2."
			} else {
				log_error "Motor acceleration must be greater or \
					equal to 1 step/sec**2."
			}
		}

		scale {
			if { $value >= 1 } {
				setScaleFactorValue $motor $value
				log "Scale factor for motor $motor set to \
					$gDevice($motor,scaleFactor) steps/$gDevice($motor,scaledUnits)."
			} else {
				log_error "Scale factor must be greater or equal to 1 \
					steps/$gDevice($motor,scaledUnits)."
			}
		}
		
		lock_enable {
			setLockEnableValue $motor $value
			if { $value } {
				log "Motor $motor locked."
			} else {
				log "Motor $motor unlocked."
			}
		}

		lower_limit_enable {
			setLowerLimitEnableValue $motor $value 
			if { $value } {
				log "Lower limit for motor $motor enabled."
			} else {
				log "Lower limit for motor $motor disabled."
			}
		}
		 
		upper_limit_enable {
			setUpperLimitEnableValue $motor $value
			if { $value } {
				log "Upper limit for motor $motor enabled."
			} else {
				log "Upper limit for motor $motor disabled."
			}
		}

		reverse_enable {
			setReverseEnableValue $motor $value
			if { $value } {
				log "Direction of motor $motor is reverse."
			} else {
				log "Direction of motor $motor is forward."
			}
		}
		
		backlash_enable {
			setBacklashEnableValue $motor $value
			if { $value } {
				log "Anti-backlash correction for motor $motor enabled."
			} else {
				log "Anti-backlash correction for motor $motor disabled."
			}
		}
	}
}


proc setUpperLimitFromScaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig

	set gDevice($motor,scaledUpperLimit) $value
	set gConfig($motor,scaledUpperLimit) [ format "%.3f" $value]
	
	if { $gDevice($motor,type) == "real_motor" } {	
		set unscaled [expr $value * $gDevice($motor,scaleFactor) ]
		set gConfig($motor,unscaledUpperLimit) [expr round($unscaled)]
	}
}


proc setUpperLimitFromUnscaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig

	set gConfig($motor,unscaledUpperLimit) [expr round($value)]
	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledUpperLimit) $scaled
	set gConfig($motor,scaledUpperLimit) [ format "%.3f" $scaled]
}


proc setLowerLimitFromScaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig
				
	set gDevice($motor,scaledLowerLimit) $value
	set gConfig($motor,scaledLowerLimit) [ format "%.3f" $value]
	
	if { $gDevice($motor,type) == "real_motor" } {
		set unscaled [expr $value * $gDevice($motor,scaleFactor) ]
		set gConfig($motor,unscaledLowerLimit) [expr round($unscaled)]
	}
}


proc setLowerLimitFromUnscaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig
				
	set gConfig($motor,unscaledLowerLimit) [expr round($value)]
	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledLowerLimit) $scaled
	set gConfig($motor,scaledLowerLimit) [ format "%.3f" $scaled]
}


proc setBacklashFromScaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig

	set gDevice($motor,scaledBacklash) $value
	set gConfig($motor,scaledBacklash) [ format "%.3f" $value]
	set unscaled [expr $value * $gDevice($motor,scaleFactor) ]
	set gConfig($motor,unscaledBacklash) [expr round($unscaled)]				
}


proc setBacklashFromUnscaledValue { motor value } {

	# global variables
	global gDevice
	global gConfig

	set gConfig($motor,unscaledBacklash) [expr round($value)]
	set scaled [expr $value / $gDevice($motor,scaleFactor) ]
	set gDevice($motor,scaledBacklash) $scaled
	set gConfig($motor,scaledBacklash) [ format "%.3f" $scaled]			
}


proc setSpeedValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,speed) [expr round($value)]
	set gConfig($motor,speed) $gDevice($motor,speed)		
}


proc setAccelerationValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,acceleration) [expr round($value)]
	set gConfig($motor,acceleration) $gDevice($motor,acceleration)
}


proc setScaleFactorValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,scaleFactor) $value
	set gConfig($motor,scaleFactor) $value
}


proc setLockEnableValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,lockOn) $value
	set gConfig($motor,lockOn) $value
}

proc setLowerLimitEnableValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,lowerLimitOn) $value
	set gConfig($motor,lowerLimitOn) $value
}

proc setUpperLimitEnableValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,upperLimitOn) $value
	set gConfig($motor,upperLimitOn) $value
}

proc setReverseEnableValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,reverseOn) $value
	set gConfig($motor,reverseOn) $value
}

proc setBacklashEnableValue { motor value } {

	# global variables
	global gDevice
	global gConfig
	
	set gDevice($motor,backlashOn) $value
	set gConfig($motor,backlashOn) $value
}


proc setSubcomponentList { motor value } {

	# global variables
	global gDevice
	
	set gDevice($motor,subcomponentList) $value
}




