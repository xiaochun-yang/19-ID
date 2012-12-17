# mono_theta_corr.tcl


proc mono_theta_corr_initialize {} {

	# specify children devices
	set_children mono_theta
}


proc mono_theta_corr_move { new_mono_theta_corr } {

	# global variables
	#variable mono_encoder
	variable mono_theta
	global gDevice


	# move mono_angle motor
	move mono_theta to $new_mono_theta_corr

	# wait for the move to complete
	wait_for_devices mono_theta

	# move mono_encoder to poll it
	print "Poll mono encoder" 

	#poll the encoder
	get_encoder mono_theta_encoder
	#wait for the result
	if { ![catch {wait_for_encoder mono_theta_encoder} errorResult] } {
		set delta [expr $gDevice(mono_theta_encoder,position) - $mono_theta]
		if { abs($delta) > 0.002 } {
			log_warning "Check mono_encoder $mono_theta $gDevice(mono_theta_encoder,position) $delta"
			#set mono_theta $gDevice(mono_theta_encoder,position)
			#try one more time
			#move mono_theta to $new_mono_theta_corr
			#wait_for_devices mono_theta
		}
	} else {
		::dcss2 sendMessage "htos_note encoder_offline"
	}
}


proc mono_theta_corr_set { new_mono_theta_corr } {

	# global variables
	variable mono_theta

	set mono_theta $new_mono_theta_corr
	
	#set the encoder value.
	set_encoder mono_theta_encoder $new_mono_theta_corr
	wait_for_encoder mono_theta_encoder
}


proc mono_theta_corr_update {} {

	# global variables
	variable mono_theta

	return $mono_theta
}


proc mono_theta_corr_calculate { mt } {

	return $mt
}
