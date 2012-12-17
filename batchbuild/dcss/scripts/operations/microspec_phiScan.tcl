proc microspec_phiScan_initialize { } {
}
proc microspec_phiScan_start { } {
    variable ::spectrometerWrap::statusStringName
    variable ::spectrometerWrap::userName
    variable ::spectrometerWrap::sessionId
    variable microspec_phiScan_status

    set userName  [get_operation_user]
    set sessionId [get_operation_SID]
    set statusStringName microspec_phiScan_status

    if {[catch {
        spectrometerWrap_prepare
    } errMsg]} {
        log_error microspec phi scan failed: $errMsg
        dict set $statusStringName message "phi scan failed: $errMsg"
        return -code error $errMsg
    }

    set startP   [dict get $microspec_phiScan_status start]
    set endP     [dict get $microspec_phiScan_status end]
    set stepSize [dict get $microspec_phiScan_status step_size]
    set dir      [dict get $microspec_phiScan_status user_dir]
    set prefix   [dict get $microspec_phiScan_status user_prefix]
    set scan_dir [dict get $microspec_phiScan_status user_scan_dir]

    user_log_note microspec \
    "============$userName start phi scan ${scan_dir}=============="
    user_log_note microspec "directory            $dir"
    user_log_note microspec "sub_dir_prefix       $prefix"
    user_log_note microspec "start_phi            $startP deg"
    user_log_note microspec "end_phi              $endP deg"
    user_log_note microspec "step_size            $stepSize deg"

    set failed 0
    if {[catch {
        spectrometerWrap_basicScan gonio_phi $startP $endP $stepSize
    } errMsg]} {
        set failed 1
        log_error microspec phi scan failed: $errMsg
        user_log_error microspec phi scan failed: $errMsg
        dict set $statusStringName message "phi scan failed: $errMsg"
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
proc microspec_phiScan_cleanup { } {
    spectrometerWrap_cleanup
}
