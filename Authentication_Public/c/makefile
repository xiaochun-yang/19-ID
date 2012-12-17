################################################################################
#  makefile for jpam
#  author: Greg Luck, David Lutterkort, Seth Theriault
#  version: $Id: makefile,v 1.2 2008/07/21 22:59:39 penjitk Exp $
#
# Instructions
# ============
# 1. You must have the JAVA_HOME environment variable set
# 2. PAM Radius is not standard. Install a PAM Radius client. Change the line /lib/security/pam_radius_auth.so
#    if the PAM Radius module is different.
#
# Dependencies
# ============
# 1. A basic development environment i.e. make, gcc etc.
# 2. For linux systems the PAM development includes. On RedHat and Fedora systems the package is called pam-devel.
#
# Tested Configurations
# =====================
# This makefile is known to work for:
#
# Linux
# -----
# It has been tested on Fedora Core 2 x86 and Fedora Core 3 x86 and x86_64. If you do not have all the modules
# listed below, remove the ones you don't have. Otherwise you will get errors.
#
# Mac OS X
# --------
# It has been tested on Panther v10.3.
# The location of required PAM modules is hardcoded in Mac OS X and do not need to be linked at compile time.
# Note that you need the Mac OS X developer tools, available from http://connect.apple.com to use this makefile.
#
# Adding Custom PAM Modules
# -------------------------
# JPAM has been successfully used with the SecurId and DigiPass hardware token authentication systems.
# As an example, for DigiPass, the Free Radius PAM module must be linked in. Add the following line for an x86 build:
#  -f /lib/security/pam_radius_auth.so \
#
# Note on Editors
# ---------------
# Many Java editors e.g. IntelliJ IDEA, replace tabs with spaces, be default. Tabs are required as separators
# in makefiles.
#
################################################################################

INCLUDE=$(JAVA_HOME)

clean:
	rm -f *.class *.so *.o
	
test: pam_test pam_thread_safety_test

pam_test: pam_test.c
	gcc -fPIC -fexceptions -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux pam_test.c
	gcc -g -fPIC -o pam_test pam_test.o -L.-ljpam -lpam -lpam_misc -lpthread -ldl

pam_authenticate: pam_authenticate.c
	gcc -fPIC -Wall -g -c pam_authenticate.c
	gcc -g -fPIC -o pam_authenticate pam_authenticate.o -L.-ljpam -lpam -lpam_misc -lm -lrt -lpthread -lc -ldl

pam_thread_safety_test: pam_thread_safety_test.c
	gcc -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux pam_thread_safety_test.c
	gcc -g -fPIC -o pam_thread_safety_test pam_thread_safety_test.o -L.-ljpam -lpam -lpam_misc -lpthread -ldl

pam: Pam.c
	gcc -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux Pam.c
	gcc -g -shared -fPIC -o libjpam.so Pam.o -lpam -lpam_misc -ldl

# Linux x86
libjpam.x86: Pam.c
	gcc -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux Pam.c
	gcc -g -shared -fPIC -o libjpam.so Pam.o -lpam -lpam_misc -ldl

# Linux x86_64
libjpam.x86_64: Pam.c
	gcc -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux Pam.c
	gcc -g -shared -fPIC -o libjpam.so Pam.o -lpam -lpam_misc -ldl	    

# Mac OS X
libjpam.mac_os_x: Pam.c
	gcc -fPIC -Wall -g -c -I$(JAVA_HOME)/include Pam.c
	gcc -g -export-dynamic -dynamiclib -Wl -o libjpam.jnilib Pam.o -lpam -lpam_misc -ldl -framework JavaVM

# Solaris
libjpam.solaris: Pam.c
	gcc -DSOLARIS -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/solaris Pam.c
	gcc -DSOLARIS -g --export-dynamic -shared -Wl -o libjpam.so Pam.o -lpam  -ldl

# HP-UX
libjpam.hp-ux: Pam.c
	gcc -DHPUX -fPIC -Wall -g -c -I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/hp-ux Pam.c
	gcc -DHPUX -g --export-dynamic -shared -Wl -o libjpam.so Pam.o -lpam
