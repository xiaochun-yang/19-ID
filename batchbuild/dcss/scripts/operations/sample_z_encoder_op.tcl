#this operation is for scripted ion chamber
proc sample_z_encoder_op_initialize {} {
}

proc sample_z_encoder_op_start { time_in_second } {
    get_encoder sample_z_encoder
    set encoderValue [wait_for_encoder sample_z_encoder]

    return $encoderValue
}
