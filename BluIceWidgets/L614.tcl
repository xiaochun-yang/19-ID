package provide L614SpecialWidgets 1.0

package require DCSStringView

class L614SoftLinkView {
    inherit ::itk::Widget

    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method refresh { } {
        set dir    [$itk_component(input_dir) get]
        set prefix [$itk_component(input_prefix) get]
        set ext    [$itk_component(input_ext) get]
        $m_objSoftLink startOperation setup $dir $prefix $ext
    }

    public method skip { } {
        set contents [$m_strL614 getContents]
        set newContents [lreplace $contents 0 0 skip]
        $m_strL614 sendContentsToServer $newContents
    }

    public method setDisplayLabel { name value } {
        $itk_component($name) configure -text $value
    }

    private variable m_objSoftLink ""
    private variable m_strL614 ""
    private variable m_displayField ""

    private variable COLOR_DISPLAY "dark green"

    constructor { args } {
        set ring $itk_interior

        label $ring.l00 -text "Next Counter"
        label $ring.l01 -text "Directory"
        label $ring.l02 -text "Prefix"
        label $ring.l03 -text "Ext"

        set deviceFactory [::DCS::DeviceFactory::getObject]
        set m_objSoftLink [$deviceFactory createOperation softLinkForL614]
        set m_strL614     [$deviceFactory createString l614_softlink_status]
        $m_strL614 createAttributeFromField next_counter 0
        $m_strL614 createAttributeFromField directory 1
        $m_strL614 createAttributeFromField prefix 2
        $m_strL614 createAttributeFromField ext 3

        itk_component add input_dir {
            ::DCS::DirectoryEntry $ring.input_dir \
            -leaveSubmit 1 \
            -entryType rootDirectory \
            -entryWidth 24 \
            -entryJustify left \
            -entryMaxLength 128 \
            -showPrompt 0 \
            -showUnits 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -shadowReference 1 \
            -reference "$m_strL614 directory" \
        } {
        }

        itk_component add input_prefix {
            ::DCS::Entry $ring.input_prefix \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 24 \
            -entryJustify left \
            -entryMaxLength 128 \
            -showPrompt 0 \
            -showUnits 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -shadowReference 1 \
            -reference "$m_strL614 prefix" \
        } {
        }

        itk_component add input_ext {
            ::DCS::Entry $ring.input_ext \
            -leaveSubmit 1 \
            -entryType field \
            -entryWidth 8 \
            -entryJustify left \
            -entryMaxLength 8 \
            -showPrompt 0 \
            -showUnits 0 \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -shadowReference 1 \
            -reference "$m_strL614 ext" \
        } {
        }

        itk_component add next_counter {
            label $ring.next_counter \
            -justify left \
            -anchor w \
            -width 10 \
            -relief sunken \
            -background $COLOR_DISPLAY \
        } {
        }
        itk_component add dir {
            label $ring.fir \
            -justify left \
            -anchor w \
            -width 24 \
            -relief sunken \
            -background $COLOR_DISPLAY \
        } {
        }
        itk_component add prefix {
            label $ring.prefix \
            -justify left \
            -anchor w \
            -width 24 \
            -relief sunken \
            -background $COLOR_DISPLAY \
        } {
        }
        itk_component add ext {
            label $ring.ext \
            -justify left \
            -anchor w \
            -width 8 \
            -relief sunken \
            -background $COLOR_DISPLAY \
        } {
        }

        itk_component add refresh {
            ::DCS::Button $ring.refresh \
            -systemIdleOnly 0 \
            -activeClientOnly 1 \
            -width  8 \
            -text "Refresh" \
            -command "$this refresh" \
        } {
        }

        itk_component add skip {
            ::DCS::Button $ring.skip \
            -systemIdleOnly 0 \
            -activeClientOnly 1 \
            -width  8 \
            -text "Skip" \
            -command "$this skip" \
        } {
        }

        $itk_component(refresh) addInput "$m_objSoftLink status inactive Busy"
        $itk_component(skip) addInput "$m_objSoftLink status inactive Busy"

        grid $ring.l00 $ring.l01 $ring.l02 $ring.l03

        grid x \
        $itk_component(input_dir) \
        $itk_component(input_prefix) \
        $itk_component(input_ext) \
        $itk_component(refresh) \
        -sticky news

        grid \
        $itk_component(next_counter) \
        $itk_component(dir) \
        $itk_component(prefix) \
        $itk_component(ext) \
        $itk_component(skip) \
        -sticky news

        eval itk_initialize $args

        set m_displayField [::DCS::StringFieldDisplayBase ::\#auto $this]
        $m_displayField setLabelList [list next_counter 0 dir 1 prefix 2 ext 3]
        $m_displayField configure -stringName $m_strL614
    }
}
