#this operation is for scripted ion chamber
proc microSpectIon_initialize {} {
}

proc microSpectIon_start { time_in_second } {
    variable spectro_integration
    variable microSpectIon_const

    if {abs($time_in_second - $spectro_integration) > 0.001} {
        move spectro_integration to $time_in_second
        wait_for_devices spectro_integration
    }

    set oph [start_waitable_operation get_spectrum 1]
    set opr [wait_for_operation_to_finish $oph]
    foreach {status rawWList rawCList} $opr break

    set resultList ""
    foreach windowDef $microSpectIon_const {
        set rr [microSpectIon_sum $rawWList $rawCList $windowDef]
        lappend resultList $rr
    }
    return $resultList
}
proc microSpectIon_sum { wList cList param } {
    set start_endList [microSpectIon_findIndex $wList $param]
    puts "param={$param}, winList={$start_endList}"

    ## this method is slow but robust, can deal with overlapped windows.
    set sum 0.0
    set i -1
    foreach count $cList {
        incr i
        if {[microSpectIon_inWindow $i $start_endList]} {
            set sum [expr $sum + $count]
        }
    }
    return [expr -1 * $sum]
}
proc microSpectIon_findIndex { wList param } {
    set result ""
    foreach wavelength $param {
        set i 0
        foreach w $wList {
            if {$wavelength <= $w} {
                break
            }
            incr i
        }
        lappend result $i
    }
    return $result
}
proc microSpectIon_inWindow { index windowList } {
    foreach {start end} $windowList {
        if {$start > $end} {
            set nn start
            set start $end
            set end   $nn
        }
        if {$index >= $start && $index <= $end} {
            return 1
        }
    }
    return 0
}
