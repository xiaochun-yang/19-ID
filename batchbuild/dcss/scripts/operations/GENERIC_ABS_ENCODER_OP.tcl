#this operation is for scripted ion chamber
proc PREFIX_encoder_op_initialize {} {
}

proc PREFIX_encoder_op_start { time_in_second } {
    get_encoder PREFIX_encoder
    set encoderValue [wait_for_encoder PREFIX_encoder]

    return $encoderValue
}
