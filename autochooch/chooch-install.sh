#!/bin/csh -f
#########################
# Chooch.sh
# by Gwyndaf Evans 
#     29 October 1999
#
#########################
# Check architecture
#
setenv RASLEBOL `uname -s`
if ( $RASLEBOL == "OSF1" ) then
        setenv ARCH alpha
endif
if ( $RASLEBOL == "IRIX" ) then
        setenv ARCH irix
        set path = ( $path /usr/bsd )
endif
if ( $RASLEBOL == "IRIX64" ) then
        setenv ARCH irix64
        set path = ( $path /usr/bsd )
endif
if ( $RASLEBOL == "Linux" ) then
        setenv ARCH linux
        set path = ( $path /usr/bsd )
endif
#
cd src
/bin/rm Makefile
ln -s Makefile.$ARCH Makefile
make benny
make chooch
make install
make clean
cd ../
#
exit

