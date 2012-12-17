### this operation is not in the lock list
### to calling this will not flash the BluIce.
proc scan3DUserSetup_initialize { } {
}
proc scan3DUserSetup_start { cmd args } {
    switch -exact -- $cmd {
        user_setup_default {
            default_rastering_user_setup
        }
        user_setup_update {
            update_rastering_user_setup
        }
        user_setup_set {
            eval set_rastering_user_setup $args
        }
    }
}
