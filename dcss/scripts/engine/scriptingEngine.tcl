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

puts "******** scriptingEngine starts *********"

rename puts native_puts
rename vwait native_vwait
global gVWaitStack
global gUseOneTimeTicket
set gVWaitStack ""
## so we can use it in dcss
set gUseOneTimeTicket 1

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

proc vwait { var_name } {
    global gVWaitStack

    set scriptInfo [get_script_info]

    if {$scriptInfo == "error"} {
        set who_is_waiting system
    } elseif {[llength $scriptInfo] == 4} {
        set who_is_waiting [lindex $scriptInfo 1]
    } else {
        set who_is_waiting unknown 
    }


    set what_waiting_for $var_name
    ####append operation name if it is waiting for operation
    if {[string equal -length 11 $var_name gOperation(]} {
        ###try to extract operation handle
        set end_index [string first , $var_name 11]
        if {$end_index > 11} {
            incr end_index -1
            set handle [string range $var_name 11 $end_index]
            global gOperation
            if {[info exists gOperation($handle,name)]} {
                #append what_waiting_for "([set gOperation($handle,name)])"
                set what_waiting_for "[set gOperation($handle,name)]($handle)"
            } else {
                puts "cannot find name for operation $handle"
            }
        }
    } elseif {[string equal -length 8 $var_name gDevice(]} {
        ###try to extract device name
        set end_index [string first , $var_name]
        if {$end_index > 8} {
            incr end_index -1
            set what_waiting_for [string range $var_name 8 $end_index]
        }
    } elseif {[string equal $var_name gWait(status)]} {
        set what_waiting_for time
    } elseif {[string equal $var_name sleepFlag]} {
        set what_waiting_for sleep
    } elseif {[string first wait_reply $var_name] >= 0} {
        set what_waiting_for serial_port
    } elseif {[string equal -length 6 $var_name ::smtp]} {
        set what_waiting_for send_notice
    } elseif {[string equal -length 6 $var_name ::http]} {
        set what_waiting_for web_service
    }
    set item [format "%-20s <- %s" $what_waiting_for $who_is_waiting]
    lappend gVWaitStack $item

    ######################DEBUG##############
    puts "#############vwait stack: bottom to top##############"
    foreach wwww $gVWaitStack {
        puts $wwww
    }
    puts "#####################################################"
    
    native_vwait $var_name
    set top_of_stack [lindex $gVWaitStack end]
    if {$top_of_stack == $item} {
        set gVWaitStack [lreplace $gVWaitStack end end]
    } else {
        set index [lsearch -exact $gVWaitStack $item]
        if {$index >= 0} {
            puts "vwait stack confused for $item: $gVWaitStack"
            set gVWaitStack [lreplace $gVWaitStack $index $index]
        } else {
            puts "clear vwait stack wrong: $gVWaitStack"
            set gVWaitStack ""
        }
    }
}

puts "******** scriptingEngine puts re-directed to log file *********"

proc bgerror { args } {

	global errorInfo
	
	catch [puts "********* Background error in Tcl script *********"]
	catch [puts "$errorInfo"]
	catch [puts "**************************************************"]
	return 0
	}
	
	

set serverName localhost

set DCS_DIR "../.."
set DCSWIDGETS "$DCS_DIR/DcsWidgets"
set DCS_TCL_PACKAGES_DIR "$DCS_DIR/dcs_tcl_packages/"
set DCSS_DIR "$DCS_DIR/dcss/scripts"
set ENGINE_DIR "$DCSS_DIR/engine/"
set DEVICE_DIR "$DCSS_DIR/devices/"
set OPERATION_DIR "$DCSS_DIR/operations/"
set STRING_DIR "$DCSS_DIR/strings/"

package require Itcl
namespace import itcl::*
package require DCSUtil
global env
package require DCSUtil
set MACHINE [getMachineType]

puts "Loading dcs_c_library from $DCS_DIR/tcl_clibs/$MACHINE/tcl_clibs.so"
load $DCS_DIR/tcl_clibs/$MACHINE/tcl_clibs.so dcs_c_library

source $ENGINE_DIR/util.tcl
source $ENGINE_DIR/set.tcl
source $ENGINE_DIR/motor_control.tcl
source $ENGINE_DIR/configure_motor.tcl
source $ENGINE_DIR/hardware_commands.tcl
source $ENGINE_DIR/message_handlers.tcl

#the following should be changes to a package require
source $DCS_TCL_PACKAGES_DIR/DcsNetworkProtocol.tcl
####source $DCS_TCL_PACKAGES_DIR/DcsRunSequencer.tcl

package require DCSConfig
package require tls
package require http
package require DCSSpreadsheet
package require DCSDetectorBase
http::register https 443 [list ::tls::socket -cafile ./server.pem]

###load config file
DCS::Config config
config setConfigDir [file join $DCS_DIR dcsconfig data]
config setConfigRootName $gBeamlineId
config load

global gMotorBeamWidth
global gMotorBeamHeight
global gMotorEnergy
global gMotorDistance
global gMotorVert
global gMotorHorz
global gMotorBeamStop
global gMotorBeamStopHorz
global gMotorBeamStopVert
global gMotorPhi
global gMotorOmega
global gCounterFormat

set gMotorBeamWidth  [::config getMotorRunBeamWidth]
set gMotorBeamHeight [::config getMotorRunBeamHeight]
set gMotorEnergy     [::config getMotorRunEnergy]
set gMotorDistance   [::config getMotorRunDistance]
set gMotorVert       [::config getMotorRunVert]
set gMotorHorz       [::config getMotorRunHorz]
set gMotorBeamStop   [::config getMotorRunBeamStop]
set gMotorBeamStopHorz   [::config getMotorRunBeamStopHorz]
set gMotorBeamStopVert   [::config getMotorRunBeamStopVert]
set gMotorPhi        [::config getMotorRunPhi]
set gMotorOmega      [::config getMotorRunOmega]
set gCounterFormat   [::config getFrameCounterFormat]

#this need config
source $ENGINE_DIR/timerService.tcl
source $ENGINE_DIR/detectorService.tcl


if [catch "unlockAllSil $gUserName $gSessionID 1" errMsg] {
    puts "unlockAllSil failed: $errMsg"
}

global scriptPort;
global hardwarePort;

puts "self ports: $scriptPort"
puts "client port: $hardwarePort"

DcsClient dcss $serverName $scriptPort -callback "handle_stog_messages" -_reconnectTime 100
dcss connect

DcssHardwareClient dcss2 $serverName $hardwarePort -hardwareName "self" -_reconnectTime 3000 -callback "handle_stoh_messages"
after 3000 dcss2 connect
