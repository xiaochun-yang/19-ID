#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <unistd.h>

#include "handel.h"
#include "handel_constants.h"
#include "handel_generic.h"
#include "handel_errors.h"

main(){

// set the MCA bin size
double  dmcaBinWidth = 10.0;
double  dmcaBinWidthReadback;
double  dnumMCAChannels;
double  dnumMCAChannelsReadback;

int 	 i, n_channels_done, status;
int	 numChannels = 2048;
unsigned long run_active;
double	 presetType = XIA_PRESET_FIXED_REAL;
double 	 presetRealtime = 1.0;
double   realtime = 0.0;
double   dpeakingTime=1;
unsigned long mcaLength=0;
int	 ignored = 0;

	dnumMCAChannels = numChannels;

// the following are the sequence of get data from mercury
	//Connect to xiaSaturn (still use the word saturn, but actually it's mercury)
	printf("press Enter to initialize Mercury");
	getchar();

	// Initialize Handel
	status = xiaInit("saturn.ini");
	if (status != XIA_SUCCESS)
                {
                printf ("connectToXiaSaturn: Error connecting to the Saturn\n");
                exit(1);
       }
	
	// Starting the system
	status = xiaStartSystem();
	if (status != XIA_SUCCESS)
                {
                printf ("connectToXiaSaturn: Error starting the Saturn system\n");
                exit(1);
                }
	//set up mca
	status = xiaSetAcquisitionValues(-1, "mca_bin_width", &dmcaBinWidth);
	 if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set MCA bin width.\n");
                exit(1);
        }

        status = xiaGetAcquisitionValues(0,"mca_bin_width", &dmcaBinWidthReadback);
        if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to get MCA width.\n");
                exit(1);
        }

	status = xiaSetAcquisitionValues(-1, "number_mca_channels", &dnumMCAChannels);
         if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set MCA number.\n");
                exit(1);
        }

        status = xiaGetAcquisitionValues(0,"number_mca_channels", &dnumMCAChannels);
        if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to get MCA number.\n");
                exit(1);
        }

	status = xiaSetAcquisitionValues(-1, "preset_type", &presetType);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set preset_type.\n");
                exit(1);
        }

	status = xiaSetAcquisitionValues(-1, "preset_value", &presetRealtime);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set presetRealtime.\n");
                exit(1);
        }

/*	//Apply new acquisition value. this function is only for single channel
	status = xiaBoardOperation(-1, "apply", &ignored);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set apply.\n");
                exit(1);
        }
*/
	status = xiaSetAcquisitionValues(-1, "peaking_time", &dpeakingTime);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set peaking time.\n");
                exit(1);
        }


	//start data acqusition
	printf("press Enter to start the data acquisition");
	getchar();
	status = xiaStartRun(-1, 0);
	if (status != XIA_SUCCESS)
        {
                printf ("connectToXiaSaturn: Error connecting to the Mercury\n");
                exit(1);
         }
	else {
                printf ("acquireSpectrumXiaSaturn: started acquisition");
        }
       
        // Wait for acquisition to complete.
        while (1) {
                // Sleep for 500 ms
		sleep(0.5);
                status = xiaGetRunData(0, "run_active", &run_active);
                //printf("run_active=%d \n", run_active);

                //check to see if the detector is still busy
                if (!(run_active & 0x1))
                        break;
		sleep(1);
        }

	// Get the data
	 status = xiaStopRun(0);
	 if (status != XIA_SUCCESS)
        {
                printf ("acquireSpectrumXiaSaturn: failed to stop acquisition.");
                exit(1);
        }

	status = xiaGetRunData(0, "realtime", &realtime);
	if (status != XIA_SUCCESS)
        {
                printf ("acquireSpectrumXiaSaturn: error to reading elapsed real time.");
                exit(1);
        }


	// Read the spectrum length
        status = xiaGetRunData(0, "mca_length", (void *)&mcaLength);
	if ( status != XIA_SUCCESS )
        {
		printf ("acquireSpectrumXiaSaturn: Error reading spectrum length.");
                exit(1);
         }

	printf("the mcaLength = %ld \n", mcaLength);

	unsigned long spectrumData[mcaLength];
        printf ("acquireSpectrumXiaSaturn: Read the spectrum.\n");
        status = xiaGetRunData(0, "mca", spectrumData);
	if ( status != XIA_SUCCESS )
        {
                printf ("acquireSpectrumXiaSaturn: Error reading spectrum.");
                exit(1);
        }

	for(i=0; i<mcaLength;i++)
		printf("%ld ",spectrumData[i]);
	xiaExit();
}
