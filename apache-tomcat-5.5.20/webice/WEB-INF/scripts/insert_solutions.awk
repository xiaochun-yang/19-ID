# Require -v solNum=xxx 
#		-v spacegroups=xxx
#		-v x=xxx
#		-v y=xxx
#		-v distance=xxx
#		-v resolution=xxx
#		-v mosaicity=xxx
BEGIN {
	inIntegrateTable = 0;
	inserted = 0;
	smile = "  ";
};


{
	
	if (inIntegrateTable && (length($0) > 1)) {
		
		if ($1 == ":)") {
			num = $2;
			smile = $1;
		} else if ($1 == ";(") {
			num = $2;
			smile = $1;
		} else {
			num = $1
			smile = "  ";
		}
		
		
		# Find solution number that is smaller 
		# than the given solution.
		# Insert the given solution the line above.
		if (num == solNum) {
			if ($1 == ":)" || $1 == ";(") {
				x = $4;
				y = $5;
				distance = $6;
				resolution = $7;
				mosaicity = $8;
				RMS = $9;
			} else {
				x = $3;
				y = $4;
				distance = $5;
				resolution = $6;
				mosaicity = $7;
				RMS = $8;
			}
			# Replace the line
			printf("%2s%4d %20s%7.2f%7.2f%8.2f%11.2f%12.6f%9.3f\n", 
				smile, solNum, spacegroups, x, y, distance,
				resolution, mosaicity, RMS);
			inserted = 1;
		} else if (solNum > num) {
			# Insert a new solution whose solution number is higher than
			# the highest existing solutions.
			if (inserted == 0) {
				printf("%2s%4d %20s%7.2f%7.2f%8.2f%11.2f%12.6f%9.3f\n", 
					"  ", solNum, spacegroups, x, y, distance,
					resolution, mosaicity, RMS);
				inserted = 1;
			}
			# Print the current line after inserting the new solution.
			if ($1 == ":)" || $1 == ";(") {
				spacegroups = $3;
				x = $4;
				y = $5;
				distance = $6;
				resolution = $7;
				mosaicity = $8;
				RMS = $9;
			} else {
				spacegroups = $2;
				x = $3;
				y = $4;
				distance = $5;
				resolution = $6;
				mosaicity = $7;
				RMS = $8;
			}
			printf("%2s%4d %20s%7.2f%7.2f%8.2f%11.2f%12.6f%9.3f\n", 
					smile, num, spacegroups, x, y, distance,
					resolution, mosaicity, RMS);
		} else {
			print $0;
		}
						
			
	} else {
		if ($1 == "Solution" && $2 == "SpaceGroup") {
			inIntegrateTable = 1;
		}
		print $0;
	}

};


END {
};

