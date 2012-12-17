BEGIN {
	inTask = 0;
	expType = "";
};

# Enter autoindex task node
/<task name="run_autoindex.csh">/{
	inTask = 1;
};

# Inside task node
{
	if (inTask == 1) {
		# expType
		ret = match($0, "<expType>.*</expType>");
		if (ret > 0) {
			expType = substr($0, RSTART+9, RLENGTH-19);
		};
	}
};

# Exit task node
/<\/task>/{ 
	if (inTask == 1) {
		inTask = 0;
	}
};

END { 
# Encode spaces
gsub(/ /, "\\&nbsp;", expType);
printf("%s", expType);
}

