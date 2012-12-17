BEGIN {
    start = 0;
    count = 0;
};

{
    # Locate the end of autoindex solution table
    if ($1 == "MOSFLM") {
    	start = 0;
    };
 
    # Get all solutions from the table
    if (start == 1) {
    	# Good solution
    	if ($1 == ":)" || $1 == ";(") {
	    count++;
	    if ($2 < 10) {
	    	resultArray[count] = "0"$2;
	    } else {
	    	resultArray[count] = $2;
	    }
    	}
    }

    # Locate the beginning of autoindex solution table
    if ($1 == "Solution" && $2 == "Metric") {
    	start = 1;
    };
    
};

END {
    if (count > 0) {
    	print resultArray[1];
    }
    for (i = 2; i <= count; i++) {
    	print " " resultArray[i];
    }
};

