# omptimized_energy.tcl


proc optimized_energy_initialize {} {
	# specify children devices
	set_children energy
	#set_triggers table_vert
}


proc optimized_energy_move { new_energy } {
	# global variables
        
	variable energy
	variable detector_z
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
    ### in check_beam_good (normalize.tcl):
    # 25: ion chamber check
    # 26: beamineOpenStateStateDelay  
    # 27: spearStateCheck
    # 28: spearStateDelay
    # 29: enable beamHappy check

    #### new: 11/22/2011 requied by Mike Soltis:
    set lastOptimizedDetectorZ [lindex $optimizedEnergyParameters 30]
    set detectorZTolerance [lindex $optimizedEnergyParameters 31]
    if {![string is double -strict $detectorZTolerance]} {
        set detectorZTolerance -1
    }
    if {![string is double -strict $lastOptimizedDetectorZ]} {
        set lastOptimizedDetectorZ $detector_z
    }

   if { $trackingEnable == 1 } {
	   # move energy to destination
	   move energy to $new_energy
	   # wait for the move to complete
	   wait_for_devices energy
   } else {
		log_warning "Energy tracking disabled.  Energy did not move."
   }

    set need4Energy \
    [expr abs($energy - $lastOptimizedPosition) >= $energyTolerance]

    set need4Time \
    [expr [clock seconds] - $lastOptimizedTime  >= $optimizeTimeout]

    set need4DetectorZ 0
    if {$detectorZTolerance >= 0} {
        set need4DetectorZ \
        [expr abs($detector_z - $lastOptimizedDetectorZ) >= $detectorZTolerance]
	}
	#check to see if optimizations are disabled
	if { $optimizeEnable == 0 } {
		log_warning "Table optimization disabled. Table not optimized."
		return
	}

    if {!$need4Energy && !$need4Time && !$need4DetectorZ} {
        return
    }
	
	smartOptimize $energy

	# store the current
	set lastOptimizedPosition $energy
    set lastOptimizedDetectorZ $detector_z
   set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 9 9 $lastOptimizedPosition ]

    set optimizedEnergyParameters [setStringFieldWithPadding \
    $optimizedEnergyParameters 30 $lastOptimizedDetectorZ]
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


proc smartOptimize { new_energy } {
	# global variables
   variable beamlineID
   variable energy
   variable attenuation
   variable beam_size_x
   variable beam_size_y
   variable table_vert
   variable mono_theta_corr

   variable optimizedEnergyParameters
   set resetEnergyAfterOptimize [lindex $optimizedEnergyParameters 5]
   set lastOptimizedTime [lindex $optimizedEnergyParameters 10]
   set optimizeTimeout [lindex $optimizedEnergyParameters 12]
   set ionChamber [lindex $optimizedEnergyParameters 18]
   set minimumBeamSizeX [lindex $optimizedEnergyParameters 19]
   set minimumBeamSizeY [lindex $optimizedEnergyParameters 20]
   set minCounts [lindex $optimizedEnergyParameters 21]
   set scanPoints [lindex $optimizedEnergyParameters 22]
   set scanStep [lindex $optimizedEnergyParameters 23]
   set scanTime [lindex $optimizedEnergyParameters 24]

   set originalAttenuation $attenuation
   set oldbeam_size_y $beam_size_y
   set oldbeam_size_x $beam_size_x

   set originalTableVert $table_vert

	# Open a log file to monitor beamline behaviour
   set logFile "../tmp/optimizedEnergy.log"
	if { [catch {set handle [open $logFile a ] } errorResult ] } {
		log_warning "Error opening logFile"
      return -code error $errorResult
	}

   set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 1 1 [list "Optimizing table..."]]
	puts $handle "[time_stamp] Energy: $energy ,table: $table_vert"

	if { ![beamGood] } {
		wait_for_good_beam
	}

	# Remove any filters in the beam. Write attenuation to log
	if { $attenuation > 0 } { 
		puts $handle "[time_stamp] Initial attenuation: $originalAttenuation" 
		move attenuation to 0 
		log_warning "Removing filters for table optimization"
	}

   # If slits are twoo small, open them up to minimum defined size
	# Write initial position to log

	if { $beam_size_x < $minimumBeamSizeX } {
		puts $handle "[time_stamp] Initial beamsizeX: $oldbeam_size_x"
		move beam_size_x to $minimumBeamSizeX
		log_warning "Making horizontal beam size $minimumBeamSizeX for table optimization"
	}

	if { $beam_size_y < $minimumBeamSizeY } {
		puts $handle "[time_stamp] Initial beamsizeY: $oldbeam_size_y"
		move beam_size_y to $minimumBeamSizeY
		log_warning "Making vertical beam size $minimumBeamSizeY for table optimization"
	}

	wait_for_devices beam_size_x beam_size_y attenuation
   puts $handle "[time_stamp] Attenuation: $attenuation"
	puts $handle "[time_stamp] Beam size: $beam_size_x $beam_size_y"


	while { 1 } { 

		if { ![beamGood] } {
			wait_for_good_beam
		}
  			
		if { [catch {
         set tableNew [optimizeTable_start table_vert $table_vert $ionChamber $scanPoints $scanStep $scanTime]
         set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 1 1 [list "Optimized table"]]
      } errorResult] } {
			log_warning "table optimization failed: $errorResult"
         set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 1 1 [list "error: $errorResult"]]
  		
			switch $errorResult {
				CUBGCVFailed {}
				FindExtremaFailed {}
				NoGoodMax {}
				MaxOnEdge {}
				NoSigMax {}
				TooNarrow {}
				TooWide {}
				TooSteep {}
				NoGoodMax  {}
				UnknownResult {}
				default {}

			}

			if { [beamGood] } {
				#optimized after ten minutes because we failed to optimize, even with beam. Optimally
            #it should be even sooner, but trying the move the table motors too frequently can make them lose steps. 
				
				set lastOptimizedTime [expr [clock seconds] - $optimizeTimeout + 600 ]
            set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 10 10 $lastOptimizedTime ]

				log_warning "Resuming data collection. Will try optimizing again in ten minutes."
            set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 1 1 [list "Table optimization failed while beam was good.  Error: $errorResult"]]
				#move table vert back to original position
				move table_vert to $originalTableVert
				wait_for_devices table_vert
            puts $handle "[time_stamp] Failed optimization. Moved table to $table_vert. Initial position was $originalTableVert"
				break

			} else {
            set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 1 1 [list "Waiting for good beam before retrying optimization..."]]
				move table_vert to $originalTableVert
				wait_for_devices table_vert
				puts $handle "[time_stamp] No beam. Moved table to $table_vert. Initial position was $originalTableVert"
				continue
			}
		}

		#optimize was successful
		set lastOptimizedTime [clock seconds]
      set optimizedEnergyParameters [lreplace $optimizedEnergyParameters 10 10 $lastOptimizedTime ]

      log_note "Table optimization was sucessful. Moving table to $tableNew"
      move table_vert to $tableNew
      wait_for_devices table_vert
		puts $handle "[time_stamp] Optimization OK .Moved table to $table_vert. Initial position was $originalTableVert"

       set energy $new_energy
       log_note "energy_set $new_energy"
       break
       }

	if { $attenuation < $originalAttenuation } { move attenuation to $originalAttenuation }
	if { $beam_size_y > $oldbeam_size_y } { move beam_size_y to $oldbeam_size_y }
	if { $beam_size_x > $oldbeam_size_x } { move beam_size_x to $oldbeam_size_x }
	
	wait_for_devices beam_size_x beam_size_y attenuation
   puts $handle "[time_stamp] Attenuation after scan: $attenuation"
	puts $handle "[time_stamp] Beam size after scan: $beam_size_x $beam_size_y"
	puts $handle ""
	close $handle

	return
		
}



