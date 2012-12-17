simdetector is a simulated detector dhs that writes a diffraction 
image to a designated directory upon receiving a 
detector_collect_image operation. It loads a diffraction image from 
a source directory and writes it to an output directory (via the 
impersonation server) with the appropriate filename received 
in the operation arguments. The source directory is specified in 
the beamline config file, e.g. /usr/local/dcs/dcsconfig/data/BL-sim.config.
The output directory is specified in the directory text box in the
screening tab in bluice.

Configurations
==============


You need to configure simdetector by adding or editing the following 
config in <dcs root>/dcsconfig/data/<beamline>.config file. 


simdetector.name=simdetector
simdetector.type=Q315CCD
simdetector.imageDir=/data/blctl/default_imagedata
simdetector.imageFilter=infl_1_*

The name config is an instance name of simdetector, which must 
correspond to the device name defined in 
<dcs root>/dcsconfig/data/<beamline>.dat file, for example:


simdetector
3
smbdev1.slac.stanford.edu 2


imageDir is the default directory from which the images are loaded. 
simdetector loads an image from this location when there is a request 
for an image. 

type is a detector type: Q315CCD, MAR325, MAR165, MAR345, Q4CCD.
simdetector uses the detector type to determine which file extension 
to append to the requested filename. File extension for MAR325 is mccd
and it is img for all other detector types. The detector type 
set in the config must match the detectorType parameter set in the 
dcss database.

imageFilter filters image file names to be loaded from imageDir. 
In the above example, if the image directory contains a series of 
image files from infl_1_001.img to inf_1_120.img, the dhs will load 
an image in this series where the image index is incremented by 1 
for every detector_collect_image operation and is reset to 1 after 
it reaches max index, in this example 20.

In addition to the imageDir directory, simdetector has a list 
other image directories from which to load images. The list is 
created from cassette_dirs.txt file in the current directory. 
For example, the file may contain the following lines:

/data/blctl/cassettedata/cassette130
/data/blctl/cassettedata/cassette131
/data/blctl/cassettedata/cassette132


If the requested file name matches one of the directories in the list,
images in that directory will be used. Otherwise the images from 
the default imageDir will be used. 

For example, if the requested image path is /data/joeuser/cassette130/TM0559/1478/1478_001.img

simdetector will try to find source image in 
/data/blctl/cassettedata/cassette130/1478/1478_001.img

If found, it will be copied to the requested path.

If this file does not exist, simdetector will copy a file from
imageDir to the requested path.

Note that the file extension is determined by simdetector.type 
parameter.

Also note that the source images must be readble by the simdetector
process but the requested image path only need to be writable by 
the user who makes the request.


Running it
==========

simdetctor takes one commandline argument, which is a beamline name.
Like other dhs, simdetector must be able to locate a beamline
configuration file in ../../dcsconfig/data directory. The beamline
config file name must be the same as the beamline name with file 
extension ".config", for example, ../../dcsconfig/data/BL-sim.config.

Type the following commands to run the dhs.


>cd /usr/local/dcs/simdetector/linux
>./simdetector BL-sim


Operations
==========


1. Receive detector_collect_image operation.

detector_collect_image <operationId> <runIndex> <filename> <directory> <userName> <axisName> <exposureTime> <oscStart> <oscRange> <distance> <wavelength> <detectorX> <detectorY> <detectorMode> <useDark> <sessionId>


where the operation parameters as follows:
operationId	Unique operation ID
runIndex	Not used
filename	Output image fille name
directory	Output image directory
username	Not used
axisName	Not used
exposureTime	Exposure time
oscStart	Not used
oscRange	Not used
distance	Not used
wavelength	Not used
detectorX	Not used
detectorY	Not used
detectorMode	Not used
useDark	Not used
sessionId	SMB session id used to copy image files to the user's directory (via the impersonation server).

For example,
detector_collect_image 4.55 15 test14_29_40  /data/joeuser  joeuser NULL 1.00 255.000000 1.00 300.000000 0.979764295303 0.000000 0.000000 0 0 1400BC92B6FF7DDEC55C2E8113AAE7E6 

Note that the resulting output image is /data/joeuser/test14_29_40.img.

2. Send operation_update for the operation received in step 1.

operation_update <operationId> start_oscillation shutter <exposureTime/2.0>

For example,

operation_update 4.55 start_oscillation shutter 0.5

3. Receive

detector_transfer_image <operationId>

For example,

detector_transfer_image 4.56

If this step has been repeated NN times (in this case, 4 times),
send 

operation_completed 4.56 normal 

and then jump to step 8.


4. Send operation_complted for the operation recieved in step 3
   and operation_update that received in step 1. Notice the differences
   in operation IDs.

operation_completed <operationId>
operation_update prepare_for_oscillation <operationId> <oscStart>

For example,

operation_completed 4.56 normal
operation_update prepare_for_oscillation 4.55 shutter 0.5 255.0

5. Receive detector_oscillation_ready operation.

detector_oscillation_ready <operationId>

For example,

detector_oscillation_ready 4.57

6. Send operation_completed for the operation received in step 5
   and send operation_update for that received in step 1.

operation_completed 4.57 normal
operation_update 4.55 start_oscillation shutter 0.5

7. Go back to step 3 until step 3 has been done 4 times.

8. Send operation_completed for the operation received in step 1
   and send set_string_completed to report the last image this 
   simdetector has written.

operation_completed 4.55 normal
set_string_completed lastImageCollected /data/joeuser/test14_29_40.img



Errors During detector_collect_image Operation
==============================================

When encountering an error, the detector sends 

operation_completed <operationId> error <reasons>

For example, 

operation_completed 4.55 error Directory not found


FAQ
===
-------------------

I got an error 
"error Failed to copy image file from XXX to YYY"
when I try to re-screen the same crystal. 

In general the source directory only contain 
2 image files, such as XXX_001.img and XXX_002.img.
When you re-screen a crystal without dismounting
and remounting the crystal, the dcss will increment
the image index by 1 each time an image is collected,
e.g. XXX_003.img. The error is likely caused by the 
fact that the source directory does not contain XXX_003.img.

If you really want to rescreen the crystal Here is what 
you need to do:
1) Dismount the crystal, for example, from A1.
2) Remove all files in directory for A1, which is <roor dir>/<directory column for A1>
3) Screen another crystal, for example A2.
4) Screen A1.

------------------- 
 


