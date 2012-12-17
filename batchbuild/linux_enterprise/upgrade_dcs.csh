#!/bin/csh -f

set SCRIPT_DIR = `pwd`
set DCS_DIR = "/usr/local/dcs"


###########
# tcl_clibs
###########

cd ${DCS_DIR}/tcl_clibs

# Fix makefile
# Use tcl8.4 instead of 8.3
awk '{ if ((NR == 288) && (match($0, /TCL_LIB/) > 0)) { \
print "TCL_LIB = /usr/lib/libtcl8.4$(SHAREDEXT) /usr/lib/libtk8.4$(SHAREDEXT)"; \
} else { print $0; } \
}' makefile > mytmp
mv mytmp makefile


# Fix src/analyzePeak.c
# Use const char* instead of char*
awk '{ if ((NR == 160) && (match($0, /const/) <= 0)) { \
gsub(/char/, "const char"); print; \
} else { print $0; } \
}' src/analyzePeak.c > mytmp
mv mytmp src/analyzePeak.c



# Fix src/ice_cal.c
# Use const char* instead of char*
awk '{ if ((NR >= 39) && (NR <= 42) && (match($0, /const/) <= 0)) { \
gsub(/char/, "const char"); print; \
} else { print $0; } \
}' src/ice_cal.c > mytmp
mv mytmp src/ice_cal.c

# Use const char* instead of char*
awk '{ if ((NR >= 72) && (NR <= 75) && (match($0, /const/) <= 0)) { \
gsub(/char/, "const char"); print; \
} else { print $0; } \
}' src/ice_cal.c > mytmp
mv mytmp src/ice_cal.c


# Fix src/image_channel.c
# Use const char* instead of char*
awk '{ if ((NR >= 285) && (NR <= 286) && (match($0, /const/) <= 0)) { \
gsub(/char/, "const char"); print; \
} else { print $0; } \
}' src/image_channel.c > mytmp
mv mytmp src/image_channel.c

# Use const char* instead of char*
awk '{ if (((NR == 291) || (NR == 378) || (NR == 432)) && (match($0, /const/) <= 0)) { \
gsub(/char/, "const char"); print; \
} else { print $0; } \
}' src/image_channel.c > mytmp
mv mytmp src/image_channel.c


# Need additional arg
awk '{ if (NR == 417) { \
gsub(/channel->width, channel->height );/, "channel->width, channel->height, TK_PHOTO_COMPOSITE_SET);"); print; \
} else { print $0; } \
}' src/image_channel.c > mytmp
mv mytmp src/image_channel.c


# Use XOS_WAIT_SUCCESS instead of XOS_SUCCESS
awk '{ if ((NR == 542) || (NR == 591)) { \
gsub(/XOS_SUCCESS/, "XOS_WAIT_SUCCESS"); print; \
} else { print $0; } \
}' src/image_channel.c > mytmp
mv mytmp src/image_channel.c

# Use const char* instead of char*
awk '{ if ((NR == 670) && (match($0, /const/) <= 0)) { \
gsub(/char \* channelName;/, "const char * channelName = argv[1];"); print; \
} else if ((NR == 683) && (match($0, /channelName/) > 0)) { \
} else { print $0; } \
}' src/image_channel.c > mytmp
mv mytmp src/image_channel.c


# Fix src/tcl_macros.h
# Use const char* instead of char*
awk '{ if (match($0, /Tcl_Interp \*interp,int argc, char \*argv\[\] )/) > 0) { \
gsub(/char/, "const char"); print; } else { print $0;} \
}' src/tcl_macros.h > mytmp
mv mytmp src/tcl_macros.h


######
# DCSS
######

cd ${DCS_DIR}/dcss

# Fix makefile
# Use tcl8.4 instead 8.3
awk '{ if ((NR == 244) && (match($0, /TCL_LIB/) > 0)) { \
print "TCL_LIB = /usr/lib/libtcl8.4.so /usr/lib/libtk8.4.so /usr/lib/itcl3.3/libitcl3.3.so"; \
} else if ((NR >= 246) && (NR <= 248) && (match($0, /\#/) <= 0)) { \
print "#" $0; \
} else { print $0; } \
}' makefile > mytmp
mv mytmp makefile



