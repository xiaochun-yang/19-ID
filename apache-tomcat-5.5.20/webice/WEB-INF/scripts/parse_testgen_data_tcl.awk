BEGIN {
	start = 0;
	lookForEmptyLine = 0;
	print "  { testgen\n    {";
};

/TESTGEN OPTION/{
	start = 1;
}

/Phi start/{
	lookForEmptyLine = 1;
}

{
	if ((lookForEmptyLine == 1) && ($0 == "")) {
		start = 0;
		lookForEmptyLine = 0;
	}
	
	if (start == 1) {
		print $0
	}
}

END {
	print "    }\n  }";
};

