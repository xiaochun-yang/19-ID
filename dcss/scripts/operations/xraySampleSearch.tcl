#
#                        Copyright 2001
#                              by
#                 The Board of Trustees of the 
#               Leland Stanford Junior University
#                      All rights reserved.
#
#                       Disclaimer Notice
#
#     The items furnished herewith were developed under the sponsorship
# of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
# Leland Stanford Junior University, nor their employees, makes any war-
# ranty, express or implied, or assumes any liability or responsibility
# for accuracy, completeness or usefulness of any information, apparatus,
# product or process disclosed, or represents that its use will not in-
# fringe privately-owned rights.  Mention of any product, its manufactur-
# er, or suppliers shall not, nor is it intended to, imply approval, dis-
# approval, or fitness for any particular use.  The U.S. and the Univer-
# sity at all times retain the right to use and disseminate the furnished
# items for any purpose whatsoever.                       Notice 91 02 01
#
#   Work supported by the U.S. Department of Energy under contract
#   DE-AC03-76SF00515; and the National Institutes of Health, National
#   Center for Research Resources, grant 2P41RR01209. 
#


proc xraySampleSearch_initialize {} {
}

proc xraySampleSearch_start { username args } {
   global gDevice	
   global gMotorBeamWidth
   global gMotorBeamHeight

   variable xraySearchParams 
   variable gonio_phi 
   variable gonio_omega
   variable sample_x
   variable sample_y
   variable sample_z
   variable $gMotorBeamWidth
   variable $gMotorBeamHeight
   
    set USE_IMP_SERVER 0
   

   set gonioPhiOrigin $gonio_phi
      
   set index(active) 0
   set index(message) 1
   #set username [lindex $xraySearchParams 2]
   set sessionID [lindex $xraySearchParams 3]
   set directory [lindex $xraySearchParams 4]
   set fileRoot [lindex $xraySearchParams 5]
   set beamSize [lindex $xraySearchParams 6]
   set scanWidth [lindex $xraySearchParams 7]
   set scanHeight [lindex $xraySearchParams 8]
   set exposureTime [lindex $xraySearchParams 9]
   set delta [lindex $xraySearchParams 10]
   set totalColumns [lindex $xraySearchParams 11]
   set totalRows [lindex $xraySearchParams 12]


   #force the user to create the directory themselves
    if {$USE_IMP_SERVER} {
        if {[impGetFileType $userName $sessionID $directory] == "directory"} {
            set is_dir 1
        } else {
            set is_dir 0
        }
    } else {
        set is_dir [file isdirectory $directory]
    }
   if { !$is_dir } {
      return -code error "$directory is not a directory."
   }
  
   set beamSizeMicrons [expr int($beamSize * 1000)]

   set logPath [file join $directory ${fileRoot}_${beamSizeMicrons}.log]

    if {$USE_IMP_SERVER} {
        set contents "$xraySearchParams\n"
        append contents "filename gonio_phi gonio_omega sample_x sample_y sample_z $gMotorBeamWidth $gMotorBeamHeight\n" 
        impWriteFile $userName $sessionID $logPath $contents false
    } else {
        if [catch {open $logPath w 0600} logChannel] {
            return -code error "could not open $logPath"
        } 

        puts $logChannel $xraySearchParams
        puts $logChannel "filename gonio_phi gonio_omega sample_x sample_y sample_z $gMotorBeamWidth $gMotorBeamHeight" 
   
        close $logChannel

        set groupName "users"
        file attribute $logPath -group $groupName
        file attribute $logPath -owner $username
    }

   #replace the active and message fields
   set xraySearchParams [lreplace $xraySearchParams 0 1 1 {Starting xray search for sample.} ]

   log_note "Starting xray search."


	if { [catch {
      #changing to the requested beam size
      move $gMotorBeamWidth to $beamSize
      move $gMotorBeamHeight to $beamSize
      wait_for_devices $gMotorBeamWidth $gMotorBeamHeight


      # calculate angle of motion
      set phiOffset 90.0
      set phiDeg [expr $gonio_phi + $gonio_omega + $phiOffset]
		set phi [expr $phiDeg / 180.0 * 3.14159]

      #move to starting corner
      set deltaXPlane [expr -$scanWidth /2 + $beamSize /2]
      set deltaYPlane [expr -$scanHeight /2 + $beamSize /2]
 
      move sample_x by [calcDeltaSampleX $phi $deltaYPlane ]
      move sample_y by [calcDeltaSampleY $phi $deltaYPlane ]
      move sample_z by $deltaXPlane

      wait_for_devices sample_x sample_y sample_z

      #save the origin
      set sampleXOrigin $sample_x
      set sampleYOrigin $sample_y
      set sampleZOrigin $sample_z
      
      #raster over all of the frames in the grid
      for { set x 0} { $x < $totalColumns } {incr x} {

         for { set y 0} { $y < $totalRows } { incr y} {
            
            set xraySearchParams [lreplace $xraySearchParams 1 1 [list Moving to [expr $x+1] ,[expr $y +1]] ]
            # calculate relative motion of each sample motor in mm
            set deltaSampleXmm [calcDeltaSampleX $phi [expr $y * $beamSize]]
            set deltaSampleYmm [calcDeltaSampleY $phi [expr $y * $beamSize]] 
            set deltaSampleZmm [expr $beamSize * $x] 

            # move the sample motors
            move sample_x to [expr $sampleXOrigin + $deltaSampleXmm]
            move sample_y to [expr $sampleYOrigin + $deltaSampleYmm]
            move sample_z to [expr $sampleZOrigin + $deltaSampleZmm]

            move gonio_phi by 90

            # wait for all device motions to complete
            wait_for_devices sample_x sample_y sample_z gonio_phi

            set filenameWithIndex ${fileRoot}_${beamSizeMicrons}_[expr $x + 1]_[expr $y + 1]

            set xraySearchParams [lreplace $xraySearchParams 1 1 [list Taking JPEG of sample: $filenameWithIndex] ]
            
            #get a jpeg of the sample
            doVideoSnapshot $username $sessionID $directory $filenameWithIndex 

            set xraySearchParams [lreplace $xraySearchParams 1 1 [list Taking diffraction image of sample: $filenameWithIndex] ]
            move gonio_phi by -90
            wait_for_devices gonio_phi

            #take diffraction image

            if { $exposureTime < 5.0 } {
                #binned
                set modeIndex 2
            } else {
                #binned dezinger
                set modeIndex 6
            }
            
            set reuseDark 0 
			   set operationHandle [start_waitable_operation collectFrame \
										 0 \
											 $filenameWithIndex \
											 $directory \
											 $username \
											 gonio_phi \
											 shutter \
											 $delta \
											 $exposureTime \
											 $modeIndex \
											 0 \
											 $reuseDark ]

            wait_for_operation $operationHandle
            
            #the data collection moves by delta. Move back.
            move gonio_phi to $gonioPhiOrigin 
            wait_for_devices gonio_phi

            if {$USE_IMP_SERVER} {
                set contents "${directory}/${filenameWithIndex} $gonio_phi $gonio_omega $sample_x $sample_y $sample_z [set $gMotorBeamWidth] [set $gMotorBeamHeight]\n" 
                impAppendTextFile $userName $sessionID $logPath $contents
            } else {
                if [catch {open $logPath a 0600} logChannel] {
                log_warning "Could not open $logPath for append."
                } 

                puts $logChannel "${directory}/${filenameWithIndex} $gonio_phi $gonio_omega $sample_x $sample_y $sample_z [set $gMotorBeamWidth] [set $gMotorBeamHeight]" 

                catch {close $logChannel}
            }
         }
      } 

	} errorResult ] } {
       variable  xraySearchParams 

       log_note "stopping xray search."

       set xraySearchParams [lreplace $xraySearchParams 0 1 0 [list Xray search for sample failed to complete: $errorResult .] ]

	   start_recovery_operation detector_stop
	   return -code error $errorResult
	}
    
   start_operation detector_stop
   set xraySearchParams [lreplace $xraySearchParams 0 1 0 {Xray search for sample completed normally.} ]
}

proc calcDeltaSampleX {phi deltaPlaneY} {
   return [expr sin($phi) * $deltaPlaneY ]
}

proc calcDeltaSampleY {phi deltaPlaneY} {
   return [expr -cos($phi) * $deltaPlaneY ]
}



proc doVideoSnapshot {username sessionID directory fileRoot } {

    set USE_IMP_SERVER 0 

    set url [getVideoUrl]

    if {$USE_IMP_SERVER} {
        if {[impGetFileType $username $sessionID $directory] == "directory"} {
            set is_dir 1
        } else {
            set is_dir 0
        }
    } else {
        set is_dir [file isdirectory $directory]
    }
   if { !$is_dir } {
      log_warning "$directory is not a directory."
      return
   }

   set filePath [file join $directory "${fileRoot}.jpg"]

    if {$USE_IMP_SERVER} {
        if {[impGetFilePermissions $username $sessionID $filePath] != ""} {
            log_warning "Overwriting $filePath"
        }
        if { [catch {
            set token [http::geturl $url -timeout 12000]
            upvar #0 $token state
            set status $state(status)
            set result [http:data $token]
            http::cleanup $token
        } err] } {
            set status "ERROR $err $url"
        }

        if { $status != "ok" } {
            log_warning "doVideoSnapshot failed to get image: status=$status"
            return
        }

        impWriteFile $username $sessionID $filePath $result

    } else {
        if { [file exists $filePath] == 1 } {
            log_warning "Overwriting $filePath"
        }
   
        if { [catch {open $filePath w 0600} fileId] } {
            log_warning "doVideoSnapshot cannot open $fileId"
            return
        }

        if { [catch {
            set token [http::geturl $url -channel $fileId -timeout 8000]
            upvar #0 $token state
            set status $state(status)
            http::cleanup $token
        } err] } {
            set status "ERROR $err $url"
        }

        if { $status != "ok" } {
            log_warning "doVideoSnapshot failed to get image: status=$status"
            return
        }

        close $fileId

        set groupName "users"
        file attribute $filePath -group $groupName
        file attribute $filePath -owner $username
        }
    }


proc getVideoUrl {} {
   variable beamlineID

   set videoServerUrl "http://x4avideo.nsls.bnl.gov"

   switch -exact -- $beamlineID {
      X4A {
         set  sampleVideoPath "/axis-cgi/jpg/image.cgi?camera=1"
      }
      BL7-1 {
         set  sampleVideoPath "/BluIceVideo/bl71/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      BL9-1 {
         set  sampleVideoPath "/BluIceVideo/bl91/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      BL9-2 {
         set  sampleVideoPath "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      BL9-3 {
         set  sampleVideoPath "/BluIceVideo/bl93/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      BL11-1 {
         set  sampleVideoPath "/BluIceVideo/bl111/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      BL11-3 {
         set  sampleVideoPath "/BluIceVideo/bl113/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      smblx6 {
         set  sampleVideoPath "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      bl92sim {
         set  sampleVideoPath "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
      default {
         log_error "getVideoUrl did not recognize beamline id: $m_beamlineID"
         set sampleVideoPath "/BluIceVideo/bl92/video1/axis-cgi/jpg/image.cgi?camera=2"
      }
   }

   return ${videoServerUrl}${sampleVideoPath}
}

