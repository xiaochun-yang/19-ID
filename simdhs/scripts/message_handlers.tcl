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


set gScan(status) inactive
set hutchDoorClosedSet 0

proc handle_stoh_messages {args} {
	puts "in<- $args"
	if { [lindex $args 1] == {} } {
		if { [catch {eval [lindex $args 0]} badResult]} {
			puts "ERROR for $args: $badResult"
		}
	} else {
	
		eval [lindex $args 0] {[lindex $args 1]}
	}
}

proc stoh_set_motor_dependency { args } {}

proc stoh_set_motor_children { args } {}

proc stoh_abort_all { args } {
	# global variables
	global gDevice
	foreach motor [registered_motor_list get] {
		Motor$motor abort
	}

    if { [itcl::find objects detector] != "" } {
        ::detector async_abort
    }

}


proc stoh_start_oscillation { motor shutter delta exposuretime } {
	# global variables
	global gDevice

	Motor$motor oscillation $shutter $delta $exposuretime

}

proc stoh_start_motor_move { motor position {fromSelf 0} } {

	# global variables
	global gDevice

	Motor$motor move $position
}

proc stoh_register_operation { operationName args } {
}

proc stoh_start_operation {operationName args} {
	#global variables
	
	set newCommand "$operationName $args"

	eval $newCommand
}


proc stoh_set_shutter_state { shutter state} {
	#${shutter}_shutter_set_state $state
	dcss sendMessage "htos_report_shutter_state $shutter $state"
}

proc stoh_register_shutter { shutter state } {
	dcss sendMessage "htos_report_shutter_state $shutter $state"
}

proc stoh_register_ion_chamber { name counter counter_channel timer timer_type } {

	# Create a SimulatedMotor object with timer as a time
	simulatedIonChambers ionChamber$name
	
	# Add the name to the list
	registeredIonChamberList add ionChamber$name
	
	# Call simulatedIonChambers:add method to 
	# add the ion chamber to the timer
	ionChamber$name add $name
}

proc stoh_read_ion_chambers { timer dummy args } {
	global gDevice
	foreach ionChamberObj [registeredIonChamberList get] {
		eval {$ionChamberObj readIonChambers $timer} $args
	}
}

proc stoh_register_real_motor { motor args } {

	# global variables
	global gDevice

	# create the device if not yet defined
	if { ! [registered_motor_list isMember $motor] } {
		simulatedMotor Motor$motor -name $motor
	}
	registered_motor_list add $motor

	dcss sendMessage "htos_send_configuration $motor"

}

proc stoh_correct_motor_position { motor correction } {
	
	Motor$motor configure -scaled [expr [Motor$motor cget -scaled] + $correction]

}


proc stoh_configure_real_motor { motor hardwareHost hardwareName position \
												 upperLimit lowerLimit scaleFactor speed acceleration \
												 unscaledBacklash lowerLimitOn upperLimitOn \
												 motorLockOn backlashOn reverseOn dummy } {
	
	# global variables
	global gDevice
	
	# set the pseudomotor parameters
	Motor$motor configure -scaleFactor $scaleFactor -speed $speed -acceleration $acceleration \
		 -lowerLimitOn $lowerLimitOn -upperLimitOn $upperLimitOn \
		 -lockOn $motorLockOn -backlashOn $backlashOn -reverseOn $reverseOn 
	
	#do the following later because we need to have scaleFactor already set
	Motor$motor configure -scaled $position -unscaledBacklash $unscaledBacklash
}



proc stoc_reconnect_on_port { port } {

	# global variables
	global gDevice

	dcss connect $port
	
}


proc stoc_send_client_type {} {
	
	# global variables
	global gDevice

	dcss send_to_server "htos_client_is_hardware simDhs"
}

proc stoh_register_encoder { encoder hardwareName } {
	#the encoder MUST be named the same as the associated motor with an extra _encoder tagged on the end
	set associatedMotor [string range $encoder 0 [expr [string first _encoder $encoder] -1]]
	
	puts "associatedMotor: $associatedMotor"

	simulatedEncoder Encoder$encoder -name $encoder	-associatedMotor $associatedMotor
	
	dcss sendMessage "htos_configure_encoder $encoder 0.0 0.0"	
}

proc stoh_set_encoder { encoder newPosition} {
	Encoder$encoder configure -position $newPosition -errorOffset 0
	dcss sendMessage "htos_set_encoder_completed $encoder $newPosition normal"	
}

proc stoh_get_encoder { encoder } {
	set position [Encoder$encoder cget -position]
	dcss sendMessage "htos_get_encoder_completed $encoder $position normal"	
}

proc stoh_register_string { name hw_name} {
	global hutchDoorClosedSet

	if { $name == "hutchDoorStatus" && ! $hutchDoorClosedSet } {
		after 10000 {update_hutch_door_state}
	} elseif {$name == "lastImageCollected"} {
	} elseif {[itcl::find objects ::sr570${name} ] != -1} { 
	   dcss sendMessage "htos_send_configuration $name"	
    } elseif {$name == "detectorType" } {
        ::detector sendType
    }
	set hutchDoorClosedSet 1
}

proc update_hutch_door_state {} {
	dcss sendMessage "htos_set_string_completed hutchDoorStatus normal closed [clock seconds]"	
	after 5000 {update_hutch_door_state}
}


proc stoh_configure_string {name hw_name args} {
   if {[itcl::find objects ::sr570${name} ] != -1} { 
	   eval sr570$name configureDevice $args	
   }
}


proc stoh_set_string {name args} {
   if {[itcl::find objects ::sr570${name} ] != -1} { 

	   set newContents [eval sr570$name configureDevice $args]
      dcss sendMessage "htos_set_string_completed $name normal $newContents"
      return
   }
   dcss sendMessage "htos_set_string_completed $name normal $args"
}

