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


# load the required standard packages
package require Itcl
package require Iwidgets
package require BWidget
package require BLT

package provide BLUICESetupTab 1.0

# load the DCS packages
package require DCSDeviceFactory
package require DCSDevice
package require DCSDeviceView
package require DCSOperationManager
package require DCSHardwareManager
package require DCSProtocol
package require DCSButton
package require DCSPrompt
package require DCSMotorControlPanel
package require DCSMdi
package require DCSPeriodicTable
package require DCSStringView
package require DCSOperationView
package require DCSLogger
package require DCSLogView
package require DCSMessageBoard
package require BLUICECommandPrompt
package require DCSLVDTForBL122
#my own class
package require DCSLiberaView

package require BLUICEDiffImageViewer

package require BLUICEDirectoryView
package require BLUICESequenceCrystals
package require BLUICESequenceActions
package require BLUICEScreeningControl

package require BLUICESlit0View
package require BLUICEFrontEndSlitsView
package require BLUICEMonoView
package require BLUICEGonioView

package require BLUICERobot
package require BLUICERobotReset

package require BLUICECollectView
package require BLUICEDetectorControl

package require BLUICEEventView
package require BLUICELogSender
package require BLUICEXraySampleSearch
package require BLUICEChangeOver
package require BLUICEAdmin
package require BLUICEMotorFile
package require BLUICEScreeningTask
package require BLUICEScreeningTab
package require BLUICESimpleRobot

package require BLUICEOptimizedEnergy
package require BLUICEAutoSampleCal
package require BLUICECryojet
package require BLUICEMotorConfigFile
package require BLUICELaserControl
package require ListSelection
package require BLUICECenterCrystalView
package require BLUICEDefaultParmView
package require BLUICECassetteView
package require BLUICELightControl
package require BLUICELoopCenterError
package require BLUICEBeamSize
package require BLUICEGapControl
package require BLUICEShutterControl
package require BLUICEMarDTBView
package require BLUICEMegaScreeningView
package require BLUICEEncoderFile
package require BLUICEIonChamberFile
package require BLUICECanvasGifView
package require BLUICEAlignFrontEndView
package require BLUICEAlignFrontEndViewBL12-2
package require BLUICESr570
package require BLUICERepositionView
package require BLUICEInlineMotorView
package require BLUICESampleMotorView
package require BLUICEQueueView
package require BLUICEFrontEndSlitsViewBL12-2
package require BLUICESpectrometerView
package require Scan3DView
package require BLUICEBarcodeView
package require RasterTab
package require VisexView
package require GridCanvas
package require BLUICEMicroSpecView
package require BLUICEMicroSpecTab
package require L614SpecialWidgets
package require BLUICEMotorLockView
package require BLUICEEnergyList
package require BLUICECollimatorMotorView
package require BLUICEWBControl
package require BLUICEGonioMotions


class SetupTab {
	inherit ::itk::Widget

	private variable _widgetCount

    private variable m_viewList ""
    private variable m_viewArray

	public method addTools
	public method addDevTools
	public method addViews
	public method addStrings

   public method launchHutchWidgets
   public method launchCollectWidgets
   public method launchScreeningWidgets
   public method launchUserWidgets

   public method handleMotorSelection
	public method openToolChest
	public method openMotorView
	public method launchWidget
	public method configureMotor
	public method editString
	public method scanMotor
	public method getLogin
	public method checkAndActivateExistingDocument

	#alias for motor names
	itk_option define -sampleXDevice sampleXDevice SampleXDevice ""
	itk_option define -sampleYDevice sampleYDevice SampleYDevice ""
	itk_option define -sampleZDevice sampleZDevice SampleZDevice ""
	itk_option define -cameraZoomDevice cameraZoomDevice CameraZoomDevice ""
	itk_option define -gonioPhiDevice gonioPhiDevice GonioPhiDevice ""
	itk_option define -gonioKappaDevice gonioKappaDevice GonioKappaDevice ""
	itk_option define -gonioOmegaDevice gonioOmegaDevice GonioOmegaDevice ""

	itk_option define -detectorHorzDevice detectorHorzDevice DetectorHorzDevice ""
	itk_option define -detectorVertDevice detectorVertDevice DetectorVertDevice ""
	itk_option define -detectorZDevice detectorZDevice DetectorZDevice ""

	itk_option define -energyDevice energyDevice EnergyDevice ""
	itk_option define -attenuationDevice attenuationDevice AttenuationDevice ""
	itk_option define -beamWidthDevice beamWidthDevice BeamWidthDevice ""
	itk_option define -beamHeightDevice beamHeightDevice BeamHeightDevice ""
	itk_option define -beamstopDevice  beamstopDevice BeamstopDevice ""

	itk_option define -videoParameters videoParameters VideoParameters {}
	itk_option define -videoEnabled videoEnabled VideoEnabled 0

	itk_option define -detectorType detectorType DetectorType Q315CCD

	itk_option define -titleForeground titleForeground TitleForeground white

	itk_option define -slit0Upper slit0Upper Slit0Upper ""
	itk_option define -slit0Lower slit0Lower Slit0Lower ""
	itk_option define -slit0Left slit0Left Slit0left ""
	itk_option define -slit0Right slit0Right Slit0right ""

	#diffraction image viewer ports and host
	itk_option define  -imageServerHost imageServerHost ImageServerHost ""
	itk_option define  -imageServerHttpPort imageServerHttpPort ImageServerHttpPort ""

	itk_option define -periodicFile periodicFile PeriodicFile ""

   private variable m_deviceFactory
   private variable m_logger

    private variable m_dictStringList ""

	# public methods
	constructor { args } {
      global env
    global gIsDeveloper

    array set m_viewArray [list]

        set dictStringList [::config getList stringDictViewList]
        set m_dictStringList ""
        foreach d $dictStringList {
            eval lappend m_dictStringList $d
        }

      set m_deviceFactory [DCS::DeviceFactory::getObject]
      set m_logger [DCS::Logger::getObject]
 
      #look for the existence of the developer file which allows packing of different widgets
      set gIsDeveloper [file exists [join ~$env(USER)/.bluice/developer]]


		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add control {
			frame $itk_component(ring).c
		}


      itk_component add hutch {
         button $itk_component(control).hutch -text "Hutch" -command "$this launchHutchWidgets" -width 8
      } {
      }

      itk_component add collect {
         button $itk_component(control).cl -text "Collect" -command "$this launchCollectWidgets" -width 8
      } {
      }

      itk_component add screening {
         button $itk_component(control).sc -text "Screening" -command "$this launchScreeningWidgets" -width 8
      } {
      }

      itk_component add scan {
         button $itk_component(control).scan -text "Fl. Scan" -command [list $this openToolChest fluorescence] -width 8
      } {
      }

      itk_component add users {
         button $itk_component(control).u -text "Users" -command "$this launchUserWidgets" -width 8
      } {
      }


      set useRobot [::config getBluIceUseRobot]
      if { $useRobot } {
         itk_component add robotButton {
            button $itk_component(control).r -text "Robot" -command [list $this openToolChest robot] -width 8
         } {}
      }


		itk_component add toolChest {
			DCS::MenuEntry $itk_component(control).w -showEntry 0 \
            -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		$itk_component(toolChest) configure -fixedEntry "Tools"
		$itk_component(toolChest) configure -state normal -entryWidth 8 

        itk_component add devtoolChest {
            DCS::MenuEntry $itk_component(control).dw -showEntry 0 \
            -activeClientOnly 0 -systemIdleOnly 0
        } {
            keep -font
        }

        $itk_component(devtoolChest) configure -fixedEntry "Developer Tools"
        $itk_component(devtoolChest) configure -state normal -entryWidth 16 


		itk_component add selectView {
			DCS::MenuEntry $itk_component(control).b -showEntry 0 \
            -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		$itk_component(selectView) configure -fixedEntry "Views"
		$itk_component(selectView) configure -state normal -entryWidth 8 



		itk_component add selectString {
			DCS::MenuEntry $itk_component(control).ss -showEntry 0 \
            -activeClientOnly 0 -systemIdleOnly 0
		} {
			keep -font
		}

		$itk_component(selectString) configure -fixedEntry "System Data"
		$itk_component(selectString) configure -state normal -entryWidth 14


		itk_component add Mdi {
			DCS::MDICanvas $itk_component(ring).m $this -background white -relief sunken -borderwidth 2
		} {
		}

		itk_component add motorControl {
			DCS::MotorMoveView $itk_component(control).mc -mdiHelper $this -width 8
		} {
		}
		eval itk_initialize $args



		addTools
		addDevTools
		addViews
		addStrings [$m_deviceFactory getStringList] 
		
		pack $itk_component(ring) -expand yes -fill both
		#pack $itk_component(control)
		#pack $itk_component(toolChest) -side left -padx 5
		#pack $itk_component(selectView) -side left -padx 5
		#pack $itk_component(selectString) -side left -padx 5
		#pack $itk_component(motorControl) -side bottom -padx 5
		#pack $itk_component(Mdi) -expand yes -fill both


		pack $itk_component(control)
		grid $itk_component(hutch) -column 1 -row 0 
		grid $itk_component(collect) -column 2 -row 0 
		grid $itk_component(screening) -column 3 -row 0 
		grid $itk_component(scan) -column 4 -row 0 
		grid $itk_component(users) -column 5 -row 0 
		if { $useRobot} {grid $itk_component(robotButton) -column 6 -row 0} 
		grid $itk_component(toolChest) -column 7 -row 0 
		grid $itk_component(devtoolChest) -column 8 -row 0 
		grid $itk_component(selectView) -column 9 -row 0 

        if {$gIsDeveloper } {
		    grid $itk_component(selectString) -column 10 -row 0 
        }
		grid $itk_component(motorControl) -column 0 -row 2 -columnspan 11 

		pack $itk_component(Mdi) -expand yes -fill both

	}
}


body SetupTab::launchHutchWidgets {} {
   openToolChest hutchOverview
   openToolChest video
   openToolChest resolution
}

body SetupTab::launchCollectWidgets {} {
   openToolChest diffImageViewer
   openToolChest runView 
}


body SetupTab::launchScreeningWidgets {} {
   #openToolChest sequenceCrystals  
   #openToolChest sequenceActions
   #openToolChest screeningControl 
   openToolChest screeningTab
}

body SetupTab::launchUserWidgets {} {
   openToolChest clientList  
   openToolChest changeover
}


body SetupTab::addViews {} {
   set beamlineViewList [::config getBeamlineViewList]

   foreach viewList $beamlineViewList {
      foreach view $viewList {
         switch $view {
         detectorPosition {

	         $itk_component(selectView) add command \
               -label "Detector Position"	\
               -command [list $this openToolChest detectorPosition]

             set widget_name $view
             set widget_class DCS::DetectorPositionView
         }
         goniometer {
            $itk_component(selectView) add command \
               -label "Goniometer"	\
               -command [list $this openToolChest goniometer]

             set widget_name $view
             set widget_class [::config getStr bluice.gonioView]
         }
         table {
            $itk_component(selectView) add command \
               -label "Table"	\
               -command [list $this openToolChest table]

             set widget_name $view
             set widget_class DCS::TableWidget
         }
         wbcontrol {
            $itk_component(selectView) add command \
               -label "wbcontrol Control"	\
               -command [list $this openToolChest wbcontrol]

             set widget_name $view
             set widget_class DCS::WBControlWidget
         }
         goniomotions {
            $itk_component(selectView) add command \
               -label "Gonio Motions"	\
               -command [list $this openToolChest goniomotions]

             set widget_name $view
             set widget_class DCS::GonioMotionsWidget
         }
	 myTestWidget {
             $itk_component(selectView) add command \
                -label "My Test Widget" \
                -command [list $this openToolChest myTestWidget]

             set widget_name $view
             set widget_class DCS::MyTestWidget
         }
         frontEndSlits {
            $itk_component(selectView) add command \
               -label "Front End Slits"	\
		         -command [list $this openToolChest frontEndSlits]

             set widget_name $view
             set widget_class DCS::FrontEndSlitsView
         }
         frontEndApertures {
            $itk_component(selectView) add command \
               -label "Front End Apertures"	\
               -command [list $this openToolChest frontEndApertures]

             set widget_name $view
             set widget_class [::config getStr bluice.$view]
             if {$widget_class == ""} {
                set widget_class DCS::FrontEndApertureView
             }
         }
         slit1Aperture {
            $itk_component(selectView) add command \
               -label "Slit 1 Aperture"	\
               -command [list $this openToolChest slitAperture]

             set widget_name $view
             set widget_class [::config getStr bluice.$view]
             if {$widget_class == ""} {
                set widget_class DCS::FrontEndSlit1ApertureView
             }
         }
         mirrorView {
	         $itk_component(selectView) add command \
		         -label "Mirror"	\
		         -command [list $this openToolChest mirror]

             set widget_name mirror
             set widget_class [::config getMirrorView]
         }
         mirrorApertureView {
	         $itk_component(selectView) add command \
		         -label "MirrorAperture"	\
		         -command [list $this openToolChest mirror_aperture]

             set widget_name mirror_aperture
             set widget_class [::config getMirrorApertureView]
         }
         toroid {
	         $itk_component(selectView) add command \
		      -label "Toroid"	\
		      -command [list $this openToolChest toroid]

             set widget_name toroid
             set widget_class [::config getToroidView]
         }
         monoView {
            $itk_component(selectView) add command \
		         -label "Monochromator"	\
		         -command [list $this openToolChest mono]

             set widget_name mono
             set widget_class [::config getMonoView]
         }
         monoApertureView {
            $itk_component(selectView) add command \
		         -label "MonoAperture"	\
		         -command [list $this openToolChest mono_aperture]

             set widget_name mono_aperture
             set widget_class [::config getMonoApertureView]
         }
         slit0 {
            $itk_component(selectView) add command \
               -label "Stopper Slits"	\
               -command [list $this openToolChest slit0]

             set widget_name $view
             set widget_class DCS::Slit0View
         }
         hutchOverview {
            $itk_component(selectView) add command \
		         -label "Hutch Overview"	\
		         -command [list $this openToolChest hutchOverview]

             set widget_name $view
             set widget_class [::config getHutchView]
         }
         focusingMirrorsView {
            $itk_component(selectView) add command \
               -label "Focusing Mirrors"	\
               -command [list $this openToolChest focusing_mirrors]

             set widget_name focusing_mirrors
             set widget_class [::config getStr bluice.focusingMirrorsView]
         }
         mardtb {
            $itk_component(selectView) add command \
            -label "Mar DTB" \
            -command [list $this openToolChest mardtb]
            set widget_name $view
            set widget_class DCS::MarDTBView
         }
         inlineMotorView {
            $itk_component(selectView) add command \
            -label "Inline Motor View" \
            -command [list $this openToolChest inline_motor_view]
            set widget_name inline_motor_view
            set widget_class BLUICE::InlineMotorWidget
         }
	 sampleMotorView {
            $itk_component(selectView) add command \
            -label "Sample Motor View" \
            -command [list $this openToolChest sample_motor_view]
            set widget_name sample_motor_view
            set widget_class BLUICE::SampleMotorWidget
         }
         microSpecMotorView {
            $itk_component(selectView) add command \
            -label "MicroSpec Motor Staff View" \
            -command [list $this openToolChest microspec_staff_view]
            #set widget_name microspec_motor_view
            #set widget_class DCS::MicroSpecMotorView
            set widget_name microspec_staff_view 
            set widget_class DCS::MicroSpecStaffView
         }
         collimatorMotorView {
            $itk_component(selectView) add command \
            -label "Collimator Motor View" \
            -command [list $this openToolChest collimator_motor_view]
            set widget_name collimator_motor_view 
            set widget_class DCS::CollimatorMotorView
         }
         default {
            $m_logger logWarning "Could not find beamline view $view."

            set widget_name ""
            set widget_class ""
         }
         }
         if {$widget_name != "" && $widget_class != ""} {
            set motorList [${widget_class}::getMotorList]

            lappend m_viewList $widget_name
            set m_viewArray($widget_name,class) $widget_class
            set m_viewArray($widget_name,motorList) $motorList
            #puts "view: $widget_name: list:$motorList"
         }
      }
   }
}

body SetupTab::addTools {} {
      set beamline [::config getConfigRootName]

    $itk_component(toolChest) add command \
    -label "Annealing Configuration"    \
    -command [list $this openToolChest anneal_config]

    set showASC [::config getStr show.auto_sample_cal]
    ### default is show
    if {$showASC != "0"} {
        $itk_component(toolChest) add command \
        -label "Auto Sample Calibration"    \
        -command [list $this openToolChest auto_sample]
    }

    $itk_component(toolChest) add command \
    -label "Burn Paper"    \
    -command [list $this openToolChest burn_paper]

    $itk_component(toolChest) add command \
         -label "Cassette Owner"    \
         -command [list $this openToolChest cassetteOwner]

    $itk_component(toolChest) add command \
    -label "Center Crystal"    \
    -command [list $this openToolChest center_crystal]

    $itk_component(toolChest) add command \
    -label "Center Slits"    \
    -command [list $this openToolChest center_slits]

    $itk_component(toolChest) add command \
         -label "Change-Over Assistant"    \
         -command [list $this openToolChest changeover]

    $itk_component(toolChest) add command \
    -label "Command Prompt"    \
    -command [list $this openToolChest command_prompt]

    $itk_component(toolChest) add command \
    -label "Cryojet Control"    \
    -command [list $this openToolChest cryojet_control]

    $itk_component(toolChest) add command \
    -label "Default Parameters"    \
    -command [list $this openToolChest default_parameter]

    $itk_component(toolChest) add command \
         -label "Detector Control"    \
         -command [list $this openToolChest detectorControl]

    $itk_component(toolChest) add command \
         -label "Diffraction Image Viewer"    \
         -command [list $this openToolChest diffImageViewer]

    $itk_component(toolChest) add command \
        -label "Encoder Position File"    \
         -command [list $this openToolChest encoder_file]

    $itk_component(toolChest) add command \
       -label "Exposure Control"    \
       -command [list $this openToolChest dose_control]
##################################################################################
    $itk_component(toolChest) add command \
       -label "Libera Control"    \
       -command [list $this openToolChest libera_control]

##################################################################################

    $itk_component(toolChest) add command \
         -label "File Viewer"    \
         -command [list $this openToolChest fileViewer]

    set showGap [::config getStr show.gap_owner]
    if {$showGap == "1"} {
        $itk_component(toolChest) add command \
        -label "Gap Ownership"    \
        -command [list $this openToolChest gapControl]
    }

    if {[$m_deviceFactory stringExists inline_sample_camera_constant]} {
        $itk_component(toolChest) add command \
        -label "Inline Camera Parameters"    \
        -command [list $this openToolChest inline_sample_camera_param]
    }

    if {[$m_deviceFactory stringExists inline_sample_camera_h_constant]} {
        $itk_component(toolChest) add command \
        -label "Inline Camera High R Parameters"    \
        -command [list $this openToolChest inline_sample_camera_h_param]
    }

    $itk_component(toolChest) add command \
        -label "Ion Chamber Counts File"    \
         -command [list $this openToolChest ion_chamber_file]

    $itk_component(toolChest) add command \
    -label "Laser Control"    \
    -command [list $this openToolChest laser_control]

    $itk_component(toolChest) add command \
    -label "LogSender"    \
    -command [list $this openToolChest logSender]

    set showLVDT [::config getStr "show.lvdt"]
    if {$showLVDT == "1"} {
        $itk_component(toolChest) add command \
        -label "LVDT Display"    \
        -command [list $this openToolChest lvdt_display]
    }

    $itk_component(toolChest) add command \
        -label "Mega Screening"    \
         -command [list $this openToolChest mega_screening]

    $itk_component(toolChest) add command \
        -label "Motor Config Restore"    \
         -command [list $this openToolChest motor_config_file]

    $itk_component(toolChest) add command \
        -label "Motor Position File"    \
         -command [list $this openToolChest motor_file]

    $itk_component(toolChest) add command \
    -label "Notify Setup"    \
    -command [list $this openToolChest notify_setup]

    $itk_component(toolChest) add command \
        -label "Optimized Energy Parameters"    \
         -command [list $this openToolChest optimizedEnergyParameterGui]

    $itk_component(toolChest) add command \
    -label "Raster Configuration"    \
    -command [list $this openToolChest rastering_config]

    $itk_component(toolChest) add command \
    -label "Repeat Mounting Test"    \
    -command [list $this openToolChest repeat_mount]

    $itk_component(toolChest) add command \
         -label "Resolution Calculator"    \
         -command [list $this openToolChest resolution]

    $itk_component(toolChest) add command \
    -label "Sample Camera Parameters"    \
    -command [list $this openToolChest sample_camera_param]

    $itk_component(toolChest) add command \
         -label "Shutter"    \
         -command [list $this openToolChest shutter]

    $itk_component(toolChest) add command \
         -label "Video"    \
         -command [list $this openToolChest video]

    $itk_component(toolChest) add command \
         -label "Video System Explorer"    \
         -command [list $this openToolChest videoExplorer]


    $itk_component(toolChest) add command \
        -label "Xray Sample Search"    \
         -command [list $this openToolChest xraySampleSearch]
}
body SetupTab::addDevTools {} {
      set beamline [::config getConfigRootName]

    $itk_component(devtoolChest) add command \
    -label "Align Front End"    \
    -command [list $this openToolChest align_front_end]

    $itk_component(devtoolChest) add command \
    -label "BarcodeView"    \
    -command [list $this openToolChest barcode_view]

    $itk_component(devtoolChest) add command \
    -label "BeamSize"    \
    -command [list $this openToolChest beam_size]

    $itk_component(devtoolChest) add command \
    -label "BeamSize Entry"    \
    -command [list $this openToolChest beam_size_entry]

    $itk_component(devtoolChest) add command \
    -label "BeamSize Parameter"    \
    -command [list $this openToolChest beam_size_parameter]

    $itk_component(devtoolChest) add command \
    -label "Blu-Ice"    \
    -command [list $this openToolChest blu-ice] 

    $itk_component(devtoolChest) add command \
    -label "CassetteView"    \
    -command [list $this openToolChest cassette_view]

    $itk_component(devtoolChest) add command \
    -label "CollimatorMenuEntry"    \
    -command [list $this openToolChest collimator_entry]

    $itk_component(devtoolChest) add command \
    -label "Collimator Preset DEBUG"    \
    -command [list $this openToolChest collimator_preset_debug]

    $itk_component(devtoolChest) add command \
    -label "DCSS Admin"    \
    -command [list $this openToolChest dcss_admin]

    set energyConfig [::config getStr "energy.config"]
    if {$energyConfig != ""} {
        $itk_component(devtoolChest) add command \
        -label "Energy Component Config"    \
        -command [list $this openToolChest config_energy]
    }

    $itk_component(devtoolChest) add command \
    -label "EventView"    \
    -command [list $this openToolChest event_view]

    $itk_component(devtoolChest) add command \
    -label "GridCanvas"    \
    -command [list $this openToolChest grid_canvas]

    $itk_component(devtoolChest) add command \
    -label "Grid Node List"    \
    -command [list $this openToolChest grid_node_list]

    $itk_component(devtoolChest) add command \
    -label "Grid User Setup"    \
    -command [list $this openToolChest grid_input]

    $itk_component(devtoolChest) add command \
    -label "Grid Video"    \
    -command [list $this openToolChest grid_video]

    $itk_component(devtoolChest) add command \
    -label "Inline Camera Preset"    \
    -command [list $this openToolChest inline_preset]

    $itk_component(devtoolChest) add command \
    -label "Inline Motor View"    \
    -command [list $this openToolChest inline_motor_view]

    $itk_component(devtoolChest) add command \
    -label "Sample Motor View"    \
    -command [list $this openToolChest sample_motor_view]

    $itk_component(devtoolChest) add command \
    -label "L614 SoftLink Control"    \
    -command [list $this openToolChest softlink_setup]

    $itk_component(devtoolChest) add command \
    -label "Light Control"    \
    -command [list $this openToolChest light_control]

    $itk_component(devtoolChest) add command \
    -label "Logger"    \
    -command [list $this openToolChest logger]

    $itk_component(devtoolChest) add command \
    -label "Login"    \
    -command [list $this openToolChest login]

    $itk_component(devtoolChest) add command \
    -label "Loop Center Error Threshold"    \
    -command [list $this openToolChest loop_center_error]

    $itk_component(devtoolChest) add command \
    -label "MicroSpec Staff View"    \
    -command [list $this openToolChest microspec_staff_view]

    $itk_component(devtoolChest) add command \
    -label "Move Crystal"    \
    -command [list $this openToolChest move_crystal]

    $itk_component(devtoolChest) add command \
    -label "Motor Lock View"    \
    -command [list $this openToolChest motor_lock_view]

    set showOffset [::config getStr "show.energy_offset"]
    if {$showOffset == "1"} {
        $itk_component(devtoolChest) add command \
        -label "Offsets from Energy"    \
        -command [list $this openToolChest offset]
    }

    $itk_component(devtoolChest) add command \
    -label "OperationView"    \
    -command [list $this openToolChest operation_view]

    $itk_component(devtoolChest) add command \
    -label "RasterRunView"    \
    -command [list $this openToolChest raster_run_view]

    $itk_component(devtoolChest) add command \
    -label "RepositionView"    \
    -command [list $this openToolChest reposition_view]

    $itk_component(devtoolChest) add command \
    -label "Queue View"    \
    -command [list $this openToolChest queue_view]

    $itk_component(devtoolChest) add command \
    -label "RunViewForQueue"    \
    -command [list $this openToolChest queue_run_view]

    $itk_component(devtoolChest) add command \
    -label "RunPosition ViewForQueue"    \
    -command [list $this openToolChest queue_position_view]

    $itk_component(devtoolChest) add command \
    -label "RunList ViewForQueue"    \
    -command [list $this openToolChest queue_list_view]

    $itk_component(devtoolChest) add command \
    -label "Run PreViewForQueue"    \
    -command [list $this openToolChest queue_preview]

    $itk_component(devtoolChest) add command \
    -label "Run AdjustViewForQueue"    \
    -command [list $this openToolChest queue_adjust_view]

    $itk_component(devtoolChest) add command \
    -label "Run Top ViewForQueue"    \
    -command [list $this openToolChest queue_top_view]

    $itk_component(devtoolChest) add command \
    -label "Sequence Actions"    \
    -command [list $this openToolChest sequenceActions]

    $itk_component(devtoolChest) add command \
    -label "Sequence Crystals"    \
    -command [list $this openToolChest sequenceCrystals]

    $itk_component(devtoolChest) add command \
    -label "Screening Control"    \
    -command [list $this openToolChest screeningControl]

    $itk_component(devtoolChest) add command \
    -label "ScreeningTask"    \
    -command [list $this openToolChest screen_task]

    $itk_component(devtoolChest) add command \
    -label "Spectrometer"    \
    -command [list $this openToolChest spectrometer_view]

    $itk_component(devtoolChest) add command \
    -label "Spectrometer 4 Hardware"    \
    -command [list $this openToolChest spectrometer_hardware]

    $itk_component(devtoolChest) add command \
    -label "Spectrometer 4 Wrap"    \
    -command [list $this openToolChest spectrometer_wrap]

    $itk_component(devtoolChest) add command \
    -label "Spectrometer Status"    \
    -command [list $this openToolChest spectrometer_status]

    $itk_component(devtoolChest) add command \
    -label "Strip Pin Test"    \
    -command [list $this openToolChest stripper_view]

    $itk_component(devtoolChest) add command \
    -label "Trigger Time DEBUG"    \
    -command [list $this openToolChest trigger_time_view]

    $itk_component(devtoolChest) add command \
    -label "User Notify Setup"    \
    -command [list $this openToolChest userNotifySetupView]

    $itk_component(devtoolChest) add command \
    -label "Visex Image Staff View"    \
    -command [list $this openToolChest visex_image_view]

    $itk_component(devtoolChest) add command \
    -label "Visex Image User View"    \
    -command [list $this openToolChest visex_user_view]

    $itk_component(devtoolChest) add command \
    -label "Visex Tab"    \
    -command [list $this openToolChest visex_tab]

    if {[::config getStr bluice.amplifiers] != "" } {
        $itk_component(toolChest) add command \
        -label "Amplifiers"    \
        -command [list $this openToolChest amplifiers]
    }

}

body SetupTab::addStrings { stringNames_  } {

	foreach stringName $stringNames_ {
		$itk_component(selectString) add command \
			 -label $stringName	\
			 -command [list $this editString $stringName]
	}
}

body SetupTab::configureMotor { device_ } {
	
	set name [namespace tail $device_]

	if [checkAndActivateExistingDocument configure_$name] return


	set path [$itk_component(Mdi) addDocument configure_$name \
    -title "Configure $name" \
    -width 550 \
    -height 300 \
    -resizable 1 \
    ]
			
	switch [$device_ getMotorType] {
		pseudo {
			# construct
			itk_component add configure_$name {
				DCS::MotorConfigWidget $path.config -device $device_ \
					 -buttonBackground  #c0c0ff \
					 -activeButtonBackground  #c0c0ff \
					 -width 8 \
					 -mdiHelper $this
			} {
			}
		}
		real {
			# construct
			itk_component add configure_$name {
				DCS::RealMotorConfigWidget $path.config -device $device_ \
					 -buttonBackground  #c0c0ff \
					 -activeButtonBackground  #c0c0ff \
					 -width 8 -mdiHelper $this
			} {
			}
		}
	}

	pack $itk_component(configure_$name)
	pack $path
}

body SetupTab::scanMotor { device_ } {
    if {![info exists _widgetCount(scan)]} {
        set _widgetCount(scan) 0
    } else {
        incr _widgetCount(scan)
    }

    set instantName scan_$_widgetCount(scan)
	
	set name [namespace tail $device_]
	set path [$itk_component(Mdi) addDocument $instantName \
    -title "Scan Motor" -resizable 1 -width 1000 -height 450]

	itk_component add $instantName {
		DCS::ScanWidget $path.scan $device_ -mdiHelper $this
	} {
	}

	pack $itk_component($instantName)
	pack $path
}


body SetupTab::handleMotorSelection { name_ } {
   switch $name_ {
      gonio_phi {launchWidget hutchOverview}
      default {
         configureMotor [$m_deviceFactory getObjectName $name_]   
      }
   }
}

body SetupTab::openMotorView { device_  } {
    #puts "enter setup openMotorView"
    # if the motor is found in the view list, bring up the view
    # other wise open a simple motor view
    set view_name ""
    foreach view $m_viewList {
        set motorList $m_viewArray($view,motorList)
        #puts "search view: $view list:$motorList"
    
        if {[lsearch -exact $motorList $device_] >= 0} {
            #puts "found"
            set view_name $view
            break
        }
    }
    if {$view_name != ""} {
        #puts "openup $view_name"
        openToolChest $view_name
        return
    }

   ########### not found in the view, open a simple motor view

   set documentName motorView_$device_

   if [checkAndActivateExistingDocument $documentName] return

	set path [$itk_component(Mdi) addDocument $documentName -title "$device_"]

   itk_component add $documentName {
     ::DCS::SimpleMotorMoveView $path.mv \
          -autoGenerateUnitsList 1 \
          -activeClientOnly 1 \
          -units mm \
          -enableOnAnyClick 1 \
          -systemIdleOnly 0 \
          -labelText $device_ \
          -mdiHelper $this \
         -device [$m_deviceFactory getObjectName $device_]
   } {
          keep -background
   }

   pack $itk_component($documentName)
	pack $path
}

body SetupTab::openToolChest { name  } {
	#store the current pointer shape and set it to a watch/clock to show the system is busy

	blt::busy hold . -cursor watch
	update
	
   if {[catch {
	   launchWidget $name
   } err ] } {
      global errorInfo
      puts $errorInfo
   }

	blt::busy release .
}

body SetupTab::launchWidget { name  } {
    if {![info exists _widgetCount($name)]} {
        set _widgetCount($name) 0
    }


	switch $name {
		video {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Video" -resizable 1 -width 500 -height 300]
			
			itk_component add video {
				DCS::BeamlineVideoNotebook $path.v "" \
		         -imageUrl2 [::config getImageUrl 2] \
		         -imageUrl3 [::config getImageUrl 3] \
		         -imageUrl4 [::config getImageUrl 4] \
		         -textUrl2 [::config getTextUrl 2] \
		         -textUrl3 [::config getTextUrl 3] \
		         -textUrl4 [::config getTextUrl 4] \
		         -presetUrl2 [::config getPresetUrl 2] \
		         -presetUrl3 [::config getPresetUrl 3] \
		         -presetUrl4 [::config getPresetUrl 4] \
		         -moveRequestUrl2 [::config getMoveRequestUrl 2] \
		         -moveRequestUrl3 [::config getMoveRequestUrl 3] \
		         -moveRequestUrl4 [::config getMoveRequestUrl 4] \
		         -channelArgs2 [::config getVideoArgs 2] \
		         -channelArgs3 [::config getVideoArgs 3] \
		         -channelArgs4 [::config getVideoArgs 4] \
                 -beamWidthWidget $itk_option(-beamWidthDevice) \
                 -beamHeightWidget $itk_option(-beamHeightDevice)
			} {
				keep -videoParameters
				keep -videoEnabled
			}

			pack $itk_component(video) -expand 1 -fill both
			pack $path
            log_error The video widgets: $itk_component(video)
		}


		videoExplorer {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Video" -resizable 1 -width 580 -height 300]
			
			itk_component add videoExplorer {
				DCS::VideoSystemExplorer $path.v2 \
                 -baseVideoSystemUrl [::config getStr video.videoSystemUrl]
			} {
				keep -videoParameters
				keep -videoEnabled
			}

			pack $itk_component(videoExplorer) -expand 1 -fill both
			pack $path
		}


		resolution {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Resolution Calculator" -resizable 1 -width 450 -height 400 ]

			itk_component add $name {
				DCS::ResolutionControlWidget $path.res \
					 -detectorBackground  #c0c0ff \
					 -detectorForeground white \
					 -activeClientOnly 0 \
					 -systemIdleOnly 0 \
                     -honorStatus 0 \
					 -mdiHelper $this
			} {
				keep -detectorVertDevice
				keep -detectorHorzDevice
				keep -beamstopDevice
				keep -energyDevice
			}

			pack $itk_component(resolution) -expand 1 -fill both
			pack $path
		} 

		hutchOverview {
			if [checkAndActivateExistingDocument $name] return

         		set hutchClass [::config getHutchView]

			set path [$itk_component(Mdi) addDocument $name -title "Hutch Overview"]

			itk_component add $name {
				$hutchClass $path.hutch  -mdiHelper $this
			} {
				keep -detectorType -gonioPhiDevice -gonioOmegaDevice
				keep -gonioKappaDevice -detectorVertDevice
				keep -detectorHorzDevice -detectorZDevice -energyDevice
                                keep -attenuationDevice -beamWidthDevice -beamHeightDevice
				keep -beamstopDevice 
			}
			pack $itk_component($name)
			pack $path
		}


		table {
			if [checkAndActivateExistingDocument table] return

			set path [$itk_component(Mdi) addDocument $name -title "Table "]
			
			itk_component add $name {
            DCS::TableWidget $path.$name -mdiHelper $this
         } {
			}      

			pack $itk_component($name)
			pack $path
		}

		wbcontrol {
			if [checkAndActivateExistingDocument wbcontrol] return

			set path [$itk_component(Mdi) addDocument $name -title "Wbcontrol"]
			
			itk_component add $name {
            DCS::WBControlWidget $path.$name -mdiHelper $this
         } {
			}      

			pack $itk_component($name)
			pack $path
		}

		goniomotions {
			if [checkAndActivateExistingDocument goniomotions] return

			set path [$itk_component(Mdi) addDocument $name -title "Goniomotions"]
			
			itk_component add $name {
            DCS::GonioMotionsWidget $path.$name -mdiHelper $this
         } {
			}      

			pack $itk_component($name)
			pack $path
		}

	myTestWidget {
            puts "Open myTestWidget.."
            if [checkAndActivateExistingDocument myTestWidget] return

            set path [$itk_component(Mdi) addDocument $name -title "My Test Widget Title"]

            itk_component add $name {
                DCS::MyTestWidget $path.$name -mdiHelper $this
            } {
            }

            pack $itk_component($name)
            pack $path
        }


		slit0 {
			if [checkAndActivateExistingDocument slit0] return

			set path [$itk_component(Mdi) addDocument $name -title "Stopper Slits"]
			
			itk_component add $name {
				DCS::Slit0View $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}


		frontEndSlits {
			if [checkAndActivateExistingDocument frontEndSlits] return

			set path [$itk_component(Mdi) addDocument $name -title "Hutch Front End Slits"]
			
			itk_component add $name {
				DCS::FrontEndSlitsView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		frontEndApertures {
			if [checkAndActivateExistingDocument frontEndApertures] return

			set path [$itk_component(Mdi) addDocument $name -title "Front End Apertures"]
			
             set widget_class [::config getStr bluice.$name]
             if {$widget_class == ""} {
                set widget_class DCS::FrontEndApertureView
             }
			itk_component add $name {
				$widget_class $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		slitAperture {
			if [checkAndActivateExistingDocument slitAperture] return

			set path [$itk_component(Mdi) addDocument $name -title "Slit 1 Aperture"]
			
             set widget_class [::config getStr bluice.$name]
             if {$widget_class == ""} {
                set widget_class DCS::FrontEndSlit1ApertureView
             }
			itk_component add $name {
				$widget_class $path.$name \
                -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		detectorPosition {
			if [checkAndActivateExistingDocument detectorPosition] return
			set path [$itk_component(Mdi) addDocument $name -title "Detector Position"]
			
			itk_component add $name {
				DCS::DetectorPositionView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}


		goniometer {
			if [checkAndActivateExistingDocument goniometer] return

			set path [$itk_component(Mdi) addDocument $name -title "Goniometer"]
			
            set gonioView [::config getStr bluice.gonioView]
			itk_component add $name {
				$gonioView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		mono {
			if [checkAndActivateExistingDocument mono] return
            set monoView [::config getMonoView]
            if {$monoView == ""} return

			set path [$itk_component(Mdi) addDocument $name -title "Monochromator" -resizable 0]
			

			itk_component add $name {
				$monoView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		mono_aperture {
			if [checkAndActivateExistingDocument $name] return
            set monoView [::config getMonoApertureView]
            if {$monoView == ""} return

			set path [$itk_component(Mdi) addDocument $name -title "MonoAperture" -resizable 0]
			

			itk_component add $name {
				$monoView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

		toroid {
			if [checkAndActivateExistingDocument toroid] return
            set monoView [::config getToroidView]
            if {$monoView == ""} return

			#pack the hutch overview widget in the titled frame
			set path [$itk_component(Mdi) addDocument $name -title "Toroid" -resizable 1 -width 760 -height 350]

			#pack the hutch overview widget in the titled frame
			itk_component add $name {
				$monoView $path.$name -mdiHelper $this
			} {
			}

			pack $itk_component($name)
			pack $path
		}

	
		mirror {
			if [checkAndActivateExistingDocument mirror] return
            set mirrorView [::config getMirrorView]
            if {$mirrorView == ""} return

			set path [$itk_component(Mdi) addDocument $name -title "Mirror" -resizable 0]
		
	
			#pack the hutch overview widget in the titled frame
			itk_component add $name {
				$mirrorView $path.$name -mdiHelper $this
			} {
			}


			pack $itk_component($name)
			pack $path
		}
	
		mirror_aperture {
			if [checkAndActivateExistingDocument $name] return
            set mirrorView [::config getMirrorApertureView]
            if {$mirrorView == ""} return

			set path [$itk_component(Mdi) addDocument $name -title "MirrorAperture" -resizable 0]
		
	
			#pack the hutch overview widget in the titled frame
			itk_component add $name {
				$mirrorView $path.$name -mdiHelper $this
			} {
			}


			pack $itk_component($name)
			pack $path
		}
	
		fluorescence {
			if [checkAndActivateExistingDocument fl_scan] return
			set path [$itk_component(Mdi) addDocument fl_scan -title "Fluorescence Scan"  -resizable 1 -width 965 -height 545]

			itk_component add fl_scan {
				ScanTab $path.mad
			} {
				keep -periodicFile
			}
			
			pack $itk_component(fl_scan) -fill both -expand 1
			pack $path
		} 

		login {
			if [checkAndActivateExistingDocument login] return

			set path [$itk_component(Mdi) addDocument login -title "Login"  -resizable 0]

			#pack the resolution in the titled widget
			itk_component add login {
				DCS::Login $path.login
			} {
			}
			
			pack $itk_component(login)
			pack $path
		} 


		fileViewer {
			if [checkAndActivateExistingDocument fileViewer] return

			blt::busy release .

			set path [$itk_component(Mdi) addDocument fileViewer -title "File Viewer"  -resizable 1  -width 600 -height 300]

			#pack the resolution in the titled widget
			itk_component add fileViewer {
				SequenceResultList $path.fv
			} {
			}
			
			#$itk_component(fileViewer) createFileList

			pack $itk_component(fileViewer)
			pack $path
		} 


		sequenceCrystals {
			if [checkAndActivateExistingDocument sequenceCrystals] return

			set path [$itk_component(Mdi) addDocument sequenceCrystals -title "Crystal Sequence"  -resizable 1  -width 600 -height 300]

			itk_component add sequenceCrystals {
				SequenceCrystals $path.sc
			} {
			}
			
			pack $itk_component(sequenceCrystals) -expand 1 -fill both
			pack $path
		}

		sequenceActions {
			if [checkAndActivateExistingDocument sequenceActions] return

			set path [$itk_component(Mdi) addDocument sequenceActions -title "Screening Actions"  -resizable 1  -width 600 -height 300]
			
         itk_component add sequenceActions {
			ScreeningSequenceConfig $path.sa
         } {}

			pack $itk_component(sequenceActions) -expand 1 -fill both
			pack $path
		}

		screeningControl {
			if [checkAndActivateExistingDocument screeningControl] return
			
			set path [$itk_component(Mdi) addDocument screeningControl -title "Screening Control"]
			
			itk_component add screeningControl {
				ScreeningControl $path.sc
			} {}
			
			pack $itk_component(screeningControl) -expand 1 -fill both
			pack $path
		}


		screeningTab {
			if [checkAndActivateExistingDocument screeningTab] return
			
			set path [$itk_component(Mdi) addDocument screeningTab -title "Screening Tab" -resizable 1 -width 800 -height 600]
			
			itk_component add screeningTab {
				ScreeningTab $path.st
			} {}
			
			pack $itk_component(screeningTab) -expand 1 -fill both
			pack $path
		}




		diffImageViewer {
			set path [$itk_component(Mdi) addDocument \
            diffImageViewer_$_widgetCount($name) \
            -title "Diffraction Image Viewer" -resizable 1 -width 500 -height 500]

			itk_component add diffImageViewer_$_widgetCount($name) {
				DiffImageViewer $path.diff -width 500 -height 500 
         } {keep -imageServerHost -imageServerHttpPort}
				
			pack $itk_component(diffImageViewer_$_widgetCount($name)) \
            -expand 1 -fill both
			pack $path
			incr _widgetCount($name)
		}

		runView {

			if [checkAndActivateExistingDocument runView] return

			set path [$itk_component(Mdi) addDocument runView -title "Run View" -resizable 1 -width 600 -height 600]

			itk_component add runView {
			   DCS::CollectView $path.rv
			} {}
			
			pack $itk_component(runView)  -expand 1 -fill both
			pack $path
		} 

       	robot {
			if [checkAndActivateExistingDocument robot] return

			set path [$itk_component(Mdi) addDocument robot -title "Robot Control"  -resizable 1  -width 800 -height 500]

			itk_component add robot {
				RobotControlWidget $path.rbt -mdiHelper "$this"
		} {
		}
			
			pack $itk_component(robot) -expand 1 -fill both
			pack $path
       	}

       	cassette_view {
			if [checkAndActivateExistingDocument cassette_view] return

			set path [$itk_component(Mdi) addDocument cassette_view -title "Cassette Status"  -resizable 1  -width 500 -height 400]

			itk_component add cassette_view {
				RobotMountWidget $path.casv -mdiHelper "$this"
			} {
			}
			
			pack $itk_component(cassette_view) -expand 1 -fill both
			pack $path
       	}

       	barcode_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Barcode View"  -resizable 1  -width 700 -height 250]

			itk_component add $name {
				BarcodeView $path.casv
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
       	}

       	stripper_view {
			if [checkAndActivateExistingDocument stripper_view] return

			set path [$itk_component(Mdi) addDocument stripper_view -title "Strip Pin Test"  -resizable 1  -width 200 -height 150]

			itk_component add stripper_view {
				RobotStripperWidget $path.casv -mdiHelper "$this"
			} {
			}
			
			pack $itk_component(stripper_view) -expand 1 -fill both
			pack $path
       	}

       	event_view {
			if [checkAndActivateExistingDocument event_view] return

			set path [$itk_component(Mdi) addDocument event_view -title "EventLog View"  -resizable 1  -width 800 -height 600]

			itk_component add event_view {
				EventViewWidget $path.elv -mdiHelper "$this"
			} {
			}
			
			pack $itk_component(event_view) -expand 1 -fill both
			pack $path
       	}

		operation_view {
            set ov_name ${name}_$_widgetCount($name)
            set path [$itk_component(Mdi) addDocument $ov_name -title "Generic Operation View"  -resizable 1  -width 600 -height 300]

            itk_component add $ov_name {
                DCS::OperationView $path.gov -badletter {;[$\]\\}
            } {
            }
            
            pack $itk_component($ov_name) -expand 1 -fill both
            incr _widgetCount($name)
        }

		getgoniodata {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Data for Goniometer CAL"  -resizable 1  -width 600 -height 300]

			itk_component add $name {
				DCS::OperationView $path.gov -operation "ISampleMountingDevice getGonioCALDATA" -editable 0
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

		clientList {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Users"  -resizable 1  -width 600 -height 300]

			itk_component add $name {
				ClientStatusView $path.u 
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

		changeover {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Change-Over Assistant"  -resizable 0 ]

            itk_component add $name {
                ChangeOverWidget $path.change_over
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

		motor_file {
            set mf_name ${name}_$_widgetCount($name)
            incr _widgetCount($name)

			set path [$itk_component(Mdi) addDocument $mf_name -title "Motor File Utilities"  -resizable 1 -width 650 -height 700]

            itk_component add $mf_name {
                MotorFileWidget $path.motor_file -mdiHelper "$this"
            } {
            }
			pack $itk_component($mf_name) -expand 1 -fill both
        }

		motor_config_file {
            set mcf_name ${name}_$_widgetCount($name)
            incr _widgetCount($name)

			set path [$itk_component(Mdi) addDocument $mcf_name -title "Database File Utilities"  -resizable 1 -width 650 -height 700]

            itk_component add $mcf_name {
                MotorConfigFileWidget $path.motor_file -mdiHelper "$this"
            } {
            }
			pack $itk_component($mcf_name) -expand 1 -fill both
        }


		detectorControl {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Detector Control"  -resizable 0 ]

			itk_component add $name {
				DCS::DetectorControl $path.dc
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

		logger {
         set logger_name logger_$_widgetCount($name)
			set path [$itk_component(Mdi) addDocument $logger_name -title "Logger"  -resizable 1 -width 600 -height 300]

			itk_component add $logger_name {
				DCS::LogView $path.log -showControls 1
			} {
			}
			
			pack $itk_component($logger_name) -expand 1 -fill both
            incr _widgetCount($name)
        }

        logSender {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Log Sender"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				LogSender $path.ls
			} {
			}
			pack $itk_component($name) -expand 1 -fill both
        }

        dcss_admin {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "DCSS Admin"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				Admin $path.ad
			} {
			}
			pack $itk_component($name) -expand 1 -fill both
        }

        dose_control {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "Exposure Control"  -resizable 1  -width 900 -height 220]

			itk_component add $name {
				DCS::DoseDetailView $path.$name
			} {
			}
			pack $itk_component($name) -expand 1 -fill both
        }

	libera_control {
                        if [checkAndActivateExistingDocument $name] return
                        set path [$itk_component(Mdi) addDocument $name \
                            -title "Libera Control"  -resizable 1  -width 750 -height 600]

                        itk_component add $name {
                                DCS::LiberaDetailView $path.$name
                        } {
                        }
                        pack $itk_component($name) -expand 1 -fill both
       }

        PlotWin1 {
                        if [checkAndActivateExistingDocument $name] return
                        set path [$itk_component(Mdi) addDocument $name \
                            -title "Plot window 1"  -resizable 1  -width 1550 -height 600]

                        itk_component add $name {
                                DCS::PlotWin1 $path.$name
                        } {
                        }
                        pack $itk_component($name) -expand 1 -fill both
       }


        screen_task {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name \
            -title "Screening Task"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				ScreeningTaskWidget $path.ad
			} {
			}
			pack $itk_component($name) -expand 1 -fill both
        }

		xraySampleSearch {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Xray Sample Search"  -resizable 0]

			itk_component add $name {
				DCS::XraySampleSearchGui $path.xraysearch 
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

		optimizedEnergyParameterGui {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Optimized Energy Parameters (Current)"  -resizable 0]

			itk_component add $name {
                set obj [DCS::OptimizedEnergyParams::getObject]
				DCS::OptimizedEnergyGui $path.optimizedEnergy $obj $obj
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        auto_sample {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Auto Sample Calibration"  -resizable 1 -width 400 -height 400]

			itk_component add $name {
				AutoSampleWidget $path.optimizedEnergy 
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        sample_anneal {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Sample Anneal"  -resizable 1 -width 440 -height 30]

			itk_component add $name {
				AnnealWidget $path.$name \
                -systemIdleOnly 1 \
                -activeClientOnly 1
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        anneal_config {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Annealing Configuration"  -resizable 1 -width 300 -height 200]

			itk_component add $name {
				AnnealConfigWidget $path.$name \
                -systemIdleOnly 1 \
                -activeClientOnly 1
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        cryojet_control {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Cryojet Control"  -resizable 1 -width 400 -height 350]

			itk_component add $name {
				CryojetWidget $path.$name \
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        command_prompt {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Command Prompt"  -resizable 1 -width 1200 -height 30]

			itk_component add $name {
				DCS::CommandPrompt $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        laser_control {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Laser Control"  -resizable 1 -width 880 -height 120]

			itk_component add $name {
				LaserControlWidget $path.$name \
                -systemIdleOnly 1 \
                -activeClientOnly 1
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        center_crystal {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Center Crystal"  -resizable 1  -width 600 -height 500]

			itk_component add $name {
				centerCrystalView $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        center_slits {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Center Slits"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				centerSlitsView $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        burn_paper {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Burn Paper"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				burnPaperView $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        repeat_mount {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Rpeat Mounting Test"  -resizable 1  -width 600 -height 600]

			itk_component add $name {
				repeatMountWidget $path.ls -mdiHelper "$this" \
                -activeClientOnly 1 \
                -systemIdleOnly 1
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        notify_setup {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Notify Setup"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				NotifyView $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        default_parameter {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Default Parameters"  -resizable 1  -width 800 -height 600]

			itk_component add $name {
				DefaultParamWidget $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        inline_light_control {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Inline Light Control"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
                InlineLightControlWidget $path.control -mdiHelper $this
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        inline_motor_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Inline Motor View"  -resizable 1  -width 600 -height 300]

			itk_component add $name {
                BLUICE::InlineMotorWidget $path.control -mdiHelper $this
		    } {
                keep -videoParameters
                keep -videoEnabled
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
			$itk_component($name) configure \
            -videoEnabled 1
        }

        sample_motor_view {
                        if [checkAndActivateExistingDocument $name] return

                        set path [$itk_component(Mdi) addDocument $name -title "Sample Motor View"  -resizable 1  -width 600 -height 300]

                        itk_component add $name {
                BLUICE::SampleMotorWidget $path.control
                    } {
                keep -videoParameters
                keep -videoEnabled
                    }

                        pack $itk_component($name) -expand 1 -fill both
                        pack $path
                        $itk_component($name) configure \
            -videoEnabled 1
        }

        light_control {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Light Control"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
                LightControlWidget $path.control
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        loop_center_error {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Loop Center Error Threshold"  -resizable 1  -width 400 -height 100]

			itk_component add $name {
                LoopCenterErrorWidget $path.control
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        beam_size {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Beam Size"  -resizable 1  -width 500 -height 100]

			itk_component add $name {
                BeamSizeView $path.control \
				-activeClientOnly 0 \
				-systemIdleOnly 0 \
                -honorStatus 0
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        beam_size_entry {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Beam Size Entry"  -resizable 1  -width 500 -height 100]

			itk_component add $name {
                BeamSizeEntry $path.control \
				-activeClientOnly 0 \
				-systemIdleOnly 0 \
                -honorStatus 0
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

		focusing_mirrors {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Focusing Mirrors"  -resizable 0]
            set widget_class [::config getStr bluice.focusingMirrorsView]

            itk_component add $name {
                $widget_class $path.$name -mdiHelper $this
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        gapControl {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Gap Ownership"  -resizable 1 -width 600 -height 240]

			itk_component add $name {
				GapControlWidget $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        lvdt_display {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "LVDT Display"  -resizable 1 -width 600 -height 250]

			itk_component add $name {
				DCS::LVDTViewForBL122 $path.$name \
                -background black \
                -font "helvetica -24 bold" \
                -valueForeground #ffc080 \
                -valueBackground #603030 \
		-component ::device::analogInStatus1 \
               -attribute contents
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        cassetteOwner {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Cassette Owner"  -resizable 1 -width 600 -height 180]

			itk_component add $name {
				DCS::CassetteOwnerView $path.$name \
                -systemIdleOnly 0 \
                -activeClientOnly 0 \
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        shutter {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Shutters"  -resizable 1 -width 400 -height 480]

			itk_component add $name {
				ShutterControlWidget $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        mardtb {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Mar DTB"  -resizable 1 -width 700 -height 350]

			itk_component add $name {
				DCS::MarDTBView $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        mega_screening {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Mega Screening"  -resizable 1 -width 700 -height 350]

			itk_component add $name {
				MegaScreeningView $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        move_crystal {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Move Crystal"  -resizable 1 -width 800 -height 350]

			itk_component add $name {
				MoveCrystalSelectWidget $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        motor_lock_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Motor Lock View"  -resizable 1 -width 800 -height 600]

			itk_component add $name {
				MotorLockView $path.$name \
                -motorList [list gonio_phi sample_x sample_y sample_z]
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        encoder_file {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Encoder Position File"  -resizable 1 -width 600 -height 700]

			itk_component add $name {
				EncoderFileWidget $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        ion_chamber_file {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Ion Chamber Counts File"  -resizable 1 -width 700 -height 500]

			itk_component add $name {
				IonChamberFileWidget $path.$name
			} {
			}
			
			pack $itk_component($name) -expand 1 -fill both
        }

        align_front_end {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Align Front End"  -resizable 1  -width 1050 -height 600]

            set widget_name alignFrontEndView
            set cfgName [::config getStr "bluice.alignFrontEndView"]
            if {$cfgName != ""} {
                set widget_name $cfgName
            }

			itk_component add $name {
				$widget_name $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        amplifiers {
            if [checkAndActivateExistingDocument $name] return
            set path [$itk_component(Mdi) addDocument $name -title "Amplifiers"  -resizable 1 -width 850 -height 350]

            itk_component add $name {
                DCS::AmplifierNotebook $path.ampNotebook
            } {
            }

            pack $itk_component($name) -expand 1 -fill both
        }

		offset {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Offsets From Energy"  -resizable 0 ]

            itk_component add $name {
                DCS::EnergyOffsetLevel2View $path.offset \
                -activeClientOnly 0 -systemIdleOnly 0 \
                -stringName ::device::energy_offset \
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

		config_energy {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Energy Component Config"  -resizable 0 ]

            set eCfg [::config getStr energy.config]
            set i 0
            set nameList ""
            foreach checkboxName $eCfg {
                if {$checkboxName != "move_mirror_vert"} {
                    lappend nameList [list $checkboxName $i]
                }
                incr i
            }

            itk_component add $name {
                DCS::StringFieldView $path.offset \
                -defaultType checkbutton \
                -activeClientOnly 0 -systemIdleOnly 0 \
                -stringName ::device::energy_config \
                -fieldNameList $nameList
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

		sample_camera_param {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Sample Camera Parameters"  -width 600 -height 270 -resizable 1 ]

            itk_component add $name {
                #DCS::StringValueNamePairView $path.$name
                DCS::SampleCameraParamView $path.$name sample_camera_constant \
                -activeClientOnly 0 -systemIdleOnly 0 \
                -stringName ::device::sample_camera_constant \
                -nameStringName ::device::sample_camera_constant_name_list
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

		inline_sample_camera_param {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Inline Camera Parameters"  -width 600 -height 270 -resizable 1 ]

            itk_component add $name {
                DCS::SampleCameraParamView $path.$name inline_sample_camera_constant \
                -activeClientOnly 0 -systemIdleOnly 0 \
                -stringName ::device::sample_camera_constant \
                -nameStringName ::device::sample_camera_constant_name_list
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

	inline_sample_camera_h_param {
                        if [checkAndActivateExistingDocument $name] return
                        set path [$itk_component(Mdi) addDocument $name -title "Inline Camera High R Parameters"  -width 600 -height 270 -resizable 1 ]

            itk_component add $name {
                DCS::SampleCameraParamView $path.$name inline_sample_camera_h_constant \
                -activeClientOnly 0 -systemIdleOnly 0 \
                -stringName ::device::sample_camera_constant \
                -nameStringName ::device::sample_camera_constant_name_list
            } {
            }
                        pack $itk_component($name) -expand 1 -fill both
        }
	
        reposition_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Reposition View"  -width 600 -height 300 -resizable 1 ]

            itk_component add $name {
                DCS::RepositionView $path.$name \
                -activeClientOnly 1 \
                -systemIdleOnly 1 \
                -honorStatus 1 \
                -mdiHelper $this
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        userNotifySetupView {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "User Notify Setup"  -resizable 1  -width 600 -height 400]

			itk_component add $name {
				UserNotifySetupView $path.ls -mdiHelper "$this"
		    } {
		    }
			
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        queue_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Queue View"  -width 800 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::QueueView $path.$name \
                -mdiHelper $this
            } {
				keep -videoParameters
				keep -videoEnabled
            }
			$itk_component($name) hook
			pack $itk_component($name) -expand 1 -fill both
        }

        queue_run_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run View For Queue"  -width 300 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::RunViewForQueue $path.$name \
                -mdiHelper $this
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        queue_position_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run Position View For Queue"  -width 300 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::PositionViewForQueue $path.$name \
                -positionLabels [list [list default position1 pos2] [list 1 1 1]] \
                -mdiHelper $this
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        queue_preview {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run Task Previous"  -width 300 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::RunSequenceView $path.$name \
                -purpose forQueue \
            } {
            }
			pack $itk_component($name) -expand 1 -fill both

            $itk_component($name) handleRunDefinitionPtrChange 0 1 0 ::device::virtualRunForQueue 1
        }

        queue_adjust_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run Adjust View For Queue"  -width 600 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::AdjustViewForQueue $path.$name \
                -mdiHelper $this
            } {
				keep -videoParameters
				keep -videoEnabled
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        queue_list_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run List View For Queue"  -width 600 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::RunListViewForQueue $path.$name \
                -mdiHelper $this
            } {
            }
			$itk_component($name) hook
			pack $itk_component($name) -expand 1 -fill both
        }

        queue_top_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Run Top View For Queue"  -width 600 -height 700 -resizable 1 ]

            itk_component add $name {
                DCS::RunTopViewForQueue $path.$name \
                -mdiHelper $this
            } {
				keep -videoParameters
				keep -videoEnabled
            }
			$itk_component($name) hook
			pack $itk_component($name) -expand 1 -fill both
        }

        spectrometer_status {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Spectrometer Status"  -width 800 -height 600 -resizable 1]

            itk_component add $name {
                MicroSpecCalculationSetupView $path.$name \
                -stringName ::device::spectro_config
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        spectrometer_view {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Spectrometer View"  -width 800 -height 600 -resizable 1 ]

            itk_component add $name {
                #SpectrometerView $path.$name
                MicroSpectUserView $path.$name
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        spectrometer_hardware {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Spectrometer Low Level View"  -width 800 -height 600 -resizable 1 ]

            itk_component add $name {
                SpectrometerView $path.$name \
                -purpose raw
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        spectrometer_wrap {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Spectrometer Sub view"  -width 800 -height 600 -resizable 1 ]

            itk_component add $name {
                SpectrometerView $path.$name \
                -purpose wrap
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        rastering_config {
			if [checkAndActivateExistingDocument $name] return
			set path [$itk_component(Mdi) addDocument $name -title "Raster Configuration"  -width 800 -height 600 -resizable 1 ]

            itk_component add $name {
                RasteringConfigView $path.$name \
            } {
            }
			pack $itk_component($name) -expand 1 -fill both
        }

        inline_preset {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Inline Preset"  -resizable 1  -width 600 -height 300]

			itk_component add $name {
                DCS::InlineCameraPresetLevel2View $path.$name \
                -stringName ::device::inline_camera_position_preset \
                -systemIdleOnly 0 \
                -activeClientOnly 0
		    } {
                keep -mdiHelper
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        raster_run_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Raster Run View"  -resizable 1  -width 800 -height 600]

			itk_component add $name {
                RasterTab $path.$name \
		    } {
				keep -videoParameters
				keep -videoEnabled
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        visex_image_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Visex Staff View"  \
            -resizable 1  \
            -width 1200 \
            -height 800]

			itk_component add $name {
                #VisexImageView $path.$name
                #VisexResultView $path.$name 0
                VisexStaffView $path.$name
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        visex_user_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Visex User View"  \
            -resizable 1  \
            -width 800 \
            -height 650]

			itk_component add $name {
                VisexUserView $path.$name sample 1
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        visex_tab {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Visex Tab"  \
            -resizable 1  \
            -width 700 \
            -height 800]

			itk_component add $name {
                VisexTab $path.$name \
                -packOption "-side right -anchor ne"
		    } {
				keep -videoParameters
				keep -videoEnabled
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        grid_canvas {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Raster Canvas"  -resizable 1  -width 600 -height 800]

			itk_component add $name {
                GridDisplayWidget $path.$name
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        grid_video {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Raster Video"  -resizable 1  -width 600 -height 500]

			itk_component add $name {
                GridVideoWidget $path.$name \
                -videoEnabled 1 \
		    } {
				keep -videoParameters
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        microspec_staff_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "MicroSpec Staff View"  -resizable 1  -width 900 -height 700]

			itk_component add $name {
                DCS::MicroSpecStaffView $path.$name -mdiHelper $this
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        microspec_motor_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "MicroSpec Motor View"  -resizable 1  -width 800 -height 600]

			itk_component add $name {
                DCS::MicroSpecMotorView $path.$name \
		    } {
		    }
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        collimator_motor_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Collimator Motor View" ]

			itk_component add $name {
                DCS::CollimatorMotorView $path.$name \
		    } {
		    }
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }




        collimator_entry {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Collimator Entry Test"  -resizable 1  -width 800 -height 600]

			itk_component add $name {
                CollimatorMenuEntry $path.$name \
                -forUser 1 \
                -entryWidth 16 \
                -entryType string \
                -showEntry 0 \
                -reference "::device::user_collimator_status contents" \
                -shadowReference 1
		    } {
		    }
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        beam_size_parameter {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "BeamSize Parmeter test"  -resizable 1  -width 400 -height 300]

			itk_component add $name {
                BeamSizeParameter $path.$name \
                -promptText "BeamSize: " \
                -promptWidth 16 \
                -onCollimatorSubmit "puts \"collimator=%s\"" \
                -onWidthSubmit "puts width=%s"
		    } {
		    }
            $path.$name setValue 0.5 0.5 {0 -1 2.0 2.0}


			pack $itk_component($name) -expand 1 -fill both
			pack $path

            log_warning beamsize parameter=$path.$name
        }

        grid_input {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Raster Setup"  -resizable 1  -width 400 -height 600]

			itk_component add $name {
                GridListView $path.$name \
                -activeClientOnly 1 \
                -systemIdleOnly 1 \
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        grid_node_list {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "Raster Node List"  -resizable 1  -width 400 -height 600]

			itk_component add $name {
                GridNodeListView $path.$name \
                -activeClientOnly 1 \
                -systemIdleOnly 1 \
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        softlink_setup {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name -title "SoftLink Setup For L614"  -resizable 1  -width 600 -height 100]

			itk_component add $name {
                L614SoftLinkView $path.$name \
                -stringName ::device::l614_softlink_status \
		    } {
		    }
            
			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        collimator_preset_debug {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "Collimator Preset DEBUG"  \
            -resizable 1  -width 1000 -height 500]

            itk_component add $name {
                DCS::CollimatorPresetLevel2View $path.$name \
                -stringName ::device::collimator_preset \
                -systemIdleOnly 0 \
                -activeClientOnly 0
            } {
                keep -mdiHelper
            }

            #$itk_component($name) setValue 12978.0 1

			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

        trigger_time_view {
			if [checkAndActivateExistingDocument $name] return

			set path [$itk_component(Mdi) addDocument $name \
            -title "User Align Beam Trigger Time"  \
            -resizable 1  -width 1000 -height 160]

            itk_component add $name {
                DCS::TriggerTimeForUserAlignBeam $path.$name \
                -stringName ::device::collimator_preset \
                -systemIdleOnly 0 \
                -activeClientOnly 0
            } {
                keep -mdiHelper
            }

            #$itk_component($name) setValue 12978.0 1

			pack $itk_component($name) -expand 1 -fill both
			pack $path
        }

		blu-ice {
			if [checkAndActivateExistingDocument $name] return
			
			#pack the hutch overview widget in the titled frame
			set path [$itk_component(Mdi) addDocument $name -resizable 1]
			
			#pack the hutch overview widget in the titled frame
			itk_component add $name {
				BluIce $path.blu-ice
			} {
				keep -detectorType -gonioPhiDevice -gonioOmegaDevice
				keep -gonioKappaDevice -detectorVertDevice
				keep -detectorHorzDevice -detectorZDevice -energyDevice
				keep -attenuationDevice -beamWidthDevice -beamHeightDevice
				keep -beamstopDevice -cameraZoomDevice
				keep -videoParameters
				keep -sampleXDevice
				keep -sampleYDevice
				keep -sampleZDevice
				keep -videoEnabled
			}
			pack $itk_component($name) -expand yes -fill both
			pack $path
		}	
	}

}

body SetupTab::editString { name_ } {

	if [checkAndActivateExistingDocument $name_] return
	
	#pack the hutch overview widget in the titled frame
	set path [$itk_component(Mdi) addDocument $name_ -resizable 1  -title "$name_" -width 500 -height 100]

	set stringObject [$m_deviceFactory getObjectName $name_]

	#pack the hutch overview widget in the titled frame
	itk_component add $name_ {
		DCS::StringView $path.$name_ \
             -systemIdleOnly 0 \
             -activeClientOnly 0 \
			 -vscrollmode dynamic \
			 -hscrollmode dynamic \
			 -stringName $stringObject \
			 -wrap word
	} {
	}

	pack $itk_component($name_) -expand yes -fill both
	pack $path

    if {[lsearch -exact $m_dictStringList $name_] < 0} {
        puts "name=$name_ list=$m_dictStringList"
        return
    }

	if [checkAndActivateExistingDocument ${name_}Dict] return
	
	#pack the hutch overview widget in the titled frame
	set path [$itk_component(Mdi) addDocument ${name_}Dict -resizable 1  -title "$name_ dict" -width 200 -height 600]

	#pack the hutch overview widget in the titled frame
	itk_component add ${name_}Dict {
		DCS::StringDictView $path.${name_}Dict \
             -systemIdleOnly 0 \
             -activeClientOnly 0 \
			 -stringName $stringObject \
	} {
	}

	pack $itk_component(${name_}Dict) -expand yes -fill both
	pack $path

}


body SetupTab::getLogin {} {
	openToolChest login
}

body SetupTab::checkAndActivateExistingDocument { documentName_ } {
	
	if { [info exists itk_component($documentName_)] } {
		$itk_component(Mdi) activateDocument $documentName_
		return 1
	}

	return 0
}


proc handle_network_error {args} {
}

proc startSetupTab { configuration_ } {
	global BLC_DATA
    global gMotorBeamWidth
    global gMotorBeamHeight
    global gMotorPhi
    global gMotorOmega
    global gMotorDistance
    global gMotorBeamStop
    global gMotorBeamStopHorz
    global gMotorBeamStopVert
    global gMotorVert
    global gMotorHorz

	wm title . "Developer Mode for beamline [$configuration_ getConfigRootName]"
	wm resizable . 1 1
	wm geometry . 800x700
	
	set imageServerHost [$configuration_ getImgsrvHost]
	set imageServerHttpPort [$configuration_ getImgsrvHttpPort]
	
	#get the name of the periodic table specification file
	set periodicFile [$configuration_ getPeriodicFilename]
	if { $periodicFile != ""} {
		#add the directory if we know the name of the file
		set periodicFile [file join $BLC_DATA $periodicFile]
	}

	#create the status bar
	StatusBar .activeButton

	SetupTab .setup 	 \
		 -gonioPhiDevice ::device::$gMotorPhi \
		 -gonioOmegaDevice ::device::$gMotorOmega \
		 -gonioKappaDevice ::device::gonio_kappa \
		 -detectorVertDevice ::device::$gMotorVert \
		 -detectorHorzDevice ::device::$gMotorHorz \
		 -detectorZDevice ::device::$gMotorDistance \
		 -energyDevice ::device::energy \
		 -attenuationDevice ::device::attenuation \
		 -beamWidthDevice ::device::$gMotorBeamWidth \
		 -beamHeightDevice ::device::$gMotorBeamHeight \
		 -beamstopDevice ::device::$gMotorBeamStop \
		 -cameraZoomDevice ::device::camera_zoom \
		 -videoParameters &resolution=high \
		 -sampleXDevice ::device::sample_x \
		 -sampleYDevice ::device::sample_y \
		 -sampleZDevice ::device::sample_z \
		 -slit0Upper ::device::slit_0_upper \
		 -slit0Lower ::device::slit_0_lower \
		 -slit0Left ::device::slit_0_ssrl \
		 -slit0Right ::device::slit_0_spear \
		 -videoEnabled 1 \
		 -periodicFile $periodicFile \
		 -imageServerHost $imageServerHost \
		 -imageServerHttpPort $imageServerHttpPort

		
	dcss configure -forcedLoginCallback "::.setup getLogin"
	
	grid rowconfigure . 0 -weight 1
	grid rowconfigure . 1 -weight 0
	grid columnconfigure . 0 -weight 1

	grid .setup -row 0 -column 0 -sticky news
	grid .activeButton -row 1 -column 0 -sticky ew
}


#testSetupTab
