BEGIN {
    start = 0;
    sol = "1"
};

{
    # Parse each row in Integration Result table
    if (start == 1) {
    	# Good solution
    	if ($1 == ":)") {
	    	sol = $2;
	    	start = 0;
	    }
    }

    # Locate Integration Result table
    if ($1 == "Solution" && $2 == "SpaceGroup") {
    	start = 1;
    };
    
};

END {
    print sol;
};
