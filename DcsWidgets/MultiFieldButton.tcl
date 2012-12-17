#####################################################################
# FILENAME: MultiFieldButton.tcl                                         #
# CREATED:  8/14/06                                                 #
# AUTHOR:   John O'Keefe                                            #
# EMAIL:	jmokeefe@slac.stanford.edu; MavSoccer1417@yahoo.com #
#               jmokeefe@cs.ucsb.edu                                #
# DESCRIPTION:                                                      #
# History:                                                          #
#                                                                   #
# DATE      BY   Ver.   REVISION                                    #
# ----      --   ----   --------                                    #
# 08/16/05  JMO  1.00   CREATION                                    #
#####################################################################


package provide MultiFieldButton 1.0

#################################################
# class MultiFieldButton is a check button that 	#
# when clicked send a string of values to 	#
# the command it is given.  This string of 	#
# values is taken from the stringMonitor	#
# which is the string that it is monitoring	#
#################################################
class ::DCS::MultiFieldButton {
#    inherit ::itk::Widget ::DCS::ComponentGate
    inherit ::DCS::ComponentGateExtension
    itk_option define -mdiHelper mdiHelper MdiHelper ""
    itk_option define -stringName stringName StringName ""
    itk_option define -indexList indexList IndexList {}
    itk_option define -command command Command ""
    

    #constructor/destructor
    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        itk_component add checkB {
            DCS::Checkbutton $itk_interior.checkB -command "$this doCommand %s"
        } {
            keep -text -font -width -height -state -activebackground
            keep -background -relief -selectcolor -foreground -activeforeground
            keep -highlightthickness -highlightbackground -highlightcolor
            keep -trigger -systemIdleOnly -controlSystem -state -activeClientOnly
            keep -matchColor -reference -shadowReference -disabledforeground
        }
        pack $itk_component(checkB)
        eval itk_initialize $args
        update
    }
    destructor {
        if {$_lastStringName != ""} {
            set StrObj [$m_deviceFactory createString $_lastStringName]
            $StrObj unregister $this contents handleStringConfigure
        }
    }

    #public methods
    public method doCommand
    public method handleStringConfigure {name_ ready_ alias_ contents_ -}

    #private methods
    private method setVals {val}
    private method update {}

    #variables
    private variable _lastStringName ""
    private variable m_deviceFactory
    private variable _strContents ""
    private variable _depressed ""
}

configbody DCS::MultiFieldButton::stringName {
    set stringName $itk_option(-stringName)
    if { $stringName != "" && $stringName != $_lastStringName } {
        #unregister
        if {$_lastStringName != ""} {
            set StrObj [$m_deviceFactory createString $_lastStringName]
            $StrObj unregister $this contents handleStringConfigure
            deleteInput $StrObj status
        }
        set StrObj [$m_deviceFactory createString $stringName]
        $StrObj register $this contents handleStringConfigure
        addInput "$StrObj status inactive {supporting device}"
        # store the name of the device for next time
        set _lastStringName $stringName
    }
}
configbody DCS::MultiFieldButton::indexList {
    foreach {index} $itk_option(-indexList) {
        if {[string is integer -strict $index]} {
        } else {
            puts "wrong format of indexList. List must be integers"
        }
    }
}
body ::DCS::MultiFieldButton::doCommand {val} {
    setVals $val
    $itk_component(checkB)  setValue $_depressed
}

#################################
# handkeStringConfigure is what	#
# blu ice calls when there is	#
# a new string if the contents	#
# are new then it is taken as a	#
# new string			#
#################################
body DCS::MultiFieldButton::handleStringConfigure { name_ ready_ alias_ contents_ - } {
    if { ! $ready_} {
        return
    }
    if { $_strContents != $contents_} {
        set _strContents $contents_
        update
        if {$itk_option(-command) != ""} {
            set fullCommand "[replace%sInCommandWithValue $itk_option(-command) $_strContents] $_depressed"
            eval $fullCommand
        }
    }
}

#################################
# update: if all items in item	#
# list are 1 then it sets the 	#
# button to be selected	else	#
# it deselects the button	#
# this is called by 		#
# handleString configure which	#
# is called whenever the string	#
# is updated			#
#################################
body DCS::MultiFieldButton::update {} {
    if {$itk_option(-indexList) == ""} {
        return
    }
    set allTrue 1
    foreach {index} $itk_option(-indexList) {
        if {[lindex $_strContents $index] == 0} {
            set allTrue 0
        }
    }
    #if indexList is all 1's then set clicked
    #else set unclicked
    if {$allTrue == 1} {
        $itk_component(checkB)  setValue 1
        set _depressed 1
    } else {
        $itk_component(checkB)  setValue 0
        set _depressed 0
    }
}

#################################
# setVals: sets all items in    #
# indexList to val. This method #
# is called when the button     #
# is selected or unselected     #
#################################
body DCS::MultiFieldButton::setVals {val} {
    set StrObj [$m_deviceFactory createString $_lastStringName]
    set text [eval $StrObj getContents]
    set textList [eval list $text]
    foreach {index} $itk_option(-indexList) {
        set textList [lreplace $textList $index $index $val]
    }
    $StrObj sendContentsToServer $textList
}
