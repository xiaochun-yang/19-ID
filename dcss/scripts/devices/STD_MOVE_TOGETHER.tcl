proc PREFIX_initialize { } {
    set_children PREFIX_1 PREFIX_2
}
proc PREFIX_move { newP } {
    variable PREFIX
    variable PREFIX_1
    variable PREFIX_2

    set diff [expr $newP - $PREFIX]

    set new1 [expr $PREFIX_1 + $diff]
    set new2 [expr $PREFIX_2 + $diff]

    assertMotorLimit PREFIX_1 $new1
    assertMotorLimit PREFIX_2 $new2

    move PREFIX_1 to $new1
    move PREFIX_2 to $new2

    wait_for_devices PREFIX_1 PREFIX_2
}
proc PREFIX_set { newP } {
    log_error NOT SUPPORT SET, please set PREFIX_1 and PREFIX_2 directly
}
proc PREFIX_update { } {
    variable PREFIX_1
    variable PREFIX_2

    return [PREFIX_calculate $PREFIX_1 $PREFIX_2]
}
proc PREFIX_calculate { p1 p2 } {
    return [expr ($p1 + $p2) / 2.0]
}
