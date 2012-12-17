#!/usr/bin/wish


set DCS_DIR "/usr/local/dcs"
set DCS_TCL_PACKAGES_DIR "$DCS_DIR/dcs_tcl_packages/"

package require Itcl
#namespace import itcl::*
#load $DCS_DIR/tcl_clibs/linux/tcl_clibs.so dcs_c_library

#the following should be changes to a package require
#source $DCS_TCL_PACKAGES_DIR/DcsRunSequencer.tcl


class RunSequenceViewer {
	private variable _runCalculator
	private variable _textScrollY
	private variable _textScrollX
	private variable _textWidget
	private variable _runIndex 0
	private variable _pageSize 10
	public variable _entrySelectCommand
	public variable font *-courier-bold-r-normal--12-*-*-*-*-*-*-*
	public variable _collectedFrameColor darkgrey
	public variable _collectingFrameColor red
	public variable _uncollectedFrameColor black
	public variable _width 15
	public variable _snapShotView 0
	
	public method changeView
	public method fillViewer
	public method restoreColors
	public method focusOnCurrentFrame {}
	public method showSnapShot {}
	private method verifyRunIndex {}
	private method insertFrame {textIndex frameIndex}

	constructor { path runCalculator args} {
		
		frame $path
		
		# handle configuration options
		eval configure $args
		
		# create the widgets
		set _textScrollY [scrollbar $path.yscroll -command "$this changeView" -orient vertical]
		set _textScrollX [scrollbar $path.xscroll -command [list $path.text xview] -orient horizontal]
		set _textWidget [text $path.text -wrap none -width $_width -xscrollcommand "$_textScrollX set"  -cursor hand2 -state normal \
									-background gray80 -selectbackground gray80]

		#let the scroll bar widgets know what protocol to use.
		$_textScrollY set 0.0 1.0
		$_textScrollX set 0.0 1.0

		#pack the internal widgets
		pack $_textScrollY -side right -fill y
		pack $_textScrollX -side bottom -fill x
		pack $_textWidget -side left -fill both -expand true

		bind $_textWidget <Configure> "$this fillViewer"
		bind $_textWidget <Button-1> {}
		bind $_textWidget <Double-Button-1> {}
		
		
		set _runCalculator $runCalculator
	}

}


body RunSequenceViewer::focusOnCurrentFrame {} {
	set nextFrame [$_runCalculator cget -nextFrame]
	set _runIndex [expr int( $nextFrame - $_pageSize / 2)]

	fillViewer
}


#######################################################
#
######################################################
body RunSequenceViewer::verifyRunIndex {} {
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
body RunSequenceViewer::showSnapShot {} {

	#erase what is currently in the text box.
	$_textWidget configure -state normal
	$_textWidget delete 1.0 end
	$_textWidget insert end "[$_runCalculator getMotorPositionsAtIndex 0]\n" "collectingFrameTag"
	restoreColors


	$_textWidget configure -state disabled
}


##############################################################
#
###############################################################
body RunSequenceViewer::fillViewer {} {
	if { $_snapShotView == 1} {
		showSnapShot
		return
	}

	$_textWidget configure -state normal
	set nextFrame [$_runCalculator cget -nextFrame]


	$_textWidget tag configure collectingFrameTag -foreground $_collectingFrameColor -font $font
	$_textWidget tag configure collectedFrameTag -foreground $_collectedFrameColor -font $font
	$_textWidget tag configure uncollectedFrameTag -foreground $_uncollectedFrameColor  -font $font
	$_textWidget tag configure completedRunTag -foreground $_uncollectedFrameColor  -font $font
	
	#make sure that we dont try to do an insane request.
	verifyRunIndex

	#erase what is currently in the text box.
	$_textWidget delete 1.0 end
	
	set totalFrames [$_runCalculator getTotalFrames]

	#fill up until not all of the text is visible or we have reached the end of the run
	set displayFrame [expr $_runIndex]
	while { [lindex [$_textWidget yview] 1] == 1 && $displayFrame < $totalFrames} {
		insertFrame end $displayFrame
		incr displayFrame
	}

	#insert the COMPLETE message into the run sequence if it is complete and visible
	if { $nextFrame >= $totalFrames && $displayFrame >= $totalFrames } {
		$_textWidget insert end "Complete\n" "completedRunTag"
	}

	#insert the end into the run sequence if the end of the run is visible, but the run isn't complete
	if { $nextFrame < $totalFrames && $displayFrame >= $totalFrames } {
		$_textWidget insert end "End\n" "completedRunTag"
	}


	#insert one more line to be sure to see everything
	if { $nextFrame < $totalFrames && $displayFrame < $totalFrames } {
		insertFrame end $displayFrame
	}
	
	#calculate the last frame shown in the box
	set endIndex [expr $displayFrame]
	
	set displayFrame  [expr $_runIndex - 1]
	if {  [lindex [$_textWidget yview] 1] == 1 } {
		#start filling up from the bottom
		while { [lindex [$_textWidget yview] 1] == 1 && $displayFrame >= 0} {
			insertFrame 0.0 $displayFrame
			incr displayFrame -1
		}
	}

	restoreColors

	#calculate the first frame shown in the box
	set startIndex [expr $displayFrame]

	#set the size and offset of the scroll bar
	$_textScrollY set [expr 1.0 - ($totalFrames - $startIndex) / double($totalFrames)] [expr 1.0 - ($totalFrames - $endIndex) / double($totalFrames)] 
	#set the current pages size for future page scrolling requests
	set _pageSize [expr $endIndex - $startIndex]

	$_textWidget configure -state disabled
}


body RunSequenceViewer::restoreColors {} {
	$_textWidget tag configure collectingFrameTag -foreground $_collectingFrameColor -font $font
	$_textWidget tag configure collectedFrameTag -foreground $_collectedFrameColor -font $font
	$_textWidget tag configure uncollectedFrameTag -foreground $_uncollectedFrameColor  -font $font
	$_textWidget tag configure completedRunTag -foreground $_uncollectedFrameColor  -font $font
}

###############################################################
#
###############################################################
body RunSequenceViewer::insertFrame {textIndex frameIndex} {
	set totalFrames [$_runCalculator getTotalFrames]
	set nextFrame [$_runCalculator cget -nextFrame]

	if { $frameIndex < $nextFrame } {
		$_textWidget insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "collectedFrameTag runIndexTag$frameIndex"
	} elseif {$frameIndex == $nextFrame } {
		$_textWidget insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "collectingFrameTag runIndexTag$frameIndex"
	} elseif {$frameIndex < $totalFrames } {
		$_textWidget insert $textIndex "[$_runCalculator getMotorPositionsAtIndex $frameIndex]\n" "uncollectedFrameTag runIndexTag$frameIndex"
	}

	$_textWidget tag bind runIndexTag$frameIndex <Enter> "$_textWidget tag configure runIndexTag$frameIndex -underline 1"
	$_textWidget tag bind runIndexTag$frameIndex <Leave> "$_textWidget tag configure runIndexTag$frameIndex -underline 0"
	$_textWidget tag bind runIndexTag$frameIndex <Double-1> [list $_entrySelectCommand $frameIndex] 
	
	
}



#############################################################
#
############################################################
body RunSequenceViewer::changeView {command args } {

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

