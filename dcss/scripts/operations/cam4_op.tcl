proc cam4_op_initialize {} {
}

proc cam4_op_start { time } {

	variable cam4_stats1_total
	set tm [expr $time*1000]
	after [format "%5.0f" $tm]
        return $cam4_stats1_total
}
