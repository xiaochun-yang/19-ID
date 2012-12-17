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

#
# SequenceActions.tcl
#
# part of Screening UI
# used by Sequence.tcl
#
error "The screening tab is obsolete in the 'blu-ice' project. Do not source SequenceActions.tcl.  Use 'BluIceWidgets' project instead."
# ===================================================

package require Itcl

::itcl::class SequenceActions {
# contructor / destructor
constructor { top} {}

# protected variables
protected variable m_indexSelect 0
protected variable m_indexCurrent 0
protected variable m_indexNext 0
protected variable m_nElements 0
protected variable m_detectorMode 0
protected variable m_isRunning 0
protected variable m_actionListener 0

# private variables
private variable m_isCrystalMounted 0
private variable w_oldEntry 0
private variable m_oldEntryVal -1
private variable m_oldEntryName 0
private variable m_oldEntryTime 0
private variable m_isMaster 0
private variable m_monitoredBluIceOperations { centerLoopStatus collectRunsStatus collectRunStatus collectFrameStatus normalizeStatus optimizeStatus }

# layout configuration
private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
private variable m_borderWidth 2
private variable m_yviewSize 11
private variable m_actitionWidth 200
private variable m_actitionHeight 350
private variable m_actitionXincr 10
private variable m_actitionYincr 23

private variable m_defaultActions {
{ MountNextCrystal {} }
{ LoopAlignment {} }
{ Pause {} }
{ VideoSnapshot {1.0 0deg} }
{ CollectImage {0.25 30.0 1 0deg} }
{ Rotate {90} }
{ VideoSnapshot {1.0 90deg} }
{ CollectImage {0.25 30.0 1 90deg} }
{ Pause {} }
{ Rotate {-45} }
{ VideoSnapshot {1.0 45deg} }
{ CollectImage {0.25 30.0 1 45deg} }
{ Pause {} }
}
private variable m_actions

private variable m_actionNames {
{Mount Next Crystal}
{Loop Alignment}
{Stop}
{Video Snapshot}
{Collect Image}
{Rotate}
{Video Snapshot}
{Collect Image}
{Stop}
{Rotate}
{Video Snapshot}
{Collect Image}
{Stop}
}
private variable m_actionParamEntryControls {}

private variable m_actionViewOptionList {"Overview" "BlanckWall" "Crystal" "CryoStream" "GoniometerPhi" }
private variable m_defaultActionView {
{Overview}
{PositionSample}
{x}
{x}
{x}
{x}
{x}
{x}
{Overview}
{x}
{x}
{x}
{x}
}
private variable m_actionView
private variable m_actionViewControls {}

# static array
private common c_actionNames
set c_actionNames(MountNextCrystal) "Mount Next Crystal"
set c_actionNames(OptimizeTable) "Optimize Table"
set c_actionNames(LoopAlignment) "Loop Alignment"
set c_actionNames(VideoSnapshot) "Video Snapshot"
set c_actionNames(CollectImage) "Collect Image"
set c_actionNames(Pause) "Stop"
set c_actionNames(Rotate) "Rotate"
set c_actionNames(FluorescenceScan) "Fluorescence Scan"
# static array
private common c_actionParamNames
set c_actionParamNames(MountNextCrystal) {}
set c_actionParamNames(OptimizeTable) {}
set c_actionParamNames(LoopAlignment) {}
set c_actionParamNames(VideoSnapshot) {{Zoom} {Name tag}}
set c_actionParamNames(CollectImage) {{Delta-phi [deg]} {Time [sec]} {# of images} {Name tag}}
set c_actionParamNames(Pause) {}
set c_actionParamNames(Rotate) {{Angle [deg]}}
set c_actionParamNames(FluorescenceScan) {}
#

#subcomponents
protected variable w_directoryLabel
protected variable w_directory
protected variable w_detectorMode
protected variable w_doseCheck
protected variable w_doseFactor
protected variable w_doseNormalize
protected variable w_actionList
protected variable w_parameterTabFrame
protected variable w_start
protected variable w_stop
protected variable w_dismount
protected variable w_reset
protected variable w_abort
protected variable w_mountedCrystal
protected variable w_nextCrystal
protected variable w_useRobot

# private methods
private method ActionSequenceFrame { top actions } {}
private method createCellsAndInitScrollbars { canvasFrame canvas actions } {}
private method CellsAndInitScrollbars { canvasFrame canvas actions } {}
private method ActionGeneralParameterFrame { top } {}
private method ActionParameterTabFrame { top actions} {}
private method ActionButtonFrame { top } {}
private method MountNextCrystalParameters {top actionClass actionParameters} {}
private method OptimizeTableParameters {top actionClass actionParameters} {}
private method LoopAlignmentParameters {top actionClass actionParameters} {}
private method RotateParameters {top actionClass actionParameters} {}
private method VideoSnapshotParameters {top actionClass actionParameters} {}
private method CollectImageParameters {top actionClass actionParameters} {}
private method FluorescenceScanParameters {top actionClass actionParameters} {}
private method PauseParameters {top actionClass actionParameters} {}
private method setCellColor { canvasFrame } {}
private method setCurrentActionColor { canvasFrame } {}
private method enableButtons {} {}
private method getCheckbox { index } {}
private method setCheckbox { index value } {}
private method getDetectorMode { name } {}
private method setDetectorMode { index } {}
private method bindEventHandlers { canvasFrame parameterTabFrame } {}
private method bindEntryChangeHandlersForActionParameters {} {}
private method testMasterPrivilege {} {}
private method handleDetectorModeSelect {} {}
private method handleDoseModeCheckbox { box } {}
private method handleDoseNormalizeClick {} {}
private method handleCellCheckbox { box index} {}
private method handleCellClick { canvasFrame index} {}
private method handleNextActionClick { canvasFrame index} {}
private method handleStartClick {} {}
private method handleStopClick {} {}
private method handleDismountClick {} {}
private method handleResetClick {} {}
private method handleAbortClick {} {}
private method handleEntryChange { entry entryName event} {}
private method handleVideoViewSelect { control index} {}
private method saveOldEntryVal { entry entryName} {}
private method sendCheckBoxStates {} {}
private method sendActionMsg { msg} {}
private method setActionListParameters { data } {}
private method getActionListParameters {} {}
private method loadViewOptionList {} {}
private method selectVideoView { actionIndex } {}
private method setActionView { viewList } {}
private method trc_msg { text } {}

# public methods
public method addActionListener { listener} {}
public method setConfig { attribute value} {}
public method setMasterSlave { master} {}
public method updateDoseMode { args } {}
public method updateDoseFactor { args } {}
public method handleUpdateFromComponent { component attribute value } {}
}

# ===================================================
# ===================================================

::itcl::body SequenceActions::constructor { top } {

set m_actionViewOptionList [loadViewOptionList]
set m_actionViewOptionList [linsert $m_actionViewOptionList 0 "PositionSample"]
set m_actionViewOptionList [linsert $m_actionViewOptionList 0 "x"]

frame $top -borderwidth $m_borderWidth

pack $top -side top

set topParam [frame $top.actionParam -borderwidth 0]
set w_parameterTabFrame $topParam.parameterTabs

set m_actions $m_defaultActions
set actions $m_actions
set m_actionView $m_defaultActionView
ActionSequenceFrame $top.actionSequence $actions
ActionGeneralParameterFrame $topParam.generalParameters
ActionParameterTabFrame $w_parameterTabFrame $actions
ActionButtonFrame $top.actionButtons

pack $topParam $topParam.generalParameters -side top -fill x -anchor nw
pack $topParam $topParam.parameterTabs -side top -fill both -anchor nw

#pack $top $top.actionSequence -side left
#pack $top $topParam -side left -fill y -anchor nw
#pack $top $top.actionButtons -side right -anchor nw

grid $top.actionSequence $topParam $top.actionButtons
grid $topParam -sticky nw
grid $top.actionButtons -sticky nw

DynamicHelp::register $w_start balloon "Start execution of selected actions"
DynamicHelp::register $w_stop balloon "Stop execution after current action is finished"
DynamicHelp::register $w_dismount balloon "Dismount current crystal and stop"
DynamicHelp::register $w_reset balloon "Reset all action parameters to default values"
DynamicHelp::register $w_abort balloon "Abort the current action and stop"
DynamicHelp::register $w_mountedCrystal balloon "Currently mounted crystal"
DynamicHelp::register $w_nextCrystal balloon "Next crystal"
DynamicHelp::register $w_detectorMode balloon "Detector mode"
DynamicHelp::register $w_doseCheck balloon "Enable Dose Mode\n(Correct exposure time with Dose Factor)"
DynamicHelp::register $w_doseFactor balloon "Dose Factor\n(Change of ion chamber reading since last Normalize)"
DynamicHelp::register $w_doseNormalize balloon "Normalize Dose Factor\n(Use current ion chamber reading to set 'Dose Factor' to 1.0)"

bindEventHandlers $w_actionList $w_parameterTabFrame
enableButtons

}

# ===================================================
# ===================================================

::itcl::body SequenceActions::ActionSequenceFrame { top actions} {
	
	# Create the top frame (component container)
	#frame $top -borderwidth 10
	frame $top -borderwidth 1 -relief groove
	pack $top -side top -ipadx 2 -ipady 2

	# Create a frame caption
	set f [frame $top.header -bd 4]
	label $f.label -text {Action Sequence:} -font $m_font
	pack $f.label -side left
	pack $f -side top -fill x

	# Create a scrolling canvas for the Table
	frame $top.c
	canvas $top.c.canvas -width 10 -height 10 \
		-yscrollcommand [list $top.c.yscroll set]
	scrollbar $top.c.yscroll -orient vertical \
		-command [list $top.c.canvas yview]
	pack $top.c.yscroll -side right -fill y
	pack $top.c.canvas -side left -fill both -expand true
	pack $top.c -side top -fill both -expand true

	set w_actionList [frame $top.c.canvas.f -bd 0]
	createCellsAndInitScrollbars $w_actionList $top.c.canvas $actions
	set m_nElements [llength $actions]
	
	$w_actionList.check0 select

	set selectedRow 0
	setCellColor $w_actionList
	setCurrentActionColor $w_actionList
}

# ===================================================

::itcl::body SequenceActions::createCellsAndInitScrollbars { canvasFrame canvas actions } {
	# Create one frame to hold everything
	# and position it on the canvas

	set yviewSize $m_yviewSize
	
	# set f [frame $canvas.f -bd 0]
	set f $canvasFrame
	$canvas create window 0 0 -anchor nw -window $f

	# Create and grid the action entries
	set i 0
	foreach action $actions {
		
		set actionClass [lindex $action 0]
		set actionParameters [lindex $action 1]
		#set actionName $c_actionNames($actionClass)
		set actionName [lindex $m_actionNames $i]

		entry $f.state$i -relief flat -font $m_font
		$f.state$i insert 0 $i
		$f.state$i config -state disabled
		$f.state$i config -width 2

		checkbutton $f.check$i
		
		#entry $f.cellA$i -relief groove
		entry $f.cellA$i -relief flat -font $m_font
		$f.cellA$i insert 0 $actionName
		$f.cellA$i config -state disabled
		$f.cellA$i config -width 18

		grid $f.state$i $f.check$i $f.cellA$i
		grid $f.state$i -sticky we
		grid $f.check$i -sticky w
		grid $f.cellA$i -sticky we

		incr i
	}
	set child $f.cellA0

	# Wait for the window to become visible and then
	# set up the scroll region based on
	# the requested size of the frame, and set 
	# the scroll increment based on the
	# requested height of the widgets

	#gw tkwait visibility $child
	set bbox [grid bbox $f 0 0]
        set width $m_actitionWidth
	set height $m_actitionHeight
        set xincr $m_actitionXincr
        set yincr $m_actitionYincr
	$canvas config -scrollregion "0 0 $width $height"
	$canvas config -yscrollincrement $yincr

	# max canvas size = 3x10 cells
	set ymax [llength $actions]
	if {$ymax > $yviewSize} {
		set ymax $yviewSize
	}
	set height [expr $yincr * $ymax]
	$canvas config -width $width -height $height

}

# ===================================================
# ===================================================
# ===================================================

::itcl::body SequenceActions::ActionGeneralParameterFrame { top } {
	
	# Create the top frame (component container)
	#frame $top -borderwidth 10
	#pack $top -side top
	frame $top -borderwidth 1 -relief groove
	pack $top -side top -ipadx 2 -ipady 2

	# Create the frame
	set f [frame $top.param -bd 4]

	# directory
	set l [label $f.labelDirectory -text "Directory:" -font $m_font]
        set w_directoryLabel $l
	set w_directory [entry $f.entryDirectory -relief sunken -width 17 -font $m_font]
	$w_directory insert 0 "/data/usrname"
	grid configure $l -sticky w -column 0 -row 0
	grid configure $w_directory -sticky we -columnspan 3 -column 1 -row 0

	# detector mode
	global gDefineRun
	set modes $gDefineRun(modeChoicesSupported)
	set w_detectorMode [iwidgets::combobox $f.detectorMode -width 14 -labeltext "Detector: " -grab global -labelfont $m_font -textfont $m_font]
	foreach m $modes {
		$w_detectorMode insert list end $m
	}
	$w_detectorMode selection set $m_detectorMode
	$w_detectorMode config -editable false 
        set popup [$w_detectorMode component list]
        $popup config -height 200
	grid configure $w_detectorMode -pady 2 -columnspan 4 -column 0 -row 1

	# dose mode
	set gray [$f cget -background]
	global gWindows
        set doseFactor $gWindows(runs,doseFactor)
	set w_doseCheck [checkbutton $f.checkDose -background $gray -text "Dose Mode"]
	set w_doseFactor [label $f.labelDoseFactor -text "$doseFactor"  -font $m_font]
        set w_doseNormalize [button $f.doseNormalize -padx 0 -text "Normalize" -font $m_font]
	grid configure $w_doseCheck -sticky w -columnspan 2 -column 0 -row 2
	grid configure $w_doseFactor -sticky w -columnspan 1 -column 2 -row 2
	grid configure $w_doseNormalize -sticky w -pady 1 -columnspan 1 -column 3 -row 2

	pack $f -side top
}

# ===================================================

::itcl::body SequenceActions::ActionParameterTabFrame { top actions} {
	set blue #a0a0c0
	set tabWidth 25


	#frame $top -borderwidth 10
	frame $top -borderwidth 1 -relief groove -background $blue
	pack $top -side top -ipadx 2 -ipady 2 -fill y


	# for ech action create a tab-frame for the parameter caption and the parameter entries
	set i 0
        set m_actionViewControls {}
	foreach action $actions {
		#create the tab-frame
		set p [frame $w_parameterTabFrame.parameterTab$i -bd 4 -background $blue]

		set actionClass [lindex $action 0]
		set actionParameters [lindex $action 1]
		#set actionName $c_actionNames($actionClass)
		set actionName [lindex $m_actionNames $i]

		# Create a frame caption
		set f [frame $p.header -bd 4 -background $blue]
		label $f.label -text "$i $actionName" -width $tabWidth -background $blue -anchor w -font $m_font
		pack $f.label -side left
		pack $f -side top -fill x

		# Create frame for the parameter entries
		set f [frame $p.entries -bd 4 -background $blue]

                # add the dropdown for the videoPreset
                set actionIndex $i
        	set modes $m_actionViewOptionList
                set bgColor $blue
        	set viewPreset [iwidgets::combobox $f.viewPreset -width 15 -labeltext "View  " -background $bgColor -grab global -labelfont $m_font -textfont $m_font]

        	foreach m $modes {
                    if { $m=="x" } {
                        set m ""
                    }
                    $viewPreset insert list end $m
                }
                set viewSelectionText  [lindex $m_actionView $actionIndex]
                set viewSelectionIndex [lsearch $m_actionViewOptionList $viewSelectionText]
		if { $viewSelectionIndex<0 } {
			set viewSelectionIndex 0
		}

        	$viewPreset selection set $viewSelectionIndex
        	$viewPreset config -editable false 
                set popup [$viewPreset component list]
                $popup config -height 150
        	grid configure $viewPreset -padx 2 -pady 2 -columnspan 2 -column 0
                set m_actionViewControls [linsert $m_actionViewControls end $viewPreset]

		# add parameter controls for this action
                switch -exact -- $actionClass {
			MountNextCrystal { MountNextCrystalParameters $f $actionClass $actionParameters}
			OptimizeTable { OptimizeTableParameters $f $actionClass $actionParameters}
			LoopAlignment { LoopAlignmentParameters $f $actionClass $actionParameters}
			Rotate { RotateParameters $f $actionClass $actionParameters}
			VideoSnapshot { VideoSnapshotParameters $f $actionClass $actionParameters}
			CollectImage { CollectImageParameters $f $actionClass $actionParameters}
			FluorescenceScan { FluorescenceScanParameters $f $actionClass $actionParameters}
			Pause { PauseParameters $f $actionClass $actionParameters}
		}

		pack $f -side left -fill y

		incr i
	}
	pack $w_parameterTabFrame.parameterTab0 -in $top -fill both
}

# ===================================================
# ===================================================

::itcl::body SequenceActions::ActionButtonFrame { top } {
	set red #c04080
	set green #00a040
	set yellow #d0d000

	frame $top -borderwidth 2
	#pack $top -side top 
	#frame $top -borderwidth 1 -relief groove -background $blue
	#pack $top -side top -ipadx 2 -ipady 2 -fill y

	set w_start [button $top.buttonStart -text "Start" -font $m_font]
	set w_stop [button $top.buttonStop -text "Stop" -font $m_font]
	set w_dismount [button $top.buttonDismount -text "Dismount" -font $m_font]
	set w_reset [button $top.buttonReset -text "Reset" -font $m_font]
	set w_abort [button $top.buttonAbort -text "Abort" -font $m_font -bg \#ffaaaa -activebackground \#ffaaaa]

	label $top.labelSpace -text " " -anchor w  -font $m_font

	label $top.labelMounted -text "Mounted:" -anchor w  -font $m_font
	set w_mountedCrystal [entry $top.entryMounted -relief sunken -width 8 -bg $red -font $m_font]
	$top.entryMounted insert 0 ""
	$top.entryMounted config -state disabled
	
	label $top.labelNext -text "Next:" -anchor w  -font $m_font
	set w_nextCrystal [entry $top.entryNext -relief sunken -width 8 -bg $green -font $m_font]
	$top.entryNext insert 0 "offline"
	$top.entryNext config -state disabled

        set frameRobot [frame $top.frameRobot]
	label $frameRobot.labelRobotState -text "Robot:" -anchor w  -font $m_font
	set w_useRobot [entry $frameRobot.entryRobotState -relief sunken -width 3 -bg lightgray -font $m_font]
	$frameRobot.entryRobotState insert 0 "off"
	$frameRobot.entryRobotState config -state disabled

	pack $top.buttonStart -side top -fill x -pady 0
	pack $top.buttonStop -side top -fill x -pady 0
	pack $top.buttonDismount -side top -fill x -pady 0
	pack $top.buttonReset -side top -fill x -pady 0
	pack $top.buttonAbort -side top -fill x -pady 0
	pack $top.labelSpace -side top -fill x -anchor w

	pack $top.labelMounted -side top -fill x -anchor w
	pack $top.entryMounted -side top -fill x
	pack $top.labelNext -side top -fill x -anchor w
	pack $top.entryNext -side top -fill x

	pack $frameRobot.labelRobotState -pady 3 -side left -fill x -anchor w
	pack $frameRobot.entryRobotState -side left -fill x
	pack $frameRobot -side top -fill x -anchor w

	pack $top -side right

}

# ===================================================
# ===================================================

::itcl::body SequenceActions::MountNextCrystalParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	#label $f.label -text $actionClass -background $bgColor -font $m_font
	#pack $f.label -side left

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass ""]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::OptimizeTableParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	#label $f.label -text $actionClass -background $bgColor -font $m_font
	#pack $f.label -side left

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass ""]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::LoopAlignmentParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	#label $f.label -text $actionClass -background $bgColor -font $m_font
	#pack $f.label -side left

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass ""]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::RotateParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	set i 0
	set entryList ""
	foreach param $c_actionParamNames($actionClass) {
		set l [label $f.label$i -text "$param" -background $bgColor -font $m_font]
		set e [entry $f.entry$i -relief sunken -font $m_font]
		$e insert 0 [lindex $actionParameters $i]
		$e config -width 10
		grid $l $e
		grid $l -sticky w
		grid $e -sticky we
		set entryList [concat $entryList $e]
		incr i
	}

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass $entryList]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::VideoSnapshotParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	set i 0
	set entryList ""
	foreach param $c_actionParamNames($actionClass) {
		set l [label $f.label$i -text "$param" -background $bgColor -font $m_font]
		set e [entry $f.entry$i -relief sunken -font $m_font]
		$e insert 0 [lindex $actionParameters $i]
		$e config -width 10
		grid $l $e
		grid $l -sticky w
		grid $e -sticky we
		set entryList [concat $entryList $e]
		incr i
	}

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass $entryList]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::CollectImageParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	set i 0
	set entryList ""
	foreach param $c_actionParamNames($actionClass) {
		set l [label $f.label$i -text "$param" -background $bgColor -font $m_font]
		set e [entry $f.entry$i -relief sunken -font $m_font]
		$e insert 0 [lindex $actionParameters $i]
		$e config -width 10
		grid $l $e
		grid $l -sticky w
		grid $e -sticky we
		set entryList [concat $entryList $e]
		incr i
	}

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass $entryList]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::FluorescenceScanParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	#label $f.label -text $actionClass -background $bgColor -font $m_font
	#pack $f.label -side left

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list $actionClass ""]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================

::itcl::body SequenceActions::PauseParameters {top actionClass actionParameters} {
	set bgColor [$top cget -background]
	set f $top
	#label $f.label -text $actionClass -background $bgColor -font $m_font
	#pack $f.label -side left

	# append all entryControls to the list m_actionParamEntryControls
	set paramControles [list [list $actionClass] "{}"]
	set m_actionParamEntryControls [linsert $m_actionParamEntryControls end $paramControles]
}

# ===================================================
# ===================================================

::itcl::body SequenceActions::setCellColor { canvasFrame } {
	# show selected row with darkblue background
	set blue #a0a0c0

	set nElements $m_nElements 
	set sel $m_indexSelect

	set f $canvasFrame
	#get default background color
	set gray [$f cget -background]

	# reset all cells to gray
	for {set i 0} {$i < $nElements} {incr i} {
		#$f.check$i config -background $gray
		$f.cellA$i config -background $gray
	}
	
	# set selected row to darkblue
	#$f.check$sel config -background $blue
	$f.cellA$sel config -background $blue
}

# ===================================================

::itcl::body SequenceActions::setCurrentActionColor { canvasFrame } {
	# show current action with red arrow
	# show next action with green arrow
	set red #c04080
	set green #00a040
	set yellow #d0d000

	set nElements $m_nElements 
	set sel $m_indexCurrent
	set next $m_indexNext

	set f $canvasFrame
	#get default background color
	set gray [$f cget -background]

	# reset all cells to gray
	for {set i 0} {$i < $nElements} {incr i} {
		#set item .ex.actionSequence.c.canvas.f.state$i
		set item $f.state$i
		$item config -state normal
		$item delete 0  2
		$item insert 0 $i
		$item config -state disabled
		$item config -background $gray
		$f.cellA$i config -foreground black
	}
	
	if { $m_isRunning==1 } {
		# set selected row to red
		#set item .ex.actionSequence.c.canvas.f.state$i
		set item $f.state$sel
		$item config -state normal
		$item delete 0  2
		$item insert 0 "->"
		$item config -state disabled
		$item config -background $red
		$f.cellA$sel config -foreground red
	
		# set next row to green
		set item $f.state$next
		$item config -state normal
		$item delete 0  2
		$item insert 0 "->"
		$item config -state disabled
		$item config -background $green
	} else {
		# set next row to green
		set item $f.state$next
		$item config -state normal
		$item delete 0  2
		$item insert 0 "->"
		$item config -state disabled
		$item config -background $green
	}


}

# ===================================================

::itcl::body SequenceActions::enableButtons {} {
if { $m_isRunning==1 } {
	$w_start config -state disabled
	$w_doseNormalize config -state disabled
	$w_stop config -state normal
} else {
	$w_start config -state normal
	$w_doseNormalize config -state normal
	$w_stop config -state disabled
}
$w_reset config -state normal
$w_directoryLabel config -state normal
$w_directory config -state normal -bg \#f0f0ff
$w_detectorMode config -state normal
$w_doseCheck config -state normal
$w_doseNormalize config -state normal

global gDefineRun
set doseMode $gDefineRun(doseMode)
if { $doseMode==0 } {
    $w_doseNormalize config -state disabled
}

if { $m_isCrystalMounted==1 } {
	$w_dismount config -state normal
} else {
	$w_dismount config -state disabled
}

# disable start and dismount when any operation in another blu-ice tab is running
foreach { obj } $m_monitoredBluIceOperations {
    set objState [$obj cget -status]
    if { $objState!="inactive" } {
        trc_msg "SequenceActions::enableButtons disable since $obj $objState"
       	$w_start config -state disabled
	$w_dismount config -state disabled
    }
}

if { $m_isMaster==0 } {
    $w_start config -state disabled
    $w_reset config -state disabled
    $w_directoryLabel config -state disabled
    $w_directory config -state disabled -bg lightgray
    $w_detectorMode config -state disabled
    $w_doseCheck config -state disabled
    $w_doseNormalize config -state disabled
}

# disable checkboxes if this client is not master
if { $m_isMaster==0 } {
    # disable action ckeckboxes
    set f $w_actionList
    set nElements $m_nElements
    for {set i 0} {$i < $nElements} {incr i} {
        $f.check$i config -state disabled
        $f.check$i config -selectcolor gray
    }
    $w_doseCheck config -state disabled
    $w_doseCheck config -selectcolor gray
} else {
    # enable action ckeckboxes
    set f $w_actionList
    set nElements $m_nElements
    for {set i 0} {$i < $nElements} {incr i} {
        $f.check$i config -state normal
        $f.check$i config -selectcolor blue
    }
    $w_doseCheck config -state normal
    $w_doseCheck config -selectcolor blue
}

# disable action parameter entries if this client is not master
if { $m_isMaster==0 } {
    set nElements [llength $m_actionParamEntryControls]
    # for all action items
    for {set i 0} {$i < $nElements} {incr i} {
	set actionItemControls [lindex $m_actionParamEntryControls $i]
	set actionClass [lindex $actionItemControls 0]
	set controlList [lindex $actionItemControls 1]
        foreach control $controlList {
            if { $control=="" } {
                continue
            }
            $control config -state disabled -bg lightgray
        }
    }
    foreach control $m_actionViewControls {
        if { $control=="" } {
            continue
        }
        $control config -state disabled
    }
} else  {
    set nElements [llength $m_actionParamEntryControls]
    # for all action items
    for {set i 0} {$i < $nElements} {incr i} {
	set actionItemControls [lindex $m_actionParamEntryControls $i]
	set actionClass [lindex $actionItemControls 0]
	set controlList [lindex $actionItemControls 1]
        foreach control $controlList {
            if { $control=="" } {
                continue
            }
            $control config -state normal -bg \#f0f0ff
        }
    }
    foreach control $m_actionViewControls {
        if { $control=="" } {
            continue
        }
        $control config -state normal
    }
}

}

# ===================================================

::itcl::body SequenceActions::getCheckbox { index } {
	set s checkActionState$index
	global $s
	# trc_msg "old=[set $s]"
	set value [set $s]
	return $value
}

# ===================================================

::itcl::body SequenceActions::setCheckbox { index value } {
	set s checkActionState$index
	global $s
	# trc_msg "old=[set $s]"
	set $s $value
}


# ===================================================

::itcl::body SequenceActions::getDetectorMode { modeName } {
trc_msg "SequenceActions::getDetectorMode $modeName"
	# find the index of the entry "modeName" in the list gDefineRun(modeChoices)
	global gDefineRun
	set modeList $gDefineRun(modeChoices)
	set modeIndex 0
	foreach m $modeList {
		if { $m==$modeName } {
			# here is the mode
			trc_msg "modeIndex=$modeIndex"
			return $modeIndex
		}
		incr modeIndex
	}
return 0
}

# ===================================================

::itcl::body SequenceActions::setDetectorMode { modeIndex } {
trc_msg "SequenceActions::setDetectorMode $modeIndex"
	# get modeName from the list gDefineRun(modeChoices)
	global gDefineRun
	set modeList $gDefineRun(modeChoices)
	set modeName [lindex $modeList $modeIndex]
	global gDefineRun
	set modeList $gDefineRun(modeChoicesSupported)
	set index 0
	foreach m $modeList {
		if { $m==$modeName } {
			# here is the mode
			trc_msg "index=$index"
			$w_detectorMode config -state normal
			$w_detectorMode config -editable true
			$w_detectorMode selection set $index
			$w_detectorMode config -editable false 
                        enableButtons
			return
		}
		incr index
	}
}

# ===================================================

::itcl::body SequenceActions::bindEventHandlers { canvasFrame parameterTabFrame } {
	set f $canvasFrame

	set nElements $m_nElements 
	for {set i 0} {$i < $nElements} {incr i} {
		bind $f.state$i <Button-1> [::itcl::code $this handleNextActionClick $f $i]
		#$f.check$i config -variable selectedAction -value $i
		$f.check$i config -variable checkActionState$i
		$f.check$i config -command [::itcl::code $this handleCellCheckbox $f.check$i $i]
		bind $f.cellA$i <Button-1> [::itcl::code $this handleCellClick $f $i]
	}
	$w_start config -command [::itcl::code $this handleStartClick]
	$w_stop config -command [::itcl::code $this handleStopClick]
	$w_dismount config -command [::itcl::code $this handleDismountClick]
	$w_reset config -command [::itcl::code $this handleResetClick]
	$w_abort config -command [::itcl::code $this handleAbortClick]

	set entry $w_directory
	bind $entry <FocusIn> [::itcl::code $this saveOldEntryVal $entry "directory"]
	bind $entry <FocusOut> [::itcl::code $this handleEntryChange $entry "directory" "FocusOut"]
	bind $entry <Return> [::itcl::code $this handleEntryChange $entry "directory" "Return"]

	$w_detectorMode config -selectioncommand [::itcl::code $this handleDetectorModeSelect]

	# Dose Mode
	global gDefineRun
        $w_doseCheck config -variable gDefineRun(doseMode)

	$w_doseCheck config -command [::itcl::code $this handleDoseModeCheckbox $f.checkDose]
	$w_doseNormalize config -command [::itcl::code $this handleDoseNormalizeClick]

	for {set i 0} {$i < $nElements} {incr i} {
            set control [lindex $m_actionViewControls $i]
            $control config -selectioncommand [::itcl::code $this handleVideoViewSelect $control $i]
	}
	
	bindEntryChangeHandlersForActionParameters

        # register for state changes of operations in other blu-ice tabs
        # state changes will be handled in handleUpdateFromComponent
        # (-> disable buttons if another operation is running)
        foreach { obj } $m_monitoredBluIceOperations {
            $obj register $this status
        }

	global gWindows
        trace variable gDefineRun(doseMode) w [::itcl::code $this updateDoseMode]
        trace variable gWindows(runs,doseFactor) w [::itcl::code $this updateDoseFactor]

}

# ===================================================

::itcl::body SequenceActions::bindEntryChangeHandlersForActionParameters {} {
trc_msg "SequenceActions::bindEntryChangeHandlersForActionParameters"

set nElements [llength $m_actionParamEntryControls]
# for all action items
for {set i 0} {$i < $nElements} {incr i} {
	set actionItemControls [lindex $m_actionParamEntryControls $i]
	set actionClass [lindex $actionItemControls 0]
	set controlList [lindex $actionItemControls 1]
	set n [llength $controlList]
	if { $controlList=="{}" } {
		set n 0
	}
	# for all parameters of this action item
	for {set j 0} {$j < $n} {incr j} {
		# bind the event handler for this control
		set entry [lindex $controlList $j]
		bind $entry <FocusIn> [::itcl::code $this saveOldEntryVal $entry "ActionParameter"]
		bind $entry <FocusOut> [::itcl::code $this handleEntryChange $entry "ActionParameter" "FocusOut"]
		bind $entry <Return> [::itcl::code $this handleEntryChange $entry "ActionParameter" "Return"]
	} ;# for all parameters of this action item
} ;# for all action items


} ;# bindEntryChangeHandlersForActionParameters {}


# ===================================================
# ===================================================

::itcl::body SequenceActions::testMasterPrivilege {} {
if { ! $m_isMaster } {
        trc_msg "This client is not the master."
        log_error "This client is not the master."
        return 0
}
return 1
}

# ===================================================

::itcl::body SequenceActions::handleDetectorModeSelect {} {

	trc_msg "SequenceActions::handleDetectorModeSelect"
if { ! [testMasterPrivilege] } {
    setDetectorMode $m_detectorMode
    return
}

	set modeName [$w_detectorMode getcurselection]
	set mode [getDetectorMode $modeName]

	if { $mode==$m_detectorMode } {
		return
	}
	set m_detectorMode $mode

	sendActionMsg "setConfig detectorMode $m_detectorMode"
}

# ===================================================

::itcl::body SequenceActions::handleDoseModeCheckbox { box} {
	trc_msg "SequenceActions::handleDoseModeCheckbox= $box"

	# enable/disbale the doseNormalize button
	enableButtons
	
        # call update_runs_to_server in collect tab (dice_tabs.tcl) to inform dcss about current doseMode selection
        update_runs_to_server
}


# ===================================================

::itcl::body SequenceActions::handleDoseNormalizeClick {} {
trc_msg "handleDoseNormalizeClick"
if { ! [testMasterPrivilege] } {
    return
}
	sendActionMsg "doseNormalize"
}

# ===================================================

::itcl::body SequenceActions::handleCellCheckbox { box index} {

	trc_msg "handleCellCheckbox= $box $index"

	sendCheckBoxStates
}

# ===================================================

::itcl::body SequenceActions::handleCellClick { canvasFrame index} {

	trc_msg "handleCellClick=$canvasFrame $index"

	set parameterTabFrame $w_parameterTabFrame
	set oldTab [lindex [pack slaves $parameterTabFrame] 0]
	trc_msg "oldTab=$oldTab"
	pack forget $oldTab
	pack $parameterTabFrame.parameterTab$index -in $parameterTabFrame -fill y

	set m_indexSelect $index

	setCellColor $canvasFrame
	setCurrentActionColor $canvasFrame
}

# ===================================================

::itcl::body SequenceActions::handleNextActionClick { canvasFrame index} {

	trc_msg "handleNextActionClick=$canvasFrame $index"
if { ! [testMasterPrivilege] } {
    return
}
	set m_indexNext $index
	setCheckbox $index 1

	handleCellClick $canvasFrame $index
	#setCurrentActionColor $canvasFrame

	sendActionMsg "setConfig nextAction $index"
}


# ===================================================

::itcl::body SequenceActions::handleStartClick {} {
trc_msg "handleStartClick"
if { ! [testMasterPrivilege] } {
    return
}
	
        if { $w_oldEntry!=0 } {
		handleEntryChange $w_oldEntry $m_oldEntryName "FocusOut"
	}

	# make sure that the directory exists and the user has access right
	set dir [$w_directory get]
	if { [catch {file mkdir $dir} err] } {
		set msg "ERROR SequenceActions::handleStartClick mkdir: $err"
		log_error "$err"
		#trc_msg "$msg"
		return
	}
	if { [file isdirectory $dir]==0 || [file writable $dir]==0 } {
		set msg "ERROR SequenceActions::handleStartClick no writable directory $dir"
		log_error "no writable directory $dir"
		#trc_msg "$msg"
		return
	}
#	if { [catch {cd $dir} err] } {
#		set msg "ERROR SequenceActions::handleStartClick $err"
#		log_error "$err"
#		#trc_msg "$msg"
#		return
#	}

        # make sure that the robot is ready
       if { [$w_useRobot get]=="on" } {
            set handle [start_waitable_operation sequenceGetConfig getConfig robotState]
            set result [wait_for_operation $handle]
            global gConfig
            print "gConfig(robot,useRobot)=$gConfig(robot,useRobot)"
            print "gConfig(robot,robotState)=$gConfig(robot,robotState)"
            if { $gConfig(robot,robotState)>0 } {
                log_error "Robot reset required (robotState=$gConfig(robot,robotState))"
                return
            }
        }

        # send the selected detectormode (dcss is initilized with detectormode=0, which could be wrong)
        handleDetectorModeSelect

        $w_start config -state disabled
        sendCheckBoxStates
	sendActionMsg "start"
}


# ===================================================

::itcl::body SequenceActions::handleStopClick {} {
trc_msg "handleStopClick"
if { ! [testMasterPrivilege] } {
    return
}
	sendActionMsg "stop"
}

# ===================================================

::itcl::body SequenceActions::handleDismountClick {} {
trc_msg "handleDismountClick"
if { ! [testMasterPrivilege] } {
    return
}
	sendActionMsg "dismount"
}

# ===================================================

::itcl::body SequenceActions::handleResetClick {} {
trc_msg "handleResetClick"
    setDetectorMode "0"

    global gDefineRun
    set gDefineRun(doseMode) 1
    
    setActionListParameters $m_defaultActions
    setActionView $m_defaultActionView
    selectVideoView $m_indexSelect
}

# ===================================================

::itcl::body SequenceActions::handleAbortClick {} {

	trc_msg "handleAbortClick"
	do_command abort
}

# ===================================================

::itcl::body SequenceActions::handleEntryChange { entry entryName event} {

	trc_msg "handleEntryChange $entryName"

	if { $m_oldEntryVal==[$entry get] } {
            if { $event!="Return" } {
		trc_msg "ignore unchanged value $entryName: $m_oldEntryVal"
		return
            }
            set timeDiff [expr [clock seconds] - $m_oldEntryTime]
            if { $timeDiff<3 } {
		trc_msg "ignore unchanged value $entryName: $m_oldEntryVal since timeDiff=$timeDiff"
		return
            }
	}

if { ! [testMasterPrivilege] } {
    $entry delete 0 end
    $entry insert 0 $m_oldEntryVal
    return
}

	set m_oldEntryVal [$entry get]
	set m_oldEntryTime [clock seconds]
	if { $entryName=="directory" } {
		set newDir [$w_directory get]
		sendActionMsg "setConfig directory $newDir"
	} elseif { $entryName=="ActionParameter" } {
		set data [getActionListParameters]
		sendActionMsg "setConfig actionListParameters {$data}"
	}
	
}

# ===================================================

::itcl::body SequenceActions::handleVideoViewSelect { control index} {

	trc_msg "handleVideoViewSelect $index"
if { ! [testMasterPrivilege] } {
    set oldViewName [lindex $m_actionView $index]
    set oldViewIndex [lsearch $m_actionViewOptionList $oldViewName]
    $control config -editable true
    $control selection set $oldViewIndex
    $control config -editable false 
    return
}
	set viewName [$control getcurselection]
        if { [string length $viewName]<2 } {
           set viewName "x"
        }
        set m_actionView [lreplace $m_actionView $index $index $viewName]

        selectVideoView $index
	sendActionMsg "setConfig actionView {$m_actionView}"
}

# ===================================================

::itcl::body SequenceActions::saveOldEntryVal { entry entryName} {
	set w_oldEntry $entry
	set m_oldEntryVal [$entry get]
	set m_oldEntryName $entryName
}

# ===================================================

::itcl::body SequenceActions::sendCheckBoxStates {} {
	set actionListStates {}
	set nElements $m_nElements
	for {set i 0} {$i < $nElements} {incr i} {
		set actionListStates [concat $actionListStates [getCheckbox $i]]
	}
	sendActionMsg "setConfig actionListStates {$actionListStates}"
}

# ===================================================

::itcl::body SequenceActions::sendActionMsg { msg } {

	trc_msg "sendActionMsg"
	set actionListener $m_actionListener
	set n [llength $actionListener]
	for {set i 0} {$i<$n} {incr i} {
		set listener [lindex $actionListener $i]
		eval $listener SequenceActions $msg
	}
}


# ===================================================

::itcl::body SequenceActions::setActionListParameters { data} {
trc_msg "SequenceActions::setActionListParameters"

set m_actions $data

# we have two list with the same structure:
# * the "data" list has the parameter values
# * the "m_actionParamEntryControls" list has the corresponding entry widgets
# loop through both lists and check if something needs to be updated
set nElements $m_nElements
if { $nElements>[llength $data] } {
	set nElements [llength $data]
}
# for all action items
for {set i 0} {$i < $nElements} {incr i} {
	set actionItemData [lindex $data $i]
	set actionItemControls [lindex $m_actionParamEntryControls $i]
	set dataList [lindex $actionItemData 1]
	set controlList [lindex $actionItemControls 1]
	set n [llength $dataList]
	set nControl [llength $controlList]
	if { $n>$nControl } {
		set n nControl
	}
	# for all parameters of this action item
	for {set j 0} {$j < $n} {incr j} {
		set value [lindex $dataList $j]
		set control [lindex $controlList $j]
		# update the entry widget if value has changed
		set oldval [$control get]
		if { $oldval!=$value } {
                        $control config -state normal
			$control delete 0 end
			$control insert 0 $value
		}
	} ;# for all parameters of this action item
} ;# for all action items

} ;# setActionListParameters {}

# ===================================================

::itcl::body SequenceActions::getActionListParameters {} {
trc_msg "SequenceActions::getActionListParameters"

set data ""

# create a list with all parameter values

set nElements [llength $m_actionParamEntryControls]
# for all action items
for {set i 0} {$i < $nElements} {incr i} {
	# insert a list element like this: {CollectImage {0.25 30.0 1}}
	set actionItemControls [lindex $m_actionParamEntryControls $i]
	set actionClass [lindex $actionItemControls 0]
	set controlList [lindex $actionItemControls 1]
	set n [llength $controlList]
	if { $controlList=="{}" } {
		set n 0
	}

	# special CollectImage versions
	set actionName [lindex $m_actionNames $i]
	if { $actionClass=="CollectImage" && $i>=14 && [string range $actionName 0 6]!="Collect"} {
		#BeamsizeScan
		#TimeScan
		#ZScan
		set actionClass $actionName
		trc_msg "Special CollectImage version!!! actionClass=$actionClass"
	}

	set paramList ""
	# for all parameters of this action item
	for {set j 0} {$j < $n} {incr j} {
		# read the value of this entry widget
		set control [lindex $controlList $j]
		set value [$control get]
		if { [string length $value]<=0 } {
			set value "{}"
		}
		set paramList [concat $paramList $value]
	} ;# for all parameters of this action item
	# append the parameter values of this action item to the data list
	set actionItemData [list $actionClass $paramList]
	set data [linsert $data end $actionItemData]
} ;# for all action items

return $data

} ;# getActionListParameters {}

# ===================================================

::itcl::body SequenceActions::loadViewOptionList {} {
	trc_msg "SequenceActions::loadViewOptionList"
	set result {}
	set viewOptionList {"Home"}

	# load the list of the hutch camera preset options from the web server
        global gBeamline
	set url "${gBeamline(videoServerUrl)}${gBeamline(ptzPath)}?query=presetposall"
	trc_msg "$url"
        if { [catch {
            set token [http::geturl $url -timeout 8000]
            upvar #0 $token state
            set status $state(status)
            set replystatus $state(http)
            set replycode [lindex $replystatus 1]
        } err] } {
            log_error "$err $url"
            set status "ERROR $err $url"
        }
	if { $status!="ok" } {
		# error -> use the default option list
		set msg "ERROR SequenceActions::loadViewOptionList http::geturl status=$status"
		trc_msg $msg
	} elseif { $replycode!=200 } {
		# error -> use the default option list
		set msg "ERROR SequenceActions::loadViewOptionList http::geturl replycode=$replycode"
		trc_msg $msg
                log_error "SequenceActions::loadViewOptionList $replystatus"
	} else {
		set totalsize $state(totalsize)
		set currentsize $state(currentsize)
		trc_msg "totalsize=$totalsize"
		trc_msg "currentsize=$currentsize"
		if { $currentsize>10 } {
			set result $state(body)
			if { [string range $result 0 3]!="pres" } {
				set msg "ERROR SequenceActions::loadViewOptionList - Web server returned: $result"
				trc_msg $msg
			} else {
				trc_msg "$result"
			}
		}
	}

        set lng [llength $result]
	if { $lng > 0 } {
        	# parse the result for the preset names and store them in viewOptionList
                set viewOptionList {}

		# replace all equal signs with spaces
		while { [set nextEqualSign [string first = $result]] != -1 } {
			set result [string replace $result $nextEqualSign $nextEqualSign " "] 
		}

		# count the tokens to parse
		set tokenCount [llength $result]
		
		# store preset names in viewOptionList
		for { set i 1 } { $i < $tokenCount } { incr i 2 } {
			
			set presetName [lindex $result $i]
			set viewOptionList [linsert $viewOptionList end $presetName]
		}			
	}
        trc_msg "viewOptionList=$viewOptionList"

	return $viewOptionList
}


# ===================================================

::itcl::body SequenceActions::selectVideoView { actionIndex } {
	trc_msg "SequenceActions::selectVideoView $actionIndex"
        set viewPresetControl [lindex $m_actionViewControls $actionIndex]
        set viewPresetName [$viewPresetControl get]
        if { [string length $viewPresetName]<2 } {
           set viewPresetName "x"
        }
        trc_msg "viewPresetName=$viewPresetName"
	sendActionMsg "selectVideoView $viewPresetName"
}

# ===================================================

::itcl::body SequenceActions::setActionView { viewList } {
	trc_msg "SequenceActions::setActionView $viewList"
        set lng [llength $viewList]
        if { $lng>[llength $m_actionViewControls] } {
            set lng [llength $m_actionViewControls]
        }
        if { $lng>[llength $m_actionView] } {
            set lng [llength $m_actionView]
        }
        for {set i 0} { $i<$lng } {incr i} {
            set newViewPresetName [lindex $viewList $i]
            set oldViewPresetName [lindex $m_actionView $i]
            if { $newViewPresetName==$oldViewPresetName } {
                continue
            }
            set viewIndex [lsearch $m_actionViewOptionList $newViewPresetName]
            if { $viewIndex<0 } {
                trc_msg "Unknown preset $newViewPresetName"
                set newViewPresetName "x"
                set viewIndex 0
            }
            set m_actionView [lreplace $m_actionView $i $i $newViewPresetName]
            set control [lindex $m_actionViewControls $i]
            $control config -editable true
            $control selection set $viewIndex
            $control config -editable false 
        }
}

# ===================================================

::itcl::body SequenceActions::trc_msg { text } {
# puts "$text"
print "$text"
}

# ===================================================
# ===================================================
# public methods

::itcl::body SequenceActions::addActionListener { listener} {

if { $m_actionListener==0 } then {
	set m_actionListener [list $listener]
} else {
	set m_actionListener [list $m_actionListener $listener]
}

}

# ===================================================

::itcl::body SequenceActions::setConfig { attribute value} {
trc_msg "SequenceActions::setConfig attribute=$attribute value=$value"
switch -exact -- $attribute {
	directory { 
		set oldval [$w_directory get]
		if { $oldval!=$value } {
                        $w_directory config -state normal
			$w_directory delete 0 end
			$w_directory insert 0 $value
                        enableButtons
		}
	}
	actionListParameters {
		setActionListParameters $value
                # disable entries in case we have enabled them to change values
                enableButtons
	}
	actionView {
		setActionView $value
	}
	actionListStates {
		set nElements $m_nElements
		if { $nElements>[llength $value] } {
			set nElements [llength $value]
		}
		for {set i 0} {$i < $nElements} {incr i} {
			setCheckbox $i [lindex $value $i]
		}
                # disbale checkboxes if this client is not master
                enableButtons
	}
	nextAction {
                if { $value<0 } {
                    set value 0
                }
		if { $m_indexNext!=$value } {
			set m_indexNext $value
			setCurrentActionColor $w_actionList
		}
	}
	currentAction {
		if { $m_indexCurrent!=$value } {
			set m_indexCurrent $value
			setCurrentActionColor $w_actionList
		}
                if { $m_isRunning==1 } {
                        set actionName [lindex $m_actionNames $value]
                        log_note "Screening $value $actionName"
                        if { $value==0 && [$w_useRobot get]=="off" } {
                            log_warning "Robot is offline"
                        }
                }
                if { $m_isRunning==1 } {
                        selectVideoView $value
                }
	}
	isRunning {
                if { $m_isRunning==0 && $value==1 } {
                        log_note "Screening started."
                }
                if { $m_isRunning==1 && $value==0 } {
                        log_note "Screening stopped."
                }
		set m_isRunning $value
		setCurrentActionColor $w_actionList
		enableButtons
	}
	generalParameters {}
	detectorMode {
		if { $m_detectorMode!=$value } {
			set m_detectorMode $value
			setDetectorMode $value
		}
		
	}
	nextCrystal {
		set oldval [$w_nextCrystal get]
		if { $oldval!=$value } {
        		$w_nextCrystal config -state normal
			$w_nextCrystal delete 0 end
			$w_nextCrystal insert 0 $value
        		$w_nextCrystal config -state disabled
		}
	}
	currentCrystal {
		set oldval [$w_mountedCrystal get]
		if { $oldval!=$value } {
        		$w_mountedCrystal config -state normal
			$w_mountedCrystal delete 0 end
			if { $value!="" } {
				$w_mountedCrystal insert 0 $value
				set m_isCrystalMounted 1
			} else {
				set m_isCrystalMounted 0
			}
        		$w_mountedCrystal config -state disabled
		}
		enableButtons
	}
	useRobot {
                if { $value==0 } {
                    set robotState "off"
                    set color black
                } else {
                    set robotState "on"
                    set color red
                }
		set oldval [$w_useRobot get]
		if { $oldval!=$robotState } {
        		$w_useRobot config -state normal
			$w_useRobot delete 0 end
			$w_useRobot insert 0 $robotState
        		$w_useRobot config -state disabled -foreground $color
		}
	}
	default { trc_msg "ERROR unknown attribute=$attribute" }
} ;# switch

}

# ===================================================

::itcl::body SequenceActions::setMasterSlave { master} {
trc_msg "SequenceActions::setMasterSlave $master"
set m_isMaster $master
enableButtons

}

# ===================================================

::itcl::body SequenceActions::updateDoseMode { args } {
trc_msg "SequenceActions::updateDoseMode"
enableButtons
}

# ===================================================

::itcl::body SequenceActions::updateDoseFactor { args } {
trc_msg "SequenceActions::updateDoseFactor"
    global gWindows
    set doseFactor $gWindows(runs,doseFactor)
    $w_doseFactor config -text $doseFactor
}

# ===================================================

::itcl::body SequenceActions::handleUpdateFromComponent { component attribute value } {
trc_msg "SequenceActions::handleUpdateFromComponent $component $attribute $value"
enableButtons
}

# ===================================================
# ===================================================
#// main

#set top .ex
#SequenceActions action $top



# ===================================================
# ===================================================
