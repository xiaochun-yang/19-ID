### for each motor, a set of dcs strings will be used.
### please map the strings to related EPICS PVs.
### it is OK to map 1 PV to more than 1 dcs strings.
### No motor config allowed through BluIce.
### It should be done via EPICS.
### for a motor named "MOTOR",
### following strings should be mapped to epics pvs
###
### this is the PV to set point
### this should trigger go if there is no PV for "move" command
### ${MOTOR}Sp
###
### this is the PV to command "go"
### ${MOTOR}Cmd    (optional)
###
### this is the command to abort
### ${MOTOR}Stop   (optional)
###
### this is the PV to see if the motor is ready or not
### if it is a PV of ready, remember to change the values
### ${MOTOR}Busy
###
### these 2 are the soft limits
### ${MOTOR}DrvH
### ${MOTOR}DrvL
###
### this is the PV to monitor position
### ${MOTOR}Monit
###
### This is the PV to indicate error happened, move failed
### ${MOTOR}Error
###
### This is the PV for detailed error messages
### Remember to set it read as string in config file
### epicsgw.${MOTOR}Msg.stringTypeRead=1
### ${MOTOR}Msg    (optional)
###
proc VIRTUAL_initialize {} {
	set_children
	set_siblings

	set_triggers VIRTUALBusy VIRTUALDrvH VIRTUALDrvL VIRTUALMonit VIRTUALError

    registerAbortCallback VIRTUAL_abort
}

proc VIRTUAL_move { pos } {
    variable VIRTUALBusy
    variable VIRTUALError
    variable VIRTUALMsg
    variable VIRTUALSp
    variable VIRTUALCmd

    #####check preconditions
    if {$VIRTUALBusy} {
        return -code error "busy"
    }

    ####OK start to move
    set VIRTUALSp $pos
    if {[isString VIRTUALCmd]} {
        set VIRTUALCmd 1
    }

    catch { wait_for_string_contents VIRTUALBusy 1 0 1000 }
    #wait_for_time 1000

    ##now it is started process the request
    #wait it done or fail
    wait_for_string_contents VIRTUALBusy 0

    if {[isString VIRTUALError] && $VIRTUALError} {
        log_error VIRTUAL moving error happened
        if {[isString VIRTUALMsg] && $VIRTUALMsg != ""} {
            regsub -all {[[:space:]]} $VIRTUALMsg _ oneWord
        } else {
            set oneWord "ERROR"
        }
        return -code error $oneWord
    }
}

##this is the proc called in config
#we will use this to inform user that config is not supported
proc VIRTUAL_set { new_pos } {
    log_error Cannot config VIRTUAL.  Please do it through EPICS

    VIRTUALUpdateConfig

    return -code error "config_not-supported"
}

proc VIRTUAL_update {} {
    variable VIRTUALMonit
    return $VIRTUALMonit
}
###this is update and cnofig messages
proc VIRTUAL_trigger { triggerDevice } {
    global gDevice
    variable VIRTUALMonit
    variable VIRTUALBusy

    if {$triggerDevice == "VIRTUALDrvH" || \
    $triggerDevice == "VIRTUALDrvL"} {
        VIRTUALUpdateConfig
        return
    }

    if {$VIRTUALBusy} {
        dcss2 sendMessage "htos_update_motor_position VIRTUAL $VIRTUALMonit normal"
    } elseif {$gDevice(VIRTUAL,status) == "inactive"} {
        ###not started by us
        ###should be started by epics
        VIRTUALUpdateConfig
    }
}

proc VIRTUALUpdateConfig { } {
    variable VIRTUALMonit
    variable VIRTUALDrvH
    variable VIRTUALDrvL

    if {$VIRTUALDrvH != 0 || $VIRTUALDrvL != 0} {
        dcss2 sendMessage "htos_configure_device VIRTUAL $VIRTUALMonit $VIRTUALDrvH $VIRTUALDrvL 1 1 0"
    } else {
        dcss2 sendMessage "htos_configure_device VIRTUAL $VIRTUALMonit $VIRTUALDrvH $VIRTUALDrvL 0 0 0"
    }
}
proc VIRTUAL_abort { } {
    variable VIRTUALStop
    if {[isString VIRTUALStop]} {
        set VIRTUALStop 1
    }
}
