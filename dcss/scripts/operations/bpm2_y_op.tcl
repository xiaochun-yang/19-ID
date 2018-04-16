proc bpm2_y_op_initialize {} {
}

proc bpm2_y_op_start {time} {

        #horizontal and vertical PV of BPM2 near the sample
        variable 1_0_sa_y_mon
        variable 1_0_sa_x_mon

	return $1_0_sa_y_mon
        #return [list $1_0_sa_x_mon $1_0_sa_y_mon]
}

