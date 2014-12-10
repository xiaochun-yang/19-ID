########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: xiaSaturn


PROJ_NAME = xiaSaturn
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
# Figuring out the platform on which gmake is executed.
# From this point onwards, we will rely on the variable 
# MACHINE for platform specific stuff.
#
########################################################

ifeq ($(OS),Windows_NT)
MACHINE = nt
else
ifeq ($(OSTYPE),osf1)
MACHINE = decunix
else
ifeq ($(OSTYPE),irix)
MACHINE = irix
else
ifeq ($(OSTYPE),linux64)
MACHINE = linux64
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
#The XIA Saturn needs the -Zp2 flag!
CFLAGS	= -nologo -W3 -GR -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o" -Zp2
CPPFLAGS =
LIBEXT	= .lib
EXEEXT  = .exe

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC		+=
STD_LIBS 	+= wsock32.lib user32.lib


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
		-ptr $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(AUTH__CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(DCSMSG_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
		

STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc
INC 	+= -I/usr/include/cxx \
           -I/usr/local/include


endif

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)
CC      = CC
CXX	= CC
LINK 	= CC
CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET -xc++ -MP:dsm=off -LANG:std=on -LANG:exceptions=on -no_prelink -ptused
CPPFLAGS =
LDFLAGS =
STD_LIBS += -lC -lc -lm -lpthread
INC 	+= -I/usr/include/CC \
           -I/usr/local/include


endif


ifeq ($(MACHINE),linux64)

########################################################
# linux 
########################################################

CC      = g++
CXX	= g++
LINK 	= g++
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT 
CPPFLAGS = -Wall
LDFLAGS =


STD_LIBS += -lm -lrt -lpthread -lc -lz


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
XOS_INCLUDE = -I${XOS_DIR}$(SLASH)src
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)

# logging
LOGGING_DIR = ..$(SLASH)logging
LOGGING_INCLUDE = -I${LOGGING_DIR}$(SLASH)src
LOGGING_LIB = $(LOGGING_DIR)$(SLASH)$(MACHINE)$(SLASH)liblogging$(LIBEXT)

# XOS_CPP
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_INCLUDE = -I${XOS_CPP_DIR}$(SLASH)src
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# HTTP_CPP
HTTP_CPP_DIR = ..$(SLASH)http_cpp
HTTP_CPP_INCLUDE = -I${HTTP_CPP_DIR}$(SLASH)src
HTTP_CPP_LIB = $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libhttp-cpp$(LIBEXT)


# AUTH_CLIENT
AUTH_CLIENT_DIR = ..$(SLASH)auth_client
AUTH_CLIENT_INCLUDE = -I${AUTH_CLIENT_DIR}$(SLASH)src
AUTH_CLIENT_LIB = $(AUTH_CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)libauthclient$(LIBEXT)

# logging
DCSMSG_DIR = ..$(SLASH)dcsmsg$
DCSMSG_INCLUDE = -I$(DCSMSG_DIR)$(SLASH)src
DCSMSG_LIB = $(DCSMSG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsmsg$(LIBEXT)

# logging
DCSCONFIG_DIR = ..$(SLASH)dcsconfig$
DCSCONFIG_INCLUDE = -I$(DCSCONFIG_DIR)$(SLASH)src
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)

# Handel
HANDEL_DIR = handelSrc
HANDEL_INCLUDE = -I$(HANDEL_DIR)
HANDEL_LIB = $(HANDEL_DIR)$(SLASH)$(MACHINE)$(SLASH)libhandel$(LIBEXT)

# libusb
USB_DIR = /usr/lib64
USB_LIB = $(USB_DIR)$(SLASH)libusb$(LIBEXT)

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(AUTH_CLIENT_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(HANDEL_INCLUDE) \
	$(DCSMSG_INCLUDE) \
	$(DCSCONFIG_INCLUDE) 
	



########################################################
# Libraries
########################################################

LIBS += $(DCSCONFIG_LIB) $(AUTH_CLIENT_LIB) $(HTTP_CPP_LIB) $(DCSMSG_LIB) $(XOS_CPP_LIB) $(LOGGING_LIB) $(XOS_LIB) $(HANDEL_LIB) $(USB_LIB) $(STD_LIBS) 

########################################################
# Object files
########################################################

	
objs =  $(MACHINE)/xiaSaturn.o \
		$(MACHINE)/xiaSaturnService.o \
		$(MACHINE)/xiaSaturnSystem.o \
		$(MACHINE)/xiaSaturnAPI.o

clientObjs =  $(MACHINE)/test_dcss.o

testObjs =  $(MACHINE)/test.o

myDcssObjs =  $(MACHINE)/myDcss.o

dcssClientTestObjs = $(MACHINE)/dcssClientTest.o


########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/xiaSaturn.o: $(SRC_DIR)$(SLASH)xiaSaturn.cxx \
              ${SRC_DIR}/xiaSaturnService.h \
              ${SRC_DIR}/xiaSaturnSystem.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/xiaSaturnService.o: $(SRC_DIR)$(SLASH)xiaSaturnService.cxx \
              ${SRC_DIR}/xiaSaturnService.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/xiaSaturnSystem.o: $(SRC_DIR)$(SLASH)xiaSaturnSystem.cxx \
              ${SRC_DIR}/xiaSaturnSystem.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/xiaSaturnAPI.o: $(SRC_DIR)$(SLASH)xiaSaturnAPI.cxx \
              ${SRC_DIR}/xiaSaturnAPI.h
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
	-$(RM) $(MACHINE)$(SLASH)xiaSaturn$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository
	make -C handelSrc clean


# exe target


xiaSaturn: makedir $(objs) $(DCSMSG_LIB)
	make -C handelSrc
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
endif

client: showinfo makedir $(clientObjs) $(DCSMSG_LIB)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(clientObjs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(clientObjs) $(LIBS)
endif

test: showinfo makedir $(testObjs) $(DCSMSG_LIB)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(testObjs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(testObjs) $(LIBS)
endif

myDcss: showinfo makedir $(myDcssObjs) $(DCSMSG_LIB)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(myDcssObjs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(myDcssObjs) $(LIBS)
endif

dcssClientTest: showinfo makedir $(dcssClientTestObjs) $(DCSMSG_LIB)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(dcssClientTestObjs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(dcssClientTestObjs) $(LIBS)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: xiaSaturn doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


