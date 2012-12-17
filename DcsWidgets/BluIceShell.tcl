
package provide BluIceShell 1.0

package require Itcl
namespace import ::itcl::*
package require DCSProtocol
package require DCSDevice
package require DCSConfig
package require tls
package require DCSUtil
package require DCSDetector
package require DCSScriptCommand

    

proc loadBeamlineConfig { beamline } {
    global env
    global TCL_CLIBS_DIR
    global DCS_DIR
    global gEncryptSID

    set MACHINE [getMachineType]
    foreach directory $env(TCLLIBPATH) {
        #looking for the blu-ice directory
        if { [file tail $directory] == "DcsWidgets" } {
            #go up one directory level to get the DCS root directory
            set DCS_DIR [file dirname $directory]
            set TCL_CLIBS_DIR [file join $DCS_DIR tcl_clibs $MACHINE]
            set foundBLCDirectory 1
        }
    }

    CLibraryAvailable

    ::DCS::Config config 
    config setConfigDir ${DCS_DIR}/dcsconfig/data
    config setConfigRootName $beamline
    config load
    if {[catch {
        puts "loading certificate ${DCS_DIR}/dcsconfig/data/$beamline.crt"
        DcsSslUtil loadCertificate ${DCS_DIR}/dcsconfig/data/$beamline.crt
        set gEncryptSID 1
    } errMsg]} {
        set gEncryptSID 0
        puts "failed to load dcss certificate, running in unsecured mode"
        puts $errMsg
        log_error failed to load dcss certificate, running in unsecured mode
        log_error $errMsg
    }
}

proc connectToBeamlineFirstTimeSafe { beamline nickName } {
    global __loadedBeamline;  

    set ::gBluIceStyle shell
    set ::gNickName $nickName

    #guard against multiple attempts to connect;
    if { [info exists ::dcss ] } return;
    

    loadBeamlineConfig $beamline

    puts [DCS::DcssUserProtocol ::dcss [::config getDcssHost] [::config getDcssGuiPort] -useSSL 1 -authProtocol 2 -_reconnectTime 1000 -callback "" -networkErrorCallback ""]
    ::dcss waitForLoginComplete
    namespace eval ::nScripts init_device_variables
}


#overwrite the puts statement so that the event handler won't output asynchronous messages unexpectedly.
rename puts native_puts
set ::__stdoutGatekeeper on

proc log_puts {args} {
    if {$::__stdoutGatekeeper == "on"} return
    native_puts $args
}

proc puts { args } {
    set argc [llength $args]
    if {$argc >= 3} {
        #channel_id present, must be writing to a file or socket
        eval native_puts $args
        return
    }
    if {$argc == 2 && [lindex $args 0] != "-nonewline"} {
        eval native_puts $args
        return
    }

    ##### re-direct to log #######

    set msg [lindex $args 0]
    if {$msg == "-nonewline"} {
        set msg [lindex $args 1]
    }

    #####change % to %% for C log
    set msg [string map {% %% \n { } \0 {}} $msg]

    log_puts $msg TCL_LOG
}

#the shell may not have a logger
namespace eval ::DCS::UserLogView {
    proc handleNewEntry {args} {
        puts $args
    }
}

class BluIceShell {

    private variable _buildingMsg ""


    public method handleStdin {} {
        if {[eof stdin]} {exit}

        while { [set a [read stdin 1]] != ""}  {
            scan $a %c ascii
            if { $ascii == "24" } {
                break
            }
            append _buildingMsg $a
        }

        if {$a == ""} { return }

        #puts "! $_buildingMsg !"
        if {[catch {
            set ::__stdoutGatekeeper off
            eval $_buildingMsg
            set _buildingMsg ""
        } err] } {
            set _buildingMsg ""
            global errorInfo
            puts stdout $errorInfo
        }
        set ::__stdoutGatekeeper on
    }
}

proc outputIfExists { outputVar } {
    variable nScripts::$outputVar
    if [info exists $outputVar] {
        puts stdout "${outputVar}: \"[set $outputVar]\""
    }
}

proc assertDcssConnectionIsGood {} {
    if {[::dcss cget -_connectionGood] == "1"} {
        puts stdout "Connected to dcss."                
    } else {
        puts stdout "Disconnected from dcss."
        ::dcss waitForLoginComplete                   
    }
}

proc assertClientIsActive { } {
    variable ::nScripts::activeKey
    

    if { [info exists activeKey] && $activeKey != "null" } {
        puts stdout "LOCK $activeKey"
        ::nScripts::lock_active $activeKey        
    } else {
        ::nScripts::lock_active new
        set activeKey [::dcss getActiveKey]
    }
    return $activeKey
}


#event Handler Mode
proc enterEventHandleMode {} {
    set shell [BluIceShell #auto]
    fconfigure stdin -blocking 0 -translation binary
    fileevent stdin readable [list $shell handleStdin]
    
    puts stdout "enter vwait"
    vwait forever
}

