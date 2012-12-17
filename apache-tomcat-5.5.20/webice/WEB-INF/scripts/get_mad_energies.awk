BEGIN {
	inTask = 0;
	en["inflection"] = 0.0;
	en["peak"] = 0.0;
	en["remote"] = 0.0;
};

# Enter autoindex task node
/<task name="run_autoindex.csh">/{
	inTask = 1;
};

# Inside task node
{
	if (inTask == 1) {
			
		# imageDir
		if ($1 == "<mad") {
			split($2, arr, "=");
			str = substr(arr[2], 2, length(arr[2])-2);
			if (length(str) > 0) {
				split(str, arr, "-");
				element = arr[1];
				edge = arr[2];
			}
			split($3, arr, "=");
			en[arr[1]] = substr(arr[2], 2, length(arr[2])-2);
			split($4, arr, "=");
			en[arr[1]] = substr(arr[2], 2, length(arr[2])-2);
			split($5, arr, "=");
			en[arr[1]] = substr(arr[2], 2, length(arr[2])-2);
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
printf("%.2f %.2f %.2f %s %s\n", en["inflection"], en["peak"], en["remote"], element, edge);
}

