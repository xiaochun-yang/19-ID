proc sample_bpm3_op_initialize {} {
}

proc sample_bpm3_op_start { time } {

	variable 1_0_sa_y_mon

#	set tm [expr $time*1000]
#	after [format "%5.0f" $tm]
	return $1_0_sa_y_mon
}
