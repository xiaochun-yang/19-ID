BEGIN {
	start = 0;
	lookForEmptyLine = 0;
	start2 = 0;
	count = 0;
	uniqueStart = 0;
	anomStart = 0;
	print "  <anomalousStrategy>";
};

/axis is closest/{
	start = 1;
	print "    <summary>";
}

/^ Unique axis is/{
	lookForEmptyLine = 1;
}

/^ Optimum rotation/{
	start2 = 1;
	start = 0;
}

/^ The number of unique reflections/{
	uniqueStart = 1;
	print "    <uniqueData>";
	print " UNIQUE DATA";
	print " ===========";
}

/^ ANOMALOUS DATA/{
	uniqueStart = 0;
	anomStart = 1;
	print "    </uniqueData>";
	print "    <anomalousData>";
}

/^ COMPLETE option/{
	anomStart = 0;
	print "    </anomalousData>";
}


{
	if ((lookForEmptyLine == 1) && ($0 == "")) {
		start = 0;
		lookForEmptyLine = 0;
	}
			
	if (start == 1) {
		print $0
	}
	
	if (start2 == 1) {
		
		if (count == 0) {
			print " ";
		}

		if (count >= 3) {
			start2 = 0;
			print "    </summary>";		
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
	print "  </anomalousStrategy>";
};


