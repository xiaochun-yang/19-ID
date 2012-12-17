package provide DCSBarcodeMap 1.0

package require Itcl
package require DCSConfig

class DCS::BarcodeMap {
    public method getUserList { barcode staff_name SID }
    public method getMultipleUserList { staff_name SID args }
    public method addUser { barcode userList staff_name SID }

    private variable m_fileName ""
    private variable m_fileHandle ""
    constructor { args } {
        set m_fileName [::config getStr "barcodeMap.file"]
        puts "$this using $m_fileName as barcode file"
    }
}
body DCS::BarcodeMap::getUserList { barcode staff_name SID } {
    if {$barcode == "" || $barcode == "unknown"} {
        ## this means no user access, only staff
        return blctl
    }
    if {$m_fileName == ""} {
        log_error config error, no barcode map file defined yet.
        ## this means no user access, only staff
        return blctl
    }
    if {$m_fileHandle != ""} {
        catch { close $m_fileHandle }
        set m_fileHandle ""
    }
    if {[catch {open $m_fileName r} m_fileHandle]} {
        log_error failed to open barcode map file:$m_fileHandle
        set m_fileHandle ""
    } else {
        set userList ""

        while {![eof $m_fileHandle]} {
            set line [gets $m_fileHandle]
            if {[string index $line 0] == "#"} {
                continue
            }

            set bc [lindex $line 0]
            if {$bc == $barcode} {
                set ul [lrange $line 1 end]
                eval lappend userList $ul
            }
        }
        close $m_fileHandle
        set m_fileHandle ""
    }
    if {$userList == ""} {
        set userList blctl
    }
    return $userList
}
body DCS::BarcodeMap::addUser { barcode userList staff_name SID } {
    if {$barcode == "" || $barcode == "unknown"} {
        return
    }
    if {$m_fileName == ""} {
        log_error cannot addUser: no mapping file defined
        return
    }

    ### check users 
    set currentOwner [getUserList $barcode $staff_name $SID]
    set newUserList ""
    foreach user $userList {
        if {[lsearch -exact $currentOwner $user] < 0} {
            lappend newUserList $user
        }
    }
    if {$newUserList == ""} {
        log_warning all required users already on the owner list
        return
    }

    if {$m_fileHandle != ""} {
        catch { close $m_fileHandle }
        set m_fileHandle ""
    }
    if {[catch {open $m_fileName a} m_fileHandle]} {
        log_error failed to open barcode map file:$m_fileHandle
        set m_fileHandle ""
    } else {
        set line $barcode
        eval lappend line $userList
        puts $m_fileHandle $line
        close $m_fileHandle
        set m_fileHandle ""
    }
}
body DCS::BarcodeMap::getMultipleUserList { staff_name SID args } {
    set ll [llength $args]
    if {$ll < 1} {
        log_error no barcode given
        return -code error empty_barcode_list
    }

    puts "getMultipleUserList for $args ll=$ll"

    for {set i 0} {$i < $ll} {incr i} {
        set userList$i ""
    }

    if {$m_fileName == ""} {
        log_error config error, no barcode map file defined yet.
        set result ""
        for {set i 0} {$i < $ll} {incr i} {
            lappend result blctl
        }
        return $result
    }
    if {$m_fileHandle != ""} {
        catch { close $m_fileHandle }
        set m_fileHandle ""
    }
    if {[catch {open $m_fileName r} m_fileHandle]} {
        log_error failed to open barcode map file:$m_fileHandle
        set m_fileHandle ""
    } else {
        set userList ""

        while {![eof $m_fileHandle]} {
            set line [gets $m_fileHandle]
            if {[string index $line 0] == "#"} {
                continue
            }

            set bc [lindex $line 0]
            set index [lsearch -exact $args $bc]
            if {$index >= 0} {
                set ul [lrange $line 1 end]
                eval lappend userList$index $ul
                puts "add $ul for $bc index=$index"
            }
        }
        close $m_fileHandle
        set m_fileHandle ""
    }
    set result ""
    for {set i 0} {$i < $ll} {incr i} {
        set bc [lindex $args $i]
        set uL [set userList$i]
        if {$uL == ""} {
            set uL blctl
        }
        lappend result $uL
    }
    return $result
}
