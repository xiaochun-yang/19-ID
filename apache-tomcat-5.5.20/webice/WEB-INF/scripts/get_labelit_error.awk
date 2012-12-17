{ 
	ret = match($0, "<error>.*</error>");
	if (ret > 0) {
		print $0;
	} 
}

