#!/bin/csh -f
source ${LABELIT_BUILD}/setpaths.csh
setenv SPOTREF ${PROJECT_SRC}/diffimage_regression_test/testoutput
setenv imagePath \
 ${PROJECT_SRC}/diffimage_regression_test/rawdata/ana2/H3/vinc_H3_021.img

labelit.python <<eof
import os,sys
from labelit.webice_support import markup_header, spotfinder_markup
from labelit.webice_support.spotfinder import do_distl
from labelit.command_line.stats_distl import webice_image_stats
from labelit.preferences import procedure_preferences
procedure_preferences.phil.distl_permit_binning = False

filename = "${imagePath}"
args = [ filename ]
S,frame = do_distl(args)
newname = "${TEST_DIR}/test1.spt.img"
g = open(newname,"wb")
g.write(markup_header(filename))
spotfinder_markup(S,frame,g)
g.close()
text = webice_image_stats(S,frame)
logname = "${TEST_DIR}/test1.log"
f = open(logname,"wb")
f.write(text)
f.close()
eof

diff ${TEST_DIR}/test1.log ${SPOTREF}/test1.log
diff ${TEST_DIR}/test1.spt.img ${SPOTREF}/test1.spt.img
$TEST1_EXE $TEST_DIR/test1.spt.img $TEST_DIR/test1.jpeg $TEST_DIR/test1t.jpeg

$TEST1_EXE $imagePath $TEST_DIR/test1b.jpeg $TEST_DIR/test1bt.jpeg

diff $TEST_DIR/test1.jpeg ${SPOTREF}/test1.jpeg
diff $TEST_DIR/test1t.jpeg ${SPOTREF}/test1t.jpeg
