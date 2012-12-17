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
   set scanMotor [lindex $args 4]
   set directory [lindex $args 5]
   set fileRoot [lindex $args 6]
   set startPos [lindex $args 7]
   set scanRange [lindex $args 8]
   set scanStep [lindex $args 9]
   set timeInterval [lindex $args 10]
   set numSets [lindex $args 11]
   set exposureTime [lindex $args 12]
   set numImages [lindex $args 13]
 
	#simply return whatever is given us without any error checking
   return "$active \{$message\} $username $sessionID $scanMotor $directory $fileRoot $startPos $scanRange $scanStep $timeInterval $numSets $exposureTime $numImages"
 
}


