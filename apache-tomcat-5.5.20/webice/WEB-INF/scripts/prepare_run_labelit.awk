BEGIN {
	inTask = 0;
	inLabelit = 0;
	shouldPrint = 1;
	imageDir = "";
	image[1] = "";
	image[2] = "";
	beamX = "0.0";
	beamY = "0.0";
}; 

# Enter run_autoindex task node
/<task name="run_autoindex.csh">/{
	inTask = 1;
};

# Found existing run_labelit task node
# do not print it.
/<task name="run_labelit.csh">/{

	shouldPrint = 0;
	inLabelit = 1;

};

/<\/input>/{

	if (unitCell == "") {
		unitCell = "<unitCell a=\"\" b=\"\" c=\"\" alpha=\"\" beta=\"\" gamma=\"\"/>";
	}
	print "  <task name=\"run_labelit.csh\">";
	print "    <imageDir>" imageDir "</imageDir>";
	print "    <image>" image[1] "</image>";
	print "    <image>" image[2] "</image>";
	print "    <beamCenterX>" beamX "</beamCenterX>";
	print "    <beamCenterY>" beamY "</beamCenterY>";
	print "    <laueGroup>" laueGroup "</laueGroup>";
	print "    " unitCell;
	print "  </task>";

};

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
		
		# beam center X, Y
		ret = match($0, "<beamCenterX>.*</beamCenterX>");
		if (ret > 0) {
			beamX = substr($0, RSTART+13, RLENGTH-27);
		};
		ret = match($0, "<beamCenterY>.*</beamCenterY>");
		if (ret > 0) {
			beamY = substr($0, RSTART+13, RLENGTH-27);
		};
		
		ret = match($0, "<laueGroup>.*</laueGroup>");
		if (ret > 0) {
			laueGroup = substr($0, RSTART+11, RLENGTH-23);
		};
		
		ret = match($0, "<unitCell.*/>");
		if (ret > 0) {
			unitCell = substr($0, RSTART);
		};
		
	}
	

	# Print selected line
	if (shouldPrint) {
		print $0
	}
		
};

# Exit task node
/<\/task>/{
	if (inTask == 1) {
		inTask = 0;
	} else if (inLabelit == 1) {
		inLabelit = 0;
		shouldPrint = 1;
	}
};


END { 

}

