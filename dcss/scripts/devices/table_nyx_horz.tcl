# table_nyx_horz.tcl


proc table_nyx_horz_initialize {} {

        # specify children devices
        set_children table_h1 table_h2
        set_siblings table__nyx_yaw
}


proc table_nyx_horz_move { new_table_nyx_horz } {
        #global 
        global gDevice

        # global variables
        variable table_nyx_yaw

        # move the two motors
        move table_h1 to [calculate_table_h1 $new_table_nyx_horz $gDevice(table_nyx_yaw,target)]
        move table_h2 to [calculate_table_h2 $new_table_nyx_horz $gDevice(table_nyx_yaw,target)]

        #check to see if the move can be completed by the real motors
        assertMotorLimit table_h1 $new_table_h1
        assertMotorLimit table_h2 $new_table_h2

        # wait for the moves to complete
        wait_for_devices table_h1 table_h2
}


proc table_nyx_horz_set { new_table_nyx_horz } {

        # global variables
        variable table_h1
        variable table_h2
        variable table_nyx_yaw

        # move the two motors
        set table_h1 [calculate_table_h1 $new_table_nyx_horz $table_nyx_yaw]
        set table_h2 [calculate_table_h2 $new_table_nyx_horz $table_nyx_yaw]
}

proc table_nyx_horz_update {} {

        # global variables
        variable table_h1
        variable table_h2

        # calculate from real motor positions and motor parameters
        return [table_nyx_horz_calculate $table_h1 $table_h2]
}


proc table_nyx_horz_calculate { th1 th2 } {


        return [expr ($th1*902 - $th2*749)*180/3.14/1651]
}

proc calculate_table_h1 { th ty } {

        return [expr 10.8*($th - $ty*749*3.14/180) ]
}


proc calculate_table_h2 { th ty} {

        return [expr 10.8*($th - 902*3.14/180)]
}

