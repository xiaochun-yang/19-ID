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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################


# provide the DCSDevice package
package provide DCSStringView 1.0

package require DCSComponent
package require DCSDeviceFactory
package require DCSCollimatorMenu
package require DCSScrolledFrame

# load standard packages
package require Iwidgets
package require ComponentGateExtension

class DCS::StringViewBase {
	# inheritance
#	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -stringName stringName StringName ""

	itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method handleStringConfigure
	public method applyChanges
	public method cancelChanges

    ###derived classes need to implement following methods
	protected method setContents
	protected method getNewContents

    ####derived classes may implement following methods
    ###called in applyChanges
    ###cannot send if it return 0
    protected method checkContentsBeforeSend { contentsREF } {
        return 1
    }

	protected variable _lastStringName ""

    protected variable m_site

	# call base class constructor
	constructor { args } {} {
        itk_component add site {
            frame $itk_interior.site
        } {
        }
        set m_site $itk_component(site)

		# create the apply button
		itk_component add apply {
			button $itk_interior.apply \
			-text "Apply" \
			-command "$this applyChanges" \
		} {
			keep -font -width -height
			keep -activeforeground -foreground -relief
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

		# create the cancel button
		itk_component add cancel {
			button $itk_interior.cancel \
				 -text "Cancel" \
				 -command "$this cancelChanges" \
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

		grid rowconfigure $itk_interior 0 -weight 1
		grid rowconfigure $itk_interior 1 -weight 0
		grid columnconfigure $itk_interior 0 -weight 1
		grid columnconfigure $itk_interior 1 -weight 1

		grid $itk_component(site) -columnspan 2 -sticky news
		grid $itk_component(apply) -row 1 -column 0 -sticky e
		grid $itk_component(cancel) -row 1 -column 1 -sticky w
		registerComponent $itk_component(apply)
		eval itk_initialize $args
	}
}

configbody DCS::StringViewBase::stringName {
	puts "this variable is $this."
	puts "This is stringName configbody in StringView Base."
	puts "$_lastStringName"
	puts "$itk_option(-stringName)"
    if {$itk_option(-stringName) != $_lastStringName} {
        if {$_lastStringName != ""} {
			puts "$itk_option(-stringName)"
			puts "_lastStringName is $_lastStringName"
			#unregister
			::mediator unregister $this $_lastStringName contents
			deleteInput "$_lastStringName status"
			deleteInput "$_lastStringName permission"
        }
        set _lastStringName $itk_option(-stringName)
	puts "_lastStringNamewas was set to $_lastStringName"
        if {$itk_option(-stringName) != ""} {
            set stringName $itk_option(-stringName)
		puts "stringName was set to $stringName"
		    ::mediator register $this $stringName contents handleStringConfigure
		puts "handleStringConfigure was executed in stringName."
            if {[string first ::device::run $stringName] != 0 \
            && [string first ::device::virtualRun $stringName] \
            && [string first ::device::virtualPosition $stringName] != 0} {
		        addInput "$stringName status inactive {supporting device}"
			puts "last if statement was passed. addInput was $stringName status inactive {supporting device}"
            }
		    addInput "$stringName permission GRANTED PERMISSION"
        }
    }
	#puts "end of method. stringname is $stringName and this is $this"
}


body DCS::StringViewBase::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
#########
   # puts "this is handleStringConfigure method."
	#puts "update string: $stringName_"
	#puts "$contents_"
	if { ! $targetReady_} return
	#puts "arg tagetReady_ is $targetReady_"
	setContents $contents_
}

body DCS::StringViewBase::applyChanges {} {
	set newContents [getNewContents]
	if {![checkContentsBeforeSend newContents]} {
        log_error failed to pass checkContentsBeforeSend
        return
    }
	$_lastStringName sendContentsToServer $newContents
}

body DCS::StringViewBase::cancelChanges {} {
	setContents [$_lastStringName getContents]
}
##################################################################################################
class DCS::StringViewBase2 {
	# inheritance
#	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -stringName stringName StringName ""

	itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method handleStringConfigure
	public method applyChanges
	public method cancelChanges

    ###derived classes need to implement following methods
	protected method setContents
	protected method getNewContents

    ####derived classes may implement following methods
    ###called in applyChanges
    ###cannot send if it return 0
	protected method checkContentsBeforeSend { contentsREF } {
		return 1
	}

	protected variable _lastStringName ""
	protected variable m_site

	# call base class constructor
	constructor { args } {} {
	       itk_component add site {
			frame $itk_interior.site -width 20 -height 20
        } {
        }
	set m_site $itk_component(site)
	grid rowconfigure $itk_interior 0 -weight 1
	grid rowconfigure $itk_interior 1 -weight 0
	grid columnconfigure $itk_interior 0 -weight 1
	grid columnconfigure $itk_interior 1 -weight 1
	grid $itk_component(site) -columnspan 2 -sticky news

	eval itk_initialize $args
	}
}

configbody DCS::StringViewBase2::stringName {
	if {$itk_option(-stringName) != $_lastStringName} {
		if {$_lastStringName != ""} {
			#unregister
			::mediator unregister $this $_lastStringName contents
			deleteInput "$_lastStringName status"
			deleteInput "$_lastStringName permission"
        	}
       	set _lastStringName $itk_option(-stringName)
       	if {$itk_option(-stringName) != ""} {
        		set stringName $itk_option(-stringName)
			::mediator register $this $stringName contents handleStringConfigure
			if {[string first ::device::run $stringName] != 0 \
				&& [string first ::device::virtualRun $stringName] \
				&& [string first ::device::virtualPosition $stringName] != 0} {
		       	addInput "$stringName status inactive {supporting device}"
            		}
		addInput "$stringName permission GRANTED PERMISSION"
        	}
	}
}


body DCS::StringViewBase2::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
    #puts "this is handleStringConfigure method."
	#puts "update string: $stringName_"
	#puts "$contents_"
	if { ! $targetReady_} return
	#puts "arg tagetReady_ is $targetReady_"
	setContents $contents_
}

body DCS::StringViewBase2::applyChanges {} {
	set newContents [getNewContents]
	if {![checkContentsBeforeSend newContents]} {
        log_error failed to pass checkContentsBeforeSend
        return
    }
	$_lastStringName sendContentsToServer $newContents
}

body DCS::StringViewBase2::cancelChanges {} {
	setContents [$_lastStringName getContents]
}
#########################################################################################
##################################################################################################
class DCS::StringViewBase3 {
	# inheritance
#	inherit ::itk::Widget ::DCS::ComponentGate
	inherit ::DCS::ComponentGateExtension
	itk_option define -stringName stringName StringName ""

	itk_option define -mdiHelper mdiHelper MdiHelper ""

	public method handleStringConfigure
	public method applyChanges
	public method cancelChanges

    ###derived classes need to implement following methods
	protected method setContents
	protected method getNewContents

    ####derived classes may implement following methods
    ###called in applyChanges
    ###cannot send if it return 0
	protected method checkContentsBeforeSend { contentsREF } {
		return 1
	}

	protected variable _lastStringName ""
	protected variable m_site

	# call base class constructor
	constructor { args } {} {
	       itk_component add site {
			frame $itk_interior.site -width 20 -height 20
        } {
        }
	set m_site $itk_component(site)

		# create the apply button
		itk_component add apply {
			button $itk_interior.apply \
			-text "Apply" \
			-command "$this applyChanges" \
		} {
			keep -font -width -height
			keep -activeforeground -foreground -relief
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

		# create the cancel button
		itk_component add cancel {
			button $itk_interior.cancel \
				 -text "Cancel" \
				 -command "$this cancelChanges" \
		} {
			keep -font -width -height -state
			keep -activeforeground -foreground -relief
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

	grid $itk_component(site) $itk_component(apply) $itk_component(cancel)
	registerComponent $itk_component(apply)
	eval itk_initialize $args
	}
}

configbody DCS::StringViewBase3::stringName {
	if {$itk_option(-stringName) != $_lastStringName} {
		if {$_lastStringName != ""} {
			#unregister
			::mediator unregister $this $_lastStringName contents
			deleteInput "$_lastStringName status"
			deleteInput "$_lastStringName permission"
        	}
       	set _lastStringName $itk_option(-stringName)
       	if {$itk_option(-stringName) != ""} {
        		set stringName $itk_option(-stringName)
			::mediator register $this $stringName contents handleStringConfigure
			if {[string first ::device::run $stringName] != 0 \
				&& [string first ::device::virtualRun $stringName] \
				&& [string first ::device::virtualPosition $stringName] != 0} {
		       	addInput "$stringName status inactive {supporting device}"
            		}
		addInput "$stringName permission GRANTED PERMISSION"
        	}
	}
}


body DCS::StringViewBase3::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
	if { ! $targetReady_} return
	setContents $contents_
}

body DCS::StringViewBase3::applyChanges {} {
	set newContents [getNewContents]
	if {![checkContentsBeforeSend newContents]} {
        log_error failed to pass checkContentsBeforeSend
        return
    }
	$_lastStringName sendContentsToServer $newContents
}

body DCS::StringViewBase3::cancelChanges {} {
	setContents [$_lastStringName getContents]
}
#########################################################################################
class DCS::StringFieldViewBase {
	inherit ::DCS::StringViewBase

    protected variable m_entryList ""
    protected variable m_checkbuttonList ""

    #### only display, no change no submit
    #### support: text, timestamp, timespan
    #### the widget name starts with:
    #### ts_XXXX:     timestamp
    #### ti_XXXX:     timespan time interval
    #### td_XXXX:     display "overdue" if less than 0
    #### other:       text
    protected variable m_labelList ""

    #### 1: active state 0: disabled state
    protected variable m_stateList ""

    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black

	protected method setContents
	protected method getNewContents

    ###derived classes may put a callback here
    protected method onFieldChange { name index value } {
    }

    protected common gCheckButtonVar

    public method updateEntryColor { name index newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [lindex $contents $index]
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $index $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name index } {
        set fg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [lindex $contents $index]
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set fg $m_origCheckButtonFG
            }
        }
        $itk_component($name) configure \
        -foreground $fg \
        -disabledforeground $fg \
        -activeforeground $fg

        if {[catch {
            onFieldChange $name $index $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringFieldViewBase::setContents { contents_ } {
    foreach {name index } $m_entryList {
        set value [lindex $contents_ $index]
        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index } $m_checkbuttonList {
        set value [lindex $contents_ $index]
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -foreground $m_origCheckButtonFG

        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index } $m_labelList {
        set value [lindex $contents_ $index]
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index } $m_stateList {
        set value [lindex $contents_ $index]
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringFieldViewBase::getNewContents { } {
	puts "this is getNewContents method:"
    set contents [$_lastStringName getContents]
    set ll [llength $contents]
    foreach {name index } $m_entryList {
        if {$index < $ll} {
            set value [$itk_component($name) get]
            set contents [lreplace $contents $index $index $value]
        }
    }
    foreach {name index } $m_checkbuttonList {
        if {$index < $ll} {
            set value $gCheckButtonVar($this,$name)
            set contents [lreplace $contents $index $index $value]
        }
    }
	puts "return is contents : $contents"
    return $contents
}

class DCS::StringFieldLevel2ViewBase {
	inherit ::DCS::StringViewBase

    ## set this to 1 to support delete field.
    ## getNewContents will create contents only from GUI, not the 
    ## string contents.
    protected variable m_allFieldDisplayed 0

    protected variable m_entryList ""
    protected variable m_checkbuttonList ""
    protected variable m_labelList ""
    protected variable m_stateList ""


    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black

	protected method setContents
	protected method getNewContents

    ###derived classes may put a callback here
    protected method onFieldChange { name index1 index2 value } {
    }

    protected common gCheckButtonVar

    public method updateEntryColor { name index1 index2 newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [lindex $contents $index1 $index2]
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $index1 $index2 $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name index1 index2 } {
        set fg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [lindex $contents $index1 $index2]
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set fg $m_origCheckButtonFG
            }
            puts "updateCheckButtonColor $name $index1 $index2"
            puts "ref=$refValue newValue=$newValue"
        }
        $itk_component($name) configure \
        -foreground $fg \
        -disabledforeground $fg \
        -activeforeground $fg

        if {[catch {
            onFieldChange $name $index1 $index2 $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringFieldLevel2ViewBase::setContents { contents_ } {
    #puts "level2 setContents: $contents_"

    foreach {name index1 index2} $m_entryList {
        set value [lindex $contents_ $index1 $index2]
        #puts "for name=$name index =$index1,$index2 value=$value"

        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $index1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index1 index2 } $m_checkbuttonList {
        set value [lindex $contents_ $index1 $index2]
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -foreground $m_origCheckButtonFG

        if {[catch {
            onFieldChange $name $index1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index1 index2 } $m_labelList {
        set value [lindex $contents_ $index1 $index2]
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $index1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index1 index2} $m_stateList {
        set value [lindex $contents_ $index1 $index2]
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $index1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringFieldLevel2ViewBase::getNewContents { } {
    if {$m_allFieldDisplayed} {
        set contents ""
    } else {
        set contents [$_lastStringName getContents]
    }
    foreach {name index1 index2} $m_entryList {
        set old_f [lindex $contents $index1]
        set value [$itk_component($name) get]
        set new_f [setStringFieldWithPadding $old_f $index2 $value]
        set contents [setStringFieldWithPadding $contents $index1 $new_f]
    }
    foreach {name index1 index2} $m_checkbuttonList {
        set old_f [lindex $contents $index1]
        set value $gCheckButtonVar($this,$name)
        set new_f [setStringFieldWithPadding $old_f $index2 $value]
        set contents [setStringFieldWithPadding $contents $index1 $new_f]
    }
    return $contents
}

class DCS::StringFieldMixLevelViewBase {
	inherit ::DCS::StringViewBase

    ## set this to 1 to support delete field.
    ## getNewContents will create contents only from GUI, not the 
    ## string contents.
    protected variable m_allFieldDisplayed 0

    protected variable m_entryList ""
    protected variable m_checkbuttonList ""
    protected variable m_labelList ""
    protected variable m_stateList ""

    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black

	protected method setContents
	protected method getNewContents

    ###derived classes may put a callback here
    protected method onFieldChange { name indexList value } {
    }

    protected common gCheckButtonVar

    public method updateEntryColor { name indexList newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [getMultiLevelListElement $contents $indexList]
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $indexList $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name indexList } {
        set fg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set refValue [getMultiLevelListElement $contents $indexList]
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set fg $m_origCheckButtonFG
            }
        }
        $itk_component($name) configure \
        -foreground $fg \
        -disabledforeground $fg \
        -activeforeground $fg

        if {[catch {
            onFieldChange $name $indexList $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringFieldMixLevelViewBase::setContents { contents_ } {
    #puts "level2 setContents: $contents_"

    foreach {name indexList} $m_entryList {
        set value [getMultiLevelListElement $contents_ $indexList]
        #puts "for name=$name index =$index1,$index2 value=$value"

        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList } $m_checkbuttonList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -foreground $m_origCheckButtonFG

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList} $m_labelList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList} $m_stateList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringFieldMixLevelViewBase::getNewContents { } {
    if {$m_allFieldDisplayed} {
        set contents ""
    } else {
        set contents [$_lastStringName getContents]
    }
    foreach {name indexList} $m_entryList {
        set value [$itk_component($name) get]
        set contents [setMultiLevelListElement $contents $indexList $value]
    }
    foreach {name indexList} $m_checkbuttonList {
        set value $gCheckButtonVar($this,$name)
        set contents [setMultiLevelListElement $contents $indexList $value]
    }
    return $contents
}
#### instead of using index, we use key here
class DCS::StringDictViewBase {
	inherit ::DCS::StringViewBase

    #### only display, no change no submit
    #### support: text, timestamp, timespan
    #### the widget name starts with:
    #### ts_XXXX:     timestamp
    #### ti_XXXX:     timespan time interval
    #### other:       text
    protected variable m_labelList ""
    protected variable m_stateList ""
    protected variable m_entryList ""
    protected variable m_checkbuttonList ""

    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black
    protected variable m_origCheckButtonBG gray

	protected method setContents
	protected method getNewContents

    ###derived classes may put a callback here
    protected method onFieldChange { name key value } {
    }

    protected common gCheckButtonVar

    public method updateEntryColor { name key newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set ll [llength $contents]
            if {$ll % 2} {
                lappend contents {}
            }
            
            if {[catch {dict get $contents $key} refValue]} {
                set refValue ""
            }
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $key $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name key } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            set ll [llength $contents]
            if {$ll % 2} {
                lappend contents {}
            }
            if {[catch {dict get $contents $key} refValue]} {
                set refValue ""
            }
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set bg $m_origCheckButtonBG
            }
        }
        $itk_component($name) configure \
        -background $bg \
        -activebackground $bg

        if {[catch {
            onFieldChange $name $key $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringDictViewBase::setContents { contents_ } {
    puts "$this is setContents method: arg is $contents_"
    set ll [llength $contents_]
	puts $ll
    if {$ll % 2} {
        lappend contents_ {}
    }
	puts $m_entryList
    foreach {name key} $m_entryList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key} $m_checkbuttonList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -background $m_origCheckButtonBG \
        -activebackground $m_origCheckButtonBG \

        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key} $m_labelList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key} $m_stateList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringDictViewBase::getNewContents { } {
	puts "this is StringDictViewBase::getNewContents"
    set contents [$_lastStringName getContents]
    set ll [llength $contents]
    if {$ll % 2} {
        lappend contents {}
    }

    foreach {name key} $m_entryList {
        set value [$itk_component($name) get]
        dict set contents $key $value
    }
    foreach {name key} $m_checkbuttonList {
        set value $gCheckButtonVar($this,$name)
        dict set contents $key $value
    }
    return $contents
}

### 2 level string, first is dict, then a list of field.
class DCS::StringDictFieldViewBase {
	inherit ::DCS::StringViewBase

    ## set this to 1 to support delete field.
    ## getNewContents will create contents only from GUI, not the 
    ## string contents.
    protected variable m_allFieldDisplayed 0

    protected variable m_entryList ""
    protected variable m_checkbuttonList ""
    protected variable m_labelList ""
    protected variable m_stateList ""

    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black

	protected method setContents
	protected method getNewContents

    ###derived classes may put a callback here
    protected method onFieldChange { name key1 index2 value } {
    }

    protected common gCheckButtonVar

    public method updateEntryColor { name key1 index2 newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            if {[catch {
                lindex [dict get $contents $key1] $index2
            } refValue]} {
                puts "failed in updateEntryColor: $refValue"
                set refValue ""
            }
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $key1 $index2 $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name key1 index2 } {
        set fg red
        if {$_lastStringName != ""} {
            set contents [$_lastStringName getContents]
            if {[catch {
                lindex [dict get $contents $key1] $index2
            } refValue]} {
                puts "failed in updateCheckButtonColor: $refValue"
                set refValue ""
            }
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set fg $m_origCheckButtonFG
            }
            puts "updateCheckButtonColor $name $key1 $index2"
            puts "ref=$refValue newValue=$newValue"
        }
        $itk_component($name) configure \
        -foreground $fg \
        -disabledforeground $fg \
        -activeforeground $fg

        if {[catch {
            onFieldChange $name $key1 $index2 $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringDictFieldViewBase::setContents { contents_ } {
	puts "this is StringDictFieldViewBase::setContents method"
    #puts "level2 setContents: $contents_"

    foreach {name key1 index2} $m_entryList {
        if {[catch {
            lindex [dict get $contents_ $key1] $index2
        } value]} {
                puts "failed entry for {$name $key1 $index2}: $value"
            set value ""
        }
        #puts "for name=$name index =$key1,$index2 value=$value"

        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $key1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key1 index2 } $m_checkbuttonList {
        if {[catch {
            lindex [dict get $contents_ $key1] $index2
        } value]} {
                puts "failed chkbtn for {$name $key1 $index2}: $value"
            set value ""
        }
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -foreground $m_origCheckButtonFG

        if {[catch {
            onFieldChange $name $key1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key1 index2 } $m_labelList {
        if {[catch {
            lindex [dict get $contents_ $key1] $index2
        } value]} {
                puts "failed label for {$name $key1 $index2}: $value"
            set value ""
        }
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $key1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key1 index2} $m_stateList {
        if {[catch {
            lindex [dict get $contents_ $key1] $index2
        } value]} {
                puts "failed label for {$name $key1 $index2}: $value"
            set value ""
        }
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $key1 $index2 $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringDictFieldViewBase::getNewContents { } {
	puts "this is StringDictFieldViewBase::getNewContents"
    if {$m_allFieldDisplayed} {
        set contents ""
    } else {
        set contents [$_lastStringName getContents]
    }
    foreach {name key1 index2} $m_entryList {
        if {[catch {dict get $contents $key1} old_f]} {
            set old_f ""
        }
        set value [$itk_component($name) get]
        set new_f [setStringFieldWithPadding $old_f $index2 $value]
        dict set contents $key1 $new_f
    }
    foreach {name key1 index2} $m_checkbuttonList {
        if {[catch {dict get $contents $key1} old_f]} {
            set old_f ""
        }
        set value $gCheckButtonVar($this,$name)
        set new_f [setStringFieldWithPadding $old_f $index2 $value]
        dict set contents $key1 $new_f
    }
    return $contents
}

class DCS::StringView {
	puts "this is StringView class."
	inherit ::DCS::StringViewBase

	protected method setContents
	protected method getNewContents

	constructor { args } {
	puts "this is StringView class constructor."
		itk_component add contents {
			::iwidgets::Scrolledtext $m_site.c -textbackground white
		} {
			keep  -vscrollmode -hscrollmode -wrap
		}
        pack $itk_component(contents) -expand 1 -fill both

		registerComponent $itk_component(contents)
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringView::setContents { contents_ } {
	puts "StringView::setContents was executed."
	puts "contents_ is $contents_"
	puts "itk_component(contents) is $itk_component(contents)"
	set state [$itk_component(contents) cget -state]
	$itk_component(contents) configure -state normal

	$itk_component(contents) delete 0.0 end
	$itk_component(contents) insert 0.0 $contents_

	$itk_component(contents) configure -state $state
}
body DCS::StringView::getNewContents { } {
	puts "StringView::getNewContents method was executed."
	return [$itk_component(contents) get 0.0 end]
}
#####################################################
class DCS::StringViewLabel {
	inherit ::DCS::StringViewBase2
	protected method setContents
	protected method getNewContents

	constructor { args } {
		itk_component add contents {
			label $m_site.c -width 15 -height 1 -bg red
		} {
	} 
	
       pack $itk_component(contents) -fill both
		registerComponent $itk_component(contents)
		eval itk_initialize $args
		announceExist
	}
}
body DCS::StringViewLabel::setContents { contents_ } {
	set state [$itk_component(contents) cget -state]
	# Clear widget
	$itk_component(contents) configure -text $contents_
}
body DCS::StringViewLabel::getNewContents { } {
	return [$itk_component(contents) get 0.0 end]
}
#####
class DCS::StringViewEntry {
	inherit ::DCS::StringViewBase3
	protected method setContents
	protected method getNewContents

	constructor { args } {
		itk_component add contents {
			entry $m_site.c -width 15 -bg green -textvariable ""
		} {
		keep -textvariable
		}
       pack $itk_component(contents) -fill both
		registerComponent $itk_component(contents)
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringViewEntry::setContents { contents_ } {
	set state [$itk_component(contents) cget -state]
	# Clear widget
	$itk_component(contents) delete 0 end
	$itk_component(contents) insert 0 $contents_
	$itk_component(contents) configure -textvariable $contents_
}
body DCS::StringViewEntry::getNewContents { } {
	puts "get Newgcon is  [$itk_component(contents) get]"
	return [$itk_component(contents) get ]
}


#######################################################################
class DCS::StringFieldView {
	inherit ::DCS::StringFieldViewBase

    itk_option define -fieldNameList fieldNameList FieldNameList ""
    itk_option define -defaultType defaultType DefaultType entry
    #### entry or checkbutton

    private method autoFields
    private method showFields

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringFieldView::autoFields { } {
    set contents [$_lastStringName getContents]
    set ll [llength $contents]
    if {$ll < 1} {
        set ll 1
    }

    set m_entryList ""
    set m_checkbuttonList ""
    switch -exact -- $itk_option(-defaultType) {
        checkbutton {
            for {set i 0} {$i < $ll} {incr i} {
                lappend m_checkbuttonList field$i $i
            }
        }
        entry -
        default {
            for {set i 0} {$i < $ll} {incr i} {
                lappend m_entryList field$i $i
            }
        }
    }
}

body DCS::StringFieldView::showFields { } {
    ####ummap old display
    set all [grid slaves $m_site]
    if {$all != ""} {
        eval grid forget $all
    }

    set i 0
    foreach {name index} $m_entryList {
        set cmd [list $this updateEntryColor $name $index %P]
        itk_component add l$i {
            label $m_site.l$i \
            -text $name
        } {
        }
        itk_component add $name {
            entry $m_site.f$i \
            -validate all \
            -background white \
            -vcmd $cmd
        } {
        }
        set m_origEntryBG [$itk_component($name) cget -background]
		registerComponent $itk_component($name)
        grid $itk_component(l$i) -column 0 -row $i -sticky e
        grid $itk_component($name) -column 1 -row $i -sticky w
        incr i
    }
    foreach {name index} $m_checkbuttonList {
        set cmd [list $this updateCheckButtonColor $name $index]
        itk_component add $name {
            checkbutton  $m_site.c$i \
            -anchor w \
            -variable [scope gCheckButtonVar($this,$name)] \
            -command $cmd \
            -text $name
        } {
        }
        #set m_origCheckButtonFG [$itk_component($name) cget -foreground]
		registerComponent $itk_component($name)
        grid $itk_component($name) -column 0 -row $i -sticky w
        incr i
    }
}
configbody DCS::StringFieldView::fieldNameList {
    # we add a scrolled frame later if we need to
    set site $m_site

    #####set up new display fields
    if {$itk_option(-fieldNameList) == ""} {
        autoFields
    } else {
        set m_entryList ""
        set m_checkbuttonList ""
        set index -1
        foreach item $itk_option(-fieldNameList) {
            if {[llength $item] > 1} {
                set name [lindex $item 0]
                set index [lindex $item 1]
            } else {
                set name [lindex $item 0]
                incr index
            }
            switch -exact -- $itk_option(-defaultType) {
                checkbutton {
                    lappend m_checkbuttonList $name $index
                }
                entry -
                default {
                    lappend m_entryList $name $index
                }
            }
        }
    }
    showFields

    if {$_lastStringName != ""} {
        setContents [$_lastStringName getContents]
    }
}

class DCS::StringDictView {
	inherit ::DCS::StringDictViewBase

    itk_option define -keyList keyList KeyList ""
    itk_option define -defaultType defaultType DefaultType entry
    #### entry or checkbutton

    private method autoFields
    private method showFields

	constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringDictView::autoFields { } {
    set contents [$_lastStringName getContents]
    set ll [llength $contents]
    if {($ll % 2)} {
        lappend contents {}
        incr ll
    }

    set dd [eval dict create $contents]
    set m_entryList ""
    set m_checkbuttonList ""
    switch -exact -- $itk_option(-defaultType) {
        checkbutton {
            foreach key [dict keys $dd] {
                lappend m_checkbuttonList $key $key
            }
            set m_checkbuttonList [lsort $m_checkbuttonList]
        }
        entry -
        default {
            foreach key [dict keys $dd] {
                lappend m_entryList $key $key
            }
            set m_entryList [lsort $m_entryList]
        }
    }
}

body DCS::StringDictView::showFields { } {
    ####ummap old display
    set all [grid slaves $m_site]
    if {$all != ""} {
        eval grid forget $all
    }

    puts "DictView showFields:"
    puts "entryList: $m_entryList"
    puts "chkbuttonList: $m_checkbuttonList"


    set i 0
    foreach {name key} $m_entryList {
        set cmd [list $this updateEntryColor $name $key %P]
        itk_component add l$i {
            label $m_site.l$i \
            -text $name
        } {
        }
        itk_component add $name {
            entry $m_site.f$i \
            -validate all \
            -background white \
            -vcmd $cmd
        } {
        }
        set m_origEntryBG [$itk_component($name) cget -background]
		registerComponent $itk_component($name)
        grid $itk_component(l$i) -column 0 -row $i -sticky e
        grid $itk_component($name) -column 1 -row $i -sticky w
        incr i
    }
    foreach {name key} $m_checkbuttonList {
        set cmd [list $this updateCheckButtonColor $name $key]
        itk_component add $name {
            checkbutton  $m_site.c$i \
            -anchor w \
            -variable [scope gCheckButtonVar($this,$name)] \
            -command $cmd \
            -text $name
        } {
        }
        #set m_origCheckButtonFG [$itk_component($name) cget -foreground]
		registerComponent $itk_component($name)
        grid $itk_component($name) -column 0 -row $i -sticky w
        incr i
    }
}
configbody DCS::StringDictView::keyList {
    # we add a scrolled frame later if we need to
    set site $m_site

    #####set up new display fields
    if {$itk_option(-keyList) == ""} {
        autoFields
    } else {
        set m_entryList ""
        set m_checkbuttonList ""
        set index -1
        foreach item $itk_option(-keyList) {
            if {[llength $item] > 1} {
                set name [lindex $item 0]
                set key [lindex $item 1]
            } else {
                set name [lindex $item 0]
                set key $name
            }
            switch -exact -- $itk_option(-defaultType) {
                checkbutton {
                    lappend m_checkbuttonList $name $key
                }
                entry -
                default {
                    lappend m_entryList $name $key
                }
            }
        }
    }
    showFields

    if {$_lastStringName != ""} {
        setContents [$_lastStringName getContents]
    }
}

class DCS::CassetteOwnerView {
	inherit ::DCS::StringFieldView

    private variable m_entryIndex -1

    public method setEntryIndex { index } {
        set m_entryIndex $index
    }

    public method setName { name } {
        set cmpIndex [expr $m_entryIndex * 2]
        set cmpName [lindex $m_entryList $cmpIndex]
        set e $itk_component($cmpName)
        $e delete 0 end
        $e insert 0 $name
    }

    constructor { args } {
        ::DCS::StringFieldView::constructor \
        -stringName ::device::cassette_owner \
        -fieldNameList {no left middle right}
    } {
        itk_component add Menu {
            menu $m_site.mastermenu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0 \
            -activeborderwidth 0 \
        } {
        }

        if {[catch {
            set authObj [AuthClient::getObject]
            set userList [$authObj getAuthorizedUserList]
        } errMsg]} {
            log_error failed to get current user list
            log_error please close and reopen this widgets
            set userList {}
        }

        puts "userlist: $userList"

        $itk_component(Menu) add command -label "ANYBODY" -command "$this setName {}"
        $itk_component(Menu) add command -label "STAFFONLY" -command "$this setName blctl"

        foreach user $userList {
            $itk_component(Menu) add command -label $user -command "$this setName $user"
        }

        for {set i 0} {$i < 4} {incr i} {
            itk_component add aB$i {
                menubutton $m_site.aB$i \
                -menu $m_site.aB$i.menu \
                -image [DCS::MenuEntry::getArrowImage] \
                -width 16 \
                -anchor c \
                -relief raised
            } {
            }

            bind $itk_component(aB$i) <Enter> "+$this setEntryIndex $i"

            $itk_component(Menu) clone $m_site.aB$i.menu

            grid $itk_component(aB$i) -row $i -column 2 -pady 3
		    registerComponent $itk_component(aB$i)
        }
		eval itk_initialize $args
        
    }
}
class DCS::CenterCrystalConfigView {
	inherit ::DCS::StringFieldViewBase

    itk_option define -showCollimator showCollimator ShowCollimator 0 {
        if {!$itk_option(-showCollimator)} {
            pack forget $itk_component(collimator)
            pack forget $m_collimatorObj
        } else {
        }
    }

    public method handleNameStringEvent
    public method handleStandardDoseEvent

    protected variable m_cntsNameString ""
    protected variable m_sizeObj ""
    protected variable m_collimatorObj ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
    extra_lw  loop_width_extra \
    extra_lh  loop_height_extra \
    min_col   min_column \
    max_col   max_column \
    min_row   min_row \
    max_row   max_row \
    min_wd    min_step_x \
    max_wd    max_step_x \
    min_ht    min_step_y \
    max_ht    max_step_y \
    delta_phi delta \
    ini_time  init_expose_time \
    cre_time  increment_expose_time \
    min_time  min_expose_time \
    max_time  max_expose_time \
    back_sub  background_sub \
    min_spot  min_num_spot \
    tgt_spot  target_num_spot \
    min_loop  min_loop \
    max_loop  max_loop \
    term_horz finish_horizontal \
    term_vert finish_vertical \
    extra_wd  beam_width_extra \
    extra_ht  beam_height_extra \
    clmtr_scale    collimator_scale_factor \
    clmtr_min_col  collimator_min_column \
    clmtr_max_col  collimator_max_column \
    clmtr_min_row  collimator_min_row \
    clmtr_max_row  collimator_max_row \
    clmtr_min_step_x  collimator_min_step_x \
    clmtr_max_step_x  collimator_max_step_x \
    clmtr_min_step_y  collimator_min_step_y \
    clmtr_max_step_y  collimator_max_step_y \
    ]
    protected variable m_checkbuttonMap [list \
    system_on system_on \
    no_size   keep_orig_beam_size \
    collimator collimator_scan \
    ]

    protected method addEntry { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -background white
            } {
            }
            ####registerComponent $itk_component($name)
        }
    }
    protected method fillComponentList { }

    protected method onFieldChange { name index value } {
        switch -exact -- $name {
            no_size {
                if {$value == "1"} {
                    pack forget $m_sizeObj
                } else {
                    pack $m_sizeObj \
                    -side top -fill x -expand 0 \
                    -after $itk_component($name)
                }
            }
            collimator {
                if {$value == "0"} {
                    pack forget $m_collimatorObj
                } else {
                    if {$itk_option(-showCollimator)} {
                        pack $m_collimatorObj \
                        -side top -fill x -expand 0 \
                        -after $itk_component($name)
                    }
                }
            }
        }
    }
    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::center_crystal_const
    } {
        itk_component add system_on {
            checkbutton $m_site.cb1 \
            -anchor w \
            -variable [scope gCheckButtonVar($this,system_on)] \
            -text "show button on Collect Tab"
        } {
            keep -background
        }
        #set m_origCheckButtonFG [$itk_component(system_on) cget -foreground]


        frame $m_site.left
        frame $m_site.right
        set leftSite $m_site.left
        set rightSite $m_site.right

        iwidgets::Labeledframe $leftSite.f_scan \
        -borderwidth 3 \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Scan Area"
        set scanAreaSite [$leftSite.f_scan childsite]
        
        label $scanAreaSite.l11 \
        -text "width  = loop width plus"
        label $scanAreaSite.l13 \
        -text "%"

        label $scanAreaSite.l21 \
        -text "height = loop height plus"
        label $scanAreaSite.l23 \
        -text "%"

        addEntry $scanAreaSite 3 extra_lw extra_lh
        set m_origEntryBG [$itk_component(extra_lw) cget -background]

        grid columnconfigure $scanAreaSite 2 -weight 100
        grid $scanAreaSite.l11 $itk_component(extra_lw) \
        $scanAreaSite.l13 -sticky w
        grid $scanAreaSite.l21 $itk_component(extra_lh) \
        $scanAreaSite.l23 -sticky w

        iwidgets::Labeledframe $leftSite.f_matrix \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Scan Matrix"
        set matrixSite [$leftSite.f_matrix childsite]
        
        label $matrixSite.l12 \
        -text "minimum"
        label $matrixSite.l14 \
        -text "maximum"

        label $matrixSite.l21 \
        -text "num of columns"

        label $matrixSite.l31 \
        -text "num of rows"

        label $matrixSite.l41 \
        -text "beamsize width"
        label $matrixSite.l43 \
        -text "mm"
        label $matrixSite.l45 \
        -text "mm"

        label $matrixSite.l51 \
        -text "beamsize height"
        label $matrixSite.l53 \
        -text "mm"
        label $matrixSite.l55 \
        -text "mm"

        addEntry $matrixSite 8 \
        min_col max_col min_row max_row min_wd max_wd min_ht max_ht

        grid columnconfigure $matrixSite 4 -weight 100
        grid x $matrixSite.l12 x $matrixSite.l14 -sticky w
        grid $matrixSite.l21 $itk_component(min_col) x $itk_component(max_col) \
        -sticky w
        grid $matrixSite.l31 $itk_component(min_row) x $itk_component(max_row) \
        -sticky w
        grid $matrixSite.l41 $itk_component(min_wd) $matrixSite.l43 \
        $itk_component(max_wd) $matrixSite.l45 -sticky w
        grid $matrixSite.l51 $itk_component(min_ht) $matrixSite.l53 \
        $itk_component(max_ht) $matrixSite.l55 -sticky w

        frame $leftSite.f2
        set deltaSite $leftSite.f2
        label $deltaSite.l1 \
        -text "phi delta"

        addEntry $deltaSite 8 delta_phi

        label $deltaSite.l2 \
        -text "degree"

        pack $deltaSite.l1 $itk_component(delta_phi) $deltaSite.l2 \
        -side left

        itk_component add exposureFrame {
            iwidgets::Labeledframe $leftSite.f_time \
            -borderwidth 3 \
            -labelpos nw \
            -labeltext "Exposure Factor"
        } {
        }
        set timeSite [$itk_component(exposureFrame) childsite]
        
        label $timeSite.l11 \
        -text "initial"
        label $timeSite.l13 \
        -text "times"

        label $timeSite.l21 \
        -text "increment"
        label $timeSite.l23 \
        -text "X"

        label $timeSite.l31 \
        -text "minimum"
        label $timeSite.l33 \
        -text "times"

        label $timeSite.l41 \
        -text "maximum"
        label $timeSite.l43 \
        -text "times"

        addEntry $timeSite 8 ini_time cre_time min_time max_time

        grid columnconfigure $timeSite 2 -weight 100
        grid $timeSite.l11 $itk_component(ini_time) $timeSite.l13 -sticky w
        grid $timeSite.l21 $itk_component(cre_time) $timeSite.l23 -sticky w
        grid $timeSite.l31 $itk_component(min_time) $timeSite.l33 -sticky w
        grid $timeSite.l41 $itk_component(max_time) $timeSite.l43 -sticky w

        iwidgets::Labeledframe $rightSite.f_image \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Image Processing"
        set imageSite [$rightSite.f_image childsite]
        
        label $imageSite.l11 \
        -text "number of spots to substract"

        label $imageSite.l21 \
        -text "minimum number of spots"
        label $imageSite.l31 \
        -text "target number of spots"

        addEntry $imageSite 8 back_sub min_spot tgt_spot

        grid columnconfigure $imageSite 2 -weight 100
        grid $imageSite.l11 $itk_component(back_sub) -sticky w
        grid $imageSite.l21 $itk_component(min_spot) -sticky w
        grid $imageSite.l31 $itk_component(tgt_spot) -sticky w
        
        iwidgets::Labeledframe $rightSite.f_loop \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Number of Zoom-in Iterations"
        set loopSite [$rightSite.f_loop childsite]
        
        label $loopSite.l11 \
        -text "minimum"
        label $loopSite.l14 \
        -text "maximum"

        addEntry $loopSite 3 min_loop max_loop

        grid columnconfigure $loopSite 2 -weight 100
        grid $loopSite.l11            -row 0 -column 0 -sticky e
        grid $itk_component(min_loop) -row 0 -column 1 -sticky w
        grid $loopSite.l14            -row 0 -column 3 -sticky e
        grid $itk_component(max_loop) -row 0 -column 4 -sticky w

        iwidgets::Labeledframe $rightSite.f_term \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Termination Condition"
        set termSite [$rightSite.f_term childsite]
        
        label $termSite.l1 \
        -text "crystal size exceeds"

        label $termSite.l22 \
        -text "% of horizontal scan matrix width"

        label $termSite.l32 \
        -text "% of vertical scan matrix height"

        addEntry $termSite 3 term_horz term_vert

        grid columnconfigure $termSite 1 -weight 100
        grid $termSite.l1 -columnspan 2 -sticky w
        grid $itk_component(term_horz) $termSite.l22 -sticky w
        grid $itk_component(term_vert) $termSite.l32 -sticky w

        itk_component add no_size {
            checkbutton $rightSite.no_size \
            -anchor w \
            -variable [scope gCheckButtonVar($this,no_size)] \
            -text "keep original beam size"
        } {
            keep -background
        }

        iwidgets::Labeledframe $rightSite.f_beam \
        -borderwidth 3 \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Final Beam Size"
        set beamSite [$rightSite.f_beam childsite]

        set m_sizeObj $rightSite.f_beam
        
        label $beamSite.l11 \
        -text "width  = crystal width plus"
        label $beamSite.l13 \
        -text "%"

        label $beamSite.l21 \
        -text "height = crystal height plus"
        label $beamSite.l23 \
        -text "%"

        addEntry $beamSite 3 extra_wd extra_ht

        grid columnconfigure $beamSite 2 -weight 100
        grid $beamSite.l11 $itk_component(extra_wd) $beamSite.l13 -sticky w
        grid $beamSite.l21 $itk_component(extra_ht) $beamSite.l23 -sticky w

        ############################################
        itk_component add collimator {
            checkbutton $rightSite.collimator \
            -anchor w \
            -variable [scope gCheckButtonVar($this,collimator)] \
            -text "Enable Collimator Scan"
        } {
            keep -background
        }

        iwidgets::Labeledframe $rightSite.f_collimator \
        -borderwidth 3 \
        -borderwidth 3 \
        -labelpos nw \
        -labeltext "Collimator Scan Setup"
        set collimatorSite [$rightSite.f_collimator childsite]

        set m_collimatorObj $rightSite.f_collimator

        label $collimatorSite.l01 \
        -text "flux scale factor"

        label $collimatorSite.l12 \
        -text "minimum"
        label $collimatorSite.l14 \
        -text "maximum"

        label $collimatorSite.l21 \
        -text "num of columns"

        label $collimatorSite.l31 \
        -text "num of rows"

        label $collimatorSite.l41 \
        -text "step size horz"
        label $collimatorSite.l43 \
        -text "mm"
        label $collimatorSite.l45 \
        -text "mm"

        label $collimatorSite.l51 \
        -text "step size vert"
        label $collimatorSite.l53 \
        -text "mm"
        label $collimatorSite.l55 \
        -text "mm"

        addEntry $collimatorSite 8 \
        clmtr_scale clmtr_min_col clmtr_max_col clmtr_min_row clmtr_max_row \
        clmtr_min_step_x clmtr_max_step_x clmtr_min_step_y clmtr_max_step_y

        grid columnconfigure $collimatorSite 4 -weight 100
        grid $collimatorSite.l01 $itk_component(clmtr_scale) -sticky w

        grid x                   $collimatorSite.l12           \
        x \
        $collimatorSite.l14 -sticky w

        grid $collimatorSite.l21 $itk_component(clmtr_min_col) \
        x \
        $itk_component(clmtr_max_col) -sticky w

        grid $collimatorSite.l31 $itk_component(clmtr_min_row) \
        x \
        $itk_component(clmtr_max_row) -sticky w

        grid $collimatorSite.l41 $itk_component(clmtr_min_step_x) \
        $collimatorSite.l43 \
        $itk_component(clmtr_max_step_x) $collimatorSite.l45 -sticky w

        grid $collimatorSite.l51 $itk_component(clmtr_min_step_y) \
        $collimatorSite.l53 \
        $itk_component(clmtr_max_step_y) $collimatorSite.l55 -sticky w
        ################################################

        pack $leftSite.f_scan -side top -fill both
        pack $leftSite.f_matrix -side top -fill both
        pack $leftSite.f2 -side top -fill both
        pack $leftSite.f_time -side top -fill both

        pack $rightSite.f_image -side top -fill x -expand 0
        pack $rightSite.f_loop -side top -fill x -expand 0
        pack $rightSite.f_term -side top -fill x -expand 0
        pack $itk_component(no_size) -side top -fill x -expand 0
        pack $rightSite.f_beam -side top -fill x -expand 0
        pack $itk_component(collimator) -side top -fill x -expand 0
        pack $rightSite.f_collimator -side top -fill x -expand 0

        grid $itk_component(system_on) -columnspan 2 -sticky w
        grid $m_site.left $m_site.right -sticky news

        mediator register $this ::device::center_crystal_constant_name_list contents handleNameStringEvent
        mediator register $this ::device::collect_default contents handleStandardDoseEvent

		eval itk_initialize $args

		announceExist
    }
    destructor {
        mediator unregister $this ::device::collect_default contents
        mediator unregister $this ::device::center_crystal_constant_name_list contents
    }
}
body DCS::CenterCrystalConfigView::handleStandardDoseEvent { - ready_ - contents_ - } {
    if {!$ready_} return
    set defT [lindex $contents_ 1]
    set defA [lindex $contents_ 2]

    $itk_component(exposureFrame) configure \
    -labeltext "Exposure Factor of (time=${defT}s attn=${defA}%)"
}
body DCS::CenterCrystalConfigView::handleNameStringEvent { - ready_ - contents_ - } {
    if {!$ready_} return

    if {$contents_ == $m_cntsNameString} return
    set m_cntsNameString $contents_

    fillComponentList
    if {$_lastStringName != ""} {
        setContents [$_lastStringName getContents]
    }
}
body DCS::CenterCrystalConfigView::fillComponentList { } {
    set m_entryList ""
    set m_checkbuttonList ""

    foreach {name keyword} $m_entryMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            set cmd [list $this updateEntryColor $name $index %P]
            puts "map $name to $index"
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }
    foreach {name keyword} $m_checkbuttonMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -command ""
        } else {
            set cmd [list $this updateCheckButtonColor $name $index]
            #puts "map $name to $index"
            lappend m_checkbuttonList $name $index
            $itk_component($name) configure \
            -command $cmd
        }
    }
}
class DCS::DoseControlConfigView {
	inherit ::DCS::StringFieldViewBase

    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set ll [llength $contents]
        if {$ll < 5} {
            log_error contents length wrong $ll < 5
            return 0
        }
        set allOK 1
        foreach {timeStamp signal itime minsig stable} $contents break
        if {[lsearch $m_sigList $signal] < 0} {
            log_error bad signal $signal.  Must be one of $m_sigList
            set allOK 0
        }
        if {![string is double -strict $itime] || $itime <= 0} {
            log_error wrong integration time: $itime
            set allOK 0
        }
        if {![string is double -strict $minsig]} {
            log_error wrong minimum signal: $minsig
            set allOK 0
        }
        if {![string is double -strict $stable] || \
        $stable < 0 || $stable > 100} {
            log_error wrong stable ration: $stable. Should be between 0 and 100
            set allOK 0
        }
        
        ###set timestamp.  The dcss will set timestamp again when it
        ####broadcast it
        set contents [lreplace $contents 0 0 [clock seconds]]

        return $allOK
    }

    public method setSignal { name } {
        $itk_component(signal) delete 0 end
        $itk_component(signal) insert 0 $name
    }

    ###will be overwriten in constructor
    private variable m_sigList ""

    constructor { args } {
    } {
        if {[catch {
            set deviceFactory [DCS::DeviceFactory::getObject]
            set m_sigList [$deviceFactory getSignalList]
        } errMsg] || $m_sigList == ""} {
            log_error failed to retrieve ion chamber list, default to i0, i1, i2
            set m_sigList [list i0 i1 i2]
        }
        set m_entryList [list \
        signal 1 \
        itime  2 \
        minsig 3 \
        stable 4]

        ######create entries
        foreach {name index} $m_entryList {
            set cmd [list $this updateEntryColor $name $index %P]
            itk_component add $name {
                entry $m_site.$name \
                -font "helvetica -12 bold" \
                -justify right \
                -width 15 \
                -background white \
                -validate all \
                -vcmd $cmd
            } {
            }
        }

        label $m_site.l11 \
        -text signal:

        itk_component add sigmb {
            menubutton $m_site.sigmb \
            -menu $m_site.sigmb.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised
        } {
        }
        itk_component add sigmn {
            menu $m_site.sigmb.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }

        foreach s $m_sigList {
            $itk_component(sigmn) add command \
            -label $s \
            -command "$this setSignal $s"
        }

        label $m_site.l21 \
        -text "integration time:"
        label $m_site.l23 \
        -text s

        label $m_site.l31 \
        -text "minimum signal:"
        label $m_site.l33 \
        -text counts

        label $m_site.l41 \
        -text "stability ratio:"
        label $m_site.l43 \
        -text %

        grid $m_site.l11 -row 0 -column 0 -sticky e
        grid $m_site.l21 -row 1 -column 0 -sticky e
        grid $m_site.l31 -row 2 -column 0 -sticky e
        grid $m_site.l41 -row 3 -column 0 -sticky e

        grid $itk_component(signal) -row 0 -column 1 -sticky we
        grid $itk_component(itime)  -row 1 -column 1 -sticky we
        grid $itk_component(minsig) -row 2 -column 1 -sticky we
        grid $itk_component(stable) -row 3 -column 1 -sticky we

        grid $itk_component(sigmb) -row 0 -column 2 -sticky w
        grid $m_site.l23           -row 1 -column 2 -sticky w
        grid $m_site.l33           -row 2 -column 2 -sticky w
        grid $m_site.l43           -row 3 -column 2 -sticky w

		eval itk_initialize $args
		announceExist
        configure \
        -stringName ::device::dose_const
    }
}
class DCS::DoseDetailView {
    inherit ::itk::Widget

    itk_option define -controlSystem controlSystem ControlSystem ::dcss

    private variable m_strDoseConst
    private variable m_strDoseData
    private variable m_opNormalize

    private variable m_ctxDoseConst ""
    private variable m_ctxDoseData  ""

    private variable m_format "%D %T"

    public method handleDoseConstEvent
    public method handleDoseDataEvent

    private method updateDisplay

    constructor { args } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strDoseConst [$deviceFactory createString dose_const]
        set m_strDoseData  [$deviceFactory createString dose_data]

        itk_component add ts_cfg {
            label $itk_interior.left_ts \
            -width 20
        } {
        }
        itk_component add ts_op {
            label $itk_interior.right_ts \
            -width 20
        } {
        }

        itk_component add f_left {
            iwidgets::Labeledframe $itk_interior.left \
            -labelpos nw \
            -labeltext "Configuration"
        } {
        }
        set leftSite [$itk_component(f_left) childsite]
        itk_component add config {
            DCS::DoseControlConfigView $leftSite.config \
            -systemIdleOnly 0 \
            -activeClientOnly 0
        } {
        }
        pack $itk_component(config) -side top -expand 1 -fill both

        itk_component add control {
            DCS::DoseControlView $itk_interior.control
        } {
        }


        itk_component add f_right {
            iwidgets::Labeledframe $itk_interior.right \
            -labelpos nw \
            -labeltext "Data"
        } {
        }
        set rightSite [$itk_component(f_right) childsite]

        label $rightSite.l12 \
        -text counts
        label $rightSite.l13 \
        -text "time stamp"
        label $rightSite.l14 \
        -text "energy"
        label $rightSite.l15 \
        -text "beam width"
        label $rightSite.l16 \
        -text "beam height"
        label $rightSite.l17 \
        -text "attenuation"

        label $rightSite.l21 \
        -justify right \
        -text stored:

        itk_component add stored {
            label $rightSite.stored \
            -justify right \
            -width 10 \
            -background #00a040 \
            -foreground black \
            -relief sunken
        } {
        }

        itk_component add ts_stored {
            label $rightSite.ts_stored \
            -width 20
        } {
        }

        itk_component add energy_stored {
            label $rightSite.energy_stored \
            -width 8
        } {
        }

        itk_component add slit_w_stored {
            label $rightSite.slit_w_stored \
            -width 6
        } {
        }

        itk_component add slit_h_stored {
            label $rightSite.slit_h_stored \
            -width 6
        } {
        }

        itk_component add attenuation_stored {
            label $rightSite.attenuation_stored \
            -width 7
        } {
        }

        label $rightSite.l31 \
        -justify right \
        -text last:

        itk_component add last {
            label $rightSite.last \
            -justify right \
            -width 10 \
            -background #00a040 \
            -foreground black \
            -relief sunken
        } {
        }

        itk_component add ts_last {
            label $rightSite.ts_last \
            -width 20
        } {
        }

        itk_component add energy_last {
            label $rightSite.energy_last \
            -width 8
        } {
        }

        itk_component add slit_w_last {
            label $rightSite.slit_w_last \
            -width 6
        } {
        }

        itk_component add slit_h_last {
            label $rightSite.slit_h_last \
            -width 6
        } {
        }

        itk_component add attenuation_last {
            label $rightSite.attenuation_last \
            -width 7
        } {
        }

        grid columnconfig $rightSite 2 -weight 10

        grid x $rightSite.l12 $rightSite.l13 $rightSite.l14 $rightSite.l15 $rightSite.l16 $rightSite.l17
        grid $rightSite.l21       -row 1 -column 0 -sticky e
        grid $rightSite.stored    -row 1 -column 1 -sticky e
        grid $rightSite.ts_stored -row 1 -column 2 -sticky w
        grid $rightSite.energy_stored -row 1 -column 3 -sticky w
        grid $rightSite.slit_w_stored -row 1 -column 4 -sticky w
        grid $rightSite.slit_h_stored -row 1 -column 5 -sticky w
        grid $rightSite.attenuation_stored -row 1 -column 6 -sticky w

        grid $rightSite.l31     -row 2 -column 0 -sticky e
        grid $rightSite.last    -row 2 -column 1 -sticky e
        grid $rightSite.ts_last -row 2 -column 2 -sticky w
        grid $rightSite.energy_last -row 2 -column 3 -sticky w
        grid $rightSite.slit_w_last -row 2 -column 4 -sticky w
        grid $rightSite.slit_h_last -row 2 -column 5 -sticky w
        grid $rightSite.attenuation_last -row 2 -column 6 -sticky w

        grid $itk_component(ts_cfg) $itk_component(ts_op)
        grid $itk_component(f_left) $itk_component(control) -sticky news
        grid ^ $itk_component(f_right)

		eval itk_initialize $args
        $m_strDoseConst register $this contents handleDoseConstEvent
        $m_strDoseData  register $this contents handleDoseDataEvent
    }
    destructor {
        $m_strDoseConst unregister $this contents handleDoseConstEvent
        $m_strDoseData  unregister $this contents handleDoseDataEvent
    }
}
body DCS::DoseDetailView::handleDoseConstEvent {- targetReady_ - contents_ -} {
    if {!$targetReady_} return

    set m_ctxDoseConst $contents_
    updateDisplay
}
body DCS::DoseDetailView::handleDoseDataEvent {- targetReady_ - contents_ -} {
    if {!$targetReady_} return

    set m_ctxDoseData $contents_
    updateDisplay
}
body DCS::DoseDetailView::updateDisplay { } {
    set ts_cfg ""
    set cfg_i 0
    if {[catch {
        set cfg_i [lindex $m_ctxDoseConst 0]
        if {[string is integer -strict $cfg_i] && $cfg_i > 0} {
            set ts_cfg [clock format $cfg_i -format $m_format]
        }
    } errMsg]} {
        log_error DoseDetailView update failed: $errMsg
    }
    $itk_component(ts_cfg) configure \
    -text $ts_cfg

    set ts_op ""
    set ts_last ""
    set op_i 0
    set op_e ""
    set op_w ""
    set op_h ""
    set op_a ""
    set last_i 0
    set last_e ""
    set last_w ""
    set last_h ""
    set last_a ""

    if {[catch {
        set op_s [lindex $m_ctxDoseData 0]
        set last_s [lindex $m_ctxDoseData 2]
        foreach {op_i   op_e   op_w   op_h   op_a}   $op_s  break
        foreach {last_i last_e last_w last_h last_a} $last_s break

        if {[string is integer -strict $op_i] && $op_i > 0} {
            set ts_op [clock format $op_i -format $m_format]
        }
        if {[string is integer -strict $last_i] && $last_i > 0} {
            set ts_last [clock format $last_i -format $m_format]
        }
    } errMsg]} {
        log_error DoseDetailView update failed: $errMsg
    }
    if {$cfg_i > $op_i} {
        $itk_component(ts_op) configure \
        -text $ts_op \
        -foreground red
    } else {
        $itk_component(ts_op) configure \
        -text $ts_op \
        -foreground black
    }

    if {[string is double -strict $op_e]} {
        set op_e [format "%.1f" $op_e]
    }
    if {[string is double -strict $last_e]} {
        set last_e [format "%.1f" $last_e]
    }

    if {[string is double -strict $op_w]} {
        set op_w [format "%.3f" $op_w]
    }
    if {[string is double -strict $last_w]} {
        set last_w [format "%.3f" $last_w]
    }

    if {[string is double -strict $op_h]} {
        set op_h [format "%.3f" $op_h]
    }
    if {[string is double -strict $last_h]} {
        set last_h [format "%.3f" $last_h]
    }

    if {[string is double -strict $op_a]} {
        set op_a [format "%.1f" $op_a]
    }
    if {[string is double -strict $last_a]} {
        set last_a [format "%.1f" $last_a]
    }


    $itk_component(ts_stored) configure -text $ts_op
    $itk_component(energy_stored) configure -text $op_e
    $itk_component(slit_w_stored) configure -text $op_w
    $itk_component(slit_h_stored) configure -text $op_h
    $itk_component(attenuation_stored) configure -text $op_a

    $itk_component(ts_last)   configure -text $ts_last
    $itk_component(energy_last) configure -text $last_e
    $itk_component(slit_w_last) configure -text $last_w
    $itk_component(slit_h_last) configure -text $last_h
    $itk_component(attenuation_last) configure -text $last_a

    set stored [lindex $m_ctxDoseData 1]
    set last [lindex $m_ctxDoseData 3]

    if {[catch {
        if {$stored != ""} {
            set stored [format "%.3f" $stored]
        }
        if {$last != ""} {
            set last [format "%.3f" $last]
        }
    } errMsg]} {
        log_error DoseDetailView update failed: $errMsg
    }

    $itk_component(stored) configure -text $stored
    $itk_component(last) configure -text $last
}
class DCS::AlignFrontEndConfigView {
	inherit ::DCS::StringFieldViewBase

    ### to update read-only displays
    public method handleOptimizedEnergyParamEvent

    public method setSignal { name } {
        $itk_component(fsig) delete 0 end
        $itk_component(fsig) insert 0 $name
    }

    public method openOEPView { } {
        if {$itk_option(-mdiHelper) == ""} {
            return
        }
        $itk_option(-mdiHelper) openToolChest optimizedEnergyParameterGui
    }

    protected variable m_cntsNameString ""
    protected variable m_sigList ""
    protected variable m_menubuttonIndex

    protected variable color4OptimizeEnergyParam #00a040
    protected variable color4SlitWidth cyan
    protected variable color4SlitHeight lightblue
    protected variable color4BeamWidth  burlywood
    protected variable color4BeamHeight brown

    protected variable m_flux 155
    protected variable m_time 0.11
    protected variable m_signal i1

    protected variable m_slitGapxUL 0.1
    protected variable m_beamGapxUL 0.1
    protected variable m_slitGapyUL 0.1
    protected variable m_beamGapyUL 0.1

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
        vs_gap_h        optimize_vert_slit_gap_horz \
        vs_gap_v        optimize_vert_slit_gap_vert \
        hs_gap_h        optimize_horz_slit_gap_horz \
        hs_gap_v        optimize_horz_slit_gap_vert \
        sstep_v         optimize_slit_step_size_vert \
        sstep_h         optimize_slit_step_size_horz \
        snum_v          optimize_slit_num_step_vert \
        snum_h          optimize_slit_num_step_horz \
        swmin_v         optimize_slit_wmin_vert \
        swmin_h         optimize_slit_wmin_horz \
        swmax_v         optimize_slit_wmax_vert \
        swmax_h         optimize_slit_wmax_horz \
        sglc_v          optimize_slit_glc_vert \
        sglc_h          optimize_slit_glc_horz \
        sgrc_v          optimize_slit_grc_vert \
        sgrc_h          optimize_slit_grc_horz \
        fdist           align_front_detector_distance \
        fenergy         align_front_energy \
        vf_gap_h        align_front_vert_gap_horz \
        vf_gap_v        align_front_vert_gap_vert \
        hf_gap_h        align_front_horz_gap_horz \
        hf_gap_v        align_front_horz_gap_vert \
        fatten          align_front_attenuation \
        fsig            align_front_ion_chamber \
        fstep_v         align_front_step_size_vert \
        fstep_h         align_front_step_size_horz \
        fnum_v          align_front_num_step_vert \
        fnum_h          align_front_num_step_horz \
        ftime_v         align_front_scan_time_vert \
        ftime_h         align_front_scan_time_horz \
        fwmin_v         align_front_wmin_vert \
        fwmin_h         align_front_wmin_horz \
        fwmax_v         align_front_wmax_vert \
        fwmax_h         align_front_wmax_horz \
        fglc_v          align_front_glc_vert \
        fglc_h          align_front_glc_horz \
        fgrc_v          align_front_grc_vert \
        fgrc_h          align_front_grc_horz \
    ]

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::alignFrontEnd_constant
    } {
        set beamNotSlit 1

        set LABEL_WIDTH 15
        set ENTRY_WIDTH 10
        set UNITS_WIDTH 3

        set m_cntsNameString [::config getStr alignFrontEndConstantsNameList]
        puts "namelist $m_cntsNameString"

        array set m_menubuttonIndex [list]
        if {[catch {
            set deviceFactory [DCS::DeviceFactory::getObject]
            set m_sigList [$deviceFactory getSignalList]
        } errMsg] || $m_sigList == ""} {
            log_error failed to retrieve ion chamber list, default to i0, i1, i2
            set m_sigList [list i0 i1 i2]
        }

        frame $m_site.top
        set topSite $m_site.top

        iwidgets::Labeledframe $topSite.g \
        -labelfont "helvetica -16 bold" \
        -foreground blue \
        -labelpos nw \
        -labeltext "Global Prepare"
        set gSite [$topSite.g childsite]

        ### labels
        label $gSite.l1 -text "energy:" -anchor e

        label $gSite.l2 -text "detector Distance:" -anchor e

        label $gSite.l3 -text "ev" -anchor w -width $UNITS_WIDTH
        label $gSite.l4 -text "mm" -anchor w -width $UNITS_WIDTH
        addEntries $gSite $ENTRY_WIDTH fenergy fdist
        grid $gSite.l1 $itk_component(fenergy) $gSite.l3 -sticky news
        grid $gSite.l2 $itk_component(fdist)   $gSite.l4 -sticky news
        grid columnconfig $gSite 0 -weight 1

        iwidgets::Labeledframe $topSite.legend \
        -labelfont "helvetica -16 bold" \
        -foreground blue \
        -labelpos nw \
        -labeltext "Legend"
        set legendSite [$topSite.legend childsite]

        button $legendSite.o \
        -text "from OptimizedEnergyParameters" \
        -background $color4OptimizeEnergyParam \
        -command "$this openOEPView"

        grid $legendSite.o -sticky news
        if {$beamNotSlit} {
        }

        grid $topSite.g $topSite.legend -stick news
        grid columnconfig $topSite 0 -weight 1
        grid columnconfig $topSite 1 -weight 0


        iwidgets::Labeledframe $m_site.slit \
        -labelfont "helvetica -16 bold" \
        -labeltext "Slit"
        set slitSite [$m_site.slit childsite]

        iwidgets::Labeledframe $slitSite.title
        set slitTSite [$slitSite.title childsite]

        label $slitTSite.lC0 -text "    " -width $LABEL_WIDTH
        label $slitTSite.lC1 -text "Vertical" \
        -width $ENTRY_WIDTH -relief sunken
        label $slitTSite.lC2 -text "Horizontal" \
        -width $ENTRY_WIDTH -relief sunken
        label $slitTSite.lC3 -text "  "

        grid $slitTSite.lC0 \
        $slitTSite.lC1 $slitTSite.lC2 \
        $slitTSite.lC3 \
        -sticky news

        iwidgets::Labeledframe $slitSite.prepare \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -foreground blue \
        -labeltext "Prepare"
        set slitPSite [$slitSite.prepare childsite]
        label $slitPSite.lR21 -text "attenuation:" -anchor e -width $LABEL_WIDTH
        label $slitPSite.lR22 -text "N/A" -relief sunken
        label $slitPSite.lR31 -text "slit width:" -anchor e -width $LABEL_WIDTH
        label $slitPSite.lR34 -text "mm" -anchor w -width $UNITS_WIDTH
        label $slitPSite.lR41 -text "slit height:" -anchor e -width $LABEL_WIDTH
        label $slitPSite.lR44 -text "mm" -anchor w -width $UNITS_WIDTH

        addEntries $slitPSite $ENTRY_WIDTH vs_gap_h vs_gap_v hs_gap_h hs_gap_v

        label $slitPSite.gapy \
        -anchor e \
        -background $color4SlitHeight \
        -width $ENTRY_WIDTH \
        -relief sunken \
        -textvariable [scope m_slitGapyUL]

        grid $slitPSite.lR21 \
        $slitPSite.lR22 - - \
        -sticky news

        grid $slitPSite.lR31 \
        $itk_component(vs_gap_h) $itk_component(hs_gap_h) $slitPSite.lR34 \
        -sticky news
        
        grid $slitPSite.lR41 \
        $itk_component(vs_gap_v) $itk_component(hs_gap_v) $slitPSite.lR44 \
        -sticky news

        iwidgets::Labeledframe $slitSite.scan \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -foreground blue \
        -labeltext "Scan Parameters"
        set slitSSite [$slitSite.scan childsite]

        label $slitSSite.lR51 -text "signal:" -anchor e -width $LABEL_WIDTH
        label $slitSSite.lR61 -text "num of points:" -anchor e -width $LABEL_WIDTH
        label $slitSSite.lR71 -text "step size:" -anchor e -width $LABEL_WIDTH
        label $slitSSite.lR74 -text "mm" -anchor w -width $UNITS_WIDTH
        label $slitSSite.lR81 -text "time at point:" -anchor e -width $LABEL_WIDTH
        label $slitSSite.lR84 -text "s" -anchor w -width $UNITS_WIDTH

        label $slitSSite.s_signal \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_signal]

        label $slitSSite.time1 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_time]
        label $slitSSite.time2 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_time]

        addEntries $slitSSite $ENTRY_WIDTH snum_v snum_h sstep_v sstep_h

        grid $slitSSite.lR51 \
        $slitSSite.s_signal - \
        -sticky news

        grid $slitSSite.lR61 \
        $itk_component(snum_v) $itk_component(snum_h) \
        -sticky news

        grid $slitSSite.lR71 \
        $itk_component(sstep_v) $itk_component(sstep_h) \
        $slitSSite.lR74 \
        -sticky news

        grid $slitSSite.lR81 \
        $slitSSite.time1 $slitSSite.time2 \
        $slitSSite.lR84 \
        -sticky news

        iwidgets::Labeledframe $slitSite.analysis \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -foreground blue \
        -labeltext "Peak Analysis Parameters"
        set slitASite [$slitSite.analysis childsite]

        label $slitASite.lRA1 -text "flux:" -anchor e -width $LABEL_WIDTH
        label $slitASite.lRA4 -text "" -anchor w -width $UNITS_WIDTH
        label $slitASite.lRB1 -text "wmin:" -anchor e -width $LABEL_WIDTH
        label $slitASite.lRB4 -text "mm" -anchor w -width $UNITS_WIDTH
        label $slitASite.lRC1 -text "wmax:" -anchor e -width $LABEL_WIDTH
        label $slitASite.lRC4 -text "mm" -anchor w -width $UNITS_WIDTH
        label $slitASite.lRD1 -text "glc:" -anchor e -width $LABEL_WIDTH
        label $slitASite.lRD4 -text "" -anchor w -width $UNITS_WIDTH
        label $slitASite.lRE1 -text "grc:" -anchor e -width $LABEL_WIDTH
        label $slitASite.lRE4 -text "" -anchor w -width $UNITS_WIDTH

        label $slitASite.flux1 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_flux]
        label $slitASite.flux2 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_flux]

        addEntries $slitASite $ENTRY_WIDTH \
        swmin_v swmin_h swmax_v swmax_h sglc_v sglc_h sgrc_v sgrc_h

        grid $slitASite.lRA1 \
        $slitASite.flux1 $slitASite.flux2 \
        $slitASite.lRA4 \
        -sticky news

        grid $slitASite.lRB1 \
        $itk_component(swmin_v) $itk_component(swmin_h) \
        $slitASite.lRB4 \
        -sticky news

        grid $slitASite.lRC1 \
        $itk_component(swmax_v) $itk_component(swmax_h) \
        $slitASite.lRC4 \
        -sticky news

        grid $slitASite.lRD1 \
        $itk_component(sglc_v) $itk_component(sglc_h) \
        $slitASite.lRD4 \
        -sticky news

        grid $slitASite.lRE1 \
        $itk_component(sgrc_v) $itk_component(sgrc_h) \
        $slitASite.lRE4 \
        -sticky news

        #####display
        pack $slitSite.title $slitSite.prepare $slitSite.scan \
        $slitSite.analysis \
        -side top -expand 1 -fill both


        iwidgets::Labeledframe $m_site.front \
        -labelfont "helvetica -16 bold" \
        -labeltext "Front End"
        set frontSite [$m_site.front childsite]

        iwidgets::Labeledframe $frontSite.title
        set frontTSite [$frontSite.title childsite]

        label $frontTSite.lC0 -text "    " -width $LABEL_WIDTH
        label $frontTSite.lC1 -text "Vertical" \
        -width $ENTRY_WIDTH -relief sunken
        label $frontTSite.lC2 -text "Horizontal" \
        -width $ENTRY_WIDTH -relief sunken
        label $frontTSite.lC3 -text "  "

        grid $frontTSite.lC0 \
        $frontTSite.lC1 $frontTSite.lC2 \
        $frontTSite.lC3 \
        -sticky news

        iwidgets::Labeledframe $frontSite.prepare \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -foreground blue \
        -labeltext "Prepare"
        set frontPSite [$frontSite.prepare childsite]

        label $frontPSite.lR11 -text "attenuation:" \
        -anchor e -width $LABEL_WIDTH

        label $frontPSite.lR14 -text "%" -anchor w -width $UNITS_WIDTH

        label $frontPSite.lR21 -text "beam width:" \
        -anchor e -width $LABEL_WIDTH

        label $frontPSite.lR24 -text "mm" -anchor w -width $UNITS_WIDTH

        label $frontPSite.lR31 -text "beam height:" \
        -anchor e -width $LABEL_WIDTH

        label $frontPSite.lR34 -text "mm" -anchor w -width $UNITS_WIDTH

        label $frontPSite.gapy \
        -anchor e \
        -background $color4BeamHeight \
        -width $ENTRY_WIDTH \
        -relief sunken \
        -textvariable [scope m_beamGapyUL]

        addEntries $frontPSite $ENTRY_WIDTH \
        vf_gap_h vf_gap_v hf_gap_h hf_gap_v fatten

        grid $frontPSite.lR11 \
        $itk_component(fatten) - \
        $frontPSite.lR14 \
        -sticky news
        
        grid $frontPSite.lR21 \
        $itk_component(vf_gap_h) $itk_component(hf_gap_h) \
        $frontPSite.lR24 \
        -sticky news
        
        grid $frontPSite.lR31 \
        $itk_component(vf_gap_v) $itk_component(hf_gap_v) \
        $frontPSite.lR34 \
        -sticky news


        iwidgets::Labeledframe $frontSite.scan \
        -labelpos nw \
        -labelfont "helvetica -16 bold" \
        -foreground blue \
        -labeltext "Scan Parameters"
        set frontSSite [$frontSite.scan childsite]

        label $frontSSite.lR51 -text "signal:" \
        -anchor e -width $LABEL_WIDTH

        label $frontSSite.lR61 -text "num of points:" \
        -anchor e -width $LABEL_WIDTH

        label $frontSSite.lR71 -text "step size:" \
        -anchor e -width $LABEL_WIDTH

        label $frontSSite.lR74 -text "mm" -anchor w -width $UNITS_WIDTH

        label $frontSSite.lR81 -text "time at point:" \
        -anchor e -width $LABEL_WIDTH

        label $frontSSite.lR84 -text "s" -anchor w -width $UNITS_WIDTH

        addEntries $frontSSite $ENTRY_WIDTH \
        fsig fnum_v fnum_h fstep_v fstep_h ftime_v ftime_h

        itk_component add sigmb {
            menubutton $frontSSite.sigmb \
            -menu $frontSSite.sigmb.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised
        } {
        }
        itk_component add sigmn {
            menu $frontSSite.sigmb.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }

        foreach s $m_sigList {
            $itk_component(sigmn) add command \
            -label $s \
            -command "$this setSignal $s"
        }

        grid $frontSSite.lR51 \
        $itk_component(fsig) - \
        $itk_component(sigmb) \
        -sticky news

        grid $frontSSite.lR61 \
        $itk_component(fnum_v) $itk_component(fnum_h) \
        -sticky news

        grid $frontSSite.lR71 \
        $itk_component(fstep_v) $itk_component(fstep_h) \
        $frontSSite.lR74 \
        -sticky news

        grid $frontSSite.lR81 \
        $itk_component(ftime_v) $itk_component(ftime_h) \
        $frontSSite.lR84 \
        -sticky news

        iwidgets::Labeledframe $frontSite.analysis \
        -labelfont "helvetica -16 bold" \
        -labelpos nw \
        -foreground blue \
        -labeltext "Peak Analysis Parameters"
        set frontASite [$frontSite.analysis childsite]

        label $frontASite.lRA1 -text "flux:" \
        -anchor e -width $LABEL_WIDTH

        label $frontASite.lRA4 -text "" -anchor w -width $UNITS_WIDTH

        label $frontASite.lRB1 -text "wmin:" \
        -anchor e -width $LABEL_WIDTH

        label $frontASite.lRB4 -text "mm" -anchor w -width $UNITS_WIDTH

        label $frontASite.lRC1 -text "wmax:" \
        -anchor e -width $LABEL_WIDTH

        label $frontASite.lRC4 -text "mm" -anchor w -width $UNITS_WIDTH

        label $frontASite.lRD1 -text "glc:" \
        -anchor e -width $LABEL_WIDTH

        label $frontASite.lRD4 -text "" -anchor w -width $UNITS_WIDTH

        label $frontASite.lRE1 -text "grc:" \
        -anchor e -width $LABEL_WIDTH

        label $frontASite.lRE4 -text "" -anchor w -width $UNITS_WIDTH

        label $frontASite.flux1 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_flux]
        label $frontASite.flux2 \
        -anchor e \
        -background $color4OptimizeEnergyParam \
        -relief sunken \
        -textvariable [scope m_flux]

        addEntries $frontASite $ENTRY_WIDTH \
        fwmin_v fwmin_h fwmax_v fwmax_h fglc_v fglc_h fgrc_v fgrc_h

        grid $frontASite.lRA1 \
        $frontASite.flux1 $frontASite.flux2 \
        $frontASite.lRA4 \
        -sticky news

        grid $frontASite.lRB1 \
        $itk_component(fwmin_v) $itk_component(fwmin_h) \
        $frontASite.lRB4 \
        -sticky news

        grid $frontASite.lRC1 \
        $itk_component(fwmax_v) $itk_component(fwmax_h) \
        $frontASite.lRC4 \
        -sticky news

        grid $frontASite.lRD1 \
        $itk_component(fglc_v) $itk_component(fglc_h) \
        $frontASite.lRD4 \
        -sticky news

        grid $frontASite.lRE1 \
        $itk_component(fgrc_v) $itk_component(fgrc_h) \
        $frontASite.lRE4 \
        -sticky news

        pack $frontSite.title $frontSite.prepare $frontSite.scan $frontSite.analysis -side top -expand 1 -fill both

        grid $m_site.top - -sticky we
        grid $m_site.slit $m_site.front -sticky news

        mediator register $this ::device::optimizedEnergyParameters \
        contents handleOptimizedEnergyParamEvent

		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist
    }
    destructor {
        mediator unregister $this ::device::optimizedEnergyParameters \
        contents
    }
    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        ### all field should be a number except signal should be one of
        ### ion chambers

        ### you can add auto fix here, too.

        foreach value $contents name $m_cntsNameString {
            if {$name == "align_front_ion_chamber"} {
                if {[lsearch -exact $m_sigList $value] < 0} {
                    log_error $value is not a valid ion chamber
                    return 0
                }
            } elseif {$name != ""} {
                if {![string is double -strict $value]} {
                    log_error $name=$value is not a number
                    return 0
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }
}
body DCS::AlignFrontEndConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name keyword} $m_entryMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }
}
body DCS::AlignFrontEndConfigView::handleOptimizedEnergyParamEvent { \
- ready_ - contents_ - \
} {
    if {!$ready_} return

    set flux [lindex $contents_ 14]
    set sig  [lindex $contents_ 18]
    set time [lindex $contents_ 24]

    set m_time $time
    set m_flux $flux
    set m_signal $sig
}
class DCS::StringValueNamePairView {
	inherit ::DCS::StringFieldView

	itk_option define -nameStringName nameStringName StringName ""

    constructor { args } {
		eval itk_initialize $args
		announceExist
    }
}
configbody DCS::StringValueNamePairView::nameStringName {
    set objName $itk_option(-nameStringName)
    if {$objName != ""} {
        set nameList [$objName getContents]
        configure -fieldNameList $nameList
    }
}
class DCS::SampleCameraParamView {
    inherit ::DCS::StringValueNamePairView

    private variable m_objOp
    public method start { } {
        $m_objOp startOperation
    }
    public method handleHelp { } {
        if {[catch "openWebWithBrowser [::config getStr document.calibrate_sample_camera]" err_msg]} {
            log_error "start mozilla failed: $err_msg"
        } else {
            bind $itk_component(note) <Button-1> ""
            after 20000 "bind $itk_component(note) <Button-1> {$this handleHelp}"
        }
    }

    constructor { strName args } {
        ::DCS::StringValueNamePairView::constructor \
        -stringName ::device::$strName \
    } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objOp [$deviceFactory createOperation calibrateSampleCamera]

        set mList [::config getStr sampleCameraConstantsNameList]
        puts "mList: $mList"
        configure -fieldNameList $mList
        
        itk_component add start {
            ::DCS::HotButton $m_site.start \
            -text "Calibrate Sample Camera" \
            -confirmText "Confirm to start" \
            -width 23 \
            -command "$this start"
        } {
        }

        itk_component add note {
            label $m_site.note \
            -foreground blue \
            -text "https://smb.slac.stanford.edu/wiki/\nInstallation_of_the_Camera_on_the_Beamline\n#Setting_the_Click-to-center_zoom_parameters"
        } {
        }

        bind $itk_component(note) <Button-1> "$this handleHelp"

        grid $itk_component(start) -column 2 -row 1
        grid $itk_component(note)  -column 2 -row 2 -rowspan 3
    }
}
class DCS::EnergyOffsetLevel2View {
	inherit ::DCS::StringFieldLevel2ViewBase

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set allDouble 1
        foreach v1 $contents {
            foreach v2 $v1 {
                if {![string is double -strict $v2]} {
                    set allDouble 0
                }
            }
        }
        return $allDouble
    }
    constructor { args } {
    } {
        ## change to config later for both harmonic names and
        ## offset field motor names
        set ROWHEADER [list 11th 9th 7th 5th]
        set COLUMNHEADER [::config getStr energyOffsetNameList]

        set numRow [llength $ROWHEADER]
        set numCol [llength $COLUMNHEADER]

        set idxTrigger   [lsearch -exact $COLUMNHEADER trigger_time]
        set idxTimestamp [lsearch -exact $COLUMNHEADER timestamp]

        ######### header labels ###############
        set i 0
        foreach rh $ROWHEADER {
            label $m_site.rh$i -text $rh
            grid $m_site.rh$i -row [expr $i + 1] -column 0

            incr i
        }
        set i 0
        foreach ch $COLUMNHEADER {
            label $m_site.ch$i -text $ch
            grid $m_site.ch$i -row 0 -column [expr $i + 1]

            incr i
        }

        ######## create all the fields ##########
        set m_entryList ""
        for {set row 0} {$row < $numRow} {incr row} {
            for {set col 0} {$col < $numCol} {incr col} {
                if {$col == $idxTimestamp || $col == $idxTrigger} {
                    set name ts_${row}${col}
                    itk_component add $name {
                        label $m_site.$name \
                        -anchor e \
                        -background #00a040 \
                        -width 17 \
                    } {
                    }
                    lappend m_labelList $name $row $col
                } else {
                    set name f${row}${col}
                    set cmd [list $this updateEntryColor $name $row $col %P]
                    itk_component add $name {
                        entry $m_site.$name \
                        -validate all \
                        -background white \
                        -vcmd $cmd
                    } {
                    }
                    lappend m_entryList $name $row $col
                }
                grid $m_site.$name -row [expr $row + 1] -column [expr $col + 1]
            }
        }

        set hideIdxList [list]
        foreach name {focusing_mirror_2_vert_1 focusing_mirror_2_vert_2} {
            set idx [lsearch -exact $COLUMNHEADER $name]
            if {$idx >= 0} {
                lappend hideIdxList $idx
            }
        }
        foreach idx $hideIdxList {
            set col [expr $idx + 1]
            set oneCol [grid slaves $m_site -column $col]
            if {$oneCol != ""} {
                eval grid remove $oneCol
            }
        }


        #puts "level2 entryList: $m_entryList"
		eval itk_initialize $args
		announceExist
    }
}
class DCS::AlignCollimatorConfigView {
	inherit ::DCS::StringFieldMixLevelViewBase

    public method setSignal { name } {
        $itk_component(signal) delete 0 end
        $itk_component(signal) insert 0 $name
    }
    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        ### all field should be a number except signal should be one of
        ### ion chambers

        ### you can add auto fix here, too.

        foreach value $contents name $m_cntsNameString {
            if {$name == "signal"} {
                if {[lsearch -exact $m_sigList $value] < 0} {
                    log_error $value is not a valid ion chamber
                    return 0
                }
            } elseif {$name != ""} {
                foreach vv $value {
                    if {![string is double -strict $vv]} {
                        log_error one of $name=$vv is not a number
                        return 0
                    }
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }

    ###will be overwriten in constructor
    protected variable m_sigList ""
    protected variable m_cntsNameString ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
        at11        {attenuation 0} \
        at9         {attenuation 1} \
        at7         {attenuation 2} \
        at5         {attenuation 3} \
        fl          fluorescence_z \
        signal      signal \
        mp          min_signal \
        gp          good_signal \
        hw          horz_scan_width \
        hp          horz_scan_points \
        hi          horz_scan_time \
        hs          horz_scan_wait \
        vw          vert_scan_width \
        vp          vert_scan_points \
        vi          vert_scan_time \
        vs          vert_scan_wait \
        mv          max_vert_move \
        mh          max_horz_move \
        shw         staff_horz_scan_width \
        shp         staff_horz_scan_points \
        svw         staff_vert_scan_width \
        svp         staff_vert_scan_points \
    ]

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::alignCollimator_constant
    } {
        set beamNotSlit 1

        set LABEL_WIDTH 15
        set ENTRY_WIDTH 10
        set UNITS_WIDTH 3

        set m_cntsNameString [::config getStr alignCollimatorConstantsNameList]
        puts "namelist $m_cntsNameString"

        array set m_menubuttonIndex [list]
        if {[catch {
            set deviceFactory [DCS::DeviceFactory::getObject]
            set m_sigList [$deviceFactory getSignalList]
        } errMsg] || $m_sigList == ""} {
            log_error failed to retrieve ion chamber list, default to i0, i1, i2
            set m_sigList [list i0 i1 i2]
        }

        itk_component add top_frame {
            iwidgets::Labeledframe $m_site.top \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Global Parameters"
        } {
        }
        set topSite [$itk_component(top_frame) childsite]

        label $topSite.l3 -anchor e -width $LABEL_WIDTH -text "Attenuation 11th:"
        label $topSite.l4 -anchor e -width $LABEL_WIDTH -text "9th:"
        label $topSite.l5 -anchor e -width $LABEL_WIDTH -text "7th:"
        label $topSite.l6 -anchor e -width $LABEL_WIDTH -text "5th:"
        label $topSite.l7 -anchor e -width $LABEL_WIDTH -text "Fluor. Z:"
        label $topSite.l8 -anchor e -width $LABEL_WIDTH -text "Signal:"
        label $topSite.l9 -anchor e -width $LABEL_WIDTH -text "Min Peak:"
        label $topSite.l10 -anchor e -width $LABEL_WIDTH -text "Good Peak:"
        label $topSite.l13 -anchor e -width $LABEL_WIDTH -text "Max Vert Move:"
        label $topSite.l14 -anchor e -width $LABEL_WIDTH -text "Max Horz Move:"

        label $topSite.u3 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u4 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u5 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u6 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u7 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u13 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u14 -anchor w -width $UNITS_WIDTH -text mm

        itk_component add sigmb {
            menubutton $topSite.sigmb \
            -menu $topSite.sigmb.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised
        } {
        }
        itk_component add sigmn {
            menu $topSite.sigmb.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }

        foreach s $m_sigList {
            $itk_component(sigmn) add command \
            -label $s \
            -command "$this setSignal $s"
        }

        addEntries $topSite $ENTRY_WIDTH \
        at11 at9 at7 at5 fl signal mp gp mv mh

        grid $topSite.l3 -column 0 -row 3 -sticky e
        grid $topSite.l4 -column 0 -row 4 -sticky e
        grid $topSite.l5 -column 0 -row 5 -sticky e
        grid $topSite.l6 -column 0 -row 6 -sticky e
        grid $topSite.l7 -column 0 -row 7 -sticky e
        grid $topSite.l8 -column 0 -row 8 -sticky e
        grid $topSite.l9 -column 0 -row 9 -sticky e
        grid $topSite.l10 -column 0 -row 10 -sticky e
        grid $topSite.l13 -column 0 -row 13 -sticky e
        grid $topSite.l14 -column 0 -row 14 -sticky e

        grid $itk_component(at11) -column 1 -row 3 -sticky we
        grid $itk_component(at9) -column 1 -row 4 -sticky we
        grid $itk_component(at7) -column 1 -row 5 -sticky we
        grid $itk_component(at5) -column 1 -row 6 -sticky we
        grid $itk_component(fl) -column 1 -row 7 -sticky we
        grid $itk_component(signal) -column 1 -row 8 -sticky we
        grid $itk_component(mp) -column 1 -row 9 -sticky we
        grid $itk_component(gp) -column 1 -row 10 -sticky we
        grid $itk_component(mv) -column 1 -row 13 -sticky we
        grid $itk_component(mh) -column 1 -row 14 -sticky we

        grid $topSite.u3 -column 2 -row 3 -sticky w
        grid $topSite.u4 -column 2 -row 4 -sticky w
        grid $topSite.u5 -column 2 -row 5 -sticky w
        grid $topSite.u6 -column 2 -row 6 -sticky w
        grid $topSite.u7 -column 2 -row 7 -sticky w
        grid $itk_component(sigmb) -column 2 -row 8 -sticky w
        grid $topSite.u13 -column 2 -row 13 -sticky w
        grid $topSite.u14 -column 2 -row 14 -sticky w

        itk_component add horz_frame {
            iwidgets::Labeledframe $m_site.horz \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Horizontal Scan Parameters"
        } {
        }
        set horzSite [$itk_component(horz_frame) childsite]

        label $horzSite.l01 -text "USER"
        label $horzSite.l02 -text "STAFF"
        label $horzSite.l1 -anchor e -width $LABEL_WIDTH -text "Width"
        label $horzSite.l2 -anchor e -width $LABEL_WIDTH -text "Points"
        label $horzSite.l3 -anchor e -width $LABEL_WIDTH -text "Integrating Time"
        label $horzSite.l4 -anchor e -width $LABEL_WIDTH -text "Settling Time"

        label $horzSite.u1 -anchor w -width $UNITS_WIDTH -text "mm"
        label $horzSite.u3 -anchor w -width $UNITS_WIDTH -text "s"
        label $horzSite.u4 -anchor w -width $UNITS_WIDTH -text "s"

        addEntries $horzSite $ENTRY_WIDTH hw hp hi hs shw shp

        grid $horzSite.l01 -column 1 -row 0 -sticky w
        grid $horzSite.l02 -column 2 -row 0 -sticky w

        grid $horzSite.l1 -column 0 -row 1 -sticky e
        grid $horzSite.l2 -column 0 -row 2 -sticky e
        grid $horzSite.l3 -column 0 -row 3 -sticky e
        grid $horzSite.l4 -column 0 -row 4 -sticky e

        grid $itk_component(hw) -column 1 -row 1 -sticky we
        grid $itk_component(hp) -column 1 -row 2 -sticky we
        grid $itk_component(hi) -column 1 -row 3 -sticky we
        grid $itk_component(hs) -column 1 -row 4 -sticky we

        grid $itk_component(shw) -column 2 -row 1 -sticky we
        grid $itk_component(shp) -column 2 -row 2 -sticky we

        grid $horzSite.u1 -column 3 -row 1 -sticky w
        grid $horzSite.u3 -column 2 -row 3 -sticky w
        grid $horzSite.u4 -column 2 -row 4 -sticky w

        itk_component add vert_frame {
            iwidgets::Labeledframe $m_site.vert \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Vertical Scan Parameters"
        } {
        }
        set vertSite [$itk_component(vert_frame) childsite]

        label $vertSite.l01 -text "USER"
        label $vertSite.l02 -text "STAFF"
        label $vertSite.l1 -anchor e -width $LABEL_WIDTH -text "Width"
        label $vertSite.l2 -anchor e -width $LABEL_WIDTH -text "Points"
        label $vertSite.l3 -anchor e -width $LABEL_WIDTH -text "Integrating Time"
        label $vertSite.l4 -anchor e -width $LABEL_WIDTH -text "Settling Time"

        label $vertSite.u1 -anchor w -width $UNITS_WIDTH -text "mm"
        label $vertSite.u3 -anchor w -width $UNITS_WIDTH -text "s"
        label $vertSite.u4 -anchor w -width $UNITS_WIDTH -text "s"

        addEntries $vertSite $ENTRY_WIDTH vw vp vi vs svw svp

        grid $vertSite.l01 -column 1 -row 0 -sticky w
        grid $vertSite.l02 -column 2 -row 0 -sticky w

        grid $vertSite.l1 -column 0 -row 1 -sticky e
        grid $vertSite.l2 -column 0 -row 2 -sticky e
        grid $vertSite.l3 -column 0 -row 3 -sticky e
        grid $vertSite.l4 -column 0 -row 4 -sticky e

        grid $itk_component(vw) -column 1 -row 1 -sticky we
        grid $itk_component(vp) -column 1 -row 2 -sticky we
        grid $itk_component(vi) -column 1 -row 3 -sticky we
        grid $itk_component(vs) -column 1 -row 4 -sticky we

        grid $itk_component(svw) -column 2 -row 1 -sticky we
        grid $itk_component(svp) -column 2 -row 2 -sticky we

        grid $vertSite.u1 -column 3 -row 1 -sticky w
        grid $vertSite.u3 -column 2 -row 3 -sticky w
        grid $vertSite.u4 -column 2 -row 4 -sticky w

        grid $itk_component(top_frame) -row 0 -column 0 -rowspan 2 -sticky news
        grid $itk_component(horz_frame) -row 0 -column 1 -sticky news
        grid $itk_component(vert_frame) -row 1 -column 1 -sticky news

        grid rowconfigure $m_site 0 -weight 5
        grid rowconfigure $m_site 1 -weight 5
        grid columnconfigure $m_site 2 -weight 5

		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist

    }
}
body DCS::AlignCollimatorConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name mm} $m_entryMap {
        set keyword [lindex $mm 0]
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            set index [lreplace $mm 0 0 $index]
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }
}
#### it will adjust rows according to how many items in the string
#### It was replaced by TabView.
#### Then, it is used by staff view to display some information related
#### to staff scan:
###  width
###  height
###  user_scan width
###  user_scan_points
###  staff_scan_width
###  staff_scan_points
###  selected for each harmonic.
#######
###  It only display the collimators that user can see.
class DCS::CollimatorPresetLevel2View {
	inherit ::DCS::StringFieldMixLevelViewBase

    public method staffStart { } {
        $m_opStaffAlignBeam startOperation
    }

    public method updateShowAll { } {
        set oneColumn ""
        for {set col 0} {$col < $m_numColumnDisplayed} {incr col} {
            regsub -all COLUMN $m_oneColumnList $col oneColumn

            set h0 $gCheckButtonVar($this,harm0$col)
            set h1 $gCheckButtonVar($this,harm1$col)
            set h2 $gCheckButtonVar($this,harm2$col)
            set h3 $gCheckButtonVar($this,harm3$col)

            set shouldShow 0
            if {$h0 == "1" || $h1 == "1" || $h2 == "1" || $h3 == "1"} {
                set shouldShow 1
            }

            if {$gCheckButtonVar($this,showAll) || $shouldShow} {
                foreach com $oneColumn {
                    grid $itk_component($com)
                }
            } else {
                foreach com $oneColumn {
                    grid remove $itk_component($com)
                }
            }
        }
    }

    public method handleStatusChange { - targetReady_ - contents_ - } {
        if {!$targetReady_} {
            ### no match
            set contents_ "-1 -1 0 0"
        }

        set indexMatched [lindex $contents_ 1]
        if {![string is integer -strict $indexMatched]} {
            set indexMatched -1
        }
        for {set i 0} {$i < $m_numColumnCreated} {incr i} {
            if {$i == $indexMatched} {
                set bg "light green"
            } else {
                set bg $m_colorBG
            }
            $itk_component(name$i) configure \
            -background $bg
        }
    }
    public method handleCurrentHarmonic { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }

        if {![string is integer -strict $contents_]} {
            set currentRow -1
        } else {
            set currentRow [expr $contents_ + 9]
        }
        set headerSite  [$itk_component(scrolledFrame) hfreezesite]
        for {set i 9} {$i < 13} {incr i} {
            if {$i == $currentRow} {
                set bg "light green"
            } else {
                set bg $m_origLabelBG
            }
            $headerSite.rh$i configure \
            -background $bg
        }
    }

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        return 1

    }

    private method addColumns { num } {
        for {set i 0} {$i < $num} {incr i} {
            set index1 $m_numColumnCreated
            foreach {comp -} $LABEL_MAP subIdxList $m_labelSubIndexList {
                set wName $comp$m_numColumnCreated
                set indexList [linsert $subIdxList 0 $index1]

                if {$comp == "width" || $comp == "height"} {
                    set bg tan
                } else {
                    set bg gray
                }
                itk_component add $wName {
                    label $m_tableSite.$wName \
                    -relief sunken \
                    -anchor w \
                    -background $bg \
                } {
                }
                if {$m_colorBG == ""} {
                    set m_colorBG [$itk_component($wName) cget -background]
                }
            }

            foreach \
            {comp - -} $LABEL_ENTRY_MAP \
            {lSubIdxList eSubIdxList} $m_labelEntryIndexList {
                set wName $comp$m_numColumnCreated
                itk_component add $wName {
                    frame $m_tableSite.$wName
                } {
                }
                set mySite $m_tableSite.$wName

                set lName ${comp}l$m_numColumnCreated
                set indexList [linsert $lSubIdxList 0 $index1]
                
                itk_component add $lName {
                    label $mySite.label \
                    -relief sunken \
                    -anchor w \
                    -background #00a040 \
                } {
                }

                set eName ${comp}e$m_numColumnCreated
                set indexList [linsert $eSubIdxList 0 $index1]
                set cmd [list $this updateEntryColor $eName $indexList %P]
                itk_component add $eName {
                    entry $mySite.entry \
                    -validate all \
                    -vcmd $cmd \
                    -width 7 \
                    -background white \
                } {
                }
                grid $itk_component($lName) -row 0 -column 0 -sticky news
                grid $itk_component($eName) -row 0 -column 1 -sticky news
                grid columnconfigure $mySite 0 -weight 10
                #grid columnconfigure $mySite 1 -weight 10
            }

            foreach {comp -} $CHECKBUTTON_MAP \
            subIdxList $m_checkbuttonSubIndexList {
                set wName $comp$m_numColumnCreated
                set indexList [linsert $subIdxList 0 $index1]
                set cmd [list $this updateCheckButtonColor $wName $indexList]
                itk_component add $wName {
                    checkbutton $m_tableSite.$wName \
                    -command $cmd \
                    -background darkgray \
                    -anchor w \
                    -variable [scope gCheckButtonVar($this,$wName)] \
                    -text "yes"
                } {
                }
            }

            incr m_numColumnCreated
        }
        pack $itk_component(scrolledFrame) -side left -fill both -expand true
    }
    private method adjustColumns { num } {
        if {$num == $m_numColumnDisplayed} {
            return
        }
        if {$num > $m_numColumnCreated} {
            addColumns [expr $num - $m_numColumnCreated]
        }

        while {$m_numColumnDisplayed < $num} {
            set col $m_numColumnDisplayed

            foreach \
            {comp -}   $LABEL_MAP \
            subIdxList $m_labelSubIndexList \
            row        $LABEL_ROW {
                set wName $comp$m_numColumnDisplayed
                set indexList [linsert $subIdxList 0 $col]
                lappend m_labelList $wName $indexList

                grid $itk_component($wName) \
                -ipady 1 \
                -column [expr $col + 1] \
                -row $row \
                -sticky news
            }

            foreach \
            {comp - -}   $LABEL_ENTRY_MAP \
            {lSubIdxList eSubIdxList} $m_labelEntryIndexList \
            row        $LABEL_ENTRY_ROW {
                set wName ${comp}$m_numColumnDisplayed
                set lName ${comp}l$m_numColumnDisplayed
                set eName ${comp}e$m_numColumnDisplayed

                set indexList [linsert $lSubIdxList 0 $col]
                lappend m_labelList $lName $indexList

                set indexList [linsert $eSubIdxList 0 $col]
                lappend m_entryList $eName $indexList

                grid $itk_component($wName) \
                -column [expr $col + 1] \
                -row $row \
                -sticky news
            }
            foreach \
            {comp -}   $CHECKBUTTON_MAP \
            subIdxList $m_checkbuttonSubIndexList \
            row        $CHECKBUTTON_ROW {
                set wName $comp$m_numColumnDisplayed
                set indexList [linsert $subIdxList 0 $col]
                lappend m_checkbuttonList $wName $indexList

                grid $itk_component($wName) \
                -column [expr $col + 1] \
                -row $row \
                -sticky news
            }

            incr m_numColumnDisplayed
        }

        set need_cleanList 0
        if {$m_numColumnDisplayed > $num} {
            set need_cleanList 1
        }
        while {$m_numColumnDisplayed > $num} {
            set col $m_numColumnDisplayed
            set slaves [grid slaves $m_tableSite -column $col]
            if {$slaves != ""} {
                eval grid forget $slaves
            }
            incr m_numColumnDisplayed -1
        }
        if {$need_cleanList} {
            ### clean up list (not efficient)
            set old $m_labelList
            set m_labelList [list]
            foreach {name idxList} $old {
                set col [lindex $idxList 1]
                if {$col < $num} {
                    lappend m_labelList $name $idxList
                }
            }

            set old $m_entryList
            set m_entryList [list]
            foreach {name idxList} $old {
                set col [lindex $idxList 1]
                if {$col < $num} {
                    lappend m_entryList $name $idxList
                }
            }

            set old $m_checkbuttonList
            set m_checkbuttonList [list]
            foreach {name idxList} $old {
                set col [lindex $idxList 1]
                if {$col < $num} {
                    lappend m_checkbuttonList $name $idxList
                }
            }
        }
        pack $itk_component(scrolledFrame) -side left -fill both -expand true
    }

    ##override base class
    protected method setContents { contents_ } {
        set ll [llength $contents_]

        adjustColumns $ll

	    DCS::StringFieldMixLevelViewBase::setContents $contents_

        updateShowAll
    }

    private common HEAD_LABEL [list \
    Name \
    "Display to User" \
    "Is Micro-Pinhole" \
    Width \
    "Scan Width" \
    "Scan Horz Points" \
    Height \
    "Scan Height" \
    "Scan Vert Points" \
    "Enable Harmonic 11th" \
    "Enable Harmonic 9th" \
    "Enable Harmonic 7th" \
    "Enable Harmonic 5th" \
    ]

    private common LABEL_MAP [list \
        name            name \
        display         display \
        is_micro_beam   is_micron_beam \
        width           width \
        height          height \
    ]
    private common LABEL_ROW [list 0 1 2 3 6]

    private common LABEL_ENTRY_MAP [list \
        scanWidth   horz_scan_width \
                    staff_horz_scan_width \
        scanWPoints horz_scan_points \
                    staff_horz_scan_points \
        scanHeight  vert_scan_width \
                    staff_vert_scan_width \
        scanHPoints vert_scan_points \
                    staff_vert_scan_points \
    ]
    private common LABEL_ENTRY_ROW [list 4 5 7 8]

    private common CHECKBUTTON_MAP [list \
        harm0           {staff_scan_enable 0} \
        harm1           {staff_scan_enable 1} \
        harm2           {staff_scan_enable 2} \
        harm3           {staff_scan_enable 3} \
    ]
    private common CHECKBUTTON_ROW [list 9 10 11 12]

    private variable m_numColumnCreated 0
    private variable m_numColumnDisplayed 0
    private variable m_cfgNameList ""
    private variable m_cfgScanNameList ""

    private variable m_oneColumnList ""

    private variable m_opStaffAlignBeam ""
    private variable m_opCollimatorMove ""
    private variable m_strCollimatorStatus ""
    private variable m_colorBG ""
    private variable m_origLabelBG gray

    private variable m_tableSite ""

    private variable m_labelSubIndexList ""
    private variable m_labelEntryIndexList ""
    private variable m_checkbuttonSubIndexList ""

    constructor { args } {
    } {
        set m_cfgNameList [::config getStr collimatorPresetNameList]
        set m_cfgScanNameList [::config getStr alignCollimatorConstantsNameList]

        array set fName2index [list]
        array set sName2index [list]
        foreach {comp name} $LABEL_MAP {
            set fName [lindex $name 0]
            if {![info exists fName2index($fName)]} {
                set fName2index($fName) [lsearch -exact $m_cfgNameList $fName]
            }
            set idxList $fName2index($fName)
            if {$fName == "scan_parameter"} {
                set sName [lindex $name 1]
                if {![info exists sName2index($sName)]} {
                    set sName2index($sName) \
                    [lsearch -exact $m_cfgScanNameList $sName]
                }
                lappend idxList $sName2index($sName)
            }

            lappend m_labelSubIndexList $idxList

            lappend m_oneColumnList ${comp}COLUMN
        }
        set idxScan [lsearch -exact $m_cfgNameList scan_parameter]
        foreach {comp lName eName} $LABEL_ENTRY_MAP {
            if {![info exists sName2index($lName)]} {
                set sName2index($lName) \
                [lsearch -exact $m_cfgScanNameList $lName]
            }
            if {![info exists sName2index($eName)]} {
                set sName2index($eName) \
                [lsearch -exact $m_cfgScanNameList $eName]
            }

            lappend m_labelEntryIndexList [list $idxScan $sName2index($lName)]
            lappend m_labelEntryIndexList [list $idxScan $sName2index($eName)]

            lappend m_oneColumnList ${comp}COLUMN
        }
        foreach {comp name } $CHECKBUTTON_MAP {
            set fName [lindex $name 0]
            if {![info exists fName2index($fName)]} {
                set fName2index($fName) [lsearch -exact $m_cfgNameList $fName]
            }
            set idxList $fName2index($fName)
            lappend idxList [lindex $name 1]

            lappend m_checkbuttonSubIndexList $idxList

            lappend m_oneColumnList ${comp}COLUMN
        }

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_opStaffAlignBeam [$deviceFactory createOperation staffAlignBeam]
        set m_opCollimatorMove [$deviceFactory createOperation collimatorMove]
        set m_strCollimatorStatus \
        [$deviceFactory getObjectName collimator_status]

        set strCurrentHarmonic  [$deviceFactory getObjectName currentHarmonic]

        itk_component add scrolledFrame {
            DCS::ScrolledFrame $m_site.canvas \
            -vscrollmode static \
            -hscrollmode static
        } {
        }

        set m_tableSite [$itk_component(scrolledFrame) childsite]
        set headerSite  [$itk_component(scrolledFrame) hfreezesite]

        set i -1
        foreach txt $HEAD_LABEL {
            incr i

            label $headerSite.rh$i \
            -anchor e \
            -text $txt

            grid $headerSite.rh$i -row $i -column 0 -sticky e -ipady 1
        }
        set m_origLabelBG [$headerSite.rh0 cget -background]

        incr i
        set gCheckButtonVar($this,showAll) 0
        checkbutton $headerSite.showAll \
        -text "Show All" \
        -variable [scope gCheckButtonVar($this,showAll)] \
        -command "$this updateShowAll"
        grid $headerSite.showAll -row $i -column 0 -stick e -ipady 4


        grid columnconfigure $headerSite 0 -weight 1

        pack $itk_component(scrolledFrame) -side left -fill both -expand true
        $itk_component(scrolledFrame) xview moveto 0
        $itk_component(scrolledFrame) yview moveto 0

        itk_component add staffStart {
            DCS::Button $itk_interior.staffStart \
            -text "Start Staff Align Beam" \
            -command "$this staffStart" \
        } {
        }

        grid $itk_component(staffStart) -row 2 -column 0 -columnspan 2

		eval itk_initialize $args
		announceExist

        ::mediator register $this $m_strCollimatorStatus contents \
        handleStatusChange

        ::mediator register $this $strCurrentHarmonic    contents \
        handleCurrentHarmonic

        updateShowAll
    }
}
class DCS::UserAlignBeamStatusView {
	inherit ::DCS::StringFieldViewBase

    private variable m_opUserAlignBeam ""

	public method startAll { } {
        $m_opUserAlignBeam startOperation forced
    }

    ###override base class method
    protected method onFieldChange { name index value } {
        switch -exact -- $name {
            "enable_t" {
                if {$value && $gCheckButtonVar($this,enable_c)} {
                    $itk_component(enable_c) invoke
                }
            }
            "enable_c" {
                if {$value && $gCheckButtonVar($this,enable_t)} {
                    $itk_component(enable_t) invoke
                }
            }
        }
    }
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set ll [llength $contents]
        if {$ll < 6} {
            log_error contents length wrong $ll < 6
            return 0
        }
        return 1
    }

    constructor { args } {
    } {
        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_opUserAlignBeam [$deviceFactory createOperation userAlignBeam]

        itk_component add startAll {
            DCS::Button $m_site.startAll -command "$this startAll" \
            -text "Optimize Beam"
        } {}
        $itk_component(startAll) addInput \
        "$m_opUserAlignBeam permission GRANTED {PERMISSION}"

        $itk_component(startAll) addInput \
        "$m_opUserAlignBeam status inactive {supporting device}"

        set m_checkbuttonList [list \
        enable_t 0 \
        enable_c 1 \
        ]

        set m_entryList [list \
        span_t 2 \
        span_c 3 \
        ]

        set m_labelList [list \
        ti_t 2 \
        ti_c 3 \
        ]

        ######create entries
        foreach {name index} $m_entryList {
            set cmd [list $this updateEntryColor $name $index %P]
            itk_component add $name {
                entry $m_site.$name \
                -font "helvetica -12 bold" \
                -justify right \
                -width 10 \
                -background white \
                -validate all \
                -vcmd $cmd
            } {
            }
            set m_origEntryBG [$itk_component($name) cget -background]
		    registerComponent $itk_component($name)
        }

        foreach {name index} $m_checkbuttonList {
            set cmd [list $this updateCheckButtonColor $name $index]
            itk_component add $name {
                checkbutton  $m_site.$name \
                -anchor w \
                -variable [scope gCheckButtonVar($this,$name)] \
                -command $cmd \
                -text Enable \
            } {
            }
            set m_origCheckButtonFG [$itk_component($name) cget -foreground]
		    registerComponent $itk_component($name)
        }

        foreach {name index} $m_labelList {
            itk_component add $name {
                label  $m_site.$name \
                -anchor e \
                -background #00a040 \
                -text $name
            } {
            }
        }

        itk_component add triggerTime {
            DCS::TriggerTimeForUserAlignBeam $m_site.triggerTime \
            -stringName ::device::collimator_preset \
        } {
            keep -mdiHelper
        }

        label $m_site.ll01 -text Tungsten
        label $m_site.ll02 -text "Tungsten+Collimator"

        label $m_site.ll20 -anchor e -text "Time Span (seconds)"
        label $m_site.ll30 -anchor e -text "Time Span"

        grid $itk_component(startAll) $m_site.ll01 $m_site.ll02
        grid ^            $itk_component(enable_t) $itk_component(enable_c)
        grid $m_site.ll20 $itk_component(span_t)   $itk_component(span_c) -sticky news -padx 2 -pady 2
        grid $m_site.ll30 $itk_component(ti_t)     $itk_component(ti_c) -sticky news -padx 2 -pady 2
        grid $itk_component(triggerTime) -sticky news -padx 1 -pady 2 \
        -columnspan 5

        grid columnconfigure $m_site 4 -weight 10
        #grid rowconfigure    $m_site 6 -weight 10

		eval itk_initialize $args
		announceExist
        configure \
        -stringName ::device::user_align_beam_status

        $itk_component(startAll) addInput \
        "::device::user_align_beam_status anyEnabled 1 {Enable Alignment First}"
    }
}
class DCS::CassetteBarcodeView {
	inherit ::DCS::StringFieldViewBase

    itk_option define -onClick onClick OnClick ""

    public method handleBarcodeClick { label_name_ } {
        set cmd $itk_option(-onClick)
        if {$cmd != ""} {
            set barcode [$itk_component($label_name_) cget -text]
            if {[catch {
                eval $cmd $barcode
            } errMsg]} {
                puts "call -onClick failed: $errMsg"
            }
        }
    }

    public method handleScanIdConfigUpdate

    public method flipAllButton { } {
        if {$gCheckButtonVar($this,all)} {
            set newContents "1 1 1"
        } else {
            set newContents "0 0 0"
        }
        $m_objScanIdConfig sendContentsToServer $newContents
    }
    public method flipCheckbutton { i } {
        set oldContents [$m_objScanIdConfig getContents]
        set oldV [lindex $oldContents $i]
        if {$oldV == "1"} {
            set newV 0
        } else {
            set newV 1
        }
        set newContents [lreplace $oldContents $i $i $newV]
        $m_objScanIdConfig sendContentsToServer $newContents
    }
    public method scanBarcode { } {
        $m_objSAM startOperation readCassetteIdBarcode
    }
    public method updateOwner { } {
        $m_objSAMSoftOnly startOperation updateCassetteOwnerFromBarcode
    }

    public method add { name } {
        if {$name != $m_currentCom} {
            if {$m_currentCom != ""} {
                pack forget $itk_component(${m_currentCom}users)
            }
            set m_currentCom $name
            pack $itk_component(${m_currentCom}users) -side left
        } else {
            set barcode [$itk_component($name) cget -text]
            set users   [$itk_component(${name}users) get]
            if {$barcode != "" && $barcode != "unknown" && $users != ""} {
                $m_objSAMSoftOnly startOperation \
                addUsersToBarcode $barcode $users

            } else {
                log_error bad barcode or empty user list
                puts "bad barcode or empty user list"
            }
            pack forget $itk_component(${name}users)
            set m_currentCom ""
        }
    }

    private common gCheckButtonVar

    private variable m_objSAM
    private variable m_objSAMSoftOnly
    private variable m_objScanIdConfig
    private variable m_anySelectedWrap

    private variable m_currentCom ""

    private variable m_usersToAdd ""

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::cassette_barcode
    } {
        set m_anySelectedWrap [::DCS::ManualInputWrapper ::#auto]
        $m_anySelectedWrap setValue 0

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objSAM [$deviceFactory createOperation ISampleMountingDevice]
        set m_objSAMSoftOnly \
        [$deviceFactory createOperation ISampleMountingDeviceSoftOnly]
        set m_objScanIdConfig \
        [$deviceFactory createString scanId_config]

        itk_component add f0 {
            label $m_site.f0 \
            -anchor w \
            -justify left \
            -width 20 \
            -text Barcode
        } {
        }


        set m_labelList [list \
        f1 1 \
        f2 2 \
        f3 3 \
        ]

        foreach {name index} $m_labelList {
            set siteF $m_site.${name}F
            itk_component add ${name}F {
                frame $siteF
            } {
            }

            itk_component add $name {
                label  $siteF.$name \
                -anchor w \
                -justify left \
                -background #00a040 \
                -width 20 \
                -text $name
            } {
            }
            itk_component add ${name}Add {
                button $siteF.${name}Add \
                -text "+" \
                -command "$this add $name"
            } {
            }

            itk_component add ${name}users {
                entry $siteF.{$name}users \
                -background white \
                -width 30 \
                -textvariable [::scope m_usersToAdd]
            } {
            }

            bind $itk_component($name) <Button-1> "+$this handleBarcodeClick $name"

            pack $itk_component($name) -side left
            pack $itk_component(${name}Add) -side left
        }
        itk_component add enable_all {
            checkbutton $m_site.eA \
            -variable [scope gCheckButtonVar($this,all)] \
            -text "include all" \
            -anchor w \
            -justify left \
            -command "$this flipAllButton"
        } {
        }

        itk_component add enable_left {
            checkbutton $m_site.eL \
            -variable [scope gCheckButtonVar($this,left)] \
            -text "left" \
            -anchor w \
            -justify left \
            -command "$this flipCheckbutton 0"
        } {
        }

        itk_component add enable_middle {
            checkbutton $m_site.eM \
            -variable [scope gCheckButtonVar($this,middle)] \
            -text "middle" \
            -anchor w \
            -justify left \
            -command "$this flipCheckbutton 1"
        } {
        }
        itk_component add enable_right {
            checkbutton $m_site.eR \
            -variable [scope gCheckButtonVar($this,right)] \
            -text "right" \
            -anchor w \
            -justify left \
            -command "$this flipCheckbutton 2"
        } {
        }
        itk_component add scan {
			DCS::Button $m_site.scan \
            -text "Scan" \
            -command "$this scanBarcode"
        } {
        }
        itk_component add update {
			DCS::Button $m_site.update \
            -text "Update Owner" \
            -command "$this updateOwner"
        } {
        }
		registerComponent $itk_component(enable_all)
		registerComponent $itk_component(enable_left)
		registerComponent $itk_component(enable_middle)
		registerComponent $itk_component(enable_right)
		#registerComponent $itk_component(scan)
		registerComponent $itk_component(update)

        $itk_component(scan) addInput \
        "$m_anySelectedWrap value 1 {No cassette selected}"
        $itk_component(scan) addInput \
        "$m_objSAM permission GRANTED {PERMISSION}"
        $itk_component(scan) addInput \
        "$m_objSAM status inactive {supporing device}"

        set statusObj [$deviceFactory createString robot_status]
        $itk_component(scan) addInput \
        "$statusObj status_num 0 {robot not ready}"

        $itk_component(update) addInput \
        "$m_objSAMSoftOnly permission GRANTED {PERMISSION}"

        grid $itk_component(enable_all)    $itk_component(f0) -sticky w
        grid $itk_component(enable_left)   $itk_component(f1F) -sticky w
        grid $itk_component(enable_middle) $itk_component(f2F) -sticky w
        grid $itk_component(enable_right)  $itk_component(f3F) -sticky w
		grid $itk_component(scan)          $itk_component(update) -sticky w

        grid forget $itk_component(apply) $itk_component(cancel)

		eval itk_initialize $args

		announceExist

        setContents [$_lastStringName getContents]

        ::mediator register $this $m_objScanIdConfig contents \
            handleScanIdConfigUpdate
    }
}
body DCS::CassetteBarcodeView::handleScanIdConfigUpdate { \
stringName_ targetReady_ alias_ contents_ - } {
    if {!$targetReady_} {
        return
    }

    foreach {l m r} $contents_ break

    set gCheckButtonVar($this,left)   $l
    set gCheckButtonVar($this,middle) $m
    set gCheckButtonVar($this,right)  $r

    if {$l == "1" && $m == "1" && $r == "1"} {
        set gCheckButtonVar($this,all)   1
    } else {
        set gCheckButtonVar($this,all)   0
    }
    if {$l == "1" || $m == "1" || $r == "1"} {
        $m_anySelectedWrap setValue 1
    } else {
        $m_anySelectedWrap setValue 0
    }
}
class DCS::InlineCameraPresetLevel2View {
	inherit ::DCS::StringFieldLevel2ViewBase

    public method updatePosition { index } {
        if {$index < 0 || $index >= $m_numColumnDisplayed} {
            log_warning wrong index $index
            return
        }
        foreach {hIndex vIndex} $m_positionIndexList break
        if {$hIndex < 0 || $vIndex < 0} {
            log_error position tag not found, no update
            return
        }

        set h [lindex [::device::inline_camera_horz getScaledPosition] 0]
        set v [lindex [::device::inline_camera_vert getScaledPosition] 0]

        set hName [lindex $POSITION_LIST 0]$index
        set vName [lindex $POSITION_LIST 1]$index

        $itk_component($hName) delete 0 end
        $itk_component($hName) insert 0 $h
        #updateEntryColor $index $hIndex $h

        $itk_component($vName) delete 0 end
        $itk_component($vName) insert 0 $v
        #updateEntryColor $index $vIndex $v
    }

    public method moveTo { index } {
        if {$index < 0 || $index >= $m_numColumnDisplayed} {
            log_warning wrong index $index
            return
        }
        $m_opInlineMove startOperation $index
    }

    public method handleStatusChange { - targetReady_ - contents_ - } {
        if {!$targetReady_} {
            ### no match
            set contents_ -1
        }

        set indexMatched [lindex $contents_ 1]
        if {![string is integer -strict $indexMatched]} {
            set indexMatched -1
        }
        for {set i 0} {$i < $m_numColumnCreated} {incr i} {
            if {$i == $indexMatched} {
                set bg "light green"
            } else {
                set bg $m_colorBG
            }
            $itk_component(move$i) configure \
            -background $bg
        }
    }

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        return 1

    }

    private method addColumns { num } {
        for {set i 0} {$i < $num} {incr i} {
            set index1 $m_numColumnCreated
            set index2  -1
            foreach name $m_cfgNameList {
                incr index2 
                set wName $name$m_numColumnCreated
                itk_component add $wName {
                    set cmd [list $this updateEntryColor $wName $index1 $index2 %P]
                    entry $m_site.$wName \
                    -validate all \
                    -vcmd $cmd \
                    -width 15 \
                    -background white \
                } {
                }
            }
            set wName move$m_numColumnCreated
            itk_component add $wName {
                DCS::Button $m_site.$wName \
                -width 15 \
                -text "Unknown" \
                -command "$this moveTo $m_numColumnCreated"
            } {
                keep -activeClientOnly
                keep -systemIdleOnly
            }
            if {$m_colorBG == ""} {
                set m_colorBG [$itk_component($wName) cget -background]
            }

            set wName update$m_numColumnCreated
            itk_component add $wName {
                button $m_site.$wName \
                -text "update" \
                -command "$this updatePosition $index1"
            } {
            }
            incr m_numColumnCreated
        }
    }
    private method adjustColumns { num } {
        if {$num == $m_numColumnDisplayed} {
            return
        }
        if {$num > $m_numColumnCreated} {
            addColumns [expr $num - $m_numColumnCreated]
        }

        while {$m_numColumnDisplayed < $num} {
            set wName move$m_numColumnDisplayed
            set col $m_numColumnDisplayed
            grid $itk_component($wName) -column [expr $col + 1] -row 0
            set row  -1
            foreach name $m_cfgNameList {
                incr row 
                set wName $name$m_numColumnDisplayed
                set col $m_numColumnDisplayed
                lappend m_entryList $wName $col $row

                grid $itk_component($wName) \
                -column [expr $col + 1] \
                -row [expr $row + 1] \
                -sticky news
            }
            incr row 2
            set wName update$m_numColumnDisplayed
            set col $m_numColumnDisplayed
            grid $itk_component($wName) -column [expr $col + 1] -row $row
            incr m_numColumnDisplayed
        }

        set need_cleanList 0
        if {$m_numColumnDisplayed > $num} {
            set need_cleanList 1
        }
        while {$m_numColumnDisplayed > $num} {
            set col $m_numColumnDisplayed
            set slaves [grid slaves $m_site -column $col]
            if {$slaves != ""} {
                eval grid forget $slaves
            }
            incr m_numColumnDisplayed -1
        }
        if {$need_cleanList} {
            ### clean up list (not efficient)
            set old $m_entryList
            set m_entryList ""
            foreach item $old {
                set col [lindex $item 2]
                if {$col < $m_numColumnDisplayed} {
                    lappend m_entryList $item
                }
            }
        }
    }

    ##override base class
    protected method setContents { contents_ } {
        set ll [llength $contents_]

        adjustColumns $ll

        ### update moveTo button labels
        set i -1
        foreach preset $contents_ {
            incr i
            set name [lindex $preset 0]
            $itk_component(move$i) configure \
            -text $name
        }

	    DCS::StringFieldLevel2ViewBase::setContents $contents_
    }

    ## must be a subset of cfg name list
    private common POSITION_LIST    [list horz vert]

    private variable m_positionIndexList [list -1 -1]
    private variable m_numColumnCreated 0
    private variable m_numColumnDisplayed 0
    private variable m_cfgNameList ""

    private variable m_opInlineMove ""
    private variable m_strInlineStatus ""
    private variable m_colorBG ""

    constructor { args } {
    } {
        set deviceFactory  [DCS::DeviceFactory::getObject]
        set m_opInlineMove [$deviceFactory createOperation inlineCameraMove]
        set m_strInlineStatus \
        [$deviceFactory getObjectName inline_camera_position_status]

        set m_cfgNameList [::config getStr inlineCameraPresetNameList]

        ### search the position index
    
        set m_positionIndexList ""
        foreach name $POSITION_LIST {
            set index [lsearch -exact $m_cfgNameList $name]
            lappend m_positionIndexList $index
            if {$index < 0} {
                puts "position tag $name not found"
                log_warning position tag $name not found in the config list
                log_warning update button will not work
            }
        }

        label $m_site.ch0 -anchor e -text "move to"
        grid $m_site.ch0 -row 0 -column 0 -stick e
        set i 1
        foreach ch $m_cfgNameList {
            label $m_site.ch$i -anchor e -text $ch
            grid $m_site.ch$i -row $i -column 0 -sticky e

            incr i
        }
        ##extra button
        label $m_site.ch$i -anchor e -text "copy cur. pos."
        grid $m_site.ch$i -row $i -column 0 -stick e

		eval itk_initialize $args
		announceExist

        ::mediator register $this $m_strInlineStatus contents handleStatusChange
    }
}
class DCS::RasteringNormalConfigView {
	inherit ::DCS::StringFieldViewBase

    protected variable m_cntsNameString ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
    loop_we                 loopW_extra \
    loop_he                 loopH_extra \
    rMin                    rowMin \
    rMax                    rowMax \
    rDef                    rowDef \
    rHt                     rowHt \
    cMin                    colMin \
    cMax                    colMax \
    cDef                    colDef \
    cWd                     colWd \
    bW                      beamWd \
    bH                      beamHt \
    tMin                    timeMin \
    tMax                    timeMax \
    tDef                    timeDef \
    tInc                    timeIncr \
    delta                   delta \
    sV                      stopV \
    dV                      distV \
    sMin                    spotMin \
    sTgt                    spotTgt \
    maxTry                  maxTry \
    contourL                contourLevels \
    ridgeL                  ridgeLevel \
    beamS                   beamSpace \
    ]
    protected variable m_checkbuttonMap [list \
    cbD                     distMove \
    cbS                     stopMove \
    cbC                     scaling \
    ]

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    private method createLoopArea { site width } {
        label $site.l11 \
        -text "Width  = Loop Width Plus"
        label $site.l13 \
        -text "um"

        label $site.l21 \
        -text "Height = Loop Height Plus"
        label $site.l23 \
        -text "um"

        addEntries $site $width loop_we loop_he
        set m_origEntryBG [$itk_component(loop_we) cget -background]

        grid columnconfigure $site 2 -weight 100
        grid $site.l11 $itk_component(loop_we) $site.l13 -sticky w
        grid $site.l21 $itk_component(loop_he) $site.l23 -sticky w

        grid columnconfigure $site 5 -weight 10
    }
    private method createMatrixArea { site width } {
        label $site.l01 -text "points"
        label $site.l02 -text "min"
        label $site.l03 -text "max"
        label $site.l04 -text "step(mm)"

        label $site.l10 -text "Width"
        label $site.l20 -text "Height"

        addEntries $site $width cMin cMax cDef cWd rMin rMax rDef rHt

        grid     x $site.l01 $site.l02 $site.l03 $site.l04 -sticky w

        grid $site.l10 \
        $itk_component(cDef) \
        $itk_component(cMin) \
        $itk_component(cMax) \
        $itk_component(cWd) -sticky w

        grid $site.l20 \
        $itk_component(rDef) \
        $itk_component(rMin) \
        $itk_component(rMax) \
        $itk_component(rHt) -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createBeamArea { site width } {
        label $site.l00 -text "Beam Size"
        label $site.l10 -text "Distance"
        label $site.l20 -text "Beam Stop"

        label $site.l02 -text "X"
        label $site.l04 -text "mm"

        label $site.l14 -text "mm"
        label $site.l24 -text "mm"

        addEntries $site $width bW bH sV dV

        itk_component add cbD {
            checkbutton $site.moveDistance \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbD)] \
            -text "Move"
        } {
            keep -background
        }

        itk_component add cbS {
            checkbutton $site.moveBeamStop \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbS)] \
            -text "Move"
        } {
            keep -background
        }
        
        grid $site.l00 \
        $itk_component(bW) $site.l02 $itk_component(bH) $site.l04 -sticky w

        grid $site.l10 \
        $itk_component(cbD) x $itk_component(dV) $site.l14 -sticky w

        grid $site.l20 \
        $itk_component(cbS) x $itk_component(sV) $site.l24 -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createExposureArea { site width } {
        label $site.l20 -text "Delta"
        label $site.l10 -text "Time"

        label $site.l24 -text "deg"

        label $site.l01 -text "initial(s)"
        label $site.l02 -text "min(s)"
        label $site.l03 -text "max(s)"
        
        addEntries $site $width delta tMax tMin tDef

        grid x $site.l01 $site.l02 $site.l03

        grid $site.l10 \
        $itk_component(tDef) $itk_component(tMin) $itk_component(tMax)

        grid $site.l20 \
        $itk_component(delta) $site.l24 -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createSpotsArea { site width } {
        label $site.l00 -text "min"
        label $site.l01 -text "target"
        label $site.l02 -text "max factor"
        label $site.l03 -text "max retries"

        addEntries $site $width sMin sTgt tInc maxTry

        itk_component add cbC {
            checkbutton $site.scaleTime \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbC)] \
            -text "Scale 2nd Raster"
        } {
            keep -background
        }
        
        grid $site.l00 $site.l01 $site.l02 $site.l03 -sticky w
        grid $itk_component(sMin) $itk_component(sTgt) $itk_component(tInc) \
        $itk_component(maxTry) -sticky w
        grid $itk_component(cbC) - -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createTopoArea { site width } {
        label $site.l00 -text "Contour Levels"
        label $site.l02 -text "%"
        label $site.l10 -text "Ridge Cut Level"
        label $site.l12 -text "%"
        label $site.l20 -text "Space between Beam"
        label $site.l22 -text "mm"

        addEntries $site 20 contourL
        addEntries $site $width ridgeL beamS

        grid $site.l00 $itk_component(contourL) $site.l02 -sticky e
        grid $site.l10 $itk_component(ridgeL)   $site.l12 -sticky e
        grid $site.l20 $itk_component(beamS)    $site.l22 -sticky e

        grid columnconfigure $site 5 -weight 10
    }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::rastering_normal_constant
    } {

        set m_cntsNameString [::config getStr rastering.normalConstantNameList]
        puts "namelist $m_cntsNameString"

        itk_component add loop_frame {
            iwidgets::Labeledframe $m_site.loopF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Auto From Loop"
        } {
        }
        set loopSite [$itk_component(loop_frame) childsite]

        itk_component add matrix_frame {
            iwidgets::Labeledframe $m_site.matrixF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Matrix"
        } {
        }
        set matrixSite [$itk_component(matrix_frame) childsite]

        itk_component add beam_frame {
            iwidgets::Labeledframe $m_site.beamF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Beam Setup"
        } {
        }
        set beamSite [$itk_component(beam_frame) childsite]

        itk_component add exposure_frame {
            iwidgets::Labeledframe $m_site.exposureF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Exposure"
        } {
        }
        set exposureSite [$itk_component(exposure_frame) childsite]

        itk_component add spots_frame {
            iwidgets::Labeledframe $m_site.spotsF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Number of Spots"
        } {
        }
        set spotsSite [$itk_component(spots_frame) childsite]

        ### we may add contour level configure later
        itk_component add topo_frame {
            iwidgets::Labeledframe $m_site.topoF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Topographics"
        } {
        }
        set topoSite [$itk_component(topo_frame) childsite]

        createLoopArea $loopSite 4
        createMatrixArea $matrixSite 6
        createBeamArea $beamSite 8
        createExposureArea $exposureSite 8
        createSpotsArea $spotsSite 8
        createTopoArea $topoSite 8

        pack $itk_component(loop_frame) -side top -anchor w -fill x
        pack $itk_component(beam_frame) -side top -anchor w -fill x
        pack $itk_component(matrix_frame) -side top -anchor w -fill x
        pack $itk_component(exposure_frame) -side top -anchor w -fill x
        pack $itk_component(spots_frame) -side top -anchor w -fill x
        pack $itk_component(topo_frame) -side top -anchor w -fill x
        


		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist
    }
    destructor {
    }
    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        ### all field should be a number

        ### you can add auto fix here, too.

        foreach value $contents name $m_cntsNameString {
            if {$name == "contourLevels"} {
                foreach l $value {
                    if {![string is double -strict $l]} {
                        log_error contour level $l is not a number
                        return 0
                    }
                }
            } elseif {$name != ""} {
                if {![string is double -strict $value]} {
                    log_error $name=$value is not a number
                    return 0
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }
}
body DCS::RasteringNormalConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name keyword} $m_entryMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }

    set m_checkbuttonList ""
    foreach {name keyword} $m_checkbuttonMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -command ""
        } else {
            set cmd [list $this updateCheckButtonColor $name $index]
            #puts "map $name to $index"
            lappend m_checkbuttonList $name $index
            $itk_component($name) configure \
            -command $cmd
        }
    }
}
class DCS::RasteringMicroConfigView {
	inherit ::DCS::StringFieldViewBase

    protected variable m_cntsNameString ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
    cIndex                  collimator \
    rMin                    rowMin \
    rMax                    rowMax \
    rDef                    rowDef \
    rHt                     rowHt \
    cMin                    colMin \
    cMax                    colMax \
    cDef                    colDef \
    cWd                     colWd \
    tMin                    timeMin \
    tMax                    timeMax \
    tDef                    timeDef \
    tInc                    timeIncr \
    delta                   delta \
    sV                      stopV \
    dV                      distV \
    sMin                    spotMin \
    sTgt                    spotTgt \
    maxTry                  maxTry \
    contourL                contourLevels \
    ridgeL                  ridgeLevel \
    beamS                   beamSpace \
    ]

    protected variable m_checkbuttonMap [list \
    cbD                     distMove \
    cbS                     stopMove \
    cbC                     scaling \
    ]

    public method setIndex { value_ args } {
        $itk_component(cIndex) delete 0 end
        $itk_component(cIndex) insert 0 $value_
    }

    protected method onFieldChange { name index value } {
        switch -exact -- $name {
            "cIndex" {
                foreach {w h} \
                [::device::collimator_preset getCollimatorSize $value] break

                $itk_component(bW) configure -text $w
                $itk_component(bH) configure -text $h
            }
        }
    }
    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    private method createMatrixArea { site width } {
        label $site.l01 -text "points"
        label $site.l02 -text "min"
        label $site.l03 -text "max"
        label $site.l04 -text "step(mm)"

        label $site.l10 -text "Width"
        label $site.l20 -text "Height"

        addEntries $site $width cMin cMax cDef cWd rMin rMax rDef rHt

        grid     x $site.l01 $site.l02 $site.l03 $site.l04 -sticky w

        grid $site.l10 \
        $itk_component(cDef) \
        $itk_component(cMin) \
        $itk_component(cMax) \
        $itk_component(cWd) -sticky w

        grid $site.l20 \
        $itk_component(rDef) \
        $itk_component(rMin) \
        $itk_component(rMax) \
        $itk_component(rHt) -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createBeamArea { site width } {
        label $site.l00 -text "Collimator Preset Index"

        label $site.l10 -text "Beam Size"
        label $site.l20 -text "Distance"
        label $site.l30 -text "Beam Stop"

        label $site.l12 -text "X"
        label $site.l14 -text "mm"

        label $site.l24 -text "mm"
        label $site.l34 -text "mm"

        addEntries $site $width cIndex
        CollimatorMenu $site.mn \
        -cmd "$this setIndex"

        itk_component add bW {
            label $site.bW \
            -width $width \
            -text "0.005" \
            -background tan \
            -relief sunken
        } {
        }
        
        itk_component add bH {
            label $site.bH \
            -width $width \
            -text "0.005" \
            -background tan \
            -relief sunken
        } {
        }
        

        addEntries $site $width sV dV


        itk_component add cbD {
            checkbutton $site.moveDistance \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbD)] \
            -text "Move"
        } {
            keep -background
        }

        itk_component add cbS {
            checkbutton $site.moveBeamStop \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbS)] \
            -text "Move"
        } {
            keep -background
        }
        
        grid $site.l00 - - $itk_component(cIndex) $site.mn -sticky w

        grid $site.l10 \
        $itk_component(bW) $site.l12 $itk_component(bH) $site.l14 -sticky w

        grid $site.l20 \
        $itk_component(cbD) x $itk_component(dV) $site.l24 -sticky w

        grid $site.l30 \
        $itk_component(cbS) x $itk_component(sV) $site.l34 -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createExposureArea { site width } {
        label $site.l20 -text "Delta"
        label $site.l10 -text "Time"

        label $site.l24 -text "deg"

        label $site.l01 -text "initial(s)"
        label $site.l02 -text "min(s)"
        label $site.l03 -text "max(s)"
        
        addEntries $site $width delta tMax tMin tDef

        grid x $site.l01 $site.l02 $site.l03

        grid $site.l10 \
        $itk_component(tDef) $itk_component(tMin) $itk_component(tMax)

        grid $site.l20 \
        $itk_component(delta) $site.l24 -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createSpotsArea { site width } {
        label $site.l00 -text "min"
        label $site.l01 -text "target"
        label $site.l02 -text "max factor"
        label $site.l03 -text "max retries"

        addEntries $site $width sMin sTgt tInc maxTry

        itk_component add cbC {
            checkbutton $site.scaleTime \
            -anchor w \
            -variable [scope gCheckButtonVar($this,cbC)] \
            -text "Scale 2nd Raster"
        } {
            keep -background
        }
        
        grid $site.l00 $site.l01 $site.l02 $site.l03 -sticky w
        grid $itk_component(sMin) $itk_component(sTgt) $itk_component(tInc) \
        $itk_component(maxTry) -sticky w
        grid $itk_component(cbC) - -sticky w

        grid columnconfigure $site 5 -weight 10
    }

    private method createTopoArea { site width } {
        label $site.l00 -text "Contour Levels"
        label $site.l02 -text "%"
        label $site.l10 -text "Ridge Cut Level"
        label $site.l12 -text "%"
        label $site.l20 -text "Space between Beam"
        label $site.l22 -text "mm"

        addEntries $site 20 contourL
        addEntries $site $width ridgeL beamS

        grid $site.l00 $itk_component(contourL) $site.l02 -sticky e
        grid $site.l10 $itk_component(ridgeL)   $site.l12 -sticky e
        grid $site.l20 $itk_component(beamS)    $site.l22 -sticky e

        grid columnconfigure $site 5 -weight 10
    }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::rastering_micro_constant
    } {

        set m_cntsNameString [::config getStr rastering.microConstantNameList]
        puts "namelist $m_cntsNameString"

        itk_component add matrix_frame {
            iwidgets::Labeledframe $m_site.matrixF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Matrix"
        } {
        }
        set matrixSite [$itk_component(matrix_frame) childsite]

        itk_component add beam_frame {
            iwidgets::Labeledframe $m_site.beamF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Beam Setup"
        } {
        }
        set beamSite [$itk_component(beam_frame) childsite]

        itk_component add exposure_frame {
            iwidgets::Labeledframe $m_site.exposureF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Exposure"
        } {
        }
        set exposureSite [$itk_component(exposure_frame) childsite]

        itk_component add spots_frame {
            iwidgets::Labeledframe $m_site.spotsF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Number of Spots"
        } {
        }
        set spotsSite [$itk_component(spots_frame) childsite]

        itk_component add topo_frame {
            iwidgets::Labeledframe $m_site.topoF \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Topographics"
        } {
        }
        set topoSite [$itk_component(topo_frame) childsite]

        createMatrixArea $matrixSite 6
        createBeamArea $beamSite 8
        createExposureArea $exposureSite 8
        createSpotsArea $spotsSite 8
        createTopoArea $topoSite 8

        pack $itk_component(beam_frame) -side top -anchor w -fill x
        pack $itk_component(matrix_frame) -side top -anchor w -fill x
        pack $itk_component(exposure_frame) -side top -anchor w -fill x
        pack $itk_component(spots_frame) -side top -anchor w -fill x
        pack $itk_component(topo_frame) -side top -anchor w -fill x
        


		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist
    }
    destructor {
    }
    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        ### all field should be a number

        ### you can add auto fix here, too.

        foreach value $contents name $m_cntsNameString {
            if {$name == "contourLevels"} {
                foreach l $value {
                    if {![string is double -strict $l]} {
                        log_error contour level $l is not a number
                        return 0
                    }
                }
            } elseif {$name != ""} {
                if {![string is double -strict $value]} {
                    log_error $name=$value is not a number
                    return 0
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }
}
body DCS::RasteringMicroConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name keyword} $m_entryMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }

    set m_checkbuttonList ""
    foreach {name keyword} $m_checkbuttonMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -command ""
        } else {
            set cmd [list $this updateCheckButtonColor $name $index]
            #puts "map $name to $index"
            lappend m_checkbuttonList $name $index
            $itk_component($name) configure \
            -command $cmd
        }
    }
}
class DCS::AutofocusConfigView {
	inherit ::DCS::StringFieldViewBase

    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents
        foreach value $contents name $m_cntsNameString {
            if {$name != ""} {
                if {![string is double -strict $value]} {
                    log_error $name=$value is not a number
                    return 0
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }

    ###will be overwriten in constructor
    protected variable m_cntsNameString ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
        cx          ROI_center_x \
        cy          ROI_center_y \
        cw          ROI_width \
        ch          ROI_height \
        distance    scan_width \
        num         scan_points \
        cut         CUT_PERCENT \
    ]

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::autofocus_constants
    } {
        set ENTRY_WIDTH 10

        set m_cntsNameString [::config getStr autoFocusConstantsNameList]
        puts "namelist $m_cntsNameString"

        itk_component add roi_frame {
            iwidgets::Labeledframe $m_site.roi \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "ROI of Contrast Calculation"
        } {
        }
        set roiSite [$itk_component(roi_frame) childsite]

        label $roiSite.ll -text "Fraction of the Video Image"
        label $roiSite.l0 -text "Center X:"
        label $roiSite.l1 -text "Width:"
        label $roiSite.l2 -text "Center Y:"
        label $roiSite.l3 -text "Height:"

        addEntries $roiSite $ENTRY_WIDTH \
        cx cy cw ch

        grid $roiSite.ll -column 0 -row 0 -sticky w -columnspan 4

        grid $roiSite.l0        -column 0 -row 1 -sticky e
        grid $itk_component(cx) -column 1 -row 1 -sticky we
        grid $roiSite.l1        -column 2 -row 1 -sticky e
        grid $itk_component(cw) -column 3 -row 1 -sticky we

        grid $roiSite.l2        -column 0 -row 2 -sticky e
        grid $itk_component(cy) -column 1 -row 2 -sticky we
        grid $roiSite.l3        -column 2 -row 2 -sticky e
        grid $itk_component(ch) -column 3 -row 2 -sticky we

        grid columnconfigure $roiSite 5 -weight 10

        itk_component add scan_frame {
            iwidgets::Labeledframe $m_site.scan \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Scan Parameters"
        } {
        }
        set scanSite [$itk_component(scan_frame) childsite]

        label $scanSite.l00 -text "Signal"
        label $scanSite.l01 -text "Motor"
        label $scanSite.l02 -text "Width (mm)"
        label $scanSite.l03 -text "Points"

        label $scanSite.l10 \
        -text "contrast4autofocus" \
        -background tan \
        -relief sunken

        label $scanSite.l11 \
        -text "inline_camera_focus" \
        -background tan \
        -relief sunken

        addEntries $scanSite $ENTRY_WIDTH distance num

        grid $scanSite.l00 $scanSite.l01 \
        $scanSite.l02 $scanSite.l03 -sticky w

        grid $scanSite.l10 $scanSite.l11 \
        $itk_component(distance) $itk_component(num) - -sticky nws

        grid columnconfigure $scanSite 4 -weight 10

        itk_component add weight_frame {
            iwidgets::Labeledframe $m_site.weight \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Weighted Center Parameters"
        } {
        }
        set weightSite [$itk_component(weight_frame) childsite]

        label $weightSite.l0 -text "Background CUT:"
        label $weightSite.u0 -text "%"

        addEntries $weightSite $ENTRY_WIDTH cut

        pack $weightSite.l0 $itk_component(cut) $weightSite.u0 -side left


        pack $itk_component(roi_frame) -side top -fill x
        pack $itk_component(scan_frame) -side top -fill x
        pack $itk_component(weight_frame) -side top -fill x

		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist
    }
}
body DCS::AutofocusConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name keyword} $m_entryMap {
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }
}
class DCS::AlignTungstenConfigView {
	inherit ::DCS::StringFieldMixLevelViewBase

    public method setSignal { name } {
        $itk_component(signal) delete 0 end
        $itk_component(signal) insert 0 $name
    }
    ###override base class method
    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        ### all field should be a number except signal should be one of
        ### ion chambers

        ### you can add auto fix here, too.

        foreach value $contents name $m_cntsNameString {
            if {$name == "signal"} {
                if {[lsearch -exact $m_sigList $value] < 0} {
                    log_error $value is not a valid ion chamber
                    return 0
                }
            } elseif {$name != ""} {
                foreach vv $value {
                    if {![string is double -strict $vv]} {
                        log_error one of $name=$vv is not a number
                        return 0
                    }
                }
            } else {
                log_warning extra field $value
            }
        }
    
        return 1
    }

    ###will be overwriten in constructor
    protected variable m_sigList ""
    protected variable m_cntsNameString ""

    ###itk_component name to parameter name
    protected variable m_entryMap [list \
        bw          beam_width \
        bh          beam_height \
        en          energy \
        at11        {attenuation 0} \
        at9         {attenuation 1} \
        at7         {attenuation 2} \
        at5         {attenuation 3} \
        fl          fluorescence_z \
        signal      signal \
        mp          min_signal \
        gp          good_signal \
        hw          horz_scan_width \
        hp          horz_scan_points \
        hi          horz_scan_time \
        hs          horz_scan_wait \
        vw          vert_scan_width \
        vp          vert_scan_points \
        vi          vert_scan_time \
        vs          vert_scan_wait \
        sz          beam_sample_z \
        td          tungsten_delta \
        mv          max_vert_move \
        mh          max_horz_move \
        shw         staff_horz_scan_width \
        shp         staff_horz_scan_points \
        svw         staff_vert_scan_width \
        svp         staff_vert_scan_points \
    ]

    protected method addEntries { site width args } {
        foreach name $args {
            itk_component add $name {
                entry $site.$name \
                -width $width \
                -justify right \
                -background white
            } {
            }
        }
    }
    protected method fillComponentList { }

    constructor { args } {
        ::DCS::StringFieldViewBase::constructor \
        -stringName ::device::alignTungsten_constant
    } {
        set beamNotSlit 1

        set LABEL_WIDTH 22
        set ENTRY_WIDTH 10
        set UNITS_WIDTH 3

        set m_cntsNameString [::config getStr alignCollimatorConstantsNameList]
        puts "namelist $m_cntsNameString"

        array set m_menubuttonIndex [list]
        if {[catch {
            set deviceFactory [DCS::DeviceFactory::getObject]
            set m_sigList [$deviceFactory getSignalList]
        } errMsg] || $m_sigList == ""} {
            log_error failed to retrieve ion chamber list, default to i0, i1, i2
            set m_sigList [list i0 i1 i2]
        }

        itk_component add top_frame {
            iwidgets::Labeledframe $m_site.top \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Global Parameters"
        } {
        }
        set topSite [$itk_component(top_frame) childsite]

        label $topSite.l0 -anchor e -width $LABEL_WIDTH -text "Beam Width:"
        label $topSite.l1 -anchor e -width $LABEL_WIDTH -text "Beam Height:"
        label $topSite.l2 -anchor e -width $LABEL_WIDTH -text "Min Energy:"
        label $topSite.l3 -anchor e -width $LABEL_WIDTH -text "Attenuation 11th:"
        label $topSite.l4 -anchor e -width $LABEL_WIDTH -text "9th:"
        label $topSite.l5 -anchor e -width $LABEL_WIDTH -text "7th:"
        label $topSite.l6 -anchor e -width $LABEL_WIDTH -text "5th:"
        label $topSite.l7 -anchor e -width $LABEL_WIDTH -text "Fluor. Z:"
        label $topSite.l8 -anchor e -width $LABEL_WIDTH -text "Signal:"
        label $topSite.l9 -anchor e -width $LABEL_WIDTH -text "Min Peak:"
        label $topSite.l10 -anchor e -width $LABEL_WIDTH -text "Good Peak:"
        label $topSite.l11 -anchor e -width $LABEL_WIDTH \
        -text "Beam sample_z_encoder:"
        label $topSite.l12 -anchor e -width $LABEL_WIDTH -text "Tungsten Pos.:"
        label $topSite.l13 -anchor e -width $LABEL_WIDTH -text "Max Vert Move:"
        label $topSite.l14 -anchor e -width $LABEL_WIDTH -text "Max Horz Move:"

        label $topSite.u0 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u1 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u2 -anchor w -width $UNITS_WIDTH -text eV
        label $topSite.u3 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u4 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u5 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u6 -anchor w -width $UNITS_WIDTH -text %
        label $topSite.u7 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u11 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u12 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u13 -anchor w -width $UNITS_WIDTH -text mm
        label $topSite.u14 -anchor w -width $UNITS_WIDTH -text mm

        itk_component add sigmb {
            menubutton $topSite.sigmb \
            -menu $topSite.sigmb.menu \
            -image [DCS::MenuEntry::getArrowImage] \
            -width 16 \
            -anchor c \
            -relief raised
        } {
        }
        itk_component add sigmn {
            menu $topSite.sigmb.menu \
            -activebackground blue \
            -activeforeground white \
            -tearoff 0
        } {
        }

        foreach s $m_sigList {
            $itk_component(sigmn) add command \
            -label $s \
            -command "$this setSignal $s"
        }

        addEntries $topSite $ENTRY_WIDTH \
        bw bh en at11 at9 at7 at5 fl signal mp gp sz td mv mh

        grid $topSite.l0 -column 0 -row 0 -sticky e
        grid $topSite.l1 -column 0 -row 1 -sticky e
        grid $topSite.l2 -column 0 -row 2 -sticky e
        grid $topSite.l3 -column 0 -row 3 -sticky e
        grid $topSite.l4 -column 0 -row 4 -sticky e
        grid $topSite.l5 -column 0 -row 5 -sticky e
        grid $topSite.l6 -column 0 -row 6 -sticky e
        grid $topSite.l7 -column 0 -row 7 -sticky e
        grid $topSite.l8 -column 0 -row 8 -sticky e
        grid $topSite.l9 -column 0 -row 9 -sticky e
        grid $topSite.l10 -column 0 -row 10 -sticky e
        grid $topSite.l11 -column 0 -row 11 -sticky e
        grid $topSite.l12 -column 0 -row 12 -sticky e
        grid $topSite.l13 -column 0 -row 13 -sticky e
        grid $topSite.l14 -column 0 -row 14 -sticky e

        grid $itk_component(bw) -column 1 -row 0 -sticky we
        grid $itk_component(bh) -column 1 -row 1 -sticky we
        grid $itk_component(en) -column 1 -row 2 -sticky we
        grid $itk_component(at11) -column 1 -row 3 -sticky we
        grid $itk_component(at9) -column 1 -row 4 -sticky we
        grid $itk_component(at7) -column 1 -row 5 -sticky we
        grid $itk_component(at5) -column 1 -row 6 -sticky we
        grid $itk_component(fl) -column 1 -row 7 -sticky we
        grid $itk_component(signal) -column 1 -row 8 -sticky we
        grid $itk_component(mp) -column 1 -row 9 -sticky we
        grid $itk_component(gp) -column 1 -row 10 -sticky we
        grid $itk_component(sz) -column 1 -row 11 -sticky we
        grid $itk_component(td) -column 1 -row 12 -sticky we
        grid $itk_component(mv) -column 1 -row 13 -sticky we
        grid $itk_component(mh) -column 1 -row 14 -sticky we

        grid $topSite.u0 -column 2 -row 0 -sticky w
        grid $topSite.u1 -column 2 -row 1 -sticky w
        grid $topSite.u2 -column 2 -row 2 -sticky w
        grid $topSite.u3 -column 2 -row 3 -sticky w
        grid $topSite.u4 -column 2 -row 4 -sticky w
        grid $topSite.u5 -column 2 -row 5 -sticky w
        grid $topSite.u6 -column 2 -row 6 -sticky w
        grid $topSite.u7 -column 2 -row 7 -sticky w
        grid $itk_component(sigmb) -column 2 -row 8 -sticky w
        grid $topSite.u11 -column 2 -row 11 -sticky w
        grid $topSite.u12 -column 2 -row 12 -sticky w
        grid $topSite.u13 -column 2 -row 13 -sticky w
        grid $topSite.u14 -column 2 -row 14 -sticky w

        itk_component add horz_frame {
            iwidgets::Labeledframe $m_site.horz \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Horizontal Scan Parameters"
        } {
        }
        set horzSite [$itk_component(horz_frame) childsite]

        label $horzSite.l01 -text "USER"
        label $horzSite.l02 -text "STAFF"
        label $horzSite.l1 -anchor e -width $LABEL_WIDTH -text "Width"
        label $horzSite.l2 -anchor e -width $LABEL_WIDTH -text "Points"
        label $horzSite.l3 -anchor e -width $LABEL_WIDTH -text "Integrating Time"
        label $horzSite.l4 -anchor e -width $LABEL_WIDTH -text "Settling Time"

        label $horzSite.u1 -anchor w -width $UNITS_WIDTH -text "mm"
        label $horzSite.u3 -anchor w -width $UNITS_WIDTH -text "s"
        label $horzSite.u4 -anchor w -width $UNITS_WIDTH -text "s"

        addEntries $horzSite $ENTRY_WIDTH hw hp hi hs shw shp

        grid $horzSite.l01 -column 1 -row 0 -sticky w
        grid $horzSite.l02 -column 2 -row 0 -sticky w

        grid $horzSite.l1 -column 0 -row 1 -sticky e
        grid $horzSite.l2 -column 0 -row 2 -sticky e
        grid $horzSite.l3 -column 0 -row 3 -sticky e
        grid $horzSite.l4 -column 0 -row 4 -sticky e

        grid $itk_component(hw) -column 1 -row 1 -sticky we
        grid $itk_component(hp) -column 1 -row 2 -sticky we
        grid $itk_component(hi) -column 1 -row 3 -sticky we
        grid $itk_component(hs) -column 1 -row 4 -sticky we

        grid $itk_component(shw) -column 2 -row 1 -sticky we
        grid $itk_component(shp) -column 2 -row 2 -sticky we

        grid $horzSite.u1 -column 3 -row 1 -sticky w
        grid $horzSite.u3 -column 2 -row 3 -sticky w
        grid $horzSite.u4 -column 2 -row 4 -sticky w

        itk_component add vert_frame {
            iwidgets::Labeledframe $m_site.vert \
            -labelfont "helvetica -16 bold" \
            -foreground blue \
            -labelpos nw \
            -labeltext "Vertical Scan Parameters"
        } {
        }
        set vertSite [$itk_component(vert_frame) childsite]

        label $vertSite.l01 -text "USER"
        label $vertSite.l02 -text "STAFF"
        label $vertSite.l1 -anchor e -width $LABEL_WIDTH -text "Width"
        label $vertSite.l2 -anchor e -width $LABEL_WIDTH -text "Points"
        label $vertSite.l3 -anchor e -width $LABEL_WIDTH -text "Integrating Time"
        label $vertSite.l4 -anchor e -width $LABEL_WIDTH -text "Settling Time"

        label $vertSite.u1 -anchor w -width $UNITS_WIDTH -text "mm"
        label $vertSite.u3 -anchor w -width $UNITS_WIDTH -text "s"
        label $vertSite.u4 -anchor w -width $UNITS_WIDTH -text "s"

        addEntries $vertSite $ENTRY_WIDTH vw vp vi vs svw svp

        grid $vertSite.l01 -column 1 -row 0 -sticky w
        grid $vertSite.l02 -column 2 -row 0 -sticky w

        grid $vertSite.l1 -column 0 -row 1 -sticky e
        grid $vertSite.l2 -column 0 -row 2 -sticky e
        grid $vertSite.l3 -column 0 -row 3 -sticky e
        grid $vertSite.l4 -column 0 -row 4 -sticky e

        grid $itk_component(vw) -column 1 -row 1 -sticky we
        grid $itk_component(vp) -column 1 -row 2 -sticky we
        grid $itk_component(vi) -column 1 -row 3 -sticky we
        grid $itk_component(vs) -column 1 -row 4 -sticky we

        grid $itk_component(svw) -column 2 -row 1 -sticky we
        grid $itk_component(svp) -column 2 -row 2 -sticky we

        grid $vertSite.u1 -column 3 -row 1 -sticky w
        grid $vertSite.u3 -column 2 -row 3 -sticky w
        grid $vertSite.u4 -column 2 -row 4 -sticky w

        grid $itk_component(top_frame) -row 0 -column 0 -rowspan 2 -sticky news
        grid $itk_component(horz_frame) -row 0 -column 1 -sticky news
        grid $itk_component(vert_frame) -row 1 -column 1 -sticky news

        grid rowconfigure $m_site 0 -weight 5
        grid rowconfigure $m_site 1 -weight 5
        grid columnconfigure $m_site 2 -weight 5

		eval itk_initialize $args

        fillComponentList
        setContents [$_lastStringName getContents]
		announceExist

    }
}
body DCS::AlignTungstenConfigView::fillComponentList { } {
    set m_entryList ""

    foreach {name mm} $m_entryMap {
        set keyword [lindex $mm 0]
        set index [lsearch -exact $m_cntsNameString $keyword]
        if {$index < 0} {
            puts "cannot find $keyword for $name"
            log_error cannot find $keyword for $name
            $itk_component($name) configure \
            -validate none
        } else {
            set index [lreplace $mm 0 0 $index]
            puts "map $name to $index"
            set cmd [list $this updateEntryColor $name $index %P]
            lappend m_entryList $name $index
            $itk_component($name) configure \
            -validate all \
            -vcmd $cmd
        }
    }
}

####### StringXXXXDisplay is for display only and be used together with
####### StringXXXXView to display contents of another string in one GUI.
####### The host GUI must have:
####### public method setDisplayLabel { name value }
####### public method setDisplayState { name state }
class DCS::StringDisplayBase {
	puts "this is StringDisplayBase class."
	public variable stringName ""

	public method handleStringConfigure
    	public method setLabelList { ll } { set m_labelList $ll }
    	public method setStateList { ll } { set m_stateList $ll }

    ###derived classes need to implement following methods
	protected method setContents { contents_ } {
       set name [lindex $m_labelList 0]
	puts "m_host is $m_host, name is $name, contents_ is $contents_"
       $m_host setDisplayLabel $name $contents_
   	}

	protected variable _lastStringName ""
    	protected variable m_host

    #### only display, no change no submit
    #### support: text, timestamp, timespan
    #### the widget name starts with:
    #### ts_XXXX:     timestamp
    #### ti_XXXX:     timespan time interval
    #### other:       text
   	protected variable m_labelList ""
    	protected variable m_stateList ""


	# call base class constructor
    ## updateCmd will be called as eval $updateCmd name value
	constructor { host args } {
	puts "this is contstructor of DisplayBaseClass."
        set m_host $host
		eval configure $args
	}
    destructor {
	puts "this is destructor of StringDisplayBase class"
        if {$_lastStringName != ""} {
			#unregister
			#::mediator unregister $this $_lastStringName contents
			puts "_lastStringName Iis $_lastStringName"
			$_lastStringName unregister $this contents handleStringConfigure
        }
    }
}

configbody DCS::StringDisplayBase::stringName {
	puts "this is stringDistplayBase::stringName"
    if {$stringName != $_lastStringName} {
        if {$_lastStringName != ""} {
			#unregister
			#::mediator unregister $this $_lastStringName contents
			$_lastStringName unregister $this contents handleStringConfigure
        }
        set _lastStringName $stringName
        if {$stringName != ""} {
		    #::mediator register $this $stringName contents \
            #handleStringConfigure
		    $stringName register $this contents handleStringConfigure
        }
    }
}


body DCS::StringDisplayBase::handleStringConfigure { stringName_ targetReady_ alias_ contents_ - } {
	puts "this is StringDisplayBase::handleStringConfigure"
	if { ! $targetReady_} return

	setContents $contents_
	puts "contents_ is $contents"
}
class DCS::StringDictDisplayBase {
	inherit ::DCS::StringDisplayBase

	protected method setContents
    ###derived classes may put a callback here
    protected method onFieldChange { name key value } {
    }

	constructor { host args } {
		eval ::DCS::StringDisplayBase::constructor $host $args
    } {
    }
}
body DCS::StringDictDisplayBase::setContents { contents_ } {
    set ll [llength $contents_]
    if {$ll % 2} {
        lappend contents_ {}
    }

    foreach {name key} $m_labelList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $m_host setDisplayLabel $name $displayValue

        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name key} $m_stateList {
        if {[catch {dict get $contents_ $key} value]} {
            set value ""
        }
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $m_host setDisplayState $name active
            }
            default {
                $m_host setDisplayState $name disabled
            }
        }
        if {[catch {
            onFieldChange $name $key $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
class DCS::StringFieldDisplayBase {
	inherit ::DCS::StringDisplayBase

    public method setLabelList { ll } { set m_labelList $ll }
    public method setStateList { ll } { set m_StateList $ll }

    #### only display, no change no submit
    #### support: text, timestamp, timespan
    #### the widget name starts with:
    #### ts_XXXX:     timestamp
    #### ti_XXXX:     timespan time interval
    #### other:       text
    protected variable m_labelList ""
    protected variable m_StateList ""

	protected method setContents
    ###derived classes may put a callback here
    protected method onFieldChange { name index value } {
    }

	constructor { host args } {
		eval ::DCS::StringDisplayBase::constructor $host $args
    } {
    }
}
body DCS::StringFieldDisplayBase::setContents { contents_ } {
    foreach {name index} $m_labelList {
        set value [lindex $contents_ $index]
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $m_host setDisplayLabel $name $displayValue

        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name index} $m_stateList {
        set value [lindex $contents_ $index]
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $m_host setDisplayState $name active
            }
            default {
                $m_host setDisplayState $name disabled
            }
        }
        if {[catch {
            onFieldChange $name $index $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
class DCS::SpectrometerWrapConfigView {
	inherit ::DCS::StringFieldViewBase

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set ll [llength $contents]
        if {$ll < 5} {
            log_error contents length wrong $ll < 5
            return 0
        }
        return 1
    }

    constructor { args } {
    } {
        set m_entryList [list \
        on_delay 0 \
        span_ref 1 \
        span_drk 2 \
        diameter 3 \
        min_avg  4 \
        ]

        #### ti_XXXX:     timespan time interval
        set m_labelList [list \
        ti_ref 1 \
        ti_drk 2 \
        ]

        ######create entries
        foreach {name index} $m_entryList {
            set cmd [list $this updateEntryColor $name $index %P]
            itk_component add $name {
                entry $m_site.$name \
                -font "helvetica -12 bold" \
                -justify right \
                -width 10 \
                -background white \
                -validate all \
                -vcmd $cmd
            } {
            }
            set m_origEntryBG [$itk_component($name) cget -background]
		    registerComponent $itk_component($name)
        }

        foreach {name index} $m_labelList {
            itk_component add $name {
                label  $m_site.$name \
                -width 12 \
                -anchor e \
                -background #00a040 \
                -text $name
            } {
            }
        }

        label $m_site.ll00 -anchor e -text "Light On Delay"
        label $m_site.ll10 -anchor e -text "Dark Valid Span"
        label $m_site.ll20 -anchor e -text "Reference Valid Span"
        label $m_site.ll30 -anchor e -text "Light Spot Diameter"
        label $m_site.ll40 -anchor e -text "Dark and Ref. Min. Average"

        label $m_site.ll02 -anchor w -text "s"
        label $m_site.ll32 -anchor w -text "mm"
        label $m_site.ll42 -anchor w -text "times"

        grid $m_site.ll00 -row 0 -column 0 -sticky e
        grid $m_site.ll10 -row 1 -column 0 -sticky e
        grid $m_site.ll20 -row 2 -column 0 -sticky e
        grid $m_site.ll30 -row 3 -column 0 -sticky e
        grid $m_site.ll40 -row 4 -column 0 -sticky e

        grid $itk_component(on_delay) -row 0 -column 1 -sticky news
        grid $itk_component(span_ref) -row 1 -column 1 -sticky news
        grid $itk_component(span_drk) -row 2 -column 1 -sticky news
        grid $itk_component(diameter) -row 3 -column 1 -sticky news
        grid $itk_component(min_avg)  -row 4 -column 1 -sticky news

        grid $m_site.ll02           -row 0 -column 2 -sticky w
        grid $itk_component(ti_ref) -row 1 -column 2 -sticky w
        grid $itk_component(ti_drk) -row 2 -column 2 -sticky w
        grid $m_site.ll32           -row 3 -column 2 -sticky w
        grid $m_site.ll42           -row 4 -column 2 -sticky w

		eval itk_initialize $args
		announceExist
        configure \
        -stringName ::device::spectroWrap_config
    }
}
class DCS::MicroSpecSystemBatchLevel2View {
	inherit ::DCS::StringFieldLevel2ViewBase

    protected method clearAddField { } {
        foreach ch $m_cfgNameList {
            $m_tableSite.${ch}Add delete 0 end
        }
    }

    public method addField { } {
        set wrapConfig [$m_objWrapConfig getContents]
        set minAvg [lindex $wrapConfig 4]

        foreach ch $m_cfgNameList vName {iTime nAvg bWidth} {
            set $vName [$m_tableSite.${ch}Add get]
        }
        set anyError 0
        if {![string is double  -strict $iTime] \
        ||  ![string is integer -strict $nAvg] \
        ||  ![string is integer -strict $bWidth] \
        || $iTime <= 0 \
        || $bWidth < 0 \
        } {
                log_error new config "{$iTime $nAvg $bWidth}" wrong
                return
        }
        $m_objWrap startOperation add_batch $iTime $nAvg $bWidth
    }
    public method deleteField { index } {
        set oldContents [getNewContents]
        set newContents [lreplace $oldContents $index $index]
        #puts "deleteField $index"
        #puts "old: $oldContents"
        #puts "new: {$newContents}"

        ### this local delete and can by Canceled.
        #setContents $newContents
        #updateAllEntryColor

        ### this is sending delete to the system, no cancel.
	    $_lastStringName sendContentsToServer $newContents
    }
    protected method updateAllEntryColor { } {
        foreach {wName index1 index2} $m_entryList {
            set v [$itk_component($wName) get]
            updateEntryColor $wName $index1 $index2 $v
        }
    }

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set wrapConfig [$m_objWrapConfig getContents]
        set minAvg [lindex $wrapConfig 4]

        set anyError 0
        foreach cfg $contents {
            foreach {t a b} $cfg break
            if {![string is double  -strict $t] \
            ||  ![string is integer -strict $a] \
            ||  ![string is integer -strict $b] \
            || $t < 0 \
            || $a < 0 \
            || $b < 0 \
            } {
                log_error config "{$cfg}" wrong
                incr anyError
            }
            if {$a < $minAvg} {
                log_error "{$cfg}" number average $a < min=$minAvg
                incr anyError
            }
        }
        if {$anyError} {
            return 0
        }

        return 1

    }

    private method addRows { num } {
        for {set i 0} {$i < $num} {incr i} {
            set index1 $m_numRowCreated
            set index2  -1
            foreach name $m_cfgNameList {
                incr index2 
                set wName $name$m_numRowCreated
                itk_component add $wName {
                    set cmd [list $this updateEntryColor $wName $index1 $index2 %P]
                    entry $m_tableSite.$wName \
                    -justify right \
                    -validate all \
                    -vcmd $cmd \
                    -width 15 \
                    -background white \
                } {
                }
            }
            itk_component add ${wName}Delete {
                DCS::Button $m_tableSite.${wName}Delete \
                -text "Delete" \
                -width 6 \
                -command "$this deleteField $m_numRowCreated" \
            } {
                keep -systemIdleOnly -activeClientOnly
            }
            incr m_numRowCreated
        }
    }
    private method adjustRows { num } {
        puts "adjustRows: $num current=$m_numRowDisplayed"

        if {$num == $m_numRowDisplayed} {
            return
        }
        if {$num > $m_numRowCreated} {
            addRows [expr $num - $m_numRowCreated]
        }

        while {$m_numRowDisplayed < $num} {
            set col  -1
            foreach name $m_cfgNameList {
                incr col 
                set wName $name$m_numRowDisplayed
                lappend m_entryList $wName $m_numRowDisplayed $col

                grid $itk_component($wName) \
                -row [expr $m_numRowDisplayed + 1] \
                -column $col \
                -sticky news
            }
            incr col 
            grid $itk_component(${wName}Delete) \
            -row [expr $m_numRowDisplayed + 1] \
            -column $col \

            incr m_numRowDisplayed
        }

        set need_cleanList 0
        if {$m_numRowDisplayed > $num} {
            set need_cleanList 1
        }
        while {$m_numRowDisplayed > $num} {
            set slaves [grid slaves $m_tableSite -row $m_numRowDisplayed]
            if {$slaves != ""} {
                eval grid forget $slaves
            }
            incr m_numRowDisplayed -1
        }
        if {$need_cleanList} {
            ### clean up list (not efficient)
            set old $m_entryList
            set m_entryList ""
            foreach {name index1 index2} $old {
                if {$index1 < $num} {
                    lappend m_entryList $name $index1 $index2
                }
            }
            #puts "old entryList: $old"
            #puts "new entryList: $m_entryList"
        }
        set i 0
        set row [expr $num + 1]
        foreach ch $m_cfgNameList {
            grid $m_tableSite.${ch}Add -row $row -column $i -sticky news
            incr i
        }
        grid $itk_component(addField) -row $row -column $i
    }

    ##override base class
    protected method setContents { contents_ } {
        set ll [llength $contents_]

        puts "setContents ll=$ll"
        adjustRows $ll

        clearAddField

	    DCS::StringFieldLevel2ViewBase::setContents $contents_
    }

    private variable m_objWrap ""
    private variable m_objWrapConfig ""
    private variable m_numRowCreated 0
    private variable m_numRowDisplayed 0
    private variable m_cfgNameList [list \
    "integration_time" \
    "average_times" \
    "boxcar_width" \
    ]

    private variable m_tableSite ""

    constructor { args } {
    } {
        ## we support remove field.
        set m_allFieldDisplayed 1

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_objWrap       [$deviceFactory createOperation spectrometerWrap]
        set m_objWrapConfig [$deviceFactory createString spectroWrap_config]


        set m_tableSite $m_site
        set headerSite  $m_site

        set i -1
        foreach ch $m_cfgNameList {
            incr i

            label $headerSite.ch$i \
            -text $ch \
            -relief groove

            entry $m_tableSite.${ch}Add \
            -justify right \
            -width 15 \
            -background white \

            grid $headerSite.ch$i      -row 0 -column $i -sticky news
            grid $m_tableSite.${ch}Add -row 1 -column $i -sticky news

        }
        itk_component add addField {
            DCS::Button $m_tableSite.addField \
            -width 6 \
            -text "Add" \
            -command "$this addField" \
        } {
            keep -systemIdleOnly -activeClientOnly
        }
        incr i
        grid $itk_component(addField) -row 1 -column $i

        $itk_component(addField) addInput \
        "$m_objWrap permission GRANTED {PERMISSION}"

		eval itk_initialize $args
		announceExist
        configure \
        -stringName ::device::microspec_setup_batch
    }
}
class DCS::MicroSpecIonChamberLevel2View {
	inherit ::DCS::StringFieldLevel2ViewBase

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        set anyError 0
        foreach cfg $contents {
            foreach {a b} $cfg break
            if {![string is integer -strict $a] \
            ||  ![string is integer -strict $b] \
            } {
                log_error config "{$cfg}" wrong
                incr anyError
            }
        }
        if {$anyError} {
            return 0
        }

        return 1

    }

    private method addRows { num } {
        for {set i 0} {$i < $num} {incr i} {
            label $m_tableSite.ll$m_numRowCreated \
            -text "i_microSpect_$m_numRowCreated"

            set index1 $m_numRowCreated
            set index2  -1
            foreach name $m_cfgNameList {
                incr index2 
                set wName $name$m_numRowCreated
                itk_component add $wName {
                    set cmd [list $this updateEntryColor $wName $index1 $index2 %P]
                    entry $m_tableSite.$wName \
                    -justify right \
                    -validate all \
                    -vcmd $cmd \
                    -width 15 \
                    -background white \
                } {
                }
            }
            incr m_numRowCreated
        }
    }
    private method adjustRows { num } {
        puts "adjustRows: $num current=$m_numRowDisplayed"

        if {$num == $m_numRowDisplayed} {
            return
        }
        if {$num > $m_numRowCreated} {
            addRows [expr $num - $m_numRowCreated]
        }

        while {$m_numRowDisplayed < $num} {
            set col 0
            grid $m_tableSite.ll$m_numRowDisplayed \
            -row [expr $m_numRowDisplayed + 1] \
            -column $col \
            -sticky news

            foreach name $m_cfgNameList {
                incr col 
                set wName $name$m_numRowDisplayed
                lappend m_entryList $wName $m_numRowDisplayed [expr $col - 1]

                grid $itk_component($wName) \
                -row [expr $m_numRowDisplayed + 1] \
                -column $col \
                -sticky news
            }

            incr m_numRowDisplayed
        }

        set need_cleanList 0
        if {$m_numRowDisplayed > $num} {
            set need_cleanList 1
        }
        while {$m_numRowDisplayed > $num} {
            set slaves [grid slaves $m_tableSite -row $m_numRowDisplayed]
            if {$slaves != ""} {
                eval grid forget $slaves
            }
            incr m_numRowDisplayed -1
        }
        if {$need_cleanList} {
            ### clean up list (not efficient)
            set old $m_entryList
            set m_entryList ""
            foreach {name index1 index2} $old {
                if {$index1 < $num} {
                    lappend m_entryList $name $index1 $index2
                }
            }
            #puts "old entryList: $old"
            #puts "new entryList: $m_entryList"
        }
    }

    ##override base class
    protected method setContents { contents_ } {
        set ll [llength $contents_]

        puts "setContents ll=$ll"
        adjustRows $ll

	    DCS::StringFieldLevel2ViewBase::setContents $contents_
    }

    private variable m_numRowCreated 0
    private variable m_numRowDisplayed 0
    private variable m_cfgNameList [list \
    "start_wavelength" \
    "end_wavelength" \
    ]

    private variable m_tableSite ""

    constructor { args } {
    } {
        ## we support remove field.
        set m_allFieldDisplayed 1

        set m_tableSite $m_site
        set headerSite  $m_site

        set i 0
        label $headerSite.ch$i \
        -text "name" \
        -relief groove
        grid $headerSite.ch$i  -row 0 -column $i -sticky news
        foreach ch $m_cfgNameList {
            incr i

            label $headerSite.ch$i \
            -text $ch \
            -relief groove

            grid $headerSite.ch$i      -row 0 -column $i -sticky news
        }

		eval itk_initialize $args
		announceExist
        configure \
        -stringName ::device::microSpectIon_const
    }
}

#### each field will be a tab.
#### each tab is the same GUI.
#### It should be use for strings with no less than 2 levels.

class DCS::StringFieldTabViewBase {
	inherit ::DCS::StringViewBase

    #### the field to use a the tab name.
    #### -1 means it will just use field index 0, 1, 2,....
    itk_option define -nameField nameField NameField -1

    protected variable m_tabIndex 0
    protected variable m_baseSite ""

    ### these are per tab.
    protected variable m_entryList ""
    protected variable m_checkbuttonList ""

    #### only display, no change no submit
    #### support: text, timestamp, timespan
    #### the widget name starts with:
    #### ts_XXXX:     timestamp
    #### ti_XXXX:     timespan time interval
    #### other:       text
    protected variable m_labelList ""
    protected variable m_stateList ""

    ### to support hide some tabs.
    protected variable m_tabMap ""

    protected variable m_origEntryBG white
    protected variable m_origCheckButtonFG black
    protected variable m_origTabBG gray

	protected method setContents
	protected method getNewContents

    protected method updatePage { pageContents_ }

    ### must use this, not directly use string
    protected method getFieldContents { } {
        set contents [$_lastStringName getContents]
        set fIndex [lindex $m_tabMap $m_tabIndex]
        return [lindex $contents $fIndex]
    }

    ###derived classes may put a callback here
    protected method onFieldChange { name indexList value } {
    }

    ### derived classess need to override this if need.
    protected method shouldDisplay { fIndex fContents } { return 1}

    protected common gCheckButtonVar

    public method updateEntryColor { name indexList newValue } {
        set bg red
        if {$_lastStringName != ""} {
            set contents [getFieldContents]
            set refValue [getMultiLevelListElement $contents $indexList]
            if {$refValue == $newValue} {
                set bg $m_origEntryBG
            }
        }
        $itk_component($name) configure \
        -background $bg

        if {[catch {
            onFieldChange $name $indexList $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
        return 1
    }
    public method updateCheckButtonColor { name indexList } {
        set fg red
        if {$_lastStringName != ""} {
            set contents [getFieldContents]
            set refValue [getMultiLevelListElement $contents $indexList]
            set newValue $gCheckButtonVar($this,$name)
            if {$refValue == $newValue} {
                set fg $m_origCheckButtonFG
            }
        }
        $itk_component($name) configure \
        -foreground $fg \
        -disabledforeground $fg \
        -activeforeground $fg

        if {[catch {
            onFieldChange $name $indexList $newValue
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }

    public method onTabSwitch { index } {
        set m_tabIndex $index
        if {$_lastStringName != ""} {
            set pContents [getFieldContents]
            updatePage $pContents
        }
    }

	constructor { args } {
        itk_component add rootTab {
            iwidgets::tabnotebook $m_site.roottab \
        } {
            keep -tabpos
        }
        $itk_component(rootTab) add \
        -label "0" \
        -command "$this onTabSwitch 0"

        set tabs [$itk_component(rootTab) component tabset]
        set m_origTabBG [$tabs cget -background]


        set childsite [$itk_component(rootTab) childsite 0]
        $itk_component(rootTab) select 0
        set m_tabIndex 0
        $itk_component(rootTab) configure \
        -auto 0

        #### replace m_site so that derived class can use it.
        set m_baseSite $m_site
        set m_site $childsite

        pack $itk_component(rootTab) -expand 1 -fill both

		eval itk_initialize $args
		announceExist
    }
}
body DCS::StringFieldTabViewBase::setContents { contents_ } {
    set oldFIndex [lindex $m_tabMap $m_tabIndex]

    #### update tab labels
    set lStr [llength $contents_]

    set tabLabelList [list]
    if {$itk_option(-nameField) < 0} {
        for {set i 0} {$i < $lStr} {incr i} {
            lappend tabLabelList $i
        }
    } else {
        for {set i 0} {$i < $lStr} {incr i} {
            lappend tabLabelList [lindex $contents_ $i $itk_option(-nameField)]
        }
    }

    set lTab [$itk_component(rootTab) index end]
    incr lTab
    puts "setContents, tabLabelList=$tabLabelList lTab=$lTab lStr=$lStr"

    set m_tabMap [list]
    set numTab -1
    for {set i 0} {$i < $lStr} {incr i} {
        set fContents [lindex $contents_ $i]
        if {![shouldDisplay $i $fContents]} {
            continue
        }

        incr numTab
        set tLabel [lindex $tabLabelList $i]
        if {$numTab < $lTab} {
            $itk_component(rootTab) pageconfigure $numTab \
            -label $tLabel \
            -command "$this onTabSwitch $numTab"
        } else {
            $itk_component(rootTab) add \
            -label $tLabel \
            -command "$this onTabSwitch $numTab"
        }
        lappend m_tabMap $i
    }
    incr numTab
    if {$lTab > $numTab} {
        $itk_component(rootTab) delete $numTab end
    }

    ## try to show current page
    puts "try to display current page tabMap=$m_tabMap, oldFIndex={$oldFIndex}"
    set tabIndex 0
    set i -1
    foreach fIndex $m_tabMap {
        incr i
        if {$fIndex == $oldFIndex} {
            set tabIndex $i
            puts "set tabIndex to $i"
            break
        }
    }
    
    puts "select $tabIndex"
    $itk_component(rootTab) select $tabIndex
    onTabSwitch $tabIndex
}
body DCS::StringFieldTabViewBase::updatePage { contents_ } {
    puts "updatePage :$contents_"
    foreach {name indexList } $m_entryList {
        set value [getMultiLevelListElement $contents_ $indexList]
        $itk_component($name) delete 0 end
        $itk_component($name) insert 0 $value
        $itk_component($name) configure \
        -background $m_origEntryBG

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList } $m_checkbuttonList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set gCheckButtonVar($this,$name) $value
        #puts "set $name to $value"
        $itk_component($name) configure \
        -foreground $m_origCheckButtonFG

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList } $m_labelList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set prefix [string range $name 0 2]
        switch -exact -- $prefix {
            ts_ {
                if {![string is integer -strict $value]} {
                    set displayValue $value
                } else {
                    set displayValue [clock format $value -format "%D %T"]
                }
            }
            ti_ {
                set displayValue [secondToTimespan $value]
            }
            td_ {
                set displayValue [secondToDue $value]
            }
            default {
                set displayValue $value
            }
        }

        $itk_component($name) configure \
        -text $displayValue

        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
    foreach {name indexList} $m_stateList {
        set value [getMultiLevelListElement $contents_ $indexList]
        set firstChar [string index $value 0]
        switch -exact -- $firstChar {
            1 -
            Y -
            y -
            T -
            t {
                $itk_component($name) configure \
                -state active
            }
            default {
                $itk_component($name) configure \
                -state disabled
            }
        }
        if {[catch {
            onFieldChange $name $indexList $value
        } errMsg]} {
            puts "Error onFieldChange $name: $errMsg"
        }
    }
}
body DCS::StringFieldTabViewBase::getNewContents { } {
    set wholeContents [$_lastStringName getContents]
    set contents [getFieldContents]
    # same as set contents [lindex $wholeContents $m_tabIndex]

    foreach {name indexList} $m_entryList {
        set value [$itk_component($name) get]
        set contents [setMultiLevelListElement $contents $indexList $value]
    }
    foreach {name indexList} $m_checkbuttonList {
        set value $gCheckButtonVar($this,$name)
        set contents [setMultiLevelListElement $contents $indexList $value]
    }
    set fIndex [lindex $m_tabMap $m_tabIndex]
    return [lreplace $wholeContents $fIndex $fIndex $contents]
}

class DCS::CollimatorPresetTabView {
	inherit ::DCS::StringFieldTabViewBase

    public method handleCurrentHarmonic { - ready_ - contents_ - }
    public method handleCollimatorStatus { - ready_ - contents_ - }

    public method refresh { } {
	    setContents [$_lastStringName getContents]
        updateTabColor
    }

    ## button
    public method updatePosition { {all 0} }
    public method moveTo { } {
        set fIndex [lindex $m_tabMap $m_tabIndex]
        $m_opCollimatorMove startOperation $fIndex
    }
    public method staffStart { } {
        $m_opStaffAlignBeam startOperation
    }

    private method createPropertySection { site }
    private method createScanSection { site }
    private method createResultSection { site }
    private method createControlSection { site }

    ###override
    protected method shouldDisplay { fIndex fContents } {
        if {$m_idxShow < 0} {
            return 1
        }
        if {!$gCheckButtonVar($this,onlyShowDisplay)} {
            return 1
        }
        return [lindex $fContents $m_idxShow]
    }

    protected method updateTabColor { }

    private variable m_cfgNameList [::config getStr collimatorPresetNameList]
    private variable m_idxShow ""

    private variable m_resultSite ""
    private variable m_origLabelBG gray

    private variable m_opCollimatorMove ""
    private variable m_ctsCollimatorStatus "0 -1 2.0 2.0"
    private variable m_ctsCurrentHarmonic 0
    private variable m_strUserAlignBeamStatus ""

    constructor { args } {
    } {
        set m_idxShow [lsearch -exact $m_cfgNameList display]

        set deviceFactory [DCS::DeviceFactory::getObject]
        set strCurrentHarmonic  [$deviceFactory getObjectName currentHarmonic]
        set strCollimatorStatus [$deviceFactory getObjectName collimator_status]
        set m_strUserAlignBeamStatus \
        [$deviceFactory getObjectName user_align_beam_status]

        set m_opCollimatorMove  [$deviceFactory createOperation collimatorMove]

        itk_component add propertyFrame {
            iwidgets::labeledframe $m_site.propertyF \
            -labeltext "Properties"
        } {
        }
        itk_component add scanFrame {
            iwidgets::labeledframe $m_site.scanF \
            -labeltext "Scan Parameters"
        } {
        }
        itk_component add resultFrame {
            iwidgets::labeledframe $m_site.resultF \
            -labeltext "Collimator Positions"
        } {
        }
        set pSite [$itk_component(propertyFrame) childsite]
        set sSite [$itk_component(scanFrame) childsite]
        set rSite [$itk_component(resultFrame) childsite]
        set cSite [frame $m_site.controlF]

        createPropertySection $pSite
        createScanSection     $sSite
        createResultSection   $rSite
        createControlSection  $cSite
        set m_resultSite $rSite

        itk_component add onlyShowDisplay {
            checkbutton $m_site.onlyShowDisplay \
            -command "$this refresh" \
            -anchor w \
            -variable [scope gCheckButtonVar($this,onlyShowDisplay)] \
            -text "Only Show Presets That users can see" \
        } {
        }

        set idxName [lsearch -exact $m_cfgNameList name]
        itk_component add fieldName {
            label $m_site.fieldName \
            -text "field name" \
            -font "helvetica -16 bold" \
        } {
        }
        lappend m_labelList fieldName $idxName

        grid $itk_component(onlyShowDisplay) -row 0 -column 0 -columnspan 2 \
        -sticky w

        grid $itk_component(fieldName)       -row 1 -column 0 -columnspan 2 \
        -sticky w

        grid $itk_component(propertyFrame)   -row 2 -column 0 -sticky news
        grid $itk_component(scanFrame)       -row 2 -column 1 -sticky news
        grid $itk_component(resultFrame)     -row 3 -column 0 -columnspan 2

        grid $cSite                          -row 4 -column 0 -columnspan 2 \
        -sticky wn

        grid rowconfigure $m_site 4 -weight 10

		eval itk_initialize $args
		announceExist

        ::mediator register $this $strCurrentHarmonic contents \
        handleCurrentHarmonic

        ::mediator register $this $strCollimatorStatus contents \
        handleCollimatorStatus
    }
}
body DCS::CollimatorPresetTabView::createPropertySection { site } {
    set entryMap [list \
    name \
    width \
    height \
    focus_beam_width \
    focus_beam_height \
    tolerance_horz \
    tolerance_vert \
    flux_table \
    ]
    set entryRow [list 0 3 4 5 6 7 8 9]

    set checkbuttonMap   [list display is_micron_beam]
    set checkbuttonRow   [list 1        2]

    set entryWidth 20
    foreach fName $entryMap {
        set index [lsearch -exact $m_cfgNameList $fName]
        if {$index < 0} {
            puts "$fName not found in collimator preset name list"
            continue
        }
        set cmd [list $this updateEntryColor $fName $index %P]
        itk_component add $fName {
            entry $site.$fName \
            -background white \
            -width $entryWidth \
            -validate all \
            -vcmd $cmd \
        } {
        }
		registerComponent $itk_component($fName)
        set m_origEntryBG [$itk_component($fName) cget -background]

        lappend m_entryList $fName $index
    }

    foreach fName $checkbuttonMap {
        set index [lsearch -exact $m_cfgNameList $fName]
        if {$index < 0} {
            puts "$fName not found in collimator preset name list"
            continue
        }
        set cmd [list $this updateCheckButtonColor $fName $index]
        itk_component add $fName {
            checkbutton $site.$fName \
            -background darkgray \
            -command $cmd \
            -anchor w \
            -variable [scope gCheckButtonVar($this,$fName)] \
            -text Yes \
        } {
        }
		registerComponent $itk_component($fName)
        set m_origCheckButtonFG [$itk_component($fName) cget -foreground]
        lappend m_checkbuttonList $fName $index
    }

    label $site.l00 -text "Name"
    label $site.l10 -text "Display to User"
    label $site.l20 -text "Is Micro-Pinhole"
    label $site.l30 -text "Width"
    label $site.l40 -text "Height"
    label $site.l50 -text "Focus Beam Width"
    label $site.l60 -text "Focus Beam Height"
    label $site.l70 -text "Horz Tolerance"
    label $site.l80 -text "Vert Tolerance"
    label $site.l90 -text "Flux Table Name"

    label $site.l32 -text "mm"
    label $site.l42 -text "mm"
    label $site.l52 -text "mm"
    label $site.l62 -text "mm"
    label $site.l72 -text "mm"
    label $site.l82 -text "mm"

    for {set i 0} {$i < 10} {incr i} {
        grid $site.l${i}0 -row $i -column 0 -sticky e
    }
    foreach fName $entryMap row $entryRow {
        grid $itk_component($fName) \
        -row $row -column 1 -sticky news
    }
    foreach fName $checkbuttonMap row $checkbuttonRow {
        grid $itk_component($fName) \
        -row $row -column 1 -sticky news
    }
    for {set i 3} {$i < 9} {incr i} {
        grid $site.l${i}2 -row $i -column 2 -sticky w
    }
}
body DCS::CollimatorPresetTabView::createScanSection { site } {
    set entryWidth 15
    ### first level index
    set scanParameterIndex [lsearch -exact $m_cfgNameList scan_parameter]

    set scanParameterFieldNameList \
    [::config getStr "alignCollimatorConstantsNameList"]

    set hvMap [list \
    horz_scan_width \
    horz_scan_points \
    horz_scan_time \
    horz_scan_wait \
    vert_scan_width \
    vert_scan_points \
    vert_scan_time \
    vert_scan_wait \
    staff_horz_scan_width \
    staff_horz_scan_points \
    staff_vert_scan_width \
    staff_vert_scan_points \
    ]

    set hvSite [frame $site.hvF]

    label $hvSite.l10 -text "User Horz"
    label $hvSite.l20 -text "User Vert"
    label $hvSite.l30 -text "Staff Horz" 
    label $hvSite.l40 -text "Staff Vert"

    label $hvSite.l01 -text "Width(mm)"
    label $hvSite.l02 -text "Points"
    label $hvSite.l03 -text "Integat. Time(s)"
    label $hvSite.l04 -text "Settling Time(s)"

    foreach fName $hvMap {
        set index2 [lsearch -exact $scanParameterFieldNameList $fName]
        if {$index2 < 0} {
            puts "$fName not found in scan collimator parameter name list"
            continue
        }
        set comName sp_$fName
        set indexList [list $scanParameterIndex $index2]
        set cmd [list $this updateEntryColor $comName $indexList %P]
        itk_component add $comName {
            entry $hvSite.$comName \
            -background white \
            -width $entryWidth \
            -validate all \
            -vcmd $cmd \
        } {
        }
		registerComponent $itk_component($comName)
        lappend m_entryList $comName $indexList
    }
    grid \
    x \
    $hvSite.l01 \
    $hvSite.l02 \
    $hvSite.l03 \
    $hvSite.l04

    grid \
    $hvSite.l10 \
    $itk_component(sp_horz_scan_width) \
    $itk_component(sp_horz_scan_points) \
    $itk_component(sp_horz_scan_time) \
    $itk_component(sp_horz_scan_wait) \

    grid \
    $hvSite.l20 \
    $itk_component(sp_vert_scan_width) \
    $itk_component(sp_vert_scan_points) \
    $itk_component(sp_vert_scan_time) \
    $itk_component(sp_vert_scan_wait) \

    grid \
    $hvSite.l30 \
    $itk_component(sp_staff_horz_scan_width) \
    $itk_component(sp_staff_horz_scan_points)

    grid \
    $hvSite.l40 \
    $itk_component(sp_staff_vert_scan_width) \
    $itk_component(sp_staff_vert_scan_points)

    label $site.separate \
    -anchor w \
    -text "-------------------------------------------------"

    ##global site
    set gSite [frame $site.gFrame]

    set gMap [list fluorescence_z signal min_signal good_signal \
    max_horz_move max_vert_move] 
    foreach fName $gMap {
        set index2 [lsearch -exact $scanParameterFieldNameList $fName]
        if {$index2 < 0} {
            puts "$fName not found in scan collimator parameter name list"
            continue
        }
        set comName sp_$fName
        set indexList [list $scanParameterIndex $index2]
        set cmd [list $this updateEntryColor $comName $indexList %P]
        itk_component add $comName {
            entry $gSite.$comName \
            -background white \
            -width $entryWidth \
            -validate all \
            -vcmd $cmd \
        } {
        }
		registerComponent $itk_component($comName)
        lappend m_entryList $comName $indexList
    }

    set i -1
    set index2 [lsearch -exact $scanParameterFieldNameList attenuation]
    foreach harmonic [list 11 9 7 5] {
        incr i
        set comName sp_att$harmonic
        set indexList [list $scanParameterIndex $index2 $i]
        set cmd [list $this updateEntryColor $comName $indexList %P]
        itk_component add $comName {
            entry $gSite.$comName \
            -background white \
            -width $entryWidth \
            -validate all \
            -vcmd $cmd \
        } {
        }
		registerComponent $itk_component($comName)
        lappend m_entryList $comName $indexList
    }

    label $gSite.l00 -text "Fluor.Z"
    label $gSite.l10 -text "Signal"
    label $gSite.l20 -text "Min Peak"
    label $gSite.l30 -text "Good Peak"
    label $gSite.l40 -text "Max Horz Move"
    label $gSite.l50 -text "Max Vert Move"

    label $gSite.l02 -text "mm"
    label $gSite.l42 -text "mm"
    label $gSite.l52 -text "mm"

    label $gSite.l03 -text "Attenuation"
    label $gSite.l13 -text "11th Harmonic"
    label $gSite.l23 -text "9th Harmonic"
    label $gSite.l33 -text "7th Harmonic"
    label $gSite.l43 -text "5th Harmonic"

    label $gSite.l15 -text "%"
    label $gSite.l25 -text "%"
    label $gSite.l35 -text "%"
    label $gSite.l45 -text "%"

    for {set i 0} {$i < 6} {incr i} {
        grid $gSite.l${i}0 -row $i -column 0 -sticky e
    }
    grid $itk_component(sp_fluorescence_z) -column 1 -row 0 -sticky news
    grid $itk_component(sp_signal)         -column 1 -row 1 -sticky news
    grid $itk_component(sp_min_signal)     -column 1 -row 2 -sticky news
    grid $itk_component(sp_good_signal)    -column 1 -row 3 -sticky news
    grid $itk_component(sp_max_horz_move)  -column 1 -row 4 -sticky news
    grid $itk_component(sp_max_vert_move)  -column 1 -row 5 -sticky news
    
    grid $gSite.l02 -column 2 -row 0 -sticky w
    grid $gSite.l42 -column 2 -row 4 -sticky w
    grid $gSite.l52 -column 2 -row 5 -sticky w

    for {set i 0} {$i < 5} {incr i} {
        grid $gSite.l${i}3 -row $i -column 3 -sticky e
    }
    for {set i 1} {$i < 5} {incr i} {
        grid $gSite.l${i}5 -row $i -column 5 -sticky e
    }
    grid $itk_component(sp_att11) -column 4 -row 1 -sticky news
    grid $itk_component(sp_att9)  -column 4 -row 2 -sticky news
    grid $itk_component(sp_att7)  -column 4 -row 3 -sticky news
    grid $itk_component(sp_att5)  -column 4 -row 4 -sticky news

    grid columnconfigure $gSite 2 -weight 10

    pack $hvSite -side top
    pack $site.separate -side top -fill x
    pack $gSite -side bottom -fill x
}
body DCS::CollimatorPresetTabView::createResultSection { site } {
    set entryWidth 18

    set idxStaffScan [lsearch -exact $m_cfgNameList staff_scan_enable]
    for {set i 0} {$i < 4} {incr i} {
        set indexList [list $idxStaffScan $i]
        set comName staff_$i
        set cmd [list $this updateCheckButtonColor $comName $indexList]
        itk_component add $comName {
            checkbutton $site.$comName \
            -background darkgray \
            -command $cmd \
            -anchor w \
            -variable [scope gCheckButtonVar($this,$comName)] \
            -text "Yes" \
        } {
        }
        registerComponent $itk_component($comName)
        lappend m_checkbuttonList $comName $indexList

        grid $itk_component($comName) -column 1 -row [expr $i + 1]
    }

    set idxTrigger [lsearch -exact $m_cfgNameList trigger_time]
    for {set i 0} {$i < 4} {incr i} {
        set indexList [list $idxTrigger $i]
        set comName ts_trigger_$i
        itk_component add $comName {
            label $site.$comName \
            -anchor e \
            -background #00a040 \
            -width 17 \
            -text $comName \
        } {
        }

        lappend m_labelList $comName $indexList

        grid $itk_component($comName) -column 2 -row [expr $i + 1]

        ### hidden, will use them to update trigger_time with
        ### "Update Position" button
        set comName trigger_time$i
        itk_component add $comName {
            entry $site.$comName \
            -width 40 \
        } {
        }
        lappend m_entryList $comName $indexList
    }

    set timestampIndex [lsearch -exact $m_cfgNameList timestamp]
    if {$timestampIndex >= 0} {
        for {set i 0} {$i < 4} {incr i} {
            set indexList [list $timestampIndex $i]
            set comName ts_$i
            itk_component add $comName {
                label $site.$comName \
                -anchor e \
                -background #00a040 \
                -width 17 \
                -text $comName \
            } {
            }

            lappend m_labelList $comName $indexList

            grid $itk_component($comName) -column 3 -row [expr $i + 1]

            ### hidden, will use them to update timestamp with
            ### "Update Position" button
            set comName timestamp$i
            itk_component add $comName {
                entry $site.$comName \
                -width 40 \
            } {
            }
            lappend m_entryList $comName $indexList
        }
    }

    ### first level index
    set firstMap [list horz_encoder vert_encoder horz vert]
    set col 3
    foreach fName $firstMap {
        incr col
        set firstIndex [lsearch -exact $m_cfgNameList $fName]
        if {$firstIndex < 0} {
            puts "$fName not found in collimator preset name list"
            continue
        }
        for {set i 0} {$i < 4} {incr i} {
            set indexList [list $firstIndex $i]
            set comName ${fName}$i
            set cmd [list $this updateEntryColor $comName $indexList %P]
            itk_component add $comName {
                entry $site.$comName \
                -background white \
                -width $entryWidth \
                -validate all \
                -vcmd $cmd \
            } {
            }
            grid $itk_component($comName) -column $col -row [expr $i + 1]
		    registerComponent $itk_component($comName)
            lappend m_entryList $comName $indexList
        }
    }

    label $site.l01 -text "Staff Scan"
    label $site.l02 -text "Trigger Time"
    label $site.l03 -text "TimeStamp"
    label $site.l04 -text "Horz Encoder(mm)"
    label $site.l05 -text "Vert Encoder(mm)"
    label $site.l06 -text "Horz Motor(mm)"
    label $site.l07 -text "Vert Motor(mm)"
    for {set i 1} {$i < 8} {incr i} {
        grid $site.l0$i -column $i -row 0 -sticky wes
    }

    label $site.l10 -text "Harmonic 11th"
    label $site.l20 -text "Harmonic 9th"
    label $site.l30 -text "Harmonic 7th"
    label $site.l40 -text "Harmonic 5th"
    set m_origLabelBG [$site.l10 cget -background]

    for {set i 1} {$i < 5} {incr i} {
        grid $site.l${i}0 -column 0 -row $i -sticky e
    }
}
body DCS::CollimatorPresetTabView::createControlSection { site } {
    itk_component add move {
        button $site.moveButton \
        -text "Insert" \
        -command "$this moveTo"
    } {
    }
    itk_component add update {
        button $site.updateButton \
        -text "Update Position" \
        -command "$this updatePosition"
    } {
    }
    itk_component add updateAll {
        button $site.updateAllButton \
        -background red \
        -text "Update All Harmonic Position" \
        -command "$this updatePosition 1"
    } {
    }
    set index [lsearch -exact $m_cfgNameList adjust]
    set cmd [list $this updateCheckButtonColor adjust $index]
    itk_component add adjust {
        checkbutton $site.adjust \
        -background darkgray \
        -command $cmd \
        -anchor w \
        -variable [scope gCheckButtonVar($this,adjust)] \
        -text "Auto adjust position with first micro collimator" \
    } {
    }
    registerComponent $itk_component(adjust)
    lappend m_checkbuttonList adjust $index

    pack $itk_component(move) -side left
    pack $itk_component(update) -side left
    pack $itk_component(updateAll) -side left
    pack $itk_component(adjust) -side right
}
body DCS::CollimatorPresetTabView::handleCurrentHarmonic { - ready_ - contents_ - } {
    if {!$ready_} {
        return
    }
    set m_ctsCurrentHarmonic $contents_

    if {![string is integer -strict $contents_]} {
        set currentRow -1
    } else {
        set currentRow [expr $contents_ + 1]
    }
    for {set i 1} {$i < 5} {incr i} {
        if {$i == $currentRow} {
            set bg "light green"
        } else {
            set bg $m_origLabelBG
        }
        $m_resultSite.l${i}0 configure \
        -background $bg
    }
}
body DCS::CollimatorPresetTabView::handleCollimatorStatus { - ready_ - contents_ - } {
    if {!$ready_} {
        set m_ctsCollimatorStatus "0 -1 2.0 2.0"
    } else {
        set m_ctsCollimatorStatus $contents_
    }
    updateTabColor
}

body DCS::CollimatorPresetTabView::updateTabColor { } {
    set indexMatched [lindex $m_ctsCollimatorStatus 1]
    if {![string is integer -strict $indexMatched]} {
        set indexMatched -1
    }

    set tabs [$itk_component(rootTab) component tabset]

    set lTab [$itk_component(rootTab) index end]
    incr lTab
    for {set i 0} {$i < $lTab} {incr i} {
        set fIndex [lindex $m_tabMap $i]
        if {$fIndex == $indexMatched} {
            set bg "light green"
        } else {
            set bg $m_origTabBG
        }
        $tabs tabconfigure $i \
        -selectbackground $bg \
        -background $bg
    }
}
body DCS::CollimatorPresetTabView::updatePosition { {all 0} } {
    if {$all == 0} {
        if {![string is integer -strict $m_ctsCurrentHarmonic]} {
            log_error wrong harmonic: not an integer $m_ctsCurrentHarmonic
            return
        }
        if {$m_ctsCurrentHarmonic < 0 || $m_ctsCurrentHarmonic > 3} {
            log_error wrong harmonic: $m_ctsCurrentHarmonic
            return
        }
    }

    set motorList [list \
    collimator_horz_encoder_motor \
    collimator_vert_encoder_motor \
    collimator_horz \
    collimator_vert]

    set comList [list \
    horz_encoder \
    vert_encoder \
    horz \
    vert]

    set tNow [clock seconds]
    set ctsUser [$m_strUserAlignBeamStatus getContents]
    set span [lindex $ctsUser 3]
    set tTrigger [expr $tNow + $span]
    foreach cName $comList motor $motorList {
        set value [lindex [::device::$motor getScaledPosition] 0]
        for {set i 0} {$i < 4} {incr i} {
            if {!$all && $i != $m_ctsCurrentHarmonic} {
                continue
            }
            $itk_component($cName$i) delete 0 end
            $itk_component($cName$i) insert 0 $value

            $itk_component(timestamp$i) delete 0 end
            $itk_component(timestamp$i) insert 0 $tNow

            $itk_component(trigger_time$i) delete 0 end
            $itk_component(trigger_time$i) insert 0 $tTrigger
        }
    }
}
class DCS::TriggerTimeForUserAlignBeam {
	inherit ::DCS::StringFieldMixLevelViewBase

    public method updateShowAll { } {
        set oneColumn ""
        for {set col 0} {$col < $m_numColumnDisplayed} {incr col} {
            regsub -all COLUMN $m_oneColumnList $col oneColumn

            set show2user [$itk_component(display$col) cget -text]
            set isMicro   [$itk_component(is_micro_beam$col) cget -text]

            if {$gCheckButtonVar($this,showAll) \
            || ($show2user == "1" && $isMicro == "1")} {
                foreach com $oneColumn {
                    grid $itk_component($com)
                }
            } else {
                foreach com $oneColumn {
                    grid remove $itk_component($com)
                }
            }
        }
    }

    public method handleStatusChange { - targetReady_ - contents_ - } {
        if {!$targetReady_} {
            ### no match
            set contents_ "-1 -1 0 0"
        }

        set m_currentCol [lindex $contents_ 1]
        if {![string is integer -strict $m_currentCol]} {
            set m_currentCol -1
        }
        updateTableCellBackground
    }
    private method updateTableCellBackground { } {
        for {set i 0} {$i < $m_numColumnCreated} {incr i} {
            if {$i == $m_currentCol} {
                set bg "light green"
            } else {
                set bg $m_colorBG
            }
            $itk_component(name$i) configure \
            -background $bg

            for {set j 0} {$j < 4} {incr j} {
                set row [expr $j + 1]
                if {$row == $m_currentRow} {
                    if {$i == $m_currentCol} {
                        set bg #00a040
                    } else {
                        set bg "light green"
                    }
                } else {
                    if {$i == $m_currentCol} {
                        set bg "light green"
                    } else {
                        set bg $m_colorBG
                    }
                }
                $itk_component(ts_trigger${j}$i) configure \
                -background $bg
            }
        }
    }
    public method handleCurrentHarmonic { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }

        if {![string is integer -strict $contents_]} {
            set m_currentRow -1
        } else {
            set m_currentRow [expr $contents_ + 1]
        }
        set headerSite  [$itk_component(scrolledFrame) hfreezesite]
        for {set i 1} {$i < 5} {incr i} {
            if {$i == $m_currentRow} {
                set bg "light green"
            } else {
                set bg $m_origLabelBG
            }
            $headerSite.rh$i configure \
            -background $bg

            $itk_component(ts_tungsten$i) configure \
            -background $bg

        }
        updateTableCellBackground
    }
    public method handleEnergyOffsetUpdate { - ready_ - contents_ - } {
        if {!$ready_} {
            return
        }
        if {[llength $contents_] != 4} {
            log_error energy_offset not match harmonics
            return
        }
        set i 0
        foreach offset $contents_ {
            incr i
            set triggerTime [lindex $offset $m_idxTriggerEnergy]
            if {$triggerTime == ""} {
                $itk_component(ts_tungsten$i) configure \
                -text ""
            } else {
                $itk_component(ts_tungsten$i) configure \
                -text [clock format $triggerTime -format "%D %T"]
            }
        }
    }

    protected method checkContentsBeforeSend { contentsREF } {
        upvar $contentsREF contents

        return 1

    }

    private method addColumns { num } {
        for {set i 0} {$i < $num} {incr i} {
            set index1 $m_numColumnCreated
            foreach {comp -} $LABEL_MAP subIdxList $m_labelSubIndexList {
                set wName $comp$m_numColumnCreated
                set indexList [linsert $subIdxList 0 $index1]
                if {$comp == "name"} {
                    itk_component add $wName {
                        label $m_tableSite.$wName \
                        -anchor w \
                    } {
                    }
                    if {$m_colorBG == ""} {
                        set m_colorBG [$itk_component($wName) cget -background]
                    }
                } else {
                    itk_component add $wName {
                        label $m_tableSite.$wName \
                        -relief sunken \
                        -anchor w \
                        -background #00a040 \
                    } {
                    }
                }
            }
            foreach {comp -} $HIDE_MAP subIdxList $m_hideSubIndexList {
                set wName $comp$m_numColumnCreated
                set indexList [linsert $subIdxList 0 $index1]
                itk_component add $wName {
                    label $m_tableSite.$wName \
                    -anchor w \
                } {
                }
            }
            incr m_numColumnCreated
        }
        pack $itk_component(scrolledFrame) -side left -fill both -expand true
    }
    private method adjustColumns { num } {
        if {$num == $m_numColumnDisplayed} {
            return
        }
        if {$num > $m_numColumnCreated} {
            addColumns [expr $num - $m_numColumnCreated]
        }

        while {$m_numColumnDisplayed < $num} {
            set col $m_numColumnDisplayed

            foreach \
            {comp -}   $LABEL_MAP \
            subIdxList $m_labelSubIndexList \
            row        $LABEL_ROW {
                set wName $comp$m_numColumnDisplayed
                set indexList [linsert $subIdxList 0 $col]
                lappend m_labelList $wName $indexList

                grid $itk_component($wName) \
                -ipady 1 \
                -column [expr $col + 1] \
                -row $row \
                -sticky news
            }
            foreach \
            {comp -}   $HIDE_MAP \
            subIdxList $m_hideSubIndexList {
                set wName $comp$m_numColumnDisplayed
                set indexList [linsert $subIdxList 0 $col]
                lappend m_labelList $wName $indexList
            }
            incr m_numColumnDisplayed
        }

        set need_cleanList 0
        if {$m_numColumnDisplayed > $num} {
            set need_cleanList 1
        }
        while {$m_numColumnDisplayed > $num} {
            set col $m_numColumnDisplayed
            set slaves [grid slaves $m_tableSite -column $col]
            if {$slaves != ""} {
                eval grid forget $slaves
            }
            incr m_numColumnDisplayed -1
        }
        if {$need_cleanList} {
            ### clean up list (not efficient)
            set old $m_labelList
            set m_labelList [list]
            foreach {name idxList} $old {
                set col [lindex $idxList 1]
                if {$col < $num} {
                    lappend m_labelList $name $idxList
                }
            }
        }
        pack $itk_component(scrolledFrame) -side left -fill both -expand true
    }

    ##override base class
    protected method setContents { contents_ } {
        set ll [llength $contents_]

        adjustColumns $ll

	    DCS::StringFieldMixLevelViewBase::setContents $contents_
    }

    private common HEAD_LABEL [list \
    "Trigger Time" \
    "Harmonic 11th" \
    "Harmonic 9th" \
    "Harmonic 7th" \
    "Harmonic 5th" \
    ]

    private common LABEL_MAP [list \
        name               name \
        ts_trigger0        {trigger_time 0} \
        ts_trigger1        {trigger_time 1} \
        ts_trigger2        {trigger_time 2} \
        ts_trigger3        {trigger_time 3} \
    ]
    private common LABEL_ROW [list 0 1 2 3 4]

    ### we need these to decide display or not
    private common HIDE_MAP [list \
        display         display \
        is_micro_beam   is_micron_beam \
    ]

    private variable m_numColumnCreated 0
    private variable m_numColumnDisplayed 0
    private variable m_cfgNameList ""
    private variable m_cfgScanNameList ""

    private variable m_oneColumnList ""

    private variable m_opCollimatorMove ""
    private variable m_strCollimatorStatus ""
    private variable m_colorBG ""
    private variable m_origLabelBG gray

    private variable m_tableSite ""

    private variable m_labelSubIndexList ""
    private variable m_hideSubIndexList ""

    private variable m_idxTriggerEnergy -1

    ### changing background color
    private variable m_currentRow -1
    private variable m_currentCol -1

    constructor { args } {
    } {
        set m_cfgNameList [::config getStr collimatorPresetNameList]
        set m_cfgScanNameList [::config getStr alignCollimatorConstantsNameList]

        set cfgEnergyOffsetNameList [::config getStr energyOffsetNameList]
        set m_idxTriggerEnergy \
        [lsearch -exact $cfgEnergyOffsetNameList trigger_time]
        if {$m_idxTriggerEnergy < 0} {
            set m_idxTriggerEnergy 0
        }

        array set fName2index [list]
        array set sName2index [list]
        foreach {comp name} $LABEL_MAP {
            set fName [lindex $name 0]
            if {![info exists fName2index($fName)]} {
                set fName2index($fName) [lsearch -exact $m_cfgNameList $fName]
            }
            set idxList $fName2index($fName)
            if {$fName == "trigger_time"} {
                lappend idxList [lindex $name 1]
            }

            lappend m_labelSubIndexList $idxList

            lappend m_oneColumnList ${comp}COLUMN

            puts "$comp: $idxList"
        }
        foreach {comp name} $HIDE_MAP {
            set fName [lindex $name 0]
            if {![info exists fName2index($fName)]} {
                set fName2index($fName) [lsearch -exact $m_cfgNameList $fName]
            }
            set idxList $fName2index($fName)

            lappend m_hideSubIndexList $idxList
            puts "$comp: $idxList"
        }

        set deviceFactory [DCS::DeviceFactory::getObject]
        set m_strCollimatorStatus \
        [$deviceFactory getObjectName collimator_status]

        set strCurrentHarmonic  [$deviceFactory getObjectName currentHarmonic]
        set strEnergyOffset     [$deviceFactory getObjectName energy_offset]

        itk_component add scrolledFrame {
            DCS::ScrolledFrame $m_site.canvas \
            -height 160 \
        } {
        }

        set m_tableSite [$itk_component(scrolledFrame) childsite]
        set headerSite  [$itk_component(scrolledFrame) hfreezesite]

        set i -1
        foreach txt $HEAD_LABEL {
            incr i

            label $headerSite.rh$i \
            -anchor e \
            -text $txt

            grid $headerSite.rh$i -row $i -column 0 -sticky e -ipady 1

            if {$i == 0} {
                label $headerSite.tttt \
                -text "Tungsten"

                grid $headerSite.tttt -row 0 -column 1 -sticky news

                continue
            }

            itk_component add ts_tungsten$i {
                label $headerSite.ts$i \
                -relief sunken \
                -anchor e \
                -background #00a040 \
                -width 17 \
            } {
            }

            grid $headerSite.ts$i -row $i -column 1 -sticky news
        }
        set m_origLabelBG [$headerSite.rh0 cget -background]

        incr i
        checkbutton $headerSite.onlyShowDisplayed \
        -text "Show All Collimators" \
        -variable [scope gCheckButtonVar($this,showAll)] \
        -command "$this updateShowAll"
        grid $headerSite.onlyShowDisplayed -row $i -column 0 -stick e \
        -columnspan 2


        grid columnconfigure $headerSite 0 -weight 1

        pack $itk_component(scrolledFrame) -side left -fill both -expand true
        $itk_component(scrolledFrame) xview moveto 0
        $itk_component(scrolledFrame) yview moveto 0

        grid forget $itk_component(apply) $itk_component(cancel)

		eval itk_initialize $args
		announceExist

        ::mediator register $this $m_strCollimatorStatus contents \
        handleStatusChange

        ::mediator register $this $strCurrentHarmonic    contents \
        handleCurrentHarmonic

        ::mediator register $this $strEnergyOffset    contents \
        handleEnergyOffsetUpdate

        updateShowAll
    }
}
