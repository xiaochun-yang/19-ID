proc sample_bpm1_op_initialize {} {
}

proc sample_bpm1_op_start { time } {

	variable 2_0_sa_y_mon

#	set tm [expr $time*1000]
#	after [format "%5.0f" $tm]
	return $2_0_sa_y_mon
}
