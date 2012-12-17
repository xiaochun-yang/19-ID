BEGIN {
	lineNum = 0;
}

/width\| Exposure/{
	lineNum = NR;
}
NR==lineNum+2{
      width = $4;
      exposureTime = $5;
}

/^ I\/Sigma/ {
  i2si= $5;
}

/^ Anomalous data/{
  anom=$4;
}
/^ Phi_start =/{
	phiMin = $3;
	phiMax = $7
};

/^ Overall Completeness =/{
  complete = $4;
  redundant = $8;
};



END {
  if (anom=="No") {
    print "width =" width "\nexposureTime =" exposureTime;
    print "phiMin_u ="  phiMin "\nphiMax_u =" phiMax "\ncompleteness_u =" complete "\nredundancy_u =" redundant "\noverall_IsigI_u =" i2si}
  else {print "phiMin_a ="  phiMin "\nphiMax_a =" phiMax "\ncompleteness_a =" complete "\nredundancy_a =" redundant "\noverall_IsigI_a =" i2si}
};
