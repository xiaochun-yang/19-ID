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


proc recoverFromScan_initialize {} {
}

proc recoverFromScan_start {} {

	# namespace variables
	variable oldAttenuation
	variable oldEnergy
	variable oldBeamstopZ

	global gStopFluorescenceScan
	set gStopFluorescenceScan 0

	# global variables
	global gDevice

	# close the shutter
	close_shutter shutter

	# start move of energy if a valid oldEnergy value exists
	if { $oldEnergy > 0 } {
	    move attenuation to 0
        wait_for_devices attenuation
        move energy to $oldEnergy
	}

	# start move of beamstop_z if a valid oldBeamstopZ exists
	if { $oldBeamstopZ > 0 } {
	    puts "MOVING BEAMSTOP_Z BACK TO $oldBeamstopZ"
	    move beamstop_z to $oldBeamstopZ
	} else {
	    puts "LEAVING BEAMSTOP_Z ALONE"
	}

	# start moves of fluorescence_z and attenuation
	if {[motor_exists fluorescence_z]} {
		move fluorescence_z to  [expr $gDevice(fluorescence_z,scaledUpperLimit) - 0.5]
		wait_for_devices fluorescence_z
	}

	# wait for all devices to finish moving
	wait_for_devices energy

	# wait for the shutter to close
	wait_for_shutters shutter

	# wait for all devices to finish moving
	wait_for_devices beamstop_z

	# attenuation is depend on energy, so it should be restore after energy.
	move attenuation to [expr $oldAttenuation + 0.001]
	wait_for_devices attenuation
}






