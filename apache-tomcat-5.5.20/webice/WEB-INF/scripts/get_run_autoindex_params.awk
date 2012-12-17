BEGIN {
	inTask = 0;
	imageDir = "";
	image[1] = "";
	image[2] = "";
	imageCount = 0;
	integrate = "best";
	generateStrategy = "no";
	beamX = "0.0";
	beamY = "0.0";
	distance = "0.0";
	wavelength = "0.0";
	detector = "";
	format = "";
	resolution = 0.0;
	exposureTime = 0.0;
	beamline = "";
	oscRange = 0.0;
	beamlineFile = "";
	dcsDumpFile = "";
	strategyMethod = "mosflm";
};

# Enter autoindex task node
/<task name="run_autoindex.csh">/{
	inTask = 1;
};

# Inside task node
{
	if (inTask == 1) {
			
		# imageDir
		ret = match($0, "<imageDir>.*</imageDir>");
		if (ret > 0) {
			imageDir = substr($0, RSTART+10, RLENGTH-21);
		};
		
		# imageDir
		ret = match($0, "<image>.*</image>");
		if (ret > 0) {
			imageCount++;
			if (imageCount == 1) {
				image[1] = substr($0, RSTART+7, RLENGTH-15);
			} else if (imageCount == 2) {
				image[2] = substr($0, RSTART+7, RLENGTH-15);
			}
		};
				
		
		# integrate option
		ret = match($0, "<integrate>.*</integrate>");
		if (ret > 0) {
			integrate = substr($0, RSTART+11, RLENGTH-23);
		};

		# Strategy
		ret = match($0, "<generate_strategy>.*</generate_strategy>");
		if (ret > 0) {
			generateStrategy = substr($0, RSTART+19, RLENGTH-39);
		};

		# beam center X, Y
		ret = match($0, "<beamCenterX>.*</beamCenterX>");
		if (ret > 0) {
			beamX = substr($0, RSTART+13, RLENGTH-27);
		};
		ret = match($0, "<beamCenterY>.*</beamCenterY>");
		if (ret > 0) {
			beamY = substr($0, RSTART+13, RLENGTH-27);
		};
		
		# distance
		ret = match($0, "<distance>.*</distance>");
		if (ret > 0) {
			distance = substr($0, RSTART+10, RLENGTH-21);
		};
		
		# wavelength
		ret = match($0, "<wavelength>.*</wavelength>");
		if (ret > 0) {
			wavelength = substr($0, RSTART+12, RLENGTH-25);
		};
		
		# detector
		ret = match($0, "<detector>.*</detector>");
		if (ret > 0) {
			detector = substr($0, RSTART+10, RLENGTH-21);
		};
		
		# detector
		ret = match($0, "<detectorFormat>.*</detectorFormat>");
		if (ret > 0) {
			format = substr($0, RSTART+16, RLENGTH-33);
		};
		if (format == "") {
			format = "N/A";
		}
		
		# detector resolution
		ret = match($0, "<detectorResolution>.*</detectorResolution>");
		if (ret > 0) {
			resolution = substr($0, RSTART+20, RLENGTH-41);
		};
		
		# exposure time
		ret = match($0, "<exposureTime>.*</exposureTime>");
		if (ret > 0) {
			exposureTime = substr($0, RSTART+14, RLENGTH-29);
		};
		
		# detector width
		ret = match($0, "<detectorWidth>.*</detectorWidth>");
		if (ret > 0) {
			detectorWidth = substr($0, RSTART+15, RLENGTH-31);
		};

		# beamline
		ret = match($0, "<beamline>.*</beamline>");
		if (ret > 0) {
			beamline = substr($0, RSTART+10, RLENGTH-21);
		};
		
		if (beamline == "") {
			beamline = "unknown";
		}

		# oscRange
		ret = match($0, "<oscRange>.*</oscRange>");
		if (ret > 0) {
			oscRange = substr($0, RSTART+10, RLENGTH-21);
		}
		
		# beamlineFile
		ret = match($0, "<beamlineFile>.*</beamlineFile>");
		if (ret > 0) {
			beamlineFile = substr($0, RSTART+14, RLENGTH-29);
		}
		
		# dcsDumpFile
		ret = match($0, "<dcsDumpFile>.*</dcsDumpFile>");
		if (ret > 0) {
			dcsDumpFile = substr($0, RSTART+13, RLENGTH-27);
		}
		
		# strategyMethod
		ret = match($0, "<strategyMethod>.*</strategyMethod>");
		if (ret > 0) {
			strategyMethod = substr($0, RSTART+16, RLENGTH-33);
		}
	}
};

# Exit task node
/<\/task>/{ 
	if (inTask == 1) {
		inTask = 0;
	}
};

END { 
# Encode spaces
gsub(/ /, "\\&nbsp;", imageDir);
gsub(/ /, "\\&nbsp;", image[1]);
gsub(/ /, "\\&nbsp;", image[2]);
gsub(/ /, "\\&nbsp;", integrate);
gsub(/ /, "\\&nbsp;", generateStrategy);
gsub(/ /, "\\&nbsp;", distance);
gsub(/ /, "\\&nbsp;", wavelength);
gsub(/ /, "\\&nbsp;", detector);
gsub(/ /, "\\&nbsp;", format);
gsub(/ /, "\\&nbsp;", resolution);
gsub(/ /, "\\&nbsp;", exposureTime);
gsub(/ /, "\\&nbsp;", detectorWidth);
gsub(/ /, "\\&nbsp;", oscRange);
printf("%s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s %s", 
	imageDir, image[1], image[2], integrate, 
	generateStrategy, beamX, beamY,
	distance, wavelength, detector, format,
	resolution, exposureTime, detectorWidth,
	beamline, oscRange, beamlineFile, dcsDumpFile, strategyMethod);
}

