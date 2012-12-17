########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: libhttp rawsocketclient_test http_client


HTTP_LIB =
PROJ_NAME = http_cpp
PROJ_VERSION = head

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
CP	= copy
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
STD_LIBS 	+= wsock32.lib user32.lib
HTTP_CPP_LIB	 = libhttp-cpp.lib


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
CFLAGS += -o $@
CPPFLAGS =
HTTP_CPP_LIB	= libhttp-cpp.a
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
LDFLAGS = -ptr $(TEMPLATES_DIR) \
		-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
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
LDFLAGS = -L/usr/local/openssl/lib
# Link ssl library statically from /usr/local/openssl/lib dir to prevent
# use of shared library loaded from /usr/freeware dir which is in the compiler path.
STD_LIBS += -B static -lssl -B dynamic -lC -lc -lm -lpthread 
INC 	+= -I/usr/include/CC \
           -I/usr/local/include \
           -I/usr/local/openssl/include


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
CPPFLAGS = -DLINUX
LDFLAGS =
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


# source directory
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

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(XOS_CPP_INCLUDE)


########################################################
# Libraries
########################################################

LIBS += $(XOS_CPP_LIB) $(LOGGING_LIB) $(XOS_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################

http_client_objs = $(MACHINE)/http_client.o
test_objs = $(MACHINE)/test.o
rawsocketclient_test_objs = $(MACHINE)/RawSocketClientTest.o
testClient_objs = $(MACHINE)/TestClient.o
testServer_objs = $(MACHINE)/testServer.o

objs =	  $(MACHINE)/InetdServer.o \
          $(MACHINE)/HttpStreamFactory.o \
          $(MACHINE)/HttpMessage.o \
          $(MACHINE)/HttpRequest.o \
          $(MACHINE)/HttpUtil.o \
          $(MACHINE)/HttpResponse.o \
          $(MACHINE)/HttpClientImp.o \
          $(MACHINE)/HttpClientSSLImp.o \
          $(MACHINE)/SSLCommon.o \
          $(MACHINE)/HttpCookie.o \
          $(MACHINE)/SocketServer.o
	

########################################################
#
# Targets
#
########################################################


# Object files


$(MACHINE)/HttpUtil.o: $(SRC_DIR)$(SLASH)HttpUtil.cxx $(SRC_DIR)$(SLASH)HttpUtil.h $(SRC_DIR)$(SLASH)HttpConst.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/XosStringUtil.o: $(SRC_DIR)$(SLASH)XosStringUtil.cxx $(SRC_DIR)$(SLASH)XosStringUtil.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<
	
$(MACHINE)/InetdServer.o: $(SRC_DIR)$(SLASH)InetdServer.cxx $(SRC_DIR)$(SLASH)InetdServer.h $(SRC_DIR)$(SLASH)HttpServer.h $(SRC_DIR)$(SLASH)HttpServerHandler.h $(SRC_DIR)$(SLASH)HttpConst.h $(SRC_DIR)$(SLASH)HttpStatusCodes.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SocketServer.o: $(SRC_DIR)$(SLASH)SocketServer.cxx $(SRC_DIR)$(SLASH)SocketServer.h $(SRC_DIR)$(SLASH)HttpServer.h $(SRC_DIR)$(SLASH)HttpServerHandler.h $(SRC_DIR)$(SLASH)HttpConst.h $(SRC_DIR)$(SLASH)HttpStatusCodes.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpMessage.o: $(SRC_DIR)$(SLASH)HttpMessage.cxx $(SRC_DIR)$(SLASH)HttpMessage.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpRequest.o: $(SRC_DIR)$(SLASH)HttpRequest.cxx $(SRC_DIR)$(SLASH)HttpRequest.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpResponse.o: $(SRC_DIR)$(SLASH)HttpResponse.cxx $(SRC_DIR)$(SLASH)HttpResponse.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpStreamFactory.o: $(SRC_DIR)$(SLASH)HttpServerFactory.cxx $(SRC_DIR)$(SLASH)HttpServerFactory.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpClientImp.o: $(SRC_DIR)$(SLASH)HttpClientImp.cxx $(SRC_DIR)$(SLASH)HttpClientImp.h $(SRC_DIR)$(SLASH)HttpClient.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpClientSSLImp.o: $(SRC_DIR)$(SLASH)HttpClientSSLImp.cxx $(SRC_DIR)$(SLASH)HttpClientSSLImp.h $(SRC_DIR)$(SLASH)HttpClient.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/SSLCommon.o: $(SRC_DIR)$(SLASH)SSLCommon.cxx $(SRC_DIR)$(SLASH)SSLCommon.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/HttpCookie.o: $(SRC_DIR)$(SLASH)HttpCookie.cxx $(SRC_DIR)$(SLASH)HttpCookie.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/TestClient.o: $(SRC_DIR)$(SLASH)TestClient.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/testServer.o: $(TEST_DIR)$(SLASH)testServer$(SLASH)testServer.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/http_client.o: $(SRC_DIR)$(SLASH)http_client.cxx
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/RawSocketClientTest.o: $(SRC_DIR)$(SLASH)RawSocketClientTest.cxx
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
	-$(RM) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB)
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)test*
	-$(RM) $(MACHINE)$(SLASH)http_client
	-$(RM) $(MACHINE)$(SLASH)rawsocketclient_test
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository
	-$(RM) doc$(SLASH)html
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)http_cpp.tag


# Libary target

libhttp: showinfo makedir $(objs)
	@echo ...
	@echo Making $(HTTP_CPP_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(HTTP_CPP_LIB)" $(objs)
else
	ar -vr $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(objs)
	-ranlib $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) 
endif


http_client: $(http_client_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(http_client_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(http_client_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)
endif

rawsocketclient_test: $(rawsocketclient_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(rawsocketclient_test_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(rawsocketclient_test_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)
endif


test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)
endif

testServer: $(testServer_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS) $(testServer_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(testServer_objs) $(MACHINE)$(SLASH)$(HTTP_CPP_LIB) $(LIBS)
endif


# document target

cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag


install: libhttp doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	
