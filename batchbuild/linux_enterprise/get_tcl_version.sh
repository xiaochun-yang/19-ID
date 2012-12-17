#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}

puts "tcl [info tclversion]"
exit
