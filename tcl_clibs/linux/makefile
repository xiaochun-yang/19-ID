##################
# directory macros
##################

# XOS header directory
XOS_DIR = ../../xos/src/

# XOS library directory
XOS_LIB_DIR = ../../xos/linux/

# AUTH include directory
AUTH_DIR = ../../auth/src

# AUTH include directory
AUTH_LIB_DIR = ../../auth/linux/

# Matrix library
NEWMAT_DIR = ../../newmat10/linux/

# Matrix library
NEWMAT_LIB_DIR = ../../newmat10/linux/

# Tcl include directory
TCL_INCLUDE_DIR = /usr/local/include/

# Tcl library directory
TCL_LIB_DIR = /usr/lib/


# JPEG Library directory
JPEG_DIR = /usr/lib/

# Extensions to JPEG library
JPEG_EXT_DIR = ../../jpegsoc/

CODE = ../src/

########################
# preprocessor constants
########################

CPP_CONSTANTS = -DLINUX -Wall


############################
# custom include directories
############################

INCLUDE_DIR = -I./ -I../ -I${TCL_INCLUDE_DIR}  -I${AUTH_DIR} -I${XOS_DIR}  -I${JPEG_DIR} -I${JPEG_EXT_DIR}/src

################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lpthread

# multithreading libraries
THREAD_LIBS = -lc

# tclpro libraries
TCL_LIBS =  ${TCL_LIB_DIR}libtcl8.3.so 

# local libraries
LOCAL_LIBS =  ${JPEG_EXT_DIR}linux/jpegsoc_applack.a ${NEWMAT_LIB_DIR}libnewmat.a  ${AUTH_LIB_DIR}auth.a  ${XOS_LIB_DIR}xos.a ${JPEG_DIR}libjpeg.a

# all the libraries
ALL_LIBS =  ${LOCAL_LIBS} ${THREAD_LIBS} ${TCL_LIBS} ${STD_LIBS}

OBJS = ice.o ice_cal.o calibrate.o ice_auth.o  image_channel.o analyzePeak.o cubgcv.o

CC = g++
CFLAGS = -O


#####################
# target declarations
#####################

tcl_clibs.so: ${OBJS}
	${CC} -shared ${OBJS} ${ALL_LIBS} -o tcl_clibs.so

ice.o : ${CODE}ice.c 
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}ice.c

ice_cal.o : ${CODE}ice_cal.c
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}ice_cal.c

calibrate.o : ${CODE}calibrate.c
	${CC} -c -I${NEWMAT_DIR} ${CODE}calibrate.c

ice_auth.o : ${CODE}ice_auth.c
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}ice_auth.c

image_channel.o : ${CODE}image_channel.c 
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}image_channel.c

analyzePeak.o: ${CODE}analyzePeak.c
	$(CC) -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}analyzePeak.c

cubgcv.o: ${CODE}cubgcv.c
	$(CC) -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}cubgcv.c
