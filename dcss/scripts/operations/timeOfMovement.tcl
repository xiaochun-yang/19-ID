proc timeOfMovement_initialize {} {
}

variable timeoperation

proc timeOfMovement_start { motor movementstart movementend } {

global gDevice

set scaleFactor $gDevice($motor,scaleFactor)
set scaled $gDevice($motor,scaled)
set speed  $gDevice($motor,speed)
set acceleration $gDevice($motor,acceleration)
set lowerLimitOn $gDevice($motor,lowerLimitOn)
set upperLimitOn $gDevice($motor,upperLimitOn)
set scaledUpperLimit $gDevice($motor,scaledUpperLimit)
set scaledLowerLimit $gDevice($motor,scaledLowerLimit)
set lockOn $gDevice($motor,lockOn)
set backlashOn $gDevice($motor,backlashOn)
set reverseOn $gDevice($motor,reverseOn)
set scaledBacklash $gDevice($motor,scaledBacklash)  
set circlemode $motor.circleMode

#send_operation_update "speed=$speed scaleFactor=$scaleFactor scaledBacklash=$scaledBacklash"


set start [expr $movementstart * $scaleFactor]
set end [expr $movementend * $scaleFactor]

#set timedistance [expr double($end-$start)/$speed]

set timeacceleration [expr $acceleration /1000.0]
set backlash [expr $scaledBacklash * $scaleFactor]

if {$motor == "gonio_phi"} {
    set distance1 [expr $end - $start]
    while {$distance1 > [expr 360*$scaleFactor] } {
        set distance1 [expr $distance1 - (360*$scaleFactor)]
    }
    if {$distance1 > [expr 180*$scaleFactor]} {
        set distance [expr (360*$scaleFactor) - $distance1]
    } else {
        set distance [expr $distance1 ]
    }    
} else {
    set distance [expr $end - $start]
}

set timeoperation 0.0
set timetest [expr abs($distance)/double($speed)]

if {$distance != 0.0} {

    if {$backlashOn==1} {
    ####BACKLASH IN ON    
        if {$distance <0 && $backlash >0 } {
        ####MOVEMENT AND BACKLASH ARE OPPOSITE
            set timeoperation [expr (abs($distance) + 2*abs($backlash))/double($speed) + 4*$timeacceleration]
        } elseif {$distance >0 && $backlash <0 } {
        ####MOVEMENT AND BACKLASH ARE OPPOSITE
            set timeoperation [expr (abs($distance) + 2*abs($backlash))/double($speed) + 4*$timeacceleration]
        } else { 
         #####BACKLASH IS NOT ENGAGED
             if { $timetest < $timeacceleration } {
             ####MOVE FINISHES BEFORE FINAL SPEED REACHED
                set timeoperation [expr 2*sqrt(abs($distance)*$timeacceleration/double($speed))]
             } else {
                set timeoperation [expr abs($distance)/double($speed) + 2*$timeacceleration]
             }
        } 
    } else {
        ####BACKLASH IS OFF
        if { $timetest < $timeacceleration } {
         ####MOVE FINISHES BEFORE FINAL SPEED REACHED
            set timeoperation [expr 2*sqrt(abs($distance)*$timeacceleration/double($speed))]
         } else {
            set timeoperation [expr abs($distance)/double($speed) + 2*$timeacceleration]
         }
    }                
}
puts "Time of movement $motor $timeoperation seconds"
return $timeoperation
}

