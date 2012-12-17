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


EventHook becomeMasterHook
EventHook becomeSlaveHook
set addingRun 0
set requestedImage 0

set gClientId 0
set gDialogOpen 0


proc handle_stog_messages {args} {
	print "in<- [lindex $args 0]"
	if { [lindex $args 1] == {} } {
		if { [catch {eval [lindex $args 0]} badResult]} {
			log_error "'[lindex $args 0]' -> $badResult "
			#log_error "handle_stog_messages: $badResult:"
		}
	} else {
		eval [lindex $args 0] {[lindex $args 1]}
	}
}

proc stog_note { args } {
#	log_note $args
	if { [ catch { eval sNote::[join $args] } error] } {
		log_note $error
	}
}

#define server note handler
namespace eval sNote {}
namespace eval operationStart {}
namespace eval operationUpdate {}
#define namespace for handling replies from operations
namespace eval operationComplete {}

proc sNote::image_ready { filename } {
	::log_note "Loading $filename..."
	::lastImage load $filename
}

proc sNote::encoder_offline {} {

	::log_error "Mono encoder is offline!"
}


proc sNote::mono_corrected { oldTheta newTheta delta } {

	::log_warning "Mono_theta corrected from $oldTheta to $newTheta (delta = $delta)"
}

proc sNote::changing_detector_mode {} {

	set ::gWindows(runsStatusText) "Changing detector mode..."
}

proc sNote::exposing { filename } {
#	::lastImage load $filename
	set ::gWindows(runsStatusText) "Exposing $filename..."
	$::gWindows(runsStatus) configure -fg red
#	::log_note "Exposing $filename."
}


proc sNote::movedExistingFile { filename backupdirectory} {
	
	::log_warning "$filename moved to $backupdirectory"
}


proc sNote::detector_z { args } {
	
	::log_warning "detector_z $args"
}

proc sNote::failedToBackupExistingFile { filename args} {
	
	::log_error "$filename already exists and could not be backed up."
}


proc sNote::ion_chamber { dummy filtered actual } {
	::log_note ion_chamber $filtered $actual
}

proc sNote::Warning { args } {
	::log_warning $args
}


proc sNote::Error { args } {
	::log_error $args
}

proc stog_collect_stopped {} {

	# global variables
	global gDefineRun
	global gWindows
		
	print "Handling stog_collect_stopped."

	$gWindows(runsStatus) configure -fg black
	set gWindows(runsStatusText) "Idle"
}

proc sNote::no_beam { } {
	set ::gWindows(runsStatusText) "No Beam"
	$::gWindows(runsStatus) configure -fg red
}

proc sNote::unstable_beam { counts } {
	#set ::gWindows(runsStatusText) "Unstable Beam"
	#$::gWindows(runsStatus) configure -fg red
	#log_note "Unstable Beam. Counts $counts"
}


proc sNote::beam_normalized { counts } {
	global gDevice

	set ::gWindows(runsStatusText) "Beam Normalized"
	$::gWindows(runsStatus) configure -fg red
	log_note "Beam Normalized. Counts $counts"
}

proc stog_configure_runs { count currentRun isActive doseMode } {

	# global variables
	global gDefineRun
	global gMode
	global gWindows

	set oldCurrentRun $gDefineRun(currentRun)
	set gDefineRun(currentRun) $currentRun
	set gDefineRun(doseMode) $doseMode
	
	if { $oldCurrentRun != $currentRun } {
		update_active_run_tab
	}

	run_update_control_buttons
	set lastValue $gDefineRun(runCount)
	if { $count < 1 } {
		set count 0
	}
	
	if { $count < $gDefineRun(runCount) } {
		for { set run $gDefineRun(runCount) } { $run > $count } { incr run -1 } {
			run_delete $run
		}
	} else {
		for { set run $gDefineRun(runCount) } { $run < $count } { incr run } {
			run_add
		}	
	}
	
	
#	log_note $oldCurrentRun $currentRun	
#	$gWindows(runs,notebook) pageconfigure [expr $oldCurrentRun - 1] \
#		-foreground black -tabforeground black
#	if { $isActive } {
#		$gWindows(runs,notebook) pageconfigure [expr $currentRun - 1] \
#			-foreground red -tabforeground red
#	}

	#re-enable the star key if master.  (key was disabled during add_run function)
	if { [dcss is_master] } {
		$gWindows(runs,notebook) pageconfigure end -state enabled
	}
}


proc stog_configure_run { name runStatus nextFrame runLabel \
										fileroot directory startFrameLabel axisMotorName \
										startAngle endAngle delta wedgeSize exposureTime distance \
										numEnergy energy1 energy2 energy3 energy4 energy5 \
										modeIndex inverseOn } {
	# global variables
	global gDefineRun
	global gMode
	global gWindows

	# get run number
	set run [string range $name 3 end]

   set gDefineRun($run,label) $runLabel
	set gDefineRun($run,fileroot) $fileroot
	set gDefineRun($run,directory) $directory

	#set gDefineRun($run,axisLastChoice) $gDefineRun($run,axis)
	set gDefineRun($run,axis) $axisMotorName
	set gDefineRun($run,axisLastChoice) $gDefineRun($run,axis)
	set gDefineRun($run,startframe) [format "%03d" $startFrameLabel ]
	set gDefineRun($run,nextframe) [format "%d" $nextFrame ]

	set endFrame [ expr int(($endAngle - $startAngle) / $delta - 0.01 + $startFrameLabel ) ]
	set gDefineRun($run,endframe) [format "%03d" $endFrame ]

	set gDefineRun($run,delta) [format "%.2f" $delta]
	set gDefineRun($run,runStatus)  $runStatus
	set gDefineRun($run,inversebeam) $inverseOn

   run_configure_label $run $runLabel

	#don't set values until entries are instantiated
	if { [info command wedgesize($run)] != ""} {
		startAngleEntry($run) set_value [format "%.2f" $startAngle]

		startAngleEntry($run) set_reference_variable gDevice($axisMotorName,scaledShort)
		
		detectorMode($run) set_value [lindex $gDefineRun(modeChoices) $modeIndex]
		collectTimeEntry($run) set_value [format "%.1f" $exposureTime]
		distanceEntry($run) set_value [format "%.3f" $distance]
		wedgesize($run) set_value [format "%.1f" $wedgeSize]
		
		energyEntry($run,1) set_value [format "%.2f" $energy1]
		if { $run != 0} {
			for {set cnt 2} {$cnt <= 5} {incr cnt} {

				if { $cnt < [expr $numEnergy +1] } {
					energyEntry($run,$cnt) set_value [format "%.2f" [set energy$cnt]]
					energyEntry($run,$cnt) pack_this {-anchor w }
				}
				if {$cnt == [expr $numEnergy + 1] } {
					energyEntry($run,$cnt) set_value ""
					energyEntry($run,$cnt) pack_this {-anchor w }
				}
				if {$cnt > [expr $numEnergy + 1]} {
					energyEntry($run,$cnt) set_value ""
					energyEntry($run,$cnt) unpack_this
				}
			}
			
			update_energy_list $run
		}
		run_change_frame_num $run start 1
		run_change_frame_angle $run start 1
		save_run_values $run
		
		if { $run <= $gDefineRun(runCount) } {
			run_update_widget_states $run
		}
	}
	
	update_run_sequence $run
	updateRunColors $run
}



proc stog_update_run { name nextframe runStatus } {

	# global variables
	global gDefineRun
	global gMode
	global gWindows
		
	# get tab number
	set run [string range $name 3 end]
	
	set gDefineRun($run,nextframe) $nextframe

	set gDefineRun($run,runStatus) $runStatus #[lindex $gDefineRun(runStatusStrings) $runStatus]

	#run_change_frame_num $run next
	save_run_values $run

	if { $run <= $gDefineRun(runCount) } {
		run_update_widget_states $run
	}

	#for {set cnt 0} {$cnt < $run } {incr cnt} {
	#	$gWindows(runs,notebook) pageconfigure $cnt -foreground grey
	#}
	#	$gWindows(runs,notebook) pageconfigure $run -foreground blue

	#set highlightframe [expr $nextframe -2]
	#set tempentry [$gDefineRun(sequence) get $highlightframe]
	#$gDefineRun(sequence) delete $highlightframe
	#$gDefineRun(sequence) insert $highlightframe "*$tempentry"
	#$gDefineRun(sequence) see $highlightframe
}


proc stog_configure_operation { args } {}

proc stog_configure_hardware_host { hardwareName computer status args } {
	if { $status != "online" } {
		log_error "Hardware server '$hardwareName' is $status."
	} else {
		log_note "Hardware server '$hardwareName' is $status."
	}
}

proc stog_configure_detector { args} {}

#This function is called during initialization of the scripting engine.
#The encoders are initialized here.  The controller position is what the actual motion controller
#thinks the position is.  The databasePosition is what was stored in the file on the computer 
#controlling the motion controller.
proc stog_configure_encoder { encoder hardwarehost databasePosition controllerPosition } {
	global gDevice

	set gDevice($encoder,status) inactive
	set gDevice($encoder,position) $controllerPosition
	set gDevice($encoder,controllerPosition) $controllerPosition
	set gDevice($encoder,databasePosition) $databasePosition
	
	if { $databasePosition != $controllerPosition} {
		log_warning "Encoder '$encoder' controller's internal position ($controllerPosition) differs from stored position ($databasePosition)"
	}
}

proc stog_configure_real_motor { motor hardwareHost hardwareName \
 	position upperLimit lowerLimit scaleFactor speed acceleration backlash \
 	lowerLimitOn upperLimitOn motorLockOn backlashOn reverseOn status } {

	# global variables
	global gDevice

	setScaleFactorValue $motor $scaleFactor
	setScaledValue $motor $position
	setUpperLimitFromScaledValue $motor $upperLimit
	setLowerLimitFromScaledValue $motor $lowerLimit
	setSpeedValue $motor $speed
	setAccelerationValue $motor $acceleration
	setBacklashFromUnscaledValue $motor $backlash
	setLowerLimitEnableValue $motor $lowerLimitOn
	setUpperLimitEnableValue $motor $upperLimitOn
	setLockEnableValue $motor $motorLockOn
	setBacklashEnableValue $motor $backlashOn
	setReverseEnableValue $motor $reverseOn

	device::$motor configure \
		 -hardwareHost $hardwareHost \
		 -hardwareName $hardwareName \
		 -scaledPosition $position \
		 -upperLimit $upperLimit \
		 -lowerLimit $lowerLimit \
		 -scaleFactor $scaleFactor \
		 -speed $speed \
		 -acceleration $acceleration \
		 -backlash $backlash \
		 -backlashOn $backlashOn \
		 -lowerLimitOn $lowerLimitOn \
		 -upperLimitOn $upperLimitOn \
		 -lockOn $motorLockOn \
		 -reverseOn $reverseOn

	if { $status == 0 && $gDevice($motor,status) != "inactive" } {
		handle_move_complete $motor
	}

	if { $status != 0 && $gDevice($motor,status) == "inactive" } {
		handle_move_start $motor
	}
}


proc stog_configure_pseudo_motor { motor hardwareHost hardwareName position \
	upperLimit lowerLimit lowerLimitOn upperLimitOn motorLockOn status } {

	# global variables
	global gDevice
	
	# set the pseudomotor parameters
	setScaledValue $motor $position
	setUpperLimitFromScaledValue $motor $upperLimit
	setLowerLimitFromScaledValue $motor $lowerLimit
	setLowerLimitEnableValue $motor $lowerLimitOn
	setUpperLimitEnableValue $motor $upperLimitOn
	setLockEnableValue $motor $motorLockOn
	

	device::$motor configure \
		 -hardwareHost $hardwareHost \
		 -hardwareName $hardwareName \
		 -scaledPosition $position \
		 -upperLimit $upperLimit \
		 -lowerLimit $lowerLimit \
		 -lowerLimitOn $lowerLimitOn \
		 -upperLimitOn $upperLimitOn \
		 -lockOn $motorLockOn

	if { $status == 0 && $gDevice($motor,status) != "inactive" } {
		handle_move_complete $motor
	}

	if { $status != 0 && $gDevice($motor,status) == "inactive" } {
		handle_move_start $motor
	}
}


proc stog_set_motor_dependency { motor args } {}


proc stog_configure_ion_chamber { 
	ion_chamber host counter channel timer timer_type } {

	# global variables
	global gDevice
	
	# set ion chamber parameters
	set gDevice($ion_chamber,counter)		$counter
	set gDevice($ion_chamber,timer)			$timer
	set gDevice($ion_chamber,channel)		$channel
	set gDevice($ion_chamber,status) 		inactive
	set gDevice($ion_chamber,counts) 		0
	set gDevice($ion_chamber,cps) 			0
	set gDevice($ion_chamber,type)			ion_chamber
	set gDevice($ion_chamber,timer_type)	$timer_type

	# add ion chamber to list of detectors associated with timer
	add_to_set gDevice(ion_chamber_list) $ion_chamber
}


proc stog_simulating_device { device } {

 log_error "Simulating device $device."
}

proc stog_update_motor_position { motor position status } {

	# global variables
	global gDevice

	# update the motor object
	device::$motor configure \
		 -scaledPosition $position \
		 -timedOut 0

	# note that motor is moving if position is changing
	if { $gDevice($motor,status) == "inactive" } {
		handle_move_start $motor 1
	}

	# reset timeout
	set gDevice($motor,timedOut) 0

	# update the motor position
	setScaledValue $motor $position
	
	# check if motor hit clockwise hardware limit
	if { $status == "cw_hw_limit" } {
		log_error "Motor $motor hit clockwise hardware limit."
		return
	}
	
	# check if motor hit counter-clockwise hardware limit
	if { $status == "ccw_hw_limit" } {
		log_error "Motor $motor hit counterclockwise hardware limit."
		return
	}
}


proc stog_motor_move_completed { motor position status } {

	# global variables
	global gDevice
	global gConfig
	global gScan
	
	# update the motor object
	device::$motor configure -scaledPosition $position -lastResult $status

	# update the motor position
	setScaledValue $motor $position
	
	# update gui
	handle_move_complete $motor

	switch $status {
		normal {
			log_note "Move of motor $motor completed normally at $position."
		}

		motor_active {
			log_error "Motor $motor already moving."
		}
	
		cw_hw_limit {
			log_error "Motor $motor hit clockwise hardware limit."
		}
	
		ccw_hw_limit {
			log_error "Motor $motor hit counterclockwise hardware limit."
		}

		both_hw_limits {
			log_error "Motor $motor hit both hardware limits."
			log_error "Check hardware reset button (green button)."
		}

		sw_limit {
			log_error "Motor move would exceed software limit."
		}
	
		no_hw_host {
			log_error "Hardware host for motor $motor not connected."
		}

		hutch_open_remote {
			log_error "Hutch door must be closed to move $motor from remote console."
		}

		hutch_open_local {
			log_error "Hutch door must be closed to move $motor from local console."
		}

		in_hutch_restricted {
			log_error "User may not be in the hutch to move $motor."
		}

		in_hutch_and_door_closed {
			log_error "Hutch door must be open to use console in hutch."
		}

		no_permissions {
			log_error "User has no permissions to use $motor."
		}

		hutch_door_closed {
			log_error "User must be in the hutch to use $motor."
		}

		default {
			log_error "Motor $motor reported: $status."
		}
	}
}

proc stog_no_master {} {

	# global variables
	global gWindows
	
	if { [dcss is_master] == 0 } { 
		$gWindows(networkMenu) entryconfigure 0 -state normal
		$gWindows(networkMenu) entryconfigure 1 -state normal		
		$gWindows(networkMenu) entryconfigure 2 -state disabled		
	}
	
}


proc stog_other_master {} {

	log_error "Another client is currently the DCS master."

#	iwidgets::messagedialog .masterDialog -title "Network Status" \
#		-modality application -text "Become master by force?"
#	after 2000 { catch {destroy .masterDialog} }
#	catch {if { [.masterDialog activate] } {
#		dcss sendMessage "gtos_become_master force"		
#	}}
#	catch {destroy .masterDialog }
}

proc stog_set_motor_children { args } {}

proc stog_motor_move_started { motor position } {

	# global variables
	global gDevice
	global gScan
	
	# update gui
	handle_move_start $motor
	
	# log event if not during a scan
	#if { $gScan(status) == "inactive" } {	
	log_note "Move of motor $motor to $position " "$gDevice($motor,scaledUnits) started."
	#}
}


proc stog_motor_correct_started { motor } {

	# global variables
	global gDevice
		
	# update the motor object
	device::$motor configure -status "moving"

	# update status of motor
	set gDevice($motor,status) moving
	
	updateMotorControlButtons
	
	log_note "Abort correction for motor $motor started."
}


proc stog_limit_hit { motor direction } {

	# global variables
	global gDevice
	global gScan

	# report the error
	log_error "Motor $motor has hit $direction hardware limit."

}


proc stog_device_active { device operation } {

	# global variables
	global gDevice

	# report the error
	log_error "Device $device is active.  $operation operation failed."
}


proc stog_no_hardware_host { device } {

	# global variables
	global gDevice
	global gScan

	# report the error
	log_error "Hardware host for device $device not connected."
}


proc stog_unknown_device { device } {
	# report the error

	log_error "Server has no knowledge of device '$device'."

}


proc update_motor_config_to_server { motor } {
	
	# global variables
	global gDevice
	
	if { $gDevice($motor,type) == "real_motor" } {
		set backlash [expr round($gDevice($motor,scaledBacklash) * \
			$gDevice($motor,scaleFactor) ) ]
	
		dcss sendMessage "gtos_configure_device $motor \
			$gDevice($motor,scaled)\
			$gDevice($motor,scaledUpperLimit)\
			$gDevice($motor,scaledLowerLimit)\
			$gDevice($motor,scaleFactor)\
			$gDevice($motor,speed)\

			$gDevice($motor,acceleration)\
			$backlash\
			$gDevice($motor,lowerLimitOn)\
			$gDevice($motor,upperLimitOn)\
			$gDevice($motor,lockOn)\
			$gDevice($motor,backlashOn)\
			$gDevice($motor,reverseOn) "
	} else {
		dcss sendMessage "gtos_configure_device $motor \
			$gDevice($motor,scaled) 			\
			$gDevice($motor,scaledUpperLimit)\
			$gDevice($motor,scaledLowerLimit)\
			$gDevice($motor,lowerLimitOn)\
			$gDevice($motor,upperLimitOn)\
			$gDevice($motor,lockOn)	"
	}
}



proc stog_unrecognized_command {} {
	
	log_error "Command unrecognized by server."
	}



proc stog_become_master {} {

	# global variables
	global gWindows	

	clientState configure -master 1

	dcss setMaster 1

	# execute appropriate event handlers
	updateMotorControlButtons
	run_handle_become_master

	$gWindows(networkMenu) entryconfigure 0 -state disabled
	$gWindows(networkMenu) entryconfigure 1 -state disabled	
	$gWindows(networkMenu) entryconfigure 2 -state normal
	set gWindows(networkStatusText) "Active"
	$gWindows(networkStatus) configure -fg red


	
	log_note "This client may now issue commands."
}


proc stog_become_slave {} {

	# global variables
	global gWindows
	
	clientState configure -master 0

	dcss setMaster 0

	updateMotorControlButtons
	run_handle_become_slave	

	$gWindows(networkMenu) entryconfigure 0 -state normal
	$gWindows(networkMenu) entryconfigure 1 -state normal		
	$gWindows(networkMenu) entryconfigure 2 -state disabled		

	set gWindows(networkStatusText) "Passive"
	$gWindows(networkStatus) configure -fg black

	log_warning "This client is passively viewing the beamline."
}

# Callback for stoc_send_client_type message from dcss
# The message is received when the client connects to the 
# dcss the first time. The client replies with user name 
# and session id for authentication.
proc stoc_send_client_type {} {
	global env
	global gSessionId
	global gAuthHost
	global gAuthPort
	global gAuthTimeout
	global gAuthProtocol
	
	puts "In stoc_send_client_type gSessionId = $gSessionId" 
	
	if { $gAuthProtocol == 1} {
		dcss send_to_server "gtos_client_is_gui $env(USER) $env(HOST) $env(DISPLAY)" 200
	} else {
		dcss send_to_server "gtos_client_is_gui $env(USER) $gSessionId $env(HOST) $env(DISPLAY)" 200
	}
}


#this message is sent by DCSS if the session of this client is valid or has become
# invalid or the user no longer has permission to access the dcss.
# Set gSessionId to an empty string so that we blu-ice tries to connect
# to dcss again we can then pop up a log window for the user
# to enter a password again and then we can get a new session id.
proc stog_authentication_failed { clientId args } {
	global gAuthProtocol
	global gSessionId
	
	if { $gSessionId != "" } {
		set gSessionId ""
		set gWorkingOffline 0
	}
	puts "protocol #2"
	set gAuthProtocol 2
	getLogin
}


proc stog_respond_to_challenge { _binaryMessage } {
	global gAuthProtocol
	global env

	if { $gAuthProtocol == 2} {
		set gAuthProtocol 1
		
		puts "-----------------------------------------------------------"
		puts "Recieved an authenticaion protocol 1 message."
		puts "Attempting to load the authentication protocol 1 libraries."
		puts "-----------------------------------------------------------"
		
		loadAuthenticationProtocol1Library
	}
	
	set response [generate_auth_response $env(USER) $_binaryMessage]
	dcss send_to_server $response 200
	return
}

proc getLogin {} {
	global gAuthProtocol
	global gDialogOpen
	global gSessionId
	global gAuthHost
	global gAuthPort
	global gAuthTimeout
	global gWorkingOffline
	
	if { $gWorkingOffline == 1 } {
		return
	}

	# session id is not supplied as command line argument
	# We need to pop up a window and ask for it
	if { [string length $gSessionId] == 0 } {
	
		if { $gDialogOpen == 0 } {

			set gDialogOpen 1


			if { [catch {

				# Create a login dialog that will send user name and password to 
				# the authentication server to get a valid session id. 
				# The command arguments are host and port of the auth server
				# and the timeout period of the connection in msec.
				set gSessionId [ Dialog_Login $gAuthHost $gAuthPort $gAuthTimeout ]
				puts "gSessionId = $gSessionId"
				

			} err] } {

				puts $err
				puts "Login failed"
				set gWorkingOffline 1

			}
			
			set gDialogOpen 0
			return
			
		}
		

	}
}

proc gaussian { x {y 0} } {

	set center 0
	set sigma 0.5

	set dist [distance 0 0 $x $y]
	if { $dist > 10 } {
		return 0 
	} else {
		return [expr 0.3989/$sigma * exp(-0.5 * pow(($dist-$center)/$sigma,2)) ]
	}
}

proc stog_report_ion_chambers { time args } {

	# global variables
	global gDevice
	global gScan

	# get number of arguments
	set argc [llength $args]
	
	# initialize argument index
	set index 0
	
	while { $index < $argc } {

		set ion_chamber [lindex $args $index]
		incr index
		set counts [lindex $args $index]
		incr index

		if { [string index $ion_chamber 0] != "a" } {
			# fake the counts if scanning
			if { $gScan(fake) && $gScan(status) == "scanning" } {
				if { $ion_chamber == "i0" } {
					set counts [expr $gScan(scan_time) * 100000]
				} else {
					switch $gScan(type) {
						energy {
							set counts [expr int($index) * $gDevice(energy,scaled)/1200.0]
						}
						counts_vs_time { 
							set counts [expr int(sqrt($index * $gScan(scan_num)) * \
															 $gScan(scan_time) * 10000 )]
						}
						counts_vs_1_motor { 
							set counts [expr int($index * $gScan(scan_num) 	\
															 * [gaussian $gScan(motor1,position)] 				\
															 * $gScan(scan_time) * 10000)]
						}
						counts_vs_2_motors { 
							set counts [expr int($index * $gScan(scan_num) 	\
															 * [gaussian $gScan(motor1,position) $gScan(motor2,position)]\
															 * $gScan(scan_time) * 10000)]
						}
					}
				}
			}
		} else {
			set counts [expr abs($counts * 1000)]
		}
		
		set gDevice($ion_chamber,counts) $counts
		
		# added by TM
		log_note "Ion chamber $ion_chamber read $counts counts in $time seconds."

		catch {set gDevice($ion_chamber,cps)	[expr int($counts / $time) ]}
		set gDevice($ion_chamber,status) inactive
	
	
#		if { $gScan(status) == "inactive" } {
#			log_note "Ion chamber $ion_chamber reported $counts counts."
#		}
	}
}	


proc stog_configure_shutter { shutter hardwarehost state args} {

	stog_report_shutter_state $shutter $state
}


proc stog_report_shutter_state { shutter state } {

	# global variables
	global gDevice

	#this gui doesn't care about this filter.
	if { ![info exists gDevice($shutter,type)] } {
		log_warning "Unused filter '$shutter'."
		return
	}

	# update the shutter object state
	device::$shutter configure \
		 -state $state

	# set the state of the shutter
	set gDevice($shutter,state) $state
	# report the event

	if { $shutter == "shutter" } {
		log_note "Shutter $state."
		#update the beam on the hutch tab
		#update_user_beam
	} else {
		log_note "Filter $shutter $state."
	}

	# update canvases displaying filters
	update_filter_canvas $shutter

	# set status to inactive
	set gDevice($shutter,status) "inactive"
	
	# update menu
	update_shutter_menu
}	



proc stog_test_socket_connection { junk } {
	
		log_note "got Test Message."
  
	}

proc stog_failed_to_store_image { filename } {

log_error "Could not create $filename"

}

proc stog_update_client_list { num } {
	global clientList

	#log_note "getting new client list"
	$clientList clear

	set columnHeadings "[pad_string {} 10] [pad_string {User Name} 25] [pad_string {Staff} 8] [pad_string {Roaming} 12] [pad_string {Location} 10]"
	$clientList insert 1 $columnHeadings

}

proc stog_update_client { clientId accountName name remoteStatus jobtitle staff remoteAccess host display isMaster} {
	global clientList
	global gClientId
	
	set booleanText "No Yes"
	
	set masterList {"" "Active->"}
	
	#log_note "got client info"
	if { [string index $display 0] == ":" } {
		set display $host$display
	}

	if { $name != "DCSS" } {
		$clientList insert 1 "[pad_string [lindex $masterList $isMaster] 10] [pad_string $name 25] [pad_string [lindex $booleanText $staff] 8] [pad_string [lindex $booleanText $remoteAccess] 12] [pad_string $remoteStatus 10]  [pad_string $display 20]" 
	}
}

proc pad_string { message requestedlength } {

	set blank_string "                                     "
	set length [string length $message]

	if { $length < $requestedlength } {
		append message [string range $blank_string 0 [expr $requestedlength - $length -1] ]
	}


	return $message

}


proc stog_set_permission_level { staff remoteAccess location } {
	global gBeamline
	global gUserData
	global gWindows

	#lookup the tab indices by name
	set hutchTabIndex [$gWindows(notebook) index "Hutch"]
	set scanTabIndex [$gWindows(notebook) index "Scan"]
	set setupTabIndex [$gWindows(notebook) index "Setup"]

 	if { ! $staff } {
 		#kick you out of tabs that you don't have permission for
 		if { [ $gWindows(notebook) view ] == $setupTabIndex  || [ $gWindows(notebook) view ] == $scanTabIndex } {
 			$gWindows(notebook) select $hutchTabIndex
 		}

 		$gWindows(notebook) pageconfigure $setupTabIndex -state disabled
		
 		#disable the scan window if we do not have a moveable energy
 		if { $gBeamline(moveableEnergy) != 1 } {
 			$gWindows(notebook) pageconfigure $scanTabIndex -state disabled
 		}
 	}
 
 	if { $staff } {
 		$gWindows(notebook) pageconfigure $setupTabIndex -state normal
 		$gWindows(notebook) pageconfigure $scanTabIndex -state normal
 	}
}

proc stog_insufficient_privilege { message } {
	log_error "Insufficient privilege executing command: $message"
}

proc stog_log { level source args } {
	switch $level {
		note {log_note $source reports \"$args\"}
		warning {log_warning $source reports \"$args\"}
		error {log_error $source reports \"$args\"}
		default {log_error $source reports \"$args\"}
	}
}

#proc stog_operation_completed { operation status args } {
#	
#	# check if operation completed normally
#	if { $status == "normal" } {
#		log_note "Operation $operation completed normally."
#		#beep_complete
#		return
#	}  elseif { $status == "aborted" } {
#		log_error "Operation $operation was aborted."
#		return
#	} elseif { $status == "active" } {
#		log_error "Operation $operation already active"
#	}
#
#}

#this message is sent by DCSS after client is completely initialized
proc stog_login_complete { clientId args } {
	global gClientId
	#force the gui to be a passive client
	stog_become_slave 
	set gClientId $clientId
	#ask the server for the last image
	requestLastImage

        #gw
        #call the registered message handlers
        set x login_complete
	foreach eventHandler [get_operation_eventHandlerList $x] {
		$eventHandler $x $x "login_complete" "login_complete" $args
	}
}


# =======================================================================
# =======================================================================
#gw
#register a handler for stog_operation events
proc register_operation_eventHandler { operation handlerProc} {
	print "register_operation_eventHandler $operation $handlerProc"
        set eventHandlerList [get_operation_eventHandlerList $operation]
        if { [lsearch $eventHandlerList $handlerProc]>=0 } {
            # the handlerProc is already regitered
            print "WARNING register_operation_eventHandler - already registered $operation $handlerProc"
            return
        }
        set eventHandlerList [linsert $eventHandlerList end $handlerProc]
        global gOperation
	set gOperation($operation,eventHandler) $eventHandlerList
	print "register_operation_eventHandler OK"
}

# =======================================================================
#gw
#get a list of the registered enventHandlers
proc get_operation_eventHandlerList { operation} {
    set eventHandlerList {}
    global gOperation
    set hasEventHandler [info exists gOperation($operation,eventHandler)]
    if { $hasEventHandler } {
	set eventHandlerList $gOperation($operation,eventHandler)
    }
    return $eventHandlerList
}

# =======================================================================

proc stog_start_operation { operation operationHandle args } { 
	
	# update the operation status object
	catch { ${operation}Status configure -status active }

	#gw
        set eventHandlerList [get_operation_eventHandlerList $operation]
	foreach eventHandler $eventHandlerList  {
		#$eventHandler $operation $operationHandle "start" "active" $args
		eval {$eventHandler $operation $operationHandle start active} [join $args]
	}
        if { [llength $eventHandlerList]>0 } {
            return
        }

	#	log_note $args
	if { [ catch { eval operationStart::$operation $operationHandle [join $args] } error] } {
		log_note $error
	}
}


proc stog_operation_completed { operation operationHandle status args } {
	global gOperation
	
	# update the operation status object
	catch { ${operation}Status configure -status inactive }

	#gw
        set eventHandlerList [get_operation_eventHandlerList $operation]
	foreach eventHandler $eventHandlerList  {
		eval {$eventHandler $operation $operationHandle completed $status} $args
	}

	switch $status {
		hutch_open_remote {
			log_error "Hutch door must be closed to start '$operation' from remote console."
		}

		hutch_open_local {
			log_error "Hutch door must be closed to start '$operation' from local console."
		}

		in_hutch_restricted {
			log_error "User may not be in the hutch to start '$operation'"
		}

		in_hutch_and_door_closed {
			log_error "Hutch door must be open to use console in hutch."
		}

		hutch_door_closed {
			log_error "User must be in the hutch to start '$operation'."
		}

		no_permissions {
			log_error "User has no permissions to start '$operation'."
		}
	}

	#if the operationHandle is in the global operation table, store the result
	if { [info exists gOperation($operationHandle,status) ] } {
		set gOperation($operationHandle,result) $args
		set gOperation($operationHandle,status) $status
	} elseif { [llength $eventHandlerList]>0 } {
            return
        } else {
		#	log_note $args
		if { [ catch { eval operationComplete::$operation $status [join $args] } error] } {
			log_note $error
		}
	}
}


proc stog_operation_update { operation operationHandle args } {
	global gOperation

	#gw
        set eventHandlerList [get_operation_eventHandlerList $operation]
	foreach eventHandler $eventHandlerList  {
		eval {$eventHandler $operation $operationHandle update active} [join $args]
	}

	#if the operationHandle is in the global operation table, store the result
	if { [info exists gOperation($operationHandle,status) ] } {
		#store the update in the fifo
		set gOperation($operationHandle,update,$gOperation($operationHandle,updateInIndex)) [list $args]
		incr gOperation($operationHandle,updateInIndex)
		#trigger the vwait in wait_for_operation
		set gOperationHandle($operationHandle,status) "active"  
	}
        if { [llength $eventHandlerList]>0 } {
            return
        }

	#	log_note $args
	if { [ catch { eval operationUpdate::$operation $operationHandle [join $args] } error] } {
		log_note $error
	}

}

proc stog_configure_string {args} {
}

proc stog_set_string_completed {args} {
}


proc operationStart::requestCollectedImage {operationHandle args } {}
proc operationComplete::requestCollectedImage { status args } {
	global requestedImage

	if { $requestedImage } {
		if { $status != "error" } {
			#::log_note "last image collected: $args..."
			#::lastImage load [lindex $args 0]
			set requestedImage 0
		}
	}
}

proc operationStart::optimize {operationHandle motor args} {
	log_note "Started optimization of $motor."
	set ::gWindows(runsStatusText) "Optimizing beam..."
	$::gWindows(runsStatus) configure -fg black
}

proc operationComplete::optimize {status args} {
	if { $status == "normal" } {
		log_note "Optimization complete."
		set ::gWindows(runsStatusText) "Beam optimized."
		$::gWindows(runsStatus) configure -fg black
	} else {
		log_error "Error optimizing motor."
		set ::gWindows(runsStatusText) "Error optimizing beam."
		$::gWindows(runsStatus) configure -fg red
	}
}


proc operationStart::expose {operationHandle args } {
	#set ::gWindows(runsStatusText) "Exposing"
	#$::gWindows(runsStatus) configure -fg red	
}


proc operationComplete::expose { status args } {
	if { $status != "normal"} {
		::log_note "Exposure completed abnormally: $args"
	}
}

proc operationStart::detector_transfer_image {operationHandle args} {	
	set ::gWindows(runsStatusText) "Reading out detector..."
	$::gWindows(runsStatus) configure -fg black
}
proc operationComplete::detector_transfer_image { args } {}

proc operationStart::normalize {status args } {}
proc operationComplete::normalize { status args } {
	if { $status == "error"} {
		::log_error "Operation normalize returned error: $args"
	}
}


proc operationStart::requestExposureTime { args } {}
proc operationComplete::requestExposureTime { status args } {
	if { $status == "error" } {
		::log_note "Operation requestExposureTime returned error: $args"
	}
}

proc operationStart::getLoopTip { args } {}
proc operationComplete::getLoopTip { status args } {
	if { $status == "error" } {
		::log_note "Operation getLoopTip returned error: $args"
	}
}

proc operationStart::addImageToList { args } {}
proc operationComplete::addImageToList { status args } {
	if { $status == "error" } {
		::log_note "Operation addImageToList returned error: $args"
	}
}


proc operationStart::moveSample { args } {}
proc operationComplete::moveSample { status args } {}


proc operationStart::findBoundingBox { args } {}
proc operationComplete::findBoundingBox { status args } {
	if { $status == "error" } {
		::log_note "Operation findBoundingBox returned error: $args"
	}
}

proc operationStart::centerLoop { args } {} 
proc operationComplete::centerLoop { status args } {
	if { $status != "normal" } {
		::log_error "Operation centerLoop returned error: $status"
	}
}

proc operationStart::detector_collect_image {operationHandle args} {}

proc operationUpdate::detector_collect_image {operationHandle args } {
	set updateMessage [lindex $args 0]
	
	#::log_note "$updateMessage $args"

	if { $updateMessage == "start_oscillation" } {
		set shutterName [lindex $args 1]
		set oscillationTime [lindex $args 2]
		set filename [lindex $args 3]

		set ::gWindows(runsStatusText) "Exposing $filename..."
		$::gWindows(runsStatus) configure -fg red
	} elseif { $updateMessage == "scanning_plate" } {
		set percentComplete [lindex $args 1]
		$::gWindows(runsStatus) configure -fg black
		set ::gWindows(runsStatusText) "Scanning Plate %$percentComplete..."
	} elseif { $updateMessage == "erasing_plate" } {
		set percentComplete [lindex $args 1]
		#	::log_note "Erasing plate $percent_complete..."
		$::gWindows(runsStatus) configure -fg black
		set ::gWindows(runsStatusText) "Erasing Plate %$percentComplete..."
	}
}


proc operationComplete::detector_collect_image {status args} {
	if { $status != "normal" } {
		::log_error "Data collection returned error: $status $args"
	} else {
	}
}


proc operationStart::collectRuns {operationHandle runNumber args} {
	# global variables
	global ::gDefineRun
	global ::gWindows

	set ::gWindows(runsStatusText) "Starting data collection..."
	$::gWindows(runsStatus) configure -fg black	
	::log_note "Started data collection on run $runNumber"

	$::gWindows(runs,doseModeButton) configure -state disabled
}

proc operationComplete::collectRuns {status args} {
	global ::gWindows

	::log_note "Data collection stopped."
	set ::gWindows(runsStatusText) "Data collection stopped."
	$::gWindows(runsStatus) configure -fg black	
	
	if { [dcss is_master] } {
		$::gWindows(runs,doseModeButton) configure -state normal
	}
}

proc operationStart::collectRun {args} {}

proc operationComplete::collectRun {status args} {
	if { $status == "error" } {
		::log_note "Data collection interrupted: $status $args"
	} else {
	}
}


proc operationStart::collectFrame { args } {}
proc operationUpdate::collectFrame { args } {}
proc operationComplete::collectFrame { status args } {
	if { $status != "normal" } {
		::log_error "Operation collectFrame returned error: $status"
	}
}



proc operationStart::detector_oscillation_ready {args} {}

proc operationComplete::detector_oscillation_ready {status args} {
	if { $status == "error" } {
		::log_note "Data collection returned error while moving to next frame: $status $args"
	} else {
	}
}


proc operationStart::detector_reset_run {args} {}
proc operationComplete::detector_reset_run {args} {}

proc operationStart::pauseDataCollection {args} {}
proc operationComplete::pauseDataCollection {args} {}



proc operationStart::detector_stop {operationHandle args} {}

proc operationComplete::detector_stop {status args } {
	# global variables
	global ::gDefineRun
	global ::gWindows

	if { $status != "normal" } {
		set ::gWindows(runsStatusText) "Detector Error"
		$::gWindows(runsStatus) configure -fg red
		::log_note "Detector stop error $status: $args"
	} else {
		set ::gWindows(runsStatusText) "Detector Ready"
		$::gWindows(runsStatus) configure -fg black	
		#::log_note "Data collection stopped."
	}
}


proc stog_get_encoder_completed { encoder position status } {
	global gDevice

	if { $status != "normal" } {
		log_error "Error reading $encoder: $status"
		set gDevice($encoder,status) inactive
		return
	}

	set gDevice($encoder,position) $position
	set gDevice($encoder,status) inactive
}


proc stog_set_encoder_completed { encoder position status } {
	global gDevice

	if { $status != "normal" } {
		log_error "Error reading $encoder: $status"
		set gDevice($encoder,status) inactive
		return
	}
	
	set gDevice($encoder,position) $position
	set gDevice($encoder,status) inactive
}


proc operationStart::acquireSpectrum { args } {}
proc operationUpdate::acquireSpectrum { args } {}
proc operationComplete::acquireSpectrum { status args } {
	if { $status != "normal" } {
		::log_error "Operation acqquireSpectrum returned error: $status"
	} else {
		set deadTimePercent [expr [lindex $args 0] * 100]
		::log_note "Scan dead time: $deadTimePercent %"
	}
}


proc operationStart::excitationScan { args } {}
proc operationUpdate::excitationScan { args } {}
proc operationComplete::excitationScan { status args } {
	if { $status != "normal" } {
		::log_error "Operation excitationScan returned error: $status"
	}
}


proc operationStart::prepareForScan { args } {}
proc operationUpdate::prepareForScan { args } {}
proc operationComplete::prepareForScan { status args } {
	if { $status != "normal" } {
		::log_error "Operation prepareForScan returned error: $status"
	}
}

proc operationStart::recoverFromScan { args } {}
proc operationUpdate::recoverFromScan { args } {}
proc operationComplete::recoverFromScan { status args } {
	if { $status != "normal" } {
		::log_error "Operation recoverFromScan returned error: $status"
	}
}

proc operationStart::readAnalog { args } {}
proc operationUpdate::readAnalog { args } {}
proc operationComplete::readAnalog { status args } {
	if { $status != "normal" } {
		::log_error "Operation readAnalog returned error: $status"
	} else {
	}
}

proc operationStart::getPV { args } {}
proc operationUpdate::getPV { args } {}
proc operationComplete::getPV { status args } {
	if { $status != "normal" } {
		::log_error "Operation getPV returned error: $status $args"
	}
}
 
proc operationStart::waitPV { args } {}
proc operationUpdate::waitPV { args } {}
proc operationComplete::waitPV { status args } {
	if { $status != "normal" } {
		::log_error "Operation waitPV returned error: $status $args"
	}
}


proc operationStart::ISampleMountingDevice { args } {}
proc operationUpdate::ISampleMountingDevice { args } {}
proc operationComplete::ISampleMountingDevice { status args } {
	if { $status != "normal" } {
		::log_error "Operation ISampleMountingDevice returned error: $status $args"
	} else {
		::log_note "Operation ISampleMountingDevice returned $status $args"
	}
}

proc operationStart::robot_calibrate { args } {}
proc operationUpdate::robot_calibrate { args } {
	::log_note "Operation robot_calibrate update: $status $args"
}
proc operationComplete::robot_calibrate { status args } {
	if { $status != "normal" } {
		::log_error "Operation robot_calibrate returned error: $status $args"
	}
}

proc operationStart::robot_config { args } {}
proc operationUpdate::robot_config { args } {}
proc operationComplete::robot_config { status args } {
	if { $status != "normal" } {
		::log_error "Operation robot_config  returned error: $status $args"
	} else {
        ::log_note "Operation robot_config  returned: $status $args"
    }
}


proc operationStart::get_robotstate { args } {}
proc operationUpdate::get_robotstate { args } {}
proc operationComplete::get_robotstate { status args } {
	if { $status != "normal" } {
		::log_error "Operation get_robotstate returned error: $status $args"
	} else {
        ::log_note "Operation get_robotstate returned: $status $args"
    }
}


proc operationStart::prepare_mount_crystal { args } {}
proc operationUpdate::prepare_mount_crystal { args } {}
proc operationComplete::prepare_mount_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation prepare_mount_crystal returned error: $status $args"
	} else {
        ::log_note "Operation prepare_mount_crystal returned: $status $args"
    }
}

proc operationStart::mount_crystal { args } {}
proc operationUpdate::mount_crystal { args } {}
proc operationComplete::mount_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation mount_crystal returned error: $status $args"
	} else {
        ::log_note "Operation mount_crystal returned: $status $args"
    }
}

proc operationStart::prepare_dismount_crystal { args } {}
proc operationUpdate::prepare_dismount_crystal { args } {}
proc operationComplete::prepare_dismount_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation prepare_dismount_crystal returned error: $status $args"
	} else {
        ::log_note "Operation prepare_dismount_crystal returned: $status $args"
    }
}

proc operationStart::dismount_crystal { args } {}
proc operationUpdate::dismount_crystal { args } {}
proc operationComplete::dismount_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation dismount_crystal returned error: $status $args"
	} else {
        ::log_note "Operation dismount_crystal returned: $status $args"
    }
}

proc operationStart::prepare_mount_next_crystal { args } {}
proc operationUpdate::prepare_mount_next_crystal { args } {}
proc operationComplete::prepare_mount_next_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation prepare_mount_next_crystal returned error: $status $args"
	} else {
        ::log_note "Operation prepare_mount_next_crystal returned: $status $args"
    }
}

proc operationStart::mount_next_crystal { args } {}
proc operationUpdate::mount_next_crystal { args } {}
proc operationComplete::mount_next_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation mount_next_crystal returned error: $status $args"
	} else {
        ::log_note "Operation mount_next_crystal returned: $status $args"
    }
}

proc operationStart::prepare_move_crystal { args } {}
proc operationUpdate::prepare_move_crystal { args } {}
proc operationComplete::prepare_move_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation prepare_move_crystal returned error: $status $args"
	} else {
        ::log_note "Operation prepare_move_crystal returned: $status $args"
    }
}

proc operationStart::move_crystal { args } {}
proc operationUpdate::move_crystal { args } {}
proc operationComplete::move_crystal { status args } {
	if { $status != "normal" } {
		::log_error "Operation move_crystal returned error: $status $args"
	} else {
        ::log_note "Operation move_crystal returned: $status $args"
    }
}

proc operationStart::robot_standby { args } {}
proc operationUpdate::robot_standby { args } {}
proc operationComplete::robot_standby { status args } {
	if { $status != "normal" } {
		::log_error "Operation robot_standby returned error: $status $args"
	} else {
        ::log_note "Operation robot_standby returned: $status $args"
    }
}

proc operationStart::RobotTest { args } {
        ::log_note "Operation RobotTest started with $args"
}
proc operationUpdate::RobotTest { args } {
        ::log_note "update RobotTest $args"
}
proc operationComplete::RobotTest { status args } {
	if { $status != "normal" } {
		::log_error "Operation RobotTest returned error: $status $args"
	} else {
        ::log_note "Operation RobotTest returned: $status $args"
    }
}
