proc timeOptEnergy_initialize { } {
}

proc timeOptEnergy_start {  } {
    set motor table_vert_1
    global gDevice
    set backlashOn $gDevice($motor,backlashOn)
    set reverseOn $gDevice($motor,reverseOn)
    set scaledBacklash $gDevice($motor,scaledBacklash)
    variable optimizedEnergyParameters
    variable table_vert_1
    variable table_vert
    set scanPoints [lindex $optimizedEnergyParameters 22]
    set scanStep [lindex $optimizedEnergyParameters 23]
    set scanTime [lindex $optimizedEnergyParameters 24]
    variable table_pitch

    if {$backlashOn == 1} {
	if {$scaledBacklash < 0 } {
	    set scanmove [expr $table_vert +($scanPoints * $scanStep / 2.0)]
	    set new_table_vert_1 [calculate_table_vert_1 $scanmove $gDevice(table_pitch,target)]
	    set timescan [timeOfMovement_start table_vert_1 $table_vert_1 $new_table_vert_1]

	    set iontime [ expr $scanTime * $scanPoints]
	    set stepmove [expr ($table_vert - $scanStep)]
	    set table_vert_1_step [calculate_table_vert_1 $stepmove $gDevice(table_pitch,target)]
	    set timestep [timeOfMovement_start table_vert_1 $table_vert_1 $table_vert_1_step]

	    set totaltime [expr ($timestep * $scanPoints) + (2 * $timescan) + $iontime  ]
	    send_operation_update "time to scan table: $totaltime seconds" 

	} else {

	    set scanmove [expr $table_vert - ($scanPoints * $scanStep / 2.0)]
	    set new_table_vert_1 [calculate_table_vert_1 $scanmove $gDevice(table_pitch,target)]
	    set timescan [timeOfMovement_start table_vert_1 $table_vert_1 $new_table_vert_1]

	    set iontime [ expr $scanTime * $scanPoints]	   
	    set stepmove [expr ($table_vert + $scanStep)]
	    set table_vert_1_step [calculate_table_vert_1 $stepmove $gDevice(table_pitch,target)]
	    set timestep [timeOfMovement_start table_vert_1 $table_vert_1 $table_vert_1_step]

	    set totaltime [expr ($timestep * $scanPoints) + (2 * $timescan) + $iontime  ]
	    send_operation_update "time to scan table: $totaltime seconds" 

	}
    } else {
	log_error "Backlash is not set for table_vert"
    }
   
   

 return $totaltime

}


proc calculate_table_vert_1 { tv tp } {

	# global variables
	variable table_pivot
	variable table_v1_z
	variable table_pivot_z
	
	return [expr $tv + ( $table_v1_z - $table_pivot_z ) * tan([rad $tp]) ]
}


