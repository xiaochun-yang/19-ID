
##################
# targets
##################

default: makedir logging
all: logging test

##################
# directory macros
##################



########################
# preprocessor constants
########################

CPP_CONSTANTS = -DLINUX -DXOS_PRODUCTION_CODE

############################
# Platform dependent variables
############################
PLATFORM = linux
LIBEXT = .a

############################
# Directories
# All directories are relative to BASE_DIR
############################
BASE_DIR = ../..
XOS_DIR = ${BASE_DIR}/xos
LOGGING_DIR = ${BASE_DIR}/logging

INCLUDE_DIR = -I${LOGGING_DIR}/src -I${XOS_DIR}/src
CODE = ${LOGGING_DIR}/src
OUT_DIR = ${LOGGING_DIR}/${PLATFORM}


################
# Shell commands
################
MKDIR = mkdir

################
# library macros
################

# standard UNIX libraries
STD_LIBS = -lm -lrt

# multithreading libraries
THREAD_LIBS = -lpthread -lc

# local libraries
LOCAL_LIBS = ${OUT_DIR}/logging.a ${XOS_DIR}/${PLATFORM}/xos.a

# all the libraries
ALL_LIBS = ${STD_LIBS} ${LOCAL_LIBS} ${THREAD_LIBS}

OBJS = log_level.o \
	log_record.o \
	log_formatter.o \
	log_simple_formatter.o \
	log_formatter_factory.o \
	log_filter.o \
	log_handler.o \
	log_console_handler.o \
	logger.o \
	log_handler_factory.o
	
objs = ${OUT_DIR}/log_level.o \
	${OUT_DIR}/log_record.o \
	${OUT_DIR}/log_formatter.o \
	${OUT_DIR}/log_simple_formatter.o \
	${OUT_DIR}/log_formatter_factory.o \
	${OUT_DIR}/log_filter.o \
	${OUT_DIR}/log_handler.o \
	${OUT_DIR}/log_console_handler.o \
	${OUT_DIR}/logger.o \
	${OUT_DIR}/log_handler_factory.o


TEST_OBJS = test_log_level.o \
		test_log_record.o \
		test_log_formatter.o \
		test_logger.o \
		test.o
		
test_objs = ${OUT_DIR}/test_log_level.o \
		${OUT_DIR}/test_log_record.o \
		${OUT_DIR}/test_log_formatter.o \
		${OUT_DIR}/test_logger.o \
		${OUT_DIR}/test.o

CC = cc
#CFLAGS += ${CPP_CONSTANTS} ${INCLUDE_DIR}
#LIBS +=  ${ALL_LIBS}


#####################
# Compiling instructions
#####################


%.o: %.c
	${CC} -o ${OUT_DIR}/$@ -c ${CPP_CONSTANTS} ${INCLUDE_DIR} $<


	
#####################
# target declarations
#####################

makedir:
	-${MKDIR} ${OUT_DIR}

logging: ${OBJS}
	ar -vr ${OUT_DIR}/$@${LIBEXT} ${objs}

test: ${TEST_OBJS}
	${CC} -o${OUT_DIR}/$@ -lz ${test_objs} ${ALL_LIBS}
		
	
clean:
	-${RM} ${OUT_DIR}/*.o 
	-${RM} ${OUT_DIR}/*.obj
	-${RM} ${OUT_DIR}/*.a 
	-${RM} ${OUT_DIR}/*.so
	-${RM} ${OUT_DIR}/*.lib
	-${RM} ${OUT_DIR}/*.dll
	-${RM} ${OUT_DIR}/*.exe
	-${RM} ${OUT_DIR}/test
