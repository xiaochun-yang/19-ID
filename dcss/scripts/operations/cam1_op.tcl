proc cam1_op_initialize {} {
}

proc cam1_op_start { time } {

	variable cam1_stats1_max
	variable cam1_stats1_total

	set tm [expr $time*1000]
	after [format "%5.0f" $tm]
#        set camInt [$deviceFactory getObjectName $camIntensity]
#        set camValue [$camInt getContents]
#        return $cam1_stats1_max
         return $cam1_stats1_total
}
