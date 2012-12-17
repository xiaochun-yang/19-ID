# -v integratedSols="xxx,xxx,xxx"
BEGIN {
	indexTable = "notFound";
	integrationTable = "notFound";
	count = 0;
	inCount = 0;
	beforeLastLine = "";
	lastLine = "";
	labelitError = "";
};

/^Beam center/{
	split($4, tmp, ",");
	beamX = tmp[1];
	split($6, tmp, ",");
	beamY = tmp[1];
	distance = $8;
	split($11, tmp, "=");
	mosaicityValue = tmp[2];
	mosaicityPercent = $10;
};

{
	beforeLastLine = lastLine;
	lastLine = $0;
	
	if (($1 == "Solution") && ($2 == "Metric")) {
		indexTable = "inIt";
	}
	
	if (($1 == "MOSFLM") && ($2 == "Integration")) {
		indexTable = "done";
	}
	
	if (($1 == "Solution") && ($2 == "SpaceGroup")) {
		integrationTable = "inIt";
	}

	if ( $0 ~ "pseudotranslation") {
		integrationTable = "done";
	}




	if ((indexTable == "inIt") && ($1 != "Solution") && (NF > 13)) {
	 	count++;
		status[count] = "";
		if ($1 == ":)") {
			status[count] = "good";
	 	} else if ($1 == ";(") {
	 		status[count] = "bad";
	 	}
	 	solNum[count] = $2;
	 	matrixFit[count] = $3 " " $4;
	 	rmsd[count] = $5;
	 	spots[count] = $6;
	 	crystalSystem[count] = $7;
	 	lattice[count] = $8;
	 	cellA[count] = $9;
	 	cellB[count] = $10;
	 	cellC[count] = $11;
	 	cellAlpha[count] = $12;
	 	cellBeta[count] = $13;
	 	cellGamma[count] = $14;
	 	volume[count] = $15;
	 	
	} else if ((integrationTable == "inIt") && ($1 != "Solution") && (NF > 7)) {
		inCount++;
		inStatus[inCount] = "";
		if ($1 == ":)") {
			inStatus[inCount] = "good";
			if (predictedResolution == "")
				predictedResolution = $7;
		} else if ($1 == ";(") {
			inStatus[inCount] = "bad";
		}
		# how many solutions should we print
		num = split(integratedSols, sols, " ");
		integrated[inCount] = "false";
		sp[inCount] = "";
		if (inStatus[inCount] == "") {
			# loop over solutions we have integrated
			# (where subdir solutionNN exists)
			for (i = 1; i <= num; i++) {
				if ($1 == sols[i]) {
					integrated[inCount] = "true";
					break;
				}
			}
			inSolNum[inCount] = $1;
			sp[inCount] = $2;
			inBeamX[inCount] = $3;
			inBeamY[inCount] = $4;
			inDistance[inCount] = $5;
			inResolution[inCount] = $6;
			inMosaicity[inCount] = $7;
			inRms[inCount] = $8;
		} else {
			# loop over solutions we have integrated
			# (where subdir solutionNN exists)
			for (i = 1; i <= num; i++) {
				if ($2 == sols[i]) {
					integrated[inCount] = "true";
					break;
				}
			}
			inSolNum[inCount] = $2;
			sp[inCount] = $3;
			inBeamX[inCount] = $4;
			inBeamY[inCount] = $5;
			inDistance[inCount] = $6;
			inResolution[inCount] = $7;
			inMosaicity[inCount] = $8;
			inRms[inCount] = $9;
		}
	}
};

/No_Indexing_Solution:/{
	labelitError = $0;	
}

END {
print "<labelit>"
if ((indexTable == "notFound") || (integrationTable == "notFound")) {
	if (labelitError != "") {
		print "  <error>" labelitError "</error>";
	} else {
		if (index(lastLine, "known_symmetry") > 0) {
			print "  <error>" beforeLastLine " " lastLine "</error>";
		} else {
			print "  <error>" lastLine "</error>";
		}
	}
}
print "  <beamX value=\"" beamX "\"/>";
print "  <beamY value=\"" beamY "\"/>";
print "  <distance value=\"" distance "\"/>";
print "  <mosaicity value=\"" mosaicityValue "\" percent=\"" mosaicityPercent "\"/>";
print "  <resolution value=\"" predictedResolution "\"/>";
if (indexTable != "notFound") {
print "  <indexing>";
for (i = 1; i <= count; i++) {
	print "    <solution number=\"" solNum[i] "\" status=\"" status[i] "\" matrixFit=\"" matrixFit[i] \
				"\" rmsd=\"" rmsd[i] "\" spots=\"" spots[i] \
				"\" crystalSystem=\"" crystalSystem[i]  \
				"\" lattice=\"" lattice[i] \
				"\" cellA=\"" cellA[i] \
				"\" cellB=\"" cellB[i] \
				"\" cellC=\"" cellC[i] \
				"\" cellAlpha=\"" cellAlpha[i] \
				"\" cellBeta=\"" cellBeta[i] \
				"\" cellGamma=\"" cellGamma[i] \
				"\" volume=\"" volume[i] \
				"\" />";
}
print "  </indexing>";
}
if (integrationTable != "notFound") {
print "  <integration>"
for (i = 1; i <= inCount; i++) {
	print "    <solution number=\"" inSolNum[i] "\" status=\"" inStatus[i] \
		"\" integrated=\"" integrated[i] \
		"\" beamX=\"" inBeamX[i] \
		"\" beamY=\"" inBeamY[i] \
		"\" distance=\"" inDistance[i] \
		"\" resolution=\"" inResolution[i] \
		"\" mosaicity=\"" inMosaicity[i] \
		"\" rms=\"" inRms[i]  "\">";				
	num = split(sp[i], spaceGroups, ",");
	for (j=1; j <=num; j++) {
		print "      <spaceGroup name=\"" spaceGroups[j] "\" />";
	}
print "    </solution>";
}
print "  </integration>";
}
print "</labelit>";
};

