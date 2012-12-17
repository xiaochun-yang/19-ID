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

package provide BLUICEAutoSampleCal 1.0

# load standard packages
package require Iwidgets
#package require BWidget 1.2.1

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

#package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
#package require DCSHardwareManager
#package require DCSPrompt
#package require DCSMotorControlPanel
package require DCSCheckbutton
#package require DCSGraph
package require DCSLabel
package require DCSFeedback
package require DCSDeviceLog
package require DCSCheckbox
package require DCSEntryfield
package require DCSDeviceFactory

class AutoSampleWidget {
    inherit ::itk::Widget

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }

        #create all of the pages
        set CommandSite [$itk_component(notebook) add -label "Calibration"]
        set ConfigSite [$itk_component(notebook) add -label "Config"]
        set CalibrateSite [$itk_component(notebook) add -label "Installation"]
        set LogSite [$itk_component(notebook) add -label "Log"]
        $itk_component(notebook) view 0
        
        itk_component add command {
          AutoSampleCommandWidget $CommandSite.cs
        } {
        }

        itk_component add config {
          AutoSampleConfigWidget $ConfigSite.cs -systemIdleOnly 0
        } {
        }

        itk_component add calibrate {
          AutoSampleSelfWidget $CalibrateSite.cs -systemIdleOnly 0
        } {
        }

        itk_component add log {
            DCS::DeviceLog $LogSite.l \
            -logStyle all
        } {
        }
        $itk_component(log) addOperations auto_sample_cal
        $itk_component(log) addMotors sample_x sample_y sample_z

        eval itk_initialize $args

        pack $itk_component(command) -expand yes -fill both
        pack $itk_component(config) -expand yes -fill both
        pack $itk_component(calibrate) -expand yes -fill both
        pack $itk_component(log) -expand yes -fill both

        pack $itk_component(notebook) -expand yes -fill both
        pack $itk_interior -expand yes -fill both
    }

    destructor {
    }
}

class AutoSampleCommandWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objOpAuto
    private variable m_objX
    private variable m_objY
    private variable m_objZ

    public method handleMove { } {
        $m_objOpAuto startOperation move_xyz
    }

    public method handleCheck { } {
        $m_objOpAuto startOperation check_xyz
    }

    public method handleCalibrate { } {
        $m_objOpAuto startOperation calibrate_xyz
    }

    public method handleSet { } {
        $m_objOpAuto startOperation reset_xyz
    }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objOpAuto [$m_deviceFactory createOperation auto_sample_cal]
        set m_objX [$m_deviceFactory getObjectName sample_x]
        set m_objY [$m_deviceFactory getObjectName sample_y]
        set m_objZ [$m_deviceFactory getObjectName sample_z]

        itk_component add left_pane {
            frame $itk_interior.left
        } {
        }

        set ring $itk_component(left_pane)

        itk_component add move {
            DCS::Button $ring.move \
            -text "Move xyz to 0" \
            -width 20\
            -command "$this handleMove"
        } {
            keep -systemIdleOnly
        }
        itk_component add check {
            DCS::Button $ring.check \
            -text "Check xyz" \
            -width 20\
            -command "$this handleCheck"
        } {
            keep -systemIdleOnly
        }
        itk_component add calibrate {
            DCS::Button $ring.cal    \
            -text "Calibrate xyz" \
            -width 20\
            -command "$this handleCalibrate"
        } {
            keep -systemIdleOnly
        }

        itk_component add config {
            DCS::Button $ring.config \
            -text "Reset xyz to 0" \
            -background yellow \
            -width 20 \
            -command "$this handleSet"
        } {
            keep -systemIdleOnly
        }

        $itk_component(move) addInput \
        "$m_objOpAuto permission GRANTED {PERMISSION}"
        $itk_component(check) addInput \
        "$m_objOpAuto permission GRANTED {PERMISSION}"
        $itk_component(calibrate) addInput \
        "$m_objOpAuto permission GRANTED {PERMISSION}"
        $itk_component(config) addInput \
        "$m_objOpAuto permission GRANTED {PERMISSION}"

        $itk_component(move) addInput \
        "$m_objOpAuto status inactive {supporting device}"
        $itk_component(check) addInput \
        "$m_objOpAuto status inactive {supporting device}"
        $itk_component(calibrate) addInput \
        "$m_objOpAuto status inactive {supporting device}"
        $itk_component(config) addInput \
        "$m_objOpAuto status inactive {supporting device}"

        eval itk_initialize $args

        pack $itk_component(move) -side top -anchor w
        pack $itk_component(check) -side top -anchor w
        pack $itk_component(calibrate) -side top -anchor w
        pack $itk_component(config) -side top -anchor w

        itk_component add right_pane {
            frame $itk_interior.right
        } {
        }
        set MotorSite $itk_component(right_pane)
        itk_component add sample_x {
            DCS::TitledMotorEntry $MotorSite.x \
            -autoGenerateUnitsList 1 \
            -labelText sample_x \
            -device $m_objX
        } {
        }

        itk_component add sample_y {
            DCS::TitledMotorEntry $MotorSite.y \
            -autoGenerateUnitsList 1 \
            -labelText sample_y \
            -device $m_objY
        } {
        }

        itk_component add sample_z {
            DCS::TitledMotorEntry $MotorSite.z \
            -autoGenerateUnitsList 1 \
            -labelText sample_z \
            -device $m_objZ
        } {
        }

        pack $itk_component(sample_x) -side top
        pack $itk_component(sample_y) -side top
        pack $itk_component(sample_z) -side top

        pack $itk_component(left_pane) -side left
        pack $itk_component(right_pane) -side right
    }

    destructor {
    }
}
class AutoSampleConfigWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objStrConst

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objStrConst [$m_deviceFactory createString auto_sample_const]

        set ring $itk_interior

        itk_component add max_cycle {
            DCS::Entryfield $ring.mc    \
            -validate integer \
            -fixed 3 -width 6 \
            -labeltext "max calibration cycle" \
            -labelpos w \
            -offset 1 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }

        itk_component add etc {
            frame $ring.fr_etc
        } {
        }
        set frame_etc $itk_component(etc)

        itk_component add system_on {
            DCS::Checkbox $frame_etc.on \
            -itemList [list system_on 29 save_data 31] \
            -stringName auto_sample_const
        } {
        }
        pack $itk_component(system_on) -side top

        #puts "add num_point"
        itk_component add num_point {
            iwidgets::Labeledframe $ring.fr_np \
            -labelpos nw \
            -labeltext "number of points"
        } {
        }

        set frame_num_point [$itk_component(num_point) childsite]

        itk_component add point_cal {
            DCS::Entryfield $frame_num_point.cal    \
            -validate integer \
            -fixed 3 -width 6 \
            -labeltext "calibration xyz" \
            -labelpos w \
            -offset 3 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }

        itk_component add point_check {
            DCS::Entryfield $frame_num_point.chk    \
            -validate integer \
            -fixed 3 -width 6 \
            -labeltext "check xyz" \
            -labelpos w \
            -offset 5 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }

        itk_component add point_self {
            DCS::Entryfield $frame_num_point.slf    \
            -validate integer \
            -fixed 3 -width 6 \
            -labeltext "self calibration" \
            -labelpos w \
            -offset 7 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(point_cal) -side top
        pack $itk_component(point_check) -side top
        pack $itk_component(point_self) -side top

        #puts "add sample"
        itk_component add sample {
            iwidgets::Labeledframe $ring.fr_sl \
            -labelpos nw \
            -labeltext "samples per point"
        } {
        }

        set frame_sample [$itk_component(sample) childsite]

        itk_component add sample_num {
            DCS::Entryfield $frame_sample.num    \
            -validate integer \
            -fixed 2 -width 6 \
            -labeltext "sample number" \
            -labelpos w \
            -offset 11 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add sample_time {
            DCS::Entryfield $frame_sample.time    \
            -validate real \
            -fixed 5 -width 6 \
            -labeltext "average time (s)" \
            -labelpos w \
            -offset 9 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(sample_num) -side top
        pack $itk_component(sample_time) -side top
    
        #puts "add threshold"
        itk_component add threshold {
            iwidgets::Labeledframe $ring.fr_td \
            -labelpos nw \
            -labeltext "satisfying threshold"
        } {
        }

        set frame_threshold [$itk_component(threshold) childsite]

        itk_component add threshold_x {
            DCS::Entryfield $frame_threshold.x    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "X (mm)" \
            -labelpos w \
            -offset 15 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add threshold_y {
            DCS::Entryfield $frame_threshold.y    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "Y (mm)" \
            -labelpos w \
            -offset 17 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add threshold_z {
            DCS::Entryfield $frame_threshold.z    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "Z (mm)" \
            -labelpos w \
            -offset 19 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add threshold_std {
            DCS::Entryfield $frame_threshold.s    \
            -validate integer \
            -fixed 1 -width 6 \
            -labeltext "num std deviation" \
            -labelpos w \
            -offset 13 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(threshold_x) -side top
        pack $itk_component(threshold_y) -side top
        pack $itk_component(threshold_z) -side top
        pack $itk_component(threshold_std) -side top
    
        #puts "add max"
        itk_component add max {
            iwidgets::Labeledframe $ring.fr_max \
            -labelpos nw \
            -labeltext "max values"
        } {
        }
        set frame_max [$itk_component(max) childsite]

        itk_component add max_x {
            DCS::Entryfield $frame_max.x    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "x correct (mm)" \
            -labelpos w \
            -offset 21 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add max_y {
            DCS::Entryfield $frame_max.y    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "y correct (mm)" \
            -labelpos w \
            -offset 23 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add max_z {
            DCS::Entryfield $frame_max.z    \
            -validate real \
            -fixed 4 -width 6 \
            -labeltext "z correct (mm)" \
            -labelpos w \
            -offset 25 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
    
        itk_component add max_phi_offset {
            DCS::Entryfield $frame_max.phi    \
            -validate real \
            -fixed 3 -width 6 \
            -labeltext "warning phi offset" \
            -labelpos w \
            -offset 27 \
            -stringName auto_sample_const
        } {
            keep -systemIdleOnly
        }
        pack $itk_component(max_x) -side top
        pack $itk_component(max_y) -side top
        pack $itk_component(max_z) -side top
        pack $itk_component(max_phi_offset) -side top


        iwidgets::Labeledwidget::alignlabels \
        [$itk_component(point_cal) getEntryfield] \
        [$itk_component(point_check) getEntryfield] \
        [$itk_component(point_self) getEntryfield] \
        [$itk_component(sample_num) getEntryfield] \
        [$itk_component(sample_time) getEntryfield] \
        [$itk_component(threshold_x) getEntryfield] \
        [$itk_component(threshold_y) getEntryfield] \
        [$itk_component(threshold_z) getEntryfield] \
        [$itk_component(threshold_std) getEntryfield] \
        [$itk_component(max_x) getEntryfield] \
        [$itk_component(max_y) getEntryfield] \
        [$itk_component(max_z) getEntryfield] \
        [$itk_component(max_phi_offset) getEntryfield]

        #puts "grid"
        grid $itk_component(max_cycle) -row 0 -column 0 -sticky w
        grid $itk_component(etc) -row 0 -column 1 -sticky w

        grid $itk_component(num_point) -row 1 -column 0 -sticky w
        grid $itk_component(sample) -row 1 -column 1    -sticky w

        grid $itk_component(threshold) -row 2 -column 0 -sticky w
        grid $itk_component(max) -row 2 -column 1       -sticky w
        #puts "done constructo5r"
    }
}
class AutoSampleSelfWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable m_deviceFactory
    private variable m_objOpAuto
    private variable m_objStrData

    public method handleSelf { } {
        $m_objOpAuto startOperation self_calibration
    }
    public method handleHelp { } {
        if {[catch "openWebWithBrowser [::config getStr document.displacement_sensor]" err_msg]} {
            log_error "start mozilla failed: $err_msg"
        } else {
            bind $itk_component(note2) <Button-1> ""
            after 20000 "bind $itk_component(note2) <Button-1> {$this handleHelp}"
        }
    }

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objOpAuto [$m_deviceFactory createOperation auto_sample_cal]
        set m_objStrData [$m_deviceFactory createString auto_sample_data]
        $m_objStrData createAttributeFromField time_stamp 0
        $m_objStrData createAttributeFromField desired_average 2
        $m_objStrData createAttributeFromField scale_x 4
        $m_objStrData createAttributeFromField scale_y 6
        $m_objStrData createAttributeFromField scale_z 8
        $m_objStrData createAttributeFromField phi_offset_x 10
        $m_objStrData createAttributeFromField phi_offset_y 12

        itk_component add left_pane {
            frame $itk_interior.left
        } {
        }

        set ring $itk_component(left_pane)

        itk_component add note1 {
            label $ring.note1 \
            -text "This option is only used for the initial installation of \nthe displacement sensor hardware and stand.\n\nFor more information see:"
        } {
        }
        itk_component add note2 {
            label $ring.note2 \
            -foreground blue \
            -text "https://smb.slac.stanford.edu/secure/staff_pages/\nEngineeringDev/DisplacementSensorInstallation/\n"
        } {
        }

        bind $itk_component(note2) <Button-1> "$this handleHelp"

        itk_component add self {
            DCS::Button $ring.self \
            -text "self calibration" \
            -width 20\
            -command "$this handleSelf"
        } {
            keep -systemIdleOnly
        }
        $itk_component(self) addInput \
        "$m_objOpAuto permission GRANTED {PERMISSION}"
        $itk_component(self) addInput \
        "$m_objOpAuto status inactive {supporting device}"
    
        pack $itk_component(note1)
        pack $itk_component(note2)
        pack $itk_component(self)

        itk_component add right_pane {
            frame $itk_interior.right
        } {
        }

        set frame_right $itk_component(right_pane)
        itk_component add time_stamp {
            DCS::Label $frame_right.ts \
            -component $m_objStrData \
            -attribute time_stamp \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "time stamp"
        } {
        }

        itk_component add average {
            DCS::Label $frame_right.average \
            -component $m_objStrData \
            -attribute desired_average \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "desired average"
        } {
        }

        itk_component add scale_x {
            DCS::Label $frame_right.scale_x \
            -component $m_objStrData \
            -attribute scale_x \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "X scale"
        } {
        }

        itk_component add scale_y {
            DCS::Label $frame_right.scale_y \
            -component $m_objStrData \
            -attribute scale_y \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "Y scale"
        } {
        }

        itk_component add scale_z {
            DCS::Label $frame_right.scale_z \
            -component $m_objStrData \
            -attribute scale_z \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "Z scale"
        } {
        }

        itk_component add phi_offset_x {
            DCS::Label $frame_right.phix \
            -component $m_objStrData \
            -attribute phi_offset_x \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "phi offset X"
        } {
        }

        itk_component add phi_offset_y {
            DCS::Label $frame_right.phiy \
            -component $m_objStrData \
            -attribute phi_offset_y \
            -promptWidth 18 \
            -promptAnchor w \
            -width 18 \
            -anchor w \
            -promptText "phi offset Y"
        } {
        }
        pack $itk_component(time_stamp)
        pack $itk_component(average)
        pack $itk_component(scale_x)
        pack $itk_component(scale_y)
        pack $itk_component(scale_z)
        pack $itk_component(phi_offset_x)
        pack $itk_component(phi_offset_y)

        pack $itk_component(left_pane) -side top
        pack $itk_component(right_pane) -side top
        
    }
}
