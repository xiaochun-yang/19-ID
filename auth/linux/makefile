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

CPP_CONSTANTS = -DLINUX


############################
# custom include directories
############################

INCLUDE_DIR =  -I../ -I${XOS_HEADER_DIR}


################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lX11 

# multithreading libraries
THREAD_LIBS = -lpthread -lc

# local libraries
LOCAL_LIBS = ${XOS_LIB_DIR}/xos.a 

# all the libraries
ALL_LIBS =  ${LOCAL_LIBS} ${THREAD_LIBS} ${STD_LIBS}

OBJS = auth.o

CC = cc
CFLAGS = -O


#####################
# target declarations
#####################

auth.a : ${OBJS}
	ar -vr $@ ${OBJS}

auth.o : ${CODE_DIR}/auth.c
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE_DIR}/auth.c


