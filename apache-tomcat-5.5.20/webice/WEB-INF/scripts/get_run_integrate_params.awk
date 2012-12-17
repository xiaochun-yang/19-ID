BEGIN {
	inTask = 0;
	integrate = "best";
	generateStrategy = "yes";
	additionalSols = "";
}; 

# Enter autoindex task node
/<task name="run_integrate.csh">/{
	inTask = 1;
};

# Inside task node
{
	if (inTask == 1) {
						
		# integrate option
		ret = match($0, "<integrate>.*</integrate>");
		if (ret > 0) {
			integrate = substr($0, RSTART+11, RLENGTH-23);
		};
		
		# Strategy
		ret = match($0, "<generate_strategy>.*</generate_strategy>");
		if (ret > 0) {
			generateStrategy = substr($0, RSTART+19, RLENGTH-39);
		};
		
		# Additional solutions to integrate
		ret = match($0, "<additional_solutions>.*</additional_solutions>");
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
printf("%s %s %s", integrate, generateStrategy, additionalSols);

}

