#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

proc STRING_initialize {} {
    variable ::nScripts::STRING
	#reset the string to empty on startup
   set STRING [lreplace $STRING 0 1 0 {Dcss was reset}] 
}


proc STRING_configure { args } {

   variable ::nScripts::STRING

   set active  [lindex $args 0] 
   set message [lindex $args 1] 
   set username [lindex $args 2]
   set sessionID [lindex $args 3]
   set directory [lindex $args 4]
   set fileRoot [lindex $args 5]
   set beamSize_x [lindex $args 6]
   set beamSize_y [lindex $args 7]
   set scanWidth [lindex $args 8]
   set scanHeight [lindex $args 9]
   set exposureTime [lindex $args 10]
   set delta [lindex $args 11]
  
   #check and correct for inconsistent definitions 
   if {$beamSize_x > $scanWidth}  {set scanWidth $beamSize_x}
   if {$beamSize_y > $scanHeight}  {set scanHeight $beamSize_y}

   set totalColumns [expr round( $scanWidth / $beamSize_x )]
   set totalRows [expr round($scanHeight / $beamSize_y )]

   set scanWidth [expr $totalColumns * $beamSize_x]
   set scanHeight [expr $totalRows * $beamSize_y]

	#simply return whatever is given us without any error checking
	return "$active \{$message\} $username $sessionID $directory $fileRoot $beamSize_x $beamSize_y $scanWidth $scanHeight $exposureTime $delta $totalColumns $totalRows"
 
}


