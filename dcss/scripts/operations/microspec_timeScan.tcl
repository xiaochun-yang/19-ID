proc microspec_timeScan_initialize { } {
}
proc microspec_timeScan_start { } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable microspec_timeScan_status

    set userName  [get_operation_user]
    set sessionId [get_operation_SID]
    set statusStringName microspec_timeScan_status

    if {[catch {
        spectrometerWrap_prepare
    } errMsg]} {
        log_error microspec time scan failed: $errMsg
        dict set $statusStringName message "time scan failed: $errMsg"
        return -code error $errMsg
    }

    #set startP   [dict get $microspec_timeScan_status start]
    set startP   0
    set endP     [dict get $microspec_timeScan_status end]
    set stepSize [dict get $microspec_timeScan_status step_size]
    set dir      [dict get $microspec_timeScan_status user_dir]
    set prefix   [dict get $microspec_timeScan_status user_prefix]
    set scan_dir [dict get $microspec_timeScan_status user_scan_dir]

    user_log_note microspec \
    "============$userName start time scan ${scan_dir}=============="
    user_log_note microspec "directory            $dir"
    user_log_note microspec "sub_dir_prefix       $prefix"
    #user_log_note microspec "start_time           $startP s"
    user_log_note microspec "end_time             $endP s"
    user_log_note microspec "step_size            $stepSize s"
    set gggg [user_log_get_motor_position gonio_phi]
    user_log_note microspec "gonio_phi            $gggg deg"

    set failed 0
    if {[catch {
        spectrometerWrap_basicScan time $startP $endP $stepSize
    } errMsg]} {
        set failed 1
        log_error microspec time scan failed: $errMsg
        user_log_error microspec time scan failed: $errMsg
        dict set $statusStringName message "time scan failed: $errMsg"
    }
    user_log_note microspec \
    "=========================end========================="
    cleanupAfterAll
    spectrometerWrap_moveLensOut
    lightsControl_start restore

    if {$failed} {
        return -code error $errMsg
    }
}
proc microspec_timeScan_cleanup { } {
    spectrometerWrap_cleanup
}
