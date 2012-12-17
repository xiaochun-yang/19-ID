package provide DCSPersistent 1.0

package require Itcl
namespace import ::itcl::*
package require huddle
package require yaml

package require DCSUtil

#### variable starts with "_" : ignore.
#### variable starts with "m_": save contents as string
#### variable starts with "l_": treat as list of strings.
#### variable starts with "d_": treat as dict.
#### variable starts with "o_": treat as object and save the object.
####                            The object should be DCSPersistentBase
#### variable starts with "lo": treat as list of objects.
####                            Save all objects.
#### variable starts with "ld": list of dict
#########################
#### Customize:
####  1. You can define DCSPERSISTENT_MANIFEST
####  2. You can define you own "toHuddle" interface and "fromHuddle" interface.

#################################################################
# derived class should have a constructor with no argument.
#
# previous objects in OBJECT and LIST_OBJECT may be reused or deleted.
# for now , we delete them.
#################################################################

#### file name and directory logical:
#### each object can have its own preferred sub-dir name and file name.
#### The goal is use file name prefix or use sub-dir for each level of obj.
#### Example:  Group1_Snapshot1_Grid2.yaml (current)
#### Example:  ./Group1/Snapshot1/Grid2.yaml

###################################
### All Persistent class will have access to a TOP object, which will hold
### the top_directory and you can register for load from file command.

### interface
class DCSPersistentBaseTop {
    public method getTopDirectory { } { return "." }

    #### obj must be DCSSelfPersistent, it will call [obj reload]
    public method registerSelfPersistentObject { obj }
    public method unregisterSelfPersistentObject { obj }
    public method getLoadAll { } { return $_loadAll }

    public method checkRegisteredSelfPersistentObjects { {forced 0} }
    public method flushRegisteredSelfPersistentObjects { {forced 0} }

    public method getAllSubFileRPath { }

    protected variable _registeredObjectList ""
    protected variable _loadAll 1
}
body DCSPersistentBaseTop::registerSelfPersistentObject { obj_ } {
    if {[lsearch -exact $_registeredObjectList $obj_] < 0} {
        lappend _registeredObjectList $obj_
    }
    puts "$obj_ registeredSefl to $this: queue=$_registeredObjectList"
}
body DCSPersistentBaseTop::unregisterSelfPersistentObject { obj_ } {
    set index [lsearch -exact $_registeredObjectList $obj_]
    if {$index >= 0} {
        set _registeredObjectList \
        [lreplace $_registeredObjectList $index $index]
    }
    puts "$obj_ unregisterdSELF to $this: queue=$_registeredObjectList"
}
body DCSPersistentBaseTop::checkRegisteredSelfPersistentObjects { {forced 0} } {
    foreach obj $_registeredObjectList {
        if {[catch {$obj reload $forced} errMsg]} {
            puts "sub self obj $obj failed to reload: $errMsg"
        }
    }
}
body DCSPersistentBaseTop::flushRegisteredSelfPersistentObjects { {forced 0} } {
    foreach obj $_registeredObjectList {
        if {[catch { $obj flush $forced } errMsg]} {
            puts "sub self obj $obj failed to flush: $errMsg"
        }
    }
}
body DCSPersistentBaseTop::getAllSubFileRPath { } {
    puts "calling getAllSubFile for $this: queue=$_registeredObjectList"
    set result ""
    foreach obj $_registeredObjectList {
        if {[catch {$obj getRPath} rPath]} {
            puts "sub self obj $obj failed to getRPath: $rPath"
        } else {
            lappend result $rPath
        }
    }
    return $result
}

class DCSPersistentBase {
    #### variable list to save
    #### element: {name TYPE}
    #### TYPE: STRING       : save as is. (default)
    ####       OBJECT       : object of DCSPersistentBase.
    ####       DICT         : dict
    ####       LIST_STRING  : list of string
    ####       LIST_OBJECT  : list of objects.
    ####       LIST_DICT    : list of DICT.
    protected variable DCSPERSISTENT_MANIFEST ""
    ## set to NULL if no need to save.

    ### used in toHuddle
    protected variable _preferredClassName ""

    ### used in fromHuddle
    ### It gives user a chance to instantiate a different class from
    ### the saved object.  Normally, a base class or a derived class from the
    #### saved class.
    protected variable _mapSubClassName [dict create]

    ### to support file
    ### Tags are only used in the first time to write
    ### the object into file.  Later access should all use top_dir and 
    ### m_rPathFromTop
    protected variable _topObject ""
    protected variable _parentTags ""
    protected variable _clearNeedAfterWrite 0
    ### above should be changed in constructor of derived class if needed.
    protected variable m_myTag ""
    
    ######### generated from above and no change afterward:
    protected variable m_rPathFromTop ""
    ##### passed in right after constructor
    ### from this, we can get top_dir and combined with m_rPathFromTop, you can
    ### get the absolute path for this obj if it is self persistent.

    protected variable _needWrite         1
    protected variable _handle ""
    protected variable _path_tmSync      0

    ## used by objectFromFile
    protected common s_handle ""


    protected method needLoad { }
    protected method needWrite { } { return $_needWrite }

    ### remove this method if not need at all.
    protected method _loadFromFile { path_ {silent_ 0} }
    ## path already set by _load or initialization.
    protected method _writeToFile { path }

    protected method _setTopAndTags { top tagList } {
        set _topObject $top
        set _parentTags $tagList
    }
    protected method setupTopAndTagsForChild { child }

    protected method _generateRPath { } {
        ### we use flat directory with XXX_YYYY_ZZZZ file patterns.
        set m_rPathFromTop ""
        foreach pTag $_parentTags {
            append m_rPathFromTop "_${pTag}"
        }
        append m_rPathFromTop "_${m_myTag}"

        if {$m_rPathFromTop != ""} {
            set m_rPathFromTop [string range $m_rPathFromTop 1 end]
        } else {
            puts "all tags empty for $this"
            set m_rPathFromTop [namespace tail $this]
        }
    }

    protected method autoFillSaveList { }

    public method toHuddle { }
    public method fromHuddle { h }
    public method removePersistent { }
    #### for really want to permenantly remove the object.
    ### it may have more than files used by Persystent to remove.
    ### For example, snapsho images.

    ## hook for derived class to do something
    protected method afterInitializeFromHuddle { } { }

    public proc objectFromHuddle { parent_ h }
    public proc objectFromFile { parent_ path_ mapClassName_ {silent_ 0} }

    constructor { } {
        set m_myTag [namespace tail $this]
    }
}
body DCSPersistentBase::autoFillSaveList { } {
    set DCSPERSISTENT_MANIFEST ""

    set vList [$this info variable]
    foreach {v} $vList {
        set info [$this info variable $v]
        foreach {pLevel type name init cur} $info break
        if {$type != "variable"} {
            continue
        }
        set nn [namespace tail $name]
        if {$nn == "this"} {
            continue
        }
        if {$nn == "DCSPERSISTENT_MANIFEST"} {
            lappend DCSPERSISTENT_MANIFEST [list $nn LIST_STRING]
            continue
        }
        set tag0 [string index $nn 0]
        set tag1 [string index $nn 1]
        set tag2 [string index $nn 2]
        switch -exact -- $tag0 {
            _ {
                ### ignore
                continue
            }
            o {
                set vt OBJECT
            }
            d {
                set vt DICT
            }
            l {
                switch -exact -- $tag1 {
                    o {
                        set vt LIST_OBJECT
                    }
                    d {
                        set vt LIST_DICT
                    }
                    default {
                        set vt LIST_STRING
                    }
                }
            }
            m -
            default {
                set vt STRING
            }
        }
        lappend DCSPERSISTENT_MANIFEST [list $nn $vt]
    }

    if {$DCSPERSISTENT_MANIFEST == ""} {
        #### flag no need to save
        set DCSPERSISTENT_MANIFEST NULL
    }
}
body DCSPersistentBase::toHuddle { } {
    if {$DCSPERSISTENT_MANIFEST == ""} {
        autoFillSaveList
    }
    if {$DCSPERSISTENT_MANIFEST == "NULL"} {
        return ""
    }

    if {$_preferredClassName == ""} {
        set _preferredClassName [$this info class]
    }
    set result [huddle create DCSCLASSNAME $_preferredClassName]
    foreach v $DCSPERSISTENT_MANIFEST {
        foreach {name type} $v {
            set vContents [$this info variable $name -value]

            switch -exact -- $type {
                DICT {
                    huddle set result $name [eval huddle create $vContents]
                }
                OBJECT {
                    set objName $vContents
                    if {[catch {
                        if {[$objName isa DCSPersistentBase]} {
                            set objHH   [$objName toHuddle]
                            huddle set result $name $objHH
                        }
                    } errMsg]} {
                        puts "failed to save $name as OBJECT: $errMsg"
                        continue
                    }
                }
                LIST_DICT {
                    set dList $vContents
                    set hhList [huddle list]
                    foreach d $dList {
                        if {[catch {
                            set dHH [eval huddle create $d]
                        } errMsg]} {
                            set dHH ""
                        }
                        huddle append hhList $dHH
                    }
                    huddle set result $name $hhList
                }
                LIST_OBJECT {
                    #### we save "" if not supported to preserve list position.
                    set objList $vContents
                    puts "LIST_OBJECT got {$objList} for $name"
                    set hList [huddle list]
                    foreach obj $objList {
                        if {[catch {
                            if {[$obj isa DCSPersistentBase]} {
                                puts "obj=$obj is [$obj info class]"
                                puts "calling $obj toHuddle"
                                set objHH [$obj toHuddle]
                                puts "got hh=$objHH"
                            } else {
                                set objHH ""
                            }
                        } errMsg]} {
                            puts "got error in isa PER: $errMsg"
                            set objHH ""
                        }
                        huddle append hList $objHH
                    }
                    huddle set result $name $hList
                }
                LIST_STRING {
                    set ddList [eval huddle list $vContents]
                    huddle set result $name $ddList
                }
                STRING -
                default {
                    huddle set result $name $vContents
                }
            }
        }
    }
    #puts "========HUDDLE==================="
    #puts $result
    #puts "===========endof HUDDLE==================="
    return $result
}
body DCSPersistentBase::fromHuddle { h } {
    set manifest [huddle gets $h DCSPERSISTENT_MANIFEST]

    if {$manifest == "" || $manifest == "NULL"} {
        afterInitializeFromHuddle
        return
    }

    set vList [$this info variable]
    set vNameList ""
    foreach v $vList {
        set name [namespace tail $v]
        lappend vNameList $name
    }

    foreach vv $manifest {
        foreach {name type} $vv break

        if {[lsearch -exact $vNameList $name] < 0} {
            puts "DEBUG: for $this vlist={$vNameList}"
            puts "DEBUG: $name not in the class variable list, skip"
            continue
        }

        set vh [huddle get $h $name]
        set vv [huddle strip $vh]
        if {$vv== "<undefined>"} {
            puts "$name undefined, skip"
            continue
        }
        switch -exact -- $type {
            LIST_DICT {
                ### mostlikely, this can be merged into default
                #set value [huddle strip $vh]

                if {[huddle type $vh] != "list"} {
                    puts "LIST_DICT not with list type for $name"
                    continue
                }
                set ll [huddle llength $vh]
                set value ""
                for {set i 0} {$i < $ll} {incr i} {
                    set hh [huddle gets $vh $i]
                    if {$hh == "" || $hh == "NULL"} {
                        set ee ""
                    } else {
                        set ee [eval dict create $hh]
                    }
                    lappend value $ee
                }
            }
            LIST_OBJECT {
                ### clear old list
                set oldList [$this info variable $name -value]
                foreach oldObj $oldList {
                    if {$oldObj != ""} {
                        delete object $oldObj
                    }
                }

                if {$vv != "" && [huddle type $vh] != "list"} {
                    puts "LIST_OBJECT not with list type"
                    continue
                }
                set ll [huddle llength $vh]
                set value ""
                for {set i 0} {$i < $ll} {incr i} {
                    set hh [huddle get $vh $i]
                    if {$hh == "" || $hh == "NULL"} {
                        set ee ""
                    } else {
                        if {[catch {huddle gets $hh DCSCLASSNAME} className]} {
                            puts "NO DCSCLASSNAME defined for $name in $this"
                            puts "h=$hh"
                            continue
                        }
                        if {[dict exists $_mapSubClassName $className]} {
                            set className [dict get $_mapSubClassName $className]
                        }
                        set ee [$className ::\#auto]
                        setupTopAndTagsForChild $ee
                        $ee fromHuddle $hh
                    }
                    lappend value $ee
                }
            }
            DICT {
                ### mostlikely, this can be mergede into default
                #set value [huddle strip $vh]
                set value [eval dict create [huddle strip $vh]]
            }
            OBJECT {
                set oldObj [$this info variable $name -value]
                if {$oldObj != ""} {
                    delete object $oldObj
                }

                set className [huddle gets $vh DCSCLASSNAME]
                if {[dict exists $_mapSubClassName $className]} {
                    set className [dict get $_mapSubClassName $className]
                }
                set value [$className ::\#auto]
                setupTopAndTagsForChild $value
                $value fromHuddle $vh
            }
            STRING -
            LIST_STRING -
            default {
                set value [huddle strip $vh]
            }
        }
        ## set $name $value
        if {[catch {
            set "@itcl $this $name" $value
        } errMsg]} {
            puts "failed to set class variable $name: $errMsg"
        }
    }
    afterInitializeFromHuddle
}
body DCSPersistentBase::removePersistent { } {
    if {$DCSPERSISTENT_MANIFEST == ""} {
        autoFillSaveList
    }
    if {$DCSPERSISTENT_MANIFEST == "NULL"} {
        return
    }

    foreach v $DCSPERSISTENT_MANIFEST {
        foreach {name type} $v {
            set vContents [$this info variable $name -value]

            switch -exact -- $type {
                OBJECT {
                    set objName $vContents
                    if {[catch {
                        if {[$objName isa DCSPersistentBase]} {
                            $objName removePersistent
                        }
                    } errMsg]} {
                        puts "failed removePersistent for child of $this: $objName: $errMsg"
                        continue
                    }
                }
                LIST_OBJECT {
                    #### we save "" if not supported to preserve list position.
                    set objList $vContents
                    puts "removePersistent LIST_OBJECT got {$objList} for $name"
                    set hList [huddle list]
                    foreach obj $objList {
                        if {[catch {
                            if {[$obj isa DCSPersistentBase]} {
                                $obj removePersistent
                            }
                        } errMsg]} {
                            puts "failed removePersistent for child of $this: $obj: $errMsg"
                        }
                    }
                }
                default {
                }
            }
        }
    }
}
body DCSPersistentBase::objectFromHuddle { parent_ h } {
    if {$h == "" || $h == "NULL"} {
        return ""
    }
    if {[catch {huddle gets $h DCSCLASSNAME} className]} {
        puts "NO DCSCLASSNAME defined in h to create obj"
        return ""
    }
    puts "calling objFromHuddle: class=$className"
    if {$className == ""} {
        return ""
    }
    if {[info commands $className] == ""} {
        puts "class $className not defined"
        return ""
    }
    set value [$className ::\#auto]
    if {$parent_ != ""} {
        $parent_ setupTopAndTagsForChild $value
    } else {
        $value _setTopAndTags $value ""
    }
    $value fromHuddle $h

    return $value
}
body DCSPersistentBase::objectFromFile { parent_ path_ mapClassName_ {silent_ 0} } {
    if {$path_ == "" || $path_ == "NULL"} {
        return ""
    }

    if {$s_handle != ""} {
        close $s_handle
        set s_handle ""
    }

    if {[catch {open $path_} s_handle]} {
        set errMsg $s_handle
        set s_handle ""
        if {!$silent} {
            log_error failed to open $path_: $errMsg
        }
        return -code error $errMsg
    }
    set tmSync [clock seconds]
    set yyy [read -nonewline $s_handle]
    close $s_handle
    set s_handle ""

    ### only str to prevent yaml convert "N" to "0".
    set hh [::yaml::yaml2huddle -types str $yyy ]

    if {[catch {huddle gets $hh DCSCLASSNAME} className]} {
        puts "NO DCSCLASSNAME defined for $this self class: $className"
        return ""
    }
    if {[dict exists $mapClassName_ $className]} {
        set className [dict get $mapClassName_ $className]
    }
    set obj [$className ::\#auto]
    if {$parent_ != ""} {
        $parent_ setupTopAndTagsForChild $obj
    } else {
        $obj _setTopAndTags $obj ""
    }

    $obj fromHuddle $hh

    return $obj
}
body DCSPersistentBase::setupTopAndTagsForChild { obj } {
    puts "$this setupTopAndTagsForChild for $obj"
    set tags $_parentTags
    lappend tags $m_myTag
    $obj _setTopAndTags $_topObject $tags
}
body DCSPersistentBase::needLoad { } {
    set top_dir [$_topObject getTopDirectory]
    set path [file join $top_dir ${m_rPathFromTop}.yaml]
    if {$path ==".yaml"} {
        puts "$this needLoad path=={}"
        return 1
    }
    if {[catch {file mtime $path} mTime]} {
        puts "$this needLoad mtime failed"
        return 1
    }
    if {$mTime >= $_path_tmSync} {
        puts "$this needLoad new"
        return 1
    }
    return 0
}
body DCSPersistentBase::_loadFromFile { path_ {silent_ 0} } {
    puts "loadFromFile $path_ for $this"
    if {$_handle != ""} {
        close $_handle
        set _handle ""
    }
    if {[catch {open $path_} _handle]} {
        set errMsg $_handle
        set _handle ""
        if {!$silent_} {
            log_error failed to open $path_: $errMsg
        }
        return -code error $errMsg
    }
    set _path_tmSync [clock seconds]
    set yyy [read -nonewline $_handle]
    close $_handle
    set _handle ""

    ### only str to prevent yaml convert "N" to "0".
    set hhh [::yaml::yaml2huddle -types str $yyy ]

    DCSPersistentBase::fromHuddle $hhh

    ## we just loaded, no need to write
    if {$_clearNeedAfterWrite} {
        puts "clear _needWrite for $this by load"
        set _needWrite 0
    }
    puts "$this loaded from file $path_"
}
body DCSPersistentBase::_writeToFile { path_ } {
    puts "_writeToFile for $this"
    if {$_handle != ""} {
        close $_handle
        set _handle ""
    }
    if {$path_ == ""} {
        log_error canont write to File, path not set yet.
        return -code error NO_PATH
    }
    set hh [DCSPersistentBase::toHuddle]
    set yy [::yaml::huddle2yaml $hh 4 80]

    if {![catch {open $path_ w} _handle]} {
        puts $_handle $yy
        close $_handle
        set _handle ""
    } else {
        set errMsg $_handle
        set _handle ""
        log_error failed to write to $path_: $errMsg
        return -code error $errMsg
    }
    set _path_tmSync [clock seconds]

    if {$_clearNeedAfterWrite} {
        puts "clear _needWrite for $this by _writeToFile"
        set _needWrite 0
    }
    puts "$this saved to $path_"
}

class DCSSelfPersistent {
    inherit DCSPersistentBase

    protected common TAG_SELF_RPATH "SELF_PERSISTENT_RPATH"

    #### these will be saved with parent and self.
    #### access to these does not need to load the self file.
    #### for now, we only support STRING: direct set.
    #### If you need to include other types, you need to rewrite the code
    #### changing element to  "name TYPE" and copy the code from toHuddle.
    protected variable _alwaysAvailableVariableList ""
    protected variable _allLoaded 0

    ##override base class:
    public method toHuddle { }
    public method fromHuddle { h }
    public method removePersistent { }
    protected method _setTopAndTags { top tagList } {
        DCSPersistentBase::_setTopAndTags $top $tagList
        if {$_topObject != "" && $_topObject != $this} {
            $_topObject registerSelfPersistentObject $this
        }
    }

    ####self:
    public method reload { {forced 0} }
    public method flush { {forced 0} }
    public method getRPath { } { return ${m_rPathFromTop}.yaml }

    destructor {
        if {$_topObject != "" && $_topObject != $this} {
            $_topObject unregisterSelfPersistentObject $this
        }
    }
}
body DCSSelfPersistent::toHuddle { } {
    puts "self toHuddle for $this"
    ### this part is the same as base class
    if {$_preferredClassName == ""} {
        set _preferredClassName [$this info class]
    }
    set toResult [huddle create DCSCLASSNAME $_preferredClassName]

    foreach name $_alwaysAvailableVariableList {
        if {[catch {
            set vContents [$this info variable $name -value]
            huddle set toResult $name $vContents
        } errMsg]} {
            puts "failed to save header $name for $this"
        }
    }

    ####################################
    set relativePath ${m_rPathFromTop}.yaml
    huddle set toResult $TAG_SELF_RPATH $relativePath
    ##### end of generating toHuddle
    if {!$_needWrite} {
        puts "$this no _needWrite, skip"
        return $toResult
    }
    if {!$_allLoaded} {
        puts "$this not loaded, skip write"
        return $toResult
    }
    #### now write out own file.
    set top_dir [$_topObject getTopDirectory]
    set path [file join $top_dir $relativePath]
    _writeToFile $path
    puts "$this self saved to $path"
    return $toResult
}
body DCSSelfPersistent::fromHuddle { h } {
    puts "calling fromHuddle for $this class: [$this info class]"
    foreach name $_alwaysAvailableVariableList {
        set vh [huddle get $h $name]
        set vv [huddle strip $vh]
        if {$vv== "<undefined>"} {
            puts "$name undefined, skip"
            continue
        }
        ## set $name $value
        if {[catch {
            set "@itcl $this $name" $vv
        } errMsg]} {
            puts "failed to set $this class variable $name: $errMsg"
        }
    }

    if {[catch {huddle gets $h $TAG_SELF_RPATH} relativePath]} {
        puts "$this no $TAG_SELF_RPATH defined in hh"
        puts "hh={$h}"
        return -code error LACKING_RPATH
    }
    set m_rPathFromTop [file rootname $relativePath]
    if {$relativePath == ""} {
        puts "$this $TAG_SELF_RPATH =={}"
        return -code error LACKING_RPATH
    }
    if {![$_topObject getLoadAll]} {
        puts "not loadAll, so skip loading from file for $this"
        set _allLoaded 0
        return
    }

    set top_dir [$_topObject getTopDirectory]
    set path [file join $top_dir $relativePath]
    puts "in fromHuddle loading from $path for $this"
    _loadFromFile $path
    set _allLoaded 1
    puts "self $this loaded from file $path"
}
body DCSSelfPersistent::removePersistent { } {
    puts "removePersistent for self $this"
    set top_dir [$_topObject getTopDirectory]
    set path [file join $top_dir ${m_rPathFromTop}.yaml]
    if {[catch {file delete -force $path} errMsg]} {
        puts "failed to removePersistent for $this: $errMsg"
    }

    DCSPersistentBase::removePersistent
}
body DCSSelfPersistent::reload { {forced_ 0} } {
    ### reload: must be loaded to call this.
    puts "calling reload for $this class: [$this info class]"
    puts "forced=$forced_ _allLoaded=$_allLoaded need=[needLoad]"
    if {$forced_ || ($_allLoaded && [needLoad])} {
        set top_dir [$_topObject getTopDirectory]
        set path [file join $top_dir ${m_rPathFromTop}.yaml]
        _loadFromFile $path
        set _allLoaded 1
        puts "self $this reloaded from file $path"
    }
}
body DCSSelfPersistent::flush { {forced_ 0} } {
    puts "calling flush for $this class: [$this info class]"
    puts "forced=$forced_ _allLoaded=$_allLoaded need=$_needWrite"
    if {$_allLoaded && ($forced_ || $_needWrite)} {
        set top_dir [$_topObject getTopDirectory]
        set path [file join $top_dir ${m_rPathFromTop}.yaml]
        _writeToFile $path
        puts "self $this flush to file $path"
    }
}

class DCSPersistentCCC1 {
    inherit DCSSelfPersistent

    public variable m_ccc1V1 "my var1"
    private variable m_ccc1V2 "my var2"

    constructor { } {
        set _allLoaded 1
        puts "constructor $this"
    }

    destructor {
        puts "destructor $this"
    }
}

class DCSPersistentTest {
    inherit DCSPersistentBase DCSPersistentBaseTop

    public method getTopDirectory { } { return "." }

    public variable m_pv1 "public variable 1"
    #protected variable m_pv2 "protected variable 2"
    public variable m_pv2 "protected variable 2"
    private variable m_pv3 "private variable 3"
    private common s_ssss "common "
    protected variable o_ptrObj ""

    protected variable d_ptrDict ""

    constructor { } {
        set _topObject $this

        set o_ptrObj [DCSPersistentCCC1 ::\#auto]
        setupTopAndTagsForChild $o_ptrObj
        $o_ptrObj _generateRPath

        set d_ptrDict [dict create k1 v1 k2 v2]
    }

}
proc DCSPersistentBaseTest { } {
    DCSPersistentTest aaa
    aaa configure -m_pv1 "changed from outside"

    puts "calling toHuddle"
    set dddd [aaa toHuddle]
    set yyyy [::yaml::huddle2yaml $dddd 4 80]
    puts "===================yyyyyyyyy========"
    puts $yyyy
    puts "===================end yyyyyyyyy========"

    set hhhout [::yaml::yaml2huddle $yyyy]
    puts "callin fromHuddle :{$hhhout}"
    set value [DCSPersistentBase::objectFromHuddle "" $hhhout]
    $value removePersistent
}
#DCSPersistentBaseTest
