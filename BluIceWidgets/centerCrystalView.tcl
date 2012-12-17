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

package require Itcl
package require Iwidgets
package require BWidget

package provide BLUICECenterCrystalView 1.0

# load the DCS packages
package require DCSString
package require DCSDeviceLog
package require DCSButton
package require DCSDeviceFactory

class centerCrystalView {
 	inherit ::itk::Widget
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        set showCollimatorConfig 0
        set deviceFactory [DCS::DeviceFactory::getObject]
        if {[$deviceFactory motorExists collimator_horz]} {
            set showCollimatorConfig 1
        }

        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        #create all of the pages
        set RunSite [$itk_component(notebook) add -label "Run"]
        set ConfigSite [$itk_component(notebook) add -label "Config"]
        if {$showCollimatorConfig} {
            set CollimatorConfigSite \
            [$itk_component(notebook) add -label "Collimator Config"]
        }
        $itk_component(notebook) view 0

        itk_component add run {
            centerCrystalRunView $RunSite.run
        } {
            keep -mdiHelper
        }
        itk_component add config {
            DCS::CenterCrystalConfigView $ConfigSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
            keep -mdiHelper
        }

        if {$showCollimatorConfig} {
            itk_component add collimator_config {
                DCS::CenterCrystalConfigView $CollimatorConfigSite.config \
                -showCollimator 1 \
                -stringName ::device::collimator_center_crystal_const \
                -systemIdleOnly 0 \
                -activeClientOnly 0
            } {
                keep -mdiHelper
            }
        }

        eval itk_initialize $args

        pack $itk_component(run) -expand yes -fill both
        pack $itk_component(config) -side top -expand 0 -fill x
        if {$showCollimatorConfig} {
            pack $itk_component(collimator_config) -side top -expand 0 -fill x
        }
        pack $itk_component(notebook) -expand 1 -fill both
    }
}

class centerCrystalRunView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method startOperation { use_collimator }

    private method constructControlPanel { ring }

    private variable m_deviceFactory
    private variable m_operation
    private variable m_logger

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_operation [$m_deviceFactory createOperation centerCrystal]
        set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel $itk_interior

        eval itk_initialize $args

	}
}



body centerCrystalRunView::constructControlPanel { ring } {

    itk_component add start {
        DCS::Button $ring.c -command "$this startOperation 0" \
        -text "Start Crystal Centering"\
        -width 30
    } {}

    itk_component add start_micro {
        DCS::Button $ring.mc -command "$this startOperation 1" \
        -text "Start MicroCrystal Centering"\
        -width 30
    } {}

	# make the filename root entry
    itk_component add fileRoot {
        DCS::Entry $ring.filename \
        -entryType field \
        -entryWidth 20 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Prefix: " \
        -promptWidth 12 \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
    } {}

    itk_component add candidates {
        listbox $ring.lb
    } {
    }
    # make the data directory entry
    itk_component add directory {
        DCS::DirectoryEntry $ring.dir \
        -entryType rootDirectory \
        -entryWidth 60 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Directory: " \
        -promptWidth 12 \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
    } {}

    set user [::dcss getUser]

    $itk_component(directory) setValue "/data/$user"

    itk_component add log {
        DCS::DeviceLog $ring.l
    } {
    }
    #$itk_component(log) addDeviceObjs $m_operation
    $itk_component(log) addOperations centerCrystal scan3DSetup manualRastering

	pack $itk_component(directory) -side top
	pack $itk_component(fileRoot) -side top
	pack $itk_component(start) -side top
	pack $itk_component(start_micro) -side top
    pack $itk_component(log) -side top -expand 1 -fill both
}

body centerCrystalRunView::startOperation { use_collimator } {
	global env

    set rootDir [$itk_component(directory) get]
    
    if { [catch {file mkdir $rootDir} err] } {
        
        set msg "$env(USER) could not create directory $rootDir: $err"
        $m_logger logError $msg
        return
    }
        
    if { [file isdirectory $rootDir]==0 || [file writable $rootDir]==0 } {
        $m_logger logError "$env(USER) does not have permission to write to $rootDir."
        return
    }
    set filePrefix [$itk_component(fileRoot) get]
    
    set user [::dcss getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }

    if {$use_collimator} {
        $m_operation startOperation $user $SID $rootDir $filePrefix \
        use_collimator_constant
    } else {
        $m_operation startOperation $user $SID $rootDir $filePrefix
    }
}
#####################################################################
#####################################################################
#####################################################################
#####################################################################
#####################################################################
class nameValueView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -width width Width 10

    itk_option define -nameString nameString NameString ""
    itk_option define -valueString valueString ValueString ""

    public method handleNameChange
    public method handleValueChange

    private variable m_deviceFactory

    private variable m_currentNameString ""
    private variable m_currentValueString ""
    private variable MAX_ITEM 60
    private variable m_numItemShow 0

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        itk_component add sf {
            iwidgets::scrolledframe $itk_interior.sf \
            -vscrollmode static
        } {
        }
        set root_frame [$itk_component(sf) childsite]
        ##########create all items
        for {set i 0} {$i < $MAX_ITEM} {incr i} {
            itk_component add item$i {
                DCS::Entryfield $root_frame.item$i \
                -labelpos w \
                -offset $i
            } {
                keep -systemIdleOnly
                keep -activeClientOnly
                keep -width
            }
        }


        pack $itk_component(sf) -expand 1 -fill both
        eval itk_initialize $args
    }
}
configbody nameValueView::nameString {
    set newNameString $itk_option(-nameString)

    if {$newNameString != "" && $m_currentNameString != $newNameString} {
        puts "set name string to $newNameString"
        ##### unregister current one
        if {$m_currentNameString != ""} {
            set StrObj [$m_deviceFactory createString $m_currentNameString]
		    $StrObj unregister $this contents handleNameChange
        }

        ########### register new one
        set StrObj [$m_deviceFactory createString $newNameString]
        puts "register name change"
		$StrObj register $this contents handleNameChange

        ########### save ##############
        set m_currentNameString $newNameString
    }
}
configbody nameValueView::valueString {
    set newValueString $itk_option(-valueString)

    if {$newValueString != "" && $m_currentValueString != $newValueString} {
        puts "set value string to $newValueString"
        for {set i 0} {$i < $MAX_ITEM} {incr i} {
            $itk_component(item$i) configure \
            -stringName $newValueString
        }

        set m_currentValueString $newValueString
    }
}
body nameValueView::handleNameChange { name_ ready_ alias_ contents_ - } {
    if {!$ready_}  return

    puts "handleNameChange: $contents_"

    set ll [llength $contents_]
    if {$ll > $MAX_ITEM} {
        set ll $MAX_ITEM
        puts "reduced list to $ll"
    }

    #### update labels
    for {set i 0} {$i < $ll} {incr i} {
        set labeltext [lindex $contents_ $i]
        $itk_component(item$i) configure \
        -labeltext $labeltext
        #puts "update item $i label to $labeltext"
    }

    #### adjust display #####
    if {$ll > $m_numItemShow} {
        for {set i $m_numItemShow} {$i < $ll} {incr i} {
            grid $itk_component(item$i) -row $i -sticky w
            #puts "show item $i"
        }
    } elseif {$ll < $m_numItemShow} {
        for {set i $ll} {$i < $m_numItemShow} {incr i} {
            grid forget $itk_component(item$i)
            #puts "hide item $i"
        }
    }
    set m_numItemShow $ll

    ########### adjust label width
    set label_list [list]
    for {set i 0} {$i < $m_numItemShow} {incr i} {
        lappend label_list [$itk_component(item$i) getEntryfield]
    }
    eval iwidgets::Labeledwidget::alignlabels $label_list
}
class burnPaperView {
 	inherit ::itk::Widget
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        #create all of the pages
        set RunSite [$itk_component(notebook) add -label "Run"]
        set ConfigSite [$itk_component(notebook) add -label "Config"]
        $itk_component(notebook) view 0

        itk_component add run {
            burnPaperRunView $RunSite.run
        } {
            keep -mdiHelper
        }
        itk_component add config {
            nameValueView $ConfigSite.config \
            -nameString burn_paper_constant_name_list \
            -valueString burn_paper_constant
        } {
            keep -mdiHelper
        }

        eval itk_initialize $args

        pack $itk_component(run) -expand yes -fill both
        pack $itk_component(config) -expand yes -fill both
        pack $itk_component(notebook) -expand 1 -fill both
    }
}
class burnPaperRunView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method startOperation

    private method constructControlPanel { ring }

    private variable m_deviceFactory
    private variable m_operation
    private variable m_logger

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_operation [$m_deviceFactory createOperation burnPaper]
        set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel $itk_interior

        eval itk_initialize $args
	}
}
body burnPaperRunView::constructControlPanel { ring } {

    itk_component add start {
        DCS::Button $ring.c -command "$this startOperation" \
        -text "Start Burn Paper"\
        -width 30
    } {}
    itk_component add cx {
        iwidgets::checkbox $ring.cx
    } {
    }

    $itk_component(cx) add b0 -text "clear log for each operation"

    itk_component add log {
        DCS::DeviceLog $ring.l
    } {
    }
    $itk_component(log) addDeviceObjs $m_operation

	pack $itk_component(start) -side top
	pack $itk_component(cx) -side top
    pack $itk_component(log) -side top -expand 1 -fill both
}

body burnPaperRunView::startOperation {} {
    $m_operation startOperation
}

class centerSlitsView {
 	inherit ::itk::Widget
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    constructor { args } {
        itk_component add notebook {
            iwidgets::Tabnotebook $itk_interior.nb -tabpos n -height 400
        } {
        }
        #create all of the pages
        set RunSite [$itk_component(notebook) add -label "Run"]
        set ConfigSite [$itk_component(notebook) add -label "Config"]
        set DataSite [$itk_component(notebook) add -label "Data"]
        $itk_component(notebook) view 0

        itk_component add run {
            centerSlitsRunView $RunSite.run
        } {
            keep -mdiHelper
        }
        itk_component add config {
            nameValueView $ConfigSite.config \
            -nameString center_slits_constant_name_list \
            -valueString center_slits_const
        } {
            keep -mdiHelper
        }
        itk_component add data {
            nameValueView $DataSite.data \
            -width 80 \
            -nameString center_slits_data_name_list \
            -valueString center_slits_data
        } {
            keep -mdiHelper
        }

        eval itk_initialize $args

        pack $itk_component(run) -expand yes -fill both
        pack $itk_component(config) -expand yes -fill both
        pack $itk_component(data) -expand yes -fill both
        pack $itk_component(notebook) -expand 1 -fill both
    }
}

class centerSlitsRunView {
 	inherit ::itk::Widget

    itk_option define -controlSystem controlsytem ControlSystem ::dcss
    itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method startOperation

    private method constructControlPanel { ring }

    private variable m_deviceFactory
    private variable m_operation
    private variable m_logger

	constructor { args } {

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_operation [$m_deviceFactory createOperation centerSlits]
        set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructControlPanel $itk_interior

        eval itk_initialize $args

	}
}



body centerSlitsRunView::constructControlPanel { ring } {

    itk_component add start {
        DCS::Button $ring.c -command "$this startOperation" \
        -text "Start Slits Centering"\
        -width 30
    } {}

	# make the filename root entry
    itk_component add fileRoot {
        DCS::Entry $ring.filename \
        -entryType field \
        -entryWidth 20 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Prefix: " \
        -promptWidth 12 \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
    } {}

    # make the data directory entry
    itk_component add directory {
        DCS::Entry $ring.dir \
        -entryType field \
        -entryWidth 60 \
        -entryJustify center \
        -entryMaxLength 128 \
        -promptText "Directory: " \
        -promptWidth 12 \
        -shadowReference 0 \
        -systemIdleOnly 1 \
        -activeClientOnly 1 \
    } {}
    set user [::dcss getUser]

    $itk_component(directory) setValue "/data/$user"

    itk_component add log {
        DCS::DeviceLog $ring.l
    } {
    }
    $itk_component(log) addDeviceObjs $m_operation

	pack $itk_component(directory) -side top
	pack $itk_component(fileRoot) -side top
	pack $itk_component(start) -side top
    pack $itk_component(log) -side top -expand 1 -fill both
}

body centerSlitsRunView::startOperation {} {
	global env

    set rootDir [$itk_component(directory) get]
    
    if { [catch {file mkdir $rootDir} err] } {
        
        set msg "$env(USER) could not create directory $rootDir: $err"
        $m_logger logError $msg
        return
    }
        
    if { [file isdirectory $rootDir]==0 || [file writable $rootDir]==0 } {
        $m_logger logError "$env(USER) does not have permission to write to $rootDir."
        return
    }
    set filePrefix [$itk_component(fileRoot) get]
    
    set user [::dcss getUser]
    global gEncryptSID
    if {$gEncryptSID} {
        set SID SID
    } else {
        set SID PRIVATE[::dcss getSessionId]
    }

    $m_operation startOperation $user $SID $rootDir $filePrefix
}
