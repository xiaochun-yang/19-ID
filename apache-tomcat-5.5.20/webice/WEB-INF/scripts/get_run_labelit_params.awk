BEGIN {
	inTask = 0;
	imageDir = "";
	image[1] = "";
	image[2] = "";
	imageCount = 0;
	beamX = "0.0";
	beamY = "0.0";
	laueGroup = "unknown";
	a = 0.0;
	b = 0.0;
	c = 0.0;
	alpha = 0.0;
	beta = 0.0;
	gamma = 0.0;
}; 

# Enter autoindex task node
/<task name="run_labelit.csh">/{
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
		
		# image
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
		
		if (laueGroup != "unknown") {
		ret = match($0, "<unitCell.*");
			if (ret > 0) {
				pos1 = index($0, "a=\"");
				str = substr($0, pos1+3);
				pos1 = index(str, "\"");
				a = substr(str, 1, pos1-1);
				
				pos1 = index(str, "b=\"");
				str = substr(str, pos1+3);
				pos1 = index(str, "\"");
				b = substr(str, 1, pos1-1);
				
				pos1 = index(str, "c=\"");
				str = substr(str, pos1+3);
				pos1 = index(str, "\"");
				c = substr(str, 1, pos1-1);

				pos1 = index(str, "alpha=\"");
				str = substr(str, pos1+7);
				pos1 = index(str, "\"");
				alpha = substr(str, 1, pos1-1);

				pos1 = index(str, "beta=\"");
				str = substr(str, pos1+6);
				pos1 = index(str, "\"");
				beta = substr(str, 1, pos1-1);

				pos1 = index(str, "gamma=\"");
				str = substr(str, pos1+7);
				pos1 = index(str, "\"");
				gamma = substr(str, 1, pos1-1);

			}
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
	gsub(/ /, "\\&nbsp;", laueGroup);
	
	if (laueGroup == "")
		laueGroup = "unknown";
	
	printf("%s %s %s %s %s %s %.2f %.2f %.2f %.2f %.2f %.2f", imageDir, image[1], image[2], beamX, beamY, laueGroup, a, b, c, alpha, beta, gamma);
}

