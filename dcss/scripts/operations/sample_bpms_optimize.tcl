proc test_bpm_optimize_initialize {} {
}

proc test_bpm_optimize_start { } {

        #motion to optimaze BPM2 value 2_0_sa_y_mon and 2_0_sa_x_mon
        variable optic_vert
        variable optic_horz
	variable gonio_phi

        #First align the BPM2 near the sample position
        #loop to read the following values
        #set step 0.001
        set step 1
        #Center the beam on vertical direction on down stream BPM
	set j 1
        foreach {mt} [list gonio_phi spare_1 spare_2] {
 
	   set i 1
       	   read_ion_chambers 1 sample_bpm$j
           wait_for_devices sample_bpm$j
           set temp [get_ion_chamber_counts sample_bpm$j]
	   puts "yangx bpm j=$j  temp = $temp motor = $mt"
  
           while 1 {
		if { $i > 3 } {
			break
		}

                #compare current 2_0_sa_y_mon with 0 
                if { abs($temp - 0) < 0.005 } {
                        break
                }

                if {$temp < 0} {
                        set step -$step
                }

                #move motor in step
                move $mt by $step
                wait_for_devices $mt

                #wait for 300 ms and read the bpm value
                after 300
                read_ion_chambers 1 sample_bpm$j
                wait_for_devices sample_bpm$j
                set bpm [get_ion_chamber_counts sample_bpm$j]

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
		set temp $bpm
		incr i
         }
	 incr j
      }
}

