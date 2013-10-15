#scan phi with ion chamber

proc scanPhi_initialize {} {

}

proc scanPhi_start { fileName myDirectory delta time nloops} {

        set fullpath $myDirectory/$fileName;
	if [catch {open $fullpath w} fileId] {
       		puts stderr "Cannot open $fullpath $fileId"
		return
	}	

	set i 0
	set pos 0
	set ion 0
	while { $i < $nloops } {

                #move gonio_phi by $delta deg
		#move by pulses with steps
		move gonio_phi by $delta steps
                wait_for_devices gonio_phi
		set pos  [expr $pos + $delta]
                # wait for 100 mill-seconds
                after 200
		
                # read ion chamber 
		read_ion_chambers $time i1
		wait_for_devices i1
		set ion [get_ion_chamber_counts i1]
		puts $fileId "$pos   $ion"
		incr i
	}
	close $fileId
}
