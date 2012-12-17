proc impTest_initialize { } {
}
proc impTest_start { num } {
    variable beamlineID
    set user [get_operation_user]
    set sessionID PRIVATE[get_operation_SID]
    set filename /data/$user/imp${beamlineID}IMPERSONTEST.txt

    for {set i 0} {$i < $num} {incr i} {
	    set scriptInfo [get_script_info]
	    if { [lindex $scriptInfo 2] == "aborted" } {
		    return -code error aborted
	    }
        if {[get_operation_stop_flag]} {
            break
        }
        set oneLine "${i} line line line line line line line line line line\n"
        impAppendTextFile $user $sessionID $filename $oneLine
    }
}
