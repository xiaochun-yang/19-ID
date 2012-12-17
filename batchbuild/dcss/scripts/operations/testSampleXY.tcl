proc testSampleXY_initialize { } {
}

proc testSampleXY_start { num } {


    for {set i 0} {$i < $num} {incr i} {

        set xr [expr 1.8 * rand() - 0.9]
        set yr [expr 1.8 * rand() - 0.9]
        set zr [expr 4.0 * rand() - 2.0]
        set pr [expr 360.0 * rand() - 180.0]

        send_operation_update moving sample_xyz and phi to $xr $yr $zr $pr
        move sample_x to $xr
        move sample_y to $yr
        move sample_z to $zr
        move gonio_phi to $pr
        wait_for_devices sample_x sample_y sample_z gonio_phi

        read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
        wait_for_devices i_home_sample_x i_home_sample_y
        foreach {xOn yOn} [get_ion_chamber_counts i_home_sample_x i_home_sample_y] break
        if {abs($xr) > 0.1 && $xOn != 0} {
            send_operation_update error xHome wrong at $xr
            log_warning xHome wrong at $xr
        }
        if {abs($yr) > 0.1 && $yOn != 0} {
            send_operation_update error yHome wrong at $yr
            log_warning yHome wrong at $yr
        }

        send_operation_update moving back to 0
        move sample_x to 0
        move sample_y to 0
        move sample_z to 0
        wait_for_devices sample_x sample_y sample_z

        read_ion_chambers 1.0 i_home_sample_x i_home_sample_y
        wait_for_devices i_home_sample_x i_home_sample_y
        foreach {xOn yOn} [get_ion_chamber_counts i_home_sample_x i_home_sample_y] break
        if {$xOn != 0 && $yOn != 0} {
            send_operation_update done $i of $num
        } else {
            send_operation_update done $i of $num error xOn: $xOn yOn: $yOn
        }

        simCollect
    }
}


proc simCollect { } {
    variable gonio_phi

    set delta [expr rand() * 1.0 + 0.1]
    set expTime [expr rand() * 5.0 + 0.1 ]

    send_operation_update expose 30 at delta $delta and $expTime $expTime

    set start $gonio_phi
    for {set i 0} {$i<5} {incr i} {
        move gonio_phi to [expr $start + $i * $delta]
        set handle [start_waitable_operation expose gonio_phi shutter $delta $expTime]
        wait_for_operation $handle
    }

}
