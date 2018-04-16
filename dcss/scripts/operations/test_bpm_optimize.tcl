proc test_bpm_optimize_initialize {} {
}

proc test_bpm_optimize_start { } {

        #motion to optimaze BPM2 value 2_0_sa_y_mon and 2_0_sa_x_mon
        variable optic_vert
        variable optic_horz
	variable gonio_phi

        #horizontal and vertical PV of BPM2 near the sample
        read_ion_chambers 1 bpmDownStream
        wait_for_devices bpmDownStream
        set bpm [get_ion_chamber_counts bpmDownStream]

        #First align the BPM2 near the sample position
        #loop to read the following values
        #set step 0.001
        set step 1
        #Center the beam on vertical direction on down stream BPM
	set i 1
        #foreach {mt} [list mon optic_vert optic_horz] { 
        while 1 {
		if { $i > 5 } {
			break
		}
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
                move $mt by $step
                wait_for_devices $mt

                #wait for 300 ms and read the bpm value
                after 300
                read_ion_chambers 1 bpmDownStream
                wait_for_devices bpmDownStream
                set bpm [get_ion_chamber_counts bpmDownStream]

	        puts "yangx bpm loop = $i temp = $temp bpm = $bpm"
                if {$bpm > 0} {
                        if { [expr $temp - $bpm] > $temp } {
                                set step [expr $step*0.5]
                        }
                } else {
                        if { [expr $temp - $bpm] < $temp } {
                                set step [expr $step*0.5]
                        }
                }
		incr i
         }
      #}
}

