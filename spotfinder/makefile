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
	@echo diffimage library is not supprted on Windows platform
else
default: spotfinder
endif

PROJ_NAME = spotfinder
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

# Install directory
INSTALL_DIR = $(MACHINE)


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

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = 

# CBF directory
CBF_DIR = ../cbflib
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.lib


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

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)


# CBF directory
CBF_DIR = ../cbflib
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.a


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
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET -std strict_ansi
CPPFLAGS = -x cxx
# For building exe
LDFLAGS = -ptr $(TEMPLATES_DIR) \
		-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(MACHINE)$(SLASH)cxx_repository
		
STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc
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

# JPEG directory
JPEG_DIR = /home/scottm/code/working/jpeg-6b
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)


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
CPPFLAGS =
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

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

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

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

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

endif


#endif any unix
endif


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src
TEST_DIR = .$(SLASH)src

DIFFIMAGE_LIB = diffimage$(LIBEXT)


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
DIFFIMAGE_DIR = ..$(SLASH)diffimage
DIFFIMAGE_INCLUDE = -I${DIFFIMAGE_DIR}$(SLASH)src
DIFFIMAGE_LIB = $(DIFFIMAGE_DIR)$(SLASH)$(MACHINE)$(SLASH)diffimage$(LIBEXT)


########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(DIFFIMAGE_INCLUDE) \
	$(JPEGSOC_INCLUDE) \
	$(JPEG_INCLUDE) \
	$(CBF_INCLUDE)
	



########################################################
# Libraries
########################################################

LIBS += $(DIFFIMAGE_LIB) $(CBF_LIB) $(JPEGSOC_LIB) $(JPEG_LIB) $(XOS_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################


objs =	  $(MACHINE)/spotfinder.o \
	  $(MACHINE)/libdistl.o \
	  $(MACHINE)/spot.o
	

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/spotfinder.o: $(SRC_DIR)$(SLASH)spotfinder.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/libdistl.o: $(SRC_DIR)$(SLASH)libdistl.cc
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/spot.o: $(SRC_DIR)$(SLASH)spot.cc
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
	-@$(RM) $(MACHINE)$(SLASH)*.o
	-@$(RM) $(MACHINE)$(SLASH)*.par
	-@$(RM) $(MACHINE)$(SLASH)spotfinder
	-@$(RM) $(MACHINE)$(SLASH)*.idb
	-@$(RM) $(MACHINE)$(SLASH)*.pdb
	-@$(RM) $(MACHINE)$(SLASH)*.d
	-@$(RM) $(MACHINE)$(SLASH).pure.*
	-@$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-@$(RM) $(MACHINE)$(SLASH)ii_files
	-@$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target

spotfinder: showinfo makedir $(objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
	$(CP) .$(SLASH)src$(SLASH)spotfinder.par $(MACHINE)
	$(CP) .$(SLASH)src$(SLASH)center.par $(MACHINE)
endif


# document target


cleandoc: 
	-@$(RM) doc$(SLASH)$(PROJ_VERSION)
	-@$(RM) doc$(SLASH)log.txt
	-@$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: $(MACHINE)/spotfinder
	$(CP) .$(SLASH)src$(SLASH)spotfinder.par $(INSTALL_DIR)
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


