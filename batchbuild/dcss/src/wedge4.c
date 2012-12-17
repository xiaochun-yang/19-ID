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

#include "xos.h"
#include "dcss_collect.h"
#include "wedge.h"
#include "log_quick.h"


#define MAX_NUM_ENERGY 5

/*module data*/

/* definition of MAD run */
static double	mDelta[MAX_RUN_ARRAY_SIZE];
static double	mWedgeSize[MAX_RUN_ARRAY_SIZE];
static double	mRunStartAngle[MAX_RUN_ARRAY_SIZE];
static double	mRunEndAngle[MAX_RUN_ARRAY_SIZE];
static int		mRunStartFrame[MAX_RUN_ARRAY_SIZE];
static int		mNumEnergies[MAX_RUN_ARRAY_SIZE];
static int		mInverseOn[MAX_RUN_ARRAY_SIZE];
static double	mEnergy[MAX_RUN_ARRAY_SIZE][MAX_NUM_ENERGY];
static int		mMaxFrame[MAX_RUN_ARRAY_SIZE];
static int 		mFramesPerWedge[MAX_RUN_ARRAY_SIZE];
static int		mInverseStartFrame[MAX_RUN_ARRAY_SIZE];

static int		mLastFrameIndex[MAX_RUN_ARRAY_SIZE];

static int 		mCurrentWedgeIndex[MAX_RUN_ARRAY_SIZE];
static int 	 	mCurrentInverseIndex[MAX_RUN_ARRAY_SIZE];
static int		mCurrentEnergyIndex[MAX_RUN_ARRAY_SIZE];
static int		mMaxAbsoluteFrame[MAX_RUN_ARRAY_SIZE];

char				mUnique[MAX_RUN_ARRAY_SIZE][MAX_NUM_ENERGY][20];

char				mFileRoot[MAX_RUN_ARRAY_SIZE][40];
int				mRunLabel[MAX_RUN_ARRAY_SIZE];

xos_result_t wedge_set_mad_definition( int 					runIndex, 
													double				delta,
													double				wedgeSize,
													double				runStartAngle,
													double				runEndAngle,
													int					runStartFrame,
													xos_boolean_t 		inverseOn,
													int					numEnergies,
													double				*energy )
	{
	int x;
	float framesPer180;
	float framesPer360;
	int inverseJumpFrameIndex;

	mDelta[runIndex] = delta;
	mWedgeSize[runIndex] = wedgeSize;
	mRunStartAngle[runIndex] = runStartAngle;
	mRunStartFrame[runIndex] = runStartFrame;
	mRunEndAngle[runIndex] = runEndAngle;
	mNumEnergies[runIndex] = numEnergies;
	mInverseOn[runIndex] = inverseOn;


	for ( x = 0; x < mNumEnergies[runIndex]; x++, energy ++)
		{
		mEnergy[runIndex][ x ] = *energy;
		}
	
	if ( mDelta[runIndex] == 0.0 )
		{
		LOG_WARNING("wedge_set_mad_definition: delta is zero\n");
		mMaxFrame[runIndex]= 0;
		mMaxAbsoluteFrame[runIndex] = 0;
		return XOS_FAILURE;
		}

	/*Calculate some fixed numbers*/
	mMaxFrame[runIndex] = (int) ((mRunEndAngle[runIndex]+ 0.0001 - mRunStartAngle[runIndex]) / mDelta[runIndex]);

	/*calculate total number of steps in run sequence for all energes and inverse wedge*/
	mMaxAbsoluteFrame[runIndex] = mMaxFrame[runIndex] * mNumEnergies[runIndex];
	if (mInverseOn[runIndex] == TRUE)
		{
		/*double for inverse beam*/
		mMaxAbsoluteFrame[runIndex] *= 2;
		}

	mFramesPerWedge[runIndex] = mWedgeSize[runIndex] / mDelta[runIndex];
	if (mFramesPerWedge[runIndex] == 0)
		{
		LOG_INFO("WARNING: delta > wedgesize\n");
		mFramesPerWedge[runIndex] = 1;
		}

 
	framesPer180 = 180.0 / mDelta[runIndex];
	framesPer360 = framesPer180 *2 ;
	inverseJumpFrameIndex = (int)( ( (float)mMaxFrame[runIndex] + framesPer180 -1 ) / framesPer360 ) + 1;
	mInverseStartFrame[runIndex] = inverseJumpFrameIndex * framesPer360  - framesPer180 ;

	mCurrentWedgeIndex[runIndex] = 1;
	mCurrentInverseIndex[runIndex] = 0;
	mCurrentEnergyIndex[runIndex] = 0;
	mLastFrameIndex[runIndex] = 1;

	/*LOG_INFO3("SET_RUN_DEFINITION:delta %f, wedge %f, startangle %f ",
			 mDelta[runIndex],
			 mWedgeSize[runIndex],
			 mRunStartAngle[runIndex])
			 
		LOG_INFO3("endangle%f , numEnergies %d, inverseOn %d \n",
			 mRunEndAngle[runIndex],
			 mNumEnergies[runIndex],
			 mInverseOn[runIndex] );

		for (x =0; x < mNumEnergies[runIndex]; x++)
				{
				LOG_INFO2("energy %d: %f  ",x ,mEnergy[runIndex][x]);
				}
				LOG_INFO("\n"); */

	return XOS_SUCCESS;
	}


xos_result_t wedge_get_next_frame( int runIndex )
	{

	int	nextWedgeIndex;
	int	nextInverseIndex;
	int	nextEnergyIndex;

	int	wedgeIndex;
	int	inverseRange;

	xos_boolean_t doNextEnergy = FALSE;
	xos_boolean_t minusWedgeIndex = TRUE;
	xos_boolean_t lastFrameInWedge = FALSE;

	nextWedgeIndex = mCurrentWedgeIndex[runIndex] + 1;
	nextEnergyIndex = mCurrentEnergyIndex[runIndex];
	nextInverseIndex = mCurrentInverseIndex[runIndex];

	/*if index is too high*/
	if ( mCurrentWedgeIndex[runIndex] > mMaxFrame[runIndex])
		return XOS_FAILURE;

	if ( mCurrentWedgeIndex[runIndex]%mFramesPerWedge[runIndex] == 0 )
		lastFrameInWedge = TRUE;
	
	if ((lastFrameInWedge == TRUE ) ||
		 ( ( mCurrentWedgeIndex[runIndex] == mMaxFrame[runIndex] ) ) )
		{
		minusWedgeIndex = TRUE;
		if ( mInverseOn[runIndex] )
			{
			nextInverseIndex = nextInverseIndex + 1;
			/*doing inverse*/
			if ( nextInverseIndex == 2 )
				{
				/*finshed Inverse. Do next energy*/
				nextInverseIndex = 0;
				doNextEnergy = TRUE;
				}
			}
		else
			{
			/*not doing inverse. Do next energy*/
			doNextEnergy = TRUE;
			}
		
		if ( doNextEnergy == TRUE )
			{
			nextEnergyIndex = nextEnergyIndex + 1;
			if (( nextEnergyIndex >= mNumEnergies[runIndex] ))
				{
				nextEnergyIndex = 0;
				minusWedgeIndex = FALSE;
				}
			}

		if ( minusWedgeIndex == TRUE )
			{
			nextWedgeIndex = ((int)(mCurrentWedgeIndex[runIndex] - 1) / mFramesPerWedge[runIndex]) * mFramesPerWedge[runIndex] + 1;
			}
		}

	mCurrentWedgeIndex[runIndex] = nextWedgeIndex;
	mCurrentEnergyIndex[runIndex] = nextEnergyIndex;
	mCurrentInverseIndex[runIndex] = nextInverseIndex;

	/*if index is too high*/
	if ( mCurrentWedgeIndex[runIndex] > mMaxFrame[runIndex])
		return XOS_FAILURE;

	return XOS_SUCCESS;

	}

// This function exists because the wedge_get_next_frame_function uses the results 
// of the previous frame to calculate the next frame.
// If the requested frame does not follow the previously requested frame, this 
// function will loop over all prior frames to get to the requested frame.
xos_result_t wedge_get_frame_data( int					runIndex,
											  int					absoluteFrameIndex,
											  double				*startAngle,
											  int					*frameLabel,
											  int	  				*energyIndex )
	{
	int frameCnt;

	//Check to see if the requested frame immediately follows the
	//frame requested the previous time this function was called.
	if ( absoluteFrameIndex == mLastFrameIndex[runIndex] + 1 )
		{
		//yes, simply get the next frame.
		if ( wedge_get_next_frame( runIndex ) == XOS_FAILURE)
			{
			LOG_WARNING("wedge_get_frame_data: could not get next frame.\n");
			return XOS_FAILURE;
			}
		}
	else if ( absoluteFrameIndex == mLastFrameIndex[runIndex] )
		{
		//its the same frame we requested last time...(for this run)
		LOG_INFO("wedge_get_frame_data: calculated this frame previously.\n");
		}
	else
		{
		//no, start from the beginning and call the wedge_get_next_frame
		//until we are at the frame we want.
		mCurrentWedgeIndex[runIndex] = 1;
		mCurrentInverseIndex[runIndex] = 0;
		mCurrentEnergyIndex[runIndex] = 0;
		//loop over all prior frames.
		for (frameCnt = 1; frameCnt < absoluteFrameIndex; frameCnt++)
			{
			if ( wedge_get_next_frame( runIndex ) == XOS_FAILURE)
				{
				LOG_WARNING("wedge_get_frame_data: could not get next frame.\n");
				return XOS_FAILURE;
				}
			}
		}

	//remember the last frame requested.
	mLastFrameIndex[runIndex] = absoluteFrameIndex;
	
	*frameLabel = mCurrentWedgeIndex[runIndex]  + mRunStartFrame[runIndex] -1;
	*startAngle = (double)(mCurrentWedgeIndex[runIndex]) * mDelta[runIndex] - mDelta[runIndex] + mRunStartAngle[runIndex];

	if ( ( mInverseOn[runIndex] == TRUE ) && ( mCurrentInverseIndex[runIndex] == 1) )
		{
		*frameLabel += mInverseStartFrame[runIndex];
		(*startAngle) = (*startAngle) + 180.0;
		}
	*energyIndex = mCurrentEnergyIndex[runIndex];
	//LOG_INFO1("wedge_get_frame_data: energyIndex %d\n", *energyIndex);
	return XOS_SUCCESS;
	}



int wedge_get_max_index ( int runIndex)
	{
	LOG_INFO2("run Index:%d,  maxAbsoluteFrame:%d\n", runIndex, mMaxAbsoluteFrame[runIndex] );
	return mMaxAbsoluteFrame[runIndex];
	}


