BEGIN {
  runStatus = "unknown"; 
  lastimage = "unknown";
  firstimage = "unknown";
  dcsrunLabel = "unknown";
  dcsimageName = "unknown";
  dcsimageDir = "unknown";
  startingPhi = "unknown";
  endPhi = "unknown";
  deltaPhi = "unknown";
  detectorDistance = "unknown";
  numEnergy = "unknown"; 
  energy1 = "unknown";
  energy2 = "unknown";
  energy3 = "unknown";
  energy4 = "unknown";
  energy5 = "unknown";
  inverse = "unknown";
  expType= "unknown";
}

/collecting/ {
  runStatus = $2;
  lastimage = $3 - 1;
  firstimage = $7;
  dcsrunLabel = $4;
  dcsimageName = $5;
  dcsimageDir = $6;
  startingPhi = $9;
  endPhi = $10;
  deltaPhi = $11;
  detectorDistance = $12;
  numEnergy = $17;
  energy1 = $18;
  energy2 = $19;
  energy3 = $20;
  energy4 = $21;
  energy5 = $22;
  inverse = $24;
}

END {

  expType = native;
  if ( (numEnergy == 1) && (inverse == 1) ) {
    expType = SAD;
  } else if (numEnergy > 1) {
    expType = MAD;
  }

  print runStatus" "lastimage" "firstimage" "dcsrunLabel" "dcsimageName" "dcsimageDir" "startingPhi" "endPhi" "deltaPhi" " \
    detectorDistance" "numEnergy" "energy1" "energy2" "energy3" "energy4" "energy5" "inverse" "expType ;
}
