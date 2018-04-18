proc test_bpm_optimize_initialize {} {
}

proc test_bpm_optimize_start { } {

	#set the motor steps to adjusted the bpm center
	#optic_vert optic_horz pitch and yaw
	#first number is a dummy
        set steps [list 0.00 0.004 0.004 0.0004 0.0004]

	#set index of the bpm PV. 1&2 bpm3 (near sample) 3&4 bpm2
	set j 1

        #foreach {mt} [list optic_vert optic_horz pitch yaw] {
        foreach {mt} [list gonio_phi spare_1 spare_2] {

	   #i controls the number of optimization steps 
	   set i 1

	   #Get the bpm PV value
       	   read_ion_chambers 1 sample_bpm$j
           wait_for_devices sample_bpm$j
           set temp [get_ion_chamber_counts sample_bpm$j]
	   set step [lindex steps $j]	 
	   #puts "yangx bpm j=$j  temp = $temp motor = $mt step = $step"

	   #start the optimization 
           while 1 {
		#set limits of optimization steps
		if { $i > 3 } {
			break
		}

                #compare current bpm value. Beam center value is 0 
		#current bpm setting 10000 counts is about 1um
                if { abs($temp - 0) < 10000 } {
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
		# if the motor step size is too small. quit from
		# the optimization
		if {$j<3 && $step < 0.001} {
			break
		} else if {$j>2 && $step < 0.0001} {
			break

		set temp $bpm
		incr i
         }
	 incr j
      }
}

