########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: impdhs test myDcss dcssClientTest


PROJ_NAME = impdhs
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
		

STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc -lssl
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
STD_LIBS += -lC -lc -lm -lpthread -lssl
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

STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl

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
STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl

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
STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl


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


########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(AUTH_CLIENT_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(DCSMSG_INCLUDE) \
	$(DCSCONFIG_INCLUDE)
	



########################################################
# Libraries
########################################################

LIBS += $(DCSCONFIG_LIB) $(AUTH_CLIENT_LIB) $(HTTP_CPP_LIB) $(DCSMSG_LIB) $(XOS_CPP_LIB) $(LOGGING_LIB) $(XOS_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################

	
objs =  $(MACHINE)/impdhs.o \
		$(MACHINE)/ImpersonService.o \
		$(MACHINE)/ImpersonSystem.o \
		$(MACHINE)/AutochoochThread.o \
		$(MACHINE)/ImpConfig.o \
		$(MACHINE)/SnapThread.o \
		$(MACHINE)/FileAccessThread.o \
		$(MACHINE)/SilThread.o \
		$(MACHINE)/AllSilThread.o \
		$(MACHINE)/Strategy.o \
		$(MACHINE)/ImageConvertThread.o

clientObjs =  $(MACHINE)/test_dcss.o

testObjs =  $(MACHINE)/test.o

myDcssObjs =  $(MACHINE)/myDcss.o

dcssClientTestObjs = $(MACHINE)/dcssClientTest.o

test3Objs =  $(MACHINE)/test3.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/impdhs.o: $(SRC_DIR)$(SLASH)impdhs.cxx \
              ${SRC_DIR}/ImpersonService.h \
              ${SRC_DIR}/ImpersonSystem.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpersonService.o: $(SRC_DIR)$(SLASH)ImpersonService.cxx \
              ${SRC_DIR}/ImpersonService.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpersonSystem.o: $(SRC_DIR)$(SLASH)ImpersonSystem.cxx \
              ${SRC_DIR}/ImpersonSystem.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/AutochoochThread.o: $(SRC_DIR)$(SLASH)AutochoochThread.cxx \
              ${SRC_DIR}/AutochoochThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SnapThread.o: $(SRC_DIR)$(SLASH)SnapThread.cxx \
              ${SRC_DIR}/SnapThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/FileAccessThread.o: $(SRC_DIR)$(SLASH)FileAccessThread.cxx \
              ${SRC_DIR}/FileAccessThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SilThread.o: $(SRC_DIR)$(SLASH)SilThread.cxx \
              ${SRC_DIR}/SilThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/AllSilThread.o: $(SRC_DIR)$(SLASH)AllSilThread.cxx \
              ${SRC_DIR}/AllSilThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/Strategy.o: $(SRC_DIR)$(SLASH)Strategy.cpp \
              ${SRC_DIR}/Strategy.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImageConvertThread.o: $(SRC_DIR)$(SLASH)ImageConvertThread.cxx \
              ${SRC_DIR}/ImageConvertThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SaveScanThread.o: $(SRC_DIR)$(SLASH)SaveScanThread.cxx \
              ${SRC_DIR}/SaveScanThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpConfig.o: $(SRC_DIR)$(SLASH)ImpConfig.cxx \
              ${SRC_DIR}/ImpConfig.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test_dcss.o: $(SRC_DIR)$(SLASH)test_dcss.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/myDcss.o: $(SRC_DIR)$(SLASH)myDcss.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcssClientTest.o: $(SRC_DIR)$(SLASH)dcssClientTest.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test3.o: $(SRC_DIR)$(SLASH)test3.cxx
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
	-$(RM) $(MACHINE)$(SLASH)impdhs$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)dcssClientTest$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)myDcss$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


impdhs: showinfo makedir $(objs) $(DCSMSG_LIB)
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

test3: showinfo makedir $(test3Objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test3Objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test3Objs) $(LIBS)
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
	


