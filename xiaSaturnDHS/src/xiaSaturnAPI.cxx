/************************************************************************
                        Copyright 2001
                              by
                 The Board of Trustees of the
               Leland Stanford Junior University
                      All rights reserved.

                       Disclaimer Notice

     The items furnished herewith were developed under the sponsorship
of the U.S. Government.  Neither the U.S., nor the U.S. D.O.E., nor the
Leland Stanford Junior University, nor their employees, makes any war-
ranty, express or implied, or assumes any liability or responsibility
for accuracy, completeness or usefulness of any information, apparatus,
product or process disclosed, or represents that its use will not in-
fringe privately-owned rights.  Mention of any product, its manufactur-
er, or suppliers shall not, nor is it intended to, imply approval, dis-
approval, or fitness for any particular use.  The U.S. and the Univer-
sity at all times retain the right to use and disseminate the furnished
items for any purpose whatsoever.                       Notice 91 02 01

   Work supported by the U.S. Department of Energy under contract
   DE-AC03-76SF00515; and the National Institutes of Health, National
   Center for Research Resources, grant 2P41RR01209.

************************************************************************/


// **************************************************
// xiaSaturn.cpp
// **************************************************

// local include files
#include <sstream>
#include <iosfwd>

#include <signal.h>

using namespace std;

#include "xos_hash.h"
#include "xiaSaturnAPI.h"
#include "xiaSaturnSystem.h"

#include "handel.h"
#include "handel_constants.h"
#include "handel_generic.h"
#include "handel_errors.h"
//#include "xia_xerxes.h"

#define MAX_XIASATURN_CHANNELS 8192
#define PEAKING_TIME 0.1

#define MAX_DCSS_RETURN_MESSAGE 1000
#define XIA_SATURN_CONTROL_CHANNEL -1
#define XIA_SATURN_CHANNEL 0

extern xiaSaturnService *g_xiaSaturnServicePtr;

xos_result_t handleMessagesXiaSaturn( xos_thread_t	*pThread );

//#include "simulate_xiaSaturn.h"

xos_result_t connectToXiaSaturn();
xos_result_t closeConnectionXiaSaturn();
xos_result_t clearMemoryXiaSaturn();
xos_result_t setElapsedTimePresetXiaSaturn( float presetTime );
xos_result_t acquireSpectrumXiaSaturn( char * operationHandle,
						long startChannel,
						long numChannels );
void sendToDcss( const char * message );

// module data
//static char mSerialNumber[30];
static xos_message_queue_t mCommandQueue;
//static unsigned long mSpectrumData[ MAX_XIASATURN_CHANNELS ];

static xos_boolean_t mAbortXiaSaturn = FALSE;

// private function declarations

// *************************************************************
// xiaSaturnInit: This is the function that is called by DHS when
// it knows that it is responsible for a xiaSaturn flourescence detector.
// This routine spawns another two threads and begins handling
// messages from DHS core.
// *************************************************************
xos_result_t xiaSaturnInit( )
	{
	xos_thread_t    xiaSaturnControlThreadHandle;

	printf("xiaSaturnInit: Enter\n");

	// thread specific data

	// create the command message queue
	if ( xos_message_queue_create( & mCommandQueue, 10, 1000 ) != XOS_SUCCESS )
	  	{
	  	xos_error("xiaSaturnInit: error creating command message queue");
	 	return XOS_FAILURE;
	 	}
	// initialize devices

	// handle internally queued messages--returns only if fatal error occurs
	if ( xos_thread_create( &xiaSaturnControlThreadHandle,
									xiaSaturnControlThread,
									NULL) != XOS_SUCCESS )
		xos_error_exit("xiaSaturnInit: error creating internal message thread");

	printf("xiaSaturnInit: Leave\n");
   return XOS_SUCCESS;
	}


//
//	xiaSaturnControlThread:
//	 interfacing to this thread is done via message queues. The control thread
// is independent of the message handler thread in order to be able to
// receive aborts during a long operation.
// ***************************************************************************

XOS_THREAD_ROUTINE xiaSaturnControlThread( void * arg )
	{
	// local variables
	char commandBuffer[1000];
	char commandToken[100];
	char dcssCommand[MAX_DCSS_RETURN_MESSAGE];
	char operationHandle[40];
	long startChannel;
	long numChannels;
	float elapsedTimePreset;

	/*signal (SIGINT, termination_handler);*/

	while ( TRUE )
		{
		// repeatedly connect to detector until successful
		while ( connectToXiaSaturn()!= XOS_SUCCESS )
			{
			xos_thread_sleep(1000);
			}

		while (TRUE)
			{
			puts("xiaSaturnControlThread: Reading next command from queue...");
			// read next command from message queue
			if ( xos_message_queue_read( &mCommandQueue, commandBuffer ) == -1 	)
				xos_error_exit("xiaSaturnControlThread: error reading from command message queue");

			puts("xiaSaturnControlThread: Got command:");
			puts(commandBuffer);

			sscanf( commandBuffer, "%*s %s %40s", commandToken, operationHandle );

			puts(commandToken);
			puts(operationHandle);
			if (strcmp (commandToken, "abort") )
				{
				mAbortXiaSaturn = FALSE;
				}

			//throw away messages until the abort is handled
			if ( mAbortXiaSaturn ) {
				printf("Throw away message waiting for abort complete.\n");
				continue;
			}

			// ******************************************************************
			// acquireSpectrum
			// ******************************************************************
			if ( strcmp( commandToken, "acquireSpectrum" ) == 0 )
				{
				sscanf(commandBuffer,"%*s %*s %20s %ld %ld %f",
						 operationHandle,
						 &startChannel,
						 &numChannels,
						 &elapsedTimePreset);

				//check to see if the XiaSaturn can handle the request
				if (numChannels > MAX_XIASATURN_CHANNELS)
					{
					sprintf( dcssCommand,
					"htos_operation_completed acquireSpectrum %s requestedTooManyChannels ",
								operationHandle );
					sendToDcss( dcssCommand );
					continue;
					}

				//clear the acquisition memory
				if ( clearMemoryXiaSaturn() != XOS_SUCCESS )
					{
					sprintf( dcssCommand,
								"htos_operation_completed acquireSpectrum %s failedToClearMemory ",
								operationHandle );
					sendToDcss( dcssCommand );
					//drop out of loop and try to restablish connection
					break;
					}
			printf("Elapsed time prest set to %f.\n",elapsedTimePreset);

				//set the live time preset
				if ( setElapsedTimePresetXiaSaturn(elapsedTimePreset ) != XOS_SUCCESS )
					{
					sprintf( dcssCommand,
								"htos_operation_completed acquireSpectrum %s failedToSetPreset ",
								operationHandle );
					sendToDcss( dcssCommand );
					//drop out of loop and try to restablish connection
					break;
					}

				//start aquiring the data
				if ( acquireSpectrumXiaSaturn ( operationHandle,
														startChannel,
														numChannels ) != XOS_SUCCESS )
					{
					sprintf( dcssCommand,
								"htos_operation_completed acquireSpectrum %s failedAcquireSpectrum ",
								operationHandle );
					sendToDcss( dcssCommand );
					}

				continue;
				}
			}
		// close connection to DS2000;
		closeConnectionXiaSaturn();
		}
	// code should never reach here
	XOS_THREAD_ROUTINE_RETURN;
	}


// Initialize the connection to the XiaSaturn
xos_result_t connectToXiaSaturn ()
	{
	int status;

	printf ("connectToXiaSaturn: Enter.\n");

	// Establish a connection to the Saturn using the default ini file
	// Put in the (char *) to avoid compiler warnings. Correct fix would be to
	// change the library function, but given that is an external library, I
	// don't want to do that.
	status = xiaInit("saturn.ini");
	if (status != XIA_SUCCESS)
		{
		printf ("connectToXiaSaturn: Error connecting to the Saturn\n");
		return XOS_FAILURE;
		}

	// Start the Saturn
	status = xiaStartSystem();
	if (status != XIA_SUCCESS)
		{
		printf ("connectToXiaSaturn: Error starting the Saturn system\n");
		return XOS_FAILURE;
		}

	// set the MCA bin size
	double dmcaBinWidth = 8.0;
	double dmcaBinWidthReadback;
	status = xiaSetAcquisitionValues(XIA_SATURN_CONTROL_CHANNEL, "mca_bin_width", &dmcaBinWidth);

	if (status != XIA_SUCCESS) {
		printf("connectToXiaSaturn: Failed to set MCA bin width.\n");
		return XOS_FAILURE;
	}

	status = xiaGetAcquisitionValues(XIA_SATURN_CHANNEL, "mca_bin_width", &dmcaBinWidthReadback);
	printf("connectToXiaSaturn: MCA bin width readback = %lf\n", dmcaBinWidthReadback);
	if (status != XIA_SUCCESS) {
                printf("connectToXiaSaturn: Failed to set MCA width.\n");
                return XOS_FAILURE;
        }

	printf ("connectToXiaSaturn: Leave.\n");
	return XOS_SUCCESS;
	}


// Break connection to the Saturn - this is a NOOP for the Saturn
xos_result_t closeConnectionXiaSaturn ()
	{
	printf ("closeConnectionXiaSaturn: Enter.\n");

	xiaExit();
	printf ("closeConnectionXiaSaturn: Leave.\n");
	return XOS_SUCCESS;
	}


// Clear the acquisition memory - for the Saturn, this is a NOOP. 
// We will start each acquisition with the command to clear the memory.
xos_result_t clearMemoryXiaSaturn ()
	{
	printf ("clearMemoryXiaSaturn: Clear the acquisition memory.\n");
	return XOS_SUCCESS;
	}




// Set the elapsed time preset on the XiaSaturn
xos_result_t setElapsedTimePresetXiaSaturn (float presetTime )
{
	int status;
	double dpresetTime = (double) presetTime;
	double dpresetTimeReadback;
	double dpeakingTime = (double) PEAKING_TIME;
	double peakingTimeReadback;
	double presetType = XIA_PRESET_FIXED_REAL;

	//check to see if the request preset time is reasonable
	if ( dpresetTime < 0.000001 )
		{
		printf("setElapsedTimePresetXiaSaturn: Elapsed time preset too small %lf.\n",dpresetTime);
		return XOS_FAILURE;
		}

	// Set acquisition preset to the requested realtime (in seconds).
	printf ("setElapsedTimePresetXiaSaturn: Set the acquisition preset to %lf.\n", dpresetTime);

	status = xiaSetAcquisitionValues(XIA_SATURN_CONTROL_CHANNEL, "preset_type", &presetType);
        if (status != XIA_SUCCESS) {
                printf("setElapsedTimePresetXiaSaturn: Failed to set preset_type.\n");
                return XOS_FAILURE;
        }

	status = xiaSetAcquisitionValues(XIA_SATURN_CONTROL_CHANNEL, "preset_value", &dpresetTime);
	if (status != XIA_SUCCESS) {
		printf("setElapsedTimePresetXiaSaturn: Failed to set elapsed time preset.\n");
		return XOS_FAILURE;
	}

	status = xiaGetAcquisitionValues(XIA_SATURN_CHANNEL, "preset_value", &dpresetTimeReadback);
	printf("setElapsedTimePresetXiaSaturn: Readback of preset time = %lf\n", dpresetTimeReadback);

	status = xiaSetAcquisitionValues(XIA_SATURN_CONTROL_CHANNEL, "peaking_time", &dpeakingTime);

	if (status != XIA_SUCCESS) {
		printf("setElapsedTimePresetXiaSaturn: Failed to set peaking time\n");
		return XOS_FAILURE;
	}

	status = xiaGetAcquisitionValues(XIA_SATURN_CHANNEL, "peaking_time", &peakingTimeReadback);
	printf("setElapsedTimePresetXiaSaturn: Readback of peaking time = %lf\n", peakingTimeReadback);

	return XOS_SUCCESS;
}



// acquire spectrum
xos_result_t acquireSpectrumXiaSaturn ( char * operationHandle,
									 long startChannel,
									 long numChannels )
	{
	char dcssCommand[200];
	ostringstream dcssLongResponse;

	int status;
	unsigned long run_active;

	double	liveTime;
	double  elapsedTime;
	unsigned long mcaLength = 0;
	double dnumMCAChannels = (double) numChannels;
	double dnumMCAChannelsReadback;
	int	n_channels_done;

	// Start the acquisition.
	printf ("acquireSpectrumXiaSaturn: Start the acquisition.\n");
	printf ("acquireSpectrumXiaSaturn: Number of requested channels = %ld\n", numChannels);
	printf ("acquireSpectrumXiaSaturn: Start channel = %ld\n", startChannel);


//  original code
	status = xiaSetAcquisitionValues(XIA_SATURN_CONTROL_CHANNEL, "number_mca_channels", &dnumMCAChannels);
	if ( status != XIA_SUCCESS )
		{
		printf ("acquireSpectrumXiaSaturn: failed to set number of MCA channels\n");
		return XOS_FAILURE;
		}

	status = xiaGetAcquisitionValues(XIA_SATURN_CHANNEL, "number_mca_channels", &dnumMCAChannelsReadback);
	if ( status != XIA_SUCCESS )
		{
		printf ("acquireSpectrumXiaSaturn: failed to read back number of MCA channels\n");
		return XOS_FAILURE;
		}

	printf ("acquireSpectrumXiaSaturn: MCA channel readback = %lf\n", dnumMCAChannelsReadback);
//
	status = xiaStartRun(XIA_SATURN_CONTROL_CHANNEL, 0);

	if ( status != XIA_SUCCESS )
		{
		printf ("acquireSpectrumXiaSaturn: failed to start acquisition");
		return XOS_FAILURE;
		}
	else {
		printf ("acquireSpectrumXiaSaturn: started acquisition");
	}


	//let DCSS know that the detector is ready
	sprintf( dcssCommand,
				"htos_operation_update acquireSpectrum %s readyToAcquire ",
				operationHandle );
	sendToDcss( dcssCommand );
/*
	do {
		int i;
		n_channels_done = 0;
		for (i=0; i<numChannels; i++){
			printf("yangx before xiaGetRunData i=%d numChannels=%d \n",i,numChannels);
			status = xiaGetRunData(i, "run_active", &run_active);
			printf("yangx after xiaGetRunData run_active = %d\n", run_active);
			if((run_active & 0x1) ==0)
				n_channels_done++;
		}
		sleep(1);

	} while (n_channels_done != numChannels);
*/

	// Wait for acquisition to complete.
	while (1)
		{
		// Sleep for 50 ms
		xos_thread_sleep (50);
		status = xiaGetRunData(XIA_SATURN_CHANNEL, "run_active", &run_active);
		//printf("****after xiaGetRunData ********** run_active=%d XIA_RUN_HARDWARE=%d\n", run_active ,XIA_RUN_HARDWARE);

		//check to see if the detector is still busy
		if (!(run_active & XIA_RUN_HARDWARE))		
			break;

		//check to see if the operation has been aborted
		if ( mAbortXiaSaturn )
			{
			// Stop the acquisition.
			printf ("acquireSpectrumXiaSaturn: aborting acquisition.");
			status = xiaStopRun(XIA_SATURN_CONTROL_CHANNEL);
			if (status != XIA_SUCCESS)
				{
				printf ("acquireSpectrumXiaSaturn: failed to stop acquisition.");
				return XOS_FAILURE;
				}
			break;
			}
		}
	
	// if we get to here, the acquisition should have finished. stop the run gracefully
	// to tell the Handel library that the acquisition has finished.
	status = xiaStopRun(XIA_SATURN_CONTROL_CHANNEL);
	if (status != XIA_SUCCESS)
	{
		printf ("acquireSpectrumXiaSaturn: failed to stop acquisition.");
		return XOS_FAILURE;
	}

	//get the live time
	status = xiaGetRunData(XIA_SATURN_CHANNEL, "livetime", &liveTime);

	if ( status != XIA_SUCCESS )
		{
			printf ("acquireSpectrumXiaSaturn: error reading livetime.\n");
			return XOS_FAILURE;
		}

	printf ("acquireSpectrumXiaSaturn: Livetime seconds: %.3f\n", liveTime);

	//get the real elapsed time
	status = xiaGetRunData(XIA_SATURN_CHANNEL, "runtime", &elapsedTime);

	if ( status != XIA_SUCCESS )
		{
			printf ("acquireSpectrumXiaSaturn: error reading elapsed real time.\n");
			return XOS_FAILURE;
		}

	printf ("acquireSpectrumXiaSaturn: Real elapsed time seconds: %.3f\n", elapsedTime);

	// Read the spectrum length
	status = xiaGetRunData(XIA_SATURN_CHANNEL, "mca_length", (void *)&mcaLength);

	if ( status != XIA_SUCCESS )
		{
		printf ("acquireSpectrumXiaSaturn: Error reading spectrum length.");
		return XOS_FAILURE;
		}

	printf ("acquireSpectrumXiaSaturn: Spectrum length: %lu\n", mcaLength);

	// Read the spectrum
	unsigned long spectrumData[mcaLength];

	printf ("acquireSpectrumXiaSaturn: Read the spectrum.\n");
	status = xiaGetRunData(XIA_SATURN_CHANNEL, "mca", spectrumData);

	if ( status != XIA_SUCCESS )
		{
		printf ("acquireSpectrumXiaSaturn: Error reading spectrum.");
		return XOS_FAILURE;
		}

	if ( elapsedTime < 0.0000001 )
		{
		elapsedTime = 0.0000001;
		}

	//start making response
	dcssLongResponse	<< "htos_operation_completed acquireSpectrum "
							<< string (operationHandle )
							<< " normal " << (float)(elapsedTime - liveTime)/(float)elapsedTime;


	printf("%s\n",dcssLongResponse.str().c_str() );

	// check that we have enough data from the MCA to meet the request. If not,
	// just send what we do have
	//if (startChannel + numChannels > (signed long)mcaLength)
		//numChannels = mcaLength - startChannel;

	//build up the text string containing the spectrum results
	for ( int channel = 0; channel < numChannels; channel++ )
		{
		dcssLongResponse << " " << spectrumData[channel];
		}

	//send the long message back to DCSS
	sendToDcss( dcssLongResponse.str().c_str() );

	return XOS_SUCCESS;
	}


//set a global flag and stop the other thread from acquiring the spectrum
int xiaSaturn_stop() {
   mAbortXiaSaturn = TRUE;
	if ( xos_message_queue_write( & mCommandQueue,
											"xxxxx abort" ) != XOS_SUCCESS )
	xos_error_exit("handleMessagesXiaSaturn: error writing abort to command queue");
	return 1;
}

//
int xiaSaturn_start(const char* operationPtr ) {

	if ( xos_message_queue_write( & mCommandQueue,
											operationPtr ) != XOS_SUCCESS )
	xos_error_exit("handleMessagesXiaSaturn: error writing to command queue");
	return 1;
}



void sendToDcss( const char * message )
{
   printf("sendToDCSS: %s\n", message);
   DcsMessageManager& msgManager=DcsMessageManager::GetObject();
   DcsMessage* reply = msgManager.NewDcsTextMessage( message );

   // The reply message will be deleted in SendoutDcsMessage()
	// if no other handlers want to process it.
   g_xiaSaturnServicePtr->SendoutDcsMessage(reply);
}



