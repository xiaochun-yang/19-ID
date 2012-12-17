proc contrast_ion_initialize { } {
}
proc contrast_ion_start { time } {
    #### center x, centerY, width and height
    variable contrast_roi
    foreach {x y w h} $contrast_roi break

    set h [start_waitable_operation getInlineContrast $x $y $w $h]
    set result [wait_for_operation_to_finish $h]

    return [lrange $result 1 end]
}
