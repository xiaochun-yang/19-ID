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

package provide BLUICECollectTab 1.0

package require DCSTabNotebook
package require BLUICEResolution
package require BLUICECollectTimedBurst


class DCS::CollectTab {
	inherit ::itk::Widget

	# public methods
	constructor { args } {
		global env

       #the paned windows organizes all of the graphing functions in one place
       itk_component add pw {
           iwidgets::panedwindow $itk_interior.pw -orient vertical 
       } {
       }

      $itk_component(pw) add DiffViewer 
      $itk_component(pw) add RunDef -minimum 450

      set diffView [$itk_component(pw) childsite 0] 
      set runDef [$itk_component(pw) childsite 1]

        set collectClass "DCS::CollectView"
        ::config get bluice.collectView collectClass

		itk_component add runView {
			$collectClass $runDef.rv
		} {
		}

		eval itk_initialize $args

      #create the diffraction image viewer
		itk_component add diffImageViewer {
      DiffImageViewer $diffView.diff -width 500 -height 500 
      } {
         keep -imageServerHost -imageServerHttpPort
      }
				
		#grid columnconfigure $itk_interior 0 -weight 0
		#grid columnconfigure $itk_interior 1 -weight 1
		#grid rowconfigure $itk_interior 0 -weight 1 

      #grid $itk_component(diffImageViewer) -row 0 -column 0 -sticky news
		#grid $itk_component(runView) -row 0 -column 1 -sticky news


      pack $itk_component(pw) -expand 1 -fill both -side left
      pack $itk_component(diffImageViewer) -expand 1 -fill both -side left
		pack $itk_component(runView) -expand 1 -fill both -side left
	}
}

