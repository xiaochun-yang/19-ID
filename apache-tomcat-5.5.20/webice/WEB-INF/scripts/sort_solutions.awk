BEGIN {
	count = 0;
};

{
	# Put each line in an array
	count++;
	num[count] = $0;
};

END {
	
	# Sort the array
	for (i = 2; i <= count; i++) {
		for (j = i; num[j-1] > num[j]; j--) {
			tmp = num[j];
			num[j] = num[j-1];
			num[j-1] = tmp;
		}
	}

	# Print the sorted array
	printf("%d", num[count]);
	for (j = count-1; j >= 1; j--) {
		printf(" %d", num[j]);
	}
	
};

