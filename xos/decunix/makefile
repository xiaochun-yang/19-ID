
##################
# directory macros
##################



########################
# preprocessor constants
########################

CPP_CONSTANTS = -DDEC_UNIX -DXOS_PRODUCTION_CODE


############################
# custom include directories
############################

INCLUDE_DIR = ../src/
CODE = ../src/

################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lrt

# multithreading libraries
THREAD_LIBS = -lpthread -lmach -lexc -lc

# local libraries
LOCAL_LIBS = 

# all the libraries
ALL_LIBS = ${STD_LIBS} ${LOCAL_LIBS} ${THREAD_LIBS}

OBJS = xos.o xos_hash.o xos_semaphore_set.o xos_socket.o xos_log.o

CC = cc
CFLAGS = -w0 -pthread 


#####################
# target declarations
#####################

xos.a : ${OBJS}
	ar -vr $@ ${OBJS}

xos.o : ${CODE}/xos.c ${CODE}/xos.h
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}/xos.c

xos_hash.o : ${CODE}/xos_hash.c ${CODE}/xos.h ${CODE}/xos_hash.h
	${CC}  -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}/xos_hash.c

xos_semaphore_set.o : ${CODE}/xos_semaphore_set.c ${CODE}/xos.h ${CODE}/xos_semaphore_set.h
	${CC}  -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}/xos_semaphore_set.c

xos_socket.o : ${CODE}/xos_socket.c ${CODE}/xos.h ${CODE}/xos_socket.h
	${CC}  -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}/xos_socket.c

xos_log.o : ${CODE}/xos_log.c ${CODE}/xos_log.h
	${CC} -c ${CFLAGS} ${CPP_CONSTANTS} ${INCLUDE_DIR} ${CODE}/xos_log.c

clean:
	rm -rf *.a *.o
	
