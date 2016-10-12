#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "handel.h"
#include "handel_constants.h"
#include "handel_generic.h"
#include "handel_errors.h"

main(){

// set the MCA bin size
double  dmcaBinWidth = 8.0;
double  dmcaBinWidthReadback;
int 	i, n_channels_done, status;
int	numChannels = 1024;
unsigned long run_active;
double	 presetType = XIA_PRESET_FIXED_REAL;
double 	 presetRealtime = 5.0;
double   realtime = 0.0;
int	 ignored = 0;

// the following are the sequence of get data from mercury
//1) Connect to xiaSaturn (still use the word saturn, but actually it's mercury)
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
/*
	status = xiaSetAcquisitionValues(-1, "mca_bin_width", &dmcaBinWidth);
	 if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set MCA bin width.\n");
                exit(1);
        }

	status = xiaGetAcquisitionValues(0,"mca_bin_width", &dmcaBinWidthReadback);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set MCA width.\n");
                exit(1);
	}
*/
// 2) Prepare for data acquisition
	status = xiaSetAcquisitionValues(-1, "preset_type", &presetType);
	status = xiaSetAcquisitionValues(-1, "preset_value", &presetRealtime);
//	status = xiaSetAcquisitionValues(-1, "apply", &ignored);

//	status = xiaGetAcquisitionValues(0, "preset_value", &dpresetTimeReadback);
//	status = xiaSetAcquisitionValues(-1, "peaking_time", &dpeakingTime);
//	status = xiaSetAcquisitionValues(-1, "number_mca_channels", &dnumMCAChannels);
//	status = xiaGetAcquisitionValues(0, "number_mca_channels", &dnumMCAChannelsReadback);

// 3) start data acqusition
	printf("press Enter to start the data acquisition");
	getchar();

//	status = xiaStartRun(-1, 0);
	status = xiaStartRun(0, 0);
	if (status != XIA_SUCCESS)
        {
                printf ("connectToXiaSaturn: Error connecting to the Mercury\n");
                exit(1);
         }
	else {
                printf ("acquireSpectrumXiaSaturn: started acquisition");
        }
        do {
              	n_channels_done = 0;
         	for (i=0; i<numChannels; i++){
                printf("before xiaGetRunData i=%d numChannels=%d \n",i,numChannels);
                status = xiaGetRunData(i, "run_active", &run_active);
                printf("after xiaGetRunData run_active = %d\n", run_active);
                if((run_active & 0x1) ==0)
                     n_channels_done++;
		     printf("n_channels_done = %d \n", n_channels_done);
                }
                sleep(1);
        } while (n_channels_done != numChannels);
        
// 4) Get the data
	 status = xiaStopRun(-1);

// Exit xia
	xiaExit();
}
