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

# provide the BIWGraph package
package provide DCSGraph 1.0

# load standard packages
package require BLT
package require Iwidgets
package require BWidget

# load other BIW packages
package require DCSMenu
package require DCSUtil
package require DCSSet
package require DCSCif


##########################################################################
# The class Graph defines a graph object that wraps a blt::graph.  Graphs
# may contain traces and various kinds of markers.
##########################################################################

class DCS::Graph {
 	inherit ::itk::Widget

	# public member functions
	public method constructor { frame args }
	public method updateTable {}
	public method getGraphCoordinates { screenX screenY graphX graphY graphX2 graphY2 } 
	public method zoomSelectStart { x y }
	public method zoomSelectMove { x y }
	public method zoomSelectEnd { x y }
	public method createRectangle {}
	public method drawRectangle { x0 y0 x1 y1 }
	public method destroyRectangle {}
	public method setZoomDefaultX { minX maxX }
	public method setupZoomButton { }
	public method zoomIn { x0 y0 x1 y1 }
	public method zoomOut {}
	public method zoomOutAll {}
    public method isInZoom { }
    public method manualSetZoom { x0 y0 x1 y1 }
	public method deleteAllTraces {}
	public method deleteAllMarkers {}
	public method hideAllLegends {}
	public method createTrace  { traceName xLabels passedXVector args }
	public method createSubTrace { traceName subTraceName yLabels passedYVector args }
	public method deleteSubTraces { subTraceName }
	public method makeOverlay { traceName overlayName }
    public method deleteAllOverlay { }
    ### get self local vector to hold data.
    public method makeTraceStandalone { traceName }

	public method addToTrace { traceName xValue yValues }
	public method getPeaks { }
	public method getXMinMax { }
	public method getYMinMax { yLabel }
	public method getYMinMaxLog { yLabel }
	public method setXPosition { args }
	public method setYPosition { args }
	public method configureTrace { traceName args }
	public method configureSubTrace { traceName subTraceName args }
	public method createVerticalMarker { markerName initialX axisName args }
	public method configureVerticalMarker { markerName args }
	public method createHorizontalMarker { markerName initialY axisName args}
	public method configureHorizontalMarker { markerName args }
	public method createTextMarker { markerName initialX initialY args}
	public method configureTextMarker { markerName args }
	public method createCrosshairsMarker { markerName initialX initialY xAxisName yAxisName args }
	public method configureCrosshairsMarker { markerName args }
	public method handleMouseMotion { x y }
	public method popGraphMenu {}
	public method handleShowGrid { newValue }
	public method handleShowZero { newValue }
	public method handleYLogScale { newValue }
	public method handleY2LogScale { newValue }
	public method setTraceXVector { trace xVector }
	public method setTraceYVector { trace yVector }
	public method setEventSource { object }
	public method updateShownAxisLabels {}
	public method deleteYLabels { yLabels }
	public method deleteXLabels { xLabels }
	public method reportDeletedTrace { traceName }
	public method reportDeletedLineMarker { markerName }
	public method addYMarker {}
	public method addY2Marker {}
	public method addXMarker {}
	public method addX2Marker {}
	public method updateGrid {}
	public method handleFileOpen {}
	public method handleFileSave {}
	public method openFile { fileName } 
	public method saveFile { fileName }
	public method print {}
	public method printSetup {}

    public method getLastOpenFileInfo { } {
        return $m_subTraceNumList
    }
    public method getLastOpenFileEnergy { } {
        return $m_inputEnergy
    }

	public method getBltGraph {} {return $itk_component(bltGraph)}

    #customize 
    public method removeFileAccess { } {
        $graphMenu deleteEntry save
        $graphMenu deleteEntry open
    }
    public method setShowZero { new_value } {
        $graphMenu configureEntry zero -value $new_value
    }
    public method addToMainMenu { name label cmd } {
	    $graphMenu addCommand $name \
        -label $label \
        -command $cmd
    }

	# protected methods
	protected method getElementInfoFromName { element }
	protected method resetAxisColors {}
    protected method doConfigAxis { {force 0} }
    protected method doConfigAxisLinear { axis force }
    protected method doConfigAxisLog { axis force }
	
	# public data members (accessed via -configure)
	itk_option define -title title Title ""
	itk_option define -xLabel xLabel XLabel	 ""				
	itk_option define -yLabel yLabel YLabel ""
	itk_option define -x2Label x2Label X2Label ""
	itk_option define -y2Label y2Label Y2Label ""
	itk_option define -background background Background "" 
	itk_option define -plotbackground plotbackground Plotbackground "white"
	itk_option define -legendBackground legendBackground LegendBackground ""
	itk_option define -legendPosition legendPosition LegendPosition ""
	itk_option define -legendFont legendFont LegendFont ""
	itk_option define -tickFont tickFont TickFont "*-Courier-Bold-R-Normal-*-100-*"

	itk_option define -titleFont titleFont TitleFont ""
	itk_option define -axisLabelFont axisLabelFont AxisLabelFont ""
	itk_option define -gridOn gridOn GridOn ""

	itk_option define -graphMouseX graphMouseX GraphMouseX ""
	itk_option define -graphMouseY graphMouseY GraphMouseY "" 
	itk_option define -screenMouseX screenMouseX ScreenMouseX ""
	itk_option define -screenMouseY screenMouseY ScreenMouseY ""
	itk_option define -hideDatumMarker hideDatumMarker HideDatumMarker 0

	#itk_option define -markerColor markerColor MarkerColor white

	itk_option define -normalAxisTickFont normalAxisTickFont NormalAxisTickFont "*-Helvetica-Medium-R-Normal-*-10-*"
	itk_option define -normalAxisTitleFont normalAxisTitleFont NormalAxisTitleFont "*-Helvetica-Medium-R-Normal-*-12-120-*"

    ## for callback when X axis changes
	itk_option define -onXAxisChange onXAxisChange OnXAxisChange ""

    
	itk_option define -onOpenFile onOpenFile OnOpenFile ""

	itk_option define -noDelete noDelete NoDelete 0

	private variable _windowMouseX ""
	private variable _windowMouseY ""
	public method getWindowMouseX {} {return $_windowMouseX}
	public method getWindowMouseY {} {return $_windowMouseY}
	
	# private data members

	private variable header		""
	private variable vbar		""
	private variable hbar		""
	private variable footer		""
	private variable graphHalfHeight
	private variable graphHalfWidth

	private variable xAxisLabelBag
	private variable yAxisLabelBag
	
	private variable graphMenu
	private variable xAxisMenu
	private variable x2AxisMenu
	private variable yAxisMenu
	private variable y2AxisMenu

	private variable zoomStack
	private variable zoomX
	private variable zoomY
	private variable zoomX2
	private variable zoomY2
	private variable inZoom 0

	private variable trace
	private variable traceSet
	private variable lineMarker
	private variable textMarker
	private variable datumMarker

	private variable darkgrey "\#777777"

	private variable axisUsageCount
	private variable eventSource ""
	private variable cancelZoom 0

	private variable cif

    private variable m_showZero 1
    private variable m_dataCrossZero
    private variable m_zeroSet

    private variable m_yLogScale 0
    private variable m_y2LogScale 0
    private variable m_subTraceNumList ""
    private variable m_inputEnergy -1
}
body DCS::Graph::print {} {
    set types [list [list PDF .pdf]]
    set outFile [tk_getSaveFile \
    -defaultextension ".pdf" \
    -filetypes $types \
    ]

    if {$outFile == ""} {
        ## user aborted
        return
    }

    puts "printing from Graph"
	set tmpGraphFile "/tmp/graph_[clock clicks].ps"
	$itk_component(bltGraph) postscript output $tmpGraphFile \
    -landscape 1 \
    -colormode color \
    -maxpect 1

    #### convert to pdf:
    ## from email from Thomas on 04/21/14

	#puts [exec eps2eps $tmpGraphFile $outGraphFile]
    puts [exec ps2pdf \
    -dPDFSETTINGS=/printer \
    -dEmbedAllFonts=true \
    -sPAPERSIZE=letter \
    -dUseCIEColor=true \
    $tmpGraphFile $outFile \
    ]

    log_warning print saved to $outFile

	puts [exec rm $tmpGraphFile]
}

body DCS::Graph::deleteAllMarkers {} {

	foreach markerName [array names lineMarker] {
        #puts "delete mark: $markerName"
		delete object $lineMarker($markerName)
	}
    array unset lineMarker
	foreach markerName [array names textMarker] {
        #puts "delete mark: $markerName"
		delete object $textMarker($markerName)
	}
    array unset textMarker
}

body DCS::Graph::deleteAllTraces {} {
    #puts "deleteAllTraces"

	foreach traceName [array names trace] {
        #puts "deleting $traceName"
		delete object $trace($traceName)
	}

    $traceSet clear

    #puts "init remove limits zero in delete all trace"
    $itk_component(bltGraph) axis configure y -min "" -max ""
    $itk_component(bltGraph) axis configure y2 -min "" -max ""
    set m_zeroSet(y) 0
    set m_zeroSet(y2) 0
    set m_dataCrossZero(y) 0
    set m_dataCrossZero(y2) 0
}
body DCS::Graph::hideAllLegends {} {
	foreach traceName [array names trace] {
        $trace($traceName) hideLegend 1
    }
}

configbody DCS::Graph::background {
	if {$itk_option(-background) != "" } {
		$itk_component(bltGraph) configure -background $itk_option(-background)
		$itk_component(ring) configure -background $itk_option(-background)
		$footer  configure -background $itk_option(-background)
		$header  configure -background $itk_option(-background)
	}
}

configbody DCS::Graph::legendPosition {
	if {$itk_option(-legendPosition) != "" } {

		$itk_component(bltGraph) legend configure -position $itk_option(-legendPosition) -anchor ne
	}
}


configbody DCS::Graph::legendFont {
	if {$itk_option(-legendFont) != "" } {
		$itk_component(bltGraph) legend configure -font $itk_option(-legendFont)
	}
}


configbody DCS::Graph::titleFont {
	if {$itk_option(-titleFont) != "" } {
		$itk_component(bltGraph) configure -font $itk_option(-titleFont)
	}
}


configbody DCS::Graph::tickFont {
	if {$itk_option(-tickFont) != "" } {

		foreach axis { x y x2 y2 } {
			$itk_component(bltGraph) axis configure $axis -tickfont $itk_option(-tickFont)
		}
	}
}

configbody DCS::Graph::axisLabelFont {
	if {$itk_option(-axisLabelFont) != "" } {
		foreach axis { x y x2 y2 } {
			$itk_component(bltGraph) axis configure $axis -titlefont $itk_option(-axisLabelFont)
		}
	}
}



body DCS::Graph::openFile { fileName } {
    #puts "openFile $fileName"

    set m_subTraceNumList ""

	# read the cif file from disk
	$cif read $fileName

	# set the global parameters
	$this configure -title [$cif getValue 0 "_graph_title.text"]
	$this configure -xLabel [$cif getValue 0 "_graph_axes.xLabel"]
	$this configure -x2Label [$cif getValue 0 "_graph_axes.x2Label"]
	$this configure -yLabel [$cif getValue 0 "_graph_axes.yLabel"]	
	$this configure -y2Label [$cif getValue 0 "_graph_axes.y2Label"]
	$this configure -gridOn [$cif getValue 0 "_graph_background.showGrid"]

    $cif setDefaults _input.energy -1
    set m_inputEnergy [$cif getValue 0 "_input.energy"]
    puts "==================================================="
    puts "ENERGY: $m_inputEnergy"
    puts "==================================================="


	# get number of line markers
	set markerCount [$cif getValueCount 0 "_line_marker.type"]
	
	# create the line markers
	for { set markerIndex 1} { $markerIndex <= $markerCount} { incr markerIndex } {
		set type [$cif getValue 0 _line_marker.type $markerIndex ]
		set position [$cif getValue 0 _line_marker.position $markerIndex]
		set label [$cif getValue 0 _line_marker.label $markerIndex]
		set color [$cif getValue 0 _line_marker.color $markerIndex]
		set width [$cif getValue 0 _line_marker.width $markerIndex]

		if { $type == "vertical" } {
			$this createVerticalMarker [DCS::getUniqueName] $position $label -color $color -width $width
		} elseif { $type == "crosshairs" } {
			$this createCrosshairsMarker [DCS::getUniqueName] [lindex $position 0] [lindex $position 1] [lindex $label 0] [lindex $label 1] -color $color -width $width
		} else {
			$this createHorizontalMarker [DCS::getUniqueName] $position $label -color $color -width $width
		}
	}

	# get number of traces
	set traceCount [$cif getBlockCount]

	# create the traces
	for { set traceIndex 1} {$traceIndex <= $traceCount } { incr traceIndex } {

		# create the trace
		set traceName [$cif getValue $traceIndex _trace.name]
		while { [$traceSet isMember $traceName] } {
			set traceName ${traceName}~
		}

		set traceXLabels [$cif getValue $traceIndex _trace.xLabels]
		set traceHide [$cif getValue $traceIndex _trace.hide]
		$this createTrace $traceName $traceXLabels {} -hide $traceHide

		# get the number of sub-traces
		set subTraceCount [$cif getValueCount $traceIndex "_sub_trace.name"]

        lappend m_subTraceNumList $subTraceCount

		# create the sub-traces
		for { set subTraceIndex 1} {$subTraceIndex <= $subTraceCount } { incr subTraceIndex } {
			set subTraceName [$cif getValue $traceIndex _sub_trace.name $subTraceIndex]
			set subTraceYLabels [$cif getValue $traceIndex _sub_trace.yLabels $subTraceIndex]
		set color [$cif getValue $traceIndex _sub_trace.color $subTraceIndex]
			set width [$cif getValue $traceIndex _sub_trace.width $subTraceIndex]
			set symbol [$cif getValue $traceIndex _sub_trace.symbol $subTraceIndex]
			set symbolSize [$cif getValue $traceIndex _sub_trace.symbolSize $subTraceIndex]
			$this createSubTrace $traceName $subTraceName $subTraceYLabels {} \
				-color $color -width $width -symbol $symbol -symbolSize $symbolSize
		}

		# get the number of data for the trace
		set dataCount [$cif getValueCount $traceIndex "_sub_trace.x" ]

		# read in data for the sub-traces
		for { set dataIndex 1} {$dataIndex <= $dataCount } { incr dataIndex } {
			set x [$cif getValue $traceIndex _sub_trace.x $dataIndex]
			set y {}
			for { set subTraceIndex 1} {$subTraceIndex <= $subTraceCount } { incr subTraceIndex } {
				lappend y [$cif getValue $traceIndex _sub_trace.y$subTraceIndex $dataIndex]
			}
			$this addToTrace $traceName $x $y
		}
	}

    if {$itk_option(-onOpenFile) != ""} {
        eval $itk_option(-onOpenFile)
    }

}


body DCS::Graph::handleFileOpen {} {

	set types { {{BLU-ICE  plots} {.bip}} {{All Files} * }}

	set fileName [tk_getOpenFile -defaultextension ".bip" -filetypes $types \
						  -title "Open a BLU-ICE Plot"]
	
	if { $fileName != "" } {
		openFile $fileName
	}
}

body DCS::Graph::handleFileSave {} {

	set types { {{BLU-ICE  plots} {.bip}} {{All Files} * }}
	
	set fileName [tk_getSaveFile -defaultextension ".bip" -filetypes $types \
						 -title "Save BLU-ICE Plot"]
	
	if { $fileName != "" } {
		saveFile $fileName
	}
}


body DCS::Graph::saveFile { fileName } {

	# open the file for writing 
	set fileHandle [open $fileName w]

	# write information about the graph title 
	puts $fileHandle ""
	puts $fileHandle "\# Information about the graph title"
	puts $fileHandle "_graph_title.text			\"$itk_option(-title)\""

	# write information about the axes
	puts $fileHandle ""
	puts $fileHandle "\# Information about the currently defined axes"
	puts $fileHandle "_graph_axes.xLabel			\"$itk_option(-xLabel)\""
	puts $fileHandle "_graph_axes.x2Label			\"$itk_option(-x2Label)\""
	puts $fileHandle "_graph_axes.yLabel			\"$itk_option(-yLabel)\""
	puts $fileHandle "_graph_axes.y2Label			\"$itk_option(-y2Label)\""

	# write information about the plot background
	puts $fileHandle ""
	puts $fileHandle "\# write information about the plot background"
	puts $fileHandle "_graph_background.showGrid		$itk_option(-gridOn)"

	# write information about the line markers
	puts $fileHandle ""
	puts $fileHandle "loop_"
	puts $fileHandle "_line_marker.type"
	puts $fileHandle "_line_marker.label"
	puts $fileHandle "_line_marker.position"
	puts $fileHandle "_line_marker.color"
	puts $fileHandle "_line_marker.width"
	foreach markerName [array names lineMarker] {
		puts $fileHandle "[$lineMarker($markerName) cget -type] \
			\"[$lineMarker($markerName) cget -label]\" \
			[$lineMarker($markerName) cget -position] \
			[$lineMarker($markerName) cget -color] \
			[$lineMarker($markerName) cget -width]"
	}

	# write out the traces 
	# BAD ARRAY NAMES
	foreach traceName [$traceSet get] {
        if [catch {
		    $trace($traceName) save $fileHandle
        } errMsg] {
            log_error failed for trace: $traceName: $errMsg
        }
	}

	puts $fileHandle ""

	# close the file
	close $fileHandle
}


body DCS::Graph::setEventSource { object } {

	set eventSource $object
}

body DCS::Graph::setupZoomButton { } {
	bind $itk_component(bltGraph) <ButtonPress-1> "$this zoomSelectStart %x %y"
	bind $itk_component(bltGraph) <B1-Motion> "$this zoomSelectMove %x %y"
	bind $itk_component(bltGraph) <ButtonRelease-1> "$this zoomSelectEnd %x %y"
}

body DCS::Graph::constructor { args } {

    array set m_zeroSet [list y 0 y2 0]
    array set m_dataCrossZero [list y 0 y2 0]

	# store the frame as the table
	#set table $frame
	itk_component add ring {
		frame $itk_interior.r
	}

	pack $itk_component(ring) -expand yes -fill both
	pack $itk_interior -expand yes -fill both

	# create the header frame
	set header [frame $itk_component(ring).header -background lightgrey]

	# create the blt::Graph
	itk_component add bltGraph {
		blt::graph $itk_component(ring).graph \
			 -background lightgrey
	} {
	}

	# create the vertical scrollbar
	set vbar [ scrollbar $itk_component(ring).vbar 				\
					  -orient vertical					\
					  -command "$this setYPosition"	\
				]

	# create the horizontal scrollbar
	set hbar [ scrollbar $itk_component(ring).hbar 				\
					  -orient horizontal					\
					  -command "$this setXPosition"	\
				]

	# configure the x axis
	$itk_component(bltGraph) axis configure x				\
		-scrollcommand "$hbar set" 

	# configure the y axis
	$itk_component(bltGraph) axis configure y 			\
		-scrollcommand "$vbar set"

	# initialize axis usage counts
	set axisUsageCount(x) 0
	set axisUsageCount(x2) 0
	set axisUsageCount(y) 0
	set axisUsageCount(y2) 0

	# create the header frame
	set footer [frame $itk_component(ring).footer]

	# pack the component widgets into a blt::table
	blt::table $itk_component(ring) \
		0,0 $header -cspan 3 -fill x \
		1,0 $itk_component(bltGraph)  -fill both -cspan 3 -rspan 3 \
		2,3 $vbar -fill y  -padx 0 -pady 0 \
		4,1 $hbar -fill x \
		5,0 $footer -cspan 3 -fill x

	# make only the appropriate table rows and columns resize
	blt::table configure $itk_component(ring) c3 r0 r4 r5 -resize none

	# reformat table whenever its parent window is resized
	bind $itk_component(ring) <Configure> "$this updateTable"	

	# configure the legend
	$itk_component(bltGraph) legend configure -background white

	# create the main graph popup menu
	set graphMenu [DCS::PopupMenu \#auto]

	$graphMenu addLabel title -label "Plotting Region"
	$graphMenu addSeparator sep1
	$graphMenu addCheckbox grid -label "Show grid" -callback "$this handleShowGrid" -value 0
	$graphMenu addCheckbox zero -label "Show zero" -callback "$this handleShowZero" -value 0
	$graphMenu addCommand zoomout -label "Zoom Out" -command "$this zoomOut"
	$graphMenu addCommand zoomout -label "View All" -command "$this zoomOutAll"
	$graphMenu addSeparator sep2
	$graphMenu addCommand open -label "Open" -command "$this handleFileOpen"
	$graphMenu addCommand save -label "Save" -command "$this handleFileSave"
	$graphMenu addCommand print -label "Print" -command "$this print"
	#$graphMenu addCommand printSetup -label "Print Setup" -command "$this printSetup"

	# create the x-axis menu
	foreach axisMenu { xAxisMenu yAxisMenu x2AxisMenu y2AxisMenu } \
		label {"Primary X Axis" "Primary Y Axis" "Secondary X Axis" "Secondary Y Axis"} {
			set menu [set $axisMenu [DCS::PopupMenu \#auto]]
			$menu addLabel title -label $label
			$menu addSeparator sep
			$menu addSeparator sep2
		}

	$xAxisMenu  addCommand marker -label "Add marker" -command "$this addXMarker"
 	$x2AxisMenu addCommand marker -label "Add marker" -command "$this addX2Marker"
 	$yAxisMenu  addCommand marker -label "Add marker" -command "$this addYMarker"
	$yAxisMenu  addCheckbox log -label "Log scale" -callback "$this handleYLogScale" -value 0
 	$y2AxisMenu addCommand marker -label "Add marker" -command "$this addY2Marker"
	$y2AxisMenu addCheckbox log -label "Log scale" -callback "$this handleY2LogScale" -value 0

	$x2AxisMenu addCommand none -label None -before {"Add marker" -1} \
		-command "$this configure -x2Label {}" 	
	$y2AxisMenu addCommand none -label None -before {"Add marker" -1} \
		-command "$this configure -y2Label {}" 
	
	bind $itk_component(bltGraph) <Button-3> "$this popGraphMenu"

	# set up bindings for tracking mouse motion
	bind $itk_component(bltGraph) <Motion> "$this handleMouseMotion %x %y"

	# set up bindings for zooming
    setupZoomButton
	bind $itk_component(bltGraph) <Double-2> "$this zoomOut"

	# create the zoom stack
	set zoomStack [DCS::ZoomStack \#auto $itk_component(bltGraph)]
	
	# create a text marker to show coordinates of closest data point
	set datumMarker [DCS::TextMarker \#auto $this 0 0 -xOffset 5 -anchor w] 

	# create bags to hold x and y axis labels
	set xAxisLabelBag [DCS::Bag \#auto]
	set yAxisLabelBag [DCS::Bag \#auto]

	# creat the set to hold the ordered list of trace names
	set traceSet [DCS::Set \#auto]

	# create the cif object
	set cif [DCS::CifFile \#auto]

	after 500 "$this updateTable"

#	$itk_component(bltGraph) crosshairs on
#	$itk_component(bltGraph) crosshairs configure -hide 0 -color red -linewidth 2

	eval itk_initialize $args					
    if {!$itk_option(-noDelete)} {
	    $graphMenu addCommand deleteAll -label "Delete All Traces" -command "$this deleteAllTraces"
    }
	
	updateShownAxisLabels
}


body DCS::Graph::addYMarker {} {

	createHorizontalMarker [DCS::getUniqueName] \
		[$itk_component(bltGraph) axis invtransform y $_windowMouseY] $itk_option(-yLabel)
}


body DCS::Graph::addY2Marker {} {

	createHorizontalMarker [DCS::getUniqueName] \
		[$itk_component(bltGraph) axis invtransform y2 $_windowMouseY] $itk_option(-y2Label)
}


body DCS::Graph::addXMarker {} {

	createVerticalMarker [DCS::getUniqueName] \
		 [$itk_component(bltGraph) axis invtransform x $_windowMouseX] $itk_option(-xLabel)
}


body DCS::Graph::addX2Marker {} {

	createVerticalMarker [DCS::getUniqueName] \
		 [$itk_component(bltGraph) axis invtransform x2 $_windowMouseX] $itk_option(-x2Label)
}


body DCS::Graph::handleShowGrid { newValue } {

	if { $newValue } {
		set itk_option(-gridOn) 1
	} else {
		set itk_option(-gridOn) 0
	}

	updateGrid
}

body DCS::Graph::handleShowZero { newValue } {
    #puts "show zero $newValue"

    set m_showZero $newValue
    doConfigAxis 1
}

body DCS::Graph::handleYLogScale { newValue } {
    set m_yLogScale $newValue
    if {$m_yLogScale} {
        doConfigAxisLog y 1
    } else {
        doConfigAxisLinear y 1
    }
}
body DCS::Graph::handleY2LogScale { newValue } {
    set m_y2LogScale $newValue
    if {$m_y2LogScale} {
        doConfigAxisLog y2 1
    } else {
        doConfigAxisLinear y2 1
    }
}

body DCS::Graph::popGraphMenu {} {

	if { $eventSource != "" } {
		$eventSource popMenu
		set eventSource ""
		return
	}

	if { [$itk_component(bltGraph) inside $_windowMouseX $_windowMouseY] } {
		$graphMenu post
		return
	}

	if { $_windowMouseX < $graphHalfWidth && [$itk_component(bltGraph) inside $graphHalfWidth $_windowMouseY] } {
		$yAxisMenu post
		return
	}

	if { $_windowMouseX > $graphHalfWidth && [$itk_component(bltGraph) inside $graphHalfWidth $_windowMouseY] } {
		$y2AxisMenu post
		return
	}

	if { $_windowMouseY < $graphHalfHeight && [$itk_component(bltGraph) inside $_windowMouseX $graphHalfHeight] } {
		$x2AxisMenu post
		return
	}

	if { $_windowMouseY > $graphHalfHeight && [$itk_component(bltGraph) inside $_windowMouseX $graphHalfHeight] } {
		$xAxisMenu post
		return
	}
}

body DCS::Graph::createVerticalMarker { markerName initialX axisLabel args } {

	set lineMarker($markerName) [eval DCS::VerticalMarker \#auto $markerName \
											  $this $initialX [list $axisLabel] $args]
	$lineMarker($markerName) setShownAxisLabels $itk_option(-xLabel) $itk_option(-x2Label) $itk_option(-yLabel) $itk_option(-y2Label)
    return [$lineMarker($markerName) getObj]
}

body DCS::Graph::createCrosshairsMarker { markerName initialX initialY xAxisName yAxisName args } {

    #puts "createCrosshairsMarker  $markerName $initialX $initialY $xAxisName $yAxisName"
    #puts "createCrosshairsMarker $args"
	set lineMarker($markerName) [eval DCS::CrosshairsMarker \#auto $markerName \
	                		  $this $initialX $initialX [list $xAxisName] [list $yAxisName] $args]
	$lineMarker($markerName) setShownAxisLabels $itk_option(-xLabel) $itk_option(-x2Label) $itk_option(-yLabel) $itk_option(-y2Label)
    return [$lineMarker($markerName) getObj]
}

body DCS::Graph::configureCrosshairsMarker { markerName args } {

	eval $lineMarker($markerName) configure $args
}

body DCS::Graph::configureVerticalMarker { markerName args } {

	eval $lineMarker($markerName) configure $args
}


body DCS::Graph::createHorizontalMarker { markerName initialY axisLabel args } {

	set lineMarker($markerName) [eval DCS::HorizontalMarker \#auto $markerName \
												$this $initialY [list $axisLabel] $args]
	$lineMarker($markerName) setShownAxisLabels $itk_option(-xLabel) $itk_option(-x2Label) $itk_option(-yLabel) $itk_option(-y2Label)

    return [$lineMarker($markerName) getObj]
}


body DCS::Graph::configureHorizontalMarker { markerName args } {

	eval $lineMarker($markerName) configure $args
}


body DCS::Graph::createTextMarker { markerName initialX initialY args } {

	set textMarker($markerName) [eval DCS::TextMarker \#auto $this $initialX $initialY $args]
    return [$textMarker($markerName) getObj]
}


body DCS::Graph::configureTextMarker { markerName args } {

	eval $textMarker($markerName) configure $args
}


body DCS::Graph::createTrace { traceName xLabels passedXVector args } {
    #puts "createTrace $traceName"

	# create the new trace
	set trace($traceName) \
		[ eval DCS::Trace \#auto $traceName $this [list $xLabels] [list $passedXVector] $args]

	# add trace name to the set of traces
	$traceSet add $traceName

	# add a checkbox to the main menu
	$graphMenu addCheckbox $traceName -label "Show $traceName" \
		-callback "DCS::Graph::$trace($traceName) handleShowTrace" -value 1

	# add labels to the x axis label bag
	set newLabels [eval $xAxisLabelBag add $xLabels]

	# add new labels to the x axis menus
	foreach label $newLabels {
		$xAxisMenu addCommand $label -label $label -before {"Add marker" -1} \
			-command "$this configure -xLabel [list $label]"
		$x2AxisMenu addCommand $label -label $label -before {"Add marker" -1} \
			-command "$this configure -x2Label [list $label]"
	}

    return [$trace($traceName) getObj]
}


body DCS::Graph::reportDeletedTrace { traceName } {
    #puts "reportDeletedTrace $traceName"

	# delete menu entry for trace in main graph menu
	$graphMenu deleteEntry $traceName

	# remove from the trace array
	unset trace($traceName)

	# remove from trace set
	$traceSet remove $traceName
    doConfigAxis 1
}


body DCS::Graph::reportDeletedLineMarker { markerName } {

	# remove from the trace array
	unset lineMarker($markerName)
}


body DCS::Graph::createSubTrace { traceName subTraceName yLabels passedYVector args } {
    #puts "createSubTrace: $traceName $subTraceName"

    set result [eval $trace($traceName) createSubTrace $subTraceName \
		[list $yLabels] [list $passedYVector] $args]

	# add labels to the y axis label bag
	set newLabels [eval $yAxisLabelBag add $yLabels]

	# add new labels to the y axis menus
	foreach label $newLabels {
		$yAxisMenu addCommand $label -label $label -before {"Add marker" -1} \
			-command "$this configure -yLabel [list $label]"
		$y2AxisMenu addCommand $label -label $label -before {"Add marker" -1} \
			-command "$this configure -y2Label [list $label]"
	}

	updateShownAxisLabels
    return $result
}

body DCS::Graph::deleteSubTraces { subTraceName } {
	foreach traceName [$traceSet get] {
        $trace($traceName) deleteSubTrace $subTraceName
    }
	updateShownAxisLabels
}
body DCS::Graph::deleteAllOverlay { } {
	foreach traceName [$traceSet get] {
        set obj $trace($traceName)
        if {[$obj isOverlay]} {
		    delete object $obj
        }
    }
	updateShownAxisLabels
}
body DCS::Graph::makeOverlay { traceName overlayName } {
    if {[info exists trace($overlayName)]} {
        log_error overlay name $overlayName already exists.
        return
    }

    set src $trace($traceName)
    $src clone $overlayName "" 1
}

body DCS::Graph::deleteXLabels { xLabels } {

	# remove labels from the x axis label bag
	set oldLabels [eval $xAxisLabelBag remove $xLabels]

	# remove new labels from the y axis menus
	foreach label $oldLabels {
		$xAxisMenu deleteEntry $label
		$x2AxisMenu deleteEntry $label
	}

	updateShownAxisLabels
}


body DCS::Graph::deleteYLabels { yLabels } {

	# remove labels from the y axis label bag
	set oldLabels [eval $yAxisLabelBag remove $yLabels]

	# remove new labels from the y axis menus
	foreach label $oldLabels {
		$yAxisMenu deleteEntry $label
		$y2AxisMenu deleteEntry $label
	}

	updateShownAxisLabels
}

#change to easy for read, not care efficiency
body DCS::Graph::doConfigAxis { {force 0} } {
    if {$m_yLogScale} {
        doConfigAxisLog y $force
    } else {
        doConfigAxisLinear y $force
    }
    if {$m_y2LogScale} {
        doConfigAxisLog y2 $force
    } else {
        doConfigAxisLinear y2 $force
    }
}
body DCS::Graph::doConfigAxisLinear { axis force } {
    #puts "doConfigAxisLinear: $axis $force"

    set currentLabel ""
    set currentOn [ $itk_component(bltGraph) ${axis}axis cget -log]
    if {$force || $currentOn} {
        $itk_component(bltGraph) axis configure $axis -log 0
        if {[catch {
            if {[info exists itk_option(-${axis}Label)]} {
                $itk_component(bltGraph) axis configure $axis \
                -title $itk_option(-${axis}Label)

                set currentLabel $itk_option(-${axis}Label)
            }
        } errMsg]} {
            puts "ERROR1111: $errMsg"
        }
    }
    foreach {min max min2 max2} [getYMinMax $currentLabel] break

    if {$axis == "y2"} {
        set min $min2
        set max $max2
    }

    if {$force} {
        puts "min max for $axis: $min $max"
        if {!$m_showZero} {
            #puts "remove limits zero"
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
            puts "forced not show zero"
            return
        }
        #####show zero turned on ###########
        if {$min == "" || $max == ""} {
            #data not ready, no need
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
        } else {
            if {$min * $max > 0} {
                puts "add y limits zero: $min $max"
                if {$min > 0} {
                    $itk_component(bltGraph) axis configure $axis -min 0 -max ""
                } else {
                    $itk_component(bltGraph) axis configure $axis -min "" -max 0
                }
                set m_zeroSet($axis) 1
                set m_dataCrossZero($axis) 0
            } else {
                puts "data cross zero: $min $max"
                $itk_component(bltGraph) axis configure $axis -min "" -max ""
                set m_zeroSet($axis) 0
                set m_dataCrossZero($axis) 1
            }
        }
        return
    }

    ####not forced, only called by addToTrace#########
    if {!$m_showZero} {
        if {$m_zeroSet($axis)} {
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
        }
        return
    }

    ####### not forced, but showZero is on ########
    if {$min == "" || $max == "" } {
        if {$m_zeroSet($axis)} {
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
        }
    } elseif {!$m_dataCrossZero($axis)} {
        if {$min * $max > 0} {
            if {!$m_zeroSet($axis)} {
                puts "add limits zero: $min $max"
                if {$min > 0} {
                    $itk_component(bltGraph) axis configure $axis -min 0 -max ""
                } else {
                    $itk_component(bltGraph) axis configure $axis -min "" -max 0
                }
                set m_zeroSet($axis) 1
                set m_dataCrossZero($axis) 0
            }
        } else {
            puts "data cross zero: $min $max"
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
            set m_zeroSet($axis) 1
            set m_dataCrossZero($axis) 1
        }
    }
}

body DCS::Graph::doConfigAxisLog { axis force } {
    puts "doConfigAxisLog: $axis $force"
    set currentLabel ""
    if {[catch {
        if {[info exists itk_option(-${axis}Label)]} {
            set currentLabel $itk_option(-${axis}Label)
        }
    } errMsg]} {
        puts "ERROR1111: $errMsg"
    }
    foreach {min max min2 max2} [getYMinMax $currentLabel] break
    if {$axis == "y2"} {
        set min $min2
        set max $max2
    }
    if {$min != "" && $max != ""} {
        if {$min <= 0} {
            if {$max > 0} {
                log_error non-positive value with log scale
            } else {
                log_error all data are non-positive 
            }
        }
    }

    set currentOn [$itk_component(bltGraph) ${axis}axis cget -log]
    foreach {min max min2 max2} [getYMinMaxLog $currentLabel] break

    if {$axis == "y2"} {
        set min $min2
        set max $max2
    }

    if {$min == "" || $max == ""} {
        #data not ready, no need
        if {$force || !$currentOn} {
            $itk_component(bltGraph) axis configure $axis -min "" -max "" -log 1
        } else {
            $itk_component(bltGraph) axis configure $axis -min "" -max ""
        }
        set m_zeroSet($axis) 0
        set m_dataCrossZero($axis) 0
        return
    }

    puts "logscale min max: $min $max"
    ###now we know max >= min > 0

    if {$force} {
        if {!$m_showZero} {
            puts "set to all to empty"
            $itk_component(bltGraph) axis configure $axis -min "" -max "" -log 1
            if {[catch {
                if {[info exists itk_option(-${axis}Label)]} {
                    $itk_component(bltGraph) axis configure $axis \
                    -title "$itk_option(-${axis}Label) (log scale)"
                }
            } errMsg]} {
                puts "ERROR2222: $errMsg"
            }
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
            return
        }

        #####show zero turned on ###########
        if {$max <= 1} {
            $itk_component(bltGraph) axis configure $axis -min "" -max 1 -log 1
            set m_zeroSet($axis) 1
            set m_dataCrossZero($axis) 0
        } elseif {$min >= 1} {
            $itk_component(bltGraph) axis configure $axis -min 1 -max "" -log 1
            set m_zeroSet($axis) 1
            set m_dataCrossZero($axis) 0
        } else {
            $itk_component(bltGraph) axis configure $axis -min "" -max "" -log 1
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 1
        }
        if {[catch {
            if {[info exists itk_option(-${axis}Label)]} {
                $itk_component(bltGraph) axis configure $axis \
                -title "$itk_option(-${axis}Label) (log scale)"
            }
        } errMsg]} {
            puts "ERROR3333: $errMsg"
        }
        return
    }

    ####not forced, only called by addToTrace#########
    if {!$m_showZero} {
        if {$m_zeroSet($axis)} {
            $itk_component(bltGraph) axis configure $axis -min "" -max "" -log 1
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 0
        }
        return
    }

    ####### not forced, but showZero is on ########
    if {!$m_dataCrossZero($axis)} {
        if {$max <= 1} {
            if {!$m_zeroSet($axis)} {
                $itk_component(bltGraph) axis configure $axis \
                -min "" -max 1 -log 1
                set m_zeroSet($axis) 1
            }
        } elseif {$min >= 1} {
            if {!$m_zeroSet($axis)} {
                $itk_component(bltGraph) axis configure $axis \
                -min 1 -max "" -log 1
                set m_zeroSet($axis) 1
            }
        } else {
            $itk_component(bltGraph) axis configure $axis \
            -min "" -max "" -log 1
            set m_zeroSet($axis) 0
            set m_dataCrossZero($axis) 1
        }
    }
}

body DCS::Graph::addToTrace { traceName xValue yValues } { 

	$trace($traceName) add $xValue $yValues

    doConfigAxis

    if {$itk_option(-onXAxisChange) != ""} {
        if {[catch {
            eval $itk_option(-onXAxisChange)
        } errMsg]} {
            puts "onXAxisChange error: $errMsg"
        }
    }
 }   
body DCS::Graph::getPeaks { } {
    set resultList ""
    if {![info exist traceSet]} {
        return $resultList
    }
	foreach traceName [$traceSet get] {
		set pp [$trace($traceName) getPeaks]
        lappend resultList $pp
    }
    puts "getPeaks result: $resultList"
    return $resultList
}
body DCS::Graph::getXMinMax { } { 
    if {![info exist traceSet]} {
        return [list 0 0]
    }

    set x_min ""
    set x_max ""
	foreach traceName [$traceSet get] {
		foreach {min max } [$trace($traceName) getXMinMax] break
        if {$min != "" && ($x_min == "" || $x_min > $min)} {
            set x_min $min
        }
        if {$max != "" && ($x_max == "" || $x_max < $max)} {
            set x_max $max
        }
	}
    return [list $x_min $x_max]
}

body DCS::Graph::getYMinMax { currentYLabel } {
    if {![info exist traceSet]} {
        return [list "" "" "" ""]
    }

    set y_min ""
    set y_max ""
    set y2_min ""
    set y2_max ""
    #puts "getYMinMax: traces: [$traceSet get]"
	foreach traceName [$traceSet get] {
		foreach {min max min2 max2} [$trace($traceName) getYMinMax $currentYLabel] break
        #puts "trace $traceName: $min $max $min2 $max2"
        if {$min != "" && ($y_min == "" || $y_min > $min)} {
            set y_min $min
        }
        if {$max != "" && ($y_max == "" || $y_max < $max)} {
            set y_max $max
        }
        if {$min2 != "" && ($y2_min == "" || $y2_min > $min2)} {
            set y2_min $min2
        }
        if {$max2 != "" && ($y2_max == "" || $y2_max < $max2)} {
            set y2_max $max2
        }
	}
    #puts "final: $y_min $y_max $y2_min $y2_max"
    return [list $y_min $y_max $y2_min $y2_max]
}

body DCS::Graph::getYMinMaxLog { currentYLabel } { 
    puts "getYMinMaxLog for $this with label=$currentYLabel"
    if {![info exist traceSet]} {
        return [list "" "" "" ""]
    }

    set y_min ""
    set y_max ""
    set y2_min ""
    set y2_max ""
    #puts "getYMinMax: traces: [$traceSet get]"
	foreach traceName [$traceSet get] {
		foreach {min max min2 max2} [$trace($traceName) getYMinMaxLog $currentYLabel] break
        #puts "trace $traceName: $min $max $min2 $max2"
        if {$min != "" && ($y_min == "" || $y_min > $min)} {
            set y_min $min
        }
        if {$max != "" && ($y_max == "" || $y_max < $max)} {
            set y_max $max
        }
        if {$min2 != "" && ($y2_min == "" || $y2_min > $min2)} {
            set y2_min $min2
        }
        if {$max2 != "" && ($y2_max == "" || $y2_max < $max2)} {
            set y2_max $max2
        }
	}
    puts "final: $y_min $y_max $y2_min $y2_max"
    return [list $y_min $y_max $y2_min $y2_max]
}

body DCS::Graph::configureTrace { traceName args } {

	eval $trace($traceName) configure $args
}


body DCS::Graph::configureSubTrace { traceName subTraceName args } {

	eval $trace($traceName) configureSubTrace $subTraceName $args
}


body DCS::Graph::createRectangle {} {

	$itk_component(bltGraph) marker create line -name "ZoomRegion" \
		-dashes { 4 2 }
}


body DCS::Graph::drawRectangle { x0 y0 x1 y1 } {

	$itk_component(bltGraph) marker configure "ZoomRegion" \
		-coords "$x0 $y0 $x1 $y0 $x1 $y1 $x0 $y1 $x0 $y0" \
		-under yes
}


body DCS::Graph::destroyRectangle {} {

	$itk_component(bltGraph) marker delete "ZoomRegion"
}


body DCS::Graph::getElementInfoFromName { element } {

	foreach traceName [array names trace] {
		set axes [$trace($traceName) getElementInfoFromName $element]
		if { $axes != "" } {
			return $axes
		}
	}

	error "No matching trace found!"
}


body DCS::Graph::handleMouseMotion { x y } {

	set _windowMouseX $x
	set _windowMouseY $y
	set graphMouseX [$itk_component(bltGraph) axis invtransform x $x]
	set graphMouseY [$itk_component(bltGraph) axis invtransform y $y]
	set screenMouseX [winfo pointerx .]
	set screenMouseY [winfo pointery .]

	if { ! $itk_option(-hideDatumMarker) && [$itk_component(bltGraph) element closest $x $y info] } {

		# get information about the subtrace
		set elementInfo [getElementInfoFromName $info(name)]
		
		# extract trace properties from elementInfo string
		set traceXAxis [lindex $elementInfo 0]
		set traceYAxis [lindex $elementInfo 1]
		set traceColor [lindex $elementInfo 2]

		# update the text marker appearance
		$datumMarker configure \
			-text [format "(%0.5g, %0.5g)" $info(x) $info(y)] \
			-foreground $traceColor \
			-xAxis $traceXAxis  	\
			-yAxis $traceYAxis 	\
			 -background $itk_option(-plotbackground) \
			-font $itk_option(-tickFont) \
			-hide 0

		# update the text marker location
		$datumMarker moveTo $info(x) $info(y)

		# set the colors of the axes associated with the trace to match the trace
		resetAxisColors 
		foreach axis "$traceXAxis $traceYAxis" {
			$itk_component(bltGraph) axis configure $axis 	\
				-color $traceColor -titlecolor $traceColor
		}

	} else {
		if { [$datumMarker cget -hide] == "0" } {
			$datumMarker configure -hide 1
			resetAxisColors
		}
	}
}


body DCS::Graph::resetAxisColors {} {

	foreach axis {x x2 y y2 } {
		if { $axisUsageCount($axis) == 0 } {
			$itk_component(bltGraph) axis configure $axis \
				-color $darkgrey -titlecolor $darkgrey	-showticks 0	
		} else {
			$itk_component(bltGraph) axis configure $axis \
				-color black -titlecolor black -showticks 1
		}
	} 
}


body DCS::Graph::getGraphCoordinates { screenX screenY graphX graphY graphX2 graphY2 } {

	upvar $graphX x
	upvar $graphY y
	upvar $graphX2 x2
	upvar $graphY2 y2

	# get graph coordinates in terms of the x and y axes
	set x [$itk_component(bltGraph) axis invtransform x $screenX]
	set y [$itk_component(bltGraph) axis invtransform y $screenY]

	# get graph coordinates in terms of the x2 and y2 axes
	set x2 [$itk_component(bltGraph) axis invtransform x2 $screenX]
	set y2 [$itk_component(bltGraph) axis invtransform y2 $screenY]
}


body DCS::Graph::zoomSelectStart { x y } {
	
	if { [$itk_component(bltGraph) inside $x $y] } {
		getGraphCoordinates $x $y zoomX zoomY zoomX2 zoomY2
		createRectangle

        ###############
        #to avoid confusion between move crosshairs marker and zoom selection
        set inZoom 1
	} else {
		set cancelZoom 1
	}
}


body DCS::Graph::zoomSelectMove { x y } {
    if { ! $inZoom } return

	if { ! $cancelZoom } {
		getGraphCoordinates $x $y x1 y1 dummy1 dummy2
		drawRectangle $zoomX $zoomY $x1 $y1
	}
}


body DCS::Graph::zoomSelectEnd { x y } {
    if { ! $inZoom } return
    set inZoom 0

	if { ! $cancelZoom } {
		set x2 0
		set y2 0
		getGraphCoordinates $x $y x1 y1 x2 y2
		destroyRectangle
		zoomIn $x1 $y1 $x2 $y2
	}

	set cancelZoom 0
}

body DCS::Graph::isInZoom { } {
	if {[$zoomStack isEmpty]} {
        return 0
    } else {
        return 1
    }
}

body DCS::Graph::setZoomDefaultX { minX maxX } {

	 # first zoom out all the way
	 zoomOutAll

	 # now set the default x axis min and max
	 $itk_component(bltGraph) axis configure x -min $minX -max $maxX

}

body DCS::Graph::manualSetZoom { x0 y0 x1 y1 } {
	$zoomStack push 	[$itk_component(bltGraph) xaxis cget -min] [$itk_component(bltGraph) xaxis cget -max ] \
							[$itk_component(bltGraph) yaxis cget -min] [$itk_component(bltGraph) yaxis cget -max ]	\
							[$itk_component(bltGraph) x2axis cget -min] [$itk_component(bltGraph) x2axis cget -max ] \
							[$itk_component(bltGraph) y2axis cget -min] [$itk_component(bltGraph) y2axis cget -max ]

    if {$x0 == $x1} {
        set x1 [expr $x0 + 1.0]
    }
    if {$y0 == $y1} {
        set y1 [expr $y0 + 1.0]
    }

	# set the x axis limits 
	if { $x0 > $x1 } {
		$itk_component(bltGraph) axis configure x -min $x1 -max $x0
	} else {
		$itk_component(bltGraph) axis configure x -min $x0 -max $x1
	}

	# set the y axis limits
	if { $y0 > $y1 } {
		$itk_component(bltGraph) axis configure y -min $y1 -max $y0
	} else {
		$itk_component(bltGraph) axis configure y -min $y0 -max $y1
	}
}
body DCS::Graph::zoomIn { x1 y1 x2 y2 } {

	# make sure zoom box is really a rectangle
	if { ($zoomX == $x1) || ($zoomY == $y1 ) } {
		return
	}

	# push the current axis limits on the zoom stack
	$zoomStack push 	[$itk_component(bltGraph) xaxis cget -min] [$itk_component(bltGraph) xaxis cget -max ] \
							[$itk_component(bltGraph) yaxis cget -min] [$itk_component(bltGraph) yaxis cget -max ]	\
							[$itk_component(bltGraph) x2axis cget -min] [$itk_component(bltGraph) x2axis cget -max ] \
							[$itk_component(bltGraph) y2axis cget -min] [$itk_component(bltGraph) y2axis cget -max ]

	# set the x axis limits 
	if { $zoomX > $x1 } {
		$itk_component(bltGraph) axis configure x -min $x1 -max $zoomX
		$itk_component(bltGraph) axis configure x2 -min $x2 -max $zoomX2
	} else {
		$itk_component(bltGraph) axis configure x -min $zoomX -max $x1
		$itk_component(bltGraph) axis configure x2 -min $zoomX2 -max $x2
	}

	# set the y axis limits
	if { $zoomY > $y1 } {
		$itk_component(bltGraph) axis configure y -min $y1 -max $zoomY
		$itk_component(bltGraph) axis configure y2 -min $y2 -max $zoomY2
	} else {
		$itk_component(bltGraph) axis configure y -min $zoomY -max $y1
		$itk_component(bltGraph) axis configure y2 -min $zoomY2 -max $y2
	}
}


body DCS::Graph::zoomOut {} {

	eval [$zoomStack pop]
}


body DCS::Graph::zoomOutAll {} {

	eval [$zoomStack popAll]

	$itk_component(bltGraph) xaxis configure \
    -min "" -max ""
	$itk_component(bltGraph) yaxis configure \
    -min "" -max ""
	$itk_component(bltGraph) x2axis configure \
    -min "" -max ""
	$itk_component(bltGraph) y2axis configure \
    -min "" -max ""
}


body DCS::Graph::setXPosition { args } {

	eval $itk_component(bltGraph) axis view x $args
	eval $itk_component(bltGraph) axis view x2 $args
}


body DCS::Graph::setYPosition { args } {

	eval $itk_component(bltGraph) axis view y $args
	eval $itk_component(bltGraph) axis view y2 $args
}


body DCS::Graph::updateTable {} {

    blt::table configure $itk_component(ring) c0 -width [$itk_component(bltGraph) extents leftmargin]
    blt::table configure $itk_component(ring) c2 -width [$itk_component(bltGraph) extents rightmargin]
    blt::table configure $itk_component(ring) r1 -height [$itk_component(bltGraph) extents topmargin]
    blt::table configure $itk_component(ring) r3 -height [$itk_component(bltGraph) extents bottommargin]

	set graphHalfHeight [expr [winfo height $itk_component(ring)] / 2]
	set graphHalfWidth [expr [winfo width $itk_component(ring)] / 2]
}


body DCS::Graph::updateShownAxisLabels {} {

	set axisUsageCount(x) 0
	set axisUsageCount(x2) 0
	set axisUsageCount(y) 0
	set axisUsageCount(y2) 0

	# activate all line markers that match current axis labels
	foreach markerName [array names lineMarker] {
		$lineMarker($markerName) setShownAxisLabels $itk_option(-xLabel) $itk_option(-x2Label) $itk_option(-yLabel) $itk_option(-y2Label)
	}

	# activate all sub-traces that match current axis labels 
	if { [array names trace] != {} } {
		foreach traceName [array names trace] {
			set usageCounts [$trace($traceName) setShownAxisLabels $itk_option(-xLabel) $itk_option(-x2Label) $itk_option(-yLabel) $itk_option(-y2Label)]
			
			foreach axis {x x2 y y2} usageCount $usageCounts {
				incr axisUsageCount($axis) $usageCount
			}
		}
	}

	foreach axis {x x2 y y2} {
		if { $axisUsageCount($axis) == 0 } {
			[set [set axis]AxisMenu] configureEntry marker -state disabled
		} else {
			[set [set axis]AxisMenu] configureEntry marker -state normal
		}
	}

	# configure grid based on current axis usages
	updateGrid

	# set axis colors back to defaults
	resetAxisColors

    #show zero
    doConfigAxis 1
}


body DCS::Graph::updateGrid {} {

	if { $itk_option(-gridOn) == "" } return

	# turn off grid if no traces shown
	if { ! $itk_option(-gridOn) || ($axisUsageCount(x) == 0 && $axisUsageCount(x2) == 0) } {
		$itk_component(bltGraph) grid off
		return
	}

	# bind grid to x axis if in use, to x2 axis otherwise
	if { $axisUsageCount(x) > 0 } {
		$itk_component(bltGraph) grid configure -mapx x
	} else {
		$itk_component(bltGraph) grid configure -mapx x2
	}

	# bind grid to y axis if in use, to y2 axis otherwise
	if { $axisUsageCount(y) > 0 } {
		$itk_component(bltGraph) grid configure -mapy y
	} else {
		$itk_component(bltGraph) grid configure -mapy y2
	}

	# turn on the grid
	$itk_component(bltGraph) grid on
}


configbody DCS::Graph::xLabel {

	if { $itk_option(-xLabel) == "" } {
		error
	}

	zoomOutAll

	$itk_component(bltGraph) axis configure x -hide 0 -title $itk_option(-xLabel)

	updateShownAxisLabels
}


configbody DCS::Graph::yLabel {

	if { $itk_option(-yLabel) == "" } {
		error
	}

	zoomOutAll
	updateShownAxisLabels
}


configbody DCS::Graph::x2Label {
	zoomOutAll
	
	if { $itk_option(-x2Label) != "" } {
		$itk_component(bltGraph) axis configure x2 -hide 0 -title $itk_option(-x2Label)
	} else {
		$itk_component(bltGraph) axis configure x2 -hide 1
	}
	
	updateShownAxisLabels
	
}


configbody DCS::Graph::y2Label {
	
	zoomOutAll

	if { $itk_option(-y2Label) != "" } {
		$itk_component(bltGraph) axis configure y2 -hide 0
	} else {
		$itk_component(bltGraph) axis configure y2 -hide 1
	}

	updateShownAxisLabels
}


configbody DCS::Graph::plotbackground {
	if {$itk_option(-plotbackground) != "" } {
		$itk_component(bltGraph) configure -plotbackground $itk_option(-plotbackground)
	}
}


configbody DCS::Graph::title {

	$itk_component(bltGraph) configure -title $itk_option(-title)
	$itk_component(bltGraph) configure -font "Helvetica 12 bold"

    set fg black
    if {[regexp -nocase warn|error|fail $itk_option(-title)]} {
        set fg red
    }
	$itk_component(bltGraph) configure -foreground $fg
}



##########################################################################

class DCS::ZoomStack {

	# public member functions
	public method constructor { associatedBLTGraph }
	public method isEmpty {}
	public method push { xMin xMax yMin yMax x2Min x2Max y2Min y2Max }
	public method pop {}
	public method popAll {}

	# private data members
	private variable BLTGraph ""
	private variable zoomStack	""
}


body DCS::ZoomStack::constructor { associatedBLTGraph } {
	
	set BLTGraph $associatedBLTGraph
}


body DCS::ZoomStack::isEmpty {} {

	return [ expr { [llength $zoomStack] == 0 }]
}


body DCS::ZoomStack::push { xMin xMax yMin yMax x2Min x2Max y2Min y2Max } {

	set command {
		$BLTGraph xaxis configure -min "%s" -max "%s"
		$BLTGraph yaxis configure -min "%s" -max "%s"
		$BLTGraph x2axis configure -min "%s" -max "%s"
		$BLTGraph y2axis configure -min "%s" -max "%s"
	}
	lappend zoomStack [subst [format $command $xMin $xMax $yMin $yMax $x2Min $x2Max $y2Min $y2Max ]]
}


body DCS::ZoomStack::pop {} {

	set command [lindex $zoomStack end]
	set zoomStack [lreplace $zoomStack end end]
	return $command
}

body DCS::ZoomStack::popAll {} {

	set command [lindex $zoomStack 0]
	set zoomStack ""

    #DEBUG:
    puts "popAll: $command"
	
	return $command
}


##########################################################################
# The class GraphAttribute defines a base class for objects that may be
# displayed in a Graph.  The classes Trace and Marker, two distinct types
# of graph attributes are derived from GraphAttribute.
#
# GraphAttribute encapsulates the storage and assignment of the Graph
# associated with the GraphAttribute as well as the underlying blt::graph.
##########################################################################

class DCS::GraphAttribute {

	# public member functions
	public method constructor { containingGraph } 

	# protected data members
	protected variable graph
	protected variable BLTGraph

	# public data members (accessed via -configure)
	public variable xAxis x { updateXAxis } 
	public variable hide 0 { updateHide }
	public variable after "" { updateAfter }

	# public variable update functions
	protected method updateXAxis {} {}
	protected method updateHide {} {}
	protected method updateAfter {} {}
}


body DCS::GraphAttribute::constructor { containingGraph } {

	# store the name of the containing Graph
	set graph $containingGraph

	# get the name of the associated BLT::graph
	set BLTGraph [$graph getBltGraph]
}


##########################################################################
# The class Marker defines a base class from with the classes TextMarker 
# and LineMarker are derived.  Marker inherits from GraphAttribute.
# Marker encapsulates the underlying blt marker associated with these
# classes.
##########################################################################

class DCS::Marker {

	# inheritance
	inherit DCS::GraphAttribute

	# constructor
	constructor { containingGraph } {
		DCS::GraphAttribute::constructor $containingGraph
	} {
	}
    
    public method getObj { } { return $this }
    public method getBltMarker { } { return $BLTMarker }

	# private data members
	protected variable BLTMarker
	public variable yAxis y { updateYAxis }
	public variable callback {}

	# public variable update functions
	protected method updateYAxis {} {}
}




##########################################################################
# The TextObject class encapsulates generic properties of text objects
# displayed on canvases.  It includes both the text to be drawn as well
# as the colors, font, and justification to use.
##########################################################################

class TextObject {

	# public data members (accessed via -configure)
	public variable text "" { updateText }
	public variable font "" { updateFont }
	public variable foreground "black" { updateForeground }
	public variable background "white" { updateBackground }
	public variable anchor "center" { updateAnchor }

	# public variable update functions
	protected method updateText {} {}
	protected method updateFont {} {}
	protected method updateForeground {} {}
	protected method updateBackground {} {}
	protected method updateAnchor {} {}
}


##########################################################################
# The TextMarker class manages a blt text marker in a Graph.  It inherits
# the generic text object properies from TextObject, and generic blt
# marker properties from Marker.
##########################################################################

class DCS::TextMarker {

	# inheritance
	inherit DCS::Marker TextObject

	# constructor
	constructor { containingGraph initialX initialY args} {	
		Marker::constructor $containingGraph
	} {
		# create the marker 
		set BLTMarker [$BLTGraph marker create text -under 0]

		# store the initial coordinates of the marker
		set x $initialX
		set y $initialY
		
		# set up bindings for dragging marker with middle button
		$BLTGraph marker bind $BLTMarker <B2-Motion> "$this drag %x %y"
		$BLTGraph marker bind $BLTMarker <Button-3> "$containingGraph setEventSource $this"

		# handle configuration options
		eval configure $args
		
		# draw the marker
		update		
	}

	destructor {
		
		# delete the BLT text marker
		$BLTGraph marker delete $BLTMarker
	}

	# public member functions
	public method moveTo { newX newY }
	public method update {}
	public method drag { x y }
	public method popMenu {} {}

	# public data members (accessed via -configure)
	public variable xOffset 0 { updateXOffset }
	public variable yOffset 0 { updateYOffset }

	# private data members
	protected variable x
	protected variable y

	# public variable update functions
	protected method updateXAxis {}
	protected method updateYAxis {}
	protected method updateHide {}
	protected method updateText {} 
	protected method updateFont {} 
	protected method updateForeground {} 
	protected method updateBackground {}
	protected method updateAnchor {}
	protected method updateXOffset {}
	protected method updateYOffset {}
}


body DCS::TextMarker::moveTo { newX newY } {

	# store the new x-ordinate of the marker
	set x $newX
	set y $newY

	# redraw the marker
	update
}


body DCS::TextMarker::updateXAxis {} {

	$BLTGraph marker configure $BLTMarker -mapx $xAxis
	update
}


body DCS::TextMarker::updateYAxis {} {

	$BLTGraph marker configure $BLTMarker -mapy $yAxis
	update
}


body DCS::TextMarker::updateHide {} {

	$BLTGraph marker configure $BLTMarker -hide $hide
	update
}


body DCS::TextMarker::updateAnchor {} {

	$BLTGraph marker configure $BLTMarker -anchor $anchor
	update
}


body DCS::TextMarker::updateXOffset {} {

	$BLTGraph marker configure $BLTMarker -xoffset $xOffset
	update
}


body DCS::TextMarker::updateYOffset {} {

	$BLTGraph marker configure $BLTMarker -yoffset $yOffset
	update
}


body DCS::TextMarker::updateForeground {} {

	$BLTGraph marker configure $BLTMarker -foreground $foreground
}


body DCS::TextMarker::updateFont {} {

	$BLTGraph marker configure $BLTMarker -font $font
}


body DCS::TextMarker::updateText {} {

	$BLTGraph marker configure $BLTMarker -text $text
}


body DCS::TextMarker::updateBackground {} {
	$BLTGraph marker configure $BLTMarker -background $background
}


body DCS::TextMarker::update {} {

	# redraw the marker
	$BLTGraph marker configure $BLTMarker \
		-coords "$x $y"
	$BLTGraph marker before $BLTMarker
}


body DCS::TextMarker::drag { x y } {
	
	set coords [$BLTGraph invtransform $x $y]
	eval moveTo $coords
}


##########################################################################
# The LineMarker class manages a blt line marker in a Graph.  It inherits
# the generic blt marker properties from Marker.  LineMarkers are never
# instantiated.  Instead, the classes HorizontalMarker and VerticalMarker
# inherit common properteis from LineMarker.
##########################################################################

class DCS::LineMarker {

	# inheritance
	inherit DCS::Marker

	# constructor
	constructor { markerName containingGraph initialPosition axisLabel } {
		Marker::constructor $containingGraph
	} {
		# store the marker name
		set name $markerName

		# store the axis label
		set label $axisLabel

		# store the initial x-ordinate of the marker
		set position $initialPosition
		
		# create the marker
		set BLTMarker [$BLTGraph marker create line -hide 1]

		# set up bindings for dragging marker with middle button
		$BLTGraph marker bind $BLTMarker <B2-Motion> \
			"$graph configure -hideDatumMarker 1; $this drag %x %y"
		
		# create the context menu for the subtrace
		set menu [DCS::PopupMenu \#auto]
		$menu addLabel title -label "$label marker"
		$menu addSeparator sep

		# create the color cascade menu
		set colorMenu [$menu addCascade color -label "Set color"]
		foreach colorChoice { black red green blue purple brown orange pink } \
			rgb { \#000000 \#cc0000 \#00aa00 \#0000dd \#6600aa \#aa4444 \#ee5555 \#ff8888 } {
			$colorMenu addCommand $colorChoice -label $colorChoice \
				-foreground $rgb -activeforeground $rgb \
				-command "$this configure -color $rgb"
		}
		
		# create the line width cascade menu
		set thicknessMenu [$menu addCascade thickness -label "Set line thickness"]
		foreach size { 0 1 2 3 4 5 6} {
			$thicknessMenu addCommand $size -label $size \
				-command "$this configure -width $size"
		}

		# add delete entry to menu
		$menu addSeparator sep2
		$menu addCommand delete -label "Delete" \
			-command "delete object $this"

		$BLTGraph marker bind $BLTMarker <Button-3> "$containingGraph setEventSource $this"
		
		# create a text marker to show position while dragging line marker
		set textMarker [ DCS::TextMarker \#auto $graph 0 0 \
								  -background [$BLTGraph cget -plotbackground]\
								  -font [$containingGraph cget -tickFont]] 
		$BLTGraph marker bind $BLTMarker <ButtonRelease> \
			"$this hideTextMarker; $graph configure -hideDatumMarker 0"
		
		# draw the line marker
		update
	}

	destructor {

		# delete the BLT line marker
		$BLTGraph marker delete $BLTMarker

		# delete the associated text marker
		delete object $textMarker

		# delete the popup menu
		delete object $menu

		# report deletion to graph
		$graph reportDeletedLineMarker $name
	}

	# public member functions
	public method moveTo { newPosition }
	public method update {}
	public method drag { x y }
	public method hideTextMarker {}
	public method popMenu {}

    public method removeTextMarker { } {
        set m_alwaysHideTextMarker 1
        hideTextMarker
    }

    public method no_drag { } {
		$BLTGraph marker bind $BLTMarker <B2-Motion> ""
	    $BLTGraph marker bind $BLTMarker <ButtonRelease> ""
    }

    public method getTextMarker { } { return [$textMarker getObj] }

    public method setTitle { title } {
		$menu configureEntry title -label $title
    }

	# public data members (accessed via -configure)
	public variable color "black" { updateColor }
	public variable width 1 { updateWidth }
	public variable dashes {} { updateDashes }
#	public variable callback "" { udpateCallback }
	public variable label "" { error }
	public variable position
	public variable type "" { error }
	public variable textformat "%0.5g"

	# private data members
	protected variable name
	protected variable menu

	protected variable textMarker
	protected variable axis
	protected variable m_alwaysHideTextMarker 0

	# private member functions
	public method getTextMarkerCoords {}

	# public variable update functions
	protected method updateColor {}
	protected method updateWidth {}
	protected method updateDashes {} {
	    $BLTGraph marker configure $BLTMarker -dashes $dashes
    }
	protected method updateCallback {}
	protected method updatePosition {}
    protected method updateHide {} {
	    $BLTGraph marker configure $BLTMarker -hide $hide
	    update
    }
    protected method updateAfter {} {
	    eval $BLTGraph marker after $BLTMarker $after
	    update
    }
}



body DCS::LineMarker::popMenu {} {
	$menu post
}


body DCS::LineMarker::hideTextMarker {} {

	$textMarker configure -hide 1
	update
}


body DCS::LineMarker::getTextMarkerCoords {} {

	set x [expr [$graph getWindowMouseX] + 0 ]
	set y [expr [$graph getWindowMouseY] - 20 ]

	return [$BLTGraph invtransform $x $y]
}

configbody DCS::LineMarker::position {
	update
}

body DCS::LineMarker::moveTo { newPosition } {

	# store the new x-ordinate of the marker
	set position $newPosition

	# update the text marker
	$textMarker configure \
		-text [format $textformat $newPosition] \
		-foreground $color

	eval $textMarker moveTo [getTextMarkerCoords]
	$textMarker configure -hide $m_alwaysHideTextMarker
	
	# redraw the marker
	update
}


body DCS::LineMarker::updateColor {} {

	$BLTGraph marker configure $BLTMarker -outline $color
}


body DCS::LineMarker::updateWidth {} {

	$BLTGraph marker configure $BLTMarker -linewidth $width
}


body DCS::LineMarker::update {} {

	# call the callback function
	#eval $callback
}


##########################################################################
# The VerticalMarker class derives a vertical line from the 
# LineMarker class.
##########################################################################

class DCS::VerticalMarker {

	inherit DCS::LineMarker

	# public member functions
	constructor { markerName containingGraph initialX axisLabel args } {
		set axis x
		LineMarker::constructor $markerName $containingGraph $initialX $axisLabel
	} {
		# set marker type
		set type "vertical"

		# apply optional configuration options
		eval configure $args
	}
	
	public method update {}
	public method drag { x y }
	public method setShownAxisLabels { xLabel x2Label yLabel y2Label }
}


body DCS::VerticalMarker::setShownAxisLabels { xLabel x2Label yLabel y2Label } {

	if { $xLabel == $label } {
		set axis x
		$BLTGraph marker configure $BLTMarker -mapx x -hide 0
		return
	}

	if { $x2Label == $label } {
		set axis x2
		$BLTGraph marker configure $BLTMarker -mapx x2 -hide 0
		return
	}
	
	$BLTGraph marker configure $BLTMarker -hide 1
}


body DCS::VerticalMarker::drag { x y } {
	
	set newPosition [$BLTGraph axis invtransform $axis $x]
	moveTo $newPosition
	if { $callback != {} } {
		uplevel $callback $newPosition
	}
}


body DCS::VerticalMarker::update {} {

	$BLTGraph marker configure $BLTMarker \
		-mapx $axis \
		-coords "$position -Inf $position Inf"

	LineMarker::update
}


##########################################################################
# The HorizontalMarker class derives a horizontal line from the 
# LineMarker class.
##########################################################################

class DCS::HorizontalMarker {

	inherit DCS::LineMarker

	# public member functions
	constructor { markerName containingGraph initialY axisLabel args } {
		set axis y
		LineMarker::constructor $markerName $containingGraph $initialY $axisLabel
	} {
		# set marker type
		set type "horizontal"

		# apply optional configuration options
		eval configure $args
	}

	public method update {}
	public method drag { x y }
	public method setShownAxisLabels { xLabel x2Label yLabel y2Label }
}


body DCS::HorizontalMarker::setShownAxisLabels { xLabel x2Label yLabel y2Label } {

	if { $yLabel == $label } {
		set axis y
		$BLTGraph marker configure $BLTMarker -mapy y -hide 0
		return
	}

	if { $y2Label == $label } {
		set axis y2
		$BLTGraph marker configure $BLTMarker -mapy y2 -hide 0
		return
	}


	$BLTGraph marker configure $BLTMarker -hide 1
}


body DCS::HorizontalMarker::drag { x y } {

	set newPosition [$BLTGraph axis invtransform $axis $y]
	moveTo $newPosition
	if { $callback != {} } {
		uplevel $callback $newPosition
	}
}


body DCS::HorizontalMarker::update {} {

	# redraw the marker
	$BLTGraph marker configure $BLTMarker \
		-mapy $axis \
		-coords "-Inf $position Inf $position"

	LineMarker::update
}

##########################################################################
# CrosshairsMarker is derived from Marker.
# it cannot derived from LineMarker because each LineMarker
# already has one textMarker
##########################################################################
class DCS::CrosshairsMarker {
	# inheritance
	inherit DCS::Marker

	# constructor
	constructor { markerName containingGraph initialX initialY xLabel yLabel args} {
		Marker::constructor $containingGraph
	} {
        #puts "CrosshairsMarker  $markerName $containingGraph $initialX $initialY {$xLabel} {$yLabel}"
        #puts "CrosshairsMarker $args"
		set axis [list x y]
		# store the marker name
		set name $markerName

		# store the axis label
		set label [list $xLabel $yLabel]

		# store the initial x-ordinate of the marker
		set position [list $initialX $initialY]
		
		# create the marker
		set my_mark1 [$BLTGraph marker create line -hide 1]
		set my_mark2 [$BLTGraph marker create line -hide 1]
		set BLTMarker [list $my_mark1 $my_mark2]

		# create the context menu for the subtrace
		set menu [DCS::PopupMenu \#auto]
		$menu addLabel title -label "$label marker"
		$menu addSeparator sep

		# create the color cascade menu
		set colorMenu [$menu addCascade color -label "Set color"]
		foreach colorChoice { black red green blue purple brown orange pink } \
			rgb { \#000000 \#cc0000 \#00aa00 \#0000dd \#6600aa \#aa4444 \#ee5555 \#ff8888 } {
			$colorMenu addCommand $colorChoice -label $colorChoice \
				-foreground $rgb -activeforeground $rgb \
				-command "$this configure -color $rgb"
		}
		
		# create the line width cascade menu
		set thicknessMenu [$menu addCascade thickness -label "Set line thickness"]
		foreach size { 0 1 2 3 4 5 6} {
			$thicknessMenu addCommand $size -label $size \
				-command "$this configure -width $size"
		}

		# add delete entry to menu
		$menu addSeparator sep2
		$menu addCommand delete -label "Hide" \
			-command "$this configure -hide 1"

		$BLTGraph marker bind $my_mark1 <Button-3> "$containingGraph setEventSource $this"
		$BLTGraph marker bind $my_mark2 <Button-3> "$containingGraph setEventSource $this"
		
		# create a text marker to show position while dragging line marker
		set textMarker [ DCS::TextMarker \#auto $graph 0 0 \
                                  -yOffset -10 \
								  -background ""\
								  -font [$containingGraph cget -tickFont]] 

		# create a text marker to show delta if enabled
		set deltaMarker [ DCS::TextMarker \#auto $graph 0 0 \
                                  -yOffset 10 \
								  -background ""\
								  -font [$containingGraph cget -tickFont]] 

		# draw the line marker
		update

		eval configure $args
	}

	destructor {
		# delete the BLT line marker
        foreach line $BLTMarker {
		    $BLTGraph marker delete $line
        }

		# delete the associated text marker
		delete object $textMarker
		delete object $deltaMarker

		# delete the popup menu
		delete object $menu

		# report deletion to graph
		$graph reportDeletedLineMarker $name
	}

	# public member functions
	public method setShownAxisLabels { xLabel x2Label yLabel y2Label }
	public method moveTo { newX newY }
	public method update {}
	public method drag { x y }
	public method popMenu {}

    public method getTextMarker { } { return [$textMarker getObj] }

    public method hideDelta { } {
	    $deltaMarker configure -hide 1
        update
    }

    public method followFirstOrSecondMark { }

	# public data members (accessed via -configure)
	public variable color "black" { updateColor }
	public variable width 1 { updateWidth }
	public variable dashes {} { updateDashes }
#	public variable callback "" { udpateCallback }
	public variable label "" { error }
	public variable position
	public variable type "crosshairs" { error }
	public variable textformat "%0.5g %.5g"

    #if pair is defined and visible, the deltaMarker will be displayed
	public variable pair ""

    public variable thirdPercentMark ""
    ## this is also a flag
    public variable percent ""
    public variable firstMark ""
    public variable secondMark ""

	# private data members
	protected variable name
	protected variable menu

	protected variable textMarker
	protected variable deltaMarker
	protected variable axis

	# private member functions

	# public variable update functions
	protected method updateHide {}
	protected method updateColor {}
	protected method updateWidth {}
	protected method updateDashes {}
	protected method updateCallback {}
	protected method updatePosition {}

    private method updateDelta { newx newy }
}


body DCS::CrosshairsMarker::updateDelta { newX newY } {
    if {$thirdPercentMark != ""} {
        $thirdPercentMark followFirstOrSecondMark
    }

    if {$pair == "" || [$pair cget -hide] } return

    set other_pos [$pair cget -position]
    set other_x [lindex $other_pos 0]
    set other_y [lindex $other_pos 1]

    if {[string index $name end] == 1} {
        set deltaX [expr $other_x - $newX]
        set deltaY [expr $other_y - $newY]
    } else {
        set deltaX [expr $newX - $other_x]
        set deltaY [expr $newY - $other_y]
    }

	$deltaMarker configure \
    -text [format $textformat $deltaX $deltaY] \
    -hide 0

	$deltaMarker moveTo $newX $newY
}

body DCS::CrosshairsMarker::popMenu {} {
	$menu post
}

body DCS::CrosshairsMarker::updateHide { } {
    foreach line $BLTMarker {
	    $BLTGraph marker configure $line -hide $hide
    }
	$textMarker configure -hide $hide

    if {$hide || $pair == ""|| [$pair cget -hide]} {
	    $deltaMarker configure -hide 1
    } else {
	    $deltaMarker configure -hide $hide
    }

    if {$pair != ""} {
        $pair hideDelta
    }
    update

    if {$thirdPercentMark != "" && $hide} {
        $thirdPercentMark configure -hide 1
    }
}

configbody DCS::CrosshairsMarker::position {
	update
}

body DCS::CrosshairsMarker::moveTo { newX newY } {
	# store the new x-ordinate of the marker
	set position [list $newX $newY]

	# update the text marker
    if {$percent == ""} {
	    $textMarker configure -text [format $textformat $newX $newY]
    } else {
        if {$firstMark == "" \
        ||  $secondMark == ""} {
	        $textMarker configure -hide 1
        } else {
            set v1 [lindex [$firstMark cget -position] 1]
            set v2 [lindex [$secondMark cget -position] 1]
            if {$v1 > $v2} {
                set tmp $v1
                set v1 $v2
                set v2 $tmp
            }
            set percentSize [expr $v2 - $v1]
            set percentLine [expr $newY - $v1]
            if {$percentSize > 0} {
                set percent \
                [format "%.2f" [expr $percentLine * 100.0 / $percentSize]]
            } else {
                set percent 0.0
            }
            set xFmt [lindex $textformat 0]
	        $textMarker configure -text "[format $xFmt $newX] ${percent}%"
        }
    }

	$textMarker moveTo $newX $newY

    updateDelta $newX $newY
	
	# redraw the marker
	update
}
body DCS::CrosshairsMarker::followFirstOrSecondMark { } {
    if {$hide || $firstMark == "" || $secondMark == "" || $percent == ""} {
        return
    }
    set v1 [lindex [$firstMark cget -position] 1]
    set v2 [lindex [$secondMark cget -position] 1]
    if {$v1 > $v2} {
        set tmp $v1
        set v1 $v2
        set v2 $tmp
    }
    set percentSize [expr $v2 - $v1]

    set newX [lindex $position 0]
    set newY [expr $v1 + $percentSize * $percent / 100.0]
	set position [list $newX $newY]
	$textMarker moveTo $newX $newY
	update
}


body DCS::CrosshairsMarker::updateColor {} {

    foreach line $BLTMarker {
	    $BLTGraph marker configure $line -outline $color
    }
	$textMarker configure -foreground $color
}


body DCS::CrosshairsMarker::updateWidth {} {

    foreach line $BLTMarker {
	    $BLTGraph marker configure $line -linewidth $width
    }
}


body DCS::CrosshairsMarker::update {} {
    set my_mark1 [lindex $BLTMarker 0]
    set my_mark2 [lindex $BLTMarker 1]
    set x [lindex $position 0]
    set y [lindex $position 1]
    set x_axis [lindex $axis 0]
    set y_axis [lindex $axis 1]

	$BLTGraph marker configure $my_mark1 \
		-mapx $x_axis \
		-coords "$x -Inf $x Inf"
	$BLTGraph marker configure $my_mark2 \
		-mapy $y_axis \
		-coords "-Inf $y Inf $y"

}
body DCS::CrosshairsMarker::setShownAxisLabels { xLabel x2Label yLabel y2Label } {

    #puts "setShownAxisLabels $xLabel $x2Label $yLabel $y2Label"
    set myXLabel [lindex $label 0]
    set myYLabel [lindex $label 1]
    #puts "my: {$myXLabel} {$myYLabel}"

    set myXAxis ""
    set myYAxis ""
    if {$myXLabel == $xLabel} {
        set myXAxis x
    } elseif {$myXLabel == $x2Label} {
        set myXAxis x2
    } 
    if {$myYLabel == $yLabel} {
        set myYAxis y
    } elseif {$myYLabel == $y2Label} {
        set myYAxis y2
    } 

    set my_mark1 [lindex $BLTMarker 0]
    set my_mark2 [lindex $BLTMarker 1]

    if {$myXAxis == ""} {
        #puts "hide marker"
        configure -hide 1
        return
    }
    if {$myYAxis == ""} {
        set myYAxis y
        set label [lreplace $label 1 1 y]
    }

    set axis [list $myXAxis $myYAxis]
	$BLTGraph marker configure $my_mark1 -mapx $myXAxis
	$BLTGraph marker configure $my_mark2 -mapy $myYAxis
	#configure -hide 0
    #puts "show marker $myXAxis $myYAxis"
}

body DCS::CrosshairsMarker::drag { x y } {
    if {$percent != ""} {
        if {$firstMark == "" \
        ||  $secondMark == ""} {
            configure -hide 1
            return
        }
        
    }

    set myXAxis [lindex $axis 0]
    set myYAxis [lindex $axis 1]

	set newX [$BLTGraph axis invtransform $myXAxis $x]
	set newY [$BLTGraph axis invtransform $myYAxis $y]
    configure -hide 0
	moveTo $newX $newY
	if { $callback != {} } {
		uplevel $callback $newX $newY
	}
}
##########################################################################
# The class Trace defines a set of blt elements in a Graph.  While it 
# inherits from GraphAttribute it does not directly contain blt elements.
# Instead, it contains members of the class SubTrace each of which
# contains a blt graph element.  All SubTraces must be specified when the
# Trace is created.
##########################################################################

class DCS::Trace {

	# inheritance
	inherit DCS::GraphAttribute

	# constructor
	constructor { traceName containingGraph passedXAxisLabels passedXVector args } {

		DCS::GraphAttribute::constructor $containingGraph		
	} {
		# store the name of the trace
		set name $traceName

		# create a blt vector for the x-axis or store the passed vector 
		if { $passedXVector == "" } {
			set xVectorIsLocal 1
			set xVector [blt::vector ::[DCS::getUniqueName]]
		} else {
			set xVector $passedXVector
		}

		# store the x-axis labels for the trace
		set xAxisLabels $passedXAxisLabels

		# create an ordered set to hold the sub-trace names
		set subTraceSet [DCS::Set \#auto]

		# handle optional configuration options
		eval configure $args
	}

	destructor {

		# destroy all sub-traces
		foreach subTraceName [array names subTraces] {
			delete object $subTraces($subTraceName)
		}

		# destroy the x vector if local to this trace
		if { $xVectorIsLocal } {
			$xVector delete
		}

		# ask the graph to delete the relevant x axis labels
		$graph deleteXLabels $xAxisLabels

		# tell the graph that the trace has been deleted
		$graph reportDeletedTrace $name
	}
    ### make vector to self and holding the data
    public method standalone { }

    public method clone { targetName color makeOverlay }
	
	# public member functions
	public method add { xValue yValues }
	public method createSubTrace { subTraceName yLabels passedYVector args }
	public method deleteSubTrace { subTraceName }
	public method addToSubTrace { subTraceName xValue yValues }
	public method setShownAxisLabels { xLabel x2Label yLabel y2Label }
	public method getElementInfoFromName { element }
	public method configureSubTrace { subTraceName args }
	public method handleShowTrace { show }
	public method reportDeletedSubTrace { subTrace }
	public method save { fileHandle }
    public method getPeaks { }
    public method getXMinMax { }
    public method getYMinMax { currentYLabel }
    public method getYMinMaxLog { currentYLabel }
    public method hideLegend { hide }
    public method getObj { } { return $this }

    public method setIsOverlay { one_zero} {
        set m_isOverlay $one_zero
    }
    public method isOverlay { } { return $m_isOverlay }
	
	# public data members (accessed through configure method)
	public variable xAxis "" { error }
	public variable xAxisLabels { error }
	public variable name { error }

	# public variable update functions
	protected method updateHide {} {}
    protected method getXVector { } { return $xVector }

	# protected variables
	protected variable xVector
	protected variable subTraces
	protected variable subTraceSet
	protected variable menu
	protected variable xVectorIsLocal 0
	protected variable m_xMin  ""
	protected variable m_xMax  ""
    protected variable m_isOverlay 0

    protected common s_cloneSubTraceCounter 0
    protected common SUBTRACE_COLOR [list \
    chocolate \
    cyan \
    darkgreen \
    coral \
    darkred \
    darkcyan \
    firebrick \
    gold \
    magenta \
    maroon \
    navy \
    orchid \
    peru \
    purple \
    salmon \
    sienna \
    tan \
    tomato \
    turquoise \
    violet \
    yellow \
    ]
}
body DCS::Trace::standalone { } {
    set newXVector 0
    if {!$xVectorIsLocal} {
        set oldXVector $xVector
        set xVector [blt::vector ::[DCS::getUniqueName]]
        set xVectorIsLocal 1
        $oldXVector dup $xVector
        set newXVector 1
    }
	foreach subTraceName [array names subTraces] {
        set src $subTraces($subTraceName)
        $src standalone $newXVector
    }
}
body DCS::Trace::clone { targetTraceName color makeOverlay } {
    ## clone needs its own xVector
    set newTrace [$graph createTrace $targetTraceName $xAxisLabels {}]

    $newTrace setIsOverlay $makeOverlay

    set newXVector [$newTrace getXVector]
    $xVector dup $newXVector

	foreach subTraceName [array names subTraces] {
        set src $subTraces($subTraceName)
        set yLabels [$src getYLabels]
        ### new subTrace needs its own yVector to store the data.
        set tgt [$graph createSubTrace $targetTraceName $subTraceName $yLabels {}]

        ## copy data
        set srcY [$src cget -yVector]
        set tgtY [$tgt cget -yVector]
        $srcY dup $tgtY

        ### check label
        set srcLabel [$src getLabel]
        $tgt setLabel $srcLabel
        $tgt setMessage $targetTraceName
        if {[$graph cget -noDelete]} {
            $tgt enableDeleteTrace
        }

        ## copy attributes.
        set srcColor [$src cget -color]
        set srcWidth [$src cget -width]
        set srcSym   [$src cget -symbol]
        set srcSymSz [$src cget -symbolSize]
        set srcHide  [$src cget -hideLegend]

        switch -exact -- $color {
            orig {
                set color $srcColor
            }
            "" {
                set ll [llength $SUBTRACE_COLOR]
                set color [lindex $SUBTRACE_COLOR [expr $s_cloneSubTraceCounter % $ll]]
                incr s_cloneSubTraceCounter
            }
        }

        $tgt configure \
        -color $color \
        -width $srcWidth \
        -symbol $srcSym \
        -symbolSize $srcSymSz \
        -hideLegend $srcHide
    }

    return $newTrace
}

body DCS::Trace::getPeaks { } {
    set resultList ""
	foreach subTraceName [$subTraceSet get] {
		set pp [$subTraces($subTraceName) getPeaks]
        lappend resultList $pp
    }
    return $resultList
}
body DCS::Trace::getXMinMax { } {
    return [list $m_xMin $m_xMax]
}
body DCS::Trace::getYMinMax { currentYLabel } {
    puts "getYMinMax for $this with label=$currentYLabel"
    set y_min ""
    set y_max ""
    set y2_min ""
    set y2_max ""
	foreach subTraceName [$subTraceSet get] {
        set yLabelList [$subTraces($subTraceName) getYLabels]
        if {[lsearch -exact $yLabelList $currentYLabel] < 0} {
            continue
        }
		foreach {min max min2 max2} [$subTraces($subTraceName) getMinMax] break
        if {$min != "" && ($y_min == "" || $y_min > $min)} {
            set y_min $min
        }
        if {$max != "" && ($y_max == "" || $y_max < $max)} {
            set y_max $max
        }
        if {$min2 != "" && ($y2_min == "" || $y2_min > $min2)} {
            set y2_min $min2
        }
        if {$max2 != "" && ($y2_max == "" || $y2_max < $max2)} {
            set y2_max $max2
        }
	}
    return [list $y_min $y_max $y2_min $y2_max]
}
body DCS::Trace::getYMinMaxLog { currentYLabel } {
    puts "getYMinMaxLog for $this with label=$currentYLabel"
    set y_min ""
    set y_max ""
    set y2_min ""
    set y2_max ""
	foreach subTraceName [$subTraceSet get] {
        set yLabelList [$subTraces($subTraceName) getYLabels]
        if {[lsearch -exact $yLabelList $currentYLabel] < 0} {
            continue
        }
		foreach {min max min2 max2} [$subTraces($subTraceName) getMinMaxLog] break
        if {$min != "" && ($y_min == "" || $y_min > $min)} {
            set y_min $min
        }
        if {$max != "" && ($y_max == "" || $y_max < $max)} {
            set y_max $max
        }
        if {$min2 != "" && ($y2_min == "" || $y2_min > $min2)} {
            set y2_min $min2
        }
        if {$max2 != "" && ($y2_max == "" || $y2_max < $max2)} {
            set y2_max $max2
        }
	}
    puts "result  $y_min $y_max $y2_min $y2_max"
    return [list $y_min $y_max $y2_min $y2_max]
}
body DCS::Trace::hideLegend { hide } {
	foreach subTraceName [$subTraceSet get] {
		$subTraces($subTraceName) configure -hideLegend $hide
    }
}

body DCS::Trace::save { fileHandle } {
	
	puts $fileHandle ""
	puts $fileHandle "\# data for trace $name"
	puts $fileHandle "data_"
	puts $fileHandle "_trace.name 	$name"

	set labelList {}
	foreach label $xAxisLabels {
		lappend labelList $label
	}
	puts $fileHandle "_trace.xLabels	\"$labelList\""

	puts $fileHandle "_trace.hide		$hide"
	puts $fileHandle ""
	puts $fileHandle "loop_"
	puts $fileHandle "_sub_trace.name"
	puts $fileHandle "_sub_trace.yLabels"
	puts $fileHandle "_sub_trace.color"
	puts $fileHandle "_sub_trace.width"
	puts $fileHandle "_sub_trace.symbol"
	puts $fileHandle "_sub_trace.symbolSize"
	
	set yVectorList {}
	set yVectorCount 0
	foreach subTraceName [array names subTraces] {
		incr yVectorCount
		$subTraces($subTraceName) save $fileHandle
		lappend yVectorList [$subTraces($subTraceName) cget -yVector]
	}
	
	puts $fileHandle ""
	puts $fileHandle "loop_"
	puts $fileHandle "_sub_trace.x"

	set xVectorLength [$xVector length]

	for { set i 1} { $i <= $yVectorCount } { incr i } {
		puts $fileHandle "_sub_trace.y$i"
	}

	# write out the vector data itself

	for { set i 0} { $i < $xVectorLength } { incr i } {
		puts $fileHandle "[set [set xVector]($i)] " nonewline
		foreach yVector $yVectorList {
			puts $fileHandle "[set [set yVector]($i)] " nonewline
		}
		puts $fileHandle ""
	}

	
}


body DCS::Trace::handleShowTrace { show } {

	if { $show } {
		set hide 0
	} else {
		set hide 1
	}

	updateHide
}


body DCS::Trace::updateHide {} {

	$graph updateShownAxisLabels
}


body DCS::Trace::createSubTrace { subTraceName yLabels passedYVector args } {
	
	# construct the sub-traces
	set subTraces($subTraceName)\
		[eval DCS::SubTrace \#auto $subTraceName $name $this \
			 $graph $BLTGraph $xVector \
			 [list $passedYVector] [list $yLabels] $args]	
	
	# add the sub trace name to the set
	$subTraceSet add $subTraceName

    puts "created subtrace $subTraceName: obj=$subTraces($subTraceName)"

    return [$subTraces($subTraceName) getObj]
}

body DCS::Trace::deleteSubTrace { subTraceName } {
    if {[$subTraceSet isMember $subTraceName]} {
        delete object $subTraces($subTraceName)
    }
}

body DCS::Trace::reportDeletedSubTrace { name } {

	# remove sub-trace from the sub-trace array
	unset subTraces($name)

	# add the sub trace name to the set
	$subTraceSet remove $name

	# delete the trace if last sub-trace has been deleted
	if { [array names subTraces ] == {} } {
		catch { delete object $this }
	}
}


body DCS::Trace::add { xValue yValues } {
    if {$m_xMax == "" || $xValue > $m_xMax} {
        set m_xMax $xValue
    } 
    if {$m_xMin == "" || $xValue < $m_xMin} {
        set m_xMin $xValue
    }

	$xVector append $xValue
	# BAD ARRAY NAMES
	foreach subTraceName [$subTraceSet get] y $yValues {
		$subTraces($subTraceName) add $y
	}
}


body DCS::Trace::setShownAxisLabels { xLabel x2Label yLabel y2Label } {

	set xAxis ""

	set count(x)  0
	set count(x2) 0
	set count(y)  0
	set count(y2) 0

	if { $hide == 0 } {
		if { [lsearch $xAxisLabels $xLabel] != -1 } {
			set xAxis x
		} else {	
			if { [lsearch $xAxisLabels $x2Label] != -1 } {
				set xAxis x2
			}
		}
	}

	foreach subTraceName [array names subTraces] {
		set yAxis [$subTraces($subTraceName) setShownAxisLabels $xAxis $yLabel $y2Label]
		if { $yAxis != "" } {
			incr count($xAxis)
			incr count($yAxis)
		}
	}

	return "$count(x) $count(x2) $count(y) $count(y2)"
}


body DCS::Trace::getElementInfoFromName { element } {

	foreach subTraceName [array names subTraces] {
		if { [$subTraces($subTraceName) cget -BLTElement] == $element } {
			return "$xAxis [$subTraces($subTraceName) cget -yAxis] \
							[$subTraces($subTraceName) cget -color]"
		}
	}
	return {}
}


body DCS::Trace::configureSubTrace { subTraceName args } {

	eval $subTraces($subTraceName) configure $args
}


##########################################################################
# The class SubTrace encapsulates a single blt graph element.  Multiple
# subtraces may be contained by a single Trace object to form a set of
# blt graph elements sharing a single x-vector.
##########################################################################

class DCS::SubTrace {
	# constructor
	constructor { subTraceName containingTraceName containingTrace containingGraph passedBLTGraph passedXVector passedYVector passedYAxisLabels args }  {
		
		# store the name of the sub-trace
		set name $subTraceName

		# store the name of the trace
		set traceName $containingTraceName

        set m_legend_label "${traceName}::$name"

		# store the containing trace object
		set trace $containingTrace

		# store the containing Graph
		set graph $containingGraph

		# store the passed BLT graph
		set BLTGraph $passedBLTGraph

		# store the passed x vector blt vectors
		set xVector $passedXVector

		# store the passed y vector or create a blt vector for the y-axis
		if { $passedYVector == "" } {
			set yVector [blt::vector ::[DCS::getUniqueName]]
			set yVectorIsLocal 1
		} else {
			set yVector $passedYVector
		}

		# store the list of y axis labels matched by this sub-trace
		set yAxisLabels $passedYAxisLabels
		
		# create a name for the blt element
		set BLTElement [DCS::getUniqueName]
		
		# create a blt graph element
		$BLTGraph element create $BLTElement 		\
			-xdata $xVector		\
			-ydata $yVector		\
			-pixels $symbolSize 	\
			-scalesymbols false	\
			-label ""				\
			-color $color			\
			-linewidth 1			\
			-hide 1
		
		# create the context menu for the subtrace
		set menu [DCS::PopupMenu \#auto]
		$menu addLabel title -label $m_legend_label
		$menu addSeparator sep

		# create the color cascade menu
		set colorMenu [$menu addCascade color -label "Set color"]
		foreach colorChoice { black red green blue purple brown orange pink } \
			rgb { \#000000 \#cc0000 \#00aa00 \#0000dd \#6600aa \#aa4444 \#ee5555 \#ff8888 } {
			$colorMenu addCommand $colorChoice -label $colorChoice \
				-foreground $rgb -activeforeground $rgb \
				-command "$this configure -color $rgb"
		}
		
		# create the line width cascade menu
		set thicknessMenu [$menu addCascade thickness -label "Set line thickness"]
		foreach size { 0 1 2 3 4 5 6} {
			$thicknessMenu addCommand $size -label $size \
				-command "$this configure -width $size"
		}

		# create the symbol shape cascade menu
		set shapeMenu [$menu addCascade symbol -label "Set symbol"]
		foreach shape { None square circle diamond plus cross splus scross triangle } {
			$shapeMenu addCommand $shape -label $shape \
				-command "$this configure -symbol $shape"
		}

		# create the symbol size cascade menu
		set sizeMenu [$menu addCascade size -label "Set symbol size"]
		foreach size { 2 4 6 8 10 } {
			$sizeMenu addCommand $size -label $size\
				-command "$this configure -symbolSize $size"
		}

        if {![$graph cget -noDelete]} {
		    # add delete entry to menu
		    $menu addSeparator sep2
		    $menu addCommand delete -label "Delete  ${traceName}::$name" \
		    -command "delete object $this"
		    $menu addCommand deleteTrace -label "Delete $traceName" \
			-command "delete object $containingTrace"
		    $menu addCommand deleteAllSubTrace -label "Delete ALL::$name" \
			-command "$graph deleteSubTraces $name"
        }

		$BLTGraph element bind $BLTElement <Button-3> "$graph setEventSource $this"
		$BLTGraph legend bind $BLTElement <Button-3> "$graph setEventSource $this"

        eval configure $args
	}
	
	destructor {
		
		# destroy the popup menu
		delete object $menu

		# destroy the BLTElement
		$BLTGraph element delete $BLTElement 

		# destroy the y vector if local to this subTrace
		if { $yVectorIsLocal } {
			$yVector delete
		}
		
		# inform the containing trace
		$trace reportDeletedSubTrace $name

		# ask the graph to delete the relevant y axis labels
		$graph deleteYLabels $yAxisLabels
	}

	# public member functions
    public method getObj { } { return $this }
    public method getTraceName { } { return $traceName }
    public method getYLabels { } { return $yAxisLabels }
    public method getPeaks { }
	public method add { y }
	public method setShownAxisLabels { xAxis yLabel y2Label }
	public method handleMouseMotion { x y }
	public method handleMouseLeave {}
	public method popMenu {}
	public method save { fileHandle }
    public method getMinMax { } {
        updateMinMax
        switch -exact -- $yAxis {
            y {
                return [list $m_min $m_max "" ""]
            }
            y2 {
                return [list "" "" $m_min $m_max]
            }
            default {
                return [list $m_min $m_max $m_min $m_max]
            }
        }
    }
    public method getMinMaxLog { } {
        updateMinMax
        switch -exact -- $yAxis {
            y {
                return [list $m_minLog $m_maxLog "" ""]
            }
            y2 {
                return [list "" "" $m_minLog $m_maxLog]
            }
            default {
                return [list "" "" "" ""]
            }
        }
    }
    public method setLabel { ll } {
        set m_legend_label $ll

		if {![$BLTGraph element cget $BLTElement -hide]} {
		    $BLTGraph element configure $BLTElement -label $m_legend_label
		    $menu configureEntry title -label $m_legend_label
        }
    }

    public method setMessage { msg } {
        $menu addLabel message -label $msg -before 1
    }
    public method enableDeleteTrace { } {
        $menu addSeparator sep2
        $menu addCommand deleteTrace -label "Delete $traceName" \
        -command "delete object $trace"
    }

    public method getLabel { } { return $m_legend_label }
    public method getHide { } {
		return [$BLTGraph element cget $BLTElement -hide]
    }

    public method standalone { newXVector } {
        if {!$yVectorIsLocal} {
            set oldYVector $yVector
            set yVector [blt::vector ::[DCS::getUniqueName]]
            set yVectorIsLocal 1
            $oldYVector dup $yVector

		    $BLTGraph element configure $BLTElement -yData $yVector
        }
        if {$newXVector} {
		    $BLTGraph element configure $BLTElement -xData $xVector
        }
    }

    protected method updateMinMax { } {
        set m_min ""
        set m_max ""
        set m_minLog ""
        set m_maxLog ""
        set n [$yVector length]
        if {$n < 1} {
            return
        }
        set m_min [$yVector index 0]
        set m_max $m_min

        set v [expr abs($m_min)]
        if {$v == 0} {
            set v 1
        }
        set m_minLog $v
        set m_maxLog $v


        foreach value [$yVector range 1 end] {
            if {$value < $m_min} {
                set m_min $value
            } elseif {$value > $m_max} {
                set m_max $value
            }
            set v [expr abs($value)]
            if {$v == 0} {
                set v 1
            }
            if {$v < $m_minLog} {
                set m_minLog $v
            } elseif {$v > $m_maxLog} {
                set m_maxLog $v
            }
        }
    }

	# public data members (accessed through configure method)
	public variable color "black" { updateColor }
	public variable width 1 { updateWidth }
	public variable symbol circle { updateSymbol }
	public variable symbolSize 2 { updateSymbolSize }
	public variable BLTElement { error }
	public variable yAxis "" { error }
	public variable yVector "" { error }
	public variable hideLegend 0

	# public variable update functions
	protected method updateColor {}
	protected method updateWidth {} 
	protected method updateSymbol {}
	protected method updateSymbolSize {}

	# private data members
	protected variable name
	protected variable trace
	protected variable traceName ""
	protected variable graph
	protected variable BLTGraph
	protected variable xVector
	protected variable yAxisLabels
	protected variable menu
	protected variable yVectorIsLocal 0

	protected variable m_legend_label ""

    protected variable m_min ""
    protected variable m_max ""
    protected variable m_minLog ""
    protected variable m_maxLog ""

    ### 0.1 means 10% of max value of the yVector
    protected common PEAK_UP_THRESHOLD 0.015
    protected common PEAK_DOWN_THRESHOLD 0.015

    ###this is the counts
    protected common PEAK_MIN_THRESHOLD 10
    protected common PEAK_MAX_THRESHOLD 100

    ## dead span
    protected common PEAK_DEAD_SPAN       0

    protected common PEAK_UP_DEAD_SPAN    10
    protected common PEAK_DOWN_DEAD_SPAN  10
}

body DCS::SubTrace::save { fileHandle } {

	set labelList {}
	foreach label $yAxisLabels {
		lappend labelList $label
	}

	puts $fileHandle "$name \"$labelList\" $color $width $symbol $symbolSize" 
}


body DCS::SubTrace::popMenu {} {
	$menu post
}


body DCS::SubTrace::updateColor {} {

	$BLTGraph element configure $BLTElement -color $color
}


body DCS::SubTrace::updateWidth {} {

	$BLTGraph element configure $BLTElement -linewidth $width
}


body DCS::SubTrace::updateSymbol {} {
	
	if { $symbol == "None" } {
		set symbol "none"
	}

	$BLTGraph element configure $BLTElement -symbol $symbol
}


body DCS::SubTrace::updateSymbolSize {} {

	$BLTGraph element configure $BLTElement -pixels $symbolSize
}


body DCS::SubTrace::add { y } {
	$yVector append $y
    if {$m_min == "" || $m_min > $y} {
        set m_min $y
    }
    if {$m_max == "" || $m_max < $y} {
        set m_max $y
    }

    set y [expr abs($y)]
    if {$y == 0} {
        set y 1
    }

    if {$m_minLog == "" || $m_minLog > $y} {
        set m_minLog $y
    }
    if {$m_maxLog == "" || $m_maxLog < $y} {
        set m_maxLog $y
    }
}


body DCS::SubTrace::setShownAxisLabels { passedXAxis yLabel y2Label } {
    set yAxis ""

	# hide the sub trace if no x axis to map to
	if { $passedXAxis == "" } {
		$BLTGraph element configure $BLTElement -hide 1 -label ""
		return ""
	}

    if {$hideLegend} {
        set legend ""
    } else {
        set legend $m_legend_label
    }
	
	if { [lsearch $yAxisLabels $yLabel] != -1 } {
		set xAxis $passedXAxis
		set yAxis y
		$BLTGraph element configure $BLTElement -hide 0 \
			-mapx $xAxis -mapy $yAxis -label $legend
		return y
	}

	if { [lsearch $yAxisLabels $y2Label] != -1 } {
		set xAxis $passedXAxis
		set yAxis y2
		$BLTGraph element configure $BLTElement -hide 0 \
			-mapx $xAxis -mapy $yAxis -label $legend
		return y2
	}

	# no matches with y axis labels so hide sub-trace
	$BLTGraph element configure $BLTElement -hide 1 -label ""
	return ""
}

### return 4 peaks in the order of X
body DCS::SubTrace::getPeaks { } {

    if {![string is double -strict $m_max]} {
        return ""
    }
    set upThreshold   [expr $m_max * $PEAK_UP_THRESHOLD]
    set downThreshold [expr $m_max * $PEAK_DOWN_THRESHOLD]
    puts "Peak max=$m_max threshold up: $upThreshold down: $downThreshold"
    if {$upThreshold < $PEAK_MIN_THRESHOLD} {
        set upThreshold $PEAK_MIN_THRESHOLD
        puts "adjust up to MIN $PEAK_MIN_THRESHOLD"
    }
    if {$upThreshold > $PEAK_MAX_THRESHOLD} {
        set upThreshold $PEAK_MAX_THRESHOLD
        puts "adjust up to MAX $PEAK_MAX_THRESHOLD"
    }
    if {$downThreshold < $PEAK_MIN_THRESHOLD} {
        set downThreshold $PEAK_MIN_THRESHOLD
        puts "adjust down to MIN $PEAK_MIN_THRESHOLD"
    }
    if {$downThreshold > $PEAK_MAX_THRESHOLD} {
        set downThreshold $PEAK_MAX_THRESHOLD
        puts "adjust down to MAX $PEAK_MAX_THRESHOLD"
    }


    ### prototype: scan whole vector to find all peaks
    set gotUp 0
    set gotDown 0
    set peakIndexList ""
    set n [$yVector length]
    if {$n < 3} {
        return ""
    }
    set currentValue [$yVector index 0]
    set peakValue $currentValue
    set valleyValue $currentValue
    set peakIndex 0
    set valleyIndex 0
    set i 0
    set lastPeakIndex -1
    foreach value [$yVector range 1 end] {
        incr i
        if {!$gotUp} {
            if {$value >= $valleyValue + $upThreshold} {
                if {$i > $valleyIndex + $PEAK_UP_DEAD_SPAN} {
                    set gotUp 1
                    set peakValue $value
                    set peakIndex $i
                    #puts "got up at $i"
                }
            } elseif {$value < $valleyValue} {
                set valleyValue $value
                set valleyIndex $i
            }
        } elseif {!$gotDown} {
            if {$value <= $peakValue - $downThreshold} {
                if {$i > $peakIndex + $PEAK_DOWN_DEAD_SPAN} {
                    set gotDown 1
                    set valleyValue $value
                    set valleyIndex $i
                    #puts "got down at $i"
                }
            } elseif {$value > $peakValue} {
                set peakValue $value
                set peakIndex $i
            }
        }
        if {$gotUp && $gotDown} {
            if {$lastPeakIndex < 0 || \
            $peakIndex > $lastPeakIndex + $PEAK_DEAD_SPAN} {
                ###got a peak
                lappend peakIndexList $peakIndex
                #puts "got a peak at index $peakIndex"
                #puts "PEAK at X=[$xVector index $peakIndex] Y=[$yVector index $peakIndex]"
                set lastPeakIndex $peakIndex
            }
            set gotDown 0
            set gotUp 0
        }
    }
    if {$peakIndexList == ""} {
        return ""
    }
    set peakList ""
    foreach index $peakIndexList {
        set x [$xVector index $index]
        set y [$yVector index $index]
        lappend peakList [list $x $y]
    }
    return $peakList
}


proc testGraph {} {

	DCS::Graph .graph 	\
		 -xLabel "Time (years)" 		\
		 -yLabel "Population" 		\
		 -title "Test Graph"
	#myGraph configure -x2Label "Time (years)"
	
	#.graph configure -x2Label "Time (years)"

	.graph createTrace fluorescence1 { "Energy (eV)" } {}
	.graph createSubTrace fluorescence1 i0 { "Reference Counts" "Counts" } {} -color red 
	.graph createSubTrace fluorescence1 i1 { "Signal Counts" "Counts" } {} -width 1 -symbol circle -symbolSize 2
	.graph createSubTrace fluorescence1 absorbance { "Absorbance" } {}
	.graph createSubTrace fluorescence1 transmission { "Transmission" } {}
	
	set x  [blt::vector ::[DCS::getUniqueName]]
	set y1 [blt::vector ::[DCS::getUniqueName]]
	set y2 [blt::vector ::[DCS::getUniqueName]]
	
	.graph createTrace scan2 { "Time (years)" } $x
	.graph createSubTrace scan2 population { "Population" } $y1 -color blue
	.graph createSubTrace scan2 births { "Births/year" } $y2  -color green
	
	.graph createVerticalMarker marker4 410 "Time (years)" -color red
	.graph createHorizontalMarker marker5 0 Population  -width 2
	
	
	#.graph createTextMarker marker6 0 0 -text "hello"
	
	set pi 3.14159265
	
	for { set i 0 } { $i <= 360 } {incr i 3} {
		set theta [expr $i * ($pi/180)]
		set i0 0.5
		set i1 [expr $i * sin($theta)]
		set transmission [expr $i1/$i0]
		set absorbance [expr -($i1/$i0)]
		.graph addToTrace fluorescence1 [expr 100 * $i] [list $i0 $i1 $transmission $absorbance]
		
		$x append [expr 200 * $i]
		$y1 append [expr $i1 * cos($theta)]
		$y2 append [expr $i1 * $i1]
		update
	}

	pack .graph

}


#testGraph
