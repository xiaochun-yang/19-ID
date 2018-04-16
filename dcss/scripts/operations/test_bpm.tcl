proc test_bpm_initialize {} {
}

proc test_bpm_start { } {

        #horizontal and vertical PV of BPM2 near the sample
        variable 2_0_sa_x_mon
        variable 2_0_sa_y_mon
	variable cam1_stats1_total


	move gonio_phi by 5 deg
	#return $2_0_sa_y_mon
	#return cam1_stats1_total
        #return [list $2_0_sa_x_mon $2_0_sa_y_mon]
}

