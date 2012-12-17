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
	@echo imgsrv application is not supprted on Windows platform
else
default: imgsrv test test1 filebrowser  gui_test http_test
endif

PROJ_NAME = imgsrv
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

# JPEG directory
JPEG_DIR =
JPEG_INCLUDE =
JPEG_LIB = 

# CBF directory
CBF_DIR = ../cbflib
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.a

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

ifeq ($(NO_IMPSERVER),TRUE)
CFLAGS += -DNO_IMPSERVER
endif

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)


# CBF directory
CBF_DIR = ../cbflib
CBF_INCLUDE = -I$(CBF_DIR)/include
CBF_LIB = $(CBF_DIR)/lib/$(MACHINE)/libcbf.a


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
		-ptr $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(AUTH_CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(DIFFIMAGE_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
		
STD_LIBS += -lm -lrt -lpthread -lc -lmach -lexc -lssl
STD_INC = -I/usr/include/cxx \
           -I/usr/local/include

# JPEG directory
JPEG_DIR = /home/code/jpeg-6b/release/$(MACHINE)
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = $(JPEGSOC_DIR)/$(MACHINE)/jpegsoc_applack$(LIBEXT)

# Image Magick library
ifeq ($(IMAGEMAGICK_MARKUP),TRUE)
#MAGICK_DIR = /data5/penjitk/download/nick_imgsrv/project_sources/ImageMagick-6.3.1
MAGICK_DIR = /data5/penjitk/download/nick_imgsrv/ImageMagick-6.3.2
MAGICK_INCLUDE = -I$(MAGICK_DIR) -I$(MAGICK_DIR)/Magick++/lib
MAGICK_LIB = $(MAGICK_DIR)/$(MACHINE)/libMagick++.a $(MAGICK_DIR)/$(MACHINE)/libWand.a $(MAGICK_DIR)/$(MACHINE)/libMagick.a
CFLAGS += -DIMAGEMAGICK_MARKUP -D__USE_STD_IOSTREAM
LDFLAGS += -ptr $(MAGICK_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
endif


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
CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET -D__host_mips -xc++ -MP:dsm=off -LANG:std -LANG:exceptions -no_prelink -ptused
#CFLAGS += -c -DIRIX -DPTHREADS -DSEC_BASE -DSEC_NET -xc++ -MP:dsm=off -LANG:std=on -LANG:exceptions=on -no_prelink -ptused
CPPFLAGS =
LDFLAGS = -L/usr/local/openssl/lib
# Link ssl library statically from /usr/local/openssl/lib dir to prevent
# use of shared library loaded from /usr/freeware dir which is in the compiler path.
STD_LIBS += -B static -lssl -lcrypto -B dynamic -lC -lc -lm -lpthread 
STD_INC = -I/usr/include/CC \
           -I/usr/local/include \
           -I/usr/local/openssl/include

# JPEG directory
JPEG_DIR = ../jpeg-6b
JPEG_INCLUDE = -I$(JPEG_DIR)
JPEG_LIB = $(JPEG_DIR)/libjpeg.a

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

# Image Magick library
ifeq ($(IMAGEMAGICK_MARKUP),TRUE)
MAGICK_DIR = /data5/penjitk/download/nick_imgsrv/project_sources/ImageMagick-6.3.1
MAGICK_INCLUDE = -I$(MAGICK_DIR) -I$(MAGICK_DIR)/Magick++/lib
MAGICK_LIB = $(MAGICK_DIR)/$(MACHINE)/libMagick++.a $(MAGICK_DIR)/$(MACHINE)/libWand.a $(MAGICK_DIR)/$(MACHINE)/libMagick.a
CFLAGS += -DIMAGEMAGICK_MARKUP
endif

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

# jpegsoc library
JPEGSOC_DIR = ../jpegsoc
JPEGSOC_INCLUDE = -I$(JPEGSOC_DIR)/src
JPEGSOC_LIB = ${JPEGSOC_DIR}/$(MACHINE)/jpegsoc_applack$(LIBEXT)

# Image Magick library
ifeq ($(IMAGEMAGICK_MARKUP),TRUE)
MAGICK_DIR =
MAGICK_INCLUDE =
ifeq ($(IMAGEMAGICK_STATICLIB),TRUE)
MAGICK_LIB = -Wl,-Bstatic -lMagick++ -lWand -lMagick  -Wl,-Bdynamic -ltiff -lfreetype -ljpeg -lpng -ldpstk \
		-ldps -lXext -lXt -lSM -lICE -lX11 -lbz2 -lxml2 -lz -lpthread \
		-lm -lpthread
LDFLAGS += -L/usr/X11R6/lib64
else
MAGICK_LIB = -lMagick++ -lWand -lMagick
endif
CFLAGS += -DIMAGEMAGICK_MARKUP
endif

# Support for PNG
ifeq ($(DIFFIMAGE_HAVE_PNG_Z),TRUE)
PNG_DIR =
PNG_INCLUDE =
PNG_LIB = -lpng
CFLAGS += -DDIFFIMAGE_HAVE_PNG_Z
endif

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
CFLAGS  += -fexceptions -fPIC -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS = -DLINUX -Wall
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


# Image Magick library
# Linking against the distributed version of ImageMagick seems to
# work on 32bit RHEL5 and RHEL6
ifeq ($(IMAGEMAGICK_MARKUP),TRUE)
MAGICK_DIR =
MAGICK_INCLUDE = -I/usr/include/ImageMagick

# On 64bit RHEL5 build against a recent statically built ImageMagick
ifeq ($(IMAGEMAGICK_STATICLIB),TRUE)
MAGICK_DIR = /home/sw/rhel5/x86_64/magick
MAGICK_INCLUDE = -I$(MAGICK_DIR)/include/ImageMagick

# The libraries needed is dependent on what features were compiled into libMagick++
# Look in the file $(MAGICK_DIR)/lib/libMagick++.la for exact info.
MAGICK_LIB = -Wl,-Bstatic -lMagick++ -lMagickWand -lMagickCore  -Wl,-Bdynamic \
	-llcms -ltiff -lfreetype -ljasper -ljpeg -lpng12 -lwmflite -lbz2 -lIlmImf -lImath -lHalf -lIex -lz -lgomp

LDFLAGS += -pthread -fopenmp -L$(MAGICK_DIR)/lib

else
# For RHEL5
MAGICK_LIB = -lMagick++ -lWand -lMagick
# For RHEL6
#MAGICK_LIB = -lMagick++ -lMagickWand -lMagickCore
endif
CFLAGS += -DIMAGEMAGICK_MARKUP
endif

# Support for PNG
ifeq ($(DIFFIMAGE_HAVE_PNG_Z),TRUE)
PNG_DIR =
PNG_INCLUDE =
PNG_LIB = -lpng
CFLAGS += -DDIFFIMAGE_HAVE_PNG_Z
endif

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
CFLAGS  += -fexceptions -fPIC -c -DLINUX -pthread -D_REENTRANT -D_FILE_OFFSET_BITS=64
CPPFLAGS = -DLINUX -Wall
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

# Image Magick library
ifeq ($(IMAGEMAGICK_MARKUP),TRUE)
MAGICK_DIR =
MAGICK_INCLUDE =
ifeq ($(IMAGEMAGICK_STATICLIB),TRUE)
MAGICK_LIB = -Wl,-Bstatic -lMagick++ -lWand -lMagick  -Wl,-Bdynamic -ltiff -lfreetype -ljpeg -lpng -ldpstk \
		-ldps -lXext -lXt -lSM -lICE -lX11 -lbz2 -lxml2 -lz -lpthread \
		-lm -lpthread
LDFLAGS += -L/usr/X11R6/lib64
else
MAGICK_LIB = -lMagick++ -lWand -lMagick
endif
CFLAGS += -DIMAGEMAGICK_MARKUP
endif

# Support for PNG
ifeq ($(DIFFIMAGE_HAVE_PNG_Z),TRUE)
PNG_DIR =
PNG_INCLUDE =
PNG_LIB = -lpng
CFLAGS += -DDIFFIMAGE_HAVE_PNG_Z
endif

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

# HTTP_CPP
AUTH_CLIENT_DIR = ..$(SLASH)auth_client
AUTH_CLIENT_INCLUDE = -I${AUTH_CLIENT_DIR}$(SLASH)src
AUTH_CLIENT_LIB = $(AUTH_CLIENT_DIR)$(SLASH)$(MACHINE)$(SLASH)libauthclient$(LIBEXT)

# diffimage
DIFFIMAGE_DIR = ..$(SLASH)diffimage
DIFFIMAGE_INCLUDE = -I${DIFFIMAGE_DIR}$(SLASH)src
DIFFIMAGE_LIB = $(DIFFIMAGE_DIR)$(SLASH)$(MACHINE)$(SLASH)diffimage$(LIBEXT)

# diffimage
DCSCONFIG_DIR = ..$(SLASH)dcsconfig
DCSCONFIG_INCLUDE = -I${DCSCONFIG_DIR}$(SLASH)src
DCSCONFIG_LIB = $(DCSCONFIG_DIR)$(SLASH)$(MACHINE)$(SLASH)libdcsconfig$(LIBEXT)



########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(MAGICK_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE) \
	$(AUTH_CLIENT_INCLUDE) \
	$(DCSCONFIG_INCLUDE) \
	$(JPEGSOC_INCLUDE) \
	$(JPEG_INCLUDE) \
	$(PNG_INCLUDE) \
	$(CBF_INCLUDE) \
	$(DIFFIMAGE_INCLUDE) \
	$(STD_INC)
	



########################################################
# Libraries
########################################################

LIBS += $(DCSCONFIG_LIB) \
		$(AUTH_CLIENT_LIB) \
		$(HTTP_CPP_LIB) \
		$(DIFFIMAGE_LIB) \
		$(XOS_CPP_LIB) \
		$(CBF_LIB) \
		$(JPEGSOC_LIB) \
		$(JPEG_LIB) \
		$(LOGGING_LIB) \
		$(XOS_LIB) \
		$(MAGICK_LIB) \
		$(PNG_LIB) \
		$(STD_LIBS)


########################################################
# Object files
########################################################

test_objs =	  $(MACHINE)/test.o

test1_objs = $(MACHINE)/test1.o

test_cache_objs = $(MACHINE)/test_cache.o

gui_test_objs = $(MACHINE)/gui_test.o

http_test_objs = $(MACHINE)/http_test.o

filebrowser_objs = $(MACHINE)/filebrowser.o

objs =	  $(MACHINE)/imgsrv_client.o \
		  $(MACHINE)/imgsrv_cache.o \
		  $(MACHINE)/ImgServerHandler.o \
		  $(MACHINE)/imgsrv_main.o \
		  $(MACHINE)/SessionCache.o \
		  $(MACHINE)/imgsrv_validation.o
	

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/filebrowser.o: $(SRC_DIR)$(SLASH)filebrowser.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/imgsrv_client.o: $(SRC_DIR)$(SLASH)imgsrv_client.cxx $(SRC_DIR)$(SLASH)imgsrv_client.h $(SRC_DIR)$(SLASH)imgsrv_cache.h $(SRC_DIR)$(SLASH)ImgSrvCacheEntry.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imgsrv_cache.o: $(SRC_DIR)$(SLASH)imgsrv_cache.cxx $(SRC_DIR)$(SLASH)imgsrv_cache.h $(SRC_DIR)$(SLASH)ImgSrvCacheEntry.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SessionCache.o: $(SRC_DIR)$(SLASH)SessionCache.cxx $(SRC_DIR)$(SLASH)SessionCache.h $(SRC_DIR)$(SLASH)SessionInfo.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/imgsrv_main.o: $(SRC_DIR)$(SLASH)imgsrv_main.c
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/ImgServerHandler.o: $(SRC_DIR)$(SLASH)ImgServerHandler.cxx $(SRC_DIR)$(SLASH)ImgServerHandler.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/imgsrv_validation.o: $(SRC_DIR)$(SLASH)imgsrv_validation.cxx $(SRC_DIR)$(SLASH)imgsrv_validation.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/gui_test.o: $(SRC_DIR)$(SLASH)gui_test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/http_test.o: $(SRC_DIR)$(SLASH)http_test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test1.o: $(SRC_DIR)$(SLASH)test1.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test_cache.o: $(SRC_DIR)$(SLASH)test_cache.cxx
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
	-$(RM) $(MACHINE)$(SLASH)imgsrv$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)filebrowser*$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)filebrower$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*.d
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# exe target


imgsrv: showinfo makedir $(objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(objs) $(LIBS)
endif

test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(test_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(HTTP_CPP_LIB)  $(XOS_CPP_LIB) $(XOS_LIB) $(LIBS)
endif

test1: $(test1_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(test1_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test1_objs) $(XOS_CPP_LIB) $(XOS_LIB) $(LIBS)
endif

test_cache: $(test_cache_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(test_cache_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_cache_objs) $(XOS_CPP_LIB) $(XOS_LIB) $(LIBS)
endif

gui_test: $(gui_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(gui_test_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(gui_test_objs) $(XOS_CPP_LIB) $(XOS_LIB) $(LIBS)
endif

http_test: $(http_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(http_test_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(http_test_objs) $(XOS_CPP_LIB) $(XOS_LIB) $(LIBS)
endif

filebrowser: $(filebrowser_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(filebrowser_objs) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(filebrowser_objs) $(XOS_LIB) $(LIBS)
endif

# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: imgsrv doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	


