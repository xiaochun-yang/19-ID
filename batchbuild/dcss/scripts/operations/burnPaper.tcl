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

#######################################
#CONFIG is via string: burn_paper_const

##################################
# temperary data are saved in string burn_paper_data
#################################################3

proc burnPaper_initialize {} {
    variable burn_paper_constant_name_list

    set burn_paper_constant_name_list [list \
    exposure_time \
    step_ratio \
    cut_cryo_time \
    ]
}

proc burnPaper_start { args } {
    global gMotorBeamWidth

    variable $gMotorBeamWidth
    variable gonio_phi
    variable sample_z

    set orig_gonio_phi $gonio_phi
    set orig_sample_z $sample_z

    set exposure_time [get_burn_paper_constant exposure_time]
    set step_ratio    [get_burn_paper_constant step_ratio]
    set cut_cryo_time [get_burn_paper_constant cut_cryo_time]

    set step_size [expr [set $gMotorBeamWidth] * $step_ratio]
    set exposure_ms [expr int(1000.0 * $exposure_time)]

    set result "normal"
    if {[catch {
        send_operation_update "move phi by -90"
        move gonio_phi by -90
        wait_for_devices gonio_phi

        send_operation_update "exposure for $exposure_time seconds"
        open_shutter shutter
        wait_for_time $exposure_ms
        close_shutter shutter

        send_operation_update "rotate phi to +90 and move 1 step"
        move gonio_phi by 180
        move sample_z by $step_size
        wait_for_devices gonio_phi sample_z

        send_operation_update "exposure again for $exposure_time seconds"
        open_shutter shutter
        wait_for_time $exposure_ms
        close_shutter shutter

        send_operation_update "turn to original phi"
        move gonio_phi to $orig_gonio_phi

        if {$cut_cryo_time > 0} {
            send_operation_update "turn off cryojet for $cut_cryo_time seconds"
            set handle \
            [start_waitable_operation cryojet_anneal $cut_cryo_time]
            wait_for_operation_to_finish $handle
        }
    } errMsg]} {
        set result $errMsg
        log_warning "burn paper failed: $errMsg"
    }
    return $result
}

proc get_burn_paper_constant { name } {
    variable burn_paper_constant

    set index [BPaperConstantNameToIndex $name]
    return [lindex $burn_paper_constant $index]
}
proc BPaperConstantNameToIndex { name } {
    variable burn_paper_constant
    variable burn_paper_constant_name_list

    if {![info exists burn_paper_constant]} {
        return -code error "string not exists: burn_paper_constant"
    }

    set index [lsearch -exact $burn_paper_constant_name_list $name]
    if {$index < 0} {
        return -code error "bad name: $name"
    }

    if {[llength $burn_paper_constant] <= $index} {
        return -code error "bad contents of string burn_paper_constant"
    }
    return $index
}
