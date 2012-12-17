########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

ifeq ($(OS),Windows_NT)
default:
	@echo dcss application is not supprted on Windows platform
else
default: dcss url.class
endif

PROJ_NAME = dcss
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
		

STD_LIBS += $(TK_LIBS) -lm -lrt -lpthread -lc -lmach -lexc -lssl
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

STD_LIBS += -ltk8.3 \
          -ltcl8.3 \
          -litcl3.2 \
          -lX11

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
STD_LIBS += -lc -lm -lpthread -lssl
INC 	+= -I/usr/include/CC \
           -I/usr/local/include

# TK lib
TK_DIR = /usr/local/include
TK_INCLUDE = -I/usr/local/include
TK_LIB = -L/usr/local/lib -ltk8.3 -litk3.2

# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = -L/usr/local/lib -ltcl8.3 -litcl3.2

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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS = -Wall
LDFLAGS =


STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl


# TK
TK_DIR = /usr/include
TK_INCLUDE = -I$(TK_DIR)
TK_LIB =

# TCL
TCL_DIR = /usr/lib
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = 

#STD_LIBS += -ltk -ltcl -litcl
 STD_LIBS += -ltk -ltcl /usr/lib/itcl3.3/libitcl3.3.so

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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS = -Wall
LDFLAGS =


STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl


# TK
TK_DIR =
TK_INCLUDE = 
TK_LIB =

# TCL
TCL_DIR = 
TCL_INCLUDE = 
TCL_LIB =

STD_LIBS += -ltk -ltcl -litcl3.3

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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS = -Wall
LDFLAGS =


STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl


# TK
TK_DIR =
TK_INCLUDE = 
TK_LIB =

# TCL
TCL_DIR = 
TCL_INCLUDE = 
TCL_LIB =

STD_LIBS += -ltk8.4 -ltcl8.4 -litcl3.3

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

# AUTH_CLIENT
DCSCONFIG_DIR = ..$(SLASH)dcsconfig
DCSCONFIG_INCLUDE = -I${DCSCONFIG_DIR}$(SLASH)src
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)


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
	$(DCSCONFIG_INCLUDE)
	



########################################################
# Libraries
########################################################

LIBS += $(AUTH_CLIENT_LIB) $(DCSCONFIG_LIB) $(HTTP_CPP_LIB) $(XOS_CPP_LIB) \
		$(LOGGING_LIB) $(XOS_LIB) $(TK_LIB) $(TCL_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################

test2_objs = $(MACHINE)/test2.o

test_objs = $(MACHINE)/test.o
	
objs = $(MACHINE)/dcss_main.o \
       $(MACHINE)/dcss_tcl_log.o \
       $(MACHINE)/dcss_database.o \
       $(MACHINE)/dcss_client.o \
	   $(MACHINE)/dcss_scripting.o \
	   $(MACHINE)/dcss_broadcast.o \
       $(MACHINE)/dcss_gui_client.o \
       $(MACHINE)/dcss_ssl.o \
       $(MACHINE)/dcss_hardware_client.o \
       $(MACHINE)/DcssDeviceLocker.o \
       $(MACHINE)/dcss_users.o

ifeq ($(MACHINE),decunix)
objs += $(MACHINE)/wedge4.o
endif 

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/dcss_main.o: $(SRC_DIR)$(SLASH)dcss_main.c \
              ${SRC_DIR}/dcss_device.h \
              ${SRC_DIR}/dcss_hardware_client.h \
              ${SRC_DIR}/dcss_scripting.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_tcl_log.o: $(SRC_DIR)$(SLASH)dcss_tcl_log.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_database.o: ${SRC_DIR}/dcss_database.c \
                  ${SRC_DIR}/dcss_database.h \
                  ${SRC_DIR}/dcss_device.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_client.o: ${SRC_DIR}/dcss_client.c \
                ${SRC_DIR}/dcss_client.h \
                ${SRC_DIR}/dcss_hardware_client.h \
                ${SRC_DIR}/dcss_device.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_scripting.o: ${SRC_DIR}/dcss_scripting.c \
				${SRC_DIR}/dcss_scripting.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/dcss_broadcast.o: ${SRC_DIR}/dcss_broadcast.c \
                   ${SRC_DIR}/dcss_broadcast.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_gui_client.o: ${SRC_DIR}/dcss_gui_client.c \
                    ${SRC_DIR}/dcss_gui_client.h \
                    ${SRC_DIR}/dcss_hardware_client.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_ssl.o: ${SRC_DIR}/dcss_ssl.c \
                    ${SRC_DIR}/dcss_gui_client.h \
                    ${SRC_DIR}/dcss_ssl.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/DcssDeviceLocker.o: ${SRC_DIR}/DcssDeviceLocker.cxx \
                    ${SRC_DIR}/dcss_device.h \
                    ${SRC_DIR}/dcss_database.h \
                    ${SRC_DIR}/DcssDeviceLocker.h 
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_hardware_client.o: ${SRC_DIR}/dcss_hardware_client.c \
                         ${SRC_DIR}/dcss_hardware_client.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcss_users.o: ${SRC_DIR}/dcss_users.c \
               ${SRC_DIR}/dcss_users.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/wedge4.o: ${SRC_DIR}/wedge4.c \
               ${SRC_DIR}/wedge.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test2.o: ${SRC_DIR}/test2.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: ${SRC_DIR}/test.cxx
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
	-$(RM) $(MACHINE)$(SLASH)dcss*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)proxy$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


dcss: showinfo makedir $(objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
endif

url.class:  ${SRC_DIR}/url.java
	javac -d $(MACHINE) $<

test2: showinfo makedir $(test2_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test2_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test2_objs) $(LIBS)
endif

test: showinfo makedir $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(LIBS)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: dcss doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


