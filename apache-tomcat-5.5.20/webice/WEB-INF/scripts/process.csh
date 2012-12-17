#!/bin/csh -f

set curDir = `pwd`

# Set script dir to this script location
setenv WEBICE_SCRIPT_DIR `dirname $0`
cd $WEBICE_SCRIPT_DIR
setenv WEBICE_SCRIPT_DIR `pwd`
set WEBICE_CLASS_DIR = $WEBICE_SCRIPT_DIR/../classes
cd $WEBICE_CLASS_DIR
set WEBICE_CLASS_DIR = `pwd`

cd $curDir

echo `date`" WEBICE_SCRIPT_DIR = $WEBICE_SCRIPT_DIR"
echo `date`" WEBICE_CLASS_DIR = $WEBICE_CLASS_DIR"

# Setup env
source $WEBICE_SCRIPT_DIR/setup_env.csh

set curDir = `pwd`

set baseUrl = "http://smb.slac.stanford.edu/crystal-analysis-dev"
set getHeaderUrl = "http://smbfs.slac.stanford.edu:14007/getHeader"

if ($#argv != 10) then
echo "Usage: process.csh <beamline> <runName> <imageDir> <imageRootName> <imageExt> <firstImageIndex> <numImages> <inverseBeam> <imageWaitTimeout> <minPhiSeparation>"
exit
endif

set beamline = $argv[1]
set runName = $argv[2]
set imageDir = $argv[3]
set imageRootName = $argv[4]
set imageExt = $argv[5]
set firstImageIndex = $argv[6]
set numImages = $argv[7]
set inverseBeam = $argv[8]
set imageWaitTimeout = $argv[9]
set minPhiSeparation = $argv[10]

# Mininum phi range in an integration batch
# This number or phi diff of (lastImageIndex - firstImageIndex) which ever smaller.
# PUT THESE VAR in input file
set minBatchPhiRange = 10
set numBatches = 3
set solutionNum = ""
set laueGroup = ""

set lastImageIndex = `echo $firstImageIndex $numImages | awk '{print $1 + $2 - 1;}'`
set session = `cat /home/$USER/.bluice/session`
set processDir = "/data/$USER/webice/process/$runName"

mkdir -p $processDir
cd $processDir

set skip = 1
if ("$skip" == 0) then

# Wait for 2 images to autoindex. Their phi must be at least minPhiSeparation degrees apart.

if (-e image1.txt) then
rm -rf image1.txt
endif


######################################################
# Get image1 header
######################################################
set firstImageIndexStr = `echo $firstImageIndex | awk '{if ($1 < 10) {print "00"$1;} else if ($1 < 100) {print "0"$1;} else {print $1;}}'`
set image1 = "${imageRootName}_${firstImageIndexStr}"
set firstImagePath = ${imageDir}/${image1}.${imageExt}
set found = 0
while ($found == "0")
set image1Path = $firstImagePath
echo `date`" Trying to get image header for $image1Path from image server."
set imageUrl = "$getHeaderUrl?fileName=$image1Path&userName=$USER&sessionId=$session"
echo `date`" imageURL = $imageUrl"
echo "java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL $imageUrl"
java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL "$imageUrl" > image1.txt
set found = `awk 'NR==1{if (index($0, "ERROR") > 0) {print 0;} else {print 1;}}' image1.txt`
if ("$found" == 1) then
	break;
else
echo `date` `awk 'NR==1{print $0;}' image1.txt`
endif
sleep 5
end
echo `date`" Got image header for $image1Path from image server."

# Get phi from image1 header
set phi1 = `awk '/PHI/{print $2;}' image1.txt`
echo `date`" phi1 = $phi1 degrees."


######################################################
# Get image2 header
######################################################
set imageIndex = $firstImageIndex
set done = 0;
while ($done != 1) 

if (-e image2.txt) then
rm -rf image2.txt
endif

set imageIndex = `echo $imageIndex | awk '{print $1+1;}'`
set imageIndexStr = `echo $imageIndex | awk '{if ($1 < 10) {print "00"$1;} else if ($1 < 100) {print "0"$1;} else {print $1;}}'`

set image2 = "${imageRootName}_${imageIndexStr}"
set found = 0
while ($found == "0")
set image2Path = "${imageDir}/${image2}.${imageExt}"
echo `date`" Trying to get image header for $image2Path from image server."
set imageUrl = "$getHeaderUrl?fileName=$image2Path&userName=$USER&sessionId=$session"
java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL "$imageUrl" > image2.txt
set found = `awk 'NR==1{if (index($0, "ERROR") > 0) {print 0;} else {print 1;}}' image2.txt`
if ($found) then
	break;
else
echo `date` `awk 'NR==1{print $0;}' image2.txt`
endif
sleep 5
end
echo `date`" Got image header for $image2Path from image server."

# Get phi from image2 header
set phi2 = `awk '/PHI/{print $2;}' image2.txt`
echo `date`" phi2 = $phi2 degrees."

# Check if image2 has phi at least minPhiSeparation from image1.
# If not then try next image
set phiDiff = `echo $phi1 $phi2 | awk '{diff = $1 - $2; if (diff < 0) {diff = -1.0*diff;} print diff;}'`
set bigPhiDiff = `echo $phiDiff $minPhiSeparation | awk '{if ($1 >= $2) {print 1;} else {print 0;}}'`
if ($bigPhiDiff == 1) then
	set done = 1
	echo `date`" Phi1 and phi2 differ by $phiDiff degrees."
	break;
endif

# Next image index
echo `date`" Not enough phi separation between image 1 and 2 ($phiDiff degrees). Need at least $minPhiSeparation degrees."

end # while !done

echo `date`" Image $image1Path and image $image2Path will be used for autoindexing."

######################################################
# Autoindex two images. Results will be in /data/$USER/webice/autoindex/$runName
######################################################
set autoindexDir = "/data/$USER/webice/autoindex/$runName"
set autoindexUrl = "$baseUrl/jsp/autoindex.jsp?userName=$USER&SMBSessionID=$session&workDir=$autoindexDir&forBeamLine=$beamline&image1=$image1Path&image2=$image2Path&silId=-1&row=0"
java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL "$autoindexUrl"

set autoindexDone = 0
while ("$autoindexDone" != 1) 
echo `date`" Waiting for autoindex to finish. See autoindex log in $autoindexDir/autoindex.out."
set autoindexDone = `awk 'BEGIN{done = 0;}/Finished running autoindex/{done = 1;} END{print done;}' $autoindexDir/autoindex.out`
sleep 5
end # while autoindexDone

echo `date`" Autoindex finished."

endif # skip

######################################################
# Get best solution and Laue group from autoindex result
######################################################
# Get best solution number
set arr = (`awk -f $WEBICE_SCRIPT_DIR/get_bestsolution_stats.awk $autoindexDir/LABELIT/labelit.out`)
if ($#arr < 4) then
echo `date +"%T"` " Cannot find best integrated solution in the original labelit.out"
echo `date +"%T"` " Skipped recalculating phi strategy for best solution."
set bestSolNum = "01"
set bestLaueGroup = "P1"
else
set bestSolNum = $arr[3]
set bestLaueGroup = `echo $arr[4] | awk -F, '{print $1;}'`
endif #arr size < 4

# If use does not specify which solution or Laue group
# then use the best value labelit suggests during autoindex.
if (("$solutionNum" == "") || ("$laueGroup" == "")) then
set solutionNum = $bestSolNum
set laueGroup = $bestLaueGroup
endif

######################################################
# Wait until we have enough images for the each batch
######################################################

set bFirstImage = ""
foreach batch ($numBatches)

# Wait until we have enough images for the each batch
cd $imageDir
set images = (ls ${imageRootName}_*.${imageExt})
cd $processDir

if ("$bFirstImage" == "") then
set bFirstImage = $images[1]
endif
set bLastImage = $images[$#images]
echo `date`" Batch $batch first image = $bFirstImage, last image = $bLastImage"
set bFirstImageIndex = `echo $bFirstImage | awk '{num=split($1, arr1, "_"); name = arr1[num]; split(name, arr2, "."); print arr2[1];}'`
set bLastImageIndex = `echo $bLastImage | awk '{num=split($1, arr1, "_"); name = arr1[num]; split(name, arr2, "."); print arr2[1];}'`

# Make sure phi range is less than minBatchPhiRange.
set imageUrl = "$getHeaderUrl?fileName=${imageDir}/${bFirstImage}&userName=$USER&sessionId=$session"
echo "java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL $imageUrl"
java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL "$imageUrl" > image1.txt
set found = `awk 'NR==1{if (index($0, "ERROR") > 0) {print 0;} else {print 1;}}' image1.txt`
if ($found == 0) then
echo `date`" Cannot get image header for ${imageDir}/${bFirstImage}
exit
endif
set phi1 = `awk '/PHI/{print $2;}' image1.txt`

set imageUrl = "$getHeaderUrl?fileName=${imageDir}/${bFirstImage}&userName=$USER&sessionId=$session"
echo "java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL $imageUrl"
java -cp $WEBICE_CLASS_DIR webice.beans.SubmitURL "$imageUrl" > image1.txt
set found = `awk 'NR==1{if (index($0, "ERROR") > 0) {print 0;} else {print 1;}}' image1.txt`
if ($found == 0) then
echo `date`" Cannot get image header for ${imageDir}/${bLastImage}
exit
endif
set phi2 = `awk '/PHI/{print $2;}' image1.txt`

set phiDiff = `echo $ph1 $phi2 | awk '{diff = $1 - $2; if (diff < 0.0) {diff = -1.0*diff;} print diff;}'`
set enoughPhiRange = `echo $phiDiff $minBatchPhiRange | awk '{if ($1 < $2) {print 0;} else {print 1;}}'`
if ($enoughPhiRange == 0) then
echo `date`" Not enough phi range to start processing batch ${batch}."
sleep 5
continue
endif

exit

# Go to next batch
set batch = `echo $batch | awk '{print $1+1;}'`
set bNextImageIndex = `echo $bLastImageIndex | awk '{n = $1+1; if (n < 10) {print "00"n;} else if (n < 100) {print "0"n;} else {print n;}}'`
set bFirstImage = "${imageRootName}_${bNextImageIndex}.${imageExt}"

end # foreach iteration

######################################################
# Copy dcs and beamline parameters
######################################################

######################################################
# Generating mosflm processing script
######################################################
echo `date`" Generating mosflm processing script."

set solutionNum = ""
set spacegroup
set iteration = 2
set matrixFile = "index{solutionNum}.mat"

# Get best solution matrix
cp $autoindexDir/LABELIT/index${solutionNum}.mat .

echo "ipmosflm coords ${image_root_name}_${iteration}.coords summary ${imageRooName}_${iteration}.sum <<eof > ${imageRootName}_${iteration}.out" > process.mfm
echo " " >> process.mfm
echo "TITLE ${imageRootName} integration ${iteration} from images ${firstImageIndex} to ${lastImageIndex}" >> process.mfm
echo " " >> process.mfm
echo "DIRECTORY  ${imageDir}" >> process.mfm
echo "TEMPLATE ${imageRootName}_###.${imageExt}" >> process.mfm
echo "HKLOUT ${imageRootName}_${iteration}.mtz" >> process.mfm
echo " " >> process.mfm
echo "GENFILE ${imageRootName}_${iteration}.gen" >> process.mfm
echo "BEAM 157.716087 157.275759   #From autoindexing" >> process.mfm
echo " " >> process.mfm
echo "WAVE 0.979462   #From autoindexing" >> process.mfm
echo " " >> process.mfm
echo "SYNCHROTRON POLARIZATION 0.9  #From beamline properties" >> process.mfm
echo "DIVERGENCE 0.100 0.020    #From beamline properties" >> process.mfm
echo "DISPERSION 0.0001           #From beamline properties" >> process.mfm
echo "GAIN 0.250000              #From beamline properties" >> process.mfm
echo "BEAM 93.983176 93.940883  #From autoindexing" >> process.mfm
echo "DISTANCE 149.879600       #From autoindexing" >> process.mfm
echo "MOSAICITY 0.03            #From autoindexing" >> process.mfm
echo "RESOLUTION 2.020            #From autoindexing" >> process.mfm
echo "MATRIX ${matrixFile}     #From autoindexing" >> process.mfm
echo "TWOTHETA 0.0              #From autoindexing" >> process.mfm
echo "SYMMETRY ${spacegroup}" >> process.mfm
echo "PROFILE OVERLOAD PARTIALS      #From autoindexing" >> process.mfm
echo "RASTER 13 13 6 4 4              #From autoindexing" >> process.mfm
echo "SEPARATION 0.70 0.70 CLOSE       #From autoindexing" >> process.mfm
echo "REFINEMENT RESID 7.5           #From autoindexing" >> process.mfm
echo " " >> process.mfm
echo "postref fix all" >> process.mfm
echo "process ${firstImageIndex} to ${lastImageIndex}  #first and last images in this batch" >> process.mfm
echo "RUN" >> process.mfm
echo "EXIT" >> process.mfm
echo " " >> process.mfm
echo "eof" >> process.mfm
echo " " >> process.mfm

