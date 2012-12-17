BEGIN {
}

/LoginFilter/{
	url = $8
	gsub("8445", "8082", url);
	gsub("https", "http", url);
	pos = index(url, "&dcsStrategyFile=");
	if (pos > 0) {
		url = substr(url, 1, pos-1);
	}
	print "java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL \"" url "\"";
	print "sleep 3"
}

END {
}

