proc softLinkForL614_initialize { } {
    variable l614_softlink_status

    set l614_softlink_status [lreplace $l614_softlink_status 0 0 -1]
}
proc softLinkForL614_start { cmd args } {
    switch -exact -- $cmd {
        setup {
            return [eval softLinkForL614_setup $args]
        }
        refresh {
            return [softLinkForL614_refresh]
        }
        add_file {
            return [eval softLinkForL614_addFile $args]

        }
        default {
            log_error not support $cmd
            return -code error not_support
        }
    }
}
proc softLinkForL614_setup { dir_ prefix_ ext_ } {
    variable l614_softlink_status

    set l614_softlink_status [list -1 $dir_ $prefix_ $ext_]

    return [softLinkForL614_refresh]
}
proc softLinkForL614_refresh { } {
    variable l614_softlink_status

    foreach {- dir prefix ext} $l614_softlink_status break

    set dir    [TrimStringForRootDirectoryName $dir]
    set prefix [TrimStringForCrystalID $prefix]

    set counter [get_next_counter $dir $prefix $ext l]
    log_warning next counter=$counter for dir=$dir prefix=$prefix ext=$ext

    set l614_softlink_status [lreplace $l614_softlink_status 0 0 $counter]

    return $counter
}
proc softLinkForL614_addFile { target } {
    global gCounterFormat
    variable l614_softlink_status

    foreach {counter dir prefix ext} $l614_softlink_status break
    if {$counter == "skip"} {
        return ""
    }

    if {![string is integer -strict $counter] || $counter < 0} {
        softLinkForL614_refresh
    }
    if {![string is integer -strict $counter] || $counter < 0} {
        log_error something wrong, next counter still not right.
        return -code error failed
    }

    set cntTxt [format $gCounterFormat $counter]

    if {$ext == ""} {
        set link [file join $dir ${prefix}_$cntTxt]
    } else {
        set link [file join $dir ${prefix}_${cntTxt}.${ext}]
    }
    
    ### this need the target must exist.
    #file link -symbolic $link $target
    exec ln -s $target $link


    log_warning created softlink $link to $target

    incr counter
    set l614_softlink_status [lreplace $l614_softlink_status 0 0 $counter]

    return $link
}
