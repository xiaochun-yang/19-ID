#!/usr/bin/wish
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
package provide BLUICEDetectorControl 1.0

package require Itcl
package require Iwidgets
package require BWidget

# load the DCS packages
package require DCSDevice
package require DCSDeviceView

package require BLUICEDetectorMenu

class DCS::DetectorStatusParams {
    inherit DCS::Component	

    public method sendContentsToServer

    private variable m_deviceFactory
    private variable m_params 

    public variable status "inactive"

    public variable state 
    public variable temp0 
    public variable temp1 
    public variable temp2 

    public variable humid0 
    public variable humid1
    public variable humid2
    public variable gapFill
    public variable diskUsePercent


    public method setTemp0  {value_} {setField TEMP0 $value_}
    public method setTemp1  {value_} {setField TEMP1 $value_}
    public method setTemp2  {value_} {setField TEMP2 $value_}

    public method setHumid0  {value_} {setField HUMID0 $value_}
    public method setHumid1  {value_} {setFiled HUMID1 $value_}
    public method setHumid2  {value_} {setField HUMID2 $value_}

    public method setGapGill  {value_} {setField GAPFILL $value_}
    public method setDiskUsePercent  {value_} {setField DISK_USE_PERCENT $value_}

    public method getContents { } {
        $m_params getContents
    }

	# call base class constructor
	constructor { string_name args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {cget -status} \
					 contents { getContents } \
					 state {cget -state} \
					 temp0 {cget -temp0} \
					 temp1 {cget -temp1} \
					 temp2 {cget -temp2} \
					 humid0 {cget -humid0} \
					 humid1 {cget -humid1} \
					 humid2 {cget -humid2} \
					 diskUsePercent {cget -diskUsePercent} \
				     gapfill {cget -gapfill }
			 }
	} {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_detectorStatusStr [$m_deviceFactory createString $string_name]
        ::mediator register $this $m_detectorStatusStr contents handleParametersChange
        ::mediator register $this $m_detectorStatusStr status handleDetectorStatusChange
      
	    eval configure $args
      
	    announceExist

        return [namespace current]::$this
	}

    public method submitNewParameters { contents_ } {
        $m_params sendContentsToServer $contents_
    }

    public method setField  { paramName value_} {

        set clientState [::dcss cget -clientState]

        if { $clientState != "active"} return

        set newString [list TEMP0 $temp0 TEMP1 $temp1 TEMP2 $temp2 HUMID0 $humid0 HUMID1 $humid1 HUMID2 $humid2 GAPFILL $gapFill DISK_USE_PERCENT $diskUsePercent]

        set valueIndex [lookupIndexByName $newString $paramName]
        set newString [lreplace $newString $valueIndex $valueIndex $value_]
        submitNewParameters $newString
    }


    public method lookupIndexByName { paramList paramName } {
        return [expr [lsearch $paramList $paramName] +1]
    }

    public method lookupValueByName { paramList paramName } {
        return [lindex $paramList [expr [lsearch $paramList $paramName] +1]]
    }

    public method handleDetectorStatusChange { - targetReady_ - params - } {

        if {$params != "inactive" } {
            set temp0 (offline)
            set temp1 (offline)
            set temp2 (offline)
            set humid0 (offline)
            set humid1 (offline)
            set humid2 (offline)

            updateListeners
        }
    }
    public method handleParametersChange { - targetReady_ - params - } {

	    if { ! $targetReady_} return

        set temp0 [lookupValueByName $params TEMP0]
        set temp1 [lookupValueByName $params TEMP1]
        set temp2 [lookupValueByName $params TEMP2]
        set humid0 [lookupValueByName $params HUMID0]
        set humid1 [lookupValueByName $params HUMID1]
        set humid2 [lookupValueByName $params HUMID2]
        set diskUsePercent [lookupValueByName $params DISK_USE_PERCENT]

        updateListeners
    }

    private method updateListeners {} {
	    #inform observers of the change 
	    updateRegisteredComponents temp0 
	    updateRegisteredComponents temp1 
	    updateRegisteredComponents temp2 
	    updateRegisteredComponents humid0 
	    updateRegisteredComponents humid1 
	    updateRegisteredComponents humid2 
	    updateRegisteredComponents diskUsePercent 
    }

}



class DCS::Q315SpecificControl {
    inherit ::itk::Widget DCS::Component
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    private variable _mainWidget

    public method constructWidgets {} {
	    # draw and label the detector
	    global BLC_IMAGES


        set ring $itk_interior

		itk_component add canvas {
			canvas $ring.c -width 150 -height 150
		}

		set detectorImage [ image create photo \
											-file "$BLC_IMAGES/q4_small.gif" \
											-palette "255/255/255"]

		$itk_component(canvas) create image 0 0 \
			 -anchor nw \
			 -image $detectorImage -tag detectorItems 

        itk_component add q315CollectBackground {
            DCS::Button $ring.q -command "$this q315CollectBackground" \
                -text "Collect Q315 Background Images"\
                -width 20
        } {}
    

        $itk_component(q315CollectBackground) addInput "::device::collectFrame status inactive {Collecting frame of data.}"
        $itk_component(q315CollectBackground) addInput "::device::q315_collect_background status inactive {supporting device}"

	    grid $itk_component(canvas) -row 0 -column 0 -sticky news 
	    grid $itk_component(q315CollectBackground) -row 1 -column 0 
    }

	constructor { mainWidget_  args } {

        set _mainWidget $mainWidget_
		set _detectorObject [DCS::Detector::getObject]

        constructWidgets


        eval itk_initialize $args
        announceExist
    }



    public method q315CollectBackground {} {
	    global env
        set deviceFactory [DCS::DeviceFactory::getObject]

        set q315CollectBackgroundOp [$deviceFactory createOperation q315_collect_background]

        set directory [$_mainWidget getDirectory]
        set new_directory [TrimStringForRootDirectoryName $directory]
        if {$new_directory != $directory} {
            log_error directory changed from $directory to $new_directory
            $_mainWidget setDirectory $new_directory
            set directory $new_directory
        }

        set user [$itk_option(-controlSystem) getUser]
        global gEncryptSID
        if {$gEncryptSID} {
            set sessionId SID
        } else {
            set sessionId PRIVATE[$itk_option(-controlSystem) getSessionId]
        }
        $q315CollectBackgroundOp startOperation $directory $user $sessionId 0
    }


}

class DCS::PilatusSpecificControl {
    inherit ::itk::Widget DCS::Component
    private variable m_detectorStatusObj
    private variable m_deviceFactory

    public method constructWidgets {} {
	    # draw and label the detector
	    global BLC_IMAGES
        set ring $itk_interior

		itk_component add canvas {
			canvas $ring.c -width 150 -height 150
		}

		itk_component add diskUseDial {
			canvas $ring.du -width 100 -height 75
		}

		itk_component add powerBoardTxt {
			label $ring.pb -text "Power Board"
		}
		itk_component add basePlateTxt {
			label $ring.bp -text "Base Plate"
		}
		itk_component add detectorHeadTxt {
			label $ring.dh -text "Detector Head"
		}
		itk_component add tempTxt {
			label $ring.tt -text "Temperature"
		}
		itk_component add humidTxt {
			label $ring.ht -text "Humidity"
		}

        
		itk_component add temp0 {
			label $ring.t0 -text "XX.X C"
		}
		itk_component add temp1 {
			label $ring.t1 -text "XX.X C"
		}
		itk_component add temp2 {
			label $ring.t2 -text "XX.X C"
		}
		itk_component add humid0 {
			label $ring.h0 -text "XX.X %"
		}
		itk_component add humid1 {
			label $ring.h1 -text "XX.X %"
		}
		itk_component add humid2 {
			label $ring.h2 -text "XX.X %"
		}

		set detectorImage [ image create photo \
											-file "$BLC_IMAGES/pilatus6.gif" \
											-palette "255/255/255"]

		$itk_component(canvas) create image 0 0 \
			 -anchor nw \
			 -image $detectorImage -tag detectorItems 

        itk_component add setThreshold {
            DCS::Button $ring.setthresh -command "$this detectorSetThreshold" \
                -text "Set Threshold"\
                -width 20 
        } {}

        itk_component add gain {
            DCS::MenuEntry $ring.gain \
                -promptText "gain:" \
                -entryWidth 10 \
			    -showEntry 0 \
                -entryType field \
                -systemIdleOnly 0 \
                -activeClientOnly 0 
        } {}

        $itk_component(gain) configure -menuChoices "lowg Midg Highg Uhighg"
        $itk_component(gain) setValue "lowg"


        itk_component add threshold {
            DCS::Entry $ring.threshold \
                -promptText "Threshold: " -promptWidth 12 -units "eV" \
                -entryType positiveFloat \
                -entryJustify right \
                -entryWidth 10 	\
                -decimalPlaces 2 \
                -systemIdleOnly 0 \
                -activeClientOnly 0
        } {}
        $itk_component(threshold) setValue [list 6329 eV]


        $itk_component(setThreshold) addInput "::device::detectorSetThreshold status inactive {Setting threshold.}"
        $itk_component(setThreshold) addInput "::device::collectFrame status inactive {Collecting frame of data.}"

        $itk_component(diskUseDial) create oval 2 2 48 48 -tags t1 -fill #c0c0ff -outline ""
        $itk_component(diskUseDial) create arc 2 2 48 48 -tags t2 -fill red -extent 0 -outline ""
        $itk_component(diskUseDial) create text 25 25 -tags t3
        $itk_component(diskUseDial) create text 25 55 -text "Disk use"
        
	    grid $itk_component(canvas) -row 0 -column 1 -sticky news 
	    grid $itk_component(diskUseDial) -row 0 -column 2 -sticky news 
	    grid $itk_component(tempTxt) -row 1 -column 1 -sticky news
	    grid $itk_component(humidTxt) -row 1 -column 2 -sticky news 
	    grid $itk_component(powerBoardTxt) -row 2 -column 0 -sticky e 
	    grid $itk_component(basePlateTxt) -row 3 -column 0 -sticky e 
	    grid $itk_component(detectorHeadTxt) -row 4 -column 0 -sticky e 
	    grid $itk_component(temp0) -row 2 -column 1 -sticky news 
	    grid $itk_component(temp1) -row 3 -column 1 -sticky news 
	    grid $itk_component(temp2) -row 4 -column 1 -sticky news 
	    grid $itk_component(humid0) -row 2 -column 2 -sticky news 
	    grid $itk_component(humid1) -row 3 -column 2 -sticky news 
	    grid $itk_component(humid2) -row 4 -column 2 -sticky news 
	    grid $itk_component(gain) -row 5 -column 0 -sticky news 
	    grid $itk_component(setThreshold) -row 5 -column 2 -sticky news 
	    grid $itk_component(threshold) -row 5 -column 1 -sticky news 
        

    }

	constructor {  args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
		set _detectorObject [DCS::Detector::getObject]
    

        constructWidgets

        set obj [namespace current]::[DCS::DetectorStatusParams \#auto detectorStatus]
        set m_detectorStatusObj $obj
        ::mediator register $this $m_detectorStatusObj temp0 changeTemp0
        ::mediator register $this $m_detectorStatusObj temp1 changeTemp1
        ::mediator register $this $m_detectorStatusObj temp2 changeTemp2
        ::mediator register $this $m_detectorStatusObj humid0 changeHumid0
        ::mediator register $this $m_detectorStatusObj humid1 changeHumid1
        ::mediator register $this $m_detectorStatusObj humid2 changeHumid2
        ::mediator register $this $m_detectorStatusObj diskUsePercent changeDiskUsePercent

 
        eval itk_initialize $args
        announceExist
	}

	destructor {
	}

    public method changeTemp0 { - targetReady_ - x - } {
	    $itk_component(temp0) configure -text "$x C"
    }
    public method changeTemp1 { - targetReady_ - x - } {
	    $itk_component(temp1) configure -text "$x C"
    }
    public method changeTemp2 { - targetReady_ - x - } {
	    $itk_component(temp2) configure -text "$x C"
    }
    public method changeHumid0 { - targetReady_ - x - } {
	    $itk_component(humid0) configure -text "$x %"
    }
    public method changeHumid1 { - targetReady_ - x - } {
	    $itk_component(humid1) configure -text "$x %"
    }
    public method changeHumid2 { - targetReady_ - x - } {
	    $itk_component(humid2) configure -text "$x %"
    }

    public method changeDiskUsePercent { - targetReady_ - x - } {
        set percent $x
	    $itk_component(diskUseDial) itemconfig t3 -text "$x %"
        $itk_component(diskUseDial) itemconfig t2 -extent [expr {round($percent * 3.6)}]

    }

    public method detectorSetThreshold {} {
        puts "detectorSetThreshold"
        set setThresholdOp [$m_deviceFactory createOperation detectorSetThreshold]
        set threshold [lindex [$itk_component(threshold) get] 0]
        set gain [$itk_component(gain) get]
        $setThresholdOp startOperation $gain $threshold  
    }

}


class DCS::DetectorControl {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
	itk_option define -detectorType detectorType DetectorType null 

	# protected methods
	protected method constructControlPanel
	public method collectFrame
	public method handleDetectorTypeChange

    public method getDirectory {} {
        return [$itk_component(directory) get]
    }

    public method setDirectory {val} {
        $itk_component(directory) setValue $val
    }


    private variable m_deviceFactory
	private variable _detectorObject

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
		set _detectorObject [DCS::Detector::getObject]

		# construct the parameter widgets
		constructControlPanel


        eval itk_initialize $args
        ::mediator register $this ::$_detectorObject type handleDetectorTypeChange
		::mediator announceExistence $this
	}

	destructor {
	}

}

body DCS::DetectorControl::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	if { ! $targetReady_} return

    #itk_component remove detectorSpecific
    switch $type_  {

        PILATUS6 {
            destroy $itk_component(detectorSpecific)
            # make a frame for detectorSpecific stuff
            itk_component add detectorSpecific {
                DCS::PilatusSpecificControl $itk_interior.ds 
            } {}

	        grid $itk_component(detectorSpecific) -row 0 -column 3 -rowspan 7 -sticky s
        }
        Q315CCD {
            destroy $itk_component(detectorSpecific)
            itk_component add detectorSpecific {
                DCS::Q315SpecificControl $itk_interior.ds $this
            } {}

	        grid $itk_component(detectorSpecific) -row 0 -column 3 -rowspan 7 -sticky s
        }
        default {
            destroy $itk_component(detectorSpecific)
            itk_component add detectorSpecific {
                frame $itk_interior.ds 
            } {}
        }
    }
}




body DCS::DetectorControl::constructControlPanel { } {

    global env

    set ring $itk_interior

    itk_component add collect {
        DCS::Button $ring.c -command "$this collectFrame" \
            -text "Collect New Image"\
            -width 20
    } {}

    itk_component add detectorSpecific {
        frame $ring.ds 
    } {}

	# make the filename root entry
    itk_component add filename {
        DCS::Entry $ring.filename \
            -entryType field \
            -entryWidth 20 \
            -entryJustify center \
            -entryMaxLength 128 \
            -promptText "Prefix: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}

    $itk_component(filename) setValue "test"

    # make the data directory entry
    itk_component add directory {
        DCS::Entry $ring.dir \
            -entryType field \
            -entryWidth 40 \
            -entryJustify center \
            -entryMaxLength 128 \
            -promptText "Directory: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}

    $itk_component(directory) setValue "/data/$env(USER)"


    itk_component add exposureTime {
        DCS::Entry $ring.time \
            -promptText "Time: " -promptWidth 12 -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 10 	\
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}
		
    $itk_component(exposureTime) setValue [list 1.0 s]

    # make the width entry
    itk_component add delta {
        DCS::Entry $ring.delta -promptText "Delta: " \
            -promptWidth 12 \
            -entryWidth 10 	\
            -entryType positiveFloat \
            -entryJustify right \
            -decimalPlaces 2 \
            -units "deg" \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 
    } {}

    $itk_component(delta) setValue 1.0

    itk_component add shutter {
        DCS::MenuEntry $ring.shutter \
            -promptText "shutter:" \
            -entryWidth 10 \
			-showEntry 0 \
            -entryType field \
            -systemIdleOnly 0 \
            -activeClientOnly 0 
    } {}

    $itk_component(shutter) configure -menuChoices "shutter NULL"
    $itk_component(shutter) setValue "shutter"


    # make oscillation axis combo box
    itk_component add axis {
        DCS::MenuEntry $ring.axis \
            -entryWidth 10 	\
            -entryType string \
            -entryJustify center \
            -promptText "Axis: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -showEntry 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 
    } {}

	$itk_component(axis) configure -menuChoices "gonio_phi gonio_omega NULL"
	$itk_component(axis) setValue "gonio_phi"

    # make the detector mode entry
    itk_component add mode {
        DCS::DetectorModeMenu $ring.dm -entryWidth 19 \
            -promptText "Mode: " \
            -promptWidth 12 \
            -showEntry 0 \
            -entryType string \
            -entryJustify center \
            -promptText "Detector: " \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 
    } {
        keep -font
    }

    $itk_component(collect) addInput "::device::collectFrame status inactive {Collecting frame of data.}"


	grid $itk_component(directory) -row 0 -column 0 -columnspan 2 -sticky w

	grid $itk_component(filename) -row 1 -column 0 -sticky nsw
	grid $itk_component(mode) -row 1 -column 1 -sticky nsw

	grid $itk_component(shutter) -row 2 -column 0 -sticky nse
	grid $itk_component(exposureTime) -row 2 -column 1 -sticky nsw

	grid $itk_component(axis) -row 3 -column 0 -sticky nse
	grid $itk_component(delta) -row 3 -column 1 -sticky nsw

	grid $itk_component(collect) -row 5 -column 0 -columnspan 2

	grid $itk_component(detectorSpecific) -row 0 -column 2 -rowspan 5 -sticky w
}

body DCS::DetectorControl::collectFrame {} {
	global env

    set collectFrameOp [$m_deviceFactory createOperation collectFrame]

    set filename [$itk_component(filename) get][clock format [clock seconds] -format "%H_%M_%S"]

    set directory [$itk_component(directory) get]

    set new_filename  [TrimStringForCrystalID $filename]
    set new_directory [TrimStringForRootDirectoryName $directory]
    if {$new_filename != $filename} {
        log_error filename changed from $filename to $new_filename
        $itk_component(filename) setValue $new_filename
        set filename $new_filename
    }
    if {$new_directory != $directory} {
        log_error directory changed from $directory to $new_directory
        $itk_component(directory) setValue $new_directory
        set directory $new_directory
    }

    set user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set sessionId SID
    } else {
        set sessionId PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    set axis [$itk_component(axis) get]
    set shutter [$itk_component(shutter) get]
    set delta [lindex [$itk_component(delta) get] 0]
    set time [lindex [$itk_component(exposureTime) get] 0]
    set modeIndex [$itk_component(mode) selectDetectorMode] 

    set darkCacheIndex 15
    set reuseDark 0
    set flush 1

    $collectFrameOp startOperation $darkCacheIndex $filename $directory $user $axis $shutter $delta $time $modeIndex $flush $reuseDark $sessionId
}


class DCS::DetectorControlXPP {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
	itk_option define -detectorType detectorType DetectorType null 

	# protected methods
	protected method constructControlPanel
	public method collectFrame
	public method handleDetectorTypeChange

    public method getDirectory {} {
        return [$itk_component(directory) get]
    }

    public method setDirectory {val} {
        $itk_component(directory) setValue $val
    }


    private variable m_deviceFactory
	private variable _detectorObject

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
		set _detectorObject [DCS::Detector::getObject]

		# construct the parameter widgets
		constructControlPanel


        eval itk_initialize $args
        ::mediator register $this ::$_detectorObject type handleDetectorTypeChange
		::mediator announceExistence $this
	}

	destructor {
	}

}

body DCS::DetectorControlXPP::handleDetectorTypeChange { detector_ targetReady_ alias_ type_ -  } {
	if { ! $targetReady_} return

    #itk_component remove detectorSpecific
    switch $type_  {

        PILATUS6 {
            destroy $itk_component(detectorSpecific)
            # make a frame for detectorSpecific stuff
            itk_component add detectorSpecific {
                DCS::PilatusSpecificControl $itk_interior.ds 
            } {}

	        grid $itk_component(detectorSpecific) -row 0 -column 3 -rowspan 7 -sticky s
        }
        Q315CCD {
            destroy $itk_component(detectorSpecific)
            itk_component add detectorSpecific {
                DCS::Q315SpecificControl $itk_interior.ds $this
            } {}

	        grid $itk_component(detectorSpecific) -row 0 -column 3 -rowspan 7 -sticky s
        }
        default {
            destroy $itk_component(detectorSpecific)
            itk_component add detectorSpecific {
                frame $itk_interior.ds 
            } {}
        }
    }
}




body DCS::DetectorControlXPP::constructControlPanel { } {

    global env

    set ring $itk_interior

    itk_component add collect {
        DCS::Button $ring.c -command "$this collectFrame" \
            -text "Collect New Image"\
            -width 20
    } {}

    itk_component add detectorSpecific {
        frame $ring.ds 
    } {}

	# make the filename root entry
    itk_component add filename {
        DCS::Entry $ring.filename \
            -entryType field \
            -entryWidth 20 \
            -entryJustify center \
            -entryMaxLength 128 \
            -promptText "Prefix: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}

    $itk_component(filename) setValue "test"

    # make the data directory entry
    itk_component add directory {
        DCS::Entry $ring.dir \
            -entryType field \
            -entryWidth 40 \
            -entryJustify center \
            -entryMaxLength 128 \
            -promptText "Directory: " \
            -promptWidth 12 \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}

    $itk_component(directory) setValue "/data/$env(USER)"


    itk_component add exposureTime {
        DCS::Entry $ring.time \
            -promptText "Time: " -promptWidth 12 -units "s" \
            -entryType positiveFloat \
            -entryJustify right \
            -entryWidth 10 	\
            -decimalPlaces 2 \
            -systemIdleOnly 0 \
            -activeClientOnly 0
    } {}
		
    $itk_component(exposureTime) setValue [list 1.0 s]

    # make the detector mode entry
    itk_component add mode {
        DCS::DetectorModeMenu $ring.dm -entryWidth 19 \
            -promptText "Mode: " \
            -promptWidth 12 \
            -showEntry 0 \
            -entryType string \
            -entryJustify center \
            -promptText "Detector: " \
            -shadowReference 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 
    } {
        keep -font
    }

    $itk_component(collect) addInput "::device::collectFrameXPP status inactive {Collecting frame of data.}"


	grid $itk_component(directory) -row 0 -column 0 -columnspan 2 -sticky w

	grid $itk_component(filename) -row 1 -column 0 -sticky nsw
	grid $itk_component(mode) -row 1 -column 1 -sticky nsw

	grid $itk_component(exposureTime) -row 2 -column 1 -sticky nsw

	grid $itk_component(collect) -row 5 -column 0 -columnspan 2

	grid $itk_component(detectorSpecific) -row 0 -column 2 -rowspan 5 -sticky w
}

body DCS::DetectorControlXPP::collectFrame {} {
	global env

    set collectFrameOp [$m_deviceFactory createOperation collectFrameXPP]

    set filename [$itk_component(filename) get][clock format [clock seconds] -format "%H_%M_%S"]

    set directory [$itk_component(directory) get]

    set new_filename  [TrimStringForCrystalID $filename]
    set new_directory [TrimStringForRootDirectoryName $directory]
    if {$new_filename != $filename} {
        log_error filename changed from $filename to $new_filename
        $itk_component(filename) setValue $new_filename
        set filename $new_filename
    }
    if {$new_directory != $directory} {
        log_error directory changed from $directory to $new_directory
        $itk_component(directory) setValue $new_directory
        set directory $new_directory
    }

    set user [$itk_option(-controlSystem) getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set sessionId SID
    } else {
        set sessionId PRIVATE[$itk_option(-controlSystem) getSessionId]
    }
    set time [lindex [$itk_component(exposureTime) get] 0]
    set modeIndex [$itk_component(mode) selectDetectorMode] 

    set darkCacheIndex 15
    set reuseDark 0
    set flush 1
    set axis NULL
    set shutter NULL
    set delta 0.0

    $collectFrameOp startOperation $darkCacheIndex $filename $directory $user $axis $shutter $delta $time $modeIndex $flush $reuseDark $sessionId
}


