#!/bin/csh -fv

set image_dir = /data/ana/TEST-WEBICE/TM1083    #image directory
set space_group = P23         # from autoindexing or labelit.symmetry      
set runname = test-TM1083
set image_root_name = tm1083_1	 # rootname
set iteration = 2              # how many times have we integrated with mosflm, extracted from name1
set im1 = 11                   #First image in the batch
set imn = 21                  #Last image collected. It has to be at least 10 degrees away from im1

# Set environment variables

source /home/webserverroot/servlets/tomcat-smbws1/webice/WEB-INF/scripts/setup_env.csh

mkdir /data/ana/webice/process/$runname
cd /data/ana/webice/process/$runname
cp /data/ana/webice/autoindex/test-TM1083/LABELIT/index22.mat .

ipmosflm coords ${image_root_name}_${iteration}.coords summary ${image_root_name}_${iteration}.sum <<eof > ${image_root_name}_${iteration}.out

TITLE ${image_root_name} integration ${iteration} from images ${im1} to ${imn}
# Image directory
DIRECTORY  ${image_dir}
TEMPLATE ${image_root_name}_###.img 
HKLOUT ${image_root_name}_${iteration}.mtz

GENFILE ${image_root_name}_${iteration}.gen
BEAM 157.716087 157.275759   #From autoindexing

WAVE 0.979462   #From autoindexing
#beam
SYNCHROTRON POLARIZATION 0.9  #From beamline properties
DIVERGENCE 0.100 0.020    #From beamline properties
DISPERSION 0.0001           #From beamline properties
GAIN 0.250000              #From beamline properties
BEAM 93.983176 93.940883  #From autoindexing
DISTANCE 149.879600       #From autoindexing
MOSAICITY 0.03            #From autoindexing
RESOLUTION 2.020            #From autoindexing
MATRIX index22.mat     #From autoindexing
TWOTHETA 0.0              #From autoindexing
SYMMETRY ${space_group}  
PROFILE OVERLOAD PARTIALS      #From autoindexing
RASTER 13 13 6 4 4              #From autoindexing
SEPARATION 0.70 0.70 CLOSE       #From autoindexing
REFINEMENT RESID 7.5           #From autoindexing

postref fix all
process ${im1} to ${imn}  #first and last images in this batch
RUN
EXIT

eof
