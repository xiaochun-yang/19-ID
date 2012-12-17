#!/bin/csh -f

source /home/sw/rhel3/ccp4_intel/ccp4-6.0/include/ccp4.setup
source /home/sw/rhel3/labelit_1.000a2/labelit_build/setpaths.csh
set best_path=/home/sw/rhel3/best/best_v2.0
setenv besthome "$best_path"
set raddose_path=/home/sw/rhel3/raddose
set path=(/home/sw/rhel3/mosflm/v6.26 $raddose_path $best_path $path)
