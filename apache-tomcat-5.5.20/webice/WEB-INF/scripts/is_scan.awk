BEGIN{
	found = 0;
};

{
	if (index($0, "<mad scan=\"true\"") > 0) {
		found = 1;
	}
};

END{
	printf("%d\n", found);
};
