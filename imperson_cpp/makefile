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
	@echo imperson_cpp application is not supprted on Windows platform
else
default: imperson standalone_imperson test unittest
endif

PROJ_NAME = imperson_cpp
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

ifeq ($(SUPPORT_IMGSRV),TRUE)
SUPPORT_IMGSRV = TRUE
else
SUPPORT_IMGSRV = FALSE
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
LDFLAGS	= -lib
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

CC = cc
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
LDFLAGS = -L/usr/local/openssl/lib
# Link ssl library statically from /usr/local/openssl/lib dir to prevent
# use of shared library loaded from /usr/freeware dir which is in the compiler path.
STD_LIBS += -B static -lssl -lcrypto -B dynamic -lC -lc -lm -lpthread 
INC 	+= -I/usr/include/CC \
           -I/usr/local/include \
           -I/usr/local/openssl/include


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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl

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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl

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
CFLAGS  += -fexceptions -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS =
LDFLAGS =
STD_LIBS += -lm -lrt -lpthread -lc -lz -lssl

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
CODE_DIR = ..$(SLASH)src
TEST_DIR = .$(SLASH)test




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

# HTTP_CPP
AUTH_CLIENT_DIR = ..$(SLASH)auth_client
AUTH_CLIENT_INCLUDE = -I${AUTH_CLIENT_DIR}$(SLASH)src
AUTH_CLIENT_LIB = $(AUTH_CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)libauthclient$(LIBEXT)

# CBF
CBF_DIR = ../cbf
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.a

# diffimage
DIFFIMAGE_DIR = ..$(SLASH)diffimage
DIFFIMAGE_INCLUDE = -I${DIFFIMAGE_DIR}$(SLASH)src
DIFFIMAGE_LIB = $(DIFFIMAGE_DIR)$(SLASH)$(MACHINE)$(SLASH)diffimage$(LIBEXT)

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(AUTH_CLIENT_INCLUDE)	

IMGSRV_INC = $(JPEGSOC_INCLUDE) \
	$(JPEG_INCLUDE) \
	$(CBF_INCLUDE) \
	$(DIFFIMAGE_INCLUDE)


########################################################
# Libraries
########################################################

LIBS += $(AUTH_CLIENT_LIB) \
	$(HTTP_CPP_LIB) \
	$(XOS_CPP_LIB) \
	$(LOGGING_LIB) \
	$(XOS_LIB) \
	$(STD_LIBS)

IMGSRV_LIBS = 	$(DIFFIMAGE_LIB) \
	$(CBF_LIB) \
	$(JPEGSOC_LIB) \
	$(JPEG_LIB)


########################################################
# Object files
########################################################

test_objs =	  $(MACHINE)/test.o
test_appendfile_objs =	  $(MACHINE)/testAppendFile.o
read_image_objs =	  $(MACHINE)/read_image.o
TestWriteFilesObjs = $(MACHINE)/TestWriteFiles.o

common_objs =	  $(MACHINE)/ImpCommandFactory.o \
          $(MACHINE)/ImpReadFile.o \
          $(MACHINE)/ImpWriteFile.o \
          $(MACHINE)/ImpWriteFiles.o \
          $(MACHINE)/ImpRunExecutable.o \
          $(MACHINE)/ImpRunScript.o \
          $(MACHINE)/ImpListDirectory.o \
          $(MACHINE)/ImpFileAccess.o \
          $(MACHINE)/ImpVersion.o \
          $(MACHINE)/ImpProcess.o \
          $(MACHINE)/ImpServer.o
	
objs = ${common_objs} $(MACHINE)/InetdServer.o
standalone_objs = ${common_objs} $(MACHINE)/StandAloneImpServer.o 
imgsrv_objs = $(MACHINE)/ImpGetImage.o
imgcmd_objs = $(MACHINE)/ImageCmd.o
unittest_objs = $(MACHINE)/ImpTestCommon.o \
		$(MACHINE)/test_main.o \
		$(MACHINE)/TestGetFilePermissions.o \
		$(MACHINE)/TestGetFileStatus.o

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/InetdServer.o: $(SRC_DIR)$(SLASH)InetdServer.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/StandAloneImpServer.o: $(SRC_DIR)$(SLASH)StandAloneImpServer.cxx $(SRC_DIR)$(SLASH)ImpServer.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpCommandFactory.o: $(SRC_DIR)$(SLASH)ImpCommandFactory.cxx $(SRC_DIR)$(SLASH)ImpCommandFactory.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/ImpReadFile.o: $(SRC_DIR)$(SLASH)ImpReadFile.cxx $(SRC_DIR)$(SLASH)ImpReadFile.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpWriteFile.o: $(SRC_DIR)$(SLASH)ImpWriteFile.cxx $(SRC_DIR)$(SLASH)ImpWriteFile.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/ImpWriteFiles.o: $(SRC_DIR)$(SLASH)ImpWriteFiles.cxx $(SRC_DIR)$(SLASH)ImpWriteFiles.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/ImpRunExecutable.o: $(SRC_DIR)$(SLASH)ImpRunExecutable.cxx $(SRC_DIR)$(SLASH)ImpRunExecutable.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpRunScript.o: $(SRC_DIR)$(SLASH)ImpRunScript.cxx $(SRC_DIR)$(SLASH)ImpRunScript.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpListDirectory.o: $(SRC_DIR)$(SLASH)ImpListDirectory.cxx $(SRC_DIR)$(SLASH)ImpListDirectory.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpGetImage.o: $(SRC_DIR)$(SLASH)ImpGetImage.cxx $(SRC_DIR)$(SLASH)ImpGetImage.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $(IMGSRV_INC) $<

$(MACHINE)/ImpFileAccess.o: $(SRC_DIR)$(SLASH)ImpFileAccess.cxx $(SRC_DIR)$(SLASH)ImpFileAccess.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpVersion.o: $(SRC_DIR)$(SLASH)ImpVersion.cxx $(SRC_DIR)$(SLASH)ImpVersion.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpProcess.o: $(SRC_DIR)$(SLASH)ImpProcess.cxx $(SRC_DIR)$(SLASH)ImpProcess.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImpServer.o: $(SRC_DIR)$(SLASH)ImpServer.cxx $(SRC_DIR)$(SLASH)ImpServer.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/testAppendFile.o: $(SRC_DIR)$(SLASH)testAppendFile.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/read_image.o: $(SRC_DIR)$(SLASH)read_image.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImageCmd.o: $(SRC_DIR)$(SLASH)ImageCmd.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $(IMGSRV_INC) $<

$(MACHINE)/ImpTestCommon.o: $(TEST_DIR)$(SLASH)ImpTestCommon.cxx $(TEST_DIR)$(SLASH)ImpTestCommon.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TestGetFilePermissions.o: $(TEST_DIR)$(SLASH)TestGetFilePermissions.cxx $(TEST_DIR)$(SLASH)TestGetFilePermissions.h $(TEST_DIR)$(SLASH)ImpTestCommon.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TestGetFileStatus.o: $(TEST_DIR)$(SLASH)TestGetFileStatus.cxx $(TEST_DIR)$(SLASH)TestGetFileStatus.h $(TEST_DIR)$(SLASH)ImpTestCommon.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test_main.o: $(TEST_DIR)$(SLASH)test_main.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TestWriteFiles.o: $(TEST_DIR)$(SLASH)TestWriteFiles.cxx
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
	-$(RM) $(MACHINE)$(SLASH)*test*
	-$(RM) $(MACHINE)$(SLASH)*.d
	-$(RM) $(MACHINE)$(SLASH)imgcmd
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


imperson: showinfo makedir $(objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@.d" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@.d $(LDFLAGS) $(objs) $(LIBS)
endif

standalone_imperson: showinfo makedir $(standalone_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@" $(LDFLAGS) $(standalone_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@ $(LDFLAGS) $(standalone_objs) $(LIBS)
endif

ifeq ($(SUPPORT_IMGSRV),TRUE)

imgsrv: showinfo makedir $(objs) $(imgsrv_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@.d" $(LDFLAGS) $(objs) $(imgsrv_objs) $(IMGSRV_LIBS) $(LIBS) 
else
	$(LINK) -o $(MACHINE)$(SLASH)$@.d $(LDFLAGS) $(objs) $(imgsrv_objs) $(IMGSRV_LIBS) $(LIBS)  
endif

imgcmd: showinfo makedir $(imgcmd_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(imgcmd_objs) $(IMGSRV_LIBS) $(LIBS)
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(imgcmd_objs) $(IMGSRV_LIBS) $(LIBS)
endif

read_image: makedir $(read_image_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(read_image_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(read_image_objs) $(LIBS)
endif

endif # SUPPORT_IMGSRV

test: makedir $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(LIBS)
endif

appendfile: makedir $(test_appendfile_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_appendfile_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(test_appendfile_objs) $(LIBS)
endif

testGetFilePermissions: makedir $(testGetFilePermissions_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(testGetFilePermissions_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(testGetFilePermissions_objs) $(LIBS)
endif

unittest: makedir $(unittest_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(unittest_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(unittest_objs) $(LIBS)
endif

TestWriteFiles: makedir $(TestWriteFilesObjs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(TestWriteFilesObjs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(TestWriteFilesObjs) $(LIBS)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: imperson doc
	$(CP) $(MACHINE)$(SLASH)imperson.d /usr/local/sbin/imperson_test.d 
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)installation.txt $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


