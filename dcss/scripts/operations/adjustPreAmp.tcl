proc adjustPreAmp_initialize { } {
}
proc adjustPreAmp_start { mt att enabled } {
    puts "adjustPreAmp_start: $mt $att $enabled"

    variable ::preampLUT::lut_horz
    variable ::preampLUT::lut_vert
    variable amp_i_mirror_feedback_spear
    variable amp_i_mirror_feedback_ssrl
    variable amp_i_mirror_feedback_upper
    variable amp_i_mirror_feedback_lower

    set sens_h [PAS_interpolateLUT lut_horz $mt $att]
    set sens_v [PAS_interpolateLUT lut_vert $mt $att]

    ###no tweak
    set sens_h [lindex $sens_h 0]
    set sens_v [lindex $sens_v 0]

    puts "set sensitivity: h: $sens_h v: $sens_v"

    if {!$enabled} {
        log_warning skip set pre-ampifiers: h: $sens_h v: $sens_v
        return
    }

    if {1} {
        ###short format
        set amp_i_mirror_feedback_spear "SENS $sens_h"
        set amp_i_mirror_feedback_ssrl "SENS $sens_h"
        set amp_i_mirror_feedback_upper "SENS $sens_v"
        set amp_i_mirror_feedback_lower "SENS $sens_v"
    } else {
        set amp_i_mirror_feedback_spear [lreplace \
        $amp_i_mirror_feedback_spear 1 1 $sens_h
        set amp_i_mirror_feedback_ssrl [lreplace \
        $amp_i_mirror_feedback_ssrl 1 1 $sens_h
        set amp_i_mirror_feedback_upper [lreplace \
        $amp_i_mirror_feedback_upper 1 1 $sens_v
        set amp_i_mirror_feedback_lower [lreplace \
        $amp_i_mirror_feedback_lower 1 1 $sens_v
    }
    wait_for_strings \
    amp_i_mirror_feedback_spear \
    amp_i_mirror_feedback_ssrl \
    amp_i_mirror_feedback_upper \
    amp_i_mirror_feedback_lower 10000
}
