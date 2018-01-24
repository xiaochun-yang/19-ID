proc cam3_op_initialize {} {
}

proc cam3_op_start { time } {

	variable cam3_stats1_max
	variable cam3_stats1_total
	set tm [expr $time*1000]
	after [format "%5.0f" $tm]
#        set camInt [$deviceFactory getObjectName $camIntensity]
#        set camValue [$camInt getContents]
#        return $cam3_stats1_max
        return $cam3_stats1_total
}
