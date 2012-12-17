#!/bin/csh -f
source ${LABELIT_BUILD}/setpaths.csh
setenv SPOTD ${PROJECT_SRC}/diffimage_regression_test
setenv SPOTREF ${SPOTD}/testoutput
setenv imagePath ${SPOTD}/rawdata/ana2/F3/vinc_F3_021.img

cd ${TEST_DIR}
labelit.reset
labelit.index \
${SPOTD}/rawdata/ana2/F3 \
distl_permit_binning=False --index_only \

#Later, change this so indexing is directly linked to markup file,
#without intermediate creation of pickle files.

labelit.python << eof
import os,sys
from labelit.webice_support import SupportFactory, markup_header, ring_markup
from labelit.webice_support import spot_center_markup,all_other_markup

filename = "${imagePath}"
args = [ filename ]
SF = SupportFactory()
frame = SF.get_frame(args)

newname = "${TEST_DIR}/test2.spt.img"
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

diff $TEST_DIR/test2.log ${SPOTREF}/test2.log
diff $TEST_DIR/test2.spt.img ${SPOTREF}/test2.spt.img

$TEST2_EXE $TEST_DIR/test2.spt.img $TEST_DIR/test2.jpeg $TEST_DIR/test2t.jpeg
diff $TEST_DIR/test2.jpeg ${SPOTREF}/test2.jpeg
diff $TEST_DIR/test2t.jpeg ${SPOTREF}/test2t.jpeg
