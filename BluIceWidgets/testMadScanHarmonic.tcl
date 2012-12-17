####
### For 12-2 to test whether all edges fit in harmonic range.
#
set harmonicLL   [list 15449.99      12999.99      10000      6600]
set harmonicHL   [list 17000         16000         14000     10600]

set ll [llength $harmonicLL]

global gPeriodicTable

set myList [$gPeriodicTable getDisplayedEdgeList]
puts "num elements [llength $myList]"
foreach elmnt $myList {
    foreach {name temp e dummy_x dummy_y} $elmnt break

    set madL [expr $e - 200.0]
    set madH [expr $e + 210.0]

    for {set h 0} {$h < $ll} {incr h} {
        if {$madL >= [lindex $harmonicLL $h] && \
        $madH <= [lindex $harmonicHL $h]} {
            puts "$name fit in $h"
            break
        }
    }
    if {$h >= $ll} {
        puts "FIX $name $e: $madL-$madH not fit in any harmomic"
    }
}
