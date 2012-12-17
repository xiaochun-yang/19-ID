# -v integratedSols="xxx,xxx,xxx"
BEGIN {
	indexTable = "notFound";
	integrationTable = "notFound";
	count = 0;
	inCount = 0;
	lastLine = "";
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


END {
printf("{ labelit\n");
if ((indexTable == "notFound") || (integrationTable == "notFound")) {
	printf("  { error {" lastLine "} }\n");
}
printf("  { beamX %s }\n", beamX);
printf("  { beamY %s }\n", beamY);
printf("  { distance %s }\n", distance)
printf("  { mosaicity %.2f %.2f }\n", mosaicityValue, mosaicityPercent);
printf("  { resolution %.2f }\n", predictedResolution);
if (indexTable != "notFound") {
printf("  { indexing\n");
for (i = 1; i <= count; i++) {
	printf("    { solution %s {%s} {%s} %.3f %s %s %s %.2f %.2f %.2f %.2f %.2f %.2f %s }\n", \
				solNum[i], status[i], matrixFit[i], \
				rmsd[i], spots[i], crystalSystem[i],  \
				lattice[i], cellA[i], cellB[i], cellC[i], \
				cellAlpha[i], cellBeta[i], cellGamma[i], volume[i]);
}
printf("  }\n");
}
if (integrationTable != "notFound") {
printf("  { integration\n");
for (i = 1; i <= inCount; i++) {
	printf("    { solution  %s {%s} %s %s %s %s %s %s %s {", \
		inSolNum[i], inStatus[i], \
		integrated[i], \
		inBeamX[i], \
		inBeamY[i], \
		inDistance[i], \
		inResolution[i], \
		inMosaicity[i], \
		inRms[i]);
	num = split(sp[i], spaceGroups, ",");
	for (j=1; j <= num; j++) {
		if (j == 1) {
		    printf(spaceGroups[j]);
		} else {
		    printf(spaceGroups[j]);
		}
	}
printf("} }\n");
}
printf("  }\n");
}
printf("%s", "}\n");
};

