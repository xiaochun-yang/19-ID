#this operation is for scripted ion chamber
proc ion_chamber3_op_initialize {} {
}

proc ion_chamber3_op_start { time_in_second } {
    ####set counter integration time	 
    set itime [expr $time_in_second*1000]
    set encoder ion_chamber3
    set gDevice($encoder,status) inactive
    set_encoder ion_chamber3 $itime
    wait_for_encoder ion_chamber3	    

    #get the counts from the encoder   
    get_encoder ion_chamber3
    set encoderValue [wait_for_encoder ion_chamber3]
#    puts "encoder value = $encoderValue"
    return [expr $encoderValue]
}


