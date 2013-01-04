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

#trim the private keyword from the session id
proc stripPrivateKeyword { session_ } {
    if {[string equal -length 7 $session_ "PRIVATE"]} {
        return [string range $session_ 7 end]
    } else {
        return $session_
    }
}



class Pilatus::MoveFileCommand {
    
    public variable localFileName
    public variable remoteFileName
    public variable userName
    public variable sessionId
    public variable timestamp
    public variable startMs

    constructor {localFileName_ remoteFileName_ userName_ sessionId_ } {
        set localFileName $localFileName_
        set remoteFileName $remoteFileName_
        set userName $userName_
        set sessionId $sessionId_
        set timestamp [clock seconds]
    }

    public method toStr {} {
        return "$timestamp $localFileName $remoteFileName $userName $sessionId"
    }

    destructor {
        file delete $localFileName
    }
}


set gLatestImageUpdateTimestamp 0

class Pilatus::MoveFileCommandQueue {
    private variable fileQueue
    private variable _remoteFileNameHash

    constructor {} {
        set fileQueue ""
        array set _remoteFileNameHash {}
    }

    public method getObjFromRemoteFile {remoteFile} {
        return [lindex [array get _remoteFileNameHash $remoteFile] 1]
    }

    public method addToQueue { fileObj now} {
        #puts "$this addToQueue [$fileObj cget -remoteFileName]"

        if {$now} {
            set fileQueue [linsert $fileQueue 0 $fileObj] 
        } else {
            lappend fileQueue $fileObj
        } 
        set remoteFile [$fileObj cget -remoteFileName]
        set _remoteFileNameHash($remoteFile) $fileObj
    }

    public method removeFromQueue { fileObj } {
        #puts "$this removeFromQueue [$fileObj cget -remoteFileName] $fileObj"
        set remoteFile [$fileObj cget -remoteFileName]
        set index -1
        foreach obj $fileQueue {
            incr index
            if { [$obj cget -remoteFileName] != $remoteFile} continue
            removeFromQueueAndHash $remoteFile $index
            return 
        }
        puts "removeFromQueue could not find a match"
        exit
    }

    private method removeFromQueueAndHash { remoteFile index } {
        #puts "remove $remoteFile $index"
        array unset _remoteFileNameHash $remoteFile

        #puts "$this [ array names _remoteFileNameHash]"

        set fileQueue [lreplace $fileQueue $index $index]
    }

    public method findOldestExisting { } {

        foreach fileObj $fileQueue {
            if { ! [file exists [$fileObj cget -localFileName]] } continue
            
            return $fileObj
        }
    }

}

class Pilatus::FileMover {

    public variable dcss
    public variable sleepTimeMs 1000
    public variable imperson
    public variable movedFilenameList

    private variable _files


    constructor {} {
        set _files [namespace current]::[Pilatus::MoveFileCommandQueue #auto]
        set movedFilenameList ""
        after 1000 [list $this updateLastImageCollectedBg]
    }

    public method afterPropertiesSet {} {
        #after 1000 [list $this backgroundMover]
    }

    public method moveFile {localFile remoteFile userName sessionId now} {

        set duplicate [$_files getObjFromRemoteFile $remoteFile]
        if { $duplicate != ""} {
            $_files removeFromQueue $duplicate
            delete object $duplicate
        }
        
        set fileObj [namespace current]::[Pilatus::MoveFileCommand #auto $localFile $remoteFile $userName $sessionId ]
        $_files addToQueue $fileObj $now
 
    }

    public method backgroundMover {} {
        #puts "background"
        set fileObj [$_files findOldestExisting] 
        if { $fileObj != "" } {
            set remoteFile [$fileObj cget -remoteFileName]

            #the imp writefile command can return control to the tcl interpreter, so it is important to
            #remove the object from the queue before starting the move, otherwise other events
            #may attempt to remove the object before the copy is finished.
            $_files removeFromQueue $fileObj
            puts "MOVE $remoteFile"
            move $fileObj 
        } else {
            after $sleepTimeMs [list $this backgroundMover]
        }
    }


    public method move { fileObj } {

        set localFileName [$fileObj cget -localFileName]
        set remoteFile [$fileObj cget -remoteFileName]
        set userName [$fileObj cget -userName]
        set sessionId [$fileObj cget -sessionId]
        $fileObj configure -startMs [clock clicks -millisecond]

        set timeTxt [time {
            set img [open $localFileName r]
            fconfigure $img -translation binary
            set data [read $img]
            close $img
        } ]

        #puts "COPY: read from $localFileName time: $timeTxt"

        $imperson writeFiles $userName $sessionId $remoteFile $data  [list $this handleWriteFinish $fileObj] [list $this handleMoveFinish $fileObj] [list $this handleMoveError $fileObj]  [list $this handleMoveWarn $fileObj]

        #invalidate object after copy
        #$imageParams_ configure -operationHandle ""
        #puts "done writing"
    }

    public method handleWriteFinish { fileObj } {
        if { [catch {
            puts "WROTE [$fileObj cget -remoteFileName] in [expr [clock clicks -millisecond] - [$fileObj cget -startMs]  ] ms"
            #set movedFilenameList [linsert $movedFilenameList 0 [list [clock seconds] [$fileObj cget -remoteFileName]]]
            #delete object $fileObj
        } errorMsg ] } {
            puts "MOVE FINISH ERROR"
        }
        backgroundMover
    }

    public method handleMoveFinish { fileObj } {
        if { [catch {
            #puts "MOVED [$fileObj cget -remoteFileName]"
            set movedFilenameList [linsert $movedFilenameList 0 [list [clock seconds] [$fileObj cget -remoteFileName]]]
            delete object $fileObj
        } errorMsg ] } {
            puts "MOVE FINISH ERROR"
        }
        #backgroundMover
    }

    public method handleMoveError { fileObj } {
        if { [catch {
            puts "MOVE ERROR [$fileObj cget -remoteFileName]"
            moveToFailedCopyDir $fileObj
        } errorMsg ] } {
            puts "SEVERE error: could not save file $errorMsg"
        }

        backgroundMover
    }

    private method moveToFailedCopyDir { fileObj } {
        set localFileName [$fileObj cget -localFileName]

        set localDir [file dirname $localFileName] 
        set localBadDir ${localDir}/failedCopy

        file mkdir $localBadDir

        set localName [file tail $localFileName]
        file rename $localFileName ${localBadDir}/${localName}


        set failCopyDef [open ${localBadDir}/${localName}.def w]
        puts $failCopyDef [$fileObj toStr]        
        close $failCopyDef

    }

    public method updateLastImageCollectedBg { } {
        if { [catch {
            updateLastImageCollected
        } errorMsg ] } {
            puts "ERROR: update lastImage: $errorMsg"
        }
        after 1000 [list $this updateLastImageCollectedBg]
    }

    private method updateLastImageCollected { } {
        if { $movedFilenameList == "" } return 

        set cnt 0
        foreach imageName $movedFilenameList {
            set timestamp [lindex $imageName 0]
            set filename [lindex $imageName 1]
            puts "$timestamp: $filename" 
            
            if { $timestamp + 1 <= [clock seconds] } {
                $dcss sendMessage "htos_set_string_completed lastImageCollected normal $filename"
                #delete everything older than the one reported
                set movedFilenameList [lreplace $movedFilenameList $cnt end ]
                return
            }
            incr cnt
        }
    }

    public method handleMoveWarn { fileObj backupDir } {
        if { [catch {
            set filename [$fileObj cget -remoteFileName]
            $dcss sendMessage "htos_note movedExistingFile $filename $backupDir"
        } errorMsg ] } {
            puts "SEVERE error: could not send warning to dcss"
        }
    }


}

