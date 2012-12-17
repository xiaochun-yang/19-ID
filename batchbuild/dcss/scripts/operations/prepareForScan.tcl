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


proc prepareForScan_initialize {} {
}

proc prepareForScan_start { exciteEnergy {skip_save 0} } {

	# namespace variables
	variable oldAttenuation
	variable oldEnergy
	variable oldBeamstopZ
	variable energy
	variable attenuation
	variable beamstop_z
	variable fluorescence_z

	# global variables
	global gDevice

    set cfgDeadTimeRatio [::config getStr fluorescentScan.deadTimeRatio]
    if {![string is double -strict $cfgDeadTimeRatio]} {
        log_warning florescentScan dead time ratio set to 3%
        set cfgDeadTimeRatio 0.03
    }
    puts "deadTimeRatio=$cfgDeadTimeRatio"

	# store current energy and attunuation
    if {!$skip_save} {
	    set oldAttenuation $attenuation
	    set oldEnergy $energy
	    set oldBeamstopZ $beamstop_z
    }

   log_note "Optimizing fluorescence detector position."

	# start move of fluorescence detector, energy, and beamstop
	if {[motor_exists fluorescence_z]} {
		move fluorescence_z to [expr $gDevice(fluorescence_z,scaledLowerLimit) + 0.5]
	}

	move attenuation to 0
    wait_for_devices attenuation
	move energy to $exciteEnergy

	# move beamstop_z if not already past 40 mm
	if { $beamstop_z < 40.0 } {
		if { $gDevice(beamstop_z,scaledUpperLimit) < 40.5 } {
			move beamstop_z to [expr $gDevice(beamstop_z,scaledUpperLimit) - 0.5]
		} else {
			move beamstop_z to 40.0
		}
	} else {
		set oldBeamstopZ 0
	}

	# wait for all devices to finish moving
	wait_for_devices energy beamstop_z
	if {[motor_exists fluorescence_z]} {
		wait_for_devices fluorescence_z
	}
	# insert all attenuators
    set att 100.0
    #### even_limits_off == 1
    adjustPositionToLimit attenuation att 1
	move attenuation to $att
    wait_for_devices attenuation

	# open the shutter
	open_shutter shutter
	wait_for_shutters shutter

	set counts 0

	# initialize currentAttenuation to first achieved attenuation
	set currentAttenuation $attenuation

	# keep track of the last good attenuation
	set lastGoodAttenuation $attenuation

	if {[motor_exists fluorescence_z]} {
	    #get the dead time ratio
	    set deadTimeRatio [measureDeadTime]

	    #move the fluor. detector back when the dead time is too high 
		while { $deadTimeRatio > $cfgDeadTimeRatio } {
      		checkFluorescenceScanStopped 

			#move back 1 cm or as close to the hardware limit as we can
			if { ($fluorescence_z + 10.0) < ($gDevice(fluorescence_z,scaledUpperLimit) - 0.5) } {
				#we have room to move 1 cm
				move fluorescence_z by 10.0
				wait_for_devices fluorescence_z
			} else {
				#go back as far as we can and give up
				move fluorescence_z to [expr $gDevice(fluorescence_z,scaledUpperLimit) - 0.5]
				wait_for_devices fluorescence_z
				break
			}
			#get the dead time ratio again
			set deadTimeRatio [measureDeadTime]
		}
	}

   log_note "Optimizing attenuation for fluorescence detector."
	# iteratively remove attenuation until dead time ratio > .1

	while { $attenuation > 1.0 } {

      checkFluorescenceScanStopped 

		after 100

		set deadTimeRatio [measureDeadTime]

		print "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
		print "HHHHHHHHHHHHHHHHH   Got deadTimeRatio $deadTimeRatio at $attenuation attenuation HHHHHHHHHHHHHHHH"
		print "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"

		if { $deadTimeRatio > $cfgDeadTimeRatio } break

		# modulate attenuation to bring counts under 10000
		set lastGoodAttenuation $attenuation
		set currentAttenuation $attenuation

		while { abs( $attenuation - $currentAttenuation ) < 0.0001 } {
			
			set delta [expr (100.0  - $currentAttenuation ) ]
			if { $delta < 0.00001 } { set delta 0.001 }

			set currentAttenuation [expr 100.0 - $delta * 1.2 ]
            ###assume attenuation is [0,100]
            if {$currentAttenuation < 0.0} {
			    set currentAttenuation 0.0
            }

			puts "HHHHHHHHHHHHHHHHHH Attempting to move attenuation to $currentAttenuation  HHHHHHHHHHHHHHHHHHHH"

            set hitLimit [adjustPositionToLimit attenuation currentAttenuation 1]
			move attenuation to $currentAttenuation
			wait_for_devices attenuation

            if {$currentAttenuation <= 0.0 || $currentAttenuation >= 100.0 || $hitLimit} {
                break
            }
		}
	}

	if { $deadTimeRatio < $cfgDeadTimeRatio } {
		set lastGoodAttenuation 0.0
	}


	print "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"
	print "HHHHHHHHHHHHHHHHH   Moving attenuation $lastGoodAttenuation HHHHHHHHHHHHHHHH"
	print "HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH"

	# move attenuation to last good attenuation
	set att [expr $lastGoodAttenuation + 0.001]
    adjustPositionToLimit attenuation att 1
	move attenuation to $att

	# wait for the attenuation device
	wait_for_devices attenuation

	return
}

proc measureDeadTime {} {

	#ask for 1 channel over the whole detector
	set opHandle [start_waitable_operation excitationScan 0 25000 1 i2 1.0]
	set exciteResult [wait_for_operation $opHandle]
		
	set status [lindex $exciteResult 0]

	#check to make sure that things are normal
	if { $status != "normal" } {
		#return error
		return -code error $result
	}

    if {![beamGood]} {
        return -code error BEAM_NOT_GOOD
    }

	return [lindex $exciteResult 1]
}


proc checkFluorescenceScanStopped {} { 

	global gStopFluorescenceScan

   if { $gStopFluorescenceScan == 1 } {
      # move energy back to previous position if scan successful
      set operationID [start_waitable_operation recoverFromScan]
      set result [wait_for_operation_to_finish $operationID]
      return -code error "Scan stopped by user"
   }
}

