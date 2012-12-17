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

#
# sequenceGetConfig.tcl
#
# scripted operation
# calls methods of the class SequenceDevice (SequenceDevice.tcl)
#
# gtos_start_operation sequenceGetConfig methodName args
#
# database.dat definition:
# sequenceGetConfig
# 11
# self sequenceGetConfig 0
#
# Note, this operation is defined as operation.masterOnly = 0,
# i.e. it can also be called in passive mode
#
# methodName:
# getConfig
#

# 

# =======================================================================

proc sequenceGetConfig_initialize {} {
	# global

puts "sequenceGetConfig_initialize"
}

# =======================================================================

proc sequenceGetConfig_start { methodName args} {
	# global variables 
	global gOperation

puts "==========="
puts "==========="
puts "OPERATION sequenceGetConfig_start methodName=$methodName args=$args"
	if { [catch "set result [list [eval $gOperation(sequence,sequenceDevice) getConfig $args]]" error] } {
		log_error $error
		return "ERROR sequenceGetConfig_start: $error"
	}
   
	return $result
}

# =======================================================================
