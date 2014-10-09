package require Itcl
package require Iwidgets
package require BWidget
package require BLT

package provide FloatGridTab 1.0

# load the DCS packages
package require DCSButton
package require DCSMdi

package provide BLUICEVideoNotebook 1.0
package require BLUICEDiffImageViewer
package require GridCanvas
package require BLUICEDoseMode

class FloatGridTab {
	inherit ::itk::Widget

	itk_option define -videoParameters videoParameters VideoParameters {}
	itk_option define -videoEnabled videoEnabled VideoEnabled 0
	itk_option define -beamWidthDevice beamWidthDevice BeamWidthDevice ""
	itk_option define -beamHeightDevice beamHeightDevice BeamHeightDevice ""
	itk_option define -imageServerHost imageServerHost ImageServerHost ""
	itk_option define  -imageServerHttpPort imageServerHttpPort ImageServerHttpPort ""

    itk_option define -purpose purpose Purpose forGrid {
        addTools
    }

    private variable m_needOpenUp 1
    private variable m_myTabName "Rastering"
    private variable m_fileName ""
    private variable m_deviceFactory
    private variable m_visibleControl ""

    private variable m_objCollectGridGroup ""
    private variable m_objSystemIdle ""

    private variable m_hasInline 0
    private variable m_defaultList ""

    private common DEFAULT_GEO
    array set DEFAULT_GEO [list \
    video             [list 1270       5   800 520] \
    l614_video        [list 1270       5   800 520] \
    grid_input        [list    5       5   450 585] \
    helical_input     [list    5       5   450 750] \
    grid_inline_video [list  470       5   840 580] \
    grid_sample_video [list  470       5   840 580] \
    grid_node_list    [list  470     620   840 150] \
    grid_frame_preview [list 1320      5   200 580] \
    diffImageViewer   [list 1320       5   580 580] \
    resolution        [list 1270       5   400 400] \
    ]

    public method handleSystemIdle { - ready_ - contents_ - } {
        switch -exact -- $itk_option(-purpose) {
            forLCLS -
            forLCLSGrid -
            forLCLSCrystal -
            forL614 {
            }
            default {
                return
            }
        }

        if {!$ready_} {
            set contents_ ""
        }
        if {$contents_ == ""} {
            $itk_component(Mdi) configure -background orange
        } else {
            $itk_component(Mdi) configure -background white
        }
    }

    public method onFontSizePlus { name } {
        set ff [$itk_component($name) cget -font]
        puts "current font: $ff"

        set ss [lindex $ff 1]
        set ss [expr $ss - 2]
        set ff [lreplace $ff 1 1 $ss]
        $itk_component($name) configure \
        -font $ff
    }
    public method onFontSizeMinus { name } {
        set ff [$itk_component($name) cget -font]
        puts "current font: $ff"

        set ss [lindex $ff 1]
        if {$ss < -12} {
            set ss [expr $ss + 2]
        }
        set ff [lreplace $ff 1 1 $ss]
        $itk_component($name) configure \
        -font $ff
    }

    public method highlightStartButton { } {
        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                set wName helical_input
            }
            default {
                set wName grid_input
            }
        }
        openToolChest $wName
        $itk_component($wName) highlightStartButton
    }
    public method handleActiveTabUpdate { - ready_ - contents_ - } {
        if {!$ready_ || $contents_ != $m_myTabName} {
            return
        }
        if {$m_needOpenUp} {
            openUp
        }
    }

    public method handleOperationEvent { msg_ }

    public method openUp { } {
        if {![restoreLayout 1]} {
            openAllWidgets
        }
        set m_needOpenUp 0

        $itk_component(Mdi) resetView
    }

    public method showFile { path } {
        if {[checkAndActivateExistingDocument diffImageViewer 1]} {
            $itk_component(diffImageViewer) showFile $path
            raise $itk_component(diffImageViewer)
            return
        }
        if {[checkAndActivateExistingDocument video 1]} {
            $itk_component(video) showDiffractionImage $path
            raise $itk_component(video)
        }
    }
    public method unPauseDiffViewer { } {
        set anyFound 0
        if {[checkAndActivateExistingDocument diffImageViewer 1]} {
            $itk_component(diffImageViewer) unPause
            incr anyFound
        }
        if {[checkAndActivateExistingDocument video 1]} {
            $itk_component(video) unPauseDiffractionImageViwer
            incr anyFound
        }
        if {[checkAndActivateExistingDocument l614_video 1]} {
            $itk_component(l614_video) unPauseDiffractionImageViwer
            incr anyFound
        }
        if {$anyFound == 0} {
            openToolChest diffImageViewer
        }
    }
    public method goBackToPreviousVideoTab { } {
        if {[checkAndActivateExistingDocument video 1]} {
            $itk_component(video) goBackToPreviousTab
        }
        if {[checkAndActivateExistingDocument l614_video 1]} {
            $itk_component(l614_video) goBackToPreviousTab
        }
    }

	public method addChildVisibilityControl { args } {
        set m_myTabName [lindex $args end]
        set m_visibleControl $args
        foreach nn {video grid_inline_video grid_sample_video \
        l614_video} {
            if {[info exists itk_component($nn)]} {
	            eval $itk_component($nn) addChildVisibilityControl $args
            }
        }
    }

	public method addTools

	public method openToolChest
	public method closeToolChest
	public method launchWidget
	public method checkAndActivateExistingDocument { name {skipActive 0} }

    public method openAllWidgets { } {
        foreach name $m_defaultList {
	        launchWidget $name
            if {[info exists DEFAULT_GEO($name)]} {
                set geo $DEFAULT_GEO($name)
                foreach {x y w h} $geo break
                $itk_component(Mdi) configureDocument $name \
                -x $x -y $y -width $w -height $h
            }
        }
    }

    public method saveLayout { } {
        global env

        set layout [$itk_component(Mdi) getDocumentsInfo]
        if {$layout == ""} {
            log_warning no documents found.
            return
        }

        set fileId [open $m_fileName w]
        foreach doc $layout {
            puts $fileId $doc
            log_warning saved [lindex $doc 0]
        }
        close $fileId
    }

    public method restoreLayout { {starting 0} } {
        if {[catch {open $m_fileName r} fileId]} {
            if {!$starting} {
                log_error open raster layout file failed: $fileId
            }
            return 0
        }
        set data [read -nonewline $fileId]
        close $fileId

        set layout [split $data \n]

        set any 0
        foreach doc $layout {
            set name [lindex $doc 0]
	        launchWidget $name
            incr any
        }
        foreach doc $layout {
            foreach {name x y w h} $doc break
            $itk_component(Mdi) configureDocument $name \
            -x $x -y $y -width $w -height $h
        }

        return $any
    }

	# public methods
	constructor { args } {
        global env

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_objCollectGridGroup [$m_deviceFactory createOperation \
        collectGridGroup]

        set m_objSystemIdle [$m_deviceFactory createString system_idle]

        if {[$m_deviceFactory motorExists inline_camera_zoom]} {
            set m_hasInline 1
        }

		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add control {
			frame $itk_component(ring).c
		}
        set controlSite $itk_component(control)

		itk_component add toolChest {
			DCS::MenuEntry $controlSite.tools -showEntry 0 \
            -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		$itk_component(toolChest) configure -fixedEntry "Individual Widget"
		$itk_component(toolChest) configure -state normal -entryWidth 18 

        itk_component add openAll {
            button $controlSite.open \
            -text "Default Widgets Layout" \
            -command "$this openAllWidgets"

        } {
        }

        itk_component add saveAll {
            button $controlSite.save \
            -text "Save Widgets Layout" \
            -command "$this saveLayout" \
        } {
        }

        itk_component add restoreAll {
            button $controlSite.restore \
            -text "Load Widgets Layout" \
            -command "$this restoreLayout" \
        } {
        }


		itk_component add Mdi {
			DCS::MDICanvas $itk_component(ring).m $this \
            -background white \
            -relief sunken \
            -borderwidth 2 \
		} {
		}

		eval itk_initialize $args

        set beamline [::config getConfigRootName]


        switch -exact -- $itk_option(-purpose) {
            forCrystal {
                set fName helical.layout
            }
            forLCLS {
                set fName lcls.layout
            }
            forLCLSCrystal {
                set fName lcls_crystal.layout
            }
            forL614 {
                set fName l614.layout
            }
            forPXL614 {
                set fName pxl614.layout
            }
            forGrid -
            default {
                set fName raster.layout
            }
        }
        set m_fileName [file join ~$env(USER) .bluice ${beamline}_$fName]
        set m_fileName [file native $m_fileName]

		addTools
		
		pack $itk_component(ring) -expand yes -fill both

		pack $itk_component(control)
		grid $itk_component(openAll) -column 0 -row 0 
		grid $itk_component(toolChest) -column 1 -row 0 
		grid $itk_component(saveAll) -column 2 -row 0 
		grid $itk_component(restoreAll) -column 3 -row 0 

		pack $itk_component(Mdi) -expand yes -fill both

        $m_objCollectGridGroup registerForAllEvents $this handleOperationEvent

        ### comment this out if you want to open it up when the tab first show
        openUp

        $m_objSystemIdle register $this contents handleSystemIdle
	}
    destructor {
        $m_objCollectGridGroup unregisterForAllEvents $this handleOperationEvent
        $m_objSystemIdle unregister $this contents handleSystemIdle
    }
}
body FloatGridTab::handleOperationEvent { msg_ } {
    foreach {evType opName opId tag gid} $msg_ break

    if {$evType == "stog_operation_completed"} {
        if {[catch {
            goBackToPreviousVideoTab
        } errMsg]} {
            puts "goBackToPreviousVideoTab failed: $errMsg"
        }
    }
}
body FloatGridTab::addTools {} {
    switch -exact -- $itk_option(-purpose) {
        forCrystal {
            set wList [list \
            "Helical Collect"                   helical_input \
            "Heads-up Display - Inline View"    grid_inline_video \
            "Heads-up Display - Sample View"    grid_sample_video \
            "Position List"                     grid_node_list \
            "Beamline Video"                    video \
            "Collect Frame View"                grid_frame_preview \
            "Diffraction Image View"            diffImageViewer \
            "Snapshots View"                    grid_canvas \
            "Resolution Calculator"             resolution \
            ]

            set m_defaultList [list \
            helical_input \
            grid_inline_video \
            grid_frame_preview \
            diffImageViewer \
            ]

            if {!$m_hasInline} {
                set wList [lreplace $wList 2 3]
                set m_defaultList \
                [lreplace $m_defaultList 1 1 grid_sample_video]
            }
        }
        forLCLS {
            set wList [list \
            "Raster Collect"                    grid_input \
            "Heads-up Display - Inline View"    grid_inline_video \
            "Heads-up Display - Sample View"    grid_sample_video \
            "Position List"                     grid_node_list \
            "Beamline Video"                    video \
            "Diffraction Image Viewer"          diffImageViewer \
            "Snapshots View"                    grid_canvas \
            "Resolution Calculator"             resolution \
            ]
            set m_defaultList [list \
            grid_input \
            grid_inline_video \
            grid_node_list \
            diffImageViewer \
            ]
        }
        forLCLSCrystal {
            set wList [list \
            "Helical Collect"                   grid_input \
            "Heads-up Display - Inline View"    grid_inline_video \
            "Heads-up Display - Sample View"    grid_sample_video \
            "Position List"                     grid_node_list \
            "Beamline Video"                    video \
            "Helical Strategy Setup"            grid_strategy \
            "Diffraction Image Viewer"          diffImageViewer \
            "Snapshots View"                    grid_canvas \
            "Resolution Calculator"             resolution \
            ]
            set m_defaultList [list \
            grid_input \
            grid_inline_video \
            grid_node_list \
            diffImageViewer \
            ]
        }
        forPXL614 -
        forL614 {
            set wList [list \
            "Grid Collect"                      grid_input \
            "Heads-up Display - Inline View"    grid_inline_video \
            "Heads-up Display - Sample View"    grid_sample_video \
            "Grid Node List"                    grid_node_list \
            "Grid Positioning and Beamline Video "   l614_video \
            "Diffraction Image Viewer"      diffImageViewer \
            "Snapshots View"                grid_canvas \
            "Resolution Calculator"             resolution \
            ]
            set m_defaultList [list \
            grid_input \
            grid_inline_video \
            grid_node_list \
            diffImageViewer \
            ]
        }
        forGrid -
        default {
            set wList [list \
            "Raster Setup"                      grid_input \
            "Heads-up Display - Inline View"    grid_inline_video \
            "Heads-up Display - Sample View"    grid_sample_video \
            "Raster Node List"                  grid_node_list \
            "Beamline Video"                    video \
            "Diffraction Image Viewer"          diffImageViewer \
            "Snapshots View"                    grid_canvas \
            "Resolution Calculator"             resolution \
            ]
            set m_defaultList [list \
            grid_input \
            grid_inline_video \
            grid_node_list \
            diffImageViewer \
            ]
            if {!$m_hasInline} {
                set wList [lreplace $wList 2 3]
                set m_defaultList \
                [lreplace $m_defaultList 1 1 grid_sample_video]
            }
        }
    }

    $itk_component(toolChest) removeAll
    foreach {title tag} $wList {
        $itk_component(toolChest) add command \
        -label $title    \
        -command [list $this openToolChest $tag]
    }

}
body FloatGridTab::closeToolChest { name  } {
    $itk_component(Mdi) deleteDocument $name
}

body FloatGridTab::openToolChest { name  } {
	#store the current pointer shape and set it to a watch/clock to show the system is busy

	blt::busy hold . -cursor watch
	update
	
   if {[catch {
	   launchWidget $name
   } err ] } {
      global errorInfo
      puts $errorInfo
   }

	blt::busy release .
}

body FloatGridTab::launchWidget { name  } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    if {[info exists DEFAULT_GEO($name)]} {
        set geo $DEFAULT_GEO($name)
        foreach {- - w h} $geo break
    } else {
        set w 200
        set h 200
    }

	switch $name {
		video {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Beamline Video" \
            -resizable 1 -width $w -height $h]
			
			itk_component add video {
				DCS::BeamlineVideoNotebook $path.v "" \
		         -imageUrl2 [::config getImageUrl 2] \
		         -imageUrl3 [::config getImageUrl 3] \
		         -imageUrl4 [::config getImageUrl 4] \
		         -textUrl2 [::config getTextUrl 2] \
		         -textUrl3 [::config getTextUrl 3] \
		         -textUrl4 [::config getTextUrl 4] \
		         -presetUrl2 [::config getPresetUrl 2] \
		         -presetUrl3 [::config getPresetUrl 3] \
		         -presetUrl4 [::config getPresetUrl 4] \
		         -moveRequestUrl2 [::config getMoveRequestUrl 2] \
		         -moveRequestUrl3 [::config getMoveRequestUrl 3] \
		         -moveRequestUrl4 [::config getMoveRequestUrl 4] \
		         -channelArgs2 [::config getVideoArgs 2] \
		         -channelArgs3 [::config getVideoArgs 3] \
		         -channelArgs4 [::config getVideoArgs 4] \
                 -beamWidthWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamWidth] \
                 -beamHeightWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamHeight] \
                 -useStepSize 1 \
                 -showPause 1 \
			} {
				keep -videoParameters
				keep -videoEnabled
			}

			pack $itk_component(video) -expand 1 -fill both
			pack $path
	        if {$m_visibleControl != ""} {
	            eval $itk_component(video) addChildVisibilityControl \
                $m_visibleControl
            }
            if {$m_hasInline} {
			    $itk_component(video) selectView 1
            } else {
			    $itk_component(video) selectView 0
            }
		}

		l614_video {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Grid Positioning and Beamlinel Video" \
            -resizable 1 -width $w -height $h]
			
			itk_component add $name {
				DCS::BeamlineVideoNotebook $path.v "" \
		         -imageUrl2 [::config getImageUrl 2] \
		         -imageUrl3 [::config getImageUrl 3] \
		         -imageUrl4 [::config getImageUrl 4] \
		         -textUrl2 [::config getTextUrl 2] \
		         -textUrl3 [::config getTextUrl 3] \
		         -textUrl4 [::config getTextUrl 4] \
		         -presetUrl2 [::config getPresetUrl 2] \
		         -presetUrl3 [::config getPresetUrl 3] \
		         -presetUrl4 [::config getPresetUrl 4] \
		         -moveRequestUrl2 [::config getMoveRequestUrl 2] \
		         -moveRequestUrl3 [::config getMoveRequestUrl 3] \
		         -moveRequestUrl4 [::config getMoveRequestUrl 4] \
		         -channelArgs2 [::config getVideoArgs 2] \
		         -channelArgs3 [::config getVideoArgs 3] \
		         -channelArgs4 [::config getVideoArgs 4] \
                 -beamWidthWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamWidth] \
                 -beamHeightWidget \
                 [$m_deviceFactory getObjectName $gMotorBeamHeight] \
                 -useStepSize 0 \
                 -forL614 1 \
                 -showPause 1 \
			} {
				keep -videoParameters
				keep -videoEnabled
			}

			pack $itk_component($name) -expand 1 -fill both
			pack $path
	        if {$m_visibleControl != ""} {
	            eval $itk_component(video) addChildVisibilityControl \
                $m_visibleControl
            }
			$itk_component($name) selectView 1
		}
		diffImageViewer {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "Diffraction Image View" \
            -resizable 1 -width 500 -height 500]

			itk_component add $name {
				DiffImageViewer $path.diff -width 500 -height 500 -showPause 1
            } {
                keep -imageServerHost -imageServerHttpPort
            }
				
			pack $itk_component($name) -expand 1 -fill both
			pack $path
		}
        grid_frame_preview {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "Collect Frame View" \
            -resizable 1 -width 300 -height 600]

            itk_component add ${name}_dose {
                DCS::DoseControlView $path.dose \
                -forGrid  1 \
            } {
            }

			itk_component add $name {
				DCS::RunSequenceView $path.$name \
                -purpose forGrid
            } {
            }
				
			pack $itk_component(${name}_dose) -fill x -side top
			pack $itk_component($name) -expand 1 -fill both -side top
			pack $path
        }

        grid_canvas {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Snapshots View"  -resizable 1  -width 600 -height 800]

			itk_component add $name {
                GridDisplayWidget $path.$name \
                -mdiHelper $this \
                -purpose $itk_option(-purpose) \
		    } {
                keep -purpose
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        grid_inline_video {
			if [checkAndActivateExistingDocument $name] return


			set path [$itk_component(Mdi) addDocument $name \
            -title "Heads-up Display - Inline View"  \
            -resizable 1  -width $w -height $h]

			itk_component add $name {
                GridVideoWidget $path.$name \
                -videoEnabled 1 \
                -mdiHelper $this \
                -purpose $itk_option(-purpose) \
		    } {
				keep -videoParameters
                keep -purpose
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
	        if {$m_visibleControl != ""} {
	            eval $itk_component($name) \
                addChildVisibilityControl $m_visibleControl
            }
        }
        grid_sample_video {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Heads-up Display - Sample View"  \
            -resizable 1  -width $w -height $h]

			itk_component add $name {
                GridVideoWidget $path.$name \
                -camera sample \
                -videoEnabled 1 \
                -mdiHelper $this \
                -purpose $itk_option(-purpose) \
		    } {
				keep -videoParameters
                keep -purpose
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
	        if {$m_visibleControl != ""} {
	            eval $itk_component($name) \
                addChildVisibilityControl $m_visibleControl
            }
        }

        helical_input -
        grid_input {
			if [checkAndActivateExistingDocument $name] return

            switch -exact -- $itk_option(-purpose) {
                forCrystal {
                    set title "Helical Collect"
                }
                forLCLSCrystal {
                    set title "Helical Collect"
                }
                forLCLS {
                    set title "Raster Collect"
                }
                forPXL614 -
                forL614 {
                    set title "Grid Collect"
                }
                default {
                    set title "Raster Setup"
                }
            }

			set path [$itk_component(Mdi) addDocument $name \
            -title $title  \
            -fontResizable 1 \
            -resizable 1  \
            -increaseFontCallback "$this onFontSizePlus grid_input" \
            -decreaseFontCallback "$this onFontSizeMinus grid_input" \
            -width $w -height $h]

			itk_component add $name {
                GridListView $path.grid_input \
                -activeClientOnly 1 \
                -systemIdleOnly 1 \
                -onStart "$this unPauseDiffViewer" \
                -purpose $itk_option(-purpose) \
		    } {
                keep -purpose
		    }

			pack $itk_component($name) -expand 1 -fill both
			pack $path

            if {[info exists itk_component(grid_node_list)]} {
                ::mediator register ::$itk_component(grid_node_list) \
                ::$itk_component($name) on_new handleOnNewChange
            }
        }
        grid_node_list {
			if [checkAndActivateExistingDocument $name] return

            switch -exact -- $itk_option(-purpose) {
                forLCLS -
                forCrystal -
                forLCLSCrystal {
                    set title "Position List"
                }
                forPXL614 -
                forL614 {
                    set title "Grid Node List"
                }
                default {
                    set title "Raster Node List"
                }
            }

			set path [$itk_component(Mdi) addDocument $name \
            -title $title  \
            -resizable 1  -width $w -height $h]

			itk_component add $name {
                GridNodeListView $path.$name \
                -activeClientOnly 1 \
                -systemIdleOnly 1 \
                -diffViewer $this \
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path

            if {[info exists itk_component(grid_input)]} {
                ::mediator register ::$itk_component($name) \
                ::$itk_component(grid_input) on_new handleOnNewChange
            }
            if {[info exists itk_component(helical_input)]} {
                ::mediator register ::$itk_component($name) \
                ::$itk_component(helical_input) on_new handleOnNewChange
            }
        }
        grid_strategy {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Helical Strategy Setup"  \
            -resizable 1  \
            -width 500 -height 800]

			itk_component add $name {
                GridStrategyView $path.$name \
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }
		resolution {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "Resolution Calculator" \
            -resizable 1 -width 400 -height 400]

			itk_component add $name {
				GridResolutionView $path.$name \
                -purpose $itk_option(-purpose) \
                -mdiHelper $this \
            } {
                keep -purpose
            }
				
			pack $itk_component($name) -expand 1 -fill both
			pack $path
		}
	}
}

body FloatGridTab::checkAndActivateExistingDocument { \
documentName_ {skipActive 0} \
} {
	
	if { [info exists itk_component($documentName_)] } {
        if {!$skipActive} {
		    $itk_component(Mdi) activateDocument $documentName_
            if {[info exists DEFAULT_GEO($documentName_)]} {
                foreach { x y w h} $DEFAULT_GEO($documentName_) break
                $itk_component(Mdi) configureDocument $documentName_ \
                -x 10 -y 10 -width $w -height $h
            }
        }
		return 1
	}

	return 0
}


proc handle_network_error {args} {
}
