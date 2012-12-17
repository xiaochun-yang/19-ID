#!/usr/bin/wish
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

package require Itcl
package require Iwidgets
package require BWidget

package provide BLUICESr570 1.0

# load the DCS packages
package require DCSDevice
package require DCSDeviceView


class DCS::Sr570Params {
   inherit DCS::Component	

	public method sendContentsToServer

   private variable m_deviceFactory
   private variable m_ampParams 

   public variable status "inactive"

   public variable state 
   public variable sens 
   public variable sucm
   public variable ioon
   public variable iolv
   public variable iolv_sign
   public variable iosn
   public variable iouc
   public variable bson
   public variable fltt
   public variable lfrq
   public variable hfrq
   public variable gnmd
   public variable invt
   public variable blnk
   public variable sucv 0
   public variable bslv
   public variable iouv

   public method setField
   public method setSens  {value_} {setField SENS $value_}
   public method setSucm  {value_} {setField SUCM $value_}
   public method setIoon  {value_} {setField IOON $value_}
   public method setIolv  {value_} {setField IOLV $value_}
   public method setIosn  {value_} {setField IOSN $value_}
   public method setIouc  {value_} {setField IOUC $value_}
   public method setBson  {value_} {setField BSON $value_}
   public method setFltt  {value_} {setField FLTT $value_}
   public method setLfrq  {value_} {setField LFRQ $value_}
   public method setHfrq  {value_} {setField HFRQ $value_}
   public method setGnmd  {value_} {setField GNMD $value_}
   public method setInvt  {value_} {setField INVT $value_}
   public method setBlnk  {value_} {setField BLNK $value_}
   public method setSucv  {value_} {setField SUCV $value_}
   public method setBslv  {value_} {setField BSLV $value_}
   public method setIouv  {value_} {setField IOUV $value_}
   public method calc_iolv_sign
   public method extract_iolv_sign

   private method lookupIndexByName
   private method lookupValueByName

	public method handleParametersChange
	public method submitNewParameters
    public method getContents { } {
        $m_ampParams getContents
    }

	# call base class constructor
	constructor { string_name args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 status {cget -status} \
					 contents { getContents } \
					 state {cget -state} \
					 sens {cget -sens} \
					 sens {cget -sens} \
					 sucm {cget -sucm} \
					 ioon {cget -ioon} \
					 iolv {cget -iolv} \
					 iolv_sign {cget -iolv_sign} \
				    iosn {cget -iosn } \
				    iouc {cget -iouc } \
					 bson {cget -bson } \
					 fltt {cget -fltt} \
					 lfrq {cget -lfrq} \
					 hfrq {cget -hfrq} \
					 gnmd {cget -gnmd} \
					 invt {cget -invt} \
					 blnk {cget -blnk} \
					 sucv {cget -sucv } \
					 bslv {cget -bslv} \
					 iouv {cget -iouv }
			 }
	} {
		
      set m_deviceFactory [DCS::DeviceFactory::getObject]
      
      set m_ampParams [$m_deviceFactory createString $string_name]

      ::mediator register $this $m_ampParams contents handleParametersChange

		eval configure $args
      
		announceExist

      return [namespace current]::$this
	}
}


body DCS::Sr570Params::submitNewParameters { contents_ } {
   $m_ampParams sendContentsToServer $contents_
}

body DCS::Sr570Params::setField  { paramName value_} {

   set clientState [::dcss cget -clientState]

   if { $clientState != "active"} return

   set newString [list SENS $sens SUCM $sucm IOON $ioon IOLV $iolv IOUC $iouc BSON $bson FLTT $fltt LFRQ $lfrq HFRQ $hfrq GNMD $gnmd INVT $invt BLNK $blnk SUCV $sucv BSLV $bslv IOUV $iouv IOSN $iosn]

   set valueIndex [lookupIndexByName $newString $paramName]
   set newString [lreplace $newString $valueIndex $valueIndex $value_]
   submitNewParameters $newString
}



body DCS::Sr570Params::lookupIndexByName { paramList paramName } {
   return [expr [lsearch $paramList $paramName] +1]
}

body DCS::Sr570Params::lookupValueByName { paramList paramName } {
   return [lindex $paramList [expr [lsearch $paramList $paramName] +1]]
}

body DCS::Sr570Params::handleParametersChange { - targetReady_ - ampParams - } {

	if { ! $targetReady_} return

   set state [lindex $ampParams 0]

   set params [lrange $ampParams 1 end]

   set sens [lookupValueByName $params SENS]
   set sucm [lookupValueByName $params SUCM]
   set ioon [lookupValueByName $params IOON]
   set iolv [lookupValueByName $params IOLV]
   set iosn [lookupValueByName $params IOSN]
   set iouc [lookupValueByName $params IOUC]
   set bson [lookupValueByName $params BSON]
   set fltt [lookupValueByName $params FLTT]
   set lfrq [lookupValueByName $params LFRQ]
   set hfrq [lookupValueByName $params HFRQ]
   set gnmd [lookupValueByName $params GNMD]
   set invt [lookupValueByName $params INVT]
   set blnk [lookupValueByName $params BLNK]
   set sucv [lookupValueByName $params SUCV]
   set bslv [lookupValueByName $params BSLV]
   set iouv [lookupValueByName $params IOUV]

   set iolv_sign [calc_iolv_sign $iosn $iolv]

	#inform observers of the change 
	updateRegisteredComponents sens 
	updateRegisteredComponents sucm
	updateRegisteredComponents ioon
	updateRegisteredComponents iolv
	updateRegisteredComponents iosn
	updateRegisteredComponents iouc
	updateRegisteredComponents bson
	updateRegisteredComponents fltt
	updateRegisteredComponents lfrq
	updateRegisteredComponents hfrq
	updateRegisteredComponents gnmd
	updateRegisteredComponents invt
	updateRegisteredComponents blnk
	updateRegisteredComponents sucv
	updateRegisteredComponents bslv
	updateRegisteredComponents iouv

	updateRegisteredComponents iolv_sign

}

body DCS::Sr570Params::calc_iolv_sign { iosn_ iolv_ } {

   if {$iosn_ == "pos"} {
      set iolv_sign_ $iolv_
   } else {
      set iolv_sign_ "-$iolv_"
   }

   return $iolv_sign_
}

body DCS::Sr570Params::extract_iolv_sign { iolv_sign_ } {

   if { [string index $iolv_sign_ 0] == "-"} {
      set iosn_ "neg"
      set iolv_ [string range $iolv_sign_ 1 end]
   } else {
      set iosn_ "pos"
      set iolv_ $iolv_sign_ 
   }


   return [list $iosn_ $iolv_]
}




####################
#  GUI
######################
class DCS::Sr570Gui {
 	inherit ::DCS::CanvasGifView DCS::Component

    itk_option define -mdiHelper mdiHelper MdiHelper ""

	# protected methods
	protected method constructParameterEntryPanel

   private variable m_deviceFactoy
   private variable m_ampParamsObj
    private variable m_shadowRef
    private variable m_allState
   public variable lowpass 0 
   public variable highpass 1

   private method setEntryComponentDirectly
   private variable m_logger


   private variable ioonSwitchId 
   private variable bsonSwitchId 
   private variable invertorId 
   private variable filterId 

   public method changeSens
   public method changeSucm
   public method changeIoon
   public method changeIolv
   public method changeIosn
   public method changeIouc
   public method changeBson
   public method changeFltt
   public method changeLfrq
   public method changeHfrq
   public method changeGnmd
   public method changeInvt
   public method changeBlnk
   public method changeSucv
   public method changeBslv
   public method changeIouv
   public method cancelChanges
   public method applyChanges
   public method handleParamChange 
   private method repackDynamic

   public method toggleBson
   public method toggleIoon

   public method getLowpass {} {return $lowpass}
   public method getHighpass {} {return $highpass}

	# call base class constructor
	constructor { string_name args } {

		# call base class constructor
		::DCS::Component::constructor \
			 { \
					 lowpass {getLowpass } \
					 highpass {getHighpass } \
			 }
	} {

      loadBackdropImage SRS570_control.gif

      set obj [namespace current]::[DCS::Sr570Params \#auto $string_name]
      set m_ampParamsObj $obj

      set m_deviceFactory [DCS::DeviceFactory::getObject]

      set m_shadowRef 1
      set m_allState normal

      set m_logger [DCS::Logger::getObject]

		# construct the parameter widgets
		constructParameterEntryPanel

      eval itk_initialize $args

      ::mediator register $this $m_ampParamsObj sens changeSens 
      ::mediator register $this $m_ampParamsObj sucm changeSucm 
      ::mediator register $this $m_ampParamsObj ioon changeIoon
      ::mediator register $this $m_ampParamsObj iolv_sign changeIolv
      ::mediator register $this $m_ampParamsObj iouc changeIouc
      ::mediator register $this $m_ampParamsObj bson changeBson
      ::mediator register $this $m_ampParamsObj fltt changeFltt
      ::mediator register $this $m_ampParamsObj lfrq changeLfrq
      ::mediator register $this $m_ampParamsObj hfrq changeHfrq
      ::mediator register $this $m_ampParamsObj gnmd changeGnmd
      ::mediator register $this $m_ampParamsObj invt changeInvt
      ::mediator register $this $m_ampParamsObj blnk changeBlnk
      ::mediator register $this $m_ampParamsObj sucv changeSucv
      ::mediator register $this $m_ampParamsObj bslv changeBslv
      ::mediator register $this $m_ampParamsObj iouv changeIouv
      
    announceExist 
	}

	destructor {
	}
}

body DCS::Sr570Gui::setEntryComponentDirectly { component_ value_ } {
   $itk_component($component_) setValue $value_ 1
}


#dropdown sensitivity
body DCS::Sr570Gui::changeSens { - targetReady_ - x - } {
	setEntryComponentDirectly sens $x
}

#checkbox calibration mode
body DCS::Sr570Gui::changeSucm { - targetReady_ - x - } {
	$itk_component(sucm) setValue $x
	$itk_component(sucm) updateTextColor
}

#checkbox Input offset on
body DCS::Sr570Gui::changeIoon { - targetReady_ - x - } {
	$itk_component(ioon) setValue $x
	$itk_component(ioon) updateTextColor
}

#dropdown input offset level
body DCS::Sr570Gui::changeIolv { - targetReady_ - x - } {
	setEntryComponentDirectly iolv $x
}

#checkbox Input offset calibration mode
body DCS::Sr570Gui::changeIouc { - targetReady_ - x - } {
	$itk_component(iouc) setValue $x
	$itk_component(iouc) updateTextColor
}

#bias voltage on
body DCS::Sr570Gui::changeBson { - targetReady_ - x - } {
	$itk_component(bson) setValue $x
	$itk_component(bson) updateTextColor
}

#dropdown filter type
body DCS::Sr570Gui::changeFltt { - targetReady_ - x - } {
	setEntryComponentDirectly fltt $x
}

body DCS::Sr570Gui::changeLfrq { - targetReady_ - x - } {
	setEntryComponentDirectly lfrq $x
}

body DCS::Sr570Gui::changeHfrq { - targetReady_ - x - } {
	setEntryComponentDirectly hfrq $x
}

#dropdown gain mode
body DCS::Sr570Gui::changeGnmd { - targetReady_ - x - } {
	setEntryComponentDirectly gnmd $x
}

#
body DCS::Sr570Gui::changeInvt { - targetReady_ - x - } {
	$itk_component(invt) setValue $x
	$itk_component(invt) updateTextColor
}

#checkbox blank front end amp
body DCS::Sr570Gui::changeBlnk { - targetReady_ - x - } {
	$itk_component(blnk) setValue $x
	$itk_component(blnk) updateTextColor
}

body DCS::Sr570Gui::changeSucv { - targetReady_ - x - } {
	setEntryComponentDirectly sucv $x
}

body DCS::Sr570Gui::changeBslv { - targetReady_ - x - } {
	setEntryComponentDirectly bslv $x
}

body DCS::Sr570Gui::changeIouv { - targetReady_ - x - } {
	setEntryComponentDirectly iouv $x
}

body DCS::Sr570Gui::constructParameterEntryPanel { } {

	global env
	global BLC_IMAGES

   itk_component add gain  {
      ::iwidgets::labeledframe $itk_component(canvas).gain -labeltext "Gain Settings" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(gain) childsite]

	itk_component add sens {
		    DCS::MenuEntry $ring.sens -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
                -showEntry 0 \
			    -promptText "Sensitivity:"  \
                -promptWidth 11 \
			    -reference "$m_ampParamsObj sens" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0
	    } {
	    }

	    $itk_component(sens) configure -menuChoices [list 1pA/V 2pA/V 5pA/V 10pA/V 20pA/V 50pA/V 100pA/V 200pA/V 500pA/V 1nA/V 2nA/V 5nA/V 10nA/V 20nA/V 50nA/V 100nA/V 200nA/V 500nA/V 1uA/V 2uA/V 5uA/V 10uA/V 20uA/V 50uA/V 100uA/V 200uA/V 500uA/V 1mA/V]

		itk_component add tweakg {
			frame $ring.tweakg
		}
   
	itk_component add sucm {
		DCS::Checkbutton $itk_component(tweakg).sucm \
            -state $m_allState \
			 -text "Tweak" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj sucm" \
         -onvalue "uncal" \
         -offvalue "cal"
	} {}

   itk_component add sucv {
      DCS::Entry $itk_component(tweakg).sucv -promptText "" \
            -state $m_allState \
         -promptWidth 2 \
         -entryWidth 10 	\
         -entryType int \
         -entryJustify right \
         -units "%" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_ampParamsObj sucv" 
   } {}


	itk_component add gnmd {
		    DCS::MenuEntry $ring.gnmd -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
                -showEntry 0 \
			    -promptText "Mode:"  \
                -promptWidth 11 \
			    -reference "$m_ampParamsObj gnmd" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0
	    } {
	    }

	    $itk_component(gnmd) configure -menuChoices [list low_noise high_bandwidth low_drift]

	itk_component add invt {
		DCS::Checkbutton $itk_component(canvas).invt \
            -state $m_allState \
			 -text "Invert" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj invt" \
         -offvalue "non-inverted" \
         -onvalue "inverted"
	} {}



   itk_component add io  {
      ::iwidgets::labeledframe $itk_component(canvas).io -labeltext "Offset Current" -labelfont "helvetica -16 bold" -foreground blue
   } {}

   set ring [$itk_component(io) childsite]



	itk_component add iolv {
		    DCS::MenuEntry $ring.iolv -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
                -showEntry 0 \
			    -promptText ""  \
                -promptWidth 11 \
			    -reference "$m_ampParamsObj iolv_sign" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0 -menuColumnBreak 30
	    } {
	    }


	$itk_component(iolv) configure -menuChoices  [list 1pA 2pA 5pA 10pA 20pA 50pA 100pA 200pA 500pA 1nA 2nA 5nA 10nA 20nA 50nA 100nA 200nA 500nA 1uA 2uA 5uA 10uA 20uA 50uA 100uA 200uA 500uA 1mA 2mA 5mA -1pA -2pA -5pA -10pA -20pA -50pA -100pA -200pA -500pA -1nA -2nA -5nA -10nA -20nA -50nA -100nA -200nA -500nA -1uA -2uA -5uA -10uA -20uA -50uA -100uA -200uA -500uA -1mA -2mA -5mA]

	itk_component add tweakio {
		frame $ring.tweakio
	}

	itk_component add iouc {
		DCS::Checkbutton $itk_component(tweakio).iouc \
            -state $m_allState \
			 -text "Tweak" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj iouc" \
         -onvalue "uncal" \
         -offvalue "cal"
	} {}

   itk_component add iouv {
      DCS::Entry $itk_component(tweakio).iouv -promptText "" \
            -state $m_allState \
         -promptWidth 2 \
         -entryWidth 12 	\
         -entryType float \
         -entryJustify right \
         -decimalPlaces 1 \
         -units "%" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_ampParamsObj iouv" 
   } {}





   itk_component add bslv {
      DCS::Entry $itk_component(canvas).bslv -promptText "Bias" \
            -state $m_allState \
         -promptWidth 5 \
         -entryWidth 7 	\
         -entryType float \
         -decimalPlaces 3 \
         -entryJustify right \
         -units "V" \
         -shadowReference 0 \
         -systemIdleOnly 1 \
         -activeClientOnly 1 \
         -reference "$m_ampParamsObj bslv" 
   } {}


   itk_component add filter  {
      ::iwidgets::labeledframe $itk_component(canvas).filter -labeltext "Filter" -labelfont "helvetica -16 bold" -foreground blue
   } {}
   set ring [$itk_component(filter) childsite]

	itk_component add fltt {
		    DCS::MenuEntry $ring.fltt -entryType string \
                -state $m_allState \
			    -entryWidth 12 \
                -showEntry 0 \
			    -promptText "Filter Type"  \
                -promptWidth 11 \
			    -reference "$m_ampParamsObj fltt" \
                -activeClientOnly 1 \
	            -systemIdleOnly 0
	    } {
	    }

   $itk_component(fltt) configure -menuChoices [list 6dB_highpass 12dB_highpass 6dB_bandpass 6dB_lowpass 12dB_lowpass none]

	itk_component add lfrq {
		    DCS::MenuEntry $ring.lfrq -entryType string \
             -state $m_allState \
			    -entryWidth 12 \
             -showEntry 0 \
			    -promptText "lowpass"  \
             -promptWidth 11 \
			    -reference "$m_ampParamsObj lfrq" \
             -activeClientOnly 1 \
	          -systemIdleOnly 0
	    } {
	    }

   $itk_component(lfrq) configure -menuChoices [list 0.03Hz 0.1Hz 0.3Hz 1Hz 3Hz 10Hz 30Hz 100Hz 300Hz 1kHz 3kHz 10kHz 30kHz 100kHz 300kHz 1MHz]

	itk_component add hfrq {
		    DCS::MenuEntry $ring.hfrq -entryType string \
             -state $m_allState \
			    -entryWidth 12 \
             -showEntry 0 \
			    -promptText "highpass"  \
             -promptWidth 11 \
			    -reference "$m_ampParamsObj hfrq" \
             -activeClientOnly 1 \
	          -systemIdleOnly 0
	    } {
	    }

   $itk_component(hfrq) configure -menuChoices [list 0.03Hz 0.1Hz 0.3Hz 1Hz 3Hz 10Hz 30Hz 100Hz 300Hz 1kHz 3kHz 10kHz ]

      set yellow #d0d000

		# create the apply button
		itk_component add apply {
			::DCS::Button $itk_component(canvas).apply \
				 -text "Configure" \
				 -command "$this applyChanges" -activeClientOnly 1 \
               -activebackground $yellow \
               -background $yellow
		} {
			keep -font -state
			keep -activeforeground -foreground -relief
		}

		# create the cancel button
		itk_component add cancel {
			::DCS::Button $itk_component(canvas).cancel \
				 -text "Cancel" \
				 -command "$this cancelChanges" \
                 -activeClientOnly 0 \
                 -systemIdleOnly 0
		} {
			keep -font -state
			keep -activeforeground -foreground -relief 
			rename -background -buttonBackground buttonBackground ButtonBackground
			rename -activebackground -activeButtonBackground buttonBackground ButtonBackground
		}

   itk_component add mode  {
      ::iwidgets::labeledframe $itk_component(canvas).mode -labeltext "Mode" -labelfont "helvetica -16 bold" -foreground blue
   } {}
   set ring [$itk_component(mode) childsite]

	itk_component add bson {
		DCS::Checkbutton $ring.bson \
            -state $m_allState \
			 -text "Bias On/Off" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj bson" \
         -offvalue "off" \
         -onvalue "on"
	} {}

	itk_component add ioon {
		DCS::Checkbutton $ring.ioon \
            -state $m_allState \
			 -text "Offset Current On/Off" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj ioon" \
         -offvalue "off" \
         -onvalue "on"
	} {}

	itk_component add blnk {
		DCS::Checkbutton $ring.blnk \
            -state $m_allState \
			 -text "No Output" \
			 -activeClientOnly 1 \
          -systemIdleOnly 0 \
			 -shadowReference $m_shadowRef \
         -reference "$m_ampParamsObj blnk" \
         -offvalue "no_blank" \
         -onvalue "blank"
	} {}

   set switchImage [ image create photo -file $BLC_IMAGES/switch.gif -palette "256/256/256"]
	set ioonSwitchId [$itk_component(canvas) create image 153 169 -anchor nw -image $switchImage]
	set bsonSwitchId [$itk_component(canvas) create image 153 197 -anchor nw -image $switchImage]
   set invertorImage [ image create photo -file $BLC_IMAGES/invertor.gif -palette "256/256/256"]
	set invertorId [$itk_component(canvas) create image 724 178 -anchor nw -image $invertorImage]
   set filterImage [ image create photo -file $BLC_IMAGES/filter.gif -palette "256/256/256"]
	set filterId [$itk_component(canvas) create image 407 175 -anchor nw -image $filterImage]


   #set btn [ $itk_component(canvas) create text 163 181 -text "*" -font *-courier-bold-r-normal--14-*-*-*-*-*-*-*]
   #$itk_component(canvas) bind $btn <Button-1> "$this toggleIoon"
   #set btn [ $itk_component(canvas) create text 163 207 -text "*" -font *-courier-bold-r-normal--14-*-*-*-*-*-*-*]
   #$itk_component(canvas) bind $btn <Button-1> "$this toggleBson"


   place $itk_component(gain) -x 590 -y 161 -anchor sw
   place $itk_component(filter) -x 350 -y 161 -anchor sw

	place $itk_component(mode) -x 8 -y 250

	grid $itk_component(ioon) -row 0 -column 0 -sticky w
	grid $itk_component(bson) -row 1 -column 0 -sticky w
	grid $itk_component(blnk) -row 2 -column 0 -sticky w  

	place $itk_component(invt) -x 712 -y 210

	grid $itk_component(gnmd) -row 0 -column 0 -sticky w
	grid $itk_component(sens) -row 1 -column 0 -sticky w
   grid $itk_component(tweakg) -row 2 -column 0 -sticky w
	grid $itk_component(sucm) -row 0 -column 0  -sticky w


	grid $itk_component(iolv) -row 0 -column 0 -sticky w
   grid $itk_component(tweakio) -row 1 -column 0 -sticky w
	grid $itk_component(iouc) -row 0 -column 0 -sticky w

	grid $itk_component(fltt) -row 0 -column 0 -sticky w


   place $itk_component(apply) -x 350 -y 250
   place $itk_component(cancel) -x 450 -y 250

   ::mediator register $this ::$itk_component(fltt) -value handleParamChange
   ::mediator register $this ::$itk_component(ioon) -value handleParamChange
   ::mediator register $this ::$itk_component(bson) -value handleParamChange
   ::mediator register $this ::$itk_component(sucm) -value handleParamChange
   ::mediator register $this ::$itk_component(iouc) -value handleParamChange
   ::mediator register $this ::$itk_component(invt) -value handleParamChange

	set _unappliedChanges [namespace current]::[::DCS::ComponentGate \#auto]

	$itk_component(apply) addInput "::dcss staff 1 {Must be staff to configure a device.}"
	$itk_component(apply) addInput "$_unappliedChanges gateOutput 0 {First make changes to a parameter.}"
	$itk_component(cancel) addInput "$_unappliedChanges gateOutput 0 {No changes to cancel.}"

	$_unappliedChanges addInput "::$itk_component(sens) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(sucm) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(ioon) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(iolv) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(iouc) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(bson) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(fltt) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(lfrq) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(hfrq) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(gnmd) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(invt) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(blnk) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(sucv) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(bslv) -referenceMatches 1 {No unapplied changes}"
	$_unappliedChanges addInput "::$itk_component(iouv) -referenceMatches 1 {No unapplied changes}"

   place forget $itk_component(control)

   repackDynamic
}

body DCS::Sr570Gui::toggleBson {} {
   set bson_ [$itk_component(bson) get]
   if {$bson_ == "on"} {
      $itk_component(bson) setValue "off"
   } else {
      $itk_component(bson) setValue "on"
   }

   $itk_component(bson) updateRegisteredComponents -value
   $itk_component(bson) updateRegisteredComponents -referenceMatches
}

body DCS::Sr570Gui::toggleIoon {} {
   set ioon_ [$itk_component(ioon) get]
   puts $ioon_
   if {$ioon_ == "on"} {
      $itk_component(ioon) setValue "off"
   } else {
      $itk_component(ioon) setValue "on"
   }
   $itk_component(ioon) updateRegisteredComponents -value
   $itk_component(ioon) updateRegisteredComponents -referenceMatches

}

body DCS::Sr570Gui::repackDynamic {} {

   set type [$itk_component(fltt) get]
   set lowpass [expr {$type == "12dB_lowpass" || $type == "6dB_lowpass" || $type == "6dB_bandpass" }]
   set highpass [expr {$type == "12dB_highpass" || $type == "6dB_highpass" || $type == "6dB_bandpass" }]

   if {$lowpass} {
	   grid $itk_component(lfrq) -row 1 -column 0 -sticky w
   } else {
      grid forget $itk_component(lfrq) 
   }

   if {$highpass} {
	   grid $itk_component(hfrq) -row 2 -column 0 -sticky w
   } else {
      grid forget $itk_component(hfrq) 
   }
   if {$type=="none"} {
      $itk_component(canvas) itemconfigure $filterId -state hidden
   } else {
      $itk_component(canvas) itemconfigure $filterId -state normal
   }

   if { [$itk_component(ioon) get] == "on"} {
      place $itk_component(io) -x 5 -y 167 -anchor sw
      $itk_component(canvas) itemconfigure $ioonSwitchId -state hidden
   } else {
      $itk_component(canvas) itemconfigure $ioonSwitchId -state normal
      place forget $itk_component(io)
   }

   if { [$itk_component(bson) get] == "on"} {
      place $itk_component(bslv) -x 5 -y 195
      $itk_component(canvas) itemconfigure $bsonSwitchId -state hidden
   } else {
      $itk_component(canvas) itemconfigure $bsonSwitchId -state normal
      place forget $itk_component(bslv)
   }

   if { [$itk_component(sucm) get] == "uncal"} {
	   grid $itk_component(sucv) -row 0 -column 1 -sticky w
   } else {
	   grid forget $itk_component(sucv)
   }



   if { [$itk_component(iouc) get] == "uncal"} {
	   grid $itk_component(iouv) -row 0 -column 1 -sticky w
   } else {
	   grid forget $itk_component(iouv)
   }


   if { [$itk_component(invt) get] == "inverted"} {
      $itk_component(canvas) itemconfigure $invertorId -state normal
   } else {
      $itk_component(canvas) itemconfigure $invertorId -state hidden
   }
}

body DCS::Sr570Gui::handleParamChange { - targetReady_ - type - } {
	if { ! $targetReady_} return
   repackDynamic
}

body DCS::Sr570Gui::cancelChanges {} {

	$itk_component(sens) updateFromReference
	$itk_component(sucm) updateFromReference
	$itk_component(ioon) updateFromReference
	$itk_component(iolv) updateFromReference
	$itk_component(iouc) updateFromReference
	$itk_component(bson) updateFromReference
	$itk_component(fltt) updateFromReference
	$itk_component(lfrq) updateFromReference
	$itk_component(gnmd) updateFromReference
	$itk_component(invt) updateFromReference
	$itk_component(blnk) updateFromReference
	$itk_component(sucv) updateFromReference
	$itk_component(bslv) updateFromReference
	$itk_component(iouv) updateFromReference
}

body DCS::Sr570Gui::applyChanges {} {

      #puts "iosn [lindex [$m_ampParamsObj extract_iolv_sign [$itk_component(iolv) get] ] 0]"
      #puts "iolv [lindex [$m_ampParamsObj extract_iolv_sign [$itk_component(iolv) get] ] 1]"

   set newString \
      [list SENS [$itk_component(sens) get] \
      SUCM [$itk_component(sucm) get] \
      IOON [$itk_component(ioon) get] \
      IOSN [lindex [$m_ampParamsObj extract_iolv_sign [$itk_component(iolv) get] ] 0] \
      IOLV [lindex [$m_ampParamsObj extract_iolv_sign [$itk_component(iolv) get] ] 1] \
      IOUC [$itk_component(iouc) get] \
      BSON [$itk_component(bson) get] \
      FLTT [$itk_component(fltt) get] \
      LFRQ [$itk_component(lfrq) get] \
      HFRQ [$itk_component(hfrq) get] \
      GNMD [$itk_component(gnmd) get] \
      INVT [$itk_component(invt) get] \
      BLNK [$itk_component(blnk) get] \
      SUCV [lindex [$itk_component(sucv) get] 0] \
      BSLV [lindex [$itk_component(bslv) get] 0] \
      IOUV [lindex [$itk_component(iouv) get] 0] ]

   $m_ampParamsObj submitNewParameters $newString  

}

class DCS::AmplifierNotebook {
 	inherit ::itk::Widget


	constructor { args } {
        global env
		
		itk_component add ring {
			frame $itk_interior.r
		}

		itk_component add notebook {
			DCS::TabNotebook $itk_component(ring).n \
				 -tabbackground lightgrey \
				 -background lightgrey \
				 -backdrop lightgrey \
				 -borderwidth 2\
				 -tabpos w \
				 -gap 0 \
				 -angle 20 \
				 -width 490 \
				 -height 370 \
				 -raiseselect 1 \
				 -bevelamount 4 \
				 -padx 5 -pady 4 \
            -raiseselect 1 -bevelamount 4
		} {
		}

      set amplifierList [::config getStr bluice.amplifiers]

      set tabNum 0
      foreach amp $amplifierList {
		   # construct the sample position widgets
		   $itk_component(notebook) add $amp -label "$amp"

		   set widget  [$itk_component(notebook) childsite $tabNum].$amp

		   itk_component add $amp {
			   DCS::Sr570Gui $widget $amp
			} {
			}	
		   pack $itk_component($amp) -expand 1 -fill both
         incr tabNum
      }  

		pack $itk_component(notebook) -expand 1 -fill both
		pack $itk_component(ring) -expand 1 -fill both

      $itk_component(notebook) select 0
      eval itk_initialize $args
   }
}
	
