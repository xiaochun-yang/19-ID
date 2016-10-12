

class Pilatus::TestImpMoveFiles {

    public variable imperson
    public variable userName scottm
    public variable sessionId 701CFBE81D0E89DB9604ABA074F94F45
    public variable remoteDir /data/scottm/testFileMover/
    public variable localDir tests/data/
    public variable rootDir /home/det/dcs/pilatusDhs/
    private variable _fileList

    public method afterPropertiesSet {} {
        set _fileList [glob $rootDir/$localDir/*.cbf]
        moveNextFile
    }

    public method moveNextFile {} {
        
        if {[llength $_fileList] == 0 } {
            exit
        }
        set file [lindex $_fileList 0]
        moveFile $file
        set _fileList [lrange $_fileList 1 end]

    }

    public method moveFile { fileName } {

        set timeTxt [time {
            set img [open $fileName r]
            fconfigure $img -translation binary
            set data [read $img]
            close $img
        } ]

        $imperson writeFiles $userName $sessionId $remoteDir/$fileName $data [list $this copyDoneHandle]  [list $this moveDoneHandle] [list $this errorHandle ]
        
        
    }
    public method copyDoneHandle {} {
        puts "done copy"
        #after 1 [list $this moveNextFile]
    }

    public method moveDoneHandle {} {
        puts "done"
        after 1 [list $this moveNextFile]
    }

    public method errorHandle {} {
        puts "error"
        after 1 [list $this moveNextFile]
    }

}



class Pilatus::TestFileMover {

    public variable imperson
    public variable userName scottm
    public variable sessionId 701CFBE81D0E89DB9604ABA074F94F45
    public variable remoteDir /data/scottm/testFileMover/
    #public variable localDir tests/data
    #public variable rootDir /home/det/dcs/pilatusDhs/
    public variable rootDir /ramdisk/
    public variable localDir scottm
    public variable fileMover

    public method afterPropertiesSet {} {


        foreach localFile [glob $rootDir/$localDir/*.cbf] {
            $fileMover moveFile $localFile $remoteDir/$localFile $userName $sessionId false
        }

        $fileMover backgroundMover

    }

}
