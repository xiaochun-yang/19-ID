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
##########################################################################
#
#                       Permission Notice
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTA-
# BILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
##########################################################################


# provide the DCSDevice package
package provide DCSVideo 1.0

# load standard packages
package require Iwidgets
package require http

# load other BIW packages
package require DCSUtil
package require DCSComponent
package require DCSMenu
package require ComponentGateExtension

class DCS::Video {
 	inherit ::itk::Widget ::DCS::ComponentGate

	# public variables
	# the URL for grabbing video
	itk_option define -imageUrl imageUrl ImageUrl  "" {
        set m_liveVideo [string equal -length 4 $itk_option(-imageUrl) "http"]
        puts "$this liveVideo=$m_liveVideo"
        image delete $m_rawImage
		image create photo $m_rawImage -palette "256/256/256"
	    restartUpdates 0
    }

	itk_option define -updatePeriod updatePeriod UpdatePeriod 50
	itk_option define -firstUpdateWait firstUpdateWait FirstUpdateWait 5000
	itk_option define -retryPeriod retryPeriod RetryPeriod 30000
	itk_option define -videoParameters videoParameters VideoParameters {}
	itk_option define -videoEnabled videoEnabled VideoEnabled 0
	itk_option define -filters filters Filters ""
	itk_option define -videoSize videoSize VideoSize medium {
        pack forget $itk_component(ring)
        eval pack $itk_component(ring) $itk_option(-packOption)
        pack propagate $itk_component(ring) 0

        ###We do not have image size yet, but we can assume:
        switch -exact -- $itk_option(-videoSize) {
            small {
                set w $m_wSmall
                set h $m_hSmall
            }
            large {
                set w $m_wLarge
                set h $m_hLarge
            }
            default {
                set w $m_wMedium
                set h $m_hMedium
            }
        }
        ### canvas size
        if {!$m_scalingEnabled} {
            if {$w > $m_drawWidth} {
                set c_w $m_drawWidth
                set xv [expr 0.5 - $m_drawWidth / (2.0 * $w)]
            } else {
                set c_w $w
                set xv 0
            }
            if {$h > $m_drawHeight} {
                set c_h $m_drawHeight
                set yv [expr 0.5 - $m_drawHeight / (2.0 * $h)]
            } else {
                set c_h $h
                set yv 0
            }
        } else {
            set xScale [expr double($m_drawWidth)  / $w]
            set yScale [expr double($m_drawHeight) / $h]

            if {$xScale > $yScale} {
                set imgScale $yScale
            } else {
                set imgScale $xScale
            }
            set c_w [expr $w * $imgScale]
            set c_h [expr $h * $imgScale]
            set xv 0
            set yv 0
        }
        $itk_component(ring) configure \
        -width $c_w \
        -height $c_h
        $itk_component(canvas) xview moveto $xv
        $itk_component(canvas) yview moveto $yv
        puts "video resize move xv=$xv yv=$yv"
        ### force next image reset
        set m_xv -100
        set m_yv -100
    }

    ### change this if not NCSC: 704X480, 352X240, 176X120
    itk_option define -largeVideoSize largeVideoSize LargeVideoSize \
    {704 480} {
        foreach {m_wLarge m_hLarge} $itk_option(-largeVideoSize) break

        set m_wMedium [expr $m_wLarge / 2]
        set m_hMedium [expr $m_hLarge / 2]

        set m_wSmall  [expr $m_wMedium / 2]
        set m_hSmall  [expr $m_hMedium / 2]
    }

    itk_option define -packOption packOption PackOption ""

    private variable m_wLarge  704
    private variable m_hLarge  480
    private variable m_wMedium 352
    private variable m_hMedium 240
    private variable m_wSmall  176
    private variable m_hSmall  120

	# protected variables
	public variable _photoName
    private variable m_rawImage
	protected variable afterID ""

    public variable _imageData ""

    private variable _token ""

    #### decide by url starting with http or not
    private variable m_liveVideo 0
	
	# public methods
	public method startUpdate
	public method finishUpdate
    public method takeVideoSnapshot


	#add some private variables which allow the video stream
	#  to not update when the visibility is not right
	protected variable _visibility 1

	private variable _visibilityTrigger ""

	private variable _requesting 0
	private variable _fastUpdate 0
	private variable _encodingCalled 0
    private variable videoMenu

    private variable m_parent_id ""

    public variable m_scale -1

    ### this may not be 704/480 aspect ratio
    private variable m_drawWidth 0
    private variable m_drawHeight 0

    ### canvas view may need shift to show center of image
    private variable m_xv 0.0
    private variable m_yv 0.0

    ### this is 704/480 aspect ratio
    protected variable m_imageWidth  0
    protected variable m_imageHeight 0
    ###SampleVideoWidget needs to access them

    private variable m_scalingEnabled 0
	
    public method handleResize { winID width height } {
        if {$winID != $m_parent_id} return
        puts "video resize: $width $height"

        if {$width < 3 || $height < 3} {
            return
        }

        ### remove frame size
        set m_drawWidth [expr $width - 2]
        set m_drawHeight [expr $height - 2]

        if {$m_scalingEnabled} {
            #### policy:
            #### get the smallest video that is not smaller than
            #### what will be drawn
            if {$m_drawWidth > $m_wMedium && $m_drawHeight > $m_hMedium} {
                set vSize large
            } elseif {$m_drawWidth > $m_wSmall && $m_drawHeight > $m_hSmall} {
                set vSize medium
            } else {
                set vSize small
            }
        } else {
            #### policy:
            #### get the medium in most cases (may be display clipped)
            #### get the large one if the draw area is bigger than it.
            #### get the small one if the draw area is smaller than it.
            if {$m_drawWidth >= $m_wLarge && $m_drawHeight >= $m_hLarge} {
                set vSize large
            } elseif {$m_drawWidth <= $m_wSmall || $m_drawHeight <= $m_hSmall} {
                set vSize small
            } else {
                set vSize medium
            }
        }
        configure -videoSize $vSize

        ### For live video, we wait next frame to use new size,
        #### but for snapshot, we need to redraw it.
        if {!$m_liveVideo} {
            drawImage 1
        }
    }
    private method drawImage { {skipLoad 0} } {
        ### standard image is 352X240. (m_scale = 1)
        ### This is from history.
        ### If you take 704X480 as standard,
        ### you will need to change calibrate
        ### sample camera.

        $_photoName blank

        if {$m_drawWidth < 2 || $m_drawHeight < 2} {
            puts "no draw area yet"
            return
        }

        if {!$m_scalingEnabled} {
            if {!$skipLoad} {
                if {!$m_liveVideo} {
                    $_photoName configure \
                    -file $itk_option(-imageUrl) \
                    -format pgm16_auto_scale
                } else {
                    $_photoName blank
                    $_photoName configure -data $_imageData
                }
                set m_imageWidth  [image width $_photoName]
                set m_imageHeight [image height $_photoName]
            }
        } else {
            if {!$skipLoad} {
                $m_rawImage blank

                if {!$m_liveVideo} {
                    $m_rawImage configure \
                    -file $itk_option(-imageUrl) \
                    -format pgm16_auto_scale
                } else {
                    $m_rawImage blank
                    $m_rawImage configure -data $_imageData
                }
            }

            set rawW [image width $m_rawImage]
            set rawH [image height $m_rawImage]

            #puts "raw image w=$rawW h=$rawH"
            #puts "draw      w=$m_drawWidth h=$m_drawHeight"
            #puts "configure w=[$m_rawImage cget -width] h=[$m_rawImage cget -height]"

            if {$rawW == 0 || $rawH == 0} {
                return
            }

            set xScale [expr double($m_drawWidth)  / $rawW]
            set yScale [expr double($m_drawHeight) / $rawH]

            if {$xScale > $yScale} {
                set imgScale $yScale
            } else {
                set imgScale $xScale
            }

            set m_imageWidth  [expr int($rawW * $imgScale)]
            set m_imageHeight [expr int($rawH * $imgScale)]

            #puts "image scale=$imgScale w=$m_imageWidth h=$m_imageHeight"

            #puts "time=[time {imageResizeBilinear $_photoName $m_rawImage $m_imageWidth $m_imageHeight}]"
            imageResizeBilinear $_photoName $m_rawImage $m_imageWidth $m_imageHeight
            #if {$imgScale >= 0.75} {
            #    puts "time=[time {imageResizeBilinear $_photoName $m_rawImage $m_imageWidth $m_imageHeight}]"
            #} else {
            #    puts "area sample time=[time {imageDownsizeAreaSample $_photoName $m_rawImage $m_imageWidth $m_imageHeight}]"
            #}
        }
        $itk_component(canvas) config \
        -scrollregion "0 0 $m_imageWidth $m_imageHeight"

        #### check to see if need to move the image to show center
        if {$m_imageWidth > $m_drawWidth} {
            set xv [expr 0.5 - $m_drawWidth / (2.0 * $m_imageWidth)]
        } else {
            set xv 0
        }
        if {$m_imageHeight > $m_drawHeight} {
            set yv [expr 0.5 - $m_drawHeight / (2.0 * $m_imageHeight)]
        } else {
            set yv 0
        }
        if {$m_xv != $xv} {
            set m_xv $xv
            $itk_component(canvas) xview moveto $xv
            puts "xv to $xv"
            puts "image w=$m_imageWidth draw w=$m_drawWidth"
        }
        if {$m_yv != $yv} {
            set m_yv $yv
            $itk_component(canvas) yview moveto $yv
            puts "yv to $yv"
            puts "image h=$m_imageHeight draw h=$m_drawHeight"
        }

        #puts "checking scale"
        set newScale [expr double($m_imageWidth) / $m_wMedium]
        if {$newScale != $m_scale} {
            set m_scale $newScale
            puts "new scale: $m_scale"

            if {$mark_x >= 0 && $mark_y >= 0 && \
            $m_scale != $mark_scale && $mark_scale > 0.0} {
                set scaleFactor [expr $m_scale / $mark_scale]
                set x [expr $mark_x * $scaleFactor]
                set y [expr $mark_y * $scaleFactor]
	            set deltaX [expr $x - $mark_x]
	            set deltaY [expr $y - $mark_y]
	            $itk_component(canvas) move $mark_tag $deltaX $deltaY
                set mark_x $x
                set mark_y $y
                set mark_scale $m_scale
            }
            ### We put resizeCallback here so that it will be called after
            ### new sized image has been drawn.
            resizeCallback
        }
    }

	public method addChildVisibilityControl
	public method handleParentVisibility
	public method restartUpdates
	public method updateVideoRate
	public method addUpdateSpeedInput
	private method cancelUpdates
    
    public method handleRightClick
	public method handleStaffChange 
    public method handleMiddleClick
    public method handleMiddleDoubleClick
    private variable grayscaleOn 0
    private variable exp2Xon 0
    private variable gamma15on 0
    private variable gamma16on 0
    private variable equalizeOn 0
    private variable edgeOn 0
    private variable curveOn 0
    private variable constructed 0
    private variable mark_x      -1
    private variable mark_y      -1
    private variable mark_scale  1.0
    private variable mark_staff  0
	private variable mark_width	 20
	private variable mark_height 20
	private variable mark_color  red
    private variable mark_tag    cursor_mark
    public method updateGrayscale
    public method updateExp2x
    public method updateGamma15
    public method updateGamma16
    public method updateEqualize
    public method updateEdge
    public method updateCurve
    protected method updateFilters


    ##### overridable
    public method handleVideoClick {x y} {}
    public method resizeCallback { } { }
    public method handleVideoMotion {x y} {}
    public method handleVideoRelease {x y} {}

	constructor { args } {
        global gLibraryStatus

        if {[::config getVideoScalingEnabled] \
        && $gLibraryStatus(tcl_c_libs)} {
            set m_scalingEnabled 1
        } else {
            set m_scalingEnabled 0
        }

        itk_component add ring {
            frame $itk_interior.ring
        } {
        }
	
		itk_component add canvas {
			canvas $itk_component(ring).c \
            -scrollregion {0 0 352 240}
		} {
		}

        #pack $itk_component(canvas) -expand 1 -fill both
        #pack $itk_component(ring) -expand 1 -fill both

		#make sure that the Img library was loaded successfully
		if { [ImgLibraryAvailable] } {
			# create the Tcl photo
			set _photoName [image create photo -palette "256/256/256"]
			set m_rawImage [image create photo -palette "256/256/256"]
			
			# create an image on the canvas displaying the photo
            $itk_component(canvas) create image 0 0 \
            -image $_photoName \
            -anchor nw \
            -tags video
		}

		#create an object that allows for registration in events that will
		#  cause the video to update faster
		set _fastUpdate ::DCS::Video::[DCS::ComponentORGate \#auto]
		#set _fastUpdate [DCS::ComponentORGate \#auto]
		set videoMenu [DCS::PopupMenu \#auto]
		$videoMenu addLabel title -label "Filters"
		$videoMenu addCheckbox grayscale -label "Grayscale" -callback "$this updateGrayscale" -value 0
		$videoMenu addCheckbox exp2x -label "Exposure 2x" -callback "$this updateExp2x" -value 0
       		$videoMenu addCheckbox gamma15 -label "Gamma 1.5" -callback "$this updateGamma15" -value 0
        	$videoMenu addCheckbox gamma16 -label "Gamma 1.6" -callback "$this updateGamma16" -value 0
        	$videoMenu addCheckbox equalize -label "Equalize Colors" -callback "$this updateEqualize" -value 0
        	$videoMenu addCheckbox edge -label "Edge Tracing" -callback "$this updateEdge" -value 0
        	$videoMenu addCheckbox curve -label "Custom Color Curve" -callback "$this updateCurve"
		bind $itk_component(canvas) <Button-3> "$this handleRightClick"
		bind $itk_component(canvas) <Button-2> "$this handleMiddleClick %x %y"
		bind $itk_component(canvas) <B2-Motion> "$this handleMiddleClick %x %y"
		bind $itk_component(canvas) <Double-2> "$this handleMiddleDoubleClick"
		eval itk_initialize $args
		::mediator register $this $_fastUpdate gateOutput updateVideoRate

puts "_fastUpdate = $_fastUpdate\n"

        ### do not bind only to the image.  We draw cross and box on the image.
        ### it will not trigger the event if user clicks on the lines.
		bind $itk_component(canvas) <Button-1> "$this handleVideoClick %x %y"
		bind $itk_component(canvas) <B1-Motion> "$this handleVideoMotion %x %y"
		bind $itk_component(canvas) <B1-ButtonRelease> "$this handleVideoRelease %x %y"

		announceExist

        pack $itk_component(canvas) -expand 1 -fill both
        eval pack $itk_component(ring) -expand 1 -fill both $itk_option(-packOption)

        set m_parent_id $itk_interior
        bind $m_parent_id <Configure> "$this handleResize %W %w %h"

        ::mediator register $this ::dcss staff handleStaffChange
        set constructed 1
	}

	destructor {
		destroy $_photoName
		destroy $m_rawImage
		delete object $_fastUpdate

		announceDestruction

		cancelUpdates
	}
}

body DCS::Video::updateVideoRate { - targetStatus - value -} {
#yangx
#	if { $targetStatus == 1 && $value == 1 && $m_scale <= 1} 
        if { $targetStatus == 1 && $value == 1 } {
		$this configure -updatePeriod 500 -videoParameters "&resolution=medium"
		#puts "In if updateVideoRate=50\n"
	} else {
		$this configure -updatePeriod 20 -videoParameters "&resolution=high"
		#puts "In else updateVideoRate=1000 value=$value targetStatus=$targetStatus m_scale=$m_scale\n"
	}
}

body DCS::Video::handleRightClick { } {
    $videoMenu post
}

body DCS::Video::handleMiddleClick { x y } {
    if {!$mark_staff} {
        return
    }

    set x [$itk_component(canvas) canvasx $x]
    set y [$itk_component(canvas) canvasy $y]

    if {$mark_x < 0 || $mark_y < 0} {
        ### draw mark
	    set x0 [expr $x - $mark_width / 2.0]
	    set x1 [expr $x + $mark_width / 2.0]
	    set y0 [expr $y - $mark_height / 2.0 ]
	    set y1 [expr $y + $mark_height / 2.0 ]
	
	    $itk_component(canvas) create line $x $y0 $x $y1 \
        -fill $mark_color -width 1 -tag $mark_tag
	    $itk_component(canvas) create line $x0 $y $x1 $y \
        -fill $mark_color -width 1 -tag $mark_tag
    } else {
        ### move mark
	    set deltaX [expr $x - $mark_x]
	    set deltaY [expr $y - $mark_y]
	
	    $itk_component(canvas) move $mark_tag $deltaX $deltaY
    }
	set mark_x $x
	set mark_y $y
    set mark_scale $m_scale
}
body DCS::Video::handleMiddleDoubleClick { } {
    if {!$mark_staff} {
        return
    }
    $itk_component(canvas) delete $mark_tag
    set mark_x -1
    set mark_y -1
}
body ::DCS::Video::handleStaffChange {- targetReady_ alias value_ -} {

	if { ! $targetReady_ } return
    if {$mark_staff == $value_} return

	set mark_staff $value_

    if {$mark_staff != "1"} {
	    $itk_component(canvas) delete $mark_tag
        set mark_x -1
        set mark_y -1
    }
}


#This public method adds objects and their status which trigger an
#  increase of the speed of the video update.
body DCS::Video::addUpdateSpeedInput { trigger } {
	$_fastUpdate addInput $trigger
}

body DCS::Video::startUpdate {} {

	#guard against no Img Library
	if { ! [ImgLibraryAvailable] } return

#	puts "VIDEO: startUpdate $_requesting   $afterID"
#        puts "imageUrl: $itk_option(-imageUrl)"
    cancelUpdates

    if {!$m_liveVideo} {
		set _requesting 0
		if { $_visibility && $itk_option(-videoEnabled) } {
            if {[catch drawImage errMsg]} {
                log_error showSnapshot failed: $errMsg
                restartUpdates $itk_option(-retryPeriod)
            }
        }
        return
    }

	# clear the evlnt id
	set afterID 0

	if { ! $_requesting && $itk_option(-imageUrl) != ""} { 
		if { $_visibility && $itk_option(-videoEnabled) } {
			#puts "VIDEO $this Visible"
			
            if {$_token != ""} {
                catch {http::cleanup $_token}
                set _token ""
            }

			# grab the next image from the video server
			if {[catch {
                http::geturl ${itk_option(-imageUrl)}${itk_option(-videoParameters)}&size=${itk_option(-videoSize)}${itk_option(-filters)} \
                -binary 1 \
                -timeout 10000 \
			    -command "$this finishUpdate"
            } _token]} {
				set _requesting 0
                log_error updating video: $_token
                puts "updating video: $_token"
                puts "imageUrl: $itk_option(-imageUrl)"

                set _token ""
				
                #here is for switch tabs or open bluice while server if offline
                restartUpdates $itk_option(-retryPeriod)
                puts "VIDEO: retry after $itk_option(-retryPeriod) seconds"
			} else {
			    set _requesting 1
            }

		} else {
		}
	} else {
		#puts "VIDEO ********** already requesting ************"
	}
}


body DCS::Video::finishUpdate { token } {
	#puts "VIDEO: finishUpdate: $_requesting "
	set _requesting 0

    set status [http::status $token]
    if {$status != "ok"} {
        puts "VIDEO: geturl status not ok: $status"
        restartUpdates $itk_option(-retryPeriod)
        puts "VIDEO: retry after $itk_option(-retryPeriod) seconds"
        return
    }
	# convert the image encoding to standard Tcl encoding
	if { [catch { set _imageData [http::data $token] } errorResult ] } {
		puts "VIDEO: got error $errorResult"
	}
	
    if { !$_encodingCalled } {
        set _imageData [encoding convertto iso8859-1 $_imageData]
        set _encodingCalled 1
    }


    set failed 0
    if {[catch drawImage errMsg]} {
        puts "drawImage error: $errMsg"
        set failed 1
    }
	
	# schedule the next update of the video image
	#set afterID [after $itk_option(-updatePeriod) "$this startUpdate"]

    if {$m_liveVideo || $failed} {
	    restartUpdates $itk_option(-updatePeriod)
    }
}

configbody DCS::Video::updatePeriod {
	restartUpdates 0
}

configbody DCS::Video::videoEnabled {
	restartUpdates 0
}

configbody DCS::Video::firstUpdateWait {
	
	# schedule first update
	restartUpdates $itk_option(-firstUpdateWait)
}


configbody DCS::Video::filters {
	restartUpdates 0
}
body DCS::Video::updateExp2x { value } {
    set exp2Xon $value 
    updateFilters
}

body DCS::Video::updateGrayscale { value } {
    set grayscaleOn $value
    updateFilters
}

body DCS::Video::updateGamma15 { value } {
    set gamma15on $value
    updateFilters
}

body DCS::Video::updateGamma16 { value } {
    set gamma16on $value
    updateFilters
}

body DCS::Video::updateEqualize { value } {
    set equalizeOn $value
    updateFilters
}

body DCS::Video::updateEdge { value } {
    set edgeOn $value
    updateFilters
}

body DCS::Video::updateCurve { value } {
    set curveOn $value
    updateFilters
}

body DCS::Video::updateFilters {} {
   set beamline [::config getConfigRootName]
   set filters ""
   if { $exp2Xon } {
      append filters "2xExposure;"
   }

   if { $curveOn } {
      append filters "curve;"
   }

   if { $grayscaleOn } {
      append filters "grayscale;"
   }

   if { $equalizeOn } { 
      append filters "equalize;"
   }

   if { $edgeOn } {
      append filters "edge;"
   }

   if { $gamma15on } {
      append filters "gamma15;"
   }
   if { $gamma16on } {
      append filters "gamma16;"
   }
   if { $constructed } {
      $this configure -filters "&filter=$filters"
   }
}
body DCS::Video::addChildVisibilityControl { widget attribute visibleTrigger } {
	
	set _visibilityTrigger $visibleTrigger
	
	::mediator register $this ::$widget $attribute handleParentVisibility
}


body DCS::Video::handleParentVisibility { - targetReady - value -} {
	
	if { $targetReady == 0 } {
		set _visibility 0
	} elseif { $value != $_visibilityTrigger } {
		set _visibility 0
	} else {
		set _visibility 1
	    set _requesting 0
		restartUpdates 0
	}
}

body DCS::Video::cancelUpdates {} {
	if { $afterID != ""} {
		# cancel the currently scheduled update of the video

		#puts "VIDEO: AFTER $afterID"

		after cancel $afterID
        set afterID ""
	} 
}

body DCS::Video::restartUpdates { time } {
    cancelUpdates

	# schedule an update of the video immediately
	set afterID [after $time "$this startUpdate"]

	#puts "VIDEO restartUpdates $afterID  $time"
}



body DCS::Video::takeVideoSnapshot { } {
    set user [::dcss getUser]

    set types [list [list JPEG .jpg]]
    set beamline [::config getConfigRootName]
    set time [clock format [clock seconds] -format "%H_%M_%S"]

    set fileName [tk_getSaveFile \
    -initialdir /data/$user \
    -filetypes $types \
    -defaultextension ".jpg" \
    -initialfile "${beamline}_video_$time.jpg" 
    ]

    if {$fileName == ""} return

    if {[catch {open $fileName w} ch]} {
        log_error failed to open file $fileName to write image: $ch
        return
    }
    if {[catch {
        fconfigure $ch -translation binary -encoding binary
        puts -nonewline $ch $_imageData
    } errMsg]} {
        log_error failed to write image to the file $fileName: $errMsg
    }
    close $ch
    log_warning snapshot saved to $fileName
}



##### to fix bug 941: web access hang bluice
##### we reduce the repeated web access by
##### using singleton to get the information
##### once from the webserver
class DCS::AsyncWebData {
    inherit ::DCS::Component

    public variable timeout      10000
    public variable retryDelay   10000

    public proc getObject { url {timeout 10000} {delay 10000} }
    public proc start { } {
        puts "AsyncWebData::start called"
        if {[array exists gObject]} {
            set urlList [array names gObject]
            foreach url $urlList {
                $gObject($url) retrieve
            }
        }
    }

    public method getData { } { return $m_data }

    public method handleUrlCallback { token }

    public method retrieve { }

    public method refresh { }

    private variable m_data ""
    private variable m_url ""
    private variable m_retryTimes 0
    ### done waiting retry_delay retrying
    private variable m_status done
    private variable m_token ""

    private common gObject

    constructor { url args } {
        DCS::Component::constructor { data getData }
    } {
        set m_url $url
        eval configure $args
        announceExist
    }
}
body DCS::AsyncWebData::getObject { url {timeout 10000} {delay 10000} } {
    if {![info exists gObject($url)]} {
        set gObject($url) [[namespace current] ::#auto $url \
        -timeout $timeout \
        -retryDelay $delay]
    }

    set nameList [array names gObject]
    set ll [llength $nameList]
    puts "number of AysncWebData: $ll"
    return $gObject($url)
}
body DCS::AsyncWebData::handleUrlCallback { token } {
    puts "handleUrlCallback $token"

    set status [http::status $token]
    if {$status == "ok"} {
	    set m_data [http::data $token]
        set m_status done
        if {$m_retryTimes > 0} {
            puts "GOT DATA in retry $m_retryTimes for $m_url"
        }
        updateRegisteredComponents data
    } else {
        puts "geturl failed: $status delay for retry"
        set m_status retry_delay
        incr m_retryTimes
        after $retryDelay "$this retrieve"
    }
    return 0
}
body DCS::AsyncWebData::retrieve { } {
    switch -exact -- $m_status {
        done        { set m_status waiting }
        retry_delay { set m_status retrying }
        default {
            puts "wrong status {$m_status} to retrieve"
            return
        }
    }

    if {$m_token != ""} {
        if {[catch {http::cleanup $m_token} errMsg]} {
            puts "failed to cleanup $m_token: $errMsg"
        }
    }
    if {[catch {
        http::geturl $m_url \
        -timeout $timeout \
        -command "$this handleUrlCallback"
    } m_token]} {
        #puts "AsyncWebData::retrieve failed: $m_token"
        set m_token ""
    }
}
body DCS::AsyncWebData::refresh { } {
    if {$m_status != "done"} {
        puts "skip refresh, status: $m_status"
        return
    }
    retrieve
}


class DCS::PresetVideoWidget {
#	inherit ::itk::Widget
	inherit ::DCS::ComponentGateExtension
	# public variables
	itk_option define -presetUrl presetUrl PresetUrl ""
	itk_option define -moveRequestUrl moveRequestUrl MoveRequestUrl ""
	itk_option define -textUrl textUrl TextUrl ""
	itk_option define -channelArgs channelArgs ChannelArgs ""

	itk_option define -controlSystem controlsytem ControlSystem "dcss"

	# protected variables
   protected variable m_staff ""
   private variable m_realPresetName
   private variable m_extraCounter 0

   private variable m_logger

	# public methods
	public method updateVideoRate

	public method moveToPreset
	public method updatePresetButtons
	public method addChildVisibilityControl
	public method addUpdateSpeedInput
	public method handleStaffChange 
   
    public method addExtraWidget { widget args } {
        set extraName extra$m_extraCounter
        itk_component add $extraName {
            eval $widget $itk_component(control).$extraName $args
        } {
        }
        pack $itk_component($extraName)
        incr m_extraCounter
    }

   private method requestPresets

	# constructor
	constructor { args } {

        set m_logger [DCS::Logger::getObject]
        
		itk_component add control {
			frame $itk_interior.c
		}


		itk_component add presetEntry {
			DCS::MenuEntry $itk_component(control).e -showEntry 0 \
			-activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font -entryWidth
		}

		$itk_component(presetEntry) setValue NoSelection
		$itk_component(presetEntry) configure -fixedEntry "Select Preset"
		$itk_component(presetEntry) configure -state normal

		# create the video image
		itk_component add video {
			DCS::Video $itk_interior.video
		} {
			keep -imageUrl
			keep -videoParameters -updatePeriod -videoEnabled
		}
		
		itk_component add snapshot {
		    button $itk_component(control).snapshot \
			-text "Video Snapshot" \
			-width 13 -command "$itk_component(video) takeVideoSnapshot" 
		} {
		}

		# evaluate configuration parameters	
		eval itk_initialize $args

		pack $itk_component(control) -side left -anchor n -padx 0 -ipadx 0
		pack $itk_component(presetEntry) -anchor nw -side top -padx 0 -ipadx 0 -ipady 0 -pady 0
		pack $itk_component(snapshot) -anchor nw -side top -padx 5 -ipadx 0 -ipady 0 -pady 0
		pack $itk_component(video) -side left -padx 0 -ipadx 0 -expand yes -fill both

      set m_staff [::dcss getStaff]

		::mediator register $this ::$itk_component(presetEntry) -value moveToPreset
      ::mediator register $this ::dcss staff handleStaffChange


		::mediator announceExistence $this
	}

}

body ::DCS::PresetVideoWidget::handleStaffChange {- targetReady_ alias value_ -} {

	if { ! $targetReady_ } return
   if {$m_staff == $value_} return

	set m_staff $value_
   requestPresets
}





configbody DCS::PresetVideoWidget::presetUrl {

   requestPresets
}

configbody DCS::PresetVideoWidget::channelArgs {

   requestPresets
}

body DCS::PresetVideoWidget::requestPresets {} {

	if {$itk_option(-presetUrl) == "" } return
	if {$itk_option(-channelArgs) == "" } return

   set presetRequestUrl $itk_option(-presetUrl)$itk_option(-channelArgs)
   #puts $presetRequestUrl 

    set obj [DCS::AsyncWebData::getObject $presetRequestUrl]
    ::mediator register $this $obj data updatePresetButtons
    #####TODO: add unregister later
}

body DCS::PresetVideoWidget::updatePresetButtons { - ready_ - contents_ - } {

	#puts "VIDEO: updatePresetButtons"
    if {!$ready_} return
	
	# get the result of the http request
	set result $contents_

	#puts "VIDEO: preset Result : $result <done>"
	set presetList ""

	set nextEqualSign [string first = $result]
    set nextLine [string first "\n" $result]
    
    #puts $nextEqualSign
    #puts $nextLine

    if {$nextEqualSign > $nextLine} {
        set result [string replace $result 0 $nextLine ""]
    } 

	# parse the result for the token names and create buttons for each
	if { [string first < $result] == -1 } {

		# replace all equal signs with spaces
		while { [set nextEqualSign [string first = $result]] != -1 } {
			set result [string replace $result $nextEqualSign $nextEqualSign " "] 
		}

		# count the tokens to parse
		set tokenCount [llength $result]
		

		for { set i 1 } { $i < $tokenCount } { incr i 2 } {
			
			set presetName [lindex $result $i]
         #puts "PRESET $presetName"
         #user presets start with 0 by convention at ssrl
         if { [string index $presetName 0] == "0" } {
            set cleanPreset [string range $presetName 1 end]
            set m_realPresetName($cleanPreset) $presetName
            lappend presetList $cleanPreset
         } else {
            if { $m_staff } {
               set m_realPresetName($presetName) $presetName
               lappend presetList $presetName
            }
         }
		}		
	}

   #puts "PRESET LIST $presetList"

	$itk_component(presetEntry) configure -menuChoices $presetList
}


body DCS::PresetVideoWidget::moveToPreset { - targetReady - value -} {

	if { $targetReady == 0 || $value == "NoSelection"} { return }

	if { $itk_option(-moveRequestUrl) != "" } {
		
#		puts "VIDEO: changing preset to $value"

      set presetName $m_realPresetName($value)

		# request the specified preset
		http::geturl ${itk_option(-moveRequestUrl)}$presetName -timeout 60000
		
		if {$itk_option(-textUrl) != "" } {
			# change the title text on the video to match
			http::geturl ${itk_option(-textUrl)}$value -timeout 60000
			#puts "VIDEO: ${itk_option(-textUrl)}&text=$value$itk_option(-channelArgs)"
		}
	}
}

#thin wrapper for the video enable
body DCS::PresetVideoWidget::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

body DCS::PresetVideoWidget::addUpdateSpeedInput { trigger } {
	$itk_component(video) addUpdateSpeedInput $trigger
}



class DCS::VideoSystemExplorer {
	inherit ::DCS::ComponentGateExtension
	# public variables
	itk_option define -baseVideoSystemUrl baseVideoSystemUrl BaseVideoSystemUrl ""
	itk_option define -controlSystem controlsytem ControlSystem "dcss"

	# protected variables
   private variable m_currentCamera
   private variable m_realPresetName

    private variable m_tokenCameraList ""
    private variable m_tokenPreset ""

   private variable m_logger

	# public methods
	public method selectCameraList
	public method selectCamera
	public method moveToPreset
	public method updateCameraList
	public method updateCameraListMenu
	public method updatePresetList
	public method updatePresetButtons
	public method updateVideoRate
	public method addChildVisibilityControl
	public method addUpdateSpeedInput
   private method requestPresets

	# constructor
	constructor { args } {

        set m_logger [DCS::Logger::getObject]
        
		itk_component add control {
			frame $itk_interior.c
		}

		itk_component add cameraSelection {
			DCS::MenuEntry $itk_component(control).c -showEntry 0 \
			-activeClientOnly 0 -systemIdleOnly 0  -entryWidth 30 -entryMaxLength 30
		} {
			keep -font
		}

		itk_component add presetEntry {
			DCS::MenuEntry $itk_component(control).e -showEntry 0 \
			-activeClientOnly 0 -systemIdleOnly 0 -entryWidth 20
		} {
			keep -font
		}

		# create the video image
		itk_component add video {
			DCS::Video $itk_interior.video
		} {
			keep -imageUrl
			keep -videoParameters -updatePeriod -videoEnabled
		}

		itk_component add snapshot {
		    button $itk_component(control).snapshot \
			-text "Video Snapshot" \
			-width 15 -command "$itk_component(video) takeVideoSnapshot" 
		} {
		}

		$itk_component(presetEntry) setValue NoSelection
		$itk_component(presetEntry) configure -fixedEntry "Select Camera"
		$itk_component(presetEntry) configure -state normal

		$itk_component(presetEntry) setValue NoSelection
		$itk_component(presetEntry) configure -fixedEntry "Select Preset"
		$itk_component(presetEntry) configure -state normal


		# evaluate configuration parameters	
		eval itk_initialize $args


		pack $itk_component(control) -side left -anchor n -padx 0 -ipadx 0
		pack $itk_component(cameraSelection) -anchor n -side top -padx 0 -ipadx 0 -ipady 0 -pady 0
		pack $itk_component(presetEntry) -anchor n -side top -padx 0 -ipadx 0 -ipady 0 -pady 0
		pack $itk_component(snapshot) -anchor n -side top -padx 0 -ipadx 0 -ipady 0 -pady 0
		pack $itk_component(video) -side left -padx 0 -ipadx 0 -expand yes -fill both

		::mediator register $this ::$itk_component(cameraSelection) -value selectCamera
		::mediator register $this ::$itk_component(presetEntry) -value moveToPreset

		::mediator announceExistence $this
      selectCameraList
	}

}

body DCS::VideoSystemExplorer::selectCameraList {} {
   set beamline [::config getConfigRootName]
   set cameraListUrl "$itk_option(-baseVideoSystemUrl)/control.html?method=showCameraList&group=$beamline"

   #puts $cameraListUrl

    if {$m_tokenCameraList != ""} {
	    if {[catch {http::cleanup $m_tokenCameraList} errorResult ]}  {
		    puts "error cleaning http token $m_tokenCameraList:  $errorResult"
	    }
    }

	if {[catch {
      http::geturl $cameraListUrl -timeout 10000 -command "$this updateCameraList"} m_tokenCameraList]} {
      log_error updating presets: $m_tokenCameraList
        set m_tokenCameraList ""
	}


   #set obj [DCS::AsyncWebData::getObject $cameraListRequestUrl 1000 1000]
   #::mediator register $this $obj data updateCameraListMenu
}


body DCS::VideoSystemExplorer::updateCameraList { token } {

    set status [http::status $token]
    if {$status != "ok"} {
        puts "updateCameraList: geturl status not ok: $status"
        return
    }

	if { [catch { set _contents [http::data $token] } errorResult ] } {
		puts "updateCameraList: got error $errorResult"
	}

   updateCameraListMenu - 1 - $_contents -
}

body DCS::VideoSystemExplorer::updateCameraListMenu { - ready_ - contents_ - } {
   if {!$ready_} return
	
	# get the result of the http request
	set result $contents_

   #puts "camera list: $result"

	set cameraList ""
   foreach camera $result {
      lappend cameraList $camera
   }

	$itk_component(cameraSelection) configure -menuChoices $cameraList 
   $itk_component(cameraSelection) selectMenuItem [lindex $cameraList 0] 
}

body DCS::VideoSystemExplorer::requestPresets {} {

	set presetRequestUrl "$itk_option(-baseVideoSystemUrl)/control.html?method=getPresetList&stream=$m_currentCamera"
   #puts $presetRequestUrl 

    if {$m_tokenPreset != ""} {
        if {[catch {http::cleanup $m_tokenPreset} errMsg]} {
            puts "error clean up http $m_tokenPreset: $errMsg"
        }
    }

	if {[catch {
      http::geturl $presetRequestUrl -timeout 10000 -command "$this updatePresetList"} m_tokenPreset]} {
      log_error updating presets: $m_tokenPreset
        set m_tokenPreset ""
	}

   #set obj [DCS::AsyncWebData::getObject $presetRequestUrl]
   #::mediator register $this $obj data updatePresetButtons
    #####TODO: add unregister later
}

body DCS::VideoSystemExplorer::updatePresetList { token } {
    set status [http::status $token]
    if {$status != "ok"} {
        puts "updatePresetList: geturl status not ok: $status"
        return
    }

	if { [catch { set _contents [http::data $token] } errorResult ] } {
		puts "updatePresetList: got error $errorResult"
	}

   updatePresetButtons - 1 - $_contents -
}

body DCS::VideoSystemExplorer::updatePresetButtons { - ready_ - contents_ - } {

	#puts "VIDEO: updatePresetButtons"
    if {!$ready_} return
	
	# get the result of the http request
	set result $contents_

	#puts "VIDEO: preset Result : $result <done>"
	set presetList ""

	set nextEqualSign [string first = $result]
    set nextLine [string first "\n" $result]
    
    #puts $nextEqualSign
    #puts $nextLine

    if {$nextEqualSign > $nextLine} {
        set result [string replace $result 0 $nextLine ""]
    } 

	# parse the result for the token names and create buttons for each
	if { [string first < $result] == -1 } {

		# replace all equal signs with spaces
		while { [set nextEqualSign [string first = $result]] != -1 } {
			set result [string replace $result $nextEqualSign $nextEqualSign " "] 
		}

		# count the tokens to parse
		set tokenCount [llength $result]
		

		for { set i 1 } { $i < $tokenCount } { incr i 2 } {
			
			set presetName [lindex $result $i]
         #puts "PRESET $presetName"
         #user presets start with 0 by convention at ssrl
         if { [string index $presetName 0] == "0" } {
            set cleanPreset [string range $presetName 1 end]
            set m_realPresetName($cleanPreset) $presetName
            lappend presetList $cleanPreset
         } else {
            set m_realPresetName($presetName) $presetName
            lappend presetList $presetName
         }
		}		
	}

   #puts "PRESET LIST $presetList"

	$itk_component(presetEntry) configure -menuChoices $presetList
}



body DCS::VideoSystemExplorer::selectCamera { - targetReady - value -} {


   puts $value
	if { $targetReady == 0 || $value == "NoSelection"} { return }

   set m_currentCamera $value 
   set imageUrl "${itk_option(-baseVideoSystemUrl)}/video.html?stream=$m_currentCamera"
   puts "YANGX imageUrl=$imageUrl"
   $itk_component(video) configure -imageUrl $imageUrl
   requestPresets
}


body DCS::VideoSystemExplorer::moveToPreset { - targetReady - value -} {

	if { $targetReady == 0 || $value == "NoSelection"} { return }

   set presetName $m_realPresetName($value)
	# request the specified preset
	http::geturl "${itk_option(-baseVideoSystemUrl)}/control.html?method=gotoPreset&stream=${m_currentCamera}&presetName=$presetName" -timeout 60000
}


#thin wrapper for the video enable
body DCS::VideoSystemExplorer::addChildVisibilityControl { args} {
	eval $itk_component(video) addChildVisibilityControl $args
}

body DCS::VideoSystemExplorer::addUpdateSpeedInput { trigger } {
	$itk_component(video) addUpdateSpeedInput $trigger
}



