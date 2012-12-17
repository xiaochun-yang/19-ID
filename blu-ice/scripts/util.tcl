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


set gWait(status) inactive
set gDebugComments 0
set gOperationCounter 0

######################################################################
# null_function -- a function that does nothing for menu commands that
# do nothing
######################################################################

proc null_function {} {}



proc distance { x1 y1 x2 y2 } {

	expr ($x2 - $x1) * ($x2 - $x1 ) + ($y2 - $y1) * ($y2 - $y1)
	
}


proc time_stamp {} {
	clock format [clock seconds] -format "%d %b %Y %X"
}

proc wait_for_encoder { encoderList } {
	global gDevice

	print "waiting for $encoderList"

	# first check that all specified devices exist
	foreach encoder $encoderList {
		if { ![info exists gDevice($encoder,status)] } {
			log_error "$encoder does not exist"
			return -code error
		}
	}
	
	# now wait for each device in turn
	foreach encoder $encoderList {
		# wait for device to become inactive or aborting
		while { $gDevice($encoder,status) != "inactive" } {
			vwait gDevice($encoder,status)
		}
	}

	print "encoder $encoderList completed"
}

proc wait_for_devices { args } {

	# global variables
	global gDevice
	global gWait

	# make sure timer is not already in use
	if { $gWait(status) != "inactive" } {
		log_error "Wait already in use!"
		return -code error
	}
	
	# first check that all specified devices exist
	foreach device $args {
	
		# return an error if device doesn't exist
		if { ![isDevice $device]  } {
			log_error "Device $device does not exist!"
			return -code error
		}
	}

	# set wait status to waiting
	set gWait(status) waiting

	# now wait for each device in turn
	foreach device $args {

		# wait for device to become inactive or aborting
		while { $gDevice($device,status) != "inactive" && \
			$gDevice($device,status) != "aborting" } {
			vwait gDevice($device,status)
		}

		# report error if wait was aborted
		if { $gWait(status) == "aborting" } {
			set gWait(status) inactive
			return -code 5
		}
	}

	# all done so set status to inactive
	set gWait(status) inactive
}


proc wait_for_time { time } {

	# global variables
	global gWait

	# make sure timer is not already in use
	if { $gWait(status) != "inactive" } {
		log_error "Wait already in use!"
		return -code error
	}
	
	# set the status to waiting
	set gWait(status) waiting
	
	# set timer to change status after specified amount of timer
	set afterID [after $time { set gWait(status) complete }]
	
	# wait for status to change
	vwait gWait(status)

	# cancel 'after' command and return an error if wait was aborted
	if { $gWait(status) == "aborting" } {
		catch [after cancel $afterID]
		set gWait(status) inactive
		return -code 5
	}
	
	# otherwise set status to inactive and return
	set gWait(status) inactive
	return
}


proc isDevice { device } {

	# global variables
	global gDevice

	# return true if the device has an entry in the gDevice array
	return [ info exists gDevice($device,type) ]
}


proc isMotor { device } {

	# global variables
	global gDevice

	# return true if device is either a real or pseudo motor
	return [expr {[isDeviceType real_motor $device] || 
		[isDeviceType pseudo_motor $device] }]
}



proc isDeviceType { type device } {
	
	# global variables
	global gDevice

	# return true if device exists and is specified type
	return [expr { [isDevice $device] && $gDevice($device,type) == $type }]
	}




proc isPrep { prep } {

	if { $prep == "by" || $prep == "to" } {
		return 1
	} else {
		return 0
	}
}

proc isUnits { units } {

	# global variables
	global gDevice

	if { [lsearch $gDevice(control,unitList) $units] != -1 } {
		return 1
	} else {
		return 0
	}
}

proc isExpr { value } {

	if { ![catch { expr ($value) }] } {
		return 1
	} else {
		return 0
	}
}


proc rect_solid { canvas x y width height depth skewleft skewright {tag null} } {

	# global variables
	global gColors
	
	set x0 [expr $x + $skewleft]
	set y0 $y
	set x1 [expr $x + $width + $skewright]
	set y1 $y
	set x2 [expr $x + $width]
	set y2 [expr $y + $depth]
	set x3 $x
	set y3 $y2
	set x4 $x
	set y4 [expr $y3 + $height]
	set x5 $x2
	set y5 $y4
	set x6 $x1
	set y6 [expr $y1 + $height]
	
	if { $depth > 10 } {
		set y6 [expr $y6 - .04 * double($height) ]
	}
	
	$canvas create poly $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 \
		-fill $gColors(top) -tag $tag
	$canvas create line $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3 $x0 $y0 \
		-tag $tag
	
	$canvas create rectangle $x3 $y3 $x5 $y5 \
		-fill $gColors(front) -tag $tag

	$canvas create poly $x1 $y1 $x2 $y2 $x5 $y5 $x6 $y6 \
		-fill $gColors(side) -tag $tag
	$canvas create line $x1 $y1 $x2 $y2 $x5 $y5 $x6 $y6 $x1 $y1 \
		-tag $tag
	
}	




proc print_all_motor_positions {} {
	# global variables 
	global env
	global gBeamline
	global gDevice
	
	# make the temporary directory if needed
	file mkdir /tmp/$env(USER)
		
	#set the filename
	set filename /tmp/$env(USER)/config_$gBeamline(beamlineId).txt

	# try to open file 	
	if { [catch {set fileHandle [open $filename w ] } ] } {
		log_error "Error opening ${filename}.  Configuration not printed."
		return
	}

	# write current configuration of all motors sorted alphabetically
	foreach motor [lsort -ascii $gDevice(motor_list)] {
		#find out the motor type
		if { [device::$motor isa RealMotor ] } {
			set motorType ""
		} else {
			set motorType "Scripted"
		}

		#query the device for the position
		set position [device::$motor cget -scaledPosition] 

		#get the default units
		set units [lindex [device::$motor cget -unitsList] 0]

		puts $fileHandle [format "%-25s %17.8f %-10s %10s" $motor $position $units $motorType]
	}

	close $fileHandle
	
	if { [catch {
		exec a2ps $filename
	} errorResult ]} {
		#put the error as a note in the log window
		log_note $errorResult
	}
}

proc save_current_configuration {} {

	# global variables 
	global gDevice
	global gBeamline

	# get the name of the file to open
	set filename [tk_getSaveFile]

	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}	
		
	# try to open file 	
	if { [catch {set fileHandle [open $filename w ] } ] } {
		log_error "Error opening ${filename}.  Configuration not saved."
		return
	}
		
	# write header to file
	puts $fileHandle "# file       $filename"
	puts $fileHandle "# beamline   $gBeamline(beamlineId)"
	puts $fileHandle "# date       [time_stamp]"
	puts $fileHandle ""

	# write current positions of all motors to canvas
	foreach motor $gDevice(motor_list) {
		puts $fileHandle [format "%-18s %10.3f %s" \
			$motor $gDevice($motor,scaled) $gDevice($motor,scaledUnits)]
	}
	
	close $fileHandle
}


proc load_configuration {} {

	# global variables 
	global gDevice
	global gSave
	global gWindows
	
	# get the name of the file to open
	set filename [tk_getOpenFile]

	# make sure the file selection was not cancelled
	if { $filename == {} } {
		return
	}	
		
	# try to open file 	
	if { [catch {set fileHandle [open $filename r ] } ] } {
		log_error "Error opening ${filename}."
		return
	}
		
	# read header from file
	gets $fileHandle buffer
	gets $fileHandle buffer
	gets $fileHandle buffer
	gets $fileHandle buffer

	# erase old gSave array
	catch { unset gSave }

	# read each motor position into array
	while { [gets $fileHandle buffer] >= 0 } {
	
		# parse the configuration line
		set motor [lindex $buffer 0]
		set value [lindex $buffer 1]
		set units [lindex $buffer 2]

		# make sure motor exists
		if { ![info exists gDevice($motor,scaled)] } {
			log_error "Motor $motor does not exist."
			continue
		}
		
		# make sure units match
		if { $units != $gDevice($motor,scaledUnits) } {
			log_error "Motor $motor units do not match."
			continue
		}

		# add motor to save memory
		set gSave($motor) $value
		lappend gSave(list) $motor				
	}
	
	# close the file
	close $fileHandle

	# pop the configuration document
	pop_beamline_configuration

	# fill in the listbox
	refresh_beamline_configuration
}


proc refresh_beamline_configuration {} {
	
	# global variables 
	global gDevice
	global gSave
	global gWindows
	global gMode
	
	# do nothing if window not up
	if { ! [mdw_document_exists beamline_configuration] } {
		return
	}
		
	# clear the listbox
	$gWindows(configListbox) clear
	
	foreach motor $gSave(list)	{
		if { [expr abs( $gDevice($motor,scaled) - $gSave($motor) ) > 0.001] } {
		
			set line [format " %-18s %10.3f  %s" $motor $gSave($motor) \
				$gDevice($motor,scaledUnits) ]
			$gWindows(configListbox) insert end $line
		}
	}
}


proc pop_beamline_configuration {} {

	# global variables
	global gDevice

	# create the document if it doesn't exist
	if { ! [mdw_document_exists beamline_configuration] } {
		create_mdw_document beamline_configuration "Beamline Configuration" 360 390 \
			construct_beamline_configuration destroy_beamline_configuration
	}
		
	# show the document
	show_mdw_document beamline_configuration
}


proc construct_beamline_configuration { parent } {

	# global variables
	global gDevice
	global gColors
	global gFont
	global gWindows

	# create the scrolled listbox
	pack [ set gWindows(configListbox) [iwidgets::scrolledlistbox \
		$parent.listbox \
	  -hscrollmode none -selectioncommand "handle_save_select" \
		-textfont "courier 12 bold" -width 350 -height 370 ] ]\
		-expand true -fill both
	
	# set colors of the vertical scrollbar
	[$gWindows(configListbox) component vertsb] configure \
		-troughcolor $gColors(midhighlight) \
		-background $gColors(unhighlight) \
		-activebackground $gColors(unhighlight)

}

proc destroy_beamline_configuration { } {

}


proc handle_save_select { args } {
	
	# global variables
	global gWindows
	global gDevice
	
	# get index of selected line
	set index [$gWindows(configListbox) curselection]

	# get the selected line itself
	set line [$gWindows(configListbox) get $index ]

	# parse the selected line
	set motor [lindex $line 0]
	set value [lindex $line 1]
	set units [lindex $line 2]
	
	# set the motor control entries accordingly
	select_motor $motor
	set_units $units
	set gDevice(control,value) $value
}



proc beep_complete {} {
	beep
}

proc beep_error {} {
	beep
	beep
}

set gBeep 0

proc beep {} {

	# global variables
	global gBeep

	if { $gBeep == 0 } {
		after 0 do_beep
	}

	if { $gBeep < 2 } {
		incr gBeep
	}
}

proc do_beep {} {


	# global variables
	global gBeep

	bell
	incr gBeep -1


	if { $gBeep > 0 } {
		after 300 do_beep
	}	
}


class EventHook {

	# data members
	private variable commandList
	
	# public member functions
	
	# add -- adds a command to the list of handlers
	public method add { command } {
		lappend commandList $command 
	}
	
	# execute -- executes all commands currently in list
	public method execute {} {
		foreach command $commandList {
			eval $command
		}
	}
}


proc trim { string } {
        
        if { $string == "0" } { 
                return $string 
        } else {
                string trimleft $string 0
        }
}


proc print { outputString } {
	global gDebugComments
	if  { $gDebugComments } {
		catch [puts $outputString ] 
	}
}


proc create_operation_handle { } {
	global gClientId
	global gOperationCounter
	
	incr gOperationCounter
	
	return "$gClientId.$gOperationCounter"
}


proc wait_for_operation { operationHandle } {
	# global variables
	global gOperation

	#check to see if there are any updates stored in the update fifo
	if { $gOperation($operationHandle,updateInIndex) > $gOperation($operationHandle,updateOutIndex) } {
		set result $gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
		#clear out the update to avoid a memory leak
		unset gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
		incr gOperation($operationHandle,updateOutIndex)
		return "update $result"
	}

	# if the operation is still active, wait for device to become inactive, aborting or get an update
	if { $gOperation($operationHandle,status) == "active" } {
		vwait gOperation($operationHandle,status)
		#updates could have come in while we were waiting...
		#check to see if there are any updates stored in the update fifo
		if { $gOperation($operationHandle,updateInIndex) > $gOperation($operationHandle,updateOutIndex) } {
			set result $gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
			#clear out the update to avoid a memory leak
			unset gOperation($operationHandle,update,$gOperation($operationHandle,updateOutIndex))
			incr gOperation($operationHandle,updateOutIndex)
			return "update $result"
		}
	}
	
	if  { $gOperation($operationHandle,updateInIndex) !=  $gOperation($operationHandle,updateOutIndex) } {
		puts "WARNING: ***************  operation update fifo not depleted ! ************** "
	}

	set result $gOperation($operationHandle,result) 	
	set status $gOperation($operationHandle,status)
	
	unset gOperation($operationHandle,result)
	unset gOperation($operationHandle,status)
	unset gOperation($operationHandle,updateInIndex)
	unset gOperation($operationHandle,updateOutIndex)

	# return an error if any operation completed abnormally
	return "$status $result"
}





proc dumpBinary { binaryString {rowWidth 16} {valueFormat "%02X "} } {

	set characters [string length $binaryString]

	binary scan $binaryString "c$characters" asciiValues
	#puts $asciiValues
	
	set row ""
	set textViewer ""
	for { set cnt 0} { $cnt < $characters} { incr cnt } {
		set asciiValue [lindex $asciiValues $cnt]
		if { $asciiValue < 0 } {
			set asciiValue [expr ( $asciiValue + 0x100 ) % 0x100 ]
		}
		append row [format $valueFormat $asciiValue]
		set character [format "%c" $asciiValue]
		
		if {[string is wordchar $character]} {
			append textViewer $character
		} else {
			append textViewer "."
		}
		
		if { ($cnt+1)%$rowWidth == 0 } {
			puts "$row : $textViewer"
			set row ""
			set textViewer ""
		}
	}
	
	puts "$row : $textViewer"
}

proc toggle_masterhood {} {

	global gSessionId
	global gWorkingOffline
	
	if { $gSessionId == "" } {
		set gWorkingOffline 0
		getLogin
	}

	
	if { [dcss is_master] } {
		dcss sendMessage "gtos_become_slave"
	} else {
		dcss sendMessage "gtos_become_master force"
	}
}

#this function returns a list in the reverse order
proc reverseList { forwardList } {
	set reverseList ""

	foreach element $forwardList {
		set reverseList [linsert $reverseList 0 $element]
	}

	return $reverseList
}


#this function returns a list with all values outside of the limits removed
proc trimListWithLimits { fullList lowLimit highLimit } {
	set newList ""
	
	foreach element $fullList {
		if { ($element > $lowLimit) && ($element < $highLimit) } {
			lappend newList $element
		}
	}

	return $newList
}

proc save_full_configuration { {filename NULL} } {
	
	# global variables 
	global gDevice
	global gBeamline
	
	# make sure the file selection was not cancelled
	if { $filename == "NULL" } {
		set dateStr [exec date "+%m-%d-%y"]
		set filename "config_$gBeamline(beamlineId)_$dateStr.tcl"
	}	
		
	# try to open file 	
	if { [catch {set fileHandle [open $filename w ] } ] } {
		log_error "Error opening ${filename}.  Configuration not saved."
		return
	}
		
	# write header to file
	puts $fileHandle "# file       $filename"
	puts $fileHandle "# beamline   $gBeamline(beamlineId)"
	puts $fileHandle "# date       [time_stamp]"
	puts $fileHandle "# Next line is included to prevent careless accidents."
	puts $fileHandle {return -code error "ARE YOU TRYING TO LOSE ALL OF YOUR MOTOR POSITIONS!??"}
	puts $fileHandle "set thisBeamline $gBeamline(beamlineId)"
	puts $fileHandle {if {$gBeamline(beamlineId) != $thisBeamline } {return -code error "ARE YOU ON THE WRONG BEAM LINE!??"}}
	puts $fileHandle "#------------------------------------------------------------------------"

	set scaledRealParameters { scaledPosition upperLimit lowerLimit scaleFactor speed acceleration backlash }
	set boolRealParameters { lowerLimitOn  upperLimitOn lockOn  backlashOn reverseOn }
	
	set scaledPseudoParameters { scaledPosition upperLimit lowerLimit }
	set boolPseudoParameters { lowerLimitOn upperLimitOn lockOn }

	# write current configuration of all motors to canvas, sorted alphabetically
	foreach motor [lsort -ascii $gDevice(motor_list)] {
		
		#find out the motor type
		if { [device::$motor isa RealMotor ] } {
			set motorType "Real Motor"
		} else {
			set motorType "Pseudo Motor"
		}

		#get the default units
		set units [lindex [device::$motor cget -unitsList] 0]
		puts $fileHandle "set motor $motor ;# This is a $motorType. Units are in $units."
		
		if { $motorType == "Real Motor" } {
			set scaledParameters $scaledRealParameters
			set boolParameters $boolRealParameters
			
			#handle numerical characteristics
			foreach characteristic $scaledRealParameters {				

				#query the device for the value
				set value [device::$motor cget -$characteristic]

				switch $characteristic {
					acceleration {
						puts $fileHandle [format "set %-17s %17d ;# %-15s" $characteristic [expr int($value)] $motor]
					}
					speed {
						puts $fileHandle [format "set %-17s %17d ;# %-15s" $characteristic [expr int($value)] $motor]
					}
					backlash {
						puts $fileHandle [format "set %-17s %17d ;# %-15s" unscaledBacklash [expr int($value)] $motor]
					}
					default {
						puts $fileHandle [format "set %-17s %17.8f ;# %-15s" $characteristic $value $motor]
					}
				}
			}
			
			#handle boolean switches
			foreach characteristic $boolRealParameters {

				#query the device for the value
				set value [device::$motor cget -$characteristic]

				puts $fileHandle [format "set %-17s %17d ;# %-15s" $characteristic [expr int($value)] $motor]
			}
 
			puts $fileHandle { dcss sendMessage "gtos_configure_device $motor $scaledPosition $upperLimit $lowerLimit $scaleFactor $speed $acceleration $unscaledBacklash $lowerLimitOn $upperLimitOn $lockOn $backlashOn $reverseOn" }
		} else {
			set scaledParameters $scaledPseudoParameters
			set boolParameters $boolPseudoParameters

			#handle numerical characteristics
			foreach characteristic $scaledParameters {
				#query the device for the value
				set value [device::$motor cget -$characteristic]

				puts $fileHandle [format "set %-17s %17.8f ;# %-15s" $characteristic $value $motor]
			}
			
			
			#handle boolean switches
			foreach characteristic $boolParameters {
				#query the device for the value
				set value [device::$motor cget -$characteristic]

				puts $fileHandle [format "set %-17s %17d ;# %-15s" $characteristic [expr int($value)] $motor]
			}
		}
		puts $fileHandle ""
	}
	
close $fileHandle
}