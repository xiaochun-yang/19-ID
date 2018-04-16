proc upstream_bpm_op_initialize {} {
}

proc upstream_bpm_op_start { time } {

        #horizontal and vertical PV of BPM2 far away from the sample
        variable 1_0_sa_y_mon
        variable 1_0_sa_x_mon

        return [list $1_0_sa_y_mon $1_0_sa_x_mon]
}

