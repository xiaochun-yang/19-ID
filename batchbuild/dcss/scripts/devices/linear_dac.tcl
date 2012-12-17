# linear_dac.tcl


proc linear_dac_initialize {} {

	# specify children devices
	set_children dac
}


proc linear_dac_move { new_linear_dac } {

	# global variables
	variable dac

	if { $new_linear_dac < 0 } {
		#set analog output to negative position
		if { $new_linear_dac < -9.999 } {
			::dcss2 sendMessage "htos_note Warning Attempted to move beyond range of DAC: $new_linear_dac"
			set new_linear_dac -9.999
		}
		#
		move dac to [expr ($new_linear_dac + 20) /2  ] 
	} else {
		#set anaolog output to positive position
		if { $new_linear_dac > 9.999 } {
			::dcss2 sendMessage "htos_note Warning Attempted to move beyond range of DAC: $new_linear_dac"
			set new_linear_dac 9.999
		}
		move dac to [expr $new_linear_dac / 2.0 ] 

		
	}

	# wait for the moves to complete
	wait_for_devices dac
}


proc linear_dac_set { new_linear_dac } {

	# ues the linear_dac_move function to do the set
	linear_dac_move $new_linear_dac
}


proc linear_dac_update {} {

	# global variables
	variable dac

	# calculate from real motor positions and motor parameters
	return [linear_dac_calculate $dac]
}


proc linear_dac_calculate { d } {

	
	if { $d < 5.0 }  {
		return [expr $d * 2 ]  
	} else {
		return [expr $d * 2.0  - 20 ]
	}
	
}
