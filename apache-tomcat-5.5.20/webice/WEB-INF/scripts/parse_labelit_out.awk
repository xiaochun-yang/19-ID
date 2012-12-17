# Get resolution and mosaicity of the first good solution in the integration table
# in labelit.out
# -v outputType=XXX
BEGIN {
	inIntegrateTable = 0;
	solution = "";
	poor = 0;
	mosaicityStr = ""
};

/80%/{
	pos = index($0, "80%");
	if (pos > 0) {
		mosaicityStr = substr($0, pos);
	}
}

/60%\(POOR\)/{
	poor = 2;
	pos = index($0, "60%(POOR)");
	if (pos > 0) {
		mosaicityStr = substr($0, pos);
	}
}

{
	
	if (inIntegrateTable && (length($0) > 1)) {
		
		if ($1 == ":)" && solution == "") {
			solution = $2;
			spaceGroup = sp[1];
			resolution = $7;
			mosaicity = $8
			rms = $9;
			split($3, sp, ",");
		}				
			
	} else {
		if ($1 == "Solution" && $2 == "SpaceGroup") {
			inIntegrateTable = 1;
		}
	}

};


END {
	mosaicityPenalty = 1.0;
	if (poor == 2)
		mosaicityPenalty = 2.0;
	score = 0.0;
	if (resolution > 0.0)
		score = 1.0 - ( 0.7*(2.71828^(-4.0/resolution)) ) - (1.5*rms) - (0.2*mosaicity*mosaicityPenalty);
	if (outputType == "raw") {
		printf("%s, score = %.2f\n", mosaicityStr, score);
	} else if (outputType == "mosaicity") {
		printf("%s", mosaicityStr);
	} else if (outputType == "score") {
		printf("%.2f", score);
	} else {
		printf("  <bestSolution number=\"%d\" spaceGroup=\"%s\" resolution=\"%.2f\" mosaicity=\"%.2f\" score=\"%.2f\"/>\n", solution, sp[1], resolution, mosaicity, score);
	}
};

