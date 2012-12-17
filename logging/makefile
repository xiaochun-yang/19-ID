########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: liblogging test

LOGGING_LIB = 
PROJ_NAME =  logging
PROJ_VERSION	 = head

########################################################
#
# DEBUG or RELEASE
# Set DEBUG to TRUE by setting env variable DEBUG=TRUE
#
########################################################

ifeq ($(DEBUG),TRUE)
DEBUG = TRUE
else
DEBUG = FALSE
endif 

########################################################
#
# PURIFY
# Set PURIFY to TRUE by setting env variable PURIFY=TRUE
#
########################################################

ifeq ($(PURIFY),TRUE)
PURIFY = TRUE
DEBUG=TRUE
else
PURIFY = FALSE
endif 


########################################################
#
# Figuring out the platform on which gmake is executed.
# From this point onwards, we will rely on the variable 
# MACHINE for platform specific stuff.
#
########################################################

ifeq ($(OS),Windows_NT)
MACHINE = nt
else

# Assuming that we now must be using some UNIX/Linux flavour
os := $(shell uname)

ifeq ($(os),OSF1)
MACHINE = decunix
else
ifeq ($(os),IRIX64)
MACHINE = irix
else
ifeq ($(os),Linux)

# Check what flavour of hardware we are running Linux on
mach := $(shell uname -m)

ifeq ($(mach),i686)
MACHINE = linux
else
ifeq ($(mach),x86_64)
MACHINE = linux64
else
ifeq ($(mach),ia64)
MACHINE = ia64
endif
endif
endif
endif
endif
endif
endif


########################################################
# NT 
# Note that by default the library will be build with 
# the multi-threaded or debug multi-threaded option 
# (-MT or -MTd).
########################################################

ifeq ($(MACHINE),nt)

SLASH	= /
CC      = cl
LINK    = link
LDFLAGS	=
RM	= rm -rf
MKDIR	= mkdir
LIBEXT	= .lib
EXEEXT  = .exe
CP 	= copy
#CFLAGS	= -nologo -W3 -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"
CFLAGS	= -nologo -W3 -EHsc -DWIN32 -D_MBCS -D_LIB -D_CRT_SECURE_NO_DEPRECATE -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC				+=
STD_LIBS 		+= user32.lib Advapi32.lib wsock32.lib 
LOGGING_LIB		= liblogging.lib


else

########################################################
#
# Any Unix
#
########################################################

SLASH = /
RM	= rm -rf
MKDIR	= mkdir -p
CP	= cp -R
CFLAGS += -o $@ -c -DXOS_PRODUCTION_CODE
LOGGING_LIB	= liblogging.a
LIBEXT	= .a
EXEEXT  =

ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O -DXOS_PRODUCTION_CODE
endif


endif

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)


ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

CC = cc 
LINK = cc
CFLAGS += -w0 -pthread -DDEC_UNIX -D_FILE_OFFSET_BITS=64
STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc

else

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)
ifeq ($(PURIFY),TRUE)
CC      = cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -MP:dsm=off -DIRIX
STD_LIBS += -lpthread -lc


else


ifeq ($(MACHINE),linux)

########################################################
# linux 
########################################################

ifeq ($(PURIFY),TRUE)
CC      = cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
STD_LIBS += -lm -lrt -lpthread -lc


else


ifeq ($(MACHINE),linux64)

########################################################
# linux x86_64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -fPIC -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
STD_LIBS += -lm -lrt -lpthread -lc


else


ifeq ($(MACHINE),ia64)

########################################################
# linux ia64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -fPIC -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
STD_LIBS += -lm -lrt -lpthread -lc


endif
endif
endif
endif
endif


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src


########################################################
# Local liraries
########################################################

XOS_DIR = ..$(SLASH)xos$
XOS_INCLUDE = -I$(XOS_DIR)$(SLASH)src
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)xos$(LIBEXT)

########################################################
# Include directories
########################################################

INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE)


########################################################
# Libraries
########################################################

LIBS += $(XOS_LIB) $(STD_LIBS) 


########################################################
# Object files
########################################################

objs = $(MACHINE)/log_level.o \
	${MACHINE}/log_record.o \
	${MACHINE}/log_formatter.o \
	${MACHINE}/log_simple_formatter.o \
	${MACHINE}/log_token_formatter.o \
	${MACHINE}/log_trace_formatter.o \
	${MACHINE}/log_xml_formatter.o \
	${MACHINE}/log_filter.o \
	${MACHINE}/log_handler_factory.o \
	${MACHINE}/log_handler.o \
	${MACHINE}/log_console_handler.o \
	${MACHINE}/log_udp_handler.o \
	${MACHINE}/log_socket_handler.o \
	${MACHINE}/log_file_handler.o \
	${MACHINE}/logger.o \
	${MACHINE}/log_manager.o \
	${MACHINE}/log_quick.o \
	${MACHINE}/log_native_handler.o \
	${MACHINE}/log_syslog_util.o \
	${MACHINE}/log_syslog_handler.o \
	${MACHINE}/loglib_quick.o
	
	
test_objs = ${MACHINE}/test_log_level.o \
		${MACHINE}/test_log_record.o \
		${MACHINE}/test_log_formatter.o \
		${MACHINE}/test_logger.o \
		${MACHINE}/test_quick.o \
		${MACHINE}/test_syslog.o \
		${MACHINE}/test.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/log_level.o: $(SRC_DIR)$(SLASH)log_level.c $(SRC_DIR)$(SLASH)log_level.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_record.o: $(SRC_DIR)$(SLASH)log_record.c $(SRC_DIR)$(SLASH)log_record.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_formatter.o: $(SRC_DIR)$(SLASH)log_formatter.c $(SRC_DIR)$(SLASH)log_formatter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_simple_formatter.o: $(SRC_DIR)$(SLASH)log_simple_formatter.c $(SRC_DIR)$(SLASH)log_simple_formatter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_token_formatter.o: $(SRC_DIR)$(SLASH)log_token_formatter.c $(SRC_DIR)$(SLASH)log_token_formatter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_trace_formatter.o: $(SRC_DIR)$(SLASH)log_trace_formatter.c $(SRC_DIR)$(SLASH)log_trace_formatter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_xml_formatter.o: $(SRC_DIR)$(SLASH)log_xml_formatter.c $(SRC_DIR)$(SLASH)log_xml_formatter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_quick.o: $(SRC_DIR)$(SLASH)log_quick.c $(SRC_DIR)$(SLASH)log_quick.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/loglib_quick.o: $(SRC_DIR)$(SLASH)loglib_quick.c $(SRC_DIR)$(SLASH)loglib_quick.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_filter.o: $(SRC_DIR)$(SLASH)log_filter.c $(SRC_DIR)$(SLASH)log_filter.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_handler.o: $(SRC_DIR)$(SLASH)log_handler.c $(SRC_DIR)$(SLASH)log_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_console_handler.o: $(SRC_DIR)$(SLASH)log_console_handler.c $(SRC_DIR)$(SLASH)log_console_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_file_handler.o: $(SRC_DIR)$(SLASH)log_file_handler.c $(SRC_DIR)$(SLASH)log_file_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_socket_handler.o: $(SRC_DIR)$(SLASH)log_socket_handler.c $(SRC_DIR)$(SLASH)log_socket_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_udp_handler.o: $(SRC_DIR)$(SLASH)log_udp_handler.c $(SRC_DIR)$(SLASH)log_udp_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/logger.o: $(SRC_DIR)$(SLASH)logger.c $(SRC_DIR)$(SLASH)logger.h
	$(CC) $(CFLAGS) $(INC) $<
	
$(MACHINE)/log_manager.o: $(SRC_DIR)$(SLASH)log_manager.c $(SRC_DIR)$(SLASH)log_manager.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_handler_factory.o: $(SRC_DIR)$(SLASH)log_handler_factory.c $(SRC_DIR)$(SLASH)log_handler_factory.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_native_handler.o: $(SRC_DIR)$(SLASH)log_native_handler.c $(SRC_DIR)$(SLASH)log_native_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/log_syslog_util.o: $(SRC_DIR)$(SLASH)log_syslog_util.c
	$(CC) $(CFLAGS) $(INC) $<
	
$(MACHINE)/log_syslog_handler.o: $(SRC_DIR)$(SLASH)log_syslog_handler.c $(SRC_DIR)$(SLASH)log_syslog_handler.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test_log_level.o: $(SRC_DIR)$(SLASH)test_log_level.c
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test_log_record.o: $(SRC_DIR)$(SLASH)test_log_record.c
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test_log_formatter.o: $(SRC_DIR)$(SLASH)test_log_formatter.c
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test_logger.o: $(SRC_DIR)$(SLASH)test_logger.c
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test_quick.o: $(SRC_DIR)$(SLASH)test_quick.c
	$(CC) $(CFLAGS) $(INC) $<
	
$(MACHINE)/test_syslog.o: $(SRC_DIR)$(SLASH)test_syslog.c
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.c
	$(CC) $(CFLAGS) $(INC) $<


# Printing out gmake info
showinfo:
	@echo ...
	@echo ...
	@echo   
	-@gmake -version
	@echo ...
	@echo ...  

# Create the target directory

makedir:
	-@$(MKDIR) $(MACHINE)



# Cleaning the output files. Can be used before re-build all.

clean: 
	-$(RM) $(MACHINE)$(SLASH)*.o
	-$(RM) $(MACHINE)$(SLASH)*.idb
	-$(RM) $(MACHINE)$(SLASH)*.pdb
	-$(RM) $(MACHINE)$(SLASH).pure.*
	-$(RM) $(MACHINE)$(SLASH)$(LOGGING_LIB)
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)test$(EXEEXT)


# Libary target

liblogging: showinfo makedir $(objs)
	@echo ...
	@echo Making $(LOGGING_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(LOGGING_LIB)" $(objs) $(LIBS)
else
	ar -vr $(MACHINE)$(SLASH)$(LOGGING_LIB) $(objs)
endif

test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(LOGGING_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(LOGGING_LIB) $(LIBS)
endif


# document target

cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: liblogging doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	
