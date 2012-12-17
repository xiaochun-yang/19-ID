BEGIN {
	score = 0.0;
	resolution = 0.0;
}

/Resolution estimate before indexing:/{
	resolution = $5;
}

/Saturation, Top 50 Peaks:/{
	diffractionStrength = $5;
}

/Ice rings (orange):/{
	iceRings = $4;
}

/Average spot model eccentricity:/{
	spotShape = $5;
}

END {
	# resolution
	if( resolution > 20 ) {
		score=score-2;
	} else if ( resolution <20 && resolution >=8 ) {
		score=score+1;
	} else if ( resolution <8 && resolution >=5 ) {
		score=score+2;
	} else if ( imgreresolutionol_wilson <5 && resolution >=4 ) {
		score=score+3;
	} else if ( resolution <4 && resolution >=3.2 ) {
		score=score+4;
	} else if ( resolution <3.2 && resolution >=2.7 ) {
		score=score+5;
	} else if ( resolution <2.7 && resolution >=2.4 ) {
		score=score+7;
	} else if ( resolution <2.4 && resolution >=2.0 ) {
		score=score+8;
	} else if ( resolution <2.0 && resolution >=1.7 ) {
		score=score+10;
	} else if ( resolution <1.7 && resolution >=1.5 ) {
		score=score+12;
	} else {
		score=score+14;
	}
	
	# diffraction strength in percentage
	if ( diffractionStrength >= 50) {
		score=score+2;
        } else if (diffractionStrength <50 && diffractionStrength>=25) {
		score=score+1;
        }
	
	# penalize ice rings
	if (iceRings>=4 && score>3) { 
		score=score-3;
	} else if (iceRings<4 && iceRings>=2 && score >2) {
		score=score-2;
	} else if (iceRings<2 && iceRings>0 && score >1) {
		score=score-1;
        }
	
	# penalize bad spots and award really good ones
	if (spotShape < 0.5) 
		score=score-2;
#	if (ellip_median > 0.75) 
#		score=score+2;

	if (score <0.1 ) {
		if (resolution >20.0) {
			score=0;
		} else {
			score=1; # anything diffracts at least have a score of 1
		}
	}
	
#	printf("                              Score:%8d\n", score);
	print score;
}

