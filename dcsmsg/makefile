########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: libdcsmsg test UTmgr testTclList


PROJ_NAME = dcsmsg
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
CXX     = cl
LINK    = link
LDFLAGS	=
EXEFLAGS = -nologo -subsystem:console -incremental:no -machine:I386
RM	= rm -rf
MKDIR	= mkdir
CP 	= copy
CFLAGS	= -nologo -W3 -GR -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"
CPPFLAGS =
LIBEXT	= .lib
EXEEXT  = .exe

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC		+=
STD_LIBS 	+= wsock32.lib
DCSMSG_LIB	= libdcsmsg.lib


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
CFLAGS += -o $@
CPPFLAGS =
LIBEXT	= .a
EXEEXT  =
DCSMSG_LIB	= libdcsmsg.a

ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O -DXOS_PRODUCTION_CODE
endif

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)



ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

CC = cxx
CXX = cxx
LINK = cxx
TEMPLATES_DIR = ./$(MACHINE)/cxx_repository
TEMPLATES_OBJS = $(TEMPLATES_DIR)/*.o
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET
CPPFLAGS = -x cxx
# For building exe
LDFLAGS = -ptr $(TEMPLATES_DIR) \
		-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
		

STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc
INC 	+= -I/usr/include/cxx \
           -I/usr/local/include


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
CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET -xc++ -MP:dsm=off -LANG:std=on -LANG:exceptions=on -no_prelink -ptused
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


STD_LIBS += -lm -lrt -lpthread -lc -lz

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
CFLAGS  += -fexceptions -fPIC -c -DLINUX -pthread -D_REENTRANT
CPPFLAGS = -DLINUX -Wall
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc

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
CFLAGS  += -fexceptions -fPIC -c -DLINUX -pthread -D_REENTRANT
CPPFLAGS = -DLINUX -Wall
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc


endif

#endif any unix
endif 


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src
TEST_DIR = .$(SLASH)src
UT_DIR = .$(SLASH)unit_test

########################################################
# Local liraries
########################################################

# xos
XOS_DIR = ..$(SLASH)xos
XOS_INCLUDE = -I${XOS_DIR}$(SLASH)src
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)

# xos_cpp
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_INCLUDE = -I${XOS_CPP_DIR}$(SLASH)src
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# logging
LOGGING_DIR = ..$(SLASH)logging$
LOGGING_INCLUDE = -I$(LOGGING_DIR)$(SLASH)src
LOGGING_LIB = $(LOGGING_DIR)$(SLASH)$(MACHINE)$(SLASH)liblogging$(LIBEXT)

#dcsconfig
DCSCONFIG_DIR = ..$(SLASH)dcsconfig
DCSCONFIG_INCLUDE = -I$(DCSCONFIG_DIR)$(SLASH)src
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_CPP_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(DCSCONFIG_INCLUDE) \
	$(XOS_INCLUDE)
	



########################################################
# Libraries
########################################################

LIBS += $(XOS_CPP_LIB) $(LOGGING_LIB) $(XOS_LIB) $(DCSCONFIG_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################

objs = $(MACHINE)/activeObject.o \
	$(MACHINE)/DcsMessage.o \
	$(MACHINE)/DcsMessageHandler.o \
	$(MACHINE)/DcsMessageManager.o \
	$(MACHINE)/DcsMessageService.o \
	$(MACHINE)/DcsMessageTwoWay.o \
	$(MACHINE)/MQueue.o \
	$(MACHINE)/XOSSingleLock.o \
	$(MACHINE)/DhsService.o \
	$(MACHINE)/DhsSystem.o \
	$(MACHINE)/TclList.o

test_objs = $(MACHINE)/test.o \
	$(MACHINE)/RobotSim.o \
	$(MACHINE)/RobotService.o \
	$(MACHINE)/RobotSystem.o

testTclList_objs = $(MACHINE)/testTclList.o \
	$(MACHINE)/TclList.o


UTmgr_objs = $(MACHINE)/UTDcsMsgMgr.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/activeObject.o: $(SRC_DIR)$(SLASH)activeObject.cxx $(SRC_DIR)$(SLASH)activeObject.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)PointerList.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcsMessage.o: $(SRC_DIR)$(SLASH)DcsMessage.cxx $(SRC_DIR)$(SLASH)DcsMessage.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcsMessageHandler.o: $(SRC_DIR)$(SLASH)DcsMessageHandler.cxx $(SRC_DIR)$(SLASH)DcsMessageHandler.h $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)DcsMessage.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcsMessageManager.o: $(SRC_DIR)$(SLASH)DcsMessageManager.cxx $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)DcsMessage.h $(SRC_DIR)$(SLASH)PointerList.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcsMessageService.o: $(SRC_DIR)$(SLASH)DcsMessageService.cxx $(SRC_DIR)$(SLASH)DcsMessageService.h $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)activeObject.h $(SRC_DIR)$(SLASH)DcsMessage.h $(SRC_DIR)$(SLASH)DcsMessageHandler.h $(SRC_DIR)$(SLASH)MQueue.h $(SRC_DIR)$(SLASH)DcsMessageTwoWay.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcsMessageTwoWay.o: $(SRC_DIR)$(SLASH)DcsMessageTwoWay.cxx $(SRC_DIR)$(SLASH)DcsMessageTwoWay.h $(SRC_DIR)$(SLASH)activeObject.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)PointerList.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/MQueue.o: $(SRC_DIR)$(SLASH)MQueue.cxx $(SRC_DIR)$(SLASH)MQueue.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)PointerList.h $(SRC_DIR)$(SLASH)DcsMessage.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XOSSingleLock.o: $(SRC_DIR)$(SLASH)XOSSingleLock.cxx $(SRC_DIR)$(SLASH)XOSSingleLock.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DhsService.o: $(SRC_DIR)$(SLASH)DhsService.cxx $(SRC_DIR)$(SLASH)DhsService.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DhsSystem.o: $(SRC_DIR)$(SLASH)DhsSystem.cxx $(SRC_DIR)$(SLASH)DhsSystem.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TclList.o: $(SRC_DIR)$(SLASH)TclList.cxx $(SRC_DIR)$(SLASH)TclList.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx $(SRC_DIR)$(SLASH)RobotSystem.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/testTclList.o: $(SRC_DIR)$(SLASH)testTclList.cxx $(SRC_DIR)$(SLASH)TclList.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/RobotSim.o: $(SRC_DIR)$(SLASH)RobotSim.cxx $(SRC_DIR)$(SLASH)RobotSim.h $(SRC_DIR)$(SLASH)Robot.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/RobotService.o: $(SRC_DIR)$(SLASH)RobotService.cxx $(SRC_DIR)$(SLASH)RobotService.h $(SRC_DIR)$(SLASH)Robot.h $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)activeObject.h $(SRC_DIR)$(SLASH)DcsMessage.h $(SRC_DIR)$(SLASH)MQueue.h $(SRC_DIR)$(SLASH)DcsMessageTwoWay.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/RobotSystem.o: $(SRC_DIR)$(SLASH)RobotSystem.cxx $(SRC_DIR)$(SLASH)RobotSystem.h $(SRC_DIR)$(SLASH)RobotService.h $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)activeObject.h $(SRC_DIR)$(SLASH)DcsMessageService.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/UTDcsMsgMgr.o:   $(UT_DIR)$(SLASH)UTDcsMsgMgr.cc $(SRC_DIR)$(SLASH)DcsMessageManager.h $(SRC_DIR)$(SLASH)XOSSingleLock.h $(SRC_DIR)$(SLASH)DcsMessage.h $(SRC_DIR)$(SLASH)MQueue.h
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INC) $<

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
	-$(RM) $(MACHINE)$(SLASH)$(DCSMSG_LIB)
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


libdcsmsg: showinfo makedir $(objs)
	@echo ...
	@echo Making $(DCSMSG_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib -out:"$(MACHINE)$(SLASH)$(DCSMSG_LIB)" $(objs)
else
	ar -vr $(MACHINE)$(SLASH)$(DCSMSG_LIB) $(objs)
endif


testTclList: $(testTclList_objs)
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(testTclList_objs)

test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(DCSMSG_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(DCSMSG_LIB) $(LIBS)
endif

UTmgr:  $(UTmgr_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(UTmgr_objs) $(MACHINE)$(SLASH)$(DCSMSG_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(UTmgr_objs) $(MACHINE)$(SLASH)$(DCSMSG_LIB) $(LIBS)
endif

# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: impdhs doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


