#this operation is for scripted ion chamber
proc ion_chamber11_op_initialize {} {
}

proc ion_chamber11_op_start { time_in_second } {
     ####set counter integration time     
    set itime [expr $time_in_second*1000]
    set encoder ion_chamber11
    set gDevice($encoder,status) inactive
    set_encoder ion_chamber11 $itime
    wait_for_encoder ion_chamber11
 
    get_encoder ion_chamber11
    set encoderValue [wait_for_encoder ion_chamber11]
#    puts "encoder value = $encoderValue"
    return [expr $encoderValue]
}
