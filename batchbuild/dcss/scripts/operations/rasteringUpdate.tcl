proc rasteringUpdate_initialize { } {
    namespace eval ::rastering {
        set COLOR_DONE      blue
        set COLOR_EXPOSING  #c04080

        #### EDGE FACE or ""
        set currentSetup ""
        set currentInfo ""
    }
}
proc rasteringUpdate_start { cmd args } {
    switch -exact -- $cmd {
        clear {
            rastering_clear
        }
        setup {
            log_error should not be calle anymore.
            return -code error NOT_FOR_RASTER
            #eval rastering_setup $args
        }
        simple_setup {
            eval rastering_simpleSetup $args
        }
        restart {
            rastering_restart
        }
        update_cell {
            eval rastering_update_cell $args
        }
        update_text {
            eval rastering_update_text $args
        }
        update_raster_status {
            eval rastering_update_status $args
        }
        update_position {
            ## may decide to follow the sample in 90 degree away
            rastering_update_position
        }
    }
}
proc rastering_clear { } {
    variable scan2DEdgeSetup
    variable scan2DEdgeInfo
    variable scan2DFaceSetup
    variable scan2DFaceInfo

    set scan2DEdgeSetup ""
    set scan2DEdgeInfo -1
    set scan2DFaceSetup ""
    set scan2DFaceInfo -1
}
proc rastering_setup { tag x y z a cv ch row col path user sid } {
    variable ::rastering::currentSetup
    variable ::rastering::currentInfo
    variable scan2DEdgeSetup
    variable scan2DFaceSetup

    if {[string first EDGE $tag] >= 0} {
        set currentSetup scan2DEdgeSetup
        set currentInfo  scan2DEdgeInfo
        set scan2DEdgeSetup [list $x $y $z $a $cv $ch $row $col $path]
    } elseif {[string first FACE $tag] >= 0} {
        set currentSetup scan2DFaceSetup
        set currentInfo  scan2DFaceInfo
        set scan2DFaceSetup [list $x $y $z $a $cv $ch $row $col $path]
    } else {
        set currentSetup ""
        set currentInfo  ""
    }
}
proc rastering_simpleSetup { tag pattern ext threshold } {
    variable ::rastering::currentSetup
    variable ::rastering::currentInfo

    variable scan2DEdgeSetup
    variable scan2DFaceSetup

    if {[string first EDGE $tag] >= 0 || $tag == "VIEW1"} {
        set currentSetup scan2DEdgeSetup
        set currentInfo  scan2DEdgeInfo
        set scan2DEdgeSetup \
        [lreplace $scan2DEdgeSetup 8 10 $pattern $ext $threshold]
    } elseif {[string first FACE $tag] >= 0 || $tag == "VIEW2"} {
        set currentSetup scan2DFaceSetup
        set currentInfo  scan2DFaceInfo
        set scan2DFaceSetup \
        [lreplace $scan2DFaceSetup 8 10 $pattern $ext $threshold]
    } else {
        set currentSetup ""
        set currentInfo  ""
    }
}
proc rastering_update_cell { cell_num_ cell_status_ raster_status_ } {
    log_warning should not call, not used anymore
}
proc rastering_update_status { raster_status_ } {
    variable ::rastering::currentInfo
    variable $currentInfo

    set old [set $currentInfo]
    set new [lreplace $old 0 0 $raster_status_]
    set $currentInfo $new
}
proc rastering_restart { } {
    variable ::rastering::currentSetup
    variable $currentSetup

    set $currentSetup [set $currentSetup]
}
proc rastering_pad_header { header } {
    set result $header
    set l [llength $header]
    switch -exact $l {
        0 {
            set result [list -1 not_ready not_ready]
        }
        1 {
            lappend result not_ready not_ready
        }
        2 {
            lappend result not_ready
        }
    }
    return $result
}
proc rastering_update_text { args } {
    variable ::rastering::currentInfo
    variable $currentInfo

    set new [list [lindex [set $currentInfo] 0]]
    eval lappend new $args
    set $currentInfo $new
}
