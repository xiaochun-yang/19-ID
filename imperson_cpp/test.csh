#!/bin/csh -f

############################################################
#
#
# Usage:
#	monitorBeamline.csh <beamline>
#
############################################################

setenv SCRIPT_DIR `dirname $0`

if ($#argv != 4) then
	echo `date`"Usage: test.csh <auth host> <auth port> <imp host> <imp port>"
	exit 0
endif

set authHost = $1
set authPort = $2

set impHost = $3
set impPort = $4

echo "..."
echo "..."
echo "Testing impersonation daemon on ${impHost}:${impPort}"


# Get user id from env variable and get session id
# from bluice cache.
set user = $USER
set sessionFile = "$HOME/.bluice/session"
set sessionId = ""
if (-e $sessionFile) then
set sessionId = `cat $sessionFile`
#set sessionId = 5F3BF4D1FB86BBFFB391732DD7392240
endif

set OS = `uname`
switch ($OS)
case OSF1:
    set MACHINE = "decunix"
    breaksw
case IRIX64:
    set MACHINE = "irix"
    breaksw
case Linux:
    switch (`uname -m`)
    case i686:
        set MACHINE = "linux"
        breaksw
    case x86_64:
        set MACHINE = "linux64"
        breaksw
    case ia64:
        set MACHINE = "ia64"
        breaksw
    endsw
    breaksw
default:
    echo "ERROR: unsupported OS: $OS"
    exit 0
    breaksw
endsw

############################################################
# Validate session id of current user
############################################################

set authStatus = 1

set isValid = "0"
if ($sessionId != "") then
echo "..."

$SCRIPT_DIR/../auth_client/${MACHINE}/test $authHost $authPort validateSession $sessionId $USER

set isValid = `$SCRIPT_DIR/../auth_client/${MACHINE}/test $authHost $authPort validateSession $sessionId | awk 'BEGIN{valid = 0;} /sessionValid = 1/{ valid = 1; } /Auth.SessionValid=TRUE/{ valid = 1; } END { print valid; }'`
endif

echo "Session id for user $USER in $sessionFile is still valid"
./${MACHINE}/test $impHost $impPort $USER $sessionId no

