BEGIN {
	inTask = 0;
	generateStrategy = "yes";
	additionalSols = "";
}; 

# Enter autoindex task node
/<task name="run_integrate_additional_solutions.csh">/{
	inTask = 1;
};

# Inside task node
{
	if (inTask == 1) {
								
		# Strategy
		ret = match($0, "<generate_strategy>.*</generate_strategy>");
		if (ret > 0) {
			generateStrategy = substr($0, RSTART+19, RLENGTH-39);
		};
		
		# Additional solutions to integrate
		ret = match($0, "<solutions>.*</solutions>");
		if (ret > 0) {
			additionalSols = substr($0, RSTART+22, RLENGTH-45);
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
printf("%s %s", generateStrategy, additionalSols);

}

