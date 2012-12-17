# Returns image index from the given image filename
# Image filename is in the following format xxx_NNN.img,
# where xxx is any arbitrary string and NNN is 
# an image index preceded by 0s.
BEGIN {
    imgIndex = 1;
};

/_[0123456789]+\./{
	split($1, a, ".");
	extLength = length(a[2]);
    str = substr($1, length($1)-extLength-3, 3);
    if (substr(str, 1, 2) == "00") {
    	imgIndex = substr(str, 3, 1); 
    } else if ( substr(str, 1, 1) == "0") {
    	imgIndex = substr(str, 2, 2); 
    } else {
    	imgIndex = str;
    }
    
};

END {
    print imgIndex
};


