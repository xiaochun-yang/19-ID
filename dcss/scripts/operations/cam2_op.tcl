proc cam2_op_initialize {} {
}

proc cam2_op_start { time } {

	variable cam2_stats1_max
	variable cam2_stats1_total
	set tm [expr $time*1000]
	after [format "%5.0f" $tm]
#        set camInt [$deviceFactory getObjectName $camIntensity]
#        set camValue [$camInt getContents]
#        return $cam2_stats1_max
         return $cam2_stats1_total
}
