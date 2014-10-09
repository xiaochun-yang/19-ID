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

class ::DCS::TicketForImage {
    private common s_instance ""
    private common LIFE_SPAN 59
    public proc getInstance { } {
        if {$s_instance == ""} {
            set s_instance [[namespace current] ::#auto]
        }
        return $s_instance
    }

    public method getTicket { imagePath sessionId }

    private method cleanup { }

    private variable m_map

    constructor { } {
        array set m_map [list]
    }
    destructor {
        array unset m_map
    }
}
body ::DCS::TicketForImage::getTicket { imagePath sessionId } {
    set needAdd 0
    if {![info exists m_map($imagePath)]} {
        set needAdd 1
    } else {
        foreach {timeStamp ticket} $m_map($imagePath) break
        set now [clock seconds]
        if {$now > $timeStamp + $LIFE_SPAN} {
            set needAdd 1
        }
    }

    if {$needAdd} {
        if {[catch cleanup errMsg]} {
            puts "DEBUG: cleanup failed: $errMsg"
        }
        set ticket [getTicketFromSessionId $sessionId]
        if {[string first invalid $ticket] < 0} {
            set timeStamp [clock seconds]
            set m_map($imagePath) [list $timeStamp $ticket]
            #puts "DEBUG: added ticket to map for $imagePath"
        } else {
            log_error failed to get ticket for diffraction image
            ## still return the invalid ticket
        }
    } else {
        #puts "DEBUG: no add"
    }
    return $ticket
}
body ::DCS::TicketForImage::cleanup { } {
    set pathList [array names m_map]
    #puts "DEBUG: ticek map length [llength $pathList]"
    set now [clock seconds]
    set tsThreshold [expr $now - $LIFE_SPAN]
    foreach path $pathList {
        set timeStamp [lindex $m_map($path) 0]
        if {$timeStamp < $tsThreshold} {
            unset m_map($path)
            #puts "DEBUG removed $path"
        }
    }
}

###################################################################
#
# DiffImageViewer class
#
# A class that creates an image canvas and a control panel convas
# in a given frame window. The control panel allows the user to 
# adjust zoom/pan/contrast, change session id and load a new image.
# 
###################################################################

package provide BLUICEDiffImageViewer 1.0

# load standard packages
package require Iwidgets
package require BWidget

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSEntry
package require DCSBitmaps
package require DCSMenuButton
package require DCSImperson


class DiffImageViewer {
     inherit ::itk::Widget

    # public data members
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    itk_option define -scaleBrightness scaleBrightness ScaleBrightness 1 {
        if {$itk_option(-scaleBrightness)} {
            $itk_component(contrast) configure \
            -decreaseCommand "$this scale_contrast_max_by 0.5" \
            -increaseCommand "$this scale_contrast_max_by 2" \
        } else {
            $itk_component(contrast) configure \
            -decreaseCommand "$this change_contrast_max_by -100" \
            -increaseCommand "$this change_contrast_max_by 100" \
        }
    }

    itk_option define -brightness brightness Brightness 400 {
        set m_contrastMax $itk_option(-brightness)
        $itk_component(contrast) setValue $m_contrastMax 1
    }

    #diffraction image viewer ports and host
    itk_option define -imageServerHost imageServerHost ImageServerHost "" {
        handle_filename_entry
    }
    itk_option define -imageServerHttpPort imageServerHttpPort ImageServerHttpPort "" {
        handle_filename_entry
    }

    itk_option define -showPause showPause ShowPause 0 {
        if {$itk_option(-showPause)} {
            pack $itk_component(pause) -side right
        } else {
            pack forget $itk_component(pause)
        }
    }

    itk_option define -orientation orientation Orientation portrait {
        set all [grid slaves $itk_interior]
        if {$all != ""} {
            eval grid forget $all
        }

        if {$itk_option(-orientation) == "landscape"} {
            grid columnconfigure $itk_interior 0 -weight 1 
            grid columnconfigure $itk_interior 1 -weight 0 
            grid rowconfigure $itk_interior 0 -weight 1 
            grid rowconfigure $itk_interior 1 -weight 1 
            grid rowconfigure $itk_interior 2 -weight 1 
            grid rowconfigure $itk_interior 3 -weight 1 

            grid $itk_component(imageCanvas) \
            -column 0 -row 0 -rowspan 4 -sticky news
            grid $itk_component(fileF) \
            -column 0 -row 4 -columnspan 2 -sticky nw

            grid $itk_component(contrast) -column 1 -row 0 -sticky s
            grid $itk_component(arrowPad) -column 1 -row 1 -sticky ns
            grid $itk_component(zoom)     -column 1 -row 2 -sticky n
            grid $itk_component(openWith)  -column 1 -row 3 -sticky n
        } else {
            grid rowconfigure $itk_interior 0 -weight 1 
            grid columnconfigure $itk_interior 0 -weight 1 
            grid columnconfigure $itk_interior 1 -weight 1 
            grid columnconfigure $itk_interior 2 -weight 1 
            grid columnconfigure $itk_interior 3 -weight 1

            grid $itk_component(imageCanvas) \
            -column 0 -row 0 -sticky news -columnspan 4

            grid $itk_component(contrast) -column 0 -row 1 -sticky e
            grid $itk_component(arrowPad) -column 1 -row 1 -sticky ew
            grid $itk_component(zoom)     -column 2 -row 1 -sticky w
            grid $itk_component(openWith)  -column 3 -row 1 -sticky w

            grid $itk_component(fileF) \
            -column 0 -row 2 -rowspan 3 -columnspan 4  -sticky nw
        }
    }

    public method handlePause { } {
        if {!$gCheckButtonVar($this,pause)} {
            $itk_component(fileEntry) setValue $m_ctsLastImage
        }
    }
    public method handleUserChange
    public method handleSessionIdChange
    public method handleLastImageChange 
    public method loadImageCB { token }
    public method drawBlankImage { } {
        catch {image delete $m_imageName}
    }

    public method isPaused { } {
        return $gCheckButtonVar($this,pause)
    }

    public method unPause { } {
        set gCheckButtonVar($this,pause) 0
    }

    public method showFile { path_ } {
        $itk_component(fileEntry) setValue $path_
        set gCheckButtonVar($this,pause) 1
    }

    public method openWeb { } {
        set url [::config getStr webice.showImageUrl]
        set beamline [::config getConfigRootName]
        append url "?SMBSessionID=$m_sessionId&userName=$m_user"
        append url "&beamline=$beamline"
        append url "&file=$m_fileName"
        if {[catch {
            openWebWithBrowser $url
        } errMsg]} {
            log_error $errMsg
            log_error $errMsg
            log_error $errMsg
        } else {
            $itk_component(openWith) configure -state disabled
            after 10000 [list $itk_component(openWith) configure -state normal]
        }

    
    }

    public method fileNext { sign } {
        set currentFile [string trim [$itk_component(fileEntry) get]]
        set prefix fileroot
        set numD 5
        set counter 0
        set ext ""
        if {[catch {
            parseFileNameForCounter $currentFile prefix numD counter ext
        } errMsg]} {
            puts "failed to get counter from $currentFile: $errMsg"
            return
        }
        switch -exact -- $sign {
            + {
                incr counter
            }
            - {
                incr counter -1
                if {$counter < 1} {
                    set counter 1
                }
            }
            default {
                return
            }
        }
        set counter [format "%0${numD}d" $counter]
        set nextFile $prefix$counter$ext
        $itk_component(fileEntry) setValue $nextFile
        if {$itk_option(-showPause)} {
            set gCheckButtonVar($this,pause) 1
        }
    }

    ### the file loading or loaded
    private variable m_fileName         ""
    ## NO_IMAGE, LOADING, SUCCESS, FAILED
    private variable m_status           "NO_IMAGE"

    private variable m_user             $env(USER)
    private variable m_sessionId        "invalid"

    private variable m_contrastMax      400
    private variable resolutionText     ""
    private variable lastDirectory      "/data/$env(USER)"
    private variable lastExt            ".img"
    private variable centerx            0.5
    private variable centery            0.5
    private variable width              400
    private variable height             400
    
    private variable wavelength         1.0
    private variable distance           100
    private variable displayOriginX     0
    private variable displayOriginY     0
    private variable jpegPixelSize      1
    private variable exposureTime
    private variable detectorType       ""

    private variable m_imageName        ""
    private variable m_zoom             1.0
    private variable m_msgDisplay       "No Image"    
    private variable imageCanvas        ""
    private variable imageData
    private variable paremters          ""
    private variable httpObjName        ""
    private variable _encodingCalled    0
    private variable m_currentFileWrap ""
    
    # Gui constants    
    private variable smallFont         *-helvetica-bold-r-normal--14-*-*-*-*-*-*-*
    private variable largeFont        *-helvetica-bold-r-normal--18-*-*-*-*-*-*-*
    
    private common uniqueNameCounter 0
    private common gCheckButtonVar

    private variable m_lastImageObj
    private variable m_ctsLastImage ""
    private variable m_ticketHolder [::DCS::TicketForImage::getInstance]
    private variable m_oneTicketPerImage \
    [::config getInt "bluice.oneTicketPerImage" 1]
    
    # Constructor
    public method constructor
    
    # Destructor
    public method destructor {} {
        if {![ImgLibraryAvailable] } {
            return
        }
        ::mediator unregister $this $m_lastImageObj contents 
        $itk_option(-controlSystem) unregister $this user handleUserChange
        $itk_option(-controlSystem) unregister $this sessionID handleSessionIdChange

        catch {http::cleanup $httpObjName}
    }

    # Public member functions
    public method load { path }
    public method zoom_by { factor }
    public method set_contrast_max { max }
    public method change_contrast_max_by { delta }
    public method scale_contrast_max_by { factor }
    public method pan_horiz { delta }
    public method pan_vert { delta }
    public method recenter_at { x y }
    public method handle_contrast_max_entry
    public method handle_sessionid_entry {}
    public method browse_dir {}
    public method handle_filename_entry
    public method handle_zoom_entry {}
    public method set_zoom { value }
    public method view_with_adxv {}
    public method handle_resize {} 
    public method handle_mouse_motion {x y} 
    public method handle_mouse_exit {}    
    public method handle_right_click_load {}

    # private member functions
    private method update_image {}
    private method do_load { path }
    private method update_status { text }
    private method do_imageCB { token }
   
   #determine the protocol
   private common m_protocol http
   #if { [CLibraryAvailable] } {
   #   set m_protocol 2
   #} else {
   #   set m_protocol http
   #}

}


###################################################################
#
# Creates canvases for the image and control panel.
# Create a DiffImage object to represent the image.
# DiffImage will handle the loading of the image and its header.
#
###################################################################
body DiffImageViewer::constructor { args } {
    # global variables

    if {![ImgLibraryAvailable] } {
        return
    }
    set m_currentFileWrap [::DCS::ManualInputWrapper ::#auto]
    set deviceFactory [DCS::DeviceFactory::getObject]
    set m_lastImageObj [$deviceFactory createString lastImageCollected]

    set m_imageName test$uniqueNameCounter
    incr uniqueNameCounter

    # Display the image canvas
    # Note that the actual width and height of the canvas may not be exact
    # We need to set $width $height member variables again after the 
    # window becomes visible
    itk_component add imageCanvas {
        canvas $itk_interior.imageCanvas -bg white -relief sunken -borderwidth 3
    } {
      keep -width -height
   }


    set resolutionText [$itk_component(imageCanvas) create text 50 50 -text "" -tag movable]

    bind $itk_component(imageCanvas) <Double-1> "$this view_with_adxv"
    bind $itk_component(imageCanvas) <1> "$this recenter_at %x %y"
    bind $itk_component(imageCanvas) <Configure> "$this handle_resize"
    bind $itk_component(imageCanvas) <Motion> "$this handle_mouse_motion %x %y"
    bind $itk_component(imageCanvas) <Leave> "$this handle_mouse_exit"
    bind $itk_component(imageCanvas) <3> "$this handle_right_click_load"
    
    itk_component add contrast {
        DCS::ZoomEntry $itk_interior.con \
        -decreaseCommand "$this change_contrast_max_by -100" \
        -increaseCommand "$this change_contrast_max_by 100" \
        -text "Brightness" \
        -onSubmit [list $this handle_contrast_max_entry] \
        -entryWidth 6 \
        -entryType positiveInt
    } {
    }

    $itk_component(contrast) setValue $m_contrastMax 1    

    itk_component add zoom {
        DCS::ZoomEntry $itk_interior.z \
        -decreaseCommand "$this zoom_by 0.5" \
        -increaseCommand "$this zoom_by 2.0" \
        -text "Zoom" \
        -onSubmit [list $this handle_zoom_entry] \
        -entryWidth 6 \
        -entryType positiveFloat
    } {
    }

    $itk_component(zoom) setValue $m_zoom 1
    
    # make joypad
    itk_component add arrowPad {
        DCS::ArrowPad $itk_interior.ap \
        -activeClientOnly 0 \
        -systemIdleOnly 0 \
        -debounceTime 100 \
        -leftCommand "$this pan_horiz -1" \
        -upCommand "$this pan_vert -1" \
        -downCommand "$this pan_vert 1" \
        -rightCommand "$this pan_horiz 1"
    } {
    }

    itk_component add openWith {
        DCS::DropdownMenu $itk_interior.openWith \
        -systemIdleOnly 0 \
        -activeClientOnly 0 \
        -text "Open with ..." \
        -state normal
    } {
    }

    $itk_component(openWith) add command \
    -foreground blue \
    -label WebIce \
    -command "$this openWeb"
        
    $itk_component(openWith) add command \
    -label ADXV \
    -command "$this view_with_adxv"
        
    itk_component add fileF {
        frame $itk_interior.ff
    } {
    }
    set fileSite $itk_component(fileF)

    set gCheckButtonVar($this,pause) 0
    itk_component add pause {
        checkbutton $fileSite.pause \
        -variable [scope gCheckButtonVar($this,pause)] \
        -text "Hold Image" \
        -command "$this handlePause"
    } {
    }

    itk_component add fileEntry {
        DCS::Entry $fileSite.f -promptText "File Name" \
        -reference "$m_currentFileWrap value" \
        -entryType string \
        -entryJustify left \
        -entryWidth 50 \
        -entryMaxLength 200 \
        -onSubmit [list $this handle_filename_entry] \
        -activeClientOnly 0 \
        -systemIdleOnly 0
    } {
        rename -entryJustify filenameJustify filenameJustify FilenameJustity
    }

    itk_component add fileNext {
        button $fileSite.next \
        -image $DCS::ArrowButton::plusImage \
        -command "$this fileNext +" \
    } {
    }
    itk_component add filePrev {
        button $fileSite.prev \
        -image $DCS::ArrowButton::minusImage \
        -command "$this fileNext -" \
    } {
    }

    pack $itk_component(fileEntry) -side left -expand 1 -fill x -anchor w
    pack $itk_component(fileNext) -side right
    pack $itk_component(filePrev) -side right
    pack $itk_component(pause) -side right

    image create photo $m_imageName -palette 256/256/256 -format jpeg
    $itk_component(imageCanvas) create image 0 0 -image $m_imageName -anchor nw

    # Parse the arguments and set the public 
    # members that match the arguments
    eval itk_initialize $args


    $itk_option(-controlSystem) register $this user handleUserChange
    $itk_option(-controlSystem) register $this sessionID handleSessionIdChange
    ::mediator register $this $m_lastImageObj contents handleLastImageChange
    
    ::mediator announceExistence $this

}

###################################################################
#
# Public method
# Load a new image from the given file path from the image server
# Using asyncronous loading. When running in debug mode, this method
# measures the time to load/update the image. 
#
###################################################################
body DiffImageViewer::load { path } {
    if {[catch {do_load $path} errMsg]} {
        set m_status FAILED
        puts "do_load errMsg: {$errMsg}"

        if {$errMsg != "init"} {
            log_error load image $path failed: $errMsg
            update_status $errMsg
        } else {
            puts "init"
            update_status "No Image"
        }
        drawBlankImage
        set newfile [string trim [$itk_component(fileEntry) get]]
        if {$path != $newfile} {
            puts "file changed while trying to load"
            load $newfile
        }
    }
}

###################################################################
#
# Public method
# Load a new image from the given file path from the image server
#
###################################################################
body DiffImageViewer::do_load { path } {
    set m_fileName [string trim $path]
    $m_currentFileWrap setValue $m_fileName

    if { $m_fileName == "" || \
    $m_fileName == "0" || \
    $m_fileName == "{}" || \
    $itk_option(-imageServerHost) == "" || \
    $itk_option(-imageServerHttpPort) == ""} {
        puts "DiffImageViewer not ready yet"
        return -code error init
    }

    set m_status "LOADING"
    update_status "Loading..."

    set firstChar [string index $m_fileName 0]
    if {$firstChar != "/" && $firstChar != "~"} {
        puts "DiffImageViewer skip bad file $m_fileName"
        return -code error "bad filename"
    }
    
    set width [winfo width $itk_component(imageCanvas)]
    set height [winfo height $itk_component(imageCanvas)]

    #$itk_component(imageCanvas) resize $width $height

    if {$m_oneTicketPerImage} {
        set SID [$m_ticketHolder getTicket $m_fileName $m_sessionId]
    } else {
        set SID [getTicketFromSessionId $m_sessionId]
    }

    if {[string first invalid $SID] >= 0} {
        return -code error "failed to get token"
    }

    set url "http://$itk_option(-imageServerHost)"
    append url ":$itk_option(-imageServerHttpPort)/getImage"
    append url "?userName=$m_user&sessionId=$SID"
    append url "&fileName=$m_fileName"
    append url "&sizeX=$width&sizeY=$height"
    append url "&zoom=$m_zoom"
    append url "&gray=$m_contrastMax"
    append url "&percentX=$centerx&percentY=$centery"
    
    #puts "$this \n url: [SIDFilter $url]"

    catch {http::cleanup $httpObjName}

    set httpObjName [http::geturl $url \
    -binary 1 \
    -command [list $this loadImageCB] \
    -timeout 60000 \
    ]
}

body DiffImageViewer::loadImageCB { token } {
    #puts "$this callback"
    if {[catch {do_imageCB $token} errMsg]} {
        set m_status "FAILED"
        update_status $errMsg
        drawBlankImage
        puts "failed: $errMsg"
    }
    #puts "$this callback done"
    set newfile [string trim [$itk_component(fileEntry) get]]
    if {$newfile != $m_fileName} {
        puts "file changed during url load"
        load $newfile
    }
}
body DiffImageViewer::do_imageCB { token } {
    checkHttpStatus $token
    set result [http::data $token]
    upvar #0 $token state
    array set meta $state(meta)
    set m_status "SUCCESS"

    catch {image delete $m_imageName}
    image create photo $m_imageName -palette 256/256/256 -data $result

    set wavelength     0.0
    set distance       0.0
    set displayOriginX 0.0
    set displayOriginY 0.0
    set jpegPixelSize  0
    set exposureTime   0
    set detectorType   "unknown"

    foreach v {
        wavelength
        distance
        displayOriginX
        displayOriginY
        jpegPixelSize
        exposureTime
        detectorType
    } tag {
        wavelength
        distance
        originX
        originY
        pixelSize
        time
        detectorTypeC64
    } {
        if {[info exists meta($tag)]} {
            set $v $meta($tag)
        }
    }

    set x [expr [winfo pointerx $itk_component(imageCanvas)] - \
    [winfo rootx $itk_component(imageCanvas)] ]
    set y [expr [winfo pointery $itk_component(imageCanvas)] - \
    [winfo rooty $itk_component(imageCanvas)] ]
    handle_mouse_motion $x $y

    set lastDirectory [file dirname $m_fileName]
    set lastExt       [file extension $m_fileName]
}

###################################################################
#
# private method
# Set text at cursor position
#
###################################################################
body DiffImageViewer::update_status { text } {

    set m_msgDisplay $text

    #update the cursor with the new resolution
    set x [expr [winfo pointerx $itk_component(imageCanvas)] - [winfo rootx $itk_component(imageCanvas)] ]
    set y [expr [winfo pointery $itk_component(imageCanvas)] - [winfo rooty $itk_component(imageCanvas)] ]
    $this handle_mouse_motion $x $y

}

###################################################################
#
# private method
# Called when an image viewing setting has changed such as zoom level.
# Need to reload the image with the new parameters.
#
# Syncronous loading
#
###################################################################
body DiffImageViewer::update_image {} {
    if {[catch {do_load $m_fileName} errMsg]} {
        log_error update image $path failed: $errMsg
    }
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_contrast_max_entry { } {

   set newMax [$itk_component(contrast) get]

    if { $newMax == $m_contrastMax } {
        return
    }

   if {$m_status == "LOADING"} return
    
    # reset entry value if invalid
    set_contrast_max $newMax
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::browse_dir {} {
    
    handle_right_click_load

}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_filename_entry {} {
    #puts "$this handle_filename_entry"
    # get new value from entry field
    set newfile [string trim [$itk_component(fileEntry) get]]

    if {$m_status != "LOADING"} {
        load $newfile
    }
}

###################################################################
#
# 
#
###################################################################
body DiffImageViewer::handle_zoom_entry {} {
    
    # get new value from entry field
    set newZoom [$itk_component(zoom) get]
    
    if {$newZoom == $m_zoom} {
        return
    }

    # reset entry value if invalid
    if { $newZoom <= 0 || $m_status == "LOADING"} {
        $itk_component(zoom) setValue $m_zoom 1
    } else {
        set_zoom $newZoom
    }
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::zoom_by { factor } {
    

    if { $m_status == "LOADING" } {
        return
    }

    # calculate new value for zoom
    set zoom [expr $m_zoom * $factor]

    # update the diffimage object
    set_zoom $zoom
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::set_zoom { value } {
    #puts "$this set_zoom $value"
    
    if { $m_status != "SUCCESS"} {
        return
    }

    # store the new zoom value
    set m_zoom [format "%.2f" $value]

    # make sure zoom is not too small
    if { $m_zoom < 0.01 } {
        set m_zoom 0.01
    }

    $itk_component(zoom) setValue $m_zoom 1

    # update the diffimage object
    update_image
}





###################################################################
#
# 
#
###################################################################
body DiffImageViewer::set_contrast_max { max } {
    #puts "$this set_contrast_max"
    
    if {$m_status != "SUCCESS"} {
        return
    }

    # store new value of contrast max
    set m_contrastMax $max

   $itk_component(contrast) setValue $max 1

    # update the diffimage object
    update_image
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::change_contrast_max_by { delta } {
    
    if {$m_status != "SUCCESS"} {
        return
    }

    # calculate new value of contrast max
    set_contrast_max [expr $m_contrastMax + $delta]
}

body DiffImageViewer::scale_contrast_max_by { factor } {
    
    if {$m_status != "SUCCESS"} {
        return
    }

    set old $m_contrastMax
    if {$old < 1} {
        set old 1
    }
    set new [expr abs(int($old * $factor))]
    if {$new < 1} {
        set new 1
    }
    set_contrast_max $new
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::pan_horiz { delta } {
        
    if {$m_status != "SUCCESS"} {
        return
    }

    $this recenter_at [expr $width / 2 + $delta * $width / 2] [expr $height / 2 ]
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::pan_vert { delta } {
    
    if {$m_status != "SUCCESS"} {
        return
    }

    $this recenter_at [expr $width / 2] [expr $height / 2 + $delta * $height / 2]
}


###################################################################
#
#
#
###################################################################
body DiffImageViewer::recenter_at { x y } {
    #puts "$this recenter_at $x $y"
        
    if {$m_status != "SUCCESS"} {
        return
    }

    set centerx [expr ( double($x) / $width  - 0.5 ) / $m_zoom + $centerx]
    set centery [expr ( double($y) / $height - 0.5 ) / ($m_zoom * $width / $height) + $centery]

    # update the diffimage object
    update_image
}


###################################################################
#
# 
#
###################################################################
body DiffImageViewer::view_with_adxv {} {
    global env

    set display $env(DISPLAY)
    #puts "display: $display"
    set colonIndex [string last : $display]

    set exceededLimit 0
    if {$colonIndex >= 0} {
        incr colonIndex
        set displayNum [string range $display $colonIndex end]
        #puts "displayNum: $displayNum"
        if {$displayNum != 0} {
            if {[catch {
                puts "not local, check instance"
                set pid [pid]
                set pList [exec ps -ef]
                set pList [split $pList \n]
                set numInstance 0
                foreach p $pList {
                    if {[lindex $p 2] == $pid && [lindex $p 7] == "adxv"} {
                        incr numInstance
                    }
                }
                puts "num instances: $numInstance"
                if {$numInstance >= 5} {
                    set exceededLimit 1
                }
            } errMsg]} {
                log_warning adxv limit check failed: $errMsg
            }
        }
    }

    if {$exceededLimit} {
        log_error ADXV limit reached - only 5 instances of ADXV can run simultaneously.
        log_error ADXV limit reached - only 5 instances of ADXV can run simultaneously.
        log_error ADXV limit reached - only 5 instances of ADXV can run simultaneously.
        log_error ADXV limit reached - only 5 instances of ADXV can run simultaneously.
        log_error ADXV limit reached - only 5 instances of ADXV can run simultaneously.
    } else {
        exec adxv $m_fileName &
    }
}


###################################################################
#
# Callback when the window is resized
#
###################################################################
body DiffImageViewer::handle_resize {} {


    # let window repaint before starting the synchronous read
    update idletasks

    # make sure image is not in the process of loading
    if {$m_status == "LOADING"} {
        after 1000 [list catch "$this handle_resize"]
        return
    }
    
    # save old width temporarily
    set oldWidth $width
    set oldHeight $height
    
    # query and store new image size
    set width [winfo width $itk_component(imageCanvas)]
    set height [winfo height $itk_component(imageCanvas)]
    
    # size has not changed
    if { [ expr $oldWidth == $width ] && [ expr $oldHeight == $height ] } {
        return
    }
    
   #puts "$itk_component(imageCanvas) resize $width $height"    
   set newZoom [expr $m_zoom * $oldWidth / $width]

   if {$newZoom < .8} {set newZoom .8}

    # set the new zoom level and refresh the view
    set_zoom $newZoom
}


###################################################################
#
# Callback when for right mouse click.
#
###################################################################
body DiffImageViewer::handle_right_click_load {} {
    set defaultType "DEFAULT $lastExt"
    set types [list $defaultType \
    {{ADSC} {.img}} {MAR {.mar* .tif .mccd}} {ImageCif {.cif .cbf}} ]

    set imageFile [tk_getOpenFile -filetypes $types \
        -initialdir $lastDirectory]

    if { $imageFile != "" } {
        $itk_component(fileEntry) setValue $imageFile
    }
}

###################################################################
#
# Callback when mouse moves in the image canvas.
#
###################################################################
body DiffImageViewer::handle_mouse_motion {x y} {


    catch {
        set newX [expr $x + 35]
        set newY [expr $y + 35]
        
        if { $newX + 35  > $width } {
            incr newX -70
        }
        
        if { $newY + 35  > $height } {
            incr newY -70
        }
        
        $itk_component(imageCanvas) raise $resolutionText

        #move the text to near the cursor
        $itk_component(imageCanvas) coords $resolutionText $newX $newY
        
        #check to see if there is a loaded image
        if {$m_status != "SUCCESS"} {
            $itk_component(imageCanvas) itemconfigure $resolutionText -text $m_msgDisplay -fill red -font $largeFont
            return
        }

        
        #The mar header doesn't provide enough information to calculate the resolution.
        if { $detectorType == "MAR 345" } {
            $itk_component(imageCanvas) itemconfigure $resolutionText -text "" \
                                                       -fill red -font $largeFont
            return
        }


        set deltaX [expr $x * $jpegPixelSize + $displayOriginX]
        set deltaY [expr $y * $jpegPixelSize + $displayOriginY]
        set radius [expr sqrt($deltaX * $deltaX + $deltaY * $deltaY)]

        # calculate the resolution of the ring from its radius
        set twoTheta [expr atan($radius / $distance) ]
        set dSpacing [expr $wavelength / (2*sin($twoTheta/2.0))]
        
        $itk_component(imageCanvas) itemconfigure $resolutionText -text [format "%.2f A" $dSpacing] \
                                                   -fill red -font $largeFont


    }

}



###################################################################
#
# Callback when mouse exits the image canvas.
#
###################################################################
body DiffImageViewer::handle_mouse_exit {} {

    $itk_component(imageCanvas) itemconfigure $resolutionText -text ""
}


body DiffImageViewer::handleUserChange { stringName_ targetReady_ alias_ user_ - } {
    if { !$targetReady_ } return
    set m_user $user_
}

body DiffImageViewer::handleSessionIdChange { stringName_ targetReady_ alias_ sessionId_ - } {
    if { !$targetReady_ } return
    set m_sessionId $sessionId_
}


body DiffImageViewer::handleLastImageChange { stringName_ targetReady_ alias_ contents_ - } {
    if { !$targetReady_ } return
    set m_ctsLastImage $contents_

    if {!$gCheckButtonVar($this,pause)} {
        $itk_component(fileEntry) setValue $contents_
    }
}

proc startDiffImageViewer { configuration_ authProtocol_ } {
package require BLUICEStatusBar

    global env

    wm title . "Diffraction Image Viewer for beamline [$configuration_ getConfigRootName]"
    wm resizable . 1 1
    
    set httpPort [$configuration_ getImgsrvHttpPort]
    
    set imageServerHost [$configuration_ getImgsrvHost]
    
    DiffImageViewer .i \
    -width 500 -height 500 \
    -imageServerHost $imageServerHost \
    -imageServerHttpPort $httpPort

    StatusBar .activeButton
    ::dcss configure -forcedLoginCallback ".activeButton getLogin"
    
    pack .i
    pack .activeButton
}


#DiffImageViewer .test 
