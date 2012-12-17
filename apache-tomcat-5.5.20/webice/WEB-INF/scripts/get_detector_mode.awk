# -v extime=XXX (exposure time) -v format=XXX
BEGIN {
}

{
	detector = $0;
}


END {

	mode = "unknown";
	modeInt = "-1";
	
	if ((detector == "ADSC QUANTUM4") || (detector == "ADSC+QUANTUM4") || (detector == "ADSC_QUANTUM4")) {
		# mode 0=slow 1=fast 2=slow_bin 3=fast_bin 4=slow_dezing 5=fast_dezing 6=slow_bin_dezing 7=fast_bin_dezing
		# default mode = 0
		if (extime > 30) {
			mode = "unbinned/slow/dezinger";
			modeInt = 4;
		} else {
			mode = "unbinned/slow";
			modeInt = 0;
		}
	} else if ((detector == "ADSC QUANTUM315") || (detector == "ADSC+QUANTUM315") || (detector == "ADSC_QUANTUM315")) {
		# mode 0=binned 1="binned dezing"
		# default mode = 2
		if (extime > 30) {
			mode = "binned/dezinger";
			modeInt = 6;
		} else {
			mode = "binned";
			modeInt = 2;
		}
	} else if (index(detector, "MARCCD") > 0) {
		# mode 
		# default 
		if (extime > 30) {
			mode = "dezinger";
			modeInt = 1;
		} else {
			mode = "normal";
			modeInt = 0;
		}
	} else if ((detector == "MAR345") || (detector == "MAR 345") || (detector == "MAR_345") || (detector == "MAR 345") || (detector == "mar345")) {
		# Return the same detector mode
		# as in the current image
		if (format == 2300) {
			mode = "345mmx150um";
			modeInt = 0;
		} else if (format == 2000) {
			mode = "300mmx150um";
			modeInt = 1;
		} else if (format == 1600) {
			mode = "240mmx150um";
			modeInt = 2;
		} else if (format == 1200) {
			mode = "180mmx150um";
			modeInt = 3;
		} else if (format == 3450) {
			mode = "345mmx100um";
			modeInt = 4;
		} else if (format == 3000) {
			mode = "300mmx100um";
			modeInt = 5;
		} else if (format == 2400) {
			mode = "240mmx100um";
			modeInt = 6;
		} else if (format == 1800) {
			mode = "180mmx100um";
			modeInt = 7;
		} else {
			# Default mode is 2
			mode = "240mmx150um";
			modeInt = 2;
		}
	} else if (detector == "PILATUS6") {
		mode = "normal";
		modeInt = 0;
	}
	
	print modeInt " " mode;
	
}

