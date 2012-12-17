#!/bin/csh -f

set curDir = `pwd`

cd ../..

set newDir = `pwd`

set installName = `basename $newDir`

cd $curDir

echo "webice.installName=$installName"



