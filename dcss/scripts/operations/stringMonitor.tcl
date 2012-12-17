proc stringMonitor_initialize { } {
    ### flag house air pressure low
    global gHAP_low

    set gHAP_low 0

    ### it is OK to include devices not exist.
    set deviceList [list \
    analogInStatus0 \
    ]

    foreach device $deviceList {
        registerEventListener $device \
        [list ::nScripts::stringMonitor_onDeviceChange $device]
    }

}
proc stringMonitor_start { } {
}

proc stringMonitor_onDeviceChange { device } {
    global gHAP_low

    if {$device == "analogInStatus0"} {
        variable analogInStatus0
        set hap_volt [lindex $analogInStatus0 9]
        set hap_psi [unitsForIonChamber 1 $hap_volt 0.001]
        ##puts "monitor house air pressure: $hap_psi"

        if {$hap_psi < 75.0} {
            ###msg out
            if {!$gHAP_low} {
                set gHAP_low 1
                log_severe house air pressure low $hap_psi psi
            }
            return
        } else {
            set gHAP_low 0
        }
    }
}
