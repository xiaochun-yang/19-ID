#this operation is for scripted ion chamber
proc mfd_horz_encoder_op_initialize {} {
}

proc mfd_horz_encoder_op_start { time_in_second } {
    set encoderName mirror_mfd_horz_encoder
    get_encoder $encoderName
    set encoderValue [wait_for_encoder $encoderName]

    return $encoderValue
}
