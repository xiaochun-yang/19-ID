###################################################
# This operation will use results of rastering to find weighted center of
# the matrix.
# The input can be a raster file path or raster_run number
package require DCSRaster
::DCS::Raster4DCSS gRaster4Center
proc centerRaster_initialize { } {
    namespace eval centerRaster {
        ### 50% cut between max and min (not count "0")
        set cut_off 0.5

        ### use num spots to calculate
        set field_index 0
    }
}
###
# cmd = move, sample_position, projection_position
proc centerRaster_start { cmd path_or_number background_cutoff_percent } {
    variable ::rasterRunsConfig::dir
    variable centerRaster::cut_off
    variable sample_x
    variable sample_y
    variable sample_z
    variable gonio_phi
    variable gonio_omega

    set cut_off [expr $background_cutoff_percent / 100.0]

    ##### get path from raster
    if {[string is integer -strict $path_or_number]} {
        variable raster_run$path_or_number
        set rr [set raster_run$path_or_number]
        set path [lindex $rr 2]
        set status [lindex $rr 0]
        switch -exact $status {
            inactive -
            collecting {
                log_error wrong status $status for raster $path_or_number
                return -code error wrong_raster_status
            }
            paused -
            complete -
            skipped {
            }
        }
    } else {
        set path $path_or_number
    }

    if {$path == "" || $path == "not_exists"} {
        log_error raster not ready
        return -code error raster_not_exists
    }

    #### absolute path
    set firstChar [string index $path 0]
    if {$firstChar != "/" && $firstChar != "~"} {
        set path [file join $dir $path]
    }
    send_operation_update path=$path

    ### loading file into class
    gRaster4Center load -1 $path

    set my_x $sample_x
    set my_y $sample_y
    set my_z $sample_z
    set my_phi $gonio_phi

    set proj_position ""

    for {set v 0} {$v < 2} {incr v} {
        foreach {defined setup info} [gRaster4Center getView$v] break
        if {!$defined} {
            continue
        }
        set viewStatus [lindex $info 0]
        if {$viewStatus == "" || [string first "ing" $viewStatus] >= 0} {
            log_error view[expr $v + 1] not ready, busy
            return -code error RASTER_VIEW_NOT_READY
        }
        set angle  [lindex $setup 3]
        set numRow [lindex $setup 6]
        set numCol [lindex $setup 7]
        set nodeInfo [lrange $info 1 end]
        set ll [llength $nodeInfo]
        if {$ll != $numCol * $numRow} {
            log_error corrupted data num row: $numRow col: $numCol ll=$ll
            return -code error BAD_DATA
        }
        send_operation_update "num: row=$numRow col=$numCol"
        set weightList ""
        centerRaster_weightFilter $numRow $numCol $nodeInfo weightList
        foreach {center_row center_column \
        crystal_height_row crystal_width_column \
        start_row end_row start_col end_col} \
        [centerRaster_findStrongestCrystal $numRow $numCol weightList] break
        send_operation_update "view$v row col: $center_row $center_column"
        #### row col start from 0 not centered
        set proj_h [expr $center_column - ($numCol - 1) / 2.0]
        set proj_v [expr $center_row - ($numRow - 1) / 2.0]
        send_operation_update "view$v proj: $proj_v $proj_h"
        send_operation_update "view$v setup: $setup"
        lappend proj_position [list $proj_v $proj_h]
        foreach {dx dy dz} \
        [calculateSamplePositionDeltaFromProjection \
        $setup \
        $my_x $my_y $my_z \
        $proj_v $proj_h] break

        send_operation_update "view$v my $my_x $my_y $my_z"
        set my_x [expr $my_x + $dx]
        set my_y [expr $my_y + $dy]
        set my_z [expr $my_z + $dz]
        set my_phi [expr $angle - $gonio_omega]
        send_operation_update "view$v dd: $dx $dy $dz"
        
    }
    if {[llength $proj_position] > 1} {
        set tolerance [expr int(ceil($numCol * 0.2))]
        if {$tolerance < 1} {
            set tolerance 1
        }
        foreach {pp0 pp1} $proj_position break
        set proj_h0 [lindex $pp0 1]
        set proj_h1 [lindex $pp1 1]
        if {abs($proj_h1 - $proj_h0) > $tolerance} {
            log_error too much difference in horizontal of between peaks on 2 views
            log_error proj_h0=$proj_h0 proj_h1=$proj_h1 tolerance=$tolerance
            return -code error BAD_PEAK
        }
    }

    if {$cmd == "projection_position"} {
        return $proj_position
    }
    if {$cmd == "move"} {
        move sample_x to $my_x
        move sample_y to $my_y
        move sample_z to $my_z
        move gonio_phi to $my_phi
        wait_for_devices sample_x sample_y sample_z gonio_phi
    }
    return [list $my_x $my_y $my_z]
}

#######################################################################
### copied and modified from centerCrystal
### simple cut.  You can add smooth if you want to. It will not improve
### weighted center results.
### 
proc centerRaster_weightFilter {num_row num_column raw_list weightListRef} {
    variable centerRaster::cut_off
    variable centerRaster::field_index
    upvar $weightListRef result

    ### find max min
    set max -999999999
    set min 999999999
    foreach scores $raw_list {
        set w [lindex $scores $field_index]
        if {[string is double -strict $w]} {
            if {$w > $max} {
                set max $w
            }
            if {$w < $min} {
                set min $w
            }
        }
    }

    set vCutOff [expr $min + $cut_off * ($max - $min)]
    ### % cutoff will make sure the results are all non-negative
    ### we can use 0 to represent N/A

    set result [list]
    foreach scores $raw_list {
        set w [lindex $scores $field_index]
        if {[string is double -strict $w] && $w > $vCutOff} {
            lappend result [expr $w - $vCutOff]
        } else {
            lappend result 0
        }
    }
}

proc centerRaster_matrixCalculation { num_row num_column weight_list \
start_row end_row start_col end_col \
resultRef rowWeightRef columnWeightRef } {
    upvar $resultRef result
    upvar $rowWeightRef row_weight
    upvar $columnWeightRef column_weight

    array unset resultArray

    puts "row $start_row $end_row col: $start_col $end_col"

    set sum 0.0
    set center_row 0.0
    set center_column 0.0
    for {set row 0} {$row < $num_row} {incr row} {
        set row_weight($row) 0
    }
    for {set col 0} {$col < $num_column} {incr col} {
        set column_weight($col) 0
    }

    set max_weight 0
    set row_of_peak $start_row
    set column_of_peak $start_col
    for {set row $start_row} {$row <= $end_row} {incr row} {
        for {set col $start_col} {$col <= $end_col} {incr col} {
            set offset [expr $row * $num_column + $col]
            set weight [lindex $weight_list $offset]

            set center_row [expr $center_row + $row * $weight]
            set center_column [expr $center_column + $col * $weight]
            set sum [expr $sum + $weight]

            set row_weight($row) [expr $row_weight($row) + $weight]
            set column_weight($col) [expr $column_weight($col) + $weight]

            if {$weight > $max_weight} {
                set max_weight $weight
                set row_of_peak $row
                set column_of_peak $col
            }
        }
    }
    if {$sum > 0} {
        set center_row [expr $center_row / $sum]
        set center_column [expr $center_column / $sum]
    } else {
        ####should not be here
        set center_row [expr $num_row / 2.0]
        set center_column [expr $num_column / 2.0]
        log_error "all image quality is 0"
    }

    ### save result
    set result(total) $sum
    set result(peak) $max_weight
    set result(peak_row) $row_of_peak
    set result(peak_column) $column_of_peak
    set result(center_row) $center_row
    set result(center_column) $center_column

    puts "DEBUG: peak:   $result(peak_row) $result(peak_column)"
    puts "DEBUG: center: $result(center_row) $result(center_column)"

}

proc centerRaster_findStrongestCrystal {num_row num_column weightListREF} {
    upvar $weightListREF weight_list

    array set column_weight [list]
    array set row_weight [list]
    array set summary [list]

    set start_row 0
    set end_row [expr $num_row - 1]
    set start_col 0
    set end_col [expr $num_column - 1]

    while {1} {
        centerRaster_matrixCalculation $num_row $num_column $weight_list \
        $start_row $end_row $start_col $end_col \
        summary row_weight column_weight

        ###################################################
        ### check multiple crystal
        set isZero 1
        set numCrystalVert 0
        for {set row $start_row} {$row <= $end_row} {incr row} {
            if {$row_weight($row) > 0} {
                if {$isZero} {
                    incr numCrystalVert
                    set isZero 0
                }
            } else {
                set isZero 1
            }
        }

        set isZero 1
        set numCrystalHorz 0
        for {set col $start_col} {$col <= $end_col} {incr col} {
            if {$column_weight($col) > 0} {
                if {$isZero} {
                    incr numCrystalHorz
                    set isZero 0
                }
            } else {
                set isZero 1
            }
        }

        #### find boundary starting from max until 0
        for {set row $summary(peak_row)} {$row >= $start_row} {incr row -1} {
            if {$row_weight($row) == 0} {
                break
            }
        }
        set start_row [expr $row + 1]
        for {set row $summary(peak_row)} {$row <= $end_row} {incr row} {
            if {$row_weight($row) == 0} {
                break
            }
        }
        set end_row [expr $row - 1]
        puts "new row: $start_row $end_row"

        #### find boundary starting from max until 0
        for {set col $summary(peak_column)} {$col >= $start_col} {incr col -1} {
            if {$column_weight($col) == 0} {
                break
            }
        }
        set start_col [expr $col + 1]
        for {set col $summary(peak_column)} {$col <= $end_col} {incr col} {
            if {$column_weight($col) == 0} {
                break
            }
        }
        set end_col [expr $col - 1]
        puts "new col: $start_col $end_col"

        if {$numCrystalVert <= 1 && $numCrystalHorz <= 1} {
            break
        }
        puts "numCrystal: vert=$numCrystalVert horz=$numCrystalHorz"
        log_warning maybe multiple crystals
        puts "WARNING: maybe multiple crystals"
        ### loopback to check again
    }

    set max_row_weight 0
    for {set row $start_row} {$row <= $end_row} {incr row} {
        if {$row_weight($row) > $max_row_weight} {
            set max_row_weight $row_weight($row)
        }
    }

    set crystal_height_row 0.0
    for {set row $start_row} {$row <= $end_row} {incr row} {
        set crystal_height_row \
        [expr $crystal_height_row + 1.0 * $row_weight($row) / $max_row_weight]
    }

    set max_column_weight 0
    for {set col $start_col} {$col <= $end_col} {incr col} {
        if {$column_weight($col) > $max_column_weight} {
            set max_column_weight $column_weight($col)
        }
    }
    set crystal_width_column 0.0
    for {set col $start_col} {$col <= $end_col} {incr col} {
        set crystal_width_column [expr $crystal_width_column \
        + $column_weight($col) / double($max_column_weight)]
    }

    if {abs($summary(peak_row) - $summary(center_row)) > 1} {
        log_warning Weighted center is off from peak in row
    }
    if {abs($summary(peak_column) - $summary(center_column)) > 1} {
        log_warning Weighted center is off from peak in column
    }

    return [list \
    $summary(center_row) $summary(center_column) \
    $crystal_height_row $crystal_width_column \
    $start_row $end_row $start_col $end_col \
    ]
}

