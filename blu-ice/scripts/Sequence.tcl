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
# Sequence.tcl
#
# Screening UI Tab in blu-ice
#

error "The screening tab is obsolete in the 'blu-ice' project. Do not source Sequence.tcl.  Use 'BluIceWidgets' project instead."

package require Itcl


# ===================================================

::itcl::class Sequence {
# contructor / destructor
constructor { top} {}

# private variables
private variable m_isInitialized 0
# list of all accepted dcss configuration messages that are related to SequnceActions:
private variable m_actionAttributes {
 directory
 actionListParameters
 actionListStates
 actionView
 nextAction
 currentAction
 generalParameters
 detectorMode
 isRunning
}
# list of all accepted dcss configuration messages that are related to SequnceCrystals:
private variable m_crystalAttributes {
 cassetteInfo
 crystalListStates
 nextCrystal
 currentCrystal
}

# protected variables
protected variable w_crystals 0
protected variable w_filelList 0
protected variable w_action 0
protected variable w_view 0

# private methods
private method SequenceFrame { top} {}
private method bindEventHandlers {} {}
private method trc_msg { text } {}

# protected methods

# public methods
public method getInitConfiguration {} {}
public method actionPerformed { sender action args } {}
public method handleOperationEvent { operation operationHandle status args } {}
public method handleUpdateFromComponent { component attribute value } {}
public method test {} {}


}

# ===================================================
# ===================================================

::itcl::body Sequence::constructor { top } {

SequenceFrame $top.sq
pack $top

set m_isInitialized 0
# we will call getInitConfiguration when the dcss message "login_complete" arrives (see handleOperationEvent)

# these global flags will be used in robot_config.tcl
global gConfig
set gConfig(robot,robotState) "1"
set gConfig(robot,useRobot) "0"

bindEventHandlers

# after 2000 {sequence getInitConfiguration}
}

# ===================================================
# ===================================================

::itcl::body Sequence::SequenceFrame { top } {

frame $top -borderwidth 10
pack $top -side top

frame $top.right

set sequenceCrystals $top.sequenceCrystals
set fileList $top.fileList
set sequenceActions $top.right.sequenceActions
set sequenceView $top.right.sequenceView

set w_crystals [SequenceCrystals crystals $sequenceCrystals]
set w_filelList [SequenceResultList results $fileList]
set w_action [SequenceActions action $sequenceActions]
set w_view [SequenceView view $sequenceView]

#grid $sequenceCrystals -row 0 -column 0 -rowspan 2 -sticky news
#grid $fileList -row 2 -column 0 -sticky we 
#grid $sequenceActions -row 0 -column 1 -rowspan 1 -sticky nw
#grid $sequenceView -row 1 -column 1 -rowspan 2 -sticky news
#grid rowconfigure $top 0 -weight 1
#grid columnconfigure $top 0 -weight 1

pack $sequenceActions -side top
pack $sequenceView -side bottom

grid $sequenceCrystals -row 0 -column 0 -rowspan 2 -sticky new
grid $fileList -row 2 -column 0 -sticky we 
grid $top.right -row 0 -column 1 -rowspan 3 -sticky nws
grid rowconfigure $top 0 -weight 1
grid columnconfigure $top 0 -weight 1

}

# ===================================================

::itcl::body Sequence::bindEventHandlers {} {
	$w_action addActionListener [::itcl::code $this actionPerformed]
	$w_crystals addActionListener [::itcl::code $this actionPerformed]
	#register a handler for all stog_operation events
	register_operation_eventHandler "sequence" [::itcl::code $this handleOperationEvent]
	register_operation_eventHandler "sequenceGetConfig" [::itcl::code $this handleOperationEvent]
	register_operation_eventHandler "sequenceSetConfig" [::itcl::code $this handleOperationEvent]
	register_operation_eventHandler "login_complete" [::itcl::code $this handleOperationEvent]

	# register for changes in client state (changes will be handled in handleUpdateFromComponent)
	clientState register $this master
}

# ===================================================

::itcl::body Sequence::trc_msg { text } {
# puts "$text"
print "$text"
}

# ===================================================
# ===================================================
# public methods

::itcl::body Sequence::getInitConfiguration {} {
trc_msg "Sequence::getInitConfiguration"

set m_isInitialized 0
start_operation sequenceGetConfig getConfig all
}

# ===================================================


::itcl::body Sequence::actionPerformed { sender action args} {

trc_msg "Sequence::actionPerformed sender=$sender action=$action args=$args"

if { $sender=="SequenceActions" && $action=="selectVideoView" } {
	# update the view tab
	$w_view selectVideoView $args
        return
}


# make sure that we are master
if { ! [dcss is_master] } {
	#dcss sendMessage "gtos_become_master noforce"
	#gw dcss sendMessage "gtos_become_master force" 
        log_error "This client is not the master."
        getInitConfiguration
        return
}

if { $m_isInitialized==0 } {
	getInitConfiguration
}

if { $action=="setConfig" } {
	# start_operation sequenceSetConfig setConfig $args
	# eval {start_operation sequenceSetConfig setConfig} $args
        set handle [eval {start_waitable_operation sequenceSetConfig setConfig} $args]
        set result [wait_for_operation $handle]
	set attribute [lindex $args 0]
	set value [lindex $args 1]
        if { $attribute=="useRobot" } {
            $w_action setConfig useRobot $value
        }
} elseif { $action=="getConfig" } {
	eval {start_operation sequenceSetConfig getConfig} $args
} elseif { $action=="start" } then {
	start_operation sequence "start"
} elseif { $action=="stop" } {
	start_operation sequenceSetConfig setConfig stop 0
} elseif { $action=="dismount" } {
	start_operation sequenceSetConfig setConfig dismount 0
} elseif { $action=="doseNormalize" } {
	start_operation sequence "doseNormalize"
} else {
	eval {start_operation sequence $action} $args
}

}

# ===================================================

::itcl::body Sequence::handleOperationEvent { operation operationHandle event status args } {
trc_msg "Sequence::handleOperationEvent $operation $event $status: $args"

if { $operation=="login_complete" } {
    trc_msg "after 4000 {sequence getInitConfiguration}"
    after 4000 {sequence getInitConfiguration}
    trc_msg "Sequence::handleOperationEvent OK"
    return
}

if { [llength $args]<1 } {
    trc_msg "Sequence::handleOperationEvent ignore message without args"
    return
}

set msgType [lindex $args 0]

#if { $event=="start" && $msgType=="start" } {
#	$w_filelList createFileList
#}

if { $event=="start" } {
	return
}

if { $operation=="sequenceGetConfig" && $event=="completed" && $status=="normal" && $args=="getConfig all OK" } {
	set m_isInitialized 1
	trc_msg "m_isInitialized=$m_isInitialized"
	return
}

if { $msgType=="result" } {
	set operation [lindex $args 1]
	set subdir [lindex $args 2]
	set fileName [lindex $args 3]
	trc_msg "update result: operation=$operation subdir=$subdir fileName=$fileName"
	$w_filelList updateFileList $subdir $fileName
	return
}

if { $msgType=="getConfig" || $msgType=="setConfig" } {
	set attribute [lindex $args 1]
	set value [lindex $args 2]
	trc_msg "attribute=$attribute value=$value"
	if { $attribute=="stop" } {
		trc_msg "stop $value"
		return
	}
	if { $attribute=="dismount" } {
		#trc_msg "dismount $value"
		return
	}
	if { $attribute=="robotState" } {
		trc_msg "robotState $value"
                global gConfig
                set gConfig(robot,robotState) $value
                # update window in robot_config.tcl
                roboState_changed
		return
	}
	if { $attribute=="useRobot" } {
		trc_msg "useRobot $value"
                global gConfig
                set gConfig(robot,useRobot) $value
		$w_action setConfig useRobot $value
		return
	}
	foreach a $m_actionAttributes {
		if { $a!=$attribute } { continue }
		$w_action setConfig $attribute $value
		if { $a=="directory" } { 
			
			#test
			#set value "U:/gwolf"
			
                       $w_filelList setDirectory $value
                       $w_filelList createFileList
		}
		if { $a=="isRunning" } { $w_crystals setConfig $attribute $value }
		return
	}
	foreach a $m_crystalAttributes {
		if { $a!=$attribute } { continue }
		$w_crystals setConfig $attribute $value
		if { $a=="nextCrystal" } { 
			set id [$w_crystals getCrystalID $value]
			$w_action setConfig $attribute $id
		}
		if { $a=="currentCrystal" } {
			set id [$w_crystals getCrystalID $value]
			$w_action setConfig $attribute $id
		}
		if { $a=="cassetteInfo" } {
			set id [$w_crystals getCrystalID 0]
			$w_action setConfig nextCrystal $id
		}
		return
	}
	trc_msg "ERROR unknown attribute=$attribute"
	return
}

}

# ===================================================

::itcl::body Sequence::handleUpdateFromComponent { component attribute value } {
trc_msg "Sequence::handleUpdateFromComponent $component $attribute $value"
    switch $attribute {
	# update button states if master status changes
	master {
			#updateButtons
                        trc_msg "master state=$value"
                        $w_action setMasterSlave $value
                        $w_crystals setMasterSlave $value
		}

    }
}

# ===================================================

::itcl::body Sequence::test {} {
puts "Sequence::test"
}


# ===================================================
# ===================================================
# ===================================================
# ===================================================
