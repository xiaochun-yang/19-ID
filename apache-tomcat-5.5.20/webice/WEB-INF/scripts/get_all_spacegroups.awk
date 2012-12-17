# Expects lowestSym or lattice param
# -v lowestSym=xxx -v lattice=xxx
# -v separator=","
# parses 
BEGIN {
    sp = "unkown"
};

{
	if (lowestSym != "") {
	
		split($3, allsp, ",");
		if (allsp[1] == lowestSym) { 
			# spacegroups are in column 3
			sp = $3;
		}  
	} else if (lattice != "") {
	
		if ($1 == lattice) {
			# spacegroups are in column 3
			sp = $3;
		}
	}
	
	# Replace commans with space
	gsub(/,/, separator, sp);
	
};

END {
    print sp;
};

