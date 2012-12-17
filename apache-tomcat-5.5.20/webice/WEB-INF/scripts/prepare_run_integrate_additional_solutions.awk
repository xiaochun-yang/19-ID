# Require -v sols=xxx
BEGIN {
	inTask = 0;
	inIntegrate = 0;
	shouldPrint = 1;
	imageDir = "";
	image[1] = "";
	image[2] = "";
	integrate = "best";
	generateStrategy = "no";
}; 

# Enter run_autoindex task node
/<task name="run_autoindex.csh">/{
	inTask = 1;
};

# Found existing run_integrate task node
# do not print it.
/<task name="run_integrate.csh">/{

	shouldPrint = 0;
	inIntegrate = 1;

};

/<\/input>/{

	print "  <task name=\"run_integrate.csh\">"
	print "    <imageDir>" imageDir "</imageDir>";
	print "    <image>" image[1] "</image>";
	print "    <image>" image[2] "</image>";
	print "    <integrate>" integrate "</integrate>"
	if (integrate != "all") {
		print "    <additional_solutions>" sols "</additional_solutions>"
	}
	print "    <generate_strategy>" generateStrategy "</generate_strategy>"
	print "  </task>"

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
	} else if (inIntegrate == 1) {
		inIntegrate = 0;
		shouldPrint = 1;
	}
};


END { 

}

