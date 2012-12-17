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
	@echo jpegsoc library is not supprted on Windows platform
else
default: jpegsoc_applack
endif


PROJ_NAME = jpegsoc
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
LDFLAGS	= -lib
RM	= rm -rf
MKDIR	= mkdir
CP 	= copy
LIBEXT = .lib
EXEEXT = .exe
CFLAGS	= -nologo -W3 -GX -DWIN32 -D_MBCS -D_LIB -Fd"$(MACHINE)$(SLASH)" -FD -c -Fo"$*.o"

ifeq ($(DEBUG),TRUE)
CFLAGS += -MTd -Gm -ZI -Od -GZ -D_DEBUG
else
CFLAGS += -MT -O2 -DXOS_PRODUCTION_CODE -DNDEBUG
endif


INC		+=
STD_LIBS 	+= 

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
CP	= cp -R
CFLAGS += -o $@ -c
LIBEXT = .a
EXEEXT =

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

CC = cc 
CFLAGS += -w0 -pthread -DDEC_UNIX
STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc


# JPEG directory
JPEG_DIR = /home/code/jpeg-6b/release/$(MACHINE)
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a


endif

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)
CC      = cc 
CFLAGS  += -MP:dsm=off -DIRIX
STD_LIBS += -lm lrt -lpthread -lmach -lexc -lc


# JPEG directory
JPEG_DIR = ../jpeg-6b
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a


endif

ifeq ($(MACHINE),linux)

########################################################
# linux 
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -pthread -D_REENTRANT
STD_LIBS += -lm -lrt -lpthread -lmach -lexc -lc

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg


endif
ifeq ($(MACHINE),linux64)

########################################################
# linux x86_64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify cc
else
CC      = cc
endif
CFLAGS  += -DLINUX -fPIC -pthread -D_REENTRANT
STD_LIBS += -lm -lrt -lpthread -lmach -lexc -lc

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

endif

ifeq ($(MACHINE),ia64)

########################################################
# linux ia64
########################################################

ifeq ($(PURIFY),TRUE)
CC      = purify cc
else
CC      = gcc
endif
CFLAGS  += -DLINUX -fPIC -pthread -D_REENTRANT
STD_LIBS += -lm -lrt -lpthread -lmach -lexc -lc

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = -ljpeg

endif



#endif any unix
endif


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src

JPEGSOC_LIB = jpegsoc_applack$(LIBEXT)

########################################################
# Local liraries
########################################################

# XOS
XOS_DIR = ..$(SLASH)xos
XOS_INCLUDE = -I${XOS_DIR}$(SLASH)src
XOS_LIB = $(XOS_DIR)$(SLASH)$(MACHINE)$(SLASH)libxos$(LIBEXT)


########################################################
# Include directories
########################################################

INC +=  $(XOS_INCLUDE) $(JPEG_INCLUDE)


########################################################
# Libraries
########################################################

LIBS += $(XOS_LIB) $(JPEG_LIB)


########################################################
# Object files
########################################################

objs = $(MACHINE)/jsndrcv.o \
	$(MACHINE)/jdatasrcsock.o \
	$(MACHINE)/jdatadststream.o
	
#	$(MACHINE)/jdatadstsock.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/jsndrcv.o: $(SRC_DIR)$(SLASH)jsndrcv.c $(SRC_DIR)$(SLASH)jpegsoc.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/jdatasrcsock.o: $(SRC_DIR)$(SLASH)jdatasrcsock.c $(SRC_DIR)$(SLASH)jpegsoc.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/jdatadstsock.o: $(SRC_DIR)$(SLASH)jdatadstsock.c $(SRC_DIR)$(SLASH)jpegsoc.h
	$(CC) $(CFLAGS) $(INC) $<

$(MACHINE)/jdatadststream.o: $(SRC_DIR)$(SLASH)jdatadststream.c $(SRC_DIR)$(SLASH)jpegsoc.h
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
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)$(JPEGSOC_LIB)


# Libary target

jpegsoc_applack: showinfo makedir $(objs)
	@echo ...
	@echo Making $(JPEGSOC_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(JPEGSOC_LIB)" $(objs) $(LIBS)
else
	ar -vr $(MACHINE)$(SLASH)$(JPEGSOC_LIB) $(objs)
endif


# document target

cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: libxos libxos_old doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	
