#this operation is for scripted ion chamber
proc ion_chamber1_op_initialize {} {
}

proc ion_chamber1_op_start { time_in_second } {
    #variable ion_chamber_offset
    #puts "time_in_seconds = $time_in_second"
    #set counter integration time	 
    set_encoder counter1 time_in_seconds

    #get the counts from the encoder   
    get_encoder counter1
    set encoderValue [wait_for_encoder counter1]
    puts "encoder value = $encoderValue"
    return [expr $encoderValue]
#    return [expr $encoderValue + $ion_chamber_offset]
}
