proc washCrystal_initialize {} {
}

proc washCrystal_start { num } {
    if {[catch {
        ISampleMountingDevice_start washCrystal $num
    } errorMsg]} {
        puts "ERROR washCrystal: $errorMsg"
        log_error washCrystal $errorMsg

        return -code error $errorMsg
    }

    return washDone
}
