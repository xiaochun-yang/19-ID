BEGIN {
	count = 0;
};

/File :/{
	file = $3
	count++;
}

/Spot Total :/{
	spots = $4;
}

/Good Bragg Candidates :/{
	braggSpots = $5;
}

/Ice Rings :/{
	iceRings= $4;
}


/Method 1 Resolution :/{
	method1Res= $5;
}

/Method 2 Resolution :/{
	method2Res= $5;
	print "  <image number=\"" count "\" file=\"" file "\" spots=\"" spots "\" braggSpots=\"" braggSpots "\" iceRings=\"" iceRings "\" method1Res=\"" method1Res "\" method2Res=\"" method2Res"\" />"
}


END {
};


