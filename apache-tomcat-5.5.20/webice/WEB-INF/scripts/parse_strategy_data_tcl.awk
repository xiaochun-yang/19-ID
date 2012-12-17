BEGIN {
	start = 0;
	lookForEmptyLine = 0;
	start2 = 0;
	count = 0;
	uniqueStart = 0;
	anomStart = 0;
	print "  { completenessStrategy";
};

/axis is closest/{
	start = 1;
	printf("    { summary\n      {\n");
	lookForEmptyLine = 1;
}

/^ Unique axis is/{
	start = 1;
	lookForEmptyLine = 1;
}

/^ Optimum rotation/{
	start2 = 1;
}

/^ The number of unique reflections/{
	uniqueStart = 1;
	printf("    { uniqueData\n      {\n");
	print " UNIQUE DATA";
	print " ===========";
}

/^ ANOMALOUS DATA/{
	uniqueStart = 0;
	anomStart = 1;
	printf("      }\n    }\n");
	printf("    { anomalousData\n      {\n");
}

/^ COMPLETE option/{
	anomStart = 0;
	printf("      }\n    }\n");
}


{
	if ((lookForEmptyLine == 1) && ($0 == "")) {
		start = 0;
		lookForEmptyLine = 0;
	}
			
	if (start == 1) {
		print $0;
	}
	
	if (start2 == 1) {
		if (count == 0) {
			print " ";
		}
		
		if (count >= 3) {
			start2 = 0;
			printf("      }\n    }\n");		
		} else {
			print $0;
			count++;
		}
	}
	
	if (uniqueStart == 1) {
		print $0;
	}
	
	if (anomStart == 1) {
		print $0
	}
}

END {
	print "  }";
};

