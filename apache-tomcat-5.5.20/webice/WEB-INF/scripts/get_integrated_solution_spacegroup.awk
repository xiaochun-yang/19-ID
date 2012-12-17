BEGIN {
    start = 0;
    res = "unknown"
};

{
    # Parse each row in Integration Result table
    if (start == 1) {
    	# The solution
	if ($2 < 10 && "0"$2 == solNum) {
	    res = $3
	} else if ($2 >= 10 && $2 == solNum) {
	    res = $3
	}
    }

    # Locate Integration Result table
    if ($1 == "Solution" && $2 == "SpaceGroup") {
    	start = 1;
    };
    
};

END {
    print res
};

