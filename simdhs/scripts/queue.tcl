proc qinit {qvar} {
   upvar 1 $qvar Q
   set Q [list]
}

proc qput {qvar elem} {
   upvar 1 $qvar Q
   lappend Q $elem
}

proc qget {qvar} {
   upvar 1 $qvar Q
   set head [lindex $Q 0]
   set Q [lrange $Q 1 end]
   return $head
}

proc qempty {qvar} {
   upvar 1 $qvar Q
   return [expr {[llength $Q] == 0}]
}

