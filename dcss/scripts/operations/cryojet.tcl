# a string "anneal_config" is used to store configuratioin for the anneal operation.
# you can find out the contents of the string by reading 
# the procedure get_anneal_config

proc get_anneal_config { name } {
    variable ::nScripts::anneal_config
    switch -exact -- $name {
        on_flow {
            #in anneal, it will set to this value after anneal.
            return [lindex $anneal_config 0]
        }
        off_flow {
            #the flow value used during shutdown time in anneal.
            #normally, it should be 0
            return [lindex $anneal_config 1]
        }
        prepare_time {
            #added to the time of user input to cut flow
            return [lindex $anneal_config 2]
        }
        max_anneal_time {
            #maximum anneal time
            return [lindex $anneal_config 3]
        }
        default {
            return -code error "bad name $name for anneal_config"
        }
    }
}

proc cryojet_anneal_initialize {} {
}

proc cryojet_anneal_start { time } {
    variable sample_flow
    if { $time == "" } {
        return -code error "Argument 'time' needed for operation cryojet_anneal"
    }
    #will check max afte get constants from config

    #get configuration from anneal_config string
    set on_flow [get_anneal_config  on_flow]
    if {$on_flow == "" || $on_flow < 2} {
        log_warning No valid on flow defined in anneal_config string
        set on_flow 2.0
    }
    set off_flow [get_anneal_config off_flow]
    if {$off_flow == "" || $off_flow > 5} {
        log_warning No valid off flow defined in anneal_config string
        set off_flow 0
    }
    set prepare_time [get_anneal_config prepare_time]
    if {$prepare_time == "" || $prepare_time < 0} {
        log_warning No valid prepare_time defined in string anneal_config
        set prepare_time 0
    }
    set max_anneal_time [get_anneal_config max_anneal_time]
    if {$max_anneal_time == "" || $max_anneal_time < 0} {
        log_warning No valid max_anneal_time defined in string anneal_config
        set max_anneal_time 10
    }
    if {$max_anneal_time > 0 && $time > $max_anneal_time} {
        log_error Anneal time exceed maximum of $max_anneal_time seconds
        return -code error "Anneal time exceed the maximum of $max_anneal_time seconds"
    }
    #get old_flow
    set old_flow $sample_flow
    log_note "Old Sample Flow: $old_flow"

    if {abs($old_flow - $on_flow) > 0.5} {
        log_warning flow will set to $on_flow after annealing.

        set old_flow $on_flow
    }
    log note "About to shut off cryojet"
    
    if {[catch {
        #shut off sample flow
        move sample_flow to $off_flow 
        wait_for_motors sample_flow 3000

        log_note "Allowing sample to warm up"
        set ms [expr int($prepare_time * 1000.0)]
        wait_for_time $ms
        log_note "Annealing sample"
        set ms [expr int($time * 1000.0)]
        wait_for_time $ms
    } e]} {
        if {[string first abort $e] >=0} {
            log_warning "User aborted"
        }
        #if user abort, we cannot use move motor to restore flow
        #so we call an equivalent operation instead
        log_severe Anneal interrupted, please check cryojet sample_flow
        set restoreFlow [start_waitable_recovery_operation cryo_set_sample_flow $old_flow]
        set result [wait_for_operation $restoreFlow]
        log_note $result
        return -code error "cryojet_anneal $e"
    } else {
        move sample_flow to $old_flow
        wait_for_motors sample_flow
    }
    log_note "Cryostream flow restored"
    return "cryojet_anneal completed successfully"
}

