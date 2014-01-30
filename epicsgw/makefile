########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: epicsgw


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
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET -Ddatabase_mysql
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
CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET \
		  -xc++ -MP:dsm=off -LANG:std=on \
		  -LANG:exceptions=on -no_prelink -ptused \
		  -Ddatabase_mysql \
		  -DWITH_DETECTOR_SUPPORT \
		  -DWITH_ASYNC2100_SUPPORT \
		  -DWITH_DMC2180_SUPPORT
		  
CPPFLAGS = 
LDFLAGS =
STD_LIBS += -lC -lc -lm -lpthread
INC 	+= -I/usr/include/CC \
           -I/usr/local/include



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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT
			
CPPFLAGS = -Wall
LDFLAGS =
SUPPORT_EPICS = TRUE

STD_LIBS += -lm -lrt -lpthread -lc -lz -lreadline -lhistory -lncurses -ldl


# TK
TK_DIR = /usr/include
TK_INCLUDE = -I$(TK_DIR)
TK_LIB =

# TCL
TCL_DIR = /usr/lib
TCL_INCLUDE = -I/usr/local/include
TCL_LIB =


# Epics support
ifeq ($(SUPPORT_EPICS),TRUE)

CFLAGS  += -D_X86_ -Dlinux -fPIC -D_REENTRANT
CPP_CONSTANTS += -DWITH_EPICS_SUPPORT

ifdef EPICS_BASE
EPICS_DIR = $(EPICS_BASE)
else
EPICS_DIR = /usr/local/epics/base/base-3-14-11
endif
EPICS_HEADER_DIR += ${EPICS_DIR}/include
EPICS_INCLUDE = -I$(EPICS_HEADER_DIR) -I$(EPICS_HEADER_DIR)/os/Linux
EPICS_LIB_DIR = ${EPICS_DIR}/lib/linux-x86
EPICS_LIBS = $(EPICS_LIB_DIR)/libca$(LIBEXT) $(EPICS_LIB_DIR)/libCom$(LIBEXT)


INC += $(EPICS_INCLUDE)
LIBS +=	$(EPICS_LIBS)
		

# endif SUPPORT_EPICS
endif

# endif linux
endif

ifeq ($(MACHINE),linux64)

########################################################
# linux64
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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT
			
CPPFLAGS = -Wall
LDFLAGS =
SUPPORT_EPICS = TRUE

#<<<<<<< makefile
#STD_LIBS += -lm -lrt -lpthread -lc -lz -lreadline -lhistory -lncurses
#=======
#STD_LIBS += -lm -lrt -lpthread -lc -lz
STD_LIBS += -lm -lrt -lpthread -lc -lz -lreadline -lhistory -lncurses -ldl
#>>>>>>> 1.9


# TK
TK_DIR = /usr/include
TK_INCLUDE = -I$(TK_DIR)
TK_LIB =

# TCL
TCL_DIR = /usr/lib
TCL_INCLUDE = -I/usr/local/include
TCL_LIB =


# Epics support
ifeq ($(SUPPORT_EPICS),TRUE)

CFLAGS  += -D_X86_ -Dlinux -fPIC -D_REENTRANT
CPP_CONSTANTS += -DWITH_EPICS_SUPPORT

ifdef EPICS_BASE
EPICS_DIR = $(EPICS_BASE)
else
EPICS_DIR = /usr/local/dcs/epics/base
endif
EPICS_HEADER_DIR += ${EPICS_DIR}/include
EPICS_INCLUDE = -I$(EPICS_HEADER_DIR) -I$(EPICS_HEADER_DIR)/os/Linux
EPICS_LIB_DIR = ${EPICS_DIR}/lib/linux-x86_64
EPICS_LIBS = $(EPICS_LIB_DIR)/libca$(LIBEXT) $(EPICS_LIB_DIR)/libCom$(LIBEXT)


INC += $(EPICS_INCLUDE)
LIBS +=	$(EPICS_LIBS)
		

# endif SUPPORT_EPICS
endif

# endif linux
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

# LOGGING
LOGGING_DIR = ..$(SLASH)logging
LOGGING_HEADER_DIR = $(LOGGING_DIR)$(SLASH)src
LOGGING_INCLUDE = -I$(LOGGING_HEADER_DIR)
LOGGING_LIB = $(LOGGING_DIR)$(SLASH)$(MACHINE)$(SLASH)liblogging$(LIBEXT)

# XOS_CPP
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_HEADER_DIR = $(XOS_CPP_DIR)$(SLASH)src
XOS_CPP_INCLUDE = -I$(XOS_CPP_HEADER_DIR)
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# DCSCONFIG
DCSCONFIG_DIR = ..$(SLASH)dcsconfig
DCSCONFIG_HEADER_DIR = $(DCSCONFIG_DIR)$(SLASH)src
DCSCONFIG_INCLUDE = -I$(DCSCONFIG_HEADER_DIR)
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)

# DCSMSG
DCSMSG_DIR = ..$(SLASH)dcsmsg
DCSMSG_HEADER_DIR = $(DCSMSG_DIR)$(SLASH)src
DCSMSG_INCLUDE = -I$(DCSMSG_HEADER_DIR)
DCSMSG_LIB = $(DCSMSG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsmsg$(LIBEXT)


########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(EPICS_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(DCSCONFIG_INCLUDE) \
	$(DCSMSG_INCLUDE)	


########################################################
# Libraries
########################################################

LIBS += $(DCSMSG_LIB) \
		$(DCSCONFIG_LIB) \
		$(XOS_CPP_LIB) \
		$(LOGGING_LIB) \
		$(XOS_LIB) \
		$(EPICS_LIB) \
		$(STD_LIBS)



########################################################
# Object files
########################################################
	
ifeq ($(MACHINE),linux)
objs += $(MACHINE)/epicsgw.o
objs += $(MACHINE)/gw_device_mgr.o
objs += $(MACHINE)/chid_mgr.o
objs += $(MACHINE)/gw_service.o
objs += $(MACHINE)/gw_system.o
objs += $(MACHINE)/GwBaseDevice.o
objs += $(MACHINE)/GwBaseMotor.o
objs += $(MACHINE)/GwString.o
objs += $(MACHINE)/GwShutter.o
objs += $(MACHINE)/GwCLSMotor.o
objs += $(MACHINE)/GwStepperMotor.o
objs += $(MACHINE)/GwAPSMotor.o
objs += $(MACHINE)/GwMCS8Motor.o
objs += $(MACHINE)/GwASGalilMotor.o
objs += $(MACHINE)/GwSSRLGapMotor.o
objs += $(MACHINE)/GwLynceanMotor.o
endif

ifeq ($(MACHINE),linux64)
objs += $(MACHINE)/epicsgw.o
objs += $(MACHINE)/gw_device_mgr.o
objs += $(MACHINE)/chid_mgr.o
objs += $(MACHINE)/gw_service.o
objs += $(MACHINE)/gw_system.o
objs += $(MACHINE)/GwBaseDevice.o
objs += $(MACHINE)/GwBaseMotor.o
objs += $(MACHINE)/GwString.o
objs += $(MACHINE)/GwShutter.o
objs += $(MACHINE)/GwCLSMotor.o
objs += $(MACHINE)/GwStepperMotor.o
objs += $(MACHINE)/GwAPSMotor.o
objs += $(MACHINE)/GwMCS8Motor.o
objs += $(MACHINE)/GwASGalilMotor.o
objs += $(MACHINE)/GwSSRLGapMotor.o
objs += $(MACHINE)/GwLynceanMotor.o
endif

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/epicsgw.o: $(SRC_DIR)$(SLASH)epicsgw.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)gw_device_mgr.h \
              $(SRC_DIR)$(SLASH)gw_service.h \
              $(SRC_DIR)$(SLASH)gw_system.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwBaseDevice.o: $(SRC_DIR)$(SLASH)GwBaseDevice.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwBaseMotor.o: $(SRC_DIR)$(SLASH)GwBaseMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwString.o: $(SRC_DIR)$(SLASH)GwString.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwString.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwShutter.o: $(SRC_DIR)$(SLASH)GwShutter.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwShutter.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwCLSMotor.o: $(SRC_DIR)$(SLASH)GwCLSMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwCLSMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwStepperMotor.o: $(SRC_DIR)$(SLASH)GwStepperMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwStepperMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwAPSMotor.o: $(SRC_DIR)$(SLASH)GwAPSMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwAPSMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwMCS8Motor.o: $(SRC_DIR)$(SLASH)GwMCS8Motor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwMCS8Motor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwASGalilMotor.o: $(SRC_DIR)$(SLASH)GwASGalilMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwASGalilMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwSSRLGapMotor.o: $(SRC_DIR)$(SLASH)GwSSRLGapMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwSSRLGapMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/GwLynceanMotor.o: $(SRC_DIR)$(SLASH)GwLynceanMotor.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)GwBaseMotor.h \
              $(SRC_DIR)$(SLASH)GwLynceanMotor.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/gw_device_mgr.o: $(SRC_DIR)$(SLASH)gw_device_mgr.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)gw_device_mgr.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/gw_service.o: $(SRC_DIR)$(SLASH)gw_service.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)gw_device_mgr.h \
              $(SRC_DIR)$(SLASH)gw_service.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/gw_system.o: $(SRC_DIR)$(SLASH)gw_system.cc \
              $(SRC_DIR)$(SLASH)GwBaseDevice.h \
              $(SRC_DIR)$(SLASH)gw_device_mgr.h \
              $(SRC_DIR)$(SLASH)gw_service.h \
              $(SRC_DIR)$(SLASH)gw_system.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/chid_mgr.o: $(SRC_DIR)$(SLASH)chid_mgr.cc \
              $(SRC_DIR)$(SLASH)chid_mgr.h
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
	-$(RM) $(MACHINE)$(SLASH)epicsgw$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


epicsgw: showinfo makedir $(objs)
ifeq ($(MACHINE),linux)
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
else
ifeq ($(MACHINE),linux64)
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
else
	@echo epicsgw is currently available only on linux.
endif
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: epicsgw doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
