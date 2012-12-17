proc centerLoopC3D_initialize {} {
}

proc centerLoopC3D_start { } {

set prefixLow  zoom_low
set prefixHigh zoom_high

set resultLow  results1.txt
set resultHigh results2.txt


set dir [file join [pwd] .C3D]
set imageDir [file join $dir Images Loop]
set resultDir [file join $dir TEST]

set resultPathLow [file join $resultDir $resultLow]
set resultPathHigh [file join $resultDir $resultHigh]

set angleList [list 0 14 90 166 180 196 270 344]

#### ATTENTION space " " at the end
set commonArgs ""
append commonArgs "-idx=$angleList "
append commonArgs "-ang=$angleList "
append commonArgs "-imd=$imageDir "
append commonArgs "-wfo=$resultDir "
append commonArgs "-mrf -v=2 -fuz "

set C3DArgsLow $commonArgs
append C3DArgsLow "-obj=loopshape+loop3d "
append C3DArgsLow "-imt=${prefixLow}_%d.jpg "
append C3DArgsLow "-r3d=$resultLow "

set C3DArgsHigh $commonArgs
append C3DArgsHigh "-obj=loopshape+loopcentre3d "
append C3DArgsHigh "-imt=${prefixHigh}_%d.jpg "
append C3DArgsHigh "-r3d=$resultHigh "


#### clear up the directory
file delete -force $dir
file mkdir $dir $imageDir $resultDir

variable gonio_phi
variable sample_x
variable sample_y
variable sample_z
variable gonio_omega

    set restore_lights 1
    if {[catch centerSaveAndSetLights errMsg]} {
        log_warning lights control failed $errMsg
        set restore_lights 0
    }

#####################################################
##### BIG CATCH #####################################
    if {[catch {
#####################################################

set RELIABILITY 1

set retry 0
while {$RELIABILITY<3} {

    incr retry
    if {$retry >= 4} {
        return -code error "failed after retry $retry times reliability=$RELIABILITY"
    }

	#### Move camera_zoom to low level
	move camera_zoom to 0.2
	wait_for_devices camera_zoom

	set phi_start $gonio_phi

	foreach {phi} $angleList {

    		move gonio_phi to [expr $phi_start + $phi]
    		wait_for_devices gonio_phi
		
    		###filename
    		set filename ${prefixLow}_${phi}.jpg
		
		set filePath [file join $imageDir $filename]

    		VideoSnapshot $filePath
    		log_note snapshot to $filePath
	}
	
	log_note "Video snapshots done. Please wait a moment while C3D runs"
	
	
	####Getting Scale Factor at Low Zoom Level
        variable camera_zoom
    set zoomMinScale [getSampleCameraConstant zoomMinScale]
	set zoomMaxScale [getSampleCameraConstant zoomMaxScale]
    set sampleAspectRatio [getSampleCameraConstant sampleAspectRatio]

	set scaleFactorx  [expr $zoomMinScale * 0.5 * exp (log($zoomMaxScale/$zoomMinScale) * $camera_zoom) ]
	set scaleFactory  [expr $scaleFactorx * $sampleAspectRatio ]
	log_note "$scaleFactorx   $scaleFactory"

	##### running C3D to give values for centring of loop at low zoom value
	set C3D [exec /home/sw/rhel4/C3D/c3d "-scx=${scaleFactorx} -scy=${scaleFactory} $C3DArgsLow"]
	log_note "C3D done"
	
	set RELIABILITY [exec cut -c1-130 $resultPathLow | paste -s | cut -c235-240]
	log_note "Reliability $RELIABILITY -Scored range between 0 (failure) and 9 (likely good centering)"

	### getting the values from results
	set TARGET_ANGLE [expr -$phi_start + [exec cut -c1-130 $resultPathLow | paste -s | cut -c156-165]]
	set RADIUS [exec cut -c1-130 $resultPathLow | paste -s | cut -c150-155]
	set Y_centre [exec  cut -c1-130 $resultPathLow | paste -s | cut -c141-150]
	set X_centre [exec cut -c1-130 $resultPathLow | paste -s | cut -c135-140]
	set GBA [exec  cut -c1-130 $resultPathLow | paste -s | cut -c205-215]
	
	#### move vertically, in screen image, first converting pixels to mm, at 0.2 zoom image is 6.876  x 5.195 mm (704 pix by 480 pix)
    set angle [lindex $angleList 0]
    set angle [expr $TARGET_ANGLE - ($gonio_omega + $angle)]
    set angle [expr $angle * 3.14159265 / 180.0]
	
	set move_x [expr -cos($angle) * $RADIUS]
	set move_y [expr  sin($angle) * $RADIUS]	
	move sample_x by $move_x um
	move sample_y by $move_y um
	log_note "moving sample_y by $move_y"
	log_note "moving sample_x by $move_x"
	
	##### moving xtal to centre of image 704/2 pixels minus the value of X_centre (current position of xtal) and translating in Z and moving to those positions,
	
	set move_z [expr ((352*$scaleFactorx - $X_centre)) ]
	log_note "moving sample_z by $move_z"
	move sample_z by $move_z um
	move gonio_phi by $GBA
	wait_for_devices gonio_phi sample_z sample_y sample_x

}

###moving to higher zoom
move camera_zoom to 0.6
wait_for_devices camera_zoom

set retry 0
set RELIABILITY 1 
while {$RELIABILITY<6} {
    incr retry
    if {$retry >= 4} {
        return -code error "failed after retry $retry times reliability=$RELIABILITY"
    }

	set phi_start $gonio_phi

	foreach {phi} $angleList {
		
		set phi1 [expr $phi_start + $phi]
		move gonio_phi to $phi1
		wait_for_devices gonio_phi
		
		###filename
		set filename ${prefixHigh}_${phi}.jpg

		set filePath [file join $imageDir $filename]
		
		VideoSnapshot $filePath
		log_note snapshot to $filePath
	}

	log_note "Video snapshots done. Please wait a moment while C3D runs"

	####Getting Scale Factor at High Zoom Level
    variable camera_zoom

    set zoomMinScale [getSampleCameraConstant zoomMinScale]
	set zoomMaxScale [getSampleCameraConstant zoomMaxScale]
    set sampleAspectRatio [getSampleCameraConstant sampleAspectRatio]

    set scaleFactorx  [expr $zoomMinScale * 0.5 * exp (log($zoomMaxScale/$zoomMinScale) * $camera_zoom) ]
	set scaleFactory  [expr $scaleFactorx * $sampleAspectRatio ] 

	log_note "$scaleFactorx  $scaleFactory"

	##### running C3D to give values for centring of crystal in pixels
       	set C3D [exec /home/sw/rhel4/C3D/c3d "-scx=${scaleFactorx} -scy=${scaleFactory} $C3DArgsHigh" ]
	log_note "C3D done"
	
	set RELIABILITY [exec cut -c1-130 $resultPathHigh | paste -s | cut -c235-240]
	log_note "Reliability $RELIABILITY -Scored range between 0 (failure) and 9 (likely good centering)"
	
	### getting the values from results file
	
	set TARGET_ANGLE [expr -$phi_start +[exec cut -c1-130 $resultPathHigh | paste -s | cut -c156-165]]
	set RADIUS [exec cut -c1-130 $resultPathHigh | paste -s | cut -c150-155]
	set Y_centre [exec  cut -c1-130 $resultPathHigh | paste -s | cut -c141-150]
	set X_centre [exec cut -c1-130 $resultPathHigh | paste -s | cut -c135-140]
	set GBA [exec  cut -c1-130 $resultPathHigh | paste -s | cut -c205-215]

	#### move vertically, in screen image, first converting pixels to mm, at 0.2 zoom image is 6.876  x 5.195 mm (704 pix by 480 pix)
	
	set move_x [expr ((cos(($gonio_omega+$TARGET_ANGLE) *6.283185307179586 /360))* $RADIUS  ) ]
	move sample_x by $move_x um
	log_note "moving sample_x by $move_x"
	
	set move_y [expr ((sin(($gonio_omega+$TARGET_ANGLE) *6.283185307179586 /360))* $RADIUS * -1 ) ]
	move sample_y by $move_y um
	log_note "moving sample_y by $move_y"

	##### moving xtal to centre of image 704/2 pixels minus the value of X_centre (current position of xtal) and translating in Z and moving to those positions,
	
	set move_z [expr ((352*$scaleFactorx- $X_centre ) ) ]
	log_note "moving sample_z by $move_z"
	
	move sample_z by $move_z um
	move gonio_phi by $GBA
	wait_for_devices gonio_phi sample_z sample_y sample_x

}
#####################################################
##### BIG CATCH #####################################
    } errMsg]} {
        if {$restore_lights} {
            centerRestoreLights
        }
        return -code error $errMsg
    }
#####################################################
    if {$restore_lights} {
        centerRestoreLights
    }

log_note "SUCCESS!"
}

proc VideoSnapshot { filename } { 

    if {[catch {open $filename w 0600} fileId]} {
        log_warning "VideoSnapshot cannot open {$filename}: $fileId"
        return -code error "open_file_to_write_failed"
    }

    set url [::config getSnapshotUrl]
    # append url "&filter=grayscale"
    if { [catch {
        set token [http::geturl $url -channel $fileId -timeout 12000]
        upvar #0 $token state
        set status $state(status)
        set ncode [http::ncode $token]
        set code_msg [http::code $token]
        http::cleanup $token
    } err] } {
        set status "ERROR $err $url"
        set ncode 0
        set code_msg "get url failed for snapshot"
    }
    close $fileId
    if { $status!="ok" || $ncode != 200 } {
        set msg "ERROR videoSnapshot http::geturl status=$status"
        puts $msg
        log_error "videoSnapshot Web error: $status $code_msg"
        return -code error "VideoSnapshot geturl failed"
    }
}
