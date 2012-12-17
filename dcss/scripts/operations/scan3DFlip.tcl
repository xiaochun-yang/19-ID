proc scan3DFlip_initialize { } {
	global gOperation

    #enable parallel calling
    set gOperation(scan3DFlip,parallel) 1
}
proc scan3DFlip_start { view_index row_index col_index } {
    MRastering_flipSelection $view_index $row_index $col_index
}
