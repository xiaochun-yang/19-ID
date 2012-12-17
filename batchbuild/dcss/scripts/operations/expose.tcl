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

proc expose_initialize {} {}


proc expose_start { motor shutter delta time} {
    global gMotorPhi
    global gMotorOmega
	
	# global variables 
	variable maxOscTime

	if { $time == 0 } return

    ##### mapping
    switch -exact -- $motor {
        reposition_phi {
            set motor $gMotorPhi
        }
        reposition_omega {
            set motor $gMotorOmega
        }
    }

	if { $motor != "NULL" && $delta != 0 } {
		variable $motor
		
		# get the current position of the rotation axis motor
		set startAngle [set $motor]

		# calculate the number of oscillations to do
		set oscCount [expr int( double($time) / $maxOscTime ) + 1  ]
	
		# calculate the integration time for each oscillation
		set oscTime [expr double($time) / double($oscCount) ]
	
		print "OSC COUNT = $oscCount"
		print "OSC TIME = $oscTime"

		# loop over oscillations
		for { set oscIndex 1 } { $oscIndex <= $oscCount } { incr oscIndex } {
		
			print "STARTING OSCILLATION $oscIndex"
		
			# move motor back to start of oscillation if not first oscillation
			if { $oscIndex > 1 } {
			
				# start the motor moving
				move $motor to $startAngle
			    wait_for_devices $motor
			} else {
			    error_if_moving $motor
            }
			
			# start an oscillation
			start_oscillation $motor $shutter $delta $oscTime
			
			# wait for the oscillation to complete
			wait_for_devices $motor
		}
	} else {
		#not using a motor
		if { $shutter != "NULL" } { open_shutter $shutter }
		wait_for_time [expr int( $time * 1000)]
		if { $shutter != "NULL" } { close_shutter $shutter }
	}
}

