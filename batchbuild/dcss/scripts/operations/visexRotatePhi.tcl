#####
### rotate phi and then take visex snapshot
proc visexRotatePhi_initialize { } {
}
proc visexRotatePhi_start { delta } {
    variable visex_snapshot_orig
    variable visex_snapshot_nocheck
    set visex_snapshot_nocheck 1

    set from [lindex $visex_snapshot_orig 8]
    move gonio_phi by $delta
    wait_for_devices gonio_phi

    videoVisexSnapshot_start $from
}
proc visexRotatePhi_cleanup { } {
    variable visex_snapshot_nocheck
    variable visex_msg

    set visex_snapshot_nocheck 0
    set visex_msg ""
}
