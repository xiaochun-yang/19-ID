# Get crystal system for the given solution number
# Extracts crystal system from autoindex table in labelit.out file.
# Require -v solNum=xxx
BEGIN {
	inIndexTable = 1;
};

# Index table
/^Solution  Metric/{
	inIndexTable = 1;
	
};


{
	if (inIndexTable) {
		num = $2;
		
		# Print crystal system
		if (solNum == num) {
			print $8
		}
		
	}
	
}


END {
};

