#!/bin/csh -fxv

###################################################################################################################################################################################################################
##get data collection information from dcs dump - so far all we want to know is if the run of interest is active
#Exit status 0: data collection is active; 1: Data collection is finished 
###################################################################################################################################################################################################################

set workDir = `pwd`

echo $workDir

set runName = `awk '/runName/{print substr($0, 9);}' process.properties`
set dcsDumpFile = `awk '/dcsDumpFile=/{print substr($0, 13);}' process.properties`
set beamlineFile = `awk '/beamlineFile=/{print substr($0, 14);}' process.properties`
set beamline = `awk '/beamline=/{print substr($0, 10);}' process.properties`
set imageDir = `awk '/^imageDir=/{print substr($0, 10);}' process.properties`
set imageRootName = `awk '/imageRootName=/{print substr($0, 15);}' process.properties`

cat process.properties

#copy the DCS log to the working directory

$WEBICE_SCRIPT_DIR/copyDcsDump.csh $dcsDumpFile $beamline 

if ( -e PARAMETERS/${beamline}.dump ) then

	awk -f $WEBICE_SCRIPT_DIR/generate_dcs_params.awk "PARAMETERS/${beamline}.dump" > PARAMETERS/dcs_params.txt

else 
	echo `date +"%T"` " Could not access the beamline dump file for 10 tries"
	exit 1

endif 

#parse dcs_params.txt to find the active run parameters 
set run_info = `awk -f $WEBICE_SCRIPT_DIR/get_run_info.awk PARAMETERS/dcs_params.txt`

if ($run_info[1] == "collecting") then

    exit 0

else

    exit 1

endif

#######################################################################################






#We have the first image. Now we need the last image

set listImageCollected = `ls -t ${imageDir}/${imageRootName}_${runLabel}*`
set lastImageCollected = `echo ${listImageCollected[1]}:t:r | sed "s/[a-z]//g" | sed "s/[0-9_]_0*//g" `
#To do : last image for MAD and SAD...

echo "Last image collected is "$lastImageCollected "; last image processed is "$lastprocessed

if ($lastImageCollected == $lastprocessed ) then
   if ($run_info[1] == "collecting") then
	sleep 60
	# We need to wait for more images (maybe SPEAR is down)
	exit 0
   else
        #We are done...

	echo "All images collected and processed"
	exit 2
   endif


else
    #Update process.properties

    cat process.properties | awk -v last=$lastImageCollected '{sub (/lastimage=[0-9]*/ , "lastimage="last ) ; print }' > process.properties 

    #If the experiment is MAD, lastimage refers to E1; we need to extract lastimageE2, E3, etc
    #they can all be knows from the number of energies, last image collected (has it E1, E2, etc. in the name)
    # and the wedge size; eg if last image is test_1_E2_017.image and the wedge size is 10 images and nEnergy=3
    # lastimage = 20; lastimageE2 = 17; lastimageE3 = 10;
    #If the experiment is SAD, lastimage is the last image in the direct pass
    #firstimageInv is determined from the number of images (what is the rule in DCSS?); lastimageInv is determined by the wedge size;
    # eg if the last image is test_1_377 and firstimageInv is 361, wedge is 10 images, then  lastimage = 20; lastimageInv = 377


exit 0
	
endif


