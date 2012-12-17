package require DCSUtil


proc scan2Motors_initialize {} {
} 

proc scan2Motors_start {directory filename numberOfScans motor1 points1 start1 end1 stepsize1 units1 signal1 time1 sleep1 motor2 points2 start2 end2 stepsize2 units2 signal2 time2 sleep2} {
   
   set sessionId "PRIVATE[get_operation_SID]"
   set username [get_operation_user]

   for {set cnt 0} {$cnt < $numberOfScans} {incr cnt} {
   set id [start_waitable_operation scanMotor $username $sessionId [list [list [list $motor1 $points1 $start1 $end1 $stepsize1 $units1]]] {} [list $signal1] {{}} [list [list $time1 0.0 1 0.0]] [list [list $directory ${filename}-$motor1 $cnt]] ] 

    wait_for_operation_to_finish $id

      wait_for_time $sleep1

   set id [start_waitable_operation scanMotor $username $sessionId [list [list [list $motor2 $points2 $start2 $end2 $stepsize2 $units2]]] {} [list $signal2] {{}} [list [list $time2 0.0 1 0.0]] [list [list $directory ${filename}-$motor2 $cnt]] ] 
      #set id [scanMotor $username $sessionId [list [list [list $motor2 $points2 $start2 $end2 $stepsize2 $units2] {}]] [list $signal2] {} [list [list $time2 0.0 1 0.0]] [list [list $directory ${filename}-$motor2 $cnt]] ]
      wait_for_operation_to_finish $id

      wait_for_time $sleep2
   }
   
}
