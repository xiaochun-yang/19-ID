# mono_piezo.tcl


proc mono_piezo_initialize {} {
	variable monoPiezoGain

	set monoPiezoGain 430.0
	
	# specify children devices
	set_children linear_dac
}


proc mono_piezo_move { new_mono_piezo } {

	variable mono_piezo

	# global variables
	variable linear_dac

	set overShoot 40.0

	if { $new_mono_piezo > $mono_piezo + 1000 } {
		movePiezoInSteps [expr $new_mono_piezo + $overShoot]

		#wait at the overshoot position
		wait_for_time 100
	}

	movePiezoInSteps $new_mono_piezo

}


proc mono_piezo_set { new_mono_piezo } {

	# ues the mono_piezo_move function to do the set
	mono_piezo_move $new_mono_piezo
}


proc mono_piezo_update {} {

	# global variables
	variable linear_dac

	# calculate from real motor positions and motor parameters
	return [mono_piezo_calculate $linear_dac]
}


proc mono_piezo_calculate { ld } {
	variable monoPiezoGain

	return [expr $ld * $monoPiezoGain ]
}

proc movePiezoInSteps { new_mono_piezo } {
	variable monoPiezoGain
	variable linear_dac
 
	set dacTarget [expr ($new_mono_piezo) / $monoPiezoGain ]
	set dacDelta [expr $dacTarget - $linear_dac]

	puts "++++++++++++++++++++++++++++++++++++++++++++++++"
	puts "new_mono_piezo: $new_mono_piezo,  dacTarget: $dacTarget,  dacDelta: $dacDelta"
	
	# The Burleigh Op Amp can not handle high output current
	set totalSteps [expr int( abs($dacDelta) / 0.3  + 0.99999999)]

	#get our starting position and step size
	set thisDacStep $linear_dac

	#loop over all of the steps
	for { set cnt 0} { $cnt < $totalSteps} {incr cnt} {
		set thisDacStep [expr $thisDacStep +  $dacDelta / double($totalSteps) ]
		move linear_dac to $thisDacStep
		# wait for the move to complete
		wait_for_devices linear_dac

		#wait a little bit for output current to settle
		wait_for_time 50
	}
}
