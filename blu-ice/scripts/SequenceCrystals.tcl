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
# SequenceCrystals.tcl
#
# part of Screening UI
# used by Sequence.tcl
#

error "The screening tab is obsolete in the 'blu-ice' project. Do not source SequenceCrystals.tcl.  Use 'BluIceWidgets' project instead."
# ===================================================

package require Itcl
package require http

::itcl::class SequenceCrystals {
# contructor / destructor
constructor { top} {}

# protected variables
protected variable m_indexSelect 0
protected variable m_indexMounted -1
protected variable m_indexNext 0
protected variable m_nElements 0

#internal states
private variable m_isCrystalMounted 0
private variable m_isRunning 1
private variable m_isMaster 0

#
protected variable m_actionListener 0
#
private variable m_updateDataUrl "http://smb.slac.stanford.edu:8084/crystals/updateCrystalData.jsp"
private variable m_crystalDataUrl "http://smb.slac.stanford.edu:8084/crystals/getCrystalData.jsp"
private variable m_cassetteDataUrl "http://smb.slac.stanford.edu:8084/crystals/getCassetteData.jsp"
#private variable m_updateDataUrl "http://gwolfpc/cts/updateCrystalData.asp"
#private variable m_crystalDataUrl "http://gwolfpc/cts/getCrystalData.asp"
#private variable m_cassetteDataUrl "http://gwolfpc/cts/getCassetteData.asp"

private variable m_columns {
{A Port 4}
{B ID 8}
{C Protein 8}
{D Comment 35}
{E Directory 22}
{F FreezingCond 12}
{G CrystalCond 72}
{H Metal 5}
{I Priority 8}
{J Person 8}
{K CrystalURL 25}
{L ProteinURL 25}
}
private variable m_user "gwolf"
private variable m_cassetteListIndex 0
private variable m_cassetteList {}
private variable m_crystalList {}
private variable m_lastListUpdateTime 0

#subcomponents
protected variable w_crystalSequenceFrame
protected variable w_cassette
protected variable w_update
protected variable w_crystalList


# layout configuration
private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
private variable m_borderWidth 2
private variable m_xviewSize 80
private variable m_yviewSize 32
private variable m_xincr 10
private variable m_yincr 22
private variable m_width 1920

# private methods
private method CrystalSequenceFrame { top cassetteList crystalList } {}
private method CreateCellsAndInitScrollbars { canvasFrame canvas data } {}
private method setCellColor { canvasFrame } {}
private method setCurrentActionColor {canvasFrame } {}
private method enableButtons {} {}
private method getCheckbox { index } {}
private method setCheckbox { index value } {}
private method bindEventHandlers { canvasFrame } {}
private method testMasterPrivilege {} {}
private method handleHeaderCheckbox { box boxStateName} {}
private method handleCellCheckbox { box index} {}
private method handleCellClick { canvasFrame index col} {}
private method handleNextCrystalClick { canvasFrame index} {}
private method handleCassetteSelect {} {}
private method handleUpdateClick {} {}
private method sendUpdateCassetteRequest { beamlineName user } {}
private method loadCassetteList { beamlineName user } {}
private method loadCrystalList { beamlineName user cassetteListIndex cassetteList} {}
private method updateCrystalList { beamlineName user cassetteListIndex cassetteList} {}
private method loadWebData { url } {}
private method execNetscape { crystalRowIndex } {}
private method sendCheckBoxStates {} {}
private method sendActionMsg { msg} {}
private method trc_msg { text } {}

# public methods
public method getCrystalID { index } {}
public method addActionListener { listener} {}
public method setConfig { attribute value} {}
public method setMasterSlave { master} {}

}

# ===================================================

::itcl::body SequenceCrystals::constructor { top } {

global env
set m_user $env(USER)
global gBeamline
#set beamlineName $gBeamline(serverName)
set beamlineName $gBeamline(beamlineId)
trc_msg "beamlineName=$beamlineName"
#gw set m_cassetteList [loadCassetteList $beamlineName $m_user]
set m_cassetteList {undefined undefined undefined undefined}
set m_crystalList [loadCrystalList $beamlineName $m_user $m_cassetteListIndex $m_cassetteList]

frame $top -borderwidth $m_borderWidth
pack $top -side top

set w_crystalSequenceFrame $top.crystalSequence
CrystalSequenceFrame $w_crystalSequenceFrame $m_cassetteList $m_crystalList
pack $w_crystalSequenceFrame -side left

DynamicHelp::register $w_update balloon "Update crystal cassette information\n(is disabled if a crsytal is mounted)"
DynamicHelp::register $w_cassette balloon "Select a cassette from beamline dewar\n(is disabled if a crsytal is mounted)"

bindEventHandlers $w_crystalList
}

# ===================================================
# ===================================================

::itcl::body SequenceCrystals::CrystalSequenceFrame { top cassetteList data } {
	
	# Create the top frame (component container)
	#frame $top -borderwidth 10
	#pack $top -side top
	frame $top -borderwidth 1 -relief groove
	pack $top -side top -ipadx 2 -ipady 2

	# Create a frame caption
	set f [frame $top.header -bd 4]
	#set w_cassette [iwidgets::combobox $f.selectCassette -labelpos w -width 14 -labeltext "Cassette:" -grab global]
	set w_cassette [iwidgets::combobox $f.selectCassette -width 28 -labeltext "Cassette:" -grab global -labelfont $m_font -textfont $m_font]
        set n [llength $cassetteList]
	for {set i 0} {$i<$n} {incr i}  {
		set location [lindex {"No cassette" "left" "middle" "right"} $i]
		set cassette [lindex $cassetteList $i]
		set text "$location: $cassette"
		$w_cassette insert list end $text
	}
	$w_cassette selection set $m_cassetteListIndex
	$w_cassette config -editable false 
        set popup [$w_cassette component list]
        $popup config -height 120

	set w_update [button $f.buttonUpdate -text {Update} -font $m_font]

	pack $f.selectCassette -side left
	pack $f.buttonUpdate -side left -padx 10

	pack $f -side top -fill x -expand true

	# Create a scrolling canvas for the Table
	frame $top.c
	canvas $top.c.canvas -width 10 -height 10 \
		-xscrollcommand [list $top.c.xscroll set] \
		-yscrollcommand [list $top.c.yscroll set]
	scrollbar $top.c.xscroll -orient horizontal \
		-command [list $top.c.canvas xview]
	scrollbar $top.c.yscroll -orient vertical \
		-command [list $top.c.canvas yview]
	pack $top.c.yscroll -side right -fill y
	pack $top.c.xscroll -side bottom -fill x
	pack $top.c.canvas -side left -fill both -expand true
	pack $top.c -side top -fill both -expand true


	set w_crystalList [frame $top.c.canvas.f -bd 0]
	CreateCellsAndInitScrollbars $w_crystalList $top.c.canvas $data
	
	set m_nElements [llength $data]
	
	set selectedRow 0
	set m_indexSelect $selectedRow
	setCellColor $w_crystalList
	setCurrentActionColor $w_crystalList

}

# ===================================================

::itcl::body SequenceCrystals::CreateCellsAndInitScrollbars { canvasFrame canvas data } {
	# Create one frame to hold everything
	# and position it on the canvas

	# max canvas size = (xviewSize * yviewSize) characters
	set xviewSize $m_xviewSize
	set yviewSize $m_yviewSize
	
	# set f [frame $canvas.f -bd 0]
	set f $canvasFrame
	$canvas create window 0 0 -anchor nw -window $f

	# Create the table header
	entry $f.stateHeader -relief flat -font $m_font
	#$f.stateHeader insert 0 " "
	$f.stateHeader config -state disabled
	$f.stateHeader config -width 2

	checkbutton $f.checkHeader
	
	set gray [$f cget -background]
	$f.stateHeader config -background $gray
	$f.checkHeader config -background $gray

	# create the column headers
	foreach column $m_columns {
		set col [lindex $column 0]
		set name [lindex $column 1]
		set cellWidth [lindex $column 2]
		entry $f.cell$col -relief groove -font $m_font
		$f.cell$col insert 0 $name
		$f.cell$col config -state disabled
		$f.cell$col config -width $cellWidth
		$f.cell$col config -background $gray
	}
	grid $f.stateHeader $f.checkHeader $f.cellA $f.cellB $f.cellC $f.cellD \
	$f.cellE $f.cellF $f.cellG $f.cellH  $f.cellI $f.cellJ $f.cellK $f.cellL
	grid $f.checkHeader -sticky w
	foreach column $m_columns {
		set col [lindex $column 0]
		grid $f.cell$col -sticky we
	}

	# Create and grid the data entries
	set rows $data
	set i 0
	foreach row $rows {
		# label $f.label$i -text $i -width 2
		entry $f.state$i -relief flat -font $m_font
		$f.state$i insert 0 $i
		$f.state$i config -state disabled
		$f.state$i config -width 2

		checkbutton $f.check$i
		
		set j 0
		foreach column $m_columns {
			set col [lindex $column 0]
			set cellWidth [lindex $column 2]
			set cellData [lindex $row $j]
			entry $f.cell$col$i -relief flat -font $m_font
			$f.cell$col$i insert 0 $cellData
			$f.cell$col$i config -state disabled
			$f.cell$col$i config -width $cellWidth
			incr j
		}
		grid $f.state$i $f.check$i $f.cellA$i $f.cellB$i $f.cellC$i $f.cellD$i \
		$f.cellE$i $f.cellF$i  $f.cellG$i $f.cellH$i $f.cellI$i $f.cellJ$i $f.cellK$i $f.cellL$i
		grid $f.state$i -sticky we
		grid $f.check$i -sticky w
		foreach column $m_columns {
			set col [lindex $column 0]
			grid $f.cell$col$i -sticky we
		}

		incr i
	}
	set child $f.cellA0

	# Wait for the window to become visible and then
	# set up the scroll region based on
	# the requested size of the frame, and set 
	# the scroll increment based on the
	# requested height of the widgets

        set bbox [grid bbox $f 0 0]
        set xincr $m_xincr
        set yincr $m_yincr
        set width $m_width
	set height [expr [expr $yincr + 2] *  [llength $data] ]
	$canvas config -scrollregion "0 0 $width $height"
	$canvas config -xscrollincrement $xincr
	$canvas config -yscrollincrement $yincr
	
	# max canvas size = (xviewSize * yviewSize) characters
	set xmax $xviewSize
	if {$xmax > $xviewSize} {
		set xmax $xviewSize
	}
	set ymax [llength $data]
	if {$ymax > $yviewSize} {
		set ymax $yviewSize
	}
	set width [expr $xincr * $xmax]
	set height [expr $yincr * $ymax]
        
        # set height 1200 to prevent problems with short crystal lists:
        set height 1200

	$canvas config -width $width -height $height
}


# ===================================================

::itcl::body SequenceCrystals::setCellColor { canvasFrame } {
	# show selected row with darkblue background
	set blue #a0a0c0

	set nElements $m_nElements 
	set sel $m_indexSelect

	set f $canvasFrame
	set gray [$f cget -background]

	# reset all cells to gray
	for {set i 0} {$i < $nElements} {incr i} {
		#$f.check$i config -background $gray
		foreach column $m_columns {
			set col [lindex $column 0]
			$f.cell$col$i config -background $gray
		}
	}
	
	# set selected row to darkblue
	#$f.check$sel config -background $blue
	foreach column $m_columns {
		set col [lindex $column 0]
		$f.cell$col$sel config -background $blue
	}

	#$f.cellA$sel config -background $gray
}

# ===================================================

::itcl::body SequenceCrystals::setCurrentActionColor {canvasFrame } {
	# show current action with red arrow
	set red #c04080
	set green #00a040
	set yellow #d0d000

	set nElements $m_nElements 
	set sel $m_indexMounted
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
                # set text color black
		foreach column $m_columns {
			set col [lindex $column 0]
			$f.cell$col$i config -foreground black
		}
	}

	
	if { $m_isCrystalMounted==1 } {
		# set selected row to red
		#set item .ex.actionSequence.c.canvas.f.state$i
		set item $f.state$sel
		$item config -state normal
		$item delete 0  2
		$item insert 0 "->"
		$item config -state disabled
		$item config -background $red
                # set text color red
		foreach column $m_columns {
			set col [lindex $column 0]
			$f.cell$col$sel config -foreground red
		}
	}

	if { $sel!=$next || $m_isCrystalMounted==0 } {
		# set next row to green
		#set item .ex.actionSequence.c.canvas.f.state$i
		set item $f.state$next
		$item config -state normal
		$item delete 0  2
		$item insert 0 "->"
		$item config -state disabled
		$item config -background $green
	}

}

# ===================================================

::itcl::body SequenceCrystals::enableButtons {} {
#trc_msg "SequenceCrystals::enableButtons m_isRunning=$m_isRunning m_isCrystalMounted=$m_isCrystalMounted"

if { $m_isRunning==1 || $m_isCrystalMounted==1 } {
	$w_update config -state disabled
	$w_cassette config -state disabled
} else {
	$w_update config -state normal
	$w_cassette config -state normal
}

# disable checkboxes if this client is not master
if { $m_isMaster==0 } {
    # disable ckeckboxes
    set f $w_crystalList
    set nElements $m_nElements
    for {set i 0} {$i < $nElements} {incr i} {
        $f.check$i config -state disabled
        $f.check$i config -selectcolor gray
    }
    $f.checkHeader config -state disabled
    $f.checkHeader config -selectcolor gray
} else {
    # enable ckeckboxes
    set f $w_crystalList
    set nElements $m_nElements
    for {set i 0} {$i < $nElements} {incr i} {
        $f.check$i config -state normal
        $f.check$i config -selectcolor blue
    }
    $f.checkHeader config -state normal
    $f.checkHeader config -selectcolor blue
}

}

# ===================================================

::itcl::body SequenceCrystals::getCheckbox { index } {
	set s checkCellState$index
	global $s
	# trc_msg "old=[set $s]"
	set value [set $s]
	return $value
}

# ===================================================

::itcl::body SequenceCrystals::setCheckbox { index value } {
	set s checkCellState$index
	global $s
	# trc_msg "old=[set $s]"
	set $s $value
}

# ===================================================

::itcl::body SequenceCrystals::bindEventHandlers { canvasFrame } {
	
	$w_cassette config -selectioncommand [::itcl::code $this handleCassetteSelect]
	$w_update config -command [::itcl::code $this handleUpdateClick]
	
	set f $canvasFrame

	$f.checkHeader config -variable checkHeaderState
	$f.checkHeader config -command [::itcl::code $this handleHeaderCheckbox $f.checkHeader checkHeaderState]

	set nElements $m_nElements
	for {set i 0} {$i < $nElements} {incr i} {
		bind $f.state$i <Button-1> [::itcl::code $this handleNextCrystalClick $f $i]
		$f.check$i config -variable checkCellState$i
		$f.check$i select
		$f.check$i config -command [::itcl::code $this handleCellCheckbox $f.check$i $i]
		foreach column $m_columns {
			set col [lindex $column 0]
			bind $f.cell$col$i <Button-1> [::itcl::code $this handleCellClick $f $i $col]
		}
	}
}

# ===================================================

::itcl::body SequenceCrystals::testMasterPrivilege {} {
if { ! $m_isMaster } {
        trc_msg "This client is not the master."
        log_error "This client is not the master."
        return 0
}
return 1
}

# ===================================================

::itcl::body SequenceCrystals::handleHeaderCheckbox { box boxStateName } {
	# the checkbox in the header of the table was selected

	# find out the state of the checkbox
	upvar #0 $boxStateName boxState
	trc_msg "handleHeaderCheckbox= $box $boxStateName=$boxState"

	set nElements $m_nElements 
	# set all CellCheckboxes to this state
	for {set i 0} {$i < $nElements} {incr i} {
            if { $i==$m_indexMounted } {
                continue
            }
            setCheckbox $i $boxState
	}
	sendCheckBoxStates
}


# ===================================================

::itcl::body SequenceCrystals::handleCellCheckbox { box index} {

	trc_msg "handleCellCheckbox= $box $index"
	sendCheckBoxStates
}


# ===================================================

::itcl::body SequenceCrystals::handleCellClick { canvasFrame index col} {

	trc_msg "handleCellClick=$canvasFrame $index $col"
	
	set m_indexSelect $index
	
	setCellColor $canvasFrame
	setCurrentActionColor $canvasFrame

	if { $col=="C" || $col=="L" } {
            # load web page with protein information
            execNetscape $index
	}
}

# ===================================================

::itcl::body SequenceCrystals::handleNextCrystalClick { canvasFrame index } {
	trc_msg "handleNextCrystalClick=$canvasFrame $index"
if { ! [testMasterPrivilege] } {
    return
}
	
	set m_indexNext $index
	setCheckbox $index 1

	setCurrentActionColor $canvasFrame
	sendActionMsg "setConfig nextCrystal $index"
}

# ===================================================

::itcl::body SequenceCrystals::handleCassetteSelect {} {
	trc_msg "SequenceCrystals::handleCassetteSelect"
if { ! [testMasterPrivilege] } {
    $w_cassette config -editable true 
    $w_cassette selection set $m_cassetteListIndex
    $w_cassette config -editable false 
    return
}

        $w_update config -state disabled

	set selText [$w_cassette getcurselection]
	set cassette "undefined"
        set n [llength $m_cassetteList]
	for {set i 0} {$i<$n} {incr i}  {
		set location [lindex {"No cassette" "left" "middle" "right"} $i]
		set c [lindex $m_cassetteList $i]
		set text "$location: $c"
		if { [string compare $text $selText]==0 } {
			set m_cassetteListIndex $i
			set cassette $c
			break
		}
	}

	global env
	set m_user $env(USER)
	global gBeamline
        #set beamlineName $gBeamline(serverName)
        set beamlineName $gBeamline(beamlineId)
        trc_msg "beamlineName=$beamlineName"
	updateCrystalList $beamlineName $m_user $m_cassetteListIndex $m_cassetteList
	set cassetteInfo [list [list $m_user $m_cassetteListIndex $m_cassetteList]]

        $w_update config -state normal
	
        sendActionMsg "setConfig cassetteInfo $cassetteInfo"
}

# ===================================================

::itcl::body SequenceCrystals::handleUpdateClick {} {
	trc_msg "SequenceCrystals::handleUpdateClick"
if { ! [testMasterPrivilege] } {
    return
}
        $w_update config -state disabled

	global env
	set m_user $env(USER)
	global gBeamline
        #set beamlineName $gBeamline(serverName)
        set beamlineName $gBeamline(beamlineId)
        trc_msg "beamlineName=$beamlineName"
	sendUpdateCassetteRequest $beamlineName $m_user
	set cassetteList [loadCassetteList $beamlineName $m_user]
	$w_cassette config -editable true
	$w_cassette delete list 0 3
        set n [llength $cassetteList]
	for {set i 0} {$i<$n} {incr i}  {
		set location [lindex {"No cassette" "left" "middle" "right"} $i]
		set cassette [lindex $cassetteList $i]
		set text "$location: $cassette"
		$w_cassette insert list end $text
	}
	$w_cassette selection set $m_cassetteListIndex
	$w_cassette config -editable false 
	set m_cassetteList $cassetteList

	updateCrystalList $beamlineName $m_user $m_cassetteListIndex $m_cassetteList
	set cassetteInfo [list [list $m_user $m_cassetteListIndex $m_cassetteList]]

        $w_update config -state normal

	sendActionMsg "setConfig cassetteInfo $cassetteInfo"
}

# ===================================================
# ===================================================

::itcl::body SequenceCrystals::updateCrystalList { beamlineName user cassetteListIndex cassetteList } {
	trc_msg "SequenceCrystals::updateCrystalList $beamlineName $user $cassetteListIndex $cassetteList"
	
	set data [loadCrystalList $beamlineName $user $cassetteListIndex $cassetteList]
	if { $data==$m_crystalList } {
		trc_msg "m_crystalList is up-to-date"
		return
	}

	set m_crystalList $data
	set m_indexNext 0

	destroy $w_crystalList
	set top $w_crystalSequenceFrame
	set w_crystalList [frame $top.c.canvas.f -bd 0]
	CreateCellsAndInitScrollbars $w_crystalList $top.c.canvas $data
	set m_nElements [llength $data]
	set selectedRow 0
	set m_indexSelect $selectedRow
	setCellColor $w_crystalList
	setCurrentActionColor $w_crystalList

	bindEventHandlers $w_crystalList
}

# ===================================================

::itcl::body SequenceCrystals::sendUpdateCassetteRequest { beamlineName user } {
	trc_msg "SequenceCrystals::sendUpdateCassetteRequest $beamlineName $user"
	set url "$m_updateDataUrl?forBeamLine=${beamlineName}&forUser=${user}"
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
		# error
		set msg "ERROR SequenceCrystals::sendUpdateCassetteRequest http::geturl status=$status"
		trc_msg $msg
	} elseif { $replycode!=200 } {
		# error -> use the default option list
		set msg "ERROR SequenceCrystals::sendUpdateCassetteRequest http::geturl replycode=$replycode"
		trc_msg $msg
                log_error "SequenceCrystals::sendUpdateCassetteRequest $replystatus"
	} else {
		set totalsize $state(totalsize)
		set currentsize $state(currentsize)
		trc_msg "totalsize=$totalsize"
		trc_msg "currentsize=$currentsize"
		set response "No response from server"
		if { $currentsize>1} {
			set response $state(body)
		}
		trc_msg "SequenceCrystals::sendUpdateCassetteRequest $response"
	}
}

# ===================================================

::itcl::body SequenceCrystals::loadCassetteList { beamlineName user } {
	trc_msg "SequenceCrystals::loadCassetteList $beamlineName $user"
	set cassetteList {undefined undefined undefined undefined}

	# load the cassette list from the web server
	set url "$m_cassetteDataUrl?forBeamLine=${beamlineName}&forUser=${user}"
        set webData [loadWebData $url]
        if { [llength $webData]<1 } {
            # try it a second time
            set webData [loadWebData $url]
	}
        if { [llength $webData]>0 } {
            # we have got a tcl list
            set cassetteList $webData
	}

	return $cassetteList
}

# ===================================================

::itcl::body SequenceCrystals::loadCrystalList { beamlineName user cassetteListIndex cassetteList } {
	trc_msg "SequenceCrystals::loadCrystalList $beamlineName $user $cassetteListIndex $cassetteList"

	# create the default crystal list
	set data {}
	foreach x {A B C D E F G H I J K L} {
		for {set y 1} {$y<=8} {incr y} {
			set port ${x}$y
			#if { $port=="A1" } {
			#	# port A1 is reserved for cassetteID
			#	continue;
			#}
			set row [list $port c_$port 0 0 0 0 0 0 0]
			set data [linsert $data end $row]
		}
	}
	set m_lastListUpdateTime [clock seconds]
	set cassette [lindex $cassetteList $cassetteListIndex]
	if { $cassette=="undefined" } {
		return $data
	}

	#test
	#return $data

	# load the crystal list from the web server
	set url "$m_crystalDataUrl?forBeamLine=${beamlineName}&forUser=${user}&forCassetteIndex=${cassetteListIndex}"
        set webData [loadWebData $url]
        if { [llength $webData]<1 } {
            # try it a second time
            set webData [loadWebData $url]
	}
        if { [llength $webData]>0 } {
            # we have got a tcl list
            set data $webData
	}

	set m_lastListUpdateTime [clock seconds]

	trc_msg "SequenceCrystals::loadCrystalList OK"
	return $data
}

# ===================================================

::itcl::body SequenceCrystals::loadWebData { url } {
trc_msg "SequenceCrystals::loadWebData"
trc_msg "$url"
        set data ""
        if { [catch {
            set token [http::geturl $url -timeout 12000]
            upvar #0 $token state
            set status $state(status)
            set replystatus $state(http)
            set replycode [lindex $replystatus 1]
        } err] } {
            log_error "$err $url"
            set status "ERROR $err $url"
        }
	if { $status!="ok" } {
		# error -> use the default crystal list
		set msg "ERROR SequenceCrystals::loadWebData http::geturl status=$status"
		trc_msg "$msg"
	} elseif { $replycode!=200 } {
		# error -> use the default option list
		set msg "ERROR SequenceCrystals::loadWebData http::geturl replycode=$replycode"
		trc_msg $msg
                log_error "SequenceCrystals::loadWebData $replystatus"
	} else {
		set totalsize $state(totalsize)
		set currentsize $state(currentsize)
		trc_msg "totalsize=$totalsize"
		trc_msg "currentsize=$currentsize"
		if { $currentsize>10} {
			set dd $state(body)
			if { [string range $dd 0 3]=="<Err" || [string first "\{" [string range $dd 0 5] ]<0 } {
				set msg "ERROR SequenceCrystals::loadWebData - Web server returned: $dd"
				trc_msg $msg
			} else {
				set d [lindex $dd 0]
				set data $d
			}
		}
	}

return $data
}

# ===================================================

::itcl::body SequenceCrystals::execNetscape { crystalRowIndex } {
trc_msg "SequenceCrystals::execNetscape $crystalRowIndex"
# exec >@ stdout env

#set target "TM0057"
set row [lindex $m_crystalList $crystalRowIndex]
set target [lindex $row 2]
set targetURL [lindex $row 11]

trc_msg "targetURL=$targetURL"

if { [string length $targetURL]<8 } {
    # this can not be a valid url
    return
}

#set dir [pwd]
variable ::env
# set dir $env(PWD)
set dir /tmp/$env(USER)
#trc_msg "dir=$dir"

# make the temporary directory if needed
file mkdir $dir

# exec netscape -remote openFile(/home/gwolf/test1/n/onload.html) &
set htmlFile [file join $dir "loadURL.html"] 

# create a htmlFile with Javascript that redirects to the JCSG Web page for the selected target
set part1 {
<html><head>
<script type="text/javascript">
<!--
function loadTarget( t)
{
//submitUrl= "http://bioinfo-core.jcsg.org/cgi-bin/psat/analyzer.cgi?acc="+ t;
//submitUrl= "http://gwolfpc/test1/test1.asp?x="+ t;
submitUrl= t;
//location.replace( submitUrl);
//window.location.href= submitUrl;
window.open( submitUrl, "_self");
}
// -->
</script>
</head>
<body onLoad='loadTarget("}

set part2 {")'>
</body></html>
}

set text "${part1}${targetURL}${part2}"
#trc_msg "$text"
trc_msg "http://bioinfo-core.jcsg.org/cgi-bin/psat/analyzer.cgi?acc=$target"

set fileid [open $htmlFile w 0777]
puts $fileid "$text"
close $fileid

catch {
exec netscape -remote openFile($htmlFile) &
} err

trc_msg "SequenceCrystals::execNetscape $err"
}


# ===================================================
# ===================================================

::itcl::body SequenceCrystals::sendCheckBoxStates {} {
	set crystalListStates {}
	set nElements $m_nElements
	for {set i 0} {$i < $nElements} {incr i} {
		set crystalListStates [concat $crystalListStates [getCheckbox $i]]
	}
	sendActionMsg "setConfig crystalListStates {$crystalListStates}"
}

# ===================================================

::itcl::body SequenceCrystals::sendActionMsg { msg } {

	trc_msg "sendActionMsg"
	set actionListener $m_actionListener
	set n [llength $actionListener]
	for {set i 0} {$i<$n} {incr i} {
		set listener [lindex $actionListener $i]
		eval $listener SequenceActions $msg
	}
}

# ===================================================

::itcl::body SequenceCrystals::trc_msg { text } {
# puts "$text"
print "$text"
}

# ===================================================
# ===================================================
# public methods

::itcl::body SequenceCrystals::getCrystalID { index } {

	trc_msg "handleNextCrystalClick $index"
	
	if { $index<0 } { return "" }
	set row [lindex $m_crystalList $index]
	set id [lindex $row 1]

	return $id
}

# ===================================================

::itcl::body SequenceCrystals::addActionListener { listener} {

if { $m_actionListener==0 } then {
	set m_actionListener [list $listener]
} else {
	set m_actionListener [list $m_actionListener $listener]
}

}

# ===================================================

::itcl::body SequenceCrystals::setConfig { attribute value} {
trc_msg "SequenceCrystals::setConfig attribute=$attribute value=$value"
switch -exact -- $attribute {
	cassetteInfo {
		set user [lindex $value 0]
		set index [lindex $value 1]
		set cassetteList [lindex $value 2]
		trc_msg "user=$user"
		trc_msg "index=$index"
		trc_msg "cassetteList=$cassetteList"
		set t [expr [clock seconds] - $m_lastListUpdateTime]
		if { $t<6 && $user==$m_user && $index==$m_cassetteListIndex && $cassetteList==$m_cassetteList } {
			trc_msg "cassetteList is up-to-date"
		} else {
			set m_user $user
			set m_cassetteListIndex $index
			set m_cassetteList $cassetteList

			$w_cassette config -state normal
			$w_cassette config -editable true 
                	$w_cassette delete list 0 3
                        set n [llength $cassetteList]
                        for {set i 0} {$i<$n} {incr i}  {
                            set location [lindex {"No cassette" "left" "middle" "right"} $i]
                            set cassette [lindex $cassetteList $i]
                            set text "$location: $cassette"
                            $w_cassette insert list end $text
                        }
			$w_cassette selection set $m_cassetteListIndex
			$w_cassette config -editable false 

			global gBeamline
			#set beamlineName $gBeamline(serverName)
                        set beamlineName $gBeamline(beamlineId)
			updateCrystalList $beamlineName $user $m_cassetteListIndex $m_cassetteList
			enableButtons
		}
	}
	crystalListStates {
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
	nextCrystal {
		if { $m_indexNext!=$value } {
			if { $value<0 } {
				set value 0
			}
			set m_indexNext $value
			setCurrentActionColor $w_crystalList
		}
	}
	currentCrystal {
		if { $m_indexMounted!=$value } {
			set m_indexMounted $value
			if { $value<0 } {
				set m_isCrystalMounted 0
			} else {
				set m_isCrystalMounted 1
			}
			setCurrentActionColor $w_crystalList
			enableButtons
		}
	}
	isRunning {
		set m_isRunning $value
		enableButtons
	}
	default { trc_msg "ERROR unknown attribute=$attribute" }
}; # switch

}

# ===================================================

::itcl::body SequenceCrystals::setMasterSlave { master} {
trc_msg "SequenceCrystals::setMasterSlave $master"
set m_isMaster $master
enableButtons

}

# ===================================================
# ===================================================
#// main

#set top .ex
#SequenceCrystals crystals $top



# ===================================================
