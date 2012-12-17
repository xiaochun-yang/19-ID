BEGIN {
detectorResolution = 0.0;
}

/^beamX/{centerX = $2}
/^beamY/{centerY = $2}
/^distance/{distance = $2}
/^wavelength/{wavelength = $2}
/^detector/{if (NF == 3) { detector = $2 " " $3; } else { detector = $2; } }
/^format/{format = $2}
/^detectorRes/{detectorResolution = $2}

END {

	if (detectorResolution > 0.0) {
		print detectorResolution;
	} else {
	
		if ((detector == "ADSC QUANTUM4") || (detector == "ADSC+QUANTUM4") || (detector == "ADSC_QUANTUM4")) {
			radius = 94
		} else if ((detector == "MAR 345") || (detector == "MAR+345") || (detector == "MAR_345") || (detector == "MAR345") || (detector == "mar345")) {
			if ( (format == "1200") || (format == "1800") ) {
				radius = 90
			} else if ( (format == "1600") || (format == "2400") ) {
				radius = 120
			} else if ( (format == "2000") || (format == "3000") ) {
				radius = 150
			} else if ( (format == "2300") || (format == "3450") ) {
				radius = 172.5
			}
		} else if (detector == "MARCCD165") {
			radius = 82.5;
		} else if (detector == "MARCCD225") {
			radius = 112.5;
		} else if (detector == "MARCCD300") {
			radius = 150.0;
		} else if (detector == "MARCCD325") {
			radius = 162.5;
		} else if ((detector == "ADSC QUANTUM315") || (detector == "ADSC+QUANTUM315") || (detector == "ADSC_QUANTUM315")) {
			radius = 157.5
		} else if (detector == "PILATUS6") {
			radius = 211.818;
			savedCenterY = centerY;
			centerY = centerX;
			centerX = savedCenterY;
		}

		beamX = radius*2.0 - centerY;
		beamY = centerX

		dX = radius - beamX;
		dY = radius - beamY;

		Rx = radius + sqrt(dX^2);
		Ry = radius + sqrt(dY^2);

		Rm = sqrt(Rx^2 + Ry^2);

		resX = wavelength / ( 2.0 * sin(atan2(Rx, distance) / 2.0) )
		resY = wavelength / ( 2.0 * sin(atan2(Ry, distance) / 2.0) )
		resM = wavelength / ( 2.0 * sin(atan2(Rm, distance) / 2.0) )

		if (resX < resY) { 
			print resX;
		} else {
			print resY;
		}
	
	}
	
}

