#!/usr/bin/tclsh
proc PAS_sort_cmd { e1 e2 } {
    ##### we sort on energy and table_vert, not on energy and slit_peak.
    ##### this way the software can deal with falling off at the end of
    ##### curves.
    ##### 

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
    puts "warning duplicate lines: $e1 $e2"
    return 0
}
proc PAS_getNodes { vList v } {
    #puts "getNodes $vList for $v"

    set v0 [lindex $vList 0]
    if {$v <= $v0} {
        puts "WARNING $v not greater than the smallest $v0"
        return [list 0 0 $v0 $v0]
    }
    set vLast [lindex $vList end]
    if {$v >= $vLast} {
        ## may need to convert to number
        puts "WARNING$v not less than the biggest $vLast"
        return [list end end $vLast $vLast]
    }
    set n1 0
    set v1 $v0
    set i 0
    foreach vV $vList {
        if {$v < $vV} {
            #puts "found it at $i $vV"
            return [list $n1 $i $v1 $vV]
        } else {
            set n1 $i
            set v1 $vV
        }
        incr i
    }
    ## we are sure it is found
    puts "error: logical wrong"
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
proc generate_table_vert { filename desired_peak } {
    ### generate output file name
    set out_fn [file tail $filename]
    set out_fn [file root $out_fn]
    append out_fn _RESULT


    set fh [open $filename r]
    
    ##skip 2 lines
    gets $fh
    gets $fh

    ### check motor names
    set motorDef1 [gets $fh]
    set motorDef2 [gets $fh]

    set motor1 [lindex $motorDef1 2]
    set motor2 [lindex $motorDef2 2]

    if {$motor1 != "energy" || $motor2 != "table_vert"} {
        puts "wrong scan file or you change the scripts"
        close $fh
        exit
    }

    #### read the file in
    ### copied from loadPreAmpLUT
    set lines [list]
    set i 0
    while {[gets $fh buffer] >= 0} {
        set line [string trim $buffer]
        if {[llength $line] >= 3 && [string index $line 0] != "#"} {
            lappend lines $line
            incr i
        }
    }
    close $fh
    puts "total lines: $i"

    ## sort the lines
    set lines [lsort -comman PAS_sort_cmd -unique $lines]

    set current_e ""
    foreach line $lines {
        foreach {e tv peak} $line break
        if {$current_e != $e} {
            lappend tt(e) $e
            set current_e $e
        }
        lappend tt($e,tv) $tv
        lappend tt($e,peak) $peak
    }
    #puts "e list: $tt(e)"
    #puts "last e list $tt($e,tv) $tt($e,peak)"

    ########################
    #### interpolate

    set output_peakList ""
    foreach e $tt(e) {
        set output_peak [PAS_linearInterpolate $tt($e,peak) $tt($e,tv) $desired_peak]
        lappend output_peakList $output_peak
    }

    ####output
    set fh [open $out_fn w]
    puts "================ result in file $out_fn =================="
    puts "energy        table_vert"
    puts $fh " energy        table_vert"
    foreach e $tt(e) p $output_peakList {
        set line [format "%-9.2f     %-8.4f" $e $p]
        puts $line
        puts $fh $line

    }
    close $fh
}

if {[llength $argv] != 2} {
    puts "wrong arguments, should be filename and desired_peak_position"
    exit
}

set fn [lindex $argv 0]
set dp [lindex $argv 1]

generate_table_vert $fn $dp
