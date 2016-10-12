# table_id19_horz.tcl


proc table_horz_initialize {} {

        # specify children devices
        set_children table_horz_1 table_horz_2
        set_siblings table_yaw
}


proc table_horz_move { new_table_horz } {
        #global 
        global gDevice

        # global variables
        variable table_yaw
        variable table_horz_1
	variable table_horz_2

        # move the two motors
        move table_horz_1 to [calculate_table_horz_1 $new_table_horz $gDevice(table_yaw,target)]
        move table_horz_2 to [calculate_table_horz_2 $new_table_horz $gDevice(table_yaw,target)]

        #check to see if the move can be completed by the real motors
        assertMotorLimit table_horz_1 $new_table_horz_1
        assertMotorLimit table_horz_2 $new_table_horz_2

        # wait for the moves to complete
        wait_for_devices table_horz_1 table_horz_2
}


proc table_horz_set { new_table_horz } {

        # global variables
        variable table_horz_1
        variable table_horz_2
        variable table_yaw

        # move the two motors
        set table_horz_1 [calculate_table_horz_1 $new_table_horz $table_yaw]
        set table_horz_2 [calculate_table_horz_2 $new_table_horz $table_yaw]
}

proc table_horz_update {} {

        # global variables
        variable table_horz_1
        variable table_horz_2

        # calculate from real motor positions and motor parameters
        return [table_horz_calculate $table_horz_1 $table_horz_2]
}


proc table_horz_calculate { th1 th2 } {


        return [expr ($th1 + $th2)/2]
}

proc calculate_table_horz_1 { th ty } {

        return [expr ($th + $ty*402*3.1415926/180) ]
}


proc calculate_table_horz_2 { th ty} {

        return [expr ($th - $ty*402*3.1415926/180) ]
}

