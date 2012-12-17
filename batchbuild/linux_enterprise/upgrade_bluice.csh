#!/bin/csh -f

set SCRIPT_DIR = `pwd`
set DCS_DIR = "/usr/local/dcs"

echo "script dir = $SCRIPT_DIR"
echo "dcs dir = $DCS_DIR"

set tclsh_expected = "8.4"
set Itcl_expected = "3.3"
set BWidget_expected = "1.7"
set BLT_expected = "2.4"
set Img_expected = "1.3"
set Iwidgets_expected = "4.0.1"

# tclsh version
set str = `${SCRIPT_DIR}/get_tcl_version.sh`
echo "$str"
set tclsh_version = $str[2]
# Itcl version
set str = `${SCRIPT_DIR}/tcl_env.sh Itcl`
echo "$str"
set Itcl_version = $str[2]
# BWidget version
set str = `${SCRIPT_DIR}/tcl_env.sh BWidget`
echo "$str"
set BWidget_version = $str[2]
# BLT version
set str = `${SCRIPT_DIR}/tcl_env.sh BLT`
echo "$str"
set BLT_version = $str[2]
# Img version
set str = `${SCRIPT_DIR}/tcl_env.sh Img`
echo "$str"
set Img_version = $str[2]
# Iwidgets version
set str = `${SCRIPT_DIR}/tcl_env.sh Iwidgets`
echo "$str"
set Iwidgets_version = $str[2]

if ($tclsh_version != $tclsh_expected) then
echo "Got tclsh version $tclsh_version while expecting version $tclsh_expected"
exit
endif
if ($Itcl_version != $Itcl_expected) then
echo "Got Itcl version $Itcl_versiob while expecting version $Itcl_expected"  
exit
endif
if ($BWidget_version != $BWidget_expected) then
echo "Got BWidget version $BWidget_versiob while expecting version $BWidget_expected"  
exit
endif
if ($BLT_version != $BLT_expected) then
echo "Got BLT version $BLT_versiob while expecting version $BLT_expected"  
exit
endif
if ($Img_version != $Img_expected) then
echo "Got Img version $Img_version while expecting version $Img_expected"  
exit
endif
if ($Iwidgets_version != $Iwidgets_expected) then
echo "Got Iwidgets version $Iwidgets_version while expecting version $Iwidgets_expected"  
exit
endif


echo "Done"

# Return to the script dir
cd ${SCRIPT_DIR}


chmod +x ${DCS_DIR}/BluIceWidgets/bluice.tcl

