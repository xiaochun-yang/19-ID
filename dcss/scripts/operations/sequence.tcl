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
# sequence.tcl
#
# scripted operation
# calls methods of the class SequenceDevice (SequenceDevice.tcl)
#
# gtos_start_operation sequence methodName args
#
# database.dat definition:
# sequence
# 11
# self sequence 1
#
# methodName:
# setConfig
#

package require Itcl

# =======================================================================

proc sequence_initialize {} {
	# global variables 

puts "sequence_initialize"
	
	sequence_create_SequenceDevice 

puts "sequence_initialize OK"
return
}

# =======================================================================

proc sequence_start { args} {
	# global variables 
	global gOperation

puts "==========="
puts "==========="
puts "OPERATION sequence_start args=$args"
	if { [catch "set result [list [eval $gOperation(sequence,sequenceDevice) operation $args]]" error] } {
		puts "xyang error=$error"
		log_error $error
		return -code error "ERROR sequence_start $error"
	}
  puts "xyang result=$result" 
	return $result
}

# =======================================================================

proc sequence_create_SequenceDevice {} {
	# global variables 
	global OPERATION_DIR
	global gOperation

# delete old object if needed
if { [info exists gOperation(sequence,sequenceDevice)] } {
	if { [catch "::itcl::delete object gOperation(sequence,sequenceDevice)" error] } {
		log_error $error
		return "ERROR"
	}
}
	
	# read the operation script
	puts $OPERATION_DIR/SequenceDevice.tcl
	if { [catch "namespace eval :: source $OPERATION_DIR/SequenceDevice.tcl" error] } {
		log_error $error
		return "ERROR"
	}

	# execute the initialization script
	if { [catch "set obj [list [namespace eval :: create_sequenceDevice sequenceDevice]]" error] } {
		log_error $error
		return "ERROR"
	}

	set gOperation(sequence,sequenceDevice) $obj
	puts "gOperation(sequence,sequenceDevice)= $gOperation(sequence,sequenceDevice)"

return $obj
}

# =======================================================================
