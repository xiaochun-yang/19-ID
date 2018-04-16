proc dstream_bpm_optimize_initialize {} {
}

proc dstream_bpm_optimize_start { } {

        #motion to optimaze BPM2 value 2_0_sa_y_mon and 2_0_sa_x_mon
        variable optic_vert
        variable optic_horz
	variable gonio_phi

        #horizontal and vertical PV of BPM2 near the sample
        read_ion_chambers 1 downstram_bpm
        wait_for_devices downstram_bpm
        set bpm [get_ion_chamber_counts downstram_bpm]
	puts "yangx bpm value=$bpm"

        #First align the BPM2 near the sample position
        #loop to read the following values
        set step 0.001
        #Center the beam on vertical direction on BPM2
        #foreach {mt} [list mon optic_vert optic_horz] { 
            while 1 {
                set temp $bpm
                set mt gonio_phi

                #compare current 2_0_sa_y_mon with 0 
                if { abs($bpm - 0) < 0.005 } {
                        break
                }

                if {$bpm < 0} {
                        set step -$step
                }
                #move motor in step
                move mt by $step
                wait_for_devices mt

                #wait for 300 ms and read the bpm value
                after 300
                read_ion_chambers 1 downstram_bpm
                wait_for_devices downstram_bpm
                set bpm [get_ion_chamber_counts downstram_bpm]

	        puts "yangx new bpm value=$bpm"
                if {$bpm > 0} {
                        if { [expr $temp - $bpm] > $temp } {
                                set step [expr $step*0.5]
                        }
                } else {
                        if { [expr $temp - $bpm] < $temp } {
                                set step [expr $step*0.5]
                        }
                }
           }
        #}
}

