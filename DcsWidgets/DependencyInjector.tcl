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
# DcsConfig.tcl
#
# Loads config from files
#
package provide DependencyInjector 1.0
package require Itcl

class DCS::InitializingObject {

    public method afterPropertiesSet {} {}

}

# ===================================================
#
# ===================================================
class DCS::DependencyInjector {

    private variable CLASS_PROP (class)
    private variable PARENT_PROP (parent)
    private variable SINGLETON_PROP (singleton)
    private variable REF_PROP (ref)

    private variable _singletonArray
    private variable _propArray

    constructor { } {
        array set _singletonArray {}
        array set _propArray {}
    }

    public method load { filename } {

        set in [open $filename r]
        set raw [read $in]
        close $in

        #clean raw data & make array
        foreach line [split $raw "\n"] {
            #guard blank lines and comments
            set trimLine [string trim $line]
            if { $trimLine == "" } continue
            if { [string index $trimLine 0] == "#" } continue

            foreach {rawProp rawValue} [split $trimLine "="] {}
            set prop [string trim $rawProp]
            set val [string trim $rawValue]
            
            set _propArray($prop) $val
            #lappend clean $trimLine
        }    

        #puts [array names _propArray]

    }

    private method endsWith { str ending } {
        if {$ending == "" } {return true}
        set strLen [string length $str]
        set endLen [string length $ending]
        if {$strLen < $endLen } {return false}
        
        if { [string range $str [expr $strLen - $endLen] end] == "$ending" } {return true}
        return false
    }

    private method trimEnd { str ending } {
        if { ! [endsWith $str $ending] } {
            return $str
        }

        set strLen [string length $str]
        set endLen [string length $ending]

        return [string range $str  0 [expr $strLen - $endLen - 1]]
    }

    private method propBase { property } {
        return [string range $property  0 [expr [string first "." $property] -1]]
    }

    private method trimBase { property} {
        return [string range $property [expr [string first "." $property] +1] end]
    }

    private method checkRef { property} {
        return [string match "*${REF_PROP}" $property]
    }

    private method addItem { name className  } {
        set _singletonArray($name) [ItemStub #auto $className]
    }

    public method createObjectByName { name } {
        #return singleton if exists
        if { [info exists _singletonArray($name) ] } {
            return $_singletonArray($name)
        }
        set obj [onlyCreateObjectByName $name]
        configureAllProp $obj $name
        set singletonProp [array names _propArray -exact ${name}.$SINGLETON_PROP ]
        if { $_propArray($singletonProp) } {
            set _singletonArray($name) $obj
        }
        return $obj

    }


    private method onlyCreateObjectByName { name } {
        set classProp [array names _propArray -exact ${name}.$CLASS_PROP ]
        set parentProp [array names _propArray -exact ${name}.$PARENT_PROP ]
        set singletonProp [array names _propArray -exact ${name}.$SINGLETON_PROP ]
        if {$singletonProp == "" } {
            #default is singleton
            set singletonProp "${name}.$SINGLETON_PROP"
            set _propArray($singletonProp) true
        }

        if { $classProp == "" } {
            if {$parentProp == ""} {
                return -code error "no class defined for $name"
            }
            set obj [onlyCreateObjectByName $_propArray($parentProp) ]
        } else {
            set obj [namespace current]::[$_propArray($classProp) #auto]
        }

        return $obj
    }
    
    private method configureAllProp {obj name} {

        set parentProp [array names _propArray -exact ${name}.$PARENT_PROP ]

        if {$parentProp != "" } {
            configureAllProp $obj $_propArray($parentProp)
        }

        set propList [array names _propArray $name.*]
        #puts "yangx propList= $propList"

        foreach propName $propList {
            set prop [trimBase $propName]
            if {$prop == $CLASS_PROP } continue
            if {$prop == $PARENT_PROP } {
                continue
            }

            if {$prop == $SINGLETON_PROP } continue
            if { [checkRef $prop] } {
		#puts "yyang inside  _propArraypropName=$_propArray($propName)"
                set ref [createObjectByName $_propArray($propName)]
                $obj configure -[trimEnd $prop $REF_PROP] $ref
		#puts "yyang end config"
                continue
            }

            configureProp $obj $prop $_propArray($propName)
	    #puts "yyang prop=$prop  _propArray($propName)=$_propArray($propName)" 
        }
	#puts "yangx loop end"
        $obj afterPropertiesSet
    }

    private method configureProp {obj prop value} {
        $obj configure -$prop $value
    }

}

