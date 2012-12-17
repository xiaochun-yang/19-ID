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

proc optimizeTable_initialize {} {
	# global variables
}

proc optimizeTable_start {  motor centerPosition detector points step time } {
    
	# global variables 
	variable $motor


   variable optimizedEnergyParameters

   set state [lindex $optimizedEnergyParameters 0]
   set message [lindex $optimizedEnergyParameters 1]
   set trackingEnable [lindex $optimizedEnergyParameters 2]
   set optimizeEnable [lindex $optimizedEnergyParameters 3]
   set beamlineOpenCheck [lindex $optimizedEnergyParameters 4]
   set resetEnergyAfterOptimize [lindex $optimizedEnergyParameters 5]
   set spareOption2 [lindex $optimizedEnergyParameters 6]
   set spareOption3 [lindex $optimizedEnergyParameters 7]
   set spareOption4 [lindex $optimizedEnergyParameters 8]
   set lastOptimizedPosition [lindex $optimizedEnergyParameters 9]
   set lastOptimizedTime [lindex $optimizedEnergyParameters 10]
   set energyTolerance [lindex $optimizedEnergyParameters 11]
   set optimizeTimeout [lindex $optimizedEnergyParameters 12]
   set lastOptimizedTablePosition [lindex $optimizedEnergyParameters 13]
   set flux [lindex $optimizedEnergyParameters 14]
   set wmin [lindex $optimizedEnergyParameters 15]
   set glc [lindex $optimizedEnergyParameters 16]
   set grc [lindex $optimizedEnergyParameters 17]
   set ionChamber [lindex $optimizedEnergyParameters 18]
   set minBeamSizeX [lindex $optimizedEnergyParameters 19]
   set minBeamSizeY [lindex $optimizedEnergyParameters 20]


	#########################

	# initialize arrays
	set positions {}
	set counts {}

	# store the current position
	set oldPosition [set $motor]

	# calculate starting position
	set start [expr $centerPosition - $points * $step / 2.0]
	# move motor to starting position
	move_no_parse $motor to $start 0

	# wait for ion chamber to become inactive and motor to reach start position
	wait_for_devices $motor $detector
	
	# loop over points
	for { set point 0 } { $point < $points } { incr point } {
		
		# move motor to next position
		set position  [expr $start + $point * $step]
		move_no_parse $motor to $position 0
		wait_for_devices $motor

		# count on the ion chamber
		read_ion_chambers $time $detector
		wait_for_devices $detector

		# store position and ion chamber reading in arrays
		lappend positions $position
		lappend counts [get_ion_chamber_counts $detector ]
	}

	# try to open file for append 	
	if { [catch {set handle [open ../tmp/optimizeNew.log a ] } errorResult ] } {
		log_error "Error opening ../optimizeNew.log"
      set handle stdout
		#return -code error $errorResult
	}

	puts $handle "[time_stamp] Maximizing: $motor"
	puts $handle [concat $positions]
	puts $handle [concat $counts]

	puts "analyzePeak $positions $counts $flux $wmin 1.0 .15 $glc $grc 1"

	#set result [cal_find_peak $points $positions $counts]
	puts "start analyze peak"


	if { [catch {set result [analyzePeak $positions $counts $flux $wmin 1.0 .15 $glc $grc 1]} errorResult] } {

		puts $handle "[time_stamp] Error Maximizing: $errorResult"

		puts $handle ""
		close $handle
  		
		return -code error $errorResult
	}
	 
	# write optimized position to log	
   set optimalValue [lindex $result 0]
	puts $handle "[time_stamp] Optimal Value = $optimalValue"
	puts $handle ""
	close $handle
   return $optimalValue
	
}

