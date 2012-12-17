rename puts native_puts
close stderr
open /dev/null a+
close stdout
open /dev/null a+
close stdin
open /dev/null a+
proc puts { args } {
    set argc [llength $args]
    if {$argc >= 3} {
        #channel_id present, must be writing to a file or socket
        eval native_puts $args
        return
    }
    if {$argc == 2 && [lindex $args 0] != "-nonewline"} {
        eval native_puts $args
        return
    }

    ##### re-direct to log #######

    set msg [lindex $args 0]
    if {$msg == "-nonewline"} {
        set msg [lindex $args 1]
    }

    log_puts INFO $msg
}
proc log_puts { type msg } {
    variable log_file_counter
    global beamline

    if {[info exists beamline]} {
        set prefix ${beamline}_simdhs_log_
    } else {
        set prefix simdhs_log_
    }

    if {![info exists log_file_counter]} {
        set log_file_counter [get_log_file_counter . $prefix txt]
    }
    if {$log_file_counter > 19} {
        set log_file_counter 0
    }
    set log_file_name ${prefix}${log_file_counter}.txt
    catch {
        if {[file size $log_file_name] > 30000000} {
            file delete -force $log_file_name
        }
    }

    if {![catch {open $log_file_name a} h]} {
        set timestamp [clock format [clock seconds] -format "%d %b %Y %X"]
        catch {native_puts $h "$timestamp $type $msg"}
        close $h
    }
    ####
    if {[file size $log_file_name] > 30000000} {
        incr log_file_counter
    }
}
