# -v time=XXX (exposure time)
BEGIN {
format = "unknown";
}

/^beamX/{centerX = $2}
/^beamY/{centerY = $2}
/^distance/{distance = $2}
/^wavelength/{wavelength = $2}
/^detector/{
	if ($1 == "detectorRes") {
		res = $2;
	} else if ($1 == "detectorWidth") {
		width = $2;
	} else if ($1 == "detector") {
		if (NF == 3) { 
			detector = $3; 
		} else { 
			detector = $2; 
		} 
	}
}
/^format/{format = $2}
/^exposureTime/{exposureTime = $2}
/^oscRange/{oscRange = $2}


END {
	
	print wavelength " " distance " " detector " " width " " width/2.0 " " res " " exposureTime " " oscRange " " format;
	
}

