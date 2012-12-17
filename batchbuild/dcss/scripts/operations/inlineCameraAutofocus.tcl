proc inlineCameraAutofocus_initialize { } {
    variable cfgAutoFocusConstantNameList

    set cfgAutoFocusConstantNameList \
    [::config getStr autoFocusConstantsNameList]

    namespace eval ::inlineCameraAutofocus {
        set logKey [list \
        inline_focus_orig \
        inline_focus_new \
        inline_focus_diff \
        ]

        ### operations allowed or included
        ### we may use these in the future
        set logOperation [list \
        inlineCameraAutofocus \
        ]

        set logStartTime 0
    }
}
proc inlineCameraAutofocus_getConstant { name } {
    variable cfgAutoFocusConstantNameList

    set index [lsearch -exact $cfgAutoFocusConstantNameList $name]
    if {$index < 0} {
        log_error $name not found on namelist for autofocus
        return -code error NAME_NOT_FOUND
    }
    if {![isString autofocus_constants]} {
        log_error need to defind string autofocus_constants to use autofocus
        return -code error STRING_NOT_FOUND
    }

    variable autofocus_constants
    if {[llength $autofocus_constants] \
    < [llength $cfgAutoFocusConstantNameList]} {
        log_error auto_focus_constants not match namelist
        return -code error NAME_NOT_MATCH_LIST
    }
    return [lindex $autofocus_constants $index]
}
proc inlineCameraAutofocus_start { args } {
    matchup_inlineLightSetup

    set motorName inline_camera_focus
    set width     [inlineCameraAutofocus_getConstant scan_width]
    set numPoint  [inlineCameraAutofocus_getConstant scan_points]
    set CUT_OFF   [inlineCameraAutofocus_getConstant CUT_PERCENT]
    set signal    contrast4autofocus
    set time      1
    set timeWait  0
    set minSignal 0
    if {![isMotor $motorName]} {
        log_error $motorName is not motor on current beamline
        return -code error "wrong_autofocus_config"
    }
    if {$numPoint < 5} {
        log_error wrong numPoint: $numPoint should be >= 5
        return -code error "wrong_autofocus_config"
    }
    if {![isIonChamber $signal]} {
        log_error wrong signal: $signal is not an ion chamber
        return -code error "wrong_autofocus_config"
    }

    variable $motorName
    set save_POS [set $motorName]
    set halfW    [expr $width / 2.0]
    set startP   [expr $save_POS - $halfW]
    set endP     [expr $save_POS + $halfW]

    if {[swapIfBacklash $motorName startP endP]} {
        puts "autofocus scan swapped start and end because backlash"
    }
    set dir [file join [pwd] alignTungsten]
    file mkdir $dir
    set TS4Name [timeStampForFileName]
    set fileName [file join $dir ${TS4Name}_autofocus]
    send_operation_update "starting scan"
    set result [peakGeneric_scan $fileName $motorName $startP $endP \
    $numPoint $time $signal $timeWait $CUT_OFF $minSignal -1 1]

    send_operation_update "scan result=$result"

    if {$result == "0 0 0"} {
        move $motorName to $save_POS
        wait_for_devices $motorName
        log_error inline camera autofocus failed
        return -code error FAILED
    }
    set center [lindex $result 0]
    move $motorName to $center
    wait_for_devices $motorName
    send_operation_update "inline camera autofocus result=$center"

    save_operation_log inline_focus_orig $save_POS
    save_operation_log inline_focus_new $center
    save_operation_log inline_focus_diff [expr $center - $save_POS]
}
