#!/bin/sh
# the next line restarts using -*-Tcl-*-sh \
	 exec wish "$0" ${1+"$@"}
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

package provide BLUICESortingTab 1.0

# load the required standard packages
package require Itcl
package require Iwidgets

# load the DCS packages
package require ListSelection

class SortingTab {
	inherit ::itk::Widget

    public method handleHelp { } {
        if {[catch "openWebWithBrowser $m_urlDocument" err_msg]} {
            log_error "start mozilla failed: $err_msg"
        } else {
            bind $itk_component(note2) <Button-1> ""
            after 20000 "bind $itk_component(note2) <Button-1> {$this handleHelp}"
        }
    }

    private variable m_urlDocument ""

	constructor { args } {
        set m_urlDocument [::config getStr document.sample_sorting]

        itk_component add upperFrame {
            iwidgets::Labeledframe $itk_interior.upper \
            -labeltext "Sample Sorting Policy Information" \
            -labelpos nw
        } {
        }

        set noteSite [$itk_component(upperFrame) childsite]

        itk_component add note1 {
            label $noteSite.note1 \
            -text "For more information and policy see:"
        } {
        }

        itk_component add note2 {
            label $noteSite.note2 \
            -foreground blue \
            -text $m_urlDocument
        } {
        }
        pack $itk_component(note1) -side top -expand 0 -fill x
        pack $itk_component(note2) -side top -expand 0 -fill x

        bind $itk_component(note2) <Button-1> "$this handleHelp"

        itk_component add sort {
            MoveCrystalSelectWidget $itk_interior.sort
        } {
        }
		eval itk_initialize $args
        #pack $itk_component(upperFrame) -side top -expand 0 -fill x
        pack $itk_component(sort) -side top -expand 1 -fill both
	}
    destructor {
    }
}
