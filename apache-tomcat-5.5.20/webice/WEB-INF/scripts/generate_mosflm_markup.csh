#!/bin/csh -f

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

set imagePath = $1
set workDir = $2

#echo `date +"%T"` " Started generating markup for image $imagePath"

# Extract the file name without path or extension
set imageDir = `dirname $imagePath`
set imageFileName = `basename $imagePath`
set imageRootName = `echo $imageFileName | awk 'BEGIN{ FS="."}{ if (NF == 1) { print $0 } else { for (x = 1; x < NF-1; x++) { printf("%s.", $x)} printf("%s",$x) }}'`

cd ${workDir}

labelit.python << eof
import os,sys
from labelit.webice_support import SupportFactory, markup_header, ring_markup
from labelit.webice_support import spot_center_markup,all_other_markup

filename = "${imagePath}"
args = [ filename ]
SF = SupportFactory()
frame = SF.get_frame(args)

newname = "${workDir}/${imageRootName}.spt.img"
dirname = os.path.dirname(newname)
g = open(newname,"wb")
g.write(markup_header(filename))

S = SF.get_spotfinder(infile = filename, pickle_dir = dirname,
  possible_dir = dirname)

ring_markup(S,frame,g)
spot_center_markup(S,frame,g)
all_other_markup(factory=SF,frame=frame,markup=g)

g.close()
eof



