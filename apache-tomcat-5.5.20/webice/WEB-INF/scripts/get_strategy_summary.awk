BEGIN {
	lineNum = -10;
};

/^ Optimum rotation gives/{
	complete = $4;
	lineNum = NR;
};

NR==lineNum+2{
	phiMin = $2;
	phiMax = $4
}

END {
	print phiMin " " phiMax " " complete
};

