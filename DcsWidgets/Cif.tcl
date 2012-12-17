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

package provide DCSCif 1.0

package require Itcl


class DCS::CifFile {

	constructor {} {}

	# public member functions
	public method setDefaults { args }
	public method read { fileName }
	public method write { fileName }
	public method getValue { block keyword {instance 1} }
	public method getValueCount { block keyword }
	public method getBlockCount {}

	# private member functions
	private method getNextLine {}

	# private data
	private variable fileHandle
	private variable defaultValue
	private variable value
	private variable valueCount
	private variable blockCount
}


body DCS::CifFile::getBlockCount {} {
	
	return $blockCount
}


body DCS::CifFile::setDefaults { args } {

	# clear previous defaults
	catch {unset defaultValue}

	# assign values to keywords in pairs
	foreach { inputKey inputVal } $args {
		set defaultValue($inputKey) $inputVal
	}
}


body DCS::CifFile::getValue { block keyword {instance 1} } {

	if { [info exists value($block,$keyword,$instance)] } {
		return $value($block,$keyword,$instance)
	} else {
		return $defaultValue($keyword)
	}
}


body DCS::CifFile::getValueCount { block keyword } {

	if { [info exists valueCount($block,$keyword)] } {
		return $valueCount($block,$keyword)
	} else {
		return 0
	}
}


body DCS::CifFile::read { fileName } {

	# initialize values and value counts
	catch {unset value}
	catch {unset valueCount}

	# open the file for reading 
	set fileHandle [open $fileName r]

	# initialize state machine
	set blockCount 0
	set loopState outside
	set loopKeywordList {}

	# keep reading until end of file
	while { [set line [getNextLine]] != "" } {

		# extract first token on line
		set token0 [lindex $line 0]

		# handle start of new data block
		if { [string range $token0 0 4] == "data_" } {

			# increment the data block index
			incr blockCount
			
			# inidicate that outside of loop
			set loopState outside

			# get next line of file
			continue
		}

		# handle start of new loop definition block
		if { [string range $token0 0 4] == "loop_" } {

			# indicate that inside of loop definition
			set loopState definition

			# initialize loop keyword list
			set loopKeywordList {}

			# get next line of file
			continue
		}

		# handle cases where first token is a keyword
		if { [string range $token0 0 0] == "_" } {

			# add keyword to loop definition if inside loop definition
			if { $loopState == "definition" } {

				lappend loopKeywordList $token0

			} else {

				# otherwise store the value of the block-global datum
				set value($blockCount,$token0,1) [lindex $line 1]

				# count each value associated with a keyword
				set valueCount($blockCount,$token0) 1
			}

			# get next line of file
			continue
		}

		# if previously in loop definition then now in loop body
		if { $loopState == "definition" } {
			set loopState inside
			set loopLineCount 0
		}
		
		# read data into loop variables if in loop
		if { $loopState == "inside" } {
			
			# keep track of number of lines
			incr loopLineCount

			# loop over loop keywords and data
			foreach keyword $loopKeywordList dataValue $line {

				#puts "$keyword: $dataValue"

				# store the value in the data value array
				set value($blockCount,$keyword,$loopLineCount) $dataValue
				
				# count each value associated with a keyword
				set valueCount($blockCount,$keyword) $loopLineCount
			}
		}
	}

	# close the file
	close $fileHandle
}




body DCS::CifFile::getNextLine {} {

	while { 1 } {
		
		# return null string if end of file reached
		if [ eof $fileHandle ] {
			return {}
		}
		
		# read the next line from the file
		gets $fileHandle lineBuffer
		
		# remove any comments
#		set commentIndex [string first "\#" $lineBuffer]
#		if { $commentIndex != -1 } {
#			set lineBuffer [string range $lineBuffer 0 [expr $commentIndex - 1]]
#		}

		if { [string range $lineBuffer 0 0] == "\#" } {
			set lineBuffer {}
		}
		
		# return line buffer if any non-white space found
		if { [llength $lineBuffer] != 0 } {
			return $lineBuffer
		}
	}
}


