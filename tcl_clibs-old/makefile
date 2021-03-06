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
	@echo tcl_clibs library is not supprted on Windows platform
else
default: tcl_clibs
endif

PROJ_NAME = tcl_clibs
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

# Set purify to FALSE since dcss expects to load
# tcl_clibs shared library with a specific name.
# purify build screw up the name.
PURIFY=FALSE

########################################################
#
# Figuring out the platform on which gmake is executed.
# From this point onwards, we will rely on the variable 
# MACHINE for platform specific stuff.
# Please also change bluice.tcl if you change here.
# It use the same logical to find the right
# directory to load this library.
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
SHAREDEXT	= .dll
EXEEXT  = .exe

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC		+=
STD_LIBS 	+= wsock32.lib user32.lib

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = 


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
SHAREDEXT = .so
EXEEXT  =

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)



ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O -DXOS_PRODUCTION_CODE
endif



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
LDFLAGS =  -update_registry $(MACHINE)$(SLASH)so_locations \
			-ptr $(TEMPLATES_DIR) \
			-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository

STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc -lssl
INC 	+= -I/usr/include/cxx \
           -I/usr/local/include

# JPEG directory
JPEG_DIR = /home/code/jpeg-6b/release/$(MACHINE)
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = $(JPEGSOC_DIR)/$(MACHINE)/jpegsoc_applack$(LIBEXT)

#old authentication library
OLD_AUTH_DIR = ../auth
OLD_AUTH_INCLUDE = -I$(OLD_AUTH_DIR)/src
OLD_AUTH_LIB =  $(OLD_AUTH_DIR)/$(MACHINE)/auth.a

# Matrix library
#NEWMAT_DIR = /home/code/newmat10
#NEWMAT_INCLUDE = -I$(NEWMAT_DIR)/include
#NEWMAT_LIB = $(NEWMAT_DIR)/alpha/lib/libnewmat.a


# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = /usr/local/lib/libtcl8.3$(SHAREDEXT) /usr/local/lib/libtk8.3$(SHAREDEXT)


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
LDFLAGS =  -update_registry $(MACHINE)$(SLASH)so_locations
STD_LIBS += -lc -lm -lpthread -lssl
INC 	+= -I/usr/include/CC \
           -I/usr/local/include

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

# Matrix library
#NEWMAT_DIR = /home/code/newmat10
#NEWMAT_INCLUDE = -I$(NEWMAT_DIR)/include
#NEWMAT_LIB = $(NEWMAT_DIR)/sgi/lib/libnewmat.a

#old authentication library
OLD_AUTH_DIR = ../auth
OLD_AUTH_INCLUDE = -I$(OLD_AUTH_DIR)/src
OLD_AUTH_LIB = $(OLD_AUTH_DIR)/$(MACHINE)/auth.a

# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = /usr/local/lib/libtcl8.3$(SHAREDEXT) /usr/local/lib/libtk8.3$(SHAREDEXT)

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
CPPFLAGS += -DNO_CONST -DUSE_COMPOSITELESS_PHOTO_PUT_BLOCK
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lssl

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

#old authentication library
OLD_AUTH_DIR = ../auth
OLD_AUTH_INCLUDE = -I$(OLD_AUTH_DIR)/src
OLD_AUTH_LIB = $(OLD_AUTH_DIR)/$(MACHINE)/auth.a

# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = -ltcl -ltk

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
CPPFLAGS += -DNO_CONST -DUSE_COMPOSITELESS_PHOTO_PUT_BLOCK
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lssl

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

#old authentication library
OLD_AUTH_DIR = ../auth
OLD_AUTH_INCLUDE = -I$(OLD_AUTH_DIR)/src
OLD_AUTH_LIB = $(OLD_AUTH_DIR)/$(MACHINE)/auth.a

# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = -ltcl -ltk

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
CPPFLAGS += -DNO_CONST -DUSE_COMPOSITELESS_PHOTO_PUT_BLOCK
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lssl

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

#old authentication library
OLD_AUTH_DIR = ../auth
OLD_AUTH_INCLUDE = -I$(OLD_AUTH_DIR)/src
OLD_AUTH_LIB = $(OLD_AUTH_DIR)/$(MACHINE)/auth.a

# Tcl directory
TCL_DIR =
TCL_INCLUDE = -I/usr/local/include
TCL_LIB = -ltcl8.4 -ltk8.4

endif

#endif any unix
endif


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src
TEST_DIR = .$(SLASH)src

TCL_CLIBS_LIB = tcl_clibs$(SHAREDEXT)


########################################################
# Local liraries
########################################################

# Matrix library
NEWMAT_DIR = ../newmat10
NEWMAT_INCLUDE = -I$(NEWMAT_DIR)/src
NEWMAT_LIB = $(NEWMAT_DIR)/$(MACHINE)/libnewmat.a

# XOS
XOS_DIR = ..$(SLASH)xos
XOS_INCLUDE = -I${XOS_DIR}$(SLASH)src
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)

# XOS_CPP
XOS_CPP_DIR = ..$(SLASH)xos_cpp
XOS_CPP_INCLUDE = -I${XOS_CPP_DIR}$(SLASH)src
XOS_CPP_LIB = $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos-cpp$(LIBEXT)

# LOGGING
LOGGING_DIR = ..$(SLASH)logging
LOGGING_INCLUDE = -I${LOGGING_DIR}$(SLASH)src
LOGGING_LIB = $(LOGGING_DIR)$(SLASH)$(MACHINE)$(SLASH)liblogging$(LIBEXT)

# HTTP_CPP
HTTP_CPP_DIR = ..$(SLASH)http_cpp
HTTP_CPP_INCLUDE = -I${HTTP_CPP_DIR}$(SLASH)src
HTTP_CPP_LIB = $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libhttp-cpp$(LIBEXT)

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(JPEGSOC_INCLUDE) \
	$(JPEG_INCLUDE) \
	$(OLD_AUTH_INCLUDE) \
	$(NEWMAT_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(TCL_INCLUDE) 




########################################################
# Libraries
########################################################

LIBS += $(JPEGSOC_LIB) $(JPEG_LIB) $(HTTP_CPP_LIB) $(TCL_LIB) $(NEWMAT_LIB) $(STD_LIBS) $(OLD_AUTH_LIB) $(LOGGING_LIB) $(XOS_CPP_LIB) $(XOS_LIB)


########################################################
# Object files
########################################################

test_objs =	  $(MACHINE)/test.o \

objs =	  $(MACHINE)/ice.o \
		  $(MACHINE)/ice_cal.o \
		  $(MACHINE)/ice_auth.o \
		  $(MACHINE)/calibrate.o \
		  $(MACHINE)/analyzePeak.o \
		  $(MACHINE)/cubgcv.o \
		  $(MACHINE)/matrix.o \
		  $(MACHINE)/matrix_cmd.o \
		  $(MACHINE)/linearRegression.o \
		  $(MACHINE)/ssl_cmd.o \
		  $(MACHINE)/dcs_message_parse.o \
		  $(MACHINE)/image_channel.o \
		  $(MACHINE)/fitFunction.o \
		  $(MACHINE)/decimalnum.o \
		  $(MACHINE)/imageScale.o \
		  $(MACHINE)/putsToLog.o \
		  $(MACHINE)/imagePGM16.o \
		  $(MACHINE)/imageBackgroundDetect.o \
		  $(MACHINE)/bilinearMap_cmd.o \
		  $(MACHINE)/projectiveMap_cmd.o \
		  $(MACHINE)/findMax.o
		  

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/ice.o: $(SRC_DIR)$(SLASH)ice.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ice_cal.o: $(SRC_DIR)$(SLASH)ice_cal.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ice_auth.o: $(SRC_DIR)$(SLASH)ice_auth.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/matrix.o: $(SRC_DIR)$(SLASH)matrix.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/matrix_cmd.o: $(SRC_DIR)$(SLASH)matrix_cmd.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/linearRegression.o: $(SRC_DIR)$(SLASH)linearRegression.cpp $(SRC_DIR)$(SLASH)linearRegression.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imageScale.o: $(SRC_DIR)$(SLASH)imageScale.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imagePGM16.o: $(SRC_DIR)$(SLASH)imagePGM16.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imageBackgroundDetect.o: $(SRC_DIR)$(SLASH)imageBackgroundDetect.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ssl_cmd.o: $(SRC_DIR)$(SLASH)ssl_cmd.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/bilinearMap_cmd.o: $(SRC_DIR)$(SLASH)bilinearMap_cmd.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/projectiveMap_cmd.o: $(SRC_DIR)$(SLASH)projectiveMap_cmd.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/dcs_message_parse.o: $(SRC_DIR)$(SLASH)dcs_message_parse.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/calibrate.o: $(SRC_DIR)$(SLASH)calibrate.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/image_channel.o: $(SRC_DIR)$(SLASH)image_channel.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/analyzePeak.o: $(SRC_DIR)$(SLASH)analyzePeak.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/cubgcv.o: $(SRC_DIR)$(SLASH)cubgcv.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/decimalnum.o: $(SRC_DIR)$(SLASH)decimalnum.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/fitFunction.o: $(SRC_DIR)$(SLASH)fitFunction.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/findMax.o: $(SRC_DIR)$(SLASH)findMax.cpp
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/putsToLog.o: $(SRC_DIR)$(SLASH)putsToLog.c
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
	-$(RM) $(MACHINE)$(SLASH)so_locations
	-$(RM) $(MACHINE)$(SLASH)*.idb
	-$(RM) $(MACHINE)$(SLASH)*.pdb
	-$(RM) $(MACHINE)$(SLASH).pure.*
	-$(RM) $(MACHINE)$(SLASH)*.d
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)*$(SHAREDEXT)*
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


tcl_clibs: showinfo makedir $(objs)
	@echo ...
	@echo Making $(TCL_CLIBS_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(TCL_CLIBS_LIB)" $(objs)
else
	$(LINK) -shared $(LDFLAGS) $(objs) $(LIBS) -o $(MACHINE)$(SLASH)$(TCL_CLIBS_LIB)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: tcl_clibs doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html


./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg

doc: ./doc/$(PROJ_VERSION)/html/index.html



