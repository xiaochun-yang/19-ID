#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}

set pp [lindex $argv 0]
package require $pp
puts "$pp [package require $pp]"
exit
