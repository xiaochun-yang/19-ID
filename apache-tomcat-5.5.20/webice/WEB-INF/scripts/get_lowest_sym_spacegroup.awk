# Expects -v lattice=xxx
# parses 
BEGIN {
    sp = "unkown"
};

{
    if ($1 == lattice) { 
    	split($3, allsp, ",");
    	sp = allsp[1];
    }    
};

END {
    print sp;
};

