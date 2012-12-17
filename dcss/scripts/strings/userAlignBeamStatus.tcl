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
}


### now enable1 means Tungsten only
###     enable2 means Tungsten+Collimator
###    They are mutual-exclusive.
###    They can be both disabled.

proc STRING_configure { args } {
    variable ::nScripts::STRING

    foreach {enable1 enable2 span1 span2 ts1 ts2} $STRING break
    foreach {newE1   newE2   newS1 newS2 } $args break

    set newContents $args

    set anyChange 0
    set tsNow [clock seconds]
    if {$newE1 != $enable1 || $span1 != $newS1} {
        set tsTriger [expr $tsNow + $newS1]
        set newContents [lreplace $newContents 4 4 $tsTriger]
        incr anyChange
    }
    if {$newE2 != $enable2 || $span2 != $newS2} {
        set tsTriger [expr $tsNow + $newS2]
        set newContents [lreplace $newContents 5 5 $tsTriger]
        incr anyChange
    }

    if {$newE1 != $enable1 && $newE1} {
        set newContents [lreplace $newContents 1 1 0]
        set newE2 0
        incr anyChange
    
    }
    if {$newE2 != $enable2 && $newE2} {
        set newContents [lreplace $newContents 0 0 0]
        set newE1 0
        incr anyChange
    
    }

    if {$newE1 && $newE2} {
        set newContents [lreplace $newContents 0 0 0]
        log_warning must align beam to phi before align collimator
        incr anyChange
    }
    if {$anyChange} {
        return $newContents
    }

	return $args
}

