#this operation is for scripted ion chamber
proc table_vert_2_encoder_op_initialize {} {
}

proc table_vert_2_encoder_op_start { time_in_second } {
    get_encoder table_vert_2_encoder
    return [wait_for_encoder table_vert_2_encoder]
}
