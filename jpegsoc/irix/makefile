
##################
# directory macros
##################

# source code
CODE_DIR = ../src

# XOS directory
XOS_DIR = ../../xos/

# XOS header directory
XOS_HEADER_DIR = ${XOS_DIR}/src/

# XOS library
XOS_LIB_DIR = ${XOS_DIR}/irix/

# JPEG directory
JPEG_DIR = /home/scottm/code/working/jpeg-6b

# JPEG header directory
JPEG_HEADER_DIR = ../jpegsoc/src

########################
# preprocessor constants
########################

#CPP_CONSTANTS = -DDEC_UNIX -DSEC_BASE -DSEC_NET
CPP_CONSTANTS = -DIRIX -DAPPLACK


############################
# custom include directories
############################

INCLUDE_DIR = -I${XOS_HEADER_DIR} -I${CODE_DIR} -I${JPEG_HEADER_DIR} -I${JPEG_DIR} -I/usr/include 


################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lrt 

# multithreading libraries
THREAD_LIBS =  -lc

# local libraries
LOCAL_LIBS = ${XOS_DIR}xos.a ${JPEG_DIR}libjpeg.a

# all the libraries
ALL_LIBS =  ${LOCAL_LIBS} ${THREAD_LIBS} ${STD_LIBS} 

OBJS = jsndrcv.o jdatasrcsock_applack.o jdatadstsock_applack.o

CC = cc
CFLAGS = -O

#####################
# target declarations
#####################

jpegsoc_applack.a : ${OBJS}
	ar -vr $@ ${OBJS}

jsndrcv.o : ${CODE_DIR}/jsndrcv.c
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE_DIR}/jsndrcv.c

jdatasrcsock_applack.o : ${CODE_DIR}/jdatasrcsock.c
	${CC} -c -o jdatasrcsock_applack.o ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE_DIR}/jdatasrcsock.c

jdatadstsock_applack.o : ${CODE_DIR}/jdatadstsock.c
	${CC} -c -o jdatadstsock_applack.o ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE_DIR}/jdatadstsock.c

clean:
	rm -rf *.a *.o
