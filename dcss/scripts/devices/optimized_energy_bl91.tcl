# omptimized_energy.tcl


proc optimized_energy_initialize {} {
	# specify children devices
	set_children energy
	#set_triggers table_vert
}


proc optimized_energy_move { new_energy } {
	# global variables
	variable energy
	variable energyOptimizeTolerance
	variable energyLastOptimized
	variable energyLastTimeOptimized
	variable energyOptimizedTimeout
	variable energyOptimizeEnable

	# move energy to destination
	move energy to $new_energy
	# wait for the move to complete
	wait_for_devices energy

	if {( abs ( double($energy) - double($energyLastOptimized) ) < $energyOptimizeTolerance) && \
			  [clock seconds] - $energyLastTimeOptimized  < $energyOptimizedTimeout } {
		#move ended near last optimization point
		return
	}
	
	#check to see if optimizations are disabled
	if { $energyOptimizeEnable == 0 } {
		::dcss2 sendMessage "htos_note Warning Optimization disabled."
		return
	}
	
	#For 1-5, 11-1, 9-1 smartOptimize resets the energy
	smartOptimize $new_energy
	#On 9-2, only the table offset is reset - no argument needed
	#"smartOptimize"

	# store the current
	set energyLastOptimized $new_energy
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
	variable energyLastTimeOptimized

	#put an if statement around the set to prevent extra dcss messages
	if { $energyLastTimeOptimized != 0} {
		set energyLastTimeOptimized 0
	}
}


proc smartOptimize { new_energy } {
	# global variables
   variable energy
	variable attenuation
	variable beam_size_x
	variable beam_size_y
	variable table_vert
	variable energyOptimizedTimeout
   variable energyLastOptimized
   variable energyLastTimeOptimized
	#For 9-2
	#variable mono_theta_corr 
	#variable table_vert_offset


	########### Move to a global device ############
	set minimumBeamSizeX 0.095
	set minimumBeamSizeY 0.095
	#########################

	set originalAttenuation $attenuation
   set oldbeam_size_y $beam_size_y
   set oldbeam_size_x $beam_size_x

	set originalTableVert $table_vert

	# Open a log file to monitor beamline behaviour
	if { [catch {set handle [open /usr/local/dcs/dcss/tmp/optimizedEnergy.log a ] } ] } {
		log_error "Error opening ../optimizedEnergy.log"
      return -code error $errorResult
	}
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
  			
		if { [catch {set tableNew [optimizeTest_start table_vert $table_vert i2 40 0.025 0.1]} errorResult] } {
			log_warning "table optimization failed: $errorResult"
  		
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
				#optimized after ten minutes because we failed to optimize, even with beam. Optimally it should be even sooner, but trying the move the table motors too frequently can make them lose steps. 
				
				set energyLastTimeOptimized [expr [clock seconds] - $energyOptimizedTimeout + 600 ]
				log_warning "Resuming data collection. Will try optimizing again in ten minutes."
				#move table vert back to original position
				move table_vert to $originalTableVert
				wait_for_devices table_vert
            puts $handle "[time_stamp] Failed optimization. Moved table to $table_vert. Initial position was $originalTableVert"
				break

			} else {
				move table_vert to $originalTableVert
				wait_for_devices table_vert
				puts $handle "[time_stamp] No beam. Moved table to $table_vert. Initial position was $originalTableVert"
				continue
			}

		}

		#optimize was successful
		set energyLastTimeOptimized [clock seconds]
      log_note "Table optimization was sucessful. Moving table to $tableNew"
      move table_vert to $tableNew
      wait_for_devices table_vert
		puts $handle "[time_stamp] Optimization OK .Moved table to $table_vert. Initial position was $originalTableVert"

		#For 11-1 9-1 and 1-5:

		#recalibrate the energy tracking system after a successful optimization
		set energy $new_energy
		log_warning "energy_set $new_energy"

		#For 9-2

		#set table_vert_offset [expr $table_vert - [energy_calculate_table_vert $mono_theta_corr]]
		#puts $handle "[time_stamp] New table offset is $table_vert_offset." 
		
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


