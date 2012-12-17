proc loadPreAmpLUT_initialize { } {
    namespace eval ::preampLUT { 
        array set lut_horz [list]
        array set lut_vert [list]

        set lut_loaded 0
    }
    loadPreAmpLUT_start \
    /usr/local/dcs/BL12-2/preamp_h.txt \
    /usr/local/dcs/BL12-2/preamp_v.txt
}
proc loadPreAmpLUT_start { h_file v_file } {
    variable ::preampLUT::lut_horz
    variable ::preampLUT::lut_vert
    variable ::preampLUT::lut_loaded

    if {$h_file == "NULL"} {
        set h_file "/usr/local/dcs/BL12-2/preamp_h.txt"
        send_operation_update "using default H file"
    }
    if {$v_file == "NULL"} {
        set v_file "/usr/local/dcs/BL12-2/preamp_v.txt"
        send_operation_update "using default V file"
    }

    set lut_loaded 0

    PAS_loadLUT lut_horz $h_file
    PAS_loadLUT lut_vert $v_file
    if {![array exists lut_horz]} {
        puts "premap_lut_horz NOT EXISTS at 2"
    }
    set lut_loaded 1
}

##### the file should be like this
#mono_theta attenuation sensitivity_setting dial_reading

#not sorted at all is OK
#but mono_theta must be grouped values

# it find the neighbor 2 mono_theta
# linear interpolate the attenuation for those 2 groups
# then linear interpolate the mono_theta

###sort by first column then second column
proc PAS_sort_cmd { e1 e2 } {
    foreach {c11 c12} $e1 break
    foreach {c21 c22} $e2 break

    if {$c11 > $c21} {
        return 1
    }
    if {$c11 < $c21} {
        return -1
    }
    if {$c12 > $c22} {
        return 1
    }
    if {$c12 < $c22} {
        return -1
    }
    log_error duplicate lines: $e1 $e2
    return 0
}

proc PAS_loadLUT { lut_ref filename } {
    upvar $lut_ref tt
    array unset tt

    if {[catch {open $filename r} fh ] } {
        log_error failed to open file $filename to read
        return
    }

    ##read the whole file
    set lines [list]
    set i 0
    while {[gets $fh buffer] >= 0} {
        set line [string trim $buffer]
        if {[llength $line] >= 4 && [string index $line 0] != "#"} {
            lappend lines $line
            incr i
        }
    }
    close $fh
    puts "total lines: $i"

    ## sort the lines
    set lines [lsort -comman PAS_sort_cmd -unique $lines]

    set current_mt ""
    foreach line $lines {
        foreach {mt att pre dial} $line break
        ### 2.5 is perfect dial reading
        set v [expr $pre * $dial / 2.5]
        #set v $pre

        if {$current_mt != $mt} {
            lappend tt(mt) $mt
            set current_mt $mt
        }
        lappend tt($mt,att) $att
        lappend tt($mt,v) $v
    }
    puts "mt list: $tt(mt)"
    puts "last mt list $tt($mt,att) $tt($mt,v)"
}
proc PAS_getNodes { vList v } {
    puts "getNodes $vList for $v"

    set v0 [lindex $vList 0]
    if {$v <= $v0} {
        puts "$v not greater than the smallest $v0"
        return [list 0 0 $v0 $v0]
    }
    set vLast [lindex $vList end]
    if {$v >= $vLast} {
        ## may need to convert to number
        puts "$v not less than the biggest $vLast"
        return [list end end $vLast $vLast]
    }
    set n1 0
    set v1 $v0
    set i 0
    foreach vV $vList {
        if {$v < $vV} {
            puts "found it at $i $vV"
            return [list $n1 $i $v1 $vV]
        } else {
            set n1 $i
            set v1 $vV
        }
        incr i
    }
    ## we are sure it is found
    log_error logical wrong
    return [list end end $vV $vV]
}

proc PAS_linearInterpolate { xList yList x } {
    foreach {n1 n2 x1 x2} [PAS_getNodes $xList $x] break

    set y1 [lindex $yList $n1]
    set y2 [lindex $yList $n2]

    if {$x1 == $x2} {
        set result [expr ($y1 + $y2) / 2.0]
    } else {
        set result [expr $y1 + ($y2 - $y1) * ($x - $x1) /( $x2 - $x1)]
    }
    return $result
}

proc PAS_convertUnits { number } {
    set uList [list pA/V nA/V uA/V mA/V]

    set i 0
    while {abs($number) >= 1000} {
        set number [expr $number / 1000]
        incr i
    }
    if {$i > 3} {
        log_error $number exceed max range
        return -code error "exceed max range"
    }
    set number [expr int($number)]

    return $number[lindex $uList $i]
}
proc PAS_convertToNumber { sens } {
    set number [string range $sens 0 end-4]

    set u [string index $sens end-3]

    switch -exact -- $u {
        m {
            set number [expr $number * 1000000000]
        }
        u {
            set number [expr $number * 1000000]
        }
        n {
            set number [expr $number * 1000]
        }
        p -
        default {
        }
    }
    return $number
}

##convert 1256 to 1000 {2000, 63}
###means:
## if no tweak, use 1000
## if tweak, use 2000 with 63%
proc PAS_autoScale { number } {
    set number [expr abs($number)]
    ###here we do not deal with $number < 1
    #### init scale
    set half 0.75
    set scale 1
    set previous $scale
    while {$number > $scale} {
        set previous $scale
        set digit [string index $scale 0]
        switch -exact -- $digit {
            2 {
                set half  [expr $scale * sqrt(2.5)]
                set scale [expr int($scale * 2.5)]
            }
            default {
                set half  [expr $scale * sqrt(2)]
                set scale [expr $scale * 2]
            }
        }
    }

    set tweak [expr int(100.0 * $number / $scale)]

    set previous [PAS_convertUnits $previous]
    set scale [PAS_convertUnits $scale]

    #log_warning DEBUG half=$half

    #return [list $scale [list $scale $tweak]]
    if {$number <= $half} {
        #log_warning DEBUG closer to previous $previous
        return [list $previous [list $scale $tweak]]
    } else {
        #log_warning DEBUG closer to scale $scale
        return [list $scale [list $scale $tweak]]
    }
}

proc PAS_interpolateLUT_raw { lut_ref mt att } {
    upvar $lut_ref lut

    ###search for columns
    foreach {n1 n2 mt1 mt2} [PAS_getNodes $lut(mt) $mt] break

    puts "for mt=$mt, get n1=$n1 n2=$n2 mt1=$mt1 mt2=$mt2"
    #log_warning for mt=$mt, get n1=$n1 n2=$n2 mt1=$mt1 mt2=$mt2

    ##interpolate attenuation for each mono_theta
    set v1 [PAS_linearInterpolate $lut($mt1,att) $lut($mt1,v) $att]
    set v2 [PAS_linearInterpolate $lut($mt2,att) $lut($mt2,v) $att]

    puts "linear interpolate: v1=$v1"
    puts "linear interpolate: v2=$v2"
    #log_warning "linear interpolate: v1=$v1"
    #log_warning "linear interpolate: v2=$v2"


    ###interpolate the mono_theta
    if {$mt1 == $mt2} {
        set result $v1
    } else {
        set result [expr $v1 + ($v2 - $v1) * ($mt - $mt1) / ($mt2 - $mt1)]
    }

    return $result
}

proc PAS_interpolateLUT { lut_ref mt att } {
    upvar $lut_ref lut

    set result [PAS_interpolateLUT_raw lut $mt $att]

    puts "raw_result: $result"
    #log_warning DEBUG result: $result
    set result [PAS_autoScale $result]
    puts "result: $result"
    #log_warning DEBUG result: $result
    return $result
}
