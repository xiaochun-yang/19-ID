# Expect -v bestSolNum=xxx -v solNum=xxx -v lowestSym=xxx -v outputFile=xxx
BEGIN {

	indexName = "index"solNum;
	
};

{ 

	# Copy the line
	line = $0;

	# Replace index01 with the correct index.
	gsub(bestSolNum, indexName, line);

	# Check if the line begins with SYMMETRY
	# Replace it with the correct symmetry
	if ($1 == "SYMMETRY") {
		line = "SYMMETRY " lowestSym;
	} 



	# Print the modified line
	print line >> outputFile;

};

