#this operation is for scripted ion chamber
proc ion_chamber2_op_initialize {} {
}

proc ion_chamber2_op_start { time_in_second } {
     ####set counter integration time     
    set itime [expr $time_in_second*1000]
    set encoder ion_chamber2
    set gDevice($encoder,status) inactive
    set_encoder ion_chamber2 $itime
    wait_for_encoder ion_chamber2
    
    get_encoder ion_chamber2
    set encoderValue [wait_for_encoder ion_chamber2]
    return [expr $encoderValue]
}
