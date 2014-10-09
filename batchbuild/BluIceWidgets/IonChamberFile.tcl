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

package provide BLUICEIonChamberFile 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSDeviceFactory
package require DCSUtil
package require DCSConfig
package require DCSButton
package require DCSEntry

class IonChamberFileWidget {
    inherit ::itk::Widget

    #options
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"
    itk_option define -mdiHelper mdiHelper MdiHelper ""

    public method handlePrint { }
    public method handleSave { }
    public method handleLoad { }
    public method handleRefresh { }
    public method handleCheckButton { }
    public method handleButtonCommon { }
    public method handleUnselectAll { }
    public method redisplay { }

    public method handleIonChamberUpdate

    private method createRow
    private method getNumSelection { }

    private method generateCommonMap
    private method allCommonSelected { }
    private method conflictWarning { }

    private variable m_deviceFactory
    private variable m_ion_chamberList
    private variable m_contentsFrame
    private variable m_numRowCreate 0

    private variable m_anySelectedWrap

    private variable m_commonIonChamberIndexList ""

    private common gCheckButtonVar

    private common EVEN_BACKGROUND #A0A0A0
    private common ODD_BACKGROUND  #C0C0C0

    #contructor/destructor
    constructor { args  } {
        set commonList [::config getList ionChamber.common]
        ### each line defined more than one patterns
        set commonList [eval concat $commonList]
        puts "common list: $commonList"

        set m_anySelectedWrap [::DCS::ManualInputWrapper ::#auto]
        $m_anySelectedWrap setValue 0

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_ion_chamberList [$m_deviceFactory getSignalList]

        generateCommonMap commonList

        itk_component add fr {
            iwidgets::labeledframe $itk_interior.lf \
            -labeltext "Command"
        } {
        }
        set controlSite [$itk_component(fr) childsite]

        itk_component add save {
            button $controlSite.cs \
            -text "Save To File" \
            -command "$this handleSave"
        } {
        }

        itk_component add load {
            button $controlSite.cl \
            -text "Load From File" \
            -command "$this handleLoad"
        } {
        }

        itk_component add print {
            button $controlSite.cp \
            -text "Print Data" \
            -command "$this handlePrint"
        } {
        }

        itk_component add refresh {
            DCS::Button $controlSite.sm \
            -activebackground #d0d000 \
            -background  #d0d000 \
            -systemIdleOnly 1 \
            -activeClientOnly 1 \
            -text "Refresh" \
            -command "$this handleRefresh"
        } {
        }

        itk_component add time {
            DCS::Entry $controlSite.tm \
            -background  #d0d000 \
            -systemIdleOnly 0 \
            -activeClientOnly 1 \
            -entryType positiveFloat \
            -promptText "Integration:" \
            -units s
        } {
        }
        $itk_component(time) setValue 0.1

        $itk_component(refresh) addInput "$m_anySelectedWrap value 1 {No signal selected}"

        pack $itk_component(print) -side left -expand 1 -fill x
        pack $itk_component(save) -side left -expand 1 -fill x
        pack $itk_component(load) -side left -expand 1 -fill x
        pack $itk_component(refresh) -side left -expand 1 -fill x
        pack $itk_component(time) -side left -expand 1 -fill x

        set utilSite [frame $itk_interior.utilFr]
        set gCheckButtonVar($this,common) 0

        itk_component add common {
            checkbutton $utilSite.common \
            -text "All Common Ion Chambers" \
            -command "$this handleButtonCommon" \
            -variable [scope gCheckButtonVar($this,common)]
        } {
        }

        set gCheckButtonVar($this,hide) 0
        itk_component add hide {
            checkbutton $utilSite.hide \
            -variable [scope gCheckButtonVar($this,hide)] \
            -text "Hide Unselected" \
            -command "$this redisplay"
        } {
        }

        itk_component add unselectall {
            DCS::Button $utilSite.cp \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
            -text "Unselect All" \
            -command "$this handleUnselectAll"
        } {
        }
        $itk_component(unselectall) addInput "$m_anySelectedWrap value 1 {No signal selected}"
        pack $itk_component(common) -side left
        pack $itk_component(hide) -side left
        pack $itk_component(unselectall) -side left


        itk_component add fileFrame {
            frame $itk_interior.ff
        } {
        }
        set fileSite $itk_component(fileFrame)
        itk_component add file_label {
            label $fileSite.f_l \
            -text "File loaded:"
        } {
        }
        itk_component add file_name {
            label $fileSite.f_n \
            -justify left \
            -anchor w
        } {
        }
        pack $itk_component(file_label) -side left
        pack $itk_component(file_name) -side left -expand 1 -fill x

        itk_component add contentsFrame {
            iwidgets::scrolledframe $itk_interior.ctsFrame \
            -vscrollmode static
        } {
        }
        set m_contentsFrame [$itk_component(contentsFrame) childsite]
        set f $m_contentsFrame

        label $f.h1 -text "Signal Name"
        label $f.h2 -text "From File"
        label $f.h3 -text "Current Value"
        grid $f.h1  -row 0 -column 1 -sticky w
        grid $f.h2  -row 0 -column 2 -sticky e
        grid $f.h3  -row 0 -column 3 -sticky e

        set ODD_BACKGROUND [$f.h1 cget -background]

        set i -1
        foreach ion_chamberName $m_ion_chamberList {
            incr i
            createRow $i $ion_chamberName
        }
        set m_numRowCreate [llength $m_ion_chamberList]

        pack $itk_component(fr) -fill x
        pack $itk_component(fileFrame) -fill x
        pack $itk_interior.utilFr -anchor w
        pack $itk_component(contentsFrame) -expand 1 -fill both

        eval itk_initialize $args
    }
    destructor {
        delete object $m_anySelectedWrap

        foreach ion_chamberName $m_ion_chamberList {
            set obj [$m_deviceFactory getObjectName $ion_chamberName]
            $obj unregister $this -value handleIonChamberUpdate
        }
    }
}

body IonChamberFileWidget::handlePrint { } {
    global env

    # make the temporary directory if needed
    file mkdir /tmp/$env(USER)

    set beamlineName [::config getConfigRootName]

    #set the filename
    set filename /tmp/$env(USER)/config_$beamlineName.txt

    #open file for write
    if {[catch { open $filename w } fileHandle]} {
        log_error tmp File $filename cannot be opened to write. \
        Configuration not printed.
        return
    }

    puts $fileHandle "# beamline   $beamlineName"
    puts $fileHandle "# date       [time_stamp]"
    #write out ion_chamber position
    foreach ion_chamberName $m_ion_chamberList {
        set obj [$m_deviceFactory getObjectName $ion_chamberName]
        set pos [$obj getCounts]
        set oneLine [format "%-30s %17.8f" $ion_chamberName $pos]
        puts $fileHandle $oneLine
    }

    close $fileHandle

    #print
    if { [catch {
        exec a2ps $filename
    } result ]} {
        log_note $result
    }
}

body IonChamberFileWidget::handleSave { } {
    set filename [tk_getSaveFile]

    if {$filename == {} } return

    #open file for write
    if {[catch { open $filename w } fileHandle]} {
        log_error File $filename cannot be opened to write. \
        Configuration not saved.
        return
    }

    #write header to file
    puts $fileHandle "# file       $filename"
    puts $fileHandle "# beamline   [::config getConfigRootName]"
    puts $fileHandle "# date       [time_stamp]"
    puts $fileHandle ""


    #write out ion_chamber position
    foreach ion_chamberName $m_ion_chamberList {
        set obj [$m_deviceFactory getObjectName $ion_chamberName]
        set pos [$obj getCounts]
        set oneLine [format "%-30s %10.3f" $ion_chamberName $pos]
        puts $fileHandle $oneLine
    }

    close $fileHandle
    log_note "IonChamber Positions saved to $filename"
}

body IonChamberFileWidget::handleLoad { } {
    set filename [tk_getOpenFile]

    if {$filename == {} } return

    #open file for read
    if {[catch { open $filename r } fileHandle]} {
        log_error File $filename cannot be opened to read. \
        return
    }

    # read header from file
    gets $fileHandle buffer
    gets $fileHandle buffer
    gets $fileHandle buffer
    gets $fileHandle buffer

    set f $m_contentsFrame
    while { [gets $fileHandle buffer] >= 0 } {
        set ion_chamber [lindex $buffer 0]
        set value [lindex $buffer 1]
        set index [lsearch $m_ion_chamberList $ion_chamber]
        if {$index >= 0} {
            $f.oldV$index configure \
            -text [format %17.8f $value]
        }
    }
    close $fileHandle

    $itk_component(file_name) configure \
    -text $filename

    handleRefresh
}
body IonChamberFileWidget::handleRefresh { } {
    if {[$itk_option(-controlSystem) cget -clientState] == "active"} {
        set itime [lindex [$itk_component(time) get] 0]
        puts "integration time: $itime"
        if {![string is double -strict $itime] || $itime <= 0} {
            log_warning invalid integration time $itime
            set itime 0.1
            log_warning integration time changed to 0.1 second
            $itk_component(time) setValue "0.1 s"
        }
        set i -1
        set message [list gtos_read_ion_chambers $itime 0]
        foreach ion_chamberName $m_ion_chamberList {
            incr i
            if {$gCheckButtonVar($this,ck$i)} {
                lappend message $ion_chamberName
                set obj [$m_deviceFactory getObjectName $ion_chamberName]
                if {[catch { $obj started } errMsg]} {
                    log_error failed to read $ion_chamberName: $errMsg
                }
            }
        }
        $itk_option(-controlSystem) sendMessage $message
        foreach ion_chamberName $m_ion_chamberList {
            set obj [$m_deviceFactory getObjectName $ion_chamberName]
            if {[catch { $obj waitForDevice } errMsg]} {
                log_error failed to read $ion_chamberName: $errMsg
            }
        }
    }
}
body IonChamberFileWidget::createRow { i ion_chamberName } {
    set obj [$m_deviceFactory getObjectName $ion_chamberName]
    set f $m_contentsFrame
    set gCheckButtonVar($this,ck$i) 0
    checkbutton $f.ck$i \
    -command "$this handleCheckButton" \
    -variable [scope gCheckButtonVar($this,ck$i)]

    if {$i % 2} {
        set bg $ODD_BACKGROUND
    } else {
        set bg $EVEN_BACKGROUND
    }

    label $f.name$i -justify left  -anchor w -width 40 -background $bg \
    -text $ion_chamberName
    label $f.oldV$i -justify right -anchor e -width 20 -background $bg
    label $f.curV$i -justify right -anchor e -width 20 -background $bg \
    -text [format %17.8f [$obj getCounts]]

    bind $f.name$i <Button-1> "$f.ck$i invoke"
    bind $f.oldV$i <Button-1> "$f.ck$i invoke"
    bind $f.curV$i <Button-1> "$f.ck$i invoke"

    grid $f.ck$i $f.name$i $f.oldV$i $f.curV$i -sticky w

    $obj register $this -value handleIonChamberUpdate
}
body IonChamberFileWidget::handleCheckButton { } {
    set n [getNumSelection]
    if {$n > 0} {
        $m_anySelectedWrap setValue 1
    } else {
        $m_anySelectedWrap setValue 0
    }

    if {[allCommonSelected]} {
        if {!$gCheckButtonVar($this,common)} {
            $itk_component(common) select
        }
    } else {
        if {$gCheckButtonVar($this,common)} {
            $itk_component(common) deselect
        }
    }

    if {$gCheckButtonVar($this,hide)} {
        redisplay
    }

    if {$n == 0 && $gCheckButtonVar($this,hide)} {
        set gCheckButtonVar($this,hide) 0
        redisplay
    }
    conflictWarning
}
body IonChamberFileWidget::getNumSelection { } {
    set numSelection 0
    set f $m_contentsFrame
    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        set sel [set [$f.ck$i cget -variable]]
        if {$sel} {
            incr numSelection
        }
    }
    return $numSelection
}
body IonChamberFileWidget::handleIonChamberUpdate { name_ ready_ - value_ - } {
    if {!$ready_} return

    set name [$name_ cget -deviceName]
    set index [lsearch $m_ion_chamberList $name]

    if {$index >= 0} {
        set f $m_contentsFrame
        set oldV [$f.oldV$index cget -text]
        if {[string is double -strict $oldV] && \
        abs( $oldV - $value_ ) > 0.001} {
            set fg red
        } else {
            set fg black
        }
        $f.curV$index configure \
        -foreground $fg \
        -text [format %17.8f $value_]
    }
}
body IonChamberFileWidget::handleButtonCommon { } {
    foreach i $m_commonIonChamberIndexList {
        set gCheckButtonVar($this,ck$i) $gCheckButtonVar($this,common)
    }
    handleCheckButton
    if {$gCheckButtonVar($this,hide)} {
        redisplay
    }
}
body IonChamberFileWidget::redisplay { } {
    set n [getNumSelection]
    if {$n == 0 && $gCheckButtonVar($this,hide)} {
        set gCheckButtonVar($this,hide) 0
    }

    set f $m_contentsFrame

    set hideUnselected $gCheckButtonVar($this,hide)

    set n 0
    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        if {$hideUnselected && !$gCheckButtonVar($this,ck$i)} {
            grid remove $f.ck$i $f.name$i $f.oldV$i $f.curV$i
        } else {
            grid $f.ck$i $f.name$i $f.oldV$i $f.curV$i -sticky w
            if {$n % 2} {
                set bg $ODD_BACKGROUND
            } else {
                set bg $EVEN_BACKGROUND
            }
            $f.name$i configure -background $bg
            $f.oldV$i configure -background $bg
            $f.curV$i configure -background $bg
            incr n
        }
    }
}
body IonChamberFileWidget::generateCommonMap { commonListREF } {
    upvar $commonListREF common

    set m_commonIonChamberIndexList ""

    set i -1
    foreach ic $m_ion_chamberList {
        incr i
        set add 0
        foreach p $common {
            if {[string match $p $ic]} {
                set add 1
                break
            }
        }
        if {$add} {
            lappend m_commonIonChamberIndexList $i
        }
    }
    puts "common List: $m_commonIonChamberIndexList"
}
body IonChamberFileWidget::allCommonSelected { } {
    foreach i $m_commonIonChamberIndexList {
        if {!$gCheckButtonVar($this,ck$i)} {
            return 0
        }
    }
    return 1
}
body IonChamberFileWidget::conflictWarning { } {
    ### just not like runtime as M x N, trying (M + N)

    set selection ""
    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        lappend selection $gCheckButtonVar($this,ck$i)
    }
    set nonCommonIndexList ""
    foreach i $m_commonIonChamberIndexList {
        set s [lindex $selection $i]
        if {$s} {
            lappend nonCommonIndexList $i
            set selection [lreplace $selection $i $i 0]
        }
    }
    if {$nonCommonIndexList == ""} {
        return
    }
    set commonIndexList ""
    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        set s [lindex $selection $i]
        if {$s} {
            lappend commonIndexList $i
        }
    }
    if {$commonIndexList == ""} {
        return
    }

    ### generate message
    set nonCommonNameList ""
    foreach i $nonCommonIndexList {
        lappend nonCommonNameList [lindex $m_ion_chamberList $i]
    }
    set commonNameList ""
    foreach i $commonIndexList {
        lappend commonNameList [lindex $m_ion_chamberList $i]
    }
    if {[llength $commonNameList] >= [llength $nonCommonNameList]} {
        log_warning Ion Chamber selection may have conflict: \
        $nonCommonNameList with $commonNameList
    } else {
        log_warning Ion Chamber selection may have conflict: \
        $commonNameList with $nonCommonNameList 
    }
}
body IonChamberFileWidget::handleUnselectAll { } {
    for {set i 0} {$i < $m_numRowCreate} {incr i} {
        set gCheckButtonVar($this,ck$i) 0
    }
    handleCheckButton
    if {$gCheckButtonVar($this,hide)} {
        redisplay
    }
}
