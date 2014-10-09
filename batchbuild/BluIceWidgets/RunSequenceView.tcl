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


package provide BLUICERunSequenceView 1.0

# load standard packages
package require Iwidgets

package require DCSRunSequenceCalculator
package require DCSRunCalculatorForGridCrystal

class DCS::RunSequenceView {
 	inherit ::itk::Widget DCS::Component

	itk_option define -runViewWidget runView RunViewWidget "" 

    itk_option define -purpose purpose Purpose forCollect {
        if {$_runCalculator != ""} {
            delete object $_runCalculator
        }
        switch -exact -- $itk_option(-purpose) {
            forGrid {
		        set _runCalculator [DCS::RunCalculatorForGridCrystal #auto]
                gCurrentGridGroup register $this current_grid_frame_list \
                handleGridUpdate

                set m_registeredGrid 1
            }
            forQueue {
		        set _runCalculator [DCS::RunSequenceCalculatorForQueue #auto]
            }
            forCollect -
            default {
		        set _runCalculator [DCS::RunSequenceCalculator #auto]
            }
        }
    }

	private variable _runCalculator ""
	private variable _runIndex 0
	private variable _pageSize 10

	public variable font *-courier-bold-r-normal--12-*-*-*-*-*-*-*
	public variable _collectedFrameColor grey50 
	public variable _collectingFrameColor red
	public variable _uncollectedFrameColor black
	public variable _width 15
	public variable _snapShotView 0
    private variable m_showRunTimer 0

    private variable m_objRunTime ""
    private variable m_objCollectConfig ""
    private variable m_objEnergy ""
    private variable m_objGridGroupConfig ""

    private variable m_registeredGrid 0
	
	public method changeView
	public method fillViewer
	public method restoreColors
	public method focusOnCurrentFrame {}
	public method handleDoubleClick
    public method showSnapShot {}
    public method showNoCrystal {}
	private method verifyRunIndex {}
	private method insertFrame {textIndex frameIndex}

   private variable m_lastRunDef ""
   public method handleRunDefinitionPtrChange 
   public method handleRunDefinitionChange 
   public method handleGridUpdate 

   public method handleCollectConfigChange 

	constructor { args} {
		
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objGridGroupConfig \
        [$deviceFactory createOperation gridGroupConfig]

        set m_objEnergy [$deviceFactory getObjectName energy]
        set m_objCollectConfig [$deviceFactory createString collect_config]
        if {[$deviceFactory stringExists run_time_estimates]} {
            set m_showRunTimer 1
            puts "enable showRunTimer and create attributes"
            set m_objRunTime [$deviceFactory getObjectName run_time_estimates]
            $m_objRunTime createAttributeFromField run0 0
            $m_objRunTime createAttributeFromField run1 1
            $m_objRunTime createAttributeFromField run2 2
            $m_objRunTime createAttributeFromField run3 3
            $m_objRunTime createAttributeFromField run4 4
            $m_objRunTime createAttributeFromField run5 5
            $m_objRunTime createAttributeFromField run6 6
            $m_objRunTime createAttributeFromField run7 7
            $m_objRunTime createAttributeFromField run8 8
            $m_objRunTime createAttributeFromField run9 9
            $m_objRunTime createAttributeFromField run10 10
            $m_objRunTime createAttributeFromField run11 11
            $m_objRunTime createAttributeFromField run12 12
            $m_objRunTime createAttributeFromField run13 13
            $m_objRunTime createAttributeFromField run14 14
            $m_objRunTime createAttributeFromField run15 15
            $m_objRunTime createAttributeFromField run16 16
        }

        itk_component add runTime {
            DCS::Entry $itk_interior.runTime \
                 -state labeled \
                 -promptText "Run Time:" \
                 -entryWidth 10     \
                 -shadowReference 1 \
                 -entryJustify right \
        } {}

		itk_component add ring {
         frame $itk_interior.r
      } {}

      set ring $itk_component(ring)
		
      itk_component add textWidget {
         text $ring.text -wrap none -width $_width \
            -cursor hand2 -state normal \
            -background gray80 -selectbackground gray80
      } {}

		# create the widgets
      itk_component add textScrollY {
         scrollbar $ring.yscroll -orient vertical
      } {}

      itk_component add textScrollX {
         scrollbar $ring.xscroll -orient horizontal
      } {}

		#let the scroll bar widgets know what protocol to use.
		$itk_component(textScrollY) set 0.0 1.0
		$itk_component(textScrollX) set 0.0 1.0

		bind $itk_component(textWidget) <Configure> "$this fillViewer"
		bind $itk_component(textWidget) <Button-1> {}
		bind $itk_component(textWidget) <Double-Button-1> {}
		
		set _runCalculator [DCS::RunSequenceCalculator #auto]

      #bind the widgets to each other
      $itk_component(textWidget) configure -xscrollcommand [list $itk_component(textScrollX) set] 
      $itk_component(textScrollY) configure -command [list $this changeView] 
      $itk_component(textScrollX) configure -command [list $itk_component(textWidget) xview] 

      eval itk_initialize $args

		#pack the internal widgets
		pack $itk_component(textScrollY) -side right -fill y
		pack $itk_component(textScrollX) -side bottom -fill x
		pack $itk_component(textWidget) -side left -fill both -expand true
		grid $itk_component(ring) -row 0 -column 0 -sticky news

        grid rowconfig $itk_interior 0 -weight 10
        grid columnconfig $itk_interior 0 -weight 10

      announceExist

        $m_objCollectConfig register $this contents handleCollectConfigChange
	}
    destructor {
        $m_objCollectConfig unregister $this contents handleCollectConfigChange
        if {$m_registeredGrid} {
            gCurrentGridGroup unregister $this current_grid_frame_list \
            handleGridUpdate
        }
        if {$_runCalculator != ""} {
            delete object $_runCalculator
        }
    }
}

body DCS::RunSequenceView::handleCollectConfigChange { - targetReady_ - contents_ -  } {
   if { !$targetReady_ } return

    set enabled [lindex $contents_ 7]
    if {$enabled == ""} {
        set enabled 0
    }

    set deviceFactory [DCS::DeviceFactory::getObject]
    if {[$deviceFactory stringExists run_time_estimates] && \
    $enabled} {
        set m_showRunTimer 1
    } else {
        set m_showRunTimer 0
    }
    if {$itk_option(-purpose) == "forQueue"} {
        set m_showRunTimer 0
    }
}

#This method changes our target widget that we are observing, which is also observing a run definition.
configbody DCS::RunSequenceView::runViewWidget {
   
   if { $itk_option(-runViewWidget) != "" } {
      #We want to know when the widget we are observing starts looking at a different run definition.
      ::mediator register $this ::$itk_option(-runViewWidget) runDefinition handleRunDefinitionPtrChange
   }
}


body DCS::RunSequenceView::handleRunDefinitionPtrChange { run_ targetReady_ alias_ runDefinitionPtr_ -  } {

   if { !$targetReady_ } return

   #This method handles the case where the target widget looks at a different run.
   #This widget will start looking at the new run definition also.

   if {$m_lastRunDef != "" } {
      ::mediator unregister $this $m_lastRunDef contents
   }
  
   set m_lastRunDef $runDefinitionPtr_

   ::mediator register $this $runDefinitionPtr_ contents handleRunDefinitionChange

}

body DCS::RunSequenceView::handleRunDefinitionChange { run_ targetReady_ alias_ runDefinition_ -  } {
   #this method is called when the run definition that we are observing changes.
    puts "handle Run Def change: {$runDefinition_}"

	if { ! $targetReady_} return

	$_runCalculator updateRunDefinition $runDefinition_

    if {$itk_option(-purpose) == "forQueue"} {
        set run -1
        set m_showRunTimer 0
    } else {
        set run [$m_lastRunDef getRunIndex]
    }

	if { $run == 0 } {
		#show one frame only
		configure -_snapShotView 1
	} else {
		configure -_snapShotView 0
	}
    if {$m_showRunTimer} {
        if {$run != 0 } {
            grid $itk_component(runTime) -row 1 -column 0 -sticky we
            $itk_component(runTime) configure \
            -reference "$m_objRunTime run$run"
        } else {
            grid forget $itk_component(runTime)
        }
    } else {
        grid forget $itk_component(runTime)
    }

	
	#show the current frame
	focusOnCurrentFrame
}

body DCS::RunSequenceView::handleGridUpdate {- targetReady_ - dContents_ - } {
	if {!$targetReady_} return
    if {$itk_option(-purpose) != "forGrid"} return
    if {$dContents_ == ""} {
        showNoCrystal
        return
    }

    if {![dict exists $dContents_ energy_list]} {
        set e [$m_objEnergy cget -scaledPosition]
        dict set dContents_ energy_list $e
    } else {
        set eList [dict get $dContents_ energy_list]
        if {[llength $eList] == 0} {
            set e [$m_objEnergy cget -scaledPosition]
            dict set dContents_ energy_list $e
        }
    }

	if {[catch {$_runCalculator update $dContents_} errMsg]} {
        log_error update faile: $errMsg
        puts "dContents_=$dContents_"
        showNoCrystal
        return
    }

    set run -1

    configure -_snapShotView 0
    grid forget $itk_component(runTime)

	
	#show the current frame
	focusOnCurrentFrame
}

body DCS::RunSequenceView::focusOnCurrentFrame {} {

	set nextFrame [$_runCalculator getField next_frame]
	set _runIndex [expr int( $nextFrame - $_pageSize / 2)]

	fillViewer
}


#######################################################
#
######################################################
body DCS::RunSequenceView::verifyRunIndex {} {

	set totalFrames [$_runCalculator getTotalFrames]	
	
	#limit the runIndex to possible frames
	if { $_runIndex < 0} {
		set _runIndex 0
	}
	if { $_runIndex > $totalFrames} {
		set _runIndex $totalFrames
	}
}



#######################################################
#
######################################################
body DCS::RunSequenceView::showSnapShot {} {

	#erase what is currently in the text box.
	$itk_component(textWidget) configure -state normal
	$itk_component(textWidget) delete 1.0 end
	$itk_component(textWidget) insert end "[$_runCalculator getMotorPositionsAtIndex 0]\n" "collectingFrameTag"
	restoreColors


	$itk_component(textWidget) configure -state disabled
}

body DCS::RunSequenceView::showNoCrystal {} {

	#erase what is currently in the text box.
	$itk_component(textWidget) configure -state normal
	$itk_component(textWidget) delete 1.0 end
	$itk_component(textWidget) insert end "Create or select a crystal first\n" "collectingFrameTag"
	restoreColors


	$itk_component(textWidget) configure -state disabled
}


##############################################################
#
###############################################################
body DCS::RunSequenceView::fillViewer {} {
	if { $_snapShotView == 1} {
		showSnapShot
		return
	}
    if {$itk_option(-purpose) == "forGrid"} {
	    if {[catch {$_runCalculator getField next_frame} nextFrame]} {
            #### no update yet.
            showNoCrystal
            return
        }
    }

	$itk_component(textWidget) configure -state normal
	set nextFrame [$_runCalculator getField next_frame]


	$itk_component(textWidget) tag configure collectingFrameTag -foreground $_collectingFrameColor -font $font
	$itk_component(textWidget) tag configure collectedFrameTag -foreground $_collectedFrameColor -font $font
	$itk_component(textWidget) tag configure uncollectedFrameTag -foreground $_uncollectedFrameColor  -font $font
	$itk_component(textWidget) tag configure completedRunTag -foreground $_uncollectedFrameColor  -font $font
	
	#make sure that we dont try to do an insane request.
	verifyRunIndex

	#erase what is currently in the text box.
	$itk_component(textWidget) delete 1.0 end
	
	set totalFrames [$_runCalculator getTotalFrames]

	#fill up until not all of the text is visible or we have reached the end of the run
	set displayFrame [expr $_runIndex]
	while { [lindex [$itk_component(textWidget) yview] 1] == 1 && $displayFrame < $totalFrames} {
		insertFrame end $displayFrame
		incr displayFrame
	}

	#insert the COMPLETE message into the run sequence if it is complete and visible
	if { $nextFrame >= $totalFrames && $displayFrame >= $totalFrames } {
		$itk_component(textWidget) insert end "Complete\n" "completedRunTag"
	}

	#insert the end into the run sequence if the end of the run is visible, but the run isn't complete
	if { $nextFrame < $totalFrames && $displayFrame >= $totalFrames } {
		$itk_component(textWidget) insert end "End\n" "completedRunTag"
	}


	#insert one more line to be sure to see everything
	if { $nextFrame < $totalFrames && $displayFrame < $totalFrames } {
		insertFrame end $displayFrame
	}
	
	#calculate the last frame shown in the box
	set endIndex [expr $displayFrame]
	
	set displayFrame  [expr $_runIndex - 1]
	if {  [lindex [$itk_component(textWidget) yview] 1] == 1 } {
		#start filling up from the bottom
		while { [lindex [$itk_component(textWidget) yview] 1] == 1 && $displayFrame >= 0} {
			insertFrame 0.0 $displayFrame
			incr displayFrame -1
		}
	}

	restoreColors

	#calculate the first frame shown in the box
	set startIndex [expr $displayFrame]

	#set the size and offset of the scroll bar
	$itk_component(textScrollY) set [expr 1.0 - ($totalFrames - $startIndex) / double($totalFrames)] [expr 1.0 - ($totalFrames - $endIndex) / double($totalFrames)] 
	#set the current pages size for future page scrolling requests
	set _pageSize [expr $endIndex - $startIndex]

	$itk_component(textWidget) configure -state disabled
}


body DCS::RunSequenceView::restoreColors {} {
	$itk_component(textWidget) tag configure collectingFrameTag -foreground $_collectingFrameColor -font $font
	$itk_component(textWidget) tag configure collectedFrameTag -foreground $_collectedFrameColor -font $font
	$itk_component(textWidget) tag configure uncollectedFrameTag -foreground $_uncollectedFrameColor  -font $font
	$itk_component(textWidget) tag configure completedRunTag -foreground $_uncollectedFrameColor  -font $font
}

###############################################################
#
###############################################################
body DCS::RunSequenceView::insertFrame {textIndex frameIndex} {

	set totalFrames [$_runCalculator getTotalFrames]
	set nextFrame [$_runCalculator getField next_frame]

	if { $frameIndex < $nextFrame } {
		$itk_component(textWidget) insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "collectedFrameTag runIndexTag$frameIndex"
	} elseif {$frameIndex == $nextFrame } {
		$itk_component(textWidget) insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "collectingFrameTag runIndexTag$frameIndex"
	} elseif {$frameIndex < $totalFrames } {
		$itk_component(textWidget) insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "uncollectedFrameTag runIndexTag$frameIndex"
	}

	$itk_component(textWidget) tag bind runIndexTag$frameIndex <Enter> "$itk_component(textWidget) tag configure runIndexTag$frameIndex -underline 1"
	$itk_component(textWidget) tag bind runIndexTag$frameIndex <Leave> "$itk_component(textWidget) tag configure runIndexTag$frameIndex -underline 0"
	$itk_component(textWidget) tag bind runIndexTag$frameIndex <Double-1> [list $this handleDoubleClick $frameIndex] 
}



#############################################################
#
############################################################
body DCS::RunSequenceView::changeView {command args } {

	set totalFrames [$_runCalculator getTotalFrames]

	switch $command {
		scroll {
			#get the direction
			set direction [lindex $args 0]
			set units [lindex $args 1]
			if { $units == "units" } {
				incr _runIndex $direction
			} else {
				incr _runIndex [expr $_pageSize * $direction]
			}

		}
		moveto {
			#get the relative offset into the run definition
			set offset [lindex $args 0]
			set _runIndex [expr int( $totalFrames * $offset)]
		}
	}

	
	#limit the runIndex to possible frames
	if { $_runIndex < 0} {
		set _runIndex 0
	}
	if { $_runIndex > $totalFrames} {
		set _runIndex $totalFrames
	}

	#fill the viewer
	fillViewer
}

body DCS::RunSequenceView::handleDoubleClick { nextFrame_ } {
    if {$itk_option(-purpose) == "forGrid"} {
        set grpNum [gCurrentGridGroup getId]
        set id     [gCurrentGridGroup getCurrentGridId]
        if {$grpNum < 0 || $id < 0} {
            return
        }

        $m_objGridGroupConfig startOperation set_next_frame \
        $grpNum $id $nextFrame_

        return
    }
    $m_lastRunDef setNextFrame $nextFrame_
}
