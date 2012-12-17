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


proc create_new_set { setName } {

	# access variable
	upvar $setName localSet
	
	# create an empty set
	set localSet {}
}


proc add_to_set { setName member } {
	
	# access variable
	upvar $setName localSet
	
	# create new set if needed
	if { ![info exists localSet] } {
		create_new_set localSet
	}
	
	# add member to set if not already there
	if { ! [is_in_set localSet $member] }  {
			lappend localSet $member
	}
}


proc remove_from_set { setName member } {

	# access variable
	upvar $setName localSet
		
	# find member in set
	set index [lsearch $localSet $member]
	
	# do nothing else if not found
	if { $index == -1 } {
		return
	}
	
	# delete the member from the set
	set localSet [lreplace $localSet $index $index]
}


proc is_in_set { setName member } {
	
	# access variable
	upvar $setName localSet
	
	# return false if can't find member, true otherwise
	if { [lsearch $localSet $member] == -1 } {
		return 0
	} else {
		return 1
	}
}


proc get_set { setName } {
	
	# access variable
	upvar $setName localSet
	
	return $localSet
}

