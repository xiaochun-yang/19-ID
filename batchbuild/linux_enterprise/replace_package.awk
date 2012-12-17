BEGIN {
	Itcl_version = "3.3";
	BWidget_version = "1.7";
	BLT_version = "2.4";
	Img_version = "1.3";
	Iwidgets_version = "4.0.1";
};

{ 
	if (($1 == "package") && ($2 == "require")) {
   	if ($3 == "Itcl") { 
			print "package require Itcl " Itcl_version;
   	} else if ($3 == "BWidget") { 
			print "package require BWidget " BWidget_version;
   	} else if ($3 == "BLT") { 
			print "package require BLT " BLT_version;
   	} else if ($3 == "Img") { 
			print "package require Img " Img_version;
   	} else if ($3 == "Iwidgets") { 
			print "package require Iwidgets " Iwidgets_version;
   	} else {
			print $0;
		}
	} else {
		print $0;
	}	
}

END {
};


