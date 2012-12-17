# Extract params for generating data collection strategy from dcss dump file

BEGIN {
	device = "";
	count = 0;
	type = 0;
	printing = 0;
	old = 0;
};

{	
	if ($0 == "detector_z_corr") {
		device = "detector_z_corr";
	} else if ($0 == "detector_z") {
		device = "detector_z";
	} else if ($0 == "detectorType") {
		device = "detectorType";
	} else if ($0 == "beamstop_z") {
		device = "beamstop_z";
	} else if ($0 == "beam_size_x") {
		device = "beam_size_x";
	} else if ($0 == "beam_size_y") {
		device = "beam_size_y";
	} else if ($0 == "energy") {
		device = "energy";
	} else if ($0 == "gonio_phi") {
		device = "gonio_phi";
	} else if ($0 == "attenuation") {
	        device = "attenuation";
	} else if ($0 == "flux") {
	        device = "flux";
	} else if ($0 == "beam_size_sample_x") {
		device = "beam_size_sample_x";
	} else if ($0 == "beam_size_sample_y") {
		device = "beam_size_sample_y";
	} else if ($0 == "collect_default") {
		device = "collect_default";
	} else if ($1 ~ /^run/ ) {
	  device = "run";
	} else if ($0 == "") {
		device = "";
		count = 0;
		type = 0;
		printing = 0;
		old = 0;
	}

	if (device != "") {
	
		# line number for this device
		count++;
		
		# Device type
		if (count == 2)
			type = $1;

		# Line number for data in old and new formats
		old_format_line = 4;
		if (type == 13) {
			new_format_line = 6;
		} else if (type == 1) {
			new_format_line = 7;
		} else if (type == 2) {
			new_format_line = 7;
		}
		
		# Check if it is in old or new format
		if (count == old_format_line) {
			if (length($0) != 9) {
				old = 1;
				printing = 1;
			} else {
				old = 0;
			}
		} else if (count == new_format_line) { # Check if it is in new format
			if (old == 0) {
				printing = 1;
			} else {
				printing = 0;
			}
		} else {
			printing = 0;
		}
				
		if (printing) {
			num = split($0, arr, " ");
			if (device == "detector_z_corr") {
				print "detector_z_corr " arr[1] " " arr[2] " " arr[3];
			} else if (device == "detector_z") {
				print "detector_z " arr[1] " " arr[2] " " arr[3];
			} else if (device == "detectorType") {
				print "detectorType " $0;
			} else if (device == "beamstop_z") {
				print "beamstop_z " arr[1] " " arr[2] " " arr[3];
			} else if (device == "beam_size_x") {
				print "beam_size_x " arr[1] " " arr[2] " " arr[3];
			} else if (device == "beam_size_y") {
				print "beam_size_y " arr[1] " " arr[2] " " arr[3];
			} else if (device == "energy") {
				print "energy " arr[1] " " arr[2] " " arr[3];
			} else if (device == "gonio_phi") {
				print "gonio_phi " arr[1] " " arr[2] " " arr[3] " " arr[4] " " arr[5] " " arr[6];
			} else if (device == "attenuation") {
				print "attenuation " arr[1];
			} else if (device == "flux") {
				print "flux " 1e+11*arr[1];
			} else if (device == "beam_size_sample_x") {
				print "beam_size_sample_x " arr[1] " " arr[2] " " arr[3];
			} else if (device == "beam_size_sample_y") {
				print "beam_size_sample_y " arr[1] " " arr[2] " " arr[3];
			} else if (device == "collect_default") {
				print "def_osc_range " arr[1];
				print "def_exposure_time " arr[2];
				print "def_attenuation " arr[3];
				if (num > 3) {
					print "min_exposure " arr[4];
					print "max_exposure " arr[5];
					print "min_attenuation " arr[6];
					print "max_attenuation " arr[7];
				} else {
					print "min_exposure";
					print "max_exposure";
					print "min_attenuation";
					print "max_attenuation";
				}
			} else if (device == "run") {
			        status = $1;
				if ((status == "collecting") || (status == "paused")) {
				        print "active_run "arr[1]" "arr[2]" "arr[3]" "arr[4]" "arr[5]" "arr[6]" "arr[7]" "arr[8]" "arr[9]" "arr[10]" "arr[11]" "arr[12]" "arr[13]" "arr[14]" "arr[15]" "arr[16]" "arr[17]" "arr[18]" "arr[19]" "arr[20]" "arr[21]" "arr[22]" "arr[23];
				}
			}
			printed = 1;
		}
		
	}
};

END {
};

