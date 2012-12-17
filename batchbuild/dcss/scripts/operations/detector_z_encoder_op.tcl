#this operation is for scripted ion chamber
proc detector_z_encoder_op_initialize {} {
}

proc detector_z_encoder_op_start { time_in_second } {
    get_encoder detector_z_encoder
    set encoderValue [wait_for_encoder detector_z_encoder]

    return $encoderValue
}
