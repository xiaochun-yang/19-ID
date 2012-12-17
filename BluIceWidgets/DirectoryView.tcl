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

#
# DirectoryView.tcl
#
# part of Screening UI
# used by Sequence.tcl
#


package require Itcl
package require Iwidgets
package require BWidget

package provide BLUICEDirectoryView 1.0

# ===================================================

::itcl::class DirectoryView {
	inherit ::itk::Widget

	# contructor / destructor
	constructor {} {}
	
	#  protected variables
	protected variable m_fileListLimit 2500
	protected variable m_filesPerSubDirLimit 620
	#protected variable m_directory "U:/gwolf"
	protected variable m_directory "/data/scottm/"
    protected variable m_fileCount 0
	
	# private variables
	private variable m_font "*-helvetica-bold-r-normal--15-*-*-*-*-*-*-*"
	private variable m_borderWidth 2
	private variable m_xviewSize 120
	private variable m_yviewSize 5
	private variable m_lastUpdateRequestID 0
	
	# private methods
	private method createCaptionFrame 
	private method createFileListFrame
	private method bindEventHandlers { canvasFrame } {}
	private method handleSelectEvent { box } {}
	private method handleOpenClick {} {}
	private method getFileInfoList { flist updateRequestID } {}
	private method trc_msg { text } {}
	
	# public methods
	public method setDirectory { dir } {}
	public method getDirectory {} {}
	public method createFileList {} {}
	public method updateFileList { subdir fileName } {}	
	public method clear { } {}

    # one way to update is setDirectory, another way is using
    # DCS string to automatically update

    # to update file list without change dir is to call
    # createFileList
}

# ===================================================
::itcl::body DirectoryView::constructor {} {
	
	#set data { {offline.img} }
	set data { }
	
	itk_component add ring {
		frame $itk_interior.ring -borderwidth $m_borderWidth
	}
	
	createCaptionFrame

	createFileListFrame $data
	
	DynamicHelp::register $itk_component(open) balloon "Open result image"
	
	bindEventHandlers $itk_component(fileList)

	pack $itk_interior -side top -expand 1 -fill both
	pack $itk_component(ring) -side left -expand 1 -fill both
}

::itcl::body DirectoryView::createCaptionFrame { } {

	# Create a frame caption
	itk_component add caption {
		frame $itk_interior.header -bd 4
	} {}
	
	itk_component add fresh {
		button $itk_component(caption).u -text "Refresh" -font $m_font
	} {}
	
	itk_component add label {
		label $itk_component(caption).l \
        -text "Results: " \
        -anchor e  \
        -width 10 \
        -font $m_font
	} {}
	
	itk_component add top_dir {
		label $itk_component(caption).d \
        -text "$m_directory" \
        -anchor w \
        -width 24 \
        -font $m_font
	} {}
	
	itk_component add open {
		button $itk_component(caption).buttonOpen -text "Open" -font $m_font
	} {}
	
	pack $itk_component(caption) -side top	
	pack $itk_component(open) -side right
	pack $itk_component(fresh) -side left
	pack $itk_component(label) -side left
	pack $itk_component(top_dir) -side left
}

# ===================================================
# ===================================================

::itcl::body DirectoryView::createFileListFrame { data } {
	
	# Create the top frame (component container)
	
	itk_component add fileListFrame {
		frame $itk_component(ring).flf -borderwidth 1 -relief groove
	}

	# Create a scrolling Listbox
	set bgtext [$itk_component(open) cget -background]
	set bgscroll [$itk_component(open) cget -background]
	set view ""
	append view $m_xviewSize "x" $m_yviewSize

	itk_component add fileList {
		::iwidgets::scrolledlistbox $itk_component(fileListFrame).scrolledList -sbwidth 12 -background $bgscroll -textbackground $bgtext -borderwidth 2 -visibleitems $view -textfont $m_font
	} {
	}

	pack $itk_component(fileListFrame) -side top -expand 1 -fill both
	pack $itk_component(fileList) -side top -expand 1 -fill both
	
	#fill in the data
	foreach {item} "$data" {
		$itk_component(fileList) insert end $item
	}

}

# ===================================================

::itcl::body DirectoryView::bindEventHandlers { scrolledList } {
	
	$scrolledList config -selectioncommand [::itcl::code $this handleSelectEvent $scrolledList]
	$scrolledList config -dblclickcommand [::itcl::code $this handleOpenClick]

	$itk_component(open) config -command [::itcl::code $this handleOpenClick]
	$itk_component(fresh) config -command [::itcl::code $this createFileList]
	
	trc_msg "bindEventHandlers"
}

# ===================================================

::itcl::body DirectoryView::handleSelectEvent { box} {
	trc_msg "handleSelectEvent"
	
	set filename [$box getcurselection]
	trc_msg "filename=$filename"
	
	#exec adxv $filename 
	#exec netscape $filename 
}

# ===================================================

::itcl::body DirectoryView::handleOpenClick {} {
	trc_msg "handleOpenClick"
	
	set filename [$itk_component(fileList) getcurselection]
	if { [string length $filename]<=0 } {
		set filename [$itk_component(fileList) get end]
	}
	trc_msg "filename=$filename"
	set filepath [file join $m_directory $filename]
	trc_msg "filepath=$filepath"
	
	set extention [file extension $filename]
	switch -exact -- $extention {
        .mar2300 -
        .mar2000 -
        .mar1600 -
        .mar1200 -
        .mar3450 -
        .mar3000 -
        .mar2400 -
        .mar1800 -
		.img { 
			trc_msg "load image - exec adxv $filepath"
			set result [ catch {exec adxv $filepath &} ]
			trc_msg "$result"
		}
		.jpg { 
			trc_msg "load jpeg - exec display $filepath"
			set result [ catch {exec display $filepath &} ]
			trc_msg "$result"
		}
		.tif { 
			trc_msg "load image - exec xv $filepath"
			set result [ catch {exec xv $filepath &} ]
			trc_msg "$result"
		}
		default { log_error unknown file extention=$extention }
	}	
}

# ===================================================

::itcl::body DirectoryView::getFileInfoList { flist updateRequestID } {
	#trc_msg "DirectoryView::getFileInfoList"
	
	set nFilesInThisDir 0
	set maxTime 0
	set dirname ""
	set fileInfoList {}
	foreach fileName $flist {
		update
		if { $updateRequestID!=$m_lastUpdateRequestID } {
			trc_msg "aborted DirectoryView::getFileInfoList $updateRequestID"
			return
		}
		if { $m_fileCount>$m_fileListLimit } {
			trc_msg "ERROR too many files in this directory (>${m_fileListLimit})"
			set fileInfo [list 999999999999999 "Too many files..."]
			if { [lindex $fileInfoList end]!=$fileInfo } {
				set fileInfoList [linsert $fileInfoList end $fileInfo]
			}
			break
		}
		#trc_msg "fileName=$fileName"
		if { [file isdirectory $fileName] &&  [file readable $fileName] && \
		[file executable $fileName] } {
			set fl [glob -nocomplain -types {d f r} -directory $fileName -- *]
			set fileInfoList [concat $fileInfoList [getFileInfoList $fl $updateRequestID]]
			set m_fileCount [llength $fileInfoList]
			continue;
		}
		# limit the number per images in a subdiretory (for the data-home directory we apply only the total limit "m_fileListLimit")
		incr nFilesInThisDir
		if { $dirname!=$m_directory && $nFilesInThisDir>$m_filesPerSubDirLimit } {
			# we are in a subdirectory and the number of files is above the limit
            trc_msg "skip other files in this directory $dirname"
			continue
		}
		
		# if the filesystem is mixed up we could get an exception in "file mtime...", so we have to catch it...
		set time "000000000000000"
		catch {
			set time [file mtime $fileName]
			set time "00000000000000$time"
			set time [string range $time end-14 end]
			set fileInfo [list $time $fileName]
			set fileInfoList [linsert $fileInfoList end $fileInfo]
			incr m_fileCount
		}
		
		if { $time>$maxTime } {
			set maxTime $time
		}
		if { [string length $dirname]<1 } {
			set dirname [file dirname $fileName]
		}
		if { $dirname=="." } {
			set dirname $m_directory
		}
		if { $dirname!=$m_directory && $nFilesInThisDir==$m_filesPerSubDirLimit } {
			# we are in a subdirectory and the number of files has reached the limit
			set time [format "%s%s" $maxTime "9"]
			set x [format "%s%s" $dirname "/..."]
			set fileInfo [list $time $x]
			set fileInfoList [linsert $fileInfoList end $fileInfo]
		}
	}
	#trc_msg "fileInfoList=$fileInfoList"

	#set n [llength $fileInfoList]
	#trc_msg "fileInfoList length=$n"
	
	return $fileInfoList
}


# ===================================================

::itcl::body DirectoryView::trc_msg { text } {
	puts "$text"
	#print "$text"
}

# ===================================================
# ===================================================
# public methods

::itcl::body DirectoryView::setDirectory { dir } {
	trc_msg "DirectoryView::setDirectory $dir"
	
    if {$m_directory == $dir} {
        return
    }
	set m_directory $dir
    $itk_component(top_dir) config -text "$m_directory"

    #createFileList
    clear
}

# ===================================================

::itcl::body DirectoryView::getDirectory {} {
	return $m_directory
}

# ===================================================

::itcl::body DirectoryView::createFileList {} {
	trc_msg "DirectoryView::createFileList"
	#trc_msg [clock format [clock seconds]]
	
	$itk_component(fileList) clear
	
	set dir $m_directory
	
	incr m_lastUpdateRequestID
	set m_lastUpdateRequestTime [clock format [clock seconds]]
	set m_lastUpdateRequestDirectory $dir
	set updateRequestID $m_lastUpdateRequestID
	trc_msg "DirectoryView::getFileInfoList m_lastUpdateRequestID=$m_lastUpdateRequestID"
	
	if { [file isdirectory $dir]==0 || [file readable $dir]==0 } {
		trc_msg "ERROR DirectoryView::createFileList no readable directory $dir"
		#log_note "No readable screening directory $dir"
		return
	}
	if { [string range $dir end end]!="/" } {
		set dir "$dir/"
	}
	$itk_component(fileList) insert end "Loading $dir ..."
	
	trc_msg "m_directory=$dir"
	
	set flist [glob -nocomplain -types {d f r} -directory $dir -- *]
    set m_fileCount 0
	set fileInfoList [getFileInfoList $flist $updateRequestID]
	if { $updateRequestID!=$m_lastUpdateRequestID } {
      trc_msg "aborted DirectoryView::createFileList"
      return
	}
	
	$itk_component(fileList) clear
	set flistSorted [lsort $fileInfoList]
	foreach file $flistSorted {
		set fileName [lindex $file 1]
		set lngRootName [string length $dir]
		if { [string range $fileName 0 [expr $lngRootName -1]]==$dir } {
			set fileName [string range $fileName $lngRootName end]
		}
		#trc_msg "$fileName"
		$itk_component(fileList) insert end $fileName
	}
	
	$itk_component(fileList) see end
	set size [llength $flistSorted]
	
	if { $size>=$m_fileListLimit } {
		puts "Too many files in directory $m_directory"
	} else {
		puts "$size files in directory $m_directory"
	}
	
	#trc_msg [clock format [clock seconds]]
	
	trc_msg "DirectoryView::createFileList OK $m_lastUpdateRequestID"
} ;# createFileList{}


# ===================================================

::itcl::body DirectoryView::updateFileList { subdir fileName } {
	trc_msg "DirectoryView::updateFileList $subdir $fileName"

	if { $subdir=="." } {
		set subdir ""
	}
	set path [file join $subdir $fileName]
	$itk_component(fileList) insert end $path
	$itk_component(fileList) see end	
}
::itcl::body DirectoryView::clear { } {
	$itk_component(fileList) clear
}

::itcl::class SequenceResultList {
	inherit DirectoryView
    private variable m_deviceFactory

    public method handleOperationEvent { message_ }
    public method handleStringDirectoryEvent

    constructor { args } {
        eval DirectoryView::constructor $args
    } {
        set m_deviceFactory [DCS::DeviceFactory::getObject]
        #register with operations
        set seqObj [$m_deviceFactory createOperation sequence]
        $seqObj registerForAllEvents $this handleOperationEvent

        set dirObj [$m_deviceFactory createString screeningParameters]
        $dirObj createAttributeFromField directory 2
        $dirObj register $this directory handleStringDirectoryEvent
    }
    destructor {
        set seqObj [$m_deviceFactory createOperation sequence]
        $seqObj unRegisterForAllEvents $this handleOperationEvent
        set dirObj [$m_deviceFactory createString screeningParameters]
        $dirObj unregister $this directory handleStringDirectoryEvent
    }
}

::itcl::body SequenceResultList::handleOperationEvent { message_ } {
    puts "SequenceResultList::handleOperationEvent $message_"

    if { [llength $message_] <= 3 } {
        # no useful infomation
        return
    }

    set eventType [lindex $message_ 0]
    set operationName [lindex $message_ 1]
    set operationID [lindex $message_ 2]
    set operationArgs [lindex $message_ 3]

    #only deal with update and complete
    switch -exact -- $eventType {
        stog_operation_completed {
            set operationStatus [lindex $operationArgs 0]
            if {$operationStatus != "normal"} {
                return
            }
        }
        stog_operation_update {
        }
        stog_start_operation -
        default {
            return
        }
    }

    switch -exact -- $operationName {
        sequence {
            if {[lindex $operationArgs 0] == "result"} {
                set subDir [lindex $operationArgs 2]
                set fileName [lindex $operationArgs 3]
                updateFileList $subDir $fileName
                puts "added file list: $subDir $fileName"
            }
        }
    }

}
::itcl::body SequenceResultList::handleStringDirectoryEvent { stringName_ targetReady_ alias_ contents_ - } {
    puts "SequenceResultList::handleStringDirectoryEvent $stringName_ $targetReady_ $contents_" 
    if {!$targetReady_} return

    puts "new dir=$contents_"

    setDirectory $contents_
}
# ===================================================
# ===================================================
#// main

#set top .ex
#FileList results $top



# ===================================================

proc testSequenceResult {} {
	DirectoryView .test

	pack .test

	.test createFileList
}

#testSequenceResult
