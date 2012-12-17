#!/bin/csh -f

#source /home/sw/rhel3/ccp4_intel/ccp4-5.0.2/include/ccp4.setup
#source /home/sw/rhel3/labelit_0.988b/labelit_build/setpaths.csh
#set path=(/home/sw/rhel3/mosflm/v6.26b $path)

# Method 1: use module command
# Enable module command
source /home/sw/rhel4/Modules/default/init/tcsh
# Load modules
module load ccp4/6.0.2-1
module load ipmosflm/7.0.1
#module load labelit/1.000nztt

# Method 2: source env.
#source /home/sw/rhel4/ccp4-6.0.2-1/include/ccp4.setup
#source /home/sw/rhel4/labelit/cvs_gcc4/setpaths.csh
source /home/sw/rhel4/labelit/svn/setpaths.csh


set best_path=/home/sw/rhel3/best/best_v3.1
setenv besthome "$best_path"
set raddose_path=/home/sw/rhel3/raddose
set path=($raddose_path $best_path $path)
