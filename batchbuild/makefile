########################################################
#
# This makefile should work with gmake 3.8
# Downloaded from http://ftp.gnu.org/pub/gnu/make/
#
########################################################

# Set the default target for this makefile. Put it 
# way up here to make sure that it's the first target
# defined in this makefile.

CVSCOMMAND=cvs -d :pserver:ogata@smb.slac.stanford.edu:/home/code/repository
CVSTAG=-A
#CVSCOMMAND=cvs

default: all

########################################################
#
# DEBUG or RELEASE
# Set DEBUG to TRUE by setting env variable DEBUG=TRUE
#
########################################################

# Debug flag is off by default
ifeq ($(DEBUG),TRUE)
DEBUG = TRUE
else
DEBUG = FALSE
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
ifeq ($(OSTYPE),osf1)
MACHINE = decunix
else
ifeq ($(OSTYPE),irix)
MACHINE = irix
else
ifeq ($(OSTYPE),linux)
MACHINE = linux
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

else

########################################################
#
# Any Unix
#
########################################################

SLASH = /


ifeq ($(MACHINE),decunix)

########################################################
# decunix 
########################################################

endif

########################################################
# irix 
########################################################

ifeq ($(MACHINE),irix)


endif


ifeq ($(MACHINE),linux)

########################################################
# linux 
########################################################


# endif linux
endif

#endif any unix
endif


# Include cvs project definitions
include include_cvs



########################################################
# BluIce
########################################################
cobluice:	co_xos \
		co_logging \
		co_xos_cpp \
		co_http_cpp \
		co_auth \
		co_auth_client \
		co_jpegsoc \
		co_newmat10 \
		co_tcl_clibs \
		co_dcsconfig \
		co_dcs_tcl_packages \
		co_DcsWidgets \
		co_blu-ice \
      		co_BluIceWidgets


bluice:		build_xos \
		build_logging \
		build_xos_cpp \
		build_http_cpp \
		build_auth \
		build_auth_client \
		build_jpegsoc \
		build_newmat10 \
		build_tcl_clibs
		
cleanbluice:	clean_xos \
		clean_logging \
		clean_xos_cpp \
		clean_http_cpp \
		clean_auth \
		clean_auth_client \
		clean_jpegsoc \
		clean_newmat10 \
		clean_tcl_clibs
		

		
		
########################################################
# Impersonation server
########################################################
coimperson: 	co_xos \
		co_logging \
		co_xos_cpp \
		co_http_cpp \
		co_auth_client \
		co_jpegsoc \
		co_cbf \
		co_diffimage \
		co_imperson_cpp

buildimperson: 	build_xos \
		build_logging \
		build_xos_cpp \
		build_http_cpp \
		build_auth_client \
		build_jpegsoc \
		build_cbf \
		build_diffimage \
		build_imperson_cpp

cleanimperson: 	clean_xos \
		clean_logging \
		clean_xos_cpp \
		clean_http_cpp \
		clean_auth_client \
		clean_jpegsoc \
		clean_cbf \
		clean_diffimage \
		clean_imperson_cpp


########################################################
# impdhs
########################################################
coimpdhs: 	co_xos \
		co_logging \
		co_xos_cpp \
		co_http_cpp \
		co_auth_client \
		co_dcsconfig \
		co_dcsmsg \
		co_impdhs

buildimpdhs: 	build_xos \
		build_logging \
		build_xos_cpp \
		build_http_cpp \
		build_auth_client \
		build_dcsconfig \
		build_dcsmsg \
		build_impdhs

cleanimpdhs: 	cleanxos \
		cleanlogging \
		cleanxos_cpp \
		cleanhttp_cpp \
		cleanauth_client \
		cleanimperson_cpp


########################################################
# Image server
########################################################
coimgsrv: 	co_xos \
		co_logging \
		co_jpegsoc \
		co_cbf \
		co_diffimage \
		co_xos_cpp \
		co_http_cpp \
		co_dcsconfig \
		co_auth_client \
		co_imgsrv

buildimgsrv: 	build_xos \
		build_logging \
		build_jpegsoc \
		build_cbf \
		build_diffimage \
		build_xos_cpp \
		build_http_cpp \
		build_dcsconfig \
		build_auth_client \
		build_imgsrv

cleanimgsrv: 	clean_xos \
		clean_logging \
		clean_jpegsoc \
		clean_cbf \
		clean_diffimage \
		clean_xos_cpp \
		clean_http_cpp \
		clean_dcsconfig \
		clean_auth_client \
		clean_imgsrv


########################################################
# Spotfinder
########################################################
cospotfinder: 	co_xos \
		co_logging \
		co_jpegsoc \
		co_cbf \
		co_diffimage \
		co_spotfinder
		
buildspotfinder: 	build_xos \
		build_logging \
		build_jpegsoc \
		build_cbf \
		build_diffimage \
		build_spotfinder

cleanspotfinder: 	clean_xos \
		clean_logging \
		clean_jpegsoc \
		clean_cbf \
		clean_diffimage \
		clean_spotfinder


########################################################
# cvs checkout all
########################################################

co: colibs coexe

codcss:  co_xos \
		co_xos_cpp \
		co_logging \
		co_dcsconfig \
		co_http_cpp \
		co_auth_client \
		co_dcss

cleandcss:  clean_xos \
		clean_xos_cpp \
		clean_logging \
		clean_dcsconfig \
		clean_http_cpp \
		clean_auth_client \
		clean_dcss

builddcss:  build_xos \
		build_xos_cpp \
		build_logging \
		build_dcsconfig \
		build_http_cpp \
		build_auth_client \
		build_dcss

colibs: 	co_xos \
		co_logging \
		co_xos_cpp \
		co_http_cpp \
		co_auth \
		co_auth_client \
		co_jpegsoc \
		co_cbf \
		co_diffimage \
		co_newmat10 \
		co_xform \
		co_tcl_clibs \
		co_dcsconfig \
		co_dcsmsg \
		co_dali \
		co_dcs_tcl_packages \
		co_java_dcss_sim \
		co_DcsWidgets
		
buildlibs: 	build_xos \
		build_logging \
		build_xos_cpp \
		build_http_cpp \
		build_auth \
		build_auth_client \
		build_jpegsoc \
		build_dali \
		build_cbf \
		build_diffimage \
		build_newmat10 \
		build_tcl_clibs \
		build_dcsconfig \
		build_dcsmsg

cleanlibs: 	clean_xos \
		clean_logging \
		clean_xos_cpp \
		clean_http_cpp \
		clean_auth \
		clean_auth_client \
		clean_MyAuthServer \
		clean_jpegsoc \
		clean_dali \
		clean_cbf \
		clean_diffimage \
		clean_newmat10 \
		clean_tcl_clibs \
		clean_dcsconfig \
		clean_dcsmsg

coexe:  	co_imperson_cpp \
		co_dcss \
		co_dhs \
		co_epicsgw \
		co_imgsrv \
		co_autochooch \
		co_impdhs \
		co_blu-ice \
		co_MyAuthServer \
      		co_BluIceWidgets \
      		co_simdhs \
      		co_simdetector

buildexe: 	build_imperson_cpp \
		build_dcss \
		build_dhs \
		build_epicsgw \
		build_imgsrv \
		build_autochooch \
		build_impdhs\
		build_MyAuthServer \
		build_SimDetector

cleanexe: 	clean_imperson_cpp \
		clean_dcss \
		clean_dhs \
		clean_epicsgw \
		clean_imgsrv \
    	clean_autochooch \
		clean_impdhs\
        clean_MyAuthServer \
        clean_simdetector

clean:  	cleanlibs \
		cleanexe

all: buildlibs buildexe
	@echo "..."
	@echo "Successfully built libararies and executables"
	@echo "..."


	

#only put things in 'basic' that can be built easily at other labs/synchrotrons
basic:		buildlibs \
		build_dcss \
		build_dhs \
		build_imgsrv \
		build_MyAuthServer \
		build_SimDetector
	

########################################################
# install targets 
########################################################
# install targets

install: installimperson_cpp installautochooch
	@echo "..."
	@echo "Successfully installed applications"
	@echo "..."

installimperson_cpp:
	@cd ../imperson_cpp && ${MAKE} install

installautochooch:
	@cd ../autochooch && ${MAKE} install



movetobranch_4.2:
	@cd ../xos && cvs update $(CVSTAG)
	@cd ../logging && cvs update $(CVSTAG)
	@cd ../xos_cpp && cvs update $(CVSTAG)
	@cd ../http_cpp && cvs update $(CVSTAG)
	@cd ../auth && cvs update $(CVSTAG)
	@cd ../auth_client && cvs update $(CVSTAG)
	@cd ../jpegsoc && cvs update $(CVSTAG)
	@cd ../cbf && cvs update $(CVSTAG)
	@cd ../diffimage && cvs update $(CVSTAG)
	@cd ../newmat10 && cvs update $(CVSTAG)
	@cd ../xform && cvs update $(CVSTAG)
	@cd ../tcl_clibs && cvs update $(CVSTAG)
	@cd ../dcsconfig && cvs update $(CVSTAG)
	@cd ../dcsmsg && cvs update $(CVSTAG)
	@cd ../dali && cvs update $(CVSTAG)
	@cd ../dcs_tcl_packages && cvs update $(CVSTAG)
	@cd ../java_dcss_sim && cvs update $(CVSTAG)
	@cd ../DcsWidgets && cvs update $(CVSTAG)
	@cd ../imperson_cpp && cvs update $(CVSTAG)
	@cd ../dcss && cvs update $(CVSTAG)
	@cd ../dhs && cvs update $(CVSTAG)
	@cd ../imgsrv && cvs update $(CVSTAG)
	@cd ../autochooch && cvs update $(CVSTAG)
	@cd ../impdhs && cvs update $(CVSTAG)
	@cd ../blu-ice && cvs update $(CVSTAG)
	@cd ../MyAuthServer && cvs update $(CVSTAG)
	@cd ../BluIceWidgets && cvs update $(CVSTAG)
	@cd ../simdhs && cvs update $(CVSTAG)
	@cd ../simdetector && cvs update $(CVSTAG)
	
movetoHEAD:
	@cd ../xos && cvs update -A
	@cd ../logging && cvs update -A
	@cd ../xos_cpp && cvs update -A
	@cd ../http_cpp && cvs update -A
	@cd ../auth && cvs update -A
	@cd ../auth_client && cvs update -A
	@cd ../jpegsoc && cvs update -A
	@cd ../cbf && cvs update -A
	@cd ../diffimage && cvs update -A
	@cd ../newmat10 && cvs update -A
	@cd ../xform && cvs update -A
	@cd ../tcl_clibs && cvs update -A
	@cd ../dcsconfig && cvs update -A
	@cd ../dcsmsg && cvs update -A
	@cd ../dali && cvs update -A
	@cd ../dcs_tcl_packages && cvs update -A
	@cd ../java_dcss_sim && cvs update -A
	@cd ../DcsWidgets && cvs update -A
	@cd ../imperson_cpp && cvs update -A
	@cd ../dcss && cvs update -A
	@cd ../dhs && cvs update -A
	@cd ../imgsrv && cvs update -A
	@cd ../autochooch && cvs update -A
	@cd ../impdhs && cvs update -A
	@cd ../blu-ice && cvs update -A
	@cd ../MyAuthServer && cvs update -A
	@cd ../BluIceWidgets && cvs update -A
	@cd ../simdhs && cvs update -A
	@cd ../simdetector && cvs update -A


