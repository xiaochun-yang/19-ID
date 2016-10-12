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
	@echo autochooch is not supprted on Windows platform
else
default: all
all: ifort_warning Benny_auto Chooch_auto wasel
endif

PROJ_NAME = chooch
PROJ_VERSION	 = head
INSTALL_DIR = ./install

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
CFLAGS += -o $@ -c

LIBEXT	= .a
EXEEXT  =

ifeq ($(DEBUG),TRUE)
CFLAGS += -g
else
CFLAGS += -DNDEBUG -O
endif

DOXYGEN_EXE = /home/penjitk/software/doxygen/$(MACHINE)/doxygen-1.3/bin/doxygen
DOT_EXE = /home/penjitk/software/graphviz/$(MACHINE)/graphviz_1.8/bin/dot
WWW_DOC_DIR = /home/webserverroot/secure/staff_pages/projects/packages/$(PROJ_NAME)



ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

# FORTRAN
FC     = f77
FFLAGS = -O5 -tune host
FLDFLAGS = 

# C/C++
CC = cc 
LINK = cc 
CFLAGS += -w0 -pthread -DDEC_UNIX
LDFLAGS =
STD_LIBS += -lc


# PGPLOT library
HAS_PGPLOT = FALSE
PGPLOT_DIR = /usr/local/pgplot
PGPLOT_LIB = ${PGPLOT_DIR}/libpgplot.a

# X11 library
X11LIB_DIR = /usr/X11R6/lib


endif

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)

# FORTRAN
FC     = f77
FFLAGS = -O2
FLDFLAGS = 

# C/C++
ifeq ($(PURIFY),TRUE)
CC      = purify cc
LINK      = purify cc
else
CC      = cc
LINK      = cc
endif
CFLAGS  += -MP:dsm=off -DIRIX
LDFLAGS = 
STD_LIBS += -lc


# PGPLOT library
HAS_PGPLOT = FALSE
PGPLOT_DIR = /usr/local/pgplot
PGPLOT_LIB = ${PGPLOT_DIR}/libpgplot.a

# X11 library
X11LIB_DIR = /usr/X11R6/lib


endif


ifeq ($(MACHINE),linux)

########################################################
# linux 
########################################################

# FORTRAN
# Use Intel compiler instead of gcc
# Make sure you have the configuration loaded ( module load intel_comp )
FC     = ifort
# Compiler options
# -fast turns on -O3 and -IPO
# -axKWP both optimizes the code for a PIII P4 and P4 w/ SSE 3.
#yangx FFLAGS =  -static -fast -axKWP
FFLAGS =  -Bstatic -axKWP
FLDFLAGS = 

# C/C++
ifeq ($(PURIFY),TRUE)
CC      = purify cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -pthread -D_REENTRANT
LDFLAGS =
STD_LIBS += -lc

# PGPLOT library
HAS_PGPLOT = FALSE
PGPLOT_DIR = /usr/local/pgplot
PGPLOT_LIB = ${PGPLOT_DIR}/libpgplot.a

# X11 library
X11LIB_DIR = /usr/lib


# endif linux
endif

ifeq ($(MACHINE),linux64)

########################################################
# linux x86_64
########################################################

# FORTRAN
# Use Intel compiler instead of gcc
# Make sure you have the configuration loaded ( module load intel_comp )
FC     = ifort
# Compiler options
# -fast turns on -O3 and -IPO
# -axKWT optimizes the code for a P4, P4 w/ SSE 3 and Core 2 Duo.
FFLAGS =  -static -fast -mp1 -axWPT
FLDFLAGS = 

# C/C++
ifeq ($(PURIFY),TRUE)
CC      = purify cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -pthread -D_REENTRANT
LDFLAGS =
STD_LIBS += -lc

# PGPLOT library
HAS_PGPLOT = FALSE
PGPLOT_DIR = /usr/local/pgplot
PGPLOT_LIB = ${PGPLOT_DIR}/libpgplot.a

# X11 library
X11LIB_DIR = /usr/lib


# endif linux
endif

ifeq ($(MACHINE),ia64)

########################################################
# linux ia64
########################################################

# FORTRAN
# Use Intel compiler instead of gcc
# Make sure you have the configuration loaded ( module load intel_comp )
FC     = ifort
# Compiler options
# -fast turns on -O3 and -IPO
# -axKWP both optimizes the code for a PIII P4 and P4 w/ SSE 3.
FFLAGS =  -static -fast
FLDFLAGS = 

# C/C++
ifeq ($(PURIFY),TRUE)
CC      = purify cc
LINK    = purify cc
else
CC      = cc
LINK    = cc
endif
CFLAGS  += -DLINUX -pthread -D_REENTRANT
LDFLAGS =
STD_LIBS += -lc

# PGPLOT library
HAS_PGPLOT = FALSE
PGPLOT_DIR = /usr/local/pgplot
PGPLOT_LIB = ${PGPLOT_DIR}/libpgplot.a

# X11 library
X11LIB_DIR = /usr/lib


# endif linux
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



########################################################
# Include directories
########################################################




########################################################
# Libraries
########################################################

ifeq ($(HAS_PGPLOT),TRUE)
FLDFLAGS = -L$(X11LIB_DIR)
FLIBS += $(PGPLOT_LIB)
endif

LIBS += $(STD_LIBS)


########################################################
# Object files
########################################################


bennyObjs  = $(MACHINE)/polfit.o \
			$(MACHINE)/Benny_auto.o


choochObjs = $(MACHINE)/Chooch_auto.o \
			$(MACHINE)/extrap.o \
			$(MACHINE)/entest.o \
			$(MACHINE)/eqofline.o \
			$(MACHINE)/mucal.o \
			$(MACHINE)/upcase.o

ifeq ($(HAS_PGPLOT),TRUE)
choochObjs += $(MACHINE)/efsplot.o
endif

waselObjs	= $(MACHINE)/wasel_1.2.o


########################################################
#
# Targets
#
########################################################


# Object files

$(MACHINE)/polfit.o: $(SRC_DIR)$(SLASH)polfit.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/Benny_auto.o: $(SRC_DIR)$(SLASH)Benny_auto.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/Chooch_auto.o: $(SRC_DIR)$(SLASH)Chooch_auto.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/extrap.o: $(SRC_DIR)$(SLASH)extrap.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/entest.o: $(SRC_DIR)$(SLASH)entest.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/eqofline.o: $(SRC_DIR)$(SLASH)eqofline.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/efsplot.o: $(SRC_DIR)$(SLASH)efsplot.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/mucal.o: $(SRC_DIR)$(SLASH)mucal.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/upcase.o: $(SRC_DIR)$(SLASH)upcase.f
	$(FC) -c $(FFLAGS) -o $@ $<

$(MACHINE)/wasel_1.2.o: $(SRC_DIR)$(SLASH)wasel_1.2.c
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

ifort_warning:
	@echo ...
	@echo ...
	@echo If ifort compiler path is not set, Use the \'module\' command 
	@echo to load the correct environment. i.e \'module load intel_fc\'
	@echo If module is not found, type the following for RHEL4
	@echo \> source /home/sw/rhel4/Modules/default/init/tcsh
	@echo \> module load intel_fc
	@echo On 64 bit RHEL5 machines that does not have modules, use
	@echo \> source /home/sw/intel/fce/10.1.022/bin/ifortvars.csh


# Cleaning the output files. Can be used before re-build all.

clean: 
	-$(RM) $(MACHINE)$(SLASH)*.o
	-$(RM) $(MACHINE)$(SLASH).pure.*
	-$(RM) $(MACHINE)$(SLASH)Benny_auto$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)Chooch_auto$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)wasel$(EXEEXT)
	-$(RM) $(MACHINE)$(SLASH)*test*$(EXEEXT)


# exe target

Benny_auto : showinfo makedir $(bennyObjs)
	$(FC) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(bennyObjs) $(FFLAGS) $(FLDFLAGS) $(FLIBS)

Chooch_auto : showinfo makedir $(choochObjs)
	$(FC) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(choochObjs) $(FFLAGS) $(FLDFLAGS) $(FLIBS)


wasel: showinfo makedir $(waselObjs)
	$(LINK) -o $(MACHINE)$(SLASH)$@$(EXEEXT) $(LDFLAGS) $(waselObjs) $(LIBS)

# document target


cleandoc: 
	-$(RM) doc$(SLASH)$(PROJ_VERSION)
	-$(RM) doc$(SLASH)log.txt
	-$(RM) doc$(SLASH)$(PROJ_NAME).tag

install: all
	-$(MKDIR) $(INSTALL_DIR)
	-$(MKDIR) $(INSTALL_DIR)$(SLASH)data
	-$(MKDIR) $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)data$(SLASH)* $(INSTALL_DIR)$(SLASH)data
	$(CP) .$(SLASH)$(MACHINE)$(SLASH)Benny_auto $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(MACHINE)$(SLASH)Chooch_auto $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(MACHINE)$(SLASH)wasel $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(SRC_DIR)$(SLASH)chooch_remote*.sh $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(SRC_DIR)$(SLASH)Chooch_auto.sh $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(SRC_DIR)$(SLASH)run_autochooch.csh $(INSTALL_DIR)$(SLASH)bin
	$(CP) .$(SLASH)$(SRC_DIR)$(SLASH)wasel_auto $(INSTALL_DIR)$(SLASH)bin
	chmod 755 $(INSTALL_DIR)$(SLASH)data$(SLASH)*
	chmod 755 $(INSTALL_DIR)$(SLASH)bin$(SLASH)*


./doc/$(PROJ_VERSION)/html/index.html: $(objs)
	-@$(MKDIR) .$(SLASH)doc$(SLASH)$(PROJ_VERSION)
	-$(DOXYGEN_EXE) .$(SLASH)doc$(SLASH)doxygen.cfg

doc: ./doc/$(PROJ_VERSION)/html/index.html



