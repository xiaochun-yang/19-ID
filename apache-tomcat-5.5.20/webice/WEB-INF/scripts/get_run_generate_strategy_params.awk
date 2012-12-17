# Enter autoindex task node
/<task name="run_generate_strategy.csh">/{
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
				
		# predictedRes
		ret = match($0, "<predictedRes>.*</predictedRes>");
		if (ret > 0) {
			predictedRes = substr($0, RSTART+14, RLENGTH-29);
		};

		# detectorRes
		ret = match($0, "<detectorRes>.*</detectorRes>");
		if (ret > 0) {
			detectorRes = substr($0, RSTART+13, RLENGTH-27);
		};

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
gsub(/ /, "\\&nbsp;", expType);
gsub(/ /, "\\&nbsp;", imageDir);
gsub(/ /, "\\&nbsp;", image[1]);
gsub(/ /, "\\&nbsp;", image[2]);
printf("%s %s %s %s %s", imageDir, image[1], image[2], predictedRes, detectorRes);
}

