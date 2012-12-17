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

#This function requires that this simulator run in DCS protocol 2.0

set gX 0
 
proc acquireSpectrum {operationHandle startChannel numChannels time } {

#	dcss send_to_server "htos_operation_completed acquireSpectrum $operationHandle error simulator_does_not_support_long_messages_yet"
	
#	return
	global gX


	dcss sendMessage "htos_operation_update acquireSpectrum $operationHandle readyToAcquire"

	after [expr int($time *1000)]

	set spectrumData ""
	for {set x 0} { $x < $numChannels} {incr x} {
		lappend spectrumData [expr $x * 200 + 1000 * rand()]
	}
	
	set deadTimePercent [expr sin( $gX ) ]
	set gx [expr $gX + 0.001]

	dcss sendMessage "htos_operation_completed acquireSpectrum $operationHandle normal $deadTimePercent $spectrumData"
}

 
proc robot_config {operationHandle args } {
	dcss sendMessage "htos_operation_completed robot_config $operationHandle normal $args"
}
proc setDigitalOutput { handle args } {
	dcss sendMessage "htos_operation_completed setDigitalOutput $handle normal $args"
}
proc readAnalog { handle args } {
	dcss sendMessage "htos_operation_completed readAnalog $handle normal 0 0 0 0 0 0 0 0"
}

proc detectorSetThreshold { handle args } {
	dcss sendMessage "htos_operation_completed detectorSetThreshold $handle normal 0 0 0 0 0 0 0 0"
}

proc setDigOutBit { handle args } {
	dcss sendMessage "htos_operation_completed setDigOutBit $handle normal 0 0 0 0 0 0 0 0"
}
