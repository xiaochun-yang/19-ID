autochooch
==========

1. Installation

1.1 Check out autochooch from cvs
1.2 Run gmake to build the FORTRAN programs including Chooch_auto, Benny_auto and Wasel.
1.3 Edit makefile and change the INSTALL_DIR variable to the location where 
    autochooch bin and data will be installed.
1.4 Run gmake install to install the executables, scripts will be installed in 
    ${INSTALL_DIR}/bin and data files in ${INSTALL_DIR}/data. 

For example:

> cd /data/joeuser/code
> cvs co autochooch
> cd autochooch
> vi makefile ==> Change INSTALL_DIR to /data/joeuser/autochooch/install
> gmake install

Note that optimization flags for g77 compiler must be turned off when building 
on linux as the executables will produce incorrect results.


2. Running autochooch manually on a beamline computer

2.1  Log on to a computer at a beamline where the scan data was collected.
2.2 Set CHOOCHBIN and CHOOCHDAT env variables to ${INSTALL_DIR}/bin and 
    ${INSTALL_DIR}/dat, respectively. Using the above example:

> setenv CHOOCHBIN /data/joeuser/autochooch/install/bin
> setenv CHOOCHDAT /data/joeuser/autochooch/install/data

2.3 Run autochooch from any directory. The command is as follows:

    ${CHOOCHBIN}/autochooch <scanfile> <atom> <edge>
    
    where
    scanfile: Scan file containing scan datapoints in bip format
    atom: 2-letter atom code
    edge: absorption edge

    For example, at beamline 9-2:

> ssh bl92a
> cd /data/joeuser
> /data/joeuser/autochooch/install/bin/autochooch /data/joeuser/scan.bip Se K

The autochooch script will use beamline parameters from ${CHOOCHDAT}/<beamline>.par
file. Output files will be written into /tmp/<user> directory, for example, in /tmp/joeuser.



3. Running autochooch manually on a NON beamline computer



4. Running autochooch from impdhs

impdhs runs chooch_remote1.sh and chooch_remote2.sh scripts instead of autochooch script.
The two scripts are esssentially the first and second parts of autochooch. The input
scan file is in the native Chooch_auto format. CHOOCHBIN and CHOOCHDAT env are set by impdhs 
using the values from dcsconfig/data/<beamline>.config file.

5. Scripts

These files can be found in ${CHOOCHBIN} directory or /autochooch/src.

autochooch: Shell script that runs Bennny_auto, Chooch_auto and wasel_auto. Can be run from command
prompt.

Chooch_auto.sh: Shell script used by autochooch script. It runs Chooch_auto FORTRAN program 
and Wasel_auto shell script.

Wasel_auto: Shell script used by Chooch_auto.sh script. It determines beamline name 
from the computer it runs on using 'uname -n' command and picks an appropriate beamline
parameter file (/data/<beamline>.par) and runs wasel FORTRAN program.

chooch_remote.sh: Shell script that runs Benny_auto, Chooch_auto and Wasel. Same as autochooch script
exception for the format of the input scan file. Can be used by impdhs only (although it is 
not used currently).

chooch_remote1.sh: Shell script that runs Benny_auto. This is the first part of chooch_remote.sh 
that only generates the smooth curves from the scan datapoints. Used by impdhs only.

chooch_remote2.sh: Shell script that runs Chooch_auto and wasel. This is the second part
of chooch_remote.sh. It uses the smooth genereated smooth curves and calculates fp, fpp for
peak, inflection and remote energies. Used by impdhs only.



6. Executables

These files can be found in ${CHOOCHBIN} or autochooch/<machine>, e.g. autochooch/linux.

Benny_auto: FORTRAN program that generates smooth curves from scan datapoints
Chooch_auto: FORTRAN program that calculates fp and fpp for peak and remote energies.
wasel: FORTRAN program that calculates fp and fpp for remote energies.

7. Data files 

These files can be found in ${CHOOCHDAT} or autochooch/data. They are used by the scripts
and executables

atom.lib: 

*.par: Beamline parameter files used by wasel program. File name must be beamline name 
as used in the DCS system. If ${CHOOCHDAT}/<beamline>.par file can not be found the 
script will use ${CHOOCHDAT}/beamline.par by default.


*.dat: Atom data files. 


