# omptimized_energy.tcl

#################################
#### NO OPTIMIZATION AT ALL
#### Please start from the normal optimized_energy
#### if you need to modify the code.
#################################


proc optimized_energy_initialize {} {
	# specify children devices
	set_children energy
	#set_triggers table_vert
}


proc optimized_energy_move { new_energy } {
	# global variables
        
	variable energy
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
   set minCounts [lindex $optimizedEnergyParameters 21]
   set scanPoints [lindex $optimizedEnergyParameters 22]
   set scanStep [lindex $optimizedEnergyParameters 23]
   set scanTime [lindex $optimizedEnergyParameters 24]

   if { $trackingEnable == 1 } {
	   # move energy to destination
	   move energy to $new_energy
	   # wait for the move to complete
	   wait_for_devices energy
   } else {
		log_warning "Energy tracking disabled.  Energy did not move."
   }

    return
}


proc optimized_energy_set { new_energy } {
	# global variables
	variable energy
	# The energy_set procedure sets table_vert offset
	 set energy $new_energy

}


proc optimized_energy_update {} {
	
	# global variables
	variable optimized_energy
	variable energy
	
	# always return current value
	return $energy
}

proc optimized_energy_calculate { new_optimized_energy } {
	
	return $new_optimized_energy
}

proc optimized_energy_trigger { triggerDevice } {
   variable optimizedEnergyParameters
   set lastOptimizedTime [lindex $optimizedEnergyParameters 10]

	#put an if statement around the set to prevent extra dcss messages
	if { $lastOptimizedTime != 0} {
		set lastOptimizedTime 0
      set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 10 10 $lastOptimizedTime ]
	}
}
