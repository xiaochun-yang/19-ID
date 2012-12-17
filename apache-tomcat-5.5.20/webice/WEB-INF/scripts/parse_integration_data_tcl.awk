BEGIN {
	printf("{ solution\n");
	count = 0;
	printSpotProfile = 0;
	countEmptyLines = 0;
	foundAnalysis = 0;
	inImage = 0;
};

/^ image FILENAME:/{
	if (inImage == 1) {
		printf("  }\n");
		inImage = 0;
	}
	start = 1;
	count++;
	printf("  { image {%s} {%s}\n", count, $3);
	foundAnalysis = 0;
	inImage = 1;
}

/AVERAGE SPOT PROFILE/{
	printSpotProfile = 1;
	countEmptyLines = 0;
	printf("    { spotProfile\n      {\n");
}

/^ Analysis as a/{
	if (foundAnalysis == 0) {
		printAnalysis = 1;
		countEmptyLines = 0;
		foundAnalysis = 1;
		printf("    { statistics\n      {\n");
	}
}

{
	if (printSpotProfile == 1) {
		if ($0 == "") {
			countEmptyLines++;
		}
		if (countEmptyLines >= 2) {
			printSpotProfile = 0;
			countEmptyLines = 0;
			printf("      }\n    }\n");
		}
	}
	
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
			printf("      }\n    }\n");
		}
	}
	
	if (printAnalysis == 1) {
		gsub(/</,"\\&lt;"); gsub(/>/, "\\&gt;"); print;
	}
}

END {
	if (inImage == 1) {
		printf("  }\n");
		inImage = 0;
	}
	printf("}\n");
};

