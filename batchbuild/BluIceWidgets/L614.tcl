package provide L614SpecialWidgets 1.0

package require DCSStringView

class L614SoftLinkView {
    inherit DCS::StringDictViewBase

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method refresh { } {
        $m_objSoftLink startOperation refresh
    }

    private variable m_objSoftLink ""
    private variable m_strL614 ""

    constructor { args } {
        set ring $m_site

        label $ring.l00 -text "Name"
        label $ring.l01 -text " "
        label $ring.l02 -text "Next Counter"
        label $ring.l03 -text "Directory"
        label $ring.l04 -text "Prefix"
        label $ring.l05 -text "Ext"

        label $ring.l10 -text "First Single"
        label $ring.l20 -text "Second Single"
        label $ring.l30 -text "Center Phi"
        label $ring.l40 -text "End Single"
        label $ring.l50 -text "All Single"
        label $ring.l60 -text "All"
        label $ring.l70 -text "Control"
        grid $ring.l00 $ring.l01 $ring.l02 $ring.l03 $ring.l04 $ring.l05 \
        -sticky w

        grid configure $ring.l00 -sticky e

        for {set i 1} {$i < 8} {incr i} {
            grid $ring.l${i}0 -row $i -column 0 -sticky e
        }

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objSoftLink [$deviceFactory createOperation softLinkForL614]

        set m_entryList [list]
        set position [list]
        set entryWidth  [list]

        set row 0
        foreach name {first second phi end single global} {
            incr row
            set col 2
            foreach field {dir prefix} w {30 20} {
                incr col
                set alias ${field}_${name}
                lappend m_entryList $alias $alias
                lappend position $row $col
                lappend entryWidth $w
            }
        }
        lappend m_entryList ext ext
        lappend position 1 5
        lappend entryWidth 5

        foreach \
        {name key} $m_entryList \
        {row col} $position \
        w $entryWidth \
        {
            set cmd [list $this updateEntryColor $name $key %P]
            itk_component add $name {
                entry $ring.$name \
                -validate all \
                -width $w \
                -background white \
                -vcmd $cmd \
            } {
            }
            grid $itk_component($name) -row $row -column $col -sticky w
            registerComponent $itk_component($name)
        }

        set m_checkbuttonList [list]
        foreach name {first second phi end single global} {
            set alias enable_${name}
            lappend m_checkbuttonList $alias $alias
        }

        set row 0
        foreach {name key} $m_checkbuttonList {
            incr row
            set cmd [list $this updateCheckButtonColor $name $key]
            itk_component add $name {
                checkbutton $ring.$name \
                -anchor w \
                -variable [scope gCheckButtonVar($this,$name)] \
                -command $cmd \
            } {
            }
            registerComponent $itk_component($name)
            grid $itk_component($name) -row $row -column 1 -sticky w
        }
        lappend m_checkbuttonList sync_counter sync_counter
        set cmd [list $this updateCheckButtonColor sync_counter sync_counter]
        itk_component add sync_counter {
            checkbutton $ring.sync_counter \
            -anchor w \
            -variable [scope gCheckButtonVar($this,sync_counter)] \
            -command $cmd \
            -text "Sync"
        } {
        }
        registerComponent $itk_component(sync_counter)
        grid $itk_component(sync_counter) \
        -row 7 -column 1 -columnspan 2 -sticky w

        set m_origCheckButtonFG [$itk_component(sync_counter) cget -foreground]
        set m_origCheckButtonBG [$itk_component(sync_counter) cget -background]

        set m_labelList [list]
        set row 0
        foreach name {first second phi end single global} {
            incr row
            set alias counter_${name}
            lappend m_labelList $alias $alias
            itk_component add $alias {
                label $ring.$alias \
                -relief sunken \
                -width 10 \
                -anchor e \
                -background #00a040 \
                -text $alias
            } {
            }
            grid $itk_component($alias) -row $row -column 2
        }


        itk_component add refresh {
            DCS::Button $ring.refresh \
            -text "Refresh" \
            -command "$this refresh"
        } {
        }

        grid $itk_component(refresh) -row 7 -column 3

        eval itk_initialize $args
        announceExist
    }
}
