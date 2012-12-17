proc setPreAmp_initialize { } {
}
proc setPreAmp_start { h v } {
    if {$v == "NULL"} {
        set v $h
    }

    variable amp_i_mirror_feedback_ssrl
    variable amp_i_mirror_feedback_spear
    variable amp_i_mirror_feedback_upper
    variable amp_i_mirror_feedback_lower

    set amp_i_mirror_feedback_ssrl "SENS $h"
    set amp_i_mirror_feedback_spear "SENS $h"
    set amp_i_mirror_feedback_upper "SENS $v"
    set amp_i_mirror_feedback_lower "SENS $v"
}
