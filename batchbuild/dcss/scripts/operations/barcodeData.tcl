package require DCSBarcodeMap

DCS::BarcodeMap gBarcodeMap

proc barcodeData_initialize { } {
}
proc barcodeData_start { cmd args } {
    set staff [get_operation_user]
    set SID  [get_operation_SID]

    switch -exact -- $cmd {
        get_user_list {
            set barcode [lindex $args 0]
            return  [barcodeData_getUserList $barcode $staff $SID]
        }
        add_user {
            set barcode [lindex $args 0]
            set users   [lrange $args 1 end]
            return [barcodeData_addUser $barcode $users $staff $SID]
        }
        get_multiple_user_list {
            return [eval barcodeData_getMultipleUserList $staff $SID $args]
        }
    }
}
proc barcodeData_getUserList { barcode staff SID } {
    return [gBarcodeMap getUserList $barcode $staff $SID]
}
proc barcodeData_addUser { barcode users staff SID } {
    return [gBarcodeMap addUser $barcode $users $staff $SID]
}
proc barcodeData_getMultipleUserList { staff SID args } {
    return [eval gBarcodeMap getMultipleUserList $staff $SID $args]
}
