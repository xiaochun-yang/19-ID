proc bpm_optimize_initialize {} {
}

proc bpm_optimize_start { } {

	#set the motor steps to adjusted the bpm center
	#optic_vert optic_horz pitch and yaw
	#first number is a dummy
        set steps [list 0.00 0.004 0.004 0.0004 0.0004]

	#set index of the bpm PV
	set j 1

	#should be optic_vert optic_horz phi yaw
        foreach {mt} [list optic_vert] {

	   #i controls the number of optimization steps 
	   #k cpntrols step settings
	   set lp_index 1
	   set bpm_limit 44000

	   #Get the bpm PV value
       	   read_ion_chambers 1 sample_bpm$j
           wait_for_devices sample_bpm$j
           set temp [get_ion_chamber_counts sample_bpm$j]
	   set step [lindex $steps $j]	 
	   puts "yangx bpm j=$j  temp = $temp motor = $mt step = $step"

	   #start the optimization 
           while 1 {
		#set loop limit to prevent the dead loop
		if { $lp_index > 30 } {
			puts "Can not optimize bpm after $lp_index tries by moving $mt"
			break
		}

                #compare current bpm value. Beam center value is 0 
		#for the current bpm, 1um motion result 10000 counts 
		#change. so we stop the optimaztion when it less than 
		#10000 counts 
                if { abs($temp) < 10000 } {
			puts "yangx close enough break"
                        break
                }

                #move motor in step
                move $mt by $step
                wait_for_devices $mt

                #wait for 300 ms and read the bpm value
                after 300
                read_ion_chambers 1 sample_bpm$j
                wait_for_devices sample_bpm$j
                set bpm [get_ion_chamber_counts sample_bpm$j]

	        puts "yangx bpm motor=$mt i = $lp_index temp = $temp bpm = $bpm"

		#Change step size based on bpm counts 
		if {abs([expr $temp -$bpm]) < $bpm_limit} {
                	set step [expr $step*0.5]
			set bpm_limit [expr $bpm_limit*0.5]
		}

		#change step sign based on the current and previous bpm values.
                if { ($temp >0 && $bpm > 0) || ($temp < 0 && $bpm <0) } {
                        if { abs($temp) < abs($bpm) } {
				set step [expr $step*-1]
			}
                } elseif { ($temp > 0 && $bpm < 0) || ($temp < 0 && $bpm > 0) } {
                        set step [expr $step*-1]
		}

		# if the motor step size is too small. quit from
                # the optimization
		if {$j<3 && abs($step) < 0.001} {
			puts " yangx step is too small break"
                        break
                } elseif {$j>2 && abs($step) < 0.0001} {
			puts "yangx step is too small break"
                        break
                }
		set temp $bpm
		incr lp_index
         }
	 incr j
      }
}

