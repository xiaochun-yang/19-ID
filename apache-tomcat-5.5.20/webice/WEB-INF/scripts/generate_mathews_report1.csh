#!/bin/csh -f

setenv WEBICE_SCRIPT_DIR `dirname $0`

if ($#argv != 1) then
echo "Usage generate_mathews_report1.csh <screening dir>"
exit
endif

set workDir = $1

cd $workDir

set crystals = (`ls`)

echo "Port, Original indexing, Indexing with crystal_orientation, Indexing with known cell, Images"

foreach crystal ($crystals)

if (! -d $crystal) then
	continue;
endif

cd $crystal/autoindex

set out1 = "cannot autoindex"
set out2 = "cannot autoindex"
set out3 = "cannot autoindex"

set out1 = `$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh .`
#$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh .

# Find the lastest backup dir
set counters = (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)
set backupDir = REMOUNT_backup1
foreach counter ($counters)
set testDir = REMOUNT_backup${counter}
set found = 0
if (-d $testDir) then
	set found = 1
	set backupDir = $testDir
else
	break;
endif
end

set image1And2 = `cat autoindex.out | awk '/imageDir/{imageDir = $4;} /image1/{image1 = $4;} /image2/{image2 = $4;} END {print imageDir "/" image1 " " imageDir "/" image2;}'`
set image3And4 = `cat $backupDir/autoindex.out | awk '/imageDir/{imageDir = $4;} /image1/{image1 = $4;} /image2/{image2 = $4;} END {print imageDir "/" image1 " " imageDir "/" image2;}'`
set images = ($image1And2 $image3And4)

if (-e REMOUNT_backup1/LABELIT/labelit.out) then
set out2 = `$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh $backupDir`
#$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh $backupDir
endif
if (-e REMOUNT/LABELIT/labelit.out) then
set out3 = `$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh REMOUNT`
#$WEBICE_SCRIPT_DIR/generate_mathews_report_helper1.csh REMOUNT
endif

echo "${crystal}, ${out1}, ${out2}, ${out3}, $images"


cd $workDir

end # foreach crystal
