#this operation is for scripted ion chamber
proc cryo_ion_initialize {} {
}

proc cryo_ion_start { time_in_second } {
    return [cryojet_start get_status]
}
