########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: dhs


PROJ_NAME = dhs
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

SLASH	= \\
CC      = cl
CXX     = cl
LINK    = link
LDFLAGS	=
EXEFLAGS = -nologo -subsystem:console -incremental:no -machine:I386
RM	= rm -rf
MKDIR	= mkdir
CP 	= copy
CFLAGS	= -TP -nologo -W3 -GR -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"
CPPFLAGS =
LIBEXT	= .lib
EXEEXT  = .exe

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC		+=
STD_LIBS 	+= wsock32.lib Advapi32.lib user32.lib

# XOS_CPP
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_INCLUDE = -I${XOS_CPP_DIR}$(SLASH)src
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# HTTP_CPP
HTTP_CPP_DIR = ..$(SLASH)http_cpp
HTTP_CPP_INCLUDE = -I${HTTP_CPP_DIR}$(SLASH)src
HTTP_CPP_LIB = $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libhttp-cpp$(LIBEXT)

# AUTH
AUTH_DIR = ..$(SLASH)auth
AUTH_HEADER_DIR = $(AUTH_DIR)$(SLASH)src
AUTH_INCLUDE = -I$(AUTH_HEADER_DIR)
AUTH_LIB =

# DIFFIMAGE
DIFFIMAGE_DIR = ..$(SLASH)diffimage
DIFFIMAGE_HEADER_DIR = $(DIFFIMAGE_DIR)$(SLASH)src
DIFFIMAGE_INCLUDE = -I$(DIFFIMAGE_HEADER_DIR)
DIFFIMAGE_LIB =


else

########################################################
#
# Any Unix
#
########################################################

SLASH = /
RM	= rm -rf
MKDIR	= mkdir -p
CP 	= cp -R
#CFLAGS += -o $@ -DDISABLE_AUTHENTICATION
CFLAGS += -o $@
CPPFLAGS =
LIBEXT	= .a
EXEEXT  =

ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O -DXOS_PRODUCTION_CODE
endif

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)

# CBF directory
CBF_DIR = ../cbflib
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.a

# AUTH
AUTH_DIR = ..$(SLASH)auth
AUTH_HEADER_DIR = $(AUTH_DIR)$(SLASH)src
AUTH_INCLUDE = -I$(AUTH_HEADER_DIR)
AUTH_LIB = $(AUTH_DIR)$(SLASH)$(MACHINE)$(SLASH)auth$(LIBEXT)

# DIFFIMAGE
DIFFIMAGE_DIR = ..$(SLASH)diffimage
DIFFIMAGE_HEADER_DIR = $(DIFFIMAGE_DIR)$(SLASH)src
DIFFIMAGE_INCLUDE = -I$(DIFFIMAGE_HEADER_DIR)
DIFFIMAGE_LIB = $(DIFFIMAGE_DIR)$(SLASH)$(MACHINE)$(SLASH)diffimage$(LIBEXT)


ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

CC = cxx
CXX = cxx
LINK = cxx
TEMPLATES_DIR = ./$(MACHINE)/cxx_repository
TEMPLATES_OBJS = $(TEMPLATES_DIR)/*.o
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET -D_FILE_OFFSET_BITS=64
CPPFLAGS = -x cxx
# For building exe
LDFLAGS = -ptr $(TEMPLATES_DIR) \
		-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
		

STD_LIBS += $(TK_LIBS) -lm -lrt -lpthread -lc -lmach -lexc
INC 	+= -I/usr/include/cxx \
           -I/usr/local/include


# TK
TK_DIR = /usr/local/include
TK_INCLUDE = -I/usr/local/include
TK_LIB =

# TCL
TCL_DIR = ..$(SLASH)auth
TCL_INCLUDE = -I/usr/local/include
TCL_LIB =

#STD_LIBS += -ltk8.3 \
#          -ltcl8.3 \
#          -litcl3.2 \
#          -lX11


# DALI
# Dali Image Libraries
DALIIMAGE_DIR =
DALIIMAGE_INCLUDE =
DALIIMAGE_LIBS =


endif

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)
ifeq ($(PURIFY),TRUE)
CC      = purify CC
CXX     = purify CC
LINK    = purify CC
else
CC      = CC
CXX     = CC
LINK    = CC
endif
#Using optimization level O2 on irix causes problems 3/07/06
CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET -O1 \
		  -xc++ -MP:dsm=off -LANG:std=on \
		  -LANG:exceptions=on -no_prelink -ptused 
		  
CPPFLAGS = 
LDFLAGS =
STD_LIBS += -lC -lc -lm -lpthread
INC 	+= -I/usr/include/CC \
           -I/usr/local/include



# DALI
# Dali Image Libraries
DALIIMAGE_DIR =
DALIIMAGE_INCLUDE =
DALIIMAGE_LIBS =

endif


ifeq ($(MACHINE),linux)

########################################################
# linux 
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify g++
CXX     = purify g++
LINK    = purify g++
else
CC      = g++
CXX     = g++
LINK    = g++
endif
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT \
			-DWITH_CAMERA_SUPPORT -D_FILE_OFFSET_BITS=64
			
CPPFLAGS = -Wall
LDFLAGS =

STD_LIBS += -lm -lrt -lpthread -lc -lz


# TK
TK_DIR = 
TK_INCLUDE =
TK_LIB =

# TCL
TCL_DIR = 
TCL_INCLUDE = 
TCL_LIB =

#DALI
# Dali Image Libraries
DALIIMAGE_DIR = ../dali
DALIIMAGE_INCLUDE = -I$(DALIIMAGE_DIR)/include 
DALIIMAGE_LIBS = -L$(DALIIMAGE_DIR)/$(MACHINE) -ldvmjpeg -ldvmpnm -ldvmcolor -ldvmvision -ldvmbasic

endif


ifeq ($(MACHINE),linux64)

########################################################
# linux x86_64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify g++
CXX     = purify g++
LINK    = purify g++
else
CC      = g++
CXX     = g++
LINK    = g++
endif
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT \
			-DWITH_CAMERA_SUPPORT -D_FILE_OFFSET_BITS=64
			
CPPFLAGS = -Wall
LDFLAGS =

STD_LIBS += -lm -lrt -lpthread -lc -lz


# TK
TK_DIR = 
TK_INCLUDE = 
TK_LIB =

# TCL
TCL_DIR = 
TCL_INCLUDE = 
TCL_LIB =

#DALI
# Dali Image Libraries
DALIIMAGE_DIR = ../dali
DALIIMAGE_INCLUDE = -I$(DALIIMAGE_DIR)/include 
DALIIMAGE_LIBS = -L$(DALIIMAGE_DIR)/$(MACHINE) -ldvmjpeg -ldvmpnm -ldvmcolor -ldvmvision -ldvmbasic

endif
ifeq ($(MACHINE),ia64)

########################################################
# linux ia64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify g++
CXX     = purify g++
LINK    = purify g++
else
CC      = g++
CXX     = g++
LINK    = g++
endif
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT \
			-DWITH_CAMERA_SUPPORT -D_FILE_OFFSET_BITS=64
			
CPPFLAGS = -Wall
LDFLAGS =

STD_LIBS += -lm -lrt -lpthread -lc -lz


# TK
TK_DIR = 
TK_INCLUDE = 
TK_LIB =

# TCL
TCL_DIR = 
TCL_INCLUDE = 
TCL_LIB =

#DALI
# Dali Image Libraries
DALIIMAGE_DIR = ../dali
DALIIMAGE_INCLUDE = -I$(DALIIMAGE_DIR)/include 
DALIIMAGE_LIBS = -L$(DALIIMAGE_DIR)/$(MACHINE) -ldvmjpeg -ldvmpnm -ldvmcolor -ldvmvision -ldvmbasic

endif

#endif any unix
endif 


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src
TEST_DIR = .$(SLASH)src

########################################################
# Local liraries
########################################################

# XOS
XOS_DIR = ..$(SLASH)xos
XOS_HEADER_DIR = $(XOS_DIR)$(SLASH)src
XOS_INCLUDE = -I$(XOS_HEADER_DIR)
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)

# logging
LOGGING_DIR = ..$(SLASH)logging
LOGGING_INCLUDE = -I${LOGGING_DIR}$(SLASH)src
LOGGING_LIB = $(LOGGING_DIR)$(SLASH)$(MACHINE)$(SLASH)liblogging$(LIBEXT)

# XOS_CPP
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_HEADER_DIR = $(XOS_CPP_DIR)$(SLASH)src
XOS_CPP_INCLUDE = -I$(XOS_CPP_HEADER_DIR)
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# HTTP_CPP
HTTP_CPP_DIR = ..$(SLASH)http_cpp
HTTP_CPP_HEADER_DIR = $(HTTP_CPP_DIR)$(SLASH)src
HTTP_CPP_INCLUDE = -I$(HTTP_CPP_HEADER_DIR)
HTTP_CPP_LIB = $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libhttp-cpp$(LIBEXT)

# AUTH_CLIENT
AUTH_CLIENT_DIR = ..$(SLASH)auth_client
AUTH_CLIENT_HEADER_DIR = $(AUTH_CLIENT_DIR)$(SLASH)src
AUTH_CLIENT_INCLUDE = -I$(AUTH_CLIENT_HEADER_DIR)
AUTH_CLIENT_LIB = $(AUTH_CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)libauthclient$(LIBEXT)

DCSCONFIG_DIR = ..$(SLASH)dcsconfig$
DCSCONFIG_INCLUDE = -I$(DCSCONFIG_DIR)$(SLASH)src
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)

# XFORM
XFORM_DIR = ..$(SLASH)xform
XFORM_HEADER_DIR = $(XFORM_DIR)
XFORM_INCLUDE = -I$(XFORM_HEADER_DIR)


########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(TK_INCLUDE) \
	$(TCL_INCLUDE) \
	$(AUTH_INCLUDE) \
	$(AUTH_CLIENT_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(DIFFIMAGE_INCLUDE) \
	$(XFORM_INCLUDE) \
	$(CBF_INCLUDE) \
	$(DCSCONFIG_INCLUDE) \
	$(DALIIMAGE_INCLUDE)
	


########################################################
# Libraries
########################################################

#DCSCONFIG_LIB must come first in the list of libraries
LIBS += $(DCSCONFIG_LIB) \
      $(LOGGING_LIB) \
      $(AUTH_CLIENT_LIB) \
		$(DIFFIMAGE_LIB) \
		$(HTTP_CPP_LIB) \
		$(XOS_CPP_LIB) \
		$(AUTH_LIB) \
		$(XOS_LIB) \
		$(XOS_CPP_LIB) \
		$(CBF_LIB) \
		$(DALIIMAGE_LIBS) \
		$(STD_LIBS)



########################################################
# Object files
########################################################
	
objs += $(MACHINE)/dhs_main.o \
       $(MACHINE)/xform.o \
       $(MACHINE)/dhs_network.o \
       $(MACHINE)/dhs_monitor.o \
       $(MACHINE)/dhs_database.o \
       $(MACHINE)/dhs_dcs_messages.o \
       $(MACHINE)/dhs_motor_messages.o \
       $(MACHINE)/dhs_config.o \
       $(MACHINE)/impFileAccess.o \
       $(MACHINE)/dhs_threads.o


ifneq ($(MACHINE),nt)
objs += $(MACHINE)/dhs_Quantum315.o \
       $(MACHINE)/dhs_Quantum210.o \
       $(MACHINE)/dhs_dmc2180.o \
       $(MACHINE)/dmc2180API.o \
       $(MACHINE)/dhsMar345.o \
       $(MACHINE)/safeFile.o \
       $(MACHINE)/dhs_Quantum4.o
endif


ifeq ($(MACHINE),linux)
objs += $(MACHINE)/marCcd.o \
       	$(MACHINE)/dhs_Camera.o \
       	$(MACHINE)/imgCentering.o
endif

ifeq ($(MACHINE),linux64)
objs += $(MACHINE)/marCcd.o \
       	$(MACHINE)/dhs_Camera.o \
       	$(MACHINE)/imgCentering.o
endif

ifeq ($(MACHINE),ia64)
objs += $(MACHINE)/marCcd.o \
       	$(MACHINE)/dhs_Camera.o \
       	$(MACHINE)/imgCentering.o
endif

ifeq ($(MACHINE),irix)
objs += $(MACHINE)/marCcd.o
endif

test_dhs_objs = $(MACHINE)/test_dhs.o
test_imgsrv_objs = $(MACHINE)/test_imgsrv.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/dcss_main.o: $(SRC_DIR)$(SLASH)dcss_main.c \
              $(SRC_DIR)$(SLASH)dcss_device.h \
              $(SRC_DIR)$(SLASH)dcss_hardware_client.h \
              $(SRC_DIR)$(SLASH)dcss_scripting.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/safeFile.o : ${SRC_DIR}$(SLASH)safeFile.cc ${SRC_DIR}$(SLASH)safeFile.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/xform.o : $(XFORM_HEADER_DIR)$(SLASH)xform.c \
			$(XFORM_HEADER_DIR)$(SLASH)xform.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_main.o : $(SRC_DIR)$(SLASH)dhs_main.cc \
			$(SRC_DIR)$(SLASH)dhs_network.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(SRC_DIR)$(SLASH)dhs_config.h \
			$(SRC_DIR)$(SLASH)dhs_motor_messages.h \
			$(SRC_DIR)$(SLASH)dhs_monitor.h \
			$(XOS_HEADER_DIR)$(SLASH)xos.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_config.o : $(SRC_DIR)$(SLASH)dhs_config.cc \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(XOS_HEADER_DIR)$(SLASH)xos.h \
			$(SRC_DIR)$(SLASH)dhs_threads.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(SRC_DIR)$(SLASH)dhs_config.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_threads.o : $(SRC_DIR)$(SLASH)dhs_threads.cc \
			$(SRC_DIR)$(SLASH)dhs_threads.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(XOS_HEADER_DIR)$(SLASH)xos.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_network.o : $(SRC_DIR)$(SLASH)dhs_network.cc \
                $(SRC_DIR)$(SLASH)dhs_network.h \
                $(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
                $(SRC_DIR)$(SLASH)dhs_database.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_monitor.o : $(SRC_DIR)$(SLASH)dhs_monitor.cc \
                $(SRC_DIR)$(SLASH)dhs_monitor.h \
                $(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
                $(SRC_DIR)$(SLASH)dhs_database.h \
                $(SRC_DIR)$(SLASH)dhs_messages.h \
                $(SRC_DIR)$(SLASH)dhs_network.h \
                $(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
                $(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_database.o : $(SRC_DIR)$(SLASH)dhs_database.cc \
				$(SRC_DIR)$(SLASH)dcs.h \
				$(XOS_HEADER_DIR)$(SLASH)xos.h \
				$(SRC_DIR)$(SLASH)dhs_database.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_hash.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_dcs_messages.o : $(SRC_DIR)$(SLASH)dhs_dcs_messages.cc \
				$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
				$(SRC_DIR)$(SLASH)dhs_messages.h \
				$(SRC_DIR)$(SLASH)dhs_motor_messages.h \
				$(SRC_DIR)$(SLASH)dhs_database.h \
				$(SRC_DIR)$(SLASH)dhs_network.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_motor_messages.o: $(SRC_DIR)$(SLASH)dhs_motor_messages.cc \
				$(SRC_DIR)$(SLASH)dhs_motor_messages.h \
				$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
				$(SRC_DIR)$(SLASH)dhs_messages.h \
				$(SRC_DIR)$(SLASH)dhs_database.h \
				$(SRC_DIR)$(SLASH)dhs_network.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhsMar345.o: $(SRC_DIR)$(SLASH)dhsMar345.cc \
				$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
				$(SRC_DIR)$(SLASH)dhs_messages.h \
				$(SRC_DIR)$(SLASH)dcs.h \
				$(SRC_DIR)$(SLASH)dhs_database.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
				$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_Quantum4.o: $(SRC_DIR)$(SLASH)dhs_Quantum4.cc \
			$(SRC_DIR)$(SLASH)dhs_Quantum4.h \
			$(DIFFIMAGE_HEADER_DIR)$(SLASH)libimage.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XFORM_HEADER_DIR)$(SLASH)xform.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_Quantum315.o : $(SRC_DIR)$(SLASH)dhs_Quantum315.cc \
			$(SRC_DIR)$(SLASH)dhs_Quantum315.h \
			$(DIFFIMAGE_HEADER_DIR)$(SLASH)libimage.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XFORM_HEADER_DIR)$(SLASH)xform.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_Quantum210.o : $(SRC_DIR)$(SLASH)dhs_Quantum210.cc \
			$(SRC_DIR)$(SLASH)dhs_Quantum210.h \
			$(DIFFIMAGE_HEADER_DIR)$(SLASH)libimage.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XFORM_HEADER_DIR)$(SLASH)xform.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dhs_dmc2180.o: $(SRC_DIR)$(SLASH)dhs_dmc2180.cc \
			$(SRC_DIR)$(SLASH)dmc2180API.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dmc2180API.o: $(SRC_DIR)$(SLASH)dmc2180API.cc \
			$(SRC_DIR)$(SLASH)dmc2180API.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/marCcd.o: $(SRC_DIR)$(SLASH)marCcd.cc \
			$(SRC_DIR)$(SLASH)marCcd.h \
			$(SRC_DIR)$(SLASH)dhs_dcs_messages.h \
			$(SRC_DIR)$(SLASH)dhs_messages.h \
			$(SRC_DIR)$(SLASH)dcs.h \
			$(SRC_DIR)$(SLASH)dhs_database.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_hash.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_semaphore_set.h \
			$(XOS_HEADER_DIR)$(SLASH)xos_socket.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/impFileAccess.o: $(SRC_DIR)$(SLASH)impFileAccess.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/dhs_Camera.o: $(SRC_DIR)$(SLASH)dhs_Camera.cc \
			$(SRC_DIR)$(SLASH)dhs_Camera.h \
			$(SRC_DIR)$(SLASH)imgCentering.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imgCentering.o: $(SRC_DIR)$(SLASH)imgCentering.cc \
			$(SRC_DIR)$(SLASH)imgCentering.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/test_dhs.o: $(SRC_DIR)$(SLASH)test_dhs.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test_imgsrv.o: $(SRC_DIR)$(SLASH)test_imgsrv.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

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
	-$(RM) $(MACHINE)$(SLASH)dhs$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


dhs: showinfo makedir $(objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
endif

test_dhs: showinfo makedir $(test_dhs_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_dhs_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test_dhs_objs) $(LIBS)
endif

test_imgsrv: showinfo makedir $(test_imgsrv_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_imgsrv_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test_imgsrv_objs) $(LIBS)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: dhs doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


