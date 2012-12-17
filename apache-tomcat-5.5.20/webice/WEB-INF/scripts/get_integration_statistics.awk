BEGIN {
	lineNum = -10;
	rms = "";
	beamX = "";
	beamY = "";
	distance = "";
}

# Find marker line
# Copy the line
/^ Final rms residual:/{
	lineNum = NR;
	rms = $4;
	line1 = $0;
};

# Copy 2 lines below marker line
NR==lineNum+2{
	beamX = $1;
	beamY = $2;
	distance = $4;
	line2 = $0;
};

# Print the last ones found, if repeated
END {
	rms = substr(rms, 1, length(rms)-3);
	print beamX " " beamY " " distance " " rms;
}

