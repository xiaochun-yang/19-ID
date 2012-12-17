#this operation is for scripted ion chamber
proc mono_theta_encoder_op_initialize {} {
}

proc mono_theta_encoder_op_start { time_in_second } {
    set encoderName mono_theta_encoder

    get_encoder $encoderName
    set encoderValue [wait_for_encoder $encoderName]

    return $encoderValue
}
