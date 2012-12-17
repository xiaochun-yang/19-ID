########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: libxos_cpp


XOS_CPP_LIB = 
PROJ_NAME = xos_cpp
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
CP	= copy
RM	= rm -rf
MKDIR	= mkdir
CFLAGS	= -nologo -W3 -GR -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"
CPPFLAGS =
LIBEXT	= .lib
EXEEXT  = .exe

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif

# Doxygen executable for generating API documents

DOXYGEN_EXE = c:/software/doxygen/bin/doxygen
WWW_DOC_DIR = 

INC		+=
STD_LIBS 	+= wsock32.lib
XOS_CPP_LIB	 = libxos-cpp.lib

else

########################################################
#
# Any Unix
#
########################################################

SLASH = /
CP	= cp -R
RM	= rm -rf
MKDIR	= mkdir -p
CFLAGS +=  -o $@
CPPFLAGS =
XOS_CPP_LIB	= libxos-cpp.a
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
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET -D_FILE_OFFSET_BITS=64
CPPFLAGS = -x cxx
# For building test exe
LDFLAGS = -ptr $(TEMPLATES_DIR)
STD_LIBS += -lm -lrt -lpthread -lc -lmach
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
LDFLAGS  =
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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS  =
STD_LIBS += -lm -lrt -lpthread -lc


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
CFLAGS  += -fexceptions -c -fPIC -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS  =
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
CFLAGS  += -fexceptions -c -fPIC -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS  =
STD_LIBS += -lm -lrt -lpthread -lc


endif

#endif any unix
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
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)

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

test_objs = 	$(MACHINE)/XosSocketTest.o \
		$(MACHINE)/test.o

objs =	$(MACHINE)/XosException.o \
	$(MACHINE)/XosSocket.o \
	$(MACHINE)/XosSocketAddress.o \
	$(MACHINE)/XosServerSocket.o \
	$(MACHINE)/XosStringUtil.o \
	$(MACHINE)/XosUrl.o \
	$(MACHINE)/XosWildcard.o \
	$(MACHINE)/XosFileNameWildcard.o \
	$(MACHINE)/XosFileUtil.o \
	$(MACHINE)/XosThread.o \
	$(MACHINE)/XosTimeCheck.o \
	$(MACHINE)/XosConfig.o \
	$(MACHINE)/TclList.o \
	$(MACHINE)/XOSSingleLock.o \
	$(MACHINE)/XosMutex.o
	
	

########################################################
#
# Targets
#
########################################################


# Object files


$(MACHINE)/XosSocketTest.o: $(SRC_DIR)$(SLASH)XosSocketTest.cxx $(SRC_DIR)$(SLASH)XosSocketTest.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosTimeCheck.o: $(SRC_DIR)$(SLASH)XosTimeCheck.cxx $(SRC_DIR)$(SLASH)XosTimeCheck.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosException.o: $(SRC_DIR)$(SLASH)XosException.cxx $(SRC_DIR)$(SLASH)XosException.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosSocketAddress.o: $(SRC_DIR)$(SLASH)XosSocketAddress.cxx $(SRC_DIR)$(SLASH)XosSocketAddress.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosServerSocket.o: $(SRC_DIR)$(SLASH)XosServerSocket.cxx $(SRC_DIR)$(SLASH)XosServerSocket.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosSocket.o: $(SRC_DIR)$(SLASH)XosSocket.cxx $(SRC_DIR)$(SLASH)XosSocket.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosStringUtil.o: $(SRC_DIR)$(SLASH)XosStringUtil.cxx $(SRC_DIR)$(SLASH)XosStringUtil.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/XosUrl.o: $(SRC_DIR)$(SLASH)XosUrl.cxx $(SRC_DIR)$(SLASH)XosUrl.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosWildcard.o: $(SRC_DIR)$(SLASH)XosWildcard.cxx $(SRC_DIR)$(SLASH)XosWildcard.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosFileNameWildcard.o: $(SRC_DIR)$(SLASH)XosFileNameWildcard.cxx $(SRC_DIR)$(SLASH)XosFileNameWildcard.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosFileUtil.o: $(SRC_DIR)$(SLASH)XosFileUtil.cxx $(SRC_DIR)$(SLASH)XosFileUtil.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosThread.o: $(SRC_DIR)$(SLASH)XosThread.cxx $(SRC_DIR)$(SLASH)XosThread.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosMutex.o: $(SRC_DIR)$(SLASH)XosMutex.cxx $(SRC_DIR)$(SLASH)XosMutex.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosConfig.o: $(SRC_DIR)$(SLASH)XosConfig.cxx $(SRC_DIR)$(SLASH)XosConfig.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TclList.o: $(SRC_DIR)$(SLASH)TclList.cxx $(SRC_DIR)$(SLASH)TclList.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/XOSSingleLock.o: $(SRC_DIR)$(SLASH)XOSSingleLock.cxx $(SRC_DIR)$(SLASH)XOSSingleLock.h
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
	-$(RM) $(MACHINE)$(SLASH)*.exe
	-$(RM) $(MACHINE)$(SLASH)*.idb
	-$(RM) $(MACHINE)$(SLASH)*.pdb
	-$(RM) $(MACHINE)$(SLASH).pure.*
	-$(RM) $(MACHINE)$(SLASH)$(XOS_CPP_LIB)
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)test$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository
	-$(RM) doc$(SLASH)html
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)xos_cpp.tag


# Libary target

libxos_cpp: showinfo makedir $(objs)
	@echo ...
	@echo Making $(XOS_CPP_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib -out:"$(MACHINE)$(SLASH)$(XOS_CPP_LIB)" $(objs) $(LIBS)
else
	ar -vr $(MACHINE)$(SLASH)$(XOS_CPP_LIB) $(objs)
	-ranlib $(MACHINE)$(SLASH)$(XOS_CPP_LIB) 
endif


test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(XOS_CPP_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(XOS_CPP_LIB) $(LIBS)
endif

# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: libxos_cpp doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	
