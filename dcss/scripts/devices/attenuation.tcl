# attenuation.tcl

proc attenuation_initialize {} {
	#global variables
	global gAttenuators

    set filterThicknessStr [::config getStr attenuation.filterThickness]
    if {$filterThicknessStr == "" } {
        log_error "please add attenuation.filterThickness to the config file"
        return
    }

    foreach {filter thickness} $filterThicknessStr {
        if {[info exists lastThickness] && $thickness > $lastThickness} {
            log_error "please order attenuation.filterThickness in order of decreasing filter thickness"
            log_error "removing $filter from attenuation equation"
            continue
        }

        append gAttenuators(names) "$filter "
        append gAttenuators(thickness) "$thickness "
        set lastThickness $thickness
    }

	#set interested devices
	eval set_triggers $gAttenuators(names) energy
}

proc getAllFilterStatus {} {
   global gAttenuators

   set status ""
   foreach filter $gAttenuators(names) {
      variable $filter
      lappend status [set $filter] 
   }

   return $status
}

proc restoreFilterStatus { statusList } {
   global gAttenuators

   set index 0
   foreach filter $gAttenuators(names) {
      ## the "1" at the end means ignore abort
      setFilter $filter [lindex $statusList $index] 1
      incr index
   }

	wait_for_shutters $gAttenuators(names)
}

proc setFilter { filter status {nocheck 0} } {
   variable $filter

   if { $status == "closed" || $status == "1"} {
		if { [set $filter] != "closed" } {
         close_shutter $filter $nocheck
      }
   }
   
   if { $status == "open" || $status == "0" } {
	   if { [set $filter] != "open" } {
         open_shutter $filter $nocheck
      }
   }
}

proc attenuation_move { new_attenuation } {
	# global variables
	global gAttenuators

	# global devices
	variable attenuation
   variable energy

	#check for oddball requests
	if { $new_attenuation >= 100 } {
		#Put in every filter without any calculation,
		#otherwise we will try to calculate log(0) later.
		foreach shutter $gAttenuators(names) {
         variable $shutter
			#open the shutter if it is closed
         setFilter $shutter closed
		}
		wait_for_shutters $gAttenuators(names)
		return
	}
	
	if { $new_attenuation < 0 } {
		set new_attenuation 0
	}
	
	#Calculate the desired thickness needed to achieve the attenuation.
	set thickness [calculateThickness $new_attenuation "Al" $energy]
	#Search for the combination of filters that will get us closest to the
	# desired thickness.
	set result [searchAttenuation $thickness $gAttenuators(thickness) ]
	#Extract the combination of filters from the search result.
	set resultPattern [lindex $result 1]

	#Open and close the filters based on the search result.
	set shutterIndex 0
	foreach openState $resultPattern {
		set shutter [lindex $gAttenuators(names) $shutterIndex]
      setFilter $shutter $openState
		incr shutterIndex
	}

	#wait for the shutters before we indicate that the attenuation move is complete.
	wait_for_shutters $gAttenuators(names)
}


proc attenuation_set { new_attenuation } {
	#attenuation_move $new_attenuation
	return
}


proc attenuation_update {} {
	# calculate from filter states and motor positions
	return [attenuation_calculate]
}


proc attenuation_calculate { } {
	# global variables
	global gAttenuators
	variable energy
	
	set totalThickness 0
	set shutterIndex 0

	#Loop over all of the filters and sum up the total thickness.
	foreach shutter $gAttenuators(names) {
      variable $shutter
		if { [set $shutter] == "closed" } {
			incr totalThickness [lindex $gAttenuators(thickness) $shutterIndex]
		}
		incr shutterIndex
	} 
	
	#Calculate the attenuation based on the total thickness. 
	set attenuationResult [expr (1.0 - [calculateTransmission Al $energy $totalThickness]) * 100]
	#Do not allow the attenuation to exceed %100.
	#if { $attenuationResult > 100} {
	#	set attenuationResult 100
	#}
	return $attenuationResult
}


#This function is called whenever a trigger device changes state or position.
proc attenuation_trigger { triggerDevice } {
	# global variables
	variable attenuation
	
	# calculate from real shutter positions and motor parameters
	#	set attenuation [attenuation_calculate]
	update_motor_position attenuation [attenuation_calculate] 1
	return
}


proc absorption { material energy } {
	set Al(0) 0.0084912
	set Al(1) -0.020347
	set Al(2) 0.015521
	
	puts "********************** energy  $energy "
	
	set lambda [expr 12398.54 / double( $energy ) ];
	set absorption [expr $Al(0) + $Al(1) * $lambda + $Al(2) * $lambda * $lambda ]
	puts "**********absorption $absorption"
	return $absorption
}

proc calculateTransmission { material energy length} {
	
	set mu [absorption $material $energy] 
	return [expr exp( -$mu * $length)]
}

proc calculateThickness { requestedAttenuation material energy } {
	set transmission [expr (100.0 - $requestedAttenuation)/ 100.0]

	set mu [absorption $material $energy]
	set length [expr  -1 * log( double($transmission))  / $mu ]
	return $length
}

# This function searches for a combination of filters that is closest to, but
# not exceeding the desired thickness.
# Inputs:  
#  targetThickness -> This it the 
#  thicknessList   -> This is the list of thicknesses for available filters.
#                     The thickness list must be ordered by decreasing thickness
#                     for this function to work.
# Outputs:
#           delta  -> The difference between the target thickness and the best
#                     achievable thickness from the component filters.
#           pattern-> This will be a list of binary numbers indicating whether
#                     the component filter should be used or not.
#
# The function will recursively call itself while searching for the answer.
# 
proc searchAttenuation { targetThickness thicknessList } {
#	puts "******************************************************************"
#	puts "targetThickness: $targetThickness,   thicknessList: $thicknessList"

	set totalShutters [llength $thicknessList]
	#set lastDelta $targetThickness
	set bestDelta $targetThickness
	set bestPattern ""
	set thisPattern ""
	

	#Shortcircuit the recursive calling if the sum of the thicknesses
	# is less than the target thickness. 
	set thicknessSum 0
	set possiblePattern ""
	foreach shutter $thicknessList {
		incr thicknessSum $shutter
		append possiblePattern "1 "
	}
	if { $thicknessSum <= $targetThickness } {
		return "[expr $targetThickness - $thicknessSum] \{$possiblePattern\}"  
	} 
	
	#Loop over all the filters, except the last filter in the list.
	set count 0
	while { $count+1 < $totalShutters } {
		set thisThickness [lindex $thicknessList $count]
		#throw away shutters that are too big
		if { $thisThickness < $targetThickness } {
			#search for best resulting pattern for sub string
			#puts $thisThickness
			set thisResult [searchAttenuation [expr $targetThickness - $thisThickness] [lrange $thicknessList [expr $count+1] end]  ]
			set delta [lindex $thisResult 0]
			set pattern [lindex $thisResult 1]
			
			#puts "targetThickness: $targetThickness:  returned $delta, $pattern"
			if { $delta >= 0 } {
				if { $delta > $bestDelta } {
					#that one didn't work
					append thisPattern "0 "
					break
				}
				if { $delta < $bestDelta} {
					set bestPattern $thisPattern
					if  { $count+1 < $totalShutters } { 
						append bestPattern "1 "
					}
					append bestPattern "$pattern "
					set bestDelta $delta
					#set lastDelta $delta
					append thisPattern "0 "
				}
			}
		} else {
			append thisPattern "0 "
		}
		incr count
	}

	# If we haven't found anything good yet, set the best pattern to
	# the accumulation of 0's
	if { $bestPattern == ""} {
		set bestPattern $thisPattern
	}

	#Look at the last filter in the list.
	set delta [expr $targetThickness - [lindex $thicknessList end]]
	if { $delta >= 0 } {
		if { $delta > $bestDelta } {
			#that one didn't work
			#give up, we have a better solution already
		} else {
			if { $delta < $bestDelta} {
				set bestPattern $thisPattern
				set bestDelta $delta
				append bestPattern "1"
			} else {
				append bestPattern "0"
			}
		}
	} else {
		append bestPattern "0"
	}
	
	#puts "return delta: $bestDelta,  return bestPattern $bestPattern"
	return  "$bestDelta \{$bestPattern\}" 
}

