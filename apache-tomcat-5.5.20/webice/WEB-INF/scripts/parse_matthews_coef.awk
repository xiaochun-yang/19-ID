BEGIN {
	best_prob_matth = 0.0;
	best_nmol_in_asu = "";
	best_percent_solvent = "";
}

/nmol_in_asu=/{
	pos1 = index($0, "nmol_in_asu=");
	str = substr($0, pos1+13);
	pos2 = index(str, "\"");
	nmol_in_asu = substr(str, 1, pos2-1) + 0;
}

/percent_solvent=/{
	pos1 = index($0, "percent_solvent=");
	str = substr($0, pos1+17);
	pos2 = index(str, "\"");
	percent_solvent = substr(str, 1, pos2-1) + 0;
}

/prob_matth=/{
	pos1 = index($0, "prob_matth=");
	str = substr($0, pos1+12);
	pos2 = index(str, "\"");
	prob_matth = substr(str, 1, pos2-1) + 0;
	if (best_prob_matth < prob_matth) {
		best_prob_matth = prob_matth;
		best_nmol_in_asu = nmol_in_asu;
		best_percent_solvent = percent_solvent/100.0;
	}
}

END {
	print  best_nmol_in_asu " " best_percent_solvent; 
}

