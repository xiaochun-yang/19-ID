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

package provide BLUICEVideoNotebook 1.0

package require DCSTabNotebook
package require BLUICESamplePosition
package require BLUICEResolution
package require BLUICEStatusBar
package require BLUICELightControl
package require BLUICEDiffImageViewer
package require VisexView

class DCS::BeamlineVideoNotebook {
     inherit ::itk::Widget

    ###### define all options here so we can enable/disable tabs
    itk_option define -imageUrl2 imageUrl2 ImageUrl2 ""
    itk_option define -textUrl2 textUrl2 TextUrl2 ""
    itk_option define -presetUrl2 presetUrl2 PresetUrl2 "" 
    itk_option define -moveRequestUrl2 moveRequestUrl2 MoveRequestUrl2 ""
    itk_option define -channelArgs2 channelArgs2 ChannelArgs2 ""

    itk_option define -imageUrl3 imageUrl3 ImageUrl3 ""
    itk_option define -textUrl3 textUrl3 TextUrl3 ""
    itk_option define -presetUrl3 presetUrl3 PresetUrl3 "" 
    itk_option define -moveRequestUrl3 moveRequestUrl3 MoveRequestUrl3 ""
    itk_option define -channelArgs3 channelArgs3 ChannelArgs3 ""

    itk_option define -imageUrl4 imageUrl4 ImageUrl4 ""
    itk_option define -textUrl4 textUrl4 TextUrl4 ""
    itk_option define -presetUrl4 presetUrl4 PresetUrl4 "" 
    itk_option define -moveRequestUrl4 moveRequestUrl4 MoveRequestUrl4 ""
    itk_option define -channelArgs4 channelArgs4 ChannelArgs4 ""

    ### hold index before we switch to diffImageViewer
    private variable m_previousIndex -1

    private variable m_sample_id
    private variable m_inline_id
    #### COMBO_SAMPLE_ONLY and COMBO_INLINE_ONLY are for special purpose.
    #### They are used in Crystal Rastering.
    private variable m_supportedList \
    [list Combo Sample Emission Hutch Robot Panel Diffraction \
    COMBO_SAMPLE_ONLY COMBO_INLINE_ONLY COMBO_INLINE_H_ONLY]
    private variable m_enabledList [list Sample Hutch Robot Panel Diffraction]

    public method selectView { index } {
        $itk_component(notebook) select $index
    }

    public method getSampleVideo { } {
        return $itk_component(sampleWidget)
    }

    public method getInlineVideo { } {
        return $itk_component(inlineWidget)
    }
    public method showDiffractionImage { path } {
        set index [lsearch -exact $m_enabledList Diffraction]
        if {$index < 0} {
            return
        }
        $itk_component(notebook) select $index
        $itk_component(diff_viewer) showFile $path
    }

    ### this and goBackToPreviousTab are paired
    public method unPauseDiffractionImageViwer { } {
        set index [lsearch -exact $m_enabledList Diffraction]
        if {$index < 0} {
            return
        }
        set m_previousIndex [$itk_component(notebook) index select]
        puts "previous index=$m_previousIndex for $this"
        $itk_component(diff_viewer) unPause
        $itk_component(notebook) select $index
    }
    public method goBackToPreviousTab { } {
        set index [lsearch -exact $m_enabledList Diffraction]
        set currentIndex [$itk_component(notebook) index select]

        if {$m_previousIndex >= 0 \
        && $index == $currentIndex \
        && ![$itk_component(diff_viewer) isPaused]} {
            $itk_component(notebook) select $m_previousIndex
        }
        set m_previousIndex -1
    }

    public method getDiffractionImageViewer { } {
        return $itk_component(diff_viewer)
    }

    ### to keep the light control just under the sample video
    public method handleResize { winID width height } {
        if {$winID != $m_sample_id} return
        if {[lsearch -exact $m_enabledList Sample] < 0 && \
        [lsearch -exact $m_enabledList Combo] < 0 && \
        [lsearch -exact $m_enabledList COMBO_INLINE_ONLY] < 0 && \
	[lsearch -exact $m_enabledList COMBO_INLINE_H_ONLY] < 0 && \
        [lsearch -exact $m_enabledList COMBO_SAMPLE_ONLY] \
        } {
            return
        }

        set req_v_w [winfo reqwidth $itk_component(sampleWidget)]
        set req_v_h [winfo reqheight $itk_component(sampleWidget)]
        set req_l_h [winfo reqheight $itk_component(light_control)]
        puts "v resize: $width $height req : $req_v_w $req_v_h"

        ############## decide the height of sampleWidget #########
        set height_available [expr $height - $req_l_h]
        if {$height_available < 0} {
            set height_available 0
        }
        set h_from_h $height_available
        puts "from height: $h_from_h"

        set h_from_w [expr $width * $req_v_h / $req_v_w]
        puts "from width $h_from_w"

        ## 240 is from observation to show the video snapshot button
        if {$h_from_h > $h_from_w} {
            if {$h_from_w < 240 && $h_from_h > 240} {
                set h_from_h 240
            } else {
                set h_from_h $h_from_w
            }
        }

        if {$h_from_h > 0} {
            place $itk_component(sampleWidget) \
            -x 0 \
            -y 0 \
            -width $width \
            -height $h_from_h
        }

        puts "place light control at 0, $h_from_h"
        place $itk_component(light_control) \
        -x 0 \
        -y $h_from_h \
        -width $width
    }

    public method handleInlineResize { winID width height } {
        if {$winID != $m_inline_id} return
#yangx modified below
        if {[lsearch -exact $m_enabledList COMBO_INLINE_ONLY] >= 0} {
        	set req_v_w [winfo reqwidth $itk_component(inlineWidget)]
        	set req_v_h [winfo reqheight $itk_component(inlineWidget)]
       		set req_l_h [winfo reqheight $itk_component(inline_light_control)]
	} else {
		return 
	}
	if {[lsearch -exact $m_enabledList COMBO_INLINE_H_ONLY] >= 0} {
        	set req_v_w [winfo reqwidth $itk_component(inlineWidget_h)]
        	set req_v_h [winfo reqheight $itk_component(inlineWidget_h)]
       		set req_l_h [winfo reqheight $itk_component(inline_light_control_h)]
	} else {
		return 
	}
        
        puts "v resize: $width $height req : $req_v_w $req_v_h"

        ############## decide the height of sampleWidget #########
        set height_available [expr $height - $req_l_h]
        if {$height_available < 0} {
            set height_available 0
        }
        set h_from_h $height_available
        puts "from height: $h_from_h"

        set h_from_w [expr $width * $req_v_h / $req_v_w]
        puts "from width $h_from_w"

        ## 240 is from observation to show the video snapshot button
        if {$h_from_h > $h_from_w} {
            if {$h_from_w < 240 && $h_from_h > 240} {
                set h_from_h 240
            } else {
                set h_from_h $h_from_w
            }
        }
	if {[lsearch -exact $m_enabledList COMBO_INLINE_ONLY] >= 0} {
        	if {$h_from_h > 0} {
            		place $itk_component(inlineWidget) \
            		-x 0 \
            		-y 0 \
            		-width $width \
            		-height $h_from_h
        	}
       		 puts "place light control at 0, $h_from_h"
       		 place $itk_component(inline_light_control) \
        		-x 0 \
        		-y $h_from_h \
        		-width $width
	}
	if {[lsearch -exact $m_enabledList COMBO_INLINE_H_ONLY] >= 0} {
        	if {$h_from_h > 0} {
            		place $itk_component(inlineWidget_h) \
            		-x 0 \
            		-y 0 \
            		-width $width \
            		-height $h_from_h
        	}
       		 puts "place light control at 0, $h_from_h"
       		 place $itk_component(inline_light_control_h) \
        		-x 0 \
        		-y $h_from_h \
        		-width $width
	}
    }
    public method addChildVisibilityControl

    private method createComboTab { nb }
    private method createSampleTab { nb }
    private method createEmissionTab { nb }
    private method createHutchTab { nb }
    private method createRobotTab { nb }
    private method createPanelTab { nb }
    private method createDiffractionTab { nb }
    private method createCOMBO_INLINE_ONLYTab { nb }
    private method createCOMBO_INLINE_H_ONLYTab { nb }
    private method createCOMBO_SAMPLE_ONLYTab { nb }

    constructor { subset args } {
        global env

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add notebook {
            DCS::TabNotebook $itk_component(ring).n \
                 -tabbackground lightgrey \
                 -background lightgrey \
                 -backdrop lightgrey \
                 -borderwidth 2\
                 -tabpos n \
                 -gap -4 \
                 -angle 20 \
                 -width 490 \
                 -height 370 \
                 -raiseselect 1 \
                 -bevelamount 4 \
                 -equaltabs 0 \
                 -padx 5 -pady 4
        } {
        }

        if {$subset == ""} {
            set cfgTabList [::config getStr bluice.videoTabList]
            if {$cfgTabList != ""} {
                set m_enabledList $cfgTabList
                puts "VideoTabList: $m_enabledList"
            }
        } else {
            set m_enabledList $subset
        }

        foreach tt $m_enabledList {
            if {[lsearch -exact $m_supportedList $tt] >= 0} {
                create${tt}Tab $itk_component(notebook)
            } else {
                puts "Tab {$tt} not in supported list {$m_supportedList}"
            }
        }

        # select the sample position tab first
        $itk_component(notebook) select 0

        pack $itk_component(notebook) -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both

        catch {eval itk_initialize $args}

        ::mediator announceExistence $this

        set matchColor [::config getStr "bluice.beamMatchColor"]
        if {$matchColor != ""} {
            configure -beamMatchColor $matchColor
        }
    }
}


#thin wrapper for the video enable based on visibility
body DCS::BeamlineVideoNotebook::addChildVisibilityControl { args} {
    eval $itk_component(notebook) addChildVisibilityControl $args
}

body DCS::BeamlineVideoNotebook::createComboTab { nb } {
    puts "adding Combo: Sample+Inline"

    # construct the sample position widgets
    set sampleSite [$nb add Sample -label "Sample"]
        
    itk_component add sampleWidget {
        ComboSamplePositioningWidget $sampleSite.s \
        "[::config getImageUrl 1] sample_camera_constant camera_zoom centerLoop moveSample" \
        "[::config getImageUrl 5] inline_sample_camera_constant inline_camera_zoom inlineMoveSample" \
    } {
        keep -purpose
        keep -mode
        keep -videoParameters
        keep -videoEnabled
        keep -beamWidthWidget
        keep -beamHeightWidget
        keep -packOption
        keep -useStepSize
        keep -forL614
        keep -beamMatchColor
    }

    set wrap [$itk_component(sampleWidget) getWrap]

    itk_component add light_control {
        ComboLightControlWidget $sampleSite.light \
        -switchWrap $wrap
    } { 
    }

    $itk_component(sampleWidget) addChildVisibilityControl $nb activeTab Sample
    pack $itk_component(sampleWidget) -expand 1 -fill both

    set m_sample_id $sampleSite
    bind $m_sample_id <Configure> "$this handleResize %W %w %h"
}

body DCS::BeamlineVideoNotebook::createCOMBO_INLINE_ONLYTab { nb } {
    puts "adding Combo: Inline alone"

    # construct the sample position widgets
    set sampleSite [$nb add Inline -label "Sample-Low-Mag"]
        
    itk_component add inlineWidget {
        ComboSamplePositioningWidget $sampleSite.s \
        "[::config getImageUrl 1] sample_camera_constant camera_zoom centerLoop inlineMoveSample" \
        "[::config getImageUrl 5] inline_sample_camera_constant inline_camera_zoom inlineMoveSample" \
        -fixedView inline \
    } {
        keep -purpose
        keep -mode
        keep -videoParameters
        keep -videoEnabled
        keep -beamWidthWidget
        keep -beamHeightWidget
        keep -packOption
        keep -useStepSize
        keep -forL614
        keep -beamMatchColor
    }

    set wrap [$itk_component(inlineWidget) getWrap]

    set className [::config getStr bluice.lightClass]
    if {$className == ""} {
        set className ComboLightControlWidget
    }
    itk_component add inline_light_control {
        $className $sampleSite.light \
        -switchWrap $wrap
    } { 
    }

    $itk_component(inlineWidget) addChildVisibilityControl $nb activeTab Inline
    pack $itk_component(inlineWidget) -expand 1 -fill both

    set m_inline_id $sampleSite
    bind $m_inline_id <Configure> "$this handleInlineResize %W %w %h"
}

#yangx add high resolution camera 
body DCS::BeamlineVideoNotebook::createCOMBO_INLINE_H_ONLYTab { nb } {
    puts "adding Combo: Inline alone"

    # construct the sample position widgets
    set sampleSite [$nb add Inline -label "Sample-Hi-Mag"]

    itk_component add inlineWidget_h {
        ComboSamplePositioningWidget $sampleSite.s \
        "[::config getImageUrl 1] sample_camera_constant camera_zoom centerLoop inlineMoveSample" \
        "[::config getImageUrl 6] inline_sample_camera_h_constant inline_camera_zoom_h inlineMoveSample" \
        -fixedView inline \
    } {
        keep -purpose
        keep -mode
        keep -videoParameters
        keep -videoEnabled
        keep -beamWidthWidget
        keep -beamHeightWidget
        keep -packOption
        keep -useStepSize
        keep -forL614
        keep -beamMatchColor
    }

    set wrap [$itk_component(inlineWidget_h) getWrap]

    set className [::config getStr bluice.lightClass]
    if {$className == ""} {
        set className ComboLightControlWidget
    }
    itk_component add inline_light_control_h {
        $className $sampleSite.light \
        -switchWrap $wrap
    } {
    }

    $itk_component(inlineWidget_h) addChildVisibilityControl $nb activeTab Inline
    pack $itk_component(inlineWidget_h) -expand 1 -fill both

    set m_inline_id $sampleSite
    bind $m_inline_id <Configure> "$this handleInlineResize %W %w %h"
}

body DCS::BeamlineVideoNotebook::createCOMBO_SAMPLE_ONLYTab { nb } {
    puts "adding Combo: Inline alone"

#yangx add
    #puts "yangx move gonio omega to 90"
    #::device::gonio_omega move to 90 deg

    # construct the sample position widgets
    set sampleSite [$nb add Sample -label "Sample OnAxis"]
        
    itk_component add sampleWidget {
        ComboSamplePositioningWidget $sampleSite.s \
        "[::config getImageUrl 1] sample_camera_constant camera_zoom centerLoop inlineMoveSample" \
        "[::config getImageUrl 5] inline_sample_camera_constant inline_camera_zoom inlineMoveSample" \
        -fixedView sample \
    } {
        keep -purpose
        keep -mode
        keep -videoParameters
        keep -videoEnabled
        keep -beamWidthWidget
        keep -beamHeightWidget
        keep -packOption
        keep -useStepSize
        keep -forL614
        keep -beamMatchColor
    }

    set wrap [$itk_component(sampleWidget) getWrap]

    set className [::config getStr bluice.lightClass]
    if {$className == ""} {
        set className ComboLightControlWidget
    }
   itk_component add light_control {
        $className $sampleSite.light \
        -switchWrap $wrap
    } { 
    }

    $itk_component(sampleWidget) addChildVisibilityControl $nb activeTab Sample
    pack $itk_component(sampleWidget) -expand 1 -fill both

    set m_sample_id $sampleSite
    bind $m_sample_id <Configure> "$this handleResize %W %w %h"
}

body DCS::BeamlineVideoNotebook::createSampleTab { nb } {
    puts "adding Sample"

    # construct the sample position widgets
    set sampleSite [$nb add Sample -label "Sample"]
        
    itk_component add sampleWidget {
        SamplePositioningWidget $sampleSite.s \
        [::config getImageUrl 1] \
        sample_camera_constant camera_zoom centerLoop moveSample
    } {
        keep -purpose
        keep -mode
        keep -videoParameters
        keep -videoEnabled
        keep -beamWidthWidget
        keep -beamHeightWidget
        keep -packOption
        keep -useStepSize
        keep -beamMatchColor
    }

    itk_component add light_control {
        LightControlWidget $sampleSite.light
    } { 
    }

    $itk_component(sampleWidget) addChildVisibilityControl $nb activeTab Sample
    pack $itk_component(sampleWidget) -expand 1 -fill both

    set m_sample_id $sampleSite
    bind $m_sample_id <Configure> "$this handleResize %W %w %h"
}
body DCS::BeamlineVideoNotebook::createHutchTab { nb } {
    global gMotorDistance
    global gMotorVert
    global gMotorHorz

    set hutchSite [$nb add Hutch -label "Hutch"]

    itk_component add hutchWidget {
        DCS::PresetVideoWidget $hutchSite.h  -entryWidth 12
    } {
        rename -imageUrl -imageUrl2 imageUrl2 ImageUrl2 
        rename -textUrl -textUrl2 textUrl2 TextUrl2 
        rename -presetUrl -presetUrl2 presetUrl2 PresetUrl2 
        rename -moveRequestUrl -moveRequestUrl2 moveRequestUrl2 MoveRequestUrl2
        rename -channelArgs -channelArgs2 channelArgs2 ChannelArgs2
        keep -videoParameters
        keep -videoEnabled
        keep -activeClientOnly
    }

    $itk_component(hutchWidget) addChildVisibilityControl $nb activeTab Hutch
    pack $itk_component(hutchWidget) -expand 1 -fill both

    $itk_component(hutchWidget) addUpdateSpeedInput "::device::$gMotorHorz status moving {detector_horz is moving}"
    $itk_component(hutchWidget) addUpdateSpeedInput "::device::$gMotorVert status moving {detector_vert is moving}"
    $itk_component(hutchWidget) addUpdateSpeedInput "::device::$gMotorDistance status moving {detector_z is moving}"
}

body DCS::BeamlineVideoNotebook::createRobotTab { nb } {
    set robotSite [$nb add Hutch2 -label "Robot"]

    itk_component add hutch2Widget {
        DCS::PresetVideoWidget $robotSite.r  -entryWidth 12
    } {
        rename -imageUrl -imageUrl3 imageUrl3 ImageUrl3 
        rename -textUrl -textUrl3 textUrl3 TextUrl3 
        rename -presetUrl -presetUrl3 presetUrl3 PresetUrl3 
        rename -moveRequestUrl -moveRequestUrl3 moveRequestUrl3 MoveRequestUrl3
        rename -channelArgs -channelArgs3 channelArgs3 ChannelArgs3
        keep -videoParameters
        keep -videoEnabled
        keep -activeClientOnly
    }

    #$itk_component(hutch2Widget) addExtraWidget SimpleRobotWidget -orientation vert

    $itk_component(hutch2Widget) addChildVisibilityControl $nb activeTab Hutch2
    pack $itk_component(hutch2Widget) -expand 1 -fill both
}
body DCS::BeamlineVideoNotebook::createPanelTab { nb } {
    set panelSite [$nb add ControlPanel -label "Panel"]

    itk_component add controlWidget {
        DCS::PresetVideoWidget $panelSite.c -entryWidth 12
    } {
        rename -imageUrl -imageUrl4 imageUrl4 ImageUrl4 
        rename -textUrl -textUrl4 textUrl4 TextUrl4 
        rename -presetUrl -presetUrl4 presetUrl4 PresetUrl4 
        rename -moveRequestUrl -moveRequestUrl4 moveRequestUrl4 MoveRequestUrl4
        rename -channelArgs -channelArgs4 channelArgs4 ChannelArgs4
        keep -videoParameters
        keep -videoEnabled
        keep -activeClientOnly
    }

    $itk_component(controlWidget) addChildVisibilityControl $nb activeTab ControlPanel 
    pack $itk_component(controlWidget) -expand 1 -fill both
}
body DCS::BeamlineVideoNotebook::createDiffractionTab { nb } {
    set diffSite [$nb add DiffView -label "Diffraction"]
    itk_component add diff_viewer {
        DiffImageViewer $diffSite.d \
        -orientation landscape \
        -imageServerHost [::config getImgsrvHost] \
        -imageServerHttpPort [::config getImgsrvHttpPort] \
    } {
        keep -brightness
        keep -showPause
    }

    pack $itk_component(diff_viewer) -expand 1 -fill both
}
body DCS::BeamlineVideoNotebook::createEmissionTab { nb } {
    set eSite [$nb add EmissionView -label "Emission"]
    itk_component add emission_view {
        VisexUserView $eSite.e sample 1
    } {
        keep -packOption
    }
    pack $itk_component(emission_view) -expand 1 -fill both
}
proc startBeamlineVideoNotebook { configuration_ } {
    
    wm title . "Video for beamline [$configuration_ getConfigRootName]"
    wm resizable . 0 1
    wm maxsize . 600 400
    wm minsize . 400 280

    DCS::BeamlineVideoNotebook .v "" \
         -imageUrl2 [$configuration_ getImageUrl 2] \
         -imageUrl3 [$configuration_ getImageUrl 3] \
         -imageUrl4 [$configuration_ getImageUrl 4] \
         -textUrl2 [$configuration_ getTextUrl 2] \
         -textUrl3 [$configuration_ getTextUrl 3] \
         -textUrl4 [$configuration_ getTextUrl 4] \
         -presetUrl2 [$configuration_ getPresetUrl 2] \
         -presetUrl3 [$configuration_ getPresetUrl 3] \
         -presetUrl4 [$configuration_ getPresetUrl 4] \
         -moveRequestUrl2 [$configuration_ getMoveRequestUrl 2] \
         -moveRequestUrl3 [$configuration_ getMoveRequestUrl 3] \
         -moveRequestUrl4 [$configuration_ getMoveRequestUrl 4] \
         -channelArgs2 [$configuration_ getVideoArgs 2] \
         -channelArgs3 [$configuration_ getVideoArgs 3] \
         -channelArgs4 [$configuration_ getVideoArgs 4] \
         -videoEnabled 1 \
         -videoParameters &resolution=high -activeClientOnly 0
    

    StatusBar .activeButton
    ::dcss configure -forcedLoginCallback ".activeButton getLogin"

    pack .v
    pack .activeButton
}

#testBeamlineVideoNotebook


