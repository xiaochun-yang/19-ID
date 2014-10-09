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

package provide BLUICESamplePosition 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent

package require DCSDeviceView
package require DCSProtocol
package require DCSOperationManager
package require DCSHardwareManager
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSDeviceFactory

package require DCSMotorButton
package require DCSVideo

global gVideoUseStep

class SamplePositioningWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss

    itk_option define -forL614 forL614 ForL614 0

    itk_option define -useStepSize useStepSize UseStepSize $gVideoUseStep {
        if {$itk_option(-useStepSize)} {
            pack $itk_component(padStep) -side left
            grid $itk_component(inPadStep) -column 2 -row 2
            pack $itk_component(phiStep) -side left
            pack $itk_component(phiPlus) -side left
            pack $itk_component(phiMinus) -side left
        } else {
            pack forget $itk_component(padStep)
            grid forget $itk_component(inPadStep)
            pack forget $itk_component(phiStep)
            pack forget $itk_component(phiPlus)
            pack forget $itk_component(phiMinus)
        }
    }

    protected variable minimumHorzStep [expr 1.0/354]
    protected variable minimumVertStep [expr 1.0/240]

    public method setPadStep { s } {
        $itk_component(padStep) setValue $s 1
        $itk_component(inPadStep) setValue $s 1
    }
    public method rotatePhiStep { s } {
        set step [lindex [$itk_component(phiStep) get] 0]
        set step [expr ${s}1 * $step]

        $m_objPhi move by $step
    }

    private method getMoveOperation { } {
        return $m_opMove
    }


    private method startStepMove { dir } {
        set camera sample
        set sign -1
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        switch -exact -- $dir {
            left {
                set horz [expr -1 * $sign * $stepSize]
                set vert 0
            }
            right {
                set horz [expr $sign * $stepSize]
                set vert 0
            }
            up {
                set horz 0
                set vert $stepSize
            }
            down {
                set horz 0
                set vert [expr -1 * $stepSize]
            }
            default {
                return
            }
        }
        $m_opStepMove startOperation $camera $horz $vert
    }

    public method padLeft { } {
        if {$itk_option(-useStepSize)} {
            startStepMove left
            return
        }
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by 0.8
        } else {
            [getMoveOperation] startOperation -$minimumHorzStep 0.0
        }
    }
    public method padRight { } {
        if {$itk_option(-useStepSize)} {
            startStepMove right
            return
        }
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by -0.8
        } else {
            [getMoveOperation] startOperation $minimumHorzStep 0.0
        }
    }
    public method padUp { } {
        if {$itk_option(-useStepSize)} {
            startStepMove up
            return
        }
        [getMoveOperation] startOperation 0.0 -$minimumVertStep
    }
    public method padDown { } {
        if {$itk_option(-useStepSize)} {
            startStepMove down
            return
        }
        [getMoveOperation] startOperation 0.0 $minimumVertStep
    }
    public method padFastLeft { } {
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by 11.2
        } else {
            [getMoveOperation] startOperation -0.5 0.0
        }
    }
    public method padFastRight { } {
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by -11.2
        } else {
            [getMoveOperation] startOperation 0.5 0.0
        }
    }

    public method addChildVisibilityControl

    public method takeVideoSnapshot { }
    public method saveVideoSnapshot { filename }

    ### horz vert here are microns
    public method setGrid { hoff voff horz vert n_horz n_vert color } {
        $itk_component(video) setGrid $hoff $voff $horz $vert $n_horz $n_vert $color
    }

    public method addInputForRaster { input } {
        $itk_component(snapshot) addInput $input
        $itk_component(center) addInput $input
    }

    public method configSnapshotButton { args } {
        eval $itk_component(snapshot) configure $args
        pack $itk_component(snapshot) -before $itk_component(zoomLabel)
    }

    public method configCenterLoopButton { args } {
        eval $itk_component(center) configure $args
    }

    public method centerCrystal { } {
        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID  PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set dir  /data/$user/centerCrystal
        set fileRoot [::config getConfigRootName]
        $m_opCenterCrystal startOperation $user $SID $dir $fileRoot
    }
    public method centerMicroCrystal { } {
        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID  PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set dir  /data/$user/centerCrystal
        set fileRoot [::config getConfigRootName]
        $m_opCenterCrystal startOperation $user $SID $dir $fileRoot use_collimator_constant
    }
    public method handleCrystalEnabledEvent { stringName_ ready_ alias_ contents_ - } {
        if {!$ready_} return

        if {$contents_ == ""} {
            set contents_ 0
        }

        #####do not show this button for now
        set contents_ 0

        if {$m_centerCrystalEnabled == $contents_} return
        set m_centerCrystalEnabled $contents_

        if {$m_centerCrystalEnabled} {
            pack $itk_component(crystal)
        } else {
            pack forget $itk_component(crystal)
        }
    }

    private variable m_deviceFactory
    private variable m_opCenterCrystal
    private variable m_centerCrystalEnabled 0
    private variable m_strCenterCrystalConst
    private variable m_opStepMove ""
    private variable m_opStepFocus ""
    private variable m_opMove ""
    private variable m_objPhi ""

    private common PHI_BUTTON_STEP_SIZE [::config getInt "phiButtonStepSize" 10]

    # constructor
    constructor { url paraName zoomName opNameCenterLoop opNameMoveSample args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objPhi [$m_deviceFactory getObjectName gonio_phi]
        set m_opMove [$m_deviceFactory getObjectName $opNameMoveSample]
        set m_opStepMove [$m_deviceFactory createOperation moveSampleOnVideo]
        set m_opStepFocus [$m_deviceFactory createOperation moveSampleOutVideo]
        set m_strCenterCrystalConst [$m_deviceFactory createString center_crystal_const]
        $m_strCenterCrystalConst createAttributeFromField system_on 0

        itk_component add control {
            frame $itk_interior.c
        }

        itk_component add zoomLabel {
            # create the camera zoom label
            label $itk_component(control).zoomLabel \
                 -text "Select Zoom Level" \
                 -font "helvetica -14 bold"
        }

        itk_component add zoomFrame {
            frame $itk_component(control).z
        }

        itk_component add zoomLow {
            # make the low zoom button
            DCS::MoveMotorsToTargetButton $itk_component(zoomFrame).zoomLow \
                 -text "Low" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {}


        itk_component add zoomMed {
            # make the medium zoom button
            DCS::MoveMotorsToTargetButton $itk_component(zoomFrame).zoomMed \
                 -text "Med" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {}

        itk_component add zoomHigh {
            # make the medium zoom button
            DCS::MoveMotorsToTargetButton  $itk_component(zoomFrame).zoomHigh \
                 -text "High" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {
        }
        itk_component add zoomMinus {
            DCS::MoveMotorRelativeButton  $itk_component(zoomFrame).zoomMinus \
                 -delta -0.1 \
                 -text "-" \
                 -background #c0c0ff -activebackground #c0c0ff
        } {
        }
        itk_component add zoomPlus {
            DCS::MoveMotorRelativeButton  $itk_component(zoomFrame).zoomPlus \
                 -delta 0.1 \
                 -text "+" \
                 -background #c0c0ff -activebackground #c0c0ff
        } {
        }

        itk_component add moveStepF {
            frame $itk_component(control).msf
        } {
        }
        set mstepSite $itk_component(moveStepF)
        itk_component add moveSampleLabel {
            # create the move sample label
            label $mstepSite.sampleLabel \
                 -text "Move Sample" \
                 -font "helvetica -14 bold"
        }

        set padStepChoices [::config getStr "arrowPadStepSize"]
        if {$padStepChoices == ""} {
            set padStepChoices "5 10 15 20 50 100 200"
        }

        itk_component add padStep {
            ::DCS::MenuEntry $mstepSite.padStep \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        pack $itk_component(moveSampleLabel) -side left

        # make joypad
        itk_component add arrowPad {
            DCS::ArrowPad $itk_component(control).ap \
                 -activeClientOnly 1 \
                 -debounceTime 100 -buttonBackground #c0c0ff
        } {
        }
        set padSite [$itk_component(arrowPad) getRing]

        itk_component add inPadStep {
            ::DCS::MenuEntry $padSite.padStep \
            -showArrow 0 \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -showUnits 0 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        grid $itk_component(inPadStep) -column 2 -row 2


        set showFocusButton [::config getInt "bluice.showFocusButton" 0]
        if {$showFocusButton} {
            itk_component add focusIn {
                ::DCS::ArrowButton $padSite.focusIn far \
                -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove 1"
            } {
            }
            grid $itk_component(focusIn) -column 0 -row 0

            itk_component add focusOut {
                ::DCS::ArrowButton $padSite.focusOut near \
                -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove -1"
            } {
            }
            grid $itk_component(focusOut) -column 4 -row 0
        }

        itk_component add phiStepF {
            frame $itk_component(control).phiStepF
        } {
        }
        set pstepSite $itk_component(phiStepF)

        itk_component add phiLabel {
            # create the phi label
            label $pstepSite.phiLabel \
                 -text "Rotate Phi" \
                 -font "helvetica -14 bold"
        } {
        }
        pack $itk_component(phiLabel) -side left

        itk_component add phiStep {
            ::DCS::MenuEntry $pstepSite.phiStep \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices {20 30 40 45 50 60 70 80} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList deg \
            -units deg \
            -showUnits 1 \
        } {
        }
        itk_component add phiPlus {
            ::DCS::ArrowButton $pstepSite.phiPlus plus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep +"
        } {
        }
        itk_component add phiMinus {
            ::DCS::ArrowButton $pstepSite.phiMinus minus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep -"
        } {
        }

        itk_component add phiFrame {
            frame $itk_component(control).p
        }

        itk_component add minus10 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).minus10 \
                 -delta "-$PHI_BUTTON_STEP_SIZE" \
                 -text "-$PHI_BUTTON_STEP_SIZE" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        itk_component add plus10 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus10 \
                 -delta "$PHI_BUTTON_STEP_SIZE" \
                 -text "+$PHI_BUTTON_STEP_SIZE" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        # make the Phi -90 button
        itk_component add minus90 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).minus90 \
                 -delta "-90" \
                 -text "-90" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        # make the Phi +90 button
        itk_component add plus90 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus90 \
                 -delta "90" \
                 -text "+90" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }


        itk_component add plus180 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus180 \
                 -delta "180" \
                 -text "+180" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }


        itk_component add center {
            ::DCS::Button $itk_component(control).center \
                 -text "Center Loop" \
                 -width 15 -activeClientOnly 1
        } {
        }
        itk_component add crystal {
            ::DCS::Button $itk_component(control).crystal \
                 -text "Center Crystal" \
                 -width 15 -activeClientOnly 1
        } {
        }
        itk_component add snapshot {
            ::DCS::Button $itk_component(control).snapshot \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Video Snapshot" \
            -width 15 \
            -command "$this takeVideoSnapshot"
        } {
        }

        # create the video image of the sample
        itk_component add video {
            SampleVideoWidget $itk_interior.video \
            -imageSettings "$url $paraName $zoomName $opNameMoveSample"
        } {
            keep -videoParameters
            keep -videoEnabled
            keep -beamWidthWidget
            keep -beamHeightWidget
            keep -purpose
            keep -mode
            keep -packOption
            keep -beamMatchColor
        }

        # evaluate configuration parameters
        eval itk_initialize $args

        set centerLoopOperation [$m_deviceFactory getObjectName $opNameCenterLoop]
        $itk_component(center) configure -command "$centerLoopOperation startOperation"
        #$itk_component(center) addInput "::dataCollectionActive gateOutput 1 {Data Collection is in progress}"
        $itk_component(center) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(center) addInput "::device::getLoopTip status inactive {supporting device}"
        $itk_component(center) addInput "::device::gonio_phi status inactive {supporting device}"
        $itk_component(center) addInput "::device::camera_zoom status inactive {supporting device}"

        set m_opCenterCrystal [$m_deviceFactory getObjectName centerCrystal]
        $itk_component(crystal) configure -command "$this centerCrystal"



        $itk_component(arrowPad) configure \
             -leftCommand      "$this padLeft" \
             -upCommand        "$this padUp" \
             -downCommand      "$this padDown" \
             -rightCommand     "$this padRight" \
             -fastLeftCommand  "$this padFastLeft" \
             -fastRightCommand "$this padFastRight"


        $itk_component(arrowPad) addInput left "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput right "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastLeft "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastRight "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "::device::sample_y status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "::device::sample_y status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "::device::sample_x status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "::device::sample_x status inactive {supporting device}"

        $itk_component(arrowPad) addInput left "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput right "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastLeft "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastRight "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "$centerLoopOperation status inactive {supporting device}"

        $itk_component(zoomLow) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(zoomMed) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(zoomHigh) addInput "$centerLoopOperation status inactive {supporting device}"

        $itk_component(minus10) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus10) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(minus90) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus90) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus180) addInput "$centerLoopOperation status inactive {supporting device}"

        #don't allow the sample to be centered while the sample is already moving
        $itk_component(center) addInput "::device::gonio_phi status inactive {supporting device}"
        $itk_component(video) addInput "::device::gonio_phi status inactive {supporting device}"

        #don't allow the sample to be centered while the sample is already moving
        $itk_component(center) addInput "::device::sample_x status inactive {supporting device}"
        $itk_component(center) addInput "::device::sample_y status inactive {supporting device}"
        $itk_component(center) addInput "::device::sample_z status inactive {supporting device}"

        $itk_component(zoomLow) addMotor ::device::$zoomName 0.0
        $itk_component(zoomMed) addMotor ::device::$zoomName 0.75
        $itk_component(zoomHigh) addMotor ::device::$zoomName 1.0
        $itk_component(zoomMinus) configure -device ::device::$zoomName
        $itk_component(zoomPlus) configure -device ::device::$zoomName

        # pack the components
      pack $itk_interior -expand yes -fill both
        pack $itk_component(control) -side left -anchor nw -ipadx 0 -padx 0
        pack $itk_component(video) -side left -expand yes -fill both -ipadx 0 -padx 0
        pack $itk_component(zoomLabel) -anchor n

        pack $itk_component(zoomFrame) -anchor n
        if {$itk_option(-useStepSize)} {
            pack $itk_component(zoomMinus) -side left
        }
        pack $itk_component(zoomLow) -side left
        pack $itk_component(zoomMed) -side left
        pack $itk_component(zoomHigh) -side left
        if {$itk_option(-useStepSize)} {
            pack $itk_component(zoomPlus) -side left
        }

        pack $itk_component(moveStepF) -anchor n
        pack $itk_component(arrowPad) -anchor n

        pack $itk_component(phiStepF) -anchor n
        pack $itk_component(phiFrame) -anchor n
        pack $itk_component(minus10) -side left
        pack $itk_component(plus10) -side left
        pack $itk_component(minus90) -side left
        pack $itk_component(plus90) -side left
        pack $itk_component(plus180) -side left

        if {$opNameCenterLoop != "not_available"} {
            pack $itk_component(center)
        }
        pack $itk_component(snapshot)
        #$itk_component(videoCanvas) configure -cursor "@crossfg.bmp crossbg.bmp  white red"
        $m_strCenterCrystalConst register $this system_on handleCrystalEnabledEvent

        set minStep [::config getStr "arrowPadDefaultStepSize"]
        if {$minStep == ""} {
            set minStep [lindex $padStepChoices 0]
        }
        $itk_component(padStep) setValue $minStep
        $itk_component(phiStep) setValue 45.0
    }
    destructor {
        $m_strCenterCrystalConst unregister $this system_on handleCrystalEnabledEvent
    }

    public method startFocusMove { dir } {
        set camera sample
        set sign -1
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        set dd [expr $dir * $sign * $stepSize]
        $m_opStepFocus startOperation $camera $dd
    }
}

#thin wrapper for the video enable
body SamplePositioningWidget::addChildVisibilityControl { args} {

    eval $itk_component(video) addChildVisibilityControl $args

}
body SamplePositioningWidget::takeVideoSnapshot { } {
    set user [$itk_option(-controlSystem) getUser]

    ###try to get what's on the goniometer
    set hint ""
    if {[catch {
        set contents [::device::robot_status getContents]
        set sample [lindex $contents 15]
        if {[llength $sample] == 3} {
            foreach {cas row col} $sample break
            set hint "${cas}${col}${row}.jpg"
        }
    } errMsg]} {
        puts "trying to get hints for filename failed: $errMsg"
    }

    set types [list [list JPEG .jpg]]
    puts "hint: $hint"

    set fileName [tk_getSaveFile \
    -initialdir /data/$user \
    -filetypes $types \
    -defaultextension ".jpg" \
    -initialfile $hint
    ]

    if {$fileName == ""} return

    if {[catch {open $fileName w} ch]} {
        log_error failed to open file $fileName to write image: $ch
        return
    }
    if {[catch {
        fconfigure $ch -translation binary -encoding binary
        set data [$itk_component(video) getImageData]
        puts -nonewline $ch $data
    } errMsg]} {
        log_error failed to write image to the file $fileName: $errMsg
    }
    close $ch
    log_warning snapshot saved to $fileName
}
body SamplePositioningWidget::saveVideoSnapshot { fileName } {

    if {$fileName == ""} return

    if {![$itk_component(video) visible]} {
        puts "skip save video to $fileName: not visible and not updating"
        return
    }

    if {[catch {open $fileName w} ch]} {
        log_error failed to open file $fileName to write image: $ch
        return
    }
    if {[catch {
        fconfigure $ch -translation binary -encoding binary
        set data [$itk_component(video) getImageData]
        puts -nonewline $ch $data
    } errMsg]} {
        log_error failed to write image to the file $fileName: $errMsg
    }
    close $ch
    log_warning snapshot saved to $fileName
}

class SampleVideoWidget {
    inherit DCS::Video

    itk_option define -beamWidthWidget beamWidthWidget BeamWidthWidget ""
    itk_option define -beamHeightWidget beamHeightWidget BeamHeightWidget ""

    ### "move_sample" or "define_scan_area" "define_scan_depth"
    itk_option define -purpose purpose Purpose "move_sample"

    ### all dynamic
    itk_option define -imageSettings imageSettings ImageSettings ""

    itk_option define -mode mode Mode "both" {
        $_crosshair configure -mode $itk_option(-mode)
    }

    itk_option define -beamMatchColor beamMatchColor BeamMatchColor white {
        $_crosshair configure \
        -color $itk_option(-beamMatchColor)

        $itk_component(beamsize) configure \
        -matchColor $itk_option(-beamMatchColor)
    }

    ### implement base
    public method handleVideoClick
    public method resizeCallback
    public method handleVideoMotion
    public method handleVideoRelease
    # public methods

    public method updateBeamPosition
    public method updateBeamSize
    public method updateGrid
    protected method handleNewOutput
    protected method updateBubble

    ### horz vert here are microns
    public method setGrid { hoff voff horz vert n_horz n_vert color } {
        set m_gridInfo [list $hoff $voff $horz $vert $n_horz $n_vert $color]
        updateGrid
    }

    public method visible { } {
        return $_visibility
    }

    private method _internalUpdateBeamSize

    #callbacks
    ### these will be called very seldomly.
    public method handleNewSampleCameraConstants
    public method handleBeamsizeUpdate { object_ ready_ - value_ - } {
        if {!$ready_} return
        foreach {_beamSizeX _beamSizeY _beamColor} $value_ break
        updateBeamSize
    }

    ### these will be called frequently
    public method handleCameraZoom

    ##for snapshot
    public method getImageData { } {
        return $_imageData
    }

    private variable _crosshair ""
    ### will change from motors of SampleImageWidth and SampleImageHeight
    #### where is the beam center on the screen [0,1]
    private variable _beamCenterH 0.5
    private variable _beamCenterV 0.5
    ##### to convert beam size from mm to pixel we need
    private variable _zoomMaxScale 1.9262
    private variable _zoomMinScale 19.184
    private variable _cameraZoom  0.75
    private variable _sampleAspectRatio 1.12
    private variable _calibrationImageWidth 352
    private variable _calibrationImageHeight 240
    private variable _beamSizeX    0.25
    private variable _beamSizeY    0.25
    private variable _beamColor    white

    private variable m_indexMap
    private variable m_variableList

    ##### half of the width and height
    private variable _crosshairX 176
    private variable _crosshairY 120

    private variable m_b1PressX 0
    private variable m_b1PressY 0

    private variable m_b1ReleaseX 0
    private variable m_b1ReleaseY 0

    private variable m_gridInfo "0 0 0 0 1 1"
    private variable m_gridWidthPixel 0
    private variable m_gridWidthOffsetPixel 0

    private variable m_deviceFactory

    private variable m_paraName ""
    private variable m_zoomName ""
    private variable m_objMoveSample ""
    private variable m_objDefineScanArea ""

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objDefineScanArea [$m_deviceFactory getObjectName scan3DSetup]

        set cfgNameList [::config getStr sampleCameraConstantsNameList]
        set m_variableList [list \
        _beamCenterH \
        _beamCenterV \
        _zoomMaxScale \
        _zoomMinScale \
        _sampleAspectRatio \
        _calibrationImageWidth \
        _calibrationImageHeight \
        ]
        set fieldList [list \
        zoomMaxXAxis \
        zoomMaxYAxis \
        zoomMaxScale \
        zoomMinScale \
        sampleAspectRatio \
        sampleImageWidth \
        sampleImageHeight \
        ]

        foreach v $m_variableList f $fieldList {
            set index [lsearch -exact $cfgNameList $f]
            set m_indexMap($v) $index
            if {$index < 0} {
                puts "ERROR wrong field {$f} for $paraName"
            }
        }

        # draw cross-hairs on image
        set _crosshair [DCS::Crosshair \#auto $itk_component(canvas) \
                                 -x $_crosshairX \
                                 -y $_crosshairY \
                                 -width 20 \
                                 -height 20
                          ]
        itk_component add beamsize {
            BeamsizeToDisplay $itk_interior.beamsize \
        } {
            keep -beamWidthWidget
            keep -beamHeightWidget
        }

        $itk_component(beamsize) configure \
        -honorCollimator [$m_deviceFactory operationExists collimatorMove]

        $itk_component(beamsize) register $this beamsize handleBeamsizeUpdate

        addUpdateSpeedInput "::device::gonio_phi status moving {gonio_phi is moving}"

        addInput "::device::sample_x status inactive {supporting device}"
        addUpdateSpeedInput "::device::sample_y status moving {sample_x is moving}"
        addInput "::device::sample_y status inactive {supporting device}"
        addUpdateSpeedInput "::device::sample_y status moving {sample_y is moving}"
        addInput "::device::sample_z status inactive {supporting device}"
        addUpdateSpeedInput "::device::sample_z status moving {sample_z is moving}"

        eval itk_initialize $args

        addInput "::dcss clientState active {Must be active to move the sample}"
        set systemIdle [$m_deviceFactory createString system_idle]
        addInput "$systemIdle contents {} {supporting device}"

        announceExist

    }

    destructor {
        destroy $_crosshair
    }

}
configbody SampleVideoWidget::imageSettings {
    if {[llength $itk_option(-imageSettings)] < 4} {
        return
    }

    foreach {url newParaName newZoomName newMoveName} \
    $itk_option(-imageSettings) break

    ### clear up old ones
    if {$m_paraName != ""} {
        ::mediator unregister $this ::device::$m_paraName contents
    }
    if {$m_zoomName != ""} {
        ::mediator unregister $this ::device::$m_zoomName scaledPosition
    }

    configure -imageUrl $url

    set m_paraName $newParaName
    set m_zoomName $newZoomName
    set m_objMoveSample [$m_deviceFactory getObjectName $newMoveName]

    if {$m_paraName != ""} {
        ::mediator register $this ::device::$m_paraName contents handleNewSampleCameraConstants
    }
    if {$m_zoomName != ""} {
        ::mediator register $this ::device::$m_zoomName scaledPosition handleCameraZoom
        addUpdateSpeedInput "::device::$m_zoomName status moving {camera_zoom is moving}"
        ## sorry no remove of speed input
    }
}

body SampleVideoWidget::resizeCallback { } {
    puts "SampleVideoWidget resizeCallback: update all"
    updateBeamPosition
    updateBeamSize
    updateGrid
}

body SampleVideoWidget::handleVideoClick { x y } {
    puts "handleVideoClick $x $y"
    $itk_component(canvas) delete -tag dash_area

    if { $_gateOutput == 1 } {

        #####
        set x [$itk_component(canvas) canvasx $x]
        set y [$itk_component(canvas) canvasy $y]

        set m_b1PressX $x
        set m_b1PressY $y
        if {$itk_option(-purpose) != "move_sample"} {
            return
        }

        if {$m_imageWidth <=0 || $m_imageHeight <=0} {
            log_error NO IMAGE displayed, click ignored
            return
        }

        if {$x < 0 || $x >= $m_imageWidth \
        || $y < 0 || $y >= $m_imageHeight} {
            puts "clicked empty area"
            return
        }

        set deltaX [expr ($_crosshairX - $x) / $m_imageWidth]
        set deltaY [expr ( $_crosshairY - $y) / $m_imageHeight]

        $m_objMoveSample startOperation $deltaX $deltaY
    }
}

body SampleVideoWidget::handleVideoMotion { x y } {
    puts "handleVideoMotion $x $y"
    if {$itk_option(-purpose) == "move_sample" \
    || $itk_option(-purpose) == "display_only"} {
        return
    }

    if { $_gateOutput != 1 } {
        return
    }

    set x [$itk_component(canvas) canvasx $x]
    set y [$itk_component(canvas) canvasy $y]
    set m_b1ReleaseX $x
    set m_b1ReleaseY $y

    if {$itk_option(-purpose) == "define_scan_depth"} {
        set halfW [expr 0.5 * $m_gridWidthPixel]
        set m_b1PressX   [expr $_crosshairX + $m_gridWidthOffsetPixel - $halfW]
        set m_b1ReleaseX [expr $m_b1PressX + $m_gridWidthPixel]

        set b1PressY   [expr 2 * $_crosshairY - $y]
        set b1ReleaseY $y
    }


    $itk_component(canvas) delete -tag dash_area
    $itk_component(canvas) create rectangle \
    $m_b1PressX $m_b1PressY $m_b1ReleaseX $m_b1ReleaseY \
    -width 1 \
    -outline green \
    -dash . \
    -tags dash_area
}

body SampleVideoWidget::handleVideoRelease { x y } {
    puts "handleVideoRelease $x $y"
    if {$itk_option(-purpose) == "move_sample"} {
        return
    }
    if {$itk_option(-purpose) == "display_only"} {
        log_error not in the right place to define scan area
        return
    }

    if { $_gateOutput != 1 } {
        return
    }

    #set x [$itk_component(canvas) canvasx $x]
    #set y [$itk_component(canvas) canvasy $y]
    #set m_b1ReleaseX $x
    #set m_b1ReleaseY $y

    $itk_component(canvas) delete -tag dash_area
    if {$m_imageWidth <=0 || $m_imageHeight <=0} {
        log_error NO IMAGE displayed, click ignored
        return
    }

    if {$m_b1PressX  < 0 || $m_b1PressX   >= $m_imageWidth \
    || $m_b1PressY   < 0 || $m_b1PressY   >= $m_imageHeight \
    || $m_b1ReleaseX < 0 || $m_b1ReleaseX >= $m_imageWidth \
    || $m_b1ReleaseY < 0 || $m_b1ReleaseY >= $m_imageHeight \
    } {
        puts "clicked empty area"
        return
    }

    set x0 [expr double($m_b1PressX) / $m_imageWidth]
    set x1 [expr double($m_b1ReleaseX) / $m_imageWidth]
    set y0 [expr double($m_b1PressY) / $m_imageHeight]
    set y1 [expr double($m_b1ReleaseY) / $m_imageHeight]

    $m_objDefineScanArea startOperation define_scan_area $x0 $y0 $x1 $y1
}

body SampleVideoWidget::handleNewOutput {} {
    if { $_gateOutput == 0 } {
        $itk_component(canvas) config -cursor watch
#"@stop.xbm black"
    } else {
      set cursor [. cget -cursor]
        $itk_component(canvas) config -cursor $cursor
    }
    updateBubble
}

#Update the help message
body SampleVideoWidget::updateBubble {} {


    #delete the help balloon
    catch {wm withdraw .help_shell}
    set message "this blu-ice has a bug"

    set outputMessage [getOutputMessage]

    foreach {output blocker status reason} $outputMessage {break}

    foreach {object attribute} [split $blocker ~] break

    if { ! $_onlineStatus } {
        set message $reason
        #the button has bad inputs and is not ready
        #if { [info commands $object] == "" } {
        #    set message "$object does not exist: $blocker."
        #} else {
        #    set message "Internal errors in $blocker"
        #}
    } elseif { $output } {
        #the widget is enabled
        set message ""
    } else {
        #set deviceStatus $itk_option(-device).status
        #the widget is disabled
        if {$reason == "supporting device" } {

            #something is happening with the device we are interested in.
            switch $status {
                inactive {
            #        configure -labelBackground lightgrey
            #        configure -labelForeground    black
                    set message "Device is ready to move."
                }
                moving   {
            #        configure -labelBackground \#ff4040
            #        configure -labelForeground white
                    set message "[namespace tail $object] is moving."
                }
                offline  {
            #        configure -labelBackground black
            #        configure -labelForeground white
                    set message "DHS '[$object cget -controller]' is offline (needed for [namespace tail $object])."
                }
                default {
            #        configure -labelBackground black
            #        configure -labelForeground white
                    set message "[namespace tail $object] is not ready: $status"
                }
            }
        } else {
            #unhandled reason, use default reason specified with addInput
            set message "$reason"
        }
    }

    DynamicHelp::register $itk_component(canvas) balloon $message
    #DynamicHelp::configure $itk_component(button) balloon -background blue -foreground white
}



body SampleVideoWidget::handleNewSampleCameraConstants { - targetStatus - contents_ -} {
    if {!$targetStatus} return

    if {$contents_ == ""} return

    foreach name $m_variableList {
        set index $m_indexMap($name)
        if {$index >= 0} {
            set value [lindex $contents_ $index]
            if {[string is double -strict $value]} {
                #puts "setting $name to $value"
                set $name $value
            }
        }
    }
    updateBeamPosition
}

body SampleVideoWidget::handleCameraZoom { - targetStatus - value_ -} {
    if { $targetStatus } {
        foreach { value units } $value_ break;
        set _cameraZoom $value
        updateBeamSize
        updateGrid
    }
}

body SampleVideoWidget::updateBeamPosition {} {
    # update the position of the crosshair
    set _crosshairX [expr $m_imageWidth * $_beamCenterH]
    set _crosshairY [expr $m_imageHeight * $_beamCenterV]

    if {$_crosshair != ""} {
        $_crosshair moveTo $_crosshairX $_crosshairY
    }
}

body SampleVideoWidget::updateBeamSize { } {
    if {[catch _internalUpdateBeamSize errMsg]} {
        log_error updateBeamSize failed: $errMsg
    }
}
body SampleVideoWidget::_internalUpdateBeamSize { } {
    ##### copied from operation moveSample
    set horzScale [expr $_zoomMinScale * \
    exp ( log ($_zoomMaxScale / $_zoomMinScale) * $_cameraZoom )]
    set vertScale [expr $horzScale * $_sampleAspectRatio]

    #### these scale factors are based on image size:
    #### _calibrationImageWidth
    #### _calibrationImageHeight
    #### Current image size: m_imageWidth m_imageHeight

    set image_scale [expr double($m_imageWidth) / $_calibrationImageWidth]

    set beamWidthPixel [expr $_beamSizeX * 1000.0 / $horzScale * $image_scale]
    set beamHeightPixel [expr $_beamSizeY * 1000.0 / $vertScale * $image_scale]

    if {$_crosshair != ""} {
        $_crosshair setBeamSize $beamWidthPixel $beamHeightPixel $_beamColor
    }
}

body SampleVideoWidget::updateGrid { } {
    set horzScale [expr $_zoomMinScale * \
    exp ( log ($_zoomMaxScale / $_zoomMinScale) * $_cameraZoom )]
    set vertScale [expr $horzScale * $_sampleAspectRatio]

    #### these scale factors are based on image size:
    #### _calibrationImageWidth
    #### _calibrationImageHeight
    #### Current image size: m_imageWidth m_imageHeight
    set image_scale [expr double($m_imageWidth) / $_calibrationImageWidth]

    foreach {hoff voff horz vert n_horz n_vert color} $m_gridInfo break

    set m_gridWidthOffsetPixel [expr 1.0 * $hoff / $horzScale * $image_scale]
    set gridHeightOffsetPixel  [expr 1.0 * $voff / $vertScale * $image_scale]
    set m_gridWidthPixel       [expr 1.0 * $horz / $horzScale * $image_scale]
    set gridHeightPixel        [expr 1.0 * $vert / $vertScale * $image_scale]

    $_crosshair setGrid \
    $m_gridWidthOffsetPixel $gridHeightOffsetPixel \
    $m_gridWidthPixel $gridHeightPixel $n_horz $n_vert $color
}


#testSamplePosition

class ComboSamplePositioningWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss

    itk_option define -forL614 forL614 ForL614 0

    itk_option define -useStepSize useStepSize UseStepSize $gVideoUseStep {
        if {$itk_option(-useStepSize)} {
            pack $itk_component(padStep) -side left
            grid $itk_component(inPadStep) -column 2 -row 2
            pack $itk_component(phiStep) -side left
            pack $itk_component(phiPlus) -side left
            pack $itk_component(phiMinus) -side left
        } else {
            pack forget $itk_component(padStep)
            grid forget $itk_component(inPadStep)
            pack forget $itk_component(phiStep)
            pack forget $itk_component(phiPlus)
            pack forget $itk_component(phiMinus)
        }
    }

    ### "sample" means sample camera only
    ### "inline" means inline camera only
    ### other means user selectable
    itk_option define -fixedView fixedView FixedView ""

    protected variable minimumHorzStep [expr 1.0/354]
    protected variable minimumVertStep [expr 1.0/240]

    public method addInputForRaster { input } {
        $itk_component(snapshot) addInput $input
        $itk_component(center) addInput $input
    }

    public method configSnapshotButton { args } {
        eval $itk_component(snapshot) configure $args
        pack $itk_component(snapshot) -before $itk_component(zoomLabel)
    }

    public method configCenterLoopButton { args } {
        eval $itk_component(center) configure $args
    }

    public method addChildVisibilityControl

    public method takeVideoSnapshot { }
    public method saveVideoSnapshot { filename }

    public method setGrid { hoff voff horz vert n_horz n_vert color } {
        $itk_component(video) setGrid $hoff $voff $horz $vert $n_horz $n_vert $color
    }


    public method getWrap { } {
        return $m_showingInlineViewWrap
    }

    private method getMoveOperation { } {
        if {[$m_showingInlineViewWrap getValue]} {
            set op $m_opInlineMove
        } else {
            set op $m_opMove
        }
        return $op
    }


    private method startStepMove { dir } {
        if {[$m_showingInlineViewWrap getValue]} {
            set camera inline
            set sign 1
        } else {
            set camera sample
            set sign -1
        }
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        switch -exact -- $dir {
            left {
                set horz [expr -1 * $sign * $stepSize]
                set vert 0
            }
            right {
                set horz [expr $sign * $stepSize]
                set vert 0
            }
            up {
                set horz 0
                set vert $stepSize
            }
            down {
                set horz 0
                set vert [expr -1 * $stepSize]
            }
            default {
                return
            }
        }
        $m_opStepMove startOperation $camera $horz $vert
    }
    public method startFocusMove { dir } {
        if {[$m_showingInlineViewWrap getValue]} {
            set camera inline
            set sign 1
        } else {
            set camera sample
            set sign -1
        }
        set stepSize [lindex [$itk_component(inPadStep) get] 0]
        if {$stepSize ==0} {
            return
        }
        set dd [expr $dir * $sign * $stepSize]
        $m_opStepFocus startOperation $camera $dd
    }

    public method padLeft { } {
        if {$itk_option(-useStepSize)} {
            startStepMove left
            return
        }
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by 0.8
        } else {
            [getMoveOperation] startOperation -$minimumHorzStep 0.0
        }
    }
    public method padRight { } {
        if {$itk_option(-useStepSize)} {
            startStepMove right
            return
        }
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by -0.8
        } else {
            [getMoveOperation] startOperation $minimumHorzStep 0.0
        }
    }
    public method padUp { } {
        if {$itk_option(-useStepSize)} {
            startStepMove up
            return
        }
        [getMoveOperation] startOperation 0.0 -$minimumVertStep
    }
    public method padDown { } {
        if {$itk_option(-useStepSize)} {
            startStepMove down
            return
        }
        [getMoveOperation] startOperation 0.0 $minimumVertStep
    }
    public method padFastLeft { } {
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by 11.2
        } else {
            [getMoveOperation] startOperation -0.5 0.0
        }
    }
    public method padFastRight { } {
        if {$itk_option(-forL614)} {
            $m_motorSampleZ move by -11.2
        } else {
            [getMoveOperation] startOperation 0.5 0.0
        }
    }

    public method centerCrystal { } {
        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set SID SID
        } else {
            set SID  PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        set dir  /data/$user/centerCrystal
        set fileRoot [::config getConfigRootName]
        $m_opCenterCrystal startOperation $user $SID $dir $fileRoot
    }
    public method handleCrystalEnabledEvent { stringName_ ready_ alias_ contents_ - } {
        if {!$ready_} return

        if {$contents_ == ""} {
            set contents_ 0
        }

        #####do not show this button for now
        #set contents_ 0

        if {$m_centerCrystalEnabled == $contents_} return
        set m_centerCrystalEnabled $contents_

        if {$m_centerCrystalEnabled} {
            pack $itk_component(crystal) -after $itk_component(center)
        } else {
            pack forget $itk_component(crystal)
        }
    }
    public method handleMicroCrystalEnabledEvent { stringName_ ready_ alias_ contents_ - } {
        if {!$ready_} return

        if {$contents_ == ""} {
            set contents_ 0
        }

        #####do not show this button for now
        #set contents_ 0

        if {$m_centerMicroCrystalEnabled == $contents_} return
        set m_centerMicroCrystalEnabled $contents_

        if {$m_centerMicroCrystalEnabled} {
            pack $itk_component(micro_crystal) -before $itk_component(snapshot)
        } else {
            pack forget $itk_component(micro_crystal)
        }
    }
    public method handleZoomSwitchEvent { - ready_ - pos - } {
        if {!$ready_} return

        updateUrl
    }

    public method switchView { } {
        set cur [$m_showingInlineViewWrap getValue]

        switch -exact -- $itk_option(-fixedView) {
            sample {
                set newV 0
            }
            inline {
                set newV 1
            }
            default {
                if {$cur} {
                    set newV 0
                } else {
                    set newV 1
                }
            }
        }
        $m_showingInlineViewWrap setValue $newV
        updateSwitchLabel
        updateUrl
    }

    public method switchToSampleView { } {
        if {[$m_showingInlineViewWrap getValue]} {
            $m_showingInlineViewWrap setValue 0
            updateSwitchLabel
            updateUrl
        }
    }

    public method setPadStep { s } {
        $itk_component(padStep) setValue $s 1
        $itk_component(inPadStep) setValue $s 1
    }

    public method rotatePhiStep { s } {
        set step [lindex [$itk_component(phiStep) get] 0]
        set step [expr ${s}1 * $step]

        $m_objPhi move by $step
    }

    private method updateUrl { }

    private method updateSwitchLabel { } {
        if {[$m_showingInlineViewWrap getValue]} {
            $itk_component(onAxis) configure \
            -text "Profile"
        } else {
            $itk_component(onAxis) configure \
            -text "On-Axis"
        }
    }

    private variable m_deviceFactory
    private variable m_motorSampleZ
    private variable m_opCenterCrystal
    private variable m_centerCrystalEnabled 0
    private variable m_centerMicroCrystalEnabled 0
    private variable m_strCenterCrystalConst
    private variable m_strCollimatorCenterCrystalConst
    private variable m_noInline 1
    private variable m_opMove
    private variable m_opInlineMove
    private variable m_mtZoomSwitch

    private variable m_opStepMove
    private variable m_opStepFocus ""
    private variable m_objPhi

    private variable m_showingInlineViewWrap ""

    private variable m_sampleSettings ""
    private variable m_inlineSettings ""

    private common PHI_BUTTON_STEP_SIZE [::config getInt "phiButtonStepSize" 10]

    # constructor
    constructor { sampleSet inlineSet args } {
        set m_showingInlineViewWrap [::DCS::ManualInputWrapper ::#auto]
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        if {[llength $sampleSet] < 5} {
            puts "software ERROR, please let programmer know"
            puts "wrong argument for ComboSampleVideo"
            exit
        }

        foreach {url paraName zoomName opNameCenterLoop opNameMoveSample} \
        $sampleSet break

        set m_sampleSettings [list $url $paraName $zoomName $opNameMoveSample]

        set m_opMove [$m_deviceFactory getObjectName $opNameMoveSample]
        set m_objPhi [$m_deviceFactory getObjectName gonio_phi]

        set m_opStepMove [$m_deviceFactory createOperation moveSampleOnVideo]
        set m_opStepFocus [$m_deviceFactory createOperation moveSampleOutVideo]

        if {[llength $inlineSet] >=2} {
            set m_noInline 0
            set m_mtZoomSwitch [$m_deviceFactory getObjectName zoomSwitch]

            foreach \
            {inlineUrl inlineParaName inlineZoomName inlineOpNameMoveSample} \
            $inlineSet break

            set m_inlineSettings [list \
            $inlineUrl $inlineParaName $inlineZoomName $inlineOpNameMoveSample]

            set m_opInlineMove \
            [$m_deviceFactory getObjectName $inlineOpNameMoveSample]
        }

        set m_strCenterCrystalConst \
        [$m_deviceFactory createString center_crystal_const]
        $m_strCenterCrystalConst createAttributeFromField system_on 0

        set m_strCollimatorCenterCrystalConst \
        [$m_deviceFactory createString collimator_center_crystal_const]
        $m_strCollimatorCenterCrystalConst createAttributeFromField system_on 0


        itk_component add control {
            frame $itk_interior.c
        }

        itk_component add zoomLabel {
            # create the camera zoom label
            label $itk_component(control).zoomLabel \
                 -text "Select Zoom Level" \
                 -font "helvetica -14 bold"
        }

        itk_component add zoomFrame {
            frame $itk_component(control).z
        }

        itk_component add zoomLow {
            # make the low zoom button
            DCS::MoveMotorsToTargetButton $itk_component(zoomFrame).zoomLow \
                 -text "Low" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {}


        itk_component add zoomMed {
            # make the medium zoom button
            DCS::MoveMotorsToTargetButton $itk_component(zoomFrame).zoomMed \
                 -text "Med" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {}

        itk_component add zoomHigh {
            # make the medium zoom button
            DCS::MoveMotorsToTargetButton  $itk_component(zoomFrame).zoomHigh \
                 -text "High" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff
        } {
        }
        itk_component add zoomMinus {
            DCS::MoveMotorRelativeButton $itk_component(zoomFrame).zoomMinus \
                 -delta -0.1 \
                 -text "-" \
                 -background #c0c0ff -activebackground #c0c0ff
        } {}
        itk_component add zoomPlus {
            DCS::MoveMotorRelativeButton $itk_component(zoomFrame).zoomPlus \
                 -delta 0.1 \
                 -text "+" \
                 -background #c0c0ff -activebackground #c0c0ff
        } {}

        itk_component add onAxis {
            button $itk_component(zoomFrame).onAxis \
            -command "$this switchView" \
            -width 7 \
            -background #c0c0ff \
            -activebackground #c0c0ff
        } {
        }

        itk_component add moveStepF {
            frame $itk_component(control).msf
        } {
        }
        set mstepSite $itk_component(moveStepF)
        itk_component add moveSampleLabel {
            # create the move sample label
            label $mstepSite.sampleLabel \
                 -text "Move Sample" \
                 -font "helvetica -14 bold"
        }

        set padStepChoices [::config getStr "arrowPadStepSize"]
        if {$padStepChoices == ""} {
            set padStepChoices "5 10 15 20 50 100 200"
        }

        itk_component add padStep {
            ::DCS::MenuEntry $mstepSite.padStep \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList um \
            -units um \
            -showUnits 1 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        pack $itk_component(moveSampleLabel) -side left

        #itk_component add moveSampleFrame {
        #    frame $itk_component(control).s
        #}

        # make joypad
        itk_component add arrowPad {
            DCS::ArrowPad $itk_component(control).ap \
                 -activeClientOnly 1 \
                 -debounceTime 100 -buttonBackground #c0c0ff
        } {
        }
        set padSite [$itk_component(arrowPad) getRing]

        itk_component add inPadStep {
            ::DCS::MenuEntry $padSite.padStep \
            -showArrow 0 \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices $padStepChoices \
            -showPrompt 0 \
            -showEntry 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -showUnits 0 \
            -onSubmit "$this setPadStep %s"
        } {
        }
        grid $itk_component(inPadStep) -column 2 -row 2

        set showFocusButton [::config getInt "bluice.showFocusButton" 0]
        if {$showFocusButton} {
            itk_component add focusIn {
                ::DCS::ArrowButton $padSite.focusIn far \
                -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove 1"
            } {
            }
            grid $itk_component(focusIn) -column 0 -row 0

            itk_component add focusOut {
                ::DCS::ArrowButton $padSite.focusOut near \
                -debounceTime 100  \
                -background #c0c0ff \
                -command "$this startFocusMove -1"
            } {
            }
            grid $itk_component(focusOut) -column 4 -row 0
        }

        itk_component add phiStepF {
            frame $itk_component(control).phiStepF
        } {
        }
        set pstepSite $itk_component(phiStepF)

        itk_component add phiLabel {
            # create the phi label
            label $pstepSite.phiLabel \
                 -text "Rotate Phi" \
                 -font "helvetica -14 bold"
        } {
        }
        pack $itk_component(phiLabel) -side left

        itk_component add phiStep {
            ::DCS::MenuEntry $pstepSite.phiStep \
            -leaveSubmit 1 \
            -decimalPlaces 1 \
            -menuChoices {20 30 40 45 50 60 70 80} \
            -showPrompt 0 \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 5 \
            -autoGenerateUnitsList 0 \
            -unitsList deg \
            -units deg \
            -showUnits 1 \
        } {
        }
        itk_component add phiPlus {
            ::DCS::ArrowButton $pstepSite.phiPlus plus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep +"
        } {
        }
        itk_component add phiMinus {
            ::DCS::ArrowButton $pstepSite.phiMinus minus \
            -debounceTime 100  \
            -background #c0c0ff \
            -command "$this rotatePhiStep -"
        } {
        }

        itk_component add phiFrame {
            frame $itk_component(control).p
        }

        itk_component add minus10 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).minus10 \
                 -delta "-$PHI_BUTTON_STEP_SIZE" \
                 -text "-$PHI_BUTTON_STEP_SIZE" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        itk_component add plus10 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus10 \
                 -delta "$PHI_BUTTON_STEP_SIZE" \
                 -text "+$PHI_BUTTON_STEP_SIZE" \
                 -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }


        # make the Phi -90 button
        itk_component add minus90 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).minus90 \
                 -delta "-90" \
                 -text "-90" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        # make the Phi +90 button
        itk_component add plus90 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus90 \
                 -delta "90" \
                 -text "+90" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }


        itk_component add plus180 {
            DCS::MoveMotorRelativeButton $itk_component(phiFrame).plus180 \
                 -delta "180" \
                 -text "+180" \
                 -width 2  -background #c0c0ff -activebackground #c0c0ff \
             -device ::device::gonio_phi
        } {
        }

        itk_component add center {
            ::DCS::Button $itk_component(control).center \
                 -text "Center Loop" \
                 -width 15 -activeClientOnly 1
        } {
        }
        itk_component add crystal {
            ::DCS::Button $itk_component(control).crystal \
                 -text "Center Crystal" \
                 -width 15 -activeClientOnly 1
        } {
        }
        itk_component add micro_crystal {
            ::DCS::Button $itk_component(control).micro_crystal \
                 -text "Center MicroCrystal" \
                 -width 15 -activeClientOnly 1
        } {
        }
        itk_component add snapshot {
            ::DCS::Button $itk_component(control).snapshot \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Video Snapshot" \
            -width 15 \
            -command "$this takeVideoSnapshot"
        } {
        }


        # create the video image of the sample
        itk_component add video {
            SampleVideoWidget $itk_interior.video \
        } {
            keep -purpose
            keep -mode
            keep -videoParameters
            keep -videoEnabled
            keep -beamWidthWidget
            keep -beamHeightWidget
            keep -packOption
            keep -beamMatchColor
        }

        # evaluate configuration parameters
        eval itk_initialize $args

        updateSwitchLabel
        updateUrl

        set centerLoopOperation [$m_deviceFactory getObjectName $opNameCenterLoop]
        $itk_component(center) configure -command "$centerLoopOperation startOperation"
        #$itk_component(center) addInput "::dataCollectionActive gateOutput 1 {Data Collection is in progress}"
        $itk_component(center) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(center) addInput "::device::getLoopTip status inactive {supporting device}"
        $itk_component(center) addInput "::device::gonio_phi status inactive {supporting device}"
        $itk_component(center) addInput "::device::camera_zoom status inactive {supporting device}"
        $itk_component(center) addInput "$m_showingInlineViewWrap value 0 {loop is too big for this camera}"

        set m_opCenterCrystal [$m_deviceFactory getObjectName centerCrystal]
                set m_motorSampleZ [$m_deviceFactory getObjectName sample_z]
        $itk_component(crystal)       configure -command "$this centerCrystal"
        $itk_component(micro_crystal) configure -command "$this centerMicroCrystal"

        $itk_component(arrowPad) configure \
             -leftCommand      "$this padLeft" \
             -upCommand        "$this padUp" \
             -downCommand      "$this padDown" \
             -rightCommand     "$this padRight" \
             -fastLeftCommand  "$this padFastLeft" \
             -fastRightCommand "$this padFastRight"

        $itk_component(arrowPad) addInput left "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput right "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastLeft "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastRight "::device::sample_z status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "::device::sample_y status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "::device::sample_y status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "::device::sample_x status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "::device::sample_x status inactive {supporting device}"

        $itk_component(arrowPad) addInput left "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput right "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastLeft "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput fastRight "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput up "$centerLoopOperation status inactive {supporting device}"
        $itk_component(arrowPad) addInput down "$centerLoopOperation status inactive {supporting device}"

        $itk_component(zoomLow) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(zoomMed) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(zoomHigh) addInput "$centerLoopOperation status inactive {supporting device}"

        $itk_component(minus10) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus10) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(minus90) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus90) addInput "$centerLoopOperation status inactive {supporting device}"
        $itk_component(plus180) addInput "$centerLoopOperation status inactive {supporting device}"

        #don't allow the sample to be centered while the sample is already moving
        $itk_component(center) addInput "::device::gonio_phi status inactive {supporting device}"
        $itk_component(video) addInput "::device::gonio_phi status inactive {supporting device}"

        #don't allow the sample to be centered while the sample is already moving
        $itk_component(center) addInput "::device::sample_x status inactive {supporting device}"
        $itk_component(center) addInput "::device::sample_y status inactive {supporting device}"
        $itk_component(center) addInput "::device::sample_z status inactive {supporting device}"

        #$itk_component(zoomLow) addMotor ::device::camera_zoom 0.0
        #$itk_component(zoomMed) addMotor ::device::camera_zoom 0.75
        #$itk_component(zoomHigh) addMotor ::device::camera_zoom 1.0

        # pack the components
      pack $itk_interior -expand yes -fill both
        pack $itk_component(control) -side left -anchor nw -ipadx 0 -padx 0
        pack $itk_component(video) -side left -expand yes -fill both -ipadx 0 -padx 0
        pack $itk_component(zoomLabel) -anchor n

        pack $itk_component(zoomFrame) -anchor n
        if {$itk_option(-useStepSize)} {
            pack $itk_component(zoomMinus) -side left
        }
        pack $itk_component(zoomLow) -side left
        pack $itk_component(zoomMed) -side left
        pack $itk_component(zoomHigh) -side left
        if {$itk_option(-useStepSize)} {
            pack $itk_component(zoomPlus) -side left
        }
        pack $itk_component(onAxis) -side left

        pack $itk_component(moveStepF) -anchor n
        pack $itk_component(arrowPad) -anchor n

        pack $itk_component(phiStepF) -anchor n
        pack $itk_component(phiFrame) -anchor n
        pack $itk_component(minus10) -side left
        pack $itk_component(plus10) -side left
        pack $itk_component(minus90) -side left
        pack $itk_component(plus90) -side left
        pack $itk_component(plus180) -side left

        if {$opNameCenterLoop != "not_available"} {
            pack $itk_component(center)
        }
        pack $itk_component(snapshot)
        #$itk_component(videoCanvas) configure -cursor "@crossfg.bmp crossbg.bmp  white red"
        $m_strCenterCrystalConst register $this system_on handleCrystalEnabledEvent
        $m_strCollimatorCenterCrystalConst register $this system_on handleMicroCrystalEnabledEvent

        #$m_mtZoomSwitch register $this scaledPosition handleZoomSwitchEvent

        switch -exact -- $itk_option(-fixedView) {
            sample {
                pack forget $itk_component(onAxis)
            }
            inline {
                $m_showingInlineViewWrap setValue 1
                updateSwitchLabel
                updateUrl
                pack forget $itk_component(onAxis)
            }
        }
        set minStep [::config getStr "arrowPadDefaultStepSize"]
        if {$minStep == ""} {
            set minStep [lindex $padStepChoices 0]
        }
        $itk_component(padStep) setValue $minStep
        $itk_component(phiStep) setValue 45.0
    }
    destructor {
        #$m_mtZoomSwitch unregister $this scaledPosition handleZoomSwitchEvent
        $m_strCenterCrystalConst unregister $this system_on handleCrystalEnabledEvent
        $m_strCollimatorCenterCrystalConst unregister $this system_on handleMicroCrystalEnabledEvent
    }
}

#thin wrapper for the video enable
body ComboSamplePositioningWidget::addChildVisibilityControl { args} {

    eval $itk_component(video) addChildVisibilityControl $args

}
body ComboSamplePositioningWidget::takeVideoSnapshot { } {
    set user [$itk_option(-controlSystem) getUser]

    ###try to get what's on the goniometer
    set hint ""
    if {[catch {
        set contents [::device::robot_status getContents]
        set sample [lindex $contents 15]
        if {[llength $sample] == 3} {
            foreach {cas row col} $sample break
            set hint "${cas}${col}${row}.jpg"
        }
    } errMsg]} {
        puts "trying to get hints for filename failed: $errMsg"
    }

    set types [list [list JPEG .jpg]]
    puts "hint: $hint"

    set fileName [tk_getSaveFile \
    -initialdir /data/$user \
    -filetypes $types \
    -defaultextension ".jpg" \
    -initialfile $hint
    ]

    if {$fileName == ""} return

    if {[catch {open $fileName w} ch]} {
        log_error failed to open file $fileName to write image: $ch
        return
    }
    if {[catch {
        fconfigure $ch -translation binary -encoding binary
        set data [$itk_component(video) getImageData]
        puts -nonewline $ch $data
    } errMsg]} {
        log_error failed to write image to the file $fileName: $errMsg
    }
    close $ch
    log_warning snapshot saved to $fileName
}
body ComboSamplePositioningWidget::saveVideoSnapshot { fileName } {
    if {$fileName == ""} return

    if {![$itk_component(video) visible]} {
        puts "skip save video to $fileName: not visible and not updating"
        return
    }

    if {[catch {open $fileName w} ch]} {
        log_error failed to open file $fileName to write image: $ch
        return
    }
    if {[catch {
        fconfigure $ch -translation binary -encoding binary
        set data [$itk_component(video) getImageData]
        puts -nonewline $ch $data
    } errMsg]} {
        log_error failed to write image to the file $fileName: $errMsg
    }
    close $ch
    log_warning snapshot saved to $fileName
}

body ComboSamplePositioningWidget::updateUrl { } {
    if {![$m_showingInlineViewWrap getValue]} {
        puts "trying to set to sample: $m_sampleSettings"
        $itk_component(video) config \
        -imageSettings $m_sampleSettings

        $itk_component(zoomLow)  removeMotor ::device::inline_camera_zoom 0.2
        $itk_component(zoomMed)  removeMotor ::device::inline_camera_zoom 0.75
        $itk_component(zoomHigh) removeMotor ::device::inline_camera_zoom 1.0

        $itk_component(zoomLow) addMotor ::device::camera_zoom 0.0
        $itk_component(zoomMed) addMotor ::device::camera_zoom 0.75
        $itk_component(zoomHigh) addMotor ::device::camera_zoom 1.0

        catch {
            $itk_component(zoomPlus)  configure -device ::device::camera_zoom
            $itk_component(zoomMinus) configure -device ::device::camera_zoom
        }
    } else {
        puts "trying to set to inlinle: $m_inlineSettings"
        $itk_component(video) config \
        -imageSettings $m_inlineSettings

        $itk_component(zoomLow)  removeMotor ::device::camera_zoom 0.0
        $itk_component(zoomMed)  removeMotor ::device::camera_zoom 0.75
        $itk_component(zoomHigh) removeMotor ::device::camera_zoom 1.0

        ### 06/13/12: inline camera off calibration, this is work around:
        ### disable low zoom.
        #$itk_component(zoomLow)  addMotor ::device::inline_camera_zoom 0.2
        set lowZoom 0.15
        set lowZoomFromCfg [::config getStr "bluice.zoomLowInline"]
        if {[string is double -strict $lowZoomFromCfg]} {
            set lowZoom $lowZoomFromCfg
        }
        $itk_component(zoomLow)  addMotor ::device::inline_camera_zoom $lowZoom

        $itk_component(zoomMed)  addMotor ::device::inline_camera_zoom 0.75
        $itk_component(zoomHigh) addMotor ::device::inline_camera_zoom 1.0

        $itk_component(zoomPlus)  configure -device ::device::inline_camera_zoom
        $itk_component(zoomMinus) configure -device ::device::inline_camera_zoom
    }
}

