#this operation is for scripted ion chamber
proc ion_chamber12_op_initialize {} {
}

proc ion_chamber12_op_start { time_in_second } {
     ####set counter integration time     
    set itime [expr $time_in_second*1000]
    set encoder ion_chamber12
    set gDevice($encoder,status) inactive
    set_encoder ion_chamber12 $itime
    wait_for_encoder ion_chamber12
 
    get_encoder ion_chamber12
    set encoderValue [wait_for_encoder ion_chamber12]
#    puts "encoder value = $encoderValue"
    return [expr $encoderValue]
}
