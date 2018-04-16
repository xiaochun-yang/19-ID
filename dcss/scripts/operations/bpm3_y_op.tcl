proc bpm3_y_op_initialize {} {
}

proc bpm3_y_op_start {time} {

        #horizontal and vertical PV of BPM2 near the sample
        variable 2_0_sa_y_mon
        variable 2_0_sa_x_mon

	return $2_0_sa_y_mon
        #return [list $2_0_sa_x_mon $2_0_sa_y_mon]
}

