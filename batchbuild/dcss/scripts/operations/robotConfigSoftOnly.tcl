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

proc robotConfigSoftOnly_initialize {} {
}

# =======================================================================

proc robotConfigSoftOnly_start { args } {
    set subCmd [lindex $args 0]

    switch -exact -- $subCmd {
        bypass_check -
        set_index_state -
        set_port_state -
        clear_force -
        clear -
        clear_status -
        clear_all -
        set_desired_ln2_level -
        set_check_filling -
        shutdown -
        reboot -
        get_meminfo -
        reset_permanent_counter -
        reset_mounted_counter -
        reset_stripped_counter - 
        reset_cassette -
        set_flags -
        clear_mounted -
        set_mounted -
        restore_cassette -
        set_cassette_state -
        set_picker {
        }
        default {
            log_error not allowed through the software only interface
            return -code error "not allowed"
        }
    }
    if {$subCmd != "bypass_check"} {
        set handle [eval start_waitable_operation robot_config $args]
    } else {
        set newArgs [lrange $args 1 end]
        set handle [eval start_waitable_operation robot_config $newArgs]
    }
    wait_for_operation_to_finish $handle
}

# =======================================================================
