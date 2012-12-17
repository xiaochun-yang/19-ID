BEGIN {
	count = 0;
};

$0 !~ /<defunct>/{
  	# We assume that the process we want to kill
  	# is the group leader. We also want to kill
  	# all of its child processes as well.
  	# Its child processes share the same group
  	# id as this process. 
  	# So here we identify child process by 
  	# looking for a process whose group id
  	# is the same number as the group id of 
  	# the desired process id.
	if ($3 == pgid) {
		if ($1 == pid) {
			printf("%s", $1);
		} else {
			count++;
			children[count] = $1;
		}
	}
    
};

END {
	for (i = 1; i <= count; i++) {
		printf(" %s", children[i]);
	}
};

