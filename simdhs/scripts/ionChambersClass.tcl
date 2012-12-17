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


package require DCSSet

DCS::Set registeredIonChamberList


class simulatedIonChambers {
	private variable ionChamberList
	private variable dummyCount
	public method simulateValues { time args}
	public method add { ionChamberName }
	public method readIonChambers { time args }
	public method constructor { args }
}


body simulatedIonChambers::constructor { args } {
	eval $this configure [concat $args]
	set dummyCount 1000
}

body simulatedIonChambers::add { ionChamberName } {
	append ionChamberList $ionChamberName
}

body simulatedIonChambers::readIonChambers { time args } {
	#foreach ionChamber $args {
	# check if ion chamber is associated with this time
	#}
	puts $args
	
	after [expr int($time * 1000)] "$this simulateValues $time $args"
}

body simulatedIonChambers::simulateValues { time args } {
	#set dummyCount 1000
	set response ""
	puts $args

	# get number of arguments
	set argc [llength $args ]
	puts $argc
	# initialize argument index
	set index 0
	while { $index < $argc } {

	#	set ion_chamber [lindex $args $index]

		append response " [lindex $args $index] [expr sin($dummyCount*3.14158/360)*1000 + 3000 ]"
		incr dummyCount 2
		incr index
		puts $dummyCount
		puts $response
	}

	dcss sendMessage "htos_report_ion_chambers $time $response"
}
