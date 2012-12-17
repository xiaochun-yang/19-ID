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

package provide DCSSet 1.1


##########################################################################
# The class Set defines an object that contains a set of unique objects.
# Objects may be added or removed and adding an object that already exists
# in the set does nothing.  The get method returns the whole set as a
# list and the clear method removes all objects from the set. 
##########################################################################

class ::DCS::Set {

	# public methods
	public method constructor {} {}
	public method add { member }
	public method remove { member }
	public method get {}
	public method clear {}
	public method isMember { member }
	public method size { }

	# private data
	private variable memberList {}
}

body ::DCS::Set::size {} {
    return [llength $memberList]
}

body ::DCS::Set::clear {} {

	# set the list of current members to the null set
	set memberList {}
}


body ::DCS::Set::isMember { member } {

	# return TRUE iff member is in the list of current members
	expr [lsearch $memberList $member] != -1
}



body ::DCS::Set::add { args } {

	# loop over each potential new member in the argument list
	foreach member $args {
		
		# append current member list with the new member if not in list already
		if { ! [isMember $member] } {
			lappend memberList $member
		}
	}
}


body ::DCS::Set::remove { args } {

	# loop over each member to be removed in argument list
	foreach member $args {
		
		# find the member in the list of current members
		set index [lsearch $memberList $member]
		
		# remove it from the list if it was found in the list of current members
		if  { $index != -1 } {
			set memberList [lreplace $memberList $index $index] 
		}
	}
}


body ::DCS::Set::get {} {
	
	# return the list of current members
	return $memberList
}


##########################################################################
# The class Bag defines an object that contains a set of counted objects.
# Objects may be added or removed.  The same object may be added to the Bag
# any number of times--the Bag keeps a count.  To remove an object from a
# Bag, the remove operation must be called as many times as the add operation
# was called for that object.  The get method returns the list of unique 
# members and the clear method removes all objects from the set. 
##########################################################################


class ::DCS::Bag {
	
	# public methods
	public method constructor {} {}

	public method add { member }
	public method remove { member }
	public method get {}
	public method clear {}
	public method isMember { member }

	# private data
	private variable memberArray
}


body ::DCS::Bag::clear {} {

	# delete all members of the member array
	unset memberArray
}


body ::DCS::Bag::isMember { member } {

	# search for the member in the list of current members
	expr [lsearch [get] $member] != -1
}


body ::DCS::Bag::add { args } {
	
	# keep track of completely new members added
	set newMembers {}

	# loop over each potential new member in the argument list
	foreach member $args {
		
		# increment the array value for the member if it already exists
		if { [isMember $member] } {
			incr memberArray($member)
		} {
			# otherwise create the array member and initialize it to 1
			set memberArray($member) 1

			# keep track of completely new members added
			lappend newMembers $member
		}
	}

	# return the new list of unique member names
	return $newMembers
}


body ::DCS::Bag::remove { args } {

	# keep track of members completely removed
	set oldMembers {}

	# loop over each member to be removed in argument list
	foreach member $args {
		
		if { [isMember $member] } {
			incr memberArray($member) -1
			
			if { $memberArray($member) < 1 } {
				unset memberArray($member)

			# keep track of members completely removed
			lappend oldMembers $member				
			}
		}
	}
		
	# return the new list of unique member names
	return $oldMembers
}


body ::DCS::Bag::get {} {
	
	# return the null set if no members in the array
	if { ! [info exists memberArray] } {
		return {}
	} else {
		# otherwise return the list of unique member names
		return [array names memberArray]
	}
}



