proc microspec_snapshot_initialize { } {
}
proc microspec_snapshot_start { } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable microspec_snapshot_status

    set userName  [get_operation_user]
    set sessionId [get_operation_SID]
    set statusStringName microspec_snapshot_status

    if {[catch {
        spectrometerWrap_prepare
    } errMsg]} {
        log_error microspec snapshot failed: $errMsg
        dict set $statusStringName message "snapshot failed: $errMsg"
        return -code error $errMsg
    }

    set dir      [dict get $microspec_snapshot_status user_dir]
    set prefix   [dict get $microspec_snapshot_status user_prefix]
    set scan_dir [dict get $microspec_snapshot_status user_scan_dir]

    user_log_note microspec \
    "============$userName start snapshot ${scan_dir}=============="
    user_log_note microspec "directory            $dir"
    user_log_note microspec "sub_dir_prefix       $prefix"
    set gggg [user_log_get_motor_position gonio_phi]
    user_log_note microspec "gonio_phi            $gggg deg"

    set failed 0
    if {[catch {
        spectrometerWrap_basicScan snapshot 0 0 0
    } errMsg]} {
        set failed 1
        log_error microspec snapshot failed: $errMsg
        user_log_error microspec snapshot failed: $errMsg
        dict set $statusStringName message "snapshot failed: $errMsg"
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
proc microspec_snapshot_cleanup { } {
    spectrometerWrap_cleanup
}
