BEGIN {
	print "<solution>";
	count = 0;
	printSpotProfile = 0;
	countEmptyLines = 0;
	foundAnalysis = 0;
	inImage = 0;
	finishedHeader = 0;
};

/^ REFLECTION INTEGRATION/{
	finishedHeader = 1;
}

/^ image FILENAME:/{
	if (finishedHeader == 1) {
	
	if (inImage == 1) {
		print "  </image>";
		inImage = 0;
	}
	start = 1;
	count++;
	print "  <image number=\"" count "\" file=\"" $3 "\">";
	foundAnalysis = 0;
	inImage = 1;
	
	}
}

/AVERAGE SPOT PROFILE/{
	if (printSpotProfile == 1) {
		# ignore if we are already in it.
	} else {
		printSpotProfile = 1;
		countEmptyLines = 0;
		print "    <spotProfile>";
	}
}

/^ Refinement using reflections/{
	printSpotProfile = 0;
	print "    </spotProfile>";
}

/^ Analysis as a/{
	if (foundAnalysis == 0) {
		printAnalysis = 1;
		countEmptyLines = 0;
		foundAnalysis = 1;
		print "    <statistics>";
	}
}

{
#	if (printSpotProfile == 1) {
#		if ($0 == "") {
#			countEmptyLines++;
#		}
#		if (countEmptyLines >= 2) {
#			printSpotProfile = 0;
#			countEmptyLines = 0;
#			print "    </spotProfile>";
#		}
#	}
	
	if (printSpotProfile == 1) {
		print $0;
	}
	
	if (printAnalysis == 1) {
		if ($0 == "") {
			countEmptyLines++;
		}
		# found an empty line
		if (countEmptyLines > 1) {
			printAnalysis = 0;
			countEmptyLines = 0;
			print "    </statistics>";
		}
	}
	
	if (printAnalysis == 1) {
		gsub(/</,"\\&lt;"); gsub(/>/, "\\&gt;"); print;
	}
}

END {
	if (inImage == 1) {
		print "  </image>";
		inImage = 0;
	}
	print "</solution>";
};

