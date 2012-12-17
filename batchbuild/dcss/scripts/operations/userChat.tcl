proc userChat_initialize {} {
}

proc userChat_start { args } {
    variable current_user_chat
    global gBeamlineId

    ################### DIRECTORY ####################
    set dir [::config getUserChatDir]
    if {$dir == ""} {
        set dir "/data/blctl/userChat/$gBeamlineId"
    }

    file mkdir $dir
    ################# FILENAME########################
    set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    set log_root [file join $dir "userChat${timestamp}"]
    set log_name ${log_root}.uct
    set counter 0
    while {[file exists $log_name]} {
        incr counter 1
        if {$counter > 100} {
            return -code error "user log filename conflict"
        }
        set log_name ${log_root}_${counter}.uct
    }

    #################### CREATE NEW LOG FILE #############
    set handle [open $log_name w 0664]
    puts $handle "UserChat $log_name"
    close $handle
    ###no need anymore, we are not running as root anymore
    ##file attribute $log_name -owner blctl -group px
    file attribute $log_name -permissions 0664

    ##################### UPDATE STRING ###############
    set old_path [lindex $current_user_chat 0]
    set current_user_chat [lreplace $current_user_chat 0 0 $log_name]

    ##################### change protection ###########
    if {[file exists $old_path]} {
        file attributes $old_path -permissions 0660
    }

    return "new user chat file created $log_name"
}
