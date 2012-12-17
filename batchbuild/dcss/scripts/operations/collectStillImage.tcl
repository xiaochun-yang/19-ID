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


proc collectStillImage_initialize {} {
	# global variables 
}

proc collectStillImage_start { filename fileroot directory detectorMode} {
	# global variables 
	variable detector_z
	variable gonio_phi
	variable energy
	variable detector_horz
	variable detector_vert

	set operationHandle [start_waitable_operation detector_collect_image 1 $filename $fileroot $directory scottm \
									 [set gonio_phi] 2 0 1 \
									 [set detector_z] [set energy] \
									 [set detector_horz] [set detector_vert] \
									 $detectorMode]

	set status "update"
	
	while { $status == "update" } {
		puts "********************************"
		set result [wait_for_operation $operationHandle]
		puts "***************** $result"
		set status [lindex $result 0]
		set result [lindex $result 1]
		if { $status == "update" } {
			set request [lindex $result 0]
			puts $request
			if { $request == "start_oscillation" } {
				if { [catch {start_operation detector_transfer_image} errorResult] } {
					#we have probably been aborted.
					start_recovery_operation detector_stop
					return -code error
				}
			}
			if { $request == "prepare_for_oscillation" } {
				if { [catch {start_operation detector_oscillation_ready} errorResult] } {
					#we have probably been aborted
					start_recovery_operation detector_stop
					return -code error
				}
			}

			puts $status
		}
	}

	start_operation detector_stop

   return $filename
}
