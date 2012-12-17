package require DCSUtil

proc scan_n_motors_initialize {} {
} 

proc scan_n_motors_start {directory filename numberOfScans scanList } {

    ###check input
    if {$numberOfScans <= 0} {
        log_error numberOfScans <= 0
        return -code error "numberOfScans <= 0"
    }

    if {[llength $scanList] <= 0} {
        log_error no scan defined
        return -code error "no scan defined"
    }
    foreach scanDef $scanList {
        if {[llength $scanDef] != 8} {
            log_error bad scan definition $scanDef
            return -code error "bad scan definition"
        }
    }

    set sessionId "PRIVATE[get_operation_SID]"
    set username [get_operation_user]

    for {set cnt 0} {$cnt < $numberOfScans} {incr cnt} {
        foreach scanDef $scanList {
            foreach \
            {motor points start end units signal time sleep} $scanDef break

            set sleep [expr int($sleep)]

            set motor1Def [list $motor $points $start $end 0 $units]
            set motor2Def ""

            set motorDef [list [list $motor1Def $motor2Def]]
            set detectors [list $signal]
            set filters [list ""]
            ############ integrationTime settleTime numScan delay
            set timing [list [list $time 0 1 0]]
            set prefix [list [list $directory ${filename}_$motor $cnt]]

            set h [start_waitable_operation scanMotor $username $sessionId \
            $motorDef $detectors $filters $timing $prefix]
            wait_for_operation_to_finish $h
            wait_for_time $sleep
        }
    }
}
