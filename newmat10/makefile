########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

default: libnewmat


DCSCONFIG_LIB =
PROJ_NAME = newmat10
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
NEWMAT_LIB	 = libnewmat.lib


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
LIBEXT	= .a
EXEEXT  =


ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O2
endif


DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)

NEWMAT_LIB	 = libnewmat.a


ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

CC = cxx
CXX = cxx
LINK = cxx
TEMPLATES_DIR = ./$(MACHINE)/cxx_repository
CFLAGS += -c -ptr $(TEMPLATES_DIR) -w1 -pthread -DDEC_UNIX -DSEC_BASE -DSEC_NET
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
LDFLAGS =
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
CFLAGS  += -fexceptions -c -DLINUX -Wall -pthread -D_REENTRANT
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
CFLAGS  += -fexceptions -c -DLINUX -fPIC -pthread -D_REENTRANT
CPPFLAGS = -DLINUX
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
CFLAGS  += -fexceptions -c -fPIC -DLINUX -pthread -D_REENTRANT
CPPFLAGS = -DLINUX
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


########################################################
# Include directories
########################################################


INC +=  -I$(SRC_DIR)


########################################################
# Libraries
########################################################

LIBS += $(STD_LIBS)


########################################################
# Object files
########################################################


objs = $(MACHINE)/newmat1.o \
		$(MACHINE)/newmat2.o \
		$(MACHINE)/newmat3.o \
		$(MACHINE)/newmat4.o \
		$(MACHINE)/newmat5.o \
		$(MACHINE)/newmat6.o \
		$(MACHINE)/newmat7.o \
		$(MACHINE)/newmat8.o \
		$(MACHINE)/newmatex.o \
		$(MACHINE)/bandmat.o \
		$(MACHINE)/submat.o \
		$(MACHINE)/myexcept.o \
		$(MACHINE)/cholesky.o \
		$(MACHINE)/evalue.o \
		$(MACHINE)/fft.o \
		$(MACHINE)/hholder.o \
		$(MACHINE)/jacobi.o \
		$(MACHINE)/newfft.o \
		$(MACHINE)/sort.o \
		$(MACHINE)/svd.o \
		$(MACHINE)/newmatrm.o \
		$(MACHINE)/newmat9.o
	

########################################################
#
# Targets
#
########################################################


# Object files


$(MACHINE)/newmat1.o: $(SRC_DIR)$(SLASH)newmat1.cpp \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat2.o: $(SRC_DIR)$(SLASH)newmat2.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat3.o: $(SRC_DIR)$(SLASH)newmat3.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat4.o: $(SRC_DIR)$(SLASH)newmat4.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat5.o: $(SRC_DIR)$(SLASH)newmat5.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat6.o: $(SRC_DIR)$(SLASH)newmat6.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat7.o: $(SRC_DIR)$(SLASH)newmat7.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat8.o: $(SRC_DIR)$(SLASH)newmat8.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)newmatrc.h \
					  $(SRC_DIR)$(SLASH)precisio.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h \
					  $(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmatex.o: $(SRC_DIR)$(SLASH)newmatex.cpp \
					  $(SRC_DIR)$(SLASH)include.h \
					  $(SRC_DIR)$(SLASH)newmat.h \
					  $(SRC_DIR)$(SLASH)boolean.h \
					  $(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/bandmat.o: $(SRC_DIR)$(SLASH)bandmat.cpp \
						$(SRC_DIR)$(SLASH)include.h \
						$(SRC_DIR)$(SLASH)newmat.h \
						$(SRC_DIR)$(SLASH)newmatrc.h \
						$(SRC_DIR)$(SLASH)boolean.h \
						$(SRC_DIR)$(SLASH)myexcept.h \
						$(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/submat.o:  $(SRC_DIR)$(SLASH)submat.cpp \
						$(SRC_DIR)$(SLASH)include.h \
						$(SRC_DIR)$(SLASH)newmat.h \
						$(SRC_DIR)$(SLASH)newmatrc.h \
						$(SRC_DIR)$(SLASH)boolean.h \
						$(SRC_DIR)$(SLASH)myexcept.h \
						$(SRC_DIR)$(SLASH)controlw.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/myexcept.o: $(SRC_DIR)$(SLASH)myexcept.cpp \
						$(SRC_DIR)$(SLASH)include.h \
						$(SRC_DIR)$(SLASH)boolean.h \
						$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/cholesky.o: $(SRC_DIR)$(SLASH)cholesky.cpp \
						$(SRC_DIR)$(SLASH)include.h \
						$(SRC_DIR)$(SLASH)newmat.h \
						$(SRC_DIR)$(SLASH)boolean.h \
						$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/evalue.o: $(SRC_DIR)$(SLASH)evalue.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmatrm.h \
					$(SRC_DIR)$(SLASH)precisio.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/fft.o: $(SRC_DIR)$(SLASH)fft.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/hholder.o: $(SRC_DIR)$(SLASH)hholder.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/jacobi.o: $(SRC_DIR)$(SLASH)jacobi.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)precisio.h \
					$(SRC_DIR)$(SLASH)newmatrm.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newfft.o: $(SRC_DIR)$(SLASH)newfft.cpp \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/sort.o: $(SRC_DIR)$(SLASH)sort.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/svd.o: $(SRC_DIR)$(SLASH)svd.cpp \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)newmatap.h \
					$(SRC_DIR)$(SLASH)newmatrm.h \
					$(SRC_DIR)$(SLASH)precisio.h \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmatrm.o: $(SRC_DIR)$(SLASH)newmatrm.cpp \
					$(SRC_DIR)$(SLASH)newmat.h \
					$(SRC_DIR)$(SLASH)newmatrm.h \
					$(SRC_DIR)$(SLASH)include.h \
					$(SRC_DIR)$(SLASH)boolean.h \
					$(SRC_DIR)$(SLASH)myexcept.h
	$(CXX) $(CFLAGS) $(CPPFLAGS) $(INC) $<

$(MACHINE)/newmat9.o: $(SRC_DIR)$(SLASH)newmat9.cpp \
			$(SRC_DIR)$(SLASH)include.h \
			$(SRC_DIR)$(SLASH)newmat.h \
			$(SRC_DIR)$(SLASH)newmatio.h \
			$(SRC_DIR)$(SLASH)newmatrc.h \
			$(SRC_DIR)$(SLASH)boolean.h \
			$(SRC_DIR)$(SLASH)myexcept.h \
			$(SRC_DIR)$(SLASH)controlw.h
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
	-@$(RM) $(MACHINE)$(SLASH)*.exe
	-@$(RM) $(MACHINE)$(SLASH)*.idb
	-@$(RM) $(MACHINE)$(SLASH)*.pdb
	-@$(RM) $(MACHINE)$(SLASH).pure.*
	-@$(RM) $(MACHINE)$(SLASH)$(NEWMAT_LIB)
	-@$(RM) $(MACHINE)$(SLASH)*$(LIBEXT)
	-@$(RM) $(MACHINE)$(SLASH)test*
	-@$(RM) $(MACHINE)$(SLASH)ii_files
	-@$(RM) $(MACHINE)$(SLASH)cxx_repository
	-@$(RM) doc$(SLASH)html
	-@$(RM) doc$(SLASH)log.txt
	-@$(RM) doc$(SLASH)dcsconfig.tag


# Libary target

libnewmat: showinfo makedir $(objs)
	@echo ...
	@echo Making $(NEWMAT_LIB)
	@echo ...
ifeq ($(MACHINE),nt)
	 $(LINK) -lib $(LDFLAGS) -out:"$(MACHINE)$(SLASH)$(NEWMAT_LIB)" $(objs)
else
	ar -vr $(MACHINE)$(SLASH)$(NEWMAT_LIB) $(objs)
endif



# document target

cleandoc: 
	-@$(RM) doc$(SLASH)$(PROJ_VERSION)
	-@$(RM) doc$(SLASH)log.txt
	-@$(RM) doc$(SLASH)$(PROJ_NAME).tag


install: dcsconfig doc
	-$(RM) $(WWW_DOC_DIR)$(SLASH)html
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(MKDIR) $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	$(CP) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html$(SLASH)* $(WWW_DOC_DIR)$(SLASH)doc$(SLASH)$(PROJ_VERSION)$(SLASH)html
	

./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg
	
doc: ./doc/$(PROJ_VERSION)/html/index.html
	
