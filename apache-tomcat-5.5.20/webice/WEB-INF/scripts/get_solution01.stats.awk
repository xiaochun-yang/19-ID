# Get resolution and mosaicity of the last solution in the integration table
# in labelit.out
BEGIN {
	inIntegrateTable = 0;
};


{
	
	if (inIntegrateTable && (length($0) > 1)) {
		
		if ($1 == ":)" || $1 == ";(") {
			resolution = $7;
			mosaicity = $8;
		} else {
			resolution = $6;
			mosaicity = $7;
		}
						
			
	} else {
		if ($1 == "Solution" && $2 == "SpaceGroup") {
			inIntegrateTable = 1;
		}
	}

};


END {
print resolution " " mosaicity;
};

