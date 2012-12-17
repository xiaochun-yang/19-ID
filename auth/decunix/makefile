
##################
# directory macros
##################

# source directory
CODE_DIR = ../src

# XOS directory
XOS_DIR = ../../xos/

# XOS header directory
XOS_HEADER_DIR = ${XOS_DIR}/src/


########################
# preprocessor constants
########################

CPP_CONSTANTS = -DDEC_UNIX 

############################
# custom include directories
############################

INCLUDE_DIR = -I{CODE_DIR} -I${XOS_HEADER_DIR}  


################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lrt -lX11 -lpthread

# multithreading libraries
THREAD_LIBS =  -lc

# local libraries
LOCAL_LIBS = ${XOS_LIB_DIR}/xos.a

# all the libraries
ALL_LIBS =  ${LOCAL_LIBS} ${THREAD_LIBS} ${STD_LIBS}

# objects to build
OBJS = auth.o

CC = cc
CFLAGS =  -w0 -pthread


#####################
# target declarations
#####################

auth.a : ${OBJS}
	ar -vr $@ ${OBJS}

auth.o : ${CODE_DIR}/auth.c
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE_DIR}/auth.c

