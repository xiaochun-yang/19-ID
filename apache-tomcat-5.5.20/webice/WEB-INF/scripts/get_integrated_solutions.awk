BEGIN {
    start = 0;
    count = 0;
};

{
    # Parse each row in Integration Result table
    if (start == 1) {
    	# Good solution
    	if ($1 == ":)") {
	    count++;
	    if ($2 < 10) {
	    	resultArray[count] = "0"$2;
	    } else {
	    	resultArray[count] = $2;
	    }
    	}
    }

    # Locate Integration Result table
    if ($1 == "Solution" && $2 == "SpaceGroup") {
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

