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
##   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#

package provide BLUICEMadScan 1.0

package require Iwidgets

package require DCSComponent
package require DCSEntry
package require DCSPeriodicTable
package require DCSGraph
package require DCSDeviceFactory
package require DCSEmissionLine


class InflectPeakRemExporter {
   inherit DCS::Component

   #variable for storing singleton exporter object
   private common m_theObject {} 
   public proc getObject
   public method enforceUniqueness

   public method setExporter
   public method getExporter {} {return $m_exporter}

   private variable m_exporter ""

    # constructor
    constructor { args } {
        # call base class constructor
        ::DCS::Component::constructor  { exporter {getExporter} }
    } {
      enforceUniqueness

        eval configure $args
        announceExist
    }
}

#return the singleton object
body InflectPeakRemExporter::getObject {} {
   if {$m_theObject == {}} {
      #instantiate the singleton object
      set m_theObject [[namespace current] ::#auto]
   }

   return $m_theObject
}

#this function should be called by the constructor
body InflectPeakRemExporter::enforceUniqueness {} {
   set caller ::[info level [expr [info level] - 2]]
   set current [namespace current]

   if ![string match "${current}::getObject" $caller] {
      error "class ${current} cannot be directly instantiated. Use ${current}::getObject"
   }
}


body InflectPeakRemExporter::setExporter { obj_ } {

   set m_exporter $obj_

   updateRegisteredComponents exporter

}

class MadScanWidget {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -switchViewCmd switchViewCmd SwitchViewCmd ""

    # constructor
    ### mode: MAD_SCAN EXCITATION_SCAN
    public method constructor {mode args}
    public method destructor

    public method getSelectedIndex { } {
        return [$itk_component(notebook) index select]
    }
    public method selectIndex { index } {
        $itk_component(notebook) select $index
    }

    # public methods
    public method handleEnergyMarkerMove { index value }
    public method updateEnergyMarker { index }
    public method handleScanButton {}
    public method handleModeSelect {}
    public method handleReset {}
    public method handleChoochOutput
    public method getMadEnergy { index }
    public method getInflectionPeakRemoteEnergy 
    public method print {}

    public method load {}
    public method save {}
    public method handleEdgeSelection
    public method handleInflectionExporterChange 
    public method updateDefinition

    public method handleOpenFile { }

    public method handleStaticElementEnter { i }
    public method handleStaticElementLeave { i }
    public method handleStaticElementClick { i }
    public method handleSingleElementSelection { name }

    public method handleEnergyUpperLimitChange { - ready_ - contents_ - } {
        if {!$ready_} return
        puts "energy upperlimit: $contents_"
        set MAX_ENERGY [lindex $contents_ 0]
    }
    public method regenerateOtherChoice { } {
        set choices none

        foreach name $m_elementNameList {
            if {[lsearch $m_staticElementNameList $name] < 0} {
                lappend choices $name
            }
        }
        $itk_component(allElement) configure \
        -menuChoices $choices
        
        $itk_component(allElement) setValue none 1
    }

    public method redisplaySelection { {selectedList ""} } {
        if {$selectedList == ""} {
            set selectedList [array names m_markArray]
        }
        set i -1
        foreach name $m_staticElementNameList {
            incr i
            $itk_component(staticElement$i) configure \
            -text $name
            pack $itk_component(staticElement$i) \
            -side left \
            -before $itk_component(allElement)
        }
        #### try to keep previous selected elements
        foreach name $selectedList {
            set i [lsearch -exact $m_staticElementNameList $name]
            if {$i >= 0} {
                handleStaticElementClick $i
            } elseif {[lsearch -exact $m_elementNameList $name] >= 0} {
                $itk_component(allElement) setValue $name 1
            }
        }
        set singleE [$itk_component(allElement) get]
        if {$singleE != "none"} {
            drawElementLine $singleE
        }
    }

    public method refreshElementList { min max } {
        if {$min == $m_energyMin && $max == $m_energyMax} {
            return
        }
        puts "new energy range: $min $max"
        puts "==============================================="
        set m_energyMin $min
        set m_energyMax $max
        set m_elementList [DCS::EmissionLine::getElementList $min $max]
        set m_elementNameList ""
        foreach element $m_elementList {
            puts $element
            foreach {eName lineList} $element break
            lappend m_elementNameList $eName
        }
        puts "==============================================="

    }

    public method handleLinkClick { } {
        set obj [InflectPeakRemExporter::getObject]
        set current [$obj getExporter]
        if {$current != ""} {
            $obj setExporter ""
        } else {
            $obj setExporter $this
            set eList [getInflectionPeakRemoteEnergy]
            foreach e $eList {
                if {![checkEnergyLimits $e]} {
                    break
                }
            }
        }
    }

    public method updateWarningSetup { - ready_ - edge_ -} {
        if {!$ready_} {
            return
        }
        puts "updateWarningSetup: $edge_"
        set setting ""
        if {$edge_ != ""} {
            set data [$itk_component(periodicTable) getDataByEdgeName $edge_]
            if {[llength $data] > 0} {
                set e [lindex $data 0]
                if {$m_scanMode != "MAD_SCAN"} {
                    set e [expr $e + 500.00] 
                }
                set v0 [expr $e - 10.0]
                set v1 [expr $e + 10.0]
                set setting [list [list $v0 eV] [list $v1 eV]]
            }
        }
        puts "settings=$setting"
        $itk_component(edgeEnergy) configure \
        -warningOutside $setting
    }

    public method handleScanOperationEvent

    private method handleMadScanOperationEvent
    private method handleExcitationScanOperationEvent

    private method setExcitationParameters
    private method setMadParameters


    private method resetGraph
    private method initializeMadGraph

    private method initializeExcitationGraph
    private method resetChoochEnergies
    private method startMadScan
    private method startExcitationScan
    private method graphExcitationScan
    private method addPointToMadGraph

    private method checkEnergyLimits { e } {
        ### bug meeting decide allow user to export
        ### checks in runDefinition and collect should
        ### have enough cover for this.
        return 1

        set localCopy [lindex $e 0]
        if {![::device::energy limits_ok localCopy 1]} {
            log_error energy $e is out of limits

            set obj [InflectPeakRemExporter::getObject]
            set current [$obj getExporter]
            if {$current != ""} {
                $obj setExporter ""
                log_error Disabled Link to Run Definition \
                energy $e is out of limits
                
            }
            return 0
        }
        return 1
    }

    private method removeAllLines { {keep_selection 0} } {
        foreach e [array names m_markArray] {
            removeElementLine $e $keep_selection
        }

        if {$m_scanMode != "MAD_SCAN"} {
            for {set i 0} {$i < $MAX_NUM_STATIC} {incr i} {
                $itk_component(staticElement$i) configure \
                -background $m_origBg \
                -foreground $m_origFg
            }
            $itk_component(allElement) setValue none 1
        }
    }
    private method removeElementLine { e {keep_selection 0} } {
        if {[catch {
            set markList $m_markArray($e)
            foreach mark $markList {
                catch {delete object $mark}
            }
            if {!$keep_selection} {
                unset -nocomplain -- m_markArray($e)
            }
        } errMsg]} {
            puts "removeElementLine $e error: $errMsg"
        }
    }
    private method drawElementLine { name } {
        set index [lsearch -exact $m_elementNameList $name]
        if {$index < 0} {
            log_error element $name not found \
            in list of elements fit the energy range
            return 0
        }
        set element [lindex $m_elementList $index]
        foreach {name lineList} $element break
        set markList ""
        set num 0
        foreach line $lineList {
            set mark [$itk_component(graph) createVerticalMarker \
            $name$num $line  "Energy (eV)" \
            -width 2 -color $m_selectedBg]

            $mark no_drag
            $mark setTitle "$name $line"

            lappend markList $mark

            incr num
        }
        if {$markList != ""} {
            set m_markArray($name) $markList
        }
        return 1
    }

    private method getExtraElements { inputEnergy }
    private method getAvailableCommonElements { }

    private variable _scanTrace
    
    # current scan parameters (set when start button is pushed)
    private variable m_scanMode
    private variable m_inConstructor 0
    private variable _edgeData {Se-K 12658.0 11222.4}
    private variable _selectedEdge
    private variable _directory
    private variable _fileRoot
    private variable _user
    private variable _sessionId
    private variable _scanDelta 1.0 
    private variable _scanTime
    private variable _edgeEnergy 1.0

    # private data
    private variable _edgeCutoff 1.0


    # appearance
    private variable _lightColor     #e0e0f0
    private variable _darkColor    #c0c0ff
    private variable _darkColor2 #777
    private variable _lightRedColor #ffaaaa

    private variable _tinyFont *-helvetica-bold-r-normal--10-*-*-*-*-*-*-*
    private variable _smallFont *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
    private variable _largeFont *-helvetica-bold-r-normal--18-*-*-*-*-*-*-*
    private variable _hugeFont  *-helvetica-medium-r-normal--30-*-*-*-*-*-*-*

    private method repack

    private method addScanlogHeader
    private method resetViews
   private method checkFilePermissionsOk 
   private variable m_deviceFactory
   private variable m_objEnergy
   private variable m_objScanStatus 

   protected variable m_logger
   private variable m_objScan

   private variable _firstPoint 1

    private variable m_energyMin 0
    private variable m_energyMax 0
    private variable m_commonElementNameList [list Se Hg Pt Zn Ca Mn Fe Cu Ni Cd Co]
    ### static is combination of common and extra
    private variable m_staticElementNameList ""
    private variable m_elementList ""
    private variable m_elementNameList ""
    private variable m_markArray
    private variable m_currentSingleElement ""
    private variable m_hoverMark
    private variable m_DEBUGPeakMark ""

    private variable m_origBg ""
    private variable m_origFg ""
    private variable m_selectedFg white
    private variable m_selectedBg DarkRed
    private variable m_hoverColor cyan

    private variable MAX_NUM_EXTRA 4
    private variable MAX_NUM_STATIC
    private variable MIN_ENERGY 1700.0
    ### get from upper limit of energy
    private variable MAX_ENERGY 16000
    private variable MAX_HOVER_LINE 4
    ### find element within peak +- 
    private variable ENERGY_PROBE 75.0
    
}


body MadScanWidget::constructor { mode args } {
    set m_inConstructor 1

    global env

    set m_scanMode $mode

    puts "scanmode=$mode for $this"

    set MAX_NUM_STATIC \
    [expr [llength $m_commonElementNameList] + $MAX_NUM_EXTRA]

    array set m_markArray [list]

    set m_logger [DCS::Logger::getObject]
    set m_deviceFactory [DCS::DeviceFactory::getObject]
    set m_objEnergy [$m_deviceFactory getObjectName energy]
    if {$m_scanMode == "MAD_SCAN"} {
        set m_objScanStatus [$m_deviceFactory createString madScanStatus]
        set m_objScan [$m_deviceFactory createOperation madScan]
    } else {
        set m_objScanStatus [$m_deviceFactory createString excitationScanStatus]
        set m_objScan [$m_deviceFactory createOperation optimalExcitation]
    }
    $m_objScanStatus createAttributeFromField active    0
    $m_objScanStatus createAttributeFromField message   1
    $m_objScanStatus createAttributeFromField user      2
    $m_objScanStatus createAttributeFromField directory 3
    $m_objScanStatus createAttributeFromField file_root 4
    $m_objScanStatus createAttributeFromField edge      5
    $m_objScanStatus createAttributeFromField energy    6
    $m_objScanStatus createAttributeFromField cut_off   7
    $m_objScanStatus createAttributeFromField time      8

    # create the tab notebook for holding the periodic table and scan graph
    itk_component add notebook {
        iwidgets::tabnotebook $itk_interior.tab  \
             -tabbackground $_darkColor -background $_lightColor -backdrop lightgrey -borderwidth 2\
             -tabpos n -gap 4 -angle 0 -raiseselect 1 -bevelamount 4 \
             -tabforeground $_darkColor2 -padx 5
    } {
    }

    #-width 720 -height 570

    # create the two notebook tabs
    $itk_component(notebook) add -label "  Periodic Table  "
    $itk_component(notebook) add -label "Plot"
    $itk_component(notebook) add -label "Log"
    $itk_component(notebook) add -label "Hardware"

    $itk_component(notebook) select 0

    # create two frames in the plot tab
    set periodicTableFrame [$itk_component(notebook) childsite 0]
    set plotTabFrame [$itk_component(notebook) childsite 1]

    pack $periodicTableFrame -expand 1 -fill both
    pack $plotTabFrame -expand 1 -fill both

    if {$m_scanMode != "MAD_SCAN"} {
        itk_component add elementFrame {
            frame $plotTabFrame.element -bg $_lightColor
        } {}

        set eSite $itk_component(elementFrame)

        for {set i 0} {$i < $MAX_NUM_STATIC} {incr i} {
            itk_component add staticElement$i {
                label $eSite.static$i
            } {
            }
            bind $itk_component(staticElement$i) <Button-1> \
            "$this handleStaticElementClick $i"

            bind $itk_component(staticElement$i) <Enter> \
            "$this handleStaticElementEnter $i"

            bind $itk_component(staticElement$i) <Leave> \
            "$this handleStaticElementLeave $i"

            puts "staticElement$i created"

        }
        set i -1
        foreach name $m_commonElementNameList {
            incr i
            $itk_component(staticElement$i) configure \
            -text $name
        }

        set m_origBg [$itk_component(staticElement0) cget -background]
        set m_origFg [$itk_component(staticElement0) cget -foreground]
        itk_component add allElement {
            DCS::MenuEntry $eSite.other \
            -entryType string \
            -entryWidth 4 \
            -showEntry 0 \
            -activeClientOnly 0 \
            -systemIdleOnly 0 \
            -onSubmit [list $this handleSingleElementSelection %s]
        } {
        }

        $itk_component(allElement) configure \
        -menuChoices none

        pack $itk_component(allElement) -side left
    }

    itk_component add energyFrame {
        frame $plotTabFrame.energyFrame -bg $_lightColor
    } {}

    itk_component add graphFrame {
        frame $plotTabFrame.graphFrame
    } {
    }
    
    # create the user scan graph
    itk_component add graph {
        DCS::Graph $itk_component(graphFrame).g \
             -onOpenFile "$this handleOpenFile" \
             -title "Energy Scan" \
             -xLabel "Energy (eV)" \
             -yLabel "Absorbance" \
             -legendFont $_smallFont \
             -background  $_lightColor \
             -tickFont $_smallFont \
             -titleFont $_largeFont \
             -axisLabelFont $_smallFont
    } {
    }

    set m_hoverMark ""
    for {set i 0} {$i < $MAX_HOVER_LINE} {incr i} {
        set mark [$itk_component(graph) createVerticalMarker \
        hover$i 0 "Energy (eV)" \
        -width 1 -color $m_hoverColor -dashes "10 2" -hide 1]

        $mark no_drag
        $mark removeTextMarker
        $mark configure -hide 1
        lappend m_hoverMark $mark
    }

    if {$m_scanMode == "MAD_SCAN"} {
        itk_component add choochButton {
            button $itk_component(energyFrame).chooch \
            -text "Reset" \
            -command "$this handleReset" \
            -font $_smallFont
        } {
        }

        # create the three energy entries and markers
        foreach { index color } \
        {Inflection orange Peak darkgreen Remote blue } {
            # create the vertical marker
            $itk_component(graph) createVerticalMarker \
            energy$index 0.25 "Energy (eV)" \
            -width 2 \
            -color $color \
            -callback "$this handleEnergyMarkerMove $index" \
            -textformat "%.2f"

            # create the energy entry
            itk_component add $index {
                DCS::Entry $itk_component(energyFrame).energy$index \
                -promptText "$index:" \
                -entryWidth 12 \
                -promptForeground $color \
                -unitsForeground $color \
                -entryType positiveFloat\
                -units "eV" \
                -shadowReference 1 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -onSubmit "$this updateEnergyMarker $index" \
            } {}

            pack $itk_component($index) -side left -padx 10
        }

        itk_component add exportCheck {
            DCS::Checkbutton $plotTabFrame.export \
            -command "$this handleLinkClick" \
            -text "Link to Run Definition via Update button" \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
        }
        pack $itk_component(exportCheck) -side bottom
    } else {
        # create the three energy entries and markers
        foreach { index color } \
        {Marker blue } {
            # create the vertical marker
            $itk_component(graph) createVerticalMarker \
            energy$index 0.25 "Energy (eV)" \
            -width 2 \
            -color $color \
            -callback "$this handleEnergyMarkerMove $index" \
            -textformat "%.2f"

            # create the energy entry
            itk_component add $index {
                DCS::Entry $itk_component(energyFrame).energy$index \
                -promptText "$index:" \
                -entryWidth 12 \
                -promptForeground $color \
                -unitsForeground $color \
                -entryType positiveFloat\
                -units "eV" \
                -shadowReference 1 \
                -activeClientOnly 0 \
                -systemIdleOnly 0 \
                -onSubmit "$this updateEnergyMarker $index" \
            } {}

            pack $itk_component($index) -side left -padx 10
        }
    }

    # create the scan mode radio buttons
    itk_component add modeRadio {
        iwidgets::radiobox $itk_interior.modeRadio \
             -labeltext "Scan Mode" -labelpos nw \
             -labelfont $_smallFont -selectcolor red\
             -command "$this handleModeSelect"
    } {
    }

    [$itk_component(modeRadio) component label] configure -font $_largeFont

    # create the help frame
    itk_component add helpLabeledFrame {
        iwidgets::Labeledframe $itk_interior.helpFrame
    }

    set helpFrame [$itk_component(helpLabeledFrame) childsite]
    pack propagate $helpFrame 1

    itk_component add helpText {
        text $helpFrame.text \
             -font $_smallFont -relief flat -wrap word -width 27 -height 5
    } {
    }
    if {$m_scanMode == "MAD_SCAN"} {
        $itk_component(helpText) insert end \
        "Scan sample to determine peak, inflection and remote energies for MAD."
    } else {
        $itk_component(helpText) insert end \
        "Use multi-channel analyzer to perform a fluorescence scan at a particular energy.  The recommended energy is 500.0 eV above the edge energy."
    }
    $itk_component(helpText) configure -state disabled

    # create the parameters labeled frame
    itk_component add parameterLabeledFrame {
        iwidgets::Labeledframe $itk_interior.parameterFrame \
             -labeltext "Scan Parameters" -ipadx 0 -labelpos nw
    } {
    }

    set parameterFrame [$itk_component(parameterLabeledFrame) childsite]

    itk_component add updateButton {
        DCS::Button $parameterFrame.u \
        -text "Update" \
        -width 5 -pady 0 -activeClientOnly 1 \
        -command "$this updateDefinition" 
    } {
    }

    # make the filename root entry
    itk_component add fileRoot {
        DCS::Entry $parameterFrame.fileroot \
        -entryType field \
        -entryWidth 17 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Prefix: " \
        -promptWidth 10 \
        -shadowReference 1 \
        -activeClientOnly 1 \
        -reference "$m_objScanStatus file_root" \
        -systemIdleOnly 0

    } {}

    # make the data directory entry
    itk_component add directory {
        DCS::DirectoryEntry $parameterFrame.dir \
        -entryType field \
        -entryWidth 17 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Directory: " \
        -promptWidth 10 \
        -shadowReference 1 \
        -activeClientOnly 1 \
        -entryMaxLength 128 \
        -reference "$m_objScanStatus directory" \
        -systemIdleOnly 0
    } {}

    # create edge entry
    itk_component add parameterEdgeEntry {
        DCS::Entry $parameterFrame.edge \
        -promptText "Edge: "  \
        -state disabled \
        -entryJustify center \
        -entryWidth 12 \
        -promptWidth 10 \
        -unitsWidth 5 \
        -escapeToDefault 0 \
        -shadowReference 1 \
        -activeClientOnly 0 \
        -reference "$m_objScanStatus edge" \
        -onSubmit "$this updateWarningSetup %s" \
        -systemIdleOnly 0
    } {
    }

    # create edge energy entry
    itk_component add edgeEnergy {
        DCS::MotorViewEntry $parameterFrame.energy \
        -checkLimits -1 \
        -device ::device::energy \
        -showPrompt 1 \
        -showArrow 0 \
        -entryType positiveFloat \
        -systemIdleOnly 0 \
        -activeClientOnly 0\
        -state normal \
        -entryJustify center \
        -unitsList { \
        eV {-decimalPlaces 3 -promptText "Energy:"} \
        keV {-decimalPlaces 4 -promptText "Energy:"} \
        A {-decimalPlaces 6 -promptText "Wavelength:"} \
        } \
        -entryWidth 12 \
        -promptWidth 10 \
        -units eV \
        -unitsWidth 5 \
        -activeClientOnly 1 \
        -escapeToDefault 1 \
        -reference "$m_objScanStatus energy" \
        -autoConversion 1 \
        -shadowReference 1
    } {
    }

    # create time entry
    itk_component add timeEntry {
        DCS::Entry $parameterFrame.time \
        -promptText "Time:" \
        -unitsList "s {} ms {}" \
        -units "s" \
        -entryType positiveFloat \
        -entryJustify right \
        -activeClientOnly 1 \
        -entryWidth 12 \
        -promptWidth 10 \
        -reference "$m_objScanStatus time" \
        -autoConversion 1 \
        -shadowReference 1 \
        -systemIdleOnly 0
    } {
    }

    # create the start scan button
    itk_component add scanButton {
        DCS::Button $itk_interior.scan \
        -text "Scan" \
        -command "$this handleScanButton" \
        -font "helvetica -14 bold" -width 7
    } {
    }

    set objStopScan [$m_deviceFactory createOperation stopFluorescenceScan]
    # create the stop button
    itk_component add stop {
        ::DCS::Button  $itk_interior.stop \
        -systemIdleOnly 0 \
        -text "Stop" \
        -font "helvetica -14 bold" \
        -width 7 \
        -command "$objStopScan startOperation"
    } {
    }    

    # create the stop button
    itk_component add abort {
        ::DCS::Button  $itk_interior.abort \
        -text "Abort" \
        -background \#ffaaaa \
        -activebackground \#ffaaaa \
        -systemIdleOnly 0 \
        -activeClientOnly 0 \
        -font "helvetica -14 bold" -width 7
    } {
        keep -height -state
        keep -activeforeground -foreground -relief 
    }

    #pack the hutch overview widget in the titled frame
    itk_component add periodicTable {
        DCS::PeriodicTable $periodicTableFrame.pt
    } {
        keep -periodicFile
    }

    global gPeriodicTable
    set gPeriodicTable $periodicTableFrame.pt

    set logSite [$itk_component(notebook) childsite 2]
    
    itk_component add log {
        DCS::scrolledLog $logSite.l
    } {
    }
    
    pack $itk_component(log) -expand yes -fill both 

    set hardwareSite [$itk_component(notebook) childsite 3]
    itk_component add hw {
        DCS::FrontEndFluorescenceView $hardwareSite.f
    } {
        keep -mdiHelper
    }
    
    repack

    $itk_component(modeRadio) add mad -text "MAD Scan" -pady 5 -padx 40
    $itk_component(modeRadio) add excitation -text "Excitation Scan" -pady 5 -padx 40
    if {$m_scanMode == "MAD_SCAN"} {
        $itk_component(modeRadio) select mad
    } else {
        $itk_component(modeRadio) select excitation
    }

    eval itk_initialize $args


    set objAutoChooch [$m_deviceFactory createOperation runAutochooch]

    ::$itk_component(periodicTable) register $this -edgeData handleEdgeSelection 
    if {$m_scanMode == "MAD_SCAN"} {
        ::mediator register $this [InflectPeakRemExporter::getObject] exporter handleInflectionExporterChange 
    }
   ::mediator announceExistence $this

    $m_objEnergy register $this upperLimit handleEnergyUpperLimitChange
    $m_objScan registerForAllEvents $this handleScanOperationEvent 

    $itk_component(parameterEdgeEntry) register $this -value updateWarningSetup

    $itk_component(abort) configure -command "$itk_option(-controlSystem) abort"

    $itk_component(scanButton) addInput "$m_objScan status inactive {supporting device}"
    $itk_component(scanButton) addInput "$objAutoChooch status inactive {supporting device}"
   $itk_component(scanButton) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
    ### auto fix in dcss code
    #$itk_component(scanButton) addInput "::$itk_component(directory) dirOK 1 {directory not set yet}" 
   if {[$m_deviceFactory motorExists fluorescence_z]} {
       $itk_component(scanButton) addInput "::device::fluorescence_z status inactive {supporting device}" 
   }
   $itk_component(scanButton) addInput "::device::attenuation status inactive {supporting device}" 
   $itk_component(timeEntry) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
   $itk_component(edgeEnergy) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
   $itk_component(fileRoot) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
   $itk_component(updateButton) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
   $itk_component(directory) addInput "$m_objScanStatus active 0 {Fluorescence scan in progress.}" 
    set m_inConstructor 0
}

body MadScanWidget::destructor {} {

    if {$m_scanMode == "MAD_SCAN"} {
        ::mediator unregister $this [InflectPeakRemExporter::getObject] exporter 
    }

    $m_objScan unRegisterForAllEvents $this handleScanOperationEvent 
    $m_objEnergy unregister $this upperLimit handleEnergyUpperLimitChange
}


body MadScanWidget::repack {} {

    pack $itk_component(periodicTable)
    pack $itk_component(graphFrame) -fill both -expand true
    pack $itk_component(graph)  -expand 1 -fill both
    if {$m_scanMode == "MAD_SCAN"} {
        pack $itk_component(choochButton) -side left -padx 10
    } else {
        pack $itk_component(elementFrame)
    }
    pack $itk_component(energyFrame) -pady 10 -padx 35

    pack $itk_component(updateButton) -side top -pady 5 -anchor n
    foreach field \
    { fileRoot directory parameterEdgeEntry edgeEnergy timeEntry } {
        pack $itk_component($field) -side top -pady 5 -anchor w
    }


    grid columnconfigure $itk_interior 1 -weight 1 
    grid columnconfigure $itk_interior 0 -weight 0

    grid rowconfigure $itk_interior 0 -weight 3
    grid rowconfigure $itk_interior 1 -weight 4
    grid rowconfigure $itk_interior 2 -weight 1
    grid rowconfigure $itk_interior 3 -weight 0
    grid rowconfigure $itk_interior 4 -weight 0
    grid rowconfigure $itk_interior 5 -weight 0
    grid rowconfigure $itk_interior 6 -weight 0
    grid rowconfigure $itk_interior 7 -weight 10

    grid $itk_component(notebook) -row 0 -column 1 -rowspan 8 -sticky news
    grid $itk_component(modeRadio) -row 0 -column 0 -sticky news
    grid $itk_component(helpLabeledFrame) -row 1 -column 0 -sticky news
    pack $itk_component(helpText)

    grid $itk_component(parameterLabeledFrame) -row 2 -column 0 -sticky news

    grid $itk_component(scanButton) -row 3 -column 0 -sticky n
    grid $itk_component(stop) -row 4 -column 0  -sticky n
    grid $itk_component(abort) -row 5 -column 0  -sticky n

    #pack $itk_interior -expand 1 -fill both
}


body MadScanWidget::print {} {
    $itk_component(notebook) select 1
    $itk_component(graph) print
}


body MadScanWidget::load {} {
    $itk_component(notebook) select 1
    $itk_component(graph) handleFileOpen
}


body MadScanWidget::save {} {
    $itk_component(notebook) select 1
    $itk_component(graph)  handleFileSave
}


body MadScanWidget::handleModeSelect {} {
    if {$m_inConstructor} {
        return
    }

    if {[$itk_component(modeRadio) get] == "mad"} {
        set newMode MAD_SCAN
    } else {
        set newMode EXCITATION_SCAN
    }
    if {$m_scanMode != $newMode} {
        ### call to switch view
        if {$itk_option(-switchViewCmd) != ""} {
            eval $itk_option(-switchViewCmd) $newMode
        }
    }
    if {$m_scanMode == "MAD_SCAN"} {
        $itk_component(modeRadio) select mad
    } else {
        $itk_component(modeRadio) select excitation
    }
}

body MadScanWidget::getInflectionPeakRemoteEnergy { } {
    return [list [getMadEnergy Inflection] [getMadEnergy Peak] [getMadEnergy Remote]]
}

body MadScanWidget::getMadEnergy { index } {

    return [$itk_component($index) get]
}

body MadScanWidget::handleReset {} {
    if {$m_scanMode == "MAD_SCAN"} {
        $itk_component(Inflection) updateFromReference
        $itk_component(Peak) updateFromReference
        $itk_component(Remote) updateFromReference

        updateEnergyMarker Inflection
        updateEnergyMarker Peak
        updateEnergyMarker Remote
    } else {
        $itk_component(Marker) updateFromReference
        updateEnergyMarker Marker
    }

}


body MadScanWidget::handleEnergyMarkerMove { index value } {
    #puts "MADSCAN: $value"

    checkEnergyLimits $value
    
    $itk_component($index) setValue [format "%.2f" $value]
}


body MadScanWidget::updateEnergyMarker { index } {
    set value [$itk_component($index) get]

    checkEnergyLimits $value

    if { [lindex $value 0] != "" } {
        set value [expr [::units convertUnitValue $value eV]]
        
        $itk_component(graph) configureVerticalMarker energy$index -position $value
    }
}

body MadScanWidget::handleInflectionExporterChange { - targetReady_ - exporter_ -} {

   if {$targetReady_} {
      if {$exporter_ == $this } {
         $itk_component(exportCheck) setValue 1
      } else {
         $itk_component(exportCheck) setValue 0
      } 
   }

}

body MadScanWidget::handleEdgeSelection { caller_ targetReady_ - edgeData_ initiatorId_} {
    #
    if { !$targetReady_} return

    #store new edge data in private variable
    set _edgeData $edgeData_

    #log_note "Edge cuttoff = $_edgeCutoff"
    if {$m_scanMode == "MAD_SCAN"} {
        setMadParameters
    } else {
        setExcitationParameters
    }
}


body MadScanWidget::setExcitationParameters {} {
    foreach {_selectedEdge edgeEnergy _edgeCutoff} $_edgeData break

    $itk_component(timeEntry) setValue 10.0
    
    $itk_component(parameterEdgeEntry) setValue $_selectedEdge
    set edgeEnergy [expr [::units convertUnitValue $edgeEnergy eV] + 500.00] 

    set eLimit [$m_objEnergy getEffectiveUpperLimit]
    set energyUpperLimit [::units convertUnitValue $eLimit eV]

    if {$edgeEnergy > $energyUpperLimit} {
        log_warning edge energy adjusted from $edgeEnergy eV to $energyUpperLimit eV due to energy limits
        set edgeEnergy $energyUpperLimit
    }

    $itk_component(edgeEnergy) setValue [list $edgeEnergy eV]
}

body MadScanWidget::setMadParameters {} {
    foreach {_selectedEdge edgeEnergy _edgeCutoff} $_edgeData break
    
    $itk_component(timeEntry) setValue "1.0 s"
    $itk_component(parameterEdgeEntry) setValue $_selectedEdge
    
    puts "setMadParameteters: edge=$_selectedEdge energy=$edgeEnergy"
    $itk_component(edgeEnergy) setValue $edgeEnergy
}

body MadScanWidget::resetViews {} {
    #clear the log
    $itk_component(log) clear
    
    #clear the graphs
    resetGraph
    initializeMadGraph
}


body MadScanWidget::addScanlogHeader { edge_ } {

    $itk_component(log) log_string "Fluorescence scan of $edge_ edge started." warning
    
    set logEntry ""
    
    # update the scanlog window
    $itk_component(log) log_string $logEntry warning 0
}




body MadScanWidget::resetGraph {} {

    # delete all existing traces in graph
    $itk_component(graph) deleteAllTraces

    # create the new trace
    set _scanTrace scan
    $itk_component(graph) createTrace $_scanTrace {"Energy (eV)"} {}
    $itk_component(graph) configure -xLabel "Energy (eV)" -x2Label "" -y2Label ""
}

body MadScanWidget::initializeMadGraph { } {
    $itk_component(graph) configure -title "Fluorescence Scan"
    
    # create the three sub-traces
    foreach {subtrace yLabelList color} \
         {    signal {"Signal Counts" "Counts"} darkgreen \
                 ref {"Reference Counts" "Counts"} black \
                 fluor {"Sample Fluorescence" "Fluorescence" } red \
             } {
                        $itk_component(graph) createSubTrace $_scanTrace $subtrace $yLabelList {} -color $color    
             }
    $itk_component(graph) configure -yLabel "Sample Fluorescence"

    handleEnergyMarkerMove Inflection 1.0
    handleEnergyMarkerMove Peak 1.0
    handleEnergyMarkerMove Remote 1.0

    $itk_component(graph) createTrace smooth {"Energy (eV)"} {}
    $itk_component(graph) createSubTrace smooth smooth {"Sample Fluorescence" "Fluorescence" "Smoothed" } {}  -color purple    

    $itk_component(graph) createTrace normal {"Energy (eV)"} {}
    $itk_component(graph) createSubTrace normal normal {"Normalized Fluoresence" } {}  -color blue    

    $itk_component(graph) createTrace Transform {"Energy (eV)"} {}
    $itk_component(graph) createSubTrace Transform fp {"Electrons" "Fp (Electrons)" } {}  -color red    
    $itk_component(graph) createSubTrace Transform fpp { "Electrons" "Fpp (Electrons)"  } {}  -color green    
}


body MadScanWidget::initializeExcitationGraph {} {
    
    # create the three sub-traces
    foreach {subtrace yLabelList color} {
        counts {"Signal Counts" "Counts"} darkgreen
    } { $itk_component(graph) createSubTrace $_scanTrace $subtrace $yLabelList {} -color $color }
    $itk_component(graph) configure -yLabel "Sample Fluorescence"

    #Inform the graph widget which trace to display
    $itk_component(graph) configure -yLabel [list "Counts"]
}

body MadScanWidget::resetChoochEnergies {} {
    foreach energy { Inflection Peak Remote } {
        $itk_component($energy) updateFromReference
        updateEnergyMarker $energy
    }
}

body MadScanWidget::handleScanButton {} {

    # global variables
    global env

    # make a copy of current parameters
    set _scanTime [::units convertUnitValue [$itk_component(timeEntry) get] s]
    set _edgeEnergy [::units convertUnitValue [$itk_component(edgeEnergy) get] eV] 
   set _directory [$itk_component(directory) get]
   set _fileRoot [$itk_component(fileRoot) get]

    set _user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set _sessionId SID
    } else {
        set _sessionId PRIVATE[$itk_option(-controlSystem) getSessionId]
    }

    # check for invalid time
    if { ! [isPositiveFloat $_scanTime] } {
      $m_logger logError "Invalid value in time entry."
        return
    }

    # check for invalid energy
   if { ! [isPositiveFloat $_edgeEnergy] } {
      $m_logger logError "Invalid value in energy entry."
        return
    }

    # check for invalid directory 
   if { $_directory == "" } {
      $m_logger logError "Invalid value in directory entry."
        return
    }

   if { ! [checkFilePermissionsOk] } {
      return
   }

    # check for invalid directory 
   if { $_fileRoot == "" } {
      $m_logger logError "Invalid value in prefix entry."
        return
    }

    if {$m_scanMode == "MAD_SCAN"} {
        resetChoochEnergies
    }
    #setMarkersToZero

   #show the hardware view
   $itk_component(notebook) select 3 
    
    # set up graph depending on scan mode
    if {$m_scanMode == "MAD_SCAN"} {
        startMadScan
    } else {
        startExcitationScan
    }
}

body MadScanWidget::checkFilePermissionsOk { } {
    #### dcss code will fix it or check it.
   return 1
}
body MadScanWidget::startMadScan {} {



    $m_objScan startOperation $_user $_sessionId $_directory $_fileRoot $_selectedEdge $_edgeEnergy $_edgeCutoff $_scanTime
    
}

body MadScanWidget::startExcitationScan {} {
    eval $m_objScan startOperation $_user $_sessionId $_directory $_fileRoot $_selectedEdge $_edgeEnergy $_scanTime
}

body MadScanWidget::handleChoochOutput { inflectionEnergy_ inflectionFP_ inflectionFPP_ peakEnergy_ peakFP_ peakFPP_ remoteEnergy_ remoteFP_ remoteFPP_ rawData_ smoothExpFile_ smoothNormFile_ FpFppFile_} {
    #    puts "$inflectionEnergy_ $inflectionFP_ $inflectionFPP_ $peakEnergy_ $peakFP_ $peakFPP_ $remoteEnergy_ $remoteFP_ $remoteFPP_ $smoothExpData_ $smoothNormData_ $fpFppData_"
    
    handleEnergyMarkerMove Inflection $inflectionEnergy_
    handleEnergyMarkerMove Peak $peakEnergy_
    handleEnergyMarkerMove Remote $remoteEnergy_

    $itk_component(log) log_string "Inflection Energy: $inflectionEnergy_ eV" warning
    $itk_component(log) log_string "Inflection   f'  : $inflectionFP_" warning
    $itk_component(log) log_string "Inflection   f'' : $inflectionFPP_" warning
    $itk_component(log) log_string "Peak Energy: $peakEnergy_ eV" warning
    $itk_component(log) log_string "Peak   f'  : $peakFP_" warning
    $itk_component(log) log_string "Peak   f'' : $peakFPP_" warning
    $itk_component(log) log_string "Remote Energy: $remoteEnergy_ eV" warning
    $itk_component(log) log_string "Remote   f'  : $remoteFP_" warning
    $itk_component(log) log_string "Remote   f'' : $remoteFPP_" warning

    $itk_component(log) log_string "Scan completed normally." warning


   set directory [$m_objScanStatus getFieldByIndex directory]

   if { [catch {
      $itk_component(graph) openFile [file join $directory $smoothExpFile_]
   } err ] } {
      puts $err
   }
   if { [catch {
      $itk_component(graph) openFile [file join $directory $smoothNormFile_]
   } err ] } {
      puts $err
   }
   if { [catch {
      $itk_component(graph) openFile [file join $directory $FpFppFile_]
   } err ] } {
      puts $err
   }

   [InflectPeakRemExporter::getObject] setExporter $this 
}
body MadScanWidget::handleScanOperationEvent { message_ } {
    if {$m_scanMode == "MAD_SCAN"} {
        handleMadScanOperationEvent $message_
    } else {
        handleExcitationScanOperationEvent $message_
    }
}

body MadScanWidget::handleMadScanOperationEvent { message_ } {
    #puts "MADSCAN: $message_"
    foreach {eventType operationName operationId arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9 arg10 arg11 arg12 arg13 arg14 arg15} $message_ break

    #verify that this scan operation is for this scan widget
    
    switch $eventType {
        stog_start_operation {
            set _firstPoint 1
            #clear the log
            resetViews
            set exporter [[InflectPeakRemExporter::getObject] getExporter]
            if {$exporter == $this} {
                [InflectPeakRemExporter::getObject] setExporter ""
            }
            addScanlogHeader $arg3
            $itk_component(graph) configure -title "Fluorescence Scan of $arg1 Edge"
        }
        stog_operation_update {
            if {[string first "BEAM_NOT_GOOD" $arg2] >= 0} {
                #### clear graph but not log
                set _firstPoint 1
                resetGraph
                initializeMadGraph
                $itk_component(log) log_string "Fluorescence scan of $arg1 edge restarted because of beam." warning
                $itk_component(log) log_string "" warning 0
            } else {
                if {$_firstPoint} {
                    set _firstPoint 0
                    $itk_component(notebook) select 1 
                }
                ###Some BluIce may just be opened and missed start message
                $itk_component(graph) configure -title "Fluorescence Scan of $arg1 Edge"
                addPointToMadGraph $arg2 $arg3 $arg4 $arg5
                $itk_component(log) log_string "$arg2 $arg3 $arg4 $arg5 $arg6" warning 0 
            }
        }
        stog_operation_completed {

            if {$arg1 == "normal" } {
                $itk_component(log) log_string $message_ warning
            #set dir $arg3
                handleChoochOutput $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14
            } else {
                resetChoochEnergies
                $itk_component(log) log_string "Scan completed [lrange $message_ 4 end]" warning
            }
        }
        default {
            return -code error "Should not have received this message: $_message"
        }
    }
}

body MadScanWidget::handleExcitationScanOperationEvent { message_ } {
    foreach {eventType operationName operationId arg1 arg2} $message_ break

    switch $eventType {
        stog_start_operation {
            resetGraph
            initializeExcitationGraph
            set edge_name [lindex $message_ 7]
            $itk_component(graph) configure -title "Excitation Scan of $edge_name Edge"
        }

        stog_operation_completed {
        }

        stog_operation_update {
            graphExcitationScan $arg1
        }

        default {
            return -code error "Should not have received this message: $message_"
        }
    }
}


body MadScanWidget::graphExcitationScan { fileName_ } {
    #graph the results
   $itk_component(notebook) select 1
    
    #$itk_component(graph) setZoomDefaultX 000 25000
   if { [catch {
        puts "calling graph openFile $fileName_"
       $itk_component(graph) openFile $fileName_
   } err ] } {
      puts $err
      return
   }
}


body MadScanWidget::addPointToMadGraph { energyPosition_ signalCounts_ referenceCounts_ fluorescence_ } {

    # add data points to graph
    $itk_component(graph) addToTrace $_scanTrace $energyPosition_ \
         "$signalCounts_ $referenceCounts_ $fluorescence_"
}

body MadScanWidget::updateDefinition { } {

    set _user [$itk_option(-controlSystem) getUser]

   #try to get the filename prefix from the screening tab...
    set object [$m_deviceFactory createString crystalStatus]
    #$object createAttributeFromField current 0
    #$object createAttributeFromField subdir 4
   set fileRoot [$object getFieldByIndex 0] 

    if { $fileRoot == "" } {
        #nothing is mounted now...leave the entry alone
        set prefix test
        set dir  [getDefaultDataDirectory $_user]
    } else {
        #something is mounted...get the directory from screening 
        set dirObj [$m_deviceFactory createString screeningParameters]
        set rootDir [$dirObj getFieldByIndex 2]
        set subDir [$object getFieldByIndex 4]
        set eList [file split $rootDir]
        foreach e $eList {
            if {[string equal -nocase $e username]} {
                set rootDir  [getDefaultDataDirectory $_user]
                log_warning directory from Screening not set yet.
                break
            }
        }
        set prefix $fileRoot 
        set dir    [file join $rootDir $subDir]
    }
    $itk_component(fileRoot)  setValue $prefix
    $itk_component(directory) setValue $dir
}


body MadScanWidget::handleSingleElementSelection { name } {
    if {$m_currentSingleElement != ""} {
        removeElementLine $m_currentSingleElement
        set m_currentSingleElement ""
    }
    set i [lsearch $m_staticElementNameList $name]
    if {$i >= 0} {
        if {[$itk_component(staticElement$i) cget -background] != \
        $m_selectedBg} {
            handleStaticElementClick $i
        }

        $itk_component(allElement) setValue none 1
        return
    }

    if {$name != "none"} {
        drawElementLine $name
        set m_currentSingleElement $name
    }
}
body MadScanWidget::getExtraElements { inputEnergy } {
    ###only handle the first subtrace of last trace
    set allPeaks [$itk_component(graph) getPeaks]
    set tracePeaks [lindex $allPeaks end]
    set subTracePeaks [lindex $tracePeaks 0]

    ##################DEBUG####################
    if {0} {
        foreach obj $m_DEBUGPeakMark {
            delete object $obj
        }
        set m_DEBUGPeakMark ""

        set i 0
        set xLabel [$itk_component(graph) cget -xLabel]
        foreach peak $subTracePeaks {
            foreach {x y} $peak break
            #puts "peak: $x $y"
            incr i
            set mark [$itk_component(graph) \
            createVerticalMarker peak$i $x $xLabel \
            -width 1 -color red -hide 0 -dashes "15 5 2 5"]
            $mark no_drag
            $mark setTitle "peak$i $x $y"
            lappend m_DEBUGPeakMark $mark
        }
    }
    ###########################################

    ##### remove peaks out of energy range #####
    set peaks ""
    foreach peak $subTracePeaks {
        foreach {x y} $peak break
        if {$x >= $MIN_ENERGY && $x <= $inputEnergy} {
            lappend peaks $peak
        } else {
            puts "peak $peak removed: out of energy range $MIN_ENERGY $inputEnergy"
        }
    }

    ##remove the last peak: input energy
    set peaks [lrange $peaks 0 end-1]
    ###sort the peaks on the height
    ###we only take the first 4 peaks
    set peaks [lsort -decreasing -real -index 1 $peaks]
    set i 0
    set resultList ""
    foreach peak $peaks {
        foreach {x y} $peak break
        if {$x < $MIN_ENERGY} {
            continue
        }
        set min [expr $x - $ENERGY_PROBE]
        set max [expr $x + $ENERGY_PROBE]
        puts "min max: $min $max"
        set elementList [DCS::EmissionLine::getElementList $min $max]
        foreach element $elementList {
            set name [lindex $element 0]
            if {[lsearch $resultList $name] < 0} {
                lappend resultList $name
                puts "adding $name"
            }
            incr i
            if {$i >= $MAX_NUM_EXTRA} {
                break
            }
        }
        if {$i >= $MAX_NUM_EXTRA} {
            break
        }
    }
    puts "extra: $resultList"
    return $resultList
}
body MadScanWidget::getAvailableCommonElements { } {
    set resultList ""
    ### add common
    foreach name $m_commonElementNameList {
        if {[lsearch $m_staticElementNameList $name] < 0 && \
        [lsearch $m_elementNameList $name] >= 0} {
            lappend resultList $name
            puts "adding common $name"
        } else {
            puts "skip commont $name"
        }
    }
    puts "common: $resultList"
    return $resultList
}
body MadScanWidget::handleOpenFile { } {
    ###save selected element names before remove all the lines
    set selectedList [array names m_markArray]
    removeAllLines
    if {$m_scanMode != "MAD_SCAN"} {
        for {set i 0} {$i < $MAX_NUM_STATIC} {incr i} {
            pack forget $itk_component(staticElement$i)
        }
    }
    foreach line $m_hoverMark {
        $line configure \
        -hide 1
    }
    puts "handleOpenFile"

    set subTraceNumList [$itk_component(graph) getLastOpenFileInfo]
    set inputEnergy     [$itk_component(graph) getLastOpenFileEnergy]
    if {$inputEnergy < $MIN_ENERGY} {
        set inputEnergy $MAX_ENERGY
        log_warning old bip format use energy upper limits $MAX_ENERGY as input energy
    } else {
        log_note input energy $inputEnergy
    }

    if {$m_scanMode != "MAD_SCAN"} {
        ########### generate STATIC element list #############
        if {$subTraceNumList != "1"} {
            puts "handleOpenFile != 1, skip peaks"
            set m_staticElementNameList ""
            refreshElementList 0 0
        } else {
            set m_staticElementNameList [getExtraElements $inputEnergy]
            refreshElementList $MIN_ENERGY $inputEnergy
            eval lappend m_staticElementNameList [getAvailableCommonElements]
        }
        ######### generate OTHER element list #######
        regenerateOtherChoice
        ####display
        redisplaySelection $selectedList
    }
}
body MadScanWidget::handleStaticElementEnter { i } {
    set name [$itk_component(staticElement$i) cget -text]
    if {$name == ""} {
        return
    }
    set index [lsearch $m_elementNameList $name]
    if {$index < 0} {
        puts "element $name not found in the available list"
        return
    }
    set bg [$itk_component(staticElement$i) cget -background]
    if {$bg == $m_selectedBg} {
        return
    }
    $itk_component(staticElement$i) configure \
    -background $m_hoverColor
    set element [lindex $m_elementList $index]
    set lineList [lindex $element 1]
    for {set i 0} {$i < $MAX_HOVER_LINE} {incr i} {
        set line [lindex $lineList $i]
        set mark [lindex $m_hoverMark $i]
        if {[string is double -strict $line]} {
            $mark moveTo $line
            $mark configure -hide 0 -after ""
        } else {
            ####$mark moveTo -100
            $mark configure -hide 1
        }
    }

}
body MadScanWidget::handleStaticElementLeave { i } {
    set name [$itk_component(staticElement$i) cget -text]
    if {$name == ""} {
        return
    }
    set bg [$itk_component(staticElement$i) cget -background]
    if {$bg == $m_hoverColor} {
        $itk_component(staticElement$i) configure \
        -background $m_origBg
    }
    foreach line $m_hoverMark {
        ####$line moveTo -100
        $line configure \
        -hide 1
    }
}
body MadScanWidget::handleStaticElementClick { i } {

    handleStaticElementLeave $i

    set name [$itk_component(staticElement$i) cget -text]
    if {$name == ""} {
        return
    }
    set bg [$itk_component(staticElement$i) cget -background]
    if {$bg == $m_selectedBg} {
        $itk_component(staticElement$i) configure \
        -background $m_origBg \
        -foreground $m_origFg

        removeElementLine $name
    } else {
        if {[drawElementLine $name]} {
            $itk_component(staticElement$i) configure \
            -background $m_selectedBg \
            -foreground $m_selectedFg
        }

    }
}

class ScanTab {
    inherit ::itk::Widget

    public method switchView { mode } {
        #puts "switch to $mode"
        if {$mode == "MAD_SCAN"} {
            set index [$itk_component(excitation_view) getSelectedIndex]
            $itk_component(mad_view) selectIndex $index
            pack forget $itk_component(excitation_view)
            pack $itk_component(mad_view) -fill both -expand 1
            #puts "showing mad_scan $itk_component(mad_view)"
        } else {
            set index [$itk_component(mad_view) getSelectedIndex]
            $itk_component(excitation_view) selectIndex $index
            pack forget $itk_component(mad_view)
            pack $itk_component(excitation_view) -fill both -expand 1
            #puts "showing excitation_scan $itk_component(excitation_view)"
        }
    }

    constructor { args } {
        itk_component add mad_view {
            MadScanWidget $itk_interior.mad MAD_SCAN \
            -switchViewCmd "$this switchView"
        } {
            keep -periodicFile
        }
        pack $itk_component(mad_view) -fill both -expand 1

        itk_component add excitation_view {
            MadScanWidget $itk_interior.excitation EXCITATION_SCAN \
            -switchViewCmd "$this switchView"
        } {
            keep -periodicFile
        }

        eval itk_initialize $args

    }
}
