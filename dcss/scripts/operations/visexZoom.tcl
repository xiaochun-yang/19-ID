proc visexZoom_initialize { } {
    variable visexZoomPreset

    set visexZoomPreset(sample,low) 0.0
    set visexZoomPreset(sample,med) 0.75
    set visexZoomPreset(sample,high) 1.0

    set visexZoomPreset(inline,low) 0.2
    set visexZoomPreset(inline,med) 0.75
    set visexZoomPreset(inline,high) 1.0

    ### showPercent
    set visexZoomPreset(visex,low)   1.0
    set visexZoomPreset(visex,med)   0.75
    set visexZoomPreset(visex,high)  0.5
}
## if camera == visex, only change the display, not adjust video camera zoom
proc visexZoom_start { zoom  {camera ""} } {
    variable visex_snapshot_orig

    if {$camera ==""} {
        set camera [lindex $visex_snapshot_orig 8]
    }

    switch -exact -- $camera {
        sample {
            visexZoom_sampleZoom $zoom
        }
        inline {
            visexZoom_inlineZoom $zoom
        }
        visex {
            visexZoom_imageZoom $zoom
        }
    }
}
proc visexZoom_getMinSampleZoom { } {
    set viewWidth [getVisexCameraConstant view_width_mm]
    set minZoom [sampleView_calculate_zoom $viewWidth]
    adjustPositionToLimit camera_zoom minZoom 1
    return $minZoom
}
proc visexZoom_getMinInlineZoom { } {
    set viewWidth [getVisexCameraConstant view_width_mm]
    set minZoom [inlineView_calculate_zoom $viewWidth]
    adjustPositionToLimit inline_camera_zoom minZoom 1
    return $minZoom
}
proc visexZoom_sampleZoom { zoom } {
    variable visexZoomPreset
    variable camera_zoom

    switch -exact -- $zoom {
        high -
        low -
        med {
            set zoom $visexZoomPreset(sample,$zoom)
        }
        current {
            set zoom $camera_zoom
        }
    }
    if {![string is double -strict $zoom]} {
        log_error zoom is not a real number.
        return
    }

    ###check wether we can accept that number
    set minZoom [visexZoom_getMinSampleZoom]
    if {$zoom < $minZoom} {
        set zoom $minZoom
    }
    if {$zoom != $camera_zoom} {
        move camera_zoom to $zoom
        wait_for_devices camera_zoom
    }
}
proc visexZoom_inlineZoom { zoom } {
    variable visexZoomPreset
    variable inline_camera_zoom

    switch -exact -- $zoom {
        high -
        low -
        med {
            set zoom $visexZoomPreset(inline,$zoom)
        }
        current {
            set zoom $inline_camera_zoom
        }
    }
    if {![string is double -strict $zoom]} {
        log_error zoom is not a real number.
        return
    }

    ###check wether we can accept that number
    set minZoom [visexZoom_getMinInlineZoom]
    if {$zoom < $minZoom} {
        set zoom $minZoom
    }
    if {$zoom != $inline_camera_zoom} {
        move inline_camera_zoom to $zoom
        wait_for_devices inline_camera_zoom
    }
}
proc visexZoom_visexZoom { zoom } {
    variable visexZoomPreset
    variable visex_snapshot_save

    switch -exact -- $zoom {
        high -
        low -
        med {
            set zoom $visexZoomPreset(visex,$zoom)
        }
    }
    if {![string is double -strict $zoom]} {
        log_error zoom is not a real number.
    }

    if {$zoom > 1} {
        set zoom 1
    }
    if {$zoom < 0.1} {
        set zoom 0.1
    }

    set visex_snapshot_save [lreplace $visex_snapshot_save 0 0 $zoom]
}
