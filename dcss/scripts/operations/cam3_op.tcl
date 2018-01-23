proc cam3_op_initialize {} {
}

proc cam3_op_start { time } {

	variable cam3_Intensity
#        after $time
#        set camInt [$deviceFactory getObjectName $camIntensity]
#        set camValue [$camInt getContents]
        return $cam3_Intensity
}
