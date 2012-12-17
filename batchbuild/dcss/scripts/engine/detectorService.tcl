#package require Itcl
#namespace import itcl::*
#source util.tcl

package require DCSDetectorBase

DCS::DetectorBase gDetector

proc onDetectorTypeChange { } {
    puts "onDetectorTypeChange"
    if {[catch {
        namespace eval ::nScripts {
            variable detectorType

            ::gDetector setType $detectorType
            puts "set type to $detectorType"
        }
    } errMsg]} {
        puts "onDetectorTypeChange error: $errMsg"
    }
}
registerEventListener detectorType onDetectorTypeChange
