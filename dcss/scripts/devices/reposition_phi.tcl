######
### reposition_phi, reposition_x, reposition_y and reposition_z are 
### virtual motors based on reposition.
### Upon reposition (loopCenter+autoindex-phi-restore+jpeg matching),
### all these motors will be at 0s.
###
### this motors will be used in saving of offsets and reposition for
### extra runs with offsets.
###
###

proc repositionOriginNameToIndex { motor_name } {
    variable repositionMotorList
    variable reposition_origin

    set ll1 [llength repositionMotorList]
    set ll2 [llength reposition_origin]
    if {$ll1 != $ll2} {
        return -code error reposition_origin not match with repositionMotorList
    }

    set index [lsearch -exact $repositionMotorList $motor_name]
    puts "repositionOriginNameToIndex $motor_name index=$index"

    return $index
}
proc getRepositionOrigin { motorName } {
    variable reposition_origin

    set index [repositionOriginNameToIndex $motorName]
    set result [lindex $reposition_origin $index]
    if {![string is double -strict $result]} {
        set result 0
    }
    return $result
}
proc setRepositionOrigin { motorName origin } {
    variable reposition_origin

    if {![string is double -strict $origin]} {
        return -code error origin "{$origin}" is not double
    }
    set index [repositionOriginNameToIndex $motorName]

    if {$index >= 0} {
        set reposition_origin [lreplace $reposition_origin $index $index $origin]
    }
}

####these 3 should be more useful than the "set"
proc setRepositionCurrent { } {
    variable repositionMotorList
    variable reposition_origin

    set new_origin ""
    foreach m $repositionMotorList {
        variable $m
        set currentPosition [set $m]
        lappend new_origin $currentPosition
    }
    set reposition_origin $new_origin
}
proc setRepositionIndividualCurrent { args } {
    variable reposition_origin

    if {[llength $args] <= 0} return

    set new_origin $reposition_origin

    foreach motor $args {
        variable $motor
        set index [repositionOriginNameToIndex $motor]
        if {$index < 0} {
            log_error motor $motor not found in reposition motor list
            continue
        }
        set new_origin [lreplace $new_origin $index $index [set $motor]]
    }

    set reposition_origin $new_origin
}
proc resetReposition { } {
    variable repositionMotorList
    variable reposition_origin

    set new_origin ""
    foreach m $repositionMotorList {
        variable $m
        lappend new_origin 0
    }
    set reposition_origin $new_origin
}
##this will move all motors parallel
proc repositionMove { rp_phi rp_x rp_y rp_z } {
    variable gonio_omega

    set phiOrigin   [getRepositionOrigin gonio_phi]
    set omegaOrigin [getRepositionOrigin gonio_omega]
    set xOrigin     [getRepositionOrigin sample_x]
    set yOrigin     [getRepositionOrigin sample_y]
    set zOrigin     [getRepositionOrigin sample_z]

    set newX [reposition_calculate_sample_x $rp_x $rp_y]
    set newY [reposition_calculate_sample_y $rp_x $rp_y]

    set newPhi [expr $rp_phi + $phiOrigin - $gonio_omega + $omegaOrigin]
    set newX [expr $newX + $xOrigin]
    set newY [expr $newY + $yOrigin]
    set newZ [expr $rp_z + $zOrigin]

    if {![limits_ok sample_x $newX] || \
    ![limits_ok sample_y $newY] || \
    ![limits_ok sample_z $newZ]} {
        return -code error "will exceed children motor limits"
    }

    move gonio_phi to $newPhi
    move sample_x to $newX
    move sample_y to $newY
    move sample_z to $newZ

    wait_for_devices gonio_phi sample_x sample_y sample_z
}

proc reposition_phi_initialize { } {
    variable repositionMotorList

    #set repositionMotorList [list sample_x sample_y sample_z gonio_phi gonio_omega]
    set repositionMotorList [::config getStr reposition.origin.motorList]

    set_children gonio_phi gonio_omega

    set_triggers reposition_origin
}
proc reposition_phi_move { new_phi } {
    variable gonio_omega
    #### change here, MUST also change repositionMove
    set phiOrigin [getRepositionOrigin gonio_phi]
    set omegaOrigin [getRepositionOrigin gonio_omega]

    #### as long as omega does not move after use_current,
    #### $gonio_omega and $omegaOrigin cancel out.
    set newP [expr $new_phi + $phiOrigin - $gonio_omega + $omegaOrigin]

    move gonio_phi to $newP
    wait_for_devices gonio_phi
}
proc reposition_phi_set { new_phi } {
    ### as long as you make sure:
    ### gonio_phi - phi_origin + gonio_omega - omega_origin ==== new_phi
    ### Generic:
    ###     set phi_origin = gonio_phi - new_phi + gonio_omega - omega_origin
    ###
    ### Another way is set omega_origin = gonio_ometa
    ###     and        set phi_origin   = gonio_phi - new_phy
    ###
    ### Another way is set omega_origin = 0
    ###     and        set phi_origin   = gonio_phi - new_phy + gonio_omega

    puts "reposition_phi_set $new_phi"
    variable gonio_phi
    variable gonio_omega
    set omegaOrigin [getRepositionOrigin gonio_omega]

    set phiOrigin [expr $gonio_phi - $new_phi + $gonio_omega - $omegaOrigin]

    setRepositionOrigin gonio_phi $phiOrigin
}
proc reposition_phi_update { } {
    variable gonio_phi
    variable gonio_omega
    return [reposition_phi_calculate $gonio_phi $gonio_omega]
}
proc reposition_phi_calculate { phi omega } {
    set phiOrigin   [getRepositionOrigin gonio_phi]
    set omegaOrigin [getRepositionOrigin gonio_omega]
    return [expr $phi - $phiOrigin + $omega - $omegaOrigin]
}
proc reposition_phi_trigger { triggerDevice } {
	update_motor_position reposition_phi [reposition_phi_update] 1
}
