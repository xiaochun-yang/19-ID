#!/bin/csh -f

set workDir = `pwd`

setenv WEBICE_SCRIPT_DIR `dirname $0`
set WEBICE_CLASS_DIR = $WEBICE_SCRIPT_DIR/../classes
cd $WEBICE_CLASS_DIR
set WEBICE_CLASS_DIR = `pwd`

cd $workDir

if (-e jobs.csh) then
rm -rf jobs.csh
endif

echo "#\!/bin/csh -f" > jobs.csh
echo "set WEBICE_CLASS_DIR=$WEBICE_CLASS_DIR" >> jobs.csh
awk -f $WEBICE_SCRIPT_DIR/list_jobs.awk $1 >> jobs.csh
chmod oug+rx jobs.csh


