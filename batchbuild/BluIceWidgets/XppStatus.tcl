package provide BLUICEXppStatus 1.0

package require Itcl
package require Iwidgets
package require BWidget

# load the DCS packages
package require DCSDevice
package require DCSDeviceView

package require BLUICEDetectorMenu

class DCS::XppStatusParams {
    inherit DCS::Component	

    public method sendContentsToServer

    private variable m_deviceFactory
    private variable m_params 

    public variable status "inactive"

    public variable state 
    public variable totalImages 1
    public variable failedImages 1
    public variable percentFailed

    public method setTotalImages  {value_} {setField TOTAL_IMAGES $value_}
    public method setFailedImages  {value_} {setField FAILED_IMAGES $value_}

    public method getContents { } {
        $m_params getContents
    }

    public method calcPercent {} {
        if {$failedImages == ""} { return 1}
        if {$totalImages == ""} {return 1}
	    return [expr $failedImages * 100 / double( $totalImages )]
    }

	# call base class constructor
	constructor { string_name args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {cget -status} \
					 contents { getContents } \
					 state {cget -state} \
					 totalImages {cget -totalImages} \
					 failedImages {cget -failedImages}
					 percentFailed { cget -percentFailed }
			 }
	} {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_xppStatusStr [$m_deviceFactory createString $string_name]
        ::mediator register $this $m_xppStatusStr contents handleParametersChange
        ::mediator register $this $m_xppStatusStr status handleXppStatusChange
      
	    eval configure $args
      
	    announceExist

        return [namespace current]::$this
	}

    public method submitNewParameters { contents_ } {
        $m_params sendContentsToServer $contents_
    }

    public method setField  { paramName value_} {

        set clientState [::dcss cget -clientState]

        if { $clientState != "active"} return

        set newString [list TOTAL_IMAGES $totalImages FAILED_IMAGES $failedImages]

        set valueIndex [lookupIndexByName $newString $paramName]
        set newString [lreplace $newString $valueIndex $valueIndex $value_]
        submitNewParameters $newString
    }


    public method lookupIndexByName { paramList paramName } {
        return [expr [lsearch $paramList $paramName] +1]
    }

    public method lookupValueByName { paramList paramName } {
        return [lindex $paramList [expr [lsearch $paramList $paramName] +1]]
    }

    public method handleXppStatusChange { - targetReady_ - params - } {
        updateListeners
    }
    public method handleParametersChange { - targetReady_ - params - } {

	    if { ! $targetReady_} return

        set totalImages [lookupValueByName $params TOTAL_IMAGES]
        set failedImages [lookupValueByName $params FAILED_IMAGES]
        set percentFailed [calcPercent]

        updateListeners
    }

    private method updateListeners {} {
	    #inform observers of the change 
	    updateRegisteredComponents totalImages
	    updateRegisteredComponents failedImages
	    updateRegisteredComponents percentFailed
    }

}



class DCS::XppStatusWidget {
    inherit ::itk::Widget DCS::Component
    private variable m_xppStatusObj
    private variable m_deviceFactory

    public method constructWidgets {} {
	    # draw and label the detector
	    global BLC_IMAGES
        set ring $itk_interior

		itk_component add canvas {
			canvas $ring.c -width 150 -height 150
		}

		itk_component add diskUseDial {
			canvas $ring.du -width 100 -height 75
		}

		itk_component add totalImagesTxt {
			label $ring.tt -text "Total Images"
		}
		itk_component add failedImagesTxt {
			label $ring.ht -text "Failed Images"
		}
		itk_component add percentFailedTxt {
			label $ring.pf -text "Percent Failed"
		}
        
		itk_component add totalImages {
			label $ring.t0 -text "XX "
		}
		itk_component add failedImages {
			label $ring.t1 -text "XX "
		}
		itk_component add percentFailed {
			label $ring.pfl -text "XX "
		}

        $itk_component(diskUseDial) create oval 2 2 48 48 -tags t1 -fill #c0c0ff -outline ""
        $itk_component(diskUseDial) create arc 2 2 48 48 -tags t2 -fill red -extent 0 -outline ""
        $itk_component(diskUseDial) create text 25 25 -tags t3
        $itk_component(diskUseDial) create text 25 55 -text "% failed"
        
	    grid $itk_component(canvas) -row 0 -column 1 -sticky news 
	    grid $itk_component(diskUseDial) -row 0 -column 2 -sticky news 
	    grid $itk_component(totalImagesTxt) -row 1 -column 1 -sticky news
	    grid $itk_component(failedImagesTxt) -row 1 -column 2 -sticky news 
	    grid $itk_component(percentFailedTxt) -row 1 -column 3 -sticky news 
	    grid $itk_component(totalImages) -row 2 -column 1 -sticky news 
	    grid $itk_component(failedImages) -row 2 -column 2 -sticky news 
	    grid $itk_component(percentFailed) -row 2 -column 3 -sticky news 
    }

	constructor {  args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]

        constructWidgets

        set obj [namespace current]::[DCS::XppStatusParams \#auto xppStatus]
        set m_xppStatusObj $obj
        ::mediator register $this $m_xppStatusObj totalImages changeTotalImages
        ::mediator register $this $m_xppStatusObj failedImages changeFailedImages
        ::mediator register $this $m_xppStatusObj percentFailed changePercentFailed
 
        eval itk_initialize $args
        announceExist
	}

	destructor {
	}

    public method changeTotalImages { - targetReady_ - x - } {
	    $itk_component(totalImages) configure -text "$x"
    }
    public method changeFailedImages { - targetReady_ - x - } {
	    $itk_component(failedImages) configure -text "$x"
    }

    public method changePercentFailed { - targetReady_ - percent - } {
        if {$percent ==""} return
	    $itk_component(percentFailed) configure -text "$percent %"
        $itk_component(diskUseDial) itemconfig t2 -extent [expr {round($percent * 3.6) }]
    }

}

