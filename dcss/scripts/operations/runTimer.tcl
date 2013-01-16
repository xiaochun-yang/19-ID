
::DCS::RunSequenceCalculator gPeteRunCalculator

proc runTimer_initialize {} {

namespace eval ::datatime {

variable table_opt_energy
variable image_overhead_time
variable timeOptEnergy
variable num_energies
variable energies
variable attenuation_for_run
variable wedges_per_energy
variable num_table_opt
variable phi_start
variable phi_end
variable phi_delta
variable wedge
variable exposure_time
variable dose_corrected_time
variable corrected_time
variable inverse
variable table_opt_timeout
variable save_energy_move_times
variable delta_energies
variable next_frame
variable totalFrames
variable numCompleteWedges
variable table_opt_enabled

}
}

proc runTimer_start {next run runLabel first start end delta wedg time atten numE e1 e2 e3 e4 e5 inv dMode bl} {
variable run_time_estimates

variable ::datatime::table_opt_energy
variable ::datatime::image_overhead_time
variable ::datatime::timeOptEnergy
variable ::datatime::num_energies
variable ::datatime::energies
variable ::datatime::attenuation_for_run
variable ::datatime::wedges_per_energy
variable ::datatime::phi_start
variable ::datatime::phi_end
variable ::datatime::phi_delta
variable ::datatime::wedge
variable ::datatime::exposure_time
variable ::datatime::image_overhead_time
variable ::datatime::inverse
variable ::datatime::table_opt_timeout
variable ::datatime::next_frame
variable ::datatime::table_opt_enabled

variable detectorType
variable optimizedEnergyParameters
variable runs
variable dose_data

global gPeteRunCalculator

clear_variables

# skip run 0 since it needs special treatment (cannot use phi_end)
if {$run == 0} {
    return
}

# fill object PeteRunCalculator

#variable run$run
gPeteRunCalculator updateRunDefinition [list "status" $next $runLabel "root" "directory" $first "axis" $start $end $delta $wedg $time "distance" "beam_stop" $atten $numE $e1 $e2 $e3 $e4 $e5 $dMode $inv] 

# get beamline-specific numbers (units are seconds, eV,  )
set table_opt_enabled [lindex $optimizedEnergyParameters 3]
set table_opt_energy [lindex $optimizedEnergyParameters 11]
set table_opt_timeout [lindex $optimizedEnergyParameters 12]

# check is Enable Table Optimizations set to true
#  to catch BL12-2
if { $table_opt_enabled == 1 } {
  set timeOptEnergy [timeOptEnergy_start]
}

# Q315R image_overhead_time 2.8 sec, MAR325 image_overhead_time 3.2 sec
#log_note dtype $detectorType

set dType [lindex $detectorType 0]

if { $dType == "Q315CCD" } {
  set image_overhead_time 2.8
} elseif {$dType == "MAR325" } {
  set image_overhead_time 3.2
} elseif {$dType == "MAR345" && $dMode == 0} {
  set image_overhead_time 84.5
} elseif {$dType == "MAR345" && $dMode == 2} {
  set image_overhead_time 54.1
} else {
  set image_overhead_time 4.0
}

set temp_energies [list $e1 $e2 $e3 $e4 $e5]
set num_energies $numE
incr numE -1
set energies [lrange $temp_energies 0 $numE]

set first_frame $first
set next_frame $next
set phi_delta $delta
set phi_start $start
set phi_end $end
set wedge $wedg
set exposure_time $time
set inverse $inv
set attenuation_for_run $atten

# ... first find time for images
# ...   if it is zero, the run is complete
# ... then time for energy moves
# ... then time for table optimizations (due to energy changes)
# ... then time for optimizations due to the timeout

lappend messages "images. . . . . . . ."
lappend messages "move energy . . . . ."
lappend messages "opt - energy trigger."
lappend messages "opt - timeout trigger"

lappend times [time_for_images] 

if {[lindex $times 0] == 0 } {
     set formatted_time 00:00:00
     set run_time_estimates \
     [setStringFieldWithPadding $run_time_estimates $run $formatted_time]
     return
}

lappend times [time_for_moves]
lappend times [time_for_opt] 
 
set est_time 0
foreach time_increment $times {
  set est_time [expr $est_time + $time_increment]
}

lappend times [time_for_timeout $est_time ]

# ... all done
set total_time 0
foreach time_increment $times message $messages {
  puts "time_increment $message [expr round($time_increment)]"
  set total_time [expr $total_time + $time_increment]
}
set total_time [expr round($total_time)]
puts "Time for run $runLabel = $total_time sec"

#reformat here
set m [expr $total_time / 60]
set h [expr $m / 60]
set S [expr $total_time % 60]
set M [expr $m % 60]
set formatted_time [format "%02d:%02d:%02d" $h $M $S]

set run_time_estimates \
[setStringFieldWithPadding $run_time_estimates $run $formatted_time]

set efficiency [time_summary $times]
set efficiency [format "%2.3f" $efficiency]
puts "Fraction of time taking images = $efficiency"

return

}


proc clear_variables { } {

variable ::datatime::table_opt_energy
variable ::datatime::image_overhead_time
variable ::datatime::timeOptEnergy
variable ::datatime::num_energies
variable ::datatime::energies
variable ::datatime::attenuation_for_run
variable ::datatime::wedges_per_energy
variable ::datatime::num_table_opt
variable ::datatime::phi_start
variable ::datatime::phi_end
variable ::datatime::phi_delta
variable ::datatime::wedge
variable ::datatime::exposure_time
variable ::datatime::dose_corrected_time
variable ::datatime::inverse
variable ::datatime::table_opt_timeout
variable ::datatime::next_frame
variable ::datatime::save_energy_move_times
variable ::datatime::delta_energies
variable ::datatime::table_opt_energy
variable ::datatime::totalFrames
variable ::datatime::numCompleteWedges
variable ::datatime::table_opt_enabled

set table_opt_energy ""
set image_overhead_time ""
set timeOptEnergy ""
set num_energies ""
set energies ""
set attenuation_for_run ""
set wedges_per_energy ""
set num_table_opt ""
set phi_start ""
set phi_end ""
set phi_delta ""
set wedge ""
set exposure_time ""
set dose_corrected_time ""
set inverse ""
set table_opt_timeout ""
set next_frame ""
set save_energy_move_times ""
set delta_energies ""
set table_opt_energy ""
set totalFrames ""
set numCompleteWedges ""
set table_opt_enabled ""

}

proc time_for_images { } {

#  added doseFactor for case where dose mode (exposure control) is enabled
#  also affects time_for_timeout via exposure_time
# doseFactor calculated as in operations/requestExposureTime.tcl
# could optionally add a check for "collecting" in run definition

global gPeteRunCalculator

variable ::datatime::image_overhead_time
variable ::datatime::exposure_time
variable ::datatime::dose_corrected_time
variable ::datatime::next_frame
variable ::datatime::completedFrames
variable ::datatime::totalFrames
variable ::datatime::attenuation_for_run

variable runs 
variable dose_data
variable beam_size_x
variable beam_size_y

set totalFrames [gPeteRunCalculator getTotalFrames]
set remainingFrames [expr $totalFrames - $next_frame]
set completedFrames [expr $totalFrames - $remainingFrames]
puts "total_frames $totalFrames"
puts "remaining_frames $remainingFrames"

set dose_mode [lindex $runs 2]

set storedCounts [lindex $dose_data 1]
#log_note "Stored dose  $storedCounts"
if {![string is double -strict $storedCounts] ||  $storedCounts == 0} {
#       log_warning dose stored counts wrong $storedCounts
        set dose_mode 0
}

set lastCounts   [lindex $dose_data 3]
#log_note "Last dose  $lastCounts"
if {![string is double -strict $lastCounts] || $lastCounts == 0} {
#       log_warning dose last counts wrong $lastCounts
        set dose_mode 0
}

set doseFactor 1
if { $dose_mode == 1} {
        set last_slit_width  [lindex $dose_data 2 2]
        set last_slit_height [lindex $dose_data 2 3]
        set last_atten       [lindex $dose_data 2 4]
        set doseFactor [expr abs(double($storedCounts) / double($lastCounts)) ]
        puts "Exposure Factor counts  $doseFactor"
        set doseFactor [expr $doseFactor * ($last_slit_width / $beam_size_x) * ($last_slit_height / $beam_size_y)]
        puts "Exposure Factor counts, beam_size $doseFactor"
        set doseFactor [expr $doseFactor * ((100.0 - $last_atten) / (100.0 - $attenuation_for_run))]
        puts "Exposure Factor counts, beam_size, attenuation $doseFactor"
}
set dose_corrected_time [expr $exposure_time * $doseFactor]

set images_time 0
set images_time [expr ($dose_corrected_time + $image_overhead_time) * $remainingFrames]

return $images_time
}

proc time_for_moves { } {
# time to move between energies
# the energy_motorlist in the energy tracking device must be correct
# also track BL12-2 moves that cross the 9500 eV energy where the Pilatus needs time to reset

variable ::datatime::num_energies
variable ::datatime::energies
variable ::datatime::wedges_per_energy
variable ::datatime::next_frame
variable ::datatime::phi_end
variable ::datatime::phi_start
variable ::datatime::wedge
variable ::datatime::completedFrames
variable ::datatime::completedEnergiesInWedge
variable ::datatime::save_energy_move_times
variable ::datatime::numCompleteWedges

variable detectorType

set numCompleteWedges [expr int(($phi_end - $phi_start)/$wedge + 0.00001)]
set fullWedgeFramesPerLevel [gPeteRunCalculator getFullWedgeFramesPerLevel]
set fragmentWedgeFramesPerLevel [gPeteRunCalculator getFragmentWedgeFramesPerLevel]
puts "fragmentWedgeFramesPerLevel_1 [lindex $fragmentWedgeFramesPerLevel 0]"

set completedLevelsInWedge [gPeteRunCalculator calculateCompletedLevelsInWedge $next_frame]
#log_note "completedLevelsInWedge $completedLevelsInWedge"
set completedEnergiesInWedge [lindex $completedLevelsInWedge 1]

if {[lindex $fragmentWedgeFramesPerLevel 0] > 0} {
  set wedges_per_energy [expr $numCompleteWedges + 1]
} else {
  set wedges_per_energy $numCompleteWedges
}
set completed_wedges [expr int(($completedFrames/[lindex $fullWedgeFramesPerLevel 2]) + 0.00001)]
set wedges_per_energy [expr $wedges_per_energy - $completed_wedges]

set timeMoveEnergy 0
if {$num_energies > 1} {
  set j 1
  foreach first_energy $energies {
    set second_energy [lindex $energies $j]
    set tempMoveEnergy [ timeMoveEnergy_start $first_energy $second_energy ]
# add time for Pilatus, before save_energy_move_times
       if { [lindex $detectorType 0] == "PILATUS6" } {
          if {[energyGetEnabled set_threshold]} {
             if { (($first_energy < 9500) && ($second_energy > 9500)) || \
                  (($first_energy > 9500) && ($second_energy < 9500)) } {
                if { $tempMoveEnergy < 120 } {
                   set tempMoveEnergy  120
                }
             }
          }
       }
    lappend save_energy_move_times $tempMoveEnergy
    if { $j > 0 } {
      set timeMoveEnergy [expr $timeMoveEnergy + $tempMoveEnergy * $wedges_per_energy]
    } else {
      set timeMoveEnergy [expr $timeMoveEnergy + $tempMoveEnergy * ( $wedges_per_energy - 1 )]
    }
    incr j
    if {$j > ($num_energies - 1)} {
      set j 0
    }
  }
  if {$completedEnergiesInWedge > 0} {
    for { set i 0 } { $i < $completedEnergiesInWedge } { incr i } {
      set first_energy [lindex $energies $i]
      set second_energy [lindex $energies [expr $i + 1]]
      set tempMoveEnergy [ timeMoveEnergy_start $first_energy $second_energy ]
         if { [lindex $detectorType 0] == "PILATUS6" } {
            if {[energyGetEnabled set_threshold]} {
               if { (($first_energy < 9500) && ($second_energy > 9500)) || \
                    (($first_energy > 9500) && ($second_energy < 9500)) } {
                  if { $tempMoveEnergy < 120 } {
                     set tempMoveEnergy  120
                  }
               }
            }
         }
      set timeMoveEnergy [expr $timeMoveEnergy - $tempMoveEnergy]
    }
  }
}

return $timeMoveEnergy
}

proc time_for_opt { } {

# time due to energy changes triggering table optimization
## also here is check on attenuation (adds 2 sec per optimization)

# changes num_table_opt, possibly timeOptEnergy

variable ::datatime::num_energies
variable ::datatime::energies
variable ::datatime::table_opt_energy
variable ::datatime::wedges_per_energy
variable ::datatime::attenuation_for_run
variable ::datatime::timeOptEnergy
variable ::datatime::num_table_opt
variable ::datatime::completedEnergiesInWedge
variable ::datatime::delta_energies
variable ::datatime::table_opt_enabled

# for 12-2 case, perhaps return 0 immediately if table_opt_enabled not set
if { $table_opt_enabled == 0 } {
   return 0
}

set num_table_opt 0
if {$num_energies > 1} {
  set j 1
  foreach energy $energies {
    set second_energy [lindex $energies $j]
    set delta_energy [expr $second_energy - $energy]
    lappend delta_energies $delta_energy
    incr j
    if {$j > ($num_energies - 1)} {
      set j 0
    }
  }
  foreach delta_energy $delta_energies {
    if {abs($delta_energy) >= $table_opt_energy} {
      incr num_table_opt
    }
  }
  set num_table_opt [expr $num_table_opt * $wedges_per_energy]

  if {$completedEnergiesInWedge > 0} {
    for { set i 0 } { $i < $completedEnergiesInWedge } { incr i } {
      if {abs([lindex $delta_energies $i]) >= $table_opt_energy} {
        set num_table_opt [expr $num_table_opt - 1] 
      }
    }
  }

  if { abs( [lindex $delta_energies end] ) >= $table_opt_energy } {
    set num_table_opt [expr $num_table_opt - 1]
  }
}
if {$attenuation_for_run > 0} {
  set timeOptEnergy [expr $timeOptEnergy + 2 ] 
}
puts "num_table_opt $num_table_opt wedges_per_energy $wedges_per_energy \
                       completedEnergiesInWedge $completedEnergiesInWedge"

return [expr $num_table_opt * $timeOptEnergy]
}

proc time_for_timeout {estimated_time} {

# time due to exceeding the table optimization timeout time limit
## call this procedure last to use the estimate of the total time due to other factors
# tricky if several energies, only some energy moves trigger table opt!

variable ::datatime::table_opt_timeout
variable ::datatime::timeOptEnergy
variable ::datatime::wedges_per_energy
variable ::datatime::num_energies
variable ::datatime::dose_corrected_time
variable ::datatime::save_energy_move_times
variable ::datatime::delta_energies
variable ::datatime::next_frame
variable ::datatime::table_opt_energy
variable ::datatime::image_overhead_time
variable ::datatime::totalFrames
variable ::datatime::numCompleteWedges
variable ::datatime::table_opt_enabled

# first check if table opt is enabled
if { $table_opt_enabled == 0 } {
     return 0
}

set fullWedgeFramesPerLevel [gPeteRunCalculator getFullWedgeFramesPerLevel]
set fragmentWedgeFramesPerLevel [gPeteRunCalculator getFragmentWedgeFramesPerLevel]
set completedLevelsInWedge [gPeteRunCalculator calculateCompletedLevelsInWedge $next_frame]

set completedEnergiesInWedge [lindex $completedLevelsInWedge 1]
set fragmentStartIndex [lindex $completedLevelsInWedge end]

#send_operation_update "fragmentWedgeFramesPerLevel_2  $fragmentWedgeFramesPerLevel"
#send_operation_update "completedLevels $completedLevelsInWedge"

set add_table_opt 0

# return if table_opt_timeout not set
if {$table_opt_timeout == 0 || $table_opt_timeout == ""} {
    return 0
}

# protect against errors due to timeout occurring every image
if {[expr $dose_corrected_time + $image_overhead_time] > $table_opt_timeout} {
  set table_opt_timeout [expr $dose_corrected_time + $image_overhead_time]
}

set accumulated_time 0

puts "next $next_frame fragment_start $fragmentStartIndex"

# use estimated_time to test whether we're done
if {$estimated_time < $table_opt_timeout} {
    return 0
}

# case before last fragment
set frames_to_next_boundary 0

if { $next_frame < $fragmentStartIndex } {
#   log_note "fullWedgeFramesPerLevel $fullWedgeFramesPerLevel"
#   log_note "fragmentWedgeFramesPerLevel $fragmentWedgeFramesPerLevel"
# do single energy cases first
#  for one energy, doesn't matter if there is a fragment or not
#
    if {$num_energies == 1} {
       set accumulated_time [expr ($totalFrames - $next_frame) * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
       set add_table_opt [expr int($accumulated_time / $table_opt_timeout)]
       return [expr $add_table_opt * $timeOptEnergy]
    }
    set frames_to_next_boundary [expr [lindex $fullWedgeFramesPerLevel 1] - \
                                      [lindex $completedLevelsInWedge 2] * [lindex $fullWedgeFramesPerLevel 0] - \
                                      [lindex $completedLevelsInWedge 3]]
    incr next_frame  $frames_to_next_boundary
    lset completedLevelsInWedge 2 0
    lset completedLevelsInWedge 3 0
    set accumulated_time [expr $frames_to_next_boundary * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
# case not at fragment start yet, unless we just moved there
#   this might carry on into the beginning of a full wedge, or might not
#
    for {set i 0} { $i < ($num_energies * $numCompleteWedges) } {incr i } {
      if { $next_frame == $fragmentStartIndex  } {
#log_note "break here"
          break
      }
      if { $next_frame <  $fragmentStartIndex  } {
#
#log_note "delta_energies $delta_energies completed $completedEnergiesInWedge"
          if {abs([lindex $delta_energies  $completedEnergiesInWedge ]) < $table_opt_energy} {
            set accumulated_time [expr $accumulated_time + [lindex $save_energy_move_times  $completedEnergiesInWedge ]]
            set accumulated_time [expr $accumulated_time + [lindex $fullWedgeFramesPerLevel 1] * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
            incr next_frame [lindex $fullWedgeFramesPerLevel 1]
          }
          if {abs([lindex $delta_energies  $completedEnergiesInWedge ]) >= $table_opt_energy} {
            if { $accumulated_time > $table_opt_timeout } {
              set add_table_opt [expr $add_table_opt + int($accumulated_time / $table_opt_timeout)]
            }
            set accumulated_time 0
            incr next_frame [lindex $fullWedgeFramesPerLevel 1]
            set accumulated_time [expr [lindex $fullWedgeFramesPerLevel 1] * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
          }
          incr completedEnergiesInWedge
# need to reset completedEnergiesInWedge from time to time . . .
          if {$completedEnergiesInWedge == $num_energies } {
             set completedEnergiesInWedge 0
          }


      }
    }

#   now capture
    set add_table_opt [expr $add_table_opt + int($accumulated_time / $table_opt_timeout)]
    if { abs([lindex $delta_energies end]) >= $table_opt_energy } {
       set accumulated_time 0
    } else {
       set accumulated_time [expr fmod($accumulated_time , $table_opt_timeout)]
    }
#log_note "carrying over $accumulated_time"

# reset completedLevelsInWedge
    lset completedLevelsInWedge 1 0
    set completedEnergiesInWedge 0

# return if all done
    if { $next_frame == $totalFrames } {
       return [expr $add_table_opt * $timeOptEnergy ]
    }

}

# case where in last fragment
set frames_to_next_energy_opt 0

if { $next_frame >= $fragmentStartIndex } {

#
    set frames_to_next_energy_opt [expr [lindex $fragmentWedgeFramesPerLevel 1] - \
                                        [lindex $completedLevelsInWedge 2] * [lindex $fragmentWedgeFramesPerLevel 0] - \
                                        [lindex $completedLevelsInWedge 3]]
    incr next_frame  $frames_to_next_energy_opt
    lset completedLevelsInWedge 2 0
    set accumulated_time [expr $accumulated_time + $frames_to_next_energy_opt * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
# might be all done now
    for { set i 0 } { $i < ($num_energies - 1) } { incr i } {
       if {$next_frame < $totalFrames } {
#
           if {abs([lindex $delta_energies  $completedEnergiesInWedge ]) < $table_opt_energy} {
              set accumulated_time [expr $accumulated_time + [lindex $save_energy_move_times  $completedEnergiesInWedge ]]
              incr next_frame [lindex $fragmentWedgeFramesPerLevel 1]
              set accumulated_time [expr $accumulated_time + [lindex $fragmentWedgeFramesPerLevel 1] * ($dose_corrected_time + $image_overhead_time) - 0.001 ]
           }
           if {abs([lindex $delta_energies  $completedEnergiesInWedge ]) >= $table_opt_energy} {
              if { $accumulated_time > $table_opt_timeout } {
                 set add_table_opt [expr $add_table_opt + int($accumulated_time / $table_opt_timeout)]
              }
              set accumulated_time 0
              incr next_frame [lindex $fragmentWedgeFramesPerLevel 1]
              set accumulated_time [expr [lindex $fragmentWedgeFramesPerLevel 1] * ($dose_corrected_time + $image_overhead_time)]
           }
           incr completedEnergiesInWedge
       }
    }
## done with five energies
    if {$next_frame < $totalFrames} {
       log_note "Trouble next $next_frame total $totalFrames"
    }
#   now capture
    set add_table_opt [expr $add_table_opt + int($accumulated_time / $table_opt_timeout)]
}


puts "add_table_opt $add_table_opt"

return [expr $add_table_opt * $timeOptEnergy]
}

proc time_summary {time_list} {

# return the ratio of time spent for images / total time spent
#  to see how inefficient a choice of wedge size might be

set a [lindex $time_list 0]
set b 0
for {set i 0} {$i < [llength $time_list]} {incr i} {
set b [expr $b + [lindex $time_list $i]]
}
return [expr $a/$b]
}
