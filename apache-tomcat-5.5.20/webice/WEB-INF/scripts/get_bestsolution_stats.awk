# Get resolution and mosaicity of the first good solution in the integration table
# in labelit.out
BEGIN {
	inIntegrateTable = 0;
	resolution = "";
	mosaicity = "";
	solutionNumStr = "";
	spacegroup = "";
};


{
	
	if (inIntegrateTable && (length($0) > 1)) {
		
		if ($1 == ":)" && resolution == "") {
			resolution = $7;
			mosaicity = $8;
			solutionNum = $2;
			spacegroup = $3;
			if (solutionNum < 10)
				solutionNumStr = "0" solutionNum;
			else
				solutionNumStr = solutionNum;
		}				
			
	} else {
		if ($1 == "Solution" && $2 == "SpaceGroup") {
			inIntegrateTable = 1;
		}
	}

};


END {
print resolution " " mosaicity " " solutionNumStr " " spacegroup;
};

