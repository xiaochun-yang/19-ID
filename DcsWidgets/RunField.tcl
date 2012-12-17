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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################

package provide DCSRunField 1.0

# load standard packages
#package require Itcl 3.2
#namespace import ::itcl::*

class ::DCS::RunField {
    public proc nameToIndex { name } {
        set index [lsearch $NAME_LIST $name]
        if {$index < 0} {
            return -code error "bad field name for run: $name"
        }
        return $index
    }
    public proc getField { runRef name } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error \
            "run definition too short for $name ll=$ll index=$index"
        }
        return [lindex $contents $index]
    }
    public proc setField { runRef name value } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error "run definition too short"
        }
        ##### checking
        if {$name == "file_root"} {
            set newValue [TrimStringForCrystalID $value]
            if {$newValue != $value} {
                log_error file_root adjusted from $value to $newValue
                set value $newValue
            }
        }
        if {$name == "directory"} {
            set newValue [TrimStringForRootDirectoryName $value]
            if {$newValue != $value} {
                log_warning directory $value changed to $newValue
                set value $newValue
            }
        }

        set contents [lreplace $contents $index $index $value]
    }
    public proc getList { runRef args } {
        upvar $runRef contents
        set ll [llength $contents]
        set valueList ""

        foreach name $args {
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            lappend valueList [lindex $contents $index]
        }
        return $valueList
    }
    public proc setList { runRef args } {
        upvar $runRef contents
        set ll [llength $args]
        if {$ll ==0} return
        if {$ll % 2} {
            return -code error "wrong name_value_pair_list"
        }
        set ll [llength $contents]
        set new_contents $contents
        foreach {name value} $args {
            if {$name == "file_root"} {
                set newValue [TrimStringForCrystalID $value]
                if {$newValue != $value} {
                    log_error file_root adjusted from $value to $newValue
                    set value $newValue
                }
            }
            if {$name == "directory"} {
                set newValue [TrimStringForRootDirectoryName $value]
                if {$newValue != $value} {
                    log_warning directory $value changed to $newValue
                    set value $newValue
                }
            }
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            set new_contents [lreplace $new_contents $index $index $value]
        }
        ##### single change of the list
        set contents $new_contents
    }

    public proc getNumField { } {
        return [llength $NAME_LIST]
    }

    #### must match with DEFAULT
    public common NAME_LIST [list \
        status \
        next_frame \
        run_label \
        file_root \
        directory \
        start_frame \
        axis_motor \
        start_angle \
        end_angle \
        delta \
        wedge_size \
        exposure_time \
        distance \
        beam_stop \
        attenuation \
        num_energy \
        energy1 \
        energy2 \
        energy3 \
        energy4 \
        energy5 \
        detector_mode \
        inverse_on \
    ]
    #### must match with NAME_LIST
    public common DEFAULT [list \
        inactive \
        0 \
        0 \
        test0 \
        /data/ \
        1 \
        Phi \
        1.00 \
        2.00 \
        1.00 \
        180.00 \
        1.0 \
        100.000 \
        40 \
        0 \
        1 \
        12000.000 \
        0.0 \
        0.0 \
        0.0 \
        0.0 \
        1 \
        0 \
    ]
}


# not straightfoward to derive a class from RunField.
# may replace the RunField in the future.
class ::DCS::RunFieldForQueue {
    public proc nameToIndex { name } {
        set index [lsearch -exact $NAME_LIST $name]
        if {$index < 0} {
            return -code error "bad field name for run: $name"
        }
        return $index
    }
    public proc getField { runRef name } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error \
            "run definition too short for $name ll=$ll index=$index"
        }
        return [lindex $contents $index]
    }
    public proc setField { runRef name value } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error "run definition too short"
        }
        ##### checking
        if {$name == "file_root"} {
            set newValue [TrimStringForCrystalID $value]
            if {$newValue != $value} {
                log_error file_root adjusted from $value to $newValue
                set value $newValue
            }
        }
        if {$name == "directory"} {
            set newValue [TrimStringForRootDirectoryName $value]
            if {$newValue != $value} {
                log_warning directory $value changed to $newValue
                set value $newValue
            }
        }

        set contents [lreplace $contents $index $index $value]
    }
    public proc getList { runRef args } {
        upvar $runRef contents
        set ll [llength $contents]
        set valueList ""

        foreach name $args {
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            lappend valueList [lindex $contents $index]
        }
        return $valueList
    }
    public proc setList { runRef args } {
        upvar $runRef contents
        set ll [llength $args]
        if {$ll ==0} return
        if {$ll % 2} {
            return -code error "wrong name_value_pair_list"
        }
        set ll [llength $contents]
        set new_contents $contents
        foreach {name value} $args {
            if {$name == "file_root"} {
                set newValue [TrimStringForCrystalID $value]
                if {$newValue != $value} {
                    log_error file_root adjusted from $value to $newValue
                    set value $newValue
                }
            }
            if {$name == "directory"} {
                set newValue [TrimStringForRootDirectoryName $value]
                if {$newValue != $value} {
                    log_warning directory $value changed to $newValue
                    set value $newValue
                }
            }
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            set new_contents [lreplace $new_contents $index $index $value]
        }
        ##### single change of the list
        set contents $new_contents
    }

    public proc getNumField { } {
        return [llength $NAME_LIST]
    }

    public proc fieldIsVirtual { name } {
        set i [lsearch -exact $NAME_VIRTUAL_LIST $name]
        if {$i >= 0} {
            return 1
        } else {
            return 0
        }
    }
    public proc fieldNeedExtraUpdateDistance { name } {
        set i [lsearch -exact $NAME_NEED_EXTRA_UPDATE_DISTANCE_LIST $name]
        if {$i >= 0} {
            return 1
        } else {
            return 0
        }
    }
    public proc fieldNeedExtraUpdateTime { name } {
        set i [lsearch -exact $NAME_NEED_EXTRA_UPDATE_TIME_LIST $name]
        if {$i >= 0} {
            return 1
        } else {
            return 0
        }
    }


    #### following fields will not be in the run definition here
    #### will be part of the run definition from SIL
    ####
    #### video snapshot at reposition_phi = 0
    #### video snapshot at reposition_phi = 90
    #### diffraction image at reposition_phi = 0
    #### diffraction image at reposition_phi = 90

    ############
    #### following fields are not in the SIL run definition, but
    #### they are in the run string
    #### SIL_ID
    #### ROW_ID
    #### UNIQUE_ID
    #### RUN_INDEX
    #### so that it can be mapped to the SIL.

    public common NAME_VIRTUAL_LIST [list \
        sil_id \
        row_id \
        unique_id \
        run_id \
    ]
    public common NAME_NEED_EXTRA_UPDATE_DISTANCE_LIST [list \
        resolution_mode \
        resolution \
        distance \
        energy1 \
        energy2 \
        energy3 \
        energy4 \
        energy5 \
        detector_mode \
    ]
    public common NAME_NEED_EXTRA_UPDATE_TIME_LIST [list \
        dose_mode \
        attenuation \
        exposure_time \
        photon_count \
        distance \
        energy1 \
        energy2 \
        energy3 \
        energy4 \
        energy5 \
    ]
    #### must match with DEFAULT
    public common NAME_LIST [list \
        sil_id \
        row_id \
        unique_id \
        run_id \
        position_id \
        status \
        next_frame \
        run_label \
        file_root \
        directory \
        start_frame \
        axis_motor \
        start_angle \
        end_angle \
        delta \
        wedge_size \
        dose_mode \
        attenuation \
        exposure_time \
        photon_count \
        resolution_mode \
        resolution \
        distance \
        beam_stop \
        num_energy \
        energy1 \
        energy2 \
        energy3 \
        energy4 \
        energy5 \
        detector_mode \
        inverse_on \
        beam_width \
        beam_height \
        reposition_x \
        reposition_y \
        reposition_z \
    ]
    #### must match with NAME_LIST
    public common DEFAULT [list \
        -1 \
        -1 \
        "" \
        -1 \
        -1 \
        inactive \
        0 \
        0 \
        test0 \
        /data/ \
        1 \
        Phi \
        1.00 \
        2.00 \
        1.00 \
        180.00 \
        1 \
        0.0 \
        1.0 \
        1.0 \
        0 \
        2.0 \
        100.000 \
        40.0 \
        1 \
        12000.000 \
        0.0 \
        0.0 \
        0.0 \
        0.0 \
        1 \
        0 \
        0.2 \
        0.1 \
        0.0 \
        0.0 \
        0.0 \
    ]
}
class ::DCS::PositionFieldForQueue {
    public proc nameToIndex { name } {
        set index [lsearch -exact $NAME_LIST $name]
        if {$index < 0} {
            return -code error "bad field name for position: $name"
        }
        return $index
    }
    public proc getField { runRef name } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error \
            "position definition too short for $name ll=$ll index=$index"
        }
        return [lindex $contents $index]
    }
    public proc setField { runRef name value } {
        upvar $runRef contents
        set ll [llength $contents]

        set index [nameToIndex $name]
        if {$index >= $ll} {
            return -code error "position definition too short"
        }
        set contents [lreplace $contents $index $index $value]
    }
    public proc getList { runRef args } {
        upvar $runRef contents
        set ll [llength $contents]
        set valueList ""

        foreach name $args {
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            lappend valueList [lindex $contents $index]
        }
        return $valueList
    }
    public proc setList { runRef args } {
        upvar $runRef contents
        set ll [llength $args]
        if {$ll ==0} return
        if {$ll % 2} {
            return -code error "wrong name_value_pair_list"
        }
        set ll [llength $contents]
        set new_contents $contents
        foreach {name value} $args {
            set index [nameToIndex $name]
            if {$index >= $ll} {
                return -code error "run definition too short"
            }
            set new_contents [lreplace $new_contents $index $index $value]
        }
        ##### single change of the list
        set contents $new_contents
    }

    public proc getNumField { } {
        return [llength $NAME_LIST]
    }

    #### must match with DEFAULT
    public common NAME_LIST [list \
        sil_id \
        row_id \
        unique_id \
        position_id \
        position_name \
        autoindexable \
        file_reorient_0 \
        file_reorient_1 \
        file_box_0 \
        file_box_1 \
        file_diff_0 \
        file_diff_1 \
        beam_width \
        beam_height \
        reposition_x \
        reposition_y \
        reposition_z \
        energy \
        distance \
        beam_stop \
        delta \
        attenuation \
        exposure_time \
        flux \
        i2 \
        camera_zoom \
        sample_scale_factor \
        detector_mode \
        beamline \
        reorient_info \
        autoindex_images \
        autoindex_score \
        autoindex_unit_cell \
        autoindex_mosaicity \
        autoindex_rmsr \
        autoindex_bravais_lattice \
        autoindex_resolution \
        autoindex_isigma \
        autoindex_dir \
        autoindex_best_solution \
        autoindex_warning \
    ]
    #### must match with NAME_LIST
    public common DEFAULT [list \
        -1 \
        -1 \
        "" \
        -1 \
        "DEFAULT_FROM_SCREENING" \
        0 \
        /home/jsong/test1.jpg \
        /home/jsong/test2.jpg \
        /home/jsong/test1.jpg \
        /home/jsong/test2.jpg \
        /home/jsong/not_exist.mccd \
        /home/jsong/not_exist.mccd \
        0.2 \
        0.2 \
        0.0 \
        0.0 \
        0.0 \
        12000.0 \
        200.0 \
        20.0 \
        1.0 \
        0.0 \
        1.0 \
        0.5 \
        2000 \
        1.0 \
        2.9 \
        0 \
        BL-sim \
        /home/jsong/reorient_info \
        {} \
        0.0 \
        {0.0 0.0 0.0 0.0 0.0 0.0} \
        0.0 \
        0.0 \
        {} \
        0.0 \
        0.0 \
        /home/jsong/autoindex_dir \
        -1 \
        {} \
    ]
}
