#this operation is for scripted ion chamber
proc mfd_vert_encoder_op_initialize {} {
}

proc mfd_vert_encoder_op_start { time_in_second } {
    if {[isEncoder focusing_mirror_2_mfd_vert_encoder]} {
        set encoderName focusing_mirror_2_mfd_vert_encoder
    } else {
        set encoderName mirror_mfd_vert_encoder
    }

    get_encoder $encoderName
    set encoderValue [wait_for_encoder $encoderName]

    return $encoderValue
}
