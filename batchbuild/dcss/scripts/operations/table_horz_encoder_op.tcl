#this operation is for scripted ion chamber
proc table_horz_encoder_op_initialize {} {
}

proc table_horz_encoder_op_start { time_in_second } {
    get_encoder table_horz_encoder
    return [wait_for_encoder table_horz_encoder]
}
