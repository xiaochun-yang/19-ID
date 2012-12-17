#!/bin/csh -f
#################################
#
# Chooch cshell script excecuting
# Benny and Chooch.
#
# Gwyndaf Evans 
# last update 29 October 1999
#
##############################################################
#
#  Usage:
#
#  Chooch_auto.sh <element> <edge> <filenameroot>
#
#  element      - two letter atomic symbol (case insensitive)
#  edge         - absorption edge ( K | L1 | L2 | L3 | M )
#  filenameroot - trunk of raw data file e.g. for a raw data
#                 file called SeMet.raw use SeMet
#
#
##############################################################
#


echo $1  > atomname
echo $2 >> atomname
ln -s ${CHOOCHDAT}/atom.lib atomdata
if (-e $3.raw) then 
cp $3.raw rawdata
else 
echo " ERROR: No raw data file found"
exit
endif
${CHOOCHBIN}/Benny_auto  
echo " CHOOCH_STATUS: Chooch transform data "
${CHOOCHBIN}/Chooch_auto
mv anomfacs $3.efs
mv valuesfile $3.inf
# The next line is a program to calculate the remote
# wavelength based on the beam line characteristics and the scans 
${CHOOCHBIN}/wasel_auto  $1.dat $3.efs
/bin/rm -f splinor splinor_raw atomdata atomname rawdata
exit
#
#
#

