proc sampleMark_initialize { } {
    namespace eval ::sampleMark {
        set orig_x 0
        set orig_y 0
        set orig_z 0
        set orig_phi 0

        set orig_horz 0.5
        set orig_vert 0.5
    }
}
proc sampleMark_start { cmd args } {
    switch -exact -- $cmd {
        setup {
            eval sampleMarkSetup $args
        }
        default {
            return [eval sampleMarkPosition $args]
        }
    }
}
proc sampleMarkSetup { args } {
    variable ::sampleMark::orig_x
    variable ::sampleMark::orig_y
    variable ::sampleMark::orig_z
    variable ::sampleMark::orig_phi
    variable ::sampleMark::orig_horz
    variable ::sampleMark::orig_vert

    set argc [llength $args]
    if {$argc == 0} {
        variable gonio_phi
        variable gonio_omega
        variable sample_x
        variable sample_y
        variable sample_z

        set zoomMaxXAxis [getSampleCameraConstant zoomMaxXAxis]
        set zoomMaxYAxis [getSampleCameraConstant zoomMaxYAxis]

        set orig_x    $sample_x
        set orig_y    $sample_y
        set orig_z    $sample_z
        set orig_phi  [expr $gonio_phi + $gonio_omega]
        set orig_horz $zoomMaxXAxis
        set orig_vert $zoomMaxYAxis
        log_warning set marker to beam center
    } elseif {$argc >= 6} {
        foreach {orig_x orig_y orig_z orig_phi orig_horz orig_vert} \
        $args break
    } else {
        log_error wrong arguments. setup x y z phi horz vert
        return -code error WRONG_ARG
    }
}
proc sampleMarkPosition { args } {
    variable ::sampleMark::orig_x
    variable ::sampleMark::orig_y
    variable ::sampleMark::orig_z
    variable ::sampleMark::orig_phi
    variable ::sampleMark::orig_horz
    variable ::sampleMark::orig_vert

    set argc [llength $args]

    if {$argc == 0} {
        variable gonio_phi
        variable gonio_omega
        variable sample_x
        variable sample_y
        variable sample_z

        set x    $sample_x
        set y    $sample_y
        set z    $sample_z
        set phi  [expr $gonio_phi + $gonio_omega]

        if {abs(int($phi - $orig_phi)) % 180 > 4} {
            log_error currently only support same phi
            return -code error NOT_SUPPORT_YET
        }

        set dx [expr $x - $orig_x]
        set dy [expr $y - $orig_y]
        set dz [expr $z - $orig_z]
        set angle [expr $orig_phi * 3.1415926 / 180.0]

        set dHorzMM $dz

        set dphi [expr ($phi - $orig_phi) * 3.1415926 / 180.0]

        ## for inline
        #set dVertMM [expr $dx * cos($angle) + $dy * sin($angle)]
        ## for sample: follow reposition_y and found sign is reversed
        set dVertMM [expr  $dx * sin($angle) - $dy * cos($angle)]
        set dVertMM [expr  cos($dphi) * $dVertMM]

        foreach {dHorz dVert} [moveSample_mmToRelative $dHorzMM $dVertMM] break

        ### assume this is the phi rotate center
        set zoomMaxYAxis [getSampleCameraConstant zoomMaxYAxis]

        set horz0 $orig_horz
        set vert0 [expr $zoomMaxYAxis + cos($dphi) * ($orig_vert - $zoomMaxYAxis)]

        set horz [expr $horz0 + $dHorz]
        set vert [expr $vert0 + $dVert]

        log_warning marker moved in mm: $dHorzMM $dVertMM \
        relative: $dHorz $dVert
        log_warning marker position at video: $horz $vert

        return [list $horz $vert]
    }
}
