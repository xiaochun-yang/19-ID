proc robotCassetteState_initialize { } {
    variable cassette_dump_file
    if {[llength $cassette_dump_file] < 3} {
        set cassette_dump_file [list {} {} {}]
    }
}

proc robotCassetteState_start { subCmd cas args } {
    switch -exact -- $subCmd {
        backup {
            robotCS_backup $cas $args
        }
        restore {
            robotCS_restore $cas $args
        }
    }
}
proc robotCS_backup { cas args } {
    variable robot_cassette
    variable cassette_dump_file

    set prefix [lindex $args 0]
    if {$prefix == ""} {
        set prefix \
        CasState[clock format [clock seconds] -format "%d%b%y%H%M%S"]
    }

    set left_file ""
    set middle_file ""
    set right_file ""
    switch -exact -- $cas {
        left {
            set left_file ${prefix}_left.txt
        }
        middle {
            set middle_file ${prefix}_middle.txt
        }
        right {
            set right_file ${prefix}_right.txt
        }
        all {
            set left_file ${prefix}_left.txt
            set middle_file ${prefix}_middle.txt
            set right_file ${prefix}_right.txt
        }
        default {
            return -code error "wrong cas: $cas"
        }
    }
    if {$left_file != ""} {
        set cassette_dump_file [lreplace $cassette_dump_file 0 0 $left_file]
        if {[catch {open $left_file w 0664} dmpChannel]} {
            return -code error "open file $left_file failed: $dmpChannel"
        }
        puts $dmpChannel [lrange $robot_cassette 0 96]
        close $dmpChannel
    }
    if {$middle_file != ""} {
        set cassette_dump_file [lreplace $cassette_dump_file 1 1 $middle_file]
        if {[catch {open $middle_file w 0664} dmpChannel]} {
            return -code error "open file $middle_file failed: $dmpChannel"
        }
        puts $dmpChannel [lrange $robot_cassette 97 193]
        close $dmpChannel
    }
    if {$right_file != ""} {
        set cassette_dump_file [lreplace $cassette_dump_file 2 2 $right_file]
        if {[catch {open $right_file w 0664} dmpChannel]} {
            return -code error "open file $right_file failed: $dmpChannel"
        }
        puts $dmpChannel [lrange $robot_cassette 194 end]
        close $dmpChannel
    }
}
proc robotCS_restore { cas args } {
    variable cassette_dump_file
    foreach {left_file middle_file right_file} $cassette_dump_file break

    set prefix [lindex $args 0]
    if {$prefix != ""} {
        set left_file ${prefix}_left.txt
        set middle_file ${prefix}_middle.txt
        set right_file ${prefix}_right.txt
    }
    switch -exact -- $cas {
        left {
            robotCS_restoreOne l $left_file
        }
        middle {
            robotCS_restoreOne m $middle_file
        }
        right {
            robotCS_restoreOne r $right_file
        }
        all {
            robotCS_restoreOne l $left_file
            robotCS_restoreOne m $middle_file
            robotCS_restoreOne r $right_file
        }
        default {
            return -code error "wrong cas: $cas"
        }
    }
}
proc robotCS_restoreOne { cas file } {
    if {[catch {open $file r} dmpChannel]} {
        return -code error "open file $file failed: $dmpChannel"
    }
    set line [gets $dmpChannel]
    close $dmpChannel
    if {[llength $line] == 97} {
        set hh [eval start_waitable_operation robot_config set_cassette_state $cas $line]
        wait_for_operation_to_finish $hh
    } else {
        return -code error "bad contents of file $file"
    }
}
