proc piezo_auto_peak_roll_initialize {} {
}

proc piezo_auto_peak_roll_start { } {


	#ion_chamber4:pitch piezo;
	#mono_fine_pitch -- vale of ion_chamber4
        #ion_chamber5:roll piezo;
	#mono_fine_roll -- value of ion_chamber5
        #ion_chamber6:beampath ion_chamber
	#analog_input1 -- value of ion_chamber6

	#check the current voltage on the piezo
	get_encoder ion_chamber5
	set volt [wait_for_encoder ion_chamber5]
	if {$volt < 1 || $volt >9} {
		set_encoder ion_chamber5 5.0
	}
	
	#the piezo voltage range 0 -- 10V
	# First move to upper boundry slowly
	while { $volt < 10} {

		set volt [expr $volt + 0.5]
		set_encoder ion_chamber5 $volt
		wait_for_encoder ion_chamber5
		after 200
	}

	#Start peak search
	set optimaVolt $volt
	set optimaValue 0
	set step 0.2
	
	while {$volt > 0} {
		#set piezo voltage
		set volt [expr $volt - $step]
		set_encoder ion_chamber5 $volt
		wait_for_encoder ion_chamber5
		after 200

		#read the ion chamber value
		get_encoder ion_chamber6
		set ion_value [wait_for_encoder ion_chamber6]
		if { $ion_value > $optimaValue} {
			set optimaValue $ion_value
			set optimaVolt $volt
			puts "yangx optimaVolt=$optimaVolt optimaValue=$optimaValue"
		}
	}
	
	#due to historices of the piezo. now moving piezo slowly
	#to it's peak voltage
	set step 0.2
	set optimaVolt [expr $optimaVolt + $step]
	while { $volt < $optimaVolt } {
		set volt [expr $volt + $step]
		set_encoder ion_chamber5 $volt
		wait_for_encoder ion_chamber5
		after 100
	}
}

