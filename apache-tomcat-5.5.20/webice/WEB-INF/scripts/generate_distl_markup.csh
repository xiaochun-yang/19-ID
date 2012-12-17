#!/bin/csh -f

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

set imagePath = $1
set workDir = $2

#echo `date +"%T"` " Started generating markup for image $imagePath"

# Extract the file name without path or extension
set imageFileName = `basename $imagePath`
set imageRootName = `echo $imageFileName | awk 'BEGIN{ FS="."}{ if (NF == 1) { print $0 } else { for (x = 1; x < NF-1; x++) { printf("%s.", $x)} printf("%s",$x) }}'`


labelit.python > ${workDir}/${imageRootName}.out <<eof
import os,sys
from labelit.webice_support import markup_header, spotfinder_markup
from labelit.webice_support.spotfinder import do_distl
from labelit.command_line.stats_distl import webice_image_stats
from labelit.preferences import procedure_preferences
procedure_preferences.phil.distl_permit_binning = True

filename = "${imagePath}"
args = [ filename ]
S,frame = do_distl(args)
newname = "${workDir}/${imageRootName}.spt.img"
g = open(newname,"wb")
g.write(markup_header(filename))
spotfinder_markup(S,frame,g)
g.close()
text = webice_image_stats(S,frame)
logname = "${workDir}/${imageRootName}.tmp"
f = open(logname,"wb")
f.write("${imagePath}\n")
f.write(text)
f.close()
eof

# Calculate score and add it to log file
set score = "`awk -f $WEBICE_SCRIPT_DIR/calculate_distl_score.awk ${workDir}/${imageRootName}.tmp`"
echo "score = $score"
awk -v score="$score" '{ if (NR != 2) { print $0;} else {printf("                              Score:%8d\n", score);} } END{}' ${workDir}/${imageRootName}.tmp > ${workDir}/${imageRootName}.log
rm -rf ${workDir}/${imageRootName}.tmp


