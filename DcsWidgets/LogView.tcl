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

# provide the DCSEntry package
package provide DCSLogView 1.0

# load standard packages
package require Iwidgets

# load other DCS packages
package require DCSUtil
package require DCSSet
package require DCSComponent
package require DCSDeviceFactory
package require DCSButton
package require DCSPrompt

############# like tk_getOpenFile ###################
# but get the file list from impersonal server      #
#####################################################
proc impGetOpenFile { user SID dir {pattern *} } {
    if {[catch {impListDirectory $user $SID $dir $pattern} fileList]} {
        log_error "failed to list directory $dir: $fileList"
        return ""
    }
    set fileList [split $fileList \n]
    if {[lindex $fileList end] == ""} {
        set fileList [lreplace $fileList end end]
    }

    #puts "fileList:$fileList"

    set win_id [::iwidgets::selectiondialog .#auto \
    -modality application \
    -title "select user log file" \
    ]

    eval $win_id insert items end $fileList
    $win_id component selectionbox component items selection set end
    $win_id selectitem

    $win_id component bbox hide 1
    $win_id buttonconfigure 0 -text Open

    if {[$win_id activate]} {
        set result [$win_id get]
    } else {
        set result ""
    }
    destroy $win_id

    return $result
}


class DCS::LogView {
   inherit ::itk::Widget DCS::Component

   itk_option define -showControls showControls ShowControls 0

    public method handleDoubleClick { } {
        set old_show $itk_option(-showControls)
        set new_show [expr "!$old_show"]
        configure -showControls $new_show
    }

   private variable m_displayLevel all

   private variable m_logIndex
   
   public  method clear { } {
      $itk_component(log) clear
   }

   public  method unregisterAll

   public method handleNewLogEntry

    public method handleFilterChange { } {
        set m_displayLevel [$itk_component(filter) get]
        if {[llength $m_displayLevel] >= 3} {
            set m_displayLevel all
        }
        ##re-populate the log
        $itk_component(log) clear
        set newLog [$m_logger getTailFromIndex 0 $m_displayLevel]
        $itk_component(log) bulkLog newLog
        set m_logIndex [$m_logger getEntryCount]
    }

   private variable m_deviceFactory
   private variable m_logger

   constructor { args } {
      set m_deviceFactory [DCS::DeviceFactory::getObject]

      itk_component add ring {
         frame $itk_interior.r
      }

      itk_component add log {
         DCS::scrolledLog $itk_component(ring).lll \
         -onDoubleClick "$this handleDoubleClick" \
         -sbwidth 6 \
         -scrollmargin 0
      } {
         keep -background -relief -width
      }

        itk_component add filter {
            ::iwidgets::checkbox $itk_component(ring).filter \
            -orient horizontal
        } {
        }
        $itk_component(filter) add note -text note
        $itk_component(filter) add warning -text warning
        $itk_component(filter) add error -text error
        $itk_component(filter) select note
        $itk_component(filter) select warning
        $itk_component(filter) select error
        $itk_component(filter) configure -command "$this handleFilterChange"

     #the clear log is not visible by default 
      itk_component add clear_log {
         button $itk_component(ring).c -text "Clear Log" \
            -command "$itk_component(log) clear"
      } {
      }

      grid $itk_component(log) -row 1 -column 0 -columnspan 3 -sticky news

      grid columnconfigure $itk_component(ring)  0 -weight 0
      grid columnconfigure $itk_component(ring)  1 -weight 1
      grid columnconfigure $itk_component(ring)  2 -weight 0

      grid rowconfigure $itk_component(ring)  1 -weight 1

      pack $itk_component(ring) -expand 1 -fill both
      eval itk_initialize $args

      set m_logger [DCS::Logger::getObject]

      #stuff the viewer with the latest 
      set newLog [$m_logger getTail 1000 ]

      $itk_component(log) bulkLog newLog

      #store how up-to-date we are.
      set m_logIndex [$m_logger getEntryCount]

      ::mediator register $this $m_logger entryCount handleNewLogEntry
      announceExist
   }

    destructor {
    }
}


configbody DCS::LogView::showControls {
   if {$itk_option(-showControls)} {
      grid $itk_component(filter) -row 0 -column 0 -sticky w
      grid $itk_component(clear_log) -row 0 -column 2 -sticky e
   } else {
      grid forget $itk_component(filter)
      grid forget $itk_component(clear_log)
   }
}

body DCS::LogView::handleNewLogEntry { - ready_ - - - } {
   if {!$ready_} return

   set newLog [$m_logger getTailFromIndex $m_logIndex $m_displayLevel]

   $itk_component(log) bulkLog newLog

   #store how up-to-date we are.
   set m_logIndex [$m_logger getEntryCount]
}


class DCS::UserLogView {
    inherit ::itk::Widget

    itk_option define -showControls showControls ShowControls 0
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    ########## use this to connect to dcs message ####
    public proc handleNewEntry { message } {
        foreach instance $gInstanceList {
            $instance handleNewMessage $message
        }
    }

    public method handleNewMessage { message }

    public method handleDoubleClick { } {
        set old_show $itk_option(-showControls)
        set new_show [expr "!$old_show"]
        configure -showControls $new_show
    }
    public method handleLevelFilterChange { } {
        set m_displayLevel [$itk_component(level_filter) get]
        if {[llength $m_displayLevel] >= 3} {
            set m_displayLevel all
        }
        loadCurrentFile
    }

    public method handleCatlogFilterChange { } {
        set m_displayCatlog [$itk_component(catlog_filter) get]
        if {[llength $m_displayCatlog] >= 5} {
            set m_displayCatlog all
        }
        loadCurrentFile
    }

    public method handleStaff 

    public method handleStringEvent { args } {
        if {!$gCheckButtonVar($this,pause)} {
            loadCurrentFile
        }
    }

    public method handlePause { } {
        if {!$gCheckButtonVar($this,pause)} {
            refresh
        }
    }

    public method refresh { } {
        loadCurrentFile
    }
    public method selectFile { }

    public method loadCurrentFile { }
    public method downloadFile { }

    private method lineToContents { line }

    private variable m_deviceFactory
    private variable m_opUserLog
    private variable m_strCurrentUserLog
    ### note, warning, error, severe
    private variable m_displayLevel all
    ### collecting, screening, madscan excitationscan, raster
    private variable m_displayCatlog all
    private variable m_currentFile ""
    private common gCheckButtonVar

    ##### for auto register ###
    private common gInstanceList ""


    #########################
    private common USE_IMPERSON 0

    constructor { args } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_opUserLog [$m_deviceFactory createOperation userLog]
        set m_strCurrentUserLog [$m_deviceFactory createString current_user_log]

        set gCheckButtonVar($this,pause) 0

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add controlFrame {
            frame $itk_component(ring).control
        } {
        }
        itk_component add file {
            button $itk_component(controlFrame).file \
            -text "load file" \
            -command "$this selectFile"
        } {
        }
        itk_component add refresh {
            button $itk_component(controlFrame).refresh \
            -text "refresh" \
            -command "$this refresh"
        } {
        }
        itk_component add download {
            button $itk_component(controlFrame).download \
            -text "download" \
            -command "$this downloadFile"
        } {
        }
        itk_component add newlog {
            ::DCS::Button $itk_component(controlFrame).newlog \
            -text "new log" \
            -command "$m_opUserLog startOperation"
        } {
        }
        itk_component add pause {
            checkbutton $itk_component(controlFrame).pause \
            -text "hold log" \
            -command "$this handlePause" \
            -variable [list [::itcl::scope gCheckButtonVar($this,pause)]]
        } {
        }
        pack $itk_component(file) -side left
        #pack $itk_component(refresh) -side left
        pack $itk_component(download) -side left
        pack $itk_component(newlog) -side left
        pack $itk_component(pause) -side left

        itk_component add log {
            DCS::scrolledLog $itk_component(ring).lll \
            -onDoubleClick "$this handleDoubleClick" \
            -sbwidth 6 \
            -scrollmargin 0
        } {
            keep -background -relief -width
        }

        itk_component add filterFrame {
            frame $itk_component(ring).filterFrame
        } {
        }

        itk_component add level_filter {
            ::iwidgets::checkbox $itk_component(filterFrame).level_filter \
            -labelpos nw \
            -labeltext "level filter" \
            -orient horizontal
        } {
        }
        $itk_component(level_filter) add note -text note
        $itk_component(level_filter) add warning -text warning
        $itk_component(level_filter) add error -text error
        $itk_component(level_filter) select note
        $itk_component(level_filter) select warning
        $itk_component(level_filter) select error
        $itk_component(level_filter) configure \
        -command "$this handleLevelFilterChange"

        itk_component add catlog_filter {
            ::iwidgets::checkbox $itk_component(filterFrame).catlog_filter \
            -labelpos nw \
            -labeltext "catlog filter" \
            -orient horizontal
        } {
        }
        $itk_component(catlog_filter) add screening      -text screening
        $itk_component(catlog_filter) add collecting     -text collecting
        $itk_component(catlog_filter) add madscan        -text "mad scan"
        $itk_component(catlog_filter) add excitationscan -text "excitation scan"
        $itk_component(catlog_filter) add raster         -text "raster"
        $itk_component(catlog_filter) add microspec      -text "microspec"
        $itk_component(catlog_filter) select screening
        $itk_component(catlog_filter) select collecting
        $itk_component(catlog_filter) select madscan
        $itk_component(catlog_filter) select excitationscan
        $itk_component(catlog_filter) select raster
        $itk_component(catlog_filter) select microspec
        $itk_component(catlog_filter) configure \
        -command "$this handleCatlogFilterChange"
        pack $itk_component(level_filter) -side left
        pack $itk_component(catlog_filter) -side left

        pack $itk_component(controlFrame) -side top -fill x
        pack $itk_component(log) -side top -expand 1 -fill both
        pack $itk_component(ring) -expand 1 -fill both
        eval itk_initialize $args

        #announceExist
        lappend gInstanceList $this

        $m_strCurrentUserLog register $this contents handleStringEvent
        $itk_option(-controlSystem) register $this staff handleStaff
    }

    destructor {
        $itk_option(-controlSystem) unregister $this staff handleStaff
        $m_strCurrentUserLog unregister $this contents handleStringEvent
        set index [lindex $gInstanceList $this]
        if {$index >= 0} {
            set gInstanceList [lreplace $gInstanceList $index $index]
        } else {
            puts "not in instance list"
        }
    }
}

configbody DCS::UserLogView::showControls {
    pack forget $itk_component(filterFrame)
    pack forget $itk_component(log)
    if {$itk_option(-showControls)} {
        pack $itk_component(filterFrame) -side top -fill x
        pack $itk_component(log) -side top -expand 1 -fill both
   } else {
        pack $itk_component(log) -side top -expand 1 -fill both
   }
}

body DCS::UserLogView::handleNewMessage { message_ } {
    ########### flags check ###########
    if {$gCheckButtonVar($this,pause)} return

    foreach { dummy type catlog contents } $message_ break

    ######## filter #####
    if {$m_displayLevel  != "all" && [lsearch $m_displayLevel $type] < 0} {
        return
    }
    if {$m_displayCatlog != "all" && [lsearch $m_displayCatlog $catlog] < 0} {
        return
    }

    #### display ####
    switch -exact -- $type {
        user_note {
            $itk_component(log) log_string "$catlog $contents" note
        }
        user_warning {
            $itk_component(log) log_string "$catlog $contents" warning
        }
        default {
            $itk_component(log) log_string "$catlog $contents" error
        }
    }
}
body DCS::UserLogView::lineToContents { line } {
    set contents ""
    set text ""
    if {![catch {llength $line} ll] && $ll == 4} {
        foreach {entryTime type catlog text} $line break
    } else {
        ### the text part may contain special characters
        ####### retrieve timestamp type catlog and text ######
        set startIndex 0
        for {set i 0} {$i < 3} {incr i} {
            set startIndex [string first {" "} $line $startIndex]
            if {$startIndex < 0} {
                break
            }
            incr startIndex 3
        }
        if {$startIndex > 3} {
            set header_end [expr $startIndex -3]
            set text_start $startIndex
            set header [string range $line 0 $header_end]
            if {![catch {llength $header} ll] && $ll == 3} {
                foreach {entryTime type catlog} $header break
                set text [string range $line $text_start end-1]
                puts "header: $header text: $text"
            }
        }
    }
    if {$text != ""} {
        if {($m_displayLevel == "all" || \
        [lsearch $m_displayLevel $type] >= 0) && \
        ($m_displayCatlog == "all" || \
        [lsearch $m_displayCatlog $catlog] >= 0)} {
            set contents [list $entryTime $type "$catlog $text"]
        }
    } else {
        if {$line != ""} {
            log_error "bad line from userLog file: $line"
        }
    }
    return $contents
}
body DCS::UserLogView::loadCurrentFile { } {
    puts "loadCurrentFile"
    $itk_component(log) clear
    puts "loadCurrentFile after clear"
    if {!$gCheckButtonVar($this,pause)} {
        set strContents [$m_strCurrentUserLog getContents]
        set m_currentFile [lindex $strContents 0]
    }
    puts "loadCurrentFile $m_currentFile"

    if {$m_currentFile == ""} return

    if {$USE_IMPERSON} {
        puts "using impersonal"

        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        if {[catch {impReadFile $user $SID $m_currentFile} data]} {
            $itk_component(log) log_string "cannot read user log file $m_currentFile: $data" error
            return
        }
    } else {
        puts "using tcl native file"
        if {![file exists $m_currentFile]} return
        if {[catch {open $m_currentFile r} handle]} {
            $itk_component(log) log_string "cannot read user log file $m_currentFile: $handle" error
            return
        }
        set data [read -nonewline $handle]
        close $handle
    }
    set data [split $data \n]
    set ll [llength $data]
    puts "number of lines: $ll"
    set contents ""
    set num 0
    foreach line $data {
        incr num
        if {$num == 1} continue
        set log_line [lineToContents $line]
        if {$log_line != ""} {
            lappend contents $log_line
        }
    }
    $itk_component(log) bulkLog contents
}
body DCS::UserLogView::downloadFile { } {
    ### get destination file name
    set fileName [tk_getSaveFile -title "download UserLog file"]
    if {$fileName == ""} return

    ### get source file name
    set strContents [$m_strCurrentUserLog getContents]
    set srcFile [lindex $strContents 0]
    if {$srcFile == "" || ![file exists $srcFile]} {
        log_error "userLog $srcFile not available"
        return
    }

    #### copy ##
    if {$USE_IMPERSON} {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        if {[catch {impCopyFile $user $SID $srcFile $fileName} errMsg]} {
            log_error "download failed: $errMsg"
        } else {
            log_note "userLog downloaded to $fileName"
        }
    } else {
        if {[catch {file copy -force $srcFile $fileName} errMsg]} {
            log_error "download failed: $errMsg"
        } else {
            log_note "userLog downloaded to $fileName"
        }
    }
}
body DCS::UserLogView::selectFile { } {
    set dir [::config getUserLogDir]
    if {$dir == ""} {
        set dir "/data/blctl/userLog/[::config getConfigRootName]"
    }

    if {$USE_IMPERSON} {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        set fileName [impGetOpenFile $user $SID $dir "*.ulg"]

        if {$fileName != ""} {
            set fileName [file join $dir $fileName]
        }
    } else {
        set types {
            {"UserLog" .ulg}
            {All *}
        }
        ### get src file name
        set fileName [tk_getOpenFile \
        -title "select UserLog file" \
        -initialdir $dir \
        -filetypes $types \
        ]
    }
    if {$fileName == ""} return

    puts "filename: $fileName"
    set gCheckButtonVar($this,pause) 1
    set m_currentFile $fileName
    loadCurrentFile
}
body DCS::UserLogView::handleStaff { name_ ready_ alias_ status_ - } {
    #puts "handleStaff: ready: $ready_ status: $status_"

    set display_file_button 0

    if {$ready_ && $status_} {
        set display_file_button 1
    }

    pack forget $itk_component(file)
    pack forget $itk_component(refresh)
    pack forget $itk_component(download)
    pack forget $itk_component(newlog)
    pack forget $itk_component(pause)

    if {$display_file_button} {
        #puts "display file button"
        pack $itk_component(file) -side left
    }
    #pack $itk_component(refresh) -side left
    pack $itk_component(download) -side left
    pack $itk_component(newlog) -side left
    pack $itk_component(pause) -side left
}
class DCS::UserChatView {
    inherit ::itk::Widget

    itk_option define -showControls showControls ShowControls 0
    itk_option define -controlSystem controlSystem ControlSystem "::dcss"

    itk_option define -noSpawn noSpawn NoSpawn 0 {
        repackControlSite
    }

    ########## use this to connect to dcs message ####
    public proc handleNewEntry { message } {
        foreach instance $gInstanceList {
            $instance handleNewMessage $message
        }
    }

    public method handleNewMessage { message }

    public method send { } {
        set clientState [$itk_option(-controlSystem) cget -clientState]
        set user [$itk_option(-controlSystem) getUser]

        if {$clientState == "offline"} {
            puts "not log in yet"
            return
        }
        set tag chat_[lindex $m_colorTag $m_type]
        puts "sending with tag=$tag"
        set msg [list gtos_log $tag $user [$itk_component(contents) get]]
        $itk_component(contents) delete 0 end

        $itk_option(-controlSystem) sendMessage $msg
    }

    public method handleDoubleClick { } {
        ### we do not want user to filter chat messages
        return

        set old_show $itk_option(-showControls)
        set new_show [expr "!$old_show"]
        configure -showControls $new_show
    }
    public method handleLevelFilterChange { } {
        set m_displayLevel [$itk_component(level_filter) get]
        if {[llength $m_displayLevel] >= 3} {
            set m_displayLevel all
        }
        loadCurrentFile
    }

    public method handleStaff 

    public method handleStringEvent { args } {
        if {!$gCheckButtonVar($this,pause)} {
            loadCurrentFile
        }
    }

    public method handlePause { } {
        if {!$gCheckButtonVar($this,pause)} {
            refresh
        }
    }

    public method refresh { } {
        loadCurrentFile
    }
    public method selectFile { }

    public method handleTypeChange { } {
        set color [lindex $m_colorValue $m_type]
        $itk_component(contents) configure \
        -foreground $color
    }

    public method loadCurrentFile { }
    public method downloadFile { }

    public method spawn { } {
        global DCS_DIR
        global gNickName
        exec $DCS_DIR/BluIceWidgets/bluice.tcl [::config getConfigRootName] chatOnly $gNickName &
    }

    private method repackControlSite { } {
        set slaves [grid slaves $itk_component(controlFrame)]
        if {$slaves != ""} {
            eval grid forget $slaves
        }
        grid $itk_component(download) -row 0 -column 0
        if {$m_staff} {
            grid $itk_component(file) -row 0 -column 1
        }
        #grid $itk_component(refresh) -row 0 -column 2
        if {!$itk_option(-noSpawn)} {
            grid $itk_component(spawn) -row 0 -column 3
        }
        grid $itk_component(newlog) -row 0 -column 4
        grid $itk_component(pause) -row 0 -column 5

        grid columnconfig $itk_component(controlFrame) 6 -weight 10

    }

    private method lineToContents { line }

    private method getExtraColors { } {
        set i 0

        set result [list]

        while {1} {
            incr i
            set tag color_$i
            set extraColor [::config getStr chat_room.$tag]
            if {$extraColor == ""} {
                break
            }
            set value ""
            foreach {name value} $extraColor break
            if {$value == ""} {
                set value $name
            }
            lappend m_colorTag $tag
            lappend m_colorName $name
            lappend m_colorValue $value

            lappend result $tag $value
        }
        set m_numColor [llength $m_colorTag]

        return $result
    }

    private variable m_deviceFactory
    private variable m_opUserChat
    private variable m_strCurrentUserChat
    ### note, warning, error, severe
    private variable m_displayLevel all
    private variable m_currentFile ""
    private common gCheckButtonVar

    ##### for auto register ###
    private common gInstanceList ""

    #########################
    private common USE_IMPERSON 0

    private variable m_type

    private variable m_staff 0

    ### Tag is what to send for the message type field
    ### Name is what to display for user
    ### Value is the color to use (maybe #a0a0a0)
    private variable m_numColor 4
    private variable m_colorTag [list output note warning error]
    private variable m_colorName [list black blue brown red]
    private variable m_colorValue [list black blue brown red]

    constructor { args } {
        set extraColors [getExtraColors]

        set m_deviceFactory [DCS::DeviceFactory::getObject]
        set m_opUserChat [$m_deviceFactory createOperation userChat]
        set m_strCurrentUserChat [$m_deviceFactory createString current_user_chat]

        set gCheckButtonVar($this,pause) 0

        itk_component add ring {
            frame $itk_interior.r
        }

        itk_component add controlFrame {
            frame $itk_component(ring).control
        } {
        }
        set controlSite $itk_component(controlFrame)

        itk_component add download {
            button $controlSite.download \
            -text "Save File" \
            -command "$this downloadFile"
        } {
        }
        itk_component add file {
            button $controlSite.file \
            -text "Load File" \
            -command "$this selectFile"
        } {
        }
        itk_component add refresh {
            button $controlSite.refresh \
            -text "Refresh" \
            -command "$this refresh"
        } {
        }
        itk_component add spawn {
            button $controlSite.spawn \
            -text "Chat View" \
            -command "$this spawn"
        } {
        }
        itk_component add newlog {
            ::DCS::Button $controlSite.newlog \
            -text "Clear All" \
            -command "$m_opUserChat startOperation"
        } {
        }
        itk_component add pause {
            checkbutton $itk_component(controlFrame).pause \
            -text "Pause" \
            -command "$this handlePause" \
            -variable [list [::itcl::scope gCheckButtonVar($this,pause)]]
        } {
        }

        itk_component add log {
            DCS::scrolledLog $itk_component(ring).lll \
            -extraTypes $extraColors \
            -onDoubleClick "$this handleDoubleClick" \
            -sbwidth 6 \
            -scrollmargin 0
        } {
            keep -background -relief -width
        }

        itk_component add filterFrame {
            frame $itk_component(ring).filterFrame
        } {
        }

        itk_component add level_filter {
            ::iwidgets::checkbox $itk_component(filterFrame).level_filter \
            -labelpos nw \
            -labeltext "level filter" \
            -orient horizontal
        } {
        }
        $itk_component(level_filter) add note -text note
        $itk_component(level_filter) add warning -text warning
        $itk_component(level_filter) add error -text error
        $itk_component(level_filter) select note
        $itk_component(level_filter) select warning
        $itk_component(level_filter) select error
        $itk_component(level_filter) configure \
        -command "$this handleLevelFilterChange"

        pack $itk_component(level_filter) -side left

        itk_component add sendFrame {
            frame $itk_component(ring).send
        } {
        }

        itk_component add contents {
            entry $itk_component(sendFrame).contents \
            -font -*-courier-bold-r-*-*-12-*-*-*-*-*-*-* \
            -background white \
            -width 80
        } {
        }
        bind $itk_component(contents) <Return> "$this send"

        itk_component add note {
            label $itk_component(sendFrame).note \
            -text "Type message then hit Enter"
        } {
        }

        itk_component add type {
            iwidgets::Labeledframe $itk_component(sendFrame).type \
            -labeltext Color \
            -labelpos nw \
        } {
        }

        set typeSite [$itk_component(type) childsite]

        for {set i 0} {$i < $m_numColor} {incr i} {
            set display [lindex $m_colorName $i]
            set color   [lindex $m_colorValue $i]

            radiobutton $typeSite.r$i \
            -text $display \
            -foreground $color \
            -selectcolor $color \
            -value $i \
            -variable [scope m_type] \
            -command "$this handleTypeChange"

            pack $typeSite.r$i -side left
        }
        $typeSite.r0 invoke

        #pack $itk_component(contents) -side left -expand 1 -fill x
        #pack $itk_component(type) -side left
        grid $itk_component(contents) $itk_component(type) -sticky news
        grid $itk_component(note)     ^

        grid columnconfigure $itk_component(sendFrame) 0 -weight 100


        pack $itk_component(controlFrame) -side top -fill x
        pack $itk_component(log) -side top -expand 1 -fill both
        pack $itk_component(sendFrame) -side bottom -fill x

        pack $itk_component(ring) -expand 1 -fill both
        eval itk_initialize $args

        repackControlSite

        #announceExist
        lappend gInstanceList $this

        $m_strCurrentUserChat register $this contents handleStringEvent
        $itk_option(-controlSystem) register $this staff handleStaff
    }

    destructor {
        $itk_option(-controlSystem) unregister $this staff handleStaff
        $m_strCurrentUserChat unregister $this contents handleStringEvent
        set index [lindex $gInstanceList $this]
        if {$index >= 0} {
            set gInstanceList [lreplace $gInstanceList $index $index]
        } else {
            puts "not in instance list"
        }
    }
}

configbody DCS::UserChatView::showControls {
    pack forget $itk_component(filterFrame)
    pack forget $itk_component(log)
    if {$itk_option(-showControls)} {
        pack $itk_component(filterFrame) -side top -fill x
        pack $itk_component(log) -side top -expand 1 -fill both
   } else {
        pack $itk_component(log) -side top -expand 1 -fill both
   }
}

body DCS::UserChatView::handleNewMessage { message_ } {
    ########### flags check ###########
    if {$gCheckButtonVar($this,pause)} return

    foreach { dummy type sender } $message_ break
    set contents [lrange $message_ 3 end]

    ######## filter #####
    if {$m_displayLevel  != "all" && [lsearch $m_displayLevel $type] < 0} {
        return
    }

    #### display ####
    if {[string range $type 0 4] == "chat_"} {
        set type [string range $type 5 end]
    }
    $itk_component(log) log_string "$sender: $contents" $type
}
body DCS::UserChatView::lineToContents { line } {
    set contents ""
    set text ""
    if {![catch {llength $line} ll] && $ll == 4} {
        foreach {entryTime type sender text} $line break
    } else {
        ### the text part may contain special characters
        ####### retrieve timestamp type catlog and text ######
        set startIndex 0
        for {set i 0} {$i < 3} {incr i} {
            set startIndex [string first {" "} $line $startIndex]
            if {$startIndex < 0} {
                break
            }
            incr startIndex 3
        }
        if {$startIndex > 3} {
            set header_end [expr $startIndex -3]
            set text_start $startIndex
            set header [string range $line 0 $header_end]
            if {![catch {llength $header} ll] && $ll == 3} {
                foreach {entryTime type sender} $header break
                set text [string range $line $text_start end-1]
                puts "header: $header text: $text"
            }
        }
    }
    if {$text != ""} {
        if {$m_displayLevel == "all" || \
        [lsearch $m_displayLevel $type] >= 0} {
            set contents [list $entryTime $type "$sender: $text"]
        }
    } else {
        if {$line != ""} {
            log_error "bad line from userChat file: $line"
        }
    }
    return $contents
}
body DCS::UserChatView::loadCurrentFile { } {
    puts "loadCurrentFile"
    $itk_component(log) clear
    if {!$gCheckButtonVar($this,pause)} {
        set strContents [$m_strCurrentUserChat getContents]
        set m_currentFile [lindex $strContents 0]
    }
    puts "loadCurrentFile $m_currentFile"

    if {$m_currentFile == ""} return

    if {$USE_IMPERSON} {
        puts "using impersonal"

        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        if {[catch {impReadFile $user $SID $m_currentFile} data]} {
            $itk_component(log) log_string "cannot read user chat file $m_currentFile: $data" error
            return
        }
    } else {
        puts "using tcl native file"
        if {![file exists $m_currentFile]} return
        if {[catch {open $m_currentFile r} handle]} {
            $itk_component(log) log_string "cannot read user chat file $m_currentFile: $handle" error
            return
        }
        set data [read -nonewline $handle]
        close $handle
    }
    set data [split $data \n]
    set ll [llength $data]
    puts "number of lines: $ll"
    set contents ""
    set num 0
    foreach line $data {
        incr num
        if {$num == 1} continue
        set log_line [lineToContents $line]
        if {$log_line != ""} {
            lappend contents $log_line
        }
    }
    $itk_component(log) bulkLog contents
}
body DCS::UserChatView::downloadFile { } {
    ### get destination file name
    set fileName [tk_getSaveFile -title "download UserChat file"]
    if {$fileName == ""} return

    ### get source file name
    set strContents [$m_strCurrentUserChat getContents]
    set srcFile [lindex $strContents 0]
    if {$srcFile == "" || ![file exists $srcFile]} {
        log_error "userChat $srcFile not available"
        return
    }

    #### copy ##
    if {$USE_IMPERSON} {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        if {[catch {impCopyFile $user $SID $srcFile $fileName} errMsg]} {
            log_error "download failed: $errMsg"
        } else {
            log_note "userLog downloaded to $fileName"
        }
    } else {
        if {[catch {file copy -force $srcFile $fileName} errMsg]} {
            log_error "download failed: $errMsg"
        } else {
            log_note "userChat downloaded to $fileName"
        }
    }
}
body DCS::UserChatView::selectFile { } {
    set dir [::config getUserChatDir]
    if {$dir == ""} {
        set dir "/data/blctl/userChat/[::config getConfigRootName]"
    }

    if {$USE_IMPERSON} {
        set user [$itk_option(-controlSystem) getUser]
        set SID [$itk_option(-controlSystem) getSessionId]
        set fileName [impGetOpenFile $user $SID $dir "*.uct"]

        if {$fileName != ""} {
            set fileName [file join $dir $fileName]
        }
    } else {
        set types {
            {"UserChat" .uct}
            {All *}
        }
        ### get src file name
        set fileName [tk_getOpenFile \
        -title "select UserChat file" \
        -initialdir $dir \
        -filetypes $types \
        ]
    }
    if {$fileName == ""} return

    puts "filename: $fileName"
    set gCheckButtonVar($this,pause) 1
    set m_currentFile $fileName
    loadCurrentFile
}
body DCS::UserChatView::handleStaff { name_ ready_ alias_ status_ - } {
    #puts "handleStaff: ready: $ready_ status: $status_"
    if {!$ready_} return

    set m_staff $status_

    repackControlSite
}
### for bluice chatOnly
proc startChat { config_ } {
    wm title . "ChatView for beamline [$config_ getConfigRootName]"
    wm resizable . 1 1
    wm geometry . 800x700

    ### do we need status bar
    ##StatusBar .activeButton

    DCS::UserChatView .chat -noSpawn 1

    dcss configure -forcedLoginCallback "::.setup getLogin"

    pack .chat -expand 1 -fill both
}
