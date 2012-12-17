proc contrast_auto_initialize { } {
}
proc contrast_auto_start { time } {
    #### center x, centerY, width and height
    variable autofocus_constants
    foreach {x y w h} $autofocus_constants break

    set h [start_waitable_operation getInlineContrast $x $y $w $h]
    set result [wait_for_operation_to_finish $h]

    return [lrange $result 1 end]
}
