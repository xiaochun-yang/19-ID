#!/bin/csh

echo -n "Username: "
set userName = $<
echo -n "Password: "
stty -echo
set password = $<
stty echo
echo " "

set curDir = `pwd`
setenv LD_LIBRARY_PATH $curDir

./pam_test $userName $password
