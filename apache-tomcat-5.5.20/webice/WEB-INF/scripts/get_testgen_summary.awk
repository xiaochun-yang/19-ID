BEGIN {
	inTable = 0;
	deltaPhi = 1000.0;
};

# In the table
inTable==1{
	# Empty line is the end of table
	if (NF < 1) {
		inTable = 0;
	} else {
		# Take the smallest value
		if (deltaPhi > $4) {
			deltaPhi = $4;
		}
	}
};

/^ Phi start/{
	inTable = 1;
};

END {
	print deltaPhi
};

