#!/bin/csh -f

echo "TCLLIBPATH=$TCLLIBPATH"

./get_tcl_version.sh

./tcl_env.sh Itcl
./tcl_env.sh BWidget
./tcl_env.sh BLT
./tcl_env.sh Img
./tcl_env.sh Iwidgets
./tcl_env.sh tls
./tcl_env.sh mime


