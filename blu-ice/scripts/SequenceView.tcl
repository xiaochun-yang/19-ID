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
# SequenceView.tcl
#
# part of Screening UI
# used by Sequence.tcl
#

error "The screening tab is obsolete in the 'blu-ice' project. Do not source SequenceView.tcl.  Use 'BluIceWidgets' project instead."

class SequenceView {

	# protected variables
	protected variable canvas
	protected variable m_hutchVideoTab 0
    protected variable w_hutchViewWidget

	# public methods
    public method selectVideoView { viewPresetName }

	# protected methods
    private method trc_msg { text } {}

	constructor { path } {
	
		# store the path to the tab frame
        set frame [frame $path -borderwidth 2 -width 523 -height 304 -relief groove]		

		# create the canvas 
		set canvas [ canvas $frame.canvas -width 520 -height 298 ]
		pack $canvas -in $frame

		# create the tab notebook for holding the sample position and overview widgets
		global gColors
		
		set videoNotebook \
			 [
			  iwidgets::tabnotebook $canvas.notebook  \
					-tabbackground lightgrey \
					-background lightgrey \
					-backdrop lightgrey \
					-borderwidth 2\
					-tabpos n \
					-gap -4 \
					-angle 20 \
					-width 513 \
					-height 290 \
					-raiseselect 1 \
					-bevelamount 4 \
					-tabforeground $gColors(dark) \
					-padx 5 -pady 4]
		place $canvas.notebook -x 5 -y 5 

		# create an object to monitor the status of the video tabbed notebook
		uplevel \#0 TabbedNotebookStatus screeningVideoNotebookStatus

		# construct the sample position widgets
		$videoNotebook add \
			 -label "Position Sample"	\
			 -command "screeningVideoNotebookStatus configure -activeTab Sample"
		SamplePositioningWidget \#auto [$videoNotebook childsite 0]  \
			-tabbedNotebookStatusObject screeningVideoNotebookStatus \
			-mainTabName "Screening"

		# construct the hutch view widgets
        $videoNotebook add \
			 -label "View Hutch" \
			 -command "screeningVideoNotebookStatus configure -activeTab Hutch"
		set w_hutchViewWidget [HutchViewWidget \#auto [$videoNotebook childsite 1] \
			-tabbedNotebookStatusObject screeningVideoNotebookStatus \
			-mainTabName "Screening" ]

		# select the sample position tab first
		$videoNotebook select 0
	}
}


# ===================================================
# ===================================================

body SequenceView::selectVideoView { viewPresetName } {

	trc_msg "SequenceView::selectVideoView $viewPresetName"
        if { $viewPresetName=="PositionSample" } {
            set m_hutchVideoTab 0
            $canvas.notebook select 0
            trc_msg "select video tab 0"
        } elseif { $viewPresetName=="x" } {
            trc_msg "select video x (ignore)"
        } else {
            set m_hutchVideoTab 1
            $canvas.notebook select 1
            trc_msg "select video tab 1"
            $w_hutchViewWidget moveToPreset $viewPresetName
        }
}

# ===================================================
# ===================================================

::itcl::body SequenceView::trc_msg { text } {
# puts "$text"
print "$text"
}

# ===================================================
