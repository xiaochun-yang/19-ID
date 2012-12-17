BEGIN{
}

/^DIRECTORY/{
	print "DIRECTORY " dir;
	done = 1;
}
/^TEMPLATE/{
	done = 1;
}

/^IMAGE/{
	print "IMAGE " image;
	done = 1;
}

/^GENFILE/{
	done = 1;
}

/^NEWMAT/{
	done = 1;
}

/^MATRIX/{
	print $0;
	print "TARGET " matrix;
	done = 1;
}

{
	if (done == 0) {
		print $0;
	}
	done = 0;
}

END{
}

