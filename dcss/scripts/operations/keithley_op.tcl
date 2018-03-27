proc keithley_op_initialize {} {
}

proc keithley_op_start { time } {

	variable keithley_reading
	set tm [expr $time*1000]
	after [format "%5.0f" $tm]
        return [expr -1*$keithley_reading]
}
