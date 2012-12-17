# Expect -predictedRes=xxx -detectorRes=xxx
BEGIN {
	inTask = 0;
	imageDir = "";
	image[1] = "";
	image[2] = "";
}; 

# Enter run_autoindex task node
/<task name="run_integrate.csh">/{
	inTask = 1;
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
		
	}
	
};

# Exit task node
/<\/task>/{
	if (inTask == 1) {
		inTask = 0;
	}
};

END { 
	print "  <input>";
	print "  <task name=\"run_generate_strategy.csh\">";
	print "    <imageDir>" imageDir "</imageDir>";
	print "    <image>" image[1] "</image>";
	print "    <image>" image[2] "</image>";
	print "    <predictedRes>" predictedRes "</predictedRes>";
	print "    <detectorRes>" detectorRes "</detectorRes>";
	print "  </task>";
	print "</input>";
}

