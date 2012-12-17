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

package provide DCSFifo 1.0


##########################################################################
# The class Set defines an object that contains a set of unique objects.
# Objects may be added or removed and adding an object that already exists
# in the set does nothing.  The get method returns the whole set as a
# list and the clear method removes all objects from the set. 
##########################################################################

class ::DCS::Fifo {

	# public methods
	public method constructor {} {}

	# private data
	private variable _fifo [list]
    
    public method size {} {
        return [llength $_fifo]
    }

    public method clear {} {
	    set _fifo [list]
    }


    public method put { item } {
		lappend _fifo $item
    }

    public method putAll { itemList } {
		eval lappend _fifo $itemList
    }

    public method get { } {
        set head [lindex $_fifo 0]
        set _fifo [lrange $_fifo 1 end]
        return $head
    }
    public method peak { } {
        return [lindex $_fifo 0]
    }

    public method isEmpty {} {
        return [expr ([llength $_fifo] == 0)]
    }
}

