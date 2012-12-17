#include "RobotEpson.h"
#include "RobotEpsonSymbal.h"
#include "log_quick.h"

#include <math.h>

/*
 * Force Sensing
 */

bool RobotEpson::ForceCalibrate ( void )
{
	m_pSPELCOM->Force_Calibrate ( );

	float forces[6] = {0};
	ReadRawForces( forces );

	int i = 0;

	bool needRetry = false;
	for (i = 0; i < 6; ++i)
	{
		if (fabsf( forces[i] ) > 0.5)
		{
			needRetry = true;
		}
	}

	if (!needRetry) return true;

	//retry reset forces
	//if (m_pEventListener)
	//{
	//	m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "retry force sensor resettting" );
	//}
	LOG_WARNING( "retry force sensor resettting" );
	RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
	m_pSPELCOM->Force_Calibrate ( );
	ReadRawForces( forces );
	
	for (i = 0; i < 6; ++i)
	{
		if (fabsf( forces[i] ) > 0.5)
		{
			char message[128] = {0};
			sprintf( message, "still force exists after reset force sensor force[%d]=%f", i, forces[i] );
			if (m_pEventListener)
			{
				m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, message );
			}
			LOG_WARNING( message );
			return false;
		}
	}
	//if (m_pEventListener)
	//{
	//	m_pEventListener->OnRobotEvent( RobotEventListener::EVTNUM_HARDWARE_LOG_WARNING, "retry force sensor reset OK" );
	//}
	return true;
}

void RobotEpson::LogRawForce( int forceName )
{
	LOG_FINE1( "============== Raw Force (%d) ==================", forceName );

	int forceIndex = forceName - 1;
	if (forceIndex < 0 || forceIndex >=6)
	{
		LOG_WARNING1( "bad forceindex=%d", forceIndex );
		return;
	}

	LOG_FINE1( "threshold min=%f", m_ThresholdMin[forceIndex] );
	LOG_FINE1( "threshold max=%f", m_ThresholdMax[forceIndex] );
	LOG_FINE1( "valid sample#=%d", m_NumValidSample[forceIndex] );

	for (int i = 0; i < FORCE_READ_TIMES; ++i)
	{
		LOG_FINE3( "rawforce[%d][%d]=%f", forceIndex, i, m_RawForces[forceIndex][i] );
	}
}

void RobotEpson::LogRawForces( )
{
	LOG_FINE( "============== Raw Forces ==================" );

	char line[256]= {0};

	sprintf( line, "threshold min: %f %f %f %f %f %f",
		m_ThresholdMin[0],
		m_ThresholdMin[1],
		m_ThresholdMin[2],
		m_ThresholdMin[3],
		m_ThresholdMin[4], 
		m_ThresholdMin[5] ); 
	LOG_FINE( line );

	sprintf( line, "threshold max: %f %f %f %f %f %f",
		m_ThresholdMax[0],
		m_ThresholdMax[1],
		m_ThresholdMax[2],
		m_ThresholdMax[3],
		m_ThresholdMax[4], 
		m_ThresholdMax[5] ); 
	LOG_FINE( line );

	sprintf( line, "valid samples: %i %i %i %i %i %i",
		m_NumValidSample[0],
		m_NumValidSample[1],
		m_NumValidSample[2],
		m_NumValidSample[3],
		m_NumValidSample[4], 
		m_NumValidSample[5] ); 
	LOG_FINE( line );

	for (int i = 0; i < FORCE_READ_TIMES; ++i)
	{
		sprintf( line, "rawforces[%d]: %f %f %f %f %f %f",
			i,
			m_RawForces[0][i],
			m_RawForces[1][i],
			m_RawForces[2][i],
			m_RawForces[3][i],
			m_RawForces[4][i], 
			m_RawForces[5][i] ); 
		LOG_FINE( line );
	}
}



float RobotEpson::ReadForce( int forceName )
{
	forceName = abs(forceName);
    int index;
    int forceIndex = forceName - 1;

    float maxValue = -999999.0f;
    float minValue = 999999.0f;

	memset( m_RawForces, 0 , sizeof(m_RawForces) );

    //wait at the beginning of reads
    RobotWait( WAIT_TIME_BEFORE_READ_FORCE );
    //read in raw force value first
    for (index = 0; index < FORCE_READ_TIMES; ++index)
    {
        //sampling force
        float instantForce = m_pSPELCOM->Force_GetForce( forceName );
        m_RawForces[forceIndex][index] = instantForce;

        //keep max/min
        if (instantForce > maxValue ) maxValue = instantForce;
        if (instantForce < minValue ) minValue = instantForce;

        //wait between readings
        RobotWait( WAIT_TIME_BETWEEN_READ_FORCE );
    }

    //get rid of odd readings
    int numValidSamples = NarrowMinMax( forceIndex, minValue, maxValue );
    if (numValidSamples > 80) NarrowMinMax( forceIndex, minValue, maxValue );

    //do the average
    return AverageForce( forceIndex, minValue, maxValue );
}

void RobotEpson::ReadForces( float forces[6] )
{
    float maxValues[6] = {-99999, -99999, -99999, -99999, -99999, -99999 };
    float minValues[6] = { 99999,  99999,  99999,  99999,  99999,  99999 };
    float values[6];

	memset( m_RawForces, 0 , sizeof(m_RawForces) );

	RobotWait( WAIT_TIME_BEFORE_READ_FORCE );
    //read in raw force value first
    for (int index = 0; index < FORCE_READ_TIMES; ++index)
    {
        //sampling force
        ReadRawForces( values );

        for (int i = 0; i < 6; ++i)
        {
            //fill
            m_RawForces[i][index] = values[i];

            //keep max/min
            if (values[i] > maxValues[i]) maxValues[i] = values[i];
            if (values[i] < minValues[i]) minValues[i] = values[i];
        }
        //wait between readings
        RobotWait( WAIT_TIME_BETWEEN_READ_FORCE );
    }

    for (int i = 0; i < 6; ++i)
    {
        //get rid of odd readings
        int numValidSamples = NarrowMinMax( i, minValues[i], maxValues[i] );
        if (numValidSamples > 80) NarrowMinMax( i, minValues[i], maxValues[i] );
        //do the average
        forces[i] = AverageForce( i, minValues[i], maxValues[i] );
    }
}


int RobotEpson::NarrowMinMax( int forceIndex, float& minValue, float& maxValue)
{
    if (maxValue - minValue < 0.00001) return 0;

    int bin[10] = {0};
    float binInterval = (maxValue - minValue) / 10.0f;
    int validSamples = 0;

    //fill bins
    for (int index = 0; index < FORCE_READ_TIMES; ++index)
    {
        float instantForce = m_RawForces[forceIndex][index];

        if (instantForce > maxValue || instantForce < minValue)
        {
            continue; //skip this sample
        }

        int binIndex = (int)((instantForce - minValue) / binInterval);
        if (binIndex >= 0 && binIndex < 10)
        {
            ++validSamples;
            ++bin[binIndex];
        }
    }//fill bins

    //cut 25% samples from both sides: cutting unit is bin
    int numSamplesToCut = validSamples / 4;
    int numSamplesLeft = validSamples;

    int numDiscard = 0;
	int binIndex = 0;
    for (binIndex = 0; binIndex < 10; ++binIndex)
    {
        if (numDiscard + bin[binIndex] <= numSamplesToCut)
        {
            numDiscard += bin[binIndex];
            minValue += binInterval;
        }
        else
        {
            break;
        }
    }
    numSamplesLeft -= numDiscard;

    numDiscard = 0;
    for (binIndex = 9; binIndex <= 0; --binIndex)
    {
        if (numDiscard + bin[binIndex] <= numSamplesToCut)
        {
            numDiscard += bin[binIndex];
            maxValue -= binInterval;
        }
        else
        {
            break;
        }
    }
    numSamplesLeft -= numDiscard;

    return numSamplesLeft;
}

float RobotEpson::AverageForce( int forceIndex, float minValue, float maxValue)
{
	if (forceIndex < 0 || forceIndex >=6)
	{
		LOG_WARNING1( "bad force index: %d", forceIndex);
		return 0.0f;
	}

    int numValidSamples = 0;

    float result = 0.0f;

    for (int index = 0; index < FORCE_READ_TIMES; ++index)
    {
        float instantForce = m_RawForces[forceIndex][index];
        if (instantForce > maxValue || instantForce < minValue)
        {
            continue; //skip
        }
        result += instantForce;
        ++numValidSamples;
    }

    if (numValidSamples > 0) result /= numValidSamples;

	//save infor for logging
	m_ThresholdMin[forceIndex] = minValue;
	m_ThresholdMax[forceIndex] = maxValue;
	m_NumValidSample[forceIndex] = numValidSamples;
    return result;
}


void RobotEpson::GenericMove( const PointCoordinate& position, bool withForceTrigger )
{
    //check to use move or go: we have to use "GO" if only U change
    PointCoordinate currentPosition;
    GetCurrentPosition( currentPosition );

	char log_message[256] = {0};
	sprintf( log_message, "GenericMove current position (%f, %f, %f, %f)", currentPosition.x, currentPosition.y, currentPosition.z, currentPosition.u );
	LOG_FINEST( log_message );

	sprintf( log_message, "GenericMove dest position (%f, %f, %f, %f)", position.x, position.y, position.z, position.u );
	LOG_FINEST( log_message );


	//set P66 as destination
	PointCoordinate point = position;
	point.o = currentPosition.o;
	assignPoint( P66, point );
    
	if (position.distance( currentPosition ) > 1.0)
    {
        if (withForceTrigger)
        {
	        m_pSPELCOM->Move( (COleVariant)"P66 Till Force");
        }
		else
		{
	        m_pSPELCOM->Move( (COleVariant)"P66");
		}
    }
    else
    {
        if (withForceTrigger)
        {
	        m_pSPELCOM->Go( (COleVariant)"P66 Till Force");
        }
		else
		{
	        m_pSPELCOM->Go( (COleVariant)"P66");
		}
    }
}

void RobotEpson::StepMove( const PointCoordinate& step, bool withForceTrigger )
{
    PointCoordinate destination;

    GetCurrentPosition( destination );

	destination.x += step.x;
	destination.y += step.y;
	destination.z += step.z;
	destination.u += step.u;

    GenericMove( destination, withForceTrigger );
}

#ifdef WRONG_FORCE_SENSOR
void RobotEpson::SetupForceTrigger( int forceName, float threshold )
{
	int AbsForceName = abs(forceName);
    m_pSPELCOM->Force_ClearTrigger( );
    switch (forceName)
    {
    case FORCE_XFORCE:
    case FORCE_YFORCE:
    case FORCE_ZFORCE:
    case -FORCE_XTORQUE:
    case -FORCE_YTORQUE:
    case -FORCE_ZTORQUE:
        m_pSPELCOM->Force_SetTrigger( AbsForceName, threshold, 1 );
        break;

    case -FORCE_XFORCE:
    case -FORCE_YFORCE:
    case -FORCE_ZFORCE:
    case FORCE_XTORQUE:
    case FORCE_YTORQUE:
    case FORCE_ZTORQUE:
        m_pSPELCOM->Force_SetTrigger( AbsForceName, threshold, 0 );
        break;
    }
}
#else
void RobotEpson::SetupForceTrigger( int forceName, float threshold )
{
	int AbsForceName = abs(forceName);
    m_pSPELCOM->Force_ClearTrigger( );
    switch (forceName)
    {
    case FORCE_XFORCE:
    case FORCE_YFORCE:
    case FORCE_ZFORCE:
    case FORCE_XTORQUE:
    case FORCE_YTORQUE:
    case FORCE_ZTORQUE:
        m_pSPELCOM->Force_SetTrigger( AbsForceName, threshold, 1 );
        break;

    case -FORCE_XFORCE:
    case -FORCE_YFORCE:
    case -FORCE_ZFORCE:
    case -FORCE_XTORQUE:
    case -FORCE_YTORQUE:
    case -FORCE_ZTORQUE:
        m_pSPELCOM->Force_SetTrigger( AbsForceName, threshold, 0 );
        break;
    }
}
#endif

float RobotEpson::HyperStepSize( const PointCoordinate& step )
{
    float result = step.x * step.x + step.y * step.y + step.z * step.z + step.u * step.u;
    result = sqrtf( result );
    return result;
}

float RobotEpson::HyperDistance( const PointCoordinate& position1, const PointCoordinate& position2 )
{
	PointCoordinate step;
	step.x = position2.x - position1.x;
	step.y = position2.y - position1.y;
	step.z = position2.z - position1.z;
	step.u = position2.u - position1.u;

    return HyperStepSize( step );
}

bool RobotEpson::ForceExceedThreshold( int forceName, float currentForce, float threshold )
{
    bool result = false;

    if (forceName > 0)
    {
        if (currentForce >= threshold) result = true;
    }
    else
    {
        if (currentForce <= threshold) result = true;
    }

    return result;
}


void RobotEpson::ForceBinaryCross( int forceName, const PointCoordinate& previousPosition, float previousForce, float threshold, int numSteps )
{
    //check previous force
    float preDeltaF = fabsf( previousForce - threshold );
    if (preDeltaF < 0.01)
    {
        GenericMove( previousPosition, false );
        return;
    }

    //check current force info
    float currentForce = ReadForce( forceName );
    float curDeltaF = fabsf( currentForce - threshold );
    if (curDeltaF < 0.01)
    {
        return;
    }

    //get init step size
    PointCoordinate stepSize;
    PointCoordinate currentPosition;
    PointCoordinate newPreviousPosition;
    float newPreviousForce;

    GetCurrentPosition( currentPosition );
	stepSize = currentPosition - previousPosition;
    if (HyperStepSize( stepSize ) <= 0.0001)
    {
        return;
    }

    //save best position we passed
    PointCoordinate bestPosition;
    float bestDeltaForce;
    
    if (preDeltaF < curDeltaF)
    {
        bestDeltaForce = preDeltaF;
        bestPosition = previousPosition;
    }
    else
    {
        bestDeltaForce = curDeltaF;
        bestPosition = currentPosition;
    }

    //go back to previous position: we will try to cross from the same direction as caller.
    GenericMove( previousPosition, false );
    newPreviousPosition = previousPosition;
    newPreviousForce = previousForce;

    //loop
    for (int BCIndex = 0; BCIndex < numSteps; ++BCIndex)
    {
		stepSize /= 2;
        if (HyperStepSize( stepSize ) <= 0.0001)
        {
            return;
        }

        //move step
        StepMove( stepSize, false );

        //read position and force
        PointCoordinate tmpPosition;
        float tmpForce;
        float tmpDeltaF;
        GetCurrentPosition( tmpPosition );
        tmpForce = ReadForce( forceName );

        //check to see if we are very close to the threshold
        tmpDeltaF = fabsf( tmpForce - threshold );
        if (tmpDeltaF < 0.01)
        {
            return;
        }

        //save the best
        if (tmpDeltaF < bestDeltaForce)
        {
            bestDeltaForce = tmpDeltaF;
            bestPosition = tmpPosition;
        }

        //check to see if we passed the threshold:
        //if passed, go back and reduce step size again,
        //if not, set current position to previous position and continue move forward
        if ((newPreviousForce - threshold) * ( tmpForce - threshold) < 0)
        {
            //we crossed, so take this position as new "current position"
            currentPosition = tmpPosition;
            currentForce = tmpForce;
            GenericMove( newPreviousPosition, false );
        }
        else
        {
            newPreviousPosition = tmpPosition;
            newPreviousForce = tmpForce;
        }
    }//for (int BCIndex = 0; BCIndex < numSteps; ++BCIndex)

    //move to best
    GenericMove( bestPosition, false );
}

bool RobotEpson::ForceScan( int forceName, float threshold, const PointCoordinate& destinationPosition, int numSteps, bool fineTune )
{
    PointCoordinate initPosition;

    GetCurrentPosition( initPosition );
	char log_message[256] = {0};
	sprintf( log_message, "ForceScan init position (%f, %f, %f, %f)", initPosition.x, initPosition.y, initPosition.z, initPosition.u );
	LOG_FINEST( log_message );
	sprintf( log_message, "ForceScan dest position (%f, %f, %f, %f)", destinationPosition.x, destinationPosition.y, destinationPosition.z, destinationPosition.u );
	LOG_FINEST( log_message );
	LOG_FINEST1( "numstep=%d", numSteps );

    float preForce = ReadForce( forceName );

    //check init
    if (ForceExceedThreshold( forceName, preForce, threshold ))
    {
        //should not be called
        return true;
    }

    //setup slow move
	setRobotSpeed( SPEED_PROBE );
    //check input
    if (numSteps <= 0) numSteps = 10;

    PointCoordinate stepSize;

    stepSize = (destinationPosition - initPosition) / (float)numSteps;

    float hyperStepDistance = HyperStepSize( stepSize );
    PointCoordinate prePosition;

    prePosition = initPosition;
    for (int scanIndex = 0; scanIndex < numSteps; ++scanIndex)
    {
        if (m_FlagAbort)
        {
            return false;
        }

        PointCoordinate desiredPosition;

        //calculate where we should move in this step
        desiredPosition = initPosition + stepSize * (float)(scanIndex + 1);

        //set up trigger and go
        SetupForceTrigger( forceName, 1.2f * threshold );
        GenericMove( desiredPosition, true );
		sprintf( log_message, "step[%d] dest (%f, %f, %f, %f)", scanIndex, desiredPosition.x, desiredPosition.y, desiredPosition.z, desiredPosition.u );
		LOG_FINEST( log_message );

        //check how we moved
        PointCoordinate currentPosition;
        float currentForce;
        GetCurrentPosition( currentPosition );

        //check force
        currentForce = ReadForce( forceName );
        if (ForceExceedThreshold( forceName, currentForce, threshold ))
        {
            if (fineTune) ForceBinaryCross( forceName, prePosition, preForce, threshold, FORCE_BINARY_CROSS_TIMES );
            return true;
        }

        //check how much we moved: if not on the desired position, we move to there without force trigger
        if (HyperDistance( currentPosition, desiredPosition ) > 0.0001)
        {
            //move without force trigger
            GenericMove( desiredPosition, false );
            GetCurrentPosition( currentPosition );
            //re-check force
            currentForce = ReadForce( forceName );
		    LOG_FINEST1( "move without trigger to dest, force=%f", currentForce );
            if (ForceExceedThreshold( forceName, currentForce, threshold ))
            {
                if (fineTune) ForceBinaryCross( forceName, prePosition, preForce, threshold, FORCE_BINARY_CROSS_TIMES );
                return true;
            }

        }
        else
        {
		    sprintf( log_message, "real position (%f, %f, %f, %f) force=%f", 
                currentPosition.x, 
                currentPosition.y, 
                currentPosition.z, 
                currentPosition.u,
                currentForce );
		    LOG_FINEST( log_message );
        }

        //prepare for next
        prePosition = currentPosition;
        preForce = currentForce;
    }//for (int scanIndex = 0; scanIndex < numSteps; ++scanIndex)

    //reach here, we got destination without cross the threshold
    //GenericMove( destinationPosition, false );
    return false;
}

void RobotEpson::GetTouchParameters( int forceName, float& threshold, float& min, float& initStepSize )
{
    int AbsForceName = (forceName > 0) ? forceName : -forceName;

    switch (AbsForceName)
    {
    case FORCE_XFORCE:
    case FORCE_YFORCE:
    case FORCE_XTORQUE:
    case FORCE_YTORQUE:
        threshold = 1.5f;
        min = 0.1f;
        initStepSize = 1.0f;
        break;

    case FORCE_ZFORCE:
        threshold = 4.0f;
        min = 0.1f;
        initStepSize = 1.0f;
        break;

    case FORCE_ZTORQUE:
        threshold = 0.1f;
        min = 0.05f;
        initStepSize = 1.0f;
        break;
    }
    if (forceName < 0)
    {
        threshold = -threshold;
        min = -min;
    }
}


//touch: try to move with force trigger first, if failed, step-scan to it
bool RobotEpson::ForceTouch( int forceName, const PointCoordinate& destinationPosition, bool fineTune )
{
    float threshold = 0.0f;
    float min = 0.0f;
    float initStepSize = 9999999.0f;

    bool result = false;

	PointCoordinate initPosition;
	PointCoordinate middlePosition;

    GetCurrentPosition( initPosition );

	char log_message[256] = {0};
	sprintf( log_message, "ForceTouch init position (%f, %f, %f, %f)", initPosition.x, initPosition.y, initPosition.z, initPosition.u );
	LOG_FINEST( log_message );

	sprintf( log_message, "ForceTouch dest position (%f, %f, %f, %f)", destinationPosition.x, destinationPosition.y, destinationPosition.z, destinationPosition.u );
	LOG_FINEST( log_message );

    GetTouchParameters( forceName, threshold, min, initStepSize );
	sprintf( log_message, "ForceTouch init stepsize %f", initStepSize );
	LOG_FINEST( log_message );

	setRobotSpeed( SPEED_PROBE );

    //try move with force first
    for (int retry = 0; retry < FORCE_RETRY_TIMES; ++retry)
    {
        if (m_FlagAbort)
        {
            GenericMove( initPosition, false );
            return false;
        }
		PointCoordinate prePosition;
		GetCurrentPosition( prePosition );
        SetupForceTrigger( forceName, 1.2f * threshold );
        GenericMove( destinationPosition, true );
        float currentForce = ReadForce( forceName );

		//if we did not move at all, reset force sensor
		GetCurrentPosition( middlePosition );
		float movedDistance = HyperDistance( middlePosition, prePosition );
		LOG_FINEST3( "force touch trying[%d], force=%f, moved :%f",retry, currentForce, movedDistance);
		if (movedDistance < 0.01)
		{
			LOG_FINEST("resetting force sensor in force touche");
			RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
			ForceCalibrate( );
		    m_pSPELCOM->Force_ClearTrigger( );
			continue;
		}

        //make sure force is not too big
        if (ForceExceedThreshold( forceName, currentForce, 5.0f * threshold ))
        {
            //go back and retry
            GenericMove( initPosition, false );
            continue;
        }

        //check if we passed the threshold
        if (ForceExceedThreshold( forceName, currentForce, threshold ))
        {
            result = true;
            break;
        }
    }

    GetCurrentPosition( middlePosition );
	sprintf( log_message, "ForceTouch after move with trigger, position (%f, %f, %f, %f)", middlePosition.x, middlePosition.y, middlePosition.z, middlePosition.u );
	LOG_FINEST( log_message );
    if (!result)
    {
        float hyperDistance = HyperDistance( middlePosition, destinationPosition );
        if (hyperDistance < 0.0001)
        {
            return false;
        }

        int numSteps = int(hyperDistance / initStepSize);

        if (!ForceScan( forceName, threshold, destinationPosition, numSteps, false ))
        {
            return false;
        }
    }

    //if fineTune, we turnback and find min force
    if (fineTune)
    {
        //save start position, we may need to reset force sensor and come back
        GetCurrentPosition( middlePosition );
        PointCoordinate fineDestPosition;
        float hyperDistance = HyperDistance( initPosition, middlePosition );
        int totalSteps = int(hyperDistance / initStepSize);

        fineDestPosition = middlePosition + (initPosition - middlePosition) * (float)(4.0 / totalSteps);

		int retry = 0;
        for (retry = 0; retry < FORCE_RETRY_TIMES; ++retry)
        {
            if (!ForceScan( -forceName, min, fineDestPosition, 4, true ))
            {
                if (m_FlagAbort)
                {
                    GenericMove( initPosition, false );
                    return false;
                }
                //reset force sensor
                GenericMove( initPosition, false );
                RobotWait( WAIT_TIME_BEFORE_RESET_FORCE_SENSOR );
                ForceCalibrate( );
                GenericMove( middlePosition, false );
            }
            else
            {
                break;
            }
        }
        if (retry >= FORCE_RETRY_TIMES)
        {
            return false;
        }
    }

    return true;
}


void RobotEpson::ReadRawForces( float rawForces[6] )
{
	HRESULT hr;

	memset( rawForces, 0, 6 * sizeof(float) );

	//clear the safe array's data.
	float* pData;
	hr = SafeArrayAccessData(m_ForcesVariant.parray, (void**)&pData); //Get a pointer to the data.
    if (hr != S_OK)
    {
        LOG_SEVERE( "safe array access data failed" );
        return;
    }	
	memset( pData, 0, sizeof(float) * FORCE_SAFE_ARRAY_LENGTH );
    SafeArrayUnaccessData(m_ForcesVariant.parray);

	//call function
    m_pSPELCOM->Force_GetForces( m_ForcesVariant );

    //access result
	hr = SafeArrayAccessData(m_ForcesVariant.parray, (void**)&pData); //Get a pointer to the data.
    if (hr != S_OK)
    {
        LOG_SEVERE( "after function call, safe array access data failed" );
        return;
    }
    for (int i = 0; i < 6; ++i)
    {
        rawForces[i] = pData[i + 1];
    }
    SafeArrayUnaccessData(m_ForcesVariant.parray);
}
