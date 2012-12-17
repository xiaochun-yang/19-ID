########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: libauthclient test testSSL proxy socktest memleak_test
 

AUTH_CLIENT_LIB =
PROJ_NAME = auth_client
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


INC		+=
STD_LIBS 	+= user32.lib wsock32.lib
AUTH_CLIENT_LIB	 = libauthclient.lib
WWW_DOC_DIR = 


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
LDFLAGS	=
AUTH_CLIENT_LIB	= libauthclient.a
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
		-ptr $(XOS_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository \
		-ptr $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)cxx_repository
STD_LIBS += -lm -lrt -lpthread -lc -lmach -lssl
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
STD_LIBS += -B static -lssl -lcrypto -B dynamic -lC -lc -lm -lpthread 
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
LDFLAGS	=
STD_LIBS += -lm -lrt -lpthread -lc -lssl


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
CPPFLAGS = -DLINUX
LDFLAGS  =
STD_LIBS += -lm -lrt -lpthread -lc -lssl


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
CPPFLAGS = -DLINUX
LDFLAGS  =
STD_LIBS += -lm -lrt -lpthread -lc -lssl


endif

#endif any unix
endif


########################################################
# directory macros
########################################################

# source directory
SRC_DIR = .$(SLASH)src
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

# XOS_CPP
HTTP_CPP_DIR = ..$(SLASH)http_cpp
HTTP_CPP_INCLUDE = -I${HTTP_CPP_DIR}$(SLASH)src
HTTP_CPP_LIB = $(HTTP_CPP_DIR)$(SLASH)$(MACHINE)$(SLASH)libhttp-cpp$(LIBEXT)

########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR) \
	$(XOS_INCLUDE) \
	$(LOGGING_INCLUDE) \
	$(XOS_CPP_INCLUDE) \
	$(HTTP_CPP_INCLUDE)


########################################################
# Libraries
########################################################

LIBS += $(HTTP_CPP_LIB) $(XOS_CPP_LIB) $(LOGGING_LIB)  $(XOS_LIB) $(STD_LIBS)


########################################################
# Object files
########################################################

test_objs = $(MACHINE)/test.o
testSSL_objs = $(MACHINE)/testSSL.o
proxy_objs = $(MACHINE)/proxy_server_test.o
mem_test_objs = $(MACHINE)/mem_test.o
socket_test_objs = $(MACHINE)/socket_test.o
memleak_test_objs = $(MACHINE)/memleak_test.o

objs =	  $(MACHINE)/Base64.o \
          $(MACHINE)/AuthClient.o
	

########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/Base64.o: $(SRC_DIR)$(SLASH)Base64.cxx $(SRC_DIR)$(SLASH)Base64.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<


$(MACHINE)/AuthClient.o: $(SRC_DIR)$(SLASH)AuthClient.cxx $(SRC_DIR)$(SLASH)AuthClient.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/test.o: $(SRC_DIR)$(SLASH)test.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/testSSL.o: $(SRC_DIR)$(SLASH)testSSL.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/proxy_server_test.o: $(TEST_DIR)$(SLASH)proxy_server_test.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/mem_test.o: $(TEST_DIR)$(SLASH)mem_test.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/socket_test.o: $(TEST_DIR)$(SLASH)socket_test.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/memleak_test.o: $(TEST_DIR)$(SLASH)memleak_test.cxx $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
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
	-$(RM) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)
	-$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*
	-$(RM) $(MACHINE)$(SLASH)proxy
	-$(RM) $(MACHINE)$(SLASH)ii_files
	-$(RM) $(MACHINE)$(SLASH)cxx_repository


# Libary target

libauthclient: showinfo makedir $(objs)
	@echo ...
	@echo Making $(AUTH_CLIENT_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB)" $(objs)
else
	ar -vr $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(objs)
	-ranlib $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) 
endif


test: $(test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)
endif

testSSL: $(testSSL_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(testSSL_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(testSSL_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)
endif

proxy: $(proxy_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(proxy_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(proxy_objs) $(LIBS)
endif

mem_test: $(mem_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(mem_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(mem_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)
endif

memleak_test: $(memleak_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(memleak_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(memleak_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)
endif

socktest: $(socket_test_objs)
ifeq ($(MACHINE),nt)
	 $(LINK) $(EXEFLAGS) -out:"$(MACHINE)$(SLASH)$@$(EXEEXT)" $(LDFLAGS)  $(socket_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)  
else
	$(LINK) -o $(MACHINE)/$@$(EXEEXT) $(LDFLAGS) $(socket_test_objs) $(MACHINE)$(SLASH)$(AUTH_CLIENT_LIB) $(LIBS)
endif


# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag


	
install: libauthclient doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html


./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)api
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html


	


