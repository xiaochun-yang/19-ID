# Expects -v solNum=xxx
BEGIN {
    start = 0;
    if (substr(solNum, 1, 1) == "0") {
    	# Strip off leading 0
    	tmp = solNum;
    	solNum = substr(tmp, 2, length(tmp)-1);
    };
    lattice = "unknown";
};

{

    # Locate the end of autoindex solution table
    if ($1 == "MOSFLM") {
    	start = 0;
    };
 	
 	# We are in autoindex solution table
    if (start == 1) {
    	# The solution
    	if ($2 == solNum) {
    		# Get the 8th column
	    	lattice = $8;
    	}
    }

    # Locate the beginning of autoindex solution table
    if ($1 == "Solution" && $2 == "Metric") {
    	start = 1;
    };
    
};

END {
    print lattice;
};

