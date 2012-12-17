#!/bin/csh

setenv WEBICE_SCRIPT_DIR `dirname $0`

if ($#argv != 2) then
echo "Usage generate_mathews_report2.csh <screening dir> <jpeg dir>"
exit
endif

# Display image width
set width = 200
# base url
set baseUrl = "http://smb.slac.stanford.edu/~${USER}/SampleQueuing"
set remountDir = REMOUNT

set screeningDir = $1
set jpegDirOrg = $2

set silId = `basename $screeningDir`
set outputFile = "./${silId}.html"
cd $screeningDir

set crystals = (`ls`)

echo '<\!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 TRANSITIONAL//EN">'

echo '<html>'
echo '<head>'
echo '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">'
echo ' '
echo '<title>Sample Queuing Result</title>'
echo ' '
echo '<link rel="stylesheet" href="/secure/smb_mainstyle.css" type="text/css">'
echo '<link rel=stylesheet type="text/css" href="../projectManagement.css">'
echo ' '
echo '</head>'
echo ' '
echo '<body>'
echo ' '
echo '<h2>CassetteID '$silId'</h2>'
echo '<table border="1" cellborder="1">'
echo '<tr>'
echo '<th>CrystalID</th>'
echo '<th>Run1/image1</th>'
echo '<th>Reorient/faceon (after applying phi offset)</th>'
echo '<th>Reorient/faceon (after applying matchup)</th>'
echo '<th>Run1/image2</th>'
echo '<th>Reorient/edgeOn (after applying phi offset)</th>'
echo '<th>Reorient/edgeOn (after applying matchup)</th>'
echo '<th>best_phi_strategy contents</th>'
echo '</tr>'

foreach crystal ($crystals)

if (! -d $crystal) then
	continue;
endif

cd $crystal/autoindex

set jpegDir = ${jpegDirOrg}/${crystal}

set jpeg1 = ${baseUrl}/$jpegDir/${crystal}_0deg_001_box.jpg
set jpeg2 = ${baseUrl}/$jpegDir/phiOffset_${crystal}_faceon_box.jpg
set jpeg3 = ${baseUrl}/$jpegDir/profile_remount_${crystal}_90_box.jpg
set jpeg4 = ${baseUrl}/$jpegDir/${crystal}_90deg_002_box.jpg
set jpeg5 = ${baseUrl}/$jpegDir/phiOffset_${crystal}_edgeOn_box.jpg
set jpeg6 = ${baseUrl}/$jpegDir/profile_remount_${crystal}_180_box.jpg

set set contents = ""
set phiShiftFile = $remountDir/best_phi_strategy.tcl

if (-e $phiShiftFile) then

set contentFile = $phiShiftFile

else # phiShiftFile does not exist

if (-d $remountDir/LABELIT) then
# No best_phi_strategy.tcl but REMOUNT/LABELIT/labelit.out exists.
# Most likely, labelit failed in REMOUNT.
set contents = "REMOUNT"
set contentFile = $remountDir/LABELIT/labelit.out
else
# No best_phi_strategy.tcl and no REMOUNT/LABELIT dir
# Check if first pass labelit failed
if (-e LABELIT/LABELIT_possible) then
# but first pass labelit is ok
set contents = "REMOUNT labelit did not run"
else
# and first pass labelit failed
set contents = "Run1"
set contentFile = LABELIT/labelit.out
endif
endif

endif # if phiShiftFile exists

set bestSolution1 = "cannot autoindex"
set bestSolution2 = "cannot autoindex"

if (-e LABELIT/labelit.out) then
set bestSolution1 = `$WEBICE_SCRIPT_DIR/generate_mathews_report_helper2.csh .`
endif
if (-e $remountDir/LABELIT/labelit.out) then
set bestSolution2 = `$WEBICE_SCRIPT_DIR/generate_mathews_report_helper2.csh $remountDir`
endif


echo '<tr>'
echo '<td>'$crystal'</td>'
echo '<td><img wide="'$width'" src="'$jpeg1'"/></td>'
echo '<td><img wide="'$width'" src="'$jpeg2'"/></td>'
echo '<td><img wide="'$width'" src="'$jpeg3'"/></td>'
echo '<td><img wide="'$width'" src="'$jpeg4'"/></td>'
echo '<td><img wide="'$width'" src="'$jpeg5'"/></td>'
echo '<td><img wide="'$width'" src="'$jpeg6'"/></td>'
echo '<td><pre>'
echo $contents
if (-e $contentFile) then
cat $contentFile
endif
echo "Run1: $bestSolution1"
echo "REMOUNT: $bestSolution2"
echo '</pre></td>'
echo '</tr>'

cd $screeningDir

end # foreach crystal

echo '</table>'
echo '</body>'
echo '</html>'


