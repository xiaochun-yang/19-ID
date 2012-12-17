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



#include "xos_semaphore_set.h"


xos_result_t xos_semaphore_set_create
	(
	xos_semaphore_set_t	*semaphoreSet,
	unsigned int			semaphoreCount
	)

	{
	xos_index_t			index;
	xos_semaphore_t	*semaphoreAddress;
	xos_result_t		xosResult;

	/* make sure a valid address was passed for the semaphore set */
	assert ( semaphoreSet != NULL );

	/* make sure a valid valid was passed for the semaphore count */
	assert ( semaphoreCount > 0 );

	/* allocate memory for specified number of semaphores */
	semaphoreSet->semaphoreArray = 
		malloc( sizeof( xos_semaphore_t ) * semaphoreCount );

	/* return error if memory could not be allocated */
	if ( semaphoreSet->semaphoreArray == NULL )
		{
		semaphoreSet->isValid = FALSE;
		return XOS_FAILURE;
		}

	/* create each semaphore */
	for ( index = 0; index < semaphoreCount; index++ )
		{
		/* calculate address of next semaphore */
		semaphoreAddress = semaphoreSet->semaphoreArray + index;

		/* create the next semaphore */
		xosResult = xos_semaphore_create( semaphoreAddress, 0 );

		/* handle errors from xos_semaphore_create */
		if ( xosResult != XOS_SUCCESS )
			{
			semaphoreSet->isValid = FALSE;
			return XOS_FAILURE;
			}
		}

	/* initialize remaining semaphore set data members */
	semaphoreSet->semaphoreCount	= semaphoreCount;
	semaphoreSet->useCount			= 0;
	semaphoreSet->isValid			= TRUE;

	/* report success */
	return XOS_SUCCESS;
	}


xos_result_t xos_semaphore_set_initialize
	(
	xos_semaphore_set_t	*semaphoreSet
	)

	{
	/* make sure a valid address was passed for the semaphore set */
	assert ( semaphoreSet != NULL );
	
	/* make sure semaphore set structure is valid */
	assert ( semaphoreSet->isValid == TRUE );

	/* set use count to zero */
	semaphoreSet->useCount = 0;

	/* report success */
	return XOS_SUCCESS;
}


xos_result_t xos_semaphore_set_get_next
	(
	xos_semaphore_set_t	*semaphoreSet,
	xos_semaphore_t		**semaphorePointer
	)

	{
	/* make sure a valid address was passed for the semaphore set */
	assert ( semaphoreSet != NULL );
	
	/* make sure a valid pointer was provided for the semaphore */
	assert ( semaphorePointer != NULL );

	/* make sure semaphore set structure is valid */
	assert ( semaphoreSet->isValid == TRUE );

	/* return error if no more semaphores in set */
	if ( semaphoreSet->useCount == semaphoreSet->semaphoreCount )
		{
		return XOS_FAILURE;
		}

	/* put address of next semaphore in passed pointer */
	*semaphorePointer =
		semaphoreSet->semaphoreArray + semaphoreSet->useCount;

	/* increment the number of semaphores in use */
	semaphoreSet->useCount ++;

	/* report success */
	return XOS_SUCCESS;
	}


xos_wait_result_t xos_semaphore_set_wait
	(
	xos_semaphore_set_t	*semaphoreSet,
	xos_time_t				timeout
	)

	{
	/* local variables */
	xos_index_t			index;
	xos_semaphore_t	*semaphoreAddress;
	xos_wait_result_t	xosWaitResult;

	/* make sure a valid address was passed for the semaphore set */
	assert ( semaphoreSet != NULL );

	/* make sure semaphore set structure is valid */
	assert ( semaphoreSet->isValid == TRUE );

	/* wait for each in-use semaphore in turn */
	for ( index = 0; index < semaphoreSet->useCount; index++ )
		{
		/* calculate address of next semaphore to wait for */
		semaphoreAddress = semaphoreSet->semaphoreArray + index;

		/* wait for the semaphore with the specified timeout */
		xosWaitResult = xos_semaphore_wait( semaphoreAddress, timeout );

		/* handle errors from xos_semaphore_wait */
		if ( xosWaitResult != XOS_WAIT_SUCCESS )
			{
			semaphoreSet->isValid = FALSE;
			return xosWaitResult;
			}
		}

	/* report success */
	return XOS_WAIT_SUCCESS;
	}


xos_result_t xos_semaphore_set_destroy
	(
	xos_semaphore_set_t	*semaphoreSet
	)

	{
	xos_index_t				index;
	xos_semaphore_t	*semaphoreAddress;
	xos_result_t		xosResult;

	/* make sure a valid address was passed for the semaphore set */
	assert ( semaphoreSet != NULL );

	/* make sure address of semaphore array is valid */
	assert ( semaphoreSet->semaphoreArray != NULL );
	
	/* invalidate the object */
	semaphoreSet->isValid = FALSE;

	/* close each semaphore */
	for ( index = 0; index < semaphoreSet->useCount; index++ )
		{
		/* calculate address of next semaphore to wait for */
		semaphoreAddress = semaphoreSet->semaphoreArray + index;

		/* wait for the semaphore with the specified timeout */
		xosResult = xos_semaphore_close( semaphoreAddress );

		/* handle errors from xos_semaphore_wait */
		if ( xosResult != XOS_SUCCESS )
			{
			return XOS_FAILURE;
			}
		}

	/* free memory associated with array of semaphores */
	free ( semaphoreSet->semaphoreArray );

	/* report success */
	return XOS_SUCCESS;
	}
	
	
