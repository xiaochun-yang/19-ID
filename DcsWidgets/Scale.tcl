package provide DCSScale 1.0

package require ComponentGateExtension

class DCSScale {
	inherit ::DCS::ComponentGateExtension

    itk_option define -state state State "normal"

    public method handleNewOutput {}

    public method move { num } {
        set current [$itk_component(position) get]
        set step    [$itk_component(position) cget -resolution]

        set from    [$itk_component(position) cget -from]
        set to      [$itk_component(position) cget -to]

        set newP [expr $current + $num * $step]
        if {($newP - $from) * ($to - $newP) >= 0} {
            $itk_component(position) set $newP
        }
    }

    public method setPosition { v } {
        $itk_component(position) set $v
    }

    constructor { args }  {
        itk_component add position {
            scale $itk_interior.pos
        } {
            keep -orient
            keep -showvalue
            keep -label
            keep -resolution
            keep -from
            keep -to
            keep -command
        }
        set bg [$itk_component(position) cget -background]

        itk_component add left {
            button $itk_interior.left \
            -relief flat \
            -background $bg \
            -image $DCS::ArrowButton::leftArrowImage \
            -command "$this move -1"
        } {
        }
        itk_component add right {
            button $itk_interior.right \
            -relief flat \
            -background $bg \
            -image $DCS::ArrowButton::rightArrowImage \
            -command "$this move 1"
        } {
        }


        registerComponent \
        $itk_component(position) \
        $itk_component(left) \
        $itk_component(right)

        eval itk_initialize $args
        pack $itk_component(left) -side left
        pack $itk_component(position) -side left -expand 1 -fill x
        pack $itk_component(right) -side right
        ::mediator announceExistence $this
    }

    destructor {
        unregisterComponent
        ::mediator announceDestruction $this
    }

}
configbody DCSScale::state {
    handleNewOutput
}

body DCSScale::handleNewOutput { } {
    if {$itk_option(-state) != "disabled"} {
        DCS::ComponentGateExtension::handleNewOutput
    } else {
        $itk_component(position) configure -state disabled
    }
}

