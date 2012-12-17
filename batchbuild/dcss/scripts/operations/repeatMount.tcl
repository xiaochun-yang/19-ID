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


proc repeatMount_initialize {} {
	# global variables 
}

proc repeatMount_start { port num_loop sid } {
    puts "repeatMount: $port $num_loop $sid"
    if {$num_loop < 1} {
        puts "num_loop:$num_loop < 1"
        return -code error "num_loop:$num_loop < 1"
    }

    for {set i 0} {$i < $num_loop} {incr i} {
        set handle [start_waitable_operation get_robotstate]
        set result [wait_for_operation_to_finish $handle]
        set value [lindex $result 1]
        if {$value != 0} {
            log_error check robot status
            return -code error "robot status"
        }
            
        set handle [start_waitable_operation sequenceManual mount $port $sid]
        wait_for_operation_to_finish $handle
        send_operation_update "done [expr $i + 1] of $num_loop"
    }
    set handle [start_waitable_operation sequenceManual mount nN0 $sid]
    wait_for_operation_to_finish $handle
    return done
}
