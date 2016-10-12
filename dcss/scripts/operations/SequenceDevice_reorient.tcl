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
# SequenceDevice.tcl
#
# called by scripted operations
#  sequence.tcl
#  sequenceGetConfig.tcl
#  sequenceSetConfig.tcl
#
#
#
# config in database.dat:
#
# sequenceDeviceState
# 13
# self standardString
# gwolf 0 {undefined undefined undefined undefined}
#
# sequence
# 11
# self sequence 1
#
# sequenceSetConfig
# 11
# self sequenceSetConfig 1
#
# sequenceGetConfig
# 11
# self sequenceGetConfig 0
#
# Note, the operation sequenceGetConfig is defined as operation.masterOnly = 0,
# i.e. it can also be called in passive mode
#
#
# beamlineID
# 13
# self standardString
# 11-1
#
package require Itcl
package require http
package require DCSSpreadsheet
#

#source /usr/share/tcl8.3/http2.4/http.tcl

# =======================================================================

proc create_sequenceDevice { instanceName} {
    set dev [SequenceDevice $instanceName]
    return $dev
}

# =======================================================================

proc test1 { } {
puts "TEST1"
set x [namespace current]
puts $x
namespace eval nScripts {
normalize_start
}
puts "TEST1 OK"
}


# =======================================================================

::itcl::class SequenceDevice {
    private common ADD_BEAM_INFO_TO_JPEG 0

    # action states that will be broadcasted
    private variable m_directory "/data/UserName"
    private variable m_actionListParameters "{mountNext {}} {Pause {}}"
    private variable m_actionListStates
    private variable m_nextAction 0
    private variable m_currentAction -1
    private variable m_detectorMode 0
    private variable m_distance 300.0
    private variable m_beamstop 40.0
    private variable m_isRunning 0

# crystal states that will be broadcasted
private variable m_cassetteInfo "gwolf 0 {undefined undefined undefined undefined}"
private variable m_crystalListStates "1 1 1 1 1"
private variable m_nextCrystal 0
private variable m_currentCrystal -1
private variable m_mountingCrystal -1

# added for manual mode, to avoid changing screening selections
private variable m_manualMode 0
private variable m_currentCassette n
private variable m_currentColumn N
private variable m_currentRow 0

# state for robot configuration
private variable m_robotState 1
private variable m_useRobot 0

# internal device states
private variable m_isInitialized 0
private variable m_keepRunning 0
private variable m_dismountRequested 0
private variable m_crystalPortList "A2 A3 A4 A5 A6"
private variable m_crystalIDList "c1 c2 c3 c4 c5"
private variable m_crystalDirList "null null null null null"

private variable m_lastImage1 ""
private variable m_lastImage2 ""

##### if current cassette status change, we need to re-map the
### spreadsheet rows to position in robot_cassette
private variable m_currentCassetteStatus "u"
private variable m_indexMap {}

private variable a_fileCounterInfo
private variable m_phiZero 0
#
# the following parameters are defined in initBeamlineParameters
private variable m_crystalDataUrl
private variable m_beamlineName
private variable m_strategyDir
#
#
private variable m_isSyncedWithRobot no

#change this to 1 if you want to force sync with robot after mount next call
private variable TRY_SYNC_WITH_ROBOT 1

#skip all other actions is nothing is mounted
private variable m_skipThisSample 0

#lock next crystal
private variable m_lockNextCrystal 0

private variable m_lastSessionID ""
private variable m_lastUserName ""

private variable m_SILID -1
private variable m_SILEventID -1
private variable m_numRowParsed 0
    #this is a hardcoded header for old service
    private variable m_defaultHeader {
        {Port 4 readonly}
        {CrystalID 8 readonly}
        {Protein 8 readonly}
        {Comment 35}
        {Directory 22 readonly}
        {FreezingCond 12 readonly}
        {CrystalCond 72 readonly}
        {Metal 5 readonly}
        {Priority 8 readonly}
        {Person 8 readonly}
        {CrystalURL 25 readonly}
        {ProteinURL 25 readonly}
    }

    private variable m_currentHeader ""
    private variable m_currentHeaderNameOnly ""
    ##where are the Port and ID in the columns
    private variable m_PortIndex         -1
    private variable m_IDIndex           -1
    private variable m_DirectoryIndex    -1
    private variable m_SelectedIndex     -1

    ##to save jpeg images and send them to SIL server later with detector iamge
    private variable m_jpeg1 ""
    private variable m_jpeg2 ""
    private variable m_jpeg3 ""
    private variable m_img1 ""
    private variable m_img2 ""
    private variable m_img3 ""

    ######to convert img to jpg only for screening
    private variable m_imageWaitingList ""

    private variable m_imgFileExtension "img"

    ##if get spreadsheet failed, it will keep retrying until get it
    ##during that time, no screening will be allowed to run
    private variable m_spreadsheetStatus 0
    ##### 0: not initialized
    ##### 1: OK
    ##### <0: retrying

    private variable m_afterID ""

    ############ to skip loop centering error or stop#######
    private variable m_numLoopCenteringError 0

    private variable m_motorForVideo [list \
    sample_x \
    sample_y \
    sample_z \
    gonio_phi \
    gonio_kappa \
    camera_zoom \
    ]


# constructor
constructor { args } {}

private method clearImages { } {
    set m_jpeg1 ""
    set m_jpeg2 ""
    set m_jpeg3 ""
    set m_img1 ""
    set m_img2 ""
    set m_img3 ""
}

private proc angleSpan { angle } {
    while {$angle < 0.0} {
        set angle [expr $angle + 360.0]
    }
    while {$angle >= 360.0} {
        set angle [expr $angle - 360.0]
    }
    if {$angle > 180.0} {
        set angle [expr 360.0 - $angle]
    }
    return $angle
}
public proc getPortIndexInCassette { cassette row column } {}
public proc getPortStatus { cassette row column } {}

# public methods
public method operation { args } {}
public method setConfig { args } {}
public method getConfig { args } {}
public method syncWithRobot { { try_sync 0 } args } {}
public method reset { args } { }

####for manual mode: single action per operation
public method manual_operation { op args }

public method onNewMaster { user clientId } {
    if {$m_isInitialized != 0} {
        ###ignore
        return
    }
    set m_lastUserName $user
    set m_lastSessionID [get_user_session_id $clientId]
    log_warning using user $user to init screening
    initialization
}

public method retryLoadingSpreadsheet { } {
    log_warning retrying load spreadsheet
    set m_afterID ""

    updateCassetteInfo
}

# private methods
private method initialization {} {}
private method checkInitialization {} {}
private method initBeamlineParameters {} {}
private method initActionStates {} {}
private method loadStateFromDatabaseString {} {}
private method saveStateToDatabaseString {} {}
private method stop { args } {}
private method dismount { args } {}
private method run {} {}
private method run_internal {} {}
private method runAction { index } {}
private method spinMsgLoop {} {}
private method sleep { msec } {}
private method getNextAction { current } {}
private method getNextCrystal { current } {}
private method getCrystalName {} {}
private method getCrystalNameForLog {} {}
private method getImgFileName { nameTag fileCounter } {}
private method getImgFileExt { }
private method getFileCounter { subdir fileExtension } {}
private method createDirectory { subdir } {}
private method getUserName {} {}
private method loadCrystalList { } {}
private method refreshWholeSpreadsheet { data }
private method updateRows { data }
private method parseOneRow { contents }

private method clearMounted { args } {}
private method updateAfterDismount { }

private method setPhiZero {} {}

#update the strings
private method updateCrystalSelectionListString
private method updateScreeningActionListString
private method updateScreeningParametersString
private method updateCrystalStatusString

private method loadCrystalSelectionListString
private method loadCrystalStatusString
#
# these functions call the hardware
# added for manual mode, doMountNextCrystall will also call this method
private method mountCrystal { cassette column row wash_cycle } {}

private method doManualMountCrystal { args } {}

private method doMountNextCrystal { {num_cycle_to_wash 0} } {}
private method doDismount {} {}
private method doPause {} {}
private method doOptimizeTable {} {}
private method doLoopAlignment {} {}
private method doVideoSnapshot { zoom nameTag} {}
private method doCollectImage { deltaPhi time nImages nameTag} {}
private method doExcitation
private method doRotate { angle } {}
private method checkIfRobotResetIsRequired {} {}
#
private method sendResultUpdate { operation subdir fileName } {}

#sync with robot
private method getCrystalStatus { index } {}
private method getCrystalIndex { row column } {}

private method actionSelectionOK {} {}
private method crystalSelectionOK {} {}
private method checkCrystalList { varName } {}
private method listIsUnique { list_to_check }
private method actionParametersOK { varName fixIt }
private method getCurrentPortID { }
private method getNextPortID { }
private method getCurrentRawPort { }
private method getNextRawPort { }

private method drawInfoOnVideoSnapshot

private method updateCassetteInfo { }

#it will check if at least 2 images are available and
#the angle is more than 5 degrees.
private method doAutoindex { }
private method getImageHeader { fileName }
private method getPhi { contents }
private method getRawSessionId { sessionId }
private method runMatchup { snapshot1 snapshot2 }

### get from config and unique
private method getStrategyFileName { }
### this set is to set the file field of the string "strategy_field"
private method setStrategyFileName { full_path {runName ""} }

public method handleSpreadsheetUpdateEvent { args }

#####the roadmap is using more strings
public method handlePortStatusChangeEvent { args }

#### call image convert to create thumbnail
public method handleLastImageChangeEvent { args }

public method handleCassetteListChangeEvent { args }

private method checkCassettePermit { cassette }

private method moveMotorsToDesiredPosition { } {
    variable ::nScripts::screeningParameters

    if {[llength $screeningParameters] >= 5} {
        set distanceMotor [::nScripts::getDetectorDistanceMotorName]
        move $distanceMotor to $m_distance
        move beamstop_z to $m_beamstop
        wait_for_devices beamstop_z $distanceMotor
    }
}

private method waitForMotorsForVideo { }
private method waitForMotorsForCollect { }

private method videoSnapshotBoxAndNoBox { filename } 
private method videoSnapshotScan { dir fileRoot deltaPhiList } 
}



# =======================================================================
# =======================================================================

::itcl::body SequenceDevice::constructor { args } {
    eval configure $args
set a_fileCounterInfo(jpg) 0
set a_fileCounterInfo(dir_jpg) 0
set a_fileCounterInfo(subdir_jpg) 0
set a_fileCounterInfo(crystalName_jpg) 0

set a_fileCounterInfo(img) 0
set a_fileCounterInfo(dir_img) 0
set a_fileCounterInfo(subdir_img) 0
set a_fileCounterInfo(crystalName_img) 0

set a_fileCounterInfo(bip) 0
set a_fileCounterInfo(dir_bip) 0
set a_fileCounterInfo(subdir_bip) 0
set a_fileCounterInfo(crystalName_bip) 0

set m_imgFileExtension [getImgFileExt]

registerEventListener sil_event_id [list $this handleSpreadsheetUpdateEvent]
registerEventListener robot_cassette [list $this handlePortStatusChangeEvent]
registerEventListener lastImageCollected [list $this handleLastImageChangeEvent]
registerEventListener cassette_list [list $this handleCassetteListChangeEvent]
registerMasterCallback [list $this onNewMaster]
}

# =======================================================================

::itcl::body SequenceDevice::operation { op args } {
variable ::nScripts::screening_msg
variable ::nScripts::auto_sample_msg
set auto_sample_msg ""
 
puts "SequenceDevice::operation $op $args"

set screening_msg ""

set m_lastUserName [getUserName]

set sessionID [lindex $args end]
if {$sessionID != ""} {
    if {$sessionID == "SID"} {
        set sessionID PRIVATE[get_operation_SID]
        puts "sequence use operation SID: $sessionID"
    }

    set m_lastSessionID $sessionID
    puts "operation sessionID $m_lastSessionID"

    variable ::nScripts::screening_user
    set screening_user $m_lastUserName
}

set m_manualMode 0

checkInitialization

checkCassettePermit $m_currentCassette

switch -exact -- $op {
    start {
        if {$m_spreadsheetStatus <= 0} {
            log_error cannot start before success of getting spreadsheet
            return -code error "cannot start before success of getting spreadsheet"
        }
        set m_keepRunning 1
        run
    }
    dismount {
        ###only called internally by setConfig dismount
        set m_dismountRequested 1
        set m_keepRunning 0
        run
    }
    clear_mounted {
        clearMounted
    }
    default {
        log_error "Screening unknown operation $op"
        return -code error "SequenceDevice::operation unknown operation $op"
    }
}
puts "SequenceDevice::operation OK"
return [list sequence $op OK]
}

# =======================================================================

::itcl::body SequenceDevice::setConfig { attribute value args } {
variable ::nScripts::screening_msg
variable ::nScripts::scn_crystal_msg
variable ::nScripts::scn_action_msg
variable ::nScripts::crystalStatus
puts "SequenceDevice::setConfig $attribute $value args: $args"

set screening_msg ""
set scn_crystal_msg ""
set scn_action_msg ""

####### if running, keep the starter's session id
if {!$m_isRunning} {
    set m_lastUserName [getUserName]
    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        if {$sessionID == "SID"} {
            set sessionID PRIVATE[get_operation_SID]
            puts "sequence use operation SID: $sessionID"
        }

        set m_lastSessionID $sessionID
        puts "setConfig sessionID $m_lastSessionID"

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }
}

set m_manualMode 0

checkInitialization

if { $attribute=="stop" } {
    set result [list [stop $value $args]]
    return $result
}
if { $attribute=="dismount" } {
    set result [list [dismount $value $args]]
    return $result
}
if { $attribute=="currentCrystal" } {
    return -code error "SequenceDevice::setConfig m_currentCrystal is readonly"
}

##############################################################################
# put special cases here if they need to change or check input value       ###
##############################################################################
if { $attribute=="directory" || \
$attribute=="distance" || \
$attribute=="beamstop" } {
    if {$m_isRunning} {
        set screening_msg "error: $attribute is readonly during run"
        return -code error "SequenceDevice::setConfig $attribute is readonly during a run"
    }
    if { $attribute=="directory"} {
        set value [TrimStringForRootDirectoryName $value]
    }
} elseif { $attribute=="nextAction" } {
    if {$m_currentCrystal < 0 && $value != 0} {
        set value 0
        log_error "must mount first when there is no current crystal"
    }
} elseif { $attribute=="actionListStates" || $attribute=="simpleActionListStates" } {
    if {[lindex $value 0] != 1} {
        log_error "Mount Next Crystal must be always selected"
        set value [lreplace $value 0 0 1]
    }
} elseif { $attribute=="cassetteInfo" } {
    if {[lindex $crystalStatus 3] == "1"} {
        set screening_msg "error: cannot switch cassette while sample mounted"
        return -code error "cannot switch spreadsheet while sample is mounted"
    }
    if {[catch {
        checkCassettePermit [lindex $value 1]
    } errMsg]} {
        log_error $errMsg
        set value $m_cassetteInfo
    }
} elseif { $attribute=="nextCrystal" } {
    if {$m_isRunning && $m_lockNextCrystal} {
        log_error "too late to change, already sent to robot"
        set scrn_crystal_msg "error: too late to change"
        updateCrystalStatusString 
        updateCrystalSelectionListString
        return -code error "nextCrystal locked"
    }
        
    set n [llength $m_crystalListStates]
    if {$value < 0 || $value >= $n} {
        set scn_crystal_msg "error: out of range"
        return -code error "SequenceDevice::setConfig nextCrystal value out of range"
    }
    set m_crystalListStates [lreplace $m_crystalListStates $value $value 1]
    checkCrystalList m_crystalListStates
    #above function may turn off the bit we just turned on
    set value [getNextCrystal $value]
} elseif { $attribute=="crystalListStates" } {
    if {$m_isRunning && $m_lockNextCrystal} {
        if {$m_nextCrystal < 0} {
            set scn_crystal_msg "error: too late to change"
            log_warning "too late to change, already sent to robot, will take effect next time"
        } else {
            if {[lindex $value $m_nextCrystal] != "1"} {
                set scn_crystal_msg "error: too late to change"
                log_error "too late to unselect, already sent to robot"
                set value [lreplace $value $m_nextCrystal $m_nextCrystal 1]
            }
        }
    }
    checkCrystalList value
} elseif { $attribute=="useRobot" } {
    #no crystal selection OK will be put out
    if {$m_isRunning} {
        set screening_msg "error: cannot change during run"
        return -code error "SequenceDevice::setConfig useRobot readonly during a run"
    }
} elseif { $attribute=="actionListParameters" } {
    #only warning
    actionParametersOK value 1
}
# set the corresponding variable to the new state
if {$attribute != "simpleActionListStates"} {
    set paramName m_$attribute
    set val [list $value]
} else {
    set paramName m_actionListStates
    set val [list $value]
}

if {![info exists $paramName]} {
    set screening_msg "error: no $paramName"
    return -code error "no such attribute"
}

if { [catch "set $paramName $val" error] } {
    set screening_msg "failed to set $paramName"
    log_error "Screening setConfig $error"
    return -code error "setConfig $error"
}

# additionally, handle special cases 
if { $attribute=="nextAction" } {
    # set the corresponding checkbox to 1
    set i [set $paramName]
    set m_actionListStates [lreplace $m_actionListStates $i $i 1]

    # if the system is not running ...
    if { $m_isRunning != 1 } {
        set m_currentAction -1
    }
    updateScreeningActionListString
} elseif { $attribute=="nextCrystal" } {
    updateCrystalSelectionListString
    updateCrystalStatusString 
} elseif { $attribute=="actionListStates" } {
    # update nextAction
    set m_nextAction [getNextAction $m_nextAction]
    #send_operation_update "setConfig nextAction $m_nextAction"
    actionParametersOK m_actionListParameters 1
    updateScreeningParametersString
    updateScreeningActionListString
} elseif { $attribute=="simpleActionListStates" } {
    # update nextAction
    if {$m_isRunning} {
        set m_nextAction [getNextAction [expr $m_currentAction + 1]]
    } else {
        set m_nextAction [getNextAction $m_nextAction]
    }
    #send_operation_update "setConfig nextAction $m_nextAction"
    actionParametersOK m_actionListParameters 1
    updateScreeningParametersString
    updateScreeningActionListString
} elseif { $attribute=="directory" || \
$attribute=="distance" || \
$attribute=="beamstop" } {
    updateScreeningParametersString
} elseif { $attribute=="detectorMode" } {
    set m_imgFileExtension [getImgFileExt]
    updateScreeningParametersString
} elseif { $attribute=="crystalListStates" } {
    # update nextCrystal
    set m_nextCrystal [getNextCrystal $m_nextCrystal]
    #send_operation_update "setConfig nextCrystal $m_nextCrystal"
    updateCrystalSelectionListString
    updateCrystalStatusString 
} elseif { $attribute=="cassetteInfo" } {
    updateCassetteInfo
} elseif { $attribute=="actionListParameters" } {
    updateScreeningParametersString
    getConfig all
} elseif { $attribute=="useRobot" } {
    if {$value} {
        #update m_isSyncedWithRobot
        syncWithRobot $TRY_SYNC_WITH_ROBOT
        checkCrystalList m_crystalListStates
        set m_nextCrystal [getNextCrystal $m_nextCrystal]
        updateCrystalSelectionListString
        updateCrystalStatusString 
        #check whether we need to reset next action because we may cleared
        #current crystal
        if {$m_currentCrystal < 0 && $m_nextAction != 0} {
            set m_nextAction 0
            set m_actionListStates [lreplace $m_actionListStates 0 0 1]
            updateScreeningActionListString
            log_warning Action Begin moved to Mount Next Crystal
        }
    } else {
        set m_isSyncedWithRobot no
        updateCrystalStatusString 
    }
}

return [list setConfig $attribute $value]
}

# =======================================================================

::itcl::body SequenceDevice::getConfig { attribute args } {
puts "SequenceDevice::getConfig $attribute $args"

checkInitialization

if { $attribute=="robotState" } {
    checkIfRobotResetIsRequired 
}

if { $attribute!="all" } {
    set paramName m_$attribute
    if { [catch "set val [list [set $paramName]]" error] } {
        log_error "Screening getConfig $error"
        return -code error "getConfig $error"
    }
    # puts "send_operation_update $attribute $val"
    # send_operation_update "getConfig $attribute $val"
    return [list getConfig $attribute $val]
}

puts "SequenceDevice::getConfig all OK"

updateScreeningActionListString
updateCrystalSelectionListString
updateScreeningParametersString
updateCrystalStatusString 
return [list getConfig all OK]
}

::itcl::body SequenceDevice::manual_operation { op args } {
    puts "SequenceDevice::manual_operation $op $args"
    variable ::nScripts::screening_msg
    variable ::nScripts::auto_sample_msg
    set auto_sample_msg ""
    set screening_msg ""
 
    set m_lastUserName [getUserName]
    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        if {$sessionID == "SID"} {
            set sessionID PRIVATE[get_operation_SID]
            puts "manual_sequence use operation SID: $sessionID"
        }

        set m_lastSessionID $sessionID
        puts "manual sessionID $m_lastSessionID"

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    set m_manualMode 1

    checkInitialization

    switch -exact -- $op {
        mount {
            eval doManualMountCrystal $args
        }
        default {
            return -code error "did not support manual $op"
        }
    }
}
# =======================================================================
# =======================================================================
# private methods

::itcl::body SequenceDevice::checkInitialization {} {
    if {$m_isInitialized == 0} {
        initialization 
    }

    #always check spreadsheet update
    #handleSpreadsheetUpdateEvent
}
::itcl::body SequenceDevice::initialization {} {
    variable ::nScripts::screening_user
    puts "init SequenceDevice from database"
    set m_isInitialized 1

    global gSessionID

    if {$m_lastUserName == "" || $m_lastSessionID == ""} {
        set m_lastUserName blctl
        set m_lastSessionID $gSessionID
    }

    set screening_user $m_lastUserName
    
    initBeamlineParameters
    initActionStates
    loadStateFromDatabaseString
    loadCrystalStatusString
    loadCrystalSelectionListString
    loadCrystalList
    syncWithRobot $TRY_SYNC_WITH_ROBOT
}

# =======================================================================

::itcl::body SequenceDevice::initBeamlineParameters {} {
puts "SequenceDevice::initBeamlineParameters"

#set m_crystalDataUrl "http://smb.slac.stanford.edu:8084/crystals/getCrystalData.jsp"
set m_crystalDataUrl [::config getCrystalDataUrl] 

# read string "beamlineID" from database.dat
variable ::nScripts::beamlineID
set m_beamlineName $beamlineID

set rootDir [::config getStrategyDir]
#set rootDir "/home/webserverroot/servlets/webice/data/strategy"
set m_strategyDir [file join $rootDir $m_beamlineName]
puts "strategyDir: $m_strategyDir"


puts "SequenceDevice::initBeamlineParameters OK"
}

# =======================================================================

::itcl::body SequenceDevice::initActionStates {} {
    puts "SequenceDevice::initActionStates"
    
    variable ::nScripts::screeningParameters
    set m_actionListParameters [lindex $screeningParameters 0]
    set m_detectorMode [lindex $screeningParameters 1]
    set m_directory [lindex $screeningParameters 2]
    set m_distance [lindex $screeningParameters 3]
    set m_beamstop [lindex $screeningParameters 4]

    #####remote in next version
    if {$m_distance == ""} {
        variable ::nScripts::detector_z
        set m_distance $detector_z
    }
    if {$m_beamstop == ""} {
        variable ::nScripts::beamstop_z
        set m_beamstop $beamstop_z
    }

    #set m_actionListStates ""
    variable ::nScripts::screeningActionList
    set m_currentAction [lindex $screeningActionList 1]    
    set m_nextAction [lindex $screeningActionList 2]    
    set m_actionListStates [lindex $screeningActionList 3]    
    set m_nextAction [getNextAction $m_nextAction]

    #### detector mode changed ###
    set m_imgFileExtension [getImgFileExt]
puts "SequenceDevice::initActionStates OK"
}

# =======================================================================

::itcl::body SequenceDevice::loadStateFromDatabaseString {} {
puts "SequenceDevice::loadStateFromDatabaseString"

catch {
variable ::nScripts::sequenceDeviceState
variable ::nScripts::cassette_list
puts "sequenceDeviceState=$sequenceDeviceState"
set m_cassetteInfo $sequenceDeviceState
if {[info exists cassette_list]} {
    set local_copy [lindex $cassette_list 0]
    set m_cassetteInfo [lreplace $m_cassetteInfo 2 2 $local_copy]
    saveStateToDatabaseString
}
} error

puts "SequenceDevice::loadStateFromDatabaseString done $error"
}

# =======================================================================

::itcl::body SequenceDevice::saveStateToDatabaseString {} {
puts "SequenceDevice::saveStateToDatabaseString"
variable ::nScripts::sequenceDeviceState
set sequenceDeviceState $m_cassetteInfo
puts "sequenceDeviceState=$sequenceDeviceState"
puts "SequenceDevice::saveStateToDatabaseString OK"
}

# =======================================================================
# =======================================================================

::itcl::body SequenceDevice::stop { args } {
variable ::nScripts::screening_msg


puts "SequenceDevice::stop $args"
# call this method with: gtos_start_operation sequenceSetConfig setConfig stop args
set m_keepRunning 0

if {$m_isRunning} {
    set screening_msg "stopping"
}
return [list setConfig stop OK]
}

# =======================================================================

::itcl::body SequenceDevice::dismount { args } {
puts "SequenceDevice::dismount $args"
# call this method with: gtos_start_operation sequenceSetConfig setConfig dismount args
set m_dismountRequested 1
set m_keepRunning 0
if { $m_isRunning==1 } {
    # dismount will be done in run {}
    return [list setConfig dismount OK]
}
#run
#log_note "starting dismount operation"
set op_h [start_waitable_operation sequence dismount]
set result [wait_for_operation_to_finish $op_h]
#log_note "result: $result"
return [list setConfig dismount OK]
}

# =======================================================================

::itcl::body SequenceDevice::run {} {
variable ::nScripts::screening_msg

puts "SequenceDevice::run"

if {$m_isRunning} {
    puts "PANIC: more than one start messages"
    set screening_msg "error: already running"
    log_severe "PANIC: more than one start messages"
    return "PANIC: more than one start messages"
}

puts "Checking motor moving..."
waitForMotorsForCollect
if [catch {block_all_motors;unblock_all_motors} errMsg] {
    puts "MUST wait all motors stop moving to start screening"
    log_error "MUST wait all motors stop moving to start screening"
    set screening_msg "error: motor still moving"
    return "MUST wait all motors stop moving to start screening"
}

puts "lock sil"
set index [lindex $m_cassetteInfo 1]
if [catch "lockSil $m_lastUserName $m_lastSessionID $index" errMsg] {
    puts "lock sil failed: $errMsg"
}

set m_isRunning 1
set m_lockNextCrystal 0

set result ""
if {[catch run_internal result]} {
    log_error screening run failed: $result
}
puts "unlock sil"
if [catch "unlockAllSil $m_lastUserName $m_lastSessionID" errMsg] {
    puts "unlock sil failed: $errMsg"
}
    
set m_isRunning 0
updateScreeningActionListString

return $result
}
::itcl::body SequenceDevice::run_internal {} {

if {![syncWithRobot] && $m_useRobot} {
    puts "not sync with robot"
    set screening_msg "error: not synched with robot"
    log_error "screening: not synchronized with robot, abort"
    set m_isRunning 0
    return -code error "not synchronized with robot, abort"
}
#want to make dismount available even setup is wrong
if { $m_dismountRequested==1 } {
    updateScreeningActionListString
    set m_lockNextCrystal 1
    doDismount
    set m_lockNextCrystal 0
    setStrategyFileName disMnted
    puts "SequenceDevice::run OK"
    return
}

if {![actionParametersOK m_actionListParameters 0]} {
    puts "parameters bad"
    log_error "screening: bad parameters"
    set m_isRunning 0
    set screening_msg "error: action parameter wrong"
    return -code error "bad action parameters"
}


if {![crystalSelectionOK]} {
    puts "crystal selection bad"
    log_error "screening aborted: bad crystal selection, select at least one crystal"
    set screening_msg "error: crystal selection"
    set m_isRunning 0
    return -code error "bad crystal selection, abort"
}

if {![actionSelectionOK]} {
    puts "action selection bad"
    set screening_msg "error: action selection"
    set m_isRunning 0
    return -code error "bad action selection: abort"
}

################# check directory #####################


impDirectoryWritable $m_lastUserName $m_lastSessionID $m_directory

set m_dismountRequested 0

set m_isRunning 1
updateCrystalSelectionListString
updateCrystalStatusString 

spinMsgLoop

############## user log ###########
set index [lindex $m_cassetteInfo 1]
set cassetteList [lindex $m_cassetteInfo 2]
set cassette [lindex $cassetteList $index]
user_log_note screening "========$m_lastUserName start ${m_directory}========="
if {$cassette != "undefined"} {
    user_log_note screening "cassette: $cassette"
}

user_log_system_status screening

# here is the loop that performs all the selected actions
set m_numLoopCenteringError 0
while { $m_keepRunning==1 } {
    set m_currentAction [getNextAction $m_nextAction]
    if { $m_currentAction<0 } {
        ########### all done #############
        set m_nextAction 0
        set screening_msg "All done"
        break
    }
    set m_nextAction [getNextAction [expr $m_currentAction + 1]]
    updateScreeningActionListString

    if { [catch "runAction $m_currentAction" error] } {
        puts "ERROR in SequenceDevice::runAction $m_currentAction: $error"
        log_error "Screening $m_currentAction $error"

        #### user log ##
        set action [lindex $m_actionListParameters $m_currentAction]
        set actionClass [lindex $action 0]
        user_log_error screening "[getCrystalNameForLog] $actionClass $error"

        set m_keepRunning 0
    }
    spinMsgLoop
}

if { $m_dismountRequested==1 } {
    set m_lockNextCrystal 1
    doDismount
    set m_lockNextCrystal 0
    setStrategyFileName disMnted
    puts "SequenceDevice::run OK"
    ##### doDismount will update the strings, so we can return here
    user_log_note  screening "=================all done================"
    return
}
set m_isRunning 0
set m_currentAction -1
set m_nextAction [getNextAction $m_nextAction]

updateScreeningActionListString
updateCrystalSelectionListString

updateCrystalStatusString 

puts "SequenceDevice::run OK"
user_log_note  screening "=================stopped================"

return 
}

# =======================================================================

::itcl::body SequenceDevice::runAction { index} {
puts "==========="
puts "SequenceDevice::runAction $index"
set action [lindex $m_actionListParameters $index]
puts "action=$action"
set actionClass [lindex $action 0]
set params [lindex $action 1]

spinMsgLoop

if {!$m_skipThisSample} {
    switch -exact -- $actionClass {
        MountNextCrystal {
            set m_lockNextCrystal 1
            eval doMountNextCrystal $params
            set m_lockNextCrystal 0
            clearImages
            setStrategyFileName disMnted
        }
        Pause { doPause }
        OptimizeTable { doOptimizeTable }
        LoopAlignment { doLoopAlignment }
        VideoSnapshot { eval doVideoSnapshot $params }
        CollectImage { eval doCollectImage $params }
        ExcitationScan { eval doExcitation $params }
        Rotate { eval doRotate $params }
        test { sleep 5000 }
        default { puts "ERROR SequenceDevice::runAction actionClass $actionClass not supported" }
    }
} else {
    switch -exact -- $actionClass {
        MountNextCrystal {
            set m_lockNextCrystal 1
            eval doMountNextCrystal $params
            set m_lockNextCrystal 0
            clearImages
            setStrategyFileName disMnted
        }
        Pause { doPause }
        OptimizeTable -
        LoopAlignment -
        VideoSnapshot -
        CollectImage -
        ExcitationScan -
        Rotate { log_warning "skipped $actionClass for not mounted sample [getCurrentPortID]" }
        test { sleep 5000 }
        default { puts "ERROR SequenceDevice::runAction actionClass $actionClass not supported" }
    }
}
return
}

# =======================================================================

::itcl::body SequenceDevice::spinMsgLoop {} {
# we have to give other operations a chance to receive new config information
# I couldn't find a tcl function that does this
# so here is my ugly version of it:
puts "SequenceDevice::spinMsgLoop"

global spinMsgLoopFlag
set spinMsgLoopFlag 0
after idle {set spinMsgLoopFlag 1}
#after 500 {set spinMsgLoopFlag 1}
vwait spinMsgLoopFlag

puts "SequenceDevice::spinMsgLoop OK"

}


# =======================================================================

::itcl::body SequenceDevice::sleep { msec} {
# non blocking wait (give other operations a chance to receive new config information)
# I couldn't find a tcl function that does this
# so here is my ugly version of it:
puts "SequenceDevice::sleep"

global sleepFlag
set sleepFlag 0
after $msec {set sleepFlag 1}
vwait sleepFlag

puts "SequenceDevice::sleep OK"

}

# =======================================================================

::itcl::body SequenceDevice::getNextAction { current} {
puts "SequenceDevice::getNextAction $current"

if {![actionSelectionOK]} {
    if {$m_currentCrystal < 0} {
        return 0
    }
    return "-1"
}
set n [llength $m_actionListStates]

if {$current < 0} {
    set $current 0
}

for {set i $current} {$i<$n} {incr i} {
    set state [lindex $m_actionListStates $i]
    if { $state==1 } {
        puts "nextAction=$i"
        return $i
    }
}
for {set i 0} {$i<$current} {incr i} {
    set state [lindex $m_actionListStates $i]
    if { $state==1 } {
        puts "nextAction=$i"
        return $i
    }
}
return "-1"
}

# =======================================================================

::itcl::body SequenceDevice::getNextCrystal { current} {
puts "SequenceDevice::getNextCrystal $current"

if {![crystalSelectionOK]} {
    return "-1"
}

if { $current < 0 } {
    set current 0
}
set n [llength $m_crystalListStates]
if { $current >= $n } {
    set current 0
}
for {set i $current} {$i<$n} {incr i} {
    if { $i==$m_currentCrystal } {
        continue
    }
    set state [lindex $m_crystalListStates $i]
    if { $state==1 } {
        puts "nextCrystal=$i"
        return $i
    }
}
for {set i 0} {$i<$current} {incr i} {
    if { $i==$m_currentCrystal } {
        continue
    }
    set state [lindex $m_crystalListStates $i]
    if { $state==1 } {
        puts "nextCrystal=$i"
        return $i
    }
}
puts "nextCrystal=-1"
return "-1"
}

# =======================================================================

::itcl::body SequenceDevice::getCrystalName  {} {
    puts "SequenceDevice::getCrystalName"

    if {$m_manualMode} {
        return $m_currentCassette$m_currentColumn$m_currentRow
    }

    if {$m_currentCrystal < 0} {
        return NotMounted
    }

    set crystalName [lindex $m_crystalIDList $m_currentCrystal]

    if {[string equal -nocase $crystalName "null"]} {
        set crystalName [lindex $m_crystalPortList $m_currentCrystal]
    }

    if { [string length $crystalName]<=0 } {
        if { $m_currentCrystal<0 } {
            set crystalName NotMounted
        } else {
            set crystalName crystal${m_currentCrystal}
        }
    }

    return $crystalName
}

#### this will always has port name in it
::itcl::body SequenceDevice::getCrystalNameForLog  {} {
    return $m_currentCassette$m_currentColumn$m_currentRow
}


# =======================================================================

::itcl::body SequenceDevice::getImgFileName { nameTag fileCounter } {
puts "SequenceDevice::getImgFileName $nameTag $fileCounter"

set crystalName [getCrystalName]

set counter [format "%03d" $fileCounter]

if { [string length $nameTag]<=0 || $nameTag=="\"\"" || $nameTag=="{}" } {
    set fname "${crystalName}_${counter}"
} else {
    set fname "${crystalName}_${nameTag}_${counter}"
}
puts "fileName=$fname"
return $fname
}

::itcl::body SequenceDevice::getImgFileExt { } {
    return [getDetectorFileExt $m_detectorMode]
}

# =======================================================================

::itcl::body SequenceDevice::getFileCounter { subdir fileExtension } {
puts "SequenceDevice::getFileCounter $subdir $fileExtension"

set counter 0

set arr [array get a_fileCounterInfo]
puts "a_fileCounterInfo=$arr"

set crystalName [getCrystalName]

if { [info exists a_fileCounterInfo(dir_$fileExtension)]
    && [info exists a_fileCounterInfo(subdir_$fileExtension)]
    && [info exists a_fileCounterInfo(crystalName_$fileExtension)]
    &&    $a_fileCounterInfo(dir_$fileExtension)==$m_directory
    &&    $a_fileCounterInfo(subdir_$fileExtension)==$subdir
    &&    $a_fileCounterInfo(crystalName_$fileExtension)==$crystalName
    } {
    catch {set counter $a_fileCounterInfo($fileExtension)}
    puts "oldcounter=$counter"
    if { $counter>0 } {
        incr counter
        set a_fileCounterInfo($fileExtension) $counter
        puts "newcounter=$counter"
        return $counter
    }
} 
# new crystal -> reset file counters
set a_fileCounterInfo(dir_$fileExtension) 0
set a_fileCounterInfo(subdir_$fileExtension) 0
set a_fileCounterInfo(crystalName_$fileExtension) 0
set a_fileCounterInfo($fileExtension) 0
# make sure that the directory exists
set path [file join $m_directory $subdir]
set counter [impDirectoryWritable $m_lastUserName $m_lastSessionID $path \
$crystalName $fileExtension]

set a_fileCounterInfo(dir_$fileExtension) $m_directory
set a_fileCounterInfo(subdir_$fileExtension) $subdir
set a_fileCounterInfo(crystalName_$fileExtension) $crystalName
set a_fileCounterInfo($fileExtension) $counter

puts "counter=$counter"
return $counter
}
# =======================================================================

::itcl::body SequenceDevice::getUserName {} {
puts "SequenceDevice::getUserName"

global gClient    
    #find out the operation handle
    set operationHandle [lindex [get_operation_info] 1]
    #find out the client id that started this operation
    set clientId [expr int($operationHandle)]
    #get the name of the user that started this operation
    set userName $gClient($clientId) 
puts "userName= $userName"
return $userName
}

# ===================================================

::itcl::body SequenceDevice::loadCrystalList { } {
    variable ::nScripts::scn_crystal_msg

    if {$m_afterID != ""} {
        log_warning cancel pending retry $m_afterID
        after cancel $m_afterID
        set m_afterID ""
    }

    #### m_cassetteInfo may changed by other messages
    puts "SequenceDevice::loadCrystalList"
    puts "cassetteinfo: $m_cassetteInfo"

    set user [lindex $m_cassetteInfo 0]
    set index [lindex $m_cassetteInfo 1]
    set cassetteList [lindex $m_cassetteInfo 2]
    set cassette [lindex $cassetteList $index]

    if {[catch {
        set data [string map {\n { }} [getSpreadsheetFromWeb $m_beamlineName $user $m_lastSessionID $index $cassetteList]]
    } err_msg]} {
        log_error "$err_msg"
        set data {}
    }
    if {[llength $data] > 3} {
        if {$m_spreadsheetStatus < 0} {
            log_note Success in getting spreadsheet
        }
        set m_spreadsheetStatus 1
    } else {
        set m_spreadsheetStatus -1;#mark in retrying
        log_warning get spreadsheet failed.  will retry after 10 second
        set m_afterID [after 10000 "$this retryLoadingSpreadsheet"]
    }
    #log_note "spreadsheet: $data"
    refreshWholeSpreadsheet $data
}
::itcl::body SequenceDevice::handleSpreadsheetUpdateEvent { args } {
    log_note "spreadsheet update called"
    if { $m_isInitialized==0 } {
        log_warning postpone spreadsheet update to initializaion
        return
    }

    if {![string is integer -strict $m_SILID]} {
        log_error old spreadsheet, skip update
        return
    }

    if {$m_SILID < 0} {
        log_error no spreadsheet has been loaded yet, skip update
        return
    }

    if {$m_spreadsheetStatus <= 0} {
        log_error skip update while retrying get spreadsheet in process
        return
    }
    
    if {![info exists m_SILEventID]} {
        set eventID 0
    } else {
        log_note current event id $m_SILEventID
        set eventID [expr $m_SILEventID + 1]
    }

    set data [getSpreadsheetChangesSince $m_lastUserName $m_lastSessionID $m_SILID $eventID]
    puts "row update data: $data"
    set silID [lindex $data 0]
    set eventID [lindex $data 1]
    set cmd [lindex $data 2]
    if {$silID == $m_SILID && $eventID <= $m_SILEventID} {
        puts "no change"
        return
    }
    if {$silID != $m_SILID} {
        puts "silid changed from $m_SILID to $silID"
        if {$cmd != "load"} {
            puts "but command != load, skip"
            return
        }
    }
    if {$cmd == "load"} {
        refreshWholeSpreadsheet $data
    } else {
        set rowData [lrange $data 3 end]
        updateRows $rowData
        set m_SILEventID $eventID
        log_note SIL $m_SILID $m_SILEventID
    }
}
::itcl::body SequenceDevice::refreshWholeSpreadsheet { data } {
    variable ::nScripts::sil_id
    variable ::nScripts::robot_cassette

    set index [lindex $m_cassetteInfo 1]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]

    set m_currentCassetteStatus $cassette_status
    set first [lindex $data 0]
    puts "first: $first"
    if {[llength $first] == 1} {
        puts "new SIL service"
        ##### new service
        set m_SILID $first
        set m_SILEventID [lindex $data 1]
        set cmd [lindex $data 2]
        set header [lindex $data 3]
        set crystalList [lrange $data 4 end]
        puts "SIL ID: $m_SILID Event ID: $m_SILEventID"
        log_note SIL $m_SILID $m_SILEventID
    } else {
        #### old service, using default header
        puts "old use default header"
        set m_SILID "old"
        set header $m_defaultHeader
        set crystalList $data

        #####send note to client
        set contents_to_send [lindex $crystalList 0]
        log_note SIL $m_SILID $contents_to_send
    }
    
    if {[string is integer -strict $m_SILID]} {
        if {$sil_id != $m_SILID} {
            puts "set sil_id to $m_SILID"
            set sil_id $m_SILID
        }
    } else {
        ##### set sil_id to 0 so impDHS will not poll
        if {$sil_id != 0} {
            set sil_id 0
        }
    }

    if {$m_currentHeader != $header} {
        set foundPort 0
        set m_currentHeaderNameOnly ""
        foreach column $header {
            set name [lindex $column 0]
            if {[string equal -nocase $name "Port"]} {
                set foundPort 1
            }
            lappend m_currentHeaderNameOnly $name
        }
        if {!$foundPort} {
            log_error "bad spreadsheet header: no Port column defined"
            return
        }
        set m_currentHeader $header
        set m_PortIndex [lsearch $m_currentHeaderNameOnly "Port"]
        set m_IDIndex   [lsearch $m_currentHeaderNameOnly "CrystalID"]
        if {$m_IDIndex < 0} {
            set m_IDIndex $m_PortIndex
        }
        set m_DirectoryIndex [lsearch $m_currentHeaderNameOnly "Directory"]
        set m_SelectedIndex [lsearch $m_currentHeaderNameOnly "Selected"]
        puts "index: port $m_PortIndex ID $m_IDIndex dir $m_DirectoryIndex selected: $m_SelectedIndex"
    }

    # extract from $data the lists m_crystalPortList, m_crystalIDList, m_crystalDirList, m_crystalListStates
    set crystalPortList {}
    set crystalIDList {}
    set crystalDirList {}
    set crystalListStates {}
    set m_numRowParsed 0
    foreach row $crystalList {
        foreach {port id dir} [parseOneRow $row] break

        lappend crystalPortList $port
        lappend crystalIDList $id
        lappend crystalDirList $dir
        lappend crystalListStates 1

        incr m_numRowParsed
        if {$m_numRowParsed > 300} {
            log_error too many rows > 300 on the spreadsheet
            break
        }
    }

    set m_indexMap [generateIndexMap $index $m_PortIndex crystalList \
    $m_currentCassetteStatus]
    puts "indexmap: $m_indexMap"

    #########honor "Selected" column if found
    if {$m_SelectedIndex >= 0} {
        set crystalListStates {}
        for {set i 0} {$i < $m_numRowParsed} {incr i} {
            set row [lindex $crystalList $i]
            set value [lindex $row $m_SelectedIndex]
            if {!$value} {
                log_warning [lindex $crystalIDList $i]([lindex $crystalPortList $i])  deselected by spreadsheet
            }
            lappend crystalListStates $value
        }
        log_warning Checkbox reloaded from spreadsheet, please check them
    }

    set m_crystalPortList $crystalPortList
    set m_crystalIDList $crystalIDList
    set m_crystalDirList $crystalDirList
    set m_crystalListStates $crystalListStates
    checkCrystalList m_crystalListStates
    set m_nextCrystal [getNextCrystal 0]

    set m_numRowParsed [llength $crystalList]

    ######### check lists and give warnings if not unique #####
    if {![listIsUnique $crystalIDList]} {
        log_warning "crystal IDs are not unique"
        set scn_crystal_msg "warning: crystal IDs not unique"
    }
    if {![listIsUnique $crystalPortList]} {
        log_warning "crystal Ports are not unique"
        set scn_crystal_msg "warning: PORTS NOT UNIQUE!!!"
    }
    
    #update m_isSyncedWithRobot
    syncWithRobot
    updateCrystalSelectionListString

    puts "SequenceDevice::loadCrystalList OK"
    return
}
::itcl::body SequenceDevice::updateRows { data } {
    foreach row_data $data {
        set row_index [lindex $row_data 0]
        set row_contents [lindex $row_data 1]

        if {$row_index < 0 || $row_index >= $m_numRowParsed} {
            puts "row index $row_index is out of range \[0,$m_numRowParsed) for update"
            continue
        }
        foreach {port id dir} [parseOneRow $row_contents] break
        set old_port [lindex $m_crystalPortList $row_index]
        if {$old_port != $port} {
            log_error "row $row_index new port {$port} does not match old {$old_port}"
            continue
        }
        puts "updating row: $row_index new ID: $id new DIR: $dir"
        set m_crystalIDList [lreplace $m_crystalIDList $row_index $row_index $id]
        set m_crystalDirList [lreplace $m_crystalDirList $row_index $row_index $dir]
        if {$m_currentCrystal == $row_index || $m_nextCrystal == $row_index} {
            updateCrystalStatusString 
        }
    }
}

::itcl::body SequenceDevice::parseOneRow { contents } {
    set port [lindex $contents $m_PortIndex]
    set id [lindex $contents $m_IDIndex]
    if {$m_DirectoryIndex < 0} {
        set dir .
    } else {
        set dir [lindex $contents $m_DirectoryIndex]
    }
    while { [string index $dir 0]=="/" && [string length $dir]>1} {
        set dir [string range $dir 1 end]
    }
    if { $dir=="0" || $dir=="null" || $dir=="/" || [string length $dir]==0 } {
        set dir {}
    }
    set id  [TrimStringForCrystalID $id]
    set dir [TrimStringForSubDirectoryName $dir]
    return [list $port $id $dir]
}

# =======================================================================

::itcl::body SequenceDevice::setPhiZero {} {
puts "SequenceDevice::setPhiZero"

global gDevice
set m_phiZero $gDevice(gonio_phi,scaled)
puts "m_phiZero=$m_phiZero"

puts "SequenceDevice::setPhiZero OK"
}


# =======================================================================
# =======================================================================
# here are the hardware calls

# =======================================================================

::itcl::body SequenceDevice::doMountNextCrystal { {num_cycle_to_wash_ 0} } {
variable ::nScripts::screening_msg
puts "SequenceDevice::doMountNextCrystal m_currentCrystal=$m_currentCrystal m_nextCrystal=$m_nextCrystal"

set m_skipThisSample 0

#prepare to call mountCrystal
set index [lindex $m_cassetteInfo 1]
set next_cassette [lindex {0 l m r} $index]
if {$next_cassette == 0} {
    # no cassette
    if {$m_useRobot} {
        log_error "Screening mountNextCrystal wrong dewar position (No cassette)"
        set screening_msg "error: wrong cassette"
        set m_keepRunning 0
        return
    }
}

set next [getNextCrystal $m_nextCrystal]
puts "doMountNext: next=$next"

if { $next>=0 } { 
    set next_port [lindex $m_crystalPortList $next]
    if { [string length $next_port]>1 } {
        set next_column [string index $next_port 0]
        set next_row [string range $next_port 1 end]
    } else {
        set msg "ERROR SequenceDevice::doMountNextCrystal wrong next_port=$next_port"
        puts $msg
        if { $useRobotFlag!=0 } {
            log_error "Screening mountNextCrystal wrong next_port=$next_port"
            set screening_msg "error: wrong port"
            set m_keepRunning 0
            return
        }
    }
} else {
    #mark of no mount
    set next_cassette n
    set next_column N
    set next_row 0
}

moveMotorsToDesiredPosition 

#### do mount next crystal
set m_mountingCrystal $next
mountCrystal $next_cassette $next_column $next_row $num_cycle_to_wash_
set m_mountingCrystal -1

########## move pointers of current and next crystal #########
if {$m_currentCassette == $next_cassette && \
$m_currentColumn == $next_column && \
$m_currentRow == $next_row} {
    if {$m_currentCrystal >= 0} {
        # uncheck the current crystal
        set m_crystalListStates \
        [lreplace $m_crystalListStates $m_currentCrystal $m_currentCrystal 0]
    }
    set m_currentCrystal $next
} else {
    set m_currentCrystal -1
}
if { $m_currentCrystal<0 } {
    # m_currentCrystal==-1 means no crystal mounted
    puts "all crystals are unchecked"
    # stop since there are no more crystals to analyze
    # request all system resets as if a dismount was pressed
    set m_dismountRequested 1
    set m_keepRunning 0
} else {
    variable ::nScripts::sil_config
    set enableAddImage 0
    set enableAnalyzeImage 0
    if {[info exists sil_config]} {
        puts "sil_config: {$sil_config} ll: [llength $sil_config]"
        set add_image       [lindex $sil_config 0]
        set analyze_image   [lindex $sil_config 1]
        set autoindex       [lindex $sil_config 2]

        if {$add_image == "1"} {
            set enableAddImage 1
        } 
        if {$analyze_image == "1"} {
            set enableAnalyzeImage 1
        }
    } else {
        puts "sil_config not exists"
    }
    if {[string is integer -strict $m_SILID] && \
    ($enableAddImage || $enableAnalyzeImage)} {
        if {[catch {
            #### clear all fields
            clearCrystalResults $m_lastUserName $m_lastSessionID \
            $m_SILID $m_currentCrystal
        } errmsg]} {
            log_error clearCrystalImages $errmsg
        }
    }
}

set m_nextCrystal [getNextCrystal [expr $m_currentCrystal + 1]]

updateCrystalSelectionListString

######################## check sync with robot again #############
if {!$m_useRobot}  {
    syncWithRobot
} else {
    if {![syncWithRobot $TRY_SYNC_WITH_ROBOT]}  {
        set m_keepRunning 0
        set screening_msg "error: lost sync with robot"
        log_error "screening aborted: lost sync with robot"
    }
}

if {!$m_useRobot} {
    set m_keepRunning 0
    if {$m_currentCrystal < 0} {
        set screening_msg "manual dismount"
        log_warning "If a sample is mounted, dismount it now"
    } else {
        set cur_port [lindex $m_crystalIDList $m_currentCrystal]
        set screening_msg "manual mount $cur_port"
        log_warning "Please make sure $cur_port is mounted"
    }
}
puts "SequenceDevice::doMountNextCrystal OK"
}

::itcl::body SequenceDevice::mountCrystal { cassette column row wash_cycle_ } {
variable ::nScripts::screening_msg

puts "mountCrystal $cassette $column $row $wash_cycle_"

set useRobotFlag $m_useRobot

if {$m_currentCassette != "n" && \
$m_currentColumn != "N" && \
$m_currentRow != 0} {
    puts "current port OK"
    set currentPortOK 1
} else {
    set currentPortOK 0
}
if {$cassette != "n" && \
$column != "N" && \
$row != 0} {
    puts "next port OK"
    set nextPortOK 1
} else {
    set nextPortOK 0
}

# decide if we have to call mountNextCrystal, dismountCrystal or mountCrystal
if { $currentPortOK && $nextPortOK } {

    set screening_msg "dismount $m_currentCassette$m_currentColumn$m_currentRow mount $cassette$column$row"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "doMountNextCrystal() start_operation ISampleMountingDevice mountNextCrystal $m_currentCassette $m_currentColumn $m_currentRow $cassette $column $row"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start mountNextCrystal $m_currentCassette $m_currentRow $m_currentColumn $cassette $row $column $wash_cycle_
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 5 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        set mt_status [lindex $errorText 4]

        ######### check wether the job is partially done ######
        if {$mt_status == "normal"} {
            set m_currentCassette $cassette
            set m_currentColumn $column
            set m_currentRow $row
            ####check skipped empty port
            if {[lindex $errorText 5] == "n" && \
            [lindex $errorText 6] == "0" && \
            [lindex $errorText 7] == "N"} {
                set m_skipThisSample 1
                set screening_msg "skip empty port"
            } else {
                set screening_msg "$cassette$column$row mounted"
            }
        } else {
            set m_currentCassette n
            set m_currentColumn N
            set m_currentRow 0
            set screening_msg "mount failed"
        }
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
        set m_currentCassette $cassette
        set m_currentColumn $column
        set m_currentRow $row
    }
    spinMsgLoop
} elseif { $currentPortOK && !$nextPortOK} {
    # there is no next crystal -> dismount only
    puts "ROBOT dismountCrystal $m_currentCassette$m_currentColumn$m_currentRow"
    set screening_msg "dismount $m_currentCassette$m_currentColumn$m_currentRow"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "call  ISampleMountingDevice_start dismountCrystal $m_currentCassette $m_currentRow $m_currentColumn"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start dismountCrystal $m_currentCassette $m_currentRow $m_currentColumn
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 4 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        set screening_msg "$m_currentCassette$m_currentColumn$m_currentRow dismounted"
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
    }
    set m_currentCassette n
    set m_currentColumn N
    set m_currentRow 0
    spinMsgLoop
} elseif {!$currentPortOK && $nextPortOK} {
    # there is no current crystal -> mount only
    puts "ROBOT mountCrystal $cassette $column $row" 
    set screening_msg "mount $cassette$column$row"
    set errorFlag 0
    set errorText ""
    if { $useRobotFlag==1 } {
        puts "call ISampleMountingDevice_start mountCrystal $cassette $row $column"
        set errorFlag [catch {
        namespace eval ::nScripts ISampleMountingDevice_start mountCrystal $cassette $row $column $wash_cycle_
        } errorText]
        set op_status [lindex $errorText 0]
        set op_result_l [llength $errorText]
        puts "SequenceDevice::doMountNextCrystal() done $errorText"
        if { $errorFlag || $op_status != "normal" || $op_result_l < 4 } {
            puts "ERROR SequenceDevice::doMountNextCrystal() $errorText"
            log_error "Screening mountNextCrystal $errorText"
            set screening_msg "error: $errorText"
            set m_keepRunning 0
            syncWithRobot $TRY_SYNC_WITH_ROBOT
            return -code error $errorText
        }
        if {[lindex $errorText 1] == "n" && \
        [lindex $errorText 2] == "0" && \
        [lindex $errorText 3] == "N"} {
            set m_skipThisSample 1
            set screening_msg "skip empty port"
        } else {
            set screening_msg "$cassette$column$row mounted"
        }
        checkIfRobotResetIsRequired
    } else {
        puts "ROBOT simulation"
        sleep 800
    }
    set m_currentCassette $cassette
    set m_currentColumn $column
    set m_currentRow $row
    spinMsgLoop
} else {
    puts "bad situation: current: $m_currentCassette $m_currentColumn $m_currentRow"
    puts "currentCrystal=$m_currentCrystal next=$m_nextCrystal"
}

setPhiZero

if {!$m_useRobot && $m_manualMode} {
    if {$m_currentCassette == "n" || \
    $m_currentColumn == "N" || \
    $m_currentRow == 0} {
        set screening_msg "manual dismount"
        log_warning "If a sample is mounted, dismount it now"
    } else {
        set screening_msg "manual mount $cassette$column$row"
        log_warning "Please make sure $cassette$column$row is mounted"
    }
}
return
}

# =======================================================================

::itcl::body SequenceDevice::doDismount {} {
puts "SequenceDevice::doDismount"

#tell clients that we are running dismount
set m_currentAction -1
set m_actionListStates [lreplace $m_actionListStates 0 0 1]
set m_nextAction 0
updateScreeningActionListString

set m_dismountRequested 0

mountCrystal n N 0 0

set m_isRunning 0
updateAfterDismount
return
}

# =======================================================================

::itcl::body SequenceDevice::doPause {} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doPause"
set m_keepRunning 0
}

# =======================================================================

::itcl::body SequenceDevice::doOptimizeTable {} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doOptimizeTable"

variable ::nScripts::optimized_energy

if {![info exists optimized_energy]} {
    log_warning skip optimizing table, no optimized_energy motor
    return
}

set screening_msg "optimizing table"
move optimized_energy to $optimized_energy

wait_for_devices optimized_energy
set screening_msg "table optimized"

puts "SequenceDevice::doOptimizeTable OK"
}

# =======================================================================

::itcl::body SequenceDevice::doLoopAlignment {} {
variable ::nScripts::screening_msg
variable ::nScripts::lc_error_threshold
set screening_msg "loop alignment"
puts "SequenceDevice::doLoopAlignment"

    waitForMotorsForVideo

# call scripted operation "centerLoop"
if {[catch {namespace eval ::nScripts centerLoop_start} errorMsg]} {
    user_log_error screening "[getCrystalNameForLog] loopCenter $errorMsg"

    #### if stop is selected, just return error
    set stop_selected [expr [lindex $m_actionListStates 2] ? 1 : 0]
    if {$stop_selected} {
        set screening_msg "error: $errorMsg"
        return -code error $errorMsg
    }

    #### decide whether stop screening
    #### if not stop, decide whether skip collect images.
    incr m_numLoopCenteringError

    ##### get threshold ###
    set threshold 2
    set skip_all 1
    if {[info exists lc_error_threshold]} {
        set thd_set [lindex $lc_error_threshold 0]
        if {[string is integer -strict $thd_set] && $thd_set > 0} {
            set threshold $thd_set
        }

        set skip_set [lindex $lc_error_threshold 1]
        if {[string is integer -strict $skip_set]} {
            set skip_all $skip_set
        }
    }
    ###### check ######
    if {$m_numLoopCenteringError >= $threshold} {
        set screening_msg "error: $errorMsg"
        return -code error $errorMsg
    }

    set warning_contents "loopCenter_$errorMsg"

    ######## skip ######
    if {$skip_all} {
        #### take a picture and skip all other actions
        doVideoSnapshot 0 failed
        set m_skipThisSample 1
        set screening_msg "warning: skip this sample"

        append warning_contents " skipped diffraction image"
    }

    ######## append to system warnings 
    if {[string is integer -strict $m_SILID]} {
        if {[catch {
            regsub -all {[[:blank:]]} $warning_contents _ warning_contents
            set data [list SystemWarning $warning_contents]
            set data [eval http::formatQuery $data]

            editSpreadsheet $m_lastUserName $m_lastSessionID \
            $m_SILID $m_currentCrystal $data
        } secondErr]} {
            log_warning failed to append warning message to spreadsheet
        }
    }
} else {
    ##### this number is for consecutive
    set m_numLoopCenteringError 0
set screening_msg "loop alignment OK"
}

setPhiZero

puts "SequenceDevice::doLoopAlignment OK"
}

# =======================================================================
# generate "-x 0.5 -y 0.5 -w 0.2 -h 0.1"
::itcl::body SequenceDevice::drawInfoOnVideoSnapshot { } {
    global gMotorBeamWidth
    global gMotorBeamHeight

    variable ::nScripts::$gMotorBeamWidth
    variable ::nScripts::$gMotorBeamHeight

    set sampleImageWidth  [::nScripts::getSampleCameraConstant sampleImageWidth]
    set sampleImageHeight [::nScripts::getSampleCameraConstant sampleImageHeight]
    set zoomMaxXAxis      [::nScripts::getSampleCameraConstant zoomMaxXAxis]
    set zoomMaxYAxis      [::nScripts::getSampleCameraConstant zoomMaxYAxis]

    set result "-x $zoomMaxXAxis -y $zoomMaxYAxis"
    set umPerPixelH 1
    set umPerPixelV 1
    ::nScripts::getSampleScaleFactor umPerPixelH umPerPixelV NULL

    set w [expr 1000.0 * [set $gMotorBeamWidth] / ($umPerPixelH * $sampleImageWidth)]
    set h [expr 1000.0 * [set $gMotorBeamHeight] / ($umPerPixelV * $sampleImageHeight)]

    append result " -w $w -h $h"

    log_note scale: $result
    return $result
}


# =======================================================================

::itcl::body SequenceDevice::doVideoSnapshot {zoom nameTag} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doVideoSnapshot zoom=$zoom nameTag=$nameTag"

    waitForMotorsForVideo

if {!$m_manualMode} {
    set subdir [lindex $m_crystalDirList $m_currentCrystal]
} else {
    set subdir .
}
set fileCounter [getFileCounter $subdir "jpg"]
set fileName [getImgFileName $nameTag $fileCounter]
set filePath [file join $m_directory $subdir "${fileName}.jpg"]

set screening_msg "snapshot $fileName"

	if {[motor_exists camera_zoom]} {
    	move camera_zoom to $zoom
    	wait_for_devices camera_zoom
	}

    set saveRawJPEG 1
    if {$ADD_BEAM_INFO_TO_JPEG} {
        set mySID $m_lastSessionID
        if {[string equal -length 7 $mySID "PRIVATE"]} {
            set mySID [string range $mySID 7 end]
        }

        set urlSOURCE [::config getSnapshotUrl]

        set urlTARGET "http://[::config getImpDhsImpHost]"
        append urlTARGET ":[::config getImpDhsImpPort]"
        append urlTARGET "/writeFile?impUser=$m_lastUserName"
        append urlTARGET "&impSessionID=$mySID"
        append urlTARGET "&impFilePath=$filePath"
        append urlTARGET "&impWriteBinary=true"
        append urlTARGET "&impBackupExist=true"
        append urlTARGET "&impAppend=false"

        #set cmd "java url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTARGET -debug"
        set cmd "java -Djava.awt.headless=true url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTARGET"
        #log_note cmd: $cmd
        if { [catch {
            set mm [eval exec $cmd]
            log_note exec result: $mm
            user_log_note screening "[getCrystalNameForLog] videosnap $filePath"
            set saveRawJPEG 0
        } errMsg]} {
            #set status "ERROR $errMsg"
            #set ncode 0
            #set code_msg "get url failed for snapshot"
            user_log_error screening \
            "videoSnapshot with beam info error: $errMsg"

            log_error screening "videoSnapshot with beam info error: $errMsg"
        }

    }

    if {$saveRawJPEG} {
        set url [::config getSnapshotUrl]
        puts "$url"
        if { [catch {
            set token [http::geturl $url -timeout 12000]
        } err] } {
            set status "ERROR $err $url"
            set ncode 0
            set code_msg "get url failed for snapshot"
        } else {
            upvar #0 $token state
            set status $state(status)
            set ncode [http::ncode $token]
            set code_msg [http::code $token]
            set result [http::data $token]
            http::cleanup $token

            if {[catch {
                impWriteFileWithBackup $m_lastUserName $m_lastSessionID $filePath $result
                user_log_note screening \
                "[getCrystalNameForLog] videosnap $filePath"
            } errMsg]} {
                log_error "failed to save video snapshot to $filePath: $errMsg"
                set screening_msg "error: failed to save snapshot"
            }
        }
        if { $status!="ok" || $ncode != 200 } {
            set msg \
            "ERROR SequenceDevice::doVideoSnapshot http::geturl status=$status"
            puts $msg
            set screening_msg "error: snapshot failed"
            log_error "Screening videoSnapshot Web error: $status $code_msg"
            user_log_error screening \
            "videoSnapshot Web error: $status $code_msg"
        }
    }

    ###save jpeg filename to be sent to SIL server later
switch -exact -- $m_currentAction {
    1 {
        ###### this is called in loopcenter when it is failed.
        ###### after this the sample will be dismount,
        ###### so no action needed.
    }
    3 {
        set m_jpeg1 $filePath
    }
    6 {
        set m_jpeg2 $filePath
    }
    10 {
        set m_jpeg3 $filePath
    }
    default {
        log_severe NEED TO ADJUST CODE if screening parameter list changes
    }
}

sendResultUpdate videoSnapshot $subdir "${fileName}.jpg"

puts "SequenceDevice::doVideoSnapshot OK $filePath "
set screening_msg "snapshot OK"
}

# =======================================================================

::itcl::body SequenceDevice::doCollectImage { deltaPhi time nImages nameTag} {
variable ::nScripts::screening_msg
puts "SequenceDevice::doCollectImage $deltaPhi $time $nImages $nameTag"

global gWaitForGoodBeamMsg

variable ::nScripts::gonio_phi
variable ::nScripts::runs

#### string sil_config list [addImage analyzeImage autoindex]
variable ::nScripts::sil_config

waitForMotorsForCollect

moveMotorsToDesiredPosition 

set enableAddImage 0
set enableAnalyzeImage 0
set enableAutoindex 0
if {[info exists sil_config]} {
    puts "sil_config: {$sil_config} ll: [llength $sil_config]"
    set add_image       [lindex $sil_config 0]
    set analyze_image   [lindex $sil_config 1]
    set autoindex       [lindex $sil_config 2]

    if {$add_image == "1"} {
        set enableAddImage 1
    } 
    if {$analyze_image == "1"} {
        set enableAnalyzeImage 1
    }
    if {$autoindex == "1"} {
        set enableAutoindex 1
    }
} else {
    puts "sil_config not exists"
}

switch -exact -- $m_currentAction {
    4 {
        set group 1
    }
    7 {
        set group 2
    }
    11 {
        set group 3
    }
    default {
        set group -1
        log_severe NEED TO ADJUST CODE if screening parameter list changes
    }
}
if {$group > 0 && $group < 4 && \
[string is integer -strict $m_SILID] && \
($enableAddImage || $enableAnalyzeImage)} {
    if {[catch {
        #### only clear this image group
        clearCrystalImages $m_lastUserName $m_lastSessionID \
        $m_SILID $m_currentCrystal $group
    } errmsg]} {
        log_error clearCrystalImages $errmsg
    }
}

set runNumber 16
#set userName "gwolf"
set userName [getUserName]
set axisMotor gonio_phi

if {!$m_manualMode} {
    set subdir [lindex $m_crystalDirList $m_currentCrystal]
} else {
    set subdir .
}
set directory [file join $m_directory $subdir]
set exposureTime $time
set delta $deltaPhi
set modeIndex $m_detectorMode
set useDose [lindex $runs 2]
set reuseDark 0

#### may not be necessary
set m_imgFileExtension [getImgFileExt]

set nFrames $nImages

    #loop over all remaining frames until this run is complete
    if { [catch {
        for { set iFrame 0} { $iFrame<$nFrames } { incr iFrame } {
            spinMsgLoop

            #Stop data collection now if we have been paused
            if { $m_keepRunning==0 } {
                puts "WARNING SequenceDevice::doCollectImage was stoped"
                return
            }

            #get the motor positions for this frame

            # get file name for the next image
            set fileCounter [getFileCounter $subdir $m_imgFileExtension]
            set filename [getImgFileName $nameTag $fileCounter]
            
            # wait for the detector to get into position if it was moving
            wait_for_motor_if_moving detector_z
            
            set gWaitForGoodBeamMsg screening_msg
            #If we lost beam then wait
            if { ![::nScripts::beamGood] } { 
                ::nScripts::wait_for_good_beam
            }
            doOptimizeTable   

            #gw
            set expTime [namespace eval ::nScripts requestExposureTime_start $exposureTime $useDose]
            set gWaitForGoodBeamMsg ""
 
            set fullpath [file join $directory "${filename}.$m_imgFileExtension"]
            if {$group > 0 && $group < 4 && \
            [string is integer -strict $m_SILID] && \
            ($enableAddImage || $enableAnalyzeImage)} {
                lappend m_imageWaitingList $fullpath
            }

            set current_phi [user_log_get_motor_position gonio_phi]
            set current_energy [user_log_get_motor_position energy]

            set screening_msg "collect $filename"
            set operationHandle [start_waitable_operation collectFrame \
                                             $runNumber \
                                             $filename \
                                             $directory \
                                             $m_lastUserName \
                                             $axisMotor \
                                             shutter \
                                             $delta \
                                             $expTime \
                                             $modeIndex \
                                             0 \
                                             $reuseDark \
                                             $m_lastSessionID \
                                             ]
            
            wait_for_operation $operationHandle
            set screening_msg "collected $filename"

            user_log_note screening "[getCrystalNameForLog] collect   $fullpath $current_phi deg"

            #gw
            sendResultUpdate collectImage $subdir "${filename}.$m_imgFileExtension"

            if {[string is integer -strict $m_SILID] && ($enableAddImage || $enableAnalyzeImage)} {
                ####### add image to SIL server           
                switch -exact -- $group {
                    1 {
                        set jpgPath $m_jpeg1
                        set m_img1 $fullpath
                    }
                    2 {
                        set jpgPath $m_jpeg2
                        set m_img2 $fullpath
                    }
                    3 {
                        set jpgPath $m_jpeg3
                        set m_img3 $fullpath
                    }
                }
                if {$group > 0 && $group < 4} {
                    if {[catch {
                    addCrystalImage $m_lastUserName $m_lastSessionID $m_SILID $m_currentCrystal $group $fullpath $jpgPath
                    } errmsg]} {
                        log_error addCrystalImage $errmsg
                    }
                    if {$enableAnalyzeImage} {
                        if {[catch {
                        analyzeCrystalImage $m_lastUserName $m_lastSessionID $m_SILID $m_currentCrystal $group $fullpath $m_beamlineName [getCrystalName] 
                        } errmsg]} {
                            log_error analyzeCrystalImage $errmsg
                        }
                    }
                }
            };#if {$m_SILID != "old"}

        } ;# loop over all remaining frames until this run is complete

        spinMsgLoop
        #run is complete
        start_operation detector_stop

        if {[string is integer -strict $m_SILID] && $enableAutoindex} {
            if {[catch { doAutoindex } errmsg]} {
                log_error autoindex $errmsg
            }
        }

    } errorResult ] } {
        #handle every error that could be raised during data collection
        start_recovery_operation detector_stop
        #gw update_run $runNumber $nextFrame "paused"
        #gw return -code error $errorResult
        puts "ERROR SequenceDevice::doCollectImage $errorResult"
        log_error CollectImage $errorResult
        set screening_msg "error: $errorResult"

        #if { [lsearch $errorResult aborted] >= 0 } {
        #    return -code error $errorResult
        #}
        #return
        return -code error $errorResult
    } ;# if error exception

puts "SequenceDevice::doCollectImage OK"
}
::itcl::body SequenceDevice::doExcitation { time_ nameTag_} {
    variable ::nScripts::screening_msg
   puts "SequenceDevice::doExcitation"
   variable ::nScripts::energy

    waitForMotorsForCollect

   set userName [getUserName]
    if {!$m_manualMode} {
        set subdir [lindex $m_crystalDirList $m_currentCrystal]
    } else {
        set subdir .
    }
   set directory [file join $m_directory $subdir]

   if { [catch {
      #check if we have been paused
      if { $m_keepRunning==0 } {
         puts "WARNING SequenceDevice::doExcitation was stopped"
         return
      }

   # get file name for the next image
   set fileCounter [getFileCounter $subdir "bip"]
   set filename [getImgFileName $nameTag_ $fileCounter]

   set sessionCacheFile [file join /home $userName .bluice session]
   if {[catch {open $sessionCacheFile r} fileId] } {
      log_error "Could not open user's session ID file $sessionCacheFile"
      return -code error $fileId
   }
   set sessionId [gets $fileId]
   close $fileId
               
    set screening_msg "excitation $filename"
   set exciteId [start_waitable_operation optimalExcitation $userName $sessionId $directory $filename NA $energy $time_]
    wait_for_operation $exciteId
  
    wait_for_time 2000
    } errorResult ] } {
        set screening_msg "error: $errorResult"
        puts "ERROR SequenceDevice::doExcitationCollect $errorResult"
        return -code error $errorResult
    }
    set screening_msg "done excitation"

puts "SequenceDevice::doCollectImage OK"
}


# =======================================================================

::itcl::body SequenceDevice::doRotate { angle } {
variable ::nScripts::screening_msg
puts "SequenceDevice::doRotate $angle"

wait_for_motor_if_moving gonio_phi

set phiZero $m_phiZero
set absAngle [expr $phiZero + $angle]
puts "phiZero=$phiZero absAngle=$absAngle"

#move gonio_phi to $absAngle
set screening_msg "rotate sample"
move gonio_phi by $angle
wait_for_devices gonio_phi
set screening_msg "sample rotated"

global gDevice
set phi $gDevice(gonio_phi,scaled)
puts "phi=$phi"

puts "SequenceDevice::doRotate OK"
}

# =======================================================================

::itcl::body SequenceDevice::checkIfRobotResetIsRequired { } {
variable ::nScripts::screening_msg
puts "SequenceDevice::checkIfRobotResetIsRequired"

set oldRobotState $m_robotState

set errorFlag [catch {
    set m_robotState [namespace eval ::nScripts ISampleMountingDevice_start getRobotState]
} errorText]
puts "SequenceDevice::checkIfRobotResetIsRequired() done $errorText"
if { $errorFlag } {
    puts "ERROR SequenceDevice::checkIfRobotResetIsRequired() $errorText"
    log_error "Screening ISampleMountingDevice error: $errorText"
    set m_robotState "1"
}
if { [string length $m_robotState]>6 } {
    puts "ERROR SequenceDevice::checkIfRobotResetIsRequired() ISampleMountingDevice returned robotState=$m_robotState"
    set m_robotState "1"
}

if { $oldRobotState==$m_robotState } {
    puts "SequenceDevice::checkIfRobotResetIsRequired OK $m_robotState"
    return $m_robotState
}
#send_operation_update "setConfig robotState $m_robotState"
if { $m_robotState>0 } {
    set m_keepRunning 0
    log_error "screening aborted: robot not ready check robot status"
    set screening_msg "error: robot status"
}
puts "SequenceDevice::checkIfRobotResetIsRequired OK $m_robotState"
return $m_robotState
}


# =======================================================================

::itcl::body SequenceDevice::sendResultUpdate { operation subdir fileName } {
puts "SequenceDevice::sendResultUpdate $operation $subdir $fileName "

send_operation_update [list result $operation $subdir $fileName]
}

# =======================================================================
# =======================================================================
# =======================================================================
# =======================================================================

puts "SequenceDevice.tcl loaded successfully"

#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateCrystalSelectionListString {} {
    variable ::nScripts::crystalSelectionList
    
    set crystalSelectionList [list $m_currentCrystal $m_nextCrystal $m_crystalListStates]

    if {[string is integer -strict $m_SILID] && $m_SILID > 0} {
        set data [list attrName selected attrValues $m_crystalListStates]
        set data [eval http::formatQuery $data]
        if [catch {
            setSpreadsheetAttribute $m_lastUserName $m_lastSessionID $m_SILID $data
        } errMsg] {
            log_error save selected to spreadsheet failed: $errMsg
        }
    }
}
::itcl::body SequenceDevice::loadCrystalSelectionListString {} {
    variable ::nScripts::crystalSelectionList
    variable ::nScripts::robot_status

    set m_currentCrystal [lindex $crystalSelectionList 0]
    set m_nextCrystal [lindex $crystalSelectionList 1]
    set m_crystalListStates [lindex $crystalSelectionList 2]

    set sample_on_gonio [lindex $robot_status 15]
    if {$sample_on_gonio != ""} {
        set m_currentCassette [lindex $sample_on_gonio 0]
        set m_currentRow [lindex $sample_on_gonio 1]
        set m_currentColumn [lindex $sample_on_gonio 2]
    } else {
        set m_currentCassette n
        set m_currentRow 0
        set m_currentColumn N
    }
}
#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateScreeningActionListString {} {
    variable ::nScripts::screeningActionList
    set screeningActionList [list $m_isRunning $m_currentAction $m_nextAction $m_actionListStates]
}

#this updates the system string so that all clients can see the new state
::itcl::body SequenceDevice::updateScreeningParametersString { } {
    variable ::nScripts::screeningParameters
    if {[llength $screeningParameters] >= 5} {
        set screeningParameters [list $m_actionListParameters $m_detectorMode $m_directory $m_distance $m_beamstop]
    } else {
        set screeningParameters [list $m_actionListParameters $m_detectorMode $m_directory]
    }
}

#fields: mounted, next, robot flag
::itcl::body SequenceDevice::updateCrystalStatusString { } {
    variable ::nScripts::crystalStatus

    if { $m_currentCrystal >= 0 } {
        set cur_port [getCurrentPortID]
        set enable_dismount 1
        set cur_sub_dir [lindex $m_crystalDirList $m_currentCrystal]
    } elseif {$m_currentCassette != "n" && \
    $m_currentColumn != "N" && \
    $m_currentRow != "0"} {
        ### must be manual mode
        set cur_port $m_currentCassette$m_currentColumn$m_currentRow
        set enable_dismount 1
        set cur_sub_dir .
    } else {
        set cur_port {}
        set enable_dismount 0
        set cur_sub_dir {}
    }

    if { $m_nextCrystal < 0 } {
        set next_port {}
    } else {
        set next_port [getNextPortID]
    }
    if { $m_useRobot } {
        set robotFlag robot
    } else {
        set robotFlag manual 
    }
    set crystalStatus [list $cur_port $next_port $robotFlag $enable_dismount $cur_sub_dir $m_isSyncedWithRobot]
}
::itcl::body SequenceDevice::loadCrystalStatusString { } {
    variable ::nScripts::crystalStatus

    #log_note "string: $crystalStatus"
    
    if {[lindex $crystalStatus 2] == "robot"} {
        #log_note "set to use robot from string"
        set m_useRobot 1
    } else {
        #log_note "set to use mamual from string"
        set m_useRobot 0
    }
}
::itcl::body SequenceDevice::reset { args } {
    variable ::nScripts::collect_default
    if {[llength $collect_default] < 2} {
        set collect_parameters [list 1.0 2.0]
    } else {
        set collect_parameters [lrange $collect_default 0 1]
    }

    setConfig detectorMode [::nScripts::getDetectorDefaultModeIndex] $args
    setConfig actionListParameters [list \
    {MountNextCrystal {}} \
    {LoopAlignment {}} \
    {Pause {}} \
    {VideoSnapshot {1.0 0deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {Rotate 90} \
    {VideoSnapshot {1.0 90deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {Pause {}} \
    {Rotate -45} \
    {VideoSnapshot {1.0 45deg}} \
    "CollectImage {$collect_parameters 1 {}}" \
    {ExcitationScan {10.0 test}} \
    {Pause {}}] $args
}

#this compares current crystal with what is mounted on goniometer
::itcl::body SequenceDevice::syncWithRobot { { try_to_sync 0 } args } {
    variable ::nScripts::robot_cassette
    variable ::nScripts::robot_status
    variable ::nScripts::screening_msg
    variable ::nScripts::scn_crystal_msg

    checkInitialization

    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        set m_lastSessionID $sessionID
        puts "syncWithRobot sessionID $m_lastSessionID"
        set m_lastUserName [getUserName]

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    if {$try_to_sync == ""} {
        set try_to_sync 0
    }

    #get what's on the goniometer
    set sample_on_gonio [lindex $robot_status 15]

    ################## check cassette  ##################
    set index [lindex $m_cassetteInfo 1]
    #if not l m r  cassette, we ignore robot
    if {$index <= 0 || $index > 3} {
        if {$sample_on_gonio != ""} {
            if {$try_to_sync} {
                set screening_msg "error: not robot cassette"
                set scn_crystal_msg "error: not robot cassette"
                log_error "try to sync with robot failed, not robot cassette"
            }
            set m_isSyncedWithRobot no
            updateCrystalStatusString 
            return 0
        } else {
            if {$m_currentCrystal < 0} {
                set m_isSyncedWithRobot yes
                updateCrystalStatusString 
                return 1
            }
            if {!$try_to_sync} {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            set m_currentCrystal -1
            set m_currentCassette n
            set m_currentColumn N
            set m_currentRow 0
            set m_isSyncedWithRobot yes
            updateCrystalSelectionListString
            updateCrystalStatusString 
            set screening_msg "sync: current cleared"
            set scn_crystal_msg "sync warning: current cleared"
            log_warning "sync with robot: current crystal cleared"
            return 1
        }
    }
    #check if cassette is absent
    set cur_cassette [lindex {0 l m r} $index]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]
    if {$cassette_status == "0"} {
        if {$try_to_sync} {
            set screening_msg "error: cassette $cur_cassette absent"
            set scn_crystal_msg "error: cassette $cur_cassette absent"
            log_error "try to sync with robot failed: cassette $cur_cassette absent"
        }
        set m_isSyncedWithRobot no
        updateCrystalStatusString 
        return 0
    }

    if {$sample_on_gonio != ""} {
        set gonio_cassette [lindex $sample_on_gonio 0]
        set gonio_row [lindex $sample_on_gonio 1]
        set gonio_column [lindex $sample_on_gonio 2]
    } else {
        set gonio_cassette $cur_cassette
        set gonio_row 0
        set gonio_column N
    }
    ######### compare current crystal with sample on goniometer ####
    #gether information
    if {$m_currentCrystal >= 0} {
        #get current port ID
        set cur_port [lindex $m_crystalPortList $m_currentCrystal]
        if { [string length $cur_port]>1 } {
            set cur_column [string index $cur_port 0]
            set cur_row [string range $cur_port 1 end]
        } else {
            if {!$try_to_sync} {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            if {$sample_on_gonio == ""} {
                set port_status -
            } else {
       	        set screening_msg "error: currentt=$cur_port"
       	        set scn_crystal_msg "error: bad currentt=$cur_port"
                log_error "try to sync with robot failed: current_port=$cur_port"
                return 0
            }
        }
        set port_status [getCrystalStatus $m_currentCrystal]
    } else {
        set cur_row 0
        set cur_column N
        set port_status -
    }

    #compare
    if {$sample_on_gonio == ""} {
        #nothing on goniometer, always return 1
        if {$m_currentCrystal >= 0 && $port_status != "0"} {
            # not caused by empty port
            if { !$try_to_sync } {
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }

            #try to sync with robot: clear current sample
            set screening_msg "sync: current cleared"
            set scn_crystal_msg "sync warning: current cleared"
            log_warning "sync with robot: m_currentCrystal cleared"
        }
        set m_currentCrystal -1
        set m_currentCassette n
        set m_currentColumn N
        set m_currentRow 0
        set m_nextCrystal [getNextCrystal $m_nextCrystal]
        set m_isSyncedWithRobot yes
        updateCrystalSelectionListString
        updateCrystalStatusString 
        return 1
    } else {
        if {$cur_cassette == $gonio_cassette && $cur_row == $gonio_row && $cur_column == $gonio_column} {
            set m_isSyncedWithRobot yes
            updateCrystalStatusString 
            return 1
        } else {
            if { !$try_to_sync } { 
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0 
            }
            set m_currentCassette $gonio_cassette
            set m_currentColumn $gonio_column
            set m_currentRow $gonio_row
            #try to sync with robot: change current and next crystal
            #must have the same cassette, otherwise panic
            if {$cur_cassette != $gonio_cassette} {
                set screening_msg "error: cassettes mismatch"
                set scn_crystal_msg "error: cassettes mismatch"
                log_error "try to sync with robot failed: cassettes mismatch between selection and the sample on goniometer"
                log_error "current cassette in screening: $cur_cassette"
                log_error "cassette of sample on goniometer: $gonio_cassette"
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            #try to find whether the sample on goniometer is on the list
            set sampleIndex [getCrystalIndex $gonio_row $gonio_column]
            if {$sampleIndex < 0} {
                set screening_msg "error: sample not on the list"
                set scn_crystal_msg "error: sample not on the list"
                log_error "try to sync with robot failed: sample on goniometer is not on the crystal list"
                log_error "sample on goniometer: $sample_on_gonio"
                set m_isSyncedWithRobot no
                updateCrystalStatusString 
                return 0
            }
            #set current and next crystal according to what's on the gonio
            set old_current $m_currentCrystal
            set old_next $m_nextCrystal
            set oldCurrentID [getCurrentPortID]
            set oldNextID [getNextPortID]

            set m_currentCrystal $sampleIndex
            set m_crystalListStates [lreplace $m_crystalListStates \
            $m_currentCrystal $m_currentCrystal 1]
            set m_nextCrystal [getNextCrystal [expr $m_currentCrystal + 1]]
            set m_isSyncedWithRobot yes

            updateCrystalSelectionListString
            updateCrystalStatusString 

            #generate warning message
            set newCurrentID [getCurrentPortID]
            set newNextID [getNextPortID]

            set warning_msg "sync warning: current: $oldCurrentID => $newCurrentID"
            if {$old_next != $m_nextCrystal} {
                append warning_msg " next: $oldNextID => $newNextID"
            }
            set screening_msg $warning_msg
            set scn_crystal_msg $warning_msg
            log_warning $warning_msg
            puts "sync: current: $old_current => $m_currentCrystal next: $old_next => $m_nextCrystal"
            return 1
        }
    }
}

::itcl::body SequenceDevice::getCrystalStatus { spreadsheet_index } {
    variable ::nScripts::robot_cassette

    set portIndex [lindex $m_indexMap $spreadsheet_index]

    if {![string is digit $portIndex]} {
        puts "portIndex $portIndex is not digit in getCrytalStatus $spreadsheet_index"
        puts "indexmap: $m_indexMap"
        return -
    }
    
    if {$portIndex < 0} {
        puts "portIndex $portIndex < 0"
        puts "indexmap: $m_indexMap"
        return -
    }

    set portStatus [lindex $robot_cassette $portIndex]

    if {$portStatus == ""} {
        puts "port status return empty"
        puts "portindex: $portIndex"
        puts "status: $robot_cassette"
        set portStatus -
    }
    return $portStatus
}
::itcl::body SequenceDevice::getPortIndexInCassette { cassette row column } {
    variable ::nScripts::robot_cassette

    set casIndex [lsearch {l m r} $cassette]
    set CIndex [lsearch {A B C D E F G H I J K L} $column]
    set RIndex $row
    if { $casIndex < 0 || $CIndex < 0 } { return -1 }

    set cassette_index [expr 97 * $casIndex]
    set cassette_status [lindex $robot_cassette $cassette_index]
    switch -exact -- $cassette_status {
        3 {
            return [expr "97 * $casIndex + 16 * $CIndex + $RIndex"]
        }
        default {
            return [expr "97 * $casIndex + 8 * $CIndex + $RIndex"]
        }
    }
}
::itcl::body SequenceDevice::getPortStatus { cassette row column } {
    variable ::nScripts::robot_cassette

    set portIndex [getPortIndexInCassette $cassette $row $column]
    
    if {$portIndex < 0} { return - }

    set portStatus [lindex $robot_cassette $portIndex]

    if {$portStatus == ""} {
        set portStatus -
    }
    return $portStatus
}
#search the crystal list and try to find the port.
#return -1 if the crystal is not on the list
::itcl::body SequenceDevice::getCrystalIndex { row column } {
    set port_name $column$row
    return [lsearch $m_crystalPortList $port_name]
}

#check whether action selection is OK
#must have at least one of "stop" or "mountnext"
::itcl::body SequenceDevice::actionSelectionOK {} {
    variable ::nScripts::scn_action_msg

    #mount must be first if no current sample
    if {$m_currentCrystal < 0 && $m_currentAction != 0} {
        set mountNextSelected [lindex $m_actionListStates 0]
        if {$m_nextAction != 0 || !$mountNextSelected} {
            log_error "must mount a sample first"
            set scn_action_msg "error: must mount a sample first"

            #####do it for the user
            if {!$mountNextSelected} {
                set m_actionListStates [lreplace $m_actionListStates 0 0 1]
                #send_operation_update "setConfig actionListStates $m_actionListStates"
                log_error selected Mount Next Crystal
            }
            if {$m_nextAction != 0} {
                set m_nextAction 0
                #send_operation_update "setConfig nextAction $m_nextAction"
                log_error moved Begin-> to Mount Next Crystal
            }

            log_warning Please check the Action Selection and start again
            return 0
        }
    }
    
    set move_OK 0
    set record_OK 0
        
    set n [llength $m_actionListStates]
    for {set i 0} {$i<$n} {incr i} {
        set state [lindex $m_actionListStates $i]
        if { $state==1 } {
            set action [lindex $m_actionListParameters $i]
            set actionClass [lindex $action 0]
            switch -exact -- $actionClass {
                MountNextCrystal {
                    set move_OK 1
                }
                Pause {
                    set move_OK 1
                    set record_OK 1
                }
                VideoSnapshot {
                    set record_OK 1
                }
                CollectImage {
                    set record_OK 1
                }
                ExcitationScan {
                    set record_OK 1
                }
            }
        }
    }

    if { $move_OK && $record_OK } {
        set scn_action_msg "action selection OK"
        return 1
    } else {
        log_error "screening error: must have stop or mount+image"
        set scn_action_msg "error: must have stop or mount+image"
        return 0
    }
}
::itcl::body SequenceDevice::crystalSelectionOK {} {
    variable ::nScripts::scn_crystal_msg

    if {![checkCrystalList m_crystalListStates]} {
        return 0
    }
    if {$m_currentCrystal < 0 && [lsearch $m_crystalListStates 1] < 0} {
        set scn_crystal_msg "error: must select at least one crystal"
        return 0
    }

    return 1
}

::itcl::body SequenceDevice::checkCrystalList { varName } {
    variable ::nScripts::scn_crystal_msg

    set noChange 1

    upvar $varName result

    ################## check cassette  ##################
    set index [lindex $m_cassetteInfo 1]
    if {$index == 0 || $index > 3} {
        puts "checkCrystalList no change index 0 or >3"
        set scn_crystal_msg "warning: no check for no-robot cassette"
        return 1
    }
    set cur_cassette [lindex "0 l m r" $index]

    set n [llength $result]

    if {$m_spreadsheetStatus <= 0} {
        log_severe dcss still trying to load spreadsheet
        return -code error "dcss spreadsheet not ready"
    }
    if {$n != $m_numRowParsed} {
        log_severe user selecting sample from a failed spreadsheet
        return -code error "BluIce using failed spreadsheet"
    }

    set currentPort ""
    set mountingPort ""
    if {$m_currentCrystal >= 0} {
        set currentPort [lindex $m_crystalPortList $m_currentCrystal]
    }
    if {$m_mountingCrystal >= 0} {
        set mountingPort [lindex $m_crystalPortList $m_mountingCrystal]
    }
    ################## check spreadsheet crystals ############
    for {set i 0} {$i<$n} {incr i} {
        set state [lindex $result $i]
        if {$state == 1} {
            set port [lindex $m_crystalPortList $i]
            set portID [lindex $m_crystalIDList $i]
            set ll_port [string length $port]
            if {$ll_port != 2 && $ll_port != 3} {
                set scn_crystal_msg "warning: $portID has bad name $port"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad port length"
                log_warning "screening: crystal $portID disabled because of bad port name $port"
                set noChange 0
                continue
            }
            set column [string index $port 0]
            set row [string range $port 1 end]
            if {[lsearch {A B C D E F G H I J K L M N O P} $column] < 0} {
                set scn_crystal_msg "warning: $portID has bad column $column"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad column"
                log_warning "screening: crystal $portID disabled because of bad column $column"
                set noChange 0
                continue
            }
            if {[lsearch {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16} $row] < 0} {
                set scn_crystal_msg "warning: $portID has bad row $row"
                set result [lreplace $result $i $i 0]
                puts "checkCrystalList turn off $i: bad row"
                log_note "screening: crystal $portID disabled because of bad row $row"
                set noChange 0
                continue
            }
            #check port status if using robot
            if {!$m_useRobot} continue

            set port_status [getCrystalStatus $i]
            switch -exact -- $port_status {
                j {
                    set scn_crystal_msg "warning: $portID port jam"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: port jam"
                    log_error "screening: crystal $portID disabled because of port jam"
                    set noChange 0
                    continue
                }
                b {
                    set scn_crystal_msg "warning: $portID bad port"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: bad port"
                    log_error "screening: crystal $portID disabled because of bad port"
                    set noChange 0
                    continue
                }
                - {
                    set scn_crystal_msg "warning: $portID port $port not exist"
                    set result [lreplace $result $i $i 0]
                    puts "checkCrystalList turn off $i: port not exist"
                    log_error "screening: crystal $portID disabled because of port not exist"
                    set noChange 0
                    continue
                }
                0 {
                    ### this assumed no repeat port
                    if {$i != $m_currentCrystal && $i != $m_mountingCrystal} {
                        if {$port != $currentPort && $port != $mountingPort} {
                            set scn_crystal_msg "warning: $portID empty port"
                            set result [lreplace $result $i $i 0]
                            puts "checkCrystalList turn off $i: empty port"
                            log_error "screening: crystal $portID disabled because of empty port"
                            set noChange 0
                        }
                        continue
                    }
                }
                m -
                1 -
                u -
                default {
                }
            }
        }
    }
    return $noChange
}

::itcl::body SequenceDevice::listIsUnique { list_to_check } {
    set raw_l [llength $list_to_check]
    if {$raw_l < 2} {
        return 1
    }

    set unique_l [llength [lsort -unique $list_to_check]]
    if {$unique_l >= $raw_l} {
        return 1
    } else {
        return 0
    }
}

#go through selected actions and check their parameters
::itcl::body SequenceDevice::actionParametersOK { varName fixIt} {
    upvar $varName action_parameters 
    variable ::nScripts::scn_action_msg
    set checkOK 1
    set index -1
    foreach action $action_parameters {
        incr index
        set selected [lindex $m_actionListStates $index]
        #puts "action $action selected: $selected"

        if {!$selected} {
            continue
        }
        set actionClass [lindex $action 0]
        set params [lindex $action 1]
        #puts "actionClass {$actionClass}"
        #puts "param: $params"
        switch -exact -- $actionClass {
            MountNextCrystal {
                set num_cycle $params
                if {![string is integer $num_cycle]} {
                    if {!$fixIt} {
                        log_error "wash cycle must be an integer"
                        set scn_action_msg \
                        "error: wash cycle must be an integer"
                    } else {
                        set num_cycle 0
                        log_warning "wash cycle changed to $num_cycle"
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params $num_cycle
                }
            }
            VideoSnapshot {
                foreach {zoom nameTag} $params break
				if {[motor_exists camera_zoom]} {
                    puts "motor camera_zoom exists"
                	if {$zoom == ""} {
                        if {!$fixIt} {
                    	    log_error \
                            "must have a zoom value for $index $actionClass"
                    	    set scn_action_msg "error: no zoom value"
                        } else {
                    	    log_warning \
                            "must have a zoom value for $index $actionClass"
                            foreach {lowerLimit upperLimit} \
                            [getGoodLimits camera_zoom] break

                            set zoom $upperLimit
                            log_warning zoom changed to $zoom 
                        }
                    	set checkOK 0
                	} elseif {[catch {
                        assertMotorLimit camera_zoom $zoom
                    } dummy]} {
                        if {!$fixIt} {
                    	    log_error \
                            "zoom out of soft limit for $index $actionClass"
                    	    set scn_action_msg "error: bad zoom value"
                        } else {
                    	    log_warning \
                            "zoom out of soft limit for $index $actionClass"
                            foreach {lowerLimit upperLimit} \
                            [getGoodLimits camera_zoom] break

                            set zoom $upperLimit
                            log_warning zoom changed to $zoom
                        }
                    	set checkOK 0
                	}
				}
                #if {$nameTag == ""} {
                #    set scn_action_msg "error: no name tag"
                #    log_error "must have a nameTag for $index $actionClass"
                #    set checkOK 0
                #}
                if {!$checkOK && $fixIt} {
                    set params [list $zoom $nameTag]
                }
            }
            CollectImage {
                foreach {deltaPhi time nImages nameTag} $params break
                puts "collectImage: $deltaPhi $time"
                if {$deltaPhi == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no deltaPhi"
                        log_error "must have a deltaPhi for $index $actionClass"
                    } else {
                        log_warning \
                        "must have a deltaPhi for $index $actionClass"
                        set deltaPhi 0.01
                        log_warning "deltaPhi changed to $deltaPhi"
                    }
                    set checkOK 0
                } elseif {$deltaPhi == 0.0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: deltaPhi cannot be 0"
                        log_error "deltaPhi cannot be 0 for $index $actionClass"
                    } else {
                        log_warning \
                        "deltaPhi cannot be 0 for $index $actionClass"
                        set deltaPhi 0.01
                        log_warning "deltaPhi changed to $deltaPhi"
                    }
                    set checkOK 0
                }

                if {$time == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no time input"
                        log_error "must have a time for $index $actionClass"
                    } else {
                        global gDevice
                        log_warning "must have a time for $index $actionClass"
                        if {[isString collect_default]} {
                            set contents $gDevice(collect_default,contents)
                            set time [lindex $contents 1]
                        }
                        if {$time == "" || $time <= 0.0} {
                            set time 1.0
                        }
                        log_warning time changed to $time
                    }
                    set checkOK 0
                } elseif {$time <= 0.0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: time must > 0"
                        log_error "time must > 0 for $index $actionClass"
                    } else {
                        global gDevice
                        log_warning "time must > 0 for $index $actionClass"
                        if {[isString collect_default]} {
                            puts "collect_default is string"
                            set contents $gDevice(collect_default,contents)
                            set time [lindex $contents 1]
                            puts "set time to $time"
                        }
                        if {$time == "" || $time <= 0.0} {
                            set time 1.0
                        }
                        log_warning time changed to $time
                    }
                    set checkOK 0
                }

                if {$nImages == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no nImages"
                        log_error "must have a nImages for $index $actionClass"
                    } else {
                        log_warning \
                        "must have a nImages for $index $actionClass"
                        set nImages 1
                        log_warning nImages changed to $nImages
                    }
                    set checkOK 0
                } elseif {$nImages <= 0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: nImages must > 0"
                        log_error "nImages must > 0 for $index $actionClass"
                    } else {
                        log_warning "nImages must > 0 for $index $actionClass"
                        set nImages 1
                        log_warning nImages changed to $nImages
                    }
                    set checkOK 0
                }
                #if {$nameTag == ""} {
                #    set scn_action_msg "error: no name tag"
                #    log_error "must have a nameTag for $index $actionClass"
                #    set checkOK 0
                #}
                if {!$checkOK && $fixIt} {
                    set params [list $deltaPhi $time $nImages $nameTag]
                }
            }

            ExcitationScan {
                foreach {time nameTag} $params break

                if {$time == ""} {
                    if {!$fixIt} {
                        set scn_action_msg "error: no time input"
                        log_error "must have a time for $index $actionClass"
                    } else {
                        log_warning "must have a time for $index $actionClass"
                        set time 1.0
                        log_warning time changed to $time
                    }
                    set checkOK 0
                } elseif {$time <= 0.0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: time must > 0"
                        log_error "time must > 0 for $index $actionClass"
                    } else {
                        log_warning "time must > 0 for $index $actionClass"
                        set time 1.0
                        log_warning time changed to $time
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params [list $time $nameTag]
                }
            }

            Rotate {
                puts "Rotate: $params"
                set angle $params
                if {$angle == "" || $angle == 0} {
                    if {!$fixIt} {
                        set scn_action_msg "error: bad angle"
                        log_error "angle must not 0 for $index $actionClass"
                    } else {
                        log_warning "angle must not 0 for $index $actionClass"
                        set angle 45.0
                        log_warning angle changed to $angle
                    }
                    set checkOK 0
                }
                if {!$checkOK && $fixIt} {
                    set params $angle
                }
            }
        }
        if {!$checkOK && $fixIt} {
            set action [list $actionClass $params]
            set action_parameters \
            [lreplace $action_parameters $index $index $action]
        }
    }
    return $checkOK
}
::itcl::body SequenceDevice::getCurrentPortID { } {
    if {$m_currentCrystal < 0} {
        return ""
    }
    set cur_port [lindex $m_crystalIDList $m_currentCrystal]
    if {$cur_port == "" ||$cur_port == "null" || $cur_port == "NULL" || $cur_port == "0"} {
        append cur_port ([getCurrentRawPort])
    }
    return $cur_port
}
::itcl::body SequenceDevice::getNextPortID { } {
    if {$m_nextCrystal < 0} {
        return ""
    }
    set next_port [lindex $m_crystalIDList $m_nextCrystal]
    if {$next_port == "" ||$next_port == "null" || $next_port == "NULL" || $next_port == "0"} {
        append next_port ([getNextRawPort])
    }
    return $next_port
}
::itcl::body SequenceDevice::getCurrentRawPort { } {
    if {$m_currentCrystal < 0} return ""
        
    #get cassette name
    set current_index [lindex $m_cassetteInfo 1]
    set current_cassette [lindex {0 l m r} $current_index]

    set current_port [lindex $m_crystalPortList $m_currentCrystal]
    return "${current_cassette}$current_port"
}
::itcl::body SequenceDevice::getNextRawPort { } {
    if {$m_nextCrystal < 0} return ""
    #get cassette name
    set current_index [lindex $m_cassetteInfo 1]
    set current_cassette [lindex {0 l m r} $current_index]

    set next_port [lindex $m_crystalPortList $m_nextCrystal]
    return "${current_cassette}$next_port"
}
::itcl::body SequenceDevice::doManualMountCrystal { args } {
    variable ::nScripts::robot_status

    if {[llength $args] > 2} {
        foreach {cassette column row} $args break
    } else {
        set port [lindex $args 0]
        set cassette [string index $port 0]
        set column [string index $port 1]
        set row [string range $port 2 end]
    }

    checkCassettePermit $cassette

    ########## force use robot
    if {!$m_useRobot} {
        set m_useRobot 1
    }

    #want to make sure it will work even not synced with robot
    if {![syncWithRobot 1]} {
        set sample_on_gonio [lindex $robot_status 15]
        if {$sample_on_gonio != ""} {
            set m_currentCassette [lindex $sample_on_gonio 0]
            set m_currentRow [lindex $sample_on_gonio 1]
            set m_currentColumn [lindex $sample_on_gonio 2]
        } else {
            set m_currentCassette n
            set m_currentRow 0
            set m_currentColumn N
        }
        set m_currentCrystal -1
        updateCrystalStatusString
        #send_operation_update "setConfig currentCrystal $m_currentCrystal"
    }
    
    set spreadsheet_index [lindex $m_cassetteInfo 1]
    set spreadsheet_cassette [lindex {0 l m r} $spreadsheet_index]
    if {$cassette == "n" || \
    $column == "N" || \
    $row == 0 || \
    $spreadsheet_cassette != $cassette} {
        set m_mountingCrystal -1
    } else {
        set m_mountingCrystal [getCrystalIndex $row $column]
    }
    # call mountCrystal first, the ajdust m_currentCrystal
    mountCrystal $cassette $column $row 0
    set m_mountingCrystal -1

    if {($m_currentCassette == "n" && \
    $m_currentColumn == "N" && \
    $m_currentRow == 0) || $spreadsheet_cassette != $m_currentCassette} {
            set m_currentCrystal -1
    } else {
        set m_currentCrystal [getCrystalIndex $m_currentRow $m_currentColumn]
    }
    #send_operation_update "setConfig currentCrystal $m_currentCrystal"
    syncWithRobot
    updateCrystalSelectionListString
    setStrategyFileName disMnted
}

# Get image header from image server
::itcl::body SequenceDevice::getImageHeader { fileName } {
    set mySID [getRawSessionId $m_lastSessionID]
    set url "http://"
    append url [::config getImgsrvHost]
    append url ":"
    append url [::config getImgsrvHttpPort]
    append url "/getHeader"
    append url "?userName=$m_lastUserName"
    append url "&sessionId=$mySID"
    append url "&fileName=$fileName"
    puts "getImageHeader url: [SIDFilter $url]"

    set result {}
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        log_error "getImageHeader failed $err"
        puts "getImageHeader failed $err"
    }
    checkHttpStatus $token
    set result [http::data $token]
    http::cleanup $token

    return $result
}

::itcl::body SequenceDevice::getPhi { contents } {

    set data [split $contents "\n"]
    foreach line $data {
     # puts $line
        set i [string last " " $line]
        if {$i > 0} {
            set ii [expr "$i - 1"]
            set label [string range $line 0 $ii]
            set label [string trim $label]
            set val [string range $line $i end]
            set val [string trim $val]
            if {$label == "PHI"} {
                return $val
            }
        }         
    }
     return ""
}

::itcl::body SequenceDevice::getRawSessionId { sessionId } {
    if {[string equal -length 7 $sessionId "PRIVATE"]} {
        set mySID [string range $sessionId 7 end]
    } else {
        set mySID $sessionId
    }
}
::itcl::body SequenceDevice::runMatchup { snapshot1 snapshot2 } {

    log_error "Executing(on smbdev2) /data/penjitk/sw/matchup/run_matchup.com $snapshot1 $snapshot2"
    set mySID [getRawSessionId $m_lastSessionID]
    set cmd "/data/penjitk/sw/matchup/run_matchup.com%20${snapshot1}%20${snapshot2}"
    set url "http://smbdev2.slac.stanford.edu:61001"
    append url "/runScript?impUser=$m_lastUserName"
    append url "&impSessionID=$mySID"
    append url "&impCommandLine=$cmd"
    append url "&impUseFork=false"
    append url "&impEnv=HOME=/home/${m_lastUserName}"

    puts "runMatchup: url = $url"

    set token [http::geturl $url -timeout 8000]
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    http::cleanup $token
     
    set tokens [split $result "\n"]
    set lastLine ""
     set line ""
    foreach {line} $tokens {
        if {$line != ""} {
            puts "matchup result line = $line"
            set lastLine $line
        }
     }

    return $lastLine
}

::itcl::body SequenceDevice::doAutoindex { } {
    #situations that autoindexing will not do

	variable ::nScripts::sil_config
	set enableStrategy 0
	if {[info exists sil_config]} {
    	set strategy       [lindex $sil_config 3]

    	if {$strategy == "1"} {
        set enableStrategy 1
        puts "strategy enabled"
    	}
	}


    ##### collect image selection check ######
    set c1_selected [expr [lindex $m_actionListStates 4] ? 1 : 0]
    set c2_selected [expr [lindex $m_actionListStates 7] ? 1 : 0]
    set c3_selected [expr [lindex $m_actionListStates 11] ? 1 : 0]
    set is_stopped [expr [lindex $m_actionListStates 13] ? 1 : 0]

    set total [expr $c1_selected + $c2_selected +$c3_selected]
    if {$total < 2} {
        puts "only one collect image selected"
        return;# only one collect image selected
    }
    
    ##### images available check ##########
    set img1_available 0
    set img2_available 0
    set img3_available 0
    if {$c1_selected && $m_img1 != ""} {
        set img1_available 1
    }
    if {$c2_selected && $m_img2 != ""} {
        set img2_available 1
    }
    if {$c3_selected && $m_img3 != ""} {
        set img3_available 1
    }
    set total [expr $img1_available + $img2_available + $img3_available]
    if {$total < 2} {
        puts "not enough images available"
        return;# only one collect image selected
    }

    ###### angle check ##############
    set action [lindex $m_actionListParameters 5]
    set angle2 [lindex $action 1]
    set action [lindex $m_actionListParameters 9]
    set angle3 [lindex $action 1]

    #find max angle diff
    set diff12 0
    set diff13 0
    set diff23 0
    if {$img1_available && $img2_available} {
        set diff12 [angleSpan $angle2]
    }
    if {$img1_available && $img3_available} {
        set diff13 [angleSpan [expr $angle2 + $angle3]]
    }
    if {$img2_available && $img3_available} {
        set diff23 [angleSpan $angle3]
    }

    set max_diff $diff12
    set autoindexPair [list 1 2]
    if {$diff13 > $max_diff} {
        set max_diff $diff13
        set autoindexPair [list 1 3]
    }
    if {$diff23 > $max_diff} {
        set max_diff $diff23
        set autoindexPair [list 2 3]
    }
    if {$max_diff <= 5.0} {
        puts "angle diff < 5.0"
        return;# angle separation too small
    }
    puts "we are using $autoindexPair to do autoindex"

    ################### Do it #######################################
    set image1 [set m_img[lindex $autoindexPair 0]]
    set image2 [set m_img[lindex $autoindexPair 1]]
	 
	 if {$is_stopped && $enableStrategy} {
	 	set doStrategy "true"
        set strategyFileName [getStrategyFileName]
	 } else {
	    set doStrategy "false"
        set strategyFileName notSelected
     }
     set runName [getCrystalName]
     setStrategyFileName $strategyFileName $runName

    autoindexCrystal $m_lastUserName $m_lastSessionID $m_SILID $m_currentCrystal $image1 $image2 $m_beamlineName $runName $doStrategy $strategyFileName

   set scriptName [::config getCrystalAutoindexUrl]
    if {[string first reautoindex $scriptName] < 0} {
        puts "Running stratetgy"
        clearImages
        return
    }  
    puts "Running reautoindex"

    # Get image1 and imag2 used to calculate strategy in the first pass
    set portID [lindex $m_crystalIDList $m_currentCrystal]
    set autoindexInputFile "/data/$m_lastUserName/webice/screening/$m_SILID/$portID/autoindex/input.xml"
    set handle [open $autoindexInputFile r]
    set contents [read $handle]
    close $handle
    set data [split $contents "\n"]
     set lastImage1 ""
     set lastImage2 ""
    set lastImageDir ""
    foreach line $data {
        # <image>xxxx.xxx</image>
        if {[string first <image> $line] > -1} {
            set i1 [string first > $line]
            set i1 [expr $i1 + 1]
            set i2 [string last  < $line]
            set i2 [expr $i2 - 1]
                if {$lastImage1 == ""} {
                    set lastImage1 [string range $line $i1 $i2]
                } else {
                    set lastImage2 [string range $line $i1 $i2]
                }
        } else {
                if {[string first <imageDir> $line] > -1} {
                set i1 [string first > $line]
                set i1 [expr $i1 + 1]
                set i2 [string last  < $line]
                set i2 [expr $i2 - 1]
                    set lastImageDir [string range $line $i1 $i2]
                }
          }
    }
    set lastImage1 "${lastImageDir}/$lastImage1"
    set lastImage2 "${lastImageDir}/$lastImage2"

     puts "Images for strategy are $lastImage1 and $lastImage2"
     puts "Images for reautoindex are $image1 and $image2"

    set phiOffsetFilename "/data/$m_lastUserName/webice/screening/$m_SILID/$portID/autoindex/REMOUNT/best_phi_strategy.tcl"
    wait_for_time 20000
    log_warning "wait for file: $phiOffsetFilename"
    wait_for_file $phiOffsetFilename 120000
    log_warning "done waiting for file: $phiOffsetFilename"

    # Get phi shift from best_phi_strategy.tcl
    set phiShift 0 
    set handle [open $phiOffsetFilename r]
    set contents [read $handle]
    close $handle

    set foundPhiShift 0
    set data [split $contents "\n"]
    foreach line $data {
        foreach {label token} $line {
            if {$label == "PhiShift"} {
                set phiShift $token
                set foundPhiShift 1
            }
        }
    }

    if {$foundPhiShift == 0} {
        puts "Cannot find PhiShift in $phiOffsetFilename"
        puts "$contents"
        return
    }

    # Get faceon and edgeon phi from images 
    # taken in the first pass of screening.
    set contents [getImageHeader $lastImage1]
    set faceOnPhi [getPhi $contents]

    set contents [getImageHeader $lastImage2]
    set edgeOnPhi [getPhi $contents]

    log_warning "phi shift of: $phiShift"
    log_warning "faceOn phi was: $faceOnPhi"
    log_warning "edgeOn phi was: $edgeOnPhi"

    move gonio_phi to [expr $faceOnPhi + $phiShift]
    wait_for_devices gonio_phi

    set fileNameFace phiOffset_${portID}_faceon
    set fileName ${fileNameFace}
    set subdir [lindex $m_crystalDirList $m_currentCrystal]
    set filePathFace [file join $m_directory $subdir "${fileName}"]
    set sampleUrl [::config getSnapshotUrl]
    videoSnapshotBoxAndNoBox $filePathFace

    log_warning "video snapshot: $filePathFace"

    set searchFilePath1 [file join $m_directory $subdir ${portID}_0deg_001.jpg]

    log_warning "$filePathFace $searchFilePath1"

    set doit "1"
    if { $doit } { 

    puts "Running matchup"

#    set xy_offsetResult [exec /usr/local/dcs/matchup/matchup.com $filePathFace $searchFilePath1 | grep cc | grep -v second]
    set xy_offsetResult [runMatchup ${filePathFace}.jpg $searchFilePath1]
    puts "matchup result = $xy_offsetResult"
    set tokens [split $xy_offsetResult " "]
    foreach {edgeonX edgeonY edgeonCc} $tokens {
        puts "edgeOffset: x: $edgeonX y: $edgeonY cc: $edgeonCc"
        log_warning "edgeOffset1: x: $edgeonX y: $edgeonY cc: $edgeonCc"
    }

    set x_offset [expr $edgeonX / 704.0]
    set y_offset [expr $edgeonY / 480.0]

   
    namespace eval ::nScripts moveSample_start $x_offset $y_offset

    move gonio_phi to [expr $edgeOnPhi + $phiShift]
    wait_for_devices gonio_phi

    set fileNameEdge phiOffset_${portID}_edgeOn
    set fileName ${fileNameEdge}
    set subdir [lindex $m_crystalDirList $m_currentCrystal]
    set filePathEdge [file join $m_directory $subdir "${fileName}"]

    videoSnapshotBoxAndNoBox $filePathEdge

    log_warning "video snapshot: ${filePathEdge}.jpg"

    set searchFilePath2 [file join $m_directory $subdir ${portID}_90deg_002.jpg]

#    set xy_offsetResult [exec /usr/local/dcs/matchup/matchup.com $filePathEdge $searchFilePath2 | grep cc | grep -v second]
    set xy_offsetResult [runMatchup ${filePathEdge}.jpg $searchFilePath2]
    puts "matchup result = $xy_offsetResult"
    set tokens [split $xy_offsetResult " "]
    foreach {edgeonX edgeonY edgeonCc} $tokens {
        puts "edgeOffset: x: $edgeonX y: $edgeonY cc: $edgeonCc"
        log_warning "edgeOffset2: x: $edgeonX y: $edgeonY cc: $edgeonCc"
    }

    set x_offset [expr $edgeonX / 704.0]
    set y_offset [expr $edgeonY / 480.0]

    namespace eval ::nScripts moveSample_start $x_offset $y_offset

#    videoSnapshotScan [file join $m_directory $subdir] $fileNameEdge $sampleUrl [list -3 -2 -1 -0.5 0 0.5 1 2 3 90 180 270]

    move gonio_phi to [expr $faceOnPhi + $phiShift]
    wait_for_devices gonio_phi

#    videoSnapshotScan [file join $m_directory $subdir] $fileNameFace $sampleUrl [list -3 -2 -1 -0.5 0 0.5 1 2 3 90 180 270]

    move gonio_phi by -90
    wait_for_devices gonio_phi

    videoSnapshotScan [file join $m_directory $subdir] profile_remount_${portID} [list 0 45 90 135 180 225 270 315]
    }

    ####allow re autoindex for new images
    clearImages
}





::itcl::body SequenceDevice::videoSnapshotScan { dir fileRoot deltaPhiList } {

    variable ::nScripts::gonio_phi

    set basePhi $gonio_phi 

    foreach deltaPhi $deltaPhiList {

    move gonio_phi to [expr $basePhi + $deltaPhi ]
    wait_for_devices gonio_phi

    set fileName ${fileRoot}_${deltaPhi}
    set filePath [file join $dir $fileName]

    videoSnapshotBoxAndNoBox $filePath
    }
}

::itcl::body SequenceDevice::videoSnapshotBoxAndNoBox { filePath } {
    after 2000

    set mySID $m_lastSessionID
    if {[string equal -length 7 $mySID "PRIVATE"]} {
        set mySID [string range $mySID 7 end]
    }

    set urlSOURCE [::config getSnapshotUrl]

    set urlTARGET "http://[::config getImpDhsImpHost]"
    append urlTARGET ":[::config getImpDhsImpPort]"
    append urlTARGET "/writeFile?impUser=$m_lastUserName"
    append urlTARGET "&impSessionID=$mySID"
    append urlTARGET "&impFilePath=${filePath}_box.jpg"
    append urlTARGET "&impWriteBinary=true"
    append urlTARGET "&impBackupExist=true"
    append urlTARGET "&impAppend=false"


# save file with a box 
    #set cmd "java url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTARGET -debug"
    set cmd "java -Djava.awt.headless=true url $urlSOURCE [drawInfoOnVideoSnapshot] -o $urlTARGET"
    #log_note cmd: $cmd
    if { [catch {
        set mm [eval exec $cmd]
        log_note exec result: $mm
        user_log_note screening "[getCrystalNameForLog] videosnap ${filePath}_box.jpg"
    } errMsg]} {
        user_log_error screening \
        "videoSnapshot with beam info error: $errMsg"
        log_error screening "videoSnapshot with beam info error: $errMsg"
    }

    set url [::config getSnapshotUrl]
# save file without a box
    if { [catch {
        set token [http::geturl $url -timeout 12000]
    } err] } {
        set status "ERROR $err $url"
        set ncode 0
        set code_msg "get url failed for snapshot"
    } else {
        upvar #0 $token state
        set status $state(status)
        set ncode [http::ncode $token]
        set code_msg [http::code $token]
        set result [http::data $token]
        http::cleanup $token

        if {[catch {
            impWriteFileWithBackup $m_lastUserName $m_lastSessionID ${filePath}.jpg $result
            user_log_note screening \
            "[getCrystalNameForLog] videosnap ${filePath}.jpg"
        } errMsg]} {
            log_error "failed to save video snapshot to ${filePath}.jpg: $errMsg"
            set screening_msg "error: failed to save snapshot"
        }
    }
    if { $status!="ok" || $ncode != 200 } {
        set msg \
        "ERROR SequenceDevice::doVideoSnapshot http::geturl status=$status"
        puts $msg
        set screening_msg "error: snapshot failed"
        log_error "Screening videoSnapshot Web error: $status $code_msg"
        user_log_error screening \
        "videoSnapshot Web error: $status $code_msg"
    }
}






::itcl::body SequenceDevice::handlePortStatusChangeEvent { args } {
    variable ::nScripts::robot_cassette

    log_note "port status change event called"
    if { $m_isInitialized==0 } {
        log_warning postpone port status update to initializaion
        return
    }

    ### if cassette status changed, we need to regenerate the map
    ### between spreadsheet row and robot_cassette
    set index [lindex $m_cassetteInfo 1]
    set cassette_index [expr "97 * ($index - 1)"]
    set cassette_status [lindex $robot_cassette $cassette_index]

    if {$m_currentCassetteStatus != $cassette_status} {
        set m_currentCassetteStatus $cassette_status
        #### here we only supply port list so the port_index is 0
        set m_indexMap [generateIndexMap $index 0 m_crystalPortList \
        $m_currentCassetteStatus]

        puts "re-map index: $m_indexMap"
    }

    checkCrystalList m_crystalListStates
    set m_nextCrystal [getNextCrystal $m_nextCrystal]
    updateCrystalSelectionListString
    updateCrystalStatusString 
}
::itcl::body SequenceDevice::handleLastImageChangeEvent { args } {
    log_note "last image event called: waiting list {$m_imageWaitingList}"

    if {[llength $m_imageWaitingList] <= 0} {
        return
    }
    variable ::nScripts::lastImageCollected

    set index [lsearch $m_imageWaitingList $lastImageCollected]
    if {$index < 0} {
        puts "last image: {$lastImageCollected} not found in waiting list: {$m_imageWaitingList}"
        return
    }
    if {$index != 0} {
        puts "last image: {$lastImageCollected} is not the first on in waiting list: {$m_imageWaitingList}"
        puts "all images before it skipped"
    }
    incr index
    set m_imageWaitingList [lrange $m_imageWaitingList $index end]

    start_operation image_convert $m_lastUserName $m_lastSessionID $lastImageCollected
    ##log_note start_operation image_convert $m_lastUserName $m_lastSessionID $lastImageCollected
}
::itcl::body SequenceDevice::handleCassetteListChangeEvent { args } {
    if {[::config getLockSILUrl] == ""} {
        ###### old server ######
        return
    }
    log_note "cassetteList called"

    variable ::nScripts::cassette_list

    if {![info exists cassette_list]} {
        log_error cassette_list not found in database
        return
    }

    if { $m_isInitialized==0 } {
        log_warning new cassette_list: $cassette_list
        log_warning postpone cassette list update to initializaion
        return
    }

    set local_copy [lindex $cassette_list 0]

    set m_cassetteInfo [lreplace $m_cassetteInfo 2 2 $local_copy]
    updateCassetteInfo
}
::itcl::body SequenceDevice::updateCassetteInfo { } {
    catch loadCrystalList

    saveStateToDatabaseString
    getConfig all
}
::itcl::body SequenceDevice::clearMounted { args } {
    puts "SequenceDevice::clearMounted $args"
    if { $m_isRunning==1 } {
        return -code error "SAM still running"
    }

    set sessionID [lindex $args end]
    if {$sessionID != ""} {
        set m_lastSessionID $sessionID
        puts "clearMounted sessionID $m_lastSessionID"
        set m_lastUserName [getUserName]

        variable ::nScripts::screening_user
        set screening_user $m_lastUserName
    }

    #### tell robot to clear mounted first
    set handle [start_waitable_operation robot_config clear_mounted]
    set result [wait_for_operation_to_finish $handle]

    #### clear 
    set m_currentCassette n
    set m_currentColumn N
    set m_currentRow 0
    updateAfterDismount
}
::itcl::body SequenceDevice::updateAfterDismount { } {
    if {$m_currentCrystal >= 0} {
        set m_crystalListStates \
        [lreplace $m_crystalListStates $m_currentCrystal $m_currentCrystal 0]

        if {!$m_useRobot} {
            set screening_msg "manual dismount"
            log_warning "If a sample is mounted, dismount it now"
        }
    }
    set m_currentCrystal -1
    updateCrystalSelectionListString
    updateCrystalStatusString 
    updateScreeningActionListString
    if {!$m_useRobot} {
        syncWithRobot
    } else {
        syncWithRobot $TRY_SYNC_WITH_ROBOT
    }
}
::itcl::body SequenceDevice::getStrategyFileName { } {
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set fileName "${m_SILID}_[getCrystalName]_${timestamp}.tcl"

    if {[catch {
        file mkdir $m_strategyDir
    } errMsg]} {
        log_error "failed to create the common strategy file directory $m_strategyDir: $errMsg"
    }
    if {[catch {
        file attributes $m_strategyDir -permissions 0777
    } errMsg]} {
        puts "failed to change permitssion of $m_strategyDir: $errMsg"
    }
    return [file join $m_strategyDir $fileName]
}
::itcl::body SequenceDevice::setStrategyFileName { fullPath {runName ""} } {
    variable ::nScripts::strategy_file

    if {![info exists strategy_file]} {
        puts "string strategy_file not exists"
        return
    }

    set ll [llength $strategy_file]
    switch -exact -- $ll {
        0 -
        1 {
            set strategy_file [list $fullPath $runName]
        }
        default {
            set strategy_file [lreplace $strategy_file 0 1 $fullPath $runName]
        }
    }
}
::itcl::body SequenceDevice::checkCassettePermit { cassette } {
    global gClientInfo
    variable ::nScripts::cassette_owner

    puts "checkCassettePermit $cassette"

    set operationHandle [lindex [get_operation_info] 1]
    set clientId [expr int($operationHandle)]
    set isStaff [set gClientInfo($clientId,staff)]

    puts "clientID: $clientId"
    puts "isStaff: $isStaff"

    if {$isStaff} return

    switch -exact $cassette {
        0 -
        1 -
        2 -
        3 {
            set owner [lindex $cassette_owner $cassette]
        }
        l {
            set owner [lindex $cassette_owner 1]
        }
        m {
            set owner [lindex $cassette_owner 2]
        }
        r {
            set owner [lindex $cassette_owner 3]
        }
        n {
            ### dismount is allowed
            return
        }
        default {
            set owner [lindex $cassette_owner 0]
        }
    }
    puts "owner=$owner"
    puts "lastuser=$m_lastUserName"
    if {$owner != "" && $owner != $m_lastUserName} {
        log_error "cassette access denied: not owner"
        return -code error "cassette access denied, not owner"
    }
}
::itcl::body SequenceDevice::waitForMotorsForVideo { } {
    if {[catch {
        ####here we can also use the all moving motor list from system
        set movingMotors [namespace eval \
        ::nScripts ISampleMountingDevice_start getMovingBackMotorList]

        set waitingMotors {}
        foreach motor $m_motorForVideo {
            if {[lsearch $motor $movingMotors] >= 0} {
                lappend waitingMotors $motor
            }
        }
        if {[llength $waitingMotors] > 0} {
            log_note waiting for $waitingMotors to complete moving
            eval wait_for_devices $waitingMotors
        }
    } errMsg]} {
        log_error $errMsg
    }
}
::itcl::body SequenceDevice::waitForMotorsForCollect { } {
    if {[catch {
        ####here we can also use the all moving motor list from system
        set movingMotors [namespace eval \
        ::nScripts ISampleMountingDevice_start getMovingBackMotorList]

        if {[llength $movingMotors] > 0} {
            log_note waiting for $movingMotors to complete moving
            eval wait_for_devices $movingMotors
        }
    } errMsg]} {
        log_error $errMsg
    }
}
