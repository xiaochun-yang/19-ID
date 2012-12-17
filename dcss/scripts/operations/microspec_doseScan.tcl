proc microspec_doseScan_initialize { } {
}
proc microspec_doseScan_start { } {
    global gMotorEnergy
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gWaitForGoodBeamMsg

    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId

    variable microspec_doseScan_status

    set userName  [get_operation_user]
    set sessionId [get_operation_SID]
    set statusStringName microspec_doseScan_status

    if {[catch {
        spectrometerWrap_prepare
    } errMsg]} {
        log_error microspec dose scan failed: $errMsg
        user_log_error microspec dose scan failed: $errMsg
        dict set $statusStringName message "dose scan failed: $errMsg"
        return -code error $errMsg
    }


    #set startP   [dict get $microspec_doseScan_status start]
    set startP   0
    set endP     [dict get $microspec_doseScan_status end]
    set stepSize [dict get $microspec_doseScan_status step_size]
    set dir      [dict get $microspec_doseScan_status user_dir]
    set prefix   [dict get $microspec_doseScan_status user_prefix]
    set scan_dir [dict get $microspec_doseScan_status user_scan_dir]

    set eeee     [dict get $microspec_doseScan_status energy]
    set aaaa     [dict get $microspec_doseScan_status attenuation]
    set wwww     [dict get $microspec_doseScan_status beam_width]
    set hhhh     [dict get $microspec_doseScan_status beam_height]
    set gggg     [dict get $microspec_doseScan_status gonio_phi]

    move $gMotorEnergy      to $eeee
    move $gMotorBeamWidth   to $wwww
    move $gMotorBeamHeight  to $hhhh
    move gonio_phi          to $gggg
    wait_for_devices $gMotorEnergy $gMotorBeamWidth $gMotorBeamHeight gonio_phi

    ### move this after moving energy is done
    move attenuation   to $aaaa
    wait_for_devices attenuation

    if {[catch correctPreCheckMotors errMsg]} {
        log_error failed to correct motors $errMsg
        log_error microspec dose scan failed: $errMsg
        dict set $statusStringName message "dose scan failed: $errMsg"
        return -code error $errMsg
    }

    set gWaitForGoodBeamMsg "microspec_doseScan_status key=message"
    if {![beamGood]} {
        wait_for_good_beam
    }
    set gWaitForGoodBeamMsg ""

    user_log_note microspec \
    "============$userName start dose scan ${scan_dir}=============="
    user_log_note microspec "directory            $dir"
    user_log_note microspec "sub_dir_prefix       $prefix"
    #user_log_note microspec "start_time           $startP s"
    user_log_note microspec "end_time             $endP s"
    user_log_note microspec "step_size            $stepSize s"

    set eeee [user_log_get_motor_position energy]
    set bbbb [user_log_get_motor_position beam_size]
    set aaaa [user_log_get_motor_position attenuation]
    set gggg [user_log_get_motor_position gonio_phi]
    user_log_note microspec "energy               $eeee ev"
    user_log_note microspec "attenuation          $aaaa %"
    user_log_note microspec "beam_size            $bbbb mm"
    user_log_note microspec "gonio_phi            $gggg deg"

    set errMsg ""
    if {[catch {
        spectrometerWrap_basicScan dose $startP $endP $stepSize
    } errMsg]} {
        log_error microspec dose scan failed: $errMsg
        user_log_error microspec dose scan failed: $errMsg
        dict set $statusStringName message "dose scan failed: $errMsg"
    }
    close_shutter shutter 1
    user_log_note microspec \
    "=========================end========================="
    cleanupAfterAll
    spectrometerWrap_moveLensOut
    lightsControl_start restore

    if {$errMsg != ""} {
        return -code error $errMsg
    }
}
proc microspec_doseScan_cleanup { } {
    spectrometerWrap_cleanup
}
