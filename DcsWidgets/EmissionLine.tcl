package provide DCSEmissionLine 1.0

package require Itcl
#namespace import ::itcl::*

::itcl::class DCS::EmissionLine {
    private common elementList ""

    public proc setPeriodicFile { fileName } {
        ### open the file for read
        if {[catch {open $fileName "r"} fh]} {
            log_error EmissionLine: failed to open file $fileName: $fh
            return
        }

        ### get lines with emission lines
        set elementList ""
        if {[catch {
            while {![eof $fh]} {
                set line [gets $fh]
                set line [string trim $line]
                if {[string index $line 0] == "#"} {
                    ###this is comment line
                    continue
                }
                set ll [llength $line]
                if {$ll < 8} {
                    ###no emission lines defined
                    continue
                }
                ### OK, parse the line
                set eName [lindex $line 3]
                set num   [lindex $line 4]
                set lFromN [expr 5 + $num * 3]
                if {$ll != $lFromN} {
                    ### should not happen
                    log_warning periodic file $fileName line $line wrong number
                    continue
                }
                set emissionList ""
                for {set i 0} {$i < $num} {incr i} {
                    set index [expr $i * 3 + 7]
                    set emission [lindex $line $index]
                    lappend emissionList $emission
                }
                lappend elementList [list $eName $emissionList]
            }
        } errMsg]} {
            log_error EmissionLine: failed to read file $fileName: $errMsg
        }

        close $fh
        log_note total number of elements [llength $elementList]
    }

    # each element is a list itself, consists of name and
    # the emission lines for that element.
    # Only the lines within the energy range will be returned
    public proc getElementList { energyStart energyEnd } {
        if {$energyStart > $energyEnd} {
            ##swap them
            set tmp_var $energyStart
            set energyStart $energyEnd
            set energyEnd $tmp_var
            log_warning energy start end swapped
        }
        set resultList ""
        foreach element $elementList {
            foreach {name emissionList} $element break

            set matchLine ""
            foreach emission $emissionList {
                if {$emission >= $energyStart && $emission <= $energyEnd} {
                    lappend matchLine $emission
                }
            }
            if {$matchLine != ""} {
                lappend resultList [list $name $matchLine]
            }
        }
        return $resultList
    }
}

global $DCS_DIR
DCS::EmissionLine::setPeriodicFile $DCS_DIR/BluIceWidgets/data/periodic-table.dat

##########TEST
proc test_EmissionLine { } {
    #DCS::EmissionLine::setPeriodicFile ../BluIceWidgets/data/periodic-table.dat

    set myList [DCS::EmissionLine::getElementList 10000 15000]
    puts "total elements returned [llength $myList]"
    foreach e $myList {
        puts $e
    }
}
